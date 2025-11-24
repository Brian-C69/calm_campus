import 'package:flutter/material.dart';

import '../services/login_nudge_service.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  bool _remindersEnabled = false;

  Future<void> _startReminders() async {
    setState(() => _remindersEnabled = true);
    final LoginNudgeAction action = await LoginNudgeService.instance.maybePrompt(
      context,
      LoginNudgeTrigger.timetableSetup,
    );

    if (!mounted) return;
    if (action == LoginNudgeAction.loginSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login only becomes required for campus integrations or cloud sync.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = [
      'Monday 9:00 - Algorithms @ Room 101',
      'Tuesday 11:00 - Psychology @ Room 204',
      'Thursday 14:00 - Design Lab @ Studio 2',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Timetable')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Plan your week and choose whether to keep reminders as a guest or with an account.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _remindersEnabled ? null : _startReminders,
            icon: const Icon(Icons.notifications_active_outlined),
            label: Text(_remindersEnabled ? 'Reminders on (guest mode)' : 'Set up timetable reminders'),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: classes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final classEntry = classes[index];
              return Card(
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(classEntry),
                  subtitle: Text(
                    _remindersEnabled
                        ? 'Reminders saved locally. Syncing later stays optional.'
                        : 'Tap to view. Reminders coming soon.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
