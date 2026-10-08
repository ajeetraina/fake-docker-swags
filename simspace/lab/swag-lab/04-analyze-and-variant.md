# Analyze & write a variant

The agent has baseline traces. Now it plays engineer.

## 1. Analyze the friction and write a variant

Hand the agent its playbook and the traces. It identifies the single biggest
friction point and implements a fix on its own branch:

```bash terminal-id=main
sbx exec swag-agent -- claude -p "Read the baseline traces against your AB_AGENT playbook. Find the biggest friction point and implement a variant on its own branch. Run npm run build. Print the branch name."
```

> [!NOTE]
> The agent concludes what we planted: shoppers can't narrow 12 products. It
> writes a **search box + category filter**, on branch
> `variant/filter-search`, and builds it clean.

## 2. Confirm the branch exists

```bash terminal-id=main
sbx exec swag-agent -- git -C /workspace branch
```

You should see `variant/filter-search` alongside `main`.

The agent didn't guess the fix — it derived it from how simulated shoppers
actually behaved. That's the difference between "add filters because we always
do" and "add filters because 50% of shoppers failed without them."

Now prove it helps. Continue to **Score it in the cloud**.
