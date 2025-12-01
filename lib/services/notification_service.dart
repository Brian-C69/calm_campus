import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/announcement.dart';
import '../models/class_entry.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  Future<void> initialize() async {
    if (_initialised) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    await _requestPermissions();
    await _configureLocalTimeZone();

    _initialised = true;
  }

  Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    const String timeZoneName = 'Asia/Kuala_Lumpur';
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  Future<void> scheduleWeeklyClassReminder(ClassEntry entry) async {
    final TimeOfDay? classTime = _parseTime(entry.startTime);
    if (classTime == null) {
      return;
    }

    final tz.TZDateTime targetTime =
        _nextInstanceOfWeekday(entry.dayOfWeek, classTime, leadTime: const Duration(minutes: 30));

    await _plugin.zonedSchedule(
      _notificationIdForEntry(entry),
      'Class reminder',
      '${entry.subject} at ${entry.startTime} is in 30 minutes.',
      targetTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'class_reminders',
          'Class Reminders',
          channelDescription: 'Reminders for upcoming classes',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> scheduleNightlyCheckIn(TimeOfDay time) async {
    final tz.TZDateTime scheduledTime = _nextInstance(time, repeatDaily: true);
    await _plugin.zonedSchedule(
      2001,
      'Gentle reminder',
      'It\'s time for your nightly check-in.',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'wellbeing_prompts',
          'Wellbeing Prompts',
          channelDescription: 'Reminders to check in and rest',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleSleepPlanReminder(TimeOfDay bedtime, {String plannedBedtimeLabel = '12:00am'}) async {
    final tz.TZDateTime scheduledTime = _nextInstance(bedtime, repeatDaily: true);
    await _plugin.zonedSchedule(
      2002,
      'Wind-down plan',
      'You planned to sleep by $plannedBedtimeLabel.',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'wellbeing_prompts',
          'Wellbeing Prompts',
          channelDescription: 'Reminders to check in and rest',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleClassRemindersForWeek(List<ClassEntry> entries) async {
    for (final entry in entries) {
      await scheduleWeeklyClassReminder(entry);
    }
  }

  Future<void> showAnnouncementAlert(Announcement announcement) async {
    final String body =
        announcement.summary.isNotEmpty ? announcement.summary : _truncateBody(announcement.body);

    await _plugin.show(
      _notificationIdForAnnouncement(announcement),
      announcement.title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'campus_news',
          'Campus news',
          channelDescription: 'Updates from DSA and wellness team',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  TimeOfDay? _parseTime(String raw) {
    final String cleaned = raw.trim();
    try {
      final DateTime parsed = DateFormat.jm().parse(cleaned);
      return TimeOfDay(hour: parsed.hour, minute: parsed.minute);
    } catch (_) {
      try {
        final DateTime parsed = DateFormat.Hm().parse(cleaned);
        return TimeOfDay(hour: parsed.hour, minute: parsed.minute);
      } catch (_) {
        return null;
      }
    }
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, TimeOfDay time, {Duration leadTime = Duration.zero}) {
    tz.TZDateTime scheduledDate = _nextInstance(time, repeatDaily: false);

    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tz.TZDateTime reminderTime = scheduledDate.subtract(leadTime);
    if (reminderTime.isBefore(tz.TZDateTime.now(tz.local))) {
      return reminderTime.add(const Duration(days: 7));
    }
    return reminderTime;
  }

  tz.TZDateTime _nextInstance(TimeOfDay timeOfDay, {required bool repeatDaily}) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(Duration(days: repeatDaily ? 1 : 7));
    }
    return scheduledDate;
  }

  int _notificationIdForEntry(ClassEntry entry) => 1000 + (entry.id ?? entry.subject.hashCode).abs();

  int _notificationIdForAnnouncement(Announcement announcement) {
    final int base = announcement.id ?? announcement.title.hashCode;
    return 3000 + base.abs();
  }

  String _truncateBody(String body, {int maxChars = 120}) {
    if (body.length <= maxChars) return body;
    return '${body.substring(0, maxChars)}...';
  }
}
