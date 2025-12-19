import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../l10n/app_localizations.dart';
import '../models/mood_entry.dart';
import '../services/admin_analytics_service.dart';
import '../utils/mood_labels.dart';

class AdminMoodAnalyticsPage extends StatefulWidget {
  const AdminMoodAnalyticsPage({super.key});

  @override
  State<AdminMoodAnalyticsPage> createState() => _AdminMoodAnalyticsPageState();
}

class _AdminMoodAnalyticsPageState extends State<AdminMoodAnalyticsPage> {
  final AdminAnalyticsService _service = AdminAnalyticsService();
  final List<int> _ranges = [3, 7, 30];

  int _selectedDays = 7;
  bool _loading = true;
  AdminMoodSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final summary = await _service.fetchMoodSummary(days: _selectedDays);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _summary = null;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('admin.analytics.error'))),
      );
    }
  }

  Future<void> _exportCsv() async {
    final strings = AppLocalizations.of(context);
    final summary = _summary;
    if (summary == null || summary.totalEntries == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('admin.analytics.export.empty'))),
      );
      return;
    }
    try {
      final buffer = StringBuffer();
      buffer.writeln('mood,count');
      summary.counts.forEach((mood, count) {
        buffer.writeln('${mood.name},$count');
      });
      final dir = await getApplicationDocumentsDirectory();
      final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/mood_analytics_${_selectedDays}d_$ts.csv');
      await file.writeAsString(buffer.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('admin.analytics.export.saved').replaceFirst('{path}', file.path))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${strings.t('admin.analytics.export.error')}\n$e')),
      );
    }
  }

  Future<void> _exportPdf() async {
    final strings = AppLocalizations.of(context);
    final summary = _summary;
    if (summary == null || summary.totalEntries == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('admin.analytics.export.empty'))),
      );
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/mood_analytics_${_selectedDays}d_$ts.txt');
      final buffer = StringBuffer();
      buffer.writeln('Mood analytics $_selectedDays days');
      buffer.writeln('Generated: ${DateFormat.yMMMd().add_jm().format(DateTime.now())}');
      buffer.writeln('Entries: ${summary.totalEntries}, Students: ${summary.distinctUsers}');
      buffer.writeln('---');
      summary.counts.forEach((mood, count) {
        buffer.writeln('${mood.name}: $count');
      });
      await file.writeAsString(buffer.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('admin.analytics.export.saved').replaceFirst('{path}', file.path))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${strings.t('admin.analytics.export.error')}\n$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final summary = _summary;
    final total = summary?.totalEntries ?? 0;
    final distinct = summary?.distinctUsers ?? 0;
    final counts = summary?.counts ?? {};
    final hasData = total > 0 && counts.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('admin.analytics.title')),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(strings.t('admin.analytics.subtitle'), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _ranges
                  .map(
                    (days) => FilterChip(
                      label: Text(strings.t('dsa.range.days').replaceFirst('{days}', '$days')),
                      selected: days == _selectedDays,
                      onSelected: (v) {
                        if (!v) return;
                        setState(() {
                          _selectedDays = days;
                        });
                        _load();
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
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
                          child: Text(strings.t('admin.analytics.moodOverview'),
                              style: theme.textTheme.titleMedium),
                        ),
                        if (_loading)
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        if (!_loading)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: strings.t('admin.analytics.export.csv'),
                                onPressed: _exportCsv,
                                icon: const Icon(Icons.download_outlined),
                              ),
                              IconButton(
                                tooltip: strings.t('admin.analytics.export.pdf'),
                                onPressed: _exportPdf,
                                icon: const Icon(Icons.picture_as_pdf_outlined),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings
                          .t('admin.analytics.stats')
                          .replaceFirst('{entries}', '$total')
                          .replaceFirst('{users}', '$distinct'),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    if (!hasData && !_loading)
                      Text(strings.t('admin.analytics.empty'))
                    else if (hasData)
                      SizedBox(
                        height: 260,
                        child: PieChart(
                          PieChartData(
                            sections: _buildSections(counts, strings, theme),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (hasData)
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: counts.entries
                            .map(
                              (e) => _LegendChip(
                                color: _moodColor(e.key, theme),
                                label:
                                    '${moodLabel(e.key, strings)} (${e.value})',
                              ),
                            )
                            .toList(),
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

  List<PieChartSectionData> _buildSections(
    Map<MoodLevel, int> counts,
    AppLocalizations strings,
    ThemeData theme,
  ) {
    final total = counts.values.fold<int>(0, (sum, v) => sum + v);
    final List<PieChartSectionData> sections = [];
    counts.forEach((mood, count) {
      final double pct = total == 0 ? 0 : (count / total) * 100;
      sections.add(
        PieChartSectionData(
          color: _moodColor(mood, theme),
          value: pct,
          title: '${pct.toStringAsFixed(1)}%',
          radius: 90,
          titleStyle: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    });
    return sections;
  }

  Color _moodColor(MoodLevel level, ThemeData theme) {
    final scheme = theme.colorScheme;
    switch (level) {
      case MoodLevel.happy:
        return scheme.primary;
      case MoodLevel.excited:
        return scheme.secondary;
      case MoodLevel.grateful:
        return scheme.tertiary;
      case MoodLevel.relaxed:
        return Colors.teal;
      case MoodLevel.content:
        return Colors.blueGrey;
      case MoodLevel.tired:
        return Colors.brown;
      case MoodLevel.unsure:
        return Colors.grey;
      case MoodLevel.bored:
        return Colors.indigo;
      case MoodLevel.anxious:
        return Colors.deepOrange;
      case MoodLevel.angry:
        return Colors.red;
      case MoodLevel.stressed:
        return Colors.orange;
      case MoodLevel.sad:
        return Colors.blue;
    }
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(backgroundColor: color, radius: 6),
      label: Text(label),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    );
  }
}
