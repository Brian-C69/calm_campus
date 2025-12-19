import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../services/role_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
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
