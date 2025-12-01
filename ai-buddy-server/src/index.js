import cors from 'cors';
import express from 'express';

const app = express();
const port = Number(process.env.PORT || 3001);
const ollamaUrl = process.env.OLLAMA_URL || 'http://127.0.0.1:11434';
const primaryModel = process.env.LLM_MODEL || 'gemma3:4b';
const fallbackModel = process.env.LLM_MODEL_FALLBACK || 'gemma3:1b';
const temperature = Number(process.env.LLM_TEMP || 0.5);
const timeoutMs = Number(process.env.LLM_TIMEOUT_MS || 40000);

const CRISIS_KEYWORDS = [
  'suicide',
  'self-harm',
  'kill myself',
  'end it',
  'overdose',
  'jump off',
  'cutting',
  'can not go on',
  'ending it'
];

app.use(cors());
app.use(express.json({ limit: '1mb' }));

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', model: primaryModel, fallbackModel: fallbackModel || null });
});

app.post('/chat', async (req, res) => {
  const { message, history = [], mood, timetable, tasks, sleep, contacts, consentFlags = {} } = req.body || {};
  if (!message || typeof message !== 'string') {
    return res.status(400).json({ error: 'message is required' });
  }

  const crisis = crisisCheck(message);
  const context = packContext({ mood, timetable, tasks, sleep, contacts, consentFlags });
  const system = buildSystemPrompt({ crisis });
  const messages = [
    { role: 'system', content: system },
    ...normalizeHistory(history),
    { role: 'user', content: `${context}${context ? '\n\n' : ''}User: ${message}` }
  ];

  const response = await callWithFallback(messages);
  const parsed = safeParseModelResponse(response, crisis);
  return res.json(parsed);
});

function crisisCheck(text) {
  if (!text) return false;
  const lower = text.toLowerCase();
  return CRISIS_KEYWORDS.some((k) => lower.includes(k));
}

function normalizeHistory(history) {
  if (!Array.isArray(history)) return [];
  return history
    .filter((h) => h && h.role && h.content)
    .slice(-8)
    .map((h) => ({ role: h.role, content: String(h.content) }));
}

function packContext({ mood, timetable, tasks, sleep, contacts, profile, period, movement, consentFlags }) {
  const lines = [];
  if (consentFlags?.mood && mood) {
    if (mood.summary) lines.push(`Mood: ${mood.summary}`);
    if (Array.isArray(mood.recentNotes) && mood.recentNotes.length) {
      lines.push(`Mood notes: ${mood.recentNotes.slice(0, 3).join(' | ')}`);
    }
  }
  if (consentFlags?.profile && profile) {
    const parts = [];
    if (profile.nickname) parts.push(`Name: ${profile.nickname}`);
    if (profile.course) parts.push(`Course: ${profile.course}`);
    if (profile.year) parts.push(`Year: ${profile.year}`);
    if (parts.length) lines.push(`Profile: ${parts.join(', ')}`);
  }
  if (consentFlags?.timetable && timetable) {
    if (Array.isArray(timetable.today) && timetable.today.length) {
      lines.push(`Today classes: ${timetable.today.map(formatClass).join(' ; ')}`);
    }
    if (Array.isArray(timetable.next) && timetable.next.length) {
      lines.push(`Next classes: ${timetable.next.slice(0, 2).map(formatClass).join(' ; ')}`);
    }
  }
  if (consentFlags?.tasks && tasks) {
    if (Array.isArray(tasks.pending) && tasks.pending.length) {
      lines.push(`Top tasks: ${tasks.pending.slice(0, 5).map(formatTask).join(' ; ')}`);
    }
  }
  if (consentFlags?.sleep && sleep) {
    if (sleep.recentAverage) lines.push(`Sleep avg: ${sleep.recentAverage}`);
    if (sleep.lastNight) lines.push(`Last night: ${sleep.lastNight}`);
  }
  if (consentFlags?.period && period) {
    if (period.summary) lines.push(`Cycle summary: ${period.summary}`);
    if (period.nextPeriodHint) lines.push(`Next period: ${period.nextPeriodHint}`);
    if (period.ovulationWindow) lines.push(`Ovulation window: ${period.ovulationWindow}`);
  }
  if (consentFlags?.movement && movement) {
    if (movement.recentSummary) lines.push(`Movement: ${movement.recentSummary}`);
    if (movement.energyNotes) lines.push(`Energy: ${movement.energyNotes}`);
  }
  if (consentFlags?.contacts && contacts) {
    if (Array.isArray(contacts.top) && contacts.top.length) {
      lines.push(`Support contacts: ${contacts.top.slice(0, 3).map(formatContact).join(' ; ')}`);
    }
  }
  return lines.length ? `Context:\n- ${lines.join('\n- ')}` : '';
}

function formatClass(entry) {
  return `${entry.title || entry.subject || 'Class'} @ ${entry.time || entry.startTime || ''} ${entry.location ? `(${entry.location})` : ''}`.trim();
}

function formatTask(task) {
  const parts = [task.title || 'Task'];
  if (task.due) parts.push(`due ${task.due}`);
  if (task.priority) parts.push(`p${task.priority}`);
  return parts.join(' ');
}

function formatContact(contact) {
  return contact.name || contact.relationship || 'contact';
}

function buildSystemPrompt({ crisis }) {
  return [
    "You are CalmCampus Buddy, a gentle university wellbeing + study assistant. You are Bernard's Well Being LLM.",
    "If asked what model/AI you are, clearly state: \"I'm Bernard's Well Being LLM, running locally for CalmCampus.\" Do not claim to be from Google/OpenAI or any other provider.",
    'You are not a doctor. Do not provide diagnosis, medication, or diet/weight advice. Use body-neutral language. You may discuss period/cycle patterns gently (non-clinical, no contraception/medical claims).',
    'Safety first: if the user hints at crisis, stay calm, urge contacting real humans or hotlines, and keep responses short and kind.',
    'Academic scope: you do NOT provide homework/assignment answers or tutor-style solutions. If asked for that, gently redirect to tutors, lecturers, or study resources and keep focus on wellbeing and planning.',
    'No hidden alerts or secret reporting. If data domains are not consented, ignore them.',
    'Respond in JSON only with keys: mode (check_in | support | study_planner), message_for_user, follow_up_question, suggested_actions (up to 6 short strings).',
    crisis ? 'Crisis flag true: prioritize safety, include at least one action to contact help.' : 'Keep tone warm and practical; 3-5 sentences max.'
  ].join(' ');
}

async function callWithFallback(messages) {
  const primary = await callOllama(messages, primaryModel);
  if (primary.ok) return primary;
  if (fallbackModel) {
    const secondary = await callOllama(messages, fallbackModel);
    if (secondary.ok) return secondary;
    return secondary;
  }
  return primary;
}

async function callOllama(messages, model) {
  try {
    const signal = typeof AbortSignal !== 'undefined' && AbortSignal.timeout ? AbortSignal.timeout(timeoutMs) : undefined;
    const resp = await fetch(`${ollamaUrl}/api/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model,
        messages,
        stream: false,
        // Force structured output so the model returns JSON we can parse reliably.
        format: 'json',
        options: { temperature }
      }),
      signal
    });
    const data = await resp.json();
    if (!resp.ok) {
      return { ok: false, error: data?.error || `HTTP ${resp.status}` };
    }
    return { ok: true, data };
  } catch (error) {
    return { ok: false, error: error?.message || 'unknown_error' };
  }
}

function safeParseModelResponse(response, crisis) {
  const content = response?.data?.message?.content;
  if (content) {
    try {
      const parsed = JSON.parse(content);
      if (parsed && parsed.mode && parsed.message_for_user && parsed.follow_up_question && parsed.suggested_actions) {
        if (crisis && Array.isArray(parsed.suggested_actions) && parsed.suggested_actions.length === 0) {
          parsed.suggested_actions = ['Reach out to a trusted person or hotline right now.'];
        }
        return parsed;
      }
    } catch (_) {
      // fall through to fallback
    }
  }
  return fallbackResponse(crisis, response?.error);
}

function fallbackResponse(crisis, error) {
  return {
    mode: 'support',
    message_for_user: crisis
      ? 'I care about your safety. Please reach out to someone you trust or a local crisis line right now.'
      : 'Sorry, I had trouble reaching the buddy right now. Want to try again in a moment?',
    follow_up_question: crisis
      ? 'Can you contact a friend, family member, or helpline right now?'
      : 'What else would you like help with?',
    suggested_actions: crisis
      ? ['Contact a trusted person', 'Call a local crisis line', 'Take slow breaths and move to a safe space']
      : ['Retry in a few seconds', 'Share one small thing stressing you right now'],
    error: error || undefined
  };
}

app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`CalmCampus Buddy server listening on port ${port}`);
});
