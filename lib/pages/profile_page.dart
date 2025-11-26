import 'package:flutter/material.dart';

import '../services/user_profile_service.dart';

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
    final nickname = await UserProfileService.instance.getNickname();
    final course = await UserProfileService.instance.getCourse();
    final year = await UserProfileService.instance.getYearOfStudy();
    return _ProfileData(nickname: nickname, course: course, yearOfStudy: year);
  }

  Future<void> _openSettings() async {
    await Navigator.pushNamed(context, '/settings');
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: FutureBuilder<_ProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data!;
          final theme = Theme.of(context);

          return Padding(
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
                          profile.nickname ?? 'Add your nickname in settings',
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          profile.course ?? 'Course not set',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profile.yearOfStudy != null
                              ? 'Year ${profile.yearOfStudy}'
                              : 'Year not set',
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
                          'Overview',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(Icons.email_outlined),
                          title: const Text('Contact preferences'),
                          subtitle: const Text('Add your course email later'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.schedule_outlined),
                          title: const Text('Daily reminder'),
                          subtitle: const Text('Manage reminder time in settings'),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _openSettings,
                  icon: const Icon(Icons.settings),
                  label: const Text('Open Settings'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileData {
  _ProfileData({this.nickname, this.course, this.yearOfStudy});

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
