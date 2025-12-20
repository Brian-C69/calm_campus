import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'l10n/app_localizations.dart';
import 'pages/announcements_page.dart';
import 'pages/auth_page.dart';
import 'pages/breathing_page.dart';
import 'pages/campus_map_page.dart';
import 'pages/chat_page.dart';
import 'pages/common_challenges_page.dart';
import 'pages/dsa_summary_page.dart';
import 'pages/help_now_page.dart';
import 'pages/history_page.dart';
import 'pages/journal_page.dart';
import 'pages/about_page.dart';
import 'pages/fcm_debug_page.dart';
import 'pages/mood_page.dart';
import 'pages/movement_page.dart';
import 'pages/period_tracker_page.dart';
import 'pages/profile_page.dart';
import 'pages/relax_page.dart';
import 'pages/settings_page.dart';
import 'pages/sleep_page.dart';
import 'pages/support_plan_page.dart';
import 'pages/tasks_page.dart';
import 'pages/timetable_page.dart';
import 'pages/weather_page.dart';
import 'pages/daily_snapshot_page.dart';
import 'pages/role_gate_page.dart';
import 'pages/student_shell.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/consultation_page.dart';
import 'pages/consultation_inbox_page.dart';
import 'pages/consultation_chat_page.dart';
import 'pages/admin_profile_page.dart';
import 'pages/reset_password_page.dart';
import 'pages/reset_request_page.dart';
import 'pages/admin_mood_analytics_page.dart';
import 'pages/onboarding_page.dart';
import 'services/firebase_messaging_service.dart';
import 'services/language_controller.dart';
import 'services/notification_service.dart';
import 'services/role_service.dart';
import 'services/supabase_sync_service.dart';
import 'services/theme_controller.dart';
import 'services/text_scale_controller.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://sfkefyqyuhicwbjnsdes.supabase.co',
    anonKey: 'sb_publishable_CQ9qwM0iWstuTJBrcH4eeQ_Th6W0TS4',
  );
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      navigatorKey.currentState?.pushNamed('/reset-password');
    }
  });
  await NotificationService.instance.initialize();
  await FirebaseMessagingService.instance.init();
  await LanguageController.instance.loadSavedLanguage();
  await ThemeController.instance.loadSavedTheme();
  await TextScaleController.instance.loadSavedScale();
  SupabaseSyncService.instance.startAutoUploadWatcher();
  try {
    await SupabaseSyncService.instance.restoreFromSupabaseIfSignedIn();
    final role = await RoleService.instance.refreshRoleFromSupabase();
    await FirebaseMessagingService.instance.syncForRole(role);
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
            return ValueListenableBuilder<Color>(
              valueListenable: ThemeController.instance.colorSeedNotifier,
              builder: (context, seedColor, __) {
                return ValueListenableBuilder<double>(
                  valueListenable: TextScaleController.instance.textScaleNotifier,
                  builder: (context, textScale, ___) {
                    return MaterialApp(
                      title: 'CalmCampus',
                      navigatorKey: navigatorKey,
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
                        colorSchemeSeed: seedColor,
                        useMaterial3: true,
                        brightness: Brightness.light,
                      ),
                      darkTheme: ThemeData(
                        colorSchemeSeed: seedColor,
                        useMaterial3: true,
                        brightness: Brightness.dark,
                      ),
                      builder: (context, child) {
                        final media = MediaQuery.of(context);
                        return MediaQuery(
                          data: media.copyWith(textScaler: TextScaler.linear(textScale)),
                          child: child ?? const SizedBox.shrink(),
                        );
                      },
                      initialRoute: '/home',
                      routes: {
                        '/auth': (_) => const AuthPage(),
                        '/home': (_) => const RoleGatePage(),
                        '/student': (_) => const MainNavigation(),
                        '/admin': (_) => const AdminDashboardPage(),
                        '/onboarding': (_) => const OnboardingPage(),
                        '/mood': (_) => const MoodPage(),
                        '/history': (_) => const HistoryPage(),
                        '/journal': (_) => const JournalPage(),
                        '/timetable': (_) => const TimetablePage(),
                        '/tasks': (_) => const TasksPage(),
                        '/chat': (_) => const ChatPage(),
                    '/relax': (_) => const RelaxPage(),
                    '/breathing': (_) => const BreathingPage(),
                    '/snapshot': (_) => const DailySnapshotPage(),
                    '/profile': (_) => const ProfilePage(),
                    '/settings': (_) => const SettingsPage(),
                        '/about': (_) => const AboutPage(),
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
                        '/consultation': (_) => const ConsultationPage(),
                        '/consultation/inbox': (_) => const ConsultationInboxPage(),
                        '/admin/profile': (_) => const AdminProfilePage(),
                        '/reset-password': (_) => const ResetPasswordPage(),
                        '/reset-request': (_) => const ResetRequestPage(),
                        '/admin/mood-analytics': (_) => const AdminMoodAnalyticsPage(),
                        '/debug/fcm': (_) => const FcmDebugPage(),
                        ConsultationChatPage.routeName: (_) => const ConsultationChatPage(),
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
