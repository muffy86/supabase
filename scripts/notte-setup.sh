#!/usr/bin/env bash
# notte-setup.sh — install and configure Notte browser automation
# Source: https://github.com/nottelabs/notte-skills
set -euo pipefail

echo "==> Notte Browser Automation Setup"

# Install CLI
if command -v brew &>/dev/null; then
  brew tap nottelabs/notte-cli https://github.com/nottelabs/notte-cli.git 2>/dev/null || true
  brew install notte || brew upgrade notte
elif command -v go &>/dev/null; then
  go install github.com/nottelabs/notte-cli/cmd/notte@latest
  echo "  Add ~/go/bin to PATH if not already"
else
  echo "  Install brew (https://brew.sh) or go (https://go.dev/dl/) first"
fi

# Auth
if [ -n "${NOTTE_API_KEY:-}" ]; then
  echo "  NOTTE_API_KEY is set (CI mode)"
elif command -v notte &>/dev/null; then
  notte auth login && notte auth status
else
  echo "  Get API key at https://console.notte.cc then: export NOTTE_API_KEY=notte-..."
fi

# Python SDK
pip install --quiet notte-sdk 2>/dev/null \
  && python3 -c "from notte_sdk import NotteClient; print('  notte-sdk (Python) ready')"

# Official skill
command -v npx &>/dev/null && npx --yes skills add nottelabs/notte-skills

cat <<'EOF'

Quickstart:
  trap 'notte sessions stop --yes 2>/dev/null || true' EXIT
  notte sessions start
  notte page goto "https://app.supabase.com"
  notte page observe
  notte page scrape --instructions "Extract project dashboard summary"
  notte sessions workflow-code   # export as Python SDK code

EOF
echo "==> Done. See https://docs.notte.cc"
