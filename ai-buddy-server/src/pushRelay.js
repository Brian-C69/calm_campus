import cors from 'cors';
import express from 'express';
import { GoogleAuth } from 'google-auth-library';

const app = express();
const port = Number(process.env.PORT || 3000);
const fcmTopic = process.env.FCM_TOPIC || 'announcements';

// Allow inline JSON creds for local dev, otherwise fall back to GOOGLE_APPLICATION_CREDENTIALS file.
const inlineCreds = process.env.GOOGLE_APPLICATION_CREDENTIALS_JSON;
const auth = new GoogleAuth({
  scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  ...(inlineCreds ? { credentials: JSON.parse(inlineCreds) } : {})
});

app.use(cors());
app.use(express.json({ limit: '1mb' }));

app.get('/health', async (_req, res) => {
  try {
    const projectId = await auth.getProjectId();
    res.json({ status: 'ok', topic: fcmTopic, projectId });
  } catch (error) {
    res.status(500).json({ status: 'error', error: error?.message || 'auth_error' });
  }
});

app.post('/notify/announcement', async (req, res) => {
  const { title, body } = req.body || {};
  if (!title || !body) {
    return res.status(400).json({ error: 'title and body are required' });
  }
  try {
    const result = await sendFcmNotification({ title, body });
    if (!result.ok) {
      return res.status(500).json({ error: result.error || 'fcm_error' });
    }
    return res.json({ status: 'sent' });
  } catch (error) {
    return res.status(500).json({ error: error?.message || 'fcm_error' });
  }
});

async function sendFcmNotification({ title, body }) {
  try {
    const client = await auth.getClient();
    const projectId = await auth.getProjectId();
    const accessToken = await client.getAccessToken();
    const token = typeof accessToken === 'string' ? accessToken : accessToken?.token;
    if (!token) {
      return { ok: false, error: 'no_access_token' };
    }

    const resp = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        message: {
          topic: fcmTopic,
          notification: { title, body }
        }
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
