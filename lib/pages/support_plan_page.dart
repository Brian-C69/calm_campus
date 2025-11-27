import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/support_contact.dart';
import '../services/db_service.dart';

class SupportPlanPage extends StatefulWidget {
  const SupportPlanPage({super.key});

  @override
  State<SupportPlanPage> createState() => _SupportPlanPageState();
}

class _SupportPlanPageState extends State<SupportPlanPage> {
  final List<SupportContact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await DbService.instance.getAllSupportContacts();

    if (!mounted) return;
    setState(() {
      _contacts
        ..clear()
        ..addAll(contacts);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Safety & Support Plan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'People who help you feel safe',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Save a few friends, family members, or mentors you can reach out to when things feel heavy. '
                      'You control who appears here.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved contacts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                FilledButton.icon(
                  onPressed: () => _openComposer(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add contact'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _contacts.isEmpty
                      ? _EmptyState(onAdd: () => _openComposer())
                      : RefreshIndicator(
                          onRefresh: _loadContacts,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _contacts.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final contact = _contacts[index];
                              return _ContactCard(
                                contact: contact,
                                onLaunch: _launchContact,
                                onEdit: () => _openComposer(contact),
                                onDelete: () => _deleteContact(contact),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openComposer([SupportContact? contact]) async {
    final createdOrUpdated = await showModalBottomSheet<SupportContact>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final viewInsets = MediaQuery.of(context).viewInsets.bottom;
        final safeBottom = MediaQuery.of(context).padding.bottom;
        return Padding(
          padding: EdgeInsets.only(
            bottom: viewInsets + safeBottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SafeArea(
            child: _SupportContactForm(
              initial: contact,
              onSubmit: (contact) => Navigator.of(context).pop(contact),
            ),
          ),
        );
      },
    );

    if (createdOrUpdated == null) return;

    if (createdOrUpdated.id == null) {
      final id = await DbService.instance.insertSupportContact(createdOrUpdated);
      final saved = createdOrUpdated.copyWith(id: id);
      setState(() {
        _contacts.add(saved);
        _contacts.sort((a, b) => a.priority.compareTo(b.priority));
      });
    } else {
      await DbService.instance.updateSupportContact(createdOrUpdated);
      await _loadContacts();
    }
  }

  Future<void> _deleteContact(SupportContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove contact?'),
        content: const Text('You can add them back anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (contact.id != null) {
      await DbService.instance.deleteSupportContact(contact.id!);
    }

    setState(() {
      _contacts.remove(contact);
    });
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

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contact,
    required this.onLaunch,
    required this.onEdit,
    required this.onDelete,
  });

  final SupportContact contact;
  final Future<void> Function(SupportContact contact) onLaunch;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final priorityLabel = 'Priority ${contact.priority}';

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconFor(contact.contactType), color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(contact.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        contact.relationship,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(priorityLabel,
                      style: Theme.of(context).textTheme.labelSmall),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${_labelFor(contact.contactType)}: ${contact.contactValue}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => onLaunch(contact),
                  icon: Icon(_iconFor(contact.contactType)),
                  label: Text('Contact ${contact.name}'),
                ),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
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

  String _labelFor(SupportContactType type) {
    switch (type) {
      case SupportContactType.phone:
        return 'Phone';
      case SupportContactType.whatsapp:
        return 'WhatsApp';
      case SupportContactType.email:
        return 'Email';
      case SupportContactType.other:
        return 'Other';
    }
  }
}

class _SupportContactForm extends StatefulWidget {
  const _SupportContactForm({required this.onSubmit, this.initial});

  final void Function(SupportContact contact) onSubmit;
  final SupportContact? initial;

  @override
  State<_SupportContactForm> createState() => _SupportContactFormState();
}

class _SupportContactFormState extends State<_SupportContactForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _relationshipController;
  late final TextEditingController _contactValueController;
  late SupportContactType _contactType;
  late int _priority;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initial?.name ?? '');
    _relationshipController =
        TextEditingController(text: widget.initial?.relationship ?? '');
    _contactValueController =
        TextEditingController(text: widget.initial?.contactValue ?? '');
    _contactType = widget.initial?.contactType ?? SupportContactType.phone;
    _priority = widget.initial?.priority ?? 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _contactValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.initial == null ? 'Add support contact' : 'Edit support contact',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Please add a name' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _relationshipController,
            decoration: const InputDecoration(labelText: 'Relationship'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'How do you know them?'
                : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<SupportContactType>(
            value: _contactType,
            decoration: const InputDecoration(labelText: 'Contact type'),
            items: SupportContactType.values
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(_labelFor(type)),
                    ))
                .toList(),
            onChanged: (type) {
              if (type != null) {
                setState(() => _contactType = type);
              }
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contactValueController,
            decoration: InputDecoration(labelText: _valueLabel(_contactType)),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Please add how to reach them'
                : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _priority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: [1, 2, 3]
                .map((level) => DropdownMenuItem(value: level, child: Text('Priority $level')))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _priority = value);
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final contact = SupportContact(
      id: widget.initial?.id,
      name: _nameController.text.trim(),
      relationship: _relationshipController.text.trim(),
      contactType: _contactType,
      contactValue: _contactValueController.text.trim(),
      priority: _priority,
    );

    widget.onSubmit(contact);
  }

  String _labelFor(SupportContactType type) {
    switch (type) {
      case SupportContactType.phone:
        return 'Phone';
      case SupportContactType.whatsapp:
        return 'WhatsApp';
      case SupportContactType.email:
        return 'Email';
      case SupportContactType.other:
        return 'Other';
    }
  }

  String _valueLabel(SupportContactType type) {
    switch (type) {
      case SupportContactType.phone:
        return 'Phone number';
      case SupportContactType.whatsapp:
        return 'WhatsApp number / link';
      case SupportContactType.email:
        return 'Email address';
      case SupportContactType.other:
        return 'Link or handle';
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, size: 48),
          const SizedBox(height: 8),
          Text('No contacts added yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text('Add 2–3 safe people you can contact quickly.'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Add contact'),
          ),
        ],
      ),
    );
  }
}
