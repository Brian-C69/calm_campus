# CalmCampus – Localization (Finalization Phase To-Do)

## 1. Project & Config

- [ ] Confirm `flutter_localizations` and `intl` are added in `pubspec.yaml`
- [ ] Ensure this is set in `pubspec.yaml`:
    - [ ] `flutter:`
        - [ ] `generate: true`
- [ ] Decide which languages to support for v1 (e.g. `en`, `ms`, `zh`)

---

## 2. Create Language Files (ARB)

- [ ] Create folder: `lib/l10n/`
- [ ] Add `lib/l10n/app_en.arb` with:
    - [ ] `appTitle`
    - [ ] `welcomeMessage`
    - [ ] Common labels (buttons, navigation titles, etc.)
- [ ] Add `lib/l10n/app_ms.arb` (and others) with translated values
- [ ] Run `flutter gen-l10n` (or build the app) and confirm `AppLocalizations` is generated

---

## 3. Wire Localization into `MaterialApp`

- [ ] Import:
    - [ ] `package:flutter_localizations/flutter_localizations.dart`
    - [ ] Generated `AppLocalizations` file
- [ ] Add to `MaterialApp`:
    - [ ] `localizationsDelegates`
    - [ ] `supportedLocales`
- [ ] Add a `Locale? _locale` state in the root app widget
- [ ] Provide a way to update locale (e.g. root `setLocale()` / provider / Riverpod)

---

## 4. Make Strings Localizable (Screen by Screen)

For each screen, replace hard-coded strings with `AppLocalizations.of(context)!` keys and add them to ARB files:

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

## 5. Language Picker (Settings)

- [ ] Add a “Language” section in Settings page
- [ ] Provide UI to select language (e.g. `DropdownButton`, dialog, or list of options)
- [ ] On selection:
    - [ ] Call `setLocale(Locale('en'))`, `setLocale(Locale('ms'))`, etc.
- [ ] Persist choice:
    - [ ] Save selected locale code to `SharedPreferences`
    - [ ] Load saved locale on app startup and set `_locale` before building `MaterialApp`

---

## 6. Edge Cases & Testing

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

---

## 7. Store / Release Polish (Optional)

- [ ] Localize app name and description for Play Store / App Store
- [ ] Localize screenshot captions or marketing text
- [ ] Ensure in-app help / “about” text aligns with supported languages
