#!/usr/bin/env bash

# Simple helper to run the FCM push relay on port 3000.
# Usage:
#   FCM_SERVER_KEY="YOUR_FCM_SERVER_KEY" ./scripts/start_push_relay.sh
# Optional:
#   PORT=3000 FCM_TOPIC=announcements ./scripts/start_push_relay.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR/ai-buddy-server"

if [[ -z "${FCM_SERVER_KEY:-}" ]]; then
  echo "ERROR: FCM_SERVER_KEY is not set. Export your Firebase server key from the calmcampus-4e3c4 project." >&2
  exit 1
fi

export PORT="${PORT:-3002}"
export FCM_TOPIC="${FCM_TOPIC:-announcements}"

echo "Starting push relay on port ${PORT}, topic ${FCM_TOPIC}..."
npm run start:push
