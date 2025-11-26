import 'package:flutter/material.dart';

import '../models/class_entry.dart';
import '../services/db_service.dart';
import '../services/login_nudge_service.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  bool _remindersEnabled = false;
  bool _isLoading = true;
  List<ClassEntry> _classes = [];

  static const List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _startReminders() async {
    setState(() => _remindersEnabled = true);
    final LoginNudgeAction action = await LoginNudgeService.instance.maybePrompt(
      context,
      LoginNudgeTrigger.timetableSetup,
    );

    if (!mounted) return;
    if (action == LoginNudgeAction.loginSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login only becomes required for campus integrations or cloud sync.'),
        ),
      );
    }
  }

  Future<void> _loadClasses() async {
    final classes = await DbService.instance.getAllClasses();
    if (!mounted) return;
    setState(() {
      _classes = classes;
      _isLoading = false;
    });
  }

  String _dayLabel(int day) =>
      _dayNames[((day - 1).clamp(0, _dayNames.length - 1)).toInt()];

  String _formatTimeOfDay(TimeOfDay time) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(time, alwaysUse24HourFormat: false);
  }

  Future<void> _showAddClassSheet() async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController courseCodeController = TextEditingController();
    final TextEditingController venueController = TextEditingController();
    final TextEditingController lecturerController = TextEditingController();

    int selectedDay = DateTime.monday;
    String classType = 'Lecture (L)';
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    bool timeError = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 8,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              Future<void> selectTime(bool isStart) async {
                final TimeOfDay initialTime = isStart
                    ? (startTime ?? const TimeOfDay(hour: 8, minute: 0))
                    : (endTime ?? const TimeOfDay(hour: 10, minute: 0));
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: initialTime,
                );
                if (picked != null) {
                  setSheetState(() {
                    if (isStart) {
                      startTime = picked;
                    } else {
                      endTime = picked;
                    }
                    timeError = false;
                  });
                }
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add a class to your timetable',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: courseCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Course Code',
                            hintText: 'e.g. BMIT2073',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty ? 'Enter a course code' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: selectedDay,
                          decoration: const InputDecoration(labelText: 'Day of week'),
                          items: List.generate(
                            _dayNames.length,
                            (index) => DropdownMenuItem<int>(
                              value: index + 1,
                              child: Text(_dayNames[index]),
                            ),
                          ),
                          onChanged: (value) =>
                              setSheetState(() => selectedDay = value ?? DateTime.monday),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: classType,
                          decoration: const InputDecoration(labelText: 'Type'),
                          items: const [
                            DropdownMenuItem(value: 'Lecture (L)', child: Text('Lecture (L)')),
                            DropdownMenuItem(value: 'Practical (P)', child: Text('Practical (P)')),
                            DropdownMenuItem(value: 'Tutorial (T)', child: Text('Tutorial (T)')),
                          ],
                          onChanged: (value) => setSheetState(() => classType = value ?? 'Lecture (L)'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: venueController,
                          decoration: const InputDecoration(labelText: 'Venue'),
                          validator: (value) =>
                              value == null || value.trim().isEmpty ? 'Enter the venue' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: lecturerController,
                          decoration: const InputDecoration(labelText: 'Lecturer'),
                          validator: (value) =>
                              value == null || value.trim().isEmpty ? 'Enter the lecturer name' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => selectTime(true),
                                icon: const Icon(Icons.play_arrow),
                                label: Text(startTime == null
                                    ? 'Start time'
                                    : _formatTimeOfDay(startTime!)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => selectTime(false),
                                icon: const Icon(Icons.stop),
                                label:
                                    Text(endTime == null ? 'End time' : _formatTimeOfDay(endTime!)),
                              ),
                            ),
                          ],
                        ),
                        if (timeError)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Please pick both start and end times.',
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () async {
                              final bool validForm = formKey.currentState?.validate() ?? false;
                              if (!validForm || startTime == null || endTime == null) {
                                setSheetState(() => timeError = startTime == null || endTime == null);
                                return;
                              }

                              final ClassEntry newEntry = ClassEntry(
                                subject: courseCodeController.text.trim(),
                                dayOfWeek: selectedDay,
                                startTime: _formatTimeOfDay(startTime!),
                                endTime: _formatTimeOfDay(endTime!),
                                location: venueController.text.trim(),
                                classType: classType,
                                lecturer: lecturerController.text.trim(),
                              );

                              await DbService.instance.insertClass(newEntry);
                              if (!mounted) return;
                              Navigator.of(context).pop();
                              await _loadClasses();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Class added to your timetable.')),
                              );
                            },
                            child: const Text('Save class'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    //courseCodeController.dispose();
    //venueController.dispose();
    //lecturerController.dispose();
  }

  List<Widget> _buildClassSections() {
    if (_classes.isEmpty) {
      return [
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('No classes yet'),
                SizedBox(height: 8),
                Text(
                  'Add your first class with details like course code, type, venue, lecturer, and time range.',
                ),
              ],
            ),
          ),
        ),
      ];
    }

    final Map<int, List<ClassEntry>> grouped = {};
    for (final entry in _classes) {
      grouped.putIfAbsent(entry.dayOfWeek, () => []).add(entry);
    }

    final List<int> sortedDays = grouped.keys.toList()..sort();

    return [
      const SizedBox(height: 12),
      ...sortedDays.expand((day) {
        final entries = grouped[day]!;
        return [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              _dayLabel(day),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...entries.map((entry) => Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event_note),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.subject,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text(entry.classType),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 18),
                          const SizedBox(width: 6),
                          Text('${entry.startTime} - ${entry.endTime}'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 18),
                          const SizedBox(width: 6),
                          Text(entry.location),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 18),
                          const SizedBox(width: 6),
                          Text(entry.lecturer),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        ];
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timetable')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClassSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add class'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Plan your week and choose whether to keep reminders as a guest or with an account.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _remindersEnabled ? null : _startReminders,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(
                    _remindersEnabled ? 'Reminders on (guest mode)' : 'Set up timetable reminders',
                  ),
                ),
                ..._buildClassSections(),
              ],
            ),
    );
  }
}
