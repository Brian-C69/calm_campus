class PeriodCycle {
  PeriodCycle({
    this.id,
    required this.cycleStartDate,
    required this.cycleEndDate,
    required this.periodDurationDays,
    this.calculatedCycleLength,
  });

  final int? id;
  final DateTime cycleStartDate;
  final DateTime cycleEndDate;
  final int periodDurationDays;
  final int? calculatedCycleLength;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cycleStartDate': cycleStartDate.toIso8601String(),
      'cycleEndDate': cycleEndDate.toIso8601String(),
      'periodDurationDays': periodDurationDays,
      'calculatedCycleLength': calculatedCycleLength,
    };
  }

  factory PeriodCycle.fromMap(Map<String, dynamic> map) {
    return PeriodCycle(
      id: map['id'] as int?,
      cycleStartDate: DateTime.parse(map['cycleStartDate'] as String),
      cycleEndDate: DateTime.parse(map['cycleEndDate'] as String),
      periodDurationDays: map['periodDurationDays'] as int,
      calculatedCycleLength: map['calculatedCycleLength'] as int?,
    );
  }

  PeriodCycle copyWith({
    int? id,
    DateTime? cycleStartDate,
    DateTime? cycleEndDate,
    int? periodDurationDays,
    int? calculatedCycleLength,
  }) {
    return PeriodCycle(
      id: id ?? this.id,
      cycleStartDate: cycleStartDate ?? this.cycleStartDate,
      cycleEndDate: cycleEndDate ?? this.cycleEndDate,
      periodDurationDays: periodDurationDays ?? this.periodDurationDays,
      calculatedCycleLength: calculatedCycleLength ?? this.calculatedCycleLength,
    );
  }
}
