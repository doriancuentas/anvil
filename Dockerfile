# Use a multi-stage build to keep the final image lean

# ----- Base Image -----
FROM ubuntu:22.04 AS base

# Set non-interactive frontend
ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3.10 \
    python3-pip \
    python3.10-venv \
    && rm -rf /var/lib/apt/lists/*

# ----- Node.js Image -----
FROM node:18 AS nodejs

# Install Node.js tools
RUN npm install -g \
    prettier \
    eslint \
    eslint-plugin-unused-imports

# ----- Final Image -----
FROM base

# Copy Node.js binaries from the nodejs stage
COPY --from=nodejs /usr/local/bin/node /usr/local/bin/
COPY --from=nodejs /usr/local/lib/node_modules/ /usr/local/lib/node_modules/
COPY --from=nodejs /usr/local/bin/npm /usr/local/bin/

# Set up a working directory
WORKDIR /app

# Install Python tools
RUN pip3 install \
    black \
    ruff \
    bandit \
    safety \
    detect-secrets

# Install Semgrep
# Install Semgrep
RUN python3 -m pip install semgrep

# Create a non-root user
RUN useradd -ms /bin/bash user
USER user

# Entrypoint or command
CMD ["bash"]
