# CalmCampus – Localization To-Do (Reviewed 2025-12-02)

Status: `flutter_localizations` + `intl` are already in `pubspec.yaml`, and we ship English, Malay, and Chinese via `assets/lang/*.json` with the custom `AppLocalizations` class. The checklist tracks migrating to the gen-l10n/ARB flow. Rule going forward: every new module/screen/service must add its strings to localization immediately—no more “translate at the end” passes.

## 1. Project & Config

- [x] Confirm `flutter_localizations` and `intl` are added in `pubspec.yaml`
- [ ] Ensure this is set in `pubspec.yaml`:
    - [ ] `flutter:`
        - [ ] `generate: true`
- [x] Decide which languages to support for v1 (e.g. `en`, `ms`, `zh`)

---

## 2. Create Language Files (ARB)

- [ ] Create folder: `lib/l10n/`
- [ ] Add `lib/l10n/app_en.arb` with:
    - [ ] `appTitle`
    - [ ] `welcomeMessage`
    - [ ] Common labels (buttons, navigation titles, etc.)
- [ ] Add `lib/l10n/app_ms.arb` (and others) with translated values
- [ ] Run `flutter gen-l10n` (or build the app) and confirm generated `AppLocalizations`

---

## 3. Wire Localization into `MaterialApp`

- [ ] Import:
    - [ ] `package:flutter_localizations/flutter_localizations.dart`
    - [ ] Generated `AppLocalizations` file
- [ ] Add to `MaterialApp`:
    - [ ] `localizationsDelegates`
- [ ] Add to `MaterialApp`:
    - [ ] `supportedLocales`
- [ ] Add a `Locale? _locale` state in the root app widget
- [ ] Provide a way to update locale (e.g. root `setLocale()` / provider / Riverpod)

---

## 4. Make Strings Localizable (Screen by Screen)

For each screen, replace hard-coded strings with generated localization keys and add them to ARB files:

- [ ] `AuthPage`
- [ ] Home / Dashboard
- [ ] `JournalPage`
- [ ] `TasksPage`
- [ ] `TimetablePage`
- [ ] Sleep / Relax pages
- [ ] `PeriodTrackerPage`
- [ ] Settings / Profile screens
- [ ] Any dialog/snackbar/error messages

For each screen:

- [ ] Identify all user-facing strings
- [ ] Create ARB keys (e.g. `auth_loginButton`, `tasks_title`, etc.)
- [ ] Add translations for all supported languages
- [ ] Rebuild and confirm no missing localization keys

---

## 5. UX & Store Assets

- [ ] Add a “Language” section in Settings page
- [ ] Provide UI to select language (e.g. `DropdownButton`, dialog, or list of options)
- [ ] On selection:
    - [ ] Call `setLocale(Locale('en'))`, `setLocale(Locale('ms'))`, etc.
- [ ] Persist choice:
    - [ ] Save selected locale code to `SharedPreferences`
    - [ ] Load saved locale on app startup and set `_locale` before building `MaterialApp`
- [ ] Test startup flow with a saved locale (cold start)
- [ ] Test switching languages while app is running
- [ ] Verify localization in:
    - [ ] Login / signup
    - [ ] Journal creation and messages
    - [ ] Tasks & planner
    - [ ] Timetable & reminders
    - [ ] Sleep / relax screens
    - [ ] Period tracker
- [ ] Check layout issues:
    - [ ] Long strings on small screens
    - [ ] Text wrapping in buttons, chips, and cards
    - [ ] Snackbars and dialogs
- [ ] Localize app name and description for Play Store / App Store
- [ ] Localize screenshot captions or marketing text
- [ ] Ensure in-app help / “about” text aligns with supported languages
