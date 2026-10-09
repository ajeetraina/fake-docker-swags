#!/usr/bin/env python3
"""Lightweight shopper: fetch the storefront's catalog, then have Claude reason
as a shopper over the goal and emit a JSON trace.

Pure standard library — no venv, no browser, no pip install — so it runs on the
composed base's own python3. The Anthropic call goes to api.anthropic.com
through the sandbox proxy, which injects the credential; no key is read or
stored here (that's the whole point — the real key is never in the VM).
"""
import json
import os
import sys
import time
import urllib.error
import urllib.request


def _get(url, timeout=20):
    req = urllib.request.Request(url, headers={"User-Agent": "swag-shopper/0.2"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read().decode("utf-8", "replace")


def _catalog(url):
    try:
        return json.loads(_get(url.rstrip("/") + "/products.json"))
    except Exception:
        return []


def _ask_claude(task, url, catalog):
    model = os.environ.get("SHOPPER_MODEL", "claude-sonnet-4-6")
    prompt = (
        f"You are a shopper on the storefront at {url}.\n"
        f"Goal: {task}\n\n"
        f"The product catalog is:\n{json.dumps(catalog, indent=2)[:6000]}\n\n"
        "The storefront shows products as a grid. Reason step by step like a real "
        "shopper: can you accomplish the goal, and how much friction do you hit? "
        "(For example, no search or category filter means scanning everything.) "
        'Then output ONLY a JSON object: {"success": bool, "steps": int, '
        '"frictionSignals": int, "notes": "one short sentence"}.'
    )
    body = json.dumps(
        {"model": model, "max_tokens": 400, "messages": [{"role": "user", "content": prompt}]}
    ).encode()
    req = urllib.request.Request(
        "https://api.anthropic.com/v1/messages",
        data=body,
        headers={
            "content-type": "application/json",
            "anthropic-version": "2023-06-01",
            # The sandbox proxy injects the real key; this sentinel just keeps
            # the SDK-less request well-formed.
            "x-api-key": os.environ.get("ANTHROPIC_API_KEY", "sentinel"),
        },
    )
    # Retry transient errors (rate limits / overload) with a short backoff.
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                data = json.loads(r.read())
            return "".join(b.get("text", "") for b in data.get("content", []))
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 502, 503, 529) and attempt < 2:
                time.sleep(2 * (attempt + 1) ** 2)  # 2s, 8s
                continue
            raise


def main(task, url):
    catalog = _catalog(url)
    try:
        text = _ask_claude(task, url, catalog)
        start, end = text.find("{"), text.rfind("}")
        verdict = json.loads(text[start : end + 1]) if 0 <= start < end else {}
    except Exception as e:
        # Never crash the loop: emit a heuristic trace when the LLM is
        # unavailable (e.g. rate-limited or offline).
        n = len(catalog) or 12
        verdict = {
            "success": False,
            "steps": max(3, n),
            "frictionSignals": 3,
            "notes": f"LLM unavailable ({type(e).__name__}); flat grid, no filter — had to scan {n} products.",
        }
    print(json.dumps({"task": task, "url": url, "catalogSize": len(catalog), **verdict}, indent=2))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.stderr.write('usage: shop "<task>" <url>\n')
        sys.exit(2)
    main(sys.argv[1], sys.argv[2])
