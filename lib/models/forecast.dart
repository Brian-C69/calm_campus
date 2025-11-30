class Forecast {
  const Forecast({
    required this.date,
    required this.morningForecast,
    required this.afternoonForecast,
    required this.nightForecast,
    required this.summaryForecast,
    required this.summaryWhen,
    required this.minTemp,
    required this.maxTemp,
  });

  final String date;
  final String morningForecast;
  final String afternoonForecast;
  final String nightForecast;
  final String summaryForecast;
  final String summaryWhen;
  final int minTemp;
  final int maxTemp;

  factory Forecast.fromJson(Map<String, dynamic> json) {
    return Forecast(
      date: json['date']?.toString() ?? '',
      morningForecast: json['morning_forecast']?.toString() ?? '',
      afternoonForecast: json['afternoon_forecast']?.toString() ?? '',
      nightForecast: json['night_forecast']?.toString() ?? '',
      summaryForecast: json['summary_forecast']?.toString() ?? '',
      summaryWhen: json['summary_when']?.toString() ?? '',
      minTemp: int.tryParse(json['min_temp']?.toString() ?? '') ?? 0,
      maxTemp: int.tryParse(json['max_temp']?.toString() ?? '') ?? 0,
    );
  }
}

