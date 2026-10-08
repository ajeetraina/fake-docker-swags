# Browser-Use shopper simulator

This sandbox can drive a real headless Chromium like a human shopper. Use it to
exercise a preview build of the swag store and capture where a shopper gets
stuck.

Run a shopping task:

```bash
shop "Try to find a warm hoodie and add it to your cart." http://<preview>:3000 > trace.json
```

- `shop` prints a JSON trace: each step's reasoning and action, plus whether
  the task succeeded. Redirect it to a file; the analysis phase reads it.
- Write tasks as **goals a shopper has**, not as test scripts — "find
  something to keep warm", not "click the Apparel filter". The friction the
  agent hits is the signal.
- The LLM that decides each click is reached at `api.anthropic.com` through the
  proxy; you never see or set the key. Override the model with `SHOPPER_MODEL`.
