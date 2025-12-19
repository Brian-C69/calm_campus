import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../l10n/app_localizations.dart';

class FcmDebugPage extends StatefulWidget {
  const FcmDebugPage({super.key});

  @override
  State<FcmDebugPage> createState() => _FcmDebugPageState();
}

class _FcmDebugPageState extends State<FcmDebugPage> {
  String? _token;
  String? _lastMessage;
  String? _status;
  bool _isBusy = false;
  NotificationSettings? _settings;

  @override
  void initState() {
    super.initState();
    _loadState();
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      setState(() {
        _lastMessage = 'opened:${message.messageId ?? ''} ${message.notification?.title ?? ''}';
      });
    });
  }

  Future<void> _loadState() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    final NotificationSettings settings = await messaging.getNotificationSettings();
    final String? token = await messaging.getToken();
    setState(() {
      _settings = settings;
      _token = token;
    });
  }

  Future<void> _requestPermission() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    final NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    setState(() {
      _settings = settings;
      _status = 'permission:${settings.authorizationStatus.name}';
    });
  }

  Future<void> _refreshToken() async {
    final String? token = await FirebaseMessaging.instance.getToken();
    setState(() {
      _token = token;
    });
  }

  Future<void> _copyToken() async {
    final strings = AppLocalizations.of(context);
    if (_token == null) return;
    await Clipboard.setData(ClipboardData(text: _token!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.t('fcmDebug.copied'))),
    );
  }

  Future<void> _subscribe() async {
    await FirebaseMessaging.instance.subscribeToTopic('announcements');
    setState(() {
      _status = 'subscribed';
    });
  }

  Future<void> _unsubscribe() async {
    await FirebaseMessaging.instance.unsubscribeFromTopic('announcements');
    setState(() {
      _status = 'unsubscribed';
    });
  }

  Future<void> _sendTestPush() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    final strings = AppLocalizations.of(context);

    const String pushEnv = String.fromEnvironment('PUSH_BASE_URL');
    const String chatEnv = String.fromEnvironment('CHAT_BASE_URL');
    final String baseUrl =
        pushEnv.isNotEmpty ? pushEnv : (chatEnv.isNotEmpty ? chatEnv : 'http://bernard.onthewifi.com:3002');

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/notify/announcement'),
            headers: {'Content-Type': 'application/json'},
            body: '{"title":"Test push","body":"Triggered from device"}',
          )
          .timeout(const Duration(seconds: 10));
      final ok = response.statusCode == 200;
      final String body = response.body;
      setState(() {
        _lastMessage = ok
            ? strings.t('fcmDebug.sent')
            : 'error ${response.statusCode}${body.isNotEmpty ? ' $body' : ''}';
      });
    } catch (e) {
      setState(() {
        _lastMessage = 'error $e';
      });
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('fcmDebug.title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(strings.t('fcmDebug.note'), style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            _SectionCard(
              title: strings.t('fcmDebug.permission'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_permissionLabel(strings), style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _requestPermission,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: Text(strings.t('fcmDebug.requestPermission')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: strings.t('fcmDebug.token'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(_token ?? strings.t('fcmDebug.tokenMissing')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _copyToken,
                        icon: const Icon(Icons.copy),
                        label: Text(strings.t('fcmDebug.copy')),
                      ),
                      OutlinedButton.icon(
                        onPressed: _refreshToken,
                        icon: const Icon(Icons.refresh),
                        label: Text(strings.t('fcmDebug.refreshToken')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: strings.t('fcmDebug.topic'),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _subscribe,
                    icon: const Icon(Icons.add_alert),
                    label: Text(strings.t('fcmDebug.subscribe')),
                  ),
                  OutlinedButton.icon(
                    onPressed: _unsubscribe,
                    icon: const Icon(Icons.notifications_off_outlined),
                    label: Text(strings.t('fcmDebug.unsubscribe')),
                  ),
                  if (_status != null)
                    Chip(
                      label: Text(_status!),
                      backgroundColor: colors.surfaceContainerHighest,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: strings.t('fcmDebug.sendTest'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.t('fcmDebug.sendTest.desc')),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isBusy ? null : _sendTestPush,
                    icon: const Icon(Icons.send),
                    label: Text(strings.t('fcmDebug.sendTest')),
                  ),
                  if (_lastMessage != null) ...[
                    const SizedBox(height: 8),
                    Text('${strings.t('fcmDebug.lastMessage')}: $_lastMessage'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _permissionLabel(AppLocalizations strings) {
    final status = _settings?.authorizationStatus;
    switch (status) {
      case AuthorizationStatus.authorized:
        return strings.t('fcmDebug.permission.granted');
      case AuthorizationStatus.provisional:
        return strings.t('fcmDebug.permission.provisional');
      case AuthorizationStatus.denied:
        return strings.t('fcmDebug.permission.denied');
      default:
        return strings.t('fcmDebug.permission.notDetermined');
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
