# Swag Lab — Simspace (slides + hands-on lab)

A self-contained [Simspace/Labspace](https://github.com/dockersamples/simspace)
bundle for this project. It has two cards:

| Card | Kind | Time | What it is |
|------|------|------|------------|
| **Swag Lab — Slides** | `slides` | ~25 min | The talk: the autonomous A/B testing agent, and where LLM / MCP / Kits / Policies each fit. |
| **Swag Lab — Hands-on** | lab | ~45 min | You drive the whole loop in a simulated terminal: simulate → analyze → variant → cloud score → the security trap → PR. |

The hands-on lab runs entirely in the browser via `simulator.yaml` — no real
`sbx` or cloud account needed to follow along. When you want the real thing,
every command maps 1:1 to the live tooling (`../orchestrator/run-ab-test.sh`).

## Preview locally

```bash
cd simspace
docker compose up dev            # http://localhost:5173
# open the "Swag Lab — Slides" card first, then the hands-on lab
```

## Validate

```bash
docker compose run --rm validate  # lints both labs; nonzero exit on errors
```

## Layout

```
simspace/
  compose.yaml                 authoring env (dev preview + validate)
  lab/
    swag-lab-slides/           kind: slides deck
      labspace.yaml
      deck.md
    swag-lab/                  hands-on lab
      labspace.yaml            sections, seeded files, terminals
      simulator.yaml           scripted command behavior
      00-introduction.md … 08-conclusion.md
```

> `labs.json` is generated from each `labspace.yaml` at dev-server start —
> never edit it by hand.
