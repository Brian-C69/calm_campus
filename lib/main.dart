import 'package:flutter/material.dart';

import 'pages/chat_page.dart';
import 'pages/auth_page.dart';
import 'pages/common_challenges_page.dart';
import 'pages/dsa_summary_page.dart';
import 'pages/help_now_page.dart';
import 'pages/history_page.dart';
import 'pages/home_page.dart';
import 'pages/journal_page.dart';
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
      initialRoute: '/auth',
      routes: {
        '/auth': (_) => const AuthPage(),
        '/home': (_) => const MainNavigation(),
        '/mood': (_) => const MoodPage(),
        '/history': (_) => const HistoryPage(),
        '/journal': (_) => const JournalPage(),
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

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _hasPromptedForLogin = false;

  final List<Widget> _pages = const [
    HomePage(),
    MoodPage(),
    TasksPage(),
    RelaxPage(),
  ];

  void _onItemTapped(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasPromptedForLogin) return;
      _hasPromptedForLogin = true;
      Navigator.of(context).pushNamed('/auth');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Mood',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.spa_outlined),
            selectedIcon: Icon(Icons.spa),
            label: 'Relax',
          ),
        ],
      ),
    );
  }
}
