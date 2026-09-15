import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/chat_composer.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/preview_data.dart';

void main() {
  testWidgets('disabled model thinking takes precedence over saved effort', (
    tester,
  ) async {
    final fixture = previewState();
    fixture['models'] = [
      {
        ...fixture.rows('models').first,
        'thinkingMode': 'disabled',
        'reasoningEffort': 'high',
      },
    ];
    final b = PreviewBackend(initial: fixture);
    final c = MailController(b, initial: b.data);
    await c.start();
    await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
    await tester.pumpAndSettle();
    final option = find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.label == '深度思考',
    );
    expect(tester.widget<Semantics>(option).properties.toggled, false);
    await tester.tap(find.byTooltip('深度思考'));
    await tester.pumpAndSettle();
    expect(tester.widget<Semantics>(option).properties.toggled, true);
    expect(c.requestOptions['thinking'], 'enabled');
    expect(c.currentModel.text('thinkingMode'), 'disabled');
    expect(c.currentModel.text('reasoningEffort'), 'high');
    c.data['models'] = [
      {
        ...c.currentModel,
        'thinkingMode': 'default',
        'reasoningEffort': '',
        'thinkingBudget': 1024,
      },
    ];
    c.setChatOptions(thinking: 'default');
    await tester.pumpAndSettle();
    expect(tester.widget<Semantics>(option).properties.toggled, true);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  test('voice inserts at cursor and never submits a confirmation', () {
    final input = TextEditingController(text: '已有 内容');
    input.selection = const TextSelection.collapsed(offset: 3);
    insertTranscript(input, '确认发送 hello ');
    expect(input.text, '已有 确认发送 hello 内容');
    expect(input.selection.baseOffset, 14);
    input.dispose();
  });
  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets(
        'compact composer $width / $scale supports dark, keyboard and stable buttons',
        (tester) async {
          tester.view.physicalSize = Size(width, 820);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final b = PreviewBackend(
            initial: {
              ...previewState(),
              'accounts': [],
              'settings': {
                ...previewState().child('settings'),
                'theme': 'dark',
              },
              'searchConfig': {'hasSecret': true},
            },
          );
          final c = MailController(b, initial: b.data);
          await c.start();
          await tester.pumpWidget(
            MailPilotApp(controller: c, autoStart: false),
          );
          await tester.pumpAndSettle();
          final composer = find.byKey(const ValueKey('chat-composer'));
          if (scale == 1) {
            expect(
              tester.getSize(composer).height - 14,
              lessThanOrEqualTo(102),
            );
          }
          final plus = find.byTooltip('添加附件');
          final position = tester.getTopLeft(plus);
          expect(tester.getSize(plus).width, greaterThanOrEqualTo(48));
          await tester.tap(find.byTooltip('深度思考'));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('智能搜索'));
          await tester.pumpAndSettle();
          expect(tester.getTopLeft(plus), position);
          expect(c.requestOptions['thinking'], 'enabled');
          expect(c.requestOptions['webSearch'], true);
          await tester.enterText(
            find.byType(TextField),
            '第一行\n第二行\n第三行\n第四行\n第五行\n第六行',
          );
          await tester.pumpAndSettle();
          expect(tester.widget<TextField>(find.byType(TextField)).maxLines, 4);
          tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          await tester.pumpAndSettle();
          expect(find.byTooltip('发送问题'), findsOneWidget);
          expect(tester.takeException(), isNull);
          tester.view.resetViewInsets();
          await tester.tap(plus);
          await tester.pumpAndSettle();
          await tester.tap(find.text('添加文件'));
          await tester.pumpAndSettle();
          expect(b.calls, contains('pickMaterial'));
          expect(b.calls, isNot(contains('analyze')));
          expect(c.data.rows('localMaterials').length, 1);
          await tester.tap(find.byTooltip('清空选择'));
          await tester.pumpAndSettle();
          expect(b.calls, isNot(contains('newConversation')));
          expect(c.data.rows('selection'), isEmpty);
          expect(
            c.data.rows('localMaterials').any((m) => m.flag('selected')),
            isFalse,
          );
          expect(find.byTooltip('清空选择'), findsNothing);
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            '第一行\n第二行\n第三行\n第四行\n第五行\n第六行',
          );
          await tester.pumpWidget(const SizedBox());
          c.dispose();
        },
      );
    }
  }
}
