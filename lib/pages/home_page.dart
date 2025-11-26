import 'package:flutter/material.dart';

import '../services/user_profile_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<String?> _nicknameFuture;
  bool _showCheckInReminder = true;

  @override
  void initState() {
    super.initState();
    _nicknameFuture = _loadNickname();
  }

  Future<String?> _loadNickname() async {
    final nickname = await UserProfileService.instance.getNickname();
    return nickname == null || nickname.trim().isEmpty ? null : nickname.trim();
  }

  @override
  Widget build(BuildContext context) {
    final routes = <_HomeRouteInfo>[
      _HomeRouteInfo('Mood Check-in', Icons.favorite, '/mood'),
      _HomeRouteInfo('Mood History', Icons.timeline, '/history'),
      _HomeRouteInfo('Journal', Icons.menu_book, '/journal'),
      _HomeRouteInfo('My Profile', Icons.person, '/profile'),
      _HomeRouteInfo('Timetable', Icons.schedule, '/timetable'),
      _HomeRouteInfo('Tasks', Icons.checklist, '/tasks'),
      _HomeRouteInfo('AI Buddy', Icons.chat, '/chat'),
      _HomeRouteInfo('Relax & Meditate', Icons.spa, '/relax'),
      _HomeRouteInfo('Help Now', Icons.volunteer_activism, '/help-now'),
      _HomeRouteInfo('DSA Summary', Icons.analytics, '/dsa-summary'),
      _HomeRouteInfo('Common Challenges', Icons.menu_book, '/challenges'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CalmCampus'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/auth'),
            icon: const Icon(Icons.login),
            label: const Text('Log in'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showCheckInReminder)
              _CheckInReminder(
                onDismiss: () => setState(() => _showCheckInReminder = false),
              ),
            if (_showCheckInReminder) const SizedBox(height: 12),
            FutureBuilder<String?>(
              future: _nicknameFuture,
              builder: (context, snapshot) {
                final nickname = snapshot.data;
                final greeting = nickname != null
                    ? 'Welcome back, $nickname'
                    : 'Welcome back';

                return Text(
                  greeting,
                  style: Theme.of(context).textTheme.titleLarge,
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Choose a space to explore. We are here with calm, kind support.',
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

class _CheckInReminder extends StatelessWidget {
  const _CheckInReminder({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.notifications_active,
                color: Theme.of(context).colorScheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'It’s time for a quick mood check-in',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share how you feel today so we can support you better.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  onPressed: onDismiss,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/mood'),
                  child: const Text('Check in'),
                ),
              ],
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
