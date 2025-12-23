import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../services/db_service.dart';
import '../services/login_nudge_service.dart';
import '../services/user_profile_service.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final TextEditingController _controller = TextEditingController();
  final List<JournalEntry> _entries = [];
  bool _isSaving = false;
  bool _isLoadingEntries = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      final strings = AppLocalizations.of(context);
      _showMessage(strings.t('journal.error.empty'));
      return;
    }

    final hasAccess = await _ensureLoggedInForSaving();
    if (!hasAccess) {
      return;
    }

    if (!mounted) return;

    setState(() => _isSaving = true);

    final entry = JournalEntry(content: text, createdAt: DateTime.now());

    final id = await DbService.instance.insertJournalEntry(entry);

    if (!mounted) return;

    setState(() {
      _entries.insert(0, entry.copyWith(id: id));
      _controller.clear();
      _isSaving = false;
    });

    final strings = AppLocalizations.of(context);
    _showMessage(strings.t('journal.saved'));
  }

  Future<void> _loadInitialState() async {
    final bool loggedIn = await UserProfileService.instance.isLoggedIn();
    if (!mounted) return;

    setState(() {
      _isLoggedIn = loggedIn;
    });

    if (loggedIn) {
      await _loadEntries();
    } else {
      setState(() => _isLoadingEntries = false);
    }
  }

  Future<bool> _ensureLoggedInForSaving() async {
    if (_isLoggedIn) return true;

    final action = await LoginNudgeService.instance.maybePrompt(
      context,
      LoginNudgeTrigger.journalSave,
    );

    if (!mounted) return false;

    if (action == LoginNudgeAction.loginSelected) {
      await Navigator.pushNamed(context, '/auth');

      if (!mounted) return _isLoggedIn;

      final refreshedLogin = await UserProfileService.instance.isLoggedIn();

      if (!mounted) return refreshedLogin;

      setState(() => _isLoggedIn = refreshedLogin);

      if (refreshedLogin) {
        await _loadEntries();

        if (!mounted) return true;
      }
    }

    if (!_isLoggedIn) {
      final strings = AppLocalizations.of(context);
      _showMessage(strings.t('journal.nudge'));
    }

    return _isLoggedIn;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoadingEntries = true);
    final List<JournalEntry> entries =
        await DbService.instance.getJournalEntries();
    if (!mounted) return;
    setState(() {
      _entries
        ..clear()
        ..addAll(entries);
      _isLoadingEntries = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.t('journal.title'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.t('journal.intro'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 5,
              minLines: 3,
              decoration: InputDecoration(
                labelText: strings.t('journal.field.label'),
                hintText: strings.t('journal.field.hint'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon:
                    _isSaving
                        ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.bookmark_added_outlined),
                label: Text(
                  _isSaving
                      ? strings.t('journal.saving')
                      : strings.t('journal.save'),
                ),
                onPressed: _isSaving ? null : _saveEntry,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _isLoadingEntries
                      ? const Center(child: CircularProgressIndicator())
                      : _entries.isEmpty
                      ? Center(
                        child: Text(
                          _isLoggedIn
                              ? strings.t('journal.empty.loggedIn')
                              : strings.t('journal.empty.guest'),
                          textAlign: TextAlign.center,
                        ),
                      )
                      : ListView.separated(
                        itemCount: _entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final JournalEntry entry = _entries[index];
                          return Card(
                            elevation: 0,
                            child: ListTile(
                              leading: const Icon(Icons.book_rounded),
                              title: Text(entry.content),
                              subtitle: Text(
                                strings
                                    .t('journal.saved.on')
                                    .replaceFirst(
                                      '{timestamp}',
                                      _formatDate(entry.createdAt),
                                    ),
                              ),
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: strings.t('journal.edit'),
                                    onPressed: () => _editEntry(entry, index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: strings.t('common.delete'),
                                    onPressed: () => _deleteEntry(entry, index),
                                  ),
                                ],
                              ),
                              onLongPress:
                                  () => _showEntryActions(entry, index),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final TimeOfDay time = TimeOfDay.fromDateTime(date);
    final int displayHour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${displayHour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} '
        '${time.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  Future<void> _editEntry(JournalEntry entry, int index) async {
    final strings = AppLocalizations.of(context);
    final controller = TextEditingController(text: entry.content);
    final updatedText = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.t('journal.edit'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 6,
                minLines: 3,
                decoration: InputDecoration(
                  labelText: strings.t('journal.field.label'),
                  hintText: strings.t('journal.field.hint'),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(strings.t('common.cancel')),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed:
                        () => Navigator.of(context).pop(controller.text.trim()),
                    child: Text(strings.t('journal.update')),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (updatedText == null) return;
    if (updatedText.isEmpty) {
      _showMessage(strings.t('journal.error.empty'));
      return;
    }

    final updatedEntry = entry.copyWith(content: updatedText);
    await DbService.instance.updateJournalEntry(updatedEntry);
    if (!mounted) return;
    setState(() {
      _entries[index] = updatedEntry;
    });
    _showMessage(strings.t('journal.updated'));
  }

  Future<void> _showEntryActions(JournalEntry entry, int index) async {
    final strings = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(strings.t('journal.edit')),
                onTap: () {
                  Navigator.of(context).pop();
                  _editEntry(entry, index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(strings.t('common.delete')),
                onTap: () {
                  Navigator.of(context).pop();
                  _deleteEntry(entry, index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteEntry(JournalEntry entry, int index) async {
    final deletedId = entry.id;
    if (deletedId != null) {
      await DbService.instance.deleteJournalEntry(deletedId);
    }
    if (!mounted) return;
    setState(() {
      _entries.remove(entry);
    });
    final strings = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        content: Text(
          strings.t('journal.deleted'),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        action: SnackBarAction(
          label: strings.t('common.undo'),
          textColor: Theme.of(context).colorScheme.primary,
          onPressed: () async {
            final restored = entry.copyWith(
              id: null,
              createdAt: DateTime.now(),
            );
            final newId = await DbService.instance.insertJournalEntry(restored);
            if (!mounted) return;
            setState(() {
              _entries.insert(
                index.clamp(0, _entries.length),
                restored.copyWith(id: newId),
              );
            });
          },
        ),
      ),
    );
  }
}
