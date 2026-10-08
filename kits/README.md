# Swag Lab Kits

Three v3 Docker Sandbox kits that make up the A/B testing pipeline. Each is a
self-contained OCI image whose manifest carries the kit descriptor.

| Kit | Kind | Role in the loop |
|-----|------|------------------|
| [`swag-store`](./swag-store) | workload | Serves the mounted storefront on port 3000 — the **preview** a shopper browses. |
| [`browser-use`](./browser-use) | mixin | Adds Browser-Use + headless Chromium so an agent sandbox can **simulate shoppers** (`shop "<goal>" <url>`). |
| [`ab-agent`](./ab-agent) | mixin | The **orchestration playbook** + GitHub egress/credential to raise the winning variant as a PR. Composes onto `claude` + `browser-use`. |

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

# run Claude as the A/B agent, composing both mixins
sbx run claude ../../store \
  --kit ./browser-use \
  --kit ./ab-agent
```

See the repo [README](../README.md) for the full end-to-end walkthrough.
