# Anvil Node.js Container
# JavaScript/TypeScript linting and formatting tools
FROM node:18-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install global linting tools
RUN npm install -g \
    eslint@^8.0.0 \
    @typescript-eslint/parser@^6.0.0 \
    @typescript-eslint/eslint-plugin@^6.0.0 \
    eslint-plugin-import@^2.29.0 \
    eslint-plugin-security@^1.7.0 \
    eslint-plugin-promise@^6.1.0 \
    eslint-plugin-unicorn@^48.0.0 \
    eslint-config-prettier@^9.0.0 \
    prettier@^3.0.0 \
    typescript@^5.0.0 \
    npm-check-updates@^16.0.0

# Install audit tools
RUN npm install -g \
    npm-audit-resolver@^3.0.0 \
    audit-ci@^6.6.0

# Create workspace
WORKDIR /workspace

# Copy anvil scripts
COPY scripts/ /anvil/scripts/
RUN chmod +x /anvil/scripts/*

# Default command runs all checks
CMD ["/anvil/scripts/run-nodejs-linting.sh"]