import 'app_language.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'controller.dart';
import 'history_action_icon.dart';

String mailDate(dynamic value, {BuildContext? context}) {
  final d = DateTime.fromMillisecondsSinceEpoch((value as num? ?? 0).toInt())
      .toLocal();
  if (context == null) {
    return '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
  return DateFormat.Md(Localizations.localeOf(context).toString())
      .add_Hm()
      .format(d);
}

String folderName(String name, {BuildContext? context}) =>
    {
      'inbox': strings(context).inbox,
      'sent': strings(context).sent,
      'sent messages': strings(context).sent,
      'sent items': strings(context).sent,
      'drafts': strings(context).drafts,
      'trash': strings(context).deleted,
      'deleted messages': strings(context).deleted,
      'deleted items': strings(context).deleted,
      'junk': strings(context).spam,
      'spam': strings(context).spam,
      'archive': strings(context).archive,
      'archives': strings(context).archive,
    }[name.toLowerCase()] ??
    name;

Future<void> showFolderPicker(BuildContext context, MailController c) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          final s = c.data;
          final names =
              {...s.strings('folders'), s.text('folder', 'INBOX')}.toList()
                ..sort(
                  (a, b) => a.toLowerCase() == 'inbox'
                      ? -1
                      : b.toLowerCase() == 'inbox'
                      ? 1
                      : a.compareTo(b),
                );
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings(context).mailFolders,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (s.flag('foldersLoading'))
                        const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        IconButton(
                          tooltip: strings(context).refreshFolders,
                          onPressed: () => c.act('loadFolders'),
                          icon: const Icon(Icons.refresh),
                        ),
                    ],
                  ),
                ),
                if (s.text('foldersError').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                    child: Text(
                      strings(context).couldNotRefreshFoldersLocalListRetained(
                        (s.text('foldersError')).toString(),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final name in names)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
                          leading: Icon(
                            name.toLowerCase() == 'inbox'
                                ? Icons.inbox_outlined
                                : Icons.folder_outlined,
                          ),
                          title: Text(folderName(name, context: context)),
                          selected: name == s.text('folder'),
                          trailing: name == s.text('folder')
                              ? const Icon(Icons.check, size: 20)
                              : null,
                          onTap: () {
                            Navigator.pop(context);
                            if (name != s.text('folder')) {
                              c.act('folder', {'value': name});
                            }
                          },
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  title: Text(strings(context).unreadOnly),
                  value: s.flag('unreadOnly'),
                  onChanged: (value) {
                    Navigator.pop(context);
                    c.act('search', {
                      'query': s.text('query'),
                      'unread': value,
                      'remote': false,
                    });
                  },
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

Future<void> draftAction(
  BuildContext context,
  MailController c,
  RowData draft,
  String action,
) async {
  if (action == 'redraft') {
    await c.act('redraft', {'id': draft['id']});
  } else if (action == 'delete' &&
      await confirm(
        context,
        strings(context).deleteThisDraft,
        strings(context).onlyTheLocalDraftIsDeletedChats,
        action: strings(context).delete,
      )) {
    await c.act('deleteDraft', {'id': draft['id']});
  }
}

Widget draftMenu(BuildContext context, MailController c, RowData draft) =>
    IconButton(
      tooltip: strings(context).draftActions,
      icon: const Icon(Icons.more_horiz),
      onPressed: c.busy || ['SENDING', 'UNKNOWN'].contains(draft.text('status'))
          ? null
          : () async {
              final choice = await showModalBottomSheet<String>(
                context: context,
                showDragHandle: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: Text(strings(context).editEmail),
                        onTap: () => Navigator.pop(ctx, 'edit'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.refresh_rounded),
                        title: Text(strings(context).rewrite),
                        onTap: () => Navigator.pop(ctx, 'redraft'),
                      ),
                      if (['DRAFT', 'FAILED'].contains(draft.text('status')))
                        ListTile(
                          leading: const HistoryActionIcon(
                            HistoryAction.delete,
                            size: 16,
                            color: historyDeleteColor,
                          ),
                          title: Text(
                            strings(context).deleteDraft,
                            style: TextStyle(color: historyDeleteColor),
                          ),
                          onTap: () => Navigator.pop(ctx, 'delete'),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
              if (!context.mounted || choice == null) return;
              if (choice == 'edit') {
                await c.act('editDraft', {'id': draft['id']});
              } else {
                await draftAction(context, c, draft, choice);
              }
            },
    );

Future<void> recipientSheet(
  BuildContext context,
  MailController c,
  RowData entry,
) async {
  final input = TextEditingController(
    text: entry.child('draftPreview').text('to'),
  );
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          4,
          24,
          MediaQuery.viewInsetsOf(ctx).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings(context).addRecipient,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: input,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: strings(context).recipientEmail,
                hintText: 'name@example.com',
                helperText: strings(context)
                    .separateMultipleAddressesWithCommas,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              strings(context).afterSavingReviewTheNewConfirmationCard,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () {
                  if (input.text.trim().isEmpty) return;
                  c.act('fillRecipient', {
                    'id': entry['id'],
                    'address': input.text.trim(),
                  });
                  Navigator.pop(ctx);
                },
                child: Text(strings(context).saveRecipients),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  // The route can still be animating when the future resolves.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  input.dispose();
}

class UserMessage extends StatelessWidget {
  const UserMessage(this.entry, {super.key, this.onTap});
  final VoidCallback? onTap;
  final RowData entry;
  @override
  Widget build(BuildContext context) {
    final text = entry.text('text');
    final legacy =
        text.startsWith('请将本次对话中这条回答涉及的内容写成正式邮件：') &&
        text.contains('供我检查并确认发送。');
    if (legacy) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings(context).turnThisAnswerIntoAnEmail,
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (ctx) => SafeArea(
                child: SizedBox(
                  height: MediaQuery.sizeOf(ctx).height * .6,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: SelectableText(text),
                  ),
                ),
              ),
            ),
            child: Text(strings(context).viewOriginalOfOlderVersion),
          ),
        ],
      );
    }
    if (onTap != null) {
      return Semantics(
        button: true,
        label: strings(context).messageActions,
        child: InkWell(
          key: ValueKey('user-bubble-${entry.text('id')}'),
          onTap: onTap,
          onLongPress: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              entry.text('action') == 'draft_answer'
                  ? strings(context).turnThisAnswerIntoAnEmail
                  : text,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
          ),
        ),
      );
    }
    return SelectableText(
      entry.text('action') == 'draft_answer'
          ? strings(context).turnThisAnswerIntoAnEmail
          : text,
      style: const TextStyle(fontSize: 16, height: 1.6),
    );
  }
}

String draftStatus(String name, {BuildContext? context}) =>
    {
      'SENT': strings(context).sent,
      'UNKNOWN': strings(context).needsVerification,
      'SENDING': strings(context).sending,
      'FAILED': strings(context).sendFailed,
      'DRAFT': strings(context).drafts,
    }[name] ??
    name;
Future<bool> confirm(
  BuildContext context,
  String title,
  String body, {
  String? action,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action ?? strings(context).confirm),
          ),
        ],
      ),
    ) ??
    false;

class QuietEmpty extends StatelessWidget {
  const QuietEmpty(
    this.title,
    this.subtitle, {
    super.key,
    this.action,
    this.icon = Icons.mail_outline_rounded,
  });
  final String title, subtitle;
  final Widget? action;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 22), action!],
        ],
      ),
    ),
  );
}

class MailTile extends StatelessWidget {
  const MailTile({
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
    return Material(
      color: selected ? colors.primary.withValues(alpha: .045) : colors.surface,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (mail.flag('unread')) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                        ],
                        Expanded(
                          child: Text(
                            mail.text('sender'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Text(
                          mailDate(mail['sentAt'], context: context),
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      mail.text('subject', strings(context).noSubject),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      mail.text('preview'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (mail.number('attachmentCount') > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.attach_file,
                              size: 14,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              strings(context).attachmentCount(
                                (mail.number('attachmentCount')),
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Semantics(
                label: strings(context)
                    .select((mail.text('subject')).toString()),
                child: Checkbox(
                  value: selected,
                  shape: const CircleBorder(),
                  onChanged: (_) => onSelect(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
