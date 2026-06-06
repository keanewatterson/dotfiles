#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Start llama-server
# @raycast.mode silent
# @raycast.argument1 { "type": "text", "placeholder": "model (default: qwen3)", "optional": true }

# Optional parameters:
# @raycast.icon 🦙
# @raycast.packageName llama-server

set -euo pipefail

LLAMA_SERVER=/opt/homebrew/bin/llama-server
HF_CACHE="${HOME}/.cache/huggingface/hub"
PID_FILE="${HOME}/.local/run/llama-server.pid"
LOG_DIR="${HOME}/.local/log/llama-server"

# ── Model registry ────────────────────────────────────────────────────────────
# Add new models here. Keys are the short names you pass on the command line.
# HF_REPO: the directory name under ~/.cache/huggingface/hub/
# FILE:    the .gguf filename within that repo snapshot

declare -A MODEL_REPO MODEL_FILE MODEL_FLAGS

MODEL_REPO[qwen3]="models--unsloth--DeepSeek-R1-0528-Qwen3-8B-GGUF"
MODEL_FILE[qwen3]="DeepSeek-R1-0528-Qwen3-8B-Q5_K_M.gguf"
MODEL_FLAGS[qwen3]="
  --ctx-size 32768
  --parallel 1
  --threads 4
  --threads-batch 8
  --predict 4096
  --ubatch-size 2048
  --flash-attn auto
  --temperature 0.6
  --top-p 0.95
"

MODEL_REPO[biomistral]="models--QuantFactory--Biomistral-Calme-Instruct-7b-GGUF"
MODEL_FILE[biomistral]="Biomistral-Calme-Instruct-7b.Q5_K_M.gguf"
MODEL_FLAGS[biomistral]="
  --ctx-size 8192
  --parallel 1
  --threads 4
  --threads-batch 8
  --predict 2048
  --ubatch-size 512
  --flash-attn auto
  --temperature 0.7
  --top-p 0.95
"

# ── Helpers ───────────────────────────────────────────────────────────────────

notify() {
  osascript -e "display notification \"$1\" with title \"llama-server\""
}

# ── Resolve model ─────────────────────────────────────────────────────────────

MODEL_KEY="${1:-qwen3}"

if [[ -z "${MODEL_REPO[$MODEL_KEY]+set}" ]]; then
  notify "❌ Unknown model: '${MODEL_KEY}'. Known: ${!MODEL_REPO[*]}"
  exit 1
fi

# ── Guard: already running ────────────────────────────────────────────────────

if [[ -f "$PID_FILE" ]]; then
  existing_pid=$(cat "$PID_FILE")
  if kill -0 "$existing_pid" 2>/dev/null; then
    notify "⚠️ llama-server is already running (PID ${existing_pid}). Stop it first."
    exit 1
  else
    # Stale PID file — clean it up
    rm -f "$PID_FILE"
  fi
fi

# ── Locate model file ─────────────────────────────────────────────────────────

repo_dir="${HF_CACHE}/${MODEL_REPO[$MODEL_KEY]}"
model_path=$(find "$repo_dir" -name "${MODEL_FILE[$MODEL_KEY]}" | head -n1)

if [[ -z "$model_path" ]]; then
  notify "❌ Model file not found: ${MODEL_FILE[$MODEL_KEY]}"
  exit 1
fi

# ── Set up log file ───────────────────────────────────────────────────────────

mkdir -p "$LOG_DIR" "${HOME}/.local/run"
timestamp=$(date '+%Y%m%d-%H%M%S')
log_file="${LOG_DIR}/${MODEL_KEY}-${timestamp}.log"

# ── Launch ────────────────────────────────────────────────────────────────────

notify "Starting llama-server [${MODEL_KEY}]…"

# shellcheck disable=SC2086
nohup "$LLAMA_SERVER" \
  --model "$model_path" \
  --host 0.0.0.0 \
  --port 8080 \
  ${MODEL_FLAGS[$MODEL_KEY]} \
  >> "$log_file" 2>&1 &

echo $! > "$PID_FILE"

# ── Wait for server to accept connections ─────────────────────────────────────

elapsed=0
until curl -sf http://localhost:8080/health &>/dev/null; do
  sleep 2
  elapsed=$((elapsed + 2))
  if [[ $elapsed -ge 60 ]]; then
    notify "⚠️ llama-server did not become ready within 60s — check log: ${log_file}"
    exit 1
  fi
done

notify "✅ llama-server ready [${MODEL_KEY}] — log: $(basename "$log_file")"
