import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/announcement.dart';
import 'db_service.dart';
import 'notification_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_role.dart';
import 'role_service.dart';
import 'user_profile_service.dart';

class AnnouncementService {
  AnnouncementService._();

  static final AnnouncementService instance = AnnouncementService._();

  final DbService _db = DbService.instance;
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Announcement>> loadAnnouncements() async {
    final bool isLoggedIn = await UserProfileService.instance.isLoggedIn();
    final UserRole role = isLoggedIn ? await RoleService.instance.getCachedRole() : UserRole.student;

    try {
      if (role == UserRole.admin) {
        final List<Announcement> adminRemote = await _fetchAllAndCacheForAdmin();
        if (adminRemote.isNotEmpty) return adminRemote;
      } else if (isLoggedIn) {
        final List<Announcement> studentRemote = await _fetchIncrementalForStudent();
        if (studentRemote.isNotEmpty) return studentRemote;
      } else {
        final List<Announcement> guestRemote = await _fetchAndCacheFromSupabase();
        if (guestRemote.isNotEmpty) return guestRemote;
      }
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
    bool requireAdmin = true,
  }) async {
    if (requireAdmin) {
      final role = await RoleService.instance.getCachedRole();
      if (role != UserRole.admin) {
        throw StateError('Only admins can publish announcements.');
      }
    }

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
    final role = await RoleService.instance.getCachedRole();
    if (role != UserRole.admin) {
      throw StateError('Only admins can delete announcements.');
    }

    await _db.deleteAnnouncement(id);
    _deleteAnnouncementFromSupabase(id);
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

  Future<void> _deleteAnnouncementFromSupabase(int id) async {
    try {
      await _client.from('announcements').delete().eq('id', id);
    } catch (_) {
      // Silent fail: local cache keeps it removed; remote entries will stay if offline.
    }
  }

  Future<void> _triggerRemotePush(Announcement announcement) async {
    const String pushEnv = String.fromEnvironment('PUSH_BASE_URL');
    const String chatEnv = String.fromEnvironment('CHAT_BASE_URL');
    final String baseUrl = pushEnv.isNotEmpty
        ? pushEnv
        : (chatEnv.isNotEmpty ? chatEnv : 'http://bernard.onthewifi.com:3000');
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

  Future<List<Announcement>> _fetchAllAndCacheForAdmin() async {
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

  Future<List<Announcement>> _fetchIncrementalForStudent() async {
    final user = _client.auth.currentUser;
    if (user == null) return _db.getAnnouncements();

    final Set<int> hiddenIds = await _fetchHiddenIds();
    int lastSeen = await _fetchLastSeenId();

    if (lastSeen == 0) {
      final List<dynamic> maxRow = await _client
          .from('announcements')
          .select('id')
          .order('id', ascending: false)
          .limit(1);
      if (maxRow.isNotEmpty && maxRow.first['id'] != null) {
        lastSeen = maxRow.first['id'] as int;
        await _updateLastSeenId(lastSeen);
      }
      final List<Announcement> existing = await _db.getAnnouncements();
      return existing.where((a) => a.id != null && !hiddenIds.contains(a.id!)).toList();
    }

    final List<dynamic> rows = await _client
        .from('announcements')
        .select()
        .gt('id', lastSeen)
        .order('id', ascending: true);

    final List<Announcement> newOnes = rows
        .map((row) => _mapSupabaseRow(row as Map<String, dynamic>))
        .where((a) => a.id != null && !hiddenIds.contains(a.id!))
        .toList();

    final List<Announcement> existing = await _db.getAnnouncements();
    final List<Announcement> merged = [
      ...existing.where((a) => a.id == null || !hiddenIds.contains(a.id!)),
      ...newOnes,
    ];
    merged.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    if (merged.isNotEmpty) {
      final int maxId = merged
          .where((a) => a.id != null)
          .map((a) => a.id!)
          .fold<int>(lastSeen, (prev, val) => val > prev ? val : prev);
      await _updateLastSeenId(maxId);
    }

    await _db.replaceAnnouncements(merged);
    return merged;
  }

  Future<int> _fetchLastSeenId() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;
    try {
      final Map<String, dynamic>? row = await _client
          .from('announcement_reads')
          .select('last_seen_id')
          .eq('user_id', user.id)
          .maybeSingle();
      return row?['last_seen_id'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _updateLastSeenId(int lastId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      await _client.from('announcement_reads').upsert({
        'user_id': user.id,
        'last_seen_id': lastId,
      });
    } catch (_) {
      // ignore
    }
  }

  Future<Set<int>> _fetchHiddenIds() async {
    final user = _client.auth.currentUser;
    if (user == null) return <int>{};
    try {
      final List<dynamic> rows = await _client
          .from('announcement_hides')
          .select('announcement_id')
          .eq('user_id', user.id);
      return rows
          .map((row) => row['announcement_id'] as int?)
          .whereType<int>()
          .toSet();
    } catch (_) {
      return <int>{};
    }
  }

  Future<void> hideAnnouncement(int id) async {
    final bool isLoggedIn = await UserProfileService.instance.isLoggedIn();
    if (!isLoggedIn) {
      await _db.deleteAnnouncement(id);
      return;
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      await _db.deleteAnnouncement(id);
      return;
    }

    try {
      await _client.from('announcement_hides').upsert({
        'user_id': user.id,
        'announcement_id': id,
      });
    } catch (_) {
      // ignore best effort
    }

    await _db.deleteAnnouncement(id);
  }
}
