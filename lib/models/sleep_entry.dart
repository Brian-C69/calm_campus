import 'package:equatable/equatable.dart';

class SleepEntry extends Equatable {
  const SleepEntry({
    this.id,
    required this.date,
    required this.sleepStart,
    required this.sleepEnd,
    required this.durationHours,
    required this.restfulness,
  });

  final int? id;
  final DateTime date;
  final DateTime sleepStart;
  final DateTime sleepEnd;
  final double durationHours;
  final int restfulness;

  SleepEntry copyWith({
    int? id,
    DateTime? date,
    DateTime? sleepStart,
    DateTime? sleepEnd,
    double? durationHours,
    int? restfulness,
  }) {
    return SleepEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      sleepStart: sleepStart ?? this.sleepStart,
      sleepEnd: sleepEnd ?? this.sleepEnd,
      durationHours: durationHours ?? this.durationHours,
      restfulness: restfulness ?? this.restfulness,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'sleepStart': sleepStart.toIso8601String(),
      'sleepEnd': sleepEnd.toIso8601String(),
      'durationHours': durationHours,
      'restfulness': restfulness,
    };
  }

  factory SleepEntry.fromMap(Map<String, dynamic> map) {
    return SleepEntry(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      sleepStart: DateTime.parse(map['sleepStart'] as String),
      sleepEnd: DateTime.parse(map['sleepEnd'] as String),
      durationHours: (map['durationHours'] as num).toDouble(),
      restfulness: map['restfulness'] as int,
    );
  }

  @override
  List<Object?> get props => [
        id,
        date,
        sleepStart,
        sleepEnd,
        durationHours,
        restfulness,
      ];
}
