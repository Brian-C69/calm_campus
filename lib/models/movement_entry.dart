import 'package:equatable/equatable.dart';

enum MovementType { walk, stretch, yoga, sport, dance, other }

enum MovementIntensity { light, moderate, vigorous }

class MovementEntry extends Equatable {
  const MovementEntry({
    this.id,
    required this.date,
    required this.minutes,
    required this.type,
    required this.intensity,
    this.energyBefore,
    this.energyAfter,
    this.note,
  });

  final int? id;
  final DateTime date;
  final int minutes;
  final MovementType type;
  final MovementIntensity intensity;
  final int? energyBefore;
  final int? energyAfter;
  final String? note;

  MovementEntry copyWith({
    int? id,
    DateTime? date,
    int? minutes,
    MovementType? type,
    MovementIntensity? intensity,
    int? energyBefore,
    int? energyAfter,
    String? note,
  }) {
    return MovementEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      minutes: minutes ?? this.minutes,
      type: type ?? this.type,
      intensity: intensity ?? this.intensity,
      energyBefore: energyBefore ?? this.energyBefore,
      energyAfter: energyAfter ?? this.energyAfter,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'minutes': minutes,
      'type': type.name,
      'intensity': intensity.name,
      'energyBefore': energyBefore,
      'energyAfter': energyAfter,
      'note': note,
    };
  }

  factory MovementEntry.fromMap(Map<String, dynamic> map) {
    return MovementEntry(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      minutes: map['minutes'] as int,
      type: MovementType.values.byName(map['type'] as String),
      intensity: MovementIntensity.values.byName(map['intensity'] as String),
      energyBefore: map['energyBefore'] as int?,
      energyAfter: map['energyAfter'] as int?,
      note: map['note'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        date,
        minutes,
        type,
        intensity,
        energyBefore,
        energyAfter,
        note,
      ];
}
