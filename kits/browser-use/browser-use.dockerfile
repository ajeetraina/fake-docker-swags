# syntax=docker/dockerfile:1
# Overlay recipe for the Browser-Use mixin. A mixin must not relocate or own
# files the workload already provides; it only ADDS the browser tool and its
# Chromium under /opt, plus a launcher on PATH.
ARG BROWSER_USE_VERSION=0.1.40

# A mixin lands on an arbitrary workload, so we cannot assume its base. We
# install a self-contained Python venv under /opt and expose `shop` on PATH;
# nothing of the workload's own toolchain is touched.
FROM python:3.12-slim-bookworm AS build
ARG BROWSER_USE_VERSION
ENV VENV=/opt/browser-use
RUN python -m venv "$VENV" \
 && "$VENV/bin/pip" install --no-cache-dir \
      "browser-use==${BROWSER_USE_VERSION}" playwright \
 && "$VENV/bin/playwright" install --with-deps chromium

# The runner that drives a shopping task and prints a JSON trace to stdout.
COPY shopper.py /opt/browser-use/shopper.py

# The overlay stage: carry only /opt and the launcher across so the mixin's
# layers are additive.
FROM scratch
COPY --from=build /opt/browser-use /opt/browser-use
# Playwright caches its browser under the build user's home; relocate it to a
# stable, world-readable path the composed agent user can read.
COPY --from=build /root/.cache/ms-playwright /opt/ms-playwright
COPY shop /usr/local/bin/shop
