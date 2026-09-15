import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/forms.dart';
import 'package:mailpilot/main.dart';

import '../test/context22_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('context auto/custom drawer retains model settings on API 36', (
    tester,
  ) async {
    final backend = Context22Backend();
    final c = MailController(backend, initial: backend.data);
    await c.start();
    Future<void> capture(String name) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
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
      Navigator.of(tester.element(find.byType(TextField))).push(
        MaterialPageRoute<void>(
          builder: (_) => ModelForm(c, initial: context22Model),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('高级参数'));
      await tester.tap(find.text('高级参数'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('model-context-info')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('当前上下文：1048576'), findsOneWidget);
      await capture('context-auto-light');
      final mode = find.byKey(const ValueKey('model-setting-context-mode'));
      await tester.ensureVisible(mode);
      await tester.tap(mode);
      await tester.pumpAndSettle();
      await capture('context-options');
      await tester.tap(find.byKey(const ValueKey('model-choice-custom')));
      await tester.pumpAndSettle();
      final input = find.byKey(const ValueKey('model-field-contextTokens'));
      await tester.ensureVisible(input);
      await tester.enterText(input, '65536');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      FocusManager.instance.primaryFocus?.unfocus();
      await c.act('theme', {'value': 'dark'});
      await tester.pumpAndSettle();
      await tester.ensureVisible(input);
      await tester.pumpAndSettle();
      await capture('context-custom-dark');
      await tester.tap(find.text('保存模型'));
      await tester.pumpAndSettle();
      expect(backend.saved?['contextMode'], 'custom');
      expect(backend.saved?['contextTokens'], 65536);
      expect(backend.saved?['outputTokens'], 4096);
      expect(backend.diagnostics, 0);
      expect(tester.takeException(), isNull);
      await c.act('theme', {'value': 'light'});
      Navigator.of(tester.element(find.byType(TextField)))
          .push(MaterialPageRoute<void>(builder: (_) => AccountForm(c)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('阿里企业邮箱'));
      await tester.pumpAndSettle();
      await capture('mail-setup-light');
      final guide = find.byKey(const ValueKey('mail-setup-guide'));
      await tester.ensureVisible(guide);
      await tester.tap(guide);
      await tester.pumpAndSettle();
      await capture('mail-guide-light');
      await tester.drag(
        find.byKey(const ValueKey('mail-guide-scroll')),
        const Offset(0, -350),
      );
      await tester.pumpAndSettle();
      await capture('mail-guide-links-light');
      await tester.tap(find.byTooltip('关闭配置指引'));
      await c.act('theme', {'value': 'dark'});
      await tester.pumpAndSettle();
      await tester.tap(guide);
      await tester.pumpAndSettle();
      await capture('mail-guide-dark');
      await tester.tap(find.text('返回填写'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    }
  });
}
