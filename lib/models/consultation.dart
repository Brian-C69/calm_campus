class Consultant {
  Consultant({
    required this.id,
    required this.displayName,
    this.tags = const [],
    this.isOnline = false,
    this.isConsultant = false,
  });

  final String id;
  final String displayName;
  final List<String> tags;
  final bool isOnline;
  final bool isConsultant;
}

class ConsultationSession {
  ConsultationSession({
    required this.id,
    required this.studentId,
    required this.consultantId,
    required this.status,
    required this.startedAt,
    this.endedAt,
  });

  final int id;
  final String studentId;
  final String consultantId;
  final String status; // open | closed
  final DateTime startedAt;
  final DateTime? endedAt;

  ConsultationSession copyWith({
    int? id,
    String? studentId,
    String? consultantId,
    String? status,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return ConsultationSession(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      consultantId: consultantId ?? this.consultantId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }
}

class ConsultationMessage {
  ConsultationMessage({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    required this.sentAt,
  });

  final int id;
  final int sessionId;
  final String senderId;
  final String senderRole; // student | admin
  final String content;
  final DateTime sentAt;
}
