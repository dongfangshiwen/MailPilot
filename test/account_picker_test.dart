import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';

void main() {
  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'account sheet $width / $scale preserves same selection without sync',
        (tester) async {
          tester.view.physicalSize = Size(width, 820);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final b = PreviewBackend(
            initial: {
              ...previewState(),
              'activeAccount': 'one',
              'accounts': [
                {'id': 'one', 'email': 'personal@example.test'},
                {
                  'id': 'two',
                  'email': 'team@a-very-long-business-domain.example.test',
                },
              ],
              'settings': {
                ...previewState().child('settings'),
                'theme': scale == 2 ? 'dark' : 'light',
              },
            },
          );
          final c = MailController(b, initial: b.data);
          await c.start();
          await c.act('tab', {'index': 0});
          await tester.pumpWidget(
            MailPilotApp(controller: c, autoStart: false),
          );
          await tester.pumpAndSettle();
          b.calls.clear();
          await tester.tap(find.byTooltip('切换邮箱'));
          await tester.pumpAndSettle();
          expect(find.byType(BottomSheet), findsOneWidget);
          expect(find.byType(PopupMenuItem<String>), findsNothing);
          expect(
            find.text('@a-very-long-business-domain.example.test'),
            findsOneWidget,
          );
          expect(
            tester
                .getSize(find.byKey(const ValueKey('account-choice-one')))
                .height,
            greaterThanOrEqualTo(48),
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.byKey(const ValueKey('account-choice-one')));
          await tester.pumpAndSettle();
          expect(b.calls, isEmpty);
          await tester.tap(find.byTooltip('切换邮箱'));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('account-choice-two')));
          await tester.pumpAndSettle();
          expect(b.calls, ['account']);
          expect(find.byType(BottomSheet), findsNothing);
          await tester.pumpWidget(const SizedBox());
          c.dispose();
        },
      );
    }
  }
}
