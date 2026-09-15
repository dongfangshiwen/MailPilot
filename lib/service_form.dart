import 'app_language.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controller.dart';

Future<void> showServiceSheet(
  BuildContext context,
  MailController c, {
  bool speech = false,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => ServiceDrawer(c, speech: speech),
  );
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings(context).configurationSaved)),
    );
  }
}

class ServiceDrawer extends StatefulWidget {
  const ServiceDrawer(this.c, {this.speech = false, super.key});
  final MailController c;
  final bool speech;
  @override
  State<ServiceDrawer> createState() => _ServiceDrawerState();
}

class _ServiceDrawerState extends State<ServiceDrawer> {
  late int tab = widget.speech ? 1 : 0;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SizedBox(
      height:
          MediaQuery.sizeOf(context).height * .85 -
          MediaQuery.viewInsetsOf(context).bottom,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    strings(context).searchAndVoice,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: strings(context).closeConfiguration,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
                const SizedBox(width: 8),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  for (final item in [
                    (0, strings(context).webSearch),
                    (1, strings(context).voiceInput),
                  ])
                    Expanded(
                      child: TextButton(
                        onPressed: () => setState(() => tab = item.$1),
                        style: TextButton.styleFrom(
                          backgroundColor: tab == item.$1
                              ? Theme.of(context).colorScheme.primary
                                    .withValues(alpha: .09)
                              : null,
                        ),
                        child: Text(item.$2),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: tab,
                children: [
                  ServiceForm(widget.c, active: tab == 0),
                  ServiceForm(widget.c, speech: true, active: tab == 1),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ServiceForm extends StatefulWidget {
  const ServiceForm(
    this.c, {
    this.speech = false,
    this.active = true,
    super.key,
  });
  final MailController c;
  final bool speech;
  final bool active;
  @override
  State<ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends State<ServiceForm> {
  final address = TextEditingController(),
      keyInput = TextEditingController(),
      model = TextEditingController();
  late String provider, language, mode;
  bool busy = false, obscure = true;
  String result = '';
  String? option;
  final providerInputs = <String, List<String>>{};
  static const endpoints = {
    'volcengine': 'https://open.feedcoopapi.com/search_api/web_search',
    'bocha': 'https://api.bocha.cn/v1/web-search',
    'qwen': 'https://dashscope.aliyuncs.com/compatible-mode/v1',
  };
  @override
  void initState() {
    super.initState();
    final initial = widget.c.data.child(
      widget.speech ? 'speechConfig' : 'searchConfig',
    );
    provider = initial.text('provider', widget.speech ? 'qwen' : 'volcengine');
    language = initial.text('language', 'auto');
    mode = initial.text('mode', 'system');
    address.text = initial.text('baseUrl', endpoints[provider]!);
    model.text = initial.text('model', 'qwen3-asr-flash');
  }

  @override
  void dispose() {
    address.dispose();
    keyInput.dispose();
    model.dispose();
    super.dispose();
  }

  Future<void> submit(bool test) async {
    setState(() {
      busy = true;
      result = '';
    });
    try {
      final message = await widget.c.request(
        test ? 'testService' : 'saveService',
        {
          'speech': widget.speech,
          'provider': provider,
          'baseUrl': address.text.trim(),
          'secret': keyInput.text.trim(),
          'model': model.text.trim(),
          'language': language,
          'mode': mode,
        },
      );
      if (mounted) {
        if (test) {
          setState(() => result = '$message');
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => result = e is PlatformException
              ? e.message ?? strings(context).actionFailed
              : '$e',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget choice(String title, String value, String page) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: Text(value),
    trailing: const Icon(Icons.chevron_right, size: 20),
    onTap: busy ? null : () => setState(() => option = page),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.active || option == null,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && widget.active) setState(() => option = null);
    },
    child: option != null
        ? ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.arrow_back),
                title: Text(strings(context).backToConfiguration),
                onTap: () => setState(() => option = null),
              ),
              for (final item
                  in (option == 'provider'
                          ? {
                              'volcengine': strings(context)
                                  .volcengineWebSearch,
                              'bocha': strings(context).bocha,
                            }
                          : option == 'mode'
                          ? {
                              'system': strings(context)
                                  .systemPreferredCloudOptional,
                              'cloud': strings(context).qwenCloudTranscription,
                            }
                          : {
                              'auto': strings(
                                context,
                              ).automaticSystemRecognitionFollowsDeviceLanguage,
                              'zh': strings(context).chinese,
                              'en': 'English',
                            })
                      .entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.value),
                  trailing:
                      item.key ==
                          (option == 'provider'
                              ? provider
                              : option == 'mode'
                              ? mode
                              : language)
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => setState(() {
                    if (option == 'provider') {
                      providerInputs[provider] = [address.text, keyInput.text];
                      provider = item.key;
                      address.text =
                          providerInputs[provider]?[0] ?? endpoints[provider]!;
                      keyInput.text = providerInputs[provider]?[1] ?? '';
                    } else if (option == 'mode') {
                      mode = item.key;
                    } else {
                      language = item.key;
                    }
                    option = null;
                  }),
                ),
            ],
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              if (!widget.speech)
                choice(
                  strings(context).searchProvider,
                  provider == 'bocha'
                      ? strings(context).bocha
                      : strings(context).volcengineWebSearch,
                  'provider',
                ),
              if (widget.speech) ...[
                choice(
                  strings(context).recognitionMode,
                  mode == 'cloud'
                      ? strings(context).qwenCloudTranscription
                      : strings(context).systemPreferredCloudOptional,
                  'mode',
                ),
                choice(
                  strings(context).speechLanguage,
                  {
                    'auto': strings(context).automatic,
                    'zh': strings(context).chinese,
                    'en': 'English',
                  }[language]!,
                  'language',
                ),
              ],
              const SizedBox(height: 20),
              Text(
                widget.speech
                    ? strings(context).systemRecognitionNeedsNoApiKeyIf
                    : strings(context).usedOnlyWhenSmartSearchIsEnabled,
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: address,
                decoration: InputDecoration(
                  labelText: widget.speech
                      ? strings(context).qwenAsrBaseUrl
                      : strings(context).fullSearchApiUrl,
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keyInput,
                obscureText: obscure,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  helperText: strings(context).leaveBlankToRetainTheSavedKey,
                  suffixIcon: IconButton(
                    tooltip: strings(context).showOrHideKey,
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
              ),
              if (widget.speech) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: model,
                  decoration: InputDecoration(
                    labelText: strings(context).asrModel,
                    helperText: strings(context).forExampleQwenAsrFlash,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (widget.speech)
                Text(
                  strings(context).transcriptionFillsTheInputFieldOnlyReview,
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
              if (result.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(result),
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: busy ? null : () => submit(false),
                child: Text(
                  busy ? strings(context).processing : strings(context).save,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: busy ? null : () => submit(true),
                child: Text(strings(context).connectionDiagnosticsOptional),
              ),
            ],
          ),
  );
}
