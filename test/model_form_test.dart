import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/forms.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/model_options.dart';
import 'package:mailpilot/preview_data.dart';

class RecordingBackend extends PreviewBackend {
  RowData? saved;
  @override
  Future<dynamic> invoke(String method, [RowData args = const {}]) async {
    if (method == 'saveModel') {
      saved = {...args};
      return '已保存';
    }
    return super.invoke(method, args);
  }
}

Future<void> chooseModel(WidgetTester tester, String row, String choice) async {
  final setting = find.byKey(ValueKey('model-setting-$row'));
  await tester.ensureVisible(setting);
  await tester.tap(setting);
  await tester.pumpAndSettle();
  expect(find.byType(BottomSheet), findsOneWidget);
  expect(find.byType(DropdownButtonFormField<String>), findsNothing);
  final option = find.byKey(ValueKey('model-choice-$choice'));
  await tester.ensureVisible(option);
  await tester.tap(option);
  await tester.pumpAndSettle();
}

void main() {
  for (final savedOutput in [null, 2048]) {
    testWidgets(
      'model output defaults to automatic and preserves $savedOutput',
      (tester) async {
        final backend = RecordingBackend();
        final controller = MailController(backend, initial: backend.data);
        await controller.start();
        await tester.pumpWidget(
          MailPilotApp(controller: controller, autoStart: false),
        );
        await tester.pumpAndSettle();
        Navigator.of(tester.element(find.byType(TextField))).push(
          MaterialPageRoute<void>(
            builder: (_) => ModelForm(
              controller,
              initial: savedOutput == null
                  ? const {}
                  : {'outputTokens': savedOutput},
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('高级参数'));
        await tester.tap(find.text('高级参数'));
        await tester.pumpAndSettle();
        final output = find.byKey(const ValueKey('model-field-outputTokens'));
        if (savedOutput == null) {
          expect(output, findsNothing);
          expect(find.text('跟随型号最大值'), findsOneWidget);
          expect(find.textContaining('尚未核实，暂用 4096'), findsOneWidget);
        } else {
          await tester.ensureVisible(output);
          expect(
            tester.widget<TextField>(output).controller!.text,
            '$savedOutput',
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final width in [320.0, 360.0, 412.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'model options preserve edits and require delete confirmation $width $dark',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = width == 320
              ? 2
              : width == 360
              ? 1.6
              : 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final b = RecordingBackend();
          final c = MailController(b, initial: b.data);
          await c.start();
          await c.act('theme', {'value': dark ? 'dark' : 'light'});
          await tester.pumpWidget(
            MailPilotApp(controller: c, autoStart: false),
          );
          await tester.pumpAndSettle();
          Navigator.of(tester.element(find.byType(TextField))).push(
            MaterialPageRoute<void>(
              builder: (_) => ModelForm(
                c,
                initial: {...c.models.first, 'testReport': '尚未测试'},
              ),
            ),
          );
          await tester.pumpAndSettle();
          final label = tester
              .widget<TextField>(
                find.byKey(const ValueKey('model-field-label')),
              )
              .controller!;
          label.text = '尚未保存的名称';
          await tester.ensureVisible(find.text('高级参数'));
          await tester.tap(find.text('高级参数'));
          await tester.pumpAndSettle();
          await chooseModel(tester, 'thinking', 'enabled');
          await tester.tap(
            find.byKey(const ValueKey('model-setting-thinking')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('关闭思考模式'));
          await tester.pumpAndSettle();
          expect(find.text('开启思考'), findsOneWidget);
          await chooseModel(tester, 'effort', 'high');
          await chooseModel(tester, 'parameter', 'max_completion_tokens');
          expect(label.text, '尚未保存的名称');
          // The keyboard resizes only the scrolling form; saving stays visible.
          await tester.ensureVisible(
            find.byKey(const ValueKey('model-field-outputTokens')),
          );
          await tester.enterText(
            find.byKey(const ValueKey('model-field-outputTokens')),
            '4096',
          );
          tester.view.viewInsets = FakeViewPadding(bottom: 280);
          await tester.pumpAndSettle();
          expect(
            tester.getRect(find.widgetWithText(FilledButton, '保存模型')).bottom,
            lessThanOrEqualTo(900 - 280),
          );
          tester.view.resetViewInsets();
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
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
          b.calls.clear();
          expect(find.text('尚未测试'), findsNothing);
          expect(find.text('删除模型'), findsNothing);
          await tester.tap(find.byTooltip('模型选项'));
          await tester.pumpAndSettle();
          expect(find.byType(BottomSheet), findsOneWidget);
          await tester.tap(find.text('默认文字模型'));
          await tester.pumpAndSettle();
          expect(b.calls, contains('defaultModel'));
          expect(label.text, '尚未保存的名称');
          expect(b.saved, isNull);
          expect(b.calls, isNot(contains('testModel')));
          await tester.tap(find.byTooltip('模型选项'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('删除模型'));
          await tester.tap(find.text('删除模型'));
          await tester.pumpAndSettle();
          expect(b.calls, isNot(contains('deleteModel')));
          await tester.tap(find.text('取消'));
          await tester.pumpAndSettle();
          expect(label.text, '尚未保存的名称');
          expect(b.calls, isNot(contains('deleteModel')));
          await tester.tap(find.byTooltip('模型选项'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('连接诊断（可选）'));
          await tester.tap(find.text('连接诊断（可选）'));
          await tester.pumpAndSettle();
          expect(b.calls, contains('testModel'));
          expect(label.text, '尚未保存的名称');
          expect(b.saved, isNull);
          await tester.ensureVisible(find.byTooltip('模型选项'));
          await tester.tap(find.byTooltip('模型选项'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('删除模型'));
          await tester.tap(find.text('删除模型'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(FilledButton, '删除'));
          await tester.pumpAndSettle();
          expect(
            b.calls.where((method) => method == 'deleteModel'),
            hasLength(1),
          );
          expect(find.byType(ModelForm), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          c.dispose();
        },
      );
    }
  }

  test(
    'provider detection uses host boundaries and efforts differ by provider',
    () {
      expect(modelProvider('auto', 'https://api.deepseek.com'), 'deepseek');
      expect(
        modelProvider('auto', 'https://api.deepseek.com.evil.test'),
        'compatible',
      );
      expect(
        modelProvider('auto', 'https://ark.cn-beijing.volces.com/api/v3'),
        'volcengine',
      );
      expect(modelEfforts('deepseek', 'deepseek-v4-pro'), [
        '',
        'low',
        'high',
        'max',
      ]);
      expect(modelEfforts('aliyun', 'qwen3.8-plus'), [
        '',
        'low',
        'medium',
        'xhigh',
      ]);
      expect(modelEfforts('aliyun', 'qwen3.5-plus'), ['']);
    },
  );

  testWidgets(
    'advanced reasoning fields are discoverable and saved with the profile',
    (tester) async {
      final b = RecordingBackend();
      final controller = MailController(b, initial: b.data);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MailPilotApp(controller: controller, autoStart: false),
      );
      Navigator.of(tester.element(find.byType(TextField))).push(
        MaterialPageRoute<void>(
          builder: (_) => ModelForm(
            controller,
            initial: const {
              'id': 'test',
              'label': '思考模型',
              'baseUrl': 'https://api.deepseek.com',
              'model': 'deepseek-v4-pro',
              'outputTokens': 4096,
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('思考模式、思考档位与输出长度'), findsOneWidget);
      await tester.ensureVisible(find.text('高级参数'));
      await tester.tap(find.text('高级参数'));
      await tester.pumpAndSettle();
      await chooseModel(tester, 'thinking', 'enabled');
      await chooseModel(tester, 'effort', 'max');
      await chooseModel(tester, 'parameter', 'max_completion_tokens');
      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, '保存模型'),
        280,
        scrollable: find
            .descendant(
              of: find.byType(ModelForm),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '保存模型'));
      await tester.pumpAndSettle();
      expect(b.saved?['thinkingMode'], 'enabled');
      expect(b.saved?['reasoningEffort'], 'max');
      expect(b.saved?['thinkingBudget'], 0);
      expect(b.saved?['tokenParameter'], 'max_completion_tokens');
      expect(b.saved?['outputTokens'], 4096);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Aliyun offers budget or effort and hides both when thinking is off',
    (tester) async {
      final b = RecordingBackend();
      final controller = MailController(b);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: mailTheme(false),
          home: ModelForm(
            controller,
            initial: const {
              'provider': 'aliyun',
              'model': 'qwen3.8-plus',
              'thinkingMode': 'enabled',
            },
          ),
        ),
      );
      await tester.ensureVisible(find.text('高级参数'));
      await tester.tap(find.text('高级参数'));
      await tester.pumpAndSettle();
      expect(find.text('思考预算（Token）'), findsOneWidget);
      await chooseModel(tester, 'effort', 'medium');
      expect(find.text('思考预算（Token）'), findsNothing);
      await chooseModel(tester, 'thinking', 'disabled');
      expect(find.text('思考档位'), findsNothing);
      expect(find.text('思考预算（Token）'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
