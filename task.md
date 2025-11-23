# CalmCampus – Task List

Legend:
- ✅ = done
- ⏳ = in progress
- ❌ = not doing / dropped

You can change `[ ]` to `[x]` as you complete items.

---

## 1. Project Setup & Architecture

- [ ] Create Flutter project `calm_campus` (or final name)
- [ ] Set up basic folder structure:
    - [ ] `lib/pages/`
    - [ ] `lib/models/`
    - [ ] `lib/services/`
    - [ ] `lib/widgets/`
- [ ] Configure `pubspec.yaml`:
    - [ ] Add `http`
    - [ ] Add `sqflite` + `path` (or chosen DB)
    - [ ] Add `shared_preferences`
    - [ ] Add audio package (`just_audio` or `audioplayers`)
- [ ] Set up base `MaterialApp`:
    - [ ] `theme`, `colorSchemeSeed`, `useMaterial3`
    - [ ] Named routes for all main pages
- [ ] Create placeholder pages:
    - [ ] `HomePage`
    - [ ] `MoodPage`
    - [ ] `HistoryPage`
    - [ ] `TimetablePage`
    - [ ] `TasksPage`
    - [ ] `ChatPage` (AI Buddy)
    - [ ] `RelaxPage` (Music + Meditations)
    - [ ] `HelpNowPage`
    - [ ] `DsaSummaryPage`
    - [ ] “Common Challenges” info section page(s)

---

## 2. Data Models & Local Storage

### 2.1 Models

- [ ] Define `MoodEntry` model
    - [ ] `id`
    - [ ] `dateTime`
    - [ ] `overallMood` (string/enum)
    - [ ] `mainThemeTag` (e.g. Stress, Food & Body, Social, etc.)
    - [ ] `note`
    - [ ] `extraTags` (optional)
- [ ] Define `ClassEntry` (timetable)
    - [ ] `id`
    - [ ] `subject`
    - [ ] `dayOfWeek`
    - [ ] `startTime`, `endTime`
    - [ ] `location`
- [ ] Define `Task` (study planner)
    - [ ] `id`
    - [ ] `title`
    - [ ] `subject`
    - [ ] `dueDate`
    - [ ] `status` (pending/done)
    - [ ] `priority`
- [ ] Define `RelaxTrack`
    - [ ] `id`
    - [ ] `title`
    - [ ] `assetPath`
    - [ ] `category` (Focus/Sleep/Calm)
    - [ ] `duration` (optional)
- [ ] Define `MeditationSession`
    - [ ] `id`
    - [ ] `title`
    - [ ] `description`
    - [ ] `audioAssetPath` (optional)
    - [ ] `steps` (list of strings)
    - [ ] `estimatedTime`

### 2.2 Local DB (SQLite or chosen solution)

- [ ] Set up DB service (e.g. `DbService`):
    - [ ] `initDatabase()`
- [ ] Create `moods` table + CRUD:
    - [ ] `insertMoodEntry(MoodEntry entry)`
    - [ ] `getMoodEntries({from, to})`
    - [ ] `getTodayMood()`
    - [ ] `updateMoodEntry()`
    - [ ] `deleteMoodEntry()`
- [ ] Create `classes` table + CRUD:
    - [ ] `insertClass(ClassEntry entry)`
    - [ ] `getClassesForDay(weekday)`
    - [ ] `getAllClasses()`
    - [ ] `updateClassEntry()`
    - [ ] `deleteClassEntry()`
- [ ] Create `tasks` table + CRUD:
    - [ ] `insertTask(Task task)`
    - [ ] `getPendingTasks()`
    - [ ] `getTasksByDate(DateTime date)`
    - [ ] `updateTaskStatus()`
    - [ ] `deleteTask()`

### 2.3 Shared Preferences

- [ ] Store “first run” flag (`isFirstRun`)
- [ ] Store simple profile:
    - [ ] nickname
    - [ ] course
    - [ ] year of study
- [ ] Store app settings:
    - [ ] theme (light/dark/system)
    - [ ] daily reminder time (if implemented)

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
    - [ ] Add/edit/delete class entries
    - [ ] View by day or simple list
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

- [ ] `RelaxPage` with tabs:
    - [ ] Music
    - [ ] Meditations
- [ ] Music tab:
    - [ ] List of `RelaxTrack` items (title + play button)
    - [ ] Basic single-track playback
    - [ ] (Stretch) Remember last used track
- [ ] Meditations tab:
    - [ ] List of `MeditationSession` cards
    - [ ] `MeditationDetailPage`:
        - [ ] Show title + description + steps
        - [ ] Optional: play guided voice + ambient
- [ ] Multi-audio session page:
    - [ ] Two players: ambient + voice
    - [ ] Slider for ambient volume
    - [ ] Slider for voice volume
    - [ ] Start/Stop session button

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

