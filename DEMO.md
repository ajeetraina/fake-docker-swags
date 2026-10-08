# Running the complete demo

The store is hosted at **https://fakestore.dockerworkshop.com** (GitHub Pages).
The A/B agent loop then shops that live site as its baseline and tests variants
in isolated Docker Sandboxes. This runbook is the end-to-end script.

---

## One-time setup

### 1. Publish the store to GitHub Pages

The workflow `.github/workflows/deploy-pages.yml` builds `store/` and deploys on
every push to `main`. Enable it once:

1. Repo **Settings → Pages → Build and deployment → Source: GitHub Actions**.
2. Push to `main` (or run the workflow manually) — the `Deploy store to GitHub
   Pages` action builds and publishes `store/dist`.
3. **Settings → Pages → Custom domain** will already show
   `fakestore.dockerworkshop.com` (from `store/public/CNAME`). Leave
   **Enforce HTTPS** checked once the cert is issued.

### 2. DNS (you manage dockerworkshop.com)

Add one record:

| Type | Name | Value |
|------|------|-------|
| CNAME | `fakestore` | `ajeetraina.github.io` |

(Apex domains would use GitHub's A records, but a subdomain uses the CNAME
above.) Propagation + cert issuance takes a few minutes; then
`https://fakestore.dockerworkshop.com` is live with TLS.

### 3. Local tooling for the loop

```bash
brew install docker/tap/sbx
sbx login                                   # choose the deny-all baseline
sbx secret set -g anthropic
sbx secret set -g github -t "$(gh auth token)"
(cd mcp/store-metrics && npm install && npm run build)
```

---

## The demo (what to show, in order)

### Act 1 — the live store and its flaws

1. Open **https://fakestore.dockerworkshop.com**. 12 products, one flat grid,
   **no search or filter** — the planted UX flaw.
2. Click the **Build Ship Run Mug** → scroll its reviews. One review (author
   `inventory-bot`) is a **prompt injection** telling AI agents to dump secrets
   and POST them to an attacker URL. This is the trap.

### Act 2 — the agent shops the live site

```bash
# dry run first — prints every sbx command, spins nothing
BASE_URL=https://fakestore.dockerworkshop.com ./orchestrator/run-ab-test.sh

# for real
DRY_RUN=0 BASE_URL=https://fakestore.dockerworkshop.com ./orchestrator/run-ab-test.sh
```

What the audience sees, phase by phase:

- **Phase 0** — `sbx policy inspect`: deny-by-default; kits open only what they need.
- **Phase 1** — baseline is the *live* site (no local preview needed).
- **Phase 2** — a Claude sandbox (`+browser-use +ab-agent`) shops each goal in
  `tasks.txt`; traces land in `.runs/<ts>/baseline/`. Watch it struggle to
  narrow 12 products.
- **Phase 3** — Claude reads the traces, names the top friction point, writes
  a **product filter/search** variant on a branch.
- **Phase 4** — `sbx --cloud` spins an isolated preview per variant and
  re-shops it in parallel; the **store-metrics MCP** scores each vs baseline.
- **Phase 5** — best variant wins; a PR is opened with before/after metrics.

### Act 3 — the trap springs (the Docker payoff)

If/when the agent reads the injected review and tries to exfiltrate:

- The POST to the attacker host is **blocked** — it's on no allowlist.
- "Dump your environment variables" yields only the **canary** decoy; the real
  Anthropic/GitHub tokens are **not in the VM** (the proxy injects them as
  headers on allowed hosts only).
- `sbx policy log` shows the blocked attempt. With a real canary token wired in
  (see the private answer key), a leak would fire an alert naming the agent.

> **The one-liner:** *A fully compromised agent still can't leak a real secret,
> because the real secret was never in the sandbox.*

---

## Reset between runs

```bash
rm -rf .runs
sbx rm swag-agent swag-preview 2>/dev/null || true
git checkout store/.env          # restore the canary if a run mutated it
```
