import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../models/mood_entry.dart';
import '../models/task.dart';
import '../services/db_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = true;
  List<Task> _tasks = [];
  List<JournalEntry> _journals = [];
  List<MoodEntry> _moods = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _controller.addListener(() {
      setState(() {
        _query = _controller.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = DbService.instance;
    final tasks = await db.getAllTasks();
    final journals = await db.getJournalEntries();
    final moods = await db.getMoodEntries();
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _journals = journals;
      _moods = moods;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final results = _filterResults();
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('search.title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: strings.t('search.hint'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : results.isEmpty
                      ? Center(child: Text(strings.t('search.empty')))
                      : ListView.separated(
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = results[index];
                            return ListTile(
                              leading: Icon(item.icon),
                              title: Text(item.title),
                              subtitle: Text(item.subtitle),
                              onTap: item.onTap,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  List<_SearchResult> _filterResults() {
    if (_query.isEmpty) return [];
    final List<_SearchResult> results = [];

    for (final task in _tasks) {
      if (task.title.toLowerCase().contains(_query) ||
          task.subject.toLowerCase().contains(_query)) {
        results.add(
          _SearchResult(
            icon: Icons.checklist,
            title: task.title,
            subtitle: task.subject,
            onTap: () => Navigator.pushNamed(context, '/tasks'),
          ),
        );
      }
    }

    for (final journal in _journals) {
      final content = journal.content.toLowerCase();
      if (content.contains(_query)) {
        results.add(
          _SearchResult(
            icon: Icons.menu_book,
            title: AppLocalizations.of(context).t('search.journal'),
            subtitle: journal.content,
            onTap: () => Navigator.pushNamed(context, '/journal'),
          ),
        );
      }
    }

    for (final mood in _moods) {
      final note = mood.note?.toLowerCase() ?? '';
      if (note.contains(_query)) {
        results.add(
          _SearchResult(
            icon: Icons.mood,
            title: AppLocalizations.of(context).t('search.mood'),
            subtitle: mood.note ?? '',
            onTap: () => Navigator.pushNamed(context, '/mood'),
          ),
        );
      }
    }

    return results;
  }
}

class _SearchResult {
  _SearchResult({required this.icon, required this.title, required this.subtitle, this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
}
