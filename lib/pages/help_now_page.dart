import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/support_contact.dart';
import '../services/db_service.dart';

class HelpNowPage extends StatefulWidget {
  const HelpNowPage({super.key});

  @override
  State<HelpNowPage> createState() => _HelpNowPageState();
}

class _HelpNowPageState extends State<HelpNowPage> {
  late Future<List<SupportContact>> _priorityContactsFuture;

  @override
  void initState() {
    super.initState();
    _priorityContactsFuture = _loadPriorityContacts();
  }

  Future<List<SupportContact>> _loadPriorityContacts() {
    return DbService.instance.getTopPriorityContacts(3);
  }

  void _refreshContacts() {
    setState(() {
      _priorityContactsFuture = _loadPriorityContacts();
    });
  }

  Future<void> _openSupportPlan() async {
    await Navigator.pushNamed(context, '/support-plan');
    if (!mounted) return;
    _refreshContacts();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final helpCards = [
      const _HelpCard(
        title: 'help.card.app.title',
        description: 'help.card.app.desc',
        icon: Icons.info_outline,
      ),
      const _HelpCard(
        title: 'help.card.dsa.title',
        description: 'help.card.dsa.desc',
        icon: Icons.phone_in_talk,
      ),
      const _HelpCard(
        title: 'help.card.mentor.title',
        description: 'help.card.mentor.desc',
        icon: Icons.support_agent,
      ),
      const _HelpCard(
        title: 'help.card.hotline.title',
        description: 'help.card.hotline.desc',
        icon: Icons.healing,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('help.title'))),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: helpCards.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _SupportContactsSection(
              contactsFuture: _priorityContactsFuture,
              onLaunchContact: _launchContact,
              onManagePlan: _openSupportPlan,
            );
          }

          return helpCards[index - 1];
        },
      ),
    );
  }

  Future<void> _launchContact(SupportContact contact) async {
    final Uri? uri;

    switch (contact.contactType) {
      case SupportContactType.phone:
        uri = Uri(scheme: 'tel', path: contact.contactValue);
        break;
      case SupportContactType.whatsapp:
        final sanitized = contact.contactValue.replaceAll(
          RegExp(r'[^0-9+]'),
          '',
        );
        uri = Uri.parse('https://wa.me/$sanitized');
        break;
      case SupportContactType.email:
        uri = Uri(scheme: 'mailto', path: contact.contactValue);
        break;
      case SupportContactType.other:
        uri = Uri.parse(contact.contactValue);
        break;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).t('help.error.launch')),
        ),
      );
    }
  }
}

class _SupportContactsSection extends StatelessWidget {
  const _SupportContactsSection({
    required this.contactsFuture,
    required this.onLaunchContact,
    required this.onManagePlan,
  });

  final Future<List<SupportContact>> contactsFuture;
  final Future<void> Function(SupportContact contact) onLaunchContact;
  final VoidCallback onManagePlan;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<SupportContact>>(
      future: contactsFuture,
      builder: (context, snapshot) {
        final contacts = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.volunteer_activism, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        strings.t('help.contacts.title'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: onManagePlan,
                      icon: const Icon(Icons.edit),
                      label: Text(strings.t('help.contacts.manage')),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  strings.t('help.contacts.desc'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (contacts.isEmpty)
                  _EmptyState(onManagePlan: onManagePlan)
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        contacts
                            .map(
                              (contact) => ActionChip(
                                avatar: Icon(_iconFor(contact.contactType)),
                                label: Text(
                                  '${contact.name} (${contact.relationship})',
                                ),
                                onPressed: () => onLaunchContact(contact),
                              ),
                            )
                            .toList(),
                  ),
                if (!isLoading && contacts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    strings.t('help.contacts.tip'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _iconFor(SupportContactType type) {
    switch (type) {
      case SupportContactType.phone:
        return Icons.phone;
      case SupportContactType.whatsapp:
        return Icons.chat;
      case SupportContactType.email:
        return Icons.email_outlined;
      case SupportContactType.other:
        return Icons.link;
    }
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.t(title),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(strings.t(description)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onManagePlan});

  final VoidCallback onManagePlan;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.t('help.empty.title'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          strings.t('help.empty.desc'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onManagePlan,
          icon: const Icon(Icons.person_add_alt),
          label: Text(strings.t('help.empty.add')),
        ),
      ],
    );
  }
}
