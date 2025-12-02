import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/announcement.dart';
import 'db_service.dart';
import 'notification_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AnnouncementService {
  AnnouncementService._();

  static final AnnouncementService instance = AnnouncementService._();

  final DbService _db = DbService.instance;
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Announcement>> loadAnnouncements() async {
    try {
      final List<Announcement> remote = await _fetchAndCacheFromSupabase();
      if (remote.isNotEmpty) return remote;
    } catch (_) {
      // Ignore network errors and fall back to local cache.
    }

    final List<Announcement> existing = await _db.getAnnouncements();
    if (existing.isNotEmpty) return existing;

    await _seedDefaults();
    return _db.getAnnouncements();
  }

  Future<Announcement> publishAnnouncement(
    Announcement announcement, {
    bool sendNotification = false,
  }) async {
    final int id = await _db.insertAnnouncement(announcement);
    final Announcement saved = announcement.copyWith(id: id);

    // Try to share with Supabase so other devices (including guests) see it.
    _uploadAnnouncementToSupabase(saved);

    if (sendNotification) {
      await NotificationService.instance.showAnnouncementAlert(saved);
      await _triggerRemotePush(saved);
    }

    return saved;
  }

  Future<void> deleteAnnouncement(int id) async {
    await _db.deleteAnnouncement(id);
  }

  Future<void> _seedDefaults() async {
    final List<Announcement> seeds = [
      Announcement(
        title: 'Caring for each other this week',
        summary: 'Gentle steps to check on friends and yourself after the recent incidents.',
        author: 'DSA Wellness Desk',
        category: 'Wellbeing update',
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        body: '''
Dear students,

The recent incidents have left us shocked and saddened. In these moments it matters even more that we look out for one another with care and kindness.

How you can care for friends around you:
- Reach out with a simple greeting or spend a few minutes together.
- Notice if someone seems withdrawn, low in mood, or behaving differently.
- If you see signs of distress, stay with them and encourage seeking professional help.

Please take care of yourself too:
- Keep regular rest and meals where you can.
- When stressed, talk to a trusted friend, family member, lecturer, or counsellor.
- Asking for help is a brave first step, never a weakness.

A gentle reminder: Please avoid spreading unverified news or rumours about these incidents. Sharing unproven information can cause more harm and deepen the distress for others.

If you or someone you know needs support:
- University Counseling Services: 03-41450123 ext. 3405, or make an appointment online.
- University Security (after-hours emergency): 011-1054 0154.
- Befrienders KL: 03-7627 2929 (24 hours).
- Talian HEAL: 15555 (8am-12am).
''',
      ),
      Announcement(
        title: 'Quiet corners for exam week',
        summary: 'Find calm study spaces and short breaks planned for this exam window.',
        author: 'DSA Wellness Desk',
        category: 'Campus life',
        publishedAt: DateTime.now().subtract(const Duration(days: 3)),
        body: '''
Need a breather between papers? The library side hall and Student Centre Room 2 will stay open as quiet corners this week.

What you will find:
- Soft lighting, water dispensers, and headphones for gentle background sounds.
- A short list of 2-minute stretch ideas you can do beside your seat.
- Volunteers on rotation if you want to talk to someone briefly.

If crowds feel heavy, it is okay to step outside for air or message a trusted friend. You deserve rest while you prepare.
''',
      ),
    ];

    for (final Announcement announcement in seeds) {
      await _db.insertAnnouncement(announcement);
    }
  }

  Future<List<Announcement>> _fetchAndCacheFromSupabase() async {
    final List<dynamic> rows = await _client
        .from('announcements')
        .select()
        .order('published_at', ascending: false);

    final List<Announcement> announcements = rows
        .map((row) => _mapSupabaseRow(row as Map<String, dynamic>))
        .where((a) => a.title.isNotEmpty && a.body.isNotEmpty)
        .toList();

    if (announcements.isNotEmpty) {
      await _db.replaceAnnouncements(announcements);
    }

    return announcements;
  }

  Announcement _mapSupabaseRow(Map<String, dynamic> row) {
    final String? summary = row['summary'] as String?;
    final String body = (row['body'] as String?) ?? '';

    return Announcement(
      id: row['id'] as int?,
      title: (row['title'] as String?)?.trim() ?? '',
      summary: (summary != null && summary.trim().isNotEmpty)
          ? summary.trim()
          : (body.length <= 120 ? body : '${body.substring(0, 120)}...'),
      body: body,
      author: (row['author'] as String?)?.trim() ?? 'DSA Wellness Desk',
      category: (row['category'] as String?)?.trim(),
      publishedAt: row['published_at'] != null
          ? DateTime.parse(row['published_at'] as String)
          : DateTime.now(),
    );
  }

  Future<void> _uploadAnnouncementToSupabase(Announcement announcement) async {
    try {
      await _client.from('announcements').upsert({
        'id': announcement.id,
        'title': announcement.title,
        'summary': announcement.summary,
        'body': announcement.body,
        'author': announcement.author,
        'category': announcement.category,
        'published_at': announcement.publishedAt.toIso8601String(),
      });
    } catch (_) {
      // Silent fail: local cache remains, but remote sync will be attempted later.
    }
  }

  Future<void> _triggerRemotePush(Announcement announcement) async {
    final String baseUrl =
        const String.fromEnvironment('PUSH_BASE_URL', defaultValue: 'http://10.0.2.2:3001');
    final Uri url = Uri.parse('$baseUrl/notify/announcement');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'title': announcement.title, 'body': announcement.summary}),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        // ignore failures silently for now
      }
    } catch (_) {
      // ignore network errors to keep local publish smooth
    }
  }
}
