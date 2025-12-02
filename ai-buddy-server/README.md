# CalmCampus Buddy Server (Ollama)

Small Express service that fronts Ollama for the CalmCampus AI Buddy with safety guardrails.

## Setup

1) Ensure Ollama is running locally and you have pulled the model:
```sh
ollama pull gemma2:9b
```

2) Install dependencies:
```sh
cd ai-buddy-server
npm install
```

3) Run the server (defaults to port 3001):
```sh
npm start
```

## Configuration

Environment variables (optional):
- `PORT` (default `3001`)
- `OLLAMA_URL` (default `http://127.0.0.1:11434`)
- `LLM_MODEL` (default `gemma2:9b`)
- `LLM_MODEL_FALLBACK` (e.g. `gemma3:4b`)
- `LLM_TEMP` (default `0.5`)
- `LLM_TIMEOUT_MS` (default `20000`)
- `FCM_SERVER_KEY` for announcement push
- `FCM_TOPIC` (default `announcements`)

## API

`POST /chat`
```json
{
  "message": "user text",
  "history": [{"role":"assistant","content":"hi"}],
  "profile": {"nickname":"Sam","course":"CS","year":"2"},
  "mood": {"summary":"...","recentNotes":["..."]},
  "timetable": {"today":[{"title":"Algorithms","time":"10:00","location":"Room 210"}],"next":[]},
  "tasks": {"pending":[{"title":"Read chapter 3","due":"today","priority":1}]},
  "sleep": {"recentAverage":"~6h","lastNight":"5h30m"},
  "period": {"summary":"Avg 30d cycle","nextPeriodHint":"~5 days","ovulationWindow":"approx next week"},
  "movement": {"recentSummary":"Walked 3 days, ~25m avg","energyNotes":"Higher energy after short walks"},
  "contacts": {"top":[{"name":"Alex"}]},
  "consentFlags": {
    "profile": true,
    "mood": true,
    "timetable": true,
    "tasks": true,
    "sleep": true,
    "period": false,
    "movement": true,
    "contacts": true
  }
}
```

Returns JSON:
```json
{
  "mode": "support",
  "message_for_user": "...",
  "follow_up_question": "...",
  "suggested_actions": ["...", "..."]
}
```

`POST /notify/announcement`
```json
{ "title": "New announcement", "body": "Check Latest News" }
```
Requires `FCM_SERVER_KEY`. Broadcasts to topic `/topics/${FCM_TOPIC}`.

`GET /health` returns `{ status, model, fallbackModel }`.

Context packing
- Only domains with `consentFlags` true are included.
- Profile, mood, timetable, tasks, sleep, period tracker, movement, and support contacts are all optional; send short summaries (not raw logs) to stay within context limits.
- `suggested_actions` can include up to 6 short items; crisis mode ensures at least one help action.
- Academic scope: Buddy does not provide homework/assignment answers. It should redirect users to tutors/lecturers/resources and focus on wellbeing/study planning support.
- Health scope: No diagnosis/medication/diet advice; period/cycle info is allowed in gentle, non-clinical wording (no contraception/medical claims).
- Identity: Buddy should state it is “Bernard's Well Being LLM” when asked what model/AI it is.
  - When asked about its origin/provider, it should reply that it runs locally for CalmCampus and must not claim to be from Google/OpenAI/etc.

