import 'package:flutter/material.dart';

import '../services/user_profile_service.dart';
import '../services/supabase_sync_service.dart';
import '../services/theme_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nicknameController = TextEditingController();
  final _courseController = TextEditingController();
  final _yearController = TextEditingController();

  AppThemeMode _themeMode = AppThemeMode.system;
  TimeOfDay? _reminderTime;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final nickname = await UserProfileService.instance.getNickname();
    final course = await UserProfileService.instance.getCourse();
    final year = await UserProfileService.instance.getYearOfStudy();
    final theme = await UserProfileService.instance.getTheme();
    final reminder = await UserProfileService.instance.getDailyReminderTime();

    setState(() {
      _nicknameController.text = nickname ?? '';
      _courseController.text = course ?? '';
      _yearController.text = year?.toString() ?? '';
      _themeMode = theme;
      _reminderTime = reminder;
    });
  }

  Future<void> _saveProfile() async {
    await UserProfileService.instance.saveNickname(_nicknameController.text);
    await UserProfileService.instance.saveCourse(_courseController.text);
    final parsedYear = int.tryParse(_yearController.text.trim());
    if (parsedYear != null) {
      await UserProfileService.instance.saveYearOfStudy(parsedYear);
    }
  }

  Future<void> _saveReminder() async {
    if (_reminderTime == null) {
      await UserProfileService.instance.clearDailyReminderTime();
      return;
    }
    await UserProfileService.instance.saveDailyReminderTime(_reminderTime!);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  Future<void> _saveAll() async {
    await _saveProfile();
    await ThemeController.instance.updateTheme(_themeMode);
    await _saveReminder();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')), 
    );
  }

  Future<void> _backupToSupabase() async {
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please sign in on the Auth page before backing up your data.',
          ),
        ),
      );
      return;
    }

    try {
      await SupabaseSyncService.instance.uploadAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your data has been backed up to the cloud.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'We could not back up your data right now. Please check your connection and try again.\nDetails: $e',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _courseController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Profile', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: 'Nickname',
                        helperText: 'What should we call you?',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _courseController,
                      decoration: const InputDecoration(
                        labelText: 'Course',
                        helperText: 'E.g. Computer Science',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Year of study',
                        helperText: '1, 2, 3...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Appearance', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...AppThemeMode.values.map(
                      (mode) => RadioListTile<AppThemeMode>(
                        value: mode,
                        groupValue: _themeMode,
                        title: Text(_themeLabel(mode)),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _themeMode = value);
                          ThemeController.instance.updateTheme(value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily reminder', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _reminderTime != null
                                ? 'Reminder set for ${_reminderTime!.format(context)}'
                                : 'No reminder scheduled',
                          ),
                        ),
                        TextButton(
                          onPressed: _pickReminderTime,
                          child: const Text('Choose time'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear reminder',
                          onPressed: () => setState(() => _reminderTime = null),
                        ),
                      ],
                    ),
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
                    Text('Cloud backup', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'If you sign in with your CalmCampus account, you can back up your mood, sleep, tasks, and other logs to Supabase so they are available if you switch devices.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _backupToSupabase,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Back up my data now'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saveAll,
              icon: const Icon(Icons.check),
              label: const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }

  String _themeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'Use system setting';
      case AppThemeMode.light:
        return 'Light mode';
      case AppThemeMode.dark:
        return 'Dark mode';
    }
  }
}
