# Swag Lab Kits

Four v3 Docker Sandbox kits that make up the A/B testing pipeline. Each is a
self-contained OCI image whose manifest carries the kit descriptor.

| Kit | Kind | Role in the loop |
|-----|------|------------------|
| [`claude-agent`](./claude-agent) | workload | The Claude Code agent environment. **Provides the `claude` capability** that the mixins compose onto. (Vendored from Docker's example with an install-phase egress fix so the build can fetch `claude-code`.) |
| [`browser-use`](./browser-use) | mixin | Adds a `shop "<goal>" <url>` command so the agent can **simulate shoppers** (stdlib on the base's python3 — reasons over the catalog via the LLM; no venv/Chromium to break the overlay). |
| [`ab-agent`](./ab-agent) | mixin | The **orchestration playbook** + GitHub egress/credential + the canary. Requires `claude` + `browser-use`. |
| [`swag-store`](./swag-store) | workload | Serves the mounted storefront on port 3000 — a **preview** a shopper browses. |

> **Why a `claude-agent` workload kit?** The built-in `claude` agent is a
> template image, not a v3 *workload kit*, so custom mixins can't compose onto
> it (`sbx run claude --kit …` → "no workload kit in the set"). A composition
> needs exactly one `kind: workload` that provides `claude`; that's what
> `claude-agent` is.

## Validate / build / run

```bash
# validate a descriptor (fast, no content build)
cd swag-store && docker buildx build . -f swag-store.yaml --output type=cacheonly

# build to an OCI layout and conformance-check it
docker buildx build . -f swag-store.yaml -t swag-store:0.1.0 \
  --output type=oci,dest=/tmp/swag-store-layout,tar=false
kit-tck validate --layout /tmp/swag-store-layout 0.1.0

# run the preview workload (serves ../../store mounted at /workspace)
sbx run ./swag-store ../../store

# run the A/B agent: claude-agent WORKLOAD + the two mixins (tested ✓)
sbx run ./claude-agent ../../store \
  --kit ./browser-use \
  --kit ./ab-agent
```

See the repo [README](../README.md) for the full end-to-end walkthrough.
