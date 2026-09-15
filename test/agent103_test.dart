import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/draft_streaming_preview.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';

class CapturingBackend extends MailBackend {
  final List<RowData> received = [];
  @override
  Stream<RowData> get states => const Stream.empty();
  @override
  Future<dynamic> invoke(String method, [RowData args = const {}]) async {
    received.add({'method': method, ...args});
  }
}

void main() {
  testWidgets('exhausted compression offers adjustments without a dead retry', (
    tester,
  ) async {
    final b = PreviewBackend();
    b.data = {
      ...previewState(),
      'tab': 1,
      'entries': [
        {'id': 'q', 'role': 'user', 'text': '继续'},
        {
          'id': 'a',
          'role': 'assistant',
          'resultStatus': 'failed',
          'text': '摘要仍超出实际可用空间',
          'failure': {
            'type': 'compression_too_long',
            'action': 'budget',
            'diagnostics': {
              'stage': 'compression',
              'inputBudget': 1000,
              'canResume': false,
            },
          },
        },
      ],
    };
    final c = MailController(b, initial: b.data);
    await tester.pumpWidget(
      MailPilotApp(controller: c, autoStart: false, preview: true),
    );
    await tester.pumpAndSettle();
    expect(find.text('继续整理'), findsNothing);
    expect(find.text('调整资料后重试'), findsOneWidget);
    expect(find.text('查看预算'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets('quick compression setting is opt in and updates preferences', (
    tester,
  ) async {
    final b = PreviewBackend();
    b.data = {...previewState(), 'tab': 3};
    final c = MailController(b, initial: b.data);
    await tester.pumpWidget(
      MailPilotApp(controller: c, autoStart: false, preview: true),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('上下文整理'),
      180,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('settings-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('上下文整理'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('上下文整理'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('快速整理（支持的接口使用非思考模式）'));
    await tester.pumpAndSettle();
    expect(b.data.child('settings').flag('fastCompression'), isTrue);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  test('all draft entry actions freeze the visible thinking switch', () async {
    final backend = CapturingBackend();
    final c = MailController(backend, initial: previewState());
    c.setChatOptions(thinking: 'disabled');
    await c.act('draftFromAnswer', {'id': 'answer'});
    c.setChatOptions(thinking: 'enabled');
    await c.act('redraft', {'id': 'draft'});
    expect(backend.received[0].child('options').text('thinking'), 'disabled');
    expect(backend.received[1].child('options').text('thinking'), 'enabled');
    c.dispose();
  });
  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.6, 2.0]) {
      for (final dark in [false, true]) {
        testWidgets(
          'partial preview $width $scale dark=$dark is readable and unsendable',
          (tester) async {
            tester.view.physicalSize = Size(width, 800);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? ThemeData.dark() : ThemeData.light(),
                home: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: Scaffold(
                    body: SingleChildScrollView(
                      child: DraftStreamingPreview(
                        partial: {
                          'subject': '确认周五会议 / Meeting confirmation',
                          'body': '您好，已收到会议邀请。\n\nFriday meeting confirmed.',
                        },
                        running: false,
                      ),
                    ),
                  ),
                ),
              ),
            );
            expect(find.text('未完成 · 不能发送'), findsOneWidget);
            expect(find.text('确认发送'), findsNothing);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
  testWidgets(
    'failed run retains partial, has retry and diagnostics, no draft action',
    (tester) async {
      final b = PreviewBackend();
      b.data = {
        ...previewState(),
        'selection': [],
        'entries': [
          {'id': 'q', 'role': 'user', 'text': '将这条回答写成邮件'},
          {
            'id': 'a',
            'role': 'assistant',
            'resultStatus': 'failed',
            'text': '接收模型数据时连接中断',
            'failure': {
              'draftPartial': {'subject': '会议', 'body': '您好，已收到邀请。'},
              'diagnostics': {
                'stage': 'draft',
                'model': 'fixture',
                'host': 'localhost',
              },
            },
          },
        ],
      };
      final c = MailController(b, initial: b.data);
      await tester.pumpWidget(
        MailPilotApp(controller: c, autoStart: false, preview: true),
      );
      await tester.pumpAndSettle();
      expect(find.text('未完成 · 不能发送'), findsOneWidget);
      expect(find.text('写成邮件'), findsNothing);
      expect(find.text('确认发送'), findsNothing);
      await tester.ensureVisible(find.text('连接诊断'));
      await tester.tap(find.text('连接诊断'));
      await tester.pumpAndSettle();
      expect(find.text('localhost'), findsOneWidget);
      expect(find.text('邮件起草'), findsOneWidget);
      expect(find.textContaining('API Key'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  for (final width in [320.0, 360.0, 412.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'diagnostics drawer $width dark=$dark handles large text and details',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? ThemeData.dark() : ThemeData.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(width == 320 ? 2 : 1)),
                child: child!,
              ),
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => showRunDiagnostics(context, {
                      'stage': 'draft',
                      'model': 'model-with-a-long-name-for-layout-verification',
                      'host': 'api.example.com',
                      'requestId':
                          'request-1234567890123456789012345678901234567890',
                      'cause': 'IOException',
                      'firstByteMs': 0,
                      'elapsedMs': 120001,
                      'estimatedInputTokens': 27541,
                      'inputBudget': 24576,
                      'contextTokens': 32768,
                      'outputReserve': 4096,
                      'thinkingReserve': 4096,
                      'body': 'private body',
                      'apiKey': 'private key',
                    }),
                    child: const Text('查看诊断'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('查看诊断'));
          await tester.pumpAndSettle();
          expect(tester.getSize(find.byType(BottomSheet)).width, width);
          expect(find.text('邮件起草'), findsOneWidget);
          expect(find.text('本轮预算与诊断'), findsOneWidget);
          expect(find.text('24576 Token'), findsOneWidget);
          await tester.ensureVisible(find.text('技术详情'));
          await tester.tap(find.text('技术详情'));
          await tester.pumpAndSettle();
          expect(find.text('IOException'), findsOneWidget);
          expect(find.textContaining('private'), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip('关闭连接诊断'));
          await tester.pumpAndSettle();
          expect(find.byType(BottomSheet), findsNothing);
        },
      );
    }
  }
}
