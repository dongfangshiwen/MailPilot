import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';

import '../test/attachment_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('lighter composer and individual image attachment previews', (
    tester,
  ) async {
    final backend = AttachmentFixtureBackend(await attachmentFixtureImage());
    final c = MailController(backend, initial: backend.data);
    await c.start();
    await tester.pumpWidget(
      MailPilotApp(controller: c, autoStart: false, preview: true),
    );
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    for (final dark in [false, true]) {
      await c.act('theme', {'value': dark ? 'dark' : 'light'});
      c.setChatOptions(thinking: 'enabled', search: true);
      await tester.pumpAndSettle();
      for (final key in ['composer-add-disc', 'composer-voice-disc']) {
        expect(tester.getSize(find.byKey(ValueKey(key))), const Size(28, 28));
      }
      await binding.takeScreenshot(
        'composer-empty-${dark ? 'dark' : 'light'}-fixture',
      );
      await tester.enterText(find.byType(TextField), '帮我查看选中的图片附件');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.byTooltip('语音输入'), findsNothing);
      expect(
        tester.getSize(find.byKey(const ValueKey('composer-send-disc'))),
        const Size(28, 28),
      );
      await binding.takeScreenshot(
        'composer-${dark ? 'dark' : 'light'}-fixture',
      );
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      backend.requested.clear();
      await c.act('openMessage', {'id': 'm1'});
      await tester.pumpAndSettle();
      final tile = find.byKey(const ValueKey('attachment-photo1'));
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      // A short drag also gives the Android raster thread a settled scroll frame.
      await tester.drag(find.byType(ListView).last, const Offset(0, -180));
      await tester.pumpAndSettle();
      expect(backend.requested, isEmpty);
      await binding.takeScreenshot(
        'mail-images-${dark ? 'dark' : 'light'}-fixture',
      );
      await tester.tap(find.text('项目现场图片.png'));
      await tester.pumpAndSettle();
      expect(backend.requested, ['photo1']);
      expect(find.byType(Image), findsOneWidget);
      // Decode completes outside the widget frame; verify pixels, not just Image.
      for (var attempt = 0; attempt < 50; attempt++) {
        final raw = find.byType(RawImage);
        if (raw.evaluate().isNotEmpty &&
            tester.widget<RawImage>(raw).image != null) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      final open = find.byTooltip('使用其他应用打开'), save = find.byTooltip('保存到手机');
      expect(tester.getCenter(open).dy, tester.getCenter(save).dy);
      await binding.takeScreenshot(
        'image-preview-${dark ? 'dark' : 'light'}-fixture',
      );
      await tester.tap(open);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(backend.requested, ['photo1']);
      await c.back();
      await tester.pumpAndSettle();
      await c.back();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
