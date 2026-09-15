import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/forms.dart';
import 'package:mailpilot/main.dart';

import 'context22_fixture.dart';

void main() {
  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.6, 2.0]) {
      for (final dark in [false, true]) {
        testWidgets('context auto/custom $width $scale $dark', (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final backend = Context22Backend(theme: dark ? 'dark' : 'light');
          final c = MailController(backend, initial: backend.data);
          await c.start();
          await tester.pumpWidget(
            MailPilotApp(controller: c, autoStart: false),
          );
          await tester.pumpAndSettle();
          Navigator.of(tester.element(find.byType(TextField))).push(
            MaterialPageRoute<void>(
              builder: (_) => ModelForm(c, initial: context22Model),
            ),
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('高级参数'));
          await tester.tap(find.text('高级参数'));
          await tester.pumpAndSettle();
          final info = find.byKey(const ValueKey('model-context-info'));
          await tester.ensureVisible(info);
          expect(find.textContaining('当前上下文：1048576'), findsOneWidget);
          expect(
            find.byKey(const ValueKey('model-field-contextTokens')),
            findsNothing,
          );
          final mode = find.byKey(const ValueKey('model-setting-context-mode'));
          await tester.ensureVisible(mode);
          await tester.tap(mode);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('model-choice-custom')));
          await tester.pumpAndSettle();
          final input = find.byKey(const ValueKey('model-field-contextTokens'));
          await tester.ensureVisible(input);
          await tester.enterText(input, '65536');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();
          await tester.tap(find.text('保存模型'));
          await tester.pumpAndSettle();
          expect(backend.saved?['contextTokens'], 65536);
          expect(backend.saved?['contextMode'], 'custom');
          expect(backend.saved?['outputTokens'], 4096);
          expect(backend.diagnostics, 0);
          expect(tester.takeException(), isNull);
          c.dispose();
        });
      }
    }
  }
}
