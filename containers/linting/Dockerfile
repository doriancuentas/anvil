# Anvil Linting Container
# Self-contained Python linting and formatting tools
FROM python:3.12-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    shellcheck \
    && rm -rf /var/lib/apt/lists/*

# Install Python linting tools
RUN pip install --no-cache-dir \
    ruff==0.6.* \
    black==23.* \
    isort==5.* \
    flake8==6.* \
    mypy==1.* \
    bandit==1.* \
    safety==2.* \
    pre-commit==3.*

# Install additional security tools
RUN pip install --no-cache-dir \
    semgrep \
    pip-audit

# Create workspace
WORKDIR /workspace

# Copy anvil scripts
COPY scripts/ /anvil/scripts/
RUN chmod +x /anvil/scripts/*

# Default command runs all checks
CMD ["/anvil/scripts/run-linting.sh"]