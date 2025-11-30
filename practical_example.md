PracticalFlutter Guide → CalmCampus App Reference
=================================================

This file links the `PracticalFlutter202509.txt` practicals to how we’re doing things in CalmCampus, so it is easy to show the lecturer that the project follows the expected structure.

## Practical 1 & 4 – Project Structure, `main.dart`, Navigation

**Guide ideas**
- `main()` calls `runApp(MyApp());`
- `MyApp` returns a `MaterialApp` with:
  - `theme`
  - `home` or named `routes`
  - Each screen is a `Scaffold` with its own `AppBar`.

**CalmCampus usage**
- `lib/main.dart`
  - `Future<void> main()` initializes Supabase + notifications then calls `runApp(MyApp());`
  - `MyApp` returns a `MaterialApp` with `theme`, `useMaterial3`, and named `routes` for all pages.
  - `initialRoute: '/home'` and `MainNavigation` manages bottom navigation using `NavigationBar`.
- Every page in `lib/pages/` (e.g. `home_page.dart`, `mood_page.dart`, `tasks_page.dart`, etc.) is a `StatelessWidget` or `StatefulWidget` wrapped in a `Scaffold`, matching the practical’s pattern.

## Practical 5 – State Management (setState & Provider-style patterns)

**Guide ideas**
- Use `StatefulWidget` + `setState` for local UI state.
- Introduce `ChangeNotifier` and `Provider`:
  - `ChangeNotifier` holds data (`CartProvider`).
  - UI uses `Consumer<CartProvider>` or `Provider.of<CartProvider>` to rebuild when data changes.

**CalmCampus usage**
- Local state with `setState`:
  - `lib/pages/auth_page.dart`: toggling login/register, password visibility, submitting forms.
  - `lib/pages/home_page.dart`: refreshing login and nickname state via `_refreshUserState()` and `FutureBuilder`.
  - `lib/pages/tasks_page.dart`, `timetable_page.dart`, `movement_page.dart`, etc.: use `setState` and `FutureBuilder` to refresh lists after DB changes.
- Provider-style separation (without the package):
  - `lib/services/db_service.dart`, `user_profile_service.dart`, `login_nudge_service.dart`, `notification_service.dart`, `supabase_sync_service.dart` act like “providers” from the practical:
    - UI widgets **do not** talk to SQLite or SharedPreferences directly.
    - Pages call small service methods (e.g. `DbService.instance.insertTask`, `UserProfileService.instance.isLoggedIn()`), which is the same separation of concerns the state management practical promotes.

> If needed for the demo, we can still add a simple `ChangeNotifier` (e.g. `TasksProvider`) and wrap part of the app with `ChangeNotifierProvider` to mirror the shopping cart example almost exactly.

## Practical 6 – Forms and Input Validation

**Guide ideas**
- Use `Form` + `GlobalKey<FormState>` to group fields.
- Use `TextFormField` with `validator:` for input validation.
- Use `TextEditingController` and `dispose()` them.
- Call `formKey.currentState?.validate()` before saving.

**CalmCampus usage**
- `lib/pages/auth_page.dart`:
  - Uses `Form` with `_formKey`.
  - Multiple `TextFormField`s with friendly `validator` messages (email, password, confirm password).
  - `TextEditingController`s created in state and disposed in `dispose()`, matching the practical’s pattern.
  - `_submit()` method:
    - Validates the form.
    - Calls Supabase auth.
    - Updates `UserProfileService` and navigates using named routes.
- Similar form patterns can be reused for:
  - Mood check-in forms.
  - Task creation / edit.
  - Timetable class creation.
  - Profile and settings forms.

## Practical 7 – Shared Preferences

**Guide ideas**
- `SharedPreferences.getInstance()` to read/write simple key–value data.
- Functions like `_loadProfile()` and `_updateProfile()` to:
  - load data in `initState()`
  - save data on button press.
- Dispose controllers in `dispose()`.

**CalmCampus usage**
- `lib/services/user_profile_service.dart`:
  - Wraps `SharedPreferences` calls in a dedicated service:
    - `isLoggedIn()`, `setLoggedIn(bool)`
    - `getNickname()`, `saveNickname(String)`
    - `getCourse()`, `saveCourse(String)`
    - `getYearOfStudy()`, `saveYearOfStudy(int)`
    - `getTheme()` / `saveTheme(AppThemeMode)`
    - `getDailyReminderTime()` / `saveDailyReminderTime(TimeOfDay)`
  - This matches the practical’s `SharedPreferencesDemoState` but the logic is centralised in one service instead of inside a single widget.
- `lib/pages/home_page.dart`, `profile_page.dart`, `settings_page.dart`:
  - Call the service methods to load login state, nickname, course, year and settings.
  - Use `FutureBuilder` or `initState()` to load initial values, similar to `_loadProfile()` in the notes.

## Practical 8 – Data File (local files) and Assets

**Guide ideas**
- Use an `assets/` folder for images/audio.
- Register assets in `pubspec.yaml`.
- Use widgets like `Image.asset(...)` to load them.

**CalmCampus usage**
- `assets/` directory:
  - `assets/audio/...` reserved for audio tracks (as required in AGENTS and Practical 8 style).
- `pubspec.yaml`:
  - Declares asset paths so they are bundled with the app.
- `lib/pages/relax_page.dart`:
  - Uses the `RelaxTrack` model with `assetPath` and plays audio via `just_audio` from the `assets/audio/...` directory.
  - This matches the “assets management” practice from Practical 3 & 8.

## Practical 9 – SQLite

**Guide ideas**
- Create a model class (`MoodModel`) with:
  - fields
  - `fromJson` / `toMap`
- Create a `DatabaseService` singleton:
  - `Future<Database> get database`
  - `initDatabase()` with `openDatabase` and `_onCreate` to run `CREATE TABLE`.
  - Methods like `getMood()`, `insertMood`, `editMood`, `deleteMood`.
- Use `TextEditingController` and bottom sheets/forms to insert/update records.

**CalmCampus usage**
- `lib/services/db_service.dart`:
  - Central database service using `sqflite`:
    - `initDatabase()` and table creation for moods, classes (timetable), tasks, movement entries, sleep entries, etc.
    - CRUD methods for each model (e.g. `insertMoodEntry`, `getMoodEntries`, `insertTask`, `getPendingTasks`, `insertClass`, etc.) similar in spirit to `insertMood` and `getMood` in the practical.
- Models in `lib/models/`:
  - Each model class (e.g. `MoodEntry`, `ClassEntry`, `Task`, `RelaxTrack`, `MeditationSession`, `MovementEntry`, `SleepEntry`) acts like `MoodModel` with fields and mapping to/from DB rows.
- Pages like `mood_page.dart`, `tasks_page.dart`, `timetable_page.dart`, `movement_page.dart`, `sleep_page.dart`:
  - Call `DbService` methods to:
    - Load lists with `FutureBuilder` or in `initState()`.
    - Insert/update/delete entries based on forms and user actions.
  - Use `setState` after DB operations, just like the mood journal example in the practical’s bottom-sheet UI.

## Practical 10 & 11 – Web API & Supabase (Backend as a Service)

**Guide ideas**
- Use HTTP / Supabase client to:
  - Send network requests.
  - Parse JSON into Dart models.
  - Keep networking code in services, not directly in widgets.

**CalmCampus usage**
- `lib/main.dart`:
  - Calls `Supabase.initialize(...)` before `runApp`, as shown in the Supabase practical.
- `lib/pages/auth_page.dart`:
  - Uses `Supabase.instance.client.auth.signInWithPassword` and `.signUp` for email/password login.
  - Catches `AuthException` and shows friendly error messages with `ScaffoldMessenger.of(context).showSnackBar`.
- `lib/services/supabase_sync_service.dart`:
  - Handles syncing local SQLite data with Supabase when a user is logged in (upload all data).
  - Keeps network code in a service, following the “service + model + UI” separation encouraged by the practicals.

## Practical 3 – Inputs & Outputs (simple calculations)

**Guide ideas**
- Read user input with `TextField` / `TextFormField` + `TextEditingController`.
- Perform calculations (like BMI) and show results in `Text` widgets.
- Use `setState` to update the screen.

**CalmCampus usage**
- `lib/pages/movement_page.dart`, `sleep_page.dart`, `breathing_session_page.dart`:
  - Read user input (e.g. minutes, energy levels, sleep times, breathing cycles).
  - Do simple calculations (summaries, timers, etc.).
  - Update widgets with `setState` or stream/timer updates, similar to the BMI example.

## Practical 4 – Navigation (Stack, Named Routes)

**Guide ideas**
- Use `Navigator.push`, `Navigator.pop`, `Navigator.pushNamed`.
- Pass data between screens if needed.

**CalmCampus usage**
- Named routes in `lib/main.dart` for all main pages:
  - `/home`, `/mood`, `/history`, `/journal`, `/timetable`, `/tasks`, `/chat`, `/relax`, `/breathing`, `/profile`, `/settings`, `/help-now`, `/dsa-summary`, `/challenges`, `/sleep`, `/period-tracker`, `/support-plan`, `/movement`.
- `lib/pages/home_page.dart`:
  - Uses `Navigator.pushNamed(context, route)` in the grid cards and app bar actions, matching the practical’s navigation examples.
- `MainNavigation` in `main.dart`:
  - Uses `NavigationBar` + `IndexedStack` to manage bottom navigation state, which is a standard Flutter pattern on top of what the practical introduces.

---

If we need to show the lecturer specific links:
- We can point to this file, then open:
  - `PracticalFlutter202509.txt` section (e.g. Practical 7 or 9),
  - and the matching CalmCampus file (e.g. `user_profile_service.dart`, `db_service.dart`, `auth_page.dart`, `home_page.dart`)
  - to demonstrate that the implementation follows the recommended patterns (services, models, forms, navigation, and state management).

