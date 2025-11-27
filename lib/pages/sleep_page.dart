import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mood_entry.dart';
import '../models/sleep_entry.dart';
import '../services/db_service.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  static const String _sleepSessionKey = 'sleepSessionStart';

  late Future<List<SleepEntry>> _entriesFuture;
  late Future<String> _insightsFuture;

  DateTime _selectedDate = DateTime.now();
  late TimeOfDay _sleepStart;
  late TimeOfDay _sleepEnd;
  double _restfulness = 3;
  bool _isSaving = false;
  bool _isStartingSession = false;
  bool _isEndingSession = false;
  DateTime? _sessionStartTime;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    final DateTime defaultStart = now.subtract(const Duration(hours: 8));
    _sleepStart = TimeOfDay.fromDateTime(defaultStart);
    _sleepEnd = TimeOfDay.fromDateTime(now);
    _entriesFuture = _loadEntries();
    _insightsFuture = _buildInsights();
    _restoreSessionStart();
  }

  Future<List<SleepEntry>> _loadEntries() {
    return DbService.instance.getSleepEntries();
  }

  Future<String> _buildInsights() async {
    final List<SleepEntry> entries = await DbService.instance.getSleepEntries();
    if (entries.isEmpty) {
      return 'Log a few nights of sleep to unlock personalised insights.';
    }

    final List<SleepEntry> recentEntries = entries.take(7).toList();
    final double averageDuration = _averageDurationHours(recentEntries);
    final double averageRestfulness = _averageRestfulness(recentEntries);

    final List<MoodEntry> moods = await DbService.instance.getMoodEntries();
    final Map<DateTime, MoodEntry> moodByDate = {};
    for (final mood in moods) {
      final DateTime key = _asDateKey(mood.dateTime);
      moodByDate.putIfAbsent(key, () => mood);
    }

    final List<double> brighterSleep = [];
    final List<double> lowerSleep = [];
    for (final entry in entries) {
      final MoodEntry? mood = moodByDate[_asDateKey(entry.date)];
      if (mood == null) continue;

      if (_isBrighterMood(mood.overallMood)) {
        brighterSleep.add(entry.durationHours);
      } else if (_isLowerMood(mood.overallMood)) {
        lowerSleep.add(entry.durationHours);
      }
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln(
        'Past week: average sleep ${_formatDuration(averageDuration)} · restfulness ${averageRestfulness.toStringAsFixed(1)}/5');

    if (brighterSleep.isNotEmpty && lowerSleep.isNotEmpty) {
      buffer.writeln(
        'On brighter mood days you averaged ${_formatDuration(_average(brighterSleep))} of sleep, compared to ${_formatDuration(_average(lowerSleep))} on tougher days.',
      );
    } else {
      buffer.writeln(
          'As you add more moods and sleep logs, we\'ll look for patterns to help you find balance.');
    }

    return buffer.toString();
  }

  Future<void> _restoreSessionStart() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? rawStart = prefs.getString(_sleepSessionKey);
    if (rawStart == null) return;

    final DateTime? storedStart = DateTime.tryParse(rawStart);
    if (storedStart == null) {
      await prefs.remove(_sleepSessionKey);
      return;
    }

    if (!mounted) return;
    setState(() {
      _sessionStartTime = storedStart;
    });
  }

  Future<void> _startSleepSession() async {
    setState(() {
      _isStartingSession = true;
    });

    final DateTime start = DateTime.now();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sleepSessionKey, start.toIso8601String());

    if (!mounted) return;
    setState(() {
      _sessionStartTime = start;
      _isStartingSession = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sleep session started. Sweet dreams!'),
      ),
    );
  }

  Future<void> _cancelSleepSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sleepSessionKey);
    if (!mounted) return;
    setState(() {
      _sessionStartTime = null;
    });
  }

  Future<int?> _promptRestfulnessRating() async {
    double sliderValue = 3;

    return showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('How rested do you feel?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('1 = exhausted, 5 = deeply rested'),
                  Slider(
                    value: sliderValue,
                    divisions: 4,
                    min: 1,
                    max: 5,
                    label: sliderValue.toStringAsFixed(0),
                    onChanged: (double value) {
                      setState(() {
                        sliderValue = value;
                      });
                    },
                  ),
                  Text('Restfulness: ${sliderValue.toStringAsFixed(0)}/5'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Keep sleeping'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop<int>(context, sliderValue.round()),
                  child: const Text('Save session'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _endSleepSession() async {
    if (_sessionStartTime == null) return;

    setState(() {
      _isEndingSession = true;
    });

    final int? restfulness = await _promptRestfulnessRating();
    if (!mounted) return;

    if (restfulness == null) {
      setState(() {
        _isEndingSession = false;
      });
      return;
    }

    final DateTime start = _sessionStartTime!;
    final DateTime end = DateTime.now();
    final Duration duration = end.difference(start);
    final double durationHours = duration.inMinutes / 60;

    final SleepEntry entry = SleepEntry(
      date: _asDateKey(end),
      sleepStart: start,
      sleepEnd: end,
      durationHours: durationHours,
      restfulness: restfulness,
    );

    await DbService.instance.insertSleepEntry(entry);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sleepSessionKey);

    if (!mounted) return;
    setState(() {
      _sessionStartTime = null;
      _entriesFuture = _loadEntries();
      _insightsFuture = _buildInsights();
      _isEndingSession = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Logged ${_formatDuration(durationHours)} of sleep. Restfulness $restfulness/5.',
        ),
      ),
    );
  }

  bool _isBrighterMood(MoodLevel level) {
    return switch (level) {
      MoodLevel.happy ||
      MoodLevel.excited ||
      MoodLevel.grateful ||
      MoodLevel.relaxed ||
      MoodLevel.content => true,
      _ => false,
    };
  }

  bool _isLowerMood(MoodLevel level) {
    return switch (level) {
      MoodLevel.anxious ||
      MoodLevel.angry ||
      MoodLevel.stressed ||
      MoodLevel.sad ||
      MoodLevel.tired ||
      MoodLevel.bored ||
      MoodLevel.unsure => true,
      _ => false,
    };
  }

  DateTime _asDateKey(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  double _averageDurationHours(List<SleepEntry> entries) {
    if (entries.isEmpty) return 0;
    return entries
            .map((entry) => entry.durationHours)
            .reduce((a, b) => a + b) /
        entries.length;
  }

  double _averageRestfulness(List<SleepEntry> entries) {
    if (entries.isEmpty) return 0;
    return entries
            .map((entry) => entry.restfulness.toDouble())
            .reduce((a, b) => a + b) /
        entries.length;
  }

  double _average(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final TimeOfDay initialTime = isStart ? _sleepStart : _sleepEnd;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: isStart ? 'When did you go to bed?' : 'When did you wake up?',
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _sleepStart = picked;
        } else {
          _sleepEnd = picked;
        }
      });
    }
  }

  Future<void> _saveEntry() async {
    setState(() {
      _isSaving = true;
    });

    final DateTime start = _combineDateTime(_selectedDate, _sleepStart);
    DateTime end = _combineDateTime(_selectedDate, _sleepEnd);
    if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
      end = end.add(const Duration(days: 1));
    }

    final Duration duration = end.difference(start);
    final double durationHours = duration.inMinutes / 60;

    final SleepEntry entry = SleepEntry(
      date: _asDateKey(end),
      sleepStart: start,
      sleepEnd: end,
      durationHours: durationHours,
      restfulness: _restfulness.round(),
    );

    await DbService.instance.insertSleepEntry(entry);

    if (!mounted) return;
    setState(() {
      _entriesFuture = _loadEntries();
      _insightsFuture = _buildInsights();
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sleep entry saved. Rest well!')),
    );
  }

  Duration? _currentSessionDuration() {
    if (_sessionStartTime == null) return null;
    return DateTime.now().difference(_sessionStartTime!);
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatDate(DateTime dateTime) {
    final DateTime local = dateTime.toLocal();
    final String month = local.month.toString().padLeft(2, '0');
    final String day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  String _formatDuration(double hours) {
    final int wholeHours = hours.floor();
    final int minutes = ((hours - wholeHours) * 60).round();
    if (minutes == 0) return '${wholeHours}h';
    if (minutes == 60) return '${wholeHours + 1}h';
    return '${wholeHours}h ${minutes}m';
  }

  String _formatTime(DateTime time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _deleteEntry(int id) async {
    await DbService.instance.deleteSleepEntry(id);
    if (!mounted) return;
    setState(() {
      _entriesFuture = _loadEntries();
      _insightsFuture = _buildInsights();
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep tracking'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _entriesFuture = _loadEntries();
              _insightsFuture = _buildInsights();
            });
            await Future.wait([
              _entriesFuture,
              _insightsFuture,
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Log your sleep and notice how it shapes your mood.',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              _SleepInsightCard(insightsFuture: _insightsFuture),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Simple sleep session',
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start a session when you tuck in. Tap “I\'m awake” to log automatically.',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      if (_sessionStartTime == null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isStartingSession
                                ? null
                                : _startSleepSession,
                            icon: _isStartingSession
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child:
                                        CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.bedtime_outlined),
                            label: Text(
                              _isStartingSession
                                  ? 'Starting session...'
                                  : 'Start sleep session',
                            ),
                          ),
                        )
                      else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Session running'),
                                Text(
                                  'Started at ${_formatTime(_sessionStartTime!)}',
                                  style: textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            StreamBuilder<Duration?>(
                              stream: Stream<Duration?>.periodic(
                                const Duration(seconds: 1),
                                (_) => _currentSessionDuration(),
                              ),
                              initialData: _currentSessionDuration(),
                              builder: (context, snapshot) {
                                final Duration? elapsed = snapshot.data;
                                final String elapsedText = elapsed == null
                                    ? '--'
                                    : _formatDuration(
                                        elapsed.inMinutes / 60,
                                      );
                                return Text(
                                  'Elapsed: $elapsedText',
                                  style: textTheme.titleMedium,
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isEndingSession ? null : _endSleepSession,
                                icon: _isEndingSession
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.wb_sunny_outlined),
                                label: Text(
                                  _isEndingSession
                                      ? 'Saving...'
                                      : 'I\'m awake',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed:
                                  _isEndingSession ? null : _cancelSleepSession,
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We\'ll ask how rested you feel before saving your entry.',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manual sleep log',
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SleepField(
                              label: 'Date',
                              value: _formatDate(_selectedDate),
                              icon: Icons.calendar_today,
                              onTap: _pickDate,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SleepField(
                              label: 'Went to bed',
                              value: _sleepStart.format(context),
                              icon: Icons.bedtime,
                              onTap: () => _pickTime(isStart: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SleepField(
                              label: 'Woke up',
                              value: _sleepEnd.format(context),
                              icon: Icons.wb_sunny_outlined,
                              onTap: () => _pickTime(isStart: false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Restfulness', style: textTheme.titleMedium),
                                    Text(_restfulness.toStringAsFixed(0)),
                                  ],
                                ),
                                Slider(
                                  value: _restfulness,
                                  divisions: 4,
                                  min: 1,
                                  max: 5,
                                  label: _restfulness.toStringAsFixed(0),
                                  onChanged: (double value) {
                                    setState(() {
                                      _restfulness = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveEntry,
                          icon: _isSaving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.nights_stay),
                          label: Text(_isSaving ? 'Saving...' : 'Save sleep entry'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Recent sleep',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<SleepEntry>>(
                future: _entriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ));
                  }

                  if (snapshot.hasError) {
                    return Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'We could not load your sleep right now.',
                              style: textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pull to refresh when you are ready.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final List<SleepEntry> entries = snapshot.data ?? [];
                  if (entries.isEmpty) {
                    return Column(
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'No sleep entries yet. Log tonight and we\'ll track it gently.',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: entries
                        .map(
                          (entry) => Card(
                            elevation: 0,
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('${entry.restfulness}/5'),
                              ),
                              title: Text(
                                '${_formatDuration(entry.durationHours)} • Restfulness ${entry.restfulness}',
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${_formatDate(entry.date)}'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Bed ${_formatTime(entry.sleepStart)} → Wake ${_formatTime(entry.sleepEnd)}',
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                tooltip: 'Delete entry',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: entry.id == null
                                    ? null
                                    : () => _deleteEntry(entry.id!),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Remember: poor sleep is never your fault. Small steps—like a wind-down playlist or a darker room—can help.',
                style: textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SleepInsightCard extends StatelessWidget {
  const _SleepInsightCard({required this.insightsFuture});

  final Future<String> insightsFuture;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return FutureBuilder<String>(
      future: insightsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Loading insights...'),
                ],
              ),
            ),
          );
        }

        final String insights = snapshot.data ??
            'Keep logging your sleep and moods; we will look for patterns without judgement.';

        return Card(
          elevation: 0,
          color: scheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_graph, color: scheme.onPrimaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insights,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SleepField extends StatelessWidget {
  const _SleepField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceVariant,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
