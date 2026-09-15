import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/forms.dart';
import 'package:mailpilot/mail_setup_guide.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';

class GuideBackend extends PreviewBackend {
  final opened = <RowData>[];
  @override
  Future<dynamic> invoke(String method, [RowData args = const {}]) async {
    if (method == 'openLink') {
      opened.add({...args});
      return null;
    }
    return super.invoke(method, args);
  }
}

void main() {
  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.6, 2.0]) {
      for (final dark in [false, true]) {
        testWidgets('official mail guide $width/$scale/$dark', (tester) async {
          tester.view.physicalSize = Size(width, 860);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final b = GuideBackend();
          final c = MailController(b);
          addTearDown(c.dispose);
          for (final provider in [...MailSetupGuide.catalog.keys, '自定义']) {
            await tester.pumpWidget(
              MaterialApp(
                theme: mailTheme(dark),
                home: Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => showMailSetupGuide(context, c, provider),
                      child: const Text('配置'),
                    ),
                  ),
                ),
              ),
            );
            await tester.tap(find.text('配置'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final links = MailSetupGuide.catalog[provider]?.links ?? [];
            for (final link in links) {
              final target = find.byKey(ValueKey('mail-guide-link-${link.$2}'));
              await tester.scrollUntilVisible(
                target,
                180,
                scrollable: find
                    .descendant(
                      of: find.byKey(const ValueKey('mail-guide-scroll')),
                      matching: find.byType(Scrollable),
                    )
                    .first,
              );
              await tester.pumpAndSettle();
              await tester.tap(target);
              await tester.pumpAndSettle();
              expect(b.opened.last, {'url': link.$2});
              expect(Uri.parse(link.$2).scheme, 'https');
            }
            await tester.tap(find.text('返回填写'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          expect(
            b.calls.any(
              (m) =>
                  ['testAccount', 'saveAccount', 'sync', 'analyze'].contains(m),
            ),
            isFalse,
          );
        });
      }
    }
  }
  testWidgets('guide closes without losing typed mailbox credentials', (
    tester,
  ) async {
    final b = GuideBackend();
    final c = MailController(b);
    addTearDown(c.dispose);
    await tester.pumpWidget(
      MaterialApp(theme: mailTheme(false), home: AccountForm(c)),
    );
    await tester.enterText(
      find.widgetWithText(TextField, '邮箱地址'),
      'member@example.test',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '授权码'),
      'synthetic-secret',
    );
    final guide = find.byKey(const ValueKey('mail-setup-guide'));
    await tester.ensureVisible(guide);
    await tester.tap(guide);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('关闭配置指引'));
    await tester.pumpAndSettle();
    expect(find.text('member@example.test'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, '授权码'))
          .controller!
          .text,
      'synthetic-secret',
    );
    expect(b.opened, isEmpty);
  });
}
