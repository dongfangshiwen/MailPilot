import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('citation selection and return on API36', (tester) async {
    final source = {
      'id': 'T5:S2',
      'kind': 'answer',
      'title': '引用资料示例',
      'text': '## 资料核对\n\n```text\n编号 12345\n日期 2026-09-11\n金额 500 元\n```\n\n确认范围：仅供测试，未发送邮件。',
    };
    final b = PreviewBackend(
      initial: {
        ...previewState(),
        'selection': [],
        'entries': [
          {
            'id': 'a',
            'role': 'assistant',
            'text': '点击引述核对资料 [T5:S2]',
            'sources': [source],
          },
        ],
      },
    );
    final c = MailController(b, initial: b.data);
    await c.start();
    try {
      await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      final citation = find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('[T5:S2]'),
      );
      final paragraph = tester.renderObject<RenderParagraph>(citation.last);
      final index = paragraph.text.toPlainText().indexOf('[T5:S2]') + 3;
      await tester.tapAt(
        paragraph.localToGlobal(
          paragraph.getOffsetForCaret(TextPosition(offset: index), Rect.zero) +
              const Offset(3, 9),
        ),
      );
      await tester.pumpAndSettle();
      for (final dark in [false, true]) {
        await c.act('theme', {'value': dark ? 'dark' : 'light'});
        await tester.pumpAndSettle();
        await tester.longPress(
          find.textContaining('编号 12345', findRichText: true).last,
        );
        await tester.pumpAndSettle();
        tester
            .state<SelectableRegionState>(find.byType(SelectableRegion))
            .selectAll();
        await tester.pumpAndSettle();
        expect(
          tester
              .state<SelectableRegionState>(find.byType(SelectableRegion))
              .selectionEndpoints,
          hasLength(2),
        );
        await binding.takeScreenshot(
          'citation-selection-${dark ? 'dark' : 'light'}',
        );
        expect(tester.takeException(), isNull);
      }
      await c.back();
      await tester.pumpAndSettle();
      expect(find.textContaining('点击引述核对资料', findRichText: true), findsWidgets);
      await c.act('showSource', {
        'source': {
          ...source,
          'kind': 'mail',
          'title': '通知邮件（示例）',
          'text': '    您的资料已生成。\n\n    日期：2026年9月11日\n\n    金额：500元\n\n    查看资料：https://example.org/document/12345\n\n如有疑问，请联系资料提供方。',
        },
      });
      for (final dark in [false, true]) {
        await c.act('theme', {'value': dark ? 'dark' : 'light'});
        await tester.pumpAndSettle();
        tester
            .state<EditableTextState>(find.byType(EditableText))
            .selectAll(SelectionChangedCause.toolbar);
        await tester.pumpAndSettle();
        await binding.takeScreenshot(
          'mail-selection-${dark ? 'dark' : 'light'}',
        );
        expect(find.byTooltip('查看原文'), findsNothing);
        expect(tester.takeException(), isNull);
      }
    } finally {
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    }
  });
}
