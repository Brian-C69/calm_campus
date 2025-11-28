# CalmCampus

CalmCampus is a Flutter mobile app that helps university students look after their mental health, energy, and study life in one gentle place.  
It focuses on validation, small practical steps, and clear crisis signposting – not diagnosis, diet advice, or hidden reporting.

## Core Idea

- Give students a simple daily **mood + stress check-in**.
- Connect this with **study tools** (timetable, tasks) so wellbeing is considered alongside deadlines.
- Offer quick **calm tools** (audio, breathing, grounding) students can actually use during tough moments.
- Make it easy to **reach safe people and support services** when things feel heavy.

Most data is stored **locally on the device** (SQLite + shared preferences).  
Any backend / admin features are kept minimal and are opt-in for the student.

## Key Features (Planned Scope)

### 1. Mood, Sleep & History

- Daily **Mood check-in** with:
  - Overall mood (e.g. brighter / flat / low).
  - Main theme tags: stress, food & body feelings, social stuff, sleep & tiredness, loneliness/homesick, dark thoughts, something else.
  - Optional free-text note and extra tags.
- **Mood history** page:
  - List or simple chart of past entries.
  - Tap to view full details (note, tags).
  - Optional filters by date or theme.
- **Sleep tracking**:
  - Manual log: “went to bed / woke up” + “how rested do you feel?” (1–5).
  - Sleep history for recent days (duration + restfulness).
  - Simple, gentle insights linking sleep and mood (e.g. noticing when very short sleep and low mood cluster together).

### 2. Study Support: Timetable & Tasks

- **Timetable**:
  - Add / edit / delete class entries with subject, day, time, and location.
  - View classes by day or as a simple list.
  - Planned helper: highlight “upcoming” class on Home.
- **Tasks / study planner**:
  - Create tasks with title, subject, due date, priority, and status (pending/done).
  - View pending vs completed tasks.
  - Optional filters by subject or due date.

### 3. Relax, Audio & Guided Practices

- **RelaxPage**:
  - Sections for ambient soundscapes (rain, lo-fi, ocean) and guided focus / meditation.
  - List of `RelaxTrack` items with titles and play controls.
  - Dual-player support so students can combine ambient + guided audio.
  - Volume sliders and a floating mini player.
- Audio uses `assets/audio/...` and the `just_audio` package (as configured in `pubspec.yaml`).

### 4. Breathing Exercises (Guided Calm)

- Built-in **breathing exercise catalog**, e.g.:
  - Box Breathing.
  - 4–7–8 calm breathing.
  - Gentle 4–6 breathing.
  - “Quick calm” ~1 minute preset.
- **BreathingPage**:
  - Cards showing name, short description, and approximate duration.
  - Start button for each exercise.
- **BreathingSessionPage**:
  - Shows current phase (“breathe in”, “hold”, “breathe out”) with a countdown timer.
  - Simple visual guidance (expanding/shrinking circle or ring).
  - Cycle counter and an easy “End session” button.
  - Gentle end-of-session message and option to repeat or go back to Relax.

### 5. Movement & Energy (Non-diet, Non-fitness-pressure)

- **MovementEntry** logs:
  - Date, minutes, type (walk, stretch, sport, etc.), intensity (light/moderate/vigorous).
  - Optional energy-before and energy-after ratings (1–5) and note.
- **MovementPage**:
  - “Today’s movement” quick log.
  - Simple “movement ideas” cards for study days (short, realistic suggestions).
  - Recent week summary (active days, average minutes).
- Future insights (optional): light-touch text linking movement patterns with mood and sleep – always non-judgy and body-neutral.

### 6. Period / Cycle Tracking (Opt-in & Private)

- **PeriodCycle** model:
  - Manual logging of period start/end dates, cycle length and duration.
  - Edit and correct past cycles.
- **Cycle summary**:
  - Average cycle length and period duration.
  - Last period overview.
  - Clear text: approximate only, not for contraception or medical decisions.
- **Predictions (optional)**:
  - Approximate next period start and ovulation window, shown gently.
- **Privacy**:
  - Opt-in toggle for cycle tracking.
  - Data stored only on device (for this prototype).
  - No automatic sharing with university / DSA or admins.

### 7. Support & Safety: “My Safe People”

- **Support contacts** (“My Safety & Support Plan”):
  - Save trusted people (friends, family, mentors, etc.) with their preferred contact method.
  - Mark priority contacts so they appear first.
  - Gentle explanatory copy: “These are the people you can reach out to when things feel heavy.”
- **HelpNow integration** (planned):
  - Show top priority contacts as quick actions (call/message/email).
  - Crisis help buttons: campus counselling, trusted lecturer/mentor, crisis hotlines.
  - Clear disclaimer that CalmCampus is not an emergency service.

### 8. AI Buddy & DSA / Analytics (Planned)

- **CalmCampus Buddy** (AI chat, opt-in):
  - Friendly, non-diagnostic chat for emotional support and study planning.
  - Crisis-safe prompt design: directs to HelpNow options; no hidden alerts.
  - Optional suggestions like breathing exercises, Relax tracks, or safe contacts.
- **Backend & admin panel** (PHP + MySQL, for prototype/report):
  - Minimal REST API for mood entries and announcements.
  - Simple web panel for viewing mood summaries and posting announcements.
  - Future ideas around opt-in DSA summaries and anonymised “campus pulse” stats.

## Tech Stack

- **Frontend:** Flutter, Dart, Material 3 design.
- **Local storage:** SQLite (`sqflite` + `path`) and `shared_preferences`.
- **Audio:** `just_audio` (or similar) with assets under `assets/audio/...`.
- **Backend (planned):** PHP + MySQL API and a small web admin panel.

## Running the App

1. Install Flutter and set up an emulator or physical device.
2. Fetch dependencies:
   - `flutter pub get`
3. Run the app:
   - `flutter run`

For planned or in-progress work, see `task.md`, which contains the full roadmap and checklist for CalmCampus.
