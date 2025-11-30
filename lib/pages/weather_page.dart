import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather & Planning'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Check the weather before heading to campus.',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Knowing if it will be very hot or rainy can help you plan your journey and arrive a bit calmer.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Select your state'),
                value: _selectedState,
                icon: const Icon(Icons.arrow_drop_down),
                onChanged: (String? newValue) {
                  if (newValue == null) return;
                  setState(() {
                    _selectedState = newValue;
                    _forecastData = _fetchForecastData(newValue);
                  });
                },
                items: _states.entries
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
                child: _forecastData == null
                    ? Center(
                        child: Text(
                          'Select a state to see the latest forecast.',
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
                                'We could not load the forecast right now.\n${snapshot.error}',
                                style: theme.textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return Center(
                              child: Text(
                                'No forecast data available.',
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
                'Data source: Malaysian Meteorological Department (via data.gov.my).',
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
    final dateFormat = DateFormat('yyyy-MM-dd');

    return ListView.separated(
      itemCount: forecastData.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final forecast = forecastData[index];
        final parsedDate = forecast.date.isNotEmpty
            ? dateFormat.parse(forecast.date, true).toLocal()
            : null;

        final dateLabel = parsedDate != null
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
                    Text(
                      dateLabel,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      '${forecast.minTemp}°C – ${forecast.maxTemp}°C',
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
                  Text(
                    forecast.summaryWhen,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'Morning: ${forecast.morningForecast}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'Afternoon: ${forecast.afternoonForecast}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'Night: ${forecast.nightForecast}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

