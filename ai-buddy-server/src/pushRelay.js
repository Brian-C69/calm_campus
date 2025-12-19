import cors from 'cors';
import express from 'express';
import { GoogleAuth } from 'google-auth-library';

const app = express();
const port = Number(process.env.PORT || 3002);
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
  const { title, body, topic } = req.body || {};
  if (!title || !body) {
    return res.status(400).json({ error: 'title and body are required' });
  }
  const targetTopic = topic || fcmTopic;
  try {
    const result = await sendFcmNotification({ title, body, topic: targetTopic });
    if (!result.ok) {
      // eslint-disable-next-line no-console
      console.error('FCM send failed', { topic: targetTopic, error: result.error });
      return res.status(500).json({ error: result.error || 'fcm_error' });
    }
    // eslint-disable-next-line no-console
    console.log('FCM sent', { topic: targetTopic, title });
    return res.json({ status: 'sent', topic: targetTopic });
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('FCM send exception', { topic: targetTopic, error: error?.message || error });
    return res.status(500).json({ error: error?.message || 'fcm_error' });
  }
});

// Direct send to a specific device token (useful for debugging delivery issues).
app.post('/notify/token', async (req, res) => {
  const { title, body, token } = req.body || {};
  if (!title || !body || !token) {
    return res.status(400).json({ error: 'title, body and token are required' });
  }
  try {
    const result = await sendFcmNotification({ title, body, token });
    if (!result.ok) {
      // eslint-disable-next-line no-console
      console.error('FCM token send failed', { token: token.slice(0, 12), error: result.error });
      return res.status(500).json({ error: result.error || 'fcm_error' });
    }
    // eslint-disable-next-line no-console
    console.log('FCM sent to token', { token: token.slice(0, 12), title });
    return res.json({ status: 'sent', token });
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('FCM token send exception', { token: token.slice(0, 12), error: error?.message || error });
    return res.status(500).json({ error: error?.message || 'fcm_error' });
  }
});

async function sendFcmNotification({ title, body, topic = fcmTopic }) {
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
          ...(topic ? { topic } : {}),
          ...(topic ? {} : { token }),
          notification: { title, body }
        }
      })
    });

    if (!resp.ok) {
      const text = await resp.text();
      return { ok: false, error: text || `HTTP ${resp.status}` };
    }
    // Successful HTTP response
    return { ok: true };
  } catch (error) {
    return { ok: false, error: error?.message || 'fcm_error' };
  }
}

app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`CalmCampus push relay listening on port ${port}`);
});
