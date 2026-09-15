import 'app_language.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';

import 'controller.dart';
import 'materials_sheet.dart';
import 'screens.dart' show bar;

String _pdfError(Object error, BuildContext context) =>
    error is PlatformException
    ? error.message ?? strings(context).couldNotReadThisPage
    : strings(context).couldNotReadThisPagePleaseRetry;

/// A single request in flight. Removed tiles cancel their queued work.
class PdfThumbnailQueue {
  PdfThumbnailQueue(this.c, this.id, this.token);
  final MailController c;
  final String id, token;
  final _pending = <int, Completer<Uint8List?>>{};
  final _cache = <int, Uint8List>{};
  final _wanted = <int>{};
  bool _running = false, _disposed = false;
  Future<Uint8List?> read(int page) {
    if (_disposed) return Future.value();
    _wanted.add(page);
    final cached = _cache.remove(page);
    if (cached != null) {
      _cache[page] = cached;
      return Future.value(cached);
    }
    if (_pending.containsKey(page)) return _pending[page]!.future;
    final result = Completer<Uint8List?>();
    _pending[page] = result;
    unawaited(_pump());
    return result.future;
  }

  void release(int page) {
    _wanted.remove(page);
  }

  void invalidate(int page) => _cache.remove(page);

  Future<void> _pump() async {
    if (_running) return;
    _running = true;
    try {
      while (!_disposed && _pending.isNotEmpty) {
        final page = _pending.keys.first, result = _pending.values.first;
        if (!_wanted.contains(page)) {
          _pending.remove(page);
          result.complete();
          continue;
        }
        try {
          final data = await c.request('pdfThumbnail', {
            'id': id,
            'page': page,
            'token': token,
          }) as Uint8List?;
          if (!_disposed && _wanted.contains(page) && data != null) {
            _cache[page] = data;
            while (_cache.length > 12) {
              _cache.remove(_cache.keys.first);
            }
          }
          if (!result.isCompleted) {
            result.complete(_disposed || !_wanted.contains(page) ? null : data);
          }
        } catch (e, stack) {
          if (!result.isCompleted) {
            if (_disposed || !_wanted.contains(page)) {
              result.complete();
            } else {
              result.completeError(e, stack);
            }
          }
        }
        _pending.remove(page);
      }
    } finally {
      _running = false;
    }
  }

  void dispose() {
    _disposed = true;
    for (final item in _pending.values) {
      if (!item.isCompleted) item.complete();
    }
    _pending.clear();
    _cache.clear();
    _wanted.clear();
  }
}

class PdfPicker extends StatefulWidget {
  const PdfPicker(this.c, {super.key});
  final MailController c;
  @override
  State<PdfPicker> createState() => _PdfPickerState();
}

class _PdfPickerState extends State<PdfPicker> {
  Set<int> pages = {};
  bool initialized = false;
  late final PdfThumbnailQueue queue;
  @override
  void initState() {
    super.initState();
    final choice = widget.c.data.child('pdfChoice');
    queue = PdfThumbnailQueue(
      widget.c,
      choice.child('attachment').text('id'),
      choice.text('token'),
    );
  }

  @override
  void dispose() {
    queue.dispose();
    super.dispose();
  }

  Future<void> zoom(int page) async {
    final c = widget.c, choice = c.data.child('pdfChoice');
    final future = () async {
      final path = await c.request('pdfPage', {
        'id': choice.child('attachment')['id'],
        'page': page,
      });
      return c.image(path as String);
    }();
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 4, top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      strings(context).page((page + 1).toString()),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    tooltip: strings(context).closePagePreview,
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<Uint8List?>(
                future: future,
                builder: (ctx, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(_pdfError(snapshot.error!, context)),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  return InteractiveViewer(
                    minScale: .8,
                    maxScale: 5,
                    child: Center(
                      child: Image.memory(
                        snapshot.data!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            Text(strings(context).pageImageUnavailable),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c,
        choice = c.data.child('pdfChoice'),
        file = choice.child('attachment');
    final colors = Theme.of(context).colorScheme;
    final count = choice.number('count'), loading = choice.flag('loading');
    if (!initialized && !loading && count > 0) {
      pages = (choice['selected'] as List? ?? []).cast<int>().toSet();
      initialized = true;
    }
    final ready = !loading && choice.text('error').isEmpty && count > 0;
    return Column(
      children: [
        bar(context, c, strings(context).selectPdfPages, back: true),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Icon(
                Icons.picture_as_pdf_outlined,
                size: 26,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tooltip(
                      message: file.text('name'),
                      child: Text(
                        file.text('name'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${materialSize(file.number('size', -1), context: context)}${ready ? strings(context).pagesTotal((count).toString()) : ''}',
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
        if (ready)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  strings(context)
                      .pagesSelectedMaximum((pages.length).toString()),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(
                    () => pages = {
                      for (var i = 0; i < count.clamp(0, 10); i++) i,
                    },
                  ),
                  child: Text(
                    count <= 10
                        ? strings(context).selectAll
                        : strings(context).firstPages,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(pages.clear),
                  child: Text(strings(context).clear),
                ),
              ],
            ),
          ),
        Expanded(
          child: !ready
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (loading)
                          const CircularProgressIndicator(strokeWidth: 2),
                        const SizedBox(height: 12),
                        Text(
                          loading
                              ? strings(context).readingPdf
                              : choice.text(
                                  'error',
                                  strings(context).couldNotReadPageNumbers,
                                ),
                        ),
                        if (!loading)
                          TextButton(
                            onPressed: () => c.act(
                              file.text('messageId').isEmpty
                                  ? 'localPdf'
                                  : 'editPdf',
                              {'id': file['id']},
                            ),
                            child: Text(strings(context).retryReading),
                          ),
                      ],
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (ctx, constraints) {
                    final columns =
                        count == 1 ||
                            MediaQuery.textScalerOf(context).scale(14) > 22 ||
                            constraints.maxWidth < 320
                        ? 1
                        : 2;
                    final grid = GridView.builder(
                      key: const ValueKey('pdf-page-grid'),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      scrollCacheExtent: const ScrollCacheExtent.pixels(0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: .68,
                      ),
                      itemCount: count,
                      itemBuilder: (_, page) => _PdfTile(
                        key: ValueKey('${queue.token}-$page'),
                        queue: queue,
                        page: page,
                        selected: pages.contains(page),
                        onPreview: () => zoom(page),
                        onSelect: () {
                          if (!pages.contains(page) && pages.length >= 20) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  strings(context).selectUpToPagesPerPdf,
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            if (!pages.add(page)) pages.remove(page);
                          });
                        },
                      ),
                    );
                    return count == 1
                        ? Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(width: 280, child: grid),
                          )
                        : grid;
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: ready
                    ? () => c.act('choosePdf', {
                        'pages': pages.toList()..sort(),
                        'token': queue.token,
                      })
                    : null,
                child: Text(
                  pages.isEmpty
                      ? strings(context).deselectThisAttachment
                      : strings(context)
                            .confirmSelectionPages((pages.length).toString()),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PdfTile extends StatefulWidget {
  const _PdfTile({
    super.key,
    required this.queue,
    required this.page,
    required this.selected,
    required this.onSelect,
    required this.onPreview,
  });
  final PdfThumbnailQueue queue;
  final int page;
  final bool selected;
  final VoidCallback onSelect, onPreview;
  @override
  State<_PdfTile> createState() => _PdfTileState();
}

class _PdfTileState extends State<_PdfTile> {
  late Future<Uint8List?> future;
  @override
  void initState() {
    super.initState();
    future = widget.queue.read(widget.page);
  }

  @override
  void dispose() {
    widget.queue.release(widget.page);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget retryPreview() => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined, size: 20),
          TextButton(
            onPressed: () {
              widget.queue.invalidate(widget.page);
              setState(() {
                future = widget.queue.read(widget.page);
              });
            },
            child: Text(strings(context).retryPreview),
          ),
        ],
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border.all(
          width: 1.5,
          color: widget.selected ? colors.primary : colors.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: InkWell(
              onTap: widget.onPreview,
              child: FutureBuilder<Uint8List?>(
                future: future,
                builder: (ctx, snapshot) {
                  if (snapshot.hasError) {
                    return retryPreview();
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                    );
                  }
                  return SizedBox.expand(
                    child: ColoredBox(
                      color: Colors.white,
                      child: Image.memory(
                        snapshot.data!,
                        fit: BoxFit.contain,
                        semanticLabel: strings(context)
                            .previewPage((widget.page + 1).toString()),
                        frameBuilder: (_, child, frame, sync) =>
                            sync || frame != null
                            ? child
                            : Center(
                                child: Text(
                                  strings(context).loadingPreview,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xff737780),
                                  ),
                                ),
                              ),
                        errorBuilder: (_, _, _) => retryPreview(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings(context).page((widget.page + 1).toString()),
                  maxLines: 1,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              SizedBox.square(
                dimension: 48,
                child: Checkbox(
                  value: widget.selected,
                  semanticLabel: strings(context).page480(
                    (widget.selected
                            ? strings(context).deselect
                            : strings(context).select420)
                        .toString(),
                    (widget.page + 1).toString(),
                  ),
                  onChanged: (_) => widget.onSelect(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
