import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:mailpilot/chat_composer.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/markdown_reply.dart';
import 'package:mailpilot/preview_data.dart';

const sourceMarkdown =
    '```markdown\n## 会议安排\n\n**请确认出席**\n\n'
    '| 时间 | 地点 |\n| --- | --- |\n| 周五 | 会议室 |\n\n'
    '![外部图片](https://example.com/tracker.png)\n```';

void main() {
  test('reading wrapper only unwraps explicit Markdown and preserves code', () {
    expect(readingMarkdown(sourceMarkdown), startsWith('## 会议安排'));
    const code = '```dart\nfinal value = "**literal**";\n```';
    expect(readingMarkdown(code), code);
  });
  testWidgets(
    'saved summary does not occupy composer space and opens only in menu',
    (tester) async {
      final b = PreviewBackend();
      final c = MailController(b, initial: b.data);
      await c.start();
      addTearDown(c.dispose);
      await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
      await tester.pumpAndSettle();
      final before = tester.getRect(find.byType(ChatComposer));
      b.data = {
        ...b.data,
        'contextSummary': '## 已确认\n\n**周五交付**',
        'summarizedEntries': 12,
      };
      b.publish();
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(ChatComposer)), before);
      expect(find.textContaining('已整理'), findsNothing);
      await tester.tap(find.byTooltip('打开菜单'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('对话摘要'));
      await tester.pumpAndSettle();
      expect(find.text('已整理 12 条较早消息'), findsOneWidget);
      expect(find.text('周五交付', findRichText: true), findsOneWidget);
      expect(
        b.calls.where((v) => v == 'analyze' || v == 'sourceInfo'),
        isEmpty,
      );
      await c.act('newConversation');
      await tester.pumpAndSettle();
      expect(find.text('周五交付', findRichText: true), findsNothing);
      expect(find.text('当前对话暂无摘要。'), findsOneWidget);
      b.data = {
        ...b.data,
        'conversationId': 'another',
        'contextSummary': '另一个对话的内容',
      };
      b.publish();
      await tester.pumpAndSettle();
      expect(find.text('对话已切换，请重新打开摘要。'), findsOneWidget);
      expect(find.text('另一个对话的内容'), findsNothing);
    },
  );
  for (final width in [320.0, 360.0, 412.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'citation renders Markdown and raw mode stays local $width $dark',
        (tester) async {
          tester.view.physicalSize = Size(width, 850);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = width == 320
              ? 2
              : 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final source = {
            'id': 'T1:S1',
            'kind': 'answer',
            'title': '会议引述',
            'location': '聊天回答',
            'text': sourceMarkdown,
          };
          final b = PreviewBackend(
            initial: {
              ...previewState(),
              'entries': [
                {
                  'id': 'a',
                  'role': 'assistant',
                  'text': '会议请见 [T1:S1]',
                  'sources': [source],
                },
              ],
            },
          );
          final c = MailController(b, initial: b.data);
          await c.start();
          addTearDown(c.dispose);
          await c.act('theme', {'value': dark ? 'dark' : 'light'});
          await tester.pumpWidget(
            MailPilotApp(controller: c, autoStart: false),
          );
          await tester.pumpAndSettle();
          final link = tester.widget<MarkdownBody>(find.byType(MarkdownBody));
          link.onTapLink!('[T1:S1]', 'mailpilot-source:T1:S1', '');
          await tester.pumpAndSettle();
          expect(find.text('会议安排', findRichText: true), findsOneWidget);
          expect(find.byType(Table), findsOneWidget);
          expect(find.byType(Image), findsNothing);
          expect(find.textContaining('## 会议安排'), findsNothing);
          final requests = b.calls.where((v) => v == 'sourceInfo').length;
          await tester.tap(find.byTooltip('查看原文'));
          await tester.pumpAndSettle();
          expect(find.text(sourceMarkdown), findsOneWidget);
          await tester.tap(find.byTooltip('排版阅读'));
          await tester.pumpAndSettle();
          expect(b.calls.where((v) => v == 'sourceInfo'), hasLength(requests));
          expect(c.data.child('source').text('text'), sourceMarkdown);
          expect(
            b.calls.where(
              (v) => v == 'openLink' || v == 'imageBytes' || v == 'analyze',
            ),
            isEmpty,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
