import 'app_language.dart';
import 'draft_streaming_preview.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controller.dart';
import 'message_versions.dart';
import 'chat_composer.dart';
import 'chat_scroll_viewport.dart';
import 'account_picker.dart';
import 'common.dart';
import 'forms.dart';
import 'editor.dart';
import 'markdown_reply.dart';
import 'reasoning_panel.dart';
import 'notice_toast.dart';
import 'chat_mail_preview.dart';
import 'materials_sheet.dart';
import 'multimodal_choice.dart';
import 'conversation_drawer.dart';
import 'stream_text.dart';
import 'stream_scroll_follower.dart';
import 'mail_search_results.dart';

class MailHome extends StatelessWidget {
  const MailHome({super.key, required this.controller, this.preview = false});
  final MailController controller;
  final bool preview;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final c = controller, s = c.data;
      final nested = [
        'detail',
        'editor',
        'sendPreview',
        'source',
        'pdfChoice',
      ].any((k) => s[k] != null);
      final tab = s.number('tab', 1);
      final section = switch (tab) {
        0 => Inbox(c),
        2 => DraftList(c),
        3 => SettingsPage(c),
        _ => null,
      };
      // Detail routes cover their parent instead of destroying its scroll,
      // input, expanded cards and reasoning state.
      final pages = <Widget>[
        Assistant(
          c,
          key: ValueKey(
            'assistant:${s.text('activeAccount')}:${s.text('conversationId')}',
          ),
          visible: tab == 1 && !nested,
        ),
        ?section,
      ];
      if (s['editor'] != null) {
        pages.add(
          DraftPage(
            c,
            key: ValueKey(s.child('editor').text('id')),
            visible:
                s['source'] == null &&
                s['pdfChoice'] == null &&
                s['sendPreview'] == null,
          ),
        );
      } else if (s['detail'] != null) {
        pages.add(MailDetail(c, key: ValueKey(s.child('detail').text('id'))));
      }
      if (s['sendPreview'] != null) pages.add(SendPreview(c));
      if (s['pdfChoice'] != null) {
        pages.add(
          PdfPicker(
            c,
            key: ValueKey(
              s
                  .child('pdfChoice')
                  .text(
                    'token',
                    s.child('pdfChoice').child('attachment').text('id'),
                  ),
            ),
          ),
        );
      } else if (s['source'] != null) {
        pages.add(SourcePage(c, key: ValueKey(s.child('source').text('id'))));
      }
      final page = Stack(
        fit: StackFit.expand,
        children: [
          for (var i = 0; i < pages.length; i++)
            TickerMode(
              enabled: i == pages.length - 1,
              child: Offstage(
                offstage: i != pages.length - 1,
                child: ExcludeFocus(
                  excluding: i != pages.length - 1,
                  child: pages[i],
                ),
              ),
            ),
        ],
      );
      return PopScope(
        canPop: !nested && tab == 1,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop &&
              (s['editor'] == null ||
                  s['sendPreview'] != null ||
                  s['source'] != null ||
                  s['pdfChoice'] != null)) {
            unawaited(c.back());
          }
        },
        child: Scaffold(
          drawer: nested ? null : ConversationDrawer(c),
          body: SafeArea(
            child: Column(
              children: [
                if (preview)
                  Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    child: Text(
                      strings(context).uiPreviewSampleDataInstallAndroidTo,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                NoticeToast(
                  controller: c,
                  notice: s.text('notice'),
                  busy:
                      (s.flag('busy') || s.flag('syncing')) &&
                      !s.flag('analyzing'),
                  status: s.flag('syncing')
                      ? s.text('syncLabel')
                      : s.text('status'),
                ),
                if ((c.failure ?? s['error']) != null)
                  Material(
                    color: (c.failure ?? s['error']) != null
                        ? Theme.of(context).colorScheme.errorContainer
                        : Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              (c.failure ?? s['error']).toString(),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          IconButton(
                            onPressed: c.clearError,
                            tooltip: strings(context).dismissNotice,
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: page,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

PreferredSizeWidget bar(
  BuildContext context,
  MailController c,
  String title, {
  bool back = false,
  Widget? titleWidget,
  List<Widget> actions = const [],
}) => AppBar(
  title: titleWidget ?? Text(title),
  leading: back
      ? IconButton(
          tooltip: title == strings(context).settings
              ? strings(context).backToHome
              : c.returnsToSettings &&
                    (title == strings(context).mail ||
                        title == strings(context).draftsAndSending)
              ? strings(context).backToSettings
              : title == strings(context).mail ||
                    title == strings(context).draftsAndSending
              ? strings(context).backToConversation
              : strings(context).back,
          onPressed: c.back,
          icon: const Icon(Icons.arrow_back_rounded),
        )
      : Builder(
          builder: (ctx) => IconButton(
            tooltip: strings(context).openMenu,
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {
              // Release text focus before the drawer saves focus history, so
              // closing it cannot reopen the keyboard over the conversation.
              FocusManager.instance.primaryFocus?.unfocus();
              Scaffold.of(ctx).openDrawer();
            },
          ),
        ),
  actions: actions,
);

class Assistant extends StatefulWidget {
  const Assistant(this.c, {super.key, this.visible = true});
  final MailController c;
  final bool visible;
  @override
  State<Assistant> createState() => _AssistantState();
}

class _AssistantState extends State<Assistant>
    with SingleTickerProviderStateMixin {
  final question = TextEditingController();
  final inputFocus = FocusNode();
  RowData? editing;
  TextEditingValue? savedInput;
  RowData? savedOptions;
  String editConversation = '';
  String versionAnchor = '', versionConversation = '', versionLoading = '';
  List<RowData> versions = [];
  int versionIndex = 0;

  void showLatestVersion() {
    setState(() {
      versionAnchor = '';
      versions = [];
    });
  }

  Future<void> messageActions(RowData entry) async {
    inputFocus.unfocus();
    final conversation = widget.c.data.text('conversationId');
    final edit = await showUserMessageActions(
      context,
      entry,
      canEdit:
          !entry.flag('historical') &&
          entry['canEdit'] != false &&
          !widget.c.busy,
    );
    if (edit &&
        mounted &&
        conversation == widget.c.data.text('conversationId')) {
      await editQuestion(entry);
    }
  }

  Future<void> changeVersion(RowData entry, int delta) async {
    final c = widget.c;
    if (c.busy || editing != null || versionLoading.isNotEmpty) return;
    final id = entry.text('versionAnchorId', entry.text('id'));
    final conversation = c.data.text('conversationId');
    inputFocus.unfocus();
    setState(() => versionLoading = id);
    try {
      final cached =
          versionAnchor == id &&
          versionConversation == conversation &&
          versions.isNotEmpty;
      final items = cached
          ? versions
          : (jsonDecode(
              await c.request('messageVersions', {'id': id}) as String,
            ) as List).map(row).toList();
      if (!mounted ||
          c.data.text('conversationId') != conversation ||
          !c.data.rows('entries').any((e) => e.text('id') == id)) {
        return;
      }
      if (items.isEmpty) throw StateError(strings(context).noVersionsAvailable);
      final index = ((cached ? versionIndex : items.length - 1) + delta).clamp(
        0,
        items.length - 1,
      );
      setState(() {
        versionAnchor = id;
        versionConversation = conversation;
        versions = items;
        versionIndex = index;
      });
    } catch (_) {
      if (mounted && c.data.text('conversationId') == conversation) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings(context).couldNotLoadVersionsPleaseRetry),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => versionLoading = '');
    }
  }

  Future<void> editQuestion(RowData entry) async {
    final c = widget.c;
    if (c.busy) return;
    final conversation = c.data.text('conversationId');
    try {
      final prepared = row(
        jsonDecode(
          await c.request('prepareMessageEdit', {'id': entry.text('id')})
              as String,
        ),
      );
      if (!mounted || conversation != c.data.text('conversationId')) return;
      savedInput ??= question.value;
      savedOptions ??= {...c.requestOptions};
      setState(() {
        editing = prepared;
        editConversation = conversation;
      });
      final text = prepared.text('text');
      question.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      final options = prepared.child('options');
      c.setChatOptions(
        thinking: options.text('thinking', 'default'),
        search: options.flag('webSearch'),
      );
      inputFocus.requestFocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is PlatformException
                  ? e.message ?? strings(context).cannotEditThisQuestion
                  : strings(context).couldNotEditThisQuestionPleaseRetry,
            ),
          ),
        );
      }
    }
  }

  void cancelEdit({bool restore = true}) {
    if (editing == null) return;
    inputFocus.unfocus();
    question.value = restore
        ? savedInput ?? TextEditingValue.empty
        : TextEditingValue.empty;
    widget.c.setChatOptions(
      thinking: savedOptions?.text('thinking', 'default'),
      search: savedOptions?.flag('webSearch'),
    );
    setState(() {
      editing = null;
      savedInput = null;
      savedOptions = null;
    });
  }

  final scroll = ScrollController();
  late final streamFollower = StreamScrollFollower(scroll, this);
  final latestMailCard = GlobalKey();
  bool followNextMessage = false;
  String last = '';
  String lastReviewId = '';
  int scrollRevision = 0;

  void pauseReadingFollow() {
    scrollRevision++;
    if (scroll.hasClients) scroll.position.hold(() {});
    streamFollower.pause();
  }

  bool observeChatScroll(ScrollNotification event) {
    if (event.depth == 0 &&
        event is ScrollStartNotification &&
        event.dragDetails != null) {
      scrollRevision++;
    }
    return streamFollower.observe(event);
  }

  @override
  void didUpdateWidget(Assistant oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible && !widget.visible) pauseReadingFollow();
  }

  void followStreamLayout() {
    if (widget.visible &&
        widget.c.data.flag('analyzing') &&
        (streamFollower.moving ||
            !scroll.hasClients ||
            scroll.position.extentAfter < 180)) {
      streamFollower.follow(animate: !MediaQuery.disableAnimationsOf(context));
    }
  }

  @override
  void dispose() {
    inputFocus.dispose();
    question.dispose();
    streamFollower.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final q = question.text.trim();
    if (q.isEmpty) return;
    if (editing != null) {
      final id = editing!.text('id');
      try {
        await widget.c.request('editMessage', {
          'id': id,
          'question': q,
          'options': widget.c.requestOptions,
        });
        if (mounted) {
          cancelEdit();
          followNextMessage = true;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e is PlatformException
                    ? e.message ?? strings(context).editNotSubmittedPleaseRetry
                    : strings(context).editNotSubmittedPleaseRetry,
              ),
            ),
          );
        }
      }
      return;
    }
    if (widget.c.models.isEmpty) {
      widget.c.failure = strings(context).addAModelFirst;
      await widget.c.act('tab', {'index': 3});
      return;
    }
    try {
      final budget = await refreshMaterialBudget(widget.c);
      if (!mounted) return;
      if (budget.flag('blocked')) {
        await showMaterialsSheet(context, widget.c);
        return;
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings(context).materialCheckIncompletePleaseRetry),
          ),
        );
      }
      return;
    }
    if (mounted) FocusScope.of(context).unfocus();
    question.clear();
    followNextMessage = true;
    await widget.c.act('analyze', {
      'question': q,
      'options': widget.c.requestOptions,
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c, s = c.data, colors = Theme.of(context).colorScheme;
    if (editing != null && editConversation != s.text('conversationId')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) cancelEdit(restore: false);
      });
    }
    final responseId = s.text('responseId', 'live-response');
    final entries = s
        .rows('entries')
        .where(
          (entry) => !s.flag('analyzing') || entry.text('id') != responseId,
        )
        .toList();
    var displayEntries = <RowData>[
      ...entries,
      if (s.flag('analyzing') &&
          !entries.any((entry) => entry.text('id') == responseId))
        {
          'id': responseId,
          'role': 'assistant',
          'text': s.text('streaming'),
          'reasoning': s.child('reasoning'),
          'failure': {'draftPartial': s.child('draftPartial')},
          'resultStatus': 'running',
          'live': true,
        },
    ];
    final anchorIndex = entries.indexWhere(
      (e) => e.text('id') == versionAnchor,
    );
    final hasVersionView =
        versionConversation == s.text('conversationId') &&
        anchorIndex >= 0 &&
        versions.isNotEmpty &&
        entries[anchorIndex].number('versionCount', 1) == versions.length;
    final historical =
        hasVersionView &&
        versionIndex < versions.length - 1 &&
        !s.flag('analyzing');
    if (historical) {
      final selected = versions[versionIndex];
      var oldEntries = selected.rows('entries');
      if (oldEntries.isEmpty) {
        oldEntries = [
          {
            'id': selected.text('id'),
            'role': 'user',
            'text': selected.text('text'),
          },
          {
            'id': '${selected.text('id')}-reply',
            'role': 'assistant',
            'text': selected.text('reply'),
          },
        ];
      }
      displayEntries = [
        ...entries.take(anchorIndex).map((e) => {...e, 'historical': true}),
        for (final old in oldEntries)
          {
            ...old,
            'historical': true,
            'canEdit': false,
            if (old.text('role') == 'user') ...{
              'versionAnchorId': versionAnchor,
              'versionCount': versions.length,
            },
          },
      ];
    }
    final newestReview =
        entries.lastOrNull?.child('draftPreview').isNotEmpty == true
        ? entries.last.text('id')
        : '';
    final reviewChanged =
        newestReview.isNotEmpty && newestReview != lastReviewId;
    lastReviewId = newestReview;
    final token =
        '${entries.length}:${s.text('streaming').length}:${s.child('reasoning').text('state')}';
    if (token != last) {
      final forceFollow = reviewChanged || followNextMessage;
      final follow =
          widget.visible &&
          (forceFollow ||
              (streamFollower.canFollow &&
                  (streamFollower.moving ||
                      !scroll.hasClients ||
                      scroll.position.extentAfter < 180)));
      followNextMessage = false;
      last = token;
      if (follow) {
        final revision = scrollRevision;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              widget.visible &&
              scroll.hasClients &&
              revision == scrollRevision) {
            if (!s.flag('analyzing')) streamFollower.stop();
            final cardContext = latestMailCard.currentContext;
            if (s.flag('analyzing')) {
              streamFollower.follow(
                force: forceFollow,
                animate: !MediaQuery.disableAnimationsOf(context),
              );
            } else if (entries.lastOrNull?.child('draftPreview').isNotEmpty ==
                    true &&
                cardContext != null) {
              Scrollable.ensureVisible(
                cardContext,
                alignment: 0,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
              );
            } else {
              scroll
                  .animateTo(
                    scroll.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                  )
                  .then((_) {
                    if (!mounted ||
                        !widget.visible ||
                        revision != scrollRevision ||
                        s.flag('analyzing') ||
                        entries.lastOrNull?.child('draftPreview').isEmpty !=
                            false) {
                      return;
                    }
                    final card = latestMailCard.currentContext;
                    if (card != null &&
                        card.mounted &&
                        c.data.rows('entries').lastOrNull?['id'] ==
                            entries.lastOrNull?['id']) {
                      Scrollable.ensureVisible(
                        card,
                        alignment: 0,
                        duration: const Duration(milliseconds: 160),
                      );
                    }
                  });
            }
          }
        });
      }
    }
    return Column(
      children: [
        bar(
          context,
          c,
          'MailPilot',
          titleWidget: TextButton(
            onPressed: () => chooseModel(context, c),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    c.currentModel.text('label').isEmpty
                        ? 'MailPilot'
                        : c.currentModel.text('label'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.expand_more,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              tooltip: strings(context).newConversation,
              onPressed: () => c.act('newConversation'),
              icon: const Icon(Icons.edit_square, size: 22),
            ),
            const SizedBox(width: 8),
          ],
        ),
        Expanded(
          child: ChatScrollViewport(
            controller: scroll,
            onScroll: observeChatScroll,
            onJumpingChanged: (jumping) =>
                jumping ? streamFollower.pause() : streamFollower.resume(),
            scope: '${s.text('conversationId')}:$historical',
            enabled:
                widget.visible &&
                !historical &&
                (displayEntries.isNotEmpty || s.rows('resultCards').isNotEmpty),
            child:
                entries.isEmpty &&
                    !s.flag('analyzing') &&
                    s.rows('resultCards').isEmpty
                ? QuietEmpty(
                    c.accounts.isEmpty
                        ? strings(context).whatSOnYourMind
                        : strings(context).letSMakeSenseOfYourEmails,
                    c.models.isEmpty
                        ? strings(context).configureAModelToChatYouCan
                        : strings(context).askAQuestionOrSelectEmailsAs,
                    icon: Icons.auto_awesome_outlined,
                    action: c.models.isEmpty
                        ? FilledButton(
                            onPressed: () => chooseModel(context, c),
                            child: Text(strings(context).addModel),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              for (final prompt
                                  in (c.accounts.isEmpty
                                      ? [
                                          strings(context)
                                              .helpMeOrganizeMyThoughts,
                                          strings(context).helpMeWriteSomething,
                                        ]
                                      : [
                                          strings(context)
                                              .summarizeSelectedEmails,
                                          strings(context).helpMeDraftAReply,
                                        ]))
                                ActionChip(
                                  label: Text(prompt),
                                  onPressed: () {
                                    question.text = prompt;
                                  },
                                ),
                            ],
                          ),
                  )
                : ListView(
                    key: const ValueKey('chat-message-list'),
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    children: [
                      for (final entry in displayEntries)
                        Padding(
                          key: ValueKey(
                            entry.text('versionAnchorId', entry.text('id')),
                          ),
                          padding: const EdgeInsets.only(bottom: 26),
                          child: Column(
                            crossAxisAlignment: entry.text('role') == 'user'
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (entry.text('role') == 'assistant' &&
                                  (entry
                                          .child('reasoning')
                                          .text('text')
                                          .isNotEmpty ||
                                      entry
                                          .child('reasoning')
                                          .rows('activities')
                                          .isNotEmpty ||
                                      entry
                                          .child('reasoning')
                                          .rows('previous')
                                          .isNotEmpty))
                                ReasoningPanel(
                                  key: ValueKey(
                                    'reasoning-${entry.text('id')}',
                                  ),
                                  reasoning: entry.child('reasoning'),
                                ),
                              if (entry
                                      .child('failure')
                                      .child('draftPartial')
                                      .text('subject')
                                      .isNotEmpty ||
                                  entry
                                      .child('failure')
                                      .child('draftPartial')
                                      .text('body')
                                      .isNotEmpty)
                                DraftStreamingPreview(
                                  partial: entry
                                      .child('failure')
                                      .child('draftPartial'),
                                  running: entry.flag('live'),
                                ),
                              if (entry.text('text').isNotEmpty)
                                Container(
                                  padding: EdgeInsets.zero,
                                  decoration: entry.text('role') == 'user'
                                      ? BoxDecoration(
                                          color: colors.surfaceContainerLow,
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        )
                                      : null,
                                  child: entry.text('role') == 'user'
                                      ? UserMessage(
                                          entry,
                                          onTap: () => messageActions(entry),
                                        )
                                      : StreamText(
                                          text: entry.text('text'),
                                          active: entry.flag('live'),
                                          onLayout: entry.flag('live')
                                              ? followStreamLayout
                                              : null,
                                          builder: (context, text) =>
                                              MarkdownReply(
                                                key: entry.flag('live')
                                                    ? const ValueKey(
                                                        'streaming-reply',
                                                      )
                                                    : null,
                                                text: text,
                                                controller: c,
                                                sources: entry.rows('sources'),
                                              ),
                                        ),
                                ),
                              if (entry.text('role') == 'user' &&
                                  entry.number('versionCount', 1) > 1)
                                MessageVersionPager(
                                  key: ValueKey(
                                    'version-pager-${entry.text('versionAnchorId', entry.text('id'))}',
                                  ),
                                  index:
                                      hasVersionView &&
                                          entry.text(
                                                'versionAnchorId',
                                                entry.text('id'),
                                              ) ==
                                              versionAnchor
                                      ? versionIndex
                                      : entry.number('versionCount') - 1,
                                  count: entry.number('versionCount'),
                                  loading:
                                      versionLoading ==
                                      entry.text(
                                        'versionAnchorId',
                                        entry.text('id'),
                                      ),
                                  onPrevious:
                                      !c.busy &&
                                          editing == null &&
                                          (!hasVersionView ||
                                              entry.text(
                                                    'versionAnchorId',
                                                    entry.text('id'),
                                                  ) !=
                                                  versionAnchor ||
                                              versionIndex > 0)
                                      ? () => changeVersion(entry, -1)
                                      : null,
                                  onNext:
                                      !c.busy &&
                                          editing == null &&
                                          hasVersionView &&
                                          entry.text(
                                                'versionAnchorId',
                                                entry.text('id'),
                                              ) ==
                                              versionAnchor &&
                                          versionIndex < versions.length - 1
                                      ? () => changeVersion(entry, 1)
                                      : null,
                                ),
                              if (entry.text('role') != 'user' &&
                                  !entry.flag('live')) ...[
                                if (!historical &&
                                    entry.text('action') == 'search_failed' &&
                                    entry['id'] == entries.lastOrNull?['id'])
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      TextButton(
                                        onPressed: c.busy
                                            ? null
                                            : () => c.act('retrySearch', {
                                                'webSearch': true,
                                              }),
                                        child: Text(
                                          strings(context).retryWebSearch,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: c.busy
                                            ? null
                                            : () => c.act('retrySearch', {
                                                'webSearch': false,
                                              }),
                                        child: Text(
                                          strings(context).answerWithoutSearch,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (entry.text('resultStatus') != 'running' &&
                                    entry.text('action') == 'research_partial')
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton(
                                      onPressed: c.busy
                                          ? null
                                          : () => c.act('continueResearch', {
                                              'id': entry.text('id'),
                                            }),
                                      child: Text(
                                        strings(context).continueSearching,
                                      ),
                                    ),
                                  ),
                                if (!historical &&
                                    (entry.text('resultStatus') == 'failed' ||
                                        entry.text('resultStatus') ==
                                            'stopped' ||
                                        entry
                                            .text('text')
                                            .startsWith(
                                              strings(context)
                                                  .responseIncomplete,
                                            )))
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      if (entry
                                              .child('failure')
                                              .child(
                                                'diagnostics',
                                              )['canResume'] !=
                                          false)
                                        TextButton(
                                          onPressed: c.busy
                                              ? null
                                              : () => c.act('retryAnalysis', {
                                                  'id': entry.text('id'),
                                                }),
                                          child: Text(
                                            entry
                                                    .child('failure')
                                                    .text('type')
                                                    .startsWith('compression_')
                                                ? strings(context)
                                                      .continueOrganizing
                                                : strings(context)
                                                      .retryThisTurn,
                                          ),
                                        ),
                                      if (entry
                                          .child('failure')
                                          .child('diagnostics')
                                          .isNotEmpty)
                                        TextButton(
                                          onPressed: () => showRunDiagnostics(
                                            context,
                                            entry
                                                .child('failure')
                                                .child('diagnostics'),
                                          ),
                                          child: Text(
                                            entry
                                                        .child('failure')
                                                        .text('action') ==
                                                    'budget'
                                                ? strings(context).viewBudget
                                                : strings(context)
                                                      .connectionDiagnostics,
                                          ),
                                        ),
                                      if (entry
                                              .child('failure')
                                              .text('action') ==
                                          'compatible_retry')
                                        TextButton(
                                          onPressed: c.busy
                                              ? null
                                              : () => c.act('retryAnalysis', {
                                                  'id': entry.text('id'),
                                                  'compatibleFormat': true,
                                                }),
                                          child: Text(
                                            strings(context)
                                                .retryWithCompatibleFormat,
                                          ),
                                        ),

                                      if (entry
                                              .child('failure')
                                              .text('action') ==
                                          'multimodal_choice')
                                        TextButton(
                                          onPressed: c.busy
                                              ? null
                                              : () => showMultimodalChoice(
                                                  context,
                                                  c,
                                                  entry,
                                                ),
                                          child: Text(
                                            strings(context)
                                                .chooseProcessingMethod,
                                          ),
                                        ),
                                      if (['materials', 'budget'].contains(
                                        entry.child('failure').text('action'),
                                      ))
                                        TextButton(
                                          onPressed: () => showMaterialsSheet(
                                            context,
                                            c,
                                            retryId: entry.text('id'),
                                          ),
                                          child: Text(
                                            strings(context)
                                                .adjustMaterialsAndRetry,
                                          ),
                                        ),
                                      if (entry
                                              .child('failure')
                                              .text('action') ==
                                          'thinking_default')
                                        TextButton(
                                          onPressed: c.busy
                                              ? null
                                              : () {
                                                  c.setChatOptions(
                                                    thinking: 'default',
                                                  );
                                                  c.act('retryAnalysis', {
                                                    'id': entry.text('id'),
                                                    'defaults': true,
                                                  });
                                                },
                                          child: Text(
                                            strings(context)
                                                .restoreDefaultThinkingAndRetry,
                                          ),
                                        ),
                                      if ([
                                        'model_config',
                                        'vision_helper',
                                        'search_config',
                                        'budget',
                                      ].contains(
                                        entry.child('failure').text('action'),
                                      ))
                                        TextButton(
                                          onPressed: () =>
                                              c.act('tab', {'index': 3}),
                                          child: Text(
                                            entry
                                                        .child('failure')
                                                        .text('action') ==
                                                    'vision_helper'
                                                ? strings(context)
                                                      .chooseVisionAssistant
                                                : strings(context)
                                                      .editConfiguration,
                                          ),
                                        ),
                                    ],
                                  ),
                                if (entry.text('visionModel').isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      strings(context).vision(
                                        (entry.text('visionModel')).toString(),
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                if (entry.child('draftPreview').isNotEmpty)
                                  ChatMailPreview(
                                    c,
                                    entry,
                                    key:
                                        entry['id'] == entries.lastOrNull?['id']
                                        ? latestMailCard
                                        : ValueKey('mail-${entry.text('id')}'),
                                  ),
                                if (entry.rows('sources').isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: TextButton.icon(
                                      onPressed: () => showModalBottomSheet<void>(
                                        context: context,
                                        showDragHandle: true,
                                        isScrollControlled: true,
                                        builder: (ctx) => SafeArea(
                                          child: SizedBox(
                                            height:
                                                MediaQuery.sizeOf(ctx).height *
                                                .6,
                                            child: ListView(
                                              children: [
                                                ListTile(
                                                  title: Text(
                                                    strings(context)
                                                        .referencedMaterial,
                                                  ),
                                                ),
                                                for (final source in entry.rows(
                                                  'sources',
                                                ))
                                                  ListTile(
                                                    title: Text(
                                                      '${source.text('id')} · ${source.text('title')}',
                                                    ),
                                                    subtitle: Text(
                                                      source.text('location'),
                                                    ),
                                                    trailing: const Icon(
                                                      Icons.chevron_right,
                                                    ),
                                                    onTap: () {
                                                      Navigator.pop(ctx);
                                                      c.act('showSource', {
                                                        'source': source,
                                                      });
                                                    },
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(Icons.link, size: 16),
                                      label: Text(
                                        strings(context).sourceCount(
                                          (entry.rows('sources').length),
                                        ),
                                      ),
                                    ),
                                  ),
                                Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      tooltip: strings(context).copyResponse,
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(
                                            text: entry.text('text'),
                                          ),
                                        );
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  strings(context)
                                                      .originalMarkdownCopied,
                                                ),
                                              ),
                                            );
                                      },
                                      icon: const Icon(
                                        Icons.copy_outlined,
                                        size: 17,
                                      ),
                                    ),
                                    if (!historical &&
                                        entry
                                            .rows('sources')
                                            .any(
                                              (s) =>
                                                  s.text('assetKey').isNotEmpty,
                                            ))
                                      TextButton.icon(
                                        onPressed: () =>
                                            showMaterialsSheet(context, c),
                                        icon: const Icon(
                                          Icons.refresh_rounded,
                                          size: 17,
                                        ),
                                        label: Text(
                                          strings(context).recheckImages,
                                        ),
                                      ),
                                    if (!historical &&
                                        c.accounts.isNotEmpty &&
                                        entry.text(
                                              'resultStatus',
                                              'complete',
                                            ) ==
                                            'complete' &&
                                        !entry
                                            .text('text')
                                            .contains(
                                              strings(context)
                                                  .responseIncomplete,
                                            ) &&
                                        !entry
                                            .text('text')
                                            .contains(
                                              strings(context).responseStopped,
                                            ) &&
                                        !entry
                                            .text('text')
                                            .contains(
                                              strings(
                                                context,
                                              ).stoppedThePartialResponseReceivedIsShown,
                                            ) &&
                                        entry.child('draftPreview').isEmpty)
                                      TextButton.icon(
                                        onPressed: () =>
                                            c.data
                                                .rows('drafts')
                                                .any(
                                                  (d) =>
                                                      d['id'] ==
                                                      entry['draftId'],
                                                )
                                            ? c.act('editDraft', {
                                                'id': entry['draftId'],
                                              })
                                            : c.act('draftFromAnswer', {
                                                'id': entry.text('id'),
                                              }),
                                        icon: const Icon(
                                          Icons.edit_note,
                                          size: 18,
                                        ),
                                        label: Text(
                                          c.data
                                                  .rows('drafts')
                                                  .any(
                                                    (d) =>
                                                        d['id'] ==
                                                        entry['draftId'],
                                                  )
                                              ? strings(context)
                                                    .reviewDraftAndSend
                                              : strings(context).writeAsEmail,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      if (!historical &&
                          s.flag('analyzing') &&
                          s.child('reasoning').text('state') != 'thinking')
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  s.text(
                                    'status',
                                    strings(context).connectingToModel,
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!historical && s.rows('resultCards').isNotEmpty)
                        MailSearchResults(
                          key: ValueKey('mail-results:${s.text('responseId')}'),
                          mails: s.rows('resultCards'),
                          isSelected: c.selected,
                          onOpen: (id) => c.act('openMessage', {'id': id}),
                          onSelect: (id) => c.act('toggleMessage', {'id': id}),
                          onInteract: pauseReadingFollow,
                        ),
                    ],
                  ),
          ),
        ),
        if (historical)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      strings(context).viewingAnOlderVersion,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: showLatestVersion,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.onSurfaceVariant,
                    ),
                    child: Text(strings(context).backToLatest),
                  ),
                ],
              ),
            ),
          ),
        Offstage(
          offstage: historical,
          child: ChatComposer(
            c,
            question,
            send,
            focusNode: inputFocus,
            onCancelEdit: editing != null ? cancelEdit : null,
            editMaterialLabel: editing?.text('materialLabel') ?? '',
          ),
        ),
      ],
    );
  }
}

Future<void> chooseModel(BuildContext context, MailController c) async {
  if (c.models.isEmpty) {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ModelForm(c)));
    return;
  }
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(title: Text(strings(context).textModel)),
          for (final m in c.models)
            ListTile(
              title: Text(m.text('label')),
              subtitle: Text(m.text('model')),
              trailing: c.currentModel['id'] == m['id']
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                c.act('defaultModel', {'id': m['id'], 'vision': false});
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    ),
  );
}

class Inbox extends StatefulWidget {
  const Inbox(this.c, {super.key});
  final MailController c;
  @override
  State<Inbox> createState() => _InboxState();
}

class _InboxState extends State<Inbox> {
  final search = TextEditingController();
  bool searching = false;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c, s = c.data;
    return Column(
      children: [
        bar(
          context,
          c,
          strings(context).mail,
          back: true,
          actions: [
            IconButton(
              tooltip: s.flag('syncing')
                  ? strings(context)
                        .tapToCancelSync((s.text('syncLabel')).toString())
                  : strings(context).syncLatestEmailsInEachFolder,
              onPressed: () =>
                  c.act(s.flag('syncing') ? 'cancelSync' : 'refresh'),
              icon: s.flag('syncing')
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
            ),
            IconButton(
              tooltip: strings(context).searchEmails,
              onPressed: () => setState(() => searching = !searching),
              icon: const Icon(Icons.search),
            ),
            PopupMenuButton<String>(
              tooltip: strings(context).emailActions,
              onSelected: (v) {
                if (v == 'refresh') {
                  c.act('refresh');
                } else if (v == 'compose') {
                  c.act('newDraft');
                } else {
                  c.act('search', {
                    'query': search.text,
                    'unread': !s.flag('unreadOnly'),
                    'remote': false,
                  });
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'refresh',
                  child: Text(strings(context).syncEmailsPerFolder),
                ),
                PopupMenuItem(
                  value: 'unread',
                  child: Text(
                    s.flag('unreadOnly')
                        ? strings(context).showAll
                        : strings(context).showUnread,
                  ),
                ),
                PopupMenuItem(
                  value: 'compose',
                  child: Text(strings(context).composeEmail),
                ),
              ],
            ),
          ],
        ),
        if (c.accounts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(child: AccountPickerButton(c)),
                TextButton(
                  onPressed: () => showFolderPicker(context, c),
                  child: Text(
                    '${folderName(s.text('folder', 'INBOX'), context: context)} ▾',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        if (searching)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              controller: search,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (q) =>
                  c.act('search', {'query': q, 'unread': s.flag('unreadOnly')}),
              decoration: InputDecoration(
                hintText: strings(context).subjectOrSender,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: strings(context).runSearch,
                  onPressed: () => c.act('search', {
                    'query': search.text,
                    'unread': s.flag('unreadOnly'),
                  }),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
          ),
        Expanded(
          child: c.accounts.isEmpty
              ? QuietEmpty(
                  strings(context).connectAnEmailAccountFirst,
                  strings(context).supportsQqAndCustomEmailProviders,
                  action: FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AccountForm(c)),
                    ),
                    child: Text(strings(context).addEmailAccount),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await c.act('refresh');
                  },
                  child: s.rows('messages').isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: 80),
                            QuietEmpty(
                              strings(context).noLocalEmailsYet,
                              strings(context)
                                  .pullDownToSyncRecentEmailsStartup,
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: s.rows('messages').length + 1,
                          separatorBuilder: (_, _) => const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Divider(),
                          ),
                          itemBuilder: (_, i) {
                            if (i == s.rows('messages').length) {
                              return TextButton(
                                onPressed: s.flag('searching')
                                    ? null
                                    : () => c.act('refresh', {'more': true}),
                                child: Text(strings(context).loadMore),
                              );
                            }
                            final m = s.rows('messages')[i];
                            return MailTile(
                              mail: m,
                              selected: c.selected(m.text('id')),
                              onOpen: () =>
                                  c.act('openMessage', {'id': m['id']}),
                              onSelect: () =>
                                  c.act('toggleMessage', {'id': m['id']}),
                            );
                          },
                        ),
                ),
        ),
        if (s.rows('selection').isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => c.act('tab', {'index': 1}),
                child: Text(
                  strings(context).analyzeSelectedEmails(
                    (s.rows('selection').length).toString(),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class MailDetail extends StatelessWidget {
  const MailDetail(this.c, {super.key});
  final MailController c;
  @override
  Widget build(BuildContext context) {
    final s = c.data, m = s.child('detail');
    return Column(
      children: [
        bar(
          context,
          c,
          strings(context).emailDetails,
          back: true,
          actions: [
            PopupMenuButton<String>(
              tooltip: strings(context).replyAndForward,
              onSelected: (v) => c.act('reply', {
                'id': m['id'],
                'all': v == 'all',
                'forward': v == 'forward',
              }),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'reply',
                  child: Text(strings(context).reply),
                ),
                PopupMenuItem(
                  value: 'all',
                  child: Text(strings(context).replyAll),
                ),
                PopupMenuItem(
                  value: 'forward',
                  child: Text(strings(context).forward),
                ),
              ],
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SelectableText(
                m.text('subject'),
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '${m.text('sender')} <${m.text('senderAddress')}>',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                mailDate(m['sentAt'], context: context),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  strings(context).recipientDetails,
                  style: TextStyle(fontSize: 13),
                ),
                children: [
                  ListTile(
                    title: SelectableText(
                      strings(context).toCc(
                        (m.text('to')).toString(),
                        (m.text('cc')).toString(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (m.text('bodyState') == 'PENDING')
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    strings(context).bodyAwaitingBackgroundSyncYouCanKeep,
                  ),
                ),
              for (var start = 0; start < m.text('body').length; start += 4000)
                SelectableText(
                  m
                      .text('body')
                      .substring(
                        start,
                        (start + 4000).clamp(0, m.text('body').length),
                      ),
                  style: const TextStyle(fontSize: 16, height: 1.9),
                ),
              if (m.text('bodyError').isNotEmpty)
                Text(
                  m.text('bodyError'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 28),
              if (s.rows('detailAttachments').isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings(context).attachments(
                        (s.rows('detailAttachments').length).toString(),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings(context).tapAnAttachmentToPreviewSelectIt,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              if (s.rows('detailAttachments').isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () =>
                          c.act('selectMessageFiles', {'id': m['id']}),
                      child: Text(
                        strings(context).selectAllSupportedAttachments,
                      ),
                    ),
                    TextButton(
                      onPressed: () => c.act('selectMessageFiles', {
                        'id': m['id'],
                        'bodyOnly': true,
                      }),
                      child: Text(strings(context).keepBodyOnly),
                    ),
                  ],
                ),
              if (m.text('bodyState') != 'READY' ||
                  m.number('attachmentCount') >
                      s.rows('detailAttachments').length)
                Text(
                  strings(context).attachmentListAwaitingSync,
                  style: TextStyle(fontSize: 12),
                ),
              for (final a in s.rows('detailAttachments'))
                Builder(
                  builder: (ctx) {
                    final selection =
                        s
                            .rows('selection')
                            .where((e) => e['messageId'] == m['id'])
                            .firstOrNull ??
                        <String, dynamic>{};
                    return AttachmentSelectionTile(
                      key: ValueKey('attachment-${a.text('id')}'),
                      file: {
                        ...a,
                        'pages': selection.child('pdfPages')[a['id']] ?? [],
                        'defaultPages': selection
                            .strings('defaultPdfIds')
                            .contains(a['id']),
                      },
                      selected: selection
                          .strings('attachmentIds')
                          .contains(a['id']),
                      onToggle: () =>
                          c.act('selectAttachment', {'id': a['id']}),
                      onPreview: () => c.act('preview', {'id': a['id']}),
                      onPages: a.text('name').toLowerCase().endsWith('.pdf')
                          ? () => c.act('editPdf', {'id': a['id']})
                          : null,
                    );
                  },
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => c.act('reply', {'id': m['id']}),
                  child: Text(strings(context).reply),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    if (!c.selected(m.text('id'))) {
                      await c.act('toggleMessage', {'id': m['id']});
                    }
                    await c.act('tab', {'index': 1});
                  },
                  child: Text(strings(context).askAssistant),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DraftList extends StatelessWidget {
  const DraftList(this.c, {super.key});
  final MailController c;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      bar(
        context,
        c,
        strings(context).draftsAndSending,
        back: true,
        actions: [
          IconButton(
            tooltip: strings(context).composeEmail,
            onPressed: () => c.act('newDraft'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      Expanded(
        child: c.data.rows('drafts').isEmpty
            ? QuietEmpty(
                strings(context).noDraftsYet,
                strings(context).writeYourOwnOrAskTheAssistant,
                icon: Icons.edit_note_rounded,
              )
            : ListView.separated(
                itemCount: c.data.rows('drafts').length,
                separatorBuilder: (_, _) =>
                    const Divider(indent: 20, endIndent: 20),
                itemBuilder: (_, i) {
                  final d = c.data.rows('drafts')[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    title: Text(
                      d.text('subject').isEmpty
                          ? strings(context).noSubject
                          : d.text('subject'),
                    ),
                    subtitle: Text(
                      '${d.text('to')}\n${d.text('body')}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          draftStatus(d.text('status'), context: context),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        draftMenu(context, c, d),
                      ],
                    ),
                    onTap: () => c.act('editDraft', {'id': d['id']}),
                  );
                },
              ),
      ),
    ],
  );
}
