#!/bin/bash
# Bootstrap hook for non-.agents repos.
# Ensures .agents is cloned, then delegates to its master session-start.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

AGENTS_DIR="/home/user/.agents"
MASTER_HOOK="${AGENTS_DIR}/.claude/hooks/session-start.sh"

# Clone .agents if it isn't present in this container
if [ ! -d "${AGENTS_DIR}/.git" ]; then
  git clone https://github.com/muffy86/.agents.git "${AGENTS_DIR}" -q 2>/dev/null || true
fi

# Delegate to master hook
if [ -x "$MASTER_HOOK" ]; then
  exec "$MASTER_HOOK"
else
  echo "[bootstrap] Warning: master hook not found at $MASTER_HOOK" >&2
  exit 1
fi
