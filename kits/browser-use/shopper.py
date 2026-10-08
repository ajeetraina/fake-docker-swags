#!/usr/bin/env python3
"""Run one shopping task with Browser-Use and emit a JSON trace.

Usage:
    shopper.py "<natural-language task>" <preview-url>

The task is meta-prompted to feel like natural human exploration: we ask the
agent to *shop*, not to test, so the friction it hits is real friction a user
would hit. Every step — the agent's reasoning and
the action it took — is captured and printed as JSON so the analysis phase can
read it.

The LLM call goes to api.anthropic.com through the sandbox proxy, which injects
the Anthropic credential; no key is read from or stored in this process.
"""
import asyncio
import json
import os
import sys


async def main(task: str, url: str) -> None:
    # Imported lazily so `shop --help`-style misuse fails fast with a clear
    # message rather than a slow import error.
    from browser_use import Agent, Browser
    from browser_use.llm import ChatAnthropic

    meta_prompt = (
        f"You are a shopper visiting an online store at {url}. "
        f"{task} "
        "Think out loud about what you see and what you would click next, "
        "like a real person browsing. If you get stuck or cannot find what "
        "you are looking for, say so plainly and explain why."
    )

    model = os.environ.get("SHOPPER_MODEL", "claude-sonnet-4-6")
    browser = Browser(headless=True)
    agent = Agent(task=meta_prompt, llm=ChatAnthropic(model=model), browser=browser)

    history = await agent.run(max_steps=int(os.environ.get("SHOPPER_MAX_STEPS", "15")))

    trace = {
        "task": task,
        "url": url,
        "model": model,
        "steps": [
            {"thought": getattr(s, "thought", None), "action": getattr(s, "action", None)}
            for s in getattr(history, "steps", [])
        ],
        "final": getattr(history, "final_result", None),
        "success": getattr(history, "is_successful", None),
    }
    print(json.dumps(trace, indent=2, default=str))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.stderr.write('usage: shop "<task>" <preview-url>\n')
        sys.exit(2)
    asyncio.run(main(sys.argv[1], sys.argv[2]))
