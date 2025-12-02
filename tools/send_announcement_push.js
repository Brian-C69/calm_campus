#!/usr/bin/env node

/**
 * Simple FCM sender for announcement topic.
 * Usage:
 *   node tools/send_announcement_push.js "YOUR_FCM_SERVER_KEY" "Title here" "Body here"
 */

const fetch = (...args) => import('node-fetch').then(({ default: fetchFn }) => fetchFn(...args));

async function main() {
  const [key, title, body] = process.argv.slice(2);
  if (!key || !title || !body) {
    console.error('Usage: node tools/send_announcement_push.js "BHPMwEXJmUHFlES_gHRZN9buDGsFnmCXT5ib8vIS6S1WkgtsNUz3tQO4JDFNx4MIsA0Po4tba46lNSfhrwEjEjY" "Title" "Body"');
    process.exit(1);
  }

  const resp = await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      'Authorization': `key=${key}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      to: '/topics/announcements',
      notification: { title, body },
    }),
  });

  const text = await resp.text();
  if (!resp.ok) {
    console.error(`FCM error ${resp.status}: ${text}`);
    process.exit(1);
  }

  console.log('FCM sent:', text);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
