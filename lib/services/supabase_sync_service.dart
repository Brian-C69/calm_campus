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
  bool _isWatchingLocalChanges = false;
  bool _isUploading = false;
  bool _suppressAutoUpload = false;

  void startAutoUploadWatcher() {
    if (_isWatchingLocalChanges) return;
    _isWatchingLocalChanges = true;
    DbService.instance.setOnChangeHandler(_handleLocalChange);
  }

  Future<void> _handleLocalChange() async {
    if (_suppressAutoUpload) return;
    final user = _client.auth.currentUser;
    if (user == null) return;
    if (_isUploading) return;

    _isUploading = true;
    try {
      await uploadAllData();
    } catch (_) {
      // Best-effort; silent to avoid blocking local actions.
    } finally {
      _isUploading = false;
    }
  }

  Future<void> restoreFromSupabaseIfSignedIn() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await downloadAllData();
  }

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

  Future<void> downloadAllData() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('You need to be signed in to restore your data.');
    }

    final db = DbService.instance;

    _suppressAutoUpload = true;
    try {
      final moods = await _fetchMoods(user.id);
      final classes = await _fetchClasses(user.id);
      final tasks = await _fetchTasks(user.id);
      final journalEntries = await _fetchJournalEntries(user.id);
      final sleepEntries = await _fetchSleepEntries(user.id);
      final periodCycles = await _fetchPeriodCycles(user.id);
      final supportContacts = await _fetchSupportContacts(user.id);
      final movementEntries = await _fetchMovementEntries(user.id);

      await db.replaceMoods(moods);
      await db.replaceClasses(classes);
      await db.replaceTasks(tasks);
      await db.replaceJournalEntries(journalEntries);
      await db.replaceSleepEntries(sleepEntries);
      await db.replacePeriodCycles(periodCycles);
      await db.replaceSupportContacts(supportContacts);
      await db.replaceMovementEntries(movementEntries);
    } finally {
      _suppressAutoUpload = false;
    }
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

    await _client.from('moods').upsert(
          rows,
          onConflict: 'user_id,local_id',
        );
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

    await _client.from('classes').upsert(
          rows,
          onConflict: 'user_id,local_id',
        );
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

    await _client.from('tasks').upsert(
          rows,
          onConflict: 'user_id,local_id',
        );
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

    await _client.from('journal_entries').upsert(
          rows,
          onConflict: 'user_id,local_id',
        );
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

    await _client.from('sleep_entries').upsert(
          rows,
          onConflict: 'user_id,local_id',
        );
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

    await _client.from('period_cycles').upsert(
          rows,
          onConflict: 'user_id,local_id',
        );
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

    await _client.from('support_contacts').upsert(
          rows,
          onConflict: 'user_id,local_id',
        );
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

    await _client.from('movement_entries').upsert(
          rows,
          onConflict: 'user_id,local_id',
        );
  }

  Future<List<MoodEntry>> _fetchMoods(String userId) async {
    final List<dynamic> rows = await _client
        .from('moods')
        .select()
        .eq('user_id', userId)
        .order('date_time', ascending: false);

    return _safeMap(rows, _mapMoodRow);
  }

  Future<List<ClassEntry>> _fetchClasses(String userId) async {
    final List<dynamic> rows = await _client
        .from('classes')
        .select()
        .eq('user_id', userId)
        .order('day_of_week', ascending: true)
        .order('start_time', ascending: true);

    return _safeMap(rows, _mapClassRow);
  }

  Future<List<Task>> _fetchTasks(String userId) async {
    final List<dynamic> rows = await _client
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return _safeMap(rows, _mapTaskRow);
  }

  Future<List<JournalEntry>> _fetchJournalEntries(String userId) async {
    final List<dynamic> rows = await _client
        .from('journal_entries')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return _safeMap(rows, _mapJournalRow);
  }

  Future<List<SleepEntry>> _fetchSleepEntries(String userId) async {
    final List<dynamic> rows = await _client
        .from('sleep_entries')
        .select()
        .eq('user_id', userId)
        .order('sleep_end', ascending: false);

    return _safeMap(rows, _mapSleepRow);
  }

  Future<List<PeriodCycle>> _fetchPeriodCycles(String userId) async {
    final List<dynamic> rows = await _client
        .from('period_cycles')
        .select()
        .eq('user_id', userId)
        .order('cycle_start_date', ascending: false);

    return _safeMap(rows, _mapPeriodCycleRow);
  }

  Future<List<SupportContact>> _fetchSupportContacts(String userId) async {
    final List<dynamic> rows = await _client
        .from('support_contacts')
        .select()
        .eq('user_id', userId)
        .order('priority', ascending: true)
        .order('name', ascending: true);

    return _safeMap(rows, _mapSupportContactRow);
  }

  Future<List<MovementEntry>> _fetchMovementEntries(String userId) async {
    final List<dynamic> rows = await _client
        .from('movement_entries')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    return _safeMap(rows, _mapMovementRow);
  }

  List<T> _safeMap<T>(
    List<dynamic> rows,
    T? Function(Map<String, dynamic> row) mapper,
  ) {
    return rows
        .map((row) => mapper(row as Map<String, dynamic>))
        .whereType<T>()
        .toList();
  }

  MoodEntry? _mapMoodRow(Map<String, dynamic> row) {
    final int? localId = row['local_id'] as int?;
    final String? dateTime = row['date_time'] as String?;
    final String? overallMood = row['overall_mood'] as String?;
    final String? mainThemeTag = row['main_theme_tag'] as String?;
    if (localId == null ||
        dateTime == null ||
        overallMood == null ||
        mainThemeTag == null) {
      return null;
    }

    try {
      final List<MoodThemeTag> extraTags =
          (row['extra_tags'] as List<dynamic>? ?? [])
              .whereType<String>()
              .map(MoodThemeTag.values.byName)
              .toList();

      return MoodEntry(
        id: localId,
        dateTime: DateTime.parse(dateTime),
        overallMood: MoodLevel.values.byName(overallMood),
        mainThemeTag: MoodThemeTag.values.byName(mainThemeTag),
        note: row['note'] as String?,
        extraTags: extraTags,
      );
    } catch (_) {
      return null;
    }
  }

  ClassEntry? _mapClassRow(Map<String, dynamic> row) {
    final int? localId = row['local_id'] as int?;
    final int? dayOfWeek = row['day_of_week'] as int?;
    final String? subject = row['subject'] as String?;
    final String? startTime = row['start_time'] as String?;
    final String? endTime = row['end_time'] as String?;
    final String? location = row['location'] as String?;
    if (localId == null ||
        subject == null ||
        dayOfWeek == null ||
        startTime == null ||
        endTime == null ||
        location == null) {
      return null;
    }

    return ClassEntry(
      id: localId,
      subject: subject,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      location: location,
      classType: (row['class_type'] as String?) ?? '',
      lecturer: (row['lecturer'] as String?) ?? '',
    );
  }

  Task? _mapTaskRow(Map<String, dynamic> row) {
    final int? localId = row['local_id'] as int?;
    final String? title = row['title'] as String?;
    final String? subject = row['subject'] as String?;
    final String? dueDate = row['due_date'] as String?;
    final String? status = row['status'] as String?;
    final String? priority = row['priority'] as String?;
    if (localId == null ||
        title == null ||
        subject == null ||
        dueDate == null ||
        status == null ||
        priority == null) {
      return null;
    }

    try {
      return Task(
        id: localId,
        title: title,
        subject: subject,
        dueDate: DateTime.parse(dueDate),
        status: TaskStatus.values.byName(status),
        priority: TaskPriority.values.byName(priority),
        createdAt: row['created_at'] != null
            ? DateTime.parse(row['created_at'] as String)
            : DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  JournalEntry? _mapJournalRow(Map<String, dynamic> row) {
    final int? localId = row['local_id'] as int?;
    final String? content = row['content'] as String?;
    final String? createdAt = row['created_at'] as String?;
    if (localId == null || content == null || createdAt == null) {
      return null;
    }

    return JournalEntry(
      id: localId,
      content: content,
      createdAt: DateTime.parse(createdAt),
    );
  }

  SleepEntry? _mapSleepRow(Map<String, dynamic> row) {
    final int? localId = row['local_id'] as int?;
    final String? date = row['date'] as String?;
    final String? sleepStart = row['sleep_start'] as String?;
    final String? sleepEnd = row['sleep_end'] as String?;
    final num? durationHours = row['duration_hours'] as num?;
    final int? restfulness = row['restfulness'] as int?;

    if (localId == null ||
        date == null ||
        sleepStart == null ||
        sleepEnd == null ||
        durationHours == null ||
        restfulness == null) {
      return null;
    }

    return SleepEntry(
      id: localId,
      date: DateTime.parse(date),
      sleepStart: DateTime.parse(sleepStart),
      sleepEnd: DateTime.parse(sleepEnd),
      durationHours: durationHours.toDouble(),
      restfulness: restfulness,
    );
  }

  PeriodCycle? _mapPeriodCycleRow(Map<String, dynamic> row) {
    final int? localId = row['local_id'] as int?;
    final String? start = row['cycle_start_date'] as String?;
    final String? end = row['cycle_end_date'] as String?;
    final int? periodDuration = row['period_duration_days'] as int?;

    if (localId == null || start == null || end == null || periodDuration == null) {
      return null;
    }

    return PeriodCycle(
      id: localId,
      cycleStartDate: DateTime.parse(start),
      cycleEndDate: DateTime.parse(end),
      periodDurationDays: periodDuration,
      calculatedCycleLength: row['calculated_cycle_length'] as int?,
    );
  }

  SupportContact? _mapSupportContactRow(Map<String, dynamic> row) {
    final int? localId = row['local_id'] as int?;
    final String? name = row['name'] as String?;
    final String? relationship = row['relationship'] as String?;
    final String? contactType = row['contact_type'] as String?;
    final String? contactValue = row['contact_value'] as String?;
    final int? priority = row['priority'] as int?;

    if (localId == null ||
        name == null ||
        relationship == null ||
        contactType == null ||
        contactValue == null ||
        priority == null) {
      return null;
    }

    try {
      return SupportContact(
        id: localId,
        name: name,
        relationship: relationship,
        contactType: SupportContactType.values.byName(contactType),
        contactValue: contactValue,
        priority: priority,
      );
    } catch (_) {
      return null;
    }
  }

  MovementEntry? _mapMovementRow(Map<String, dynamic> row) {
    final int? localId = row['local_id'] as int?;
    final String? date = row['date'] as String?;
    final int? minutes = row['minutes'] as int?;
    final String? type = row['type'] as String?;
    final String? intensity = row['intensity'] as String?;

    if (localId == null ||
        date == null ||
        minutes == null ||
        type == null ||
        intensity == null) {
      return null;
    }

    try {
      return MovementEntry(
        id: localId,
        date: DateTime.parse(date),
        minutes: minutes,
        type: MovementType.values.byName(type),
        intensity: MovementIntensity.values.byName(intensity),
        energyBefore: row['energy_before'] as int?,
        energyAfter: row['energy_after'] as int?,
        note: row['note'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
