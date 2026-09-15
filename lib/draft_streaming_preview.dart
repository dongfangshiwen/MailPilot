import 'app_language.dart';

import 'package:flutter/material.dart';

import 'controller.dart';

/// A candidate has no draft ID or send action until the native transaction commits.
class DraftStreamingPreview extends StatelessWidget {
  const DraftStreamingPreview({
    super.key,
    required this.partial,
    required this.running,
  });
  final RowData partial;
  final bool running;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            running
                ? strings(context).draftingReadOnlyPreview
                : strings(context).incompleteCannotSend,
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
          if (partial.text('subject').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              partial.text('subject'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
          if (partial.text('body').isNotEmpty) ...[
            const SizedBox(height: 12),
            SelectableText(
              partial.text('body'),
              style: const TextStyle(height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> showRunDiagnostics(BuildContext context, RowData value) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _RunDiagnosticsSheet(value),
    );

class _RunDiagnosticsSheet extends StatelessWidget {
  const _RunDiagnosticsSheet(this.value);
  final RowData value;

  bool has(String key) =>
      value[key] != null &&
      value.text(key).isNotEmpty &&
      value.text(key) != 'null';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final stage =
        {
          'draft': strings(context).draftingEmail,
          'answer': strings(context).generatingResponse,
          'vision': strings(context).readingImages,
          'preparing': strings(context).preparingMaterials,
          'generating': strings(context).generatingContent,
          'action_validation': strings(context).parsingModelAction,
          'synthesis': strings(context).organizingExistingResults,
          'context': strings(context).organizingContext,
          'compression': strings(context).organizingContext,
          'search': strings(context).webSearch,
        }[value.text('stage')] ??
        value.text('stage', strings(context).currentRequest);
    final details = {
      for (final field in {
        'requestId': strings(context).requestId,
        'providerRequestId': strings(context).serverId,
        'httpStatus': strings(context).httpStatus,
        'finishReason': strings(context).finishReason,
        'cause': strings(context).exceptionType,
        'reason': strings(context).validationResult,
      }.entries)
        if (has(field.key) &&
            !(field.key == 'httpStatus' && value[field.key] == 0))
          field.value: value.text(field.key),
    };
    return SafeArea(
      top: false,
      child: SizedBox(
        width: double.infinity,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            has('inputBudget')
                                ? strings(context).requestBudgetAndDiagnostics
                                : strings(context).connectionDiagnostics,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strings(context).requestRecordsForThisTurn,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: strings(context).closeDiagnostics,
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _DiagnosticRow(
                              strings(context).processingStage,
                              stage,
                            ),
                            if (has('model'))
                              _DiagnosticRow(
                                strings(context).model,
                                value.text('model'),
                              ),
                            if (has('host'))
                              _DiagnosticRow(
                                strings(context).apiHost,
                                value.text('host'),
                              ),
                            if (has('processingMode'))
                              _DiagnosticRow(
                                strings(context).imageProcessing,
                                {
                                      'complete': strings(context)
                                          .fullTextAndImageResponse,
                                      'helper': strings(context)
                                          .visionAssistantReading,
                                      'batch': strings(context)
                                          .batchProcessingSelectedForThisTurn,
                                      'reuse': strings(context)
                                          .reusingPreviousAnalysis,
                                    }[value.text('processingMode')] ??
                                    value.text('processingMode'),
                              ),
                            if (has('imageRequests'))
                              _DiagnosticRow(
                                strings(context).requestsWithImages,
                                strings(
                                  context,
                                ).requestCount(value.number('imageRequests')),
                              ),
                            if (has('uploadedImages'))
                              _DiagnosticRow(
                                strings(context).totalImagesUploaded,
                                strings(context)
                                    .imageCount(value.number('uploadedImages')),
                              ),
                            if (has('cacheHits'))
                              _DiagnosticRow(
                                strings(context).reusedImages,
                                strings(context)
                                    .imageCount(value.number('cacheHits')),
                              ),
                            if (has('batchReason'))
                              _DiagnosticRow(
                                strings(context).batchingReason,
                                value.text('batchReason'),
                              ),
                          ],
                        ),
                      ),
                      if (has('inputBudget')) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final field in {
                                'estimatedInputTokens': strings(context)
                                    .estimatedInput,
                                'inputBudget': strings(context)
                                    .availableInputBudget,
                                'contextTokens': strings(context)
                                    .configuredContext,
                                'outputReserve': strings(context).outputReserve,
                                'thinkingReserve': strings(context)
                                    .thinkingReserve,
                                'summaryTarget': strings(context)
                                    .suggestedSummaryLength,
                                'summaryBudget': strings(context)
                                    .summaryBudgetLimit,
                                'estimatedSummaryTokens': strings(context)
                                    .currentSummaryEstimate,
                              }.entries)
                                if (has(field.key))
                                  _DiagnosticRow(
                                    field.value,
                                    '${value.text(field.key)} Token',
                                  ),
                              const SizedBox(height: 8),
                              Text(
                                strings(
                                  context,
                                ).localEstimatesMayDifferFromProviderMetering,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (has('firstByteMs') || has('elapsedMs')) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              if (has('firstByteMs'))
                                _DiagnosticRow(
                                  strings(context).timeToFirstChunk,
                                  '${value.text('firstByteMs')} ms',
                                ),
                              if (has('lastByteMs'))
                                _DiagnosticRow(
                                  strings(context).lastChunkReceived,
                                  '${value.text('lastByteMs')} ms',
                                ),
                              if (has('elapsedMs'))
                                _DiagnosticRow(
                                  strings(context).requestDuration,
                                  '${value.text('elapsedMs')} ms',
                                ),
                            ],
                          ),
                        ),
                      ],
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            collapsedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(
                              strings(context).technicalDetails,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              strings(context)
                                  .requestIdsAndExceptionInformation,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            iconColor: colors.onSurfaceVariant,
                            collapsedIconColor: colors.onSurfaceVariant,
                            textColor: colors.onSurface,
                            collapsedTextColor: colors.onSurface,
                            children: [
                              for (final field in details.entries)
                                _DiagnosticRow(field.key, field.value),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final caption = Text(
      label,
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
    final content = SelectableText(
      value,
      style: const TextStyle(fontSize: 14, height: 1.45),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: MediaQuery.textScalerOf(context).scale(14) > 20
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [caption, const SizedBox(height: 4), content],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 84, child: caption),
                const SizedBox(width: 12),
                Expanded(child: content),
              ],
            ),
    );
  }
}
