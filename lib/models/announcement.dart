class Announcement {
  Announcement({
    this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.author,
    this.category,
    DateTime? publishedAt,
  }) : publishedAt = publishedAt ?? DateTime.now();

  final int? id;
  final String title;
  final String summary;
  final String body;
  final String author;
  final String? category;
  final DateTime publishedAt;

  Announcement copyWith({
    int? id,
    String? title,
    String? summary,
    String? body,
    String? author,
    String? category,
    DateTime? publishedAt,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      body: body ?? this.body,
      author: author ?? this.author,
      category: category ?? this.category,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'body': body,
      'author': author,
      'category': category,
      'publishedAt': publishedAt.toIso8601String(),
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'] as int?,
      title: map['title'] as String,
      summary: (map['summary'] as String?) ?? '',
      body: map['body'] as String,
      author: map['author'] as String,
      category: map['category'] as String?,
      publishedAt: DateTime.parse(map['publishedAt'] as String),
    );
  }
}
