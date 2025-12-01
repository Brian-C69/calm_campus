import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
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
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.t('support.title'))),
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
                      strings.t('support.people.title'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.t('support.people.desc'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
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
                  strings.t('support.saved'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                FilledButton.icon(
                  onPressed: () => _openComposer(),
                  icon: const Icon(Icons.add),
                  label: Text(strings.t('support.add')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _contacts.isEmpty
                      ? _EmptyState(onAdd: () => _openComposer())
                      : RefreshIndicator(
                        onRefresh: _loadContacts,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _contacts.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 12),
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
      final id = await DbService.instance.insertSupportContact(
        createdOrUpdated,
      );
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
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(strings.t('support.remove.title')),
            content: Text(strings.t('support.remove.desc')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(strings.t('common.cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(strings.t('common.delete')),
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
    final strings = AppLocalizations.of(context);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.t('help.error.launch'))));
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
    final strings = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final priorityLabel = strings
        .t('support.priority')
        .replaceFirst('{level}', '${contact.priority}');

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
                      Text(
                        contact.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        contact.relationship,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    priorityLabel,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_labelFor(contact.contactType, strings)}: ${contact.contactValue}',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => onLaunch(contact),
                  icon: Icon(_iconFor(contact.contactType)),
                  label: Text(
                    strings
                        .t('support.contact')
                        .replaceFirst('{name}', contact.name),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: Text(strings.t('common.edit')),
                ),
                IconButton(
                  tooltip: strings.t('common.delete'),
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

  String _labelFor(SupportContactType type, AppLocalizations strings) {
    switch (type) {
      case SupportContactType.phone:
        return strings.t('support.label.phone');
      case SupportContactType.whatsapp:
        return strings.t('support.label.whatsapp');
      case SupportContactType.email:
        return strings.t('support.label.email');
      case SupportContactType.other:
        return strings.t('support.label.other');
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
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _relationshipController = TextEditingController(
      text: widget.initial?.relationship ?? '',
    );
    _contactValueController = TextEditingController(
      text: widget.initial?.contactValue ?? '',
    );
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
    final strings = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.initial == null
                ? strings.t('support.form.title.add')
                : strings.t('support.form.title.edit'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: strings.t('support.form.name'),
            ),
            validator:
                (value) =>
                    value == null || value.trim().isEmpty
                        ? strings.t('support.form.name.error')
                        : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _relationshipController,
            decoration: InputDecoration(
              labelText: strings.t('support.form.relationship'),
            ),
            validator:
                (value) =>
                    value == null || value.trim().isEmpty
                        ? strings.t('support.form.relationship.error')
                        : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<SupportContactType>(
            value: _contactType,
            decoration: InputDecoration(
              labelText: strings.t('support.form.type'),
            ),
            items:
                SupportContactType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_labelFor(type, strings)),
                      ),
                    )
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
            decoration: InputDecoration(
              labelText: _valueLabel(_contactType, strings),
            ),
            validator:
                (value) =>
                    value == null || value.trim().isEmpty
                        ? strings.t('support.form.value.error')
                        : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _priority,
            decoration: InputDecoration(
              labelText: strings.t('support.form.priority'),
            ),
            items:
                [1, 2, 3]
                    .map(
                      (level) => DropdownMenuItem(
                        value: level,
                        child: Text(
                          strings
                              .t('support.priority')
                              .replaceFirst('{level}', '$level'),
                        ),
                      ),
                    )
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
                child: Text(strings.t('common.cancel')),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: Text(strings.t('common.save')),
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

  String _labelFor(SupportContactType type, AppLocalizations strings) {
    switch (type) {
      case SupportContactType.phone:
        return strings.t('support.label.phone');
      case SupportContactType.whatsapp:
        return strings.t('support.label.whatsapp');
      case SupportContactType.email:
        return strings.t('support.label.email');
      case SupportContactType.other:
        return strings.t('support.label.other');
    }
  }

  String _valueLabel(SupportContactType type, AppLocalizations strings) {
    switch (type) {
      case SupportContactType.phone:
        return strings.t('support.form.value.phone');
      case SupportContactType.whatsapp:
        return strings.t('support.form.value.whatsapp');
      case SupportContactType.email:
        return strings.t('support.form.value.email');
      case SupportContactType.other:
        return strings.t('support.form.value.other');
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, size: 48),
          const SizedBox(height: 8),
          Text(
            strings.t('support.empty.title'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(strings.t('support.empty.subtitle')),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_alt),
            label: Text(strings.t('support.add')),
          ),
        ],
      ),
    );
  }
}
