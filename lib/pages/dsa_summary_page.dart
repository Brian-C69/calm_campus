import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/dsa_summary_service.dart';

class DsaSummaryPage extends StatefulWidget {
  const DsaSummaryPage({super.key});

  @override
  State<DsaSummaryPage> createState() => _DsaSummaryPageState();
}

class _DsaSummaryPageState extends State<DsaSummaryPage> {
  final DsaSummaryService _summaryService = DsaSummaryService();
  final List<int> _timeRanges = [7, 14, 30, 60];

  int _selectedDays = 30;
  bool _isLoading = true;
  String? _summary;

  @override
  void initState() {
    super.initState();
    _loadSummary(_selectedDays);
  }

  Future<void> _loadSummary(int days) async {
    setState(() {
      _selectedDays = days;
      _isLoading = true;
    });

    final AppLocalizations strings = AppLocalizations.of(context);
    final entries = await _summaryService.getMoodEntriesForLastDays(days);
    final stats = _summaryService.calculateMoodStats(entries);
    final String summary =
        _summaryService.buildDsaSummaryText(stats, days, strings);

    if (!mounted) return;
    setState(() {
      _summary = summary;
      _isLoading = false;
    });
  }

  Future<void> _copySummary(AppLocalizations strings) async {
    if (_summary == null || _summary!.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _summary!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.t('dsa.copied'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('dsa.title'))),
      body: RefreshIndicator(
        onRefresh: () => _loadSummary(_selectedDays),
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Text(
              strings.t('dsa.prompt'),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeRanges
                  .map(
                    (days) => FilterChip(
                      label: Text(
                        strings
                            .t('dsa.range.days')
                            .replaceFirst('{days}', '$days'),
                      ),
                      selected: days == _selectedDays,
                      onSelected: (_) => _loadSummary(days),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            strings.t('dsa.preview.title'),
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (_isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _summary ?? strings.t('dsa.summary.empty'),
                        key: ValueKey(_summary),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed:
                          _summary == null || _summary!.isEmpty ? null : () => _copySummary(strings),
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
