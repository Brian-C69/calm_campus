import 'package:equatable/equatable.dart';

enum MoodThemeTag { stress, foodBody, social, academics, rest, motivation, other }

enum MoodLevel { great, okay, low, flat, overwhelmed }

class MoodEntry extends Equatable {
  const MoodEntry({
    this.id,
    required this.dateTime,
    required this.overallMood,
    required this.mainThemeTag,
    this.note,
    this.extraTags = const <MoodThemeTag>[],
  });

  final int? id;
  final DateTime dateTime;
  final MoodLevel overallMood;
  final MoodThemeTag mainThemeTag;
  final String? note;
  final List<MoodThemeTag> extraTags;

  MoodEntry copyWith({
    int? id,
    DateTime? dateTime,
    MoodLevel? overallMood,
    MoodThemeTag? mainThemeTag,
    String? note,
    List<MoodThemeTag>? extraTags,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      overallMood: overallMood ?? this.overallMood,
      mainThemeTag: mainThemeTag ?? this.mainThemeTag,
      note: note ?? this.note,
      extraTags: extraTags ?? this.extraTags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'overallMood': overallMood.name,
      'mainThemeTag': mainThemeTag.name,
      'note': note,
      'extraTags': extraTags.map((tag) => tag.name).toList(),
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      id: map['id'] as int?,
      dateTime: DateTime.parse(map['dateTime'] as String),
      overallMood: MoodLevel.values.byName(map['overallMood'] as String),
      mainThemeTag: MoodThemeTag.values.byName(map['mainThemeTag'] as String),
      note: map['note'] as String?,
      extraTags: (map['extraTags'] as List<dynamic>? ?? [])
          .map((tag) => MoodThemeTag.values.byName(tag as String))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, dateTime, overallMood, mainThemeTag, note, extraTags];
}
