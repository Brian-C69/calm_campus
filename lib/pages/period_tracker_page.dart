import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../l10n/app_localizations.dart';
import '../models/period_cycle.dart';
import '../services/db_service.dart';

class PeriodTrackerPage extends StatefulWidget {
  const PeriodTrackerPage({super.key});

  @override
  State<PeriodTrackerPage> createState() => _PeriodTrackerPageState();
}

class _PeriodTrackerPageState extends State<PeriodTrackerPage> {
  late Future<List<PeriodCycle>> _cyclesFuture;

  DateTime? _startDate;
  DateTime? _endDate;
  int? _editingId;
  bool _isSaving = false;
  bool _isDeleting = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _cyclesFuture = _loadCycles();
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

  String _monthLabel(DateTime date, AppLocalizations strings) {
    final formatter = strings.localeName.startsWith('zh') ? 'MM' : 'MMM';
    return formatter == 'MM'
        ? date.month.toString().padLeft(2, '0')
        : _monthAbbr(date.month);
  }

  String _monthAbbr(int month) {
    const List<String> monthLabels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return monthLabels[month - 1];
  }

  ({Set<DateTime> allDays, Set<DateTime> ongoingDays}) _generatePeriodDaySets(
    List<PeriodCycle> cycles,
  ) {
    final Set<DateTime> allDays = {};
    final Set<DateTime> ongoingDays = {};
    final DateTime today = DateUtils.dateOnly(DateTime.now());

    for (final PeriodCycle cycle in cycles) {
      final DateTime start = DateUtils.dateOnly(cycle.cycleStartDate);
      final DateTime end = DateUtils.dateOnly(cycle.cycleEndDate);
      final bool isOngoing = !today.isBefore(start) && !today.isAfter(end);

      for (int i = 0; i <= end.difference(start).inDays; i++) {
        final DateTime day = start.add(Duration(days: i));
        allDays.add(day);
        if (isOngoing) {
          ongoingDays.add(day);
        }
      }
    }

    return (allDays: allDays, ongoingDays: ongoingDays);
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    Set<DateTime> periodDays,
    Set<DateTime> ongoingDays, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    final DateTime dateOnly = DateUtils.dateOnly(day);
    final ThemeData theme = Theme.of(context);
    final bool isPeriodDay = periodDays.contains(dateOnly);
    final bool isOngoingDay = ongoingDays.contains(dateOnly);

    Color? backgroundColor;
    Color? textColor;

    if (isSelected) {
      backgroundColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
    } else if (isPeriodDay) {
      backgroundColor =
          isOngoingDay
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.secondaryContainer;
      textColor =
          isOngoingDay
              ? theme.colorScheme.onErrorContainer
              : theme.colorScheme.onSecondaryContainer;
    } else if (isToday) {
      backgroundColor = theme.colorScheme.primaryContainer;
      textColor = theme.colorScheme.onPrimaryContainer;
    }

    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: textColor,
          fontWeight: isOngoingDay ? FontWeight.w700 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildLegendChip({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildCalendar(List<PeriodCycle> cycles, AppLocalizations strings) {
    if (cycles.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.t('period.calendar.title'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(strings.t('period.calendar.empty')),
            ],
          ),
        ),
      );
    }

    final ({Set<DateTime> allDays, Set<DateTime> ongoingDays}) periodSets =
        _generatePeriodDaySets(cycles);
    final DateTime today = DateUtils.dateOnly(DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  strings.t('period.calendar.title'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${_monthLabel(_focusedDay, strings)} ${_focusedDay.year}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 4),
            TableCalendar<void>(
              firstDay: DateTime(today.year - 1, 1, 1),
              lastDay: DateTime(today.year + 1, 12, 31),
              focusedDay: _focusedDay,
              availableCalendarFormats: {
                CalendarFormat.month: strings.t('period.calendar.title'),
              },
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                isTodayHighlighted: false,
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder:
                    (context, day, focusedDay) => _buildDayCell(
                      context,
                      day,
                      periodSets.allDays,
                      periodSets.ongoingDays,
                      isToday: isSameDay(day, today),
                    ),
                todayBuilder:
                    (context, day, focusedDay) => _buildDayCell(
                      context,
                      day,
                      periodSets.allDays,
                      periodSets.ongoingDays,
                      isToday: true,
                    ),
                selectedBuilder:
                    (context, day, focusedDay) => _buildDayCell(
                      context,
                      day,
                      periodSets.allDays,
                      periodSets.ongoingDays,
                      isSelected: true,
                      isToday: isSameDay(day, today),
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendChip(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  label: strings.t('period.legend.past'),
                ),
                _buildLegendChip(
                  color: Theme.of(context).colorScheme.errorContainer,
                  label: strings.t('period.legend.ongoing'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _validateDates(BuildContext context, AppLocalizations strings) {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('period.validate.missing'))),
      );
      return false;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('period.validate.order'))),
      );
      return false;
    }

    final int duration = _calculateDurationDays(_startDate!, _endDate!);
    if (duration < 1 || duration > 14) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('period.validate.range'))),
      );
      return false;
    }

    return true;
  }

  Future<void> _saveCycle(AppLocalizations strings) async {
    if (!_validateDates(context, strings)) return;

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
          content: Text(
            isEditing
                ? strings.t('period.save.updated')
                : strings.t('period.save.success'),
          ),
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
      SnackBar(
        content: Text(AppLocalizations.of(context).t('period.delete.success')),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildStats(List<PeriodCycle> cycles, AppLocalizations strings) {
    if (cycles.isEmpty) {
      return Text(strings.t('period.stats.empty'));
    }

    final List<PeriodCycle> recent = cycles.take(6).toList();
    final List<int> durations =
        recent.map((cycle) => cycle.periodDurationDays).toList();
    final List<int> cycleLengths = [];

    for (int i = 0; i < recent.length - 1; i++) {
      final DateTime currentStart = recent[i].cycleStartDate;
      final DateTime previousStart = recent[i + 1].cycleStartDate;
      final int diff =
          currentStart
              .difference(
                DateTime(
                  previousStart.year,
                  previousStart.month,
                  previousStart.day,
                ),
              )
              .inDays;
      cycleLengths.add(diff);
    }

    final double averageDuration =
        durations.reduce((a, b) => a + b) / durations.length;
    final double? averageCycleLength =
        cycleLengths.isNotEmpty
            ? cycleLengths.reduce((a, b) => a + b) / cycleLengths.length
            : null;

    final PeriodCycle latest = recent.first;
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(
      strings
          .t('period.stats.avgLength')
          .replaceFirst('{days}', averageDuration.toStringAsFixed(1)),
    );
    if (averageCycleLength != null) {
      buffer.writeln(
        strings
            .t('period.stats.avgCycle')
            .replaceFirst('{days}', averageCycleLength.toStringAsFixed(1)),
      );
    } else {
      buffer.writeln(strings.t('period.stats.addMore'));
    }
    buffer.writeln(
      strings
          .t('period.stats.last')
          .replaceFirst('{start}', _formatDate(latest.cycleStartDate))
          .replaceFirst('{end}', _formatDate(latest.cycleEndDate))
          .replaceFirst('{days}', '${latest.periodDurationDays}'),
    );

    final DateTime? predictedStart = _predictNextPeriodStart(cycles);
    if (predictedStart != null && averageCycleLength != null) {
      final DateTimeRange? ovulationWindow = _estimateOvulationWindow(
        predictedStart,
      );
      buffer.writeln(
        strings
            .t('period.stats.next')
            .replaceFirst(
              '{daysAway}',
              '${predictedStart.difference(DateTime.now()).inDays}',
            )
            .replaceFirst('{date}', _formatDate(predictedStart)),
      );
      if (ovulationWindow != null) {
        buffer.writeln(
          strings
              .t('period.stats.ovulation')
              .replaceFirst('{start}', _formatDate(ovulationWindow.start))
              .replaceFirst('{end}', _formatDate(ovulationWindow.end)),
        );
      }
    } else {
      buffer.writeln(strings.t('period.stats.wait'));
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
      final int diff =
          currentStart
              .difference(
                DateTime(
                  previousStart.year,
                  previousStart.month,
                  previousStart.day,
                ),
              )
              .inDays;
      cycleLengths.add(diff);
    }

    if (cycleLengths.isEmpty) return null;
    final double average =
        cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
    return sorted.first.cycleStartDate.add(Duration(days: average.round()));
  }

  DateTimeRange? _estimateOvulationWindow(DateTime predictedNextStart) {
    final DateTime windowStart = predictedNextStart.subtract(
      const Duration(days: 16),
    );
    final DateTime windowEnd = predictedNextStart.subtract(
      const Duration(days: 12),
    );
    return DateTimeRange(start: windowStart, end: windowEnd);
  }

  Widget _buildCycleList(List<PeriodCycle> cycles, AppLocalizations strings) {
    if (cycles.isEmpty) {
      return Text(strings.t('period.stats.empty'));
    }

    return Column(
      children:
          cycles
              .map(
                (cycle) => Card(
                  child: ListTile(
                    title: Text(
                      '${_formatDate(cycle.cycleStartDate)} → ${_formatDate(cycle.cycleEndDate)}',
                    ),
                    subtitle: Text(
                      '${strings.t('period.list.duration').replaceFirst('{days}', '${cycle.periodDurationDays}')}${cycle.calculatedCycleLength != null ? ' • ${strings.t('period.list.cycle').replaceFirst('{days}', '${cycle.calculatedCycleLength}')}' : ''}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: AppLocalizations.of(
                            context,
                          ).t('common.edit'),
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
                          tooltip: AppLocalizations.of(
                            context,
                          ).t('common.delete'),
                          onPressed:
                              _isDeleting
                                  ? null
                                  : () => _showDeleteConfirmation(
                                    context,
                                    cycle.id!,
                                  ),
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
    final strings = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.t('period.delete.title')),
          content: Text(strings.t('period.delete.desc')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings.t('common.cancel')),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteCycle(id);
              },
              child: Text(strings.t('common.delete')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.t('period.title'))),
      body: FutureBuilder<List<PeriodCycle>>(
        future: _cyclesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${strings.t('period.error.load')} ${snapshot.error}',
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
                _buildCalendar(cycles, strings),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editingId == null
                              ? strings.t('period.form.title.add')
                              : strings.t('period.form.title.edit'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(strings.t('period.form.started')),
                                  const SizedBox(height: 4),
                                  OutlinedButton(
                                    onPressed: () => _pickDate(isStart: true),
                                    child: Text(
                                      _startDate == null
                                          ? strings.t('period.form.pickStart')
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
                                  Text(strings.t('period.form.ended')),
                                  const SizedBox(height: 4),
                                  OutlinedButton(
                                    onPressed: () => _pickDate(isStart: false),
                                    child: Text(
                                      _endDate == null
                                          ? strings.t('period.form.pickEnd')
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
                              label: Text(strings.t('period.form.chip.start')),
                              onPressed: _setTodayStart,
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.flag),
                              label: Text(strings.t('period.form.chip.end')),
                              onPressed: _setTodayEnd,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed:
                              _isSaving ? null : () => _saveCycle(strings),
                          child: Text(
                            _isSaving
                                ? strings.t('period.form.saving')
                                : _editingId == null
                                ? strings.t('period.form.save')
                                : strings.t('period.form.update'),
                          ),
                        ),
                        if (_editingId != null)
                          TextButton(
                            onPressed:
                                _isSaving
                                    ? null
                                    : () {
                                      setState(() {
                                        _editingId = null;
                                        _startDate = null;
                                        _endDate = null;
                                      });
                                    },
                            child: Text(strings.t('period.form.cancel')),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.t('period.insights.title'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _buildStats(cycles, strings),
                        const SizedBox(height: 8),
                        Text(strings.t('period.insights.note')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  strings.t('period.list.title'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildCycleList(cycles, strings),
              ],
            ),
          );
        },
      ),
    );
  }
}
