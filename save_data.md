# CalmCampus – Logged-in Users Save to Cloud (Multi-Device Sync)  
_Reviewed 2025-12-02. Supabase backup + restore is live: after sign-in we upload local data, then pull the user’s cloud records into SQLite. If a Supabase session exists on launch, we restore silently. Real auth + email confirmation is working and data syncs after signup._  

## 0. Assumptions & Goal

- [x] Goal: if a user is logged in, all data lives in a cloud database and stays in sync across devices.
- [x] Guests stay local-only on that device.
- [x] Logged-in users:
    - [x] Read/write to remote DB
    - [x] (Optional but nice) Also cache locally for offline use

---

## 1. Choose Backend & Data Source Strategy

- [x] Decide backend option:
    - [ ] Option A: Firebase (Auth + Firestore)
    - [x] Option B: Supabase (Postgres + Auth)
    - [ ] Option C: Own backend (PHP/Laravel/Node/Python + REST API + DB)
- [ ] Decide UX behaviour when offline:
    - [ ] Simple: show “needs internet to sync, data may be out of date”
    - [ ] Advanced: local cache + background sync + conflict strategy

---

## 2. Make Auth Real (User IDs, Not Just SharedPreferences)

- [x] Replace “fake login” with real auth against backend:
    - [x] Sign up: send email/password/name → backend → returns user id + token
    - [x] Login: send credentials → backend → returns user id + token
- [x] On successful auth:
    - [x] Save `userId` and `authToken` securely on device (e.g. `flutter_secure_storage`)
    - [x] Update `UserProfileService` so:
        - [x] `isLoggedIn()` checks for stored `userId`/token validity
        - [x] Exposes `currentUserId`
- [x] Update `AuthPage` to:
    - [x] Call backend instead of `UserProfileService.setLoggedIn(true)`
    - [x] Handle error messages (wrong password, email exists, etc.)

---

## 3. Introduce Repositories (Abstract Local vs Remote)

Create a clean layer so the UI doesn’t care where data comes from:

- [ ] Define repository interfaces, for example:
    - [ ] `JournalRepository` (journal entries)
    - [ ] `TaskRepository` (tasks)
    - [ ] `ClassRepository` (timetable)
    - [ ] `PeriodRepository` (period cycles)
- [ ] Each interface has CRUD methods like:
    - [ ] `Future<List<JournalEntry>> getEntries(userId)`
    - [ ] `Future<int> addEntry(userId, entry)`
- [ ] Implement two versions:
    - [ ] `LocalJournalRepository` (wraps `DbService`)
    - [ ] `RemoteJournalRepository` (uses HTTP/REST to your backend)
- [ ] Add a simple factory/helper:
    - [ ] If `isLoggedIn == false` → use local repo
    - [ ] If `isLoggedIn == true` → use remote repo (plus optional cache)

---

## 4. Backend Schema Design

For each entity, include a `user_id` so data is per-account:

- [ ] Journal entries table/collection:
    - [ ] `id`, `user_id`, `content`, `created_at`
- [ ] Tasks:
    - [ ] `id`, `user_id`, `title`, `subject`, `due_date`, `status`, `priority`, `created_at`
- [ ] Classes (timetable):
    - [ ] `id`, `user_id`, `subject`, `day_of_week`, `start_time`, `end_time`, `location`, `class_type`, `lecturer`
- [ ] Period cycles:
    - [ ] `id`, `user_id`, `cycle_start_date`, `cycle_end_date`, `duration_days`, `calculated_cycle_length?`
- [ ] Enforce:
    - [ ] All queries filter by `user_id`
    - [ ] Auth middleware checks token → user id → only returns their records

---

## 5. Refactor Existing Pages to Use Repositories

### 5.1 JournalPage

- [ ] Replace direct `DbService.instance.insertJournalEntry` calls with:
    - [ ] `journalRepositoryForCurrentUser.addEntry(currentUserId, entry)`
- [ ] On init:
    - [ ] If logged in → load from remote repository
    - [ ] If guest → load from local-only repository
- [ ] `LoginNudgeService`:
    - [ ] On login success:
        - [ ] Fetch remote journals
        - [ ] (Optional) Offer to upload any local guest entries to their account

### 5.2 TasksPage

- [ ] Replace `DbService.instance.getAllTasks()` and `insertTask/updateTask/deleteTask` with repository calls.
- [ ] Ensure all task reads/writes respect logged-in vs guest mode.

### 5.3 TimetablePage

- [ ] Replace `DbService.instance.getAllClasses()` and `insertClass` with repository equivalents.
- [ ] When enabling reminders:
    - [ ] Use the same source (remote data) on every device.

### 5.4 PeriodTrackerPage

- [ ] Replace `DbService.instance.getRecentCycles()/insertPeriodCycle/update/delete` with repository.
- [ ] Ensure cycles are tied to `user_id` in backend.

---

## 6. Guest → Logged-in Migration Flow

When a guest user logs in for the first time on a device:

- [ ] Decide behaviour:
    - [ ] Merge local guest data into their new cloud account  
      **or**
    - [ ] Ask: “Do you want to upload existing entries to your account?”
- [ ] If yes:
    - [ ] For each local row (journal, tasks, classes, cycles):
        - [ ] Push to backend with `user_id`
    - [ ] Optionally mark local rows as “synced” or clear guest DB
- [ ] Next app start:
    - [ ] Always load from cloud for logged-in users

---

## 7. Optional: Local Caching for Logged-in Users

(Do this only if you have time.)

- [ ] Add `user_id` column to local SQLite tables as well
- [ ] When fetching from backend:
    - [ ] Save/update local cache rows tagged with `user_id`
- [ ] When offline:
    - [ ] Read from local cache
    - [ ] Queue writes to be synced later
- [ ] Basic conflict strategy (pick one):
    - [ ] “Last write wins”
    - [ ] Or keep both and show “conflict” states (probably overkill for exam)

---

## 8. Testing Scenarios

- [ ] Guest mode:
    - [ ] Add data → close app → reopen → still there on same device
    - [ ] Install on another device as guest → no data (correct)
- [ ] Logged in:
    - [ ] Log in on Device A, add journal/tasks, etc.
    - [ ] Log in with same account on Device B:
        - [ ] Data appears after sync
    - [ ] Update tasks on B → see updates on A after refresh
- [ ] Guest-then-login:
    - [ ] Add guest data → log in → confirm migration behaviour works as intended
- [ ] Error handling:
    - [ ] No internet → show gentle message, don’t crash
    - [ ] Backend fails → show retry, keep local safe
