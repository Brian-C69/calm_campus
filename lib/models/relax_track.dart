class RelaxTrack {
  const RelaxTrack({
    this.id,
    required this.title,
    required this.assetPath,
    required this.category,
    this.duration,
  });

  final int? id;
  final String title;
  final String assetPath;
  final String category;
  final Duration? duration;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'assetPath': assetPath,
      'category': category,
      'duration': duration?.inSeconds,
    };
  }

  factory RelaxTrack.fromMap(Map<String, dynamic> map) {
    return RelaxTrack(
      id: map['id'] as int?,
      title: map['title'] as String,
      assetPath: map['assetPath'] as String,
      category: map['category'] as String,
      duration: map['duration'] != null
          ? Duration(seconds: map['duration'] as int)
          : null,
    );
  }
}
