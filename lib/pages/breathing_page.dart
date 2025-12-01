import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/breathing_exercise.dart';
import 'breathing_session_page.dart';

class BreathingPage extends StatelessWidget {
  const BreathingPage({super.key});

  List<BreathingExercise> _exercises(AppLocalizations strings) {
    return [
      BreathingExercise(
        id: 'box-4-4-4',
        name: strings.t('breathing.exercise.box.name'),
        description: strings.t('breathing.exercise.box.desc'),
        inhaleSeconds: 4,
        holdSeconds: 4,
        exhaleSeconds: 4,
        cycles: 6,
      ),
      BreathingExercise(
        id: '478',
        name: strings.t('breathing.exercise.478.name'),
        description: strings.t('breathing.exercise.478.desc'),
        inhaleSeconds: 4,
        holdSeconds: 7,
        exhaleSeconds: 8,
        cycles: 4,
      ),
      BreathingExercise(
        id: 'gentle-46',
        name: strings.t('breathing.exercise.gentle46.name'),
        description: strings.t('breathing.exercise.gentle46.desc'),
        inhaleSeconds: 4,
        holdSeconds: 0,
        exhaleSeconds: 6,
        cycles: 6,
      ),
      BreathingExercise(
        id: 'quick-calm',
        name: strings.t('breathing.exercise.quick.name'),
        description: strings.t('breathing.exercise.quick.desc'),
        inhaleSeconds: 3,
        holdSeconds: 2,
        exhaleSeconds: 4,
        cycles: 5,
      ),
    ];
  }

  String _formatDuration(int seconds, AppLocalizations strings) {
    if (seconds < 60) {
      return strings
          .t('breathing.duration.seconds')
          .replaceFirst('{seconds}', '$seconds');
    }
    final minutes = (seconds / 60).ceil();
    return strings
        .t('breathing.duration.minutes')
        .replaceFirst('{minutes}', '$minutes');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final exercises = _exercises(strings);

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('breathing.title'))),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: exercises.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.t('breathing.intro'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
              ],
            );
          }

          final exercise = exercises[index - 1];
          final durationLabel = _formatDuration(
            exercise.totalDurationSeconds,
            strings,
          );

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
              subtitle: Text(
                '${exercise.description}\n${strings.t('breathing.approx').replaceFirst('{duration}', durationLabel)}',
              ),
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
