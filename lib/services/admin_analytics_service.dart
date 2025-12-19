import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mood_entry.dart';

class AdminMoodSummary {
  AdminMoodSummary({
    required this.counts,
    required this.totalEntries,
    required this.distinctUsers,
  });

  final Map<MoodLevel, int> counts;
  final int totalEntries;
  final int distinctUsers;
}

class AdminAnalyticsService {
  AdminAnalyticsService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<AdminMoodSummary> fetchMoodSummary({required int days}) async {
    final DateTime since = DateTime.now().subtract(Duration(days: days));
    final List<dynamic> rows = await _client
        .from('moods')
        .select('overall_mood,user_id')
        .gte('date_time', since.toIso8601String());

    final Map<MoodLevel, int> counts = {};
    final Set<String> userIds = {};

    for (final row in rows) {
      final map = row as Map<String, dynamic>;
      final String? mood = map['overall_mood'] as String?;
      final String? userId = map['user_id'] as String?;
      if (mood == null) continue;
      try {
        final MoodLevel level = MoodLevel.values.byName(mood);
        counts.update(level, (value) => value + 1, ifAbsent: () => 1);
        if (userId != null) userIds.add(userId);
      } catch (_) {
        // ignore unknown mood values
      }
    }

    final int total = rows.length;
    return AdminMoodSummary(
      counts: counts,
      totalEntries: total,
      distinctUsers: userIds.length,
    );
  }
}
