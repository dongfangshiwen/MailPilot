import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';

void main() {
  Future<(MailController, PreviewBackend)> mount(WidgetTester tester) async {
    final backend = PreviewBackend();
    final controller = MailController(backend, initial: backend.data);
    await controller.start();
    await tester.pumpWidget(
      MailPilotApp(controller: controller, autoStart: false),
    );
    await tester.pumpAndSettle();
    addTearDown(controller.dispose);
    return (controller, backend);
  }

  testWidgets('clear and reselect retain history even during generation', (
    tester,
  ) async {
    final (c, b) = await mount(tester);
    b.data = {
      ...b.data,
      'conversationId': 'same-chat',
      'entries': [
        {'id': 'old', 'role': 'assistant', 'text': '保留之前的分析'},
      ],
      'selection': [
        {'messageId': 'm1', 'attachmentIds': <String>[]},
      ],
      'analyzing': true,
    };
    b.publish();
    await tester.pump();
    await c.act('clearSelection');
    await tester.pump();
    expect(c.data.text('conversationId'), 'same-chat');
    expect(c.data.rows('entries').single.text('text'), '保留之前的分析');
    expect(c.data.flag('analyzing'), isTrue);
    await c.act('toggleMessage', {'id': 'm1'});
    expect(c.data.rows('entries'), hasLength(1));
    expect(c.selected('m1'), isTrue);
    await c.act('cancelAnalysis');
    await tester.pumpAndSettle();
  });

  testWidgets('sync allows folder navigation and never starts on entry', (
    tester,
  ) async {
    final (c, b) = await mount(tester);
    await c.act('tab', {'index': 0});
    await tester.pumpAndSettle();
    await tester.tap(find.text('收件箱 ▾'));
    await tester.pumpAndSettle();
    expect(b.calls, isNot(contains('loadFolders')));
    expect(b.calls, isNot(contains('refresh')));
    await tester.tap(find.text('已发送'));
    await tester.pumpAndSettle();
    expect(c.data.text('folder'), 'Sent');
    expect(b.calls, isNot(contains('refresh')));
    await c.act('refresh');
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.busy, isFalse);
    await tester.tap(find.text('已发送 ▾'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('收件箱'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.data.text('folder'), 'INBOX');
    expect(c.data.flag('syncing'), isTrue);
    await c.act('tab', {'index': 1});
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TextField), findsOneWidget);
    await c.act('cancelSync');
    await tester.pumpAndSettle();
  });

  testWidgets(
    'redraft preserves recipient and delete disables old confirmation',
    (tester) async {
      final (c, b) = await mount(tester);
      await c.act('reply', {'id': 'm1'});
      await c.act('reviewDraftInChat', c.data.child('editor'));
      await tester.pumpAndSettle();
      final old = c.data.rows('drafts').single;
      await tester.tap(find.byTooltip('草稿操作'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('重新拟写'));
      await tester.pumpAndSettle();
      final revised = c.data.rows('drafts').single;
      expect(revised['id'], old['id']);
      expect(revised['to'], old['to']);
      expect(revised.number('revision'), old.number('revision') + 1);
      expect(c.data.rows('entries'), hasLength(2));
      await c.act('tab', {'index': 2});
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('草稿操作'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除草稿'));
      await tester.pumpAndSettle();
      expect(c.data.rows('drafts'), hasLength(1));
      await tester.tap(find.text('删除').last);
      await tester.pumpAndSettle();
      expect(c.data.rows('drafts'), isEmpty);
      await c.act('tab', {'index': 1});
      await tester.pumpAndSettle();
      expect(find.text('确认发送'), findsNothing);
      expect(b.calls, isNot(contains('confirmChatSend')));
    },
  );
}
