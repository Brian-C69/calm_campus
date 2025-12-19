import 'package:flutter/material.dart';

import '../services/user_profile_service.dart';
import '../l10n/app_localizations.dart';
import '../services/role_service.dart';
import '../models/user_role.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<String?> _nicknameFuture;
  late Future<bool> _isLoggedInFuture;

  @override
  void initState() {
    super.initState();
    _nicknameFuture = _loadNickname();
    _isLoggedInFuture = _loadLoginState();
    _redirectIfAdmin();
  }

  void _refreshUserState() {
    setState(() {
      _nicknameFuture = _loadNickname();
      _isLoggedInFuture = _loadLoginState();
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
