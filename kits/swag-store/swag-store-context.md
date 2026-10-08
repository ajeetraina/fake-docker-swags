# Swag Store preview environment

This sandbox serves the **fake-docker-swags** storefront mounted at
`/workspace` on port **3000** (Vite dev server, HMR on).

- The store is a React + Vite + TypeScript app. Source lives under
  `/workspace/src`; product data is `src/data/products.json`.
- To expose the preview to the host:
  `sbx ports <this-sandbox> --publish 8080:3000`, then open
  `http://localhost:8080`.
- The service binds `0.0.0.0` — never `127.0.0.1` — so the host proxy can
  reach it.

You are the **preview**, not the editor. The coding agent edits the source in
its own sandbox; your job is only to serve the current state so the
browser-use agent can shop against it.
