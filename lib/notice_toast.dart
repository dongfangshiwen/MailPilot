import 'dart:async';

import 'package:flutter/material.dart';

import 'controller.dart';

/// A zero-size observer: successful actions never move the page contents.
class NoticeToast extends StatefulWidget {
  const NoticeToast({
    super.key,
    required this.controller,
    required this.notice,
    this.busy = false,
    this.status = '',
  });
  final MailController controller;
  final String notice;
  final bool busy;
  final String status;
  @override
  State<NoticeToast> createState() => _NoticeToastState();
}

class _NoticeToastState extends State<NoticeToast> {
  @override
  void initState() {
    super.initState();
    announce();
  }

  @override
  void didUpdateWidget(NoticeToast oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notice != widget.notice ||
        oldWidget.busy != widget.busy ||
        oldWidget.status != widget.status) {
      if (widget.notice.isEmpty && !widget.busy && oldWidget.busy) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
        });
      } else {
        announce();
      }
    }
  }

  void announce() {
    final busy = widget.busy;
    final message = busy ? widget.status : widget.notice;
    if (message.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          widget.busy != busy ||
          (busy ? widget.status : widget.notice) != message) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
            duration: busy
                ? const Duration(days: 1)
                : const Duration(seconds: 3),
            showCloseIcon: true,
            content: Row(
              children: [
                if (busy) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(child: Text(message)),
              ],
            ),
          ),
        );
      if (!busy) {
        unawaited(widget.controller.act('dismissNotice', {'notice': message}));
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
