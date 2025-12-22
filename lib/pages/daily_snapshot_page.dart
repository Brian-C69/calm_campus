import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/class_entry.dart';
import '../models/mood_entry.dart';
import '../models/movement_entry.dart';
import '../models/sleep_entry.dart';
import '../utils/mood_labels.dart';
import '../models/task.dart';
import '../services/db_service.dart';

class DailySnapshotPage extends StatefulWidget {
  const DailySnapshotPage({super.key});

  @override
  State<DailySnapshotPage> createState() => _DailySnapshotPageState();
}

class _DailySnapshotPageState extends State<DailySnapshotPage> {
  late Future<_SnapshotData> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _loadSnapshot();
  }

  Future<_SnapshotData> _loadSnapshot() async {
    final db = DbService.instance;
    final now = DateTime.now();

    final moodToday = await db.getTodayMood();

    // Next class (today only)
    final List<ClassEntry> todayClasses = await db.getClassesForDay(now.weekday);
    final _NextClassInfo? nextClass = _findNextClass(todayClasses, now);

    // Tasks
    final List<Task> pendingTasks = await db.getPendingTasks();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final tasksDueToday = pendingTasks.where((task) {
      final due = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      return due == today;
    }).toList();
    final overdueTasks = pendingTasks.where((task) {
      final due = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      return due.isBefore(today);
    }).toList();

    // Sleep (yesterday)
    final yesterday = today.subtract(const Duration(days: 1));
    final List<SleepEntry> sleepEntries = await db.getSleepEntries(
      from: yesterday,
      to: yesterday,
      limit: 1,
    );
    final SleepEntry? lastSleep = sleepEntries.isNotEmpty ? sleepEntries.first : null;

    // Movement (today)
    final List<MovementEntry> movementToday = await db.getMovementEntries(
      from: today,
      to: today,
    );

    return _SnapshotData(
      moodToday: moodToday,
      nextClass: nextClass,
      tasksDueToday: tasksDueToday,
      overdueTasks: overdueTasks,
      lastSleep: lastSleep,
      movementToday: movementToday,
    );
  }

  _NextClassInfo? _findNextClass(List<ClassEntry> classes, DateTime now) {
    if (classes.isEmpty) return null;
    classes.sort((a, b) => a.startTime.compareTo(b.startTime));

    for (final cls in classes) {
      final start = _combineTime(now, cls.startTime);
      final end = _combineTime(now, cls.endTime);
      if (end.isAfter(now)) {
        final isOngoing = start.isBefore(now) && end.isAfter(now);
        final startsIn = start.difference(now);
        final leaveSoon = !isOngoing && startsIn.inMinutes > 0 && startsIn.inMinutes <= 10;
        return _NextClassInfo(
          entry: cls,
          start: start,
          end: end,
          isOngoing: isOngoing,
          leaveSoon: leaveSoon,
        );
      }
    }
    return null;
  }

  DateTime _combineTime(DateTime base, String timeString) {
    final parts = timeString.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(base.year, base.month, base.day, hour, minute);
  }

  Future<void> _refresh() async {
    setState(() {
      _snapshotFuture = _loadSnapshot();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('snapshot.title')),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: strings.t('snapshot.refresh'),
          ),
        ],
      ),
      body: FutureBuilder<_SnapshotData>(
        future: _snapshotFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          if (data == null) {
            return Center(child: Text(strings.t('snapshot.error')));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SnapshotCard(
                    title: strings.t('snapshot.nextClass.title'),
                    child: _NextClassSection(data.nextClass),
                  ),
                  const SizedBox(height: 12),
                  _SnapshotCard(
                    title: strings.t('snapshot.tasks.title'),
                    child: _TasksSection(
                      dueToday: data.tasksDueToday,
                      overdue: data.overdueTasks,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SnapshotCard(
                    title: strings.t('snapshot.mood.title'),
                    child: _MoodSection(mood: data.moodToday),
                  ),
                  const SizedBox(height: 12),
                  _SnapshotCard(
                    title: strings.t('snapshot.health.sleepTitle'),
                    child: _SleepSection(sleep: data.lastSleep),
                  ),
                  const SizedBox(height: 12),
                  _SnapshotCard(
                    title: strings.t('snapshot.health.movementTitle'),
                    child: _MovementSection(movementToday: data.movementToday),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SnapshotData {
  _SnapshotData({
    required this.moodToday,
    required this.nextClass,
    required this.tasksDueToday,
    required this.overdueTasks,
    required this.lastSleep,
    required this.movementToday,
  });

  final MoodEntry? moodToday;
  final _NextClassInfo? nextClass;
  final List<Task> tasksDueToday;
  final List<Task> overdueTasks;
  final SleepEntry? lastSleep;
  final List<MovementEntry> movementToday;
}

class _NextClassInfo {
  _NextClassInfo({
    required this.entry,
    required this.start,
    required this.end,
    required this.isOngoing,
    required this.leaveSoon,
  });

  final ClassEntry entry;
  final DateTime start;
  final DateTime end;
  final bool isOngoing;
  final bool leaveSoon;
}

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _NextClassSection extends StatelessWidget {
  const _NextClassSection(this.info);

  final _NextClassInfo? info;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (info == null) {
      return Text(strings.t('snapshot.nextClass.none'), style: theme.textTheme.bodyMedium);
    }

    final entry = info!.entry;
    final start = info!.start;
    final end = info!.end;
    final timeRange =
        '${TimeOfDay.fromDateTime(start).format(context)} - ${TimeOfDay.fromDateTime(end).format(context)}';

    String status;
    if (info!.isOngoing) {
      final minutesLeft = end.difference(DateTime.now()).inMinutes;
      status = strings
          .t('snapshot.nextClass.inProgress')
          .replaceFirst('{minutes}', minutesLeft.toString());
    } else {
      final mins = info!.start.difference(DateTime.now()).inMinutes;
      status = strings.t('snapshot.nextClass.startsIn').replaceFirst('{minutes}', mins.toString());
      if (info!.leaveSoon) {
        status += ' • ${strings.t('snapshot.nextClass.leaveHint')}';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(entry.subject, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(timeRange, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        if (entry.location.isNotEmpty)
          Text(strings.t('snapshot.nextClass.location').replaceFirst('{location}', entry.location),
              style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(status, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _TasksSection extends StatelessWidget {
  const _TasksSection({required this.dueToday, required this.overdue});

  final List<Task> dueToday;
  final List<Task> overdue;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final totalItems = dueToday.take(2).toList() + overdue.take(2).toList();

    if (dueToday.isEmpty && overdue.isEmpty) {
      return Text(strings.t('snapshot.tasks.none'), style: theme.textTheme.bodyMedium);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings
              .t('snapshot.tasks.todayCount')
              .replaceFirst('{count}', dueToday.length.toString()),
          style: theme.textTheme.bodyMedium,
        ),
        Text(
          strings
              .t('snapshot.tasks.overdueCount')
              .replaceFirst('{count}', overdue.length.toString()),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        ...totalItems.map(
          (task) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MoodSection extends StatelessWidget {
  const _MoodSection({required this.mood});

  final MoodEntry? mood;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (mood == null) {
      return Row(
        children: [
          Expanded(child: Text(strings.t('snapshot.mood.prompt'), style: theme.textTheme.bodyMedium)),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/mood'),
            child: Text(strings.t('snapshot.mood.checkIn')),
          ),
        ],
      );
    }

    final time = TimeOfDay.fromDateTime(mood!.dateTime).format(context);
    final label = moodLabel(mood!.overallMood, strings);
    final emoji = moodEmojis[mood!.overallMood] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.t('snapshot.mood.logged'), style: theme.textTheme.bodyMedium),
        const SizedBox(height: 6),
        Text(
          '$emoji $label • $time',
          style: theme.textTheme.bodyLarge,
        ),
        if (mood!.note != null && mood!.note!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(mood!.note!, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _SleepSection extends StatelessWidget {
  const _SleepSection({required this.sleep});

  final SleepEntry? sleep;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Text(
      sleep != null
          ? strings
              .t('snapshot.health.sleep')
              .replaceFirst('{hours}', sleep!.durationHours.toStringAsFixed(1))
              .replaceFirst('{rest}', sleep!.restfulness.toString())
          : strings.t('snapshot.health.sleepNone'),
      style: theme.textTheme.bodyMedium,
    );
  }
}

class _MovementSection extends StatelessWidget {
  const _MovementSection({required this.movementToday});

  final List<MovementEntry> movementToday;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final totalMinutes = movementToday.fold<int>(0, (sum, entry) => sum + entry.minutes);

    return Text(
      totalMinutes > 0
          ? strings.t('snapshot.health.movement').replaceFirst('{minutes}', totalMinutes.toString())
          : strings.t('snapshot.health.movementNone'),
      style: theme.textTheme.bodyMedium,
    );
  }
}
