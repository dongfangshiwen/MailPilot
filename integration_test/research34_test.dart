import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';
import 'package:mailpilot/reasoning_panel.dart';

class ResearchBackend extends PreviewBackend {
  @override
  Future<dynamic> invoke(String method, [RowData args = const {}]) {
    if (method == 'continueResearch') {
      calls.add(method);
      return Future.value();
    }
    return super.invoke(method, args);
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('API36 research timeline and explicit continuation', (
    tester,
  ) async {
    for (final theme in ['light', 'dark']) {
      final b = ResearchBackend();
      const thought = '已核对邮件中的公开技术主题，接下来搜索官方资料。';
      b.data = {
        ...previewState(),
        'tab': 1,
        'settings': {...previewState().child('settings'), 'theme': theme},
        'selection': [],
        'entries': [
          {'id': 'q34', 'role': 'user', 'text': '联网搜索邮件相关的内容'},
          {
            'id': 'a34',
            'role': 'assistant',
            'resultStatus': 'complete',
            'action': 'research_partial',
            'text': '已找到相关公开资料。USB-C 是接口形式，USB Power Delivery 是供电协议。\n\n具体兼容性仍需核对设备规格。',
            'reasoning': {
              'state': 'completed',
              'runComplete': true,
              'text': thought,
              'elapsedMs': 3000,
              'segments': [
                {
                  'id': 'r',
                  'start': 0,
                  'end': thought.length,
                  'order': 1,
                  'state': 'completed',
                },
              ],
              'activities': [
                {
                  'id': 's',
                  'kind': 'web_search',
                  'state': 'completed',
                  'count': 5,
                  'order': 2,
                  'domains': ['usb.org'],
                },
                {
                  'id': 'p',
                  'kind': 'read_web_page',
                  'state': 'completed',
                  'count': 2,
                  'order': 3,
                  'domains': ['usb.org'],
                },
              ],
            },
          },
        ],
      };
      final c = MailController(b, initial: b.data);
      await c.start();
      await tester.pumpWidget(
        MailPilotApp(
          key: ValueKey(theme),
          controller: c,
          autoStart: false,
          preview: true,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: find.byType(ReasoningPanel),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.text('搜索到 5 条结果'), findsOneWidget);
      expect(find.text('已读取 2 个网页'), findsOneWidget);
      expect(find.text('回到思考末尾'), findsNothing);
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await binding.takeScreenshot('research-$theme');
      await tester.ensureVisible(find.text('继续检索'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('继续检索'));
      await tester.pump();
      expect(b.calls, contains('continueResearch'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    }
  });
}
