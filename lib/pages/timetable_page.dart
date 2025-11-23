import 'package:flutter/material.dart';

class TimetablePage extends StatelessWidget {
  const TimetablePage({super.key});

  @override
  Widget build(BuildContext context) {
    final classes = [
      'Monday 9:00 - Algorithms @ Room 101',
      'Tuesday 11:00 - Psychology @ Room 204',
      'Thursday 14:00 - Design Lab @ Studio 2',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Timetable')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: classes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final classEntry = classes[index];
          return Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(classEntry),
              subtitle: const Text('More details coming soon'),
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
  }
}
