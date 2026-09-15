import 'app_language.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controller.dart';
import 'forms.dart';
import 'service_form.dart';
import 'search_globe_icon.dart';
import 'materials_sheet.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer(
    this.c,
    this.question,
    this.onSend, {
    super.key,
    this.focusNode,
    this.onCancelEdit,
    this.editMaterialLabel = '',
  });
  final MailController c;
  final TextEditingController question;
  final VoidCallback onSend;
  final FocusNode? focusNode;
  final VoidCallback? onCancelEdit;
  final String editMaterialLabel;
  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  StreamSubscription<dynamic>? events;
  String voice = '', voiceText = '', voiceConversation = '';
  bool cloudAvailable = false;
  bool get recording => voice.startsWith('listening');
  bool get voiceActive =>
      recording || voice == 'processing' || voice == 'starting';
  @override
  void initState() {
    super.initState();
    if (widget.c.backend is AndroidBackend) {
      events = const EventChannel('mailpilot/speech')
          .receiveBroadcastStream()
          .listen((value) {
            if (!mounted) return;
            final data = Map<String, dynamic>.from(value as Map);
            if (voiceConversation != widget.c.data.text('conversationId') &&
                data['state'] == 'result') {
              return;
            }
            if (data['state'] == 'result') {
              insertTranscript(widget.question, data['text'] as String? ?? '');
            }
            setState(() {
              voice = data.text('state');
              voiceText = data.text('text');
              cloudAvailable = data.flag('cloudAvailable');
              if (voice == 'result') voice = '';
            });
          }, onError: (_) {});
    }
  }

  @override
  void dispose() {
    events?.cancel();
    if (voiceActive) {
      unawaited(widget.c.request('speechCancel').catchError((_) => null));
    }
    super.dispose();
  }

  Future<void> microphone({bool cloud = false}) async {
    if (recording) {
      await widget.c.act('speechStop');
      return;
    }
    if (voiceActive) return;
    voiceConversation = widget.c.data.text('conversationId');
    setState(() {
      voice = 'starting';
      voiceText = '';
    });
    try {
      await widget.c.request('speechStart', {'cloud': cloud});
    } catch (e) {
      if (mounted) {
        setState(() {
          voice = 'error';
          voiceText = e is PlatformException
              ? e.message ?? strings(context).couldNotStartRecording
              : strings(context).couldNotStartRecording;
          cloudAvailable = widget.c.data
              .child('speechConfig')
              .flag('hasSecret');
        });
      }
    }
  }

  Future<void> add() async {
    final c = widget.c;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in [
              ('image', Icons.image_outlined, strings(context).addImage),
              ('file', Icons.description_outlined, strings(context).addFile),
              ('mail', Icons.mail_outline, strings(context).selectEmails),
            ])
              ListTile(
                leading: Icon(item.$2),
                title: Text(item.$3),
                onTap: () => Navigator.pop(ctx, item.$1),
              ),
            const SizedBox(height: 8),
            if (c.data.rows('localMaterials').isNotEmpty)
              ListTile(
                leading: const Icon(Icons.folder_open_outlined),
                title: Text(strings(context).manageImportedMaterials),
                onTap: () => Navigator.pop(ctx, 'manage'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'manage') {
      await materials();
      return;
    }
    if (choice == 'mail') {
      if (c.accounts.isEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => AccountForm(c)),
        );
      } else {
        FocusManager.instance.primaryFocus?.unfocus();
        await c.act('tab', {'index': 0, 'fromChat': true});
      }
    } else {
      await c.act('pickMaterial', {'image': choice == 'image'});
    }
  }

  Future<void> materials() => showMaterialsSheet(context, widget.c);

  Widget option(
    String full,
    String label,
    Widget Function(Color) iconBuilder,
    bool enabled,
    bool showIcon,
    VoidCallback toggle,
  ) {
    final colors = Theme.of(context).colorScheme;
    final foreground = enabled
        ? Color.lerp(colors.primary, colors.onSurfaceVariant, .22)!
        : toolForeground(colors);
    return Semantics(
      label: full,
      toggled: enabled,
      button: true,
      child: Tooltip(
        message: full,
        child: InkWell(
          onTap: toggle,
          onLongPress: full == strings(context).deepThinking
              ? () => widget.c.setChatOptions(thinking: 'default')
              : () => showServiceSheet(context, widget.c),
          borderRadius: BorderRadius.circular(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Center(
              child: Container(
                key: ValueKey('composer-option-$full'),
                constraints: const BoxConstraints(minHeight: 32),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: enabled
                      ? Color.alphaBlend(
                          colors.primary.withValues(alpha: .08),
                          colors.surface,
                        )
                      : colors.surface,
                  border: Border.all(
                    color: enabled
                        ? colors.primary.withValues(alpha: .30)
                        : colors.onSurface.withValues(alpha: .16),
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showIcon) ...[
                      iconBuilder(foreground),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double optionWidth(String label, bool withIcon) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 13,
          height: 1.2,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width + 22 + (withIcon ? 21 : 0);
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c, s = c.data, colors = Theme.of(context).colorScheme;
    final files = s
        .rows('localMaterials')
        .where((e) => e.flag('selected'))
        .length;
    final mails = s.rows('selection').length;
    final attached = s
        .rows('selection')
        .fold<int>(0, (n, e) => n + e.strings('attachmentIds').length);
    final hasMaterials = files + mails > 0;
    final thinking = c.thinkingEnabled;
    return Container(
      key: const ValueKey('chat-composer'),
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      padding: const EdgeInsets.fromLTRB(12, 2, 6, 2),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? colors.surfaceContainerLow
            : colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : [
                BoxShadow(
                  color: colors.onSurface.withValues(alpha: .035),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onCancelEdit != null) ...[
            Container(
              padding: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      strings(context).editInput,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: strings(context).cancelEdit,
                    onPressed: widget.onCancelEdit,
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.editMaterialLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
          if (hasMaterials && widget.onCancelEdit == null)
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: materials,
                    icon: const Icon(Icons.attach_file, size: 16),
                    label: Text(
                      strings(context)
                          .selectedMaterialsCount((mails), (attached + files)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: strings(context).clearSelection,
                  onPressed: () => c.act('clearSelection'),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          if (voiceActive || voice == 'error')
            Row(
              children: [
                Expanded(
                  child: Text(
                    recording
                        ? strings(context).listeningUpToSeconds
                        : voice == 'processing'
                        ? strings(context).transcribing
                        : voice == 'starting'
                        ? strings(context).startingMicrophone
                        : voiceText,
                    style: TextStyle(
                      fontSize: 12,
                      color: voice == 'error' ? colors.error : colors.primary,
                    ),
                  ),
                ),
                if (voice == 'error' && cloudAvailable)
                  TextButton(
                    onPressed: () => microphone(cloud: true),
                    child: Text(strings(context).recordAgainInCloudMode),
                  ),
                IconButton(
                  tooltip: strings(context).cancelVoiceInput,
                  onPressed: () {
                    c.act('speechCancel');
                    setState(() => voice = '');
                  },
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.question,
            builder: (context, value, _) {
              final typed = value.text.trim().isNotEmpty;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: widget.question,
                    focusNode: widget.focusNode,
                    minLines: 1,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 16, height: 1.4),
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: hasMaterials
                          ? strings(context).askAboutSelectedMaterials
                          : strings(context).messageOrUseVoiceInput,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 2,
                      ),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Reserve both 48 dp actions first; labels adapt together
                      // and never change width when a mode is toggled.
                      final available = constraints.maxWidth - 104;
                      final fullLabels =
                          optionWidth(strings(context).deepThinking, true) +
                              optionWidth(strings(context).smartSearch, true) +
                              6 <=
                          available;
                      final showIcons =
                          fullLabels ||
                          optionWidth(strings(context).thinking, true) +
                                  optionWidth(strings(context).search, true) +
                                  6 <=
                              available;
                      return Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  option(
                                    strings(context).deepThinking,
                                    fullLabels
                                        ? strings(context).deepThinking
                                        : strings(context).thinking,
                                    (color) => Icon(
                                      Icons.lightbulb_outline_rounded,
                                      size: 16,
                                      color: color,
                                    ),
                                    thinking,
                                    showIcons,
                                    () => c.setChatOptions(
                                      thinking: thinking
                                          ? 'disabled'
                                          : 'enabled',
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  option(
                                    strings(context).smartSearch,
                                    fullLabels
                                        ? strings(context).smartSearch
                                        : strings(context).search,
                                    (color) => SearchGlobeIcon(color: color),
                                    c.chatSearch,
                                    showIcons,
                                    () async {
                                      if (!c.chatSearch &&
                                          !s
                                              .child('searchConfig')
                                              .flag('hasSecret')) {
                                        await showServiceSheet(context, c);
                                        if (!mounted ||
                                            !c.data
                                                .child('searchConfig')
                                                .flag('hasSecret')) {
                                          return;
                                        }
                                      }
                                      c.setChatOptions(search: !c.chatSearch);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          toolAction(
                            tooltip: strings(context).addAttachment,
                            onPressed:
                                s.flag('busy') ||
                                    voiceActive ||
                                    widget.onCancelEdit != null
                                ? null
                                : add,
                            icon: Icons.add,
                          ),
                          toolAction(
                            tooltip: s.flag('analyzing')
                                ? strings(context).stopResponse
                                : recording
                                ? strings(context).stopRecording
                                : typed
                                ? strings(context).sendQuestion
                                : strings(context).voiceInput,
                            filled: typed || recording || s.flag('analyzing'),
                            onPressed: s.flag('analyzing')
                                ? () => c.act('cancelAnalysis')
                                : recording
                                ? microphone
                                : voiceActive || s.flag('busy')
                                ? null
                                : typed
                                ? widget.onSend
                                : microphone,
                            icon: s.flag('analyzing') || recording
                                ? Icons.stop_rounded
                                : typed
                                ? Icons.arrow_upward
                                : Icons.graphic_eq_rounded,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget toolAction({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
    bool filled = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size(48, 48),
        padding: EdgeInsets.zero,
        shape: const CircleBorder(),
      ),
      icon: Container(
        key: ValueKey(
          filled
              ? 'composer-send-disc'
              : tooltip == strings(context).addAttachment
              ? 'composer-add-disc'
              : 'composer-voice-disc',
        ),
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            width: 1.2,
            color: filled
                ? Colors.transparent
                : toolForeground(colors)
                      .withValues(alpha: onPressed == null ? .3 : 1),
          ),
          color: filled
              ? onPressed == null
                    ? colors.onSurface.withValues(alpha: .08)
                    : colors.primary
              : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 16,
          color: onPressed == null
              ? colors.onSurface.withValues(alpha: .32)
              : filled
              ? colors.onPrimary
              : toolForeground(colors),
        ),
      ),
    );
  }

  Color toolForeground(ColorScheme colors) => Color.lerp(
    colors.onSurfaceVariant,
    colors.brightness == Brightness.dark ? colors.surface : colors.onSurface,
    colors.brightness == Brightness.dark ? .06 : .14,
  )!;
}

void insertTranscript(TextEditingController controller, String text) {
  if (text.isEmpty) return;
  final value = controller.value;
  final start = value.selection.isValid
      ? value.selection.start.clamp(0, value.text.length)
      : value.text.length;
  final end = value.selection.isValid
      ? value.selection.end.clamp(start, value.text.length)
      : start;
  controller.value = TextEditingValue(
    text: value.text.replaceRange(start, end, text),
    selection: TextSelection.collapsed(offset: start + text.length),
  );
}
