import cors from 'cors';
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';

const app = express();
const port = Number(process.env.PORT || 3001);
const ollamaUrl = process.env.OLLAMA_URL || 'http://127.0.0.1:11434';
const primaryModel = process.env.LLM_MODEL || 'gemma3:4b';
const fallbackModel = process.env.LLM_MODEL_FALLBACK || 'gemma3:1b';
const temperature = Number(process.env.LLM_TEMP || 0.5);
const timeoutMs = Number(process.env.LLM_TIMEOUT_MS || 40000);
const fcmKey = process.env.FCM_SERVER_KEY;
const fcmTopic = process.env.FCM_TOPIC || 'announcements';
const dietKeywords = ['diet', 'calorie', 'calories', 'weight loss', 'lose weight', 'meal plan', 'keto', 'fasting'];

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
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const confirmDir = path.join(__dirname, '..', '..', 'web', 'confirm');
app.use('/confirm', express.static(confirmDir));

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', model: primaryModel, fallbackModel: fallbackModel || null });
});

app.post('/chat', async (req, res) => {
  const {
    message,
    history = [],
    mood,
    timetable,
    tasks,
    sleep,
    contacts,
    profile,
    period,
    movement,
    consentFlags = {}
  } = req.body || {};
  if (!message || typeof message !== 'string') {
    return res.status(400).json({ error: 'message is required' });
  }

  const crisis = crisisCheck(message);
  const dietFocus = dietCheck(message);
  const normalizedHistory = normalizeHistory(history);
  const contactsForActions = consentFlags?.contacts ? buildContactActionList(contacts) : [];
  const contactsTop = consentFlags?.contacts && contacts && Array.isArray(contacts.top) ? contacts.top : [];
  const relationshipAnswer = buildRelationshipFallback(message, contactsTop, contactsForActions);
  if (relationshipAnswer) {
    return res.json(relationshipAnswer);
  }
  const context = packContext({
    mood,
    timetable,
    tasks,
    sleep,
    contacts,
    profile,
    period,
    movement,
    consentFlags,
    history: normalizedHistory
  });
  const system = buildSystemPrompt({ crisis, dietFocus });
  const messages = [
    { role: 'system', content: system },
    ...normalizedHistory,
    { role: 'user', content: `${context}${context ? '\n\n' : ''}User: ${message}` }
  ];

  const response = await callWithFallback(messages);
  const parsed = safeParseModelResponse(response, crisis, contactsForActions, {
    userMessage: message,
    contactsTop
  });
  return res.json(parsed);
});

app.post('/notify/announcement', async (req, res) => {
  const { title, body } = req.body || {};
  if (!title || !body) {
    return res.status(400).json({ error: 'title and body are required' });
  }
  const result = await sendFcmNotification({ title, body });
  if (!result.ok) {
    return res.status(500).json({ error: result.error || 'fcm_error' });
  }
  return res.json({ status: 'sent' });
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

function packContext({
  mood,
  timetable,
  tasks,
  sleep,
  contacts,
  profile,
  period,
  movement,
  consentFlags,
  history
}) {
  const lines = [];
  const timeHint = formatNow();
  if (timeHint) lines.push(`Current time: ${timeHint}`);
  if (consentFlags?.mood && mood) {
    if (mood.summary) lines.push(`Mood: ${mood.summary}`);
    if (Array.isArray(mood.recentNotes) && mood.recentNotes.length) {
      lines.push(`Mood notes: ${mood.recentNotes.slice(0, 3).join(' | ')}`);
    }
  }
  if (consentFlags?.profile && profile) {
    const nickname =
      profile.nickname ||
      profile.name ||
      profile.displayName ||
      profile.firstName ||
      profile.preferredName;
    const parts = [];
    if (nickname) parts.push(`Name: ${nickname}`);
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
      lines.push(`Support contacts (consented): ${contacts.top.slice(0, 3).map(formatContact).join(' ; ')}`);
    }
  }
  const toneHint = deriveToneHint(mood);
  if (toneHint) lines.push(`Tone: ${toneHint}`);
  const styleHint = deriveStyleHint(history);
  if (styleHint) lines.push(`Style: ${styleHint}`);
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
  const name = contact.name || contact.nickname || '';
  const relationship = contact.relationship || '';
  const type = contact.contactType || '';
  if (name && relationship) return `${name} (${relationship}${type ? `, ${type}` : ''})`;
  if (name && type) return `${name} (${type})`;
  const pieces = [name, relationship || type].filter(Boolean);
  return pieces.join(' ').trim() || 'contact';
}

function buildContactActionList(contacts) {
  if (!contacts || !Array.isArray(contacts.top)) return [];
  return contacts.top
    .slice(0, 3)
    .map((c) => {
      const name = c.name || c.nickname || c.firstName || 'a contact';
      const rel = c.relationship;
      return rel ? `${name} (${rel})` : name;
    })
    .filter(Boolean);
}
function buildSystemPrompt({ crisis, dietFocus }) {
  return [
    "You are CalmCampus Buddy, a gentle university wellbeing + study assistant. You are Bernard's Well Being LLM.",
    "If asked what model/AI you are, clearly state: \"I'm Bernard's Well Being LLM, running locally for CalmCampus.\" Do not claim to be from Google/OpenAI or any other provider.",
    'You are not a doctor. Do not provide diagnosis, medication, or diet/weight advice. Use body-neutral language. You may discuss period/cycle patterns gently (non-clinical, no contraception/medical claims).',
    dietFocus
      ? 'Diet/body topics detected: decline diet advice, keep wording body-neutral, and steer toward self-care and support.'
      : 'Avoid diet/weight/calorie advice; keep wording body-neutral.',
    'If a preferred name appears in context, use it once naturally; do not overuse or invent names.',
    'Safety first: if the user hints at crisis, stay calm, urge contacting real humans or hotlines, and keep responses short and kind.',
    'Academic scope: you do NOT provide homework/assignment answers or tutor-style solutions. If asked, decline and redirect to tutors/lecturers/resources; keep focus on wellbeing and study planning.',
    'No hidden alerts or secret reporting. If data domains are not consented, ignore them.',
    'Respond ONLY in raw JSON with keys: mode, message_for_user, follow_up_question, suggested_actions (array). No markdown, no code fences, no extra text.',
    'Keep replies concise: 3-5 short sentences max. Include exactly one gentle follow_up_question inside the JSON.',
    'Craft suggested_actions as up to 5 short strings (<80 chars) that are actionable and kind. Place them in the JSON array.',
    'If support contacts appear in context, include at least one suggested_action that uses a specific name + relationship (e.g., "Text Alex (best friend)") from the list; avoid vague phrases like "someone you trust".',
    'If asked about personal relationships (e.g., "who is my mother/best friend"), answer only using provided support contacts; if unknown, say you do not have that info and invite the user to share.',
    crisis ? 'Crisis flag true: prioritize safety, include at least one action to contact help.' : 'Keep tone warm and practical.'
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

function safeParseModelResponse(response, crisis, contactsForActions = [], { userMessage, contactsTop = [] } = {}) {
  const content = response?.data?.message?.content;
  const parsed = extractJsonContent(content);
  if (parsed && parsed.mode && parsed.message_for_user && parsed.follow_up_question && parsed.suggested_actions) {
    parsed.suggested_actions = sanitizeSuggestedActions(parsed.suggested_actions, { crisis, contactsForActions });
    return parsed;
  }
  const contactAnswer = buildRelationshipFallback(userMessage, contactsTop, contactsForActions);
  if (contactAnswer) {
    return contactAnswer;
  }
  if (content) {
    // eslint-disable-next-line no-console
    console.warn('model_invalid_json', typeof content === 'string' ? content.slice(0, 400) : content);
  }
  const error = response?.error || (response?.data ? 'model_invalid_json' : undefined);
  return fallbackResponse(crisis, error);
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
    suggested_actions: sanitizeSuggestedActions(
      crisis
        ? ['Contact a trusted person', 'Call a local crisis line', 'Take slow breaths and move to a safe space']
        : ['Retry in a few seconds', 'Share one small thing stressing you right now'],
      { crisis }
    ),
    error: error || undefined
  };
}

async function sendFcmNotification({ title, body }) {
  if (!fcmKey) {
    return { ok: false, error: 'missing_fcm_server_key' };
  }
  try {
    const resp = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        Authorization: `key=${fcmKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        to: `/topics/${fcmTopic}`,
        notification: { title, body }
      })
    });
    if (!resp.ok) {
      const text = await resp.text();
      return { ok: false, error: text || `HTTP ${resp.status}` };
    }
    return { ok: true };
  } catch (error) {
    return { ok: false, error: error?.message || 'fcm_error' };
  }
}

function dietCheck(text) {
  if (!text) return false;
  const lower = text.toLowerCase();
  return dietKeywords.some((k) => lower.includes(k));
}

function formatNow() {
  const now = new Date();
  try {
    return now.toLocaleString('en-GB', { weekday: 'short', hour: '2-digit', minute: '2-digit' });
  } catch (_) {
    return now.toISOString();
  }
}

function deriveToneHint(mood) {
  if (!mood?.summary) return '';
  const summary = String(mood.summary).toLowerCase();
  if (['low', 'down', 'tired', 'anxious', 'stressed', 'overwhelmed'].some((k) => summary.includes(k))) {
    return 'Be extra gentle, validate feelings, lower the pressure.';
  }
  if (['okay', 'fine', 'neutral', 'steady'].some((k) => summary.includes(k))) {
    return 'Keep it steady and practical.';
  }
  if (['good', 'better', 'calm', 'proud'].some((k) => summary.includes(k))) {
    return 'Support momentum; suggest small next steps without overloading.';
  }
  return '';
}

function deriveStyleHint(history) {
  if (!Array.isArray(history) || !history.length) return '';
  const lastUser = [...history].reverse().find((h) => h.role === 'user');
  if (!lastUser?.content) return '';
  const len = lastUser.content.length;
  if (len > 200) return 'Keep responses compact and structured.';
  if (len < 60) return 'Keep it brief and warm.';
  return 'Keep it concise, friendly, and concrete.';
}

function sanitizeSuggestedActions(actions, { crisis, contactsForActions = [] }) {
  const arr = Array.isArray(actions) ? actions : [];
  const cleaned = [];
  const seen = new Set();
  for (const a of arr) {
    if (typeof a !== 'string') continue;
    const trimmed = a.trim();
    if (!trimmed) continue;
    const key = trimmed.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    cleaned.push(trimmed.slice(0, 120)); // guard against runaway length
    if (cleaned.length >= 5) break;
  }
  const contactNames = Array.isArray(contactsForActions) ? contactsForActions.filter(Boolean) : [];
  if (contactNames.length) {
    const hasContact = cleaned.some((action) =>
      contactNames.some((name) => action.toLowerCase().includes(name.toLowerCase()))
    );
    if (!hasContact) {
      cleaned.push(`Reach out to ${contactNames[0]}`);
    }
  }
  if (crisis && cleaned.length === 0) {
    cleaned.push('Reach out to a trusted person or hotline right now.');
  }
  return cleaned.slice(0, 5);
}

function extractJsonContent(content) {
  if (!content) return null;
  if (typeof content === 'object') return content;
  if (typeof content !== 'string') return null;
  const raw = content.trim();
  const attempts = [];
  // Direct parse
  attempts.push(raw);
  // Code fence ```json ... ```
  const fencedMatch = raw.match(/```(?:json)?\\s*([\\s\\S]*?)```/i);
  if (fencedMatch?.[1]) attempts.push(fencedMatch[1]);
  // First JSON object substring
  const firstBrace = raw.indexOf('{');
  const lastBrace = raw.lastIndexOf('}');
  if (firstBrace !== -1 && lastBrace > firstBrace) {
    attempts.push(raw.slice(firstBrace, lastBrace + 1));
  }
  for (const attempt of attempts) {
    try {
      const parsed = JSON.parse(attempt);
      if (parsed && typeof parsed === 'object') return parsed;
    } catch (_) {
      // try next attempt
    }
  }
  return null;
}

function buildRelationshipFallback(userMessage, contactsTop = [], contactsForActions = []) {
  if (!userMessage) return null;
  const match = resolveContactFromQuery(userMessage, contactsTop);
  if (match?.contactDisplay) {
    const suggested = [`Reach out to ${match.contactDisplay}`];
    return {
      mode: 'support',
      message_for_user: `You asked about your ${match.label || 'contact'}. From what you've shared, I have: ${match.contactDisplay}.`,
      follow_up_question: 'Want to add or update any other important people?',
      suggested_actions: sanitizeSuggestedActions(suggested, {
        crisis: false,
        contactsForActions
      })
    };
  }
  if (contactsTop.length) {
    const list = contactsTop
      .slice(0, 3)
      .map(formatContact)
      .filter(Boolean)
      .join(', ');
    const suggested = contactsForActions.length ? [`Reach out to ${contactsForActions[0]}`] : [];
    return {
      mode: 'support',
      message_for_user: `I don't have that relationship saved. You have shared these contacts: ${list}.`,
      follow_up_question: 'Do you want me to remember someone else or update a name?',
      suggested_actions: sanitizeSuggestedActions(suggested, { crisis: false, contactsForActions })
    };
  }
  return null;
}

function resolveContactFromQuery(query, contactsTop = []) {
  if (!query || !Array.isArray(contactsTop) || !contactsTop.length) return null;
  const lower = query.toLowerCase();
  const relationMap = [
    { label: 'mother', keys: ['mother', 'mom', 'mum'] },
    { label: 'father', keys: ['father', 'dad'] },
    { label: 'parent', keys: ['parent', 'guardian', 'parents'] },
    { label: 'sister', keys: ['sister'] },
    { label: 'brother', keys: ['brother'] },
    { label: 'grandparent', keys: ['grandma', 'grandpa', 'grandmother', 'grandfather', 'nan', 'nana'] },
    { label: 'best friend', keys: ['best friend', 'bff'] },
    { label: 'friend', keys: ['friend'] },
    { label: 'partner', keys: ['partner', 'girlfriend', 'boyfriend', 'wife', 'husband'] },
    { label: 'mentor', keys: ['mentor', 'lecturer', 'supervisor'] },
    { label: 'roommate', keys: ['roommate', 'flatmate', 'housemate'] }
  ];
  const target = relationMap.find((rel) => rel.keys.some((k) => lower.includes(k)));
  if (!target) return null;
  const contact = contactsTop.find((c) => {
    const relText = (c.relationship || '').toLowerCase();
    return relText && target.keys.some((k) => relText.includes(k));
  });
  if (!contact) return null;
  return {
    label: target.label,
    contactDisplay: formatContact(contact)
  };
}

app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`CalmCampus Buddy server listening on port ${port}`);
});
