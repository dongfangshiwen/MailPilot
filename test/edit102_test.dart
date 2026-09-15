import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';

void main() {
  for (final width in [320.0, 360.0, 412.0]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.6, 2.0]) {
        testWidgets('edit and cancel $width $dark $scale', (tester) async {
          tester.view.physicalSize = Size(width, 860);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final b = PreviewBackend();
          b.data = {
            ...b.data,
            'tab': 1,
            'entries': [
              {
                'id': 'q1',
                'role': 'user',
                'text': '请帮我回复这封邮件',
                'canEdit': true,
              },
              {'id': 'a1', 'role': 'assistant', 'text': '已整理回复内容。'},
            ],
            'selection': [],
          };
          final c = MailController(b, initial: b.data);
          await c.start();
          await c.act('theme', {'value': dark ? 'dark' : 'light'});
          addTearDown(c.dispose);
          await tester.pumpWidget(MailPilotApp(controller: c));
          await tester.pumpAndSettle();
          final field = find.byType(TextField).first;
          await tester.enterText(field, '尚未发送的输入');
          await tester.tap(find.byKey(const ValueKey('user-bubble-q1')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('修改输入'));
          await tester.pumpAndSettle();
          expect(find.text('修改输入'), findsOneWidget);
          expect(tester.widget<TextField>(field).controller!.text, '请帮我回复这封邮件');
          await tester.enterText(field, '请改成英文');
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip('取消修改'));
          await tester.pumpAndSettle();
          expect(tester.widget<TextField>(field).controller!.text, '尚未发送的输入');
          expect(b.calls.where((e) => e == 'editMessage'), isEmpty);
          expect(b.data.rows('entries').first.text('text'), '请帮我回复这封邮件');
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  testWidgets('edited send creates version and cancels without sending SMTP', (
    tester,
  ) async {
    final b = PreviewBackend();

    b.data = {
      ...b.data,
      'tab': 1,
      'entries': [
        {'id': 'q1', 'role': 'user', 'text': '原问题'},
        {'id': 'a1', 'role': 'assistant', 'text': '原回答'},
      ],
    };
    final c = MailController(b, initial: b.data);
    await c.start();
    addTearDown(c.dispose);
    await tester.pumpWidget(MailPilotApp(controller: c));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('user-bubble-q1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('修改输入'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '改写的问题');
    await tester.tap(find.byTooltip('发送问题'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 25));
    await tester.pumpAndSettle();
    expect(b.calls.where((e) => e == 'editMessage'), hasLength(1));
    expect(b.calls.where((e) => e == 'confirmChatSend'), isEmpty);
    expect(b.data.rows('entries').first.text('text'), '改写的问题');
    expect(find.byTooltip('取消修改'), findsNothing);
    tester.widget<ListView>(find.byType(ListView).first).controller!.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('2 / 2'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('上一版本'));
    await tester.pumpAndSettle();
    expect(find.text('原问题'), findsOneWidget);
    expect(find.text('原回答'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
