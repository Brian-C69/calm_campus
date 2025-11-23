import 'package:flutter/material.dart';

class CommonChallengesPage extends StatelessWidget {
  const CommonChallengesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final challenges = [
      _ChallengeCardData(
        title: 'When food & body feel heavy',
        description: 'You deserve gentleness with meals and rest. Small snacks and kind words help.',
      ),
      _ChallengeCardData(
        title: 'When people feel scary',
        description: 'Social anxiety is tough. Start with one safe person or a short text message.',
      ),
      _ChallengeCardData(
        title: 'When you are exhausted or numb',
        description: 'Slow down. Drink water, stretch, and pick one tiny task to finish.',
      ),
      _ChallengeCardData(
        title: 'When you feel lonely or homesick',
        description: 'Reach out to a friend, join a quiet study space, or step outside for fresh air.',
      ),
      _ChallengeCardData(
        title: 'When your thoughts get dark',
        description:
            'You are not alone. Text someone you trust and tap Help Now for crisis hotlines anytime.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Common Challenges')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: challenges.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = challenges[index];
          return Card(
            elevation: 0,
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
                    children: const [
                      Chip(label: Text('Try a calm track')),
                      Chip(label: Text('Message AI buddy')),
                      Chip(label: Text('Go to Help Now')),
                    ],
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
  const _ChallengeCardData({required this.title, required this.description});

  final String title;
  final String description;
}
