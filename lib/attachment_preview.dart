import 'app_language.dart';

import 'package:flutter/material.dart';

import 'controller.dart';

bool isImageAttachment(RowData attachment) =>
    attachment.text('mimeType').toLowerCase().startsWith('image/') ||
    const {
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
      'bmp',
      'heic',
      'heif',
      'avif',
    }.contains(attachment.text('name').split('.').last.toLowerCase());

/// Gallery-style footer, kept outside the image's scrolling/zooming surface.
class AttachmentPreviewActions extends StatelessWidget {
  const AttachmentPreviewActions({
    super.key,
    required this.onOpen,
    required this.onSave,
    this.busy = false,
  });
  final VoidCallback? onOpen, onSave;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget action(
      String label,
      String visible,
      IconData icon,
      VoidCallback? tap,
    ) => Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: Tooltip(
          message: label,
          child: InkWell(
            onTap: tap,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: tap == null
                          ? colors.outlineVariant
                          : colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      visible,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: tap == null
                            ? colors.onSurfaceVariant.withValues(alpha: .5)
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Material(
      color: colors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy) const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  action(
                    strings(context).openWithAnotherApp,
                    strings(context).openInAnotherApp,
                    Icons.open_in_new_rounded,
                    onOpen,
                  ),
                  const SizedBox(width: 12),
                  action(
                    strings(context).saveToDevice,
                    strings(context).saveToDevice,
                    Icons.save_alt_rounded,
                    onSave,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
