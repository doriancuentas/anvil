# Anvil Security Container
# Multi-language security scanning tools
FROM python:3.12-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    jq \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Install Python security tools
RUN pip install --no-cache-dir \
    bandit==1.* \
    safety==2.* \
    pip-audit==2.* \
    semgrep==1.*

# Install Node.js security tools globally
RUN npm install -g \
    audit-ci@^6.6.0 \
    retire@^4.0.0

# Install additional security scanners
RUN pip install --no-cache-dir \
    detect-secrets==1.*

# Create workspace
WORKDIR /workspace

# Copy anvil scripts
COPY scripts/ /anvil/scripts/
RUN chmod +x /anvil/scripts/*

# Default command runs security scan
CMD ["/anvil/scripts/security-scan.sh"]