import 'app_language.dart';

import 'package:flutter/material.dart';

/// Keeps navigation above the composer without taking space from the messages.
class ChatScrollViewport extends StatefulWidget {
  const ChatScrollViewport({
    super.key,
    required this.controller,
    required this.scope,
    required this.enabled,
    required this.child,
    this.onScroll,
    this.onJumpingChanged,
  });

  final ScrollController controller;
  final String scope;
  final bool enabled;
  final Widget child;
  final bool Function(ScrollNotification)? onScroll;
  final ValueChanged<bool>? onJumpingChanged;

  @override
  State<ChatScrollViewport> createState() => _ChatScrollViewportState();
}

class _ChatScrollViewportState extends State<ChatScrollViewport> {
  final visible = ValueNotifier(false);
  bool queued = false, jumping = false;
  int navigation = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(scheduleVisibility);
    scheduleVisibility();
  }

  @override
  void didUpdateWidget(ChatScrollViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(scheduleVisibility);
      widget.controller.addListener(scheduleVisibility);
    }
    if (oldWidget.scope != widget.scope || !widget.enabled) {
      navigation++;
      jumping = false;
    }
    scheduleVisibility();
  }

  void scheduleVisibility() {
    if (queued) return;
    queued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      queued = false;
      if (!mounted) return;
      visible.value =
          widget.enabled &&
          !jumping &&
          widget.controller.hasClients &&
          widget.controller.position.hasContentDimensions &&
          widget.controller.position.extentAfter > 180;
    });
  }

  Future<void> goToLatest() async {
    final controller = widget.controller;
    if (!controller.hasClients) return;
    final ticket = ++navigation;
    jumping = true;
    widget.onJumpingChanged?.call(true);
    visible.value = false;
    final position = controller.position;
    try {
      // Skip a long travel through old messages. A short move can stay animated.
      if (!MediaQuery.disableAnimationsOf(context) &&
          position.extentAfter < position.viewportDimension * 1.5) {
        await controller.animateTo(
          position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
        );
      }
      // Lazy variable-height messages refine their extent during layout. Follow
      // those corrections, not just the initial estimated end of the list.
      var settled = 0;
      for (var frame = 0; frame < 16; frame++) {
        if (!mounted || ticket != navigation || !controller.hasClients) return;
        controller.jumpTo(controller.position.maxScrollExtent);
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted || ticket != navigation || !controller.hasClients) return;
        settled = controller.position.extentAfter < 1 ? settled + 1 : 0;
        if (settled >= 2) break;
      }
    } finally {
      if (mounted && ticket == navigation) {
        jumping = false;
        widget.onJumpingChanged?.call(false);
        scheduleVisibility();
      }
    }
  }

  @override
  void dispose() {
    navigation++;
    widget.controller.removeListener(scheduleVisibility);
    visible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (event) {
        if (event.depth == 0) scheduleVisibility();
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (event) {
          if (event is ScrollStartNotification &&
              event.depth == 0 &&
              event.dragDetails != null) {
            navigation++;
            jumping = false;
            scheduleVisibility();
          }
          return widget.onScroll?.call(event) ?? false;
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            Positioned(
              right: 12,
              bottom: 8,
              child: ValueListenableBuilder<bool>(
                valueListenable: visible,
                builder: (context, show, _) => show
                    ? Tooltip(
                        message: strings(context).jumpToLatestMessage,
                        excludeFromSemantics: true,
                        child: Semantics(
                          button: true,
                          label: strings(context).jumpToLatestMessage,
                          onTap: goToLatest,
                          excludeSemantics: true,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              key: const ValueKey('chat-scroll-to-latest'),
                              onTap: goToLatest,
                              canRequestFocus: false,
                              customBorder: const CircleBorder(),
                              child: SizedBox.square(
                                dimension: 48,
                                child: Center(
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colors.outlineVariant,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: .06,
                                          ),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 21,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
