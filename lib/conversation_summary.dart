import 'app_language.dart';

import 'package:flutter/material.dart';

import 'controller.dart';
import 'markdown_reply.dart';

/// Opening this view reads the saved summary; it never requests another summary.
Future<void> showConversationSummary(BuildContext context, MailController c) {
  final conversationId = c.data.text('conversationId');
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) => ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final current = c.data.text('conversationId') == conversationId;
        final text = current ? c.data.text('contextSummary') : '';
        return SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .78,
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
                                strings(context).thisConversationSSummary,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (text.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  strings(context).summarizedMessageCount(
                                    (c.data.number('summarizedEntries')),
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: strings(context).closeSummary,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 20),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (text.isNotEmpty) ...[
                            Text(
                              strings(context)
                                  .originalMessagesAreRetainedYouCanAdd,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            MarkdownReply(
                              text: readingMarkdown(text),
                              controller: c,
                              preserveLineBreaks: true,
                            ),
                          ] else
                            Text(
                              current
                                  ? strings(context)
                                        .noSummaryForThisConversationYet
                                  : strings(
                                      context,
                                    ).conversationChangedPleaseReopenTheSummary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
