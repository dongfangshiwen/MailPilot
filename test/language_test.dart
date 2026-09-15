import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/app_language.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/forms.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';

import 'chat_results42_test.dart' show resultsFixture, mountResults;

class LanguageBackend extends PreviewBackend {
  LanguageBackend() : super(initial: previewState(tab: 3));
  Completer<void>? pending;
  bool fail = false;
  @override
  Future<dynamic> invoke(String method, [RowData args = const {}]) async {
    if (method == 'appLanguage') {
      if (fail) throw StateError('Write failed');
      await pending?.future;
    }
    return super.invoke(method, args);
  }
}

void main() {
  test('every language has complete resources and matching placeholders', () {
    final base =
        jsonDecode(File('lib/l10n/app_zh.arb').readAsStringSync()) as Map;
    final keys = base.keys
        .where((key) => !(key as String).startsWith('@'))
        .toSet();
    for (final language in AppLanguage.values) {
      final values = jsonDecode(
        File('lib/l10n/app_${language.code}.arb').readAsStringSync(),
      ) as Map;
      expect(
        values.keys.where((key) => !(key as String).startsWith('@')).toSet(),
        keys,
        reason: language.code,
      );
      for (final key in keys) {
        expect(
          (values[key] as String).trim(),
          isNotEmpty,
          reason: '$language/$key',
        );
        final placeholders = RegExp(r'\{p\d+\}');
        expect(
          placeholders.allMatches(values[key]).map((m) => m[0]).toSet(),
          placeholders.allMatches(base[key]).map((m) => m[0]).toSet(),
          reason: '$language/$key',
        );
      }
    }
  });

  testWidgets(
    'first launch uses Simplified Chinese regardless of device language',
    (tester) async {
      tester.platformDispatcher.localeTestValue = const Locale('de');
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      final b = LanguageBackend();
      final c = MailController(b, initial: b.data);
      addTearDown(c.dispose);
      await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
      await tester.pumpAndSettle();
      expect(find.text('设置'), findsOneWidget);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
        const Locale('zh'),
      );
    },
  );

  for (final language in AppLanguage.values) {
    for (final width in [320.0, 360.0, 412.0]) {
      for (final scale in [1.0, 1.6, 2.0]) {
        testWidgets('settings and picker ${language.code} $width font $scale', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 844);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final b = LanguageBackend();
          b.data = {
            ...b.data,
            'settings': {
              ...b.data.child('settings'),
              'appLanguage': language.code,
              'theme': scale == 1.6 ? 'dark' : 'light',
            },
          };
          final c = MailController(b, initial: b.data);
          addTearDown(c.dispose);
          await tester.pumpWidget(
            MailPilotApp(controller: c, autoStart: false),
          );
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(SettingsPage));
          final label = strings(context).appLanguage;
          await tester.scrollUntilVisible(
            find.text(label),
            120,
            scrollable: find.descendant(
              of: find.byKey(const PageStorageKey('settings-list')),
              matching: find.byType(Scrollable),
            ),
          );
          await tester.ensureVisible(find.text(label));
          await tester.pumpAndSettle();
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
          final picker = find.byKey(ValueKey('language-${language.code}'));
          await tester.ensureVisible(picker);
          await tester.pumpAndSettle();
          expect(tester.widget<ListTile>(picker).selected, isTrue);
          expect(tester.getSize(picker).height, greaterThanOrEqualTo(48));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }

  testWidgets('language persists and cannot switch before a successful save', (
    tester,
  ) async {
    final b = LanguageBackend();
    final c = MailController(b, initial: b.data);
    addTearDown(c.dispose);
    await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
    await tester.pumpAndSettle();
    unawaited(showLanguagePicker(tester.element(find.byType(SettingsPage)), c));
    await tester.pumpAndSettle();
    b.fail = true;
    await tester.tap(find.byKey(const ValueKey('language-en')));
    await tester.pumpAndSettle();
    expect(c.settings.text('appLanguage'), isNot('en'));
    expect(find.text('操作失败'), findsOneWidget);
    b.fail = false;
    b.pending = Completer<void>();
    await tester.tap(find.byKey(const ValueKey('language-en')));
    await tester.pump();
    expect(
      tester
          .widget<ListTile>(find.byKey(const ValueKey('language-ja')))
          .enabled,
      isFalse,
    );
    b.pending!.complete();
    await tester.pumpAndSettle();
    expect(c.settings.text('appLanguage'), 'en');
    expect(find.text('Settings'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    final restored = MailController(b, initial: b.data);
    addTearDown(restored.dispose);
    await tester.pumpWidget(
      MailPilotApp(controller: restored, autoStart: false),
    );
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.textContaining('构建'), findsNothing);
  });

  testWidgets(
    'language changes preserve input, results, selection and raw content',
    (tester) async {
      final b = resultsFixture();
      final c = await mountResults(tester, b);
      await tester.enterText(
        find.byType(TextField),
        '设置 — original user input 日本語',
      );
      final input = tester
          .widget<TextField>(find.byType(TextField))
          .controller!;
      final entries = jsonEncode(c.data.rows('entries'));
      final mails = jsonEncode(c.data.rows('resultCards'));
      final scroll = tester
          .widget<ListView>(find.byKey(const ValueKey('chat-message-list')))
          .controller!;
      scroll.jumpTo(100);
      await tester.pumpAndSettle();
      await c.request('appLanguage', {'value': 'en'});
      c.applyAppLanguage('en');
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller,
        same(input),
      );
      expect(input.text, '设置 — original user input 日本語');
      expect(jsonEncode(c.data.rows('entries')), entries);
      expect(jsonEncode(c.data.rows('resultCards')), mails);
      expect(
        tester
            .widget<ListView>(find.byKey(const ValueKey('chat-message-list')))
            .controller,
        same(scroll),
      );
      expect(
        b.calls.where(
          (method) => ['send', 'analyze', 'chat', 'saveModel'].contains(method),
        ),
        isEmpty,
      );
    },
  );

  for (final language in AppLanguage.values) {
    testWidgets('mail presets retain server identity in ${language.code}', (
      tester,
    ) async {
      final b = LanguageBackend();
      final c = MailController(b, initial: b.data);
      c.applyAppLanguage(language.code);
      addTearDown(c.dispose);
      await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(SettingsPage));
      unawaited(
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => AccountForm(c))),
      );
      await tester.pumpAndSettle();
      final local = strings(tester.element(find.byType(AccountForm)));
      await tester.tap(find.text(local.alibabaBusinessMail));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(
              find.widgetWithText(ChoiceChip, local.alibabaBusinessMail),
            )
            .selected,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
