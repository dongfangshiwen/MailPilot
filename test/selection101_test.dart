import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/materials_sheet.dart';
import 'package:mailpilot/pdf_picker.dart';
import 'package:mailpilot/preview_data.dart';

import 'pdf_fixture.dart';

void main() {
  for (final width in [320.0, 360.0, 412.0]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.6, 2.0]) {
        testWidgets('material sheet $width dark=$dark scale=$scale', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 820);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final b = PreviewBackend();
          b.data = {
            ...b.data,
            'selection': [],
            'attachments': [
              {
                'id': 'long',
                'messageId': 'm1',
                'name': 'QUOTATION-2026003385-很长的项目名称与报价附件说明.pdf',
                'size': -1,
              },
              {
                'id': 'unsupported',
                'messageId': 'm1',
                'name': '旧版报价.doc',
                'size': 100,
              },
            ],
          };
          final c = MailController(b, initial: b.data);
          await c.start();
          addTearDown(c.dispose);
          await c.act('theme', {'value': dark ? 'dark' : 'light'});
          await c.act('toggleMessage', {'id': 'm1'});
          await tester.pumpWidget(
            MailPilotApp(controller: c, autoStart: false),
          );
          await tester.pumpAndSettle();
          final sheet = showMaterialsSheet(
            tester.element(find.byType(Scaffold).first),
            c,
          );
          await tester.pumpAndSettle();
          expect(find.textContaining('大小待确认'), findsWidgets);
          expect(c.data.rows('selection').single.strings('attachmentIds'), [
            'long',
          ]);
          await tester.ensureVisible(find.text('只保留正文'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('只保留正文'));
          await tester.pumpAndSettle();
          expect(
            c.data.rows('selection').single.strings('attachmentIds'),
            isEmpty,
          );
          await tester.tap(find.byTooltip('关闭资料管理'));
          await tester.pumpAndSettle();
          await sheet;
          expect(b.calls, isNot(contains('editPdf')));
          expect(b.calls, isNot(contains('analyze')));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
        testWidgets('PDF grid $width dark=$dark scale=$scale', (tester) async {
          tester.view.physicalSize = Size(width, 820);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final b = PdfFixtureBackend(
            (await tester.runAsync(pdfFixtureImage))!,
            count: width == 412 ? 1 : 30,
          );
          final c = MailController(b, initial: b.data);
          await c.start();
          addTearDown(c.dispose);
          await c.act('openMessage', {'id': 'm1'});
          await c.act('toggleMessage', {'id': 'm1'});
          expect(c.data.child('pdfChoice'), isEmpty);
          expect(b.requestedPages, isEmpty);
          await c.act('theme', {'value': dark ? 'dark' : 'light'});
          await c.act('editPdf', {'id': 'a2'});
          await tester.pumpWidget(
            MailPilotApp(controller: c, autoStart: false),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('pdf-page-grid')), findsOneWidget);
          expect(b.requestedPages.length, lessThanOrEqualTo(6));
          expect(b.maxRunning, 1);
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('清空'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('取消选择此附件'));
          await tester.pumpAndSettle();
          expect(c.data.rows('selection').single.strings('attachmentIds'), [
            'a1',
          ]);
          expect(b.calls, isNot(contains('analyze')));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }

  testWidgets(
    'all selection is metadata only and aggregate limit preserves question',
    (tester) async {
      final b = PreviewBackend();
      b.data = {
        ...b.data,
        'attachments': List.generate(
          11,
          (i) => {
            'id': 'f$i',
            'messageId': 'm1',
            'name': 'file$i.txt',
            'size': 100,
          },
        ),
        'selection': [],
      };
      final c = MailController(b, initial: b.data);
      await c.start();
      addTearDown(c.dispose);
      await c.act('toggleMessage', {'id': 'm1'});
      expect(
        c.data.rows('selection').single.strings('attachmentIds').length,
        11,
      );
      expect(c.data.child('selectionBudget').flag('blocked'), isTrue);
      await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '请分析这批资料');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('发送问题'));
      await tester.pumpAndSettle();
      expect(find.text('本次分析资料'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '请分析这批资料',
      );
      expect(b.calls, isNot(contains('analyze')));
      expect(b.calls, isNot(contains('pdfThumbnail')));
      expect(b.calls, isNot(contains('sourceInfo')));
    },
  );

  testWidgets('leaving PDF cancels queued thumbnails and preserves selection', (
    tester,
  ) async {
    final b = PdfFixtureBackend((await tester.runAsync(pdfFixtureImage))!);
    final waiting = Completer<void>();
    b.pending = waiting.future;
    final c = MailController(b, initial: b.data);
    await c.start();
    addTearDown(c.dispose);
    await c.act('toggleMessage', {'id': 'm1'});
    final original = c.data.rows('selection').single.toString();
    await c.act('openMessage', {'id': 'm1'});
    await c.act('editPdf', {'id': 'a2'});
    await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
    await tester.pump();
    expect(b.requestedPages.length, 1);
    await tester.tap(find.text('清空'));
    await tester.pump();
    await c.back();
    await tester.pump();
    waiting.complete();
    await tester.pumpAndSettle();
    expect(b.requestedPages.length, 1);
    expect(c.data.rows('selection').single.toString(), original);
    expect(find.byType(PdfPicker), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('thumbnail failure can retry and preview never selects a page', (
    tester,
  ) async {
    final b = PdfFixtureBackend(
      (await tester.runAsync(pdfFixtureImage))!,
      count: 1,
    )..fail = true;
    final c = MailController(b, initial: b.data);
    await c.start();
    addTearDown(c.dispose);
    await c.act('openMessage', {'id': 'm1'});
    await c.act('editPdf', {'id': 'a2'});
    await tester.pumpWidget(MailPilotApp(controller: c, autoStart: false));
    await tester.pumpAndSettle();
    expect(find.text('重试预览'), findsOneWidget);
    await tester.tap(find.text('清空'));
    await tester.pumpAndSettle();
    b.fail = false;
    await tester.tap(find.text('重试预览'));
    await tester.pumpAndSettle();
    expect(b.requestedPages, [0, 0]);
    await tester.tap(find.byType(Image).first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('关闭页面预览'), findsOneWidget);
    expect(b.calls.where((e) => e == 'pdfPage').length, 1);
    await tester.tap(find.byTooltip('关闭页面预览'));
    await tester.pumpAndSettle();
    expect(find.text('取消选择此附件'), findsOneWidget);
    expect(b.calls, isNot(contains('analyze')));
  });
}
