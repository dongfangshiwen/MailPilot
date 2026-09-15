import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/editor.dart';
import 'package:mailpilot/main.dart';

import 'attachment_fixture.dart';

Future<void> settlePreviewImage(WidgetTester tester) async {
  for (var i = 0; i < 20 && find.byType(Image).evaluate().isEmpty; i++) {
    await tester.pump();
  }
  final picture = tester.widget<Image>(find.byType(Image));
  // Image decoding runs outside the fake widget-test clock.
  await tester.runAsync(() async {
    final ready = Completer<void>();
    final stream = picture.image.resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (_, synchronous) => ready.complete(),
      onError: (error, stack) => ready.completeError(error, stack),
    );
    stream.addListener(listener);
    try {
      await ready.future.timeout(const Duration(seconds: 10));
    } finally {
      stream.removeListener(listener);
    }
  });
  await tester.pumpAndSettle();
  expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
}

void main() {
  for (final width in [320.0, 360.0, 412.0]) {
    for (final dark in [false, true]) {
      testWidgets('images are opt in; preview actions fit $width dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = width == 320
            ? 2
            : 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final b = AttachmentFixtureBackend(
          (await tester.runAsync(attachmentFixtureImage))!,
        );
        final c = MailController(b, initial: b.data);
        await c.start();
        addTearDown(c.dispose);
        await c.act('theme', {'value': dark ? 'dark' : 'light'});
        await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
        await c.act('openMessage', {'id': 'm1'});
        await tester.pumpAndSettle();
        expect(b.requested, isEmpty);
        expect(find.byType(Image), findsNothing);
        final tile = find.byKey(const ValueKey('attachment-photo1'));
        await tester.scrollUntilVisible(
          tile,
          260,
          scrollable: find
              .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        final checkbox = find.descendant(
          of: tile,
          matching: find.byType(Checkbox),
        );
        await Scrollable.ensureVisible(tester.element(checkbox), alignment: .4);
        await tester.pumpAndSettle();
        await tester.tap(checkbox);
        await tester.pumpAndSettle();
        expect(b.requested, isEmpty);
        await tester.tap(find.text('项目现场图片.png'));
        await settlePreviewImage(tester);
        expect(b.requested, ['photo1']);
        expect(find.byType(Image), findsOneWidget);
        final open = find.byTooltip('使用其他应用打开'), save = find.byTooltip('保存到手机');
        expect(tester.getCenter(open).dy, tester.getCenter(save).dy);
        expect(tester.getSize(open).height, greaterThanOrEqualTo(48));
        await tester.tap(open);
        await tester.pumpAndSettle();
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(b.calls, containsAll(['openFile', 'exportFile']));
        expect(b.requested, ['photo1']);
        await c.back();
        await tester.pumpAndSettle();
        expect(find.byType(SourcePage), findsNothing);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('attachment-photo2')),
          260,
          scrollable: find
              .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('另一张尚未下载的图片.JPG'));
        await settlePreviewImage(tester);
        expect(b.requested, ['photo1', 'photo2']);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  testWidgets('failed preview retries only the same selected image', (
    tester,
  ) async {
    final b = AttachmentFixtureBackend(
      (await tester.runAsync(attachmentFixtureImage))!,
    )..failImage = true;
    final c = MailController(b, initial: b.data);
    await c.start();
    addTearDown(c.dispose);
    await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
    await c.act('openMessage', {'id': 'm1'});
    await c.act('preview', {'id': 'photo1'});
    await tester.pumpAndSettle();
    expect(find.text('重新加载'), findsOneWidget);
    expect(b.requested, ['photo1']);
    b.failImage = false;
    await tester.tap(find.text('重新加载'));
    await settlePreviewImage(tester);
    expect(b.requested, ['photo1', 'photo1']);
    expect(find.byType(Image), findsOneWidget);
    expect(find.textContaining('模拟断网'), findsNothing);
  });
  testWidgets('back during image loading does not reopen the preview', (
    tester,
  ) async {
    final pending = Completer<void>();
    final b = AttachmentFixtureBackend(
      (await tester.runAsync(attachmentFixtureImage))!,
    )..pending = pending.future;
    final c = MailController(b, initial: b.data);
    await c.start();
    addTearDown(c.dispose);
    await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
    await c.act('openMessage', {'id': 'm1'});
    await c.act('preview', {'id': 'photo1'});
    await tester.pump();
    await tester.pump();
    expect(find.text('正在加载引用资料…'), findsOneWidget);
    await c.back();
    await tester.pump();
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(SourcePage), findsNothing);
    expect(b.requested, ['photo1']);
    expect(b.calls, isNot(contains('imageBytes')));
    expect(tester.takeException(), isNull);
  });
}
