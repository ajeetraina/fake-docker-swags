# syntax=docker/dockerfile:1
# Workload rootfs for the swag-store preview environment.
FROM node:20-bookworm-slim

# The platform floor expects an `agent` user at uid 1000. The node image
# already ships a user at uid 1000 (`node`), so rename it rather than collide.
RUN groupmod -n agent node \
 && usermod -l agent -d /home/agent -m node

WORKDIR /workspace

# The store source is MOUNTED at /workspace at run time (it is not baked in),
# so the coding agent's edits to a variant are served live. The entrypoint
# installs and starts the Vite dev server against whatever is mounted.
COPY entrypoint.sh /usr/local/bin/swag-store-entrypoint
RUN chmod +x /usr/local/bin/swag-store-entrypoint

USER agent
EXPOSE 3000
ENTRYPOINT ["/usr/local/bin/swag-store-entrypoint"]
