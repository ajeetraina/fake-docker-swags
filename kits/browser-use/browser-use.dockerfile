# syntax=docker/dockerfile:1
# Overlay recipe for the browser-use mixin.
#
# It ships only the launcher + the runner. They use the COMPOSED base's own
# python3 (part of the sbx platform floor), so there is no venv to relocate and
# no dangling interpreter symlink — the bug that broke the earlier build-time
# venv overlay (its `bin/python` pointed at /usr/local/bin/python, which does
# not exist on the claude-agent base). A full Chromium can't travel as an
# overlay either (its native libs must be in the running base), so the shopper
# reasons over the storefront's catalog via the Anthropic API instead.
FROM scratch
COPY shopper.py /opt/browser-use/shopper.py
COPY shop /usr/local/bin/shop
