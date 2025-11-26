class JournalEntry {
  const JournalEntry({
    this.id,
    required this.content,
    required this.createdAt,
  });

  final int? id;
  final String content;
  final DateTime createdAt;

  JournalEntry copyWith({
    int? id,
    String? content,
    DateTime? createdAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as int?,
      content: map['content'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
