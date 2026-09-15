import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Paints only received text, spreading a burst over at most 80 ms. History,
/// stopped output and reduced-motion views display their full contents directly.
class StreamText extends StatefulWidget {
  const StreamText({
    super.key,
    required this.text,
    required this.active,
    required this.builder,
    this.onLayout,
  });
  final String text;
  final bool active;
  final Widget Function(BuildContext, String) builder;
  final VoidCallback? onLayout;

  @override
  State<StreamText> createState() => _StreamTextState();
}

class _StreamTextState extends State<StreamText>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  late String _shown = widget.text;
  int _lastMicros = 0;
  bool get _animate =>
      widget.active &&
      TickerMode.valuesOf(context).enabled &&
      !MediaQuery.disableAnimationsOf(context);

  @override
  void didUpdateWidget(StreamText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_animate || !widget.text.startsWith(_shown)) {
      _ticker.stop();
      _shown = widget.text;
    } else if (_shown != widget.text && !_ticker.isActive) {
      _lastMicros = 0;
      _ticker.start();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animate) {
      _ticker.stop();
      _shown = widget.text;
    }
  }

  void _tick(Duration elapsed) {
    final micros = elapsed.inMicroseconds;
    final remaining = math.max(1, 80000 - _lastMicros);
    final step = math.max(1, micros - _lastMicros);
    final pending = widget.text.substring(_shown.length).characters;
    final count = micros >= 80000
        ? pending.length
        : (pending.length * step / remaining).ceil();
    setState(() => _shown += pending.take(count).toString());
    _lastMicros = micros;
    if (_shown == widget.text) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onLayout = widget.onLayout;
    if (onLayout != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) onLayout();
      });
    }
    return widget.builder(context, _shown);
  }
}
