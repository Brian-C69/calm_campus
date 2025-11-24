import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/class_entry.dart';
import '../models/mood_entry.dart';
import '../models/task.dart';

class DbService {
  DbService._();

  static final DbService instance = DbService._();

  static const String _databaseName = 'calm_campus.db';
  static const int _databaseVersion = 1;

  static const String _moodsTable = 'moods';
  static const String _classesTable = 'classes';
  static const String _tasksTable = 'tasks';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final String databasePath = await getDatabasesPath();
    final String path = join(databasePath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (Database db, int version) async {
        await _createMoodTable(db);
        await _createClassesTable(db);
        await _createTasksTable(db);
      },
    );

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
        location TEXT NOT NULL
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
        priority TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertMoodEntry(MoodEntry entry) async {
    final Database db = await database;
    final Map<String, dynamic> data = entry.toMap();
    data['extraTags'] = jsonEncode(entry.extraTags.map((tag) => tag.name).toList());
    return db.insert(_moodsTable, data);
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

    return db.update(
      _moodsTable,
      data,
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteMoodEntry(int id) async {
    final Database db = await database;
    return db.delete(
      _moodsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertClass(ClassEntry entry) async {
    final Database db = await database;
    return db.insert(_classesTable, entry.toMap());
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
    return db.update(
      _classesTable,
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteClassEntry(int id) async {
    final Database db = await database;
    return db.delete(
      _classesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertTask(Task task) async {
    final Database db = await database;
    return db.insert(_tasksTable, task.toMap());
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

  Future<int> updateTaskStatus(int id, TaskStatus status) async {
    final Database db = await database;
    return db.update(
      _tasksTable,
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTask(int id) async {
    final Database db = await database;
    return db.delete(
      _tasksTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
