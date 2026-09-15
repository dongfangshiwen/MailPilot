import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mailpilot/app_language.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/forms.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'native preference persists and rejects unsupported language on API36',
    (tester) async {
      final native = AndroidBackend();
      Future<RowData> snapshot() async =>
          row(jsonDecode(await native.invoke('snapshot') as String));
      final before = await snapshot();
      final original = AppLanguage.fromCode(
        before.child('settings').text('appLanguage'),
      ).code;
      try {
        for (final language in AppLanguage.values) {
          await native.invoke('appLanguage', {'value': language.code});
          RowData current = {};
          for (var i = 0; i < 30; i++) {
            current = await snapshot();
            if (current.child('settings').text('appLanguage') == language.code) {
              break;
            }
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
          expect(current.child('settings').text('appLanguage'), language.code);
          for (final key in [
            'accountId',
            'textModelId',
            'visionModelId',
            'theme',
            'syncMinutes',
            'fastCompression',
          ]) {
            expect(
              current.child('settings')[key],
              before.child('settings')[key],
              reason: key,
            );
          }
        }
        await expectLater(
          native.invoke('appLanguage', {'value': 'unsupported'}),
          throwsA(isA<PlatformException>()),
        );
        final reopened = AndroidBackend();
        final loaded = row(
          jsonDecode(await reopened.invoke('snapshot') as String),
        );
        expect(loaded.child('settings').text('appLanguage'), 'de');
        reopened.dispose();
      } finally {
        await native.invoke('appLanguage', {'value': original});
        native.dispose();
      }
    },
  );

  testWidgets('eight language settings and picker on API36', (tester) async {
    final b = PreviewBackend(initial: previewState(tab: 3));
    final c = MailController(b, initial: b.data);
    await c.start();
    await c.act('tab', {'index': 3});
    try {
      await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      for (final language in AppLanguage.values) {
        await c.request('appLanguage', {'value': language.code});
        c.applyAppLanguage(language.code);
        await c.act('theme', {
          'value': language == AppLanguage.german ? 'dark' : 'light',
        });
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(SettingsPage));
        final label = strings(context).appLanguage;
        final list = find.descendant(
          of: find.byKey(const PageStorageKey('settings-list')),
          matching: find.byType(Scrollable),
        );
        tester.state<ScrollableState>(list).position.jumpTo(0);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text(label), 160, scrollable: list);
        await tester.ensureVisible(find.text(label));
        await tester.pumpAndSettle();
        await binding.takeScreenshot('language-${language.code}-settings');
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(find.text(language.nativeName), findsWidgets);
        if (language == AppLanguage.english) {
          await binding.takeScreenshot('language-picker-en');
        }
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(
        b.calls.where(
          (method) => [
            'analyze',
            'confirmChatSend',
            'saveModel',
            'saveAccount',
          ].contains(method),
        ),
        isEmpty,
      );
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    }
  });
}
