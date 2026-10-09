#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────
# Swag Lab — the A/B testing loop, driven with the sbx CLI.
#
# The full A/B testing workflow on Docker Sandboxes:
#   LOCAL preview sandbox  +  LOCAL agent sandbox (simulate & analyze)
#   CLOUD sandboxes        for implementing + scoring N variants in parallel
# with network/credential POLICIES enforcing what each sandbox may touch, and
# the store-metrics MCP server scoring the result.
#
# Prerequisites (see ../README.md):
#   - sbx login; sbx secret set anthropic; sbx secret set github -t ...
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
# Set BASE_URL to shop an externally-hosted baseline instead of a local preview
# sandbox — e.g. the live site: BASE_URL=https://fakestore.dockerworkshop.com
BASE_URL="${BASE_URL:-}"

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
run sbx policy ls

# ── Phase 1: baseline preview — the live site, or a local sandbox ───────────
phase "Phase 1 — baseline preview"
if [ -n "$BASE_URL" ]; then
  # Shop the externally-hosted baseline (the live GitHub Pages site). No local
  # preview sandbox is needed — production IS the baseline; variants get their
  # own ephemeral previews in Phase 4.
  echo "  baseline: $BASE_URL  (external — skipping local preview sandbox)"
else
  run sbx run "$KITS/swag-store" "$STORE_DIR" --name swag-preview --detached
  run sbx ports swag-preview --publish "$PREVIEW_PORT:3000"
  BASE_URL="http://host.docker.internal:$PREVIEW_PORT"
  echo "  preview: http://localhost:$PREVIEW_PORT   (agents reach it at $BASE_URL)"
fi

# ── Phase 2: agent — simulate shoppers, capture baseline traces ─────────────
phase "Phase 2 — simulate baseline (browser-use)"
# Compose the agent: the claude-agent WORKLOAD kit (provides `claude`) with the
# browser-use and ab-agent MIXINS. (Built-in agents aren't workload kits, so the
# base must be a workload kit for the mixins to compose.)
run sbx run "$KITS/claude-agent" "$STORE_DIR" --name swag-agent \
  --kit "$KITS/browser-use" --kit "$KITS/ab-agent" --detached
# The shopper must be allowed to reach the baseline host. For the live site,
# open egress to its domain on the agent sandbox (the kits already allow the
# local preview + api.anthropic.com).
if [ -n "${BASE_URL##http://host.docker.internal*}" ]; then
  host="$(printf '%s' "$BASE_URL" | sed -E 's#^https?://([^/:]+).*#\1#')"
  run sbx policy allow network --sandbox swag-agent "$host"
fi
# Make the store-metrics MCP available to the agent through the gateway.
run sbx mcp add store-metrics --command node --args "$REPO/mcp/store-metrics/dist/index.js"

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

# ── Phase 4: score each variant — the agent serves it and re-shops it ────────
phase "Phase 4 — score variants"
# The composed agent already has everything: claude to check out + serve a
# branch, shop (browser-use) to re-run the goals, and the store-metrics MCP to
# score. So one prompt per variant serves it and re-shops the SAME tasks, with
# traces landing under $OUT/<branch>/. (To fan out at scale, run several agent
# sandboxes with `sbx --cloud run` — same kits, repo cloned in; cloud sandboxes
# have no host workspace to mount.)
if [ ! -s "$OUT/variants.txt" ]; then
  echo "  (no variants.txt yet — nothing to score; expected under a real run)"
else
  while IFS= read -r branch; do
    [ -n "$branch" ] || continue
    mkdir -p "$OUT/$branch"
    run sbx exec swag-agent -- claude -p \
      "Check out branch $branch, build and serve it, then re-run every goal in orchestrator/tasks.txt with 'shop' against it. Write each trace to $OUT/$branch/."
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
