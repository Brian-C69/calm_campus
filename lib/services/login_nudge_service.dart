import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LoginNudgeTrigger {
  journalSave,
  moodHistorySave,
  timetableSetup,
  aiCustomization,
}

enum LoginNudgeAction {
  notNeeded,
  continueAsGuest,
  loginSelected,
}

class LoginNudgeService {
  LoginNudgeService._();

  static final LoginNudgeService instance = LoginNudgeService._();

  final Map<LoginNudgeTrigger, String> _preferenceKeys = {
    LoginNudgeTrigger.journalSave: 'nudge_journal',
    LoginNudgeTrigger.moodHistorySave: 'nudge_mood_history',
    LoginNudgeTrigger.timetableSetup: 'nudge_timetable',
    LoginNudgeTrigger.aiCustomization: 'nudge_ai_custom',
  };

  Future<LoginNudgeAction> maybePrompt(
    BuildContext context,
    LoginNudgeTrigger trigger,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = _preferenceKeys[trigger]!;
    final bool hasShown = prefs.getBool(key) ?? false;

    if (hasShown) {
      return LoginNudgeAction.notNeeded;
    }

    await prefs.setBool(key, true);

    final result = await showModalBottomSheet<LoginNudgeAction>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _LoginPrompt(trigger: trigger),
    );

    return result ?? LoginNudgeAction.continueAsGuest;
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.trigger});

  final LoginNudgeTrigger trigger;

  String get _title {
    switch (trigger) {
      case LoginNudgeTrigger.journalSave:
        return 'Keep your journal safe';
      case LoginNudgeTrigger.moodHistorySave:
        return 'Remember this check-in';
      case LoginNudgeTrigger.timetableSetup:
        return 'Save your timetable';
      case LoginNudgeTrigger.aiCustomization:
        return 'Keep your AI buddy settings';
    }
  }

  String get _body {
    switch (trigger) {
      case LoginNudgeTrigger.journalSave:
        return 'To keep this safe and remember it for you, you can log in before we save your journal entry.';
      case LoginNudgeTrigger.moodHistorySave:
        return 'To keep this safe and remember it for you, you can log in before we store your mood history.';
      case LoginNudgeTrigger.timetableSetup:
        return 'To keep this safe and remember it for you, you can log in while you set up reminders.';
      case LoginNudgeTrigger.aiCustomization:
        return 'To keep this safe and remember it for you, you can log in before we personalise your AI companion.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_open_rounded, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(
                  context,
                  LoginNudgeAction.continueAsGuest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _body,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'We only require login for DSA sharing, campus integrations, or cloud sync.',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(
                context,
                LoginNudgeAction.loginSelected,
              ),
              child: const Text('Log in to save and sync'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(
                context,
                LoginNudgeAction.continueAsGuest,
              ),
              child: const Text('Continue as guest'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
