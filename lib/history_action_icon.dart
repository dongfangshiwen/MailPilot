import 'dart:math' as math;

import 'package:flutter/material.dart';

enum HistoryAction { pin, delete }

// DeepSeek's error-primary token, supplied in the user's inspected CSS.
const historyDeleteColor = Color(0xFFEC1313);

/// Shared vector symbols for history actions and draft deletion.
class HistoryActionIcon extends StatelessWidget {
  const HistoryActionIcon(this.action, {super.key, this.size = 20, this.color});

  final HistoryAction action;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _HistoryActionPainter(
        action,
        color ??
            IconTheme.of(context).color ??
            Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _HistoryActionPainter extends CustomPainter {
  const _HistoryActionPainter(this.action, this.color);
  final HistoryAction action;
  final Color color;

  // Exact filled path from the supplied SVG, in its original 16 × 16 viewBox.
  // Cache the geometry and preserve the contours without adding an outline.
  static final _deletePath = Path()
    ..moveTo(14.4782, 4.84067)
    ..lineTo(14.2138, 10.1152)
    ..cubicTo(14.1102, 12.1872, 14.067, 13.0115, 13.3866, 13.9607)
    ..cubicTo(13.1044, 14.3546, 12.7498, 14.6912, 12.3424, 14.9535)
    ..cubicTo(11.8239, 15.2872, 11.2415, 15.4316, 10.5585, 15.4998)
    ..cubicTo(9.88727, 15.5668, 9.04946, 15.5656, 7.99998, 15.5656)
    ..cubicTo(6.95051, 15.5656, 6.1127, 15.5668, 5.44142, 15.4998)
    ..cubicTo(4.75851, 15.4316, 4.17602, 15.2872, 3.65753, 14.9535)
    ..cubicTo(3.25012, 14.6912, 2.89559, 14.3546, 2.61332, 13.9607)
    ..cubicTo(1.93296, 13.0115, 1.88979, 12.1872, 1.78619, 10.1152)
    ..lineTo(1.52179, 4.84067)
    ..lineTo(2.89006, 4.77277)
    ..lineTo(3.15343, 10.0463)
    ..cubicTo(3.26221, 12.2218, 3.32452, 12.6015, 3.72646, 13.1624)
    ..cubicTo(3.90825, 13.4161, 4.13686, 13.6334, 4.39927, 13.8023)
    ..cubicTo(4.66204, 13.9714, 5.00263, 14.0792, 5.57825, 14.1367)
    ..cubicTo(6.16562, 14.1953, 6.92298, 14.1963, 7.99998, 14.1963)
    ..cubicTo(9.07699, 14.1963, 9.83434, 14.1953, 10.4217, 14.1367)
    ..cubicTo(10.9973, 14.0792, 11.3379, 13.9714, 11.6007, 13.8023)
    ..cubicTo(11.8631, 13.6334, 12.0917, 13.4161, 12.2735, 13.1624)
    ..cubicTo(12.6755, 12.6015, 12.7378, 12.2218, 12.8465, 10.0463)
    ..lineTo(13.1099, 4.77277)
    ..lineTo(14.4782, 4.84067)
    ..close()
    ..moveTo(5.43011, 6.22849)
    ..lineTo(6.7994, 6.22849)
    ..lineTo(6.7994, 11.3909)
    ..lineTo(5.43011, 11.3909)
    ..lineTo(5.43011, 6.22849)
    ..close()
    ..moveTo(9.20056, 6.22849)
    ..lineTo(10.5699, 6.22849)
    ..lineTo(10.5699, 11.3909)
    ..lineTo(9.20056, 11.3909)
    ..lineTo(9.20056, 6.22849)
    ..close()
    ..moveTo(8.53597, 0.434431)
    ..cubicTo(9.17976, 0.434431, 9.6522, 0.426926, 10.0966, 0.571258)
    ..cubicTo(10.2357, 0.616451, 10.3717, 0.672554, 10.502, 0.738948)
    ..cubicTo(10.9182, 0.951107, 11.2464, 1.29099, 11.7015, 1.74612)
    ..lineTo(12.4978, 2.54136)
    ..lineTo(15.3742, 2.54136)
    ..lineTo(15.3742, 3.91169)
    ..lineTo(0.625732, 3.91169)
    ..lineTo(0.625732, 2.54136)
    ..lineTo(3.50218, 2.54136)
    ..lineTo(4.29845, 1.74612)
    ..cubicTo(4.75358, 1.29099, 5.08174, 0.951107, 5.49801, 0.738948)
    ..cubicTo(5.62831, 0.672554, 5.76425, 0.616451, 5.90334, 0.571258)
    ..cubicTo(6.34776, 0.426926, 6.82021, 0.434431, 7.46399, 0.434431)
    ..lineTo(8.53597, 0.434431)
    ..close()
    ..moveTo(7.46399, 1.80476)
    ..cubicTo(6.73208, 1.80476, 6.51641, 1.81187, 6.32617, 1.87369)
    ..cubicTo(6.25545, 1.89667, 6.18668, 1.92533, 6.12041, 1.95907)
    ..cubicTo(5.96398, 2.03878, 5.82348, 2.16253, 5.44142, 2.54136)
    ..lineTo(10.5585, 2.54136)
    ..cubicTo(10.1765, 2.16253, 10.036, 2.03878, 9.87955, 1.95907)
    ..cubicTo(9.81329, 1.92533, 9.74452, 1.89667, 9.6738, 1.87369)
    ..cubicTo(9.48356, 1.81187, 9.26789, 1.80476, 8.53597, 1.80476)
    ..lineTo(7.46399, 1.80476)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (action == HistoryAction.delete) {
      canvas.scale(size.width / 16, size.height / 16);
      canvas.drawPath(_deletePath, Paint()..color = color);
      canvas.restore();
      return;
    }
    canvas.scale(size.width / 24, size.height / 24);
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.65
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.translate(12, 12);
    canvas.rotate(math.pi / 4);
    canvas.translate(-12, -12);
    canvas.drawPath(
      Path()
        ..moveTo(8, 3.5)
        ..lineTo(16, 3.5)
        ..moveTo(9, 3.5)
        ..lineTo(9, 9)
        ..lineTo(6, 13)
        ..lineTo(6, 15)
        ..lineTo(18, 15)
        ..lineTo(18, 13)
        ..lineTo(15, 9)
        ..lineTo(15, 3.5)
        ..moveTo(12, 15)
        ..lineTo(12, 21),
      pen,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HistoryActionPainter oldDelegate) =>
      oldDelegate.action != action || oldDelegate.color != color;
}
