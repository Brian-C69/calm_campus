import 'package:flutter/material.dart';

import '../services/user_profile_service.dart';
import '../l10n/app_localizations.dart';
import '../services/role_service.dart';
import '../models/user_role.dart';
import '../services/db_service.dart';
import '../models/mood_entry.dart';
import '../models/class_entry.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<String?> _nicknameFuture;
  late Future<bool> _isLoggedInFuture;
  late Future<MoodEntry?> _todayMoodFuture;
  late Future<_NextClassInfo?> _nextClassFuture;

  @override
  void initState() {
    super.initState();
    _nicknameFuture = _loadNickname();
    _isLoggedInFuture = _loadLoginState();
    _todayMoodFuture = DbService.instance.getTodayMood();
    _nextClassFuture = _loadNextClass();
    _redirectIfAdmin();
  }

  void _refreshUserState() {
    setState(() {
      _nicknameFuture = _loadNickname();
      _isLoggedInFuture = _loadLoginState();
      _todayMoodFuture = DbService.instance.getTodayMood();
      _nextClassFuture = _loadNextClass();
    });
  }

  Future<void> _redirectIfAdmin() async {
    final role = await RoleService.instance.getCachedRole();
    if (!mounted) return;
    if (role == UserRole.admin) {
      Navigator.of(context).pushReplacementNamed('/admin');
    }
  }

  Future<void> _openProfile() async {
    await Navigator.pushNamed(context, '/profile');
    if (!mounted) return;
    _refreshUserState();
  }

  Future<void> _openAuth() async {
    await Navigator.pushNamed(context, '/auth');
    if (!mounted) return;
    _refreshUserState();
  }

  Future<String?> _loadNickname() async {
    final nickname = await UserProfileService.instance.getNickname();
    return nickname == null || nickname.trim().isEmpty ? null : nickname.trim();
  }

  Future<bool> _loadLoginState() {
    return UserProfileService.instance.isLoggedIn();
  }

  Future<_NextClassInfo?> _loadNextClass() async {
    final List<ClassEntry> classes = await DbService.instance.getAllClasses();
    if (classes.isEmpty) return null;
    final DateTime now = DateTime.now();

    _NextClassInfo? best;
    for (final ClassEntry entry in classes) {
      final DateTime? start = _nextOccurrence(entry, now);
      if (start == null) continue;
      if (start.isBefore(now)) continue;
      final Duration until = start.difference(now);
      if (best == null || start.isBefore(best.start)) {
        best = _NextClassInfo(entry: entry, start: start, until: until);
      }
    }
    return best;
  }

  DateTime? _nextOccurrence(ClassEntry entry, DateTime now) {
    final TimeOfDay? startTime = _parseTime(entry.startTime);
    if (startTime == null) return null;
    final int today = now.weekday;
    int deltaDays = (entry.dayOfWeek - today) % 7;
    DateTime date = DateTime(now.year, now.month, now.day).add(Duration(days: deltaDays));
    DateTime start = DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
    if (!start.isAfter(now)) {
      start = start.add(const Duration(days: 7));
    }
    return start;
  }

  TimeOfDay? _parseTime(String raw) {
    final RegExp pattern = RegExp(r'^(\\d{1,2}):(\\d{2})\\s*(am|pm)?$', caseSensitive: false);
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

  String _formatTimeOfDay(TimeOfDay time) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(time, alwaysUse24HourFormat: false);
  }

  String _friendlyMoodLabel(MoodEntry entry) {
    switch (entry.overallMood) {
      case MoodLevel.happy:
        return 'Happy';
      case MoodLevel.excited:
        return 'Excited';
      case MoodLevel.grateful:
        return 'Grateful';
      case MoodLevel.relaxed:
        return 'Relaxed';
      case MoodLevel.content:
        return 'Content';
      case MoodLevel.tired:
        return 'Tired';
      case MoodLevel.unsure:
        return 'Unsure';
      case MoodLevel.bored:
        return 'Bored';
      case MoodLevel.anxious:
        return 'Anxious';
      case MoodLevel.angry:
        return 'Angry';
      case MoodLevel.stressed:
        return 'Stressed';
      case MoodLevel.sad:
        return 'Sad';
    }
  }

  String _friendlyTheme(MoodThemeTag tag) {
    switch (tag) {
      case MoodThemeTag.stress:
        return 'Stress & overwhelm';
      case MoodThemeTag.foodBody:
        return 'Food & body feelings';
      case MoodThemeTag.social:
        return 'People & social';
      case MoodThemeTag.academics:
        return 'Study & classes';
      case MoodThemeTag.rest:
        return 'Sleep & tiredness';
      case MoodThemeTag.motivation:
        return 'Motivation & focus';
      case MoodThemeTag.other:
        return 'Something else';
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final routes = <_HomeRouteInfo>[
      _HomeRouteInfo(strings.t('home.card.mood'), Icons.favorite, '/mood'),
      _HomeRouteInfo(strings.t('home.card.news'), Icons.campaign, '/announcements'),
      _HomeRouteInfo(strings.t('home.card.journal'), Icons.menu_book, '/journal'),
      _HomeRouteInfo(strings.t('home.card.profile'), Icons.person, '/profile'),
      _HomeRouteInfo(strings.t('home.card.timetable'), Icons.schedule, '/timetable'),
      _HomeRouteInfo(strings.t('home.card.tasks'), Icons.checklist, '/tasks'),
      _HomeRouteInfo(strings.t('home.card.chat'), Icons.chat, '/chat'),
      _HomeRouteInfo(strings.t('home.card.relax'), Icons.spa, '/relax'),
      _HomeRouteInfo(strings.t('home.card.sleep'), Icons.nights_stay, '/sleep'),
      _HomeRouteInfo(strings.t('home.card.movement'), Icons.directions_walk, '/movement'),
      _HomeRouteInfo(strings.t('home.card.period'), Icons.calendar_today, '/period-tracker'),
      _HomeRouteInfo(strings.t('home.card.support'), Icons.emoji_people, '/support-plan'),
      _HomeRouteInfo(strings.t('home.card.consultation'), Icons.support_agent, '/consultation'),
      _HomeRouteInfo(strings.t('home.card.help'), Icons.volunteer_activism, '/help-now'),
      _HomeRouteInfo(strings.t('home.card.dsa'), Icons.analytics, '/dsa-summary'),
      _HomeRouteInfo(strings.t('home.card.challenges'), Icons.menu_book, '/challenges'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('app.title')),
        actions: [
          FutureBuilder<bool>(
            future: _isLoggedInFuture,
            builder: (context, snapshot) {
              final isLoggedIn = snapshot.data ?? false;

              if (isLoggedIn) {
                return IconButton(
                  onPressed: () {
                    _openProfile();
                  },
                  tooltip: 'View profile',
                  icon: const Icon(Icons.verified_user),
                );
              }

              return TextButton.icon(
                onPressed: () {
                  _openAuth();
                },
                icon: const Icon(Icons.login),
                label: Text(strings.t('auth.login')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<bool>(
              future: _isLoggedInFuture,
              builder: (context, loginSnapshot) {
                final isLoggedIn = loginSnapshot.data ?? false;

                return FutureBuilder<String?>(
                  future: _nicknameFuture,
                  builder: (context, snapshot) {
                    final nickname = snapshot.data;
                    final greeting =
                        isLoggedIn && nickname != null && nickname.isNotEmpty
                            ? strings.t('home.greeting.named').replaceFirst('{name}', nickname)
                            : strings.t('home.greeting');

                    return Text(
                      greeting,
                      style: Theme.of(context).textTheme.titleLarge,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              strings.t('home.subtitle'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FutureBuilder<MoodEntry?>(
                    future: _todayMoodFuture,
                    builder: (context, snapshot) {
                      final mood = snapshot.data;
                      return _SummaryCard(
                        title: strings.t('home.todayMoodTitle'),
                        content: mood == null
                            ? 'No check-in yet'
                            : '${_friendlyMoodLabel(mood)} • ${_friendlyTheme(mood.mainThemeTag)}',
                        icon: Icons.favorite,
                        onTap: () => Navigator.pushNamed(context, '/mood'),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<_NextClassInfo?>(
                    future: _nextClassFuture,
                    builder: (context, snapshot) {
                      final info = snapshot.data;
                      return _SummaryCard(
                        title: strings.t('home.nextClassTitle'),
                        content: info == null
                            ? 'No classes scheduled'
                            : _formatNextClass(info),
                        icon: Icons.schedule,
                        onTap: () => Navigator.pushNamed(context, '/timetable'),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: routes.length,
                itemBuilder: (context, index) {
                  final item = routes[index];
                  return _HomeCard(
                    title: item.title,
                    icon: item.icon,
                    onTap: () => Navigator.pushNamed(context, item.route),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.title, required this.icon, required this.onTap});

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeRouteInfo {
  const _HomeRouteInfo(this.title, this.icon, this.route);

  final String title;
  final IconData icon;
  final String route;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String content;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      content,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextClassInfo {
  const _NextClassInfo({required this.entry, required this.start, required this.until});

  final ClassEntry entry;
  final DateTime start;
  final Duration until;
}

extension on _HomePageState {
  String _formatNextClass(_NextClassInfo info) {
    final startTime = _parseTime(info.entry.startTime);
    final endTime = _parseTime(info.entry.endTime);
    final timeRange = startTime != null
        ? endTime != null
            ? '${_formatTimeOfDay(startTime)} - ${_formatTimeOfDay(endTime)}'
            : _formatTimeOfDay(startTime)
        : info.entry.startTime;
    final String inText = _friendlyDuration(info.until);
    final String lecturerPart =
        info.entry.lecturer.trim().isNotEmpty ? ' • ${info.entry.lecturer}' : '';
    final String locationPart =
        info.entry.location.trim().isNotEmpty ? ' @ ${info.entry.location}' : '';
    return '${info.entry.subject}$lecturerPart$locationPart • $timeRange ($inText)';
  }

  String _friendlyDuration(Duration duration) {
    if (duration.inHours >= 24) {
      final days = duration.inDays;
      return days == 1 ? 'in 1 day' : 'in $days days';
    }
    if (duration.inHours >= 1) {
      final hours = duration.inHours;
      final mins = duration.inMinutes.remainder(60);
      if (mins == 0) return 'in $hours h';
      return 'in ${hours}h ${mins}m';
    }
    final mins = duration.inMinutes.clamp(0, 59);
    return mins <= 1 ? 'in 1 min' : 'in $mins min';
  }
}
