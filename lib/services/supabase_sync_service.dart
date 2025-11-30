import 'package:supabase_flutter/supabase_flutter.dart';

import 'db_service.dart';
import '../models/class_entry.dart';
import '../models/journal_entry.dart';
import '../models/mood_entry.dart';
import '../models/movement_entry.dart';
import '../models/period_cycle.dart';
import '../models/sleep_entry.dart';
import '../models/support_contact.dart';
import '../models/task.dart';

class SupabaseSyncService {
  SupabaseSyncService._();

  static final SupabaseSyncService instance = SupabaseSyncService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> uploadAllData() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('You need to be signed in to back up data.');
    }

    final db = DbService.instance;

    await _uploadMoods(user.id, await db.getMoodEntries());
    await _uploadClasses(user.id, await db.getAllClasses());
    await _uploadTasks(user.id, await db.getAllTasks());
    await _uploadJournalEntries(user.id, await db.getJournalEntries());
    await _uploadSleepEntries(user.id, await db.getSleepEntries());
    await _uploadPeriodCycles(user.id, await db.getRecentCycles());
    await _uploadSupportContacts(user.id, await db.getAllSupportContacts());
    await _uploadMovementEntries(
      user.id,
      await db.getMovementEntries(),
    );
  }

  Future<void> _uploadMoods(String userId, List<MoodEntry> moods) async {
    if (moods.isEmpty) return;

    final rows = moods
        .where((m) => m.id != null)
        .map(
          (m) => {
            'user_id': userId,
            'local_id': m.id,
            'date_time': m.dateTime.toIso8601String(),
            'overall_mood': m.overallMood.name,
            'main_theme_tag': m.mainThemeTag.name,
            'note': m.note,
            'extra_tags': m.extraTags.map((t) => t.name).toList(),
          },
        )
        .toList();

    if (rows.isEmpty) return;

    await _client.from('moods').upsert(rows);
  }

  Future<void> _uploadClasses(String userId, List<ClassEntry> classes) async {
    if (classes.isEmpty) return;

    final rows = classes
        .where((c) => c.id != null)
        .map(
          (c) => {
            'user_id': userId,
            'local_id': c.id,
            'subject': c.subject,
            'day_of_week': c.dayOfWeek,
            'start_time': c.startTime,
            'end_time': c.endTime,
            'location': c.location,
            'class_type': c.classType,
            'lecturer': c.lecturer,
          },
        )
        .toList();

    if (rows.isEmpty) return;

    await _client.from('classes').upsert(rows);
  }

  Future<void> _uploadTasks(String userId, List<Task> tasks) async {
    if (tasks.isEmpty) return;

    final rows = tasks
        .where((t) => t.id != null)
        .map(
          (t) => {
            'user_id': userId,
            'local_id': t.id,
            'title': t.title,
            'subject': t.subject,
            'due_date': t.dueDate.toIso8601String(),
            'status': t.status.name,
            'priority': t.priority.name,
            'created_at': t.createdAt.toIso8601String(),
          },
        )
        .toList();

    if (rows.isEmpty) return;

    await _client.from('tasks').upsert(rows);
  }

  Future<void> _uploadJournalEntries(
    String userId,
    List<JournalEntry> entries,
  ) async {
    if (entries.isEmpty) return;

    final rows = entries
        .where((e) => e.id != null)
        .map(
          (e) => {
            'user_id': userId,
            'local_id': e.id,
            'content': e.content,
            'created_at': e.createdAt.toIso8601String(),
          },
        )
        .toList();

    if (rows.isEmpty) return;

    await _client.from('journal_entries').upsert(rows);
  }

  Future<void> _uploadSleepEntries(
    String userId,
    List<SleepEntry> entries,
  ) async {
    if (entries.isEmpty) return;

    final rows = entries
        .where((e) => e.id != null)
        .map(
          (e) => {
            'user_id': userId,
            'local_id': e.id,
            'date': DateTime(
              e.date.year,
              e.date.month,
              e.date.day,
            ).toIso8601String(),
            'sleep_start': e.sleepStart.toIso8601String(),
            'sleep_end': e.sleepEnd.toIso8601String(),
            'duration_hours': e.durationHours,
            'restfulness': e.restfulness,
          },
        )
        .toList();

    if (rows.isEmpty) return;

    await _client.from('sleep_entries').upsert(rows);
  }

  Future<void> _uploadPeriodCycles(
    String userId,
    List<PeriodCycle> cycles,
  ) async {
    if (cycles.isEmpty) return;

    final rows = cycles
        .where((c) => c.id != null)
        .map(
          (c) => {
            'user_id': userId,
            'local_id': c.id,
            'cycle_start_date': c.cycleStartDate.toIso8601String(),
            'cycle_end_date': c.cycleEndDate.toIso8601String(),
            'period_duration_days': c.periodDurationDays,
            'calculated_cycle_length': c.calculatedCycleLength,
          },
        )
        .toList();

    if (rows.isEmpty) return;

    await _client.from('period_cycles').upsert(rows);
  }

  Future<void> _uploadSupportContacts(
    String userId,
    List<SupportContact> contacts,
  ) async {
    if (contacts.isEmpty) return;

    final rows = contacts
        .where((c) => c.id != null)
        .map(
          (c) => {
            'user_id': userId,
            'local_id': c.id,
            'name': c.name,
            'relationship': c.relationship,
            'contact_type': c.contactType.name,
            'contact_value': c.contactValue,
            'priority': c.priority,
          },
        )
        .toList();

    if (rows.isEmpty) return;

    await _client.from('support_contacts').upsert(rows);
  }

  Future<void> _uploadMovementEntries(
    String userId,
    List<MovementEntry> entries,
  ) async {
    if (entries.isEmpty) return;

    final rows = entries
        .where((e) => e.id != null)
        .map(
          (e) => {
            'user_id': userId,
            'local_id': e.id,
            'date': DateTime(
              e.date.year,
              e.date.month,
              e.date.day,
            ).toIso8601String(),
            'minutes': e.minutes,
            'type': e.type.name,
            'intensity': e.intensity.name,
            'energy_before': e.energyBefore,
            'energy_after': e.energyAfter,
            'note': e.note,
          },
        )
        .toList();

    if (rows.isEmpty) return;

    await _client.from('movement_entries').upsert(rows);
  }
}
