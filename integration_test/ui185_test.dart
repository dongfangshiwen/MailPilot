import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('drawer return leaves Android IME closed until input is tapped', (
    tester,
  ) async {
    final backend = PreviewBackend();
    final c = MailController(backend, initial: backend.data);
    await c.start();
    await tester.pumpWidget(
      MailPilotApp(controller: c, autoStart: false, preview: true),
    );
    await tester.pumpAndSettle();
    // A cold-started emulator may still be attaching the app's input connection.
    await tester.pump(const Duration(seconds: 1));
    final input = find.byType(TextField);
    Future<void> expectKeyboard(bool visible) async {
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if ((tester.view.viewInsets.bottom > 0) == visible) break;
        if (visible && i % 10 == 9) await tester.tap(input);
      }
      await tester.pumpAndSettle();
      expect(tester.view.viewInsets.bottom > 0, visible);
    }

    for (final hideFirst in [false, true]) {
      for (final close in ['outside', 'back', 'close-button', 'swipe']) {
        await tester.tap(input);
        await tester.enterText(input, '这段内容返回后仍然保留');
        await expectKeyboard(true);
        if (hideFirst) {
          await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
          await expectKeyboard(false);
        }
        await tester.tap(find.byTooltip('打开菜单'));
        await tester.pumpAndSettle();
        final scaffold = tester.state<ScaffoldState>(
          find.byType(Scaffold).first,
        );
        expect(scaffold.isDrawerOpen, isTrue);
        final width =
            tester.view.physicalSize.width / tester.view.devicePixelRatio;
        switch (close) {
          case 'outside':
            await tester.tapAt(Offset(width - 8, 210));
          case 'back':
            await tester.binding.handlePopRoute();
          case 'close-button':
            await tester.tap(find.byTooltip('关闭侧栏'));
          case 'swipe':
            await tester.flingFrom(
              const Offset(270, 170),
              const Offset(-250, 0),
              1000,
            );
        }
        await expectKeyboard(false);
        expect(scaffold.isDrawerOpen, isFalse);
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .focusNode
              .hasFocus,
          isFalse,
        );
        expect(tester.widget<TextField>(input).controller!.text, '这段内容返回后仍然保留');
        debugPrint('IME closed, content retained: $close / hidden=$hideFirst');
      }
    }
    await tester.tap(input);
    await expectKeyboard(true);
    FocusManager.instance.primaryFocus?.unfocus();
    await expectKeyboard(false);
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('drawer-return-keyboard-closed-fixture');
    for (final dark in [false, true]) {
      await c.act('theme', {'value': dark ? 'dark' : 'light'});
      c.setChatOptions(thinking: 'enabled', search: true);
      final text = tester.widget<TextField>(input).controller!;
      text.text = '输入后，发送原位替换语音';
      await tester.pumpAndSettle();
      await binding.takeScreenshot(
        'composer-${dark ? 'dark' : 'light'}-fixture',
      );
      text.clear();
      await tester.pumpAndSettle();
      await binding.takeScreenshot(
        'composer-empty-${dark ? 'dark' : 'light'}-fixture',
      );
    }
    await c.act('tab', {'index': 3});
    await tester.pumpAndSettle();
    final version = find.byKey(const ValueKey('app-version-footer'));
    await tester.scrollUntilVisible(version, 300);
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(version).data,
      'MailPilot ${c.data.text('appVersion')}\n每次发送邮件，都由你确认。',
    );
    await binding.takeScreenshot('settings-version-fixture');
    expect(backend.calls, isNot(contains('analyze')));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
