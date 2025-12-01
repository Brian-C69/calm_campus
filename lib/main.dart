import 'package:flutter/material.dart';

import 'pages/auth_page.dart';
import 'pages/announcements_page.dart';
import 'pages/chat_page.dart';
import 'pages/common_challenges_page.dart';
import 'pages/dsa_summary_page.dart';
import 'pages/help_now_page.dart';
import 'pages/history_page.dart';
import 'pages/home_page.dart';
import 'pages/journal_page.dart';
import 'pages/mood_page.dart';
import 'pages/movement_page.dart';
import 'pages/breathing_page.dart';
import 'pages/period_tracker_page.dart';
import 'pages/profile_page.dart';
import 'pages/relax_page.dart';
import 'pages/settings_page.dart';
import 'pages/sleep_page.dart';
import 'pages/support_plan_page.dart';
import 'pages/tasks_page.dart';
import 'pages/timetable_page.dart';
import 'pages/campus_map_page.dart';
import 'pages/weather_page.dart';
import 'services/notification_service.dart';
import 'services/theme_controller.dart';
import 'services/language_controller.dart';
import 'l10n/app_localizations.dart';
import 'services/supabase_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://sfkefyqyuhicwbjnsdes.supabase.co',
    anonKey: 'sb_publishable_CQ9qwM0iWstuTJBrcH4eeQ_Th6W0TS4',
  );
  await NotificationService.instance.initialize();
  await LanguageController.instance.loadSavedLanguage();
  await ThemeController.instance.loadSavedTheme();
  SupabaseSyncService.instance.startAutoUploadWatcher();
  try {
    await SupabaseSyncService.instance.restoreFromSupabaseIfSignedIn();
  } catch (_) {
    // If offline at launch, the user can manually retry from Settings or on next start.
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.instance.localeNotifier,
      builder: (context, locale, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.instance.themeModeNotifier,
          builder: (context, mode, _) {
            return MaterialApp(
              title: 'CalmCampus',
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              themeMode: mode,
              theme: ThemeData(
                colorSchemeSeed: Colors.teal,
                useMaterial3: true,
                brightness: Brightness.light,
              ),
              darkTheme: ThemeData(
                colorSchemeSeed: Colors.teal,
                useMaterial3: true,
                brightness: Brightness.dark,
              ),
              initialRoute: '/home',
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
                '/breathing': (_) => const BreathingPage(),
                '/profile': (_) => const ProfilePage(),
                '/settings': (_) => const SettingsPage(),
                '/help-now': (_) => const HelpNowPage(),
                '/dsa-summary': (_) => const DsaSummaryPage(),
                '/challenges': (_) => const CommonChallengesPage(),
                '/sleep': (_) => const SleepPage(),
                '/period-tracker': (_) => const PeriodTrackerPage(),
                '/support-plan': (_) => const SupportPlanPage(),
                '/movement': (_) => const MovementPage(),
                '/campus-map': (_) => const CampusMapPage(),
                '/weather': (_) => const WeatherPage(),
                '/announcements': (_) => const AnnouncementsPage(),
              },
            );
          },
        );
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
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: strings.t('nav.home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_outline),
            selectedIcon: const Icon(Icons.favorite),
            label: strings.t('nav.mood'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.checklist_outlined),
            selectedIcon: const Icon(Icons.checklist),
            label: strings.t('nav.tasks'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.spa_outlined),
            selectedIcon: const Icon(Icons.spa),
            label: strings.t('nav.relax'),
          ),
        ],
      ),
    );
  }
}
