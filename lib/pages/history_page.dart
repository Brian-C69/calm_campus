import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../models/mood_entry.dart';
import '../services/db_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/mood_labels.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<MoodEntry>> _moodEntriesFuture;

  @override
  void initState() {
    super.initState();
    _moodEntriesFuture = _loadMoodEntries();
  }

  Future<List<MoodEntry>> _loadMoodEntries() {
    return DbService.instance.getMoodEntries();
  }

  Future<void> _refreshEntries() async {
    final Future<List<MoodEntry>> future = _loadMoodEntries();
    setState(() {
      _moodEntriesFuture = future;
    });
    await future;
  }

  Future<void> _exportCsv() async {
    final strings = AppLocalizations.of(context);
    try {
      final entries = await DbService.instance.getMoodEntries();
      if (entries.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.t('history.export.empty'))),
        );
        return;
      }

      final buffer = StringBuffer();
      buffer.writeln('id,date_time,overall_mood,main_theme,note');
      for (final e in entries) {
        final date = e.dateTime.toIso8601String();
        final mood = e.overallMood.name;
        final theme = e.mainThemeTag.name;
        final note = (e.note ?? '').replaceAll('"', '""');
        buffer.writeln('${e.id ?? ''},"$date","$mood","$theme","$note"');
      }

      final dir = await getApplicationDocumentsDirectory();
      final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/mood_history_$ts.csv');
      await file.writeAsString(buffer.toString());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('history.export.saved').replaceFirst('{path}', file.path))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${strings.t('history.export.error')}\n$e')),
      );
    }
  }

  String _emojiForMood(MoodLevel mood) {
    return moodEmojis[mood] ?? '🙂';
  }

  String _moodLabel(MoodLevel mood, AppLocalizations strings) {
    return moodLabel(mood, strings);
  }

  String _themeLabel(MoodThemeTag tag, AppLocalizations strings) {
    switch (tag) {
      case MoodThemeTag.stress:
        return strings.t('mood.theme.stress');
      case MoodThemeTag.foodBody:
        return strings.t('mood.theme.foodBody');
      case MoodThemeTag.social:
        return strings.t('mood.theme.social');
      case MoodThemeTag.academics:
        return strings.t('mood.theme.academics');
      case MoodThemeTag.rest:
        return strings.t('mood.theme.rest');
      case MoodThemeTag.motivation:
        return strings.t('mood.theme.motivation');
      case MoodThemeTag.other:
        return strings.t('mood.theme.other');
    }
  }

  String _formatDate(DateTime dateTime, AppLocalizations strings) {
    final DateTime local = dateTime.toLocal();
    return DateFormat.yMMMd(strings.localeName).add_jm().format(local);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('history.title')),
        actions: [
          IconButton(
            tooltip: strings.t('history.export'),
            onPressed: _exportCsv,
            icon: const Icon(Icons.download_outlined),
          ),
          IconButton(
            tooltip: strings.t('history.clearAll'),
            onPressed: _confirmClearAll,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<MoodEntry>>(
        future: _moodEntriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      strings.t('history.error.title'),
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.t('history.error.retry'),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final List<MoodEntry> entries = snapshot.data ?? [];

          if (entries.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshEntries,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 40),
                  const Icon(Icons.sentiment_satisfied_alt, size: 64),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      strings.t('history.empty'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshEntries,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final MoodEntry entry = entries[index];
                final String moodEmoji = _emojiForMood(entry.overallMood);
                final String subtitle =
                    entry.note?.isNotEmpty == true
                        ? entry.note!
                        : strings
                            .t('history.theme')
                            .replaceFirst(
                              '{theme}',
                              _themeLabel(entry.mainThemeTag, strings),
                            );

                return Card(
                  elevation: 0,
                  child: ListTile(
                    leading: Text(
                      moodEmoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(_moodLabel(entry.overallMood, strings)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subtitle),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(entry.dateTime, strings),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmClearAll() async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.t('history.clearAll')),
        content: Text(strings.t('history.clearAll.desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.t('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.t('history.clearAll.confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await DbService.instance.deleteAllMoods();
    await _refreshEntries();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.t('history.empty'))),
    );
  }
}
