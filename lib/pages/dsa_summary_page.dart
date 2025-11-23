import 'package:flutter/material.dart';

class DsaSummaryPage extends StatelessWidget {
  const DsaSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final timeRanges = [7, 14, 30, 60];

    return Scaffold(
      appBar: AppBar(title: const Text('DSA Summary')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a range to build a wellbeing summary you can share with your mentor.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: timeRanges
                  .map(
                    (days) => FilterChip(
                      label: Text('$days days'),
                      selected: days == 30,
                      onSelected: (_) {},
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Summary preview', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text(
                      'You logged moods on 8 days. Most frequent feeling: okay. Top themes: academics, rest. ',
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.copy_all),
                      label: const Text('Copy summary'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
