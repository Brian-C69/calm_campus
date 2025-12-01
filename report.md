Bug fixes summary for CalmCampus

- History and period tracking used a missing `localeName` field from `AppLocalizations`, so date formatting failed. Added a simple `localeName` getter using the current locale.
- Several screens (period tracker, movement, sleep, weather, tasks) passed `EdgeInsets` as a positional argument to `Padding`, which is now a required named `padding` parameter. Updated all `Padding` widgets to use the named argument.
- Some widgets referenced localization helpers without importing the context (`strings`/`context` undefined) or passed non-string values to localized text. Added the missing `AppLocalizations` lookups, passed the right `BuildContext`, and converted numeric forecast values to strings.
- Movement quick-log dropdowns called helper methods that were scoped inside another widget, causing undefined method errors. Moved the label helpers to file-level functions so they can be reused safely.

Verification: `flutter analyze` (only existing async context warnings remain in `journal_page.dart`).
