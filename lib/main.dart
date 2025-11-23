import 'package:flutter/material.dart';

import 'pages/chat_page.dart';
import 'pages/common_challenges_page.dart';
import 'pages/dsa_summary_page.dart';
import 'pages/help_now_page.dart';
import 'pages/history_page.dart';
import 'pages/home_page.dart';
import 'pages/mood_page.dart';
import 'pages/relax_page.dart';
import 'pages/tasks_page.dart';
import 'pages/timetable_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CalmCampus',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      initialRoute: '/home',
      routes: {
        '/home': (_) => const HomePage(),
        '/mood': (_) => const MoodPage(),
        '/history': (_) => const HistoryPage(),
        '/timetable': (_) => const TimetablePage(),
        '/tasks': (_) => const TasksPage(),
        '/chat': (_) => const ChatPage(),
        '/relax': (_) => const RelaxPage(),
        '/help-now': (_) => const HelpNowPage(),
        '/dsa-summary': (_) => const DsaSummaryPage(),
        '/challenges': (_) => const CommonChallengesPage(),
      },
    );
  }
}
