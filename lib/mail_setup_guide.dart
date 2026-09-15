import 'app_language.dart';

import 'package:flutter/material.dart';

import 'controller.dart';

/// Bundled guidance only. Links open on user action and never include form data.
class MailSetupGuide {
  const MailSetupGuide(this.name, this.imap, this.smtp, this.steps, this.links);
  final String name, imap, smtp;
  final List<(String, String)> steps, links;
  static const verifiedAt = '2026-09-09';
  static Map<String, MailSetupGuide> get catalog => catalogFor(null);
  static Map<String, MailSetupGuide> catalogFor(BuildContext? context) => {
    'QQ': MailSetupGuide(
      strings(context).qqMail,
      'imap.qq.com',
      'smtp.qq.com',
      [
        (
          strings(context).enableMailServices,
          strings(context).signInToQqMailInA,
        ),
        (
          strings(context).generateAnAppPassword,
          strings(context).completeIdentityVerificationOnTheOfficialPage,
        ),
        (
          strings(context).returnToAccountForm,
          strings(context).enterTheFullEmailAddressServersAre,
        ),
      ],
      [
        (
          strings(context).getAndManageAppPasswords,
          'https://help.mail.qq.com/detail/106/985',
        ),
      ],
    ),
    '163': MailSetupGuide(
      strings(context).mail368,
      'imap.163.com',
      'smtp.163.com',
      [
        (
          strings(context).enableImapSmtp,
          strings(context).signInToWebmailFindPopSmtp,
        ),
        (
          strings(context).getAClientAppPassword,
          strings(context).completeTheVerificationAsInstructedAndEnter,
        ),
        (
          strings(context).checkTheFullEmailAddress,
          strings(context).useYourFullComAddressIfYou,
        ),
      ],
      [
        (
          strings(context).neteaseMailOfficialHelp,
          'https://help.mail.163.com/',
        ),
      ],
    ),
    'aliyun_business': MailSetupGuide(
      strings(context).alibabaBusinessMail,
      'imap.qiye.aliyun.com',
      'smtp.qiye.aliyun.com',
      [
        (
          strings(context).checkClientPermissions,
          strings(context).askTheAdministratorToAllowThirdParty,
        ),
        (
          strings(context).prepareASecurityPassword,
          strings(context).inWebmailGoToSettingsAccountAnd,
        ),
        (
          strings(context).enterTheBusinessEmailAddress,
          strings(context).useTheFullBusinessAddressDefaultServers,
        ),
      ],
      [
        (
          strings(context).allowThirdPartyClients,
          'https://help.aliyun.com/zh/document_detail/606337.html',
        ),
        (
          strings(context).generateAThirdPartyClientSecurityPassword,
          'https://help.aliyun.com/zh/document_detail/444269.html',
        ),
        (
          strings(context).serverAddressesAndPorts,
          'https://help.aliyun.com/zh/document_detail/36576.html',
        ),
      ],
    ),
    'aliyun_personal': MailSetupGuide(
      strings(context).alibabaPersonalMail,
      'imap.aliyun.com',
      'smtp.aliyun.com',
      [
        (
          strings(context).checkAccountType,
          strings(context).thisPresetIsForFreeAlibabaCloud,
        ),
        (
          strings(context).prepareLoginDetails,
          strings(context).enterTheFullEmailAddressAndRequired,
        ),
        (
          strings(context).checkServers,
          strings(context).useTheOfficialSslServerSettingsBelow,
        ),
      ],
      [
        (
          strings(context).personalMailServersAndPorts,
          'https://help.aliyun.com/zh/document_detail/465307.html',
        ),
      ],
    ),
  };
  static MailSetupGuide get custom => customFor(null);
  static MailSetupGuide customFor(BuildContext? context) =>
      MailSetupGuide(strings(context).customEmailProvider, '', '', [
        (
          strings(context).identifyYourProvider,
          strings(context).aCustomDomainDoesNotIdentifyThe,
        ),
        (
          strings(context).getConnectionSettings,
          strings(context).prepareImapAndSmtpHostsPortsEncryption,
        ),
        (
          strings(context).enterAndVerify,
          strings(context).expandServerAndAdvancedSettingsAndEnter,
        ),
      ], []);
}

Future<void> showMailSetupGuide(
  BuildContext context,
  MailController c,
  String provider,
) {
  final guide =
      MailSetupGuide.catalogFor(context)[provider] ??
      MailSetupGuide.customFor(context);
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    constraints: BoxConstraints.tightFor(
      width: MediaQuery.sizeOf(context).width.clamp(0, 640),
    ),
    builder: (context) {
      final colors = Theme.of(context).colorScheme;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .83,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings(context).setupGuide((guide.name).toString()),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: strings(context).closeSetupGuide,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  key: const ValueKey('mail-guide-scroll'),
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  children: [
                    for (final (index, step) in guide.steps.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${index + 1}',
                                textScaler: TextScaler.noScaling,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.$1,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    step.$2,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.55,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (guide.imap.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colors.outlineVariant.withValues(alpha: .6),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings(context).defaultServersSsl,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              strings(context).incomingPortOutgoingPort(
                                (guide.imap).toString(),
                                (guide.smtp).toString(),
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (guide.links.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        strings(context).officialHelp,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      for (final link in guide.links)
                        ListTile(
                          key: ValueKey('mail-guide-link-${link.$2}'),
                          contentPadding: EdgeInsets.zero,
                          minTileHeight: 56,
                          title: Text(
                            link.$1,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            Uri.parse(link.$2).host,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          trailing: Icon(
                            Icons.open_in_new_rounded,
                            size: 18,
                            color: colors.onSurfaceVariant,
                          ),
                          onTap: () => c.act('openLink', {'url': link.$2}),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        strings(context).verifiedOfficialPagesOpenInYourBrowser(
                          (MailSetupGuide.verifiedAt).toString(),
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(strings(context).returnToForm),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
