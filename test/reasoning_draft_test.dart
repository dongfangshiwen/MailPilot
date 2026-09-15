import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';
import 'package:mailpilot/reasoning_panel.dart';

void main() {
  Future<(MailController, PreviewBackend)> mount(WidgetTester tester) async {
    final b = PreviewBackend();
    final c = MailController(b, initial: b.data);
    await c.start();
    await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
    await tester.pumpAndSettle();
    addTearDown(c.dispose);
    return (c, b);
  }

  testWidgets(
    'reasoning streams and preserves a manually expanded view on completion',
    (tester) async {
      Future<void> show(String state, String text) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReasoningPanel(
                key: const ValueKey('reply'),
                reasoning: {'text': text, 'state': state, 'elapsedMs': 2400},
              ),
            ),
          ),
        );
        await tester.pump();
      }

      await show('thinking', '真实接口返回的思考片段');
      expect(find.byType(SelectableText), findsOneWidget);
      // A short thought must not reserve a quarter-screen of empty space.
      expect(
        tester.getSize(find.byKey(const ValueKey('reasoning-body'))).height,
        lessThan(70),
      );
      await tester.tap(find.byType(InkWell));
      await show('thinking', '真实接口返回的思考片段，继续');
      expect(find.byType(SelectableText), findsNothing);
      await tester.tap(find.byType(InkWell));
      await show('completed', '真实接口返回的思考片段，继续');
      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.text('已思考 · 2 秒'), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('stopped historical reasoning is collapsed and fits large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReasoningPanel(
            reasoning: {
              'text': '中英文 thought '.padRight(1500, '思考'),
              'state': 'stopped',
              'elapsedMs': 12000,
              'truncated': true,
            },
          ),
        ),
      ),
    );
    expect(find.byType(SelectableText), findsNothing);
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.byType(SelectableText), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notices and sync progress float without moving the page', (
    tester,
  ) async {
    final (_, b) = await mount(tester);
    final before = tester.getTopLeft(find.byType(AppBar));
    expect(b.calls, isNot(contains('refresh')));
    b.data = {...b.data, 'busy': true, 'status': '正在同步邮件'};
    b.publish();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SnackBar), findsOneWidget);
    expect(tester.getTopLeft(find.byType(AppBar)), before);
    b.data = {
      ...b.data,
      'busy': false,
      'status': '',
      'notice': '草稿已保存',
      'error': '保留的错误',
    };
    b.publish();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(b.data['notice'], isNull);
    expect(b.data['error'], '保留的错误');
    expect(find.text('草稿已保存'), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('草稿已保存'), findsNothing);
    b.data = {...b.data, 'notice': '草稿已保存'};
    b.publish();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('草稿已保存'), findsOneWidget);
  });

  testWidgets(
    'AI answer to email allows recipient editing and explicit send preview',
    (tester) async {
      final (c, b) = await mount(tester);
      b.data = {
        ...b.data,
        'entries': [
          {
            'id': 'answer',
            'role': 'assistant',
            'text': '# 回复\n\n您好，**已收到**。',
            'sources': [],
          },
        ],
      };
      b.publish();
      await tester.pumpAndSettle();
      await tester.tap(find.text('写成邮件'));
      await tester.pumpAndSettle();
      expect(
        c.data
            .rows('entries')
            .where((e) => e.text('action') == 'draft_answer')
            .single
            .text('text'),
        '将这条回答写成邮件',
      );
      expect(c.data.rows('drafts').last.text('body'), '回复\n\n您好，已收到。');
      await tester.tap(find.text('编辑邮件'));
      await tester.pumpAndSettle();
      final recipient = find.widgetWithText(TextField, '收件人');
      await tester.enterText(recipient, 'other@example.test');
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      await tester.tap(find.text('在聊天中确认发送'));
      await tester.pumpAndSettle();
      expect(find.text('收件人：other@example.test'), findsOneWidget);
      expect(find.text('回复\n\n您好，已收到。'), findsOneWidget);
      expect(b.calls, isNot(contains('confirmChatSend')));
      await tester.tap(find.text('确认发送'));
      await tester.pumpAndSettle();
      expect(b.calls.where((e) => e == 'confirmChatSend').length, 1);
    },
  );

  testWidgets('existing markdown drafts convert only on request', (
    tester,
  ) async {
    final (c, b) = await mount(tester);
    await c.act('newDraft');
    await tester.pumpAndSettle();
    final editor = {
      ...b.data.child('editor'),
      'id': 'legacy',
      'body': '## 标题\n\n**内容**',
    };
    b.data = {...b.data, 'editor': editor};
    b.publish();
    await tester.pumpAndSettle();
    expect(c.data.child('editor').text('body'), contains('**'));
    await tester.tap(find.byTooltip('更多邮件操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('将 Markdown 转为正文'));
    await tester.pumpAndSettle();
    expect(c.data.child('editor').text('body'), '标题\n\n内容');
    expect(b.calls, isNot(contains('confirmChatSend')));
  });

  testWidgets('long attachment names stay compact with stable selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (c, b) = await mount(tester);
    await c.act('openMessage', {'id': 'm1'});
    b.data = {
      ...b.data,
      'detailAttachments': [
        {'id': 'long', 'name': '非常长的项目方案文件名需要单行省略并保留完整名称.docx', 'size': 1024},
      ],
    };
    b.publish();
    await tester.pumpAndSettle();
    final tile = find.byKey(const ValueKey('attachment-long'));
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    final before = tester.getSize(tile);
    expect(before.height, lessThanOrEqualTo(112));
    await tester.tap(
      find.descendant(of: tile, matching: find.byType(Checkbox)),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(tile), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'folder picker loads independently and retains retry and unread filter',
    (tester) async {
      final (c, b) = await mount(tester);
      await c.act('tab', {'index': 0});
      await tester.pumpAndSettle();
      await tester.tap(find.text('收件箱 ▾'));
      await tester.pumpAndSettle();
      expect(b.calls, isNot(contains('loadFolders')));
      await tester.tap(find.byTooltip('刷新文件夹'));
      await tester.pumpAndSettle();
      expect(b.calls, contains('loadFolders'));
      expect(find.text('已发送'), findsOneWidget);
      expect(find.text('已删除'), findsOneWidget);
      expect(find.text('仅显示未读'), findsOneWidget);
      b.data = {...b.data, 'foldersError': '测试断网'};
      b.publish();
      await tester.pumpAndSettle();
      expect(find.textContaining('已保留本地列表'), findsOneWidget);
      expect(find.byTooltip('刷新文件夹'), findsOneWidget);
      await tester.tap(find.text('已发送'));
      await tester.pumpAndSettle();
      expect(c.data.text('folder'), 'Sent Messages');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'chat confirmation card is invalid after edit and fits narrow large text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final (c, b) = await mount(tester);
      await c.act('reply', {'id': 'm1'});
      await tester.pumpAndSettle();
      await c.act('reviewDraftInChat', c.data.child('editor'));
      await tester.pumpAndSettle();
      expect(find.text('确认发送'), findsOneWidget);
      expect(b.calls, isNot(contains('confirmChatSend')));
      b.data = {
        ...b.data,
        'drafts': [
          for (final d in b.data.rows('drafts'))
            {
              ...d,
              'revision': d.number('revision') + 1,
              'to': 'changed@example.test',
            },
        ],
      };
      b.publish();
      await tester.pumpAndSettle();
      expect(find.text('确认发送'), findsNothing);
      expect(find.text('收件人：lin@example.test'), findsOneWidget);
      expect(find.textContaining('此确认已失效'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
