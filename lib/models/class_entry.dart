class ClassEntry {
  const ClassEntry({
    this.id,
    required this.subject,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.classType,
    required this.lecturer,
  });

  final int? id;
  final String subject;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String location;
  final String classType;
  final String lecturer;

  ClassEntry copyWith({
    int? id,
    String? subject,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? location,
    String? classType,
    String? lecturer,
  }) {
    return ClassEntry(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      classType: classType ?? this.classType,
      lecturer: lecturer ?? this.lecturer,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'classType': classType,
      'lecturer': lecturer,
    };
  }

  factory ClassEntry.fromMap(Map<String, dynamic> map) {
    return ClassEntry(
      id: map['id'] as int?,
      subject: map['subject'] as String,
      dayOfWeek: map['dayOfWeek'] as int,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      location: map['location'] as String,
      classType: map['classType'] as String? ?? '',
      lecturer: map['lecturer'] as String? ?? '',
    );
  }
}
