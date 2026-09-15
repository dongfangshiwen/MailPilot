import 'package:flutter/material.dart';

import 'controller.dart';
import 'l10n/app_localizations.dart';
import 'l10n/app_localizations_zh.dart';

export 'l10n/app_localizations.dart';

/// Explicit UI language, independent of system, speech and generated content.
enum AppLanguage {
  simplifiedChinese('zh', '简体中文', Locale('zh')),
  traditionalChinese(
    'zh_Hant',
    '繁體中文',
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ),
  english('en', 'English', Locale('en')),
  japanese('ja', '日本語', Locale('ja')),
  korean('ko', '한국어', Locale('ko')),
  spanish('es', 'Español', Locale('es')),
  french('fr', 'Français', Locale('fr')),
  german('de', 'Deutsch', Locale('de'));

  const AppLanguage(this.code, this.nativeName, this.locale);
  final String code, nativeName;
  final Locale locale;

  static AppLanguage fromCode(String code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () => simplifiedChinese,
  );
}

// Standalone widget previews/tests inherit the same Simplified Chinese default.
AppLocalizations strings(BuildContext? context) =>
    (context == null ? null : AppLocalizations.of(context)) ??
    AppLocalizationsZh();

Future<void> showLanguagePicker(BuildContext context, MailController c) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _LanguagePicker(c),
    );

class _LanguagePicker extends StatefulWidget {
  const _LanguagePicker(this.controller);
  final MailController controller;
  @override
  State<_LanguagePicker> createState() => _LanguagePickerState();
}

class _LanguagePickerState extends State<_LanguagePicker> {
  bool saving = false;
  String? error;
  MailController get c => widget.controller;

  Future<void> select(AppLanguage language) async {
    if (saving) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await c.request('appLanguage', {'value': language.code});
      // Apply only after the preference has been persisted successfully.
      if (!mounted) return;
      c.applyAppLanguage(language.code);
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error = strings(context).actionFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    strings(context).languageTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final language in AppLanguage.values)
                  ListTile(
                    key: ValueKey('language-${language.code}'),
                    title: Text(language.nativeName),
                    selected:
                        AppLanguage.fromCode(c.settings.text('appLanguage')) ==
                        language,
                    trailing:
                        AppLanguage.fromCode(c.settings.text('appLanguage')) ==
                            language
                        ? const Icon(Icons.check_rounded)
                        : null,
                    enabled: !saving,
                    onTap: () => select(language),
                  ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Text(
                    strings(context).languageDescription,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
