// Deliberately synthetic fixture: never imported by the production entrypoint.
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mailpilot/controller.dart';
import 'package:mailpilot/preview_data.dart';

Future<Uint8List> attachmentFixtureImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawColor(const Color(0xffedf2fa), BlendMode.src);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(40, 40, 720, 460),
      const Radius.circular(24),
    ),
    Paint()..color = Colors.white,
  );
  canvas.drawCircle(
    const Offset(630, 175),
    50,
    Paint()..color = const Color(0xffd5e1fa),
  );
  canvas.drawPath(
    Path()
      ..moveTo(90, 400)
      ..lineTo(245, 210)
      ..lineTo(360, 340)
      ..lineTo(450, 250)
      ..lineTo(680, 400)
      ..close(),
    Paint()..color = const Color(0xff9eb5df),
  );
  final text = TextPainter(
    text: const TextSpan(
      text: 'IMAGE ATTACHMENT · PREVIEW FIXTURE',
      style: TextStyle(color: Color(0xff546b94), fontSize: 24),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  text.paint(canvas, const Offset(70, 440));
  text.dispose();
  final picture = recorder.endRecording();
  final image = await picture.toImage(800, 560);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

class AttachmentFixtureBackend extends PreviewBackend {
  AttachmentFixtureBackend(this.bytes);
  final Uint8List bytes;
  final requested = <String>[];
  bool failImage = false;
  Future<void>? pending;
  @override
  Future<dynamic> invoke(String method, [RowData args = const {}]) async {
    switch (method) {
      case 'openMessage':
        await super.invoke(method, args);
        data = {
          ...data,
          'detailAttachments': [
            {
              'id': 'photo1',
              'messageId': 'm1',
              'name': '项目现场图片.png',
              'mimeType': 'image/png',
              'size': 120000,
            },
            {
              'id': 'photo2',
              'messageId': 'm1',
              'name': '另一张尚未下载的图片.JPG',
              'mimeType': 'application/octet-stream',
              'size': 90000,
            },
          ],
        };
        publish();
        return null;
      case 'preview':
        calls.add(method);
        final a = data
            .rows('detailAttachments')
            .firstWhere((a) => a['id'] == args['id']);
        data = {
          ...data,
          'source': {
            'id': 'preview-${a['id']}',
            'attachmentId': a['id'],
            'messageId': 'm1',
            'title': a['name'],
            'location': '图片附件',
          },
        };
        publish();
        return null;
      case 'sourceInfo':
        calls.add(method);
        requested.add(args.text('attachmentId'));
        await pending;
        if (failImage) throw StateError('模拟断网，尚未加载图片');
        return jsonEncode({
          ...args,
          'imagePath': 'fixture/${args['attachmentId']}',
        });
      case 'imageBytes':
        calls.add(method);
        return bytes;
    }
    return super.invoke(method, args);
  }
}
