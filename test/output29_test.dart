import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/forms.dart';
import 'package:mailpilot/main.dart';

import 'context22_fixture.dart';

void main() {
  const profiles = [
    (
      'volcengine',
      'https://ark.cn-beijing.volces.com/api/v3',
      'doubao-seed-evolving',
      262144,
    ),
    (
      'aliyun',
      'https://dashscope.aliyuncs.com/compatible-mode/v1',
      'qwen3.8-max',
      131072,
    ),
    (
      'deepseek',
      'https://api.deepseek.com/v1',
      'deepseek-v4-flash-vision-exp',
      384000,
    ),
  ];
  for (var i = 0; i < 3; i++) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.6, 2.0]) {
        final p = profiles[i], width = [320.0, 360.0, 412.0][i];
        testWidgets('automatic output ${p.$1} $width $scale dark=$dark', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final b = Context22Backend(theme: dark ? 'dark' : 'light');
          final model = {
            ...context22Model,
            'provider': p.$1,
            'baseUrl': p.$2,
            'model': p.$3,
            'outputMode': 'auto',
            'outputTokens': p.$4,
          };
          b.data['modelCatalog'] = [
            {
              ...context22Catalog.first,
              'provider': p.$1,
              'model': p.$3,
              'maxOutputTokens': p.$4,
            },
          ];
          final c = MailController(b, initial: b.data);
          await c.start();
          await tester.pumpWidget(
            MailPilotApp(controller: c, autoStart: false),
          );
          await tester.pumpAndSettle();
          Navigator.of(tester.element(find.byType(TextField))).push(
            MaterialPageRoute<void>(
              builder: (_) => ModelForm(c, initial: model),
            ),
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('高级参数'));
          await tester.tap(find.text('高级参数'));
          await tester.pumpAndSettle();
          final info = find.byKey(const ValueKey('model-output-info'));
          await tester.ensureVisible(info);
          expect(find.textContaining('型号最大输出：${p.$4} Token'), findsOneWidget);
          expect(
            find.byKey(const ValueKey('model-field-outputTokens')),
            findsNothing,
          );
          final mode = find.byKey(const ValueKey('model-setting-output-mode'));
          await tester.ensureVisible(mode);
          await tester.tap(mode);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('model-choice-custom')));
          await tester.pumpAndSettle();
          final field = find.byKey(const ValueKey('model-field-outputTokens'));
          await tester.ensureVisible(field);
          await tester.enterText(field, '4096');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.ensureVisible(mode);
          await tester.tap(mode);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('model-choice-auto')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('保存模型'));
          await tester.pumpAndSettle();
          expect(b.saved?['outputMode'], 'auto');
          expect(b.saved?['outputTokens'], 0);
          expect(b.diagnostics, 0);
          expect(tester.takeException(), isNull);
          c.dispose();
        });
      }
    }
  }
}
