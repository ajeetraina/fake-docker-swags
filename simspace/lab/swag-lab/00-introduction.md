# Swag Lab — the hands-on loop

An AI agent is about to shop a real store, find what frustrates customers, fix
it, prove the fix works, and open a pull request — and it will do all of that
inside **Docker Sandboxes**, where it *cannot* leak your secrets even if it is
tricked into trying.

Over the next ~45 minutes you will:

1. **Meet the store** — a live Docker-swag shop with a deliberate flaw and a
   hidden trap.
2. **Simulate a shopper** — watch a browser-driving agent get stuck.
3. **Analyze & write a variant** — the agent adds search + filtering.
4. **Score it in the cloud** — compare the variant to baseline on the same
   tasks via an MCP server.
5. **Spring the trap** — a prompt injection tries to exfiltrate secrets, and
   the sandbox policy blocks it.
6. **Open the PR** — ship the winning variant.

> [!NOTE]
> Everything here runs in a **simulated terminal** — no real `sbx` account or
> cloud needed. Every command maps 1:1 to the live tooling in the
> `fake-docker-swags` repo, so what you learn here is exactly what you'd run
> for real.

### The four concepts to watch for

| Concept | Where it shows up |
|---------|-------------------|
| **LLM** | the shopper's clicks *and* the coding agent |
| **MCP** | Browser-Use (shop), store-metrics (score), GitHub (PR) |
| **Kits** | `swag-store`, `browser-use`, `ab-agent` |
| **Policies** | deny-by-default egress + credential proxying |

When you're ready, go to **Setup**.
