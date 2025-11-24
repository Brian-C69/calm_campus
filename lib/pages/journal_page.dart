import 'package:flutter/material.dart';

import '../services/login_nudge_service.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _entries = [];
  bool _isSaving = false;

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

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 250));
    setState(() {
      _entries.insert(0, text);
      _controller.clear();
      _isSaving = false;
    });

    _showMessage('Saved on this device.');
    await _handleLoginPrompt();
  }

  Future<void> _handleLoginPrompt() async {
    final LoginNudgeAction action = await LoginNudgeService.instance.maybePrompt(
      context,
      LoginNudgeTrigger.journalSave,
    );

    if (!mounted) return;
    if (action == LoginNudgeAction.loginSelected) {
      _showMessage('Login stays optional unless you choose cloud sync or campus sharing.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
              child: _entries.isEmpty
                  ? const Center(
                      child: Text('No journal entries yet. Your first save will stay local.'),
                    )
                  : ListView.separated(
                      itemCount: _entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => Card(
                        elevation: 0,
                        child: ListTile(
                          leading: const Icon(Icons.book_rounded),
                          title: Text(_entries[index]),
                          subtitle: const Text('Stored locally'),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
