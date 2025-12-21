import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/announcement.dart';
import '../models/class_entry.dart';
import '../models/journal_entry.dart';
import '../models/mood_entry.dart';
import '../models/movement_entry.dart';
import '../models/period_cycle.dart';
import '../models/sleep_entry.dart';
import '../models/support_contact.dart';
import '../models/task.dart';

class DbService {
  DbService._();

  static final DbService instance = DbService._();

  Future<void> Function()? _onChange;

  static const String _databaseName = 'calm_campus.db';
  static const int _databaseVersion = 9;

  static const String _moodsTable = 'moods';
  static const String _classesTable = 'classes';
  static const String _tasksTable = 'tasks';
  static const String _journalTable = 'journal_entries';
  static const String _sleepTable = 'sleep_entries';
  static const String _periodCyclesTable = 'period_cycles';
  static const String _supportContactsTable = 'support_contacts';
  static const String _movementEntriesTable = 'movement_entries';
  static const String _announcementsTable = 'announcements';

  Database? _database;

  void setOnChangeHandler(Future<void> Function()? handler) {
    _onChange = handler;
  }

  Future<void> _notifyChange() async {
    final handler = _onChange;
    if (handler != null) {
      await handler();
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;

    final String databasePath = await getDatabasesPath();
    final String path = join(databasePath, _databaseName);

    _database = await openDatabase(path, version: _databaseVersion,
        onCreate: (Database db, int version) async {
      await _createMoodTable(db);
      await _createClassesTable(db);
      await _createTasksTable(db);
      await _createJournalTable(db);
      await _createSleepTable(db);
      await _createPeriodCyclesTable(db);
      await _createSupportContactsTable(db);
      await _createMovementEntriesTable(db);
      await _createAnnouncementsTable(db);
    }, onUpgrade: (Database db, int oldVersion, int newVersion) async {
      if (oldVersion < 2) {
        await db.execute(
          'ALTER TABLE $_classesTable ADD COLUMN classType TEXT NOT NULL DEFAULT ""',
        );
        await db.execute(
          'ALTER TABLE $_classesTable ADD COLUMN lecturer TEXT NOT NULL DEFAULT ""',
        );
      }

      if (oldVersion < 3) {
        await _createJournalTable(db);
      }

      if (oldVersion < 4) {
        await db.execute(
          'ALTER TABLE $_tasksTable ADD COLUMN createdAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP',
        );
      }

      if (oldVersion < 5) {
        await _createSleepTable(db);
      }

      if (oldVersion < 6) {
        await _createPeriodCyclesTable(db);
      }

      if (oldVersion < 7) {
        await _createSupportContactsTable(db);
      }

      if (oldVersion < 8) {
        await _createMovementEntriesTable(db);
      }

      if (oldVersion < 9) {
        await _createAnnouncementsTable(db);
      }
    });

    return _database!;
  }

  Future<void> _createMoodTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_moodsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dateTime TEXT NOT NULL,
        overallMood TEXT NOT NULL,
        mainThemeTag TEXT NOT NULL,
        note TEXT,
        extraTags TEXT
      )
    ''');
  }

  Future<void> _createClassesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_classesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT NOT NULL,
        dayOfWeek INTEGER NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        location TEXT NOT NULL,
        classType TEXT NOT NULL,
        lecturer TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createTasksTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_tasksTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        subject TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        status TEXT NOT NULL,
        priority TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createJournalTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_journalTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createSleepTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_sleepTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        sleepStart TEXT NOT NULL,
        sleepEnd TEXT NOT NULL,
        durationHours REAL NOT NULL,
        restfulness INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createPeriodCyclesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_periodCyclesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cycleStartDate TEXT NOT NULL,
        cycleEndDate TEXT NOT NULL,
        calculatedCycleLength INTEGER,
        periodDurationDays INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createSupportContactsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_supportContactsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        relationship TEXT NOT NULL,
        contactType TEXT NOT NULL,
        contactValue TEXT NOT NULL,
        priority INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createMovementEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_movementEntriesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        minutes INTEGER NOT NULL,
        type TEXT NOT NULL,
        intensity TEXT NOT NULL,
        energyBefore INTEGER,
        energyAfter INTEGER,
      note TEXT
    )
    ''');
  }

  Future<void> _createAnnouncementsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_announcementsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        summary TEXT NOT NULL,
        body TEXT NOT NULL,
        author TEXT NOT NULL,
        category TEXT,
        publishedAt TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertMoodEntry(MoodEntry entry) async {
    final Database db = await database;
    final Map<String, dynamic> data = entry.toMap();
    data['extraTags'] = jsonEncode(entry.extraTags.map((tag) => tag.name).toList());
    final int id = await db.insert(_moodsTable, data);
    await _notifyChange();
    return id;
  }

  Future<List<MoodEntry>> getMoodEntries({DateTime? from, DateTime? to}) async {
    final Database db = await database;
    final List<String> whereClauses = [];
    final List<Object?> whereArgs = [];

    if (from != null) {
      whereClauses.add('dateTime >= ?');
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      whereClauses.add('dateTime <= ?');
      whereArgs.add(to.toIso8601String());
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _moodsTable,
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'dateTime DESC',
    );

    return maps.map((map) {
      final List<dynamic> decodedTags = jsonDecode(map['extraTags'] as String? ?? '[]') as List<dynamic>;
      return MoodEntry.fromMap({
        ...map,
        'extraTags': decodedTags,
      });
    }).toList();
  }

  Future<List<MoodEntry>> getMoodEntriesForLastDays(int days) {
    final DateTime now = DateTime.now();
    final int safeDays = days <= 0 ? 1 : days;
    final DateTime start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: safeDays - 1));
    final DateTime end =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    return getMoodEntries(from: start, to: end);
  }

  Future<MoodEntry?> getTodayMood() async {
    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(now.year, now.month, now.day);
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    final List<MoodEntry> entries = await getMoodEntries(from: startOfDay, to: endOfDay);
    return entries.isNotEmpty ? entries.first : null;
  }

  Future<int> updateMoodEntry(MoodEntry entry) async {
    if (entry.id == null) return 0;

    final Database db = await database;
    final Map<String, dynamic> data = entry.toMap();
    data['extraTags'] = jsonEncode(entry.extraTags.map((tag) => tag.name).toList());

    final int updated = await db.update(
      _moodsTable,
      data,
      where: 'id = ?',
      whereArgs: [entry.id],
    );
    await _notifyChange();
    return updated;
  }

  Future<int> deleteMoodEntry(int id) async {
    final Database db = await database;
    final int deleted = await db.delete(
      _moodsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    await _notifyChange();
    return deleted;
  }

  Future<int> insertClass(ClassEntry entry) async {
    final Database db = await database;
    final int id = await db.insert(_classesTable, entry.toMap());
    await _notifyChange();
    return id;
  }

  Future<List<ClassEntry>> getClassesForDay(int weekday) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _classesTable,
      where: 'dayOfWeek = ?',
      whereArgs: [weekday],
      orderBy: 'startTime ASC',
    );

    return maps.map(ClassEntry.fromMap).toList();
  }

  Future<List<ClassEntry>> getAllClasses() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _classesTable,
      orderBy: 'dayOfWeek ASC, startTime ASC',
    );
    return maps.map(ClassEntry.fromMap).toList();
  }

  Future<int> updateClassEntry(ClassEntry entry) async {
    if (entry.id == null) return 0;

    final Database db = await database;
    final int updated = await db.update(
      _classesTable,
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
    await _notifyChange();
    return updated;
  }

  Future<int> deleteClassEntry(int id) async {
    final Database db = await database;
    final int deleted = await db.delete(
      _classesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    await _notifyChange();
    return deleted;
  }

  Future<int> restoreClassEntry(ClassEntry entry) async {
    final Database db = await database;
    final int id = await db.insert(_classesTable, entry.toMap());
    await _notifyChange();
    return id;
  }

  Future<int> insertTask(Task task) async {
    final Database db = await database;
    final int id = await db.insert(_tasksTable, task.toMap());
    await _notifyChange();
    return id;
  }

  Future<List<Task>> getPendingTasks() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tasksTable,
      where: 'status = ?',
      whereArgs: [TaskStatus.pending.name],
      orderBy: 'dueDate ASC',
    );
    return maps.map(Task.fromMap).toList();
  }

  Future<List<Task>> getTasksByDate(DateTime date) async {
    final DateTime startOfDay = DateTime(date.year, date.month, date.day);
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tasksTable,
      where: 'dueDate >= ? AND dueDate < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'dueDate ASC',
    );

    return maps.map(Task.fromMap).toList();
  }

  Future<List<Task>> getAllTasks() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tasksTable,
      orderBy: 'createdAt ASC',
    );

    return maps.map(Task.fromMap).toList();
  }

  Future<int> updateTaskStatus(int id, TaskStatus status) async {
    final Database db = await database;
    final int updated = await db.update(
      _tasksTable,
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _notifyChange();
    return updated;
  }

  Future<int> deleteTask(int id) async {
    final Database db = await database;
    final int deleted = await db.delete(
      _tasksTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    await _notifyChange();
    return deleted;
  }

  Future<int> restoreTask(Task task) async {
    final Database db = await database;
    final int id = await db.insert(_tasksTable, task.toMap());
    await _notifyChange();
    return id;
  }

  Future<int> insertJournalEntry(JournalEntry entry) async {
    final Database db = await database;
    final int id = await db.insert(_journalTable, entry.toMap());
    await _notifyChange();
    return id;
  }

  Future<int> deleteJournalEntry(int id) async {
    final Database db = await database;
    final int deleted = await db.delete(
      _journalTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    await _notifyChange();
    return deleted;
  }

  Future<List<JournalEntry>> getJournalEntries() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _journalTable,
      orderBy: 'createdAt DESC',
    );
    return maps.map(JournalEntry.fromMap).toList();
  }

  Future<int> insertSleepEntry(SleepEntry entry) async {
    final Database db = await database;
    final int id = await db.insert(_sleepTable, entry.toMap());
    await _notifyChange();
    return id;
  }

  Future<List<SleepEntry>> getSleepEntries({
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    final Database db = await database;
    final List<String> whereClauses = [];
    final List<Object?> whereArgs = [];

    if (from != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(DateTime(from.year, from.month, from.day).toIso8601String());
    }

    if (to != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(DateTime(to.year, to.month, to.day).toIso8601String());
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _sleepTable,
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'sleepEnd DESC',
      limit: limit,
    );

    return maps.map(SleepEntry.fromMap).toList();
  }

  Future<SleepEntry?> getLatestSleepEntry() async {
    final List<SleepEntry> entries = await getSleepEntries(limit: 1);
    return entries.isNotEmpty ? entries.first : null;
  }

  Future<int> deleteSleepEntry(int id) async {
    final Database db = await database;
    final int deleted = await db.delete(
      _sleepTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    await _notifyChange();
    return deleted;
  }

  Future<int> insertPeriodCycle(PeriodCycle cycle) async {
    final Database db = await database;

    int? calculatedCycleLength = cycle.calculatedCycleLength;
    final DateTime? previousStart =
        await _findPreviousCycleStart(cycle.cycleStartDate);
    if (calculatedCycleLength == null && previousStart != null) {
      calculatedCycleLength = cycle.cycleStartDate
          .difference(DateTime(previousStart.year, previousStart.month,
              previousStart.day))
          .inDays;
    }

    final PeriodCycle toSave = cycle.copyWith(
      calculatedCycleLength: calculatedCycleLength,
      periodDurationDays: cycle.periodDurationDays,
    );

    final int id = await db.insert(_periodCyclesTable, toSave.toMap());
    await _notifyChange();
    return id;
  }

  Future<List<PeriodCycle>> getRecentCycles({int? limit}) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _periodCyclesTable,
      orderBy: 'cycleStartDate DESC',
      limit: limit,
    );

    return maps.map(PeriodCycle.fromMap).toList();
  }

  Future<List<PeriodCycle>> getCyclesBetween(
      DateTime from, DateTime to) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _periodCyclesTable,
      where: 'cycleStartDate >= ? AND cycleEndDate <= ?',
      whereArgs: [
        DateTime(from.year, from.month, from.day).toIso8601String(),
        DateTime(to.year, to.month, to.day).toIso8601String(),
      ],
      orderBy: 'cycleStartDate DESC',
    );

    return maps.map(PeriodCycle.fromMap).toList();
  }

  Future<int> updatePeriodCycle(PeriodCycle cycle) async {
    if (cycle.id == null) return 0;

    final Database db = await database;
    int? calculatedCycleLength = cycle.calculatedCycleLength;
    final DateTime? previousStart = await _findPreviousCycleStart(
      cycle.cycleStartDate,
      excludeId: cycle.id,
    );

    if (calculatedCycleLength == null && previousStart != null) {
      calculatedCycleLength = cycle.cycleStartDate
          .difference(DateTime(previousStart.year, previousStart.month,
              previousStart.day))
          .inDays;
    }

    final int updated = await db.update(
      _periodCyclesTable,
      cycle.copyWith(calculatedCycleLength: calculatedCycleLength).toMap(),
      where: 'id = ?',
      whereArgs: [cycle.id],
    );
    await _notifyChange();
    return updated;
  }

  Future<int> deletePeriodCycle(int id) async {
    final Database db = await database;
    final int deleted = await db.delete(
      _periodCyclesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    await _notifyChange();
    return deleted;
  }

  Future<DateTime?> _findPreviousCycleStart(DateTime start,
      {int? excludeId}) async {
    final Database db = await database;
    final List<String> whereClauses = ['cycleStartDate < ?'];
    final List<Object?> whereArgs = [
      DateTime(start.year, start.month, start.day).toIso8601String()
    ];

    if (excludeId != null) {
      whereClauses.add('id != ?');
      whereArgs.add(excludeId);
    }

    final List<Map<String, dynamic>> result = await db.query(
      _periodCyclesTable,
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'cycleStartDate DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return DateTime.parse(result.first['cycleStartDate'] as String);
  }

  Future<int> insertSupportContact(SupportContact contact) async {
    final Database db = await database;
    final int id = await db.insert(_supportContactsTable, contact.toMap());
    await _notifyChange();
    return id;
  }

  Future<List<SupportContact>> getAllSupportContacts() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _supportContactsTable,
      orderBy: 'priority ASC, name COLLATE NOCASE ASC',
    );

    return maps.map(SupportContact.fromMap).toList();
  }

  Future<List<SupportContact>> getTopPriorityContacts(int limit) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _supportContactsTable,
      orderBy: 'priority ASC, name COLLATE NOCASE ASC',
      limit: limit,
    );

    return maps.map(SupportContact.fromMap).toList();
  }

  Future<int> updateSupportContact(SupportContact contact) async {
    if (contact.id == null) return 0;

    final Database db = await database;
    final int updated = await db.update(
      _supportContactsTable,
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
    await _notifyChange();
    return updated;
  }

  Future<int> deleteSupportContact(int id) async {
    final Database db = await database;
    final int deleted = await db.delete(
      _supportContactsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    await _notifyChange();
    return deleted;
  }

  Future<int> insertMovementEntry(MovementEntry entry) async {
    final Database db = await database;
    final int id = await db.insert(_movementEntriesTable, entry.toMap());
    await _notifyChange();
    return id;
  }

  Future<List<MovementEntry>> getMovementEntries({
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    final Database db = await database;
    final List<String> whereClauses = [];
    final List<Object?> whereArgs = [];

    if (from != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(DateTime(from.year, from.month, from.day).toIso8601String());
    }

    if (to != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(DateTime(to.year, to.month, to.day).toIso8601String());
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _movementEntriesTable,
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC',
      limit: limit,
    );

    return maps.map(MovementEntry.fromMap).toList();
  }

  Future<int> deleteMovementEntry(int id) async {
    final Database db = await database;
    final int deleted = await db.delete(
      _movementEntriesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    await _notifyChange();
    return deleted;
  }

  Future<void> replaceMoods(List<MoodEntry> entries) async {
    final Database db = await database;
    await db.transaction((txn) async {
      await txn.delete(_moodsTable);
      for (final MoodEntry entry in entries) {
        final Map<String, dynamic> data = entry.toMap();
        data['extraTags'] =
            jsonEncode(entry.extraTags.map((tag) => tag.name).toList());
        await txn.insert(
          _moodsTable,
          data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> replaceClasses(List<ClassEntry> entries) async {
    final Database db = await database;
    await db.transaction((txn) async {
      await txn.delete(_classesTable);
      for (final ClassEntry entry in entries) {
        await txn.insert(
          _classesTable,
          entry.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> replaceTasks(List<Task> tasks) async {
    final Database db = await database;
    await db.transaction((txn) async {
      await txn.delete(_tasksTable);
      for (final Task task in tasks) {
        await txn.insert(
          _tasksTable,
          task.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> replaceJournalEntries(List<JournalEntry> entries) async {
    final Database db = await database;
    await db.transaction((txn) async {
      await txn.delete(_journalTable);
      for (final JournalEntry entry in entries) {
        await txn.insert(
          _journalTable,
          entry.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> replaceSleepEntries(List<SleepEntry> entries) async {
    final Database db = await database;
    await db.transaction((txn) async {
      await txn.delete(_sleepTable);
      for (final SleepEntry entry in entries) {
        await txn.insert(
          _sleepTable,
          entry.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> replacePeriodCycles(List<PeriodCycle> cycles) async {
    final Database db = await database;
    await db.transaction((txn) async {
      await txn.delete(_periodCyclesTable);
      for (final PeriodCycle cycle in cycles) {
        await txn.insert(
          _periodCyclesTable,
          cycle.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> replaceSupportContacts(List<SupportContact> contacts) async {
    final Database db = await database;
    await db.transaction((txn) async {
      await txn.delete(_supportContactsTable);
      for (final SupportContact contact in contacts) {
        await txn.insert(
          _supportContactsTable,
          contact.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> replaceMovementEntries(List<MovementEntry> entries) async {
    final Database db = await database;
    await db.transaction((txn) async {
      await txn.delete(_movementEntriesTable);
      for (final MovementEntry entry in entries) {
        await txn.insert(
          _movementEntriesTable,
          entry.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<int> insertAnnouncement(Announcement announcement) async {
    final Database db = await database;
    final int id = await db.insert(_announcementsTable, announcement.toMap());
    await _notifyChange();
    return id;
  }

  Future<void> replaceAnnouncements(List<Announcement> announcements) async {
    final Database db = await database;
    await db.transaction((txn) async {
      await txn.delete(_announcementsTable);
      for (final Announcement announcement in announcements) {
        await txn.insert(_announcementsTable, announcement.toMap());
      }
    });
  }

  Future<List<Announcement>> getAnnouncements({int? limit}) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _announcementsTable,
      orderBy: 'publishedAt DESC',
      limit: limit,
    );

    return maps.map(Announcement.fromMap).toList();
  }

  Future<int> deleteAnnouncement(int id) async {
    final Database db = await database;
    final int deleted = await db.delete(
      _announcementsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    await _notifyChange();
    return deleted;
  }
}
