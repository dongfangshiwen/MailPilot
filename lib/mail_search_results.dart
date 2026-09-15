import 'app_language.dart';

import 'package:flutter/material.dart';

import 'common.dart';
import 'controller.dart';

/// A bounded view of the current retrieval; browsing never changes selection.
class MailSearchResults extends StatefulWidget {
  const MailSearchResults({
    super.key,
    required this.mails,
    required this.isSelected,
    required this.onOpen,
    required this.onSelect,
    required this.onInteract,
  });

  final List<RowData> mails;
  final bool Function(String) isSelected;
  final ValueChanged<String> onOpen, onSelect;
  final VoidCallback onInteract;

  @override
  State<MailSearchResults> createState() => _MailSearchResultsState();
}

class _MailSearchResultsState extends State<MailSearchResults>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  static const previewCount = 2, pageSize = 5;
  bool expanded = false;
  int page = 0;
  int get pages => (widget.mails.length / pageSize).ceil();

  @override
  void didUpdateWidget(MailSearchResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the current page anchored when a later tool result updates the list.
    final start = page * pageSize;
    if (expanded && start < oldWidget.mails.length) {
      final id = oldWidget.mails[start].text('id');
      final index = widget.mails.indexWhere((m) => m.text('id') == id);
      if (index >= 0) page = index ~/ pageSize;
    }
    page = page.clamp(0, pages > 0 ? pages - 1 : 0);
  }

  void toggle() {
    widget.onInteract();
    setState(() => expanded = !expanded);
  }

  void move(int delta) {
    widget.onInteract();
    setState(() => page += delta);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.mails.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final canExpand = widget.mails.length > previewCount;
    final visible = expanded
        ? widget.mails.skip(page * pageSize).take(pageSize)
        : widget.mails.take(previewCount);
    return Material(
      key: const ValueKey('mail-search-results-card'),
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            expanded: canExpand ? expanded : null,
            child: InkWell(
              key: const ValueKey('mail-search-results-toggle'),
              onTap: canExpand ? toggle : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 24),
                  child: Row(
                    children: [
                      Icon(
                        Icons.manage_search_rounded,
                        size: 22,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          strings(context).emailCount((widget.mails.length)),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (canExpand)
                        Icon(
                          expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          for (final mail in visible) ...[
            const Divider(),
            _MailResultRow(
              key: ValueKey('mail-result-${mail.text('id')}'),
              mail: mail,
              selected: widget.isSelected(mail.text('id')),
              onOpen: () {
                widget.onInteract();
                widget.onOpen(mail.text('id'));
              },
              onSelect: () {
                widget.onInteract();
                widget.onSelect(mail.text('id'));
              },
            ),
          ],
          if (canExpand) ...[
            const Divider(),
            if (!expanded)
              TextButton(
                key: const ValueKey('mail-search-results-expand'),
                onPressed: toggle,
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: Text(
                  strings(context).expandEmailCount((widget.mails.length)),
                ),
              )
            else
              Row(
                children: [
                  IconButton(
                    tooltip: strings(context).previousEmailPage,
                    onPressed: page > 0 ? () => move(-1) : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      '${page + 1} / $pages',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: strings(context).nextEmailPage,
                    onPressed: page + 1 < pages ? () => move(1) : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                  TextButton(
                    onPressed: toggle,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    child: Text(strings(context).collapse),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _MailResultRow extends StatelessWidget {
  const _MailResultRow({
    super.key,
    required this.mail,
    required this.selected,
    required this.onOpen,
    required this.onSelect,
  });
  final RowData mail;
  final bool selected;
  final VoidCallback onOpen, onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mail.text('subject').isEmpty
                        ? strings(context).noSubject
                        : mail.text('subject'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      mail.text('sender'),
                      mailDate(mail['sentAt'], context: context),
                    ].where((v) => v.isNotEmpty).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              label: strings(context).select((mail.text('subject')).toString()),
              child: Checkbox(
                value: selected,
                shape: const CircleBorder(),
                onChanged: (_) => onSelect(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
