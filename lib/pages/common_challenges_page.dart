import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class CommonChallengesPage extends StatelessWidget {
  const CommonChallengesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final challenges = [
      _ChallengeCardData(
        title: strings.t('challenges.study.title'),
        description: strings.t('challenges.study.desc'),
        actions: [
          _ChallengeAction(
            label: strings.t('challenges.study.plan'),
            icon: Icons.checklist,
            route: '/tasks',
          ),
          _ChallengeAction(
            label: strings.t('challenges.study.timetable'),
            icon: Icons.schedule,
            route: '/timetable',
          ),
          _ChallengeAction(
            label: strings.t('challenges.study.audio'),
            icon: Icons.spa,
            route: '/relax',
          ),
        ],
      ),
      _ChallengeCardData(
        title: strings.t('challenges.social.title'),
        description: strings.t('challenges.social.desc'),
        actions: [
          _ChallengeAction(
            label: strings.t('challenges.social.chat'),
            icon: Icons.chat_bubble,
            route: '/chat',
          ),
          _ChallengeAction(
            label: strings.t('challenges.social.contacts'),
            icon: Icons.emoji_people,
            route: '/support-plan',
          ),
          _ChallengeAction(
            label: strings.t('challenges.social.help'),
            icon: Icons.volunteer_activism,
            route: '/help-now',
          ),
        ],
      ),
      _ChallengeCardData(
        title: strings.t('challenges.exhausted.title'),
        description: strings.t('challenges.exhausted.desc'),
        actions: [
          _ChallengeAction(
            label: strings.t('challenges.exhausted.log'),
            icon: Icons.favorite,
            route: '/mood',
          ),
          _ChallengeAction(
            label: strings.t('challenges.exhausted.walk'),
            icon: Icons.directions_walk,
            route: '/movement',
          ),
          _ChallengeAction(
            label: strings.t('challenges.exhausted.audio'),
            icon: Icons.music_note,
            route: '/relax',
          ),
        ],
      ),
      _ChallengeCardData(
        title: strings.t('challenges.lonely.title'),
        description: strings.t('challenges.lonely.desc'),
        actions: [
          _ChallengeAction(
            label: strings.t('challenges.lonely.journal'),
            icon: Icons.menu_book,
            route: '/journal',
          ),
          _ChallengeAction(
            label: strings.t('challenges.lonely.contacts'),
            icon: Icons.call,
            route: '/support-plan',
          ),
          _ChallengeAction(
            label: strings.t('challenges.lonely.chat'),
            icon: Icons.chat,
            route: '/chat',
          ),
        ],
      ),
      _ChallengeCardData(
        title: strings.t('challenges.dark.title'),
        description: strings.t('challenges.dark.desc'),
        actions: [
          _ChallengeAction(
            label: strings.t('challenges.dark.help'),
            icon: Icons.healing,
            route: '/help-now',
          ),
          _ChallengeAction(
            label: strings.t('challenges.dark.pin'),
            icon: Icons.push_pin,
            route: '/support-plan',
          ),
          _ChallengeAction(
            label: strings.t('challenges.dark.audio'),
            icon: Icons.self_improvement,
            route: '/relax',
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('challenges.title'))),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: challenges.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.t('challenges.intro.title'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.t('challenges.intro.desc'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          final item = challenges[index - 1];
          return Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(item.description),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        item.actions
                            .map(
                              (action) => ActionChip(
                                avatar: Icon(action.icon),
                                label: Text(action.label),
                                onPressed:
                                    () => Navigator.pushNamed(
                                      context,
                                      action.route,
                                    ),
                              ),
                            )
                            .toList(),
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

class _ChallengeCardData {
  const _ChallengeCardData({
    required this.title,
    required this.description,
    required this.actions,
  });

  final String title;
  final String description;
  final List<_ChallengeAction> actions;
}

class _ChallengeAction {
  const _ChallengeAction({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}
