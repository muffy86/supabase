#!/usr/bin/env bash
# Setup OpenTerminal alongside the Supabase local stack
# Gives AI agents a sandboxed shell that can interact with the Supabase workspace
#
# Usage:
#   OPEN_TERMINAL_API_KEY=mysecret bash scripts/setup-open-terminal.sh docker
#   OPEN_TERMINAL_API_KEY=mysecret bash scripts/setup-open-terminal.sh pip

set -euo pipefail

INSTALL_MODE="${1:-docker}"
PORT="${OPEN_TERMINAL_PORT:-8010}"  # 8010 avoids conflict with Supabase Studio on 8000
API_KEY="${OPEN_TERMINAL_API_KEY:-}"

if [[ -z "$API_KEY" ]]; then
  if command -v openssl > /dev/null 2>&1; then
    API_KEY=$(openssl rand -hex 32)
  elif command -v python3 > /dev/null 2>&1; then
    API_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(32))')
  else
    API_KEY=$(LC_ALL=C tr -dc 'a-f0-9' < /dev/urandom | head -c 64)
  fi
  echo "  Generated API key: $API_KEY"
  echo "  Add to .env: OPEN_TERMINAL_API_KEY=$API_KEY"
fi

wait_for_health() {
  local url="$1"
  local tries=0
  echo "  Waiting for OpenTerminal..."
  while [[ $tries -lt 20 ]]; do
    if curl -sf "${url}/health" > /dev/null 2>&1; then
      echo "  Ready."
      return 0
    fi
    sleep 2
    tries=$(( tries + 1 ))
  done
  echo "  Timed out waiting for ${url}/health" >&2
  return 1
}

if [[ "$INSTALL_MODE" == "docker" ]]; then
  docker rm -f supabase-open-terminal > /dev/null 2>&1 || true
  docker run -d \
    --name supabase-open-terminal \
    --restart unless-stopped \
    -p "${PORT}:8000" \
    -e "OPEN_TERMINAL_API_KEY=${API_KEY}" \
    -v supabase_open_terminal_workspace:/workspace \
    ghcr.io/open-webui/open-terminal:latest
  wait_for_health "http://localhost:${PORT}"
  echo "[open-terminal] Running at http://localhost:${PORT}"

elif [[ "$INSTALL_MODE" == "pip" ]]; then
  python3 -m venv .venv-open-terminal
  .venv-open-terminal/bin/pip install --quiet open-terminal
  pkill -f ".venv-open-terminal/bin/open-terminal run" > /dev/null 2>&1 || true
  nohup .venv-open-terminal/bin/open-terminal run \
    --host 0.0.0.0 \
    --port "${PORT}" \
    --api-key "${API_KEY}" \
    > /tmp/open-terminal.log 2>&1 &
  echo "[open-terminal] PID $! | Logs: /tmp/open-terminal.log"
  wait_for_health "http://localhost:${PORT}"
  echo "[open-terminal] Running at http://localhost:${PORT}"

else
  echo "Usage: $0 [docker|pip]"
  exit 1
fi
