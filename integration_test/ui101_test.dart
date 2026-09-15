import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/main.dart';
import 'package:mailpilot/materials_sheet.dart';

import '../test/pdf_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('API 36 attachment defaults, material sheet and lazy PDF flows', (
    tester,
  ) async {
    final bytes = (await tester.runAsync(pdfFixtureImage))!;
    for (final count in [1, 9, 10, 11, 20, 80]) {
      final b = PdfFixtureBackend(bytes, count: count);
      final c = MailController(b, initial: b.data);
      await c.start();
      await c.act('toggleMessage', {'id': 'm1'});
      await c.act('openMessage', {'id': 'm1'});
      await c.act('editPdf', {'id': 'a2'});
      await tester.pumpWidget(
        MailPilotApp(
          key: ValueKey(count),
          controller: c,
          autoStart: false,
          preview: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(b.requestedPages.length, lessThanOrEqualTo(6));
      expect(b.maxRunning, 1);
      expect(find.text('确认选择 · ${count.clamp(0, 10)} 页'), findsOneWidget);
      if (count == 1 || count == 11) {
        if (count == 1) {
          await binding.convertFlutterSurfaceToImage();
          await tester.pumpAndSettle();
        }
        await tester.runAsync(
          () => precacheImage(
            MemoryImage(bytes),
            tester.element(find.byType(Scaffold).first),
          ),
        );
        await tester.pumpAndSettle();
        await binding.takeScreenshot(
          'pdf-${count == 1 ? 'single' : 'grid'}-fixture',
        );
        await tester.tap(find.byType(Image).first);
        await tester.pumpAndSettle();
        await binding.takeScreenshot(
          'pdf-${count == 1 ? 'single' : 'grid'}-zoom-fixture',
        );
        await tester.tap(find.byTooltip('关闭页面预览'));
        await tester.pumpAndSettle();
      }
      if (count == 80) {
        await tester.fling(
          find.byKey(const ValueKey('pdf-page-grid')),
          const Offset(0, -1500),
          3000,
        );
        await tester.pumpAndSettle();
        expect(b.requestedPages.length, lessThan(30));
        debugPrint(
          'Long PDF: ${b.requestedPages.length}/80 thumbnail requests, max in flight ${b.maxRunning}',
        );
      }
      await tester.tap(find.text('清空'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消选择此附件'));
      await tester.pumpAndSettle();
      expect(c.data.rows('selection').single.strings('attachmentIds'), ['a1']);
      if (count == 1) {
        await c.act('selectMessageFiles', {'id': 'm1', 'bodyOnly': false});
        await tester.pumpAndSettle();
        await binding.takeScreenshot('mail-attachments-fixture');
        await c.act('back');
        await tester.pumpAndSettle();
        for (final dark in [false, true]) {
          await c.act('theme', {'value': dark ? 'dark' : 'light'});
          await tester.pumpAndSettle();
          final ctx = tester.element(find.byType(Scaffold).first);
          final sheet = showMaterialsSheet(ctx, c);
          await tester.pumpAndSettle();
          await binding.takeScreenshot(
            'materials-${dark ? 'dark' : 'light'}-fixture',
          );
          await tester.tap(find.byTooltip('关闭资料管理'));
          await tester.pumpAndSettle();
          await sheet;
        }
      }
      expect(b.calls, isNot(contains('analyze')));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    }
  });
}
