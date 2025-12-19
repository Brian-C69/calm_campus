import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../services/consultation_service.dart';
import '../services/role_service.dart';
import '../services/user_profile_service.dart';
import '../models/user_role.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isOnline = false;
  bool _isLoading = true;
  int _openSessions = 0;
  String? _name;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await UserProfileService.instance.getDisplayName();
    final online = await UserProfileService.instance.isOnline();
    final sessions = await ConsultationService.instance.fetchSessionsForCurrentUser();

    if (!mounted) return;
    setState(() {
      _name = name;
      _isOnline = online;
      _openSessions = sessions.where((s) => s.status == 'open').length;
      _isLoading = false;
    });
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() => _isOnline = value);
    await ConsultationService.instance.setAvailability(isOnline: value);
    await RoleService.instance.refreshRoleFromSupabase();
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    await UserProfileService.instance.setLoggedIn(false);
    await UserProfileService.instance.saveRole(UserRole.student);
    await UserProfileService.instance.saveOnlineFlag(false);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('admin.dashboard.title')),
        actions: [
          IconButton(
            tooltip: strings.t('profile.logout'),
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    elevation: 0,
                    color: color.surfaceContainerHigh,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _name == null || _name!.isEmpty
                                ? strings.t('admin.dashboard.greeting')
                                : strings.t('admin.dashboard.named').replaceFirst('{name}', _name!),
                            style: textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(strings.t('admin.dashboard.subtitle')),
                          const SizedBox(height: 12),
                          SwitchListTile.adaptive(
                            value: _isOnline,
                            onChanged: _toggleAvailability,
                            title: Text(strings.t('admin.dashboard.status')),
                            subtitle: Text(
                              _isOnline
                                  ? strings.t('admin.dashboard.status.online')
                                  : strings.t('admin.dashboard.status.offline'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    child: ListTile(
                      leading: const Icon(Icons.inbox_outlined),
                      title: Text(strings.t('admin.dashboard.sessions')),
                      subtitle: Text(
                        strings
                            .t('admin.dashboard.sessions.count')
                            .replaceFirst('{count}', '$_openSessions'),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, '/consultation/inbox'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    child: ListTile(
                      leading: const Icon(Icons.pie_chart_outline),
                      title: Text(strings.t('admin.dashboard.analytics')),
                      subtitle: Text(strings.t('admin.dashboard.analytics.desc')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, '/admin/mood-analytics'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(strings.t('admin.profile.title')),
                      subtitle: Text(strings.t('admin.profile.subtitle')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, '/admin/profile'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    child: ListTile(
                      leading: const Icon(Icons.campaign_outlined),
                      title: Text(strings.t('admin.dashboard.announcements')),
                      subtitle: Text(strings.t('admin.dashboard.announcements.desc')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, '/announcements'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    child: ListTile(
                      leading: const Icon(Icons.phone_in_talk_outlined),
                      title: Text(strings.t('admin.dashboard.consultas')),
                      subtitle: Text(strings.t('admin.dashboard.consultas.desc')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, '/consultation'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    color: color.surfaceContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        strings.t('admin.dashboard.copy'),
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
