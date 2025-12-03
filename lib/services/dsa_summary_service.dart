import '../l10n/app_localizations.dart';
import '../models/mood_entry.dart';
import '../utils/mood_labels.dart';

import 'db_service.dart';

class MoodStats {
  const MoodStats({
    required this.totalLoggedDays,
    required this.moodCounts,
    required this.themeCounts,
    required this.totalEntries,
  });

  final int totalLoggedDays;
  final Map<MoodLevel, int> moodCounts;
  final Map<MoodThemeTag, int> themeCounts;
  final int totalEntries;
}

class DsaSummaryService {
  DsaSummaryService({DbService? db}) : _db = db ?? DbService.instance;

  final DbService _db;

  Future<List<MoodEntry>> getMoodEntriesForLastDays(int days) async {
    return _db.getMoodEntriesForLastDays(days);
  }

  MoodStats calculateMoodStats(List<MoodEntry> entries) {
    final Map<MoodLevel, int> moodCounts = {};
    final Map<MoodThemeTag, int> themeCounts = {};
    final Set<String> uniqueDays = {};

    for (final MoodEntry entry in entries) {
      final DateTime local = entry.dateTime.toLocal();
      final DateTime dayOnly = DateTime(local.year, local.month, local.day);
      uniqueDays.add(dayOnly.toIso8601String());
      moodCounts.update(entry.overallMood, (count) => count + 1, ifAbsent: () => 1);
      themeCounts.update(entry.mainThemeTag, (count) => count + 1, ifAbsent: () => 1);
    }

    return MoodStats(
      totalLoggedDays: uniqueDays.length,
      moodCounts: moodCounts,
      themeCounts: themeCounts,
      totalEntries: entries.length,
    );
  }

  String buildDsaSummaryText(MoodStats stats, int days, AppLocalizations strings) {
    if (stats.totalEntries == 0) {
      return strings.t('dsa.summary.empty');
    }

    final String topMood = _topMoodLabel(stats.moodCounts, strings);
    final String topThemes = _topThemesLabel(stats.themeCounts, strings);

    return strings
        .t('dsa.summary.template')
        .replaceFirst('{days}', days.toString())
        .replaceFirst('{loggedDays}', stats.totalLoggedDays.toString())
        .replaceFirst('{mood}', topMood)
        .replaceFirst('{themes}', topThemes);
  }

  String _topMoodLabel(Map<MoodLevel, int> counts, AppLocalizations strings) {
    final List<MoodLevel> ordered =
        _orderedByCount(counts).map((entry) => entry.key).toList();
    if (ordered.isEmpty) return strings.t('dsa.summary.mood.unknown');

    final List<String> top = ordered.take(2).map((mood) => moodLabel(mood, strings)).toList();
    return top.join(', ');
  }

  String _topThemesLabel(
      Map<MoodThemeTag, int> counts, AppLocalizations strings) {
    final List<MoodThemeTag> ordered =
        _orderedByCount(counts).map((entry) => entry.key).toList();
    if (ordered.isEmpty) return strings.t('dsa.summary.theme.unknown');

    final List<String> labels =
        ordered.take(2).map((tag) => _themeLabel(tag, strings)).toList();
    return labels.join(', ');
  }

  List<MapEntry<T, int>> _orderedByCount<T>(Map<T, int> counts) {
    final List<MapEntry<T, int>> entries = counts.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
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
}
