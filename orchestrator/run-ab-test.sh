#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────
# Swag Lab — the A/B testing loop, driven with the sbx CLI.
#
# This is the Daytona "A/B GPT" workflow rebuilt on Docker Sandboxes:
#   LOCAL preview sandbox  +  LOCAL agent sandbox (simulate & analyze)
#   CLOUD sandboxes        for implementing + scoring N variants in parallel
# with network/credential POLICIES enforcing what each sandbox may touch, and
# the store-metrics MCP server scoring the result.
#
# Prerequisites (see ../README.md):
#   - sbx login; sbx secret set -g anthropic; sbx secret set -g github -t ...
#   - the kits validate (kits/README.md)
#   - DRY_RUN defaults to 1: the script PRINTS the sbx commands instead of
#     spinning microVMs. Set DRY_RUN=0 to actually run the loop.
# ──────────────────────────────────────────────────────────────────────────
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
STORE_DIR="$REPO/store"
KITS="$REPO/kits"
TASKS="$REPO/orchestrator/tasks.txt"
OUT="$REPO/.runs/$(date +%Y%m%d-%H%M%S 2>/dev/null || echo run)"
PREVIEW_PORT="${PREVIEW_PORT:-8080}"
DRY_RUN="${DRY_RUN:-1}"

# run CMD...  — execute, or just print under DRY_RUN.
run() {
  if [ "$DRY_RUN" = "1" ]; then printf '  $ %s\n' "$*"; else "$@"; fi
}
phase() { printf '\n=== %s ===\n' "$*"; }

mkdir -p "$OUT/baseline"

# ── Phase 0: policy — fail closed, open only what each sandbox needs ─────────
phase "Phase 0 — policies"
# The global baseline is deny-by-default (set once with `sbx policy init
# deny-all`; use `sbx policy reset` to re-baseline). From there the KITS open
# exactly the egress each sandbox needs via their network-policy capability —
# npm for the preview, api.anthropic.com for the agent, github.com for the PR —
# so the descriptors ARE the allowlist and nothing is widened by hand.
# policies/apply.sh shows the equivalent explicit per-sandbox rules.
run sbx policy inspect

# ── Phase 1: LOCAL preview — serve the baseline store ───────────────────────
phase "Phase 1 — local preview (baseline)"
run sbx run "$KITS/swag-store" "$STORE_DIR" --name swag-preview --detached
run sbx ports swag-preview --publish "$PREVIEW_PORT:3000"
BASE_URL="http://host.docker.internal:$PREVIEW_PORT"
echo "  preview: http://localhost:$PREVIEW_PORT   (agents reach it at $BASE_URL)"

# ── Phase 2: LOCAL agent — simulate shoppers, capture baseline traces ───────
phase "Phase 2 — simulate baseline (browser-use)"
# A Claude sandbox composed with both mixins: it can shop AND orchestrate.
run sbx run claude "$STORE_DIR" --name swag-agent \
  --kit "$KITS/browser-use" --kit "$KITS/ab-agent" --detached
# Make the store-metrics MCP available to the agent through the gateway.
run sbx mcp add store-metrics -- node "$REPO/mcp/store-metrics/dist/index.js"

i=0
while IFS= read -r task; do
  case "$task" in ''|\#*) continue;; esac
  i=$((i+1))
  run sbx exec swag-agent -- shop "$task" "$BASE_URL" ">" "$OUT/baseline/task-$i.json"
done < "$TASKS"

# ── Phase 3: analyze + generate variants (the agent, via Claude) ────────────
phase "Phase 3 — analyze & generate variants"
# Hand the agent its playbook + the baseline traces; it finds the top friction
# point and writes 1-3 variants, each on its own git branch under /workspace.
run sbx exec swag-agent -- claude -p \
  "Read $OUT/baseline/*.json against your AB_AGENT playbook. Identify the single biggest friction point and implement up to 3 variants, each on its own branch. Run 'npm run build' per variant. Print the branch names, one per line." \
  ">" "$OUT/variants.txt"

# ── Phase 4: CLOUD — score every variant in parallel ────────────────────────
phase "Phase 4 — score variants in the cloud (parallel)"
# Push the work to the cloud so N variants are previewed + shopped at once,
# instead of serially on one laptop. Each variant gets its own cloud preview
# and its own shopper run; traces land under $OUT/<branch>/.
if [ ! -s "$OUT/variants.txt" ]; then
  echo "  (no variants.txt yet — nothing to score; expected under a real run)"
else
  while IFS= read -r branch; do
    [ -n "$branch" ] || continue
    mkdir -p "$OUT/$branch"
    run sbx --cloud run "$KITS/swag-store" --name "preview-$branch" --new --detached \
      -- --branch "$branch"
    purl="https://preview-$branch.sandbox.cloud"   # cloud preview URL (illustrative)
    j=0
    while IFS= read -r task; do
      case "$task" in ''|\#*) continue;; esac
      j=$((j+1))
      run sbx --cloud exec "preview-$branch" -- shop "$task" "$purl" \
        ">" "$OUT/$branch/task-$j.json"
    done < "$TASKS"
  done < "$OUT/variants.txt"
fi

# ── Phase 5: compare via MCP, open the winning PR ───────────────────────────
phase "Phase 5 — pick the winner & open a PR"
# The agent asks the store-metrics MCP to compare each variant's traces against
# baseline, picks the best lift, and opens a PR. The GitHub token is injected
# by the proxy at api.github.com — it never enters the VM.
run sbx exec swag-agent -- claude -p \
  "For each variant dir under $OUT, call the store-metrics MCP compare_variants against $OUT/baseline. Pick the variant with the best verdict/lift. Open a PR from its branch with gh, summarizing: the friction found, the change, and before/after metrics. If no variant beats baseline, say so and open no PR."

phase "done"
echo "traces + reports under: $OUT"
echo "(DRY_RUN=$DRY_RUN — set DRY_RUN=0 to execute for real)"
