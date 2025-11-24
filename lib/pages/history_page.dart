import 'package:flutter/material.dart';

import '../models/mood_entry.dart';
import '../services/db_service.dart';

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

  String _emojiForMood(MoodLevel mood) {
    switch (mood) {
      case MoodLevel.happy:
        return '😊';
      case MoodLevel.excited:
        return '🤩';
      case MoodLevel.grateful:
        return '🙏';
      case MoodLevel.relaxed:
        return '😌';
      case MoodLevel.content:
        return '🙂';
      case MoodLevel.tired:
        return '🥱';
      case MoodLevel.unsure:
        return '🤔';
      case MoodLevel.bored:
        return '😐';
      case MoodLevel.anxious:
        return '😟';
      case MoodLevel.angry:
        return '😠';
      case MoodLevel.stressed:
        return '😣';
      case MoodLevel.sad:
        return '😔';
    }
  }

  String _formatDate(DateTime dateTime) {
    final DateTime local = dateTime.toLocal();
    final String month = local.month.toString().padLeft(2, '0');
    final String day = local.day.toString().padLeft(2, '0');
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mood History')),
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
                      'We could not load your moods right now.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text('Please pull down to try again.'),
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
                children: const [
                  SizedBox(height: 40),
                  Icon(Icons.sentiment_satisfied_alt, size: 64),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No moods saved yet. Your check-ins will show up here.',
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
                final String subtitle = entry.note?.isNotEmpty == true
                    ? entry.note!
                    : 'Theme: ${entry.mainThemeTag.name}';

                return Card(
                  elevation: 0,
                  child: ListTile(
                    leading: Text(
                      moodEmoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(
                      entry.overallMood.name[0].toUpperCase() +
                          entry.overallMood.name.substring(1),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subtitle),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(entry.dateTime),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[600]),
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
}
