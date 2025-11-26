import 'package:flutter/material.dart';

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
    final String text = _controller.text.trim();
    if (text.isEmpty) {
      _showMessage('Write a little note first.');
      return;
    }

    final bool hasAccess = await _ensureLoggedInForSaving();
    if (!hasAccess) {
      return;
    }

    setState(() => _isSaving = true);
    final JournalEntry entry = JournalEntry(
      content: text,
      createdAt: DateTime.now(),
    );
    final int id = await DbService.instance.insertJournalEntry(entry);
    setState(() {
      _entries.insert(0, entry.copyWith(id: id));
      _controller.clear();
      _isSaving = false;
    });

    _showMessage('Saved on this device.');
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

    final LoginNudgeAction action = await LoginNudgeService.instance.maybePrompt(
      context,
      LoginNudgeTrigger.journalSave,
    );

    if (!mounted) return false;
    if (action == LoginNudgeAction.loginSelected) {
      await Navigator.pushNamed(context, '/auth');
      if (!mounted) return;
      final bool refreshedLogin = await UserProfileService.instance.isLoggedIn();
      setState(() => _isLoggedIn = refreshedLogin);
      if (refreshedLogin) {
        await _loadEntries();
      }
    }

    if (!_isLoggedIn) {
      _showMessage('Log in to save your journal so it stays here.');
    }

    return _isLoggedIn;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoadingEntries = true);
    final List<JournalEntry> entries = await DbService.instance.getJournalEntries();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Write a few lines to yourself. This stays on your device unless you choose to log in.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 5,
              minLines: 3,
              decoration: const InputDecoration(
                labelText: 'What is on your mind?',
                hintText: 'Free-write a few sentences',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bookmark_added_outlined),
                label: Text(_isSaving ? 'Saving...' : 'Save journal'),
                onPressed: _isSaving ? null : _saveEntry,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoadingEntries
                  ? const Center(child: CircularProgressIndicator())
                  : _entries.isEmpty
                      ? Center(
                          child: Text(
                            _isLoggedIn
                                ? 'No journal entries yet. Your reflections will be stored here.'
                                : 'Log in first so we can keep your journal safe and ready for next time.',
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
                                  'Saved ${_formatDate(entry.createdAt)} on this device',
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
  }

  String _formatDate(DateTime date) {
    final TimeOfDay time = TimeOfDay.fromDateTime(date);
    final int displayHour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${displayHour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} '
        '${time.period == DayPeriod.am ? 'AM' : 'PM'}';
  }
}
