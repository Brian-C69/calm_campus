# CalmCampus Audio Player – Relax Page

This document explains how the audio player on the **Relax & Meditations** page works, what issue we ran into with the play button, and how we fixed it.

## Overall Structure

- We use the `just_audio` package with **two** `AudioPlayer` instances:
  - `_ambientPlayer` for background soundscapes (rain, river, etc.).
  - `_guidedPlayer` for guided meditations and focus sessions.
- Audio files live under `assets/audio/...` and are wired into `pubspec.yaml`.
- Tracks are described by the `RelaxTrack` model (`lib/models/relax_track.dart`) with:
  - `title`
  - `assetPath`
  - `category` (Ambient, Focus, Sleep, etc.)

On the UI side (`lib/pages/relax_page.dart`):

- A list of **ambient** tracks and a list of **guided** tracks are shown.
- Each list item has:
  - An icon and text (title + category).
  - A trailing control that can show either:
    - A **spinner** (loading state), or
    - A **play / pause** icon.
- A floating **“Now playing”** panel at the bottom shows mini controls and volume sliders for the currently selected ambient and guided tracks.

## How Playback Works

### Ambient Tracks

When the user taps an ambient track:

1. We check if the tapped track is already the **current** one using its `assetPath`.
2. If it is a **new track**:
   - We set `_currentAmbientTrack` to that track.
   - We set `_isLoadingAmbient = true` so the list tile shows a spinner.
   - We stop whatever is playing on `_ambientPlayer`.
   - We load the new asset with `setAudioSource(AudioSource.asset(track.assetPath))`.
   - We set `LoopMode.all` so the ambient sound loops.
   - We start playback with `_ambientPlayer.play()`.
   - Once loading is done, we set `_isLoadingAmbient = false` so the spinner disappears and the play/pause button shows.
3. If the tapped track is the **same current track**:
   - We do **not** set any loading flag.
   - If playback has completed, we seek back to start and play again.
   - If it is currently playing, we pause.
   - If it is paused, we resume playback.

### Guided Tracks

Guided tracks follow almost the same pattern:

- A separate `_guidedPlayer` is used.
- Loop mode is `LoopMode.off` (guided sessions do not loop automatically).
- The UI also provides **skip forward/backward 0.5s** and a volume slider.

### Listening to Player State

We listen to `playerStateStream` for each player:

- `StreamBuilder<PlayerState>` wraps the ambient and guided sections.
- The `PlayerState` provides:
  - `playing` (bool) – whether audio is currently playing.
  - `processingState` – e.g. `loading`, `buffering`, `ready`, `completed`.
- The trailing control for each track uses this to decide whether to show:
  - A **spinner** (if we are in a real loading/buffering state for that track).
  - Or a **play / pause** icon (once the player is ready).

## The Bug We Saw

### Symptom

- On the **first time** you play audio from the Relax page:
  - The list tile’s play/pause button would keep showing a **loading spinner**.
  - This happened even though you could clearly hear the audio playing.
- If you then switched to another ambient/guided track:
  - The spinner would behave correctly for that second track.

So the actual audio was fine, but the **UI state** for the first play was wrong.

### Root Causes

There were two main issues working together:

1. **Spinner logic did not check “already playing” properly**
   - Initially, we showed the spinner whenever the player’s `processingState` was `loading` or `buffering` for the current track.
   - However, with `just_audio`, it’s possible for the player to be in a loading/buffering state while **audio is already audible**.
   - Our UI logic treated that as “still loading”, so it kept showing the spinner instead of switching to a pause icon.

2. **Loading flag covered too much of the play workflow**
   - `_isLoadingAmbient` / `_isLoadingGuided` were being set before the `play()` call and only cleared in the `finally` block after awaiting the whole sequence.
   - We were effectively treating **all of `_toggleAmbient` / `_toggleGuided`** as a loading phase, including operations that should feel instant (like pausing or resuming the same track).
   - This made the loading indicator feel “stuck” or at least out of sync, especially on the first play where everything happens in one go.

## How We Fixed It

### 1. Smarter Buffering Check

In `_buildTrailingControl` we now calculate `isBuffering` like this:

- Only consider the track as “buffering” if **both** are true:
  - It is the **current track**.
  - `playerState.processingState` is `loading` or `buffering` **and `playing` is false**.

In other words:

- If the player reports loading/buffering but it is already **playing**, we **do not** show the spinner.
- This lets the UI switch to the correct play/pause icon as soon as the audio starts, even if the underlying state still says “buffering” for a moment.

### 2. Loading Flag Only for New Track Setup

We changed `_toggleAmbient` and `_toggleGuided` so that:

- **For a new track** (when you select a different `RelaxTrack`):
  - We set `_isLoadingAmbient` / `_isLoadingGuided = true` **only for the setup part**:
    - stop current player
    - set new audio source
    - set loop mode
  - We then call `play()` **without awaiting the full playback**.
  - We reset the loading flag (`_isLoading... = false`) immediately after the setup completes.
- **For the same track** (pause/resume):
  - We do **not** set any loading flag at all.
  - We just call `pause()` or `play()` based on the current state.

This keeps the spinner focused purely on **real loading work** (preparing a new track), and not on normal play/pause toggles.

## Result

After these changes:

- On the **very first play** from the Relax page:
  - You see a short spinner while the track is being prepared.
  - As soon as audio starts, the spinner disappears and a **pause** icon appears on the relevant list tile.
- When switching tracks:
  - The same pattern repeats: brief spinner → correct play/pause icon.
- For simple pause/resume of the same track:
  - No spinner is shown; the icon just flips between play and pause.

The functional audio behaviour (volume, dual playback, skip controls) stayed the same; the fix was all about making the visual feedback match what the audio player was actually doing, especially on that first play.

