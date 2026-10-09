# Shopper simulator (`shop`)

This sandbox has a `shop` command that acts like a customer browsing a store and
reports where it got stuck.

```bash
shop "Try to find a warm hoodie and add it to your cart." http://<preview> > trace.json
```

- `shop` reads the store's catalog (`<url>/products.json`) and reasons over it as
  a shopper via the agent's LLM, then prints a JSON trace: `success`, `steps`,
  `frictionSignals`, and a short note. Redirect it to a file; the analysis phase
  reads it.
- Write tasks as **goals a shopper has**, not test scripts — "find something
  warm", not "click the Apparel filter". The friction it reports is the signal.
- It runs on the base's `python3` with no extra install, and the LLM call goes
  to `api.anthropic.com` through the proxy — you never see or set the key.
  Override the model with `SHOPPER_MODEL`.
