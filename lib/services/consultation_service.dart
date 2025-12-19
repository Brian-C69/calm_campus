import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/consultation.dart';
import '../models/user_role.dart';
import 'role_service.dart';

class ConsultationService {
  ConsultationService._();

  static final ConsultationService instance = ConsultationService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Consultant>> fetchConsultants() async {
    final List<dynamic> rows = await _client
        .from('profiles')
        .select('id,display_name,tags,is_online,is_consultant,role')
        .eq('role', 'admin')
        .order('is_online', ascending: false);

    return rows.map((row) {
      final Map<String, dynamic> data = row as Map<String, dynamic>;
      final List<String> tags = (data['tags'] as List<dynamic>? ?? []).map((e) => '$e').toList();
      return Consultant(
        id: data['id'] as String,
        displayName: (data['display_name'] as String?)?.trim().isNotEmpty == true
            ? (data['display_name'] as String)
            : 'DSA Consultant',
        tags: tags,
        isOnline: data['is_online'] as bool? ?? false,
        isConsultant: data['is_consultant'] as bool? ?? false,
      );
    }).toList();
  }

  Future<void> setAvailability({required bool isOnline}) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('profiles').upsert({
      'id': user.id,
      'is_online': isOnline,
    });
  }

  Future<ConsultationSession> startSession(String consultantId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('You need to be signed in to start a consultation.');
    }

    final Map<String, dynamic> row = await _client.from('consultations').insert({
      'student_id': user.id,
      'consultant_id': consultantId,
      'status': 'open',
    }).select().single();

    return _mapSession(row);
  }

  Future<List<ConsultationSession>> fetchSessionsForCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final UserRole role = await RoleService.instance.getCachedRole();
    final filterColumn = role == UserRole.admin ? 'consultant_id' : 'student_id';

    final List<dynamic> rows = await _client
        .from('consultations')
        .select()
        .eq(filterColumn, user.id)
        .order('started_at', ascending: false);

    return rows.map((row) => _mapSession(row as Map<String, dynamic>)).toList();
  }

  Future<List<ConsultationMessage>> fetchMessages(int sessionId) async {
    final List<dynamic> rows = await _client
        .from('consultation_messages')
        .select()
        .eq('session_id', sessionId)
        .order('sent_at', ascending: true);

    return rows.map((row) => _mapMessage(row as Map<String, dynamic>)).toList();
  }

  Future<ConsultationMessage> sendMessage({
    required int sessionId,
    required String content,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('You need to be signed in to chat with a consultant.');
    }

    final UserRole role = await RoleService.instance.getCachedRole();
    final Map<String, dynamic> row = await _client.from('consultation_messages').insert({
      'session_id': sessionId,
      'sender_id': user.id,
      'sender_role': role.label,
      'content': content.trim(),
    }).select().single();

    return _mapMessage(row);
  }

  Future<void> closeAndPurgeSession(int sessionId) async {
    await _client.from('consultations').update({
      'status': 'closed',
      'ended_at': DateTime.now().toIso8601String(),
    }).eq('id', sessionId);

    await _client.from('consultation_messages').delete().eq('session_id', sessionId);
    await _client.from('consultations').delete().eq('id', sessionId);
  }

  ConsultationSession _mapSession(Map<String, dynamic> row) {
    return ConsultationSession(
      id: row['id'] as int,
      studentId: row['student_id'] as String,
      consultantId: row['consultant_id'] as String,
      status: row['status'] as String? ?? 'open',
      startedAt: DateTime.parse(row['started_at'] as String),
      endedAt: row['ended_at'] != null ? DateTime.parse(row['ended_at'] as String) : null,
    );
  }

  ConsultationMessage _mapMessage(Map<String, dynamic> row) {
    return ConsultationMessage(
      id: row['id'] as int,
      sessionId: row['session_id'] as int,
      senderId: row['sender_id'] as String,
      senderRole: row['sender_role'] as String? ?? 'student',
      content: row['content'] as String? ?? '',
      sentAt: DateTime.parse(row['sent_at'] as String),
    );
  }
}
