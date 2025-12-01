import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/forecast.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final Map<String, String> _states = const {
    'St001': 'Perlis',
    'St002': 'Kedah',
    'St003': 'Pulau Pinang',
    'St004': 'Perak',
    'St005': 'Kelantan',
    'St006': 'Terengganu',
    'St007': 'Pahang',
    'St008': 'Selangor',
    'St009': 'WP Kuala Lumpur',
    'St010': 'WP Putrajaya',
    'St011': 'Negeri Sembilan',
    'St012': 'Melaka',
    'St013': 'Johor',
    'St501': 'Sarawak',
    'St502': 'Sabah',
    'St503': 'WP Labuan',
  };

  String? _selectedState;
  Future<List<Forecast>>? _forecastData;

  Future<List<Forecast>> _fetchForecastData(String locationId) async {
    if (locationId.isEmpty) {
      return Future.value(<Forecast>[]);
    }

    final url = Uri.parse(
      'https://api.data.gov.my/weather/forecast?contains=$locationId@location__location_id&sort=date',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load forecast: ${response.statusCode}');
    }

    final List<dynamic> jsonData = jsonDecode(response.body) as List<dynamic>;
    return jsonData
        .map((json) => Forecast.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('weather.title'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.t('weather.intro.title'),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                strings.t('weather.intro.desc'),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                isExpanded: true,
                hint: Text(strings.t('weather.state.hint')),
                value: _selectedState,
                icon: const Icon(Icons.arrow_drop_down),
                onChanged: (String? newValue) {
                  if (newValue == null) return;
                  setState(() {
                    _selectedState = newValue;
                    _forecastData = _fetchForecastData(newValue);
                  });
                },
                items:
                    _states.entries
                        .map(
                          (entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 12),
              Expanded(
                child:
                    _forecastData == null
                        ? Center(
                          child: Text(
                            strings.t('weather.empty'),
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        )
                        : FutureBuilder<List<Forecast>>(
                          future: _forecastData,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                _forecastData != null) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  '${strings.t('weather.error')}\n${snapshot.error}',
                                  style: theme.textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              );
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return Center(
                                child: Text(
                                  strings.t('weather.none'),
                                  style: theme.textTheme.bodyMedium,
                                ),
                              );
                            }

                            return ForecastList(forecastData: snapshot.data!);
                          },
                        ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.t('weather.source'),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ForecastList extends StatelessWidget {
  const ForecastList({super.key, required this.forecastData});

  final List<Forecast> forecastData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd');

    return ListView.separated(
      itemCount: forecastData.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final forecast = forecastData[index];
        final parsedDate =
            forecast.date.isNotEmpty
                ? dateFormat.parse(forecast.date, true).toLocal()
                : null;

        final dateLabel =
            parsedDate != null
                ? DateFormat('EEE, d MMM').format(parsedDate)
                : forecast.date;

        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dateLabel, style: theme.textTheme.titleMedium),
                    Text(
                      strings
                          .t('weather.temperatureRange')
                          .replaceFirst('{min}', '${forecast.minTemp}')
                          .replaceFirst('{max}', '${forecast.maxTemp}'),
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  forecast.summaryForecast,
                  style: theme.textTheme.bodyMedium,
                ),
                if (forecast.summaryWhen.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(forecast.summaryWhen, style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _ForecastPeriodTile(
                        label: strings.t('weather.period.morning'),
                        description: forecast.morningForecast,
                      ),
                    ),
                    Expanded(
                      child: _ForecastPeriodTile(
                        label: strings.t('weather.period.afternoon'),
                        description: forecast.afternoonForecast,
                      ),
                    ),
                    Expanded(
                      child: _ForecastPeriodTile(
                        label: strings.t('weather.period.night'),
                        description: forecast.nightForecast,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ForecastPeriodTile extends StatelessWidget {
  const _ForecastPeriodTile({required this.label, required this.description});

  final String label;
  final String description;

  IconData _iconForDescription() {
    final lower = description.toLowerCase();
    if (lower.contains('ribut petir')) {
      return Icons.thunderstorm;
    }
    if (lower.contains('hujan')) {
      return Icons.umbrella;
    }
    if (lower.contains('berjerebu')) {
      return Icons.blur_on;
    }
    if (lower.contains('tiada hujan') || lower.contains('cerah')) {
      return Icons.wb_sunny;
    }
    return Icons.cloud;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Tooltip(
          message: description,
          child: Icon(
            _iconForDescription(),
            size: 24,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
