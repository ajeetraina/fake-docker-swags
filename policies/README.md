# Policies — who can reach what

This is the part most agent demos hand-wave and the part Docker Sandboxes makes
first-class. Two controls do the work:

1. **Network policy** — a deny-by-default global baseline, widened per sandbox
   only to the hosts a sandbox genuinely needs.
2. **Credential proxying** — the Anthropic and GitHub secrets live in the host
   keychain; the proxy injects auth headers into outbound requests to the
   allowed hosts. **The raw key never enters the microVM.** A compromised or
   confused agent cannot read a token that isn't there.

## The baseline

Set once (deny everything), then let the kits open what they need:

```bash
sbx policy init deny-all          # one-time; `sbx policy reset` to redo
sbx policy inspect                # effective rules
```

## Who gets what

Each kit declares its own egress via the `network-policy@1` capability, so
composing a kit *is* granting its hosts — scoped to that sandbox, nothing
global.

| Sandbox | Kit(s) | Allowed egress | Credential |
|---------|--------|----------------|------------|
| `swag-preview` | `swag-store` | `registry.npmjs.org` | — |
| `swag-agent` | `claude` + `browser-use` + `ab-agent` | `api.anthropic.com`, the preview host, `github.com`, `api.github.com` | anthropic (inject), github (inject) |
| `preview-<variant>` (cloud) | `swag-store` | `registry.npmjs.org` | — |

The preview sandbox can reach **npm and nothing else** — it cannot phone home,
cannot reach the LLM, cannot reach GitHub. The agent sandbox can reach the LLM
and GitHub but the tokens are never in the VM. That containment is the demo.

## Explicit equivalent

`apply.sh` writes the same rules by hand with `sbx policy allow network
--sandbox ...`, for when you want to see/audit them explicitly rather than let
the kits declare them. Prefer the kit-declared form — it travels with the kit.
