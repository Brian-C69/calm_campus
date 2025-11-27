# AGENT

You are an AI assistant working on the CalmCampus Flutter app.

Goals:
- Build a mental health support app for university students.
- Keep code clean, idiomatic Flutter with Material 3.
- Use `assets/audio/...` for audio and `just_audio` for playback.
- Maintain ethical rules around mental health (no diet advice, no hidden reporting).

Workflow:
- Always read TASKS.md first.
- When you fix a bug, update TASKS.md status.
- Explain changes in simple terms so a student can understand.

## Layout & Small Screen Safety

- Always design for **narrow screens first** (min width ~360dp, e.g. 6.1–6.3" phones, 1080x2400).
- Any new screen or big UI change **must be tested** on:
    - ~360 × 800 logical pixels (portrait)
    - With large text / accessibility font enabled (if possible)

**When building UI:**

- Avoid hard-coded widths like `width: 400` or `SizedBox(width: 300)` inside rows.
- Use:
    - `Expanded` / `Flexible` around text inside `Row`
    - `Wrap` instead of `Row` when chips or buttons might overflow horizontally
    - `SingleChildScrollView` for complex columns
- Prefer `Text` that can wrap:
    - Never force `maxLines: 1` unless truly needed.
- For long button labels or headers:
    - Use `Expanded` + `softWrap: true`
    - Or shorten the text for mobile.

**Overflow debugging checklist:**

Before committing a UI change:

- [ ] Run on the smallest dev device (e.g. Pixel 4a / 360dp width).
- [ ] Check that no yellow/black overflow stripes appear.
- [ ] Check long names / labels (e.g. course code, lecturer name, contact name).