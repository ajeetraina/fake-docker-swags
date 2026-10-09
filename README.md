# 🐳 fake-docker-swags — Swag Lab

> An autonomous **A/B testing agent** for an e-commerce store, running end to
> end inside **Docker Sandboxes** — local for dev, cloud for scale — where the
> **LLM**, **MCP**, **Kits**, and **Policies** each do a real job.

**Live store:** https://fakestore.dockerworkshop.com · **Full demo runbook:** [DEMO.md](./DEMO.md) · **Workshop:** [simspace/](./simspace)

![Swag Lab loop — simulate, analyze, variant, cloud score, trap blocked, PR](./simspace/lab/swag-lab-slides/assets/swag-lab-demo.gif)

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
          ┌──────────────────────── host (sbx) ─────────────────────────┐
          │  policy: deny-all baseline + per-sandbox allow (from kits)   │
          │  secrets: anthropic, github  →  proxy injects headers        │
          └──────────────────────────────────────────────────────────────┘
                      │                                   │
                      ▼                                   ▼
   ┌─────────────────────────────────┐      ┌────────────────────────────┐
   │  swag-agent  (3 kits composed)  │      │  swag-store  (preview)      │
   │   claude-agent  (workload)      │─────►│  kit: swag-store            │
   │   + browser-use (mixin → shop)  │      │  serves the variant :3000   │
   │   + ab-agent    (mixin)         │      │  egress: npm only           │
   │                                 │      └────────────────────────────┘
   │  • shop      → baseline traces  │
   │  • claude    → variant branch   │          live baseline:
   │  • serve + re-shop → variant run│       fakestore.dockerworkshop.com
   │  • store-metrics MCP → verdict  │
   │  • gh        → PR (token proxied)│
   └─────────────────────────────────┘
```

> Scale out by running several `swag-agent` sandboxes in **Docker Cloud**
> (`sbx --cloud run …`) — same kits, same policies. Cloud sandboxes have no host
> workspace, so the repo is cloned in rather than mounted.

---

## Repo layout

```
store/                     the swag store (React/Vite/TS) — the test subject, no filter/search
kits/
  claude-agent/            workload kit: the Claude agent env (provides `claude`)
  browser-use/             mixin: Browser-Use + headless Chromium → `shop`
  ab-agent/                mixin: the A/B playbook + GitHub egress + canary
  swag-store/              workload kit: serves the store as a preview
mcp/store-metrics/         MCP server: shopper traces → conversion verdict
orchestrator/
  run-ab-test.sh           drives the loop over sbx
  tasks.txt                shopper goals
policies/                  the deny-by-default model + an explicit apply.sh
simspace/                  the slides + hands-on lab (hosted at swaglab.dockerworkshop.com)
```

---

## Quick start

```bash
# 0. prerequisites
brew install docker/tap/sbx
sbx login                                   # pick the Locked Down / deny-all baseline
sbx secret set anthropic                    # LLM
sbx secret set github -t "$(gh auth token)" # for the PR

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

1. **Policy** — `sbx policy ls` shows the deny-by-default baseline; kits open only what they need.
2. **Compose the agent** — `sbx run ./kits/claude-agent ./store --kit ./kits/browser-use --kit ./kits/ab-agent`.
3. **Simulate** — the composed agent runs each goal in `tasks.txt` with `shop`
   against the live store, capturing baseline traces.
4. **Analyze & generate** — Claude reads the traces, finds the top friction
   point (shoppers can't narrow 12 products), writes a variant on a branch.
5. **Score** — the agent serves each variant and re-shops it; the store-metrics
   MCP compares to baseline. (Fan out across cloud sandboxes to scale.)
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

Everything here is real and **tested against `sbx v0.45.1`**:

- the store builds (`npm run build` ✓);
- all four kits build, and the three-kit composition **boots coherently** —
  `sbx run ./kits/claude-agent ./store --kit ./kits/browser-use --kit ./kits/ab-agent`
  comes up with `claude`, `shop`, and the canary env var all present inside ✓;
- the MCP server registers with `sbx mcp add store-metrics --command node --args …` ✓,
  and its verdict is verified on the sample traces (`tsc` ✓).

The orchestrator is a faithful driver — `DRY_RUN=1` prints the exact `sbx`
commands; `DRY_RUN=0` executes them once you've logged in and stored secrets.
