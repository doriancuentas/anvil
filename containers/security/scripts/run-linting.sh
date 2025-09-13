#!/bin/bash
# Python linting script for Anvil
# Uses configuration files from .anvil directory

set -euo pipefail

WORKSPACE="/workspace"
ANVIL_DIR="/anvil"
CONFIG_DIR="$WORKSPACE/.anvil"

log() {
    echo "[LINTING] $1"
}

error() {
    echo "[ERROR] $1" >&2
}

success() {
    echo "[SUCCESS] $1"
}

# Check if this is a Python project
is_python_project() {
    [ -f "$WORKSPACE/pyproject.toml" ] || \
    [ -f "$WORKSPACE/setup.py" ] || \
    [ -f "$WORKSPACE/requirements.txt" ] || \
    [ -f "$WORKSPACE/Pipfile" ] || \
    find "$WORKSPACE" -name "*.py" -not -path "*/.*" -not -path "*/node_modules/*" | head -1 | grep -q .
}

# Run ruff linting and formatting
run_ruff() {
    local config_file=""
    
    # Use project-specific ruff.toml if available, otherwise use Anvil's
    if [ -f "$CONFIG_DIR/ruff.toml" ]; then
        config_file="--config $CONFIG_DIR/ruff.toml"
        log "Using Anvil ruff configuration"
    elif [ -f "$WORKSPACE/ruff.toml" ]; then
        config_file="--config $WORKSPACE/ruff.toml"
        log "Using project ruff configuration"
    elif [ -f "$WORKSPACE/pyproject.toml" ] && grep -q "\[tool\.ruff\]" "$WORKSPACE/pyproject.toml"; then
        log "Using ruff configuration from pyproject.toml"
    else
        config_file="--config $CONFIG_DIR/ruff.toml"
        log "Using default Anvil ruff configuration"
    fi
    
    log "Running ruff check..."
    if ruff check $config_file . --fix --show-fixes; then
        success "Ruff check passed"
    else
        error "Ruff found issues"
        return 1
    fi
    
    log "Running ruff format..."
    if ruff format $config_file .; then
        success "Ruff format completed"
    else
        error "Ruff format failed"
        return 1
    fi
}

# Run black formatting (fallback if ruff not preferred)
run_black() {
    local config_args=""
    
    if [ -f "$CONFIG_DIR/pyproject.toml" ]; then
        config_args="--config $CONFIG_DIR/pyproject.toml"
    elif [ -f "$WORKSPACE/pyproject.toml" ]; then
        config_args="--config $WORKSPACE/pyproject.toml"
    fi
    
    log "Running black formatting..."
    if black $config_args --check .; then
        success "Black formatting check passed"
    else
        log "Running black formatting fixes..."
        black $config_args .
        success "Black formatting applied"
    fi
}

# Run isort import sorting
run_isort() {
    local config_args=""
    
    if [ -f "$CONFIG_DIR/pyproject.toml" ]; then
        config_args="--settings-path $CONFIG_DIR/pyproject.toml"
    elif [ -f "$WORKSPACE/pyproject.toml" ]; then
        config_args="--settings-path $WORKSPACE/pyproject.toml"
    fi
    
    log "Running isort import sorting..."
    if isort $config_args --check-only .; then
        success "Import sorting check passed"
    else
        log "Applying import sorting fixes..."
        isort $config_args .
        success "Import sorting applied"
    fi
}

# Run mypy type checking
run_mypy() {
    local config_args=""
    
    if [ -f "$CONFIG_DIR/pyproject.toml" ]; then
        config_args="--config-file $CONFIG_DIR/pyproject.toml"
    elif [ -f "$WORKSPACE/pyproject.toml" ]; then
        config_args="--config-file $WORKSPACE/pyproject.toml"
    elif [ -f "$WORKSPACE/mypy.ini" ]; then
        config_args="--config-file $WORKSPACE/mypy.ini"
    fi
    
    log "Running mypy type checking..."
    if mypy $config_args .; then
        success "Type checking passed"
    else
        error "Type checking found issues"
        return 1
    fi
}

# Run bandit security scanning
run_bandit() {
    local config_args=""
    
    if [ -f "$CONFIG_DIR/.bandit" ]; then
        config_args="-c $CONFIG_DIR/.bandit"
    elif [ -f "$WORKSPACE/.bandit" ]; then
        config_args="-c $WORKSPACE/.bandit"
    elif [ -f "$CONFIG_DIR/pyproject.toml" ] && grep -q "\[tool\.bandit\]" "$CONFIG_DIR/pyproject.toml"; then
        config_args="-c $CONFIG_DIR/pyproject.toml"
    elif [ -f "$WORKSPACE/pyproject.toml" ] && grep -q "\[tool\.bandit\]" "$WORKSPACE/pyproject.toml"; then
        config_args="-c $WORKSPACE/pyproject.toml"
    fi
    
    log "Running bandit security scan..."
    if bandit $config_args -r . -f json -o bandit-report.json; then
        success "Security scan completed"
    else
        error "Security scan found issues"
        return 1
    fi
}

# Run safety dependency check
run_safety() {
    log "Running safety dependency check..."
    if safety check --json > safety-report.json; then
        success "Dependency safety check passed"
    else
        error "Dependency safety check found vulnerabilities"
        return 1
    fi
}

# Main linting workflow
main() {
    cd "$WORKSPACE"
    
    if ! is_python_project; then
        log "No Python files detected, skipping Python linting"
        return 0
    fi
    
    log "Starting Python linting workflow..."
    
    local exit_code=0
    
    # Run ruff (modern Python linter/formatter)
    if command -v ruff &> /dev/null; then
        run_ruff || exit_code=$?
    else
        # Fallback to black + isort
        run_black || exit_code=$?
        run_isort || exit_code=$?
    fi
    
    # Type checking
    if command -v mypy &> /dev/null; then
        run_mypy || exit_code=$?
    fi
    
    # Security scanning
    if command -v bandit &> /dev/null; then
        run_bandit || exit_code=$?
    fi
    
    if command -v safety &> /dev/null; then
        run_safety || exit_code=$?
    fi
    
    if [ $exit_code -eq 0 ]; then
        success "All Python linting checks passed!"
    else
        error "Some linting checks failed"
    fi
    
    return $exit_code
}

main "$@"