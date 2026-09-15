import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/conversation_drawer.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/multimodal_choice.dart';

import 'history24_fixture.dart';

void main() {
  testWidgets(
    'multi-select stays in the same drawer at the same scroll offset',
    (tester) async {
      tester.view.physicalSize = const Size(412, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final b = history24Fixture(count: 80);
      final c = MailController(b, initial: b.data);
      await c.start();
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ConversationDrawer(c))),
      );
      await tester.pumpAndSettle();
      final list = find.byKey(const PageStorageKey('conversation-list'));
      final scroll = tester.widget<ListView>(list).controller!;
      scroll.jumpTo(360);
      await tester.pumpAndSettle();
      final before = scroll.offset;
      final visible = find
          .descendant(of: list, matching: find.byType(InkWell))
          .hitTestable()
          .first;
      await tester.longPress(visible);
      await tester.pumpAndSettle();
      await tester.tap(find.text('多选'));
      await tester.pumpAndSettle();
      expect(tester.widget<ListView>(list).controller, same(scroll));
      expect(scroll.offset, before);
      expect(find.byType(ConversationDrawer), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byKey(const ValueKey('conversation-search')), findsOneWidget);
      expect(find.text('已选 1 个对话'), findsOneWidget);
      expect(b.calls, isNot(contains('loadConversation')));
      await tester.tap(find.byTooltip('退出多选'));
      await tester.pumpAndSettle();
      expect(scroll.offset, before);
      await tester.longPress(visible);
      await tester.pumpAndSettle();
      expect(find.text('重命名'), findsOneWidget);
      await tester.tap(find.text('重命名'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.6, 2.0]) {
      testWidgets('rename avoids title and keyboard $width $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final b = history24Fixture();
        final c = MailController(b, initial: b.data);
        await c.start();
        await tester.pumpWidget(
          MaterialApp(
            theme: mailTheme(false),
            home: Scaffold(body: ConversationDrawer(c)),
          ),
        );
        await tester.pumpAndSettle();
        await tester.longPress(
          find.byKey(const ValueKey('conversation-history-0')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('重命名'));
        await tester.pumpAndSettle();
        tester.view.viewInsets = const FakeViewPadding(bottom: 320);
        await tester.pumpAndSettle();
        final input = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        );
        expect(
          tester.getRect(find.text('重命名对话')).bottom,
          lessThan(tester.getRect(input).top),
        );
        expect(tester.getRect(input).bottom, lessThan(530));
        await tester.enterText(input, '  修改后的名称  ');
        await tester.ensureVisible(find.text('保存'));
        await tester.tap(find.text('保存'));
        await tester.pumpAndSettle();
        expect(b.data.rows('conversations').first.text('title'), '修改后的名称');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      });
    }
  }
  testWidgets('oversized image choice only sends after explicit batch action', (
    tester,
  ) async {
    final b = history24Fixture();
    final c = MailController(b, initial: b.data);
    await c.start();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showMultimodalChoice(ctx, c, {
                'id': 'failed',
                'failure': {'message': '服务商报告请求体超限。'},
              }),
              child: const Text('处理方式'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('处理方式'));
    await tester.pumpAndSettle();
    expect(b.calls, isNot(contains('retryAnalysis')));
    await tester.tap(find.text('返回'));
    await tester.pumpAndSettle();
    expect(b.calls, isNot(contains('retryAnalysis')));
    await tester.tap(find.text('处理方式'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('分批处理本轮'));
    await tester.pumpAndSettle();
    expect(b.calls.where((x) => x == 'retryAnalysis').length, 1);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
