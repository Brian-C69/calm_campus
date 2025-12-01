# Localization Overview

This project now supports multiple languages via JSON string files and `AppLocalizations`. Supported locales: English (UK), Chinese (Simplified), and Malay.

## How it works
- String files: `assets/lang/en.json`, `assets/lang/zh.json`, `assets/lang/ms.json`.
- Loader: `lib/l10n/app_localizations.dart` reads the JSON and provides `context.t('key')`.
- Controllers:
  - `LanguageController` keeps the current `Locale` in a `ValueNotifier` and persists it via `UserProfileService`.
  - `ThemeController` handles theme mode similarly (not localization, but paired in main).
- App wiring: `MaterialApp` in `lib/main.dart` sets `supportedLocales`, `localizationsDelegates`, and listens to `LanguageController.localeNotifier`. Changing language in Settings updates the whole app immediately.
- Storage: `UserProfileService` stores language and theme selections in `SharedPreferences`.
- Usage in widgets: Import `../l10n/app_localizations.dart` and call `AppLocalizations.of(context).t('key')` (or the `context.t('key')` extension) instead of hard-coded strings.

## Pages already localized
- Home (navigation labels and cards)
- Settings (profile fields, theme, language picker, reminders, backup)
- Auth (login/signup flow, errors, helper chips)
- Tasks (list UI, filters/sort, empty state, composer, due labels)
- Timetable (add/edit sheet, reminders, empty state, cards, long-press actions)
- Announcements (list, composer, empty state, delete dialogs)

## Pages pending localization
- MoodPage (strings still inline)
- HistoryPage (strings inline; emoji placeholders and date format pending update)
- RelaxPage, HelpNowPage, JournalPage, DsaSummaryPage, CommonChallengesPage, SleepPage, PeriodTrackerPage, SupportPlanPage, MovementPage, BreathingPage, Weather/CampusMap pages, and any other feature pages still use inline English.

## Adding/updating strings
1) Add keys/values to all three language files under `assets/lang/`.
2) Use `context.t('your.key')` in the widget instead of literals.
3) If you add new pages, ensure `AppLocalizations.supportedLocales` already covers the languages (en/zh/ms).
4) Keep copy gentle and short to avoid overflow; prefer chips/Wrap on small screens.
