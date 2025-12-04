import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }
enum AppLanguage { englishUK, chineseCN, malayMY }

class UserProfileService {
  UserProfileService._();

  static final UserProfileService instance = UserProfileService._();

  final String _nicknameKey = 'nickname';
  final String _courseKey = 'course';
  final String _yearKey = 'year_of_study';
  final String _firstRunKey = 'is_first_run';
  final String _loggedInKey = 'is_logged_in';
  final String _themeKey = 'app_theme';
  final String _languageKey = 'app_language';
  final String _timetableRemindersKey = 'timetable_reminders_enabled';
  final String _reminderTimeKey = 'daily_reminder_time';
  final String _chatShareAllKey = 'chat_share_all';
  final String _chatNoteSeenKey = 'chat_note_seen';

  Future<bool> isLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  Future<void> setLoggedIn(bool loggedIn) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, loggedIn);
  }

  Future<String?> getNickname() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nicknameKey);
  }

  Future<void> saveNickname(String nickname) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nicknameKey, nickname.trim());
  }

  Future<bool> isFirstRun() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstRunKey) ?? true;
  }

  Future<void> completeFirstRun() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstRunKey, false);
  }

  Future<void> saveCourse(String course) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_courseKey, course.trim());
  }

  Future<String?> getCourse() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_courseKey);
  }

  Future<void> saveYearOfStudy(int year) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_yearKey, year);
  }

  Future<int?> getYearOfStudy() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_yearKey);
  }

  Future<void> saveTheme(AppThemeMode theme) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
  }

  Future<AppThemeMode> getTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString(_themeKey);
    if (stored == null) return AppThemeMode.system;
    return AppThemeMode.values.byName(stored);
  }

  Future<void> saveLanguage(AppLanguage language) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.name);
  }

  Future<void> setTimetableRemindersEnabled(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_timetableRemindersKey, enabled);
  }

  Future<bool> isTimetableRemindersEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_timetableRemindersKey) ?? false;
  }

  Future<AppLanguage> getLanguage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString(_languageKey);
    if (stored == null) return AppLanguage.englishUK;
    return AppLanguage.values.byName(stored);
  }

  Future<void> saveDailyReminderTime(TimeOfDay time) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await prefs.setString(_reminderTimeKey, formatted);
  }

  Future<TimeOfDay?> getDailyReminderTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString(_reminderTimeKey);
    if (stored == null || !stored.contains(':')) return null;

    final parts = stored.split(':');
    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> clearDailyReminderTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_reminderTimeKey);
  }

  Future<bool> getChatShareAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chatShareAllKey) ?? false;
    // controls whether the AI Buddy can use all local data domains
  }

  Future<void> setChatShareAll(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chatShareAllKey, value);
  }

  Future<bool> isChatNoteSeen() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chatNoteSeenKey) ?? false;
  }

  Future<void> setChatNoteSeen() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chatNoteSeenKey, true);
  }
}
