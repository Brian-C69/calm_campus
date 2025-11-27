import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final helpCards = [
      const _HelpCard(
        title: 'This app is not an emergency service',
        description: 'If you or someone else is in danger, please contact local emergency services.',
        icon: Icons.info_outline,
      ),
      const _HelpCard(
        title: 'Contact DSA counselling',
        description: 'Email: support@dsa.edu | Phone: +65 1234 5678',
        icon: Icons.phone_in_talk,
      ),
      const _HelpCard(
        title: 'Reach out to a trusted mentor',
        description: 'Pick a lecturer or mentor you feel safe with and ask for a quick check-in.',
        icon: Icons.support_agent,
      ),
      const _HelpCard(
        title: 'Crisis hotlines',
        description: 'Samaritans of Singapore: 1767 | IMH Helpline: 6389-2222',
        icon: Icons.healing,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Help Now')),
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
        final sanitized = contact.contactValue.replaceAll(RegExp(r'[^0-9+]'), '');
        uri = Uri.parse('https://wa.me/$sanitized');
        break;
      case SupportContactType.email:
        uri = Uri(scheme: 'mailto', path: contact.contactValue);
        break;
      case SupportContactType.other:
        uri = Uri.parse(contact.contactValue);
        break;
    }

    if (uri == null) return;

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that contact right now.')),
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
                        'My safe people',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: onManagePlan,
                      icon: const Icon(Icons.edit),
                      label: const Text('Manage'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Save the people you feel safe with. They will show up here for quick calls or messages.',
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
                    children: contacts
                        .map(
                          (contact) => ActionChip(
                            avatar: Icon(_iconFor(contact.contactType)),
                            label: Text('${contact.name} (${contact.relationship})'),
                            onPressed: () => onLaunchContact(contact),
                          ),
                        )
                        .toList(),
                  ),
                if (!isLoading && contacts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'These open your phone apps (calls, WhatsApp, email).',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
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
  const _HelpCard({required this.title, required this.description, required this.icon});

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
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
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(description),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No contacts saved yet',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Add a trusted friend, sibling, or mentor so they appear here when you need them.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onManagePlan,
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Add a support contact'),
        )
      ],
    );
  }
}
