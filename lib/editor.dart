import 'app_language.dart';
export 'pdf_picker.dart';

import 'dart:convert';

import 'package:flutter/material.dart';

import 'controller.dart';
import 'history_action_icon.dart';
import 'common.dart';
import 'screens.dart' show bar;
import 'attachment_preview.dart';
import 'markdown_reply.dart';

import 'package:flutter/services.dart';

class DraftPage extends StatefulWidget {
  const DraftPage(this.c, {super.key, this.visible = true});
  final MailController c;
  final bool visible;
  @override
  State<DraftPage> createState() => _DraftPageState();
}

class _DraftPageState extends State<DraftPage> {
  final fields = <String, TextEditingController>{};
  bool dirty = false, extra = false, converting = false;
  Future<void> convertMarkdown() async {
    final before = fields['body']!.text;
    setState(() => converting = true);
    try {
      final plain = await widget.c.request('plainMailBody', {'body': before});
      if (!mounted || fields['body']!.text != before) return;
      fields['body']!.text = plain as String;
      changed();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            strings(context).convertedToEmailBodyReviewBeforeSaving,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings(context).conversionFailedOriginalTextRetained,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => converting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final d = widget.c.data.child('editor');
    for (final key in ['to', 'cc', 'bcc', 'subject', 'body']) {
      fields[key] = TextEditingController(text: d.text(key));
    }
    extra = d.text('cc').isNotEmpty || d.text('bcc').isNotEmpty;
  }

  RowData payload() => {
    ...widget.c.data.child('editor'),
    for (final f in fields.entries) f.key: f.value.text,
  };
  Future<void> leave() async {
    if (dirty &&
        !await confirm(
          context,
          strings(context).discardUnsavedChanges,
          strings(context).savedDraftsAreRetained,
          action: strings(context).discardChanges,
        )) {
      return;
    }
    await widget.c.act('back');
  }

  void changed() {
    dirty = true;
    widget.c.act('updateEditor', payload());
  }

  Future<void> deleteRecord() async {
    if (await confirm(
      context,
      strings(context).deleteThisLocalRecord,
      strings(context).serverEmailsAreRetained,
      action: strings(context).delete,
    )) {
      await widget.c.act('deleteDraft', {
        'id': widget.c.data.child('editor')['id'],
      });
    }
  }

  @override
  void dispose() {
    for (final f in fields.values) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c, d = c.data.child('editor');
    final editable = ['DRAFT', 'FAILED'].contains(d.text('status')) && !c.busy;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.visible) leave();
      },
      child: Column(
        children: [
          AppBar(
            title: Text(
              editable
                  ? strings(context).composeEmail
                  : draftStatus(d.text('status'), context: context),
            ),
            leading: IconButton(
              tooltip: strings(context).back,
              onPressed: leave,
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              if (editable)
                TextButton(
                  onPressed: () {
                    dirty = false;
                    c.act('saveDraft', payload());
                  },
                  child: Text(strings(context).save),
                ),
              if (editable)
                IconButton(
                  tooltip: strings(context).moreEmailActions,
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () async {
                    final action = await showModalBottomSheet<String>(
                      context: context,
                      showDragHandle: true,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      builder: (ctx) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              enabled: !dirty,
                              leading: const Icon(Icons.refresh),
                              title: Text(
                                dirty
                                    ? strings(context).saveChangesAndRewrite
                                    : strings(context).rewrite,
                              ),
                              onTap: () => Navigator.pop(ctx, 'redraft'),
                            ),
                            ListTile(
                              enabled: !converting,
                              leading: const Icon(Icons.text_fields),
                              title: Text(
                                strings(context).convertMarkdownToBodyText,
                              ),
                              onTap: () => Navigator.pop(ctx, 'plain'),
                            ),
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
                    if (!context.mounted) return;
                    if (action == 'plain') await convertMarkdown();
                    if (action == 'delete') await deleteRecord();
                    if (action == 'redraft' && context.mounted) {
                      await draftAction(context, c, d, 'redraft');
                    }
                  },
                ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: c.accounts.any((a) => a['id'] == d['accountId'])
                      ? d.text('accountId')
                      : null,
                  decoration: InputDecoration(
                    labelText: strings(context).sendingAccount,
                  ),
                  items: [
                    for (final a in c.accounts)
                      DropdownMenuItem(
                        value: a.text('id'),
                        child: Text(
                          a.text('email'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  isExpanded: true,
                  onChanged: !editable
                      ? null
                      : (id) {
                          dirty = true;
                          c.act('updateEditor', {
                            ...payload(),
                            'accountId': id,
                          });
                        },
                ),
                const SizedBox(height: 16),
                for (final key in [
                  'to',
                  if (extra) 'cc',
                  if (extra) 'bcc',
                  'subject',
                  'body',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextField(
                      controller: fields[key],
                      enabled: editable,
                      minLines: key == 'body' ? 6 : 1,
                      maxLines: key == 'body' ? null : 2,
                      keyboardType: ['to', 'cc', 'bcc'].contains(key)
                          ? TextInputType.emailAddress
                          : TextInputType.multiline,
                      onChanged: (_) => changed(),
                      decoration: InputDecoration(
                        labelText: {
                          'to': strings(context).to,
                          'cc': strings(context).cc,
                          'bcc': strings(context).bcc,
                          'subject': strings(context).subject,
                          'body': strings(context).body,
                        }[key],
                        helperText: key == 'to'
                            ? strings(context)
                                  .separateMultipleAddressesWithCommas
                            : key == 'body'
                            ? strings(context).sendAsThePlainTextShownHere
                            : null,
                      ),
                    ),
                  ),
                if (editable)
                  Wrap(
                    spacing: 12,
                    runSpacing: 0,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          await c.act('updateEditor', payload());
                          await c.act('pickFile');
                          dirty = true;
                        },
                        icon: const Icon(Icons.attach_file, size: 18),
                        label: Text(strings(context).addAttachment),
                      ),
                      if (!extra)
                        TextButton.icon(
                          onPressed: () => setState(() => extra = true),
                          icon: const Icon(Icons.person_add_outlined, size: 18),
                          label: Text(strings(context).ccBcc),
                        ),
                    ],
                  ),
                for (final file in d.rows('files'))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.attach_file),
                    title: Text(
                      file.text('name'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: editable
                        ? IconButton(
                            tooltip: strings(context)
                                .remove((file.text('name')).toString()),
                            onPressed: () {
                              dirty = true;
                              c.act('updateEditor', {
                                ...payload(),
                                'files': d
                                    .rows('files')
                                    .where((f) => f['path'] != file['path'])
                                    .toList(),
                              });
                            },
                            icon: const Icon(Icons.close, size: 18),
                          )
                        : null,
                  ),
                if (d.text('error').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      d.text('error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (d.text('status') == 'UNKNOWN') ...[
                  Text(strings(context).firstCheckTheServerSSentFolder),
                  TextButton(
                    onPressed: () async {
                      if (await confirm(
                        context,
                        strings(context).verifiedThatSendingSucceeded,
                        strings(context).thisOnlyUpdatesTheLocalRecord,
                      )) {
                        await c.act('resolveUnknown', {
                          'id': d['id'],
                          'sent': true,
                        });
                      }
                    },
                    child: Text(strings(context).verifiedSentSuccessfully),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (await confirm(
                        context,
                        strings(context).confirmedThatNoRecipientsReceivedIt,
                        strings(context).restoreTheDraftToReviewAndSend,
                        action: strings(context).restoreDraft,
                      )) {
                        await c.act('resolveUnknown', {
                          'id': d['id'],
                          'sent': false,
                        });
                      }
                    },
                    child: Text(strings(context).verifiedNotSent),
                  ),
                ],
              ],
            ),
          ),
          if (editable)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    dirty = false;
                    c.act('reviewDraftInChat', payload());
                  },
                  child: Text(strings(context).confirmSendingInChat),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SendPreview extends StatelessWidget {
  const SendPreview(this.c, {super.key});
  final MailController c;
  @override
  Widget build(BuildContext context) {
    final d = c.data.child('sendPreview');
    final account = c.accounts
        .where((a) => a['id'] == d['accountId'])
        .firstOrNull;
    return Column(
      children: [
        bar(context, c, strings(context).confirmBeforeSending, back: true),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                strings(context).pleaseReviewTheFollowing,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              for (final item in [
                (
                  strings(context).from,
                  account?.text('email') ?? strings(context).accountDeleted,
                ),
                (strings(context).to, d.text('to')),
                (strings(context).cc, d.text('cc')),
                (strings(context).bcc, d.text('bcc')),
              ])
                if (item.$2.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SelectableText(
                      '${item.$1}：${item.$2}',
                      style: const TextStyle(fontSize: 14, height: 1.6),
                    ),
                  ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 20),
              SelectableText(
                d.text('subject'),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              SelectableText(
                d.text('body'),
                style: const TextStyle(fontSize: 16, height: 1.8),
              ),
              const SizedBox(height: 24),
              for (final f in d.rows('files'))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.attach_file),
                  title: Text(f.text('name')),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: account != null && !c.busy
                  ? () => c.act('sendConfirmed')
                  : null,
              child: Text(strings(context).confirmSend),
            ),
          ),
        ),
      ],
    );
  }
}

class SourcePage extends StatefulWidget {
  const SourcePage(this.c, {super.key});
  final MailController c;
  @override
  State<SourcePage> createState() => _SourcePageState();
}

class _SourcePageState extends State<SourcePage> {
  RowData info = {};
  String? failure;
  bool loading = true, actionBusy = false;
  bool showOriginal = false;
  Uint8List? image;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  String errorText(Object error) => error is PlatformException
      ? error.message ?? strings(context).couldNotReadAttachment
      : '$error';

  Future<void> load() async {
    final current = ++generation;
    setState(() {
      loading = true;
      failure = null;
      image = null;
    });
    try {
      final raw = await widget.c.request(
        'sourceInfo',
        widget.c.data.child('source'),
      );
      if (!mounted || current != generation) return;
      info = row(jsonDecode(raw as String));
      if (info.text('imagePath').isNotEmpty) {
        final bytes = await widget.c.image(info.text('imagePath'));
        if (!mounted || current != generation) return;
        if (bytes == null || bytes.isEmpty) {
          throw StateError(strings(context).couldNotReadImagePleaseRetry);
        }
        image = bytes;
      }
    } catch (e) {
      if (mounted && current == generation) failure = errorText(e);
    } finally {
      if (mounted && current == generation) setState(() => loading = false);
    }
  }

  Future<void> page(int next) async {
    final current = ++generation;
    setState(() {
      loading = true;
      failure = null;
      image = null;
    });
    try {
      final path = await widget.c.request('pdfPage', {
        'id': info['attachmentId'],
        'page': next,
      });
      final bytes = await widget.c.image(path as String);
      if (!mounted || current != generation) return;
      if (bytes == null || bytes.isEmpty) {
        throw StateError(strings(context).couldNotReadPagePleaseRetry);
      }
      info['page'] = next;
      image = bytes;
    } catch (e) {
      if (mounted && current == generation) failure = errorText(e);
    } finally {
      if (mounted && current == generation) setState(() => loading = false);
    }
  }

  Future<void> fileAction(String method) async {
    if (actionBusy || loading) return;
    setState(() {
      actionBusy = true;
      failure = null;
    });
    try {
      await widget.c.request(method, {
        'id': widget.c.data.child('source')['attachmentId'],
      });
    } catch (e) {
      if (mounted) setState(() => failure = errorText(e));
    } finally {
      if (mounted) setState(() => actionBusy = false);
    }
  }

  Widget retry(String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.image_not_supported_outlined,
          size: 28,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        TextButton(
          onPressed: loading ? null : load,
          child: Text(strings(context).reload),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.c, colors = Theme.of(context).colorScheme;
    final attachment = c.data.child('source').text('attachmentId').isNotEmpty;
    final plainSource =
        info.text('kind') == 'mail' && !info.flag('isModelObservation');
    return Column(
      children: [
        bar(
          context,
          c,
          c.data
              .child('source')
              .text('title', strings(context).referencedMaterial),
          back: true,
          actions: [
            if (info.text('text').isNotEmpty && !plainSource)
              IconButton(
                tooltip: showOriginal
                    ? strings(context).formattedView
                    : strings(context).viewOriginal,
                onPressed: () => setState(() => showOriginal = !showOriginal),
                icon: Icon(
                  showOriginal ? Icons.article_outlined : Icons.code,
                  size: 20,
                ),
              ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              if (info.text('location').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    info.text('location'),
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              if (info.text('url').isNotEmpty)
                TextButton.icon(
                  onPressed: () => c.act('openLink', {'url': info['url']}),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(
                    info.text('url'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (info.flag('isModelObservation'))
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    strings(context).theFollowingWasGeneratedByAVision,
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              if (info.number('count') > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: strings(context).previousPage,
                      onPressed: !loading && info.number('page') > 0
                          ? () => page(info.number('page') - 1)
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      '${info.number('page') + 1} / ${info.number('count')}',
                    ),
                    IconButton(
                      tooltip: strings(context).nextPage,
                      onPressed:
                          !loading &&
                              info.number('page') + 1 < info.number('count')
                          ? () => page(info.number('page') + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              if (loading)
                SizedBox(
                  height: 220,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          strings(context).loadingReferencedMaterial,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (failure != null) retry(failure!),
              if (image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ColoredBox(
                    color: colors.surfaceContainerLow,
                    child: SizedBox(
                      height: (MediaQuery.sizeOf(context).height * .58).clamp(
                        200.0,
                        560.0,
                      ),
                      child: InteractiveViewer(
                        key: ValueKey(
                          '${info['attachmentId']}-${info['page']}',
                        ),
                        minScale: 1,
                        maxScale: 5,
                        child: Center(
                          child: Image.memory(
                            image!,
                            fit: BoxFit.contain,
                            semanticLabel: strings(context)
                                .selectedImageOrPdfPagePinchTo,
                            frameBuilder: (_, child, frame, synchronous) =>
                                synchronous || frame != null
                                ? child
                                : const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                            errorBuilder: (_, error, stack) => retry(
                              strings(context)
                                  .imageUnavailableRetryOrOpenWithAnother,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (image != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    strings(context).pinchToZoomSavingAndExternalOpening,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              if (info.text('text').isNotEmpty) ...[
                const SizedBox(height: 12),
                if (showOriginal || plainSource)
                  SelectableText(
                    info.text('text'),
                    style: const TextStyle(fontSize: 16, height: 1.8),
                  )
                else
                  MarkdownReply(
                    text: readingMarkdown(info.text('text')),
                    controller: c,
                    preserveLineBreaks: true,
                  ),
              ],
            ],
          ),
        ),
        if (attachment)
          AttachmentPreviewActions(
            busy: actionBusy,
            onOpen: loading || actionBusy ? null : () => fileAction('openFile'),
            onSave: loading || actionBusy
                ? null
                : () => fileAction('exportFile'),
          ),
      ],
    );
  }
}
