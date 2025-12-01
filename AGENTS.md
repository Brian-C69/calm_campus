# AGENT

You are an AI assistant working on the CalmCampus Flutter app.

## Goals
- Build a gentle mental health support app for university students.
- Keep code clean, idiomatic Flutter with Material 3.
- Use `assets/audio/...` and `just_audio` for playback.
- Follow ethical rules: no diet advice, no hidden reporting.

## Workflow
- Always read `task.md` first.
- Keep Markdown checklists up to date (notably `task.md`, `final.md`, `save_data.md`, and any new reports) whenever you finish or defer work.
- Any new module/screen/service must ship with localization from day one—add strings to the l10n files as you build, not afterward.
- When you fix a bug, update `task.md` status and add a short explanation in student-friendly language.
- Prefer concise commit-ready changes with clear rationale.

## Layout & Small-Screen Safety
- Design for narrow screens first (~360dp width, e.g. 1080x2400 portrait).
- Test new screens on ~360×800 logical pixels and, if possible, with large accessibility text.

UI guardrails:
- Avoid hard-coded widths inside rows (`width: 400`, `SizedBox(width: 300)`).
- Use `Expanded`/`Flexible` around text in `Row`; use `Wrap` when chips/buttons may overflow.
- Use `SingleChildScrollView` for complex columns.
- Let text wrap; don’t force `maxLines: 1` unless essential.
- For long labels, use `Expanded` + `softWrap: true` or shorten copy.

Overflow debugging checklist (tick before shipping UI):
- [ ] Run on the smallest dev device (~360dp width).
- [ ] Ensure no yellow/black overflow stripes appear.
- [ ] Check long names/labels (course code, lecturer name, contact name, etc.).
