# CalmCampus – Firebase Cloud Messaging (FCM)

This note captures how push notifications work in CalmCampus, how to configure Firebase keys, and how to test topic pushes end-to-end.

## What’s already wired
- App initializes `FirebaseMessagingService` on startup (`main.dart`) and subscribes every device to the `announcements` topic; tokens are re-subscribed on refresh.
- Foreground pushes render via `FlutterLocalNotificationsPlugin` so users see alerts even when the app is open.
- The in-app **FCM Debug** screen (`/debug/fcm`, `lib/pages/fcm_debug_page.dart`) lets you request permission, copy the token, subscribe/unsubscribe to the topic, and trigger a test push.
- Announcements composer (`lib/pages/announcements_page.dart`) can toggle “send notification”; when enabled it calls `/notify/announcement` on the push relay.

## App prerequisites
- Android: keep `android/app/google-services.json` from the Firebase project.  
- iOS/macOS: add the matching `GoogleService-Info.plist` if you build on Apple platforms.  
- Build-time base URL (optional):  
  - `--dart-define=PUSH_BASE_URL=https://your-push-relay` overrides where test pushes are sent.  
  - Falls back to `CHAT_BASE_URL` or `http://bernard.onthewifi.com:3001` if not set.

## Push relay (server side)
- Located at `ai-buddy-server/src/pushRelay.js`; start it with:
  ```sh
  cd ai-buddy-server
  FCM_SERVER_KEY=BHPMwEXJmUHFlES_gHRZN9buDGsFnmCXT5ib8vIS6S1WkgtsNUz3tQO4JDFNx4MIsA0Po4tba46lNSfhrwEjEjY FCM_TOPIC=announcements npm run start:push
  ```
  - `FCM_SERVER_KEY` comes from Firebase console > Project Settings > Cloud Messaging > Server key.
  - `FCM_TOPIC` defaults to `announcements`.
- Quick one-off sender: `node tools/send_announcement_push.js "YOUR_FCM_SERVER_KEY" "Title" "Body"`.
- `scripts/start_push_relay.sh` shows an example environment setup and defaults.

## Testing checklist
1) Launch the app and open **Debug > FCM** (`/debug/fcm`). Request permission and subscribe to topic.  
2) Start the push relay with a valid `FCM_SERVER_KEY`.  
3) Tap “Send test push” in the debug screen, or run the Node sender.  
4) You should see a notification banner; in foreground it comes from local notifications, in background from FCM directly.

## Notes
- All pushes are broadcast to the shared `announcements` topic; no per-user tracking or hidden reporting.  
- Keep the server key in environment variables, not in source control.  
- If pushes fail, verify: permission status, token present, relay URL reachable, server key valid, and that the device is on the `announcements` topic.
