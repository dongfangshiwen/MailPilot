import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';

void main() {
  testWidgets('a configured model can chat without any mailbox', (
    tester,
  ) async {
    final b = PreviewBackend(
      initial: {
        ...previewState(),
        'accounts': [],
        'activeAccount': '',
        'messages': [],
      },
    );
    final c = MailController(b, initial: b.data);
    addTearDown(c.dispose);
    await c.start();
    await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
    expect(find.text('有什么想聊的？'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '帮我写一段自我介绍');
    await tester.pump();
    await tester.tap(find.byTooltip('发送问题'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(b.calls.contains('analyze'), isTrue);
    expect(c.failure, isNull);
    expect(c.data.number('tab'), 1);
    expect(find.byTooltip('添加附件'), findsOneWidget);
    for (var i = 0; i < 25 && c.data.flag('analyzing'); i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpAndSettle();
    expect(c.data.rows('entries').last.text('text'), contains('邮箱是可选功能'));
    expect(find.text('写成邮件'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'summary is inspectable and new conversation clears its context',
    (tester) async {
      final b = PreviewBackend(
        initial: {
          ...previewState(),
          'contextSummary': '用户计划周五交付，预算 500 元。',
          'summarizedEntries': 12,
        },
      );
      final c = MailController(b, initial: b.data);
      addTearDown(c.dispose);
      await c.start();
      await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
      expect(find.text('已整理 12 条早期消息'), findsNothing);
      await tester.tap(find.byTooltip('打开菜单'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('对话摘要'));
      await tester.pumpAndSettle();
      expect(find.text('本次对话摘要'), findsOneWidget);
      expect(find.text('用户计划周五交付，预算 500 元。'), findsOneWidget);
      Navigator.of(tester.element(find.text('本次对话摘要'))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('新对话'));
      await tester.pumpAndSettle();
      expect(find.text('已整理 12 条早期消息'), findsNothing);
      expect(c.data.text('contextSummary'), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
