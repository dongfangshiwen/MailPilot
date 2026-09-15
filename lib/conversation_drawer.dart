import 'app_language.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'common.dart';
import 'controller.dart';
import 'conversation_summary.dart';
import 'history_action_icon.dart';

String conversationGroup(RowData chat, DateTime now, {BuildContext? context}) {
  if (chat.number('pinnedAt') > 0) return strings(context).pin;
  final time = DateTime.fromMillisecondsSinceEpoch(
    chat.number('lastActivityAt', chat.number('createdAt')),
  );
  final days = DateTime.utc(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime.utc(time.year, time.month, time.day)).inDays;
  if (days <= 0) return strings(context).today;
  if (days == 1) return strings(context).yesterday;
  if (days < 7) return strings(context).previousDays;
  if (days < 30) return strings(context).previousDays86;
  return strings(context).olderConversationDate(
    (time.year).toString(),
    (time.month).toString(),
    (time.day).toString(),
  );
}

class ConversationDrawer extends StatefulWidget {
  const ConversationDrawer(this.controller, {super.key});
  final MailController controller;
  @override
  State<ConversationDrawer> createState() => _ConversationDrawerState();
}

class _ConversationEmptyState extends StatelessWidget {
  const _ConversationEmptyState({
    required this.loading,
    required this.searching,
    required this.onAction,
  });
  final bool loading, searching;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: loading
                ? SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: colors.onSurfaceVariant,
                      semanticsLabel: strings(context).loadingConversations,
                    ),
                  )
                : Icon(
                    searching
                        ? Icons.search_rounded
                        : Icons.chat_bubble_outline_rounded,
                    size: 26,
                    color: colors.onSurfaceVariant,
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            loading
                ? strings(context).loadingConversations
                : searching
                ? strings(context).noMatchingConversations
                : strings(context).yourConversationsWillAppearHere,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: colors.onSurfaceVariant,
            ),
          ),
          if (!loading) ...[
            const SizedBox(height: 6),
            Text(
              searching
                  ? strings(context).tryShorterKeywordsOrClearTheSearch
                  : strings(context).startAChatAndComeBackAnytime,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.6,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.onSurfaceVariant,
                side: BorderSide(color: colors.outlineVariant),
                minimumSize: const Size(120, 48),
                shape: const StadiumBorder(),
                textStyle: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontSize: 13),
              ),
              child: Text(
                searching
                    ? strings(context).clearSearch
                    : strings(context).startAConversation,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConversationDrawerState extends State<ConversationDrawer> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  Timer? _searchDelay;
  String _query = '';
  Offset _pressedAt = const Offset(24, 140);
  final _selected = <String>{};
  List<RowData> _items = [];
  RowData? _cursor;
  bool _loading = false, _more = true, _multi = false;
  String? _error;
  String _account = '';
  int _revision = -1, _epoch = 0;
  Timer? _midnight;
  MailController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    c.addListener(_changed);
    _scroll.addListener(_onScroll);
    _changed();
    _scheduleDate();
  }

  void _scheduleDate() {
    final now = DateTime.now();
    _midnight = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      () {
        if (mounted) {
          setState(() {});
          _scheduleDate();
        }
      },
    );
  }

  void _changed() {
    final account = c.data.text('activeAccount');
    final revision = c.data.number('historyRevision');
    if (_account != account || _revision != revision) {
      _searchDelay?.cancel();
      _query = _search.text.trim();
      if (_account != account) {
        _items = [];
        _selected.clear();
        _multi = false;
      }
      _account = account;
      _revision = revision;
      _epoch++;
      _loading = false;
      _cursor = null;
      _more = true;
      unawaited(_load(reset: true));
    }
  }

  void _onScroll() {
    if (_scroll.hasClients && _scroll.position.extentAfter < 240) {
      unawaited(_load());
    }
  }

  void _searchChanged(String value) {
    _searchDelay?.cancel();
    setState(() {
      _epoch++;
      _items = [];
      _cursor = null;
      _loading = false;
      _more = false;
      _selected.clear();
      _error = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    if (value.trim().isEmpty) {
      _query = '';
      _more = true;
      unawaited(_load(reset: true));
      return;
    }
    _searchDelay = Timer(const Duration(milliseconds: 300), () {
      _query = value.trim();
      _more = true;
      unawaited(_load(reset: true));
    });
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading || (!_more && !reset)) return;
    final epoch = _epoch;
    _loading = true;
    try {
      final value = await c.request('listConversations', {
        'accountId': _account,
        'search': _query,
        if (!reset && _cursor != null) 'cursor': _cursor,
      });
      if (!mounted || epoch != _epoch) return;
      final result = value is String ? row(jsonDecode(value)) : row(value);
      // Older preview fixtures can still supply their in-memory headers.
      final rows = result.containsKey('items')
          ? result.rows('items')
          : c.data.rows('conversations');
      setState(() {
        _items = {
          for (final item in [if (!reset) ..._items, ...rows])
            item.text('id'): item,
        }.values.toList();
        _cursor = result['cursor'] == null ? null : result.child('cursor');
        _more = _cursor != null;
        _error = null;
      });
    } catch (_) {
      if (mounted && epoch == _epoch) {
        setState(
          () => _error = strings(context).couldNotLoadConversationsTapToRetry,
        );
      }
    } finally {
      if (mounted && epoch == _epoch) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchDelay?.cancel();
    _search.dispose();
    _midnight?.cancel();
    c.removeListener(_changed);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    _epoch++;
    _loading = false;
    await _load(reset: true);
  }

  Future<void> _rename(RowData chat) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final text = TextEditingController(text: chat.text('title'));
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: Text(strings(context).renameConversation),
        content: TextField(
          controller: text,
          autofocus: true,
          maxLength: 80,
          minLines: 1,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: strings(context).enterConversationName,
            floatingLabelBehavior: FloatingLabelBehavior.never,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) Navigator.pop(ctx, v.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings(context).cancel),
          ),
          TextButton(
            onPressed: () {
              if (text.text.trim().isNotEmpty) {
                Navigator.pop(ctx, text.text.trim());
              }
            },
            child: Text(strings(context).save),
          ),
        ],
      ),
    );
    // The dialog's closing transition may still use its controller.
    Future<void>.delayed(const Duration(milliseconds: 400), text.dispose);
    if (value != null) {
      await c.act('renameConversation', {'id': chat['id'], 'title': value});
      if (mounted) await _refresh();
    }
  }

  Future<void> _delete(List<String> ids) async {
    if (ids.isEmpty) return;
    if (!await confirm(
      context,
      strings(context).deleteConversationCount((ids.length)),
      strings(context).chatsSummariesAndAnalysisCachesForThese,
      action: strings(context).delete,
    )) {
      return;
    }
    await c.act('deleteConversations', {'ids': ids});
    if (!mounted) return;
    setState(() {
      _selected.clear();
      _multi = false;
    });
    await _refresh();
  }

  Future<void> _pin(List<String> ids, bool pin) async {
    await c.act('pinConversations', {'ids': ids, 'pin': pin});
    if (!mounted) return;
    setState(() {
      _selected.clear();
      _multi = false;
    });
    await _refresh();
  }

  Future<void> _menu(RowData chat, Offset anchor) async {
    final pinned = chat.number('pinnedAt') > 0;
    final colors = Theme.of(context).colorScheme;
    const deleteColor = historyDeleteColor;
    final actions = [
      (
        Icon(Icons.edit_outlined, size: 20, color: colors.onSurfaceVariant),
        strings(context).rename,
      ),
      (
        HistoryActionIcon(HistoryAction.pin, color: colors.onSurfaceVariant),
        pinned ? strings(context).unpin : strings(context).pin,
      ),
      (
        Icon(Icons.checklist_rounded, size: 20, color: colors.onSurfaceVariant),
        strings(context).selectMultiple,
      ),
      (
        const HistoryActionIcon(
          HistoryAction.delete,
          size: 16,
          color: deleteColor,
        ),
        strings(context).delete,
      ),
    ];
    final size = MediaQuery.sizeOf(context);
    final large =
        MediaQuery.textScalerOf(context).scale(14) > 21 || size.width < 340;
    int? selected;
    if (large) {
      selected = await showModalBottomSheet<int>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        builder: (ctx) => SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < actions.length; i++)
                  ListTile(
                    leading: actions[i].$1,
                    title: Text(
                      actions[i].$2,
                      style: TextStyle(color: i == 3 ? deleteColor : null),
                    ),
                    onTap: () => Navigator.pop(ctx, i),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
    } else {
      selected = await showMenu<int>(
        context: context,
        color: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        menuPadding: const EdgeInsets.symmetric(vertical: 4),
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        constraints: const BoxConstraints(minWidth: 196, maxWidth: 240),
        position: RelativeRect.fromLTRB(
          anchor.dx.clamp(12, size.width - 220),
          anchor.dy,
          16,
          0,
        ),
        items: [
          for (var i = 0; i < actions.length; i++)
            PopupMenuItem(
              value: i,
              height: 48,
              child: Row(
                children: [
                  actions[i].$1,
                  const SizedBox(width: 12),
                  Text(
                    actions[i].$2,
                    style: TextStyle(
                      fontSize: 14,
                      color: i == 3 ? deleteColor : null,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    if (!mounted) return;
    switch (selected) {
      case 0:
        await _rename(chat);
      case 1:
        await _pin([chat.text('id')], !pinned);
      case 2:
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() {
          _multi = true;
          _selected.add(chat.text('id'));
        });
      case 3:
        await _delete([chat.text('id')]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final entries = <Object>[];
    String? group;
    for (final item in _items) {
      final next = conversationGroup(item, DateTime.now(), context: context);
      if (group != next) {
        entries.add(next);
        group = next;
      }
      entries.add(item);
    }
    final navigation = c.data.text('contextSummary').isNotEmpty ? 1 : 0;
    final allPinned =
        _selected.isNotEmpty &&
        _selected.every(
          (id) =>
              _items.any((e) => e.text('id') == id && e.number('pinnedAt') > 0),
        );
    return Drawer(
      backgroundColor: colors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 8, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _multi
                          ? strings(context)
                                .selectedConversationCount((_selected.length))
                          : 'MailPilot',
                      style: TextStyle(
                        fontSize: _multi ? 17 : 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _multi
                        ? strings(context).exitSelection
                        : strings(context).closeSidebar,
                    onPressed: () {
                      if (_multi) {
                        setState(() {
                          _multi = false;
                          _selected.clear();
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.close_rounded, size: 21),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: TextField(
                key: const ValueKey('conversation-search'),
                controller: _search,
                readOnly: _multi,
                canRequestFocus: !_multi,
                autofocus: false,
                maxLength: 200,
                buildCounter: (
                  _, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => null,
                style: const TextStyle(fontSize: 14),
                textInputAction: TextInputAction.search,
                onChanged: _searchChanged,
                onSubmitted: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: InputDecoration(
                  hintText: strings(context).searchConversations,
                  hintMaxLines: 1,
                  filled: true,
                  fillColor: colors.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                  suffixIcon: _search.text.isEmpty || _multi
                      ? null
                      : IconButton(
                          tooltip: strings(context).clearSearch,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _search.clear();
                            _searchChanged('');
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                key: const PageStorageKey('conversation-list'),
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: navigation + entries.length + 1,
                itemBuilder: (ctx, index) {
                  if (index < navigation) {
                    return ListTile(
                      minTileHeight: 48,
                      leading: const Icon(Icons.notes_outlined, size: 21),
                      title: Text(strings(context).conversationSummary),
                      onTap: _multi
                          ? null
                          : () {
                              Navigator.pop(context);
                              showConversationSummary(context, c);
                            },
                    );
                  }
                  if (index == navigation + entries.length) {
                    if (entries.isEmpty && _error == null) {
                      return _ConversationEmptyState(
                        loading: _loading || (_searchDelay?.isActive ?? false),
                        searching: _query.isNotEmpty,
                        onAction: () {
                          if (_query.isNotEmpty) {
                            _search.clear();
                            _searchChanged('');
                          } else {
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.pop(context);
                            c.act('tab', {'index': 1});
                          }
                        },
                      );
                    }
                    return _error != null
                        ? TextButton(onPressed: _refresh, child: Text(_error!))
                        : _more
                        ? TextButton(
                            onPressed: _loading ? null : _load,
                            child: Text(
                              _loading
                                  ? strings(context).loading
                                  : strings(context).loadMore,
                            ),
                          )
                        : const SizedBox(height: 16);
                  }
                  final item = entries[index - navigation];
                  if (item is String) {
                    if (index == navigation) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 12, top: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (_multi)
                              const SizedBox(width: 48, height: 48)
                            else
                              IconButton(
                                tooltip: strings(context).selectConversations,
                                icon: const Icon(
                                  Icons.checklist_rounded,
                                  size: 20,
                                ),
                                onPressed: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  setState(() {
                                    _multi = true;
                                    _selected.clear();
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 2),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  final chat = item as RowData;
                  final id = chat.text('id');
                  final checked = _selected.contains(id);
                  return Padding(
                    padding: EdgeInsets.zero,
                    child: Material(
                      key: ValueKey('conversation-$id'),
                      color:
                          (!_multi && id == c.data.text('conversationId')) ||
                              checked
                          ? Color.alphaBlend(
                              colors.onSurface.withValues(alpha: 0.045),
                              colors.surface,
                            )
                          : colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTapDown: (details) =>
                            _pressedAt = details.globalPosition,
                        onLongPress: _multi
                            ? null
                            : () => unawaited(_menu(chat, _pressedAt)),
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          if (_multi) {
                            setState(() {
                              if (checked) {
                                _selected.remove(id);
                              } else {
                                _selected.add(id);
                              }
                            });
                          } else {
                            Navigator.pop(context);
                            c.act('loadConversation', {'id': id});
                          }
                        },
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                if (_multi) ...[
                                  Icon(
                                    checked
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    size: 23,
                                    color: checked
                                        ? colors.primary
                                        : colors.outline,
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: Text(
                                    chat.text('title'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                                if (!_multi && chat.number('pinnedAt') > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: HistoryActionIcon(
                                      HistoryAction.pin,
                                      size: 16,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_multi)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _selected.isEmpty
                            ? null
                            : () => _pin(_selected.toList(), !allPinned),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.onSurface,
                          minimumSize: const Size(48, 52),
                        ),
                        icon: const HistoryActionIcon(HistoryAction.pin),
                        label: Text(
                          allPinned
                              ? strings(context).unpin
                              : strings(context).pin,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: colors.outlineVariant,
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _selected.isEmpty
                            ? null
                            : () => _delete(_selected.toList()),
                        style: TextButton.styleFrom(
                          foregroundColor: historyDeleteColor,
                          minimumSize: const Size(48, 52),
                        ),
                        icon: const HistoryActionIcon(
                          HistoryAction.delete,
                          size: 16,
                        ),
                        label: Text(strings(context).delete),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListTile(
                minTileHeight: 48,
                contentPadding: const EdgeInsets.symmetric(horizontal: 22),
                leading: const Icon(Icons.settings_outlined, size: 21),
                title: Text(strings(context).settings),
                onTap: () {
                  Navigator.pop(context);
                  c.act('tab', {'index': 3});
                },
              ),
          ],
        ),
      ),
    );
  }
}
