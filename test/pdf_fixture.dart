// Generated document artwork for UI tests only, not a real user attachment.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/preview_data.dart';

Future<Uint8List> pdfFixtureImage() async {
  final recorder = ui.PictureRecorder();
  final page = Canvas(recorder);
  page.drawColor(Colors.white, BlendMode.src);
  void text(String value, double y, double size, Color color) {
    final p = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(fontSize: size, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 260);
    p.paint(page, Offset(30, y));
    p.dispose();
  }

  text('DOCUMENT PREVIEW', 30, 12, const Color(0xff667085));
  text('Quotation', 67, 28, const Color(0xff202631));
  text('SAMPLE · NOT A REAL EMAIL', 112, 10, const Color(0xff8a93a1));
  page.drawRect(
    const Rect.fromLTWH(30, 154, 260, 32),
    Paint()..color = const Color(0xfff0f3f8),
  );
  text('ITEM                         AMOUNT', 162, 11, const Color(0xff4c596f));
  for (var i = 0; i < 5; i++) {
    final y = 204.0 + i * 36;
    page.drawLine(
      Offset(30, y + 23),
      Offset(290, y + 23),
      Paint()..color = const Color(0xffe8ebf1),
    );
    text(
      'Service ${i + 1}                    --',
      y,
      11,
      const Color(0xff6c7586),
    );
  }
  text('Page preview fixture', 426, 10, const Color(0xff98a0ae));
  final picture = recorder.endRecording();
  final image = await picture.toImage(320, 480);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
      .asUint8List();
  image.dispose();
  picture.dispose();
  return bytes;
}

class PdfFixtureBackend extends PreviewBackend {
  PdfFixtureBackend(this.bytes, {this.count = 30});
  final Uint8List bytes;
  final int count;
  final requestedPages = <int>[];
  Future<void>? pending;
  int running = 0, maxRunning = 0;
  bool fail = false;
  @override
  Future<dynamic> invoke(String method, [RowData args = const {}]) async {
    if (method == 'editPdf') {
      await super.invoke(method, args);
      data = {
        ...data,
        'pdfChoice': {
          ...data.child('pdfChoice'),
          'count': count,
          'selected': List.generate(count.clamp(0, 10), (i) => i),
        },
      };
      publish();
      return null;
    }
    if (method == 'pdfThumbnail') {
      calls.add(method);
      requestedPages.add(args.number('page'));
      running++;
      if (running > maxRunning) maxRunning = running;
      try {
        await pending;
        if (fail) throw PlatformException(code: 'fixture', message: '模拟预览失败');
        return bytes;
      } finally {
        running--;
      }
    }
    if (method == 'pdfPage') {
      calls.add(method);
      return 'fixture.pdf.page';
    }
    if (method == 'imageBytes') return bytes;
    return super.invoke(method, args);
  }
}
