import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/mood_entry.dart';
import '../models/sleep_entry.dart';
import '../services/db_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  static const String _sleepSessionKey = 'sleepSessionStart';

  late Future<List<SleepEntry>> _entriesFuture;
  Future<String>? _insightsFuture;

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
    _restoreSessionStart();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _insightsFuture ??= _buildInsights(AppLocalizations.of(context));
  }

  Future<List<SleepEntry>> _loadEntries() {
    return DbService.instance.getSleepEntries();
  }

  Future<String> _buildInsights(AppLocalizations strings) async {
    final List<SleepEntry> entries = await DbService.instance.getSleepEntries();
    if (entries.isEmpty) {
      return strings.t('sleep.insights.empty');
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
      strings
          .t('sleep.insights.pastWeek')
          .replaceFirst('{duration}', _formatDuration(averageDuration))
          .replaceFirst('{rest}', averageRestfulness.toStringAsFixed(1)),
    );

    if (brighterSleep.isNotEmpty && lowerSleep.isNotEmpty) {
      buffer.writeln(
        strings
            .t('sleep.insights.compare')
            .replaceFirst(
              '{brighter}',
              _formatDuration(_average(brighterSleep)),
            )
            .replaceFirst('{lower}', _formatDuration(_average(lowerSleep))),
      );
    } else {
      buffer.writeln(strings.t('sleep.insights.moreData'));
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

  Future<void> _startSleepSession(AppLocalizations strings) async {
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.t('sleep.session.started'))));
  }

  Future<void> _cancelSleepSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sleepSessionKey);
    if (!mounted) return;
    setState(() {
      _sessionStartTime = null;
    });
  }

  Future<int?> _promptRestfulnessRating(AppLocalizations strings) async {
    double sliderValue = 3;

    return showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(strings.t('sleep.rest.prompt')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(strings.t('sleep.rest.scale')),
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
                  Text(
                    strings
                        .t('sleep.rest.value')
                        .replaceFirst(
                          '{value}',
                          sliderValue.toStringAsFixed(0),
                        ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(strings.t('sleep.rest.keep')),
                ),
                ElevatedButton(
                  onPressed:
                      () => Navigator.pop<int>(context, sliderValue.round()),
                  child: Text(strings.t('sleep.rest.save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _endSleepSession(AppLocalizations strings) async {
    if (_sessionStartTime == null) return;

    setState(() {
      _isEndingSession = true;
    });

    final int? restfulness = await _promptRestfulnessRating(strings);
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
      _insightsFuture = _buildInsights(strings);
      _isEndingSession = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          strings
              .t('sleep.logged')
              .replaceFirst('{duration}', _formatDuration(durationHours))
              .replaceFirst('{rest}', '$restfulness'),
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
    return entries.map((entry) => entry.durationHours).reduce((a, b) => a + b) /
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
    final strings = AppLocalizations.of(context);
    final TimeOfDay initialTime = isStart ? _sleepStart : _sleepEnd;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText:
          isStart ? strings.t('sleep.log.start') : strings.t('sleep.log.end'),
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

  Future<void> _saveEntry(AppLocalizations strings) async {
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
      _insightsFuture = _buildInsights(strings);
      _isSaving = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.t('sleep.saved'))));
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
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client
            .from('sleep_entries')
            .delete()
            .eq('user_id', user.id)
            .eq('local_id', id);
      } catch (_) {
        // best-effort; will sync on next upload
      }
    }
    if (!mounted) return;
    setState(() {
      _entriesFuture = _loadEntries();
      _insightsFuture = _buildInsights(AppLocalizations.of(context));
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('sleep.title'))),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _entriesFuture = _loadEntries();
              _insightsFuture = _buildInsights(strings);
            });
            await Future.wait([
              _entriesFuture,
              _insightsFuture ?? Future.value(''),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(strings.t('sleep.intro'), style: textTheme.bodyLarge),
              const SizedBox(height: 12),
              _SleepInsightCard(
                insightsFuture: _insightsFuture ?? _buildInsights(strings),
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
                        strings.t('sleep.session.title'),
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.t('sleep.session.desc'),
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      if (_sessionStartTime == null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isStartingSession
                                    ? null
                                    : () => _startSleepSession(strings),
                            icon:
                                _isStartingSession
                                    ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.bedtime_outlined),
                            label: Text(
                              _isStartingSession
                                  ? strings.t('sleep.session.starting')
                                  : strings.t('sleep.session.start'),
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
                                Text(strings.t('sleep.session.running')),
                                Text(
                                  strings
                                      .t('sleep.session.startedAt')
                                      .replaceFirst(
                                        '{time}',
                                        _formatTime(_sessionStartTime!),
                                      ),
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
                                final String elapsedText =
                                    elapsed == null
                                        ? '--'
                                        : _formatDuration(
                                          elapsed.inMinutes / 60,
                                        );
                                return Text(
                                  strings
                                      .t('sleep.session.elapsed')
                                      .replaceFirst('{duration}', elapsedText),
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
                                    _isEndingSession
                                        ? null
                                        : () => _endSleepSession(strings),
                                icon:
                                    _isEndingSession
                                        ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Icon(Icons.wb_sunny_outlined),
                                label: Text(
                                  _isEndingSession
                                      ? strings.t('sleep.session.ending')
                                      : strings.t('sleep.session.end'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed:
                                  _isEndingSession ? null : _cancelSleepSession,
                              child: Text(strings.t('sleep.session.cancel')),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          strings.t('sleep.session.note'),
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
                        strings.t('sleep.log.manual'),
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final bool useTwoColumns =
                              constraints.maxWidth >= 520;
                          final double fieldWidth =
                              useTwoColumns
                                  ? (constraints.maxWidth - 12) / 2
                                  : constraints.maxWidth;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  SizedBox(
                                    width: fieldWidth,
                                    child: _SleepField(
                                      label: strings.t('sleep.log.date'),
                                      value: _formatDate(_selectedDate),
                                      icon: Icons.calendar_today,
                                      onTap: _pickDate,
                                    ),
                                  ),
                                  SizedBox(
                                    width: fieldWidth,
                                    child: _SleepField(
                                      label: strings.t('sleep.log.start'),
                                      value: _sleepStart.format(context),
                                      icon: Icons.bedtime,
                                      onTap: () => _pickTime(isStart: true),
                                    ),
                                  ),
                                  SizedBox(
                                    width: fieldWidth,
                                    child: _SleepField(
                                      label: strings.t('sleep.log.end'),
                                      value: _sleepEnd.format(context),
                                      icon: Icons.wb_sunny_outlined,
                                      onTap: () => _pickTime(isStart: false),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _RestfulnessSlider(
                                label: strings.t('sleep.log.restfulness'),
                                restfulness: _restfulness,
                                onChanged: (value) {
                                  setState(() {
                                    _restfulness = value;
                                  });
                                },
                                textTheme: textTheme,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isSaving
                                          ? null
                                          : () => _saveEntry(strings),
                                  icon:
                                      _isSaving
                                          ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Icon(Icons.nights_stay),
                                  label: Text(
                                    _isSaving
                                        ? strings.t('sleep.log.saving')
                                        : strings.t('sleep.log.save'),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.t('sleep.recent.title'),
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<SleepEntry>>(
                future: _entriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    );
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
                              strings.t('sleep.error.load'),
                              style: textTheme.titleMedium?.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onErrorContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              strings.t('sleep.error.refresh'),
                              style: textTheme.bodyMedium?.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onErrorContainer,
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
                          strings.t('sleep.empty'),
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    );
                  }

                  return Column(
                    children:
                        entries
                            .map(
                              (entry) => Card(
                                elevation: 0,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text('${entry.restfulness}/5'),
                                  ),
                                  title: Text(
                                    '${_formatDuration(entry.durationHours)} • ${strings.t('sleep.entry.rest').replaceFirst('{rest}', '${entry.restfulness}')}',
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(_formatDate(entry.date)),
                                      const SizedBox(height: 4),
                                      Text(
                                        strings
                                            .t('sleep.entry.bed')
                                            .replaceFirst(
                                              '{bed}',
                                              _formatTime(entry.sleepStart),
                                            )
                                            .replaceFirst(
                                              '{wake}',
                                              _formatTime(entry.sleepEnd),
                                            ),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    tooltip: strings.t('sleep.entry.delete'),
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed:
                                        entry.id == null
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
                strings.t('sleep.footer'),
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
    final strings = AppLocalizations.of(context);

    return FutureBuilder<String>(
      future: insightsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(strings.t('sleep.insights.loading')),
                ],
              ),
            ),
          );
        }

        final String insights =
            snapshot.data ?? strings.t('sleep.insights.default');

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

class _RestfulnessSlider extends StatelessWidget {
  const _RestfulnessSlider({
    required this.label,
    required this.restfulness,
    required this.onChanged,
    required this.textTheme,
  });

  final String label;
  final double restfulness;
  final ValueChanged<double> onChanged;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: textTheme.titleMedium),
            Text(restfulness.toStringAsFixed(0)),
          ],
        ),
        Slider(
          value: restfulness,
          divisions: 4,
          min: 1,
          max: 5,
          label: restfulness.toStringAsFixed(0),
          onChanged: onChanged,
        ),
      ],
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
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(label, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
