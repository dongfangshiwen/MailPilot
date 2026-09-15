import 'app_language.dart';

import 'package:flutter/material.dart';

/// A choice stays on its own sheet, so long labels never cover the form.
Future<String?> showModelChoices(
  BuildContext context, {
  required String title,
  required String selected,
  required Map<String, String> choices,
  Map<String, String> descriptions = const {},
  String? description,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) {
      final colors = Theme.of(context).colorScheme;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .78,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: strings(context).close((title).toString()),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: [
                    if (description != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    for (final choice in choices.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: choice.key == selected
                              ? colors.primary.withValues(alpha: .08)
                              : colors.surface,
                          borderRadius: BorderRadius.circular(14),
                          child: Semantics(
                            selected: choice.key == selected,
                            child: ListTile(
                              key: ValueKey('model-choice-${choice.key}'),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              minTileHeight: 56,
                              title: Text(
                                choice.value,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: choice.key == selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: choice.key == selected
                                      ? colors.primary
                                      : colors.onSurface,
                                ),
                              ),
                              subtitle: descriptions[choice.key] == null
                                  ? null
                                  : Text(
                                      descriptions[choice.key]!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.5,
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                              trailing: SizedBox(
                                width: 20,
                                child: choice.key == selected
                                    ? Icon(
                                        Icons.check_rounded,
                                        size: 20,
                                        color: colors.primary,
                                      )
                                    : null,
                              ),
                              onTap: () => Navigator.pop(context, choice.key),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class ModelSettingRow extends StatelessWidget {
  const ModelSettingRow({
    super.key,
    required this.title,
    required this.value,
    required this.onTap,
  });
  final String title, value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
