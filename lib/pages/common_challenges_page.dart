import 'package:flutter/material.dart';

class CommonChallengesPage extends StatelessWidget {
  const CommonChallengesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final challenges = [
      _ChallengeCardData(
        title: 'When studies feel overwhelming',
        description:
            'Break the week into one next step. Short focused blocks and generous breaks are okay.',
        actions: const [
          _ChallengeAction(label: 'Plan today\'s tasks', icon: Icons.checklist, route: '/tasks'),
          _ChallengeAction(label: 'Peek at timetable', icon: Icons.schedule, route: '/timetable'),
          _ChallengeAction(label: 'Play a focus track', icon: Icons.spa, route: '/relax'),
        ],
      ),
      _ChallengeCardData(
        title: 'When people feel scary',
        description: 'Social anxiety is tough. Start with one safe person or a short text message.',
        actions: const [
          _ChallengeAction(label: 'Message AI Buddy', icon: Icons.chat_bubble, route: '/chat'),
          _ChallengeAction(label: 'Review safe contacts', icon: Icons.emoji_people, route: '/support-plan'),
          _ChallengeAction(label: 'See Help Now options', icon: Icons.volunteer_activism, route: '/help-now'),
        ],
      ),
      _ChallengeCardData(
        title: 'When you are exhausted or numb',
        description: 'Slow down. Drink water, stretch, and pick one tiny task to finish.',
        actions: const [
          _ChallengeAction(label: 'Log how you feel', icon: Icons.favorite, route: '/mood'),
          _ChallengeAction(label: 'Try a gentle walk idea', icon: Icons.directions_walk, route: '/movement'),
          _ChallengeAction(label: 'Play calming audio', icon: Icons.music_note, route: '/relax'),
        ],
      ),
      _ChallengeCardData(
        title: 'When you feel lonely or homesick',
        description: 'Reach out to a friend, join a quiet study space, or step outside for fresh air.',
        actions: const [
          _ChallengeAction(label: 'Write a journal note', icon: Icons.menu_book, route: '/journal'),
          _ChallengeAction(label: 'Open safe contacts', icon: Icons.call, route: '/support-plan'),
          _ChallengeAction(label: 'Chat with Buddy', icon: Icons.chat, route: '/chat'),
        ],
      ),
      _ChallengeCardData(
        title: 'When your thoughts get dark',
        description:
            'You are not alone. Text someone you trust and tap Help Now for crisis hotlines anytime.',
        actions: const [
          _ChallengeAction(label: 'Open Help Now', icon: Icons.healing, route: '/help-now'),
          _ChallengeAction(label: 'Pin safe people', icon: Icons.push_pin, route: '/support-plan'),
          _ChallengeAction(label: 'Play grounding audio', icon: Icons.self_improvement, route: '/relax'),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Common Challenges')),
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
                      'You are not facing these alone.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Each section links to tools already in CalmCampus so you can act quickly.',
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
                  Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(item.description),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: item.actions
                        .map(
                          (action) => ActionChip(
                            avatar: Icon(action.icon),
                            label: Text(action.label),
                            onPressed: () => Navigator.pushNamed(context, action.route),
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
