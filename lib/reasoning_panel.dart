import 'app_language.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import 'controller.dart';
import 'stream_text.dart';
import 'stream_scroll_follower.dart';

/// Shows only the displayable reasoning text supplied by the configured API.
class ReasoningPanel extends StatefulWidget {
  const ReasoningPanel({super.key, required this.reasoning});
  final RowData reasoning;

  @override
  State<ReasoningPanel> createState() => _ReasoningPanelState();
}

class _ReasoningPanelState extends State<ReasoningPanel>
    with SingleTickerProviderStateMixin {
  final scroll = ScrollController();
  late final follower = StreamScrollFollower(scroll, this);
  bool followText = true;
  final clock = Stopwatch();
  Timer? ticker;
  late bool expanded;
  bool userToggled = false;
  String? viewedAttempt;
  RowData get displayed => viewedAttempt == null
      ? widget.reasoning
      : widget.reasoning
                .rows('previous')
                .where((v) => v.text('attemptId') == viewedAttempt)
                .firstOrNull ??
            widget.reasoning;
  bool get active =>
      viewedAttempt == null && widget.reasoning.text('state') == 'thinking';
  bool completed(RowData value) => value.containsKey('runComplete')
      ? value.flag('runComplete')
      : value.text('state') != 'thinking';

  bool get running => viewedAttempt == null && !completed(widget.reasoning);

  List<Widget> timeline(BuildContext context, RowData value) {
    final colors = Theme.of(context).colorScheme;
    final text = value.text('text');
    final parts = value.rows('segments');
    final rows = <RowData>[
      if (parts.isEmpty && text.isNotEmpty)
        {'start': 0, 'end': text.length, 'order': 0},
      ...parts,
      ...value.rows('activities'),
    ]..sort((a, b) => a.number('order').compareTo(b.number('order')));
    return rows.map((row) {
      final kind = row.text('kind');
      if (kind.isEmpty) {
        final start = row.number('start').clamp(0, text.length);
        final end = row.number('end').clamp(start, text.length);
        final index = parts.indexOf(row);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: StreamText(
            key: ValueKey('thought-${row.text('id')}-${row.number('order')}'),
            text:
                '${parts.length > 1 ? strings(context).reasoningSegmentHeading((index + 1).toString()) : ''}${text.substring(start, end)}',
            active:
                active && (parts.isEmpty || row.text('state') == 'thinking'),
            onLayout: followLayout,
            builder: (context, content) => SelectableText(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        );
      }
      final pending = row.text('state') == 'running' && running;
      final failed = [
        'failed',
        'stopped',
        'interrupted',
      ].contains(row.text('state'));
      final count = row.number('count');
      final (icon, label) = switch (kind) {
        'web_search' => (
          Icons.search_rounded,
          pending
              ? strings(context).searching
              : failed
              ? strings(context).searchIncomplete
              : strings(context).searchResultCount((count)),
        ),
        'read_web_page' => (
          Icons.article_outlined,
          pending
              ? strings(context).readingWebpages
              : count > 0
              ? strings(context).readWebpageCount((count))
              : strings(context).webpageReadingFinished,
        ),
        'read_evidence' => (
          Icons.subject_rounded,
          pending
              ? strings(context).readingMaterials
              : strings(context).sourceExcerptViewed,
        ),
        'reuse' => (Icons.history_rounded, strings(context).materialsReused),
        'search_emails' => (
          Icons.mail_outline_rounded,
          pending
              ? strings(context).searchingEmails
              : strings(context).emailsSearched,
        ),
        _ => (
          Icons.task_alt_rounded,
          pending
              ? strings(context).processing493
              : strings(context).actionCompleted,
        ),
      };
      final domains = (row['domains'] as List? ?? []).whereType<String>().join(
        ' · ',
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(icon, size: 17, color: colors.onSurfaceVariant),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (domains.isNotEmpty)
                    Text(
                      domains,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
        ),
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    expanded = !completed(widget.reasoning);
    syncClock();
  }

  void syncClock() {
    clock.stop();
    clock.reset();
    if (active) {
      clock.start();
      ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else {
      ticker?.cancel();
      ticker = null;
    }
  }

  @override
  void didUpdateWidget(ReasoningPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasActive = oldWidget.reasoning.text('state') == 'thinking';
    if (!completed(oldWidget.reasoning) &&
        completed(widget.reasoning) &&
        !userToggled) {
      expanded = false;
    }
    if (!wasActive && active && !userToggled) expanded = true;
    if (wasActive != active ||
        oldWidget.reasoning.number('elapsedMs') !=
            widget.reasoning.number('elapsedMs')) {
      syncClock();
    }
    if (running &&
        expanded &&
        oldWidget.reasoning.number('revision') !=
            widget.reasoning.number('revision')) {
      followText =
          follower.moving ||
          !scroll.hasClients ||
          scroll.position.extentAfter < 40;
    }
  }

  void followLayout() {
    if (running &&
        expanded &&
        followText &&
        TickerMode.valuesOf(context).enabled) {
      follower.follow(animate: !MediaQuery.disableAnimationsOf(context));
    }
  }

  @override
  void dispose() {
    ticker?.cancel();
    clock.stop();
    follower.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (displayed.text('text').isEmpty &&
        displayed.rows('activities').isEmpty &&
        widget.reasoning.rows('previous').isEmpty) {
      return const SizedBox.shrink();
    }
    if (running && expanded && followText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) followLayout();
      });
    }
    final colors = Theme.of(context).colorScheme;
    final milliseconds =
        displayed.number('elapsedMs') +
        (active ? clock.elapsedMilliseconds : 0);
    final seconds = milliseconds ~/ 1000;
    final duration = seconds < 1
        ? strings(context).lessThanSecond
        : strings(context).elapsedSeconds((seconds));
    final title = switch (displayed.text('state')) {
      'thinking' => strings(context).thinking497,
      'stopped' => strings(context).thinkingStopped,
      'interrupted' => strings(context).thinkingInterrupted,
      _ =>
        displayed.text('text').isEmpty
            ? (running
                  ? strings(context).processing493
                  : strings(context).process)
            : strings(context).thought,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: expanded,
            label: strings(context).reasoning,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() {
                expanded = !expanded;
                userToggled = true;
              }),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: active
                          ? CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: colors.onSurfaceVariant,
                            )
                          : Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: colors.onSurfaceVariant,
                            ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        displayed.text('text').isEmpty
                            ? title
                            : '$title · $duration',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.reasoning.rows('previous').isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: PopupMenuButton<String>(
                tooltip: strings(context).viewReasoning,
                onSelected: (id) => setState(() {
                  viewedAttempt = id.isEmpty ? null : id;
                  expanded = true;
                  userToggled = true;
                  syncClock();
                }),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: '',
                    child: Text(strings(context).currentAttempt),
                  ),
                  for (final (index, item)
                      in widget.reasoning.rows('previous').indexed)
                    PopupMenuItem(
                      value: item.text('attemptId'),
                      child: Text(
                        index == 0
                            ? strings(context).previousAttempt
                            : strings(context)
                                  .earlierAttempt((index + 1).toString()),
                      ),
                    ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 4,
                  ),
                  child: Text(
                    viewedAttempt == null
                        ? strings(context).previousAttempt
                        : strings(context).viewingAPreviousAttempt,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          if (expanded)
            Container(
              key: const ValueKey('reasoning-body'),
              constraints: BoxConstraints(
                maxHeight: (MediaQuery.sizeOf(context).height * .25).clamp(
                  100.0,
                  220.0,
                ),
              ),
              margin: const EdgeInsets.only(top: 2, bottom: 6),
              padding: const EdgeInsets.only(left: 14, right: 8),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: colors.outlineVariant, width: 2),
                ),
              ),
              child: NotificationListener<ScrollNotification>(
                onNotification: (event) {
                  follower.observe(event);
                  if (event.depth == 0 && event is ScrollEndNotification) {
                    final atEnd = event.metrics.extentAfter < 40;
                    if (atEnd != followText) setState(() => followText = atEnd);
                  }
                  return false;
                },
                child: Scrollbar(
                  controller: scroll,
                  child: SingleChildScrollView(
                    controller: scroll,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...timeline(context, displayed),
                        if (displayed.flag('truncated'))
                          Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              strings(context)
                                  .reasoningIsLongTheFirstCharactersHave,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (expanded && !followText)
            Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                label: strings(context).jumpToEndOfReasoning,
                button: true,
                child: IconButton(
                  key: const ValueKey('reasoning-scroll-to-end'),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () {
                    setState(() => followText = true);
                    follower.follow(
                      force: true,
                      animate: !MediaQuery.disableAnimationsOf(context),
                    );
                  },
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
