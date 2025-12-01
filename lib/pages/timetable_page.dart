import 'package:flutter/material.dart';

import '../models/class_entry.dart';
import '../services/db_service.dart';
import '../services/login_nudge_service.dart';
import '../services/user_profile_service.dart';
import '../services/notification_service.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  bool _remindersEnabled = false;
  bool _isLoading = true;
  bool _isLoggedIn = false;
  List<ClassEntry> _classes = [];
  List<String> _courseCodeSuggestions = [];

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
    _loadState();
  }

  Future<void> _startReminders() async {
    final bool alreadyLoggedIn = await UserProfileService.instance.isLoggedIn();
    if (!mounted) return;

    if (!alreadyLoggedIn) {
      final LoginNudgeAction action = await LoginNudgeService.instance.maybePrompt(
        context,
        LoginNudgeTrigger.timetableSetup,
      );

      if (!mounted) return;
      if (action == LoginNudgeAction.loginSelected) {
        await Navigator.pushNamed(context, '/auth');
        if (!mounted) return;
      }
    }

    final bool refreshedLogin = await UserProfileService.instance.isLoggedIn();
    if (!mounted) return;

    setState(() {
      _remindersEnabled = true;
      _isLoggedIn = refreshedLogin;
    });

    await NotificationService.instance.scheduleClassRemindersForWeek(_classes);
    await NotificationService.instance
        .scheduleNightlyCheckIn(const TimeOfDay(hour: 21, minute: 0));
    await NotificationService.instance.scheduleSleepPlanReminder(
      const TimeOfDay(hour: 23, minute: 30),
      plannedBedtimeLabel: '12:00am',
    );
  }

  Future<void> _loadState() async {
    final classes = await DbService.instance.getAllClasses();
    final bool loggedIn = await UserProfileService.instance.isLoggedIn();
    final suggestions = _courseCodeHints(classes);
    if (!mounted) return;
    setState(() {
      _classes = classes;
      _isLoading = false;
      _isLoggedIn = loggedIn;
      _courseCodeSuggestions = suggestions;
    });
  }

  Future<void> _loadClasses() async {
    final classes = await DbService.instance.getAllClasses();
    final suggestions = _courseCodeHints(classes);
    if (!mounted) return;
    setState(() {
      _classes = classes;
      _courseCodeSuggestions = suggestions;
    });
  }

  String _dayLabel(int day) =>
      _dayNames[((day - 1).clamp(0, _dayNames.length - 1)).toInt()];

  String _formatTimeOfDay(TimeOfDay time) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(time, alwaysUse24HourFormat: false);
  }

  TimeOfDay? _parseTimeString(String raw) {
    final RegExp pattern = RegExp(r'^(\d{1,2}):(\d{2})\s*(am|pm)?$', caseSensitive: false);
    final Match? match = pattern.firstMatch(raw.trim());
    if (match == null) return null;

    int hour = int.parse(match.group(1)!);
    final int minute = int.parse(match.group(2)!);
    final String? meridiem = match.group(3)?.toLowerCase();

    if (meridiem != null) {
      if (meridiem == 'pm' && hour < 12) hour += 12;
      if (meridiem == 'am' && hour == 12) hour = 0;
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  List<String> _courseCodeHints(List<ClassEntry> entries) {
    final Set<String> unique = {
      for (final entry in entries)
        if (entry.subject.trim().isNotEmpty) entry.subject.trim()
    };
    return unique.take(6).toList();
  }

  Future<void> _openClassForm({ClassEntry? existing}) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final bool isEditing = existing != null;
    const List<String> classTypes = ['Lecture (L)', 'Practical (P)', 'Tutorial (T)'];
    final TextEditingController courseCodeController =
        TextEditingController(text: existing?.subject ?? '');
    final TextEditingController venueController =
        TextEditingController(text: existing?.location ?? '');
    final TextEditingController lecturerController =
        TextEditingController(text: existing?.lecturer ?? '');

    int selectedDay = existing?.dayOfWeek ?? DateTime.monday;
    String classType = classTypes.contains(existing?.classType ?? '')
        ? existing!.classType
        : classTypes.first;
    TimeOfDay? startTime = existing != null ? _parseTimeString(existing.startTime) : null;
    TimeOfDay? endTime = existing != null ? _parseTimeString(existing.endTime) : null;
    bool timeError = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 8,
          ),
          child: StatefulBuilder(
            builder: (innerContext, setSheetState) {
              Future<void> selectTime(bool isStart) async {
                final TimeOfDay initialTime = isStart
                    ? (startTime ?? const TimeOfDay(hour: 8, minute: 0))
                    : (endTime ?? const TimeOfDay(hour: 10, minute: 0));
                final TimeOfDay? picked = await showTimePicker(
                  context: innerContext,
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
                          isEditing ? 'Edit class' : 'Add a class to your timetable',
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
                        if (_courseCodeSuggestions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Pick a recent code to save typing:',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: _courseCodeSuggestions
                                .map(
                                  (code) => ActionChip(
                                    label: Text(code),
                                    onPressed: () {
                                      setSheetState(() {
                                        courseCodeController.text = code;
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ],
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
                          items: classTypes
                              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                              .toList(),
                          onChanged: (value) =>
                              setSheetState(() => classType = value ?? classTypes.first),
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
                                id: existing?.id,
                                subject: courseCodeController.text.trim(),
                                dayOfWeek: selectedDay,
                                startTime: _formatTimeOfDay(startTime!),
                                endTime: _formatTimeOfDay(endTime!),
                                location: venueController.text.trim(),
                                classType: classType,
                                lecturer: lecturerController.text.trim(),
                              );

                              if (isEditing && newEntry.id != null) {
                                await DbService.instance.updateClassEntry(newEntry);
                              } else {
                                await DbService.instance.insertClass(newEntry);
                              }
                              if (!mounted) return;
                              Navigator.of(context).pop();
                              await _loadClasses();
                              if (_remindersEnabled) {
                                await NotificationService.instance
                                    .scheduleClassRemindersForWeek(_classes);
                              }
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      isEditing ? 'Class updated in your timetable.' : 'Class added to your timetable.'),
                                ),
                              );
                            },
                            child: Text(isEditing ? 'Save changes' : 'Save class'),
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
  }

  Future<void> _showClassActions(ClassEntry entry) async {
    final String? action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit class'),
              onTap: () => Navigator.of(context).pop('edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete class'),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );

    if (action == 'edit') {
      await _openClassForm(existing: entry);
    } else if (action == 'delete') {
      await _confirmDelete(entry);
    }
  }

  Future<void> _confirmDelete(ClassEntry entry) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this class?'),
        content: Text('Delete ${entry.subject} (${entry.classType}) from your timetable?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (entry.id != null) {
      await DbService.instance.deleteClassEntry(entry.id!);
    } else {
      _classes.remove(entry);
    }

    if (!mounted) return;
    await _loadClasses();
    if (_remindersEnabled) {
      await NotificationService.instance.scheduleClassRemindersForWeek(_classes);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Class removed.')),
    );
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
          ...entries.map(
            (entry) => Card(
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onLongPress: () => _showClassActions(entry),
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
              ),
            ),
          ),
        ];
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timetable')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openClassForm(),
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
                    _remindersEnabled
                        ? _isLoggedIn
                            ? 'Reminders on (saved to your account)'
                            : 'Reminders on (guest mode)'
                        : 'Set up timetable reminders',
                  ),
                ),
                ..._buildClassSections(),
              ],
            ),
    );
  }
}
