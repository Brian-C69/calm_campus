import 'dart:convert';

import 'package:http/http.dart' as http;

class ChatService {
  ChatService({
    String? baseUrl,
    http.Client? client,
  })  : _baseUrl = baseUrl ??
            const String.fromEnvironment('CHAT_BASE_URL', defaultValue: 'http://10.0.2.2:3001'),
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Uri get _chatUri => Uri.parse('$_baseUrl/chat');

  Future<ChatReply> sendMessage({
    required String message,
    List<ChatMessage> history = const [],
    ConsentFlags consent = const ConsentFlags(),
    ChatContext context = const ChatContext(),
  }) async {
    final payload = <String, dynamic>{
      'message': message,
      'history': history.map((h) => h.toMap()).toList(),
      'consentFlags': consent.toMap(),
      ...context.toPayload(),
    };

    final response = await _client.post(
      _chatUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw ChatException('Server error ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return ChatReply.fromJson(decoded);
  }
}

class ChatReply {
  ChatReply({
    required this.mode,
    required this.messageForUser,
    required this.followUpQuestion,
    required this.suggestedActions,
  });

  final String mode;
  final String messageForUser;
  final String followUpQuestion;
  final List<String> suggestedActions;

  factory ChatReply.fromJson(Map<String, dynamic> json) {
    final actions = (json['suggested_actions'] as List<dynamic>? ?? []).map((e) => '$e').toList();
    if (json['message_for_user'] == null || json['follow_up_question'] == null) {
      throw ChatException('Invalid response shape');
    }
    return ChatReply(
      mode: json['mode']?.toString() ?? 'support',
      messageForUser: json['message_for_user']?.toString() ?? '',
      followUpQuestion: json['follow_up_question']?.toString() ?? '',
      suggestedActions: actions,
    );
  }
}

class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  final String role; // 'user' or 'assistant'
  final String content;

  Map<String, dynamic> toMap() => {
        'role': role,
        'content': content,
      };
}

class ConsentFlags {
  const ConsentFlags({
    this.profile = false,
    this.mood = false,
    this.timetable = false,
    this.tasks = false,
    this.sleep = false,
    this.period = false,
    this.movement = false,
    this.contacts = false,
  });

  final bool profile;
  final bool mood;
  final bool timetable;
  final bool tasks;
  final bool sleep;
  final bool period;
  final bool movement;
  final bool contacts;

  bool get isEmpty =>
      !profile && !mood && !timetable && !tasks && !sleep && !period && !movement && !contacts;

  Map<String, dynamic> toMap() => {
        'profile': profile,
        'mood': mood,
        'timetable': timetable,
        'tasks': tasks,
        'sleep': sleep,
        'period': period,
        'movement': movement,
        'contacts': contacts,
      };
}

/// Wraps optional context blocks so they can be added when the user consents.
class ChatContext {
  const ChatContext({
    this.profile,
    this.mood,
    this.timetable,
    this.tasks,
    this.sleep,
    this.period,
    this.movement,
    this.contacts,
  });

  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? mood;
  final Map<String, dynamic>? timetable;
  final Map<String, dynamic>? tasks;
  final Map<String, dynamic>? sleep;
  final Map<String, dynamic>? period;
  final Map<String, dynamic>? movement;
  final Map<String, dynamic>? contacts;

  Map<String, dynamic> toPayload() {
    final payload = <String, dynamic>{};
    if (profile != null) payload['profile'] = profile;
    if (mood != null) payload['mood'] = mood;
    if (timetable != null) payload['timetable'] = timetable;
    if (tasks != null) payload['tasks'] = tasks;
    if (sleep != null) payload['sleep'] = sleep;
    if (period != null) payload['period'] = period;
    if (movement != null) payload['movement'] = movement;
    if (contacts != null) payload['contacts'] = contacts;
    return payload;
  }
}

class ChatException implements Exception {
  ChatException(this.message);
  final String message;

  @override
  String toString() => 'ChatException: $message';
}
