class MeditationSession {
  const MeditationSession({
    this.id,
    required this.title,
    required this.description,
    this.audioAssetPath,
    required this.steps,
    required this.estimatedTime,
  });

  final int? id;
  final String title;
  final String description;
  final String? audioAssetPath;
  final List<String> steps;
  final Duration estimatedTime;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'audioAssetPath': audioAssetPath,
      'steps': steps,
      'estimatedTime': estimatedTime.inMinutes,
    };
  }

  factory MeditationSession.fromMap(Map<String, dynamic> map) {
    return MeditationSession(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      audioAssetPath: map['audioAssetPath'] as String?,
      steps: List<String>.from(map['steps'] as List<dynamic>),
      estimatedTime: Duration(minutes: map['estimatedTime'] as int),
    );
  }
}
