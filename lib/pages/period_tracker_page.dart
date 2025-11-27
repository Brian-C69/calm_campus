import 'package:flutter/material.dart';

import '../models/period_cycle.dart';
import '../services/db_service.dart';

class PeriodTrackerPage extends StatefulWidget {
  const PeriodTrackerPage({super.key});

  @override
  State<PeriodTrackerPage> createState() => _PeriodTrackerPageState();
}

class _PeriodTrackerPageState extends State<PeriodTrackerPage> {
  late Future<List<PeriodCycle>> _cyclesFuture;

  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  DateTime? _startDate;
  DateTime? _endDate;
  int? _editingId;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _cyclesFuture = _loadCycles();
  }

  DateTimeRange _currentMonthRange(DateTime month) {
    final DateTime start = DateTime(month.year, month.month, 1);
    final DateTime end = DateTime(month.year, month.month,
        DateUtils.getDaysInMonth(month.year, month.month));
    return DateTimeRange(start: start, end: end);
  }

  Future<List<PeriodCycle>> _loadCycles() {
    return DbService.instance.getRecentCycles();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = (isStart ? _startDate : _endDate) ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = DateTime(picked.year, picked.month, picked.day);
        } else {
          _endDate = DateTime(picked.year, picked.month, picked.day);
        }
      });
    }
  }

  void _setTodayStart() {
    final DateTime today = DateTime.now();
    setState(() {
      _startDate = DateTime(today.year, today.month, today.day);
    });
  }

  void _setTodayEnd() {
    final DateTime today = DateTime.now();
    setState(() {
      _endDate = DateTime(today.year, today.month, today.day);
      _startDate ??= DateTime(today.year, today.month, today.day);
    });
  }

  int _calculateDurationDays(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }

  bool _validateDates(BuildContext context) {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick a start and end date for your period.'),
        ),
      );
      return false;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date cannot be before start date.'),
        ),
      );
      return false;
    }

    final int duration = _calculateDurationDays(_startDate!, _endDate!);
    if (duration < 1 || duration > 14) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a realistic duration between 1 and 14 days.'),
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _saveCycle() async {
    if (!_validateDates(context)) return;

    setState(() {
      _isSaving = true;
    });

    final bool isEditing = _editingId != null;

    final PeriodCycle cycle = PeriodCycle(
      id: _editingId,
      cycleStartDate: _startDate!,
      cycleEndDate: _endDate!,
      periodDurationDays: _calculateDurationDays(_startDate!, _endDate!),
    );

    try {
      if (isEditing) {
        await DbService.instance.updatePeriodCycle(cycle);
      } else {
        await DbService.instance.insertPeriodCycle(cycle);
      }

      if (!mounted) return;
      setState(() {
        _cyclesFuture = _loadCycles();
        _startDate = null;
        _endDate = null;
        _editingId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? 'Cycle updated.'
              : 'Cycle saved. Thanks for trusting us with this info.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteCycle(int id) async {
    setState(() {
      _isDeleting = true;
    });

    await DbService.instance.deletePeriodCycle(id);

    if (!mounted) return;
    setState(() {
      _cyclesFuture = _loadCycles();
      _isDeleting = false;
      if (_editingId == id) {
        _editingId = null;
        _startDate = null;
        _endDate = null;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cycle removed.'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Set<DateTime> _periodDaysForMonth(
      DateTime month, List<PeriodCycle> cycles) {
    final DateTimeRange monthRange = _currentMonthRange(month);
    final Set<DateTime> days = {};

    for (final cycle in cycles) {
      final DateTime start = cycle.cycleStartDate;
      final DateTime end = cycle.cycleEndDate;
      final DateTime effectiveStart = start.isBefore(monthRange.start)
          ? monthRange.start
          : DateTime(start.year, start.month, start.day);
      final DateTime effectiveEnd = end.isAfter(monthRange.end)
          ? monthRange.end
          : DateTime(end.year, end.month, end.day);

      DateTime cursor = effectiveStart;
      while (!cursor.isAfter(effectiveEnd)) {
        days.add(DateTime(cursor.year, cursor.month, cursor.day));
        cursor = cursor.add(const Duration(days: 1));
      }
    }

    return days;
  }

  Set<DateTime> _ovulationWindowDays(
      DateTime month, List<PeriodCycle> cycles,
      {DateTime? predictedStart}) {
    final DateTime? predictedStartDate =
        predictedStart ?? _predictNextPeriodStart(cycles);
    if (predictedStartDate == null) return {};

    final DateTimeRange? window = _estimateOvulationWindow(predictedStartDate);
    if (window == null) return {};

    final DateTimeRange monthRange = _currentMonthRange(month);
    final DateTime effectiveStart =
        window.start.isBefore(monthRange.start) ? monthRange.start : window.start;
    final DateTime effectiveEnd =
        window.end.isAfter(monthRange.end) ? monthRange.end : window.end;

    final Set<DateTime> days = {};
    DateTime cursor = DateTime(effectiveStart.year, effectiveStart.month,
        effectiveStart.day);
    final DateTime endDay =
        DateTime(effectiveEnd.year, effectiveEnd.month, effectiveEnd.day);

    while (!cursor.isAfter(endDay)) {
      days.add(DateTime(cursor.year, cursor.month, cursor.day));
      cursor = cursor.add(const Duration(days: 1));
    }

    return days;
  }

  Widget _buildCalendar(List<PeriodCycle> cycles) {
    final DateTime firstDayOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final int daysInMonth = DateUtils.getDaysInMonth(
      _visibleMonth.year,
      _visibleMonth.month,
    );
    final int leadingBlankDays = firstDayOfMonth.weekday - DateTime.monday;

    final Set<DateTime> periodDays = _periodDaysForMonth(_visibleMonth, cycles);
    final DateTime? predictedStart = _predictNextPeriodStart(cycles);
    final Set<DateTime> ovulationDays =
        _ovulationWindowDays(_visibleMonth, cycles, predictedStart: predictedStart);
    final DateTime? ovulationDay = predictedStart == null
        ? null
        : _estimateOvulationWindow(predictedStart)?.start
            .add(const Duration(days: 2));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_visibleMonth.year}-${_visibleMonth.month.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Previous month',
                      onPressed: () {
                        setState(() {
                          _visibleMonth = DateTime(
                            _visibleMonth.year,
                            _visibleMonth.month - 1,
                          );
                        });
                      },
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      tooltip: 'Next month',
                      onPressed: () {
                        setState(() {
                          _visibleMonth = DateTime(
                            _visibleMonth.year,
                            _visibleMonth.month + 1,
                          );
                        });
                      },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Expanded(child: Center(child: Text('Mon'))),
                Expanded(child: Center(child: Text('Tue'))),
                Expanded(child: Center(child: Text('Wed'))),
                Expanded(child: Center(child: Text('Thu'))),
                Expanded(child: Center(child: Text('Fri'))),
                Expanded(child: Center(child: Text('Sat'))),
                Expanded(child: Center(child: Text('Sun'))),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: daysInMonth + leadingBlankDays,
              itemBuilder: (context, index) {
                if (index < leadingBlankDays) {
                  return const SizedBox.shrink();
                }

                final int dayNumber = index - leadingBlankDays + 1;
                final DateTime date = DateTime(
                  _visibleMonth.year,
                  _visibleMonth.month,
                  dayNumber,
                );

                final bool isPeriodDay = periodDays.any((d) => _isSameDay(d, date));
                final bool isOvulationWindow =
                    ovulationDays.any((d) => _isSameDay(d, date));
                final bool isOvulation =
                    ovulationDay != null && _isSameDay(date, ovulationDay);

                Color? background;
                if (isPeriodDay) {
                  background = Colors.pink.shade100;
                } else if (isOvulationWindow) {
                  background = Colors.orange.shade50;
                }

                return Container(
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isOvulation
                          ? Colors.orange
                          : Theme.of(context).dividerColor,
                      width: isOvulation ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.center,
                          child: Text('$dayNumber'),
                        ),
                      ),
                      if (isPeriodDay)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Icon(
                            Icons.water_drop,
                            color: Colors.pink.shade300,
                            size: 14,
                          ),
                        ),
                      if (isOvulation)
                        Positioned(
                          left: 4,
                          top: 4,
                          child: Icon(
                            Icons.star,
                            color: Colors.orange.shade700,
                            size: 14,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.pink.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Logged period days'),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Estimated ovulation window'),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.star, size: 16, color: Colors.orange),
                    SizedBox(width: 6),
                    Text('Likely ovulation day'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(List<PeriodCycle> cycles) {
    if (cycles.isEmpty) {
      return const Text('Log a few periods to unlock gentle insights.');
    }

    final List<PeriodCycle> recent = cycles.take(6).toList();
    final List<int> durations =
        recent.map((cycle) => cycle.periodDurationDays).toList();
    final List<int> cycleLengths = [];

    for (int i = 0; i < recent.length - 1; i++) {
      final DateTime currentStart = recent[i].cycleStartDate;
      final DateTime previousStart = recent[i + 1].cycleStartDate;
      final int diff = currentStart
          .difference(DateTime(previousStart.year, previousStart.month, previousStart.day))
          .inDays;
      cycleLengths.add(diff);
    }

    final double averageDuration =
        durations.reduce((a, b) => a + b) / durations.length;
    final double? averageCycleLength =
        cycleLengths.isNotEmpty ? cycleLengths.reduce((a, b) => a + b) / cycleLengths.length : null;

    final PeriodCycle latest = recent.first;
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('Average period length: ${averageDuration.toStringAsFixed(1)} days');
    if (averageCycleLength != null) {
      buffer.writeln('Average cycle: ${averageCycleLength.toStringAsFixed(1)} days');
    } else {
      buffer.writeln('Add another cycle to calculate your average cycle length.');
    }
    buffer.writeln(
        'Last period: ${_formatDate(latest.cycleStartDate)} – ${_formatDate(latest.cycleEndDate)} (${latest.periodDurationDays} days)');

    final DateTime? predictedStart = _predictNextPeriodStart(cycles);
    if (predictedStart != null && averageCycleLength != null) {
      final DateTimeRange? ovulationWindow = _estimateOvulationWindow(predictedStart);
      buffer.writeln(
          'Next period is roughly ${predictedStart.difference(DateTime.now()).inDays} days away (around ${_formatDate(predictedStart)}).');
      if (ovulationWindow != null) {
        buffer.writeln(
            'Estimated ovulation window: ${_formatDate(ovulationWindow.start)} – ${_formatDate(ovulationWindow.end)}.');
      }
    } else {
      buffer.writeln('We will offer predictions once we have a couple of cycles.');
    }

    return Text(buffer.toString());
  }

  DateTime? _predictNextPeriodStart(List<PeriodCycle> cycles) {
    if (cycles.length < 2) return null;

    final List<PeriodCycle> sorted = List.of(cycles)
      ..sort((a, b) => b.cycleStartDate.compareTo(a.cycleStartDate));

    final List<int> cycleLengths = [];
    for (int i = 0; i < sorted.length - 1; i++) {
      final DateTime currentStart = sorted[i].cycleStartDate;
      final DateTime previousStart = sorted[i + 1].cycleStartDate;
      final int diff = currentStart
          .difference(DateTime(previousStart.year, previousStart.month, previousStart.day))
          .inDays;
      cycleLengths.add(diff);
    }

    if (cycleLengths.isEmpty) return null;
    final double average = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
    return sorted.first.cycleStartDate.add(Duration(days: average.round()));
  }

  DateTimeRange? _estimateOvulationWindow(DateTime predictedNextStart) {
    final DateTime windowStart = predictedNextStart.subtract(const Duration(days: 16));
    final DateTime windowEnd = predictedNextStart.subtract(const Duration(days: 12));
    return DateTimeRange(start: windowStart, end: windowEnd);
  }

  Widget _buildCycleList(List<PeriodCycle> cycles) {
    if (cycles.isEmpty) {
      return const Text(
        'Your cycle entries stay on this device. Add your first period to start spotting gentle patterns.',
      );
    }

    return Column(
      children: cycles
          .map(
            (cycle) => Card(
              child: ListTile(
                title: Text(
                  '${_formatDate(cycle.cycleStartDate)} → ${_formatDate(cycle.cycleEndDate)}',
                ),
                subtitle: Text(
                  'Duration: ${cycle.periodDurationDays} days${cycle.calculatedCycleLength != null ? ' • Cycle: ${cycle.calculatedCycleLength} days' : ''}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () {
                        setState(() {
                          _editingId = cycle.id;
                          _startDate = cycle.cycleStartDate;
                          _endDate = cycle.cycleEndDate;
                        });
                      },
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: _isDeleting
                          ? null
                          : () => _showDeleteConfirmation(context, cycle.id!),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int id) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove this cycle?'),
          content: const Text(
            'Your entries are private to your device. Deleting this record cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteCycle(id);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Period & Cycle Tracker'),
      ),
      body: FutureBuilder<List<PeriodCycle>>(
        future: _cyclesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'We could not load your cycles right now. ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final List<PeriodCycle> cycles = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCalendar(cycles),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editingId == null
                              ? 'Log your latest period'
                              : 'Update your period entry',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Period started'),
                                  const SizedBox(height: 4),
                                  OutlinedButton(
                                    onPressed: () => _pickDate(isStart: true),
                                    child: Text(
                                      _startDate == null
                                          ? 'Pick start date'
                                          : _formatDate(_startDate!),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Period ended'),
                                  const SizedBox(height: 4),
                                  OutlinedButton(
                                    onPressed: () => _pickDate(isStart: false),
                                    child: Text(
                                      _endDate == null
                                          ? 'Pick end date'
                                          : _formatDate(_endDate!),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.today),
                              label: const Text('Period started today'),
                              onPressed: _setTodayStart,
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.flag),
                              label: const Text('Period ended today'),
                              onPressed: _setTodayEnd,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _isSaving ? null : _saveCycle,
                          child: Text(_isSaving
                              ? 'Saving...'
                              : _editingId == null
                                  ? 'Save cycle'
                                  : 'Update cycle'),
                        ),
                        if (_editingId != null)
                          TextButton(
                            onPressed: _isSaving
                                ? null
                                : () {
                                    setState(() {
                                      _editingId = null;
                                      _startDate = null;
                                      _endDate = null;
                                    });
                                  },
                            child: const Text('Cancel edit'),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cycle insights',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _buildStats(cycles),
                        const SizedBox(height: 8),
                        const Text(
                          'Cycles are unique and can shift. These estimates are for your own awareness only — not for contraception or medical decisions.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Recent cycles',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildCycleList(cycles),
              ],
            ),
          );
        },
      ),
    );
  }
}
