import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseMessagingService {
  FirebaseMessagingService._();
  static final FirebaseMessagingService instance = FirebaseMessagingService._();

  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await Firebase.initializeApp();
    _messaging = FirebaseMessaging.instance;
    await _requestPermissions();
    await _setupLocalNotifications();
    await _refreshTokenAndSubscribe();
    _messaging?.onTokenRefresh.listen(_handleToken);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
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

  Future<void> _refreshTokenAndSubscribe() async {
    final messaging = _messaging;
    if (messaging == null) return;
    final String? token = await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      // Keep topic subscription fresh to avoid missing pushes when tokens rotate.
      await messaging.subscribeToTopic('announcements');
      debugPrint('FCM token ready: $token');
    } else {
      debugPrint('FCM token missing');
    }
  }

  void _handleToken(String token) {
    // On rotation, re-subscribe to the topic and log for debugging.
    _messaging?.subscribeToTopic('announcements');
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
}
