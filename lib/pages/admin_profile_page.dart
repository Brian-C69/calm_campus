import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../services/role_service.dart';
import '../services/theme_controller.dart';
import '../services/language_controller.dart';
import '../services/user_profile_service.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  bool _isConsultant = true;
  bool _isOnline = false;
  bool _loading = true;
  AppThemeMode _themeMode = AppThemeMode.system;
  AppLanguage _language = AppLanguage.englishUK;
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
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    try {
      final savedTheme = await UserProfileService.instance.getTheme();
      final savedLanguage = await UserProfileService.instance.getLanguage();
      final savedColor = await UserProfileService.instance.getThemeColor();
      final Map<String, dynamic>? row = await Supabase.instance.client
          .from('profiles')
          .select('display_name,is_consultant,is_online,tags')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _nameController.text = (row?['display_name'] as String?) ?? (user.userMetadata?['preferred_name'] as String?) ?? '';
        _isConsultant = row?['is_consultant'] as bool? ?? true;
        _isOnline = row?['is_online'] as bool? ?? false;
        final List<dynamic> tags = row?['tags'] as List<dynamic>? ?? [];
        _tagsController.text = tags.map((e) => '$e').join(', ');
        _themeMode = savedTheme;
        _language = savedLanguage;
        _themeSeedColor = savedColor;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final strings = AppLocalizations.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    final List<String> tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    try {
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'role': 'admin',
        'display_name': _nameController.text.trim(),
        'is_consultant': _isConsultant,
        'is_online': _isOnline,
        'tags': tags,
      });
      await RoleService.instance.refreshRoleFromSupabase();
      await UserProfileService.instance.saveDisplayName(_nameController.text.trim());
      await UserProfileService.instance.saveConsultantFlag(_isConsultant);
      await UserProfileService.instance.saveOnlineFlag(_isOnline);
      await ThemeController.instance.updateTheme(_themeMode);
      await ThemeController.instance.updateColorSeed(_themeSeedColor);
      await LanguageController.instance.updateLanguage(_language);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('admin.profile.saved'))),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${strings.t('admin.profile.error')}\n$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _onSelectColor(Color color) {
    setState(() => _themeSeedColor = color);
    ThemeController.instance.updateColorSeed(color);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('admin.profile.title')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Text(strings.t('admin.profile.subtitle'),
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: strings.t('admin.profile.name'),
                      helperText: strings.t('admin.profile.name.helper'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tagsController,
                    decoration: InputDecoration(
                      labelText: strings.t('admin.profile.tags'),
                      helperText: strings.t('admin.profile.tags.helper'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    value: _isConsultant,
                    onChanged: (v) => setState(() => _isConsultant = v),
                    title: Text(strings.t('admin.profile.consultant')),
                    subtitle: Text(strings.t('admin.profile.consultant.desc')),
                  ),
                  SwitchListTile.adaptive(
                    value: _isOnline,
                    onChanged: (v) => setState(() => _isOnline = v),
                    title: Text(strings.t('admin.profile.online')),
                    subtitle: Text(strings.t('admin.profile.online.desc')),
                  ),
                  const SizedBox(height: 16),
                  Text(strings.t('settings.appearance'), style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...AppThemeMode.values.map(
                    (mode) => RadioListTile<AppThemeMode>(
                      value: mode,
                      groupValue: _themeMode,
                      title: Text(_themeLabel(mode, strings)),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _themeMode = value);
                        ThemeController.instance.updateTheme(value);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(strings.t('settings.themeColor.title'), style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _colorOptions.map((option) {
                      final bool selected = _themeSeedColor == option.color;
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
                  Text(strings.t('settings.themeColor.helper'), style: theme.textTheme.bodySmall),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: Text(strings.t('common.save')),
                  ),
                ],
              ),
            ),
    );
  }
}

String _themeLabel(AppThemeMode mode, AppLocalizations strings) {
  switch (mode) {
    case AppThemeMode.system:
      return strings.t('settings.theme.system');
    case AppThemeMode.light:
      return strings.t('settings.theme.light');
    case AppThemeMode.dark:
      return strings.t('settings.theme.dark');
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

class _ThemeColorOption {
  const _ThemeColorOption({required this.color, required this.labelKey});

  final Color color;
  final String labelKey;
}
