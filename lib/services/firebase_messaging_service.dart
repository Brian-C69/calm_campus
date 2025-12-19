import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_role.dart';

class FirebaseMessagingService {
  FirebaseMessagingService._();
  static final FirebaseMessagingService instance = FirebaseMessagingService._();

  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  UserRole _role = UserRole.student;

  Future<void> init() async {
    await Firebase.initializeApp();
    _messaging = FirebaseMessaging.instance;
    await _requestPermissions();
    await _setupLocalNotifications();
    await _refreshTokenAndSubscribe();
    _messaging?.onTokenRefresh.listen(_handleToken);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> syncForRole(UserRole role) async {
    _role = role;
    await _refreshTokenAndSubscribe(role: role);
  }

  Future<void> _requestPermissions() async {
    final messaging = _messaging;
    if (messaging == null) return;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initIOS = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(android: initAndroid, iOS: initIOS);
    await _localNotifications.initialize(settings);
  }

  Future<void> _refreshTokenAndSubscribe({UserRole? role}) async {
    final messaging = _messaging;
    if (messaging == null) return;
    final String? token = await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      final UserRole effectiveRole = role ?? _role;
      final topics = <String>{'announcements'};
      topics.add(effectiveRole == UserRole.admin ? 'admin' : 'students');
      for (final topic in topics) {
        await messaging.subscribeToTopic(topic);
      }
      await _persistToken(token, effectiveRole);
      debugPrint('FCM token ready: $token for role ${effectiveRole.label}');
    } else {
      debugPrint('FCM token missing');
    }
  }

  void _handleToken(String token) {
    // On rotation, re-subscribe to the topic and log for debugging.
    _refreshTokenAndSubscribe(role: _role);
    debugPrint('FCM token refreshed: $token');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'announcements_channel',
      'Announcements',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }

  Future<void> _persistToken(String token, UserRole role) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('fcm_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'role': role.label,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to persist FCM token: $e');
    }
  }
}
