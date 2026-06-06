#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Stop llama-server
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🛑
# @raycast.packageName llama-server

set -euo pipefail

PID_FILE="${HOME}/.local/run/llama-server.pid"

notify() {
  osascript -e "display notification \"$1\" with title \"llama-server\""
}

# ── Check PID file ────────────────────────────────────────────────────────────

if [[ ! -f "$PID_FILE" ]]; then
  notify "llama-server is not running"
  exit 0
fi

pid=$(cat "$PID_FILE")

if ! kill -0 "$pid" 2>/dev/null; then
  notify "llama-server is not running (stale PID file cleaned up)"
  rm -f "$PID_FILE"
  exit 0
fi

# ── Graceful shutdown (SIGTERM), then force if needed ─────────────────────────

notify "Stopping llama-server (PID ${pid})…"
kill -TERM "$pid"

elapsed=0
while kill -0 "$pid" 2>/dev/null; do
  sleep 1
  elapsed=$((elapsed + 1))
  if [[ $elapsed -ge 10 ]]; then
    kill -KILL "$pid" 2>/dev/null || true
    break
  fi
done

rm -f "$PID_FILE"
notify "✅ llama-server stopped"
