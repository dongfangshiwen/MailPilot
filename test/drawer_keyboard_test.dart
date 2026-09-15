import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';

void main() {
  for (final hideFirst in [false, true]) {
    for (final close in ['outside', 'back', 'close-button', 'swipe']) {
      testWidgets('drawer $close does not refocus input; hidden=$hideFirst', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(412, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final backend = PreviewBackend();
        final c = MailController(backend, initial: backend.data);
        await c.start();
        addTearDown(c.dispose);
        await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
        await tester.pumpAndSettle();
        final input = find.byType(TextField);
        await tester.enterText(input, '保留这段尚未发送的内容');
        await tester.pumpAndSettle();
        final editable = tester.widget<EditableText>(find.byType(EditableText));
        expect(editable.focusNode.hasFocus, isTrue);
        if (hideFirst) {
          // Android back can hide the IME without releasing the text focus.
          tester.testTextInput.hide();
        }
        tester.testTextInput.log.clear();
        await tester.tap(find.byTooltip('打开菜单'));
        await tester.pumpAndSettle();
        final scaffold = tester.state<ScaffoldState>(
          find.byType(Scaffold).first,
        );
        expect(scaffold.isDrawerOpen, isTrue);
        switch (close) {
          case 'outside':
            await tester.tapAt(const Offset(398, 220));
          case 'back':
            await tester.binding.handlePopRoute();
          case 'close-button':
            await tester.tap(find.byTooltip('关闭侧栏'));
          case 'swipe':
            await tester.flingFrom(
              const Offset(280, 150),
              const Offset(-260, 0),
              1000,
            );
        }
        await tester.pumpAndSettle();
        expect(scaffold.isDrawerOpen, isFalse);
        expect(editable.focusNode.hasFocus, isFalse);
        expect(tester.testTextInput.isVisible, isFalse);
        expect(
          tester.testTextInput.log.where(
            (call) => call.method == 'TextInput.show',
          ),
          isEmpty,
        );
        expect(tester.widget<TextField>(input).controller!.text, '保留这段尚未发送的内容');
        await tester.tap(input);
        await tester.pumpAndSettle();
        expect(editable.focusNode.hasFocus, isTrue);
        expect(tester.testTextInput.isVisible, isTrue);
        expect(backend.calls, isNot(contains('analyze')));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
