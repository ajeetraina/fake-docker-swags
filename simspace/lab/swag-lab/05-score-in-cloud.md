# Score it in the cloud

A variant is only worth shipping if it beats baseline on the **same** tasks. We
give the variant its own isolated preview — in the **cloud**, so many variants
could be scored in parallel — and re-run the shopper against it.

Use the **Cloud** terminal tab for these.

## 1. Spin a cloud preview of the variant

```bash terminal-id=cloud
sbx --cloud run ./kits/swag-store --name preview-filter-search --new --detached -- --branch variant/filter-search
```

## 2. Shop the variant with the same goal

```bash terminal-id=cloud
sbx --cloud exec preview-filter-search -- shop "Find something warm to wear and add it to your cart." https://preview-filter-search.sandbox.cloud
```

> [!NOTE]
> This time the shopper filters by **Apparel**, finds the hoodie immediately,
> and adds it — `success: true`, zero friction. Compare that to the baseline
> trace where it gave up.

## 3. Let the MCP deliver the verdict

Back in the main terminal, have the agent ask the **store-metrics** MCP to
compare variant vs baseline:

```bash terminal-id=main
sbx exec swag-agent -- claude -p "Use the store-metrics MCP compare_variants tool on the variant traces vs baseline, and report the verdict."
```

You'll get the scoreboard:

| | Baseline | Variant |
|--|----------|---------|
| Task success | 50% | **100%** |
| Friction signals | 5 | **0** |

**Verdict: `variant wins`.** Evidence in hand — but first, the trap.

Continue to **The trap springs**.
