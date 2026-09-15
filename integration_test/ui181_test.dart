import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/forms.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/preview_data.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('account drawer and voice-send replacement on Android', (
    tester,
  ) async {
    final b = PreviewBackend(
      initial: {
        ...previewState(),
        'accounts': [
          {'id': 'account', 'email': 'personal@example.test'},
          {'id': 'work', 'email': 'team@company.example.test'},
        ],
      },
    );
    final c = MailController(b, initial: b.data);
    await c.start();
    await tester.pumpWidget(
      MailPilotApp(controller: c, autoStart: false, preview: true),
    );
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    for (final dark in [false, true]) {
      await c.act('theme', {'value': dark ? 'dark' : 'light'});
      await c.act('tab', {'index': 0});
      await tester.pumpAndSettle();
      b.calls.clear();
      await tester.tap(find.byTooltip('切换邮箱'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      await binding.takeScreenshot(
        'accounts-${dark ? 'dark' : 'light'}-fixture',
      );
      await tester.tap(find.byKey(const ValueKey('account-choice-work')));
      await tester.pumpAndSettle();
      expect(c.data.text('activeAccount'), 'work');
      expect(b.calls, isNot(contains('refresh')));
      await c.act('tab', {'index': 1});
      await c.act('toggleMessage', {'id': 'm1'});
      c.setChatOptions(thinking: 'enabled', search: true);
      await tester.pumpAndSettle();
      expect(find.byTooltip('语音输入'), findsOneWidget);
      expect(find.byTooltip('发送问题'), findsNothing);
      for (final key in ['composer-add-disc', 'composer-voice-disc']) {
        expect(tester.getSize(find.byKey(ValueKey(key))), const Size(28, 28));
      }
      await tester.enterText(find.byType(TextField), '帮我起草回复');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(
        tester.getCenter(find.byTooltip('添加附件')).dy,
        tester.getCenter(find.byTooltip('发送问题')).dy,
      );
      expect(find.byTooltip('语音输入'), findsNothing);
      expect(
        tester.getSize(find.byKey(const ValueKey('composer-send-disc'))),
        const Size(28, 28),
      );
      await binding.takeScreenshot(
        'composer-${dark ? 'dark' : 'light'}-fixture',
      );
      expect(tester.takeException(), isNull);
      // Reconnect the Android input client before simulating a new edit after
      // dismissing the IME for the preceding screenshot.
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
      expect(find.byTooltip('发送问题'), findsNothing);
      expect(find.byTooltip('语音输入'), findsOneWidget);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.byTooltip('发送问题'), findsNothing);
      expect(find.byTooltip('语音输入'), findsOneWidget);
      await binding.takeScreenshot(
        'composer-empty-${dark ? 'dark' : 'light'}-fixture',
      );
      await c.act('clearSelection');
      Navigator.of(tester.element(find.byType(TextField))).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ModelForm(c, initial: {...c.models.first, 'testReport': '尚未测试'}),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byTooltip('模型选项'),
        240,
        scrollable: find
            .descendant(
              of: find.byType(ModelForm),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await binding.takeScreenshot(
        'model-footer-${dark ? 'dark' : 'light'}-fixture',
      );
      await tester.tap(find.byTooltip('模型选项'));
      await tester.pumpAndSettle();
      await binding.takeScreenshot(
        'model-options-${dark ? 'dark' : 'light'}-fixture',
      );
      expect(find.text('连接诊断（可选）'), findsOneWidget);
      await tester.tap(find.byTooltip('关闭模型选项'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('高级参数'));
      await tester.tap(find.text('高级参数'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('model-setting-parameter')),
      );
      await tester.pumpAndSettle();
      await binding.takeScreenshot(
        'model-advanced-${dark ? 'dark' : 'light'}-fixture',
      );
      for (final entry in {
        'thinking': 'enabled',
        'effort': 'high',
        'parameter': 'max_completion_tokens',
      }.entries) {
        final setting = find.byKey(ValueKey('model-setting-${entry.key}'));
        await tester.ensureVisible(setting);
        await tester.tap(setting);
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.byType(DropdownButtonFormField<String>), findsNothing);
        await binding.takeScreenshot(
          'model-${entry.key}-${dark ? 'dark' : 'light'}-fixture',
        );
        final choice = find.byKey(ValueKey('model-choice-${entry.value}'));
        await tester.ensureVisible(choice);
        await tester.tap(choice);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
