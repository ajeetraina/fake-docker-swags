# claude-agent (workload kit)

The Claude Code agent packaged as a v3 **workload** kit. It exists so the custom
mixins in this repo (`browser-use`, `ab-agent`) have something to compose onto:

- **Why not the built-in `claude` agent?** The built-in agents (`claude`,
  `shell`, …) are template images, not v3 *workload kits*. Composing mixins onto
  one fails: `sbx run claude --kit … → "no workload kit in the set"`. A
  composition needs exactly one `kind: workload`, and `ab-agent` additionally
  `requires` a kit that **provides `claude`** — which this kit does
  (`provides: ["claude@…"]`).
- **Renamed from `claude`** so it doesn't collide with the built-in agent name
  ("built-in agents cannot be overridden by a kit").

## Provenance & the one change

Vendored from Docker's `sandbox-kit-spec/examples/claude`. The **only**
functional change is a one-line fix to the network policy: the build re-pins the
`claude` binary with `curl https://downloads.claude.ai/…` at **install** time,
so `downloads.claude.ai` must be allowed in the `install` phase (it was only in
`runtime`, which caused `curl: (6) couldn't resolve host` during the build).

## Build & compose (tested ✓)

```bash
docker buildx build . -f claude-agent.yaml --output type=cacheonly   # validates + builds
sbx run ./ ../browser-use ../ab-agent   # see kits/README.md for the full compose line
```
