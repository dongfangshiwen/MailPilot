import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';
import 'package:mailpilot/service_form.dart';

void main() {
  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.6, 2.0]) {
      for (final dark in [false, true]) {
        testWidgets('1.8 toolbar and drawer $width dark=$dark at $scale font', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 850);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final b = PreviewBackend(
            initial: {
              ...previewState(),
              'settings': {
                ...previewState().child('settings'),
                'theme': dark ? 'dark' : 'light',
              },
              'searchConfig': {'hasSecret': true},
            },
          );
          final c = MailController(b, initial: b.data);
          await c.start();
          await tester.pumpWidget(
            MailPilotApp(controller: c, autoStart: false),
          );
          await tester.pumpAndSettle();
          final plus = find.byTooltip('添加附件'),
              thinking = find.byTooltip('深度思考'),
              search = find.byTooltip('智能搜索');
          final at = tester.getTopLeft(plus);
          final thinkingPill = find.byKey(
            const ValueKey('composer-option-深度思考'),
          );
          final searchPill = find.byKey(const ValueKey('composer-option-智能搜索'));
          final pillSize = tester.getSize(thinkingPill);
          final searchPosition = tester.getTopLeft(searchPill);
          expect(tester.getSize(thinking).height, greaterThanOrEqualTo(48));
          await tester.tap(thinking);
          await tester.tap(search);
          await tester.pumpAndSettle();
          expect(tester.getTopLeft(plus), at);
          expect(tester.getSize(thinkingPill), pillSize);
          expect(tester.getTopLeft(searchPill), searchPosition);
          if (width >= 360 && scale == 1) {
            expect(find.text('深度思考'), findsOneWidget);
            expect(find.text('智能搜索'), findsOneWidget);
          }
          final microphone = find.byTooltip('语音输入');
          final micPosition = tester.getTopLeft(microphone);
          for (final key in ['composer-add-disc', 'composer-voice-disc']) {
            expect(
              tester.getSize(find.byKey(ValueKey(key))),
              const Size(28, 28),
            );
          }
          expect(tester.getSize(plus), tester.getSize(microphone));
          expect(find.byTooltip('发送问题'), findsNothing);
          await tester.enterText(find.byType(TextField), '帮我起草回复');
          await tester.pumpAndSettle();
          final send = find.byTooltip('发送问题');
          expect(microphone, findsNothing);
          expect(tester.getTopLeft(send), micPosition);
          expect(tester.getTopLeft(plus), at);
          expect(tester.getCenter(plus).dy, tester.getCenter(send).dy);
          expect(tester.getSize(send), const Size(48, 48));
          expect(
            tester.getSize(find.byKey(const ValueKey('composer-send-disc'))),
            const Size(28, 28),
          );
          expect(tester.takeException(), isNull);
          await tester.enterText(find.byType(TextField), '   ');
          await tester.pumpAndSettle();
          expect(send, findsNothing);
          expect(tester.getTopLeft(microphone), micPosition);
          await tester.longPress(search);
          await tester.pumpAndSettle();
          expect(find.text('搜索与语音'), findsOneWidget);
          expect(find.byType(DropdownButtonFormField<String>), findsNothing);
          final address = find.widgetWithText(TextField, '完整搜索接口地址');
          await tester.enterText(address, 'https://custom.example/search');
          await tester.pumpAndSettle();
          await tester.tap(find.text('搜索服务商'));
          await tester.pumpAndSettle();
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(
            tester.widget<TextField>(address).controller!.text,
            'https://custom.example/search',
          );
          await tester.tap(find.widgetWithText(TextButton, '语音输入'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('识别方式'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('千问云端识别'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(TextButton, '联网搜索'));
          await tester.pumpAndSettle();
          expect(
            tester.widget<TextField>(address).controller!.text,
            'https://custom.example/search',
          );
          tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          tester.view.resetViewInsets();
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('关闭配置'));
          await tester.pumpAndSettle();
          expect(find.byType(ServiceDrawer), findsNothing);
          expect(b.calls, isNot(contains('testService')));
          await tester.pumpWidget(const SizedBox());
          c.dispose();
        });
      }
    }
  }
  testWidgets('failed visual answer has matching action and cannot draft', (
    tester,
  ) async {
    final b = PreviewBackend(
      initial: {
        ...previewState(),
        'entries': [
          {
            'id': 'failure',
            'role': 'assistant',
            'text': '回答未完成：图片不支持',
            'resultStatus': 'failed',
            'failure': {'action': 'vision_helper', 'type': 'image_unsupported'},
          },
        ],
      },
    );
    final c = MailController(b, initial: b.data);
    await c.start();
    await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
    await tester.pumpAndSettle();
    expect(find.text('写成邮件'), findsNothing);
    expect(find.text('选择视觉助手'), findsOneWidget);
    expect(find.textContaining('恢复默认思考'), findsNothing);
    await tester.tap(find.text('重试本轮'));
    await tester.pumpAndSettle();
    expect(b.calls, contains('retryAnalysis'));
    expect(b.calls, isNot(contains('newConversation')));
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
