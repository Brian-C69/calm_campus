import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class DsaSummaryPage extends StatelessWidget {
  const DsaSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final timeRanges = [7, 14, 30, 60];
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('dsa.title'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.t('dsa.prompt'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children:
                  timeRanges
                      .map(
                        (days) => FilterChip(
                          label: Text(
                            strings
                                .t('dsa.range.days')
                                .replaceFirst('{days}', '$days'),
                          ),
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
                    Text(
                      strings.t('dsa.preview.title'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(strings.t('dsa.preview.body')),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.copy_all),
                      label: Text(strings.t('dsa.copy')),
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
