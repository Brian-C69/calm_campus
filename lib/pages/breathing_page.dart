import 'package:flutter/material.dart';

import '../models/breathing_exercise.dart';
import 'breathing_session_page.dart';

class BreathingPage extends StatelessWidget {
  const BreathingPage({super.key});

  final List<BreathingExercise> _exercises = const [
    BreathingExercise(
      id: 'box-4-4-4',
      name: 'Box Breathing (4-4-4-4)',
      description: 'Steady four-count inhale, hold, exhale, hold to reset stress.',
      inhaleSeconds: 4,
      holdSeconds: 4,
      exhaleSeconds: 4,
      cycles: 6,
    ),
    BreathingExercise(
      id: '478',
      name: '4-7-8 Calm',
      description: 'Gentle nervous system downshift before sleep or study.',
      inhaleSeconds: 4,
      holdSeconds: 7,
      exhaleSeconds: 8,
      cycles: 4,
    ),
    BreathingExercise(
      id: 'gentle-46',
      name: 'Gentle 4-6 Breathing',
      description: 'Beginner-friendly slow inhale and longer exhale to soften tension.',
      inhaleSeconds: 4,
      holdSeconds: 0,
      exhaleSeconds: 6,
      cycles: 6,
    ),
    BreathingExercise(
      id: 'quick-calm',
      name: 'Quick Calm (1 minute)',
      description: 'Fast reset when you need one minute to steady yourself.',
      inhaleSeconds: 3,
      holdSeconds: 2,
      exhaleSeconds: 4,
      cycles: 5,
    ),
  ];

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '~${seconds}s';
    }
    final minutes = (seconds / 60).ceil();
    return '~${minutes} min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Breathing Exercises')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _exercises.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Short guided breathing to help your body settle. Start an exercise to see clear prompts and a countdown.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
              ],
            );
          }

          final exercise = _exercises[index - 1];
          final durationLabel = _formatDuration(exercise.totalDurationSeconds);

          return Card(
            elevation: 0,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                child: Icon(
                  Icons.self_improvement_outlined,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              title: Text(exercise.name),
              subtitle: Text('${exercise.description}\nApprox duration: $durationLabel'),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BreathingSessionPage(exercise: exercise),
                    ),
                  );
                },
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BreathingSessionPage(exercise: exercise),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
