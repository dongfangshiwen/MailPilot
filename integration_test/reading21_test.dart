import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('summary menu and formatted source remain opt in on API 36', (
    tester,
  ) async {
    const text =
        '```markdown\n## 会议安排\n\n**请确认出席**\n\n| 时间 | 地点 |\n| --- | --- |\n| 周五 14:00 | 会议室 A |\n\n- 提前准备项目进度\n- 确认参会人员\n```';
    final source = {
      'id': 'T1:S1',
      'kind': 'answer',
      'title': '会议引述',
      'location': '聊天回答 · 样例',
      'text': text,
    };
    final b = PreviewBackend(
      initial: {
        ...previewState(),
        'selection': [],
        'contextSummary':
            '## 已确认事项\n\n- **周五交付**项目方案\n- 预算为 500 元\n\n## 待补充\n\n请确认最终收件人。',
        'summarizedEntries': 12,
        'entries': [
          {'id': 'q', 'role': 'user', 'text': '帮我整理一下会议安排'},
          {
            'id': 'a',
            'role': 'assistant',
            'text': '会议安排已整理，可点击来源查看完整内容。[T1:S1]',
            'sources': [source],
          },
        ],
      },
    );
    final c = MailController(b, initial: b.data);
    await c.start();
    Future<void> capture(String name) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
      await tester.pump();
      await binding.takeScreenshot(name);
    }

    try {
      await tester.pumpWidget(
        MailPilotApp(controller: c, autoStart: false, preview: true),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      expect(find.textContaining('已整理 12'), findsNothing);
      await capture('chat-clean-composer');
      await tester.tap(find.byTooltip('打开菜单'));
      await tester.pumpAndSettle();
      await capture('summary-menu');
      await tester.tap(find.text('对话摘要'));
      await tester.pumpAndSettle();
      expect(find.text('本次对话摘要'), findsOneWidget);
      await capture('summary-formatted');
      await tester.tap(find.byTooltip('关闭对话摘要'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 处来源'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('T1:S1 · 会议引述'));
      await tester.pumpAndSettle();
      expect(find.byType(Table), findsOneWidget);
      await capture('citation-formatted-light');
      await tester.tap(find.byTooltip('查看原文'));
      await tester.pumpAndSettle();
      expect(find.text(text), findsOneWidget);
      await capture('citation-original');
      await tester.tap(find.byTooltip('排版阅读'));
      await c.act('theme', {'value': 'dark'});
      await tester.pumpAndSettle();
      await capture('citation-formatted-dark');
      expect(b.calls.where((v) => v == 'sourceInfo'), hasLength(1));
      expect(b.calls.where((v) => v == 'analyze' || v == 'openLink'), isEmpty);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    }
  });
}
