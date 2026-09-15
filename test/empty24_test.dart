import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/conversation_drawer.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';

import 'history24_fixture.dart';

void main() {
  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.6, 2.0]) {
      for (final dark in [false, true]) {
        testWidgets('empty sidebar action $width $scale $dark', (tester) async {
          tester.view.physicalSize = Size(width, 850);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final out = Platform.environment['MAILPILOT_EMPTY_SCREENSHOTS'];
          if (out != null) {
            for (final pair in [
              ('ReviewFont', 'MAILPILOT_REVIEW_FONT'),
              ('Ahem', 'MAILPILOT_REVIEW_FONT'),
              ('Roboto', 'MAILPILOT_REVIEW_FONT'),
              ('MaterialIcons', 'MAILPILOT_ICON_FONT'),
            ]) {
              final path = Platform.environment[pair.$2]!;
              final loader = FontLoader(pair.$1)
                ..addFont(
                  Future.value(
                    ByteData.sublistView(File(path).readAsBytesSync()),
                  ),
                );
              await loader.load();
            }
          }
          final b = history24Fixture(count: 0);
          final c = MailController(b, initial: b.data);
          await c.start();
          final boundary = GlobalKey();
          final theme = mailTheme(dark);
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundary,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: out == null
                    ? theme
                    : theme.copyWith(
                        textTheme: theme.textTheme.apply(
                          fontFamily: 'ReviewFont',
                        ),
                      ),
                home: Scaffold(
                  drawer: ConversationDrawer(c),
                  body: const SizedBox(),
                ),
              ),
            ),
          );
          tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
          await tester.pumpAndSettle();
          expect(find.text('暂无历史对话'), findsNothing);
          expect(find.text('对话会保存在这里'), findsOneWidget);
          expect(find.byTooltip('多选对话'), findsNothing);
          await tester.ensureVisible(find.text('开始对话'));
          await tester.pumpAndSettle();
          if (out != null && width == 412 && scale == 1) {
            await tester.runAsync(() async {
              final image =
                  await (boundary.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage(pixelRatio: 2);
              final bytes = (await image.toByteData(
                format: ui.ImageByteFormat.png,
              ))!;
              Directory(out).createSync(recursive: true);
              File('$out/sidebar-empty-${dark ? 'dark' : 'light'}.png')
                  .writeAsBytesSync(bytes.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.tap(find.text('开始对话'));
          await tester.pumpAndSettle();
          expect(
            tester.state<ScaffoldState>(find.byType(Scaffold)).isDrawerOpen,
            isFalse,
          );
          expect(c.data.number('tab'), 1);
          expect(
            b.calls.where((x) => x == 'analyze' || x == 'newConversation'),
            isEmpty,
          );
          expect(tester.testTextInput.isVisible, isFalse);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          c.dispose();
        });
      }
    }
  }
  test(
    'mail detail returns through inbox to settings without losing origin',
    () async {
      final b = history24Fixture();
      final c = MailController(b, initial: b.data);
      await c.start();
      await c.act('tab', {'index': 3});
      await c.act('tab', {'index': 0, 'fromSettings': true});
      expect(c.returnsToSettings, isTrue);
      await c.act('openMessage', {'id': 'm1'});
      await c.back();
      expect(c.data['detail'], isNull);
      expect(c.data.number('tab'), 0);
      await c.back();
      expect(c.data.number('tab'), 3);
      await c.act('tab', {'index': 0});
      expect(c.returnsToSettings, isFalse);
      await c.back();
      expect(c.data.number('tab'), 1);
      c.dispose();
    },
  );
  for (final systemBack in [false, true]) {
    testWidgets('mail picker returns with input and selection $systemBack', (
      tester,
    ) async {
      final b = history24Fixture();
      b.data['selection'] = <RowData>[];
      final c = MailController(b, initial: b.data);
      await c.start();
      await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
      await tester.pumpAndSettle();
      final input = find.byType(TextField);
      await tester.enterText(input, '保留尚未发送的问题');
      tester.widget<TextField>(input).controller!.selection =
          const TextSelection.collapsed(offset: 2);
      await tester.tap(find.byTooltip('添加附件'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('选择邮件'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('返回对话'), findsOneWidget);
      await c.act('toggleMessage', {'id': 'm1'});
      await tester.pumpAndSettle();
      if (systemBack) {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(find.byTooltip('返回对话'));
      }
      await tester.pumpAndSettle();
      expect(c.data.number('tab'), 1);
      expect(c.selected('m1'), isTrue);
      final restored = tester
          .widget<TextField>(find.byType(TextField))
          .controller!;
      expect(restored.text, '保留尚未发送的问题');
      expect(restored.selection.baseOffset, 2);
      expect(tester.testTextInput.isVisible, isFalse);
      expect(
        c.data.rows('selection').single.strings('attachmentIds'),
        isNotEmpty,
      );
      await tester.tap(find.byTooltip('清空选择'));
      await tester.pumpAndSettle();
      expect(c.data.rows('selection'), isEmpty);
      expect(c.data.child('selectionBudget').number('count'), 0);
      expect(find.byTooltip('清空选择'), findsNothing);
      expect(restored.text, '保留尚未发送的问题');
      expect(tester.testTextInput.isVisible, isFalse);
      expect(
        b.calls.where((x) => x == 'analyze' || x == 'newConversation'),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  }
  testWidgets(
    'mail picker input is not restored into another account or conversation',
    (tester) async {
      final b = history24Fixture();
      final c = MailController(b, initial: b.data);
      await c.start();
      await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
      await tester.pumpAndSettle();
      for (final field in ['conversationId', 'activeAccount']) {
        await tester.enterText(find.byType(TextField), '原范围的问题');
        b.data = {...b.data, field: 'different'};
        b.publish();
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty,
        );
      }
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
