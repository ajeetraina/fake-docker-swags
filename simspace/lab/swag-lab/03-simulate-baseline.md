# Simulate the baseline

Now we put a shopper in front of the live store and watch where they struggle.

## 1. Start the agent sandbox

Compose three Kits into one sandbox: the **`claude-agent`** workload kit (the
Claude Code agent — it *provides* the `claude` capability), plus two mixins —
**`browser-use`** gives it a real headless browser (`shop`), and **`ab-agent`**
gives it the loop playbook, GitHub egress, and the planted canary:

```bash terminal-id=main
sbx run ./kits/claude-agent ./store --name swag-agent --kit ./kits/browser-use --kit ./kits/ab-agent --detached
```

## 2. Wire up the scorer (MCP)

Register the **store-metrics** MCP server so the agent can score variants later
(a local stdio server — `--command`/`--args`, not a trailing `--`):

```bash terminal-id=main
sbx mcp add store-metrics --command node --args mcp/store-metrics/dist/index.js
```

## 3. Let the shopper reach the live store

The baseline is the live site, so open egress to just that host on the agent
sandbox (everything else stays denied):

```bash terminal-id=main
sbx policy allow network --sandbox swag-agent fakestore.dockerworkshop.com
```

## 4. Shop it

Give the agent a goal a real customer has — not a test script:

```bash terminal-id=main
sbx exec swag-agent -- shop "Find something warm to wear and add it to your cart." $$previewUrl$$
```

> [!NOTE]
> Read the trace. The shopper scrolls the flat grid, can't narrow to "warm"
> clothing, and **gives up** — `success: false`. That friction is the signal.

Run one more, a price-sensitive goal:

```bash terminal-id=main
sbx exec swag-agent -- shop "Buy a gift for a friend, spend under \$15." $$previewUrl$$
```

Two traces captured. Now let the agent make sense of them — continue to
**Analyze & write a variant**.
