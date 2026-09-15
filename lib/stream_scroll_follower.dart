import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// Retargets the actual scroll extent each frame instead of restarting an
/// animateTo for every network fragment. User navigation always takes priority.
class StreamScrollFollower {
  StreamScrollFollower(this.controller, TickerProvider vsync) {
    _ticker = vsync.createTicker(_tick);
  }
  final ScrollController controller;
  late final Ticker _ticker;
  bool _paused = false, _queued = false, _disposed = false, _stepping = false;
  int _lastMicros = 0;
  bool get moving => _ticker.isActive;
  bool get canFollow => !_paused;

  void stop() => _ticker.stop();
  void resume() {
    _ticker.stop();
    _paused = false;
  }

  void pause() {
    _paused = true;
    _ticker.stop();
  }

  bool observe(ScrollNotification event) {
    if (event.depth != 0 || _stepping) return false;
    if ((event is ScrollStartNotification && event.dragDetails != null) ||
        (event is UserScrollNotification &&
            event.direction != ScrollDirection.idle)) {
      pause();
    } else if (event is ScrollEndNotification) {
      _paused = event.metrics.extentAfter > 40;
    }
    return false;
  }

  void follow({bool force = false, bool animate = true}) {
    if (_disposed) return;
    if (force) _paused = false;
    if (_paused || _queued) return;
    _queued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queued = false;
      if (_disposed || _paused || !controller.hasClients) return;
      if (!animate) {
        _move(controller.position.maxScrollExtent);
      } else if (!_ticker.isActive && controller.position.extentAfter > .5) {
        _lastMicros = 0;
        _ticker.start();
      }
    });
  }

  void _move(double offset) {
    _stepping = true;
    try {
      controller.jumpTo(offset);
    } finally {
      _stepping = false;
    }
  }

  void _tick(Duration elapsed) {
    if (_paused || !controller.hasClients) {
      _ticker.stop();
      return;
    }
    final position = controller.position;
    final distance = position.maxScrollExtent - position.pixels;
    final dt = ((elapsed.inMicroseconds - _lastMicros) / 1000).clamp(1.0, 64.0);
    _lastMicros = elapsed.inMicroseconds;
    if (distance.abs() < .5) {
      _move(position.maxScrollExtent);
      _ticker.stop();
    } else {
      _move(
        (position.pixels + distance * (1 - math.exp(-dt / 45))).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
    }
  }

  void dispose() {
    _disposed = true;
    _ticker.dispose();
  }
}
