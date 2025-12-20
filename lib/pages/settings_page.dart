import 'package:flutter/material.dart';

import '../services/user_profile_service.dart';
import '../services/supabase_sync_service.dart';
import '../services/theme_controller.dart';
import '../services/language_controller.dart';
import '../l10n/app_localizations.dart';
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
  AppLanguage _language = AppLanguage.englishUK;
  TimeOfDay? _reminderTime;
  bool _chatShareAll = false;
  Color _themeSeedColor = Colors.teal;
  final List<_ThemeColorOption> _colorOptions = const [
    _ThemeColorOption(color: Colors.teal, labelKey: 'settings.themeColor.teal'),
    _ThemeColorOption(color: Colors.blue, labelKey: 'settings.themeColor.blue'),
    _ThemeColorOption(color: Colors.green, labelKey: 'settings.themeColor.green'),
    _ThemeColorOption(color: Colors.purple, labelKey: 'settings.themeColor.purple'),
    _ThemeColorOption(color: Colors.orange, labelKey: 'settings.themeColor.orange'),
    _ThemeColorOption(color: Colors.pink, labelKey: 'settings.themeColor.pink'),
  ];

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
    final language = await UserProfileService.instance.getLanguage();
    final reminder = await UserProfileService.instance.getDailyReminderTime();
    final shareAll = await UserProfileService.instance.getChatShareAll();
    final colorSeed = await UserProfileService.instance.getThemeColor();

    setState(() {
      _nicknameController.text = nickname ?? '';
      _courseController.text = course ?? '';
      _yearController.text = year?.toString() ?? '';
      _themeMode = theme;
      _language = language;
      _reminderTime = reminder;
      _chatShareAll = shareAll;
      _themeSeedColor = colorSeed;
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
    await ThemeController.instance.updateColorSeed(_themeSeedColor);
    await LanguageController.instance.updateLanguage(_language);
    await _saveReminder();
    await UserProfileService.instance.setChatShareAll(_chatShareAll);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).t('settings.saved'))), 
    );
  }

  Future<void> _backupToSupabase() async {
    final strings = AppLocalizations.of(context);
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.t('settings.backup.needLogin')),
        ),
      );
      return;
    }

    try {
      await SupabaseSyncService.instance.uploadAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.t('settings.backup.success')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${strings.t('settings.backup.error')}\nDetails: $e',
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
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('settings.title')),
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
                    Text(strings.t('settings.aiBuddy'), style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.t('settings.aiBuddy.shareAll')),
                      subtitle: Text(strings.t('settings.aiBuddy.shareAll.helper')),
                      value: _chatShareAll,
                      onChanged: (value) async {
                        setState(() => _chatShareAll = value);
                        await UserProfileService.instance.setChatShareAll(value);
                      },
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
                    Text(strings.t('settings.profile'), style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nicknameController,
                      decoration: InputDecoration(
                        labelText: strings.t('settings.nickname'),
                        helperText: strings.t('settings.nickname.helper'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _courseController,
                      decoration: InputDecoration(
                        labelText: strings.t('settings.course'),
                        helperText: strings.t('settings.course.helper'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: strings.t('settings.year'),
                        helperText: strings.t('settings.year.helper'),
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
                    Text(strings.t('settings.appearance'), style: theme.textTheme.titleMedium),
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
                    const SizedBox(height: 12),
                    Text(strings.t('settings.themeColor.title'), style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _colorOptions.map((option) {
                        final bool selected = _themeSeedColor.value == option.color.value;
                        return ChoiceChip(
                          label: Text(strings.t(option.labelKey)),
                          selected: selected,
                          avatar: CircleAvatar(
                            backgroundColor: option.color,
                            radius: 10,
                          ),
                          onSelected: (_) => _onSelectColor(option.color),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.t('settings.themeColor.helper'),
                      style: theme.textTheme.bodySmall,
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
                    Text(strings.t('settings.language'), style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...AppLanguage.values.map(
                      (lang) => RadioListTile<AppLanguage>(
                        value: lang,
                        groupValue: _language,
                        title: Text(_languageLabel(lang, strings)),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _language = value);
                          LanguageController.instance.updateLanguage(value);
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
                    Text(strings.t('settings.reminder'), style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _reminderTime != null
                                ? strings
                                    .t('settings.reminder.set')
                                    .replaceFirst('{time}', _reminderTime!.format(context))
                                : strings.t('settings.reminder.none'),
                          ),
                        ),
                        TextButton(
                          onPressed: _pickReminderTime,
                          child: Text(strings.t('settings.reminder.choose')),
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: strings.t('settings.reminder.clear'),
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
                    Text(strings.t('settings.cloud'), style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      strings.t('settings.cloud.desc'),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _backupToSupabase,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: Text(strings.t('settings.cloud.button')),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saveAll,
              icon: const Icon(Icons.check),
              label: Text(strings.t('settings.save')),
            ),
          ],
        ),
      ),
    );
  }

  String _themeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return AppLocalizations.of(context).t('settings.theme.system');
      case AppThemeMode.light:
        return AppLocalizations.of(context).t('settings.theme.light');
      case AppThemeMode.dark:
        return AppLocalizations.of(context).t('settings.theme.dark');
    }
  }

  String _languageLabel(AppLanguage language, AppLocalizations strings) {
    switch (language) {
      case AppLanguage.englishUK:
        return strings.t('settings.language.en');
      case AppLanguage.chineseCN:
        return strings.t('settings.language.zh');
      case AppLanguage.malayMY:
        return strings.t('settings.language.ms');
    }
  }

  void _onSelectColor(Color color) {
    setState(() => _themeSeedColor = color);
    ThemeController.instance.updateColorSeed(color);
  }
}

class _ThemeColorOption {
  const _ThemeColorOption({required this.color, required this.labelKey});

  final Color color;
  final String labelKey;
}
