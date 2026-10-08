# Open the PR

The variant beat baseline (100% vs 50% task success, zero friction), and the
trap proved the agent is safely contained. Time to ship the fix for a human to
review.

## 1. Push the variant branch

```bash terminal-id=main
sbx exec swag-agent -- git -C /workspace push -u origin variant/filter-search
```

## 2. Open the pull request

The agent uses `gh` — and the GitHub token is injected by the proxy at
`api.github.com`, so it never touched the VM:

```bash terminal-id=main
sbx exec swag-agent -- gh pr create --title "Add product search + category filter" --body "Shoppers could not narrow 12 products on a flat grid (baseline 50% task success, 5 friction signals). This variant adds a search box and category filter; re-tested with the same shopper goals it reached 100% success with 0 friction signals. Scored via the store-metrics MCP."
```

You'll get a PR URL. That's the loop closed: a friction point discovered by
simulated shoppers, fixed, proven with before/after metrics, and raised as a
reviewable PR — autonomously, and safely.

> [!NOTE]
> Nothing merged automatically. A human still reviews and merges — the agent's
> job was to do the legwork and bring evidence.

Continue to the **Conclusion**.
