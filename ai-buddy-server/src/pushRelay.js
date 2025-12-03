import cors from 'cors';
import express from 'express';

const app = express();
const port = Number(process.env.PORT || 3000);
const fcmKey =
  process.env.FCM_SERVER_KEY ||
  'BHPMwEXJmUHFlES_gHRZN9buDGsFnmCXT5ib8vIS6S1WkgtsNUz3tQO4JDFNx4MIsA0Po4tba46lNSfhrwEjEjY';
const fcmTopic = process.env.FCM_TOPIC || 'announcements';

app.use(cors());
app.use(express.json({ limit: '1mb' }));

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', topic: fcmTopic });
});

app.post('/notify/announcement', async (req, res) => {
  const { title, body } = req.body || {};
  if (!title || !body) {
    return res.status(400).json({ error: 'title and body are required' });
  }
  if (!fcmKey) {
    return res.status(500).json({ error: 'FCM_SERVER_KEY not set' });
  }
  const result = await sendFcmNotification({ title, body });
  if (!result.ok) {
    return res.status(500).json({ error: result.error || 'fcm_error' });
  }
  return res.json({ status: 'sent' });
});

async function sendFcmNotification({ title, body }) {
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

app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`CalmCampus push relay listening on port ${port}`);
});
