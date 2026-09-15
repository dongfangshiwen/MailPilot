import 'package:flutter/material.dart';

/// A light, symmetric globe that stays legible beside the compact tool labels.
class SearchGlobeIcon extends StatelessWidget {
  const SearchGlobeIcon({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size.square(16),
    painter: _SearchGlobePainter(color),
  );
}

class _SearchGlobePainter extends CustomPainter {
  const _SearchGlobePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.save();
    canvas.scale(size.width / 16, size.height / 16);
    canvas.drawCircle(const Offset(8, 8), 6.5, stroke);
    canvas.drawOval(const Rect.fromLTWH(5.1, 1.5, 5.8, 13), stroke);
    canvas.drawLine(const Offset(1.5, 8), const Offset(14.5, 8), stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SearchGlobePainter oldDelegate) =>
      oldDelegate.color != color;
}
