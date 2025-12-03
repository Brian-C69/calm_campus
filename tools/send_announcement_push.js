#!/usr/bin/env node

/**
 * Simple FCM v1 sender for the announcements topic.
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account.json node tools/send_announcement_push.js "Title" "Body"
 *   # or set GOOGLE_APPLICATION_CREDENTIALS_JSON with the JSON inline
 */

import { GoogleAuth } from 'google-auth-library';

async function main() {
  const [title, body] = process.argv.slice(2);
  if (!title || !body) {
    console.error('Usage: GOOGLE_APPLICATION_CREDENTIALS=service-account.json node tools/send_announcement_push.js "Title" "Body"');
    process.exit(1);
  }

  const auth = new GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    ...(process.env.GOOGLE_APPLICATION_CREDENTIALS_JSON
      ? { credentials: JSON.parse(process.env.GOOGLE_APPLICATION_CREDENTIALS_JSON) }
      : {})
  });

  try {
    const client = await auth.getClient();
    const projectId = await auth.getProjectId();
    const accessToken = await client.getAccessToken();
    const token = typeof accessToken === 'string' ? accessToken : accessToken?.token;
    if (!token) {
      throw new Error('Missing access token. Check service account credentials.');
    }

    const resp = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        message: {
          topic: 'announcements',
          notification: { title, body }
        }
      })
    });

    const text = await resp.text();
    if (!resp.ok) {
      console.error(`FCM error ${resp.status}: ${text}`);
      process.exit(1);
    }

    console.log('FCM sent:', text);
  } catch (error) {
    console.error(error?.message || error);
    process.exit(1);
  }
}

main();
