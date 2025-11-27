class BreathingExercise {
  const BreathingExercise({
    required this.id,
    required this.name,
    required this.description,
    required this.inhaleSeconds,
    required this.holdSeconds,
    required this.exhaleSeconds,
    required this.cycles,
  });

  final String id;
  final String name;
  final String description;
  final int inhaleSeconds;
  final int holdSeconds;
  final int exhaleSeconds;
  final int cycles;

  int get totalDurationSeconds {
    final singleCycleSeconds = inhaleSeconds + holdSeconds + exhaleSeconds;
    return singleCycleSeconds * cycles;
  }
}
