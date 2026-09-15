import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mailpilot/chat_composer.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';

import '../test/scroll23_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'API 36 jump to latest preserves composer, keyboard and long history',
    (tester) async {
      final b = scroll23Fixture();
      final c = MailController(b, initial: b.data);
      await c.start();
      Future<void> capture(String name) async {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 450)),
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
        final list = find.byKey(const ValueKey('chat-message-list'));
        final scroll = tester.widget<ListView>(list).controller!;
        const jump = ValueKey('chat-scroll-to-latest');
        for (final theme in ['light', 'dark']) {
          await c.act('theme', {'value': theme});
          await tester.pumpAndSettle();
          scroll.jumpTo(0);
          await tester.pumpAndSettle();
          final composer = tester.getRect(find.byType(ChatComposer));
          expect(find.byKey(jump), findsOneWidget);
          await capture('scroll-history-$theme');
          await tester.tap(find.byKey(jump));
          await tester.pumpAndSettle();
          expect(scroll.position.extentAfter, lessThan(1));
          expect(find.byKey(jump), findsNothing);
          expect(tester.getRect(find.byType(ChatComposer)), composer);
          expect(tester.view.viewInsets.bottom, 0);
          await capture('scroll-latest-$theme');
        }
        await tester.tap(find.byType(TextField));
        await tester.enterText(find.byType(TextField), '保留正在输入的内容');
        // Android's keyboard is a separate process; Flutter can settle before
        // its inset notification arrives on a cold emulator.
        for (
          var attempt = 0;
          attempt < 25 && tester.view.viewInsets.bottom == 0;
          attempt++
        ) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        await tester.pumpAndSettle();
        expect(tester.view.viewInsets.bottom, greaterThan(0));
        scroll.jumpTo(0);
        await tester.pumpAndSettle();
        await capture('scroll-with-keyboard');
        await tester.tap(find.byKey(jump));
        await tester.pumpAndSettle();
        expect(scroll.position.extentAfter, lessThan(1));
        expect(tester.view.viewInsets.bottom, greaterThan(0));
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '保留正在输入的内容',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        expect(
          b.calls.where(
            (v) =>
                v == 'analyze' || v == 'confirmChatSend' || v == 'sourceInfo',
          ),
          isEmpty,
        );
        expect(c.data.rows('entries'), hasLength(80));
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      }
    },
  );
}
