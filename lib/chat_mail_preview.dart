import 'app_language.dart';

import 'package:flutter/material.dart';

import 'controller.dart';
import 'common.dart';

/// An immutable copy of the draft reviewed in this message, not the live editor.
class ChatMailPreview extends StatelessWidget {
  const ChatMailPreview(this.c, this.entry, {super.key});
  final MailController c;
  final RowData entry;

  @override
  Widget build(BuildContext context) {
    final d = entry.child('draftPreview');
    final historical = entry.flag('historical');
    final current = c.data
        .rows('drafts')
        .where((item) => item['id'] == d['id'])
        .firstOrNull;
    final colors = Theme.of(context).colorScheme;
    // Native review conditions are shared with the final SMTP gate.
    final review = entry.child('review');
    final state = review.text(
      'label',
      current == null
          ? strings(context).draftDeleted
          : strings(context).pleaseViewTheLatestVersion,
    );
    final action = review.text('action', current == null ? '' : 'latest');
    final ready = review.flag('canSend');
    return Container(
      key: ValueKey('chat-mail-${entry.text('id')}'),
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mail_outline, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in [
            (strings(context).from, d.text('senderEmail')),
            (strings(context).to, d.text('to', '')),
            (strings(context).cc, d.text('cc')),
            (strings(context).bcc, d.text('bcc')),
          ])
            if (item.$2.isNotEmpty || item.$1 == strings(context).to)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: SelectableText(
                  '${item.$1}：${item.$2.isEmpty ? strings(context).notEntered : item.$2}',
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
          const Divider(height: 24),
          SelectableText(
            d.text('subject').isEmpty
                ? strings(context).noSubject
                : d.text('subject'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SelectableText(
            d.text('body'),
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
          if (d.rows('files').isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final file in d.rows('files'))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        file.text('name'),
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (!historical) ...[
            const SizedBox(height: 14),
            if (ready && d.text('to').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  strings(context).afterReviewingConfirmSendingOrTapThe,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            Wrap(
              spacing: 8,
              children: [
                if (action == 'send')
                  FilledButton(
                    onPressed: c.busy
                        ? null
                        : () => c.act('confirmChatSend', {'id': entry['id']}),
                    child: Text(strings(context).confirmSend),
                  ),
                if (action == 'recipient')
                  FilledButton(
                    onPressed: c.busy
                        ? null
                        : () => recipientSheet(context, c, entry),
                    child: Text(strings(context).addRecipient),
                  ),
                if (action == 'latest')
                  OutlinedButton(
                    onPressed: c.busy
                        ? null
                        : () => c.act('latestDraft', {'id': d['id']}),
                    child: Text(strings(context).viewLatestVersion),
                  ),
                if (current != null && action != 'latest')
                  TextButton(
                    onPressed: c.busy
                        ? null
                        : () => c.act('editDraft', {'id': d['id']}),
                    child: Text(
                      action == 'edit'
                          ? strings(context).reviewAndEdit
                          : strings(context).editEmail,
                    ),
                  ),
                if (current != null) draftMenu(context, c, current),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
