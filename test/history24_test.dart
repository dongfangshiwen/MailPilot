import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/conversation_drawer.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';

import 'history24_fixture.dart';

void main() {
  test('date groups are exclusive across month and year boundaries', () {
    final now = DateTime(2026, 1, 2);
    for (final pair in [
      (0, '今天'),
      (1, '昨天'),
      (6, '7 天内'),
      (7, '30 天内'),
      (29, '30 天内'),
    ]) {
      expect(
        conversationGroup({
          'lastActivityAt': now
              .subtract(Duration(days: pair.$1))
              .millisecondsSinceEpoch,
        }, now),
        pair.$2,
      );
    }
    expect(
      conversationGroup({
        'lastActivityAt': DateTime(2025, 12, 3).millisecondsSinceEpoch,
      }, now),
      '2025 年 12 月 3 日',
    );
    expect(conversationGroup({'pinnedAt': 1}, now), '置顶');
  });
  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.6, 2.0]) {
      for (final dark in [false, true]) {
        testWidgets('history actions width=$width scale=$scale dark=$dark', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 850);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final b = history24Fixture();
          final c = MailController(b, initial: b.data);
          await c.start();
          await tester.pumpWidget(
            MaterialApp(
              theme: mailTheme(dark),
              home: Scaffold(body: ConversationDrawer(c)),
            ),
          );
          await tester.pumpAndSettle();
          final first = find.byKey(const ValueKey('conversation-history-0'));
          await tester.ensureVisible(first);
          expect(tester.getSize(first).height, greaterThanOrEqualTo(48));
          await tester.longPress(first);
          await tester.pumpAndSettle();
          for (final text in ['重命名', '置顶', '多选', '删除']) {
            expect(find.text(text), findsOneWidget);
          }
          await tester.tap(find.text('多选'));
          await tester.pumpAndSettle();
          expect(find.text('已选 1 个对话'), findsOneWidget);
          await tester.tap(
            find.byKey(const ValueKey('conversation-history-1')),
          );
          await tester.pumpAndSettle();
          expect(find.text('已选 2 个对话'), findsOneWidget);
          await tester.tap(find.text('置顶').last);
          await tester.pumpAndSettle();
          expect(
            b.data.rows('conversations').where((e) => e.number('pinnedAt') > 0),
            hasLength(2),
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          c.dispose();
        });
      }
    }
  }
  testWidgets('content search debounce clear and direct multi selection', (
    tester,
  ) async {
    final b = history24Fixture();
    b.messageHistory['history-3'] = [
      {'role': 'assistant', 'text': '合同金额 48000 元'},
    ];
    final c = MailController(b, initial: b.data);
    await c.start();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ConversationDrawer(c))),
    );
    await tester.pumpAndSettle();
    final input = find.byKey(const ValueKey('conversation-search'));
    expect(tester.widget<TextField>(input).autofocus, isFalse);
    await tester.enterText(input, '合同金额');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('conversation-history-3')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('conversation-history-0')), findsNothing);
    await tester.tap(find.byTooltip('多选对话'));
    await tester.pumpAndSettle();
    expect(find.text('已选 0 个对话'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('conversation-history-3')));
    await tester.pumpAndSettle();
    expect(find.text('已选 1 个对话'), findsOneWidget);
    await tester.tap(find.byTooltip('退出多选'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('清空搜索'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('conversation-history-0')),
      findsOneWidget,
    );
    await tester.enterText(input, '不存在的正文');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('没有找到相关对话'), findsOneWidget);
    expect(find.byTooltip('多选对话'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets(
    'rename cancel, pagination, revision-only reload and no generation',
    (tester) async {
      final b = history24Fixture(count: 503);
      final controller = MailController(b, initial: b.data);
      await controller.start();
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ConversationDrawer(controller))),
      );
      await tester.pumpAndSettle();
      final requests = b.calls.where((e) => e == 'listConversations').length;
      for (var i = 0; i < 20; i++) {
        controller.notifyListeners();
        await tester.pump();
      }
      expect(b.calls.where((e) => e == 'listConversations').length, requests);
      final first = find.byKey(const ValueKey('conversation-history-0'));
      await tester.longPress(first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('重命名'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        '不应保存',
      );
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(b.data.rows('conversations').first.text('title'), '图片分析与邮件跟进');
      await tester.longPress(first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('重命名'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        '  新名称  ',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(b.data.rows('conversations').first.text('title'), '新名称');
      expect(
        b.calls.where(
          (e) => e == 'analyze' || e == 'sourceInfo' || e == 'confirmChatSend',
        ),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
}
