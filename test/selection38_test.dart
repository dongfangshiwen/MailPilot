import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/markdown_reply.dart';
import 'package:mailpilot/preview_data.dart';

void main() {
  for (final dark in [false, true]) {
    for (final width in [320.0, 360.0, 412.0]) {
      testWidgets('citation selection remains visible $dark $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 840);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final b = PreviewBackend();
        final c = MailController(b, initial: b.data);
        addTearDown(c.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: mailTheme(dark),
            home: Scaffold(
              body: SingleChildScrollView(
                child: MarkdownReply(
                  controller: c,
                  text: '引用资料\n\n```text\n日期 2026-09-11\n金额 500 元\n```\n\n行内 `编号 12345`',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        tester
            .state<SelectableRegionState>(find.byType(SelectableRegion))
            .selectAll();
        await tester.pumpAndSettle();
        final paragraphs = tester.renderObjectList<RenderParagraph>(
          find.descendant(
            of: find.byType(MarkdownReply),
            matching: find.byType(RichText),
          ),
        );
        void check(InlineSpan span) {
          expect(span.style?.backgroundColor, isNull, reason: '文字背景不能覆盖选区');
          if (span is TextSpan) {
            for (final child in span.children ?? <InlineSpan>[]) {
              check(child);
            }
          }
        }

        for (final p in paragraphs) {
          expect(p.selectionColor?.a, greaterThan(.2));
          check(p.text);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('mail citation keeps indentation as wrapping plain text', (
    tester,
  ) async {
    final b = PreviewBackend();
    final c = MailController(b, initial: b.data);
    addTearDown(c.dispose);
    await c.start();
    await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
    await c.act('showSource', {
      'source': {
        'id': 'T5:S2',
        'kind': 'mail',
        'title': '通知邮件',
        'text':
            '    日期 2026-09-11\n    金额 500 元\n链接 https://example.org/document',
      },
    });
    await tester.pumpAndSettle();
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.byType(MarkdownReply), findsNothing);
    expect(find.byTooltip('查看原文'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
