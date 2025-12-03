import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/movement_entry.dart';
import '../services/db_service.dart';

class MovementPage extends StatefulWidget {
  const MovementPage({super.key});

  @override
  State<MovementPage> createState() => _MovementPageState();
}

class _MovementPageState extends State<MovementPage> {
  late Future<List<MovementEntry>> _entriesFuture;
  DateTime _selectedDate = DateTime.now();
  int _minutes = 20;
  final TextEditingController _minutesController = TextEditingController(
    text: '20',
  );
  MovementType _type = MovementType.walk;
  MovementIntensity _intensity = MovementIntensity.light;
  double _energyBefore = 3;
  double _energyAfter = 3.5;
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _loadEntries();
  }

  Future<List<MovementEntry>> _loadEntries() async {
    final DateTime sevenDaysAgo = DateTime.now().subtract(
      const Duration(days: 7),
    );
    return DbService.instance.getMovementEntries(from: sevenDaysAgo);
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now,
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveEntry(AppLocalizations strings) async {
    setState(() {
      _isSaving = true;
    });

    final MovementEntry entry = MovementEntry(
      date: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      ),
      minutes: _minutes,
      type: _type,
      intensity: _intensity,
      energyBefore: _energyBefore.round(),
      energyAfter: _energyAfter.round(),
      note:
          _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
    );

    await DbService.instance.insertMovementEntry(entry);

    if (!mounted) return;
    setState(() {
      _entriesFuture = _loadEntries();
      _isSaving = false;
      _noteController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          strings
              .t('movement.logged')
              .replaceFirst('{minutes}', '${entry.minutes}')
              .replaceFirst('{type}', _labelForType(entry.type, strings)),
        ),
      ),
    );
  }

  Future<void> _deleteEntry(int id) async {
    await DbService.instance.deleteMovementEntry(id);
    if (!mounted) return;
    setState(() {
      _entriesFuture = _loadEntries();
    });
  }

  Map<String, dynamic> _buildWeekSummary(List<MovementEntry> entries) {
    final DateTime now = DateTime.now();
    final DateTime sevenDaysAgo = now.subtract(const Duration(days: 6));
    final List<MovementEntry> recent =
        entries
            .where(
              (entry) => entry.date.isAfter(
                DateTime(
                  sevenDaysAgo.year,
                  sevenDaysAgo.month,
                  sevenDaysAgo.day,
                ).subtract(const Duration(days: 1)),
              ),
            )
            .toList();

    final Set<DateTime> activeDays =
        recent
            .map(
              (entry) =>
                  DateTime(entry.date.year, entry.date.month, entry.date.day),
            )
            .toSet();
    final int totalMinutes = recent.fold<int>(
      0,
      (previousValue, element) => previousValue + element.minutes,
    );
    final double averageMinutes =
        recent.isEmpty ? 0 : totalMinutes / recent.length;

    return {'activeDays': activeDays.length, 'averageMinutes': averageMinutes};
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('movement.title')),
      ),
      body: FutureBuilder<List<MovementEntry>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          final List<MovementEntry> entries = snapshot.data ?? [];
          final Map<String, dynamic> weekSummary = _buildWeekSummary(entries);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _entriesFuture = _loadEntries();
              });
              await _entriesFuture;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _QuickLogCard(
                  strings: strings,
                  selectedDate: _selectedDate,
                  minutes: _minutes,
                  minutesController: _minutesController,
                  type: _type,
                  intensity: _intensity,
                  energyBefore: _energyBefore,
                  energyAfter: _energyAfter,
                  noteController: _noteController,
                  isSaving: _isSaving,
                  onDateTap: _pickDate,
                  onMinutesChanged: (value) {
                    setState(() {
                      _minutes = value;
                    });
                  },
                  onTypeChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _type = value;
                    });
                  },
                  onIntensityChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _intensity = value;
                    });
                  },
                  onEnergyBeforeChanged: (value) {
                    setState(() {
                      _energyBefore = value;
                    });
                  },
                  onEnergyAfterChanged: (value) {
                    setState(() {
                      _energyAfter = value;
                    });
                  },
                  onSave: () => _saveEntry(strings),
                ),
                const SizedBox(height: 16),
                _MovementIdeasCard(strings: strings),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.t('movement.snapshot.title'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entries.isEmpty
                              ? strings.t('movement.snapshot.empty')
                              : strings
                                  .t('movement.snapshot.data')
                                  .replaceFirst(
                                    '{days}',
                                    '${weekSummary['activeDays']}',
                                  )
                                  .replaceFirst(
                                    '{minutes}',
                                    weekSummary['averageMinutes']
                                        .toStringAsFixed(1),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.t('movement.list.title'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Center(child: CircularProgressIndicator())
                        else if (entries.isEmpty)
                          Text(strings.t('movement.list.empty'))
                        else
                          ...entries.map(
                            (entry) => Dismissible(
                              key: ValueKey(
                                entry.id ?? entry.date.toIso8601String(),
                              ),
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                              direction: DismissDirection.startToEnd,
                              onDismissed: (_) {
                                if (entry.id != null) {
                                  _deleteEntry(entry.id!);
                                }
                              },
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.directions_walk,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                title: Text(
                                  '${entry.minutes} ${strings.t('movement.minutes')} • ${_labelForIntensity(entry.intensity, strings)}',
                                ),
                                subtitle: Text(
                                  '${_labelForType(entry.type, strings)} on ${_formatDate(entry.date)}\n${strings.t('movement.list.energy').replaceFirst('{before}', '${entry.energyBefore ?? '-'}').replaceFirst('{after}', '${entry.energyAfter ?? '-'}')}',
                                ),
                                isThreeLine: true,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

String _labelForType(MovementType type, AppLocalizations strings) {
  switch (type) {
    case MovementType.walk:
      return strings.t('movement.type.walk');
    case MovementType.stretch:
      return strings.t('movement.type.stretch');
    case MovementType.yoga:
      return strings.t('movement.type.yoga');
    case MovementType.sport:
      return strings.t('movement.type.sport');
    case MovementType.dance:
      return strings.t('movement.type.dance');
    case MovementType.other:
      return strings.t('movement.type.other');
  }
}

String _labelForIntensity(
  MovementIntensity intensity,
  AppLocalizations strings,
) {
  switch (intensity) {
    case MovementIntensity.light:
      return strings.t('movement.intensity.light');
    case MovementIntensity.moderate:
      return strings.t('movement.intensity.moderate');
    case MovementIntensity.vigorous:
      return strings.t('movement.intensity.vigorous');
  }
}

class _QuickLogCard extends StatelessWidget {
  const _QuickLogCard({
    required this.strings,
    required this.selectedDate,
    required this.minutes,
    required this.minutesController,
    required this.type,
    required this.intensity,
    required this.energyBefore,
    required this.energyAfter,
    required this.noteController,
    required this.isSaving,
    required this.onDateTap,
    required this.onMinutesChanged,
    required this.onTypeChanged,
    required this.onIntensityChanged,
    required this.onEnergyBeforeChanged,
    required this.onEnergyAfterChanged,
    required this.onSave,
  });

  final AppLocalizations strings;
  final DateTime selectedDate;
  final int minutes;
  final TextEditingController minutesController;
  final MovementType type;
  final MovementIntensity intensity;
  final double energyBefore;
  final double energyAfter;
  final TextEditingController noteController;
  final bool isSaving;
  final VoidCallback onDateTap;
  final ValueChanged<int> onMinutesChanged;
  final ValueChanged<MovementType?> onTypeChanged;
  final ValueChanged<MovementIntensity?> onIntensityChanged;
  final ValueChanged<double> onEnergyBeforeChanged;
  final ValueChanged<double> onEnergyAfterChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  strings.t('movement.today'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: onDateTap,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: minutesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: strings.t('movement.minutes'),
                helperText: strings.t('movement.minutes.helper'),
                helperMaxLines: 2,
              ),
              onChanged: (value) {
                final int parsed = int.tryParse(value) ?? minutes;
                onMinutesChanged(parsed.clamp(1, 300));
              },
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                final typeField = DropdownButtonFormField<MovementType>(
                  isExpanded: true,
                  value: type,
                  decoration: InputDecoration(
                    labelText: strings.t('movement.type'),
                  ),
                  items: MovementType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            _labelForType(type, strings),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: onTypeChanged,
                );

                final intensityField = DropdownButtonFormField<MovementIntensity>(
                  isExpanded: true,
                  value: intensity,
                  decoration: InputDecoration(
                    labelText: strings.t('movement.intensity'),
                  ),
                  items: MovementIntensity.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            _labelForIntensity(value, strings),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: onIntensityChanged,
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      typeField,
                      const SizedBox(height: 12),
                      intensityField,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: typeField),
                    const SizedBox(width: 12),
                    Expanded(child: intensityField),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              strings
                  .t('movement.energy.before')
                  .replaceFirst('{value}', energyBefore.toStringAsFixed(0)),
            ),
            Slider(
              value: energyBefore,
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: onEnergyBeforeChanged,
            ),
            Text(
              strings
                  .t('movement.energy.after')
                  .replaceFirst('{value}', energyAfter.toStringAsFixed(0)),
            ),
            Slider(
              value: energyAfter,
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: onEnergyAfterChanged,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: strings.t('movement.note.label'),
                hintText: strings.t('movement.note.hint'),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: isSaving ? null : onSave,
              icon:
                  isSaving
                      ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.save),
              label: Text(
                isSaving
                    ? strings.t('movement.saving')
                    : strings.t('movement.save'),
              ),
            ),
            const SizedBox(height: 8),
            Text(strings.t('movement.nopressure')),
          ],
        ),
      ),
    );
  }
}

class _MovementIdeasCard extends StatelessWidget {
  final List<_MovementIdea> _ideas = const [
    _MovementIdea(
      title: 'movement.idea.stroll.title',
      description: 'movement.idea.stroll.desc',
    ),
    _MovementIdea(
      title: 'movement.idea.desk.title',
      description: 'movement.idea.desk.desc',
    ),
    _MovementIdea(
      title: 'movement.idea.cozy.title',
      description: 'movement.idea.cozy.desc',
    ),
  ];

  const _MovementIdeasCard({required this.strings});

  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.t('movement.ideas.title'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._ideas.map(
              (idea) => ListTile(
                leading: const Icon(Icons.lightbulb_outline),
                title: Text(strings.t(idea.title)),
                subtitle: Text(strings.t(idea.description)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementIdea {
  final String title;
  final String description;

  const _MovementIdea({required this.title, required this.description});
}
