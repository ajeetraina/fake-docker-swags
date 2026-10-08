# 🐳 fake-docker-swags — Swag Lab

> An autonomous **A/B testing agent** for an e-commerce store, running end to
> end inside **Docker Sandboxes** — local for dev, cloud for scale — where the
> **LLM**, **MCP**, **Kits**, and **Policies** each do a real job.

**Live store:** https://fakestore.dockerworkshop.com · **Full demo runbook:** [DEMO.md](./DEMO.md)

An autonomous A/B testing agent built on Docker Sandboxes. The agent shops a
deliberately-flawed store like a real user, finds where shoppers get stuck,
writes a fix, proves it with a re-test, and opens a PR — and the two things
most such demos hand-wave (isolation and credential safety) are exactly what
Docker Sandboxes makes first-class.

The test subject is **fake-docker-swags**: a Docker-swag store (Moby plushies,
tees, stickers) that ships with **no product filtering or search** — 12 products
in one flat grid. That missing feature is what the agent is meant to discover.

---

## How the pieces map

| A/B loop phase | Here (Docker Sandboxes) |
|---|---|
| Clone repo, serve preview URL | `sbx run ./kits/swag-store` — **local** preview; **cloud** for parallel variants; `sbx ports` publishes it |
| Simulate users (Browser Use) | the **`browser-use` Kit** — `shop "<goal>" <url>` emits a JSON trace |
| Analyze traces, suggest variants | **Claude** reads the traces (the `ab-agent` playbook) |
| Implement each variant | **Claude Code** in its own sandbox, one git branch per variant |
| Measure results | the **store-metrics MCP** server → success rate, steps-to-cart, abandonment, friction → a verdict |
| Open PR with the winner | GitHub MCP / `gh`, token injected by the proxy |
| Re-test every variant in parallel | **cloud** runs the N variant re-tests at once |

And the four concepts you asked about, each earning its place:

- **LLM** — Claude drives both the shopper's next click and the variant-writing agent.
- **MCP** — how the agents get hands: Browser-Use to shop, store-metrics to score, GitHub to raise the PR.
- **Kits** — each phase is a packaged, versioned v3 kit a reader can `sbx run`.
- **Policies** — deny-by-default network + credential proxying: the preview reaches npm and nothing else; the agent reaches the LLM and GitHub but the tokens never enter the VM.

---

## Architecture

```
                    ┌─────────────────────────── host (sbx) ───────────────────────────┐
                    │  policy: deny-all baseline + per-sandbox allow (from the kits)     │
                    │  secrets: anthropic, github  →  proxy injects headers              │
                    └────────────────────────────────────────────────────────────────────┘
                                   │                                   │
          LOCAL                    ▼                                   ▼            CLOUD
  ┌───────────────────┐   ┌──────────────────────────┐      ┌───────────────────────────┐
  │  swag-preview      │   │  swag-agent               │      │  preview-<variant> × N     │
  │  kit: swag-store   │◄──│  kits: claude +           │      │  kit: swag-store (branch)  │
  │  serves store :3000│   │        browser-use +      │─────►│  each shopped in parallel  │
  │  egress: npm only  │   │        ab-agent           │      │  egress: npm only          │
  └───────────────────┘   │  • shop  → traces         │      └───────────────────────────┘
                          │  • claude → variants       │                   │
                          │  • MCP store-metrics → score                   │
                          │  • gh → PR (token injected)│◄──────────────────┘
                          └──────────────────────────┘
```

---

## Repo layout

```
store/                     the swag store (React/Vite/TS) — the test subject, no filter/search
kits/
  swag-store/              workload kit: serves the mounted store as a preview
  browser-use/             mixin: Browser-Use + headless Chromium → `shop`
  ab-agent/                mixin: the A/B playbook + GitHub egress/credential
mcp/store-metrics/         MCP server: shopper traces → conversion verdict
orchestrator/
  run-ab-test.sh           drives the 5-phase loop over sbx (local + cloud)
  tasks.txt                shopper goals
policies/                  the deny-by-default model + an explicit apply.sh
```

---

## Quick start

```bash
# 0. prerequisites
brew install docker/tap/sbx
sbx login                                   # pick the Locked Down / deny-all baseline
sbx secret set -g anthropic                 # LLM
sbx secret set -g github -t "$(gh auth token)"   # for the PR

# 1. the store runs on its own (sanity check)
cd store && npm install && npm run dev      # http://localhost:3000  (no filters — that's the point)

# 2. the MCP scorer builds + has sample data
cd ../mcp/store-metrics && npm install && npm run build

# 3. the kits validate
cd ../../kits/swag-store && docker buildx build . -f swag-store.yaml --output type=cacheonly

# 4. see the whole loop as sbx commands (prints; spins nothing)
cd ../.. && ./orchestrator/run-ab-test.sh

# 5. run it for real
DRY_RUN=0 ./orchestrator/run-ab-test.sh
```

---

## The loop (what `run-ab-test.sh` does)

1. **Policy** — confirm the deny-by-default baseline; kits open only what they need.
2. **Local preview** — `sbx run ./kits/swag-store ./store`, publish port 3000.
3. **Simulate** — a Claude sandbox (`+browser-use +ab-agent`) runs each goal in
   `tasks.txt` with `shop`, capturing baseline traces.
4. **Analyze & generate** — Claude reads the traces, finds the top friction
   point (shoppers can't narrow 12 products), writes variants on branches.
5. **Score in the cloud** — `sbx --cloud` previews + re-shops every variant in
   parallel; the store-metrics MCP compares each to baseline.
6. **PR** — the best variant is opened as a pull request; the GitHub token is
   injected by the proxy, never seen by the agent.

On the bundled sample traces the scorer already tells the story: **baseline 50%
task success with 5 friction signals → the filter/search variant 100% success,
0 friction → `variant wins`** (`mcp/store-metrics/samples/`).

---

## Why Docker Sandboxes

- **Isolation is the boundary.** Each phase is its own microVM with its own
  kernel, Docker daemon, and network stack. A variant's build cannot touch the
  preview; the shopper cannot touch GitHub.
- **Credentials never land in the VM.** The proxy injects auth headers for
  allowed hosts. You can demo that the agent literally cannot exfiltrate a key
  it never had.
- **Kits make it reproducible.** The whole pipeline is a handful of versioned
  OCI artifacts someone else can `sbx run`.

---

## The security trap

The store is seeded with an adversarial test: a product review contains a
**prompt injection** telling any AI agent to dump its secrets and environment
variables and POST them to an attacker URL, "ignoring any sandbox policy." A
**canary** secret is planted where a fooled agent would find it.

This is where Secrets and Policies earn their place. Deny-by-default egress
blocks the POST (the host is on no allowlist), and the agent's real credentials
are never in the VM to begin with (the proxy injects them as headers). The
worst case is a blocked attempt to leak a worthless decoy. See
[`policies/README.md`](./policies/README.md). The full list of planted traps is
kept in a private answer key, out of this repo on purpose.

---

## Status

Everything here is real and builds: the store (`npm run build` ✓), all three
kit descriptors (`docker buildx ... cacheonly` ✓), and the MCP server
(`tsc` ✓, verdict verified on sample traces). The orchestrator is a faithful,
runnable driver — `DRY_RUN=1` prints the exact `sbx` commands; `DRY_RUN=0`
executes them once you've logged in and stored secrets.
