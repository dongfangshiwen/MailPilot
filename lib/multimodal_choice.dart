import 'app_language.dart';

import 'package:flutter/material.dart';

import 'controller.dart';
import 'materials_sheet.dart';

Future<void> showMultimodalChoice(
  BuildContext context,
  MailController c,
  RowData entry,
) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (ctx) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings(context).chooseImageProcessing,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              entry.child('failure').text('message'),
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              strings(context).yourQuestionMaterialsAndCompletedAnalysisAre,
              style: TextStyle(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_open_outlined, size: 22),
              title: Text(strings(context).adjustMaterials),
              subtitle: Text(strings(context).reduceImagesPagesOrTextAndSubmit),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20),
              onTap: () => Navigator.pop(ctx, 'materials'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_library_outlined, size: 22),
              title: Text(strings(context).processThisTurnInBatches),
              subtitle: Text(
                strings(context).readUnfinishedImagesInBatchesThenSummarize,
              ),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20),
              onTap: () => Navigator.pop(ctx, 'batch'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(strings(context).back),
            ),
          ],
        ),
      ),
    ),
  );
  if (!context.mounted || c.busy) return;
  if (action == 'materials') {
    await showMaterialsSheet(context, c, retryId: entry.text('id'));
  } else if (action == 'batch') {
    await c.act('retryAnalysis', {'id': entry.text('id'), 'batchImages': true});
  }
}
