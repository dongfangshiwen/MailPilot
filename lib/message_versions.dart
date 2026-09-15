import 'app_language.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controller.dart';

/// Version navigation lives in the transcript, never in a second conversation.
class MessageVersionPager extends StatelessWidget {
  const MessageVersionPager({
    super.key,
    required this.index,
    required this.count,
    this.loading = false,
    this.onPrevious,
    this.onNext,
  });
  final int index, count;
  final bool loading;
  final VoidCallback? onPrevious, onNext;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: strings(context).previousVersion,
          onPressed: loading ? null : onPrevious,
          color: colors.onSurfaceVariant,
          disabledColor: colors.onSurfaceVariant.withValues(alpha: .28),
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 4),
          icon: const Icon(Icons.chevron_left_rounded, size: 20),
        ),
        Semantics(
          liveRegion: true,
          label: strings(context)
              .messageVersionCount((index + 1).toString(), (count).toString()),
          child: ExcludeSemantics(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 32),
              child: Center(
                child: loading
                    ? SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.4,
                          color: colors.onSurfaceVariant,
                        ),
                      )
                    : Text(
                        '${index + 1} / $count',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: strings(context).nextVersion,
          onPressed: loading ? null : onNext,
          color: colors.onSurfaceVariant,
          disabledColor: colors.onSurfaceVariant.withValues(alpha: .28),
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 4),
          icon: const Icon(Icons.chevron_right_rounded, size: 20),
        ),
      ],
    );
  }
}

Future<bool> showUserMessageActions(
  BuildContext context,
  RowData entry, {
  required bool canEdit,
}) async {
  final colors = Theme.of(context).colorScheme;
  final result = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    backgroundColor: colors.surface,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    strings(context).messageActions,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: strings(context).closeMessageActions,
                  onPressed: () => Navigator.pop(ctx),
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (canEdit)
            ListTile(
              leading: Icon(
                Icons.edit_outlined,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
              title: Text(strings(context).editInput),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
          ListTile(
            leading: Icon(
              Icons.copy_outlined,
              size: 20,
              color: colors.onSurfaceVariant,
            ),
            title: Text(strings(context).copyMessage),
            onTap: () => Navigator.pop(ctx, 'copy'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
  if (result == 'copy') {
    await Clipboard.setData(ClipboardData(text: entry.text('text')));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings(context).messageCopied),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  return result == 'edit';
}
