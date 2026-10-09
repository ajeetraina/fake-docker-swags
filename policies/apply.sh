#!/usr/bin/env bash
# Explicit, auditable form of the per-sandbox network policy. This writes by
# hand the same rules the kits declare via their network-policy@1 capability —
# useful to SEE the containment, but in normal use let the kits carry it.
#
# DRY_RUN defaults to 1 (print, don't apply). Set DRY_RUN=0 to apply.
set -euo pipefail
DRY_RUN="${DRY_RUN:-1}"
run() { if [ "$DRY_RUN" = 1 ]; then printf '  $ %s\n' "$*"; else "$@"; fi; }

echo "== baseline: deny everything globally =="
run sbx policy init deny-all

echo "== swag-preview: npm only =="
run sbx policy allow network --sandbox swag-preview registry.npmjs.org

echo "== swag-agent: LLM + preview + GitHub (tokens injected by proxy) =="
run sbx policy allow network --sandbox swag-agent \
  "api.anthropic.com,github.com,api.github.com,host.docker.internal"

echo "== cloud variant previews: npm only =="
run sbx policy allow network --sandbox "preview-*" registry.npmjs.org

echo "== effective policy =="
run sbx policy ls
