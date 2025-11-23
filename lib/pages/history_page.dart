import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sampleHistory = List.generate(
      10,
      (index) => 'Day ${index + 1}: mood note placeholder',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Mood History')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sampleHistory.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final entry = sampleHistory[index];
          return Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: Text(entry),
              subtitle: const Text('Tap to see details when data is connected'),
            ),
          );
        },
      ),
    );
  }
}
