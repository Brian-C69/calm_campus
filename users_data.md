# User data & sync overview

This app keeps data locally (SQLite) for speed/offline, and selectively syncs to Supabase. Here’s what happens today and what’s missing for cross-device restore.

## Current flow (upload-only)
- Local storage: `DbService` (SQLite). All features save here.
- Supabase upload: `SupabaseSyncService.uploadAllData()` pushes local tables to Supabase when a user is signed in (moods, classes, tasks, journal, sleep, period, support contacts, movement). There is NO download/restore path implemented yet.
- Announcements are the only pull-based feature: `AnnouncementService` fetches shared posts from Supabase for everyone (including guests) and caches locally.
- Notifications: local-only via `NotificationService` (class reminders, wellbeing prompts, announcement alert).

## Implication
- A signed-in user on a new device will **not** see past entries unless we add a download/merge step. Upload-only protects privacy but limits portability.

## Recommended next steps for full sync
1) Add `SupabaseSyncService.syncFromSupabase()`:
   - Query each table for the current user.
   - Choose a merge rule (simple approach: clear local per table, then insert Supabase rows; or upsert by `local_id` to keep device-created IDs).
2) Call it after login and on a manual “Refresh from cloud” action.
3) Resolve conflicts gently:
   - Prefer newest `created_at`/`updated_at` if available.
   - If no timestamps, prefer server copy when in doubt and keep local-only drafts separately (optional).
4) Keep upload step as-is for backups.

## Data tables at a glance
- SQLite tables: moods, classes, tasks, journal_entries, sleep_entries, period_cycles, support_contacts, movement_entries, announcements.
- Supabase tables (see `sql.md`): same user-owned tables plus `announcements` (guest-readable).

## Privacy notes
- No hidden reporting. Uploads only happen when the user is signed in and triggers sync.
- Announcements are shared campus-wide; all other data stays per user. Configure Supabase RLS to enforce per-user access.
