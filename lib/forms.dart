import 'app_language.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controller.dart';
import 'service_form.dart';
import 'common.dart';
import 'screens.dart' show bar;
import 'model_options.dart';
import 'model_controls.dart';
import 'mail_setup_guide.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage(this.c, {super.key});
  final MailController c;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        bar(context, c, strings(context).settings, back: true),
        Expanded(
          child: ListView(
            key: const PageStorageKey('settings-list'),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              _SettingsGroup(strings(context).mail, [
                _SettingsRow(
                  Icons.mail_outline_rounded,
                  strings(context).myEmails,
                  onTap: () => c.act('tab', {'index': 0, 'fromSettings': true}),
                ),
                _SettingsRow(
                  Icons.description_outlined,
                  strings(context).draftsAndSending,
                  onTap: () => c.act('tab', {'index': 2, 'fromSettings': true}),
                ),
              ]),
              _SettingsGroup(strings(context).emailAccounts, [
                for (final a in c.accounts)
                  _SettingsRow(
                    Icons.alternate_email_rounded,
                    a.text('label').trim().isEmpty
                        ? a.text('email')
                        : a.text('label'),
                    subtitle:
                        a.text('label') != a.text('email') &&
                            a.text('label').trim().isNotEmpty
                        ? a.text('email')
                        : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AccountForm(c, initial: a),
                      ),
                    ),
                  ),
                _SettingsRow(
                  Icons.add_rounded,
                  strings(context).addEmailAccount,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AccountForm(c)),
                  ),
                ),
              ]),
              _SettingsGroup(strings(context).modelsAndServices, [
                for (final m in c.models)
                  _SettingsRow(
                    Icons.smart_toy_outlined,
                    m.text('label').trim().isEmpty
                        ? m.text('model')
                        : m.text('label'),
                    subtitle: [
                      m.text('model'),
                      if (m['id'] == c.settings['textModelId'])
                        strings(context).defaultModel,
                      if (m['id'] == c.settings['visionModelId'])
                        strings(context).visionAssistant,
                    ].join(' · '),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ModelForm(c, initial: m),
                      ),
                    ),
                  ),
                _SettingsRow(
                  Icons.add_rounded,
                  strings(context).addModel,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ModelForm(c)),
                  ),
                ),
                _SettingsRow(
                  Icons.image_outlined,
                  strings(context).visionAssistant,
                  subtitle: c.settings.text('visionModelId').isEmpty
                      ? strings(context).automaticCurrentModelPreferred
                      : strings(context).fixedAssistant(
                          (c.models
                                      .where(
                                        (m) =>
                                            m['id'] ==
                                            c.settings['visionModelId'],
                                      )
                                      .firstOrNull
                                      ?.text('label') ??
                                  strings(context).configurationUnavailable)
                              .toString(),
                        ),
                  onTap: () => pickOption(
                    context,
                    strings(context).visionAssistant,
                    {
                      '': strings(context).chooseAutomatically,
                      for (final m in c.models) m.text('id'): m.text('label'),
                    },
                    (key) => c.act('defaultModel', {'id': key, 'vision': true}),
                  ),
                ),
                _SettingsRow(
                  Icons.tune_rounded,
                  strings(context).searchAndVoice,
                  subtitle: strings(context).webServicesAndSpeechRecognition,
                  onTap: () => showServiceSheet(context, c),
                ),
              ]),
              _SettingsGroup(strings(context).preferences, [
                _SettingsRow(
                  Icons.language_rounded,
                  strings(context).appLanguage,
                  subtitle: AppLanguage.fromCode(c.settings.text('appLanguage'))
                      .nativeName,
                  onTap: () => showLanguagePicker(context, c),
                ),
                _SettingsRow(
                  Icons.bolt_outlined,
                  strings(context).contextOrganization,
                  subtitle: c.settings.flag('fastCompression')
                      ? strings(context)
                            .fastOrganizationResponseSettingsUnchanged
                      : strings(context).followCurrentThinkingMode,
                  onTap: () => pickOption(
                    context,
                    strings(context).contextOrganization,
                    {
                      'false': strings(context).followCurrentThinkingMode,
                      'true': strings(context)
                          .fastOrganizationNonThinkingModeOnSupported,
                    },
                    (key) =>
                        c.act('fastCompression', {'enabled': key == 'true'}),
                  ),
                ),
                _SettingsRow(
                  Icons.palette_outlined,
                  strings(context).appearance,
                  subtitle:
                      {
                        'system': strings(context).systemDefault,
                        'light': strings(context).light,
                        'dark': strings(context).dark,
                      }[c.settings.text('theme')] ??
                      strings(context).systemDefault,
                  onTap: () =>
                      pickOption(context, strings(context).appearance, {
                        'system': strings(context).systemDefault,
                        'light': strings(context).light,
                        'dark': strings(context).dark,
                      }, (key) => c.act('theme', {'value': key})),
                ),
                _SettingsRow(
                  Icons.sync_rounded,
                  strings(context).backgroundSync,
                  subtitle: switch (c.settings.number('syncMinutes')) {
                    0 => strings(context).off,
                    60 => strings(context).hourly,
                    1440 => strings(context).onceADay,
                    final minutes => strings(
                      context,
                    ).everyMinutes((minutes).toString()),
                  },
                  onTap: () =>
                      pickOption(context, strings(context).backgroundSync, {
                        '0': strings(context).off,
                        '30': strings(context).everyMinutes242,
                        '60': strings(context).hourly,
                        '1440': strings(context).onceADay,
                      }, (key) => c.act('sync', {'minutes': int.parse(key)})),
                ),
                _SettingsRow(
                  Icons.delete_sweep_outlined,
                  strings(context).clearCacheAndChats,
                  onTap: () async {
                    if (await confirm(
                      context,
                      strings(context).clearLocalCache,
                      strings(context)
                          .downloadedAttachmentsPagePreviewsAllChatsAnd,
                    )) {
                      await c.act('clearCache');
                    }
                  },
                ),
              ]),
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: Text(
                  strings(context).versionAndSendConfirmation(
                    (c.data.text('appVersion')).toString(),
                  ),
                  key: const ValueKey('app-version-footer'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup(this.title, this.children);
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 7),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(indent: 54, endIndent: 16),
                children[i],
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow(
    this.icon,
    this.title, {
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 24,
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox.square(
              dimension: 24,
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> pickOption(
  BuildContext context,
  String title,
  Map<String, String> values,
  void Function(String) onPick,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (ctx) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        for (final item in values.entries)
          ListTile(
            title: Text(item.value),
            onTap: () {
              Navigator.pop(ctx);
              onPick(item.key);
            },
          ),
        const SizedBox(height: 12),
      ],
    ),
  ),
);

class AccountForm extends StatefulWidget {
  const AccountForm(this.c, {super.key, this.initial = const {}});
  final MailController c;
  final RowData initial;
  @override
  State<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<AccountForm> {
  static final servers = {
    for (final entry in MailSetupGuide.catalog.entries)
      entry.key: (entry.value.imap, entry.value.smtp),
  };
  final fields = <String, TextEditingController>{};
  String imapSecurity = 'SSL', smtpSecurity = 'SSL', provider = 'QQ';
  bool busy = false, secretVisible = false;
  String? report;
  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    for (final key in [
      'email',
      'label',
      'displayName',
      'username',
      'secret',
      'imapHost',
      'smtpHost',
      'imapPort',
      'smtpPort',
    ]) {
      fields[key] = TextEditingController(text: a.text(key));
    }
    imapSecurity = a.text('imapSecurity', 'SSL');
    smtpSecurity = a.text('smtpSecurity', 'SSL');
    if (a.isEmpty) {
      preset('QQ');
    } else {
      provider = 'custom';
      for (final entry in servers.entries) {
        if (a.text('imapHost').toLowerCase() == entry.value.$1 &&
            a.text('smtpHost').toLowerCase() == entry.value.$2 &&
            a.number('imapPort') == 993 &&
            a.number('smtpPort') == 465 &&
            imapSecurity == 'SSL' &&
            smtpSecurity == 'SSL') {
          provider = entry.key;
          break;
        }
      }
    }
  }

  void preset(String value) {
    provider = value;
    fields['imapHost']!.text = servers[value]?.$1 ?? '';
    fields['smtpHost']!.text = servers[value]?.$2 ?? '';
    fields['imapPort']!.text = '993';
    fields['smtpPort']!.text = '465';
    imapSecurity = smtpSecurity = 'SSL';
  }

  String get secretLabel => switch (provider) {
    'QQ' || '163' => strings(context).appPassword,
    'aliyun_business' => strings(context).passwordSecurityPassword,
    'aliyun_personal' => strings(context).emailPassword,
    _ => strings(context).passwordAppPassword,
  };

  String get secretHelp {
    final keep = widget.initial.flag('hasSecret')
        ? strings(context).leaveBlankToKeepSavedCredentials
        : '';
    return keep +
        switch (provider) {
          'aliyun_business' => strings(
            context,
          ).theAdministratorMustAllowThirdPartyClients,
          'aliyun_personal' => strings(
            context,
          ).enterTheFullEmailAddressAndPassword,
          'QQ' || '163' => strings(context).enableImapSmtpInYourEmailSettings,
          _ => strings(context).useTheEmailPasswordOrAppPassword,
        };
  }

  RowData payload() => {
    'id': widget.initial['id'] ?? '',
    for (final f in fields.entries)
      f.key: f.key.endsWith('Port')
          ? int.tryParse(f.value.text) ?? 0
          : f.value.text.trim(),
    'imapSecurity': imapSecurity,
    'smtpSecurity': smtpSecurity,
  };
  Future<void> submit(bool test) async {
    setState(() {
      busy = true;
      report = null;
    });
    try {
      final result = await widget.c.request(
        test ? 'testAccount' : 'saveAccount',
        payload(),
      );
      if (!mounted) return;
      if (test) {
        setState(() => report = result.toString());
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => report = e is PlatformException ? e.message : e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(
    String key,
    String label, {
    String? help,
    bool secret = false,
    bool number = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: fields[key],
      enabled: !busy,
      obscureText: secret && !secretVisible,
      keyboardType: number
          ? TextInputType.number
          : key == 'email'
          ? TextInputType.emailAddress
          : TextInputType.text,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: label,
        helperText: help,
        helperMaxLines: 6,
        suffixIcon: secret
            ? IconButton(
                tooltip: secretVisible
                    ? strings(context).hideCredentials
                    : strings(context).showCredentials,
                onPressed: () => setState(() => secretVisible = !secretVisible),
                icon: Icon(
                  secretVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              )
            : null,
      ),
    ),
  );
  @override
  void dispose() {
    for (final f in fields.values) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.initial.isEmpty
            ? strings(context).connectEmail
            : strings(context).emailSettings,
      ),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final colors = Theme.of(context).colorScheme;
              final labels = {
                for (final value in [...servers.keys, 'custom'])
                  value: switch (value) {
                    'QQ' ||
                    '163' => strings(context).mail263((value).toString()),
                    'custom' => strings(context).custom,
                    'aliyun_business' => strings(context).alibabaBusinessMail,
                    'aliyun_personal' => strings(context).alibabaPersonalMail,
                    _ => value,
                  },
              };
              // Measure once at the stronger weight, so selection never
              // changes a button's width or the rows below it.
              var minimumWidth = 0.0;
              for (final label in labels.values) {
                final painter = TextPainter(
                  text: TextSpan(
                    text: label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  textScaler: MediaQuery.textScalerOf(context),
                  textDirection: Directionality.of(context),
                )..layout();
                if (painter.width + 32 > minimumWidth) {
                  minimumWidth = painter.width + 32;
                }
                painter.dispose();
              }
              final columns = ((constraints.maxWidth + 8) / (minimumWidth + 8))
                  .floor()
                  .clamp(1, 3);
              final width =
                  (constraints.maxWidth - (columns - 1) * 8) / columns;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in labels.entries)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: width,
                        maxWidth: width,
                        minHeight: 48,
                      ),
                      child: ChoiceChip(
                        label: SizedBox(
                          width: width - 26,
                          child: Text(entry.value, textAlign: TextAlign.center),
                        ),
                        showCheckmark: false,
                        selected: provider == entry.key,
                        labelStyle: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: provider == entry.key
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: provider == entry.key
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 13,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: provider == entry.key
                              ? colors.primary.withValues(alpha: .4)
                              : colors.outlineVariant.withValues(alpha: .7),
                        ),
                        backgroundColor: colors.surface,
                        selectedColor: colors.primary.withValues(alpha: .08),
                        onSelected: busy
                            ? null
                            : (_) => setState(() => preset(entry.key)),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          field('email', strings(context).emailAddress),
          field('secret', secretLabel, secret: true, help: secretHelp),
          field('displayName', strings(context).senderNameOptional),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant
                    .withValues(alpha: .6),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              key: const ValueKey('mail-setup-guide'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 2,
              ),
              leading: const Icon(Icons.help_outline_rounded, size: 22),
              title: Text(
                strings(context).emailSetupGuide,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                provider == 'custom'
                    ? strings(context).connectionDetailsAndInstructions
                    : strings(context).officialGuide(
                        (MailSetupGuide.catalog[provider]!.name).toString(),
                      ),
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20),
              onTap: () => showMailSetupGuide(context, widget.c, provider),
            ),
          ),
          ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            key: ValueKey(provider),
            initiallyExpanded: provider == 'custom',
            tilePadding: EdgeInsets.zero,
            title: Text(
              strings(context).serverAndAdvancedSettings,
              style: TextStyle(fontSize: 14),
            ),
            children: [
              const SizedBox(height: 12),
              field('label', strings(context).accountLabel),
              field(
                'username',
                strings(context).loginUsername,
                help: strings(context).leaveBlankToUseTheFullEmail,
              ),
              field('imapHost', strings(context).imapHost),
              field('imapPort', strings(context).imapPort, number: true),
              DropdownButtonFormField<String>(
                key: ValueKey('imap-$provider-$imapSecurity'),
                isExpanded: true,
                initialValue: imapSecurity,
                items: [
                  for (final v in ['SSL', 'STARTTLS'])
                    DropdownMenuItem(value: v, child: Text(v)),
                ],
                onChanged: busy
                    ? null
                    : (v) => setState(() {
                        imapSecurity = v!;
                        fields['imapPort']!.text = v == 'SSL' ? '993' : '143';
                      }),
                decoration: InputDecoration(
                  labelText: strings(context).incomingEncryption,
                ),
              ),
              const SizedBox(height: 16),
              field('smtpHost', strings(context).smtpHost),
              field('smtpPort', strings(context).smtpPort, number: true),
              DropdownButtonFormField<String>(
                key: ValueKey('smtp-$provider-$smtpSecurity'),
                isExpanded: true,
                initialValue: smtpSecurity,
                items: [
                  for (final v in ['SSL', 'STARTTLS'])
                    DropdownMenuItem(value: v, child: Text(v)),
                ],
                onChanged: busy
                    ? null
                    : (v) => setState(() {
                        smtpSecurity = v!;
                        fields['smtpPort']!.text = v == 'SSL' ? '465' : '587';
                      }),
                decoration: InputDecoration(
                  labelText: strings(context).outgoingEncryption,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
          if (report != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                report!,
                style: const TextStyle(fontSize: 13, height: 1.6),
              ),
            ),
          if (busy) const LinearProgressIndicator(),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: busy ? null : () => submit(true),
            child: Text(strings(context).testConnection),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: busy ? null : () => submit(false),
            child: Text(strings(context).saveAccount),
          ),
          if (widget.initial.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        if (await confirm(
                          context,
                          strings(context).deleteThisAccount,
                          strings(context).localEmailsDraftsAndAnalysisForThis,
                          action: strings(context).delete,
                        )) {
                          await widget.c.act('deleteAccount', {
                            'id': widget.initial['id'],
                          });
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                child: Text(
                  strings(context).deleteAccount,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class ModelForm extends StatefulWidget {
  const ModelForm(this.c, {super.key, this.initial = const {}});
  final MailController c;
  final RowData initial;
  @override
  State<ModelForm> createState() => _ModelFormState();
}

class _ModelFormState extends State<ModelForm> {
  final fields = <String, TextEditingController>{};
  late RowData value;
  bool busy = false, visible = false;
  String? report;
  String parameter = 'max_tokens';
  String provider = 'auto', thinkingMode = 'default', effort = '';
  String contextMode = 'auto';
  String outputMode = 'auto';
  RowData get contextEntry =>
      officialModelEndpoint(resolvedProvider, fields['baseUrl']!.text)
      ? widget.c.data
                .rows('modelCatalog')
                .where(
                  (m) =>
                      m.text('provider') == resolvedProvider &&
                      m.text('model') == fields['model']!.text.trim(),
                )
                .firstOrNull ??
            {}
      : {};
  int get effectiveContext => contextMode == 'auto'
      ? contextEntry.number('contextTokens', 32768)
      : int.tryParse(fields['contextTokens']!.text) ?? -1;
  String get resolvedProvider =>
      modelProvider(provider, fields['baseUrl']!.text);
  List<String> get efforts =>
      modelEfforts(resolvedProvider, fields['model']!.text);

  Future<void> modelOptions() async {
    if (busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final existing = widget.initial.text('id').isNotEmpty;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;
        Widget item(
          String key,
          IconData icon,
          String title,
          String subtitle, {
          bool selected = false,
          bool danger = false,
        }) => ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 4,
          ),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: danger ? colors.error : colors.onSurfaceVariant,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: danger ? colors.error : colors.onSurface,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: colors.onSurfaceVariant,
            ),
          ),
          trailing: selected
              ? Icon(Icons.check_circle, color: colors.primary, size: 20)
              : null,
          onTap: () => Navigator.pop(ctx, key),
        );
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * .75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 12,
                    bottom: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings(context).modelOptions,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: strings(context).closeModelOptions,
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      if (existing) ...[
                        item(
                          'text',
                          Icons.chat_bubble_outline,
                          strings(context).defaultTextModel,
                          strings(context).forEverydayChatAndEmailDrafting,
                          selected:
                              widget.c.settings.text('textModelId') ==
                              value.text('id'),
                        ),
                        item(
                          'vision',
                          Icons.image_outlined,
                          strings(context).useAsFixedVisionAssistant,
                          strings(context).forReadingImagesAndPdfPages,
                          selected:
                              widget.c.settings.text('visionModelId') ==
                              value.text('id'),
                        ),
                        const Divider(indent: 24, endIndent: 24),
                      ],
                      item(
                        'diagnose',
                        Icons.network_check_outlined,
                        strings(context).connectionDiagnosticsOptional,
                        strings(context).sendTextStreamingToolAndImageRequests,
                      ),
                      if (existing) ...[
                        const Divider(indent: 24, endIndent: 24),
                        item(
                          'delete',
                          Icons.delete_outline,
                          strings(context).deleteModel,
                          strings(context)
                              .deleteLocalConfigurationAndKeyAfterConfirmation,
                          danger: true,
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || action == null) return;
    if (action == 'diagnose') {
      await submit(true);
      return;
    }
    if (action == 'delete' &&
        !await confirm(
          context,
          strings(context).deleteThisModel,
          strings(context).theLocalConfigurationAndKeyWillBe,
          action: strings(context).delete,
        )) {
      return;
    }
    if (!mounted) return;
    setState(() => busy = true);
    try {
      await widget.c.request(
        action == 'delete' ? 'deleteModel' : 'defaultModel',
        {
          'id': widget.initial['id'],
          if (action != 'delete') 'vision': action == 'vision',
        },
      );
      if (!mounted) return;
      if (action == 'delete') {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'vision'
                  ? strings(context).setAsFixedVisionAssistant
                  : strings(context).setAsDefaultTextModel,
            ),
            behavior: SnackBarBehavior.floating,
            // Keep the brief confirmation below the app bar, away from the
            // save/options row even when the form scroll position changes.
            margin: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              (MediaQuery.sizeOf(context).height -
                      MediaQuery.paddingOf(context).top -
                      kToolbarHeight -
                      128)
                  .clamp(16.0, double.infinity),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => report = e is PlatformException ? e.message : e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void resetThinking() {
    thinkingMode = 'default';
    effort = '';
    fields['thinkingBudget']!.clear();
  }

  @override
  void initState() {
    super.initState();
    value = {...widget.initial};
    parameter = value.text('tokenParameter', 'max_tokens');
    provider = value.text('provider', 'auto');
    thinkingMode = value.text('thinkingMode', 'default');
    effort = value.text('reasoningEffort');
    contextMode = value.text(
      'contextMode',
      widget.initial.isEmpty ? 'auto' : 'custom',
    );
    outputMode = value.text(
      'outputMode',
      widget.initial.isEmpty ? 'auto' : 'custom',
    );
    for (final key in [
      'label',
      'baseUrl',
      'model',
      'secret',
      'contextTokens',
      'outputTokens',
      'thinkingBudget',
    ]) {
      fields[key] = TextEditingController(
        text: value.text(
          key,
          key == 'contextTokens'
              ? '32768'
              : key == 'outputTokens'
              ? '4096'
              : '',
        ),
      );
    }
    report = widget.initial['testReport'];
  }

  RowData payload() => {
    'id': value.text('id'),
    for (final f in fields.entries)
      f.key: f.key.endsWith('Tokens') || f.key == 'thinkingBudget'
          ? (f.value.text.trim().isEmpty && f.key == 'thinkingBudget'
                ? 0
                : int.tryParse(f.value.text) ?? -1)
          : f.value.text.trim(),
    'tokenParameter': parameter,
    'contextMode': contextMode,
    'contextTokens': effectiveContext,
    'outputMode': outputMode,
    if (outputMode == 'auto') 'outputTokens': 0,
    'provider': provider,
    'thinkingMode': thinkingMode,
    'reasoningEffort': effort,
  };
  Future<void> submit(bool test) async {
    setState(() {
      busy = true;
      report = null;
    });
    try {
      final result = await widget.c.request(
        test ? 'testModel' : 'saveModel',
        payload(),
      );
      if (!mounted) return;
      if (test) {
        setState(() {
          value = row(jsonDecode(result as String));
          report = value.text('testReport');
        });
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => report = e is PlatformException ? e.message : e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    for (final f in fields.values) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> choose(
    String title,
    String selected,
    Map<String, String> choices,
    ValueChanged<String> update, {
    String? description,
    Map<String, String> descriptions = const {},
  }) async {
    final selectedValue = await showModelChoices(
      context,
      title: title,
      selected: selected,
      choices: choices,
      description: description,
      descriptions: descriptions,
    );
    if (mounted && selectedValue != null) setState(() => update(selectedValue));
  }

  Widget field(String key, String label, {String? hint, bool secret = false}) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: label,
            child: TextField(
              key: ValueKey('model-field-$key'),
              controller: fields[key],
              enabled: !busy,
              obscureText: secret && !visible,
              autocorrect: false,
              style: const TextStyle(fontSize: 15),
              onChanged:
                  key == 'baseUrl' || key == 'model' || key == 'contextTokens'
                  ? (_) => setState(resetThinking)
                  : null,
              keyboardType: key.endsWith('Tokens') || key == 'thinkingBudget'
                  ? TextInputType.number
                  : TextInputType.text,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                fillColor: colors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: secret && value.flag('hasSecret')
                    ? strings(context).savedLeaveBlankToRetain
                    : null,
                suffixIcon: secret
                    ? IconButton(
                        tooltip: visible
                            ? strings(context).hideKey
                            : strings(context).showKey,
                        onPressed: () => setState(() => visible = !visible),
                        icon: Icon(
                          visible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          if (hint != null) ...[const SizedBox(height: 6), note(hint)],
        ],
      ),
    );
  }

  Widget note(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      height: 1.5,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );

  Widget group(List<Widget> children) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );

  Widget sectionTitle(String title) => Text(
    title,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  );

  Widget choiceRow(
    String key,
    String title,
    String selected,
    Map<String, String> choices,
    ValueChanged<String> update, {
    String? description,
    Map<String, String> descriptions = const {},
  }) => ModelSettingRow(
    key: ValueKey('model-setting-$key'),
    title: title,
    value: choices[selected] ?? selected,
    onTap: busy
        ? null
        : () => choose(
            title,
            selected,
            choices,
            update,
            description: description,
            descriptions: descriptions,
          ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final catalog = widget.c.data
        .rows('modelCatalog')
        .where((m) => m.text('provider') == resolvedProvider)
        .toList();
    final thinkingChoices = {
      'default': strings(context).providerDefault,
      'enabled': strings(context).enableThinking,
      'disabled': strings(context).disableThinking,
      if (resolvedProvider == 'volcengine')
        'auto': strings(context).letTheModelDecide,
    };
    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.initial.isEmpty
              ? strings(context).addModel
              : strings(context).modelSettings,
        ),
        actions: [
          IconButton(
            tooltip: strings(context).modelOptions,
            onPressed: busy ? null : modelOptions,
            icon: const Icon(Icons.more_horiz_rounded, size: 22),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    key: const ValueKey('model-form-scroll'),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        group([
                          sectionTitle(
                            strings(context).connectionConfiguration,
                          ),
                          choiceRow(
                            'provider',
                            strings(context).modelProvider,
                            provider,
                            {
                              ...providerLabelsFor(context),
                              'auto': resolvedProvider == 'compatible'
                                  ? strings(context).autoDetect
                                  : strings(context).autoDetect310(
                                      (providerLabelsFor(
                                        context,
                                      )[resolvedProvider]).toString(),
                                    ),
                            },
                            (key) {
                              provider = key;
                              resetThinking();
                            },
                          ),
                          field('label', strings(context).configurationName),
                          field('baseUrl', strings(context).apiUrl),
                          field('secret', 'API Key', secret: true),
                        ]),
                        const SizedBox(height: 12),
                        group([
                          sectionTitle(strings(context).model),
                          field('model', strings(context).modelName),
                          if (catalog.isNotEmpty)
                            ModelSettingRow(
                              key: const ValueKey('model-setting-catalog'),
                              title: strings(context).selectABundledModel,
                              value: strings(context)
                                  .youCanAlsoEnterTheModelName,
                              onTap: busy
                                  ? null
                                  : () => choose(
                                      strings(context).bundledModels,
                                      fields['model']!.text.trim(),
                                      {
                                        for (final m in catalog)
                                          m.text('model'): m.text('model'),
                                      },
                                      (key) {
                                        fields['model']!.text = key;
                                        resetThinking();
                                      },
                                    ),
                            ),
                        ]),
                        const SizedBox(height: 12),
                        Material(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(18),
                          clipBehavior: Clip.antiAlias,
                          child: ExpansionTile(
                            key: const ValueKey('model-advanced'),
                            shape: const Border(),
                            collapsedShape: const Border(),
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              16,
                            ),
                            title: sectionTitle(
                              strings(context).advancedParameters,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: note(
                                strings(context)
                                    .thinkingModeEffortAndOutputLength,
                              ),
                            ),
                            children: [
                              choiceRow(
                                'thinking',
                                strings(context).thinkingMode,
                                thinkingMode,
                                thinkingChoices,
                                (v) => thinkingMode = v,
                                descriptions: {
                                  'default': strings(
                                    context,
                                  ).useProviderDefaultsWithoutExtraThinkingParameters,
                                  'enabled': strings(context)
                                      .askTheModelToThinkDeeply,
                                  'disabled': strings(context)
                                      .askTheModelToAnswerDirectly,
                                  'auto': strings(context)
                                      .letTheModelDecideWhetherThinkingIs,
                                },
                              ),
                              if (thinkingMode != 'disabled') ...[
                                if (efforts.length > 1)
                                  choiceRow(
                                    'effort',
                                    strings(context).thinkingEffort,
                                    efforts.contains(effort) ? effort : '',
                                    {
                                      for (final e in efforts)
                                        e: effortLabelsFor(context)[e]!,
                                    },
                                    (v) {
                                      effort = v;
                                      if (v.isNotEmpty) {
                                        fields['thinkingBudget']!.clear();
                                      }
                                    },
                                    description: strings(context)
                                        .higherEffortUsuallyTakesLongerAndUses,
                                  ),
                                if (resolvedProvider == 'aliyun' &&
                                    effort.isEmpty)
                                  field(
                                    'thinkingBudget',
                                    strings(context).thinkingBudgetTokens,
                                    hint: strings(
                                      context,
                                    ).blankOrUsesProviderDefaultsChooseEither,
                                  ),
                              ],
                              const SizedBox(height: 8),
                              choiceRow(
                                'context-mode',
                                strings(context).contextSettings,
                                contextMode,
                                {
                                  'auto': strings(context)
                                      .followModelSpecification,
                                  'custom': strings(context).custom,
                                },
                                (v) => contextMode = v,
                                descriptions: {
                                  'auto': strings(context)
                                      .officialApisUseVerifiedContextLimitsFor,
                                  'custom': strings(context)
                                      .setALocalBudgetWithinTheProvider,
                                },
                              ),
                              Padding(
                                key: const ValueKey('model-context-info'),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: note(
                                    contextEntry.isEmpty
                                        ? strings(context).currentContextTokens(
                                            (effectiveContext).toString(),
                                            (Uri.tryParse(
                                                              fields['baseUrl']!
                                                                  .text
                                                                  .trim(),
                                                            )?.host ==
                                                            'ark.cn-beijing.volces.com' &&
                                                        fields['baseUrl']!.text
                                                            .contains(
                                                              '/api/plan/v3',
                                                            )
                                                    ? strings(
                                                        context,
                                                      ).planApiLimitsAreUnverifiedCurrentSettings
                                                    : strings(
                                                        context,
                                                      ).thisApiOrModelIsNotIn)
                                                .toString(),
                                          )
                                        : strings(
                                            context,
                                          ).currentContextTokensOfficialMaximumInputTokens(
                                            (effectiveContext.clamp(
                                              0,
                                              contextEntry.number(
                                                'contextTokens',
                                              ),
                                            )).toString(),
                                            (contextEntry.number(
                                              thinkingMode == 'disabled'
                                                  ? 'maxInputTokens'
                                                  : 'maxThinkingInputTokens',
                                            )).toString(),
                                            (thinkingMode == 'disabled'
                                                    ? strings(context)
                                                          .nonThinking
                                                    : strings(context)
                                                          .thinkingDefault)
                                                .toString(),
                                            (contextEntry.text('verifiedAt'))
                                                .toString(),
                                          ),
                                  ),
                                ),
                              ),
                              note(
                                strings(context)
                                    .contextIsOrganizedAtOfTheEffective,
                              ),
                              choiceRow(
                                'output-mode',
                                strings(context).maximumOutputLength,
                                outputMode,
                                {
                                  'auto': strings(context).useModelMaximum,
                                  'custom': strings(context).custom,
                                },
                                (v) => outputMode = v,
                                descriptions: {
                                  'auto': strings(context)
                                      .useTheVerifiedMaximumOutputForThe,
                                  'custom': strings(context)
                                      .keepYourCustomOutputLength,
                                },
                              ),
                              if (outputMode == 'auto')
                                Padding(
                                  key: const ValueKey('model-output-info'),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: note(
                                      contextEntry.isEmpty
                                          ? strings(context)
                                                .theMaximumOutputForThisApiIs
                                          : strings(
                                              context,
                                            ).modelMaximumOutputTokensRequestsAdjustTo(
                                              (contextEntry.number(
                                                'maxOutputTokens',
                                              )).toString(),
                                            ),
                                    ),
                                  ),
                                ),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final pair = [
                                    if (contextMode == 'custom')
                                      field(
                                        'contextTokens',
                                        strings(context).contextLength,
                                      ),
                                    if (outputMode == 'custom')
                                      field(
                                        'outputTokens',
                                        strings(context).customOutputLength,
                                      ),
                                  ];
                                  if (pair.length <= 1 ||
                                      constraints.maxWidth < 300 ||
                                      MediaQuery.textScalerOf(context)
                                              .scale(14) >
                                          20) {
                                    return Column(children: pair);
                                  }
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: pair[0]),
                                      const SizedBox(width: 12),
                                      Expanded(child: pair[1]),
                                    ],
                                  );
                                },
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: note(
                                  strings(context)
                                      .lengthsAreInTokensSomeModelsCount,
                                ),
                              ),
                              const SizedBox(height: 4),
                              choiceRow(
                                'parameter',
                                strings(context).outputLengthParameter,
                                parameter,
                                {
                                  'max_tokens': strings(context)
                                      .standardParameter,
                                  'max_completion_tokens': strings(context)
                                      .completionLengthParameter,
                                },
                                (v) => parameter = v,
                                description: strings(context)
                                    .chooseAccordingToTheProviderSApi,
                                descriptions: const {
                                  'max_tokens': 'max_tokens',
                                  'max_completion_tokens':
                                      'max_completion_tokens',
                                },
                              ),
                            ],
                          ),
                        ),
                        if (report != null &&
                            report!.trim().isNotEmpty &&
                            report != strings(context).notTested) ...[
                          const SizedBox(height: 12),
                          group([
                            sectionTitle(
                              strings(context).connectionDiagnostics,
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              report!,
                              style: const TextStyle(fontSize: 13, height: 1.5),
                            ),
                          ]),
                        ],
                      ],
                    ),
                  ),
                ),
                if (busy) const LinearProgressIndicator(minHeight: 2),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: busy ? null : () => submit(false),
                      child: Text(
                        busy
                            ? strings(context).processing
                            : strings(context).saveModel,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
