# CalmCampus – Task List

Legend:
- ✅ = done
- ⏳ = in progress
- ❌ = not doing / dropped

You can change `[ ]` to `[x]` as you complete items.

---

## 1. Project Setup & Architecture

- [x] Create Flutter project `calm_campus` (or final name)
- [x] Set up basic folder structure:
    - [x] `lib/pages/`
    - [x] `lib/models/`
    - [x] `lib/services/`
    - [x] `lib/widgets/`
- [x] Configure `pubspec.yaml`:
    - [x] Add `http`
    - [x] Add `sqflite` + `path` (or chosen DB)
    - [x] Add `shared_preferences`
    - [x] Add audio package (`just_audio` or `audioplayers`)
- [x] Set up base `MaterialApp`:
    - [x] `theme`, `colorSchemeSeed`, `useMaterial3`
    - [x] Named routes for all main pages
- [x] Create placeholder pages:
    - [x] `HomePage`
    - [x] `MoodPage`
    - [x] `HistoryPage`
    - [x] `TimetablePage`
    - [x] `TasksPage`
    - [x] `ChatPage` (AI Buddy)
    - [x] `RelaxPage` (Music + Meditations)
    - [x] `HelpNowPage`
    - [x] `DsaSummaryPage`
    - [x] “Common Challenges” info section page(s)

---

## 2. Data Models & Local Storage

### 2.1 Models

- [x] Define `MoodEntry` model
    - [x] `id`
    - [x] `dateTime`
    - [x] `overallMood` (string/enum)
    - [x] `mainThemeTag` (e.g. Stress, Food & Body, Social, etc.)
    - [x] `note`
    - [x] `extraTags` (optional)
- [x] Define `ClassEntry` (timetable)
    - [x] `id`
    - [x] `subject`
    - [x] `dayOfWeek`
    - [x] `startTime`, `endTime`
    - [x] `location`
- [x] Define `Task` (study planner)
    - [x] `id`
    - [x] `title`
    - [x] `subject`
    - [x] `dueDate`
    - [x] `status` (pending/done)
    - [x] `priority`
- [x] Define `RelaxTrack`
    - [x] `id`
    - [x] `title`
    - [x] `assetPath`
    - [x] `category` (Focus/Sleep/Calm)
    - [x] `duration` (optional)
- [x] Define `MeditationSession`
    - [x] `id`
    - [x] `title`
    - [x] `description`
    - [x] `audioAssetPath` (optional)
    - [x] `steps` (list of strings)
    - [x] `estimatedTime`

### 2.2 Local DB (SQLite or chosen solution)

- [x] Set up DB service (e.g. `DbService`):
    - [x] `initDatabase()`
- [x] Create `moods` table + CRUD:
    - [x] `insertMoodEntry(MoodEntry entry)`
    - [x] `getMoodEntries({from, to})`
    - [x] `getTodayMood()`
    - [x] `updateMoodEntry()`
    - [x] `deleteMoodEntry()`
- [x] Create `classes` table + CRUD:
    - [x] `insertClass(ClassEntry entry)`
    - [x] `getClassesForDay(weekday)`
    - [x] `getAllClasses()`
    - [x] `updateClassEntry()`
    - [x] `deleteClassEntry()`
- [x] Create `tasks` table + CRUD:
    - [x] `insertTask(Task task)`
    - [x] `getPendingTasks()`
    - [x] `getTasksByDate(DateTime date)`
    - [x] `updateTaskStatus()`
    - [x] `deleteTask()`

### 2.3 Shared Preferences

- [x] Store “first run” flag (`isFirstRun`)
- [x] Store simple profile:
    - [x] nickname
    - [x] course
    - [x] year of study
- [x] Store app settings:
    - [x] theme (light/dark/system)
    - [x] daily reminder time (if implemented)

---

## 3. Core UI Features (MVP)

### 3.1 Onboarding & Home

- [ ] Onboarding / intro screens
- [ ] Simple profile setup (optional)
- [ ] `HomePage`:
    - [ ] Show today’s mood (or “no check-in yet”)
    - [ ] Show next class (from timetable)
    - [ ] Quick actions:
        - [ ] “Check in now”
        - [ ] “Talk to Buddy”
        - [ ] “Relax”
        - [ ] “Need urgent help?”

### 3.2 Mood Check-in & History

- [ ] `MoodPage` UI:
    - [ ] Overall mood selector (emoji / label)
    - [ ] Main theme tags:
        - [ ] Stress & Overwhelm
        - [ ] Food & Body Feelings
        - [ ] People & Social Stuff
        - [ ] Sleep & Tired All The Time
        - [ ] Lonely / Homesick
        - [ ] Scary or Dark Thoughts
        - [ ] Something else
    - [ ] Optional note field
    - [ ] Save button → DB
- [ ] `HistoryPage`:
    - [ ] List of past entries (date + mood + main theme)
    - [ ] Tap to see details (note, tags)
    - [ ] Filter by theme or date (optional)

### 3.3 Timetable & Tasks

- [ ] `TimetablePage`:
    - [x] Add/edit/delete class entries
    - [x] View by day or simple list
    - [ ] Helper: highlight upcoming class
- [ ] `TasksPage`:
    - [ ] Add/edit/delete tasks
    - [ ] View pending and completed tasks
    - [ ] Optional: filter by subject or due date

---

## 4. Relax & Meditation Section

### 4.1 Audio Assets & Config

- [ ] Add audio files to `assets/audio/`
    - [ ] At least 2–3 ambient tracks (rain, lo-fi, ocean)
    - [ ] At least 1–2 guided voice tracks (optional; can be added later)
- [ ] Configure `pubspec.yaml` for audio assets

### 4.2 RelaxPage UI

- [x] `RelaxPage` with sections:
    - [x] Ambient soundscapes
    - [x] Guided focus / meditation series
- [x] Music / audio:
    - [x] List of `RelaxTrack` items (title + play button)
    - [x] Dual-player support (ambient + guided together)
    - [x] Volume sliders for ambient & guided
    - [x] Floating player with basic controls
- [ ] (Nice-to-have) Remember last used track / combo

---

## 5. AI Buddy (CalmCampus Buddy)

### 5.1 Backend (Node/Python + Ollama)

- [ ] Set up Ollama locally and test `/api/chat`
- [ ] Create backend server:
    - [ ] `/chat` endpoint
    - [ ] Accepts: `message`, `history`, `mood`, `timetable`, (optional `tasks`)
- [ ] Implement system prompt:
    - [ ] Friendly mental health + study assistant
    - [ ] No diagnosis / no medical advice
    - [ ] ED-safe and body-neutral wording
    - [ ] Social anxiety–supportive wording
    - [ ] Crisis-safe (direct to help, not hidden alerts)
- [ ] Implement JSON response format:
    - [ ] `mode` (`check_in` | `support` | `study_planner`)
    - [ ] `message_for_user`
    - [ ] `follow_up_question`
    - [ ] `suggested_actions` (list of strings)
- [ ] Implement crisis keyword detection:
    - [ ] If triggered, inject extra safety instructions into prompt

### 5.2 Flutter ChatPage

- [ ] `ChatService`:
    - [ ] `sendMessage(String text, {mood, timetable, tasks})`
    - [ ] Parse backend response JSON
- [ ] `ChatPage` UI:
    - [ ] List of chat bubbles (user + bot)
    - [ ] TextField + send button
    - [ ] Show loading indicator while waiting for reply
    - [ ] Render `suggested_actions` as tappable chips/buttons
    - [ ] (Nice-to-have) Persist minimal chat history locally

---

## 6. Safety & Help Flows

### 6.1 HelpNowPage

- [ ] Create `HelpNowPage`:
    - [ ] Short explanation: app is not emergency service
    - [ ] Buttons:
        - [ ] Contact DSA counselling (email/phone link)
        - [ ] Contact trusted lecturer/mentor (generic advice)
        - [ ] Crisis hotlines (list with tap-to-call)
- [ ] Link HelpNowPage:
    - [ ] From Home (“Need urgent help?”)
    - [ ] From Resources
    - [ ] From AI suggested actions (when crisis flagged)

### 6.2 “Common Challenges” Info Section

- [ ] Create section/page: `Common Student Challenges`
    - [ ] When food & body feel heavy
    - [ ] When people feel scary
    - [ ] When you’re exhausted or numb
    - [ ] When you feel lonely or homesick
    - [ ] When your thoughts get dark
- [ ] For each page:
    - [ ] 2–3 sentences of validation
    - [ ] 1–2 tiny self-help steps
    - [ ] Link to HelpNowPage
    - [ ] Link to relevant Relax/meditation or AI Buddy entry

---

## 7. DSA & Analytics Features

### 7.1 Per-Student DSA Summary (Opt-in)

- [ ] Function to get mood entries for last N days:
    - [ ] `getMoodEntriesForLastDays(int days)`
- [ ] `calculateMoodStats(List<MoodEntry>)`:
    - [ ] total days with entries
    - [ ] moodCounts (per mood)
    - [ ] topTags (themes)
- [ ] `buildDsaSummaryText(MoodStats stats, int days)`:
    - [ ] Human-readable summary for student to share
- [ ] `DsaSummaryPage` UI:
    - [ ] Select time range (e.g. 30 days)
    - [ ] Show summary text
    - [ ] “Copy summary” button

### 7.2 (Optional / Future) Anonymous Campus Pulse

- [ ] Simple weekly anonymous poll model (optional)
- [ ] UI to answer 1-question weekly check-in (no ID)
- [ ] Aggregate stats (for conceptual report only)

---

## 8. Extra Wellbeing Features (Optional / Nice-to-Have)

- [ ] Sleep self-report fields in mood check-in
- [ ] “Brave steps” for social anxiety (tiny weekly challenges)
- [ ] Pre-/post-meal support cards for Food & Body Feelings
- [ ] Pre-exam “7-day Exam Calm” mini program
- [ ] “My Safety & Support Plan” page:
    - [ ] Safe people
    - [ ] Safe places
    - [ ] Things to do when overwhelmed

---

## 9. Content & Copywriting

- [ ] Write all labels and microcopy in gentle, non-clinical language
- [ ] Crisis disclaimer text
- [ ] HelpNowPage texts
- [ ] Common Challenges blurbs (all categories)
- [ ] Relax & meditation descriptions
- [ ] System prompt text for AI buddy (final version)

---

## 10. Testing, Polish & Presentation

- [ ] Test on at least one physical Android device
- [ ] Check navigation flows between pages
- [ ] Test DB operations (insert/update/delete for moods, classes, tasks)
- [ ] Test audio playback (single + dual audio session)
- [ ] Test AI chat (normal + crisis keywords)
- [ ] Fix layout issues (different screen sizes)
- [x] Fix timetable add-class refresh error
- [x] Hide login button on Home after successful sign-in
- [ ] Prepare screenshots for slides
- [ ] Prepare demo script:
    - [ ] Scenario: stressed student before exams
    - [ ] Scenario: student with food/body worries
    - [ ] Scenario: student needing urgent help
- [ ] Finalize report sections:
    - [ ] Problem statement & objectives
    - [ ] Literature / competitor apps
    - [ ] System design (diagrams)
    - [ ] Implementation
    - [ ] Ethical considerations
    - [ ] Limitations & future work

---

## 11. Sleep Tracking & Insights

### 11.1 Sleep Data Model & Storage

- [ ] Define `SleepEntry` model:
    - [ ] `id`
    - [ ] `date` (date of sleep / wake)
    - [ ] `sleepStart` (DateTime or stored string)
    - [ ] `sleepEnd`
    - [ ] `durationHours`
    - [ ] `restfulness` (1–5)
- [ ] Add `sleep_entries` table in SQLite:
    - [ ] Create migration in `DbService`
    - [ ] CRUD methods:
        - [ ] `insertSleepEntry(SleepEntry entry)`
        - [ ] `getSleepEntries({from, to})`
        - [ ] `deleteSleepEntry(id)`
        - [ ] (Optional) `updateSleepEntry()`

### 11.2 Sleep UI (Manual & Simple Tracker)

- [ ] Add Sleep section/page:
    - [ ] Either standalone `SleepPage` or inside Mood/Relax
- [ ] Manual sleep log:
    - [ ] Time pickers for “Went to bed” and “Woke up”
    - [ ] Slider / rating for “How rested do you feel?”
    - [ ] Save to DB
- [ ] Sleep history view:
    - [ ] List / simple chart of last 7–14 days
    - [ ] Show duration + restfulness per entry
- [ ] Simple in-app sleep session (optional):
    - [ ] “Start Sleep Session” button (stores start time)
    - [ ] “I’m awake” button (stores end time, calculates duration)
    - [ ] Prompt for restfulness after session

### 11.3 Sleep–Mood Insights

- [ ] Add sleep info into Home or Mood History:
    - [ ] Show “Last night: Xh Ym” on Home if data exists
- [ ] Simple correlations:
    - [ ] Compute average sleep duration on “good mood” vs “low mood” days
    - [ ] Show small text: “You often feel low when sleep < 6 hours.”
- [ ] Add gentle copy:
    - [ ] Reminders that poor sleep can affect mood
    - [ ] No shaming, only validation + tiny suggestions

### 11.4 Future Work (for report only)

- [ ] Document potential integration with:
    - [ ] Android Health Connect / Google Fit for sleep data
    - [ ] Apple HealthKit (if iOS version)
- [ ] Note consent & privacy:
    - [ ] Explicit toggle: “Allow CalmCampus to use my sleep data.”
    - [ ] Clarify that sleep data is not auto-shared with DSA without consent

---

## 12. Backend & PHP Admin (API + Web Panel)

### 12.1 Server-Side Setup (PHP + MySQL)

- [ ] Create MySQL database `calm_campus`
- [ ] Design server tables (minimal for prototype):
    - [ ] `moods` (id, user_id, mood, main_theme, note, created_at)
    - [ ] `classes` (if syncing timetable)
    - [ ] `announcements` (id, title, body, created_at, author)
- [ ] Set up XAMPP/Apache virtual host or folder for `calm_campus_api/`

### 12.2 PHP REST API Endpoints

- [ ] Implement `moods.php`:
    - [ ] `POST /moods` to create mood entry (JSON body)
    - [ ] `GET /moods` to list moods (for admin/testing)
- [ ] Implement `announcements.php`:
    - [ ] `POST /announcements` to create announcement
    - [ ] `GET /announcements` to list announcements for app
- [ ] (Optional) Implement `classes.php` if timetable sync is needed
- [ ] Add basic validation and JSON error responses

### 12.3 Flutter Integration with PHP API

- [ ] Create `ApiService` in Flutter:
    - [ ] Base URL (e.g. `http://10.0.2.2/calm_campus_api`)
    - [ ] `submitMood(...)` → POST to `moods.php`
    - [ ] `fetchAnnouncements()` → GET from `announcements.php`
- [ ] Decide strategy:
    - [ ] Use server DB as main source for moods (and/or)
    - [ ] Keep local SQLite as cache and sync periodically (conceptual for report)

### 12.4 PHP Admin Web Panel

- [ ] Create simple admin login (even if hard-coded for prototype)
- [ ] Admin page: “All Mood Check-ins”
    - [ ] Table view: user, mood, tags, created_at
    - [ ] Filter by date range (optional)
- [ ] Admin page: “Announcements”
    - [ ] Form to create new announcement (title + body)
    - [ ] List existing announcements with created_at
- [ ] (Nice-to-have) Basic styling using simple CSS/Bootstrap

### 12.5 Future Enhancements (for report)

- [ ] Describe potential DSA dashboard:
    - [ ] Aggregated statistics (no names)
    - [ ] Filters by time range and theme (stress, sleep, social, etc.)
- [ ] Mention possibility of integrating push notifications:
    - [ ] Using FCM triggered when a new announcement is created
    - [ ] Students tap notification → CalmCampus opens Announcement page

