import 'package:flutter/material.dart';

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
  final TextEditingController _minutesController =
      TextEditingController(text: '20');
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
    final DateTime sevenDaysAgo =
        DateTime.now().subtract(const Duration(days: 7));
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

  Future<void> _saveEntry() async {
    setState(() {
      _isSaving = true;
    });

    final MovementEntry entry = MovementEntry(
      date: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
      minutes: _minutes,
      type: _type,
      intensity: _intensity,
      energyBefore: _energyBefore.round(),
      energyAfter: _energyAfter.round(),
      note: _noteController.text.trim().isEmpty
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
          'Logged ${entry.minutes} mins of ${_labelForType(entry.type)}. Nice gentle effort!',
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

  String _labelForType(MovementType type) {
    return switch (type) {
      MovementType.walk => 'walking',
      MovementType.stretch => 'stretching',
      MovementType.yoga => 'yoga or mobility',
      MovementType.sport => 'sports',
      MovementType.dance => 'dancing',
      MovementType.other => 'movement',
    };
  }

  String _labelForIntensity(MovementIntensity intensity) {
    return switch (intensity) {
      MovementIntensity.light => 'Light',
      MovementIntensity.moderate => 'Moderate',
      MovementIntensity.vigorous => 'Vigorous',
    };
  }

  Map<String, dynamic> _buildWeekSummary(List<MovementEntry> entries) {
    final DateTime now = DateTime.now();
    final DateTime sevenDaysAgo = now.subtract(const Duration(days: 6));
    final List<MovementEntry> recent = entries
        .where((entry) => entry.date.isAfter(
              DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day)
                  .subtract(const Duration(days: 1)),
            ))
        .toList();

    final Set<DateTime> activeDays = recent
        .map((entry) => DateTime(entry.date.year, entry.date.month, entry.date.day))
        .toSet();
    final int totalMinutes = recent.fold<int>(
      0,
      (previousValue, element) => previousValue + element.minutes,
    );
    final double averageMinutes = recent.isEmpty
        ? 0
        : totalMinutes / recent.length;

    return {
      'activeDays': activeDays.length,
      'averageMinutes': averageMinutes,
    };
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movement & Energy'),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text('Gentle, no diets'),
          ),
        ],
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
                  onSave: _saveEntry,
                ),
                const SizedBox(height: 16),
                _MovementIdeasCard(),
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
                          'Recent week snapshot',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entries.isEmpty
                              ? 'Log a few walks or stretches to see your momentum. Even small moves count.'
                              : '${weekSummary['activeDays']} active day(s) · average ${weekSummary['averageMinutes'].toStringAsFixed(1)} mins per log',
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
                          'Recent movement',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Center(child: CircularProgressIndicator())
                        else if (entries.isEmpty)
                          const Text(
                              'No logs yet. A 5–10 minute stretch or walk is a great gentle start.'),
                        if (entries.isNotEmpty)
                          ...entries.map(
                            (entry) => Dismissible(
                              key: ValueKey(entry.id ?? entry.date.toIso8601String()),
                              background: Container(
                                color: Colors.red.withOpacity(0.1),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: const Icon(Icons.delete, color: Colors.red),
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
                                      Theme.of(context).colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.directions_walk,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                title: Text(
                                    '${entry.minutes} mins · ${_labelForIntensity(entry.intensity)}'),
                                subtitle: Text(
                                  '${_labelForType(entry.type)} on ${_formatDate(entry.date)}\nEnergy ${entry.energyBefore ?? '-'} → ${entry.energyAfter ?? '-'}',
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

class _QuickLogCard extends StatelessWidget {
  const _QuickLogCard({
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
                  "Today's movement",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: onDateTap,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: minutesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minutes',
                helperText: 'Short sessions count. Even 5–10 mins helps reset.',
              ),
              onChanged: (value) {
                final int parsed = int.tryParse(value) ?? minutes;
                onMinutesChanged(parsed.clamp(1, 300));
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<MovementType>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: MovementType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.name.replaceAll('_', ' ').toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: onTypeChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<MovementIntensity>(
                    value: intensity,
                    decoration: const InputDecoration(labelText: 'Intensity'),
                    items: MovementIntensity.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.name[0].toUpperCase() + value.name.substring(1)),
                          ),
                        )
                        .toList(),
                    onChanged: onIntensityChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Energy before: ${energyBefore.toStringAsFixed(0)}/5'),
            Slider(
              value: energyBefore,
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: onEnergyBeforeChanged,
            ),
            Text('Energy after: ${energyAfter.toStringAsFixed(0)}/5'),
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
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. Walked with a friend between lectures',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(isSaving ? 'Saving...' : 'Save movement'),
            ),
            const SizedBox(height: 8),
            const Text(
              'No pressure or diet talk here. Movement is about kindness to your body and easing study stress.',
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementIdeasCard extends StatelessWidget {
  final List<_MovementIdea> _ideas = const [
    _MovementIdea(
      title: 'Study break stroll',
      description: '5–10 mins outside or in the hallway to reset your brain.',
    ),
    _MovementIdea(
      title: 'Desk stretch',
      description: 'Neck rolls, shoulder circles, and wrist shakes between tasks.',
    ),
    _MovementIdea(
      title: 'Cozy yoga',
      description: 'Slow stretches or child’s pose before bed, comfy clothes encouraged.',
    ),
  ];

  const _MovementIdeasCard();

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
              'Movement ideas for study days',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._ideas.map(
              (idea) => ListTile(
                leading: const Icon(Icons.lightbulb_outline),
                title: Text(idea.title),
                subtitle: Text(idea.description),
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
