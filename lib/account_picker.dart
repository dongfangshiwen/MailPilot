import 'app_language.dart';

import 'package:flutter/material.dart';

import 'controller.dart';

/// Account changes only read the local cache; choosing the current account is a no-op.
Future<void> showAccountPicker(BuildContext context, MailController c) async {
  final activeId = c.data.text('activeAccount');
  final selected = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) {
      final colors = Theme.of(ctx).colorScheme;
      return SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * .75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings(context).switchAccount,
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: strings(context).closeAccountPicker,
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  itemCount: c.accounts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, index) {
                    final account = c.accounts[index];
                    final email = account.text('email');
                    final chosen = account.text('id') == activeId;
                    final localName = email.split('@').first;
                    final domain = email.contains('@')
                        ? '@${email.split('@').skip(1).join('@')}'
                        : '';
                    return Semantics(
                      selected: chosen,
                      child: Material(
                        color: chosen
                            ? colors.primary.withValues(alpha: .07)
                            : colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          key: ValueKey('account-choice-${account.text('id')}'),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: colors.surfaceContainerLow,
                            foregroundColor: colors.primary,
                            child: const Icon(Icons.mail_outline, size: 20),
                          ),
                          title: Text(
                            localName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: domain.isEmpty
                              ? null
                              : Text(
                                  domain,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                          trailing: SizedBox(
                            width: 24,
                            child: chosen
                                ? Icon(
                                    Icons.check_circle,
                                    color: colors.primary,
                                    size: 22,
                                  )
                                : null,
                          ),
                          onTap: () => Navigator.pop(ctx, account.text('id')),
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
    },
  );
  if (selected != null && selected != c.data.text('activeAccount')) {
    await c.act('account', {'id': selected});
  }
}

class AccountPickerButton extends StatelessWidget {
  const AccountPickerButton(this.c, {super.key});
  final MailController c;

  @override
  Widget build(BuildContext context) {
    final email =
        c.accounts
            .where((a) => a['id'] == c.data['activeAccount'])
            .firstOrNull
            ?.text('email') ??
        '';
    return TextButton(
      onPressed: () => showAccountPicker(context, c),
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        alignment: Alignment.centerLeft,
      ),
      child: Semantics(
        label: strings(context).switchAccountCurrent((email).toString()),
        excludeSemantics: true,
        child: Tooltip(
          message: strings(context).switchAccount,
          child: Row(
            children: [
              const Icon(Icons.mail_outline, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
