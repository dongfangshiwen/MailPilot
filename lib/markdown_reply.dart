import 'app_language.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import 'controller.dart';

/// Treat an explicitly Markdown-wrapped document as a document, not a code sample.
/// Other code fences and the stored source text remain untouched.
String readingMarkdown(String text) =>
    RegExp(
      r'^```(?:markdown|md)[ \t]*\r?\n([\s\S]*?)\r?\n```$',
      caseSensitive: false,
    ).firstMatch(text.trim())?.group(1) ??
    text;

/// Only known source IDs become source links; model-provided paths never open files.
class _SourceSyntax extends md.InlineSyntax {
  _SourceSyntax(this.ids) : super(r'\[((?:T\d+:)?S\d+)\](?!\()');
  final Set<String> ids;
  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final id = match[1]!;
    if (!ids.contains(id)) {
      parser.addNode(md.Text(match[0]!));
      return true;
    }
    parser.addNode(
      md.Element.text('a', '[$id]')
        ..attributes['href'] = 'mailpilot-source:$id',
    );
    return true;
  }
}

class MarkdownReply extends StatefulWidget {
  const MarkdownReply({
    super.key,
    required this.text,
    required this.controller,
    this.sources = const [],
    this.preserveLineBreaks = false,
  });
  final String text;
  final MailController controller;
  final List<RowData> sources;
  final bool preserveLineBreaks;

  @override
  State<MarkdownReply> createState() => _MarkdownReplyState();
}

class _MarkdownReplyState extends State<MarkdownReply> {
  Widget? _rendered;
  String get text => widget.text;
  MailController get controller => widget.controller;
  List<RowData> get sources => widget.sources;
  bool get preserveLineBreaks => widget.preserveLineBreaks;

  @override
  void didUpdateWidget(MarkdownReply oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != text ||
        oldWidget.controller != controller ||
        oldWidget.preserveLineBreaks != preserveLineBreaks ||
        oldWidget.sources.length != sources.length ||
        sources.asMap().entries.any(
          (e) => !mapEquals(e.value, oldWidget.sources[e.key]),
        )) {
      _rendered = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rendered = null;
  }

  @override
  Widget build(BuildContext context) => _rendered ??= _buildMarkdown(context);

  Future<void> _link(BuildContext context, String? href) async {
    if (href == null) return;
    final uri = Uri.tryParse(href);
    if (uri?.scheme == 'mailpilot-source') {
      final source = sources
          .where((s) => s.text('id') == uri!.path)
          .firstOrNull;
      if (source != null) {
        await controller.act('showSource', {'source': source});
      }
      return;
    }
    if (uri == null ||
        !['https', 'http'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings(context).thisLinkIsNotAValidWeb)),
      );
      return;
    }
    // Opening model-generated URLs is always an explicit gesture, never rendering.
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings(context).openWebpage,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              SelectableText(href, maxLines: 5),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: href));
                      Navigator.pop(ctx);
                    },
                    child: Text(strings(context).copyLink),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      controller.act('openLink', {'url': href});
                    },
                    child: Text(strings(context).openInBrowser),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarkdown(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    return SelectionArea(
      child: MarkdownBody(
        data: text,
        fitContent: false,
        softLineBreak: preserveLineBreaks,
        inlineSyntaxes: [
          _SourceSyntax(sources.map((s) => s.text('id')).toSet()),
        ],
        onTapLink: (_, href, _) => _link(context, href),
        // Disable network and file image loading; actual selected images use SourcePage.
        imageBuilder: (_, _, alt) => Text(
          strings(context)
              .image((alt?.isNotEmpty == true ? '：$alt' : '').toString()),
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
          p: TextStyle(fontSize: 16, height: 1.65, color: colors.onSurface),
          h1: TextStyle(
            fontSize: 23,
            height: 1.4,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
          h2: TextStyle(
            fontSize: 20,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
          h3: TextStyle(
            fontSize: 17,
            height: 1.5,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
          blockSpacing: 14,
          code: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: colors.onSurface,
            // Glyph backgrounds paint over selection in RenderParagraph.
            // Keep the block's container fill, so selected code stays visible.
          ),
          codeblockDecoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          codeblockPadding: const EdgeInsets.all(14),
          blockquoteDecoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            border: Border(
              left: BorderSide(color: colors.outlineVariant, width: 3),
            ),
          ),
          blockquotePadding: const EdgeInsets.all(12),
          tableColumnWidth: const FixedColumnWidth(150),
          tableCellsPadding: const EdgeInsets.all(10),
          tableBorder: TableBorder.all(color: colors.outlineVariant),
        ),
      ),
    );
  }
}
