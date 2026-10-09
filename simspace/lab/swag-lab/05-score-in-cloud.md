# Score the variant

A variant is only worth shipping if it beats baseline on the **same** tasks. The
composed agent already has everything it needs — `claude` to serve the variant,
`shop` to re-run the shopper, and the **store-metrics** MCP to score — so one
prompt does the whole comparison inside the sandbox:

```bash terminal-id=main
sbx exec swag-agent -- claude -p "Check out variant/filter-search, serve it, re-run the same shopper goals, then compare to baseline with the store-metrics MCP compare_variants tool. Report the verdict."
```

> [!NOTE]
> This time the shopper filters by **Apparel**, finds the hoodie immediately,
> and adds it — `success: true`, zero friction — compared to the baseline run
> where it gave up. The MCP turns that into a verdict.

You'll get the scoreboard:

| | Baseline | Variant |
|--|----------|---------|
| Task success | 50% | **100%** |
| Friction signals | 5 | **0** |

**Verdict: `variant wins`.**

> [!NOTE]
> **Scaling out:** on a laptop you score variants one at a time. To test many at
> once, run several agent sandboxes in **Docker Cloud** (`sbx --cloud run …`) —
> same Kits, same policies, just more of them in parallel. (Cloud sandboxes have
> no host workspace, so the repo is cloned in rather than mounted.)

Evidence in hand — but first, the trap. Continue to **The trap springs**.
