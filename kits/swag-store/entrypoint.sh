#!/usr/bin/env bash
# Serve the store that is mounted at /workspace. We prefer the fast path
# (a prebuilt dist/) and fall back to the dev server so a freshly-edited
# variant still comes up without a manual build.
set -euo pipefail

cd /workspace

echo "[swag-store] installing dependencies..."
if [ -f package-lock.json ]; then
  npm ci --no-audit --no-fund
else
  npm install --no-audit --no-fund
fi

echo "[swag-store] starting preview on 0.0.0.0:3000"
# dev (HMR) is the right mode for the A/B loop: the agent edits source and the
# preview reflects it with no rebuild step.
exec npm run dev
