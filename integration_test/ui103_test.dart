import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';

class RunBackend extends PreviewBackend {
  @override
  Future<dynamic> invoke(String method, [RowData args = const {}]) {
    if (method == 'retryAnalysis') {
      calls.add(method);
      return Future.value();
    }
    return super.invoke(method, args);
  }

  void setRun(RowData value) {
    data = {...data, ...value};
    events.add(data);
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('API 36 read-only draft, failure, diagnostics and manual retry', (
    tester,
  ) async {
    final b = RunBackend();
    final question = {'id': 'q', 'role': 'user', 'text': '将这条回答写成邮件'};
    const partial = {
      'subject': '确认参加周五会议',
      'body': '您好：\n\n感谢您的邀请，我确认参加本周五的会议。',
    };
    b.data = {
      ...previewState(),
      'selection': [],
      'entries': [question],
    };
    final c = MailController(b, initial: b.data);
    await c.start();
    Future<void> capture(String name) async {
      // Surface screenshots need a real compositor frame after theme/modal changes.
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
      b.setRun({
        'analyzing': true,
        'responseId': 'run',
        'draftPartial': partial,
        'agentStage': 'generating',
        'reasoning': {
          'text': '已核对用户提供的会议时间。',
          'state': 'completed',
          'elapsedMs': 2100,
        },
      });
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('正在起草 · 只读预览'), findsOneWidget);
      expect(find.text('确认发送'), findsNothing);
      await capture('agent103-drafting-light');
      b.setRun({
        'analyzing': false,
        'responseId': '',
        'draftPartial': {},
        'entries': [
          question,
          {
            'id': 'run',
            'role': 'assistant',
            'resultStatus': 'failed',
            'text': '接收模型数据时连接中断，已收到内容保留，请重试。',
            'reasoning': {
              'text': '已核对用户提供的会议时间。',
              'state': 'completed',
              'elapsedMs': 2100,
            },
            'failure': {
              'type': 'stream_interrupted',
              'draftPartial': partial,
              'diagnostics': {
                'stage': 'draft',
                'model': '本地流程样例',
                'host': 'localhost',
                'requestId': 'fixture103',
                'finishReason': '',
                'cause': 'IOException',
              },
            },
          },
        ],
      });
      await tester.pumpAndSettle();
      expect(find.text('未完成 · 不能发送'), findsOneWidget);
      expect(find.text('写成邮件'), findsNothing);
      await capture('agent103-partial-light');
      await c.act('theme', {'value': 'dark'});
      await tester.pumpAndSettle();
      await capture('agent103-partial-dark');
      await tester.ensureVisible(find.text('连接诊断'));
      await tester.tap(find.text('连接诊断'));
      await tester.pumpAndSettle();
      expect(find.text('localhost'), findsOneWidget);
      await capture('agent103-diagnostics');
      await tester.tap(find.text('技术详情'));
      await tester.pumpAndSettle();
      expect(find.text('IOException'), findsOneWidget);
      await capture('agent103-diagnostics-details');
      await tester.tap(find.byTooltip('关闭连接诊断'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('重试本轮'));
      await tester.tap(find.text('重试本轮'));
      await tester.pumpAndSettle();
      expect(b.calls.where((e) => e == 'retryAnalysis'), hasLength(1));
      expect(
        b.calls.where((e) => e == 'confirmChatSend' || e == 'sendConfirmed'),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    }
  });
}
