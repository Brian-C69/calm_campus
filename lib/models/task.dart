enum TaskStatus { pending, done }

enum TaskPriority { low, medium, high }

class Task {
  const Task({
    this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.medium,
  });

  final int? id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final TaskStatus status;
  final TaskPriority priority;

  Task copyWith({
    int? id,
    String? title,
    String? subject,
    DateTime? dueDate,
    TaskStatus? status,
    TaskPriority? priority,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'priority': priority.name,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      subject: map['subject'] as String,
      dueDate: DateTime.parse(map['dueDate'] as String),
      status: TaskStatus.values.byName(map['status'] as String),
      priority: TaskPriority.values.byName(map['priority'] as String),
    );
  }
}
