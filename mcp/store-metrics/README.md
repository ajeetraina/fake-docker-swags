# store-metrics MCP server

A small [Model Context Protocol](https://modelcontextprotocol.io) server that
turns Browser-Use shopper traces into conversion signal. The Swag Lab A/B agent
calls it (through the sandbox MCP gateway) to decide whether a variant beats
baseline.

## Tools

| Tool | Input | Returns |
|------|-------|---------|
| `score_trace` | one trace JSON string | per-trace metrics: success, steps, reached-cart, steps-to-cart, friction signals |
| `conversion_report` | a directory of `*.json` traces | per-task metrics + aggregate (success rate, abandonment, friction) |
| `compare_variants` | baseline dir + variant dir | lift on each metric and a `verdict` (`variant wins` / `baseline wins` / `no clear difference`) |

## Build & run

```bash
npm install
npm run build
npm start          # serves MCP over stdio
```

Try it on the bundled fixtures:

```bash
node -e 'import("./dist/metrics.js").then(async m=>{ /* see samples/ */ })'
```

The `samples/` directory holds a baseline run (no filtering — 50% success, lots
of friction) and a `variant-filter` run (search + category filters — 100%
success, zero friction), so you can exercise `compare_variants` without running
the full loop.

## Wiring into a sandbox

Register it as an MCP server for the agent sandbox; `sbx` exposes it to the
agent through the MCP gateway, so the raw server never needs host network
access of its own. The `ab-agent` kit's playbook tells the agent to read
conversion signal from "the store-metrics MCP".
