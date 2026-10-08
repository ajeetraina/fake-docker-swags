# Setup

A few minutes of configuration, then you never touch it again.

## 1. Check the CLI

Confirm the Docker Sandboxes CLI is available — it should print a version:

```bash terminal-id=main
sbx version
```

## 2. Authenticate

Log in and choose the **deny-all** baseline policy when prompted (we open only
what each Kit needs):

```bash terminal-id=main
sbx login
```

## 3. Store the agent's credentials

These go into the host keychain. The proxy injects them as auth headers on
allowed hosts — **the raw values never enter a sandbox.**

```bash terminal-id=main
sbx secret set -g anthropic
```

```bash terminal-id=main
sbx secret set -g github -t "$(gh auth token)"
```

> [!IMPORTANT]
> Notice what just happened: your real tokens are now in the **host** keychain,
> not in any VM. Remember this when the trap springs later.

## 4. Confirm the policy baseline

```bash terminal-id=main
sbx policy inspect
```

You should see **deny-by-default** — nothing is reachable until a Kit (or an
explicit rule) allows it.

When the baseline reads `default: deny`, continue to **Meet the store**.
