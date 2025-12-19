import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/user_profile_service.dart';
import '../l10n/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<_ProfileData> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<_ProfileData> _loadProfile() async {
    final isLoggedIn = await UserProfileService.instance.isLoggedIn();
    if (!isLoggedIn) {
      return const _ProfileData(isLoggedIn: false);
    }

    final nickname = await UserProfileService.instance.getNickname();
    final course = await UserProfileService.instance.getCourse();
    final year = await UserProfileService.instance.getYearOfStudy();
    return _ProfileData(
      isLoggedIn: true,
      nickname: nickname,
      course: course,
      yearOfStudy: year,
    );
  }

  Future<void> _openSettings() async {
    await Navigator.pushNamed(context, '/settings');
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  Future<void> _openAbout() async {
    await Navigator.pushNamed(context, '/about');
  }

  Future<void> _openLogin() async {
    await Navigator.pushNamed(context, '/auth');
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  Future<void> _logout() async {
    final strings = AppLocalizations.of(context);
    await UserProfileService.instance.setLoggedIn(false);

    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.t('profile.logout.title')),
          content: Text(strings.t('profile.logout.body')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(strings.t('common.ok')),
            ),
          ],
        );
      },
    ).then((_) {
      if (!mounted) return;
      setState(() {
        _profileFuture = _loadProfile();
      });
    });
  }

  Future<void> _changePassword() async {
    final strings = AppLocalizations.of(context);
    final TextEditingController newPass = TextEditingController();
    final TextEditingController confirmPass = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.t('auth.password.change')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPass,
              obscureText: true,
              decoration: InputDecoration(labelText: strings.t('auth.password.new')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPass,
              obscureText: true,
              decoration: InputDecoration(labelText: strings.t('auth.password.confirm')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.t('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.t('common.save')),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed != true) return;
    if (newPass.text.isEmpty || newPass.text.length < 8 || newPass.text != confirmPass.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('auth.password.short'))),
      );
      return;
    }

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPass.text),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('auth.password.updated'))),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message.isNotEmpty ? e.message : strings.t('auth.error.generic'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('auth.error.generic'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('profile.title')),
      ),
      body: FutureBuilder<_ProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data!;
          final theme = Theme.of(context);

          if (!profile.isLoggedIn) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 56, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      strings.t('profile.guest.title'),
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.t('profile.guest.body'),
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _openLogin,
                      child: Text(strings.t('profile.login')),
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              profile.initials,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            profile.nickname ?? strings.t('profile.nickname.missing'),
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            profile.course ?? strings.t('profile.course.missing'),
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            profile.yearOfStudy != null
                                ? strings
                                    .t('profile.year.label')
                                    .replaceFirst('{year}', profile.yearOfStudy.toString())
                                : strings.t('profile.year.missing'),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.t('profile.overview'),
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            leading: const Icon(Icons.email_outlined),
                            title: Text(strings.t('profile.contact')),
                            subtitle: Text(strings.t('profile.contact.helper')),
                          ),
                          ListTile(
                            leading: const Icon(Icons.schedule_outlined),
                            title: Text(strings.t('profile.reminder')),
                            subtitle: Text(strings.t('profile.reminder.helper')),
                          ),
                          ListTile(
                            leading: const Icon(Icons.info_outline),
                            title: Text(strings.t('about.title')),
                            subtitle: Text(strings.t('about.subtitle')),
                            onTap: _openAbout,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _openSettings,
                    icon: const Icon(Icons.settings),
                    label: Text(strings.t('profile.openSettings')),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _changePassword,
                    icon: const Icon(Icons.lock_reset),
                    label: Text(strings.t('auth.password.change')),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: Text(strings.t('profile.logout')),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileData {
  const _ProfileData({required this.isLoggedIn, this.nickname, this.course, this.yearOfStudy});

  final bool isLoggedIn;
  final String? nickname;
  final String? course;
  final int? yearOfStudy;

  String get initials {
    if (nickname == null || nickname!.trim().isEmpty) {
      return '?';
    }
    final parts = nickname!.trim().split(' ');
    final buffer = StringBuffer();
    for (final part in parts.take(2)) {
      if (part.isNotEmpty) buffer.write(part[0].toUpperCase());
    }
    return buffer.isEmpty ? '?' : buffer.toString();
  }
}
