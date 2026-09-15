import 'app_language.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controller.dart';

String materialSize(int size, {BuildContext? context}) => size < 0
    ? strings(context).sizeUnknown
    : size < 1024 * 1024
    ? '${(size / 1024).ceil()} KB'
    : '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';

String pdfRange(RowData a, {BuildContext? context}) {
  if (a.flag('defaultPages')) {
    return strings(context).firstPagesByDefaultPageCountPending;
  }
  final pages = (a['pages'] as List? ?? []).cast<int>()..sort();
  if (pages.isEmpty) return strings(context).selectPdfPageNumbers;
  final runs = <String>[];
  for (var i = 0; i < pages.length; i++) {
    final start = pages[i] + 1;
    var end = start;
    while (i + 1 < pages.length && pages[i + 1] == pages[i] + 1) {
      end = pages[++i] + 1;
    }
    runs.add(start == end ? '$start' : '$start–$end');
  }
  return strings(context).page((runs.join('、')).toString());
}

class AttachmentSelectionTile extends StatelessWidget {
  const AttachmentSelectionTile({
    super.key,
    required this.file,
    required this.selected,
    required this.onToggle,
    required this.onPreview,
    this.onPages,
  });
  final RowData file;
  final bool selected;
  final VoidCallback? onToggle, onPreview, onPages;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ext = file.text('name').split('.').last.toUpperCase();
    final reason = file.text('selectionReason');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 2, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                ext == 'PDF'
                    ? Icons.picture_as_pdf_outlined
                    : ['JPG', 'JPEG', 'PNG', 'WEBP'].contains(ext)
                    ? Icons.image_outlined
                    : Icons.description_outlined,
                size: 22,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: onPreview,
                      onLongPress: () => showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(strings(context).fileName),
                          content: SelectableText(file.text('name')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(strings(context).off),
                            ),
                          ],
                        ),
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.text('name'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$ext · ${materialSize(file.number('size', -1), context: context)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (reason.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          reason,
                          style: TextStyle(fontSize: 12, color: colors.error),
                        ),
                      ),
                    if (onPages != null && reason.isEmpty)
                      TextButton.icon(
                        onPressed: onPages,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          minimumSize: const Size(48, 48),
                        ),
                        icon: const Icon(Icons.tune_rounded, size: 15),
                        label: Text(
                          pdfRange(file, context: context),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: Checkbox(
                  semanticLabel:
                      '${selected ? strings(context).deselect : strings(context).select420} ${file.text('name')}',
                  value: selected,
                  onChanged:
                      onToggle == null || (!selected && reason.isNotEmpty)
                      ? null
                      : (_) => onToggle!(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<RowData> refreshMaterialBudget(MailController c) async {
  final raw = await c.request('selectionSummary');
  return raw is String ? row(jsonDecode(raw)) : row(raw);
}

Future<void> showMaterialsSheet(
  BuildContext context,
  MailController c, {
  String? retryId,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await c.act('selectionSummary');
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(ctx).height * .76,
        child: ListenableBuilder(
          listenable: c,
          builder: (ctx, _) {
            final colors = Theme.of(ctx).colorScheme;
            final summary = c.data.child('selectionBudget');
            final groups = c.data.rows('selectionGroups');
            void open(String method, String id) {
              Navigator.pop(ctx);
              c.act(method, {'id': id});
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings(context).materialsForThisAnalysis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              strings(context).materialSummary(
                                (summary.number('count')).toString(),
                                (materialSize(
                                  summary.number('bytes'),
                                  context: context,
                                )).toString(),
                                (summary.number('unknown') > 0
                                        ? strings(context).withUnknownSize(
                                            (summary.number('unknown'))
                                                .toString(),
                                          )
                                        : '')
                                    .toString(),
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: strings(context).closeMaterials,
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: summary.flag('blocked')
                              ? colors.errorContainer
                              : colors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          summary.flag('blocked')
                              ? summary.strings('issues').join('\n')
                              : strings(context).upToAttachmentsMbAndImagesOr(
                                  (summary.flag('pendingVisuals')
                                          ? strings(context)
                                                .actualImageCountsInPdfAndOffice
                                          : strings(
                                              context,
                                            ).selectedFilesAreReadOnlyWhenPreviewing)
                                      .toString(),
                                ),
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: summary.flag('blocked')
                                ? colors.onErrorContainer
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      for (final group in groups) ...[
                        const SizedBox(height: 16),
                        Text(
                          group.text('subject'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (group.flag('pending'))
                          Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              strings(context).attachmentListAwaitingSync,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: () => c.act('selectMessageFiles', {
                                'id': group['messageId'],
                              }),
                              child: Text(
                                strings(context).selectAllSupportedAttachments,
                              ),
                            ),
                            TextButton(
                              onPressed: () => c.act('selectMessageFiles', {
                                'id': group['messageId'],
                                'bodyOnly': true,
                              }),
                              child: Text(strings(context).keepBodyOnly),
                            ),
                          ],
                        ),
                        for (final a in group.rows('attachments'))
                          AttachmentSelectionTile(
                            key: ValueKey('material-${a.text('id')}'),
                            file: a,
                            selected: a.flag('selected'),
                            onToggle: () =>
                                c.act('selectAttachment', {'id': a['id']}),
                            onPreview: () => open('preview', a.text('id')),
                            onPages:
                                a.text('name').toLowerCase().endsWith('.pdf')
                                ? () => open('editPdf', a.text('id'))
                                : null,
                          ),
                      ],
                      if (c.data.rows('localMaterials').isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.only(top: 16, bottom: 8),
                          child: Text(
                            strings(context).deviceFiles,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        for (final a in c.data.rows('localMaterials'))
                          AttachmentSelectionTile(
                            file: a,
                            selected: a.flag('selected'),
                            onToggle: () =>
                                c.act('toggleLocal', {'id': a['id']}),
                            onPreview: () {
                              Navigator.pop(ctx);
                              c.act('showSource', {
                                'source': {
                                  'attachmentId': a['id'],
                                  'title': a['name'],
                                  'kind': 'attachment-preview',
                                },
                              });
                            },
                            onPages:
                                a.text('name').toLowerCase().endsWith('.pdf')
                                ? () => open('localPdf', a.text('id'))
                                : null,
                          ),
                      ],
                      VisualReuseOptions(c),
                      if (groups.isEmpty &&
                          c.data.rows('localMaterials').isEmpty)
                        Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            strings(context)
                                .noMaterialsSelectedAddFilesOrSelect,
                          ),
                        ),
                      if (retryId != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: FilledButton(
                            onPressed: summary.flag('blocked')
                                ? null
                                : () async {
                                    try {
                                      if ((await refreshMaterialBudget(c))
                                              .flag('blocked') ||
                                          !ctx.mounted) {
                                        return;
                                      }
                                      Navigator.pop(ctx);
                                      await c.act('retryAnalysis', {
                                        'id': retryId,
                                        'useCurrentMaterials': true,
                                      });
                                    } on PlatformException catch (e) {
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              e.message ??
                                                  strings(context)
                                                      .materialCheckIncomplete,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: Text(
                              strings(context).retryWithCurrentMaterials,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// Reads only stored analysis metadata; opening this section never downloads images.
class VisualReuseOptions extends StatefulWidget {
  const VisualReuseOptions(this.controller, {super.key});
  final MailController controller;
  @override
  State<VisualReuseOptions> createState() => _VisualReuseOptionsState();
}

class _VisualReuseOptionsState extends State<VisualReuseOptions> {
  List<RowData> images = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final value = await widget.controller.request('visualMaterials');
      final list = value is String ? jsonDecode(value) : value;
      if (mounted && list is List) {
        setState(() => images = list.map(row).toList());
      }
    } catch (_) {
      /* Older preview backends have no stored image observations. */
    }
  }

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings(context).analyzedImages,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            strings(context).previousAnalysisIsReusedByDefaultSelect,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: colors.onSurfaceVariant,
            ),
          ),
          for (final image in images)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.image_outlined, size: 20),
              title: Text(
                image.text('title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
              subtitle: Text(
                image.text('location'),
                style: const TextStyle(fontSize: 12),
              ),
              trailing: IconButton(
                tooltip: image.flag('pending')
                    ? strings(context).cancelRecheck
                    : strings(context).recheckImages,
                icon: Icon(
                  image.flag('pending')
                      ? Icons.check_circle_outline
                      : Icons.refresh_rounded,
                  size: 21,
                ),
                onPressed: () async {
                  await widget.controller.act('recheckVisual', {
                    'assetKey': image['assetKey'],
                  });
                  await load();
                },
              ),
            ),
        ],
      ),
    );
  }
}
