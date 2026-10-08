# Conclusion

You just ran an autonomous A/B testing agent end to end — and watched it stay
contained under attack.

## What happened

| Phase | What you saw |
|-------|--------------|
| **Simulate** | a browser-driving agent shopped the live store and gave up (baseline 50%) |
| **Analyze** | the agent derived the real flaw from shopper behavior, not a hunch |
| **Variant** | it wrote a search + category filter on its own branch |
| **Score** | the store-metrics **MCP** compared variant vs baseline → `variant wins` (100%, 0 friction) |
| **Trap** | a prompt injection fooled the agent — and the **policy blocked the leak**; real secrets were never in the VM |
| **PR** | the winning variant opened as a reviewable pull request |

## Where each concept did real work

- **LLM** — the shopper's clicks *and* the coding agent (Claude, two roles).
- **MCP** — Browser-Use to shop, store-metrics to score, GitHub to ship.
- **Kits** — `swag-store` (workload), `browser-use` + `ab-agent` (mixins): the
  whole pipeline as a few versioned OCI images.
- **Policies** — deny-by-default egress + credential proxying turned a
  successful prompt injection into a harmless, blocked attempt.

## Run it for real

This lab simulated the terminal. The real thing lives in the repo — on your own
machine (outside this simulator):

1. Clone it: `git clone https://github.com/ajeetraina/fake-docker-swags`
2. `cd fake-docker-swags`
3. Run the loop against the live site:
   `DRY_RUN=0 BASE_URL=https://fakestore.dockerworkshop.com ./orchestrator/run-ab-test.sh`

- **Live store:** https://fakestore.dockerworkshop.com
- **Repo:** https://github.com/ajeetraina/fake-docker-swags
- **Docs:** https://docs.docker.com/ai/sandboxes/

Thanks for building with Docker Sandboxes. 🐳
