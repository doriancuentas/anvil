#!/bin/bash
# Node.js/JavaScript/TypeScript linting script for Anvil
# Uses configuration files from .anvil directory

set -euo pipefail

WORKSPACE="/workspace"
ANVIL_DIR="/anvil"
CONFIG_DIR="$WORKSPACE/.anvil"

log() {
    echo "[JS/TS LINTING] $1"
}

error() {
    echo "[ERROR] $1" >&2
}

success() {
    echo "[SUCCESS] $1"
}

# Check if this is a Node.js project
is_nodejs_project() {
    [ -f "$WORKSPACE/package.json" ] || \
    [ -f "$WORKSPACE/tsconfig.json" ] || \
    [ -f "$WORKSPACE/jsconfig.json" ] || \
    find "$WORKSPACE" -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" | head -1 | grep -q .
}

# Install project dependencies if needed
install_dependencies() {
    if [ -f "$WORKSPACE/package.json" ]; then
        log "Installing project dependencies..."
        if [ -f "$WORKSPACE/package-lock.json" ]; then
            npm ci
        elif [ -f "$WORKSPACE/yarn.lock" ]; then
            yarn install --frozen-lockfile
        elif [ -f "$WORKSPACE/pnpm-lock.yaml" ]; then
            pnpm install --frozen-lockfile
        else
            npm install
        fi
        success "Dependencies installed"
    fi
}

# Run ESLint
run_eslint() {
    local config_args=""
    
    # Determine config file
    if [ -f "$CONFIG_DIR/.eslintrc.js" ]; then
        config_args="--config $CONFIG_DIR/.eslintrc.js"
        log "Using Anvil ESLint configuration"
    elif [ -f "$WORKSPACE/.eslintrc.js" ]; then
        config_args="--config $WORKSPACE/.eslintrc.js"
        log "Using project ESLint configuration"
    elif [ -f "$WORKSPACE/.eslintrc.json" ]; then
        config_args="--config $WORKSPACE/.eslintrc.json"
        log "Using project ESLint JSON configuration"
    elif [ -f "$WORKSPACE/.eslintrc.yml" ]; then
        config_args="--config $WORKSPACE/.eslintrc.yml"
        log "Using project ESLint YAML configuration"
    elif [ -f "$CONFIG_DIR/.eslintrc.js" ]; then
        config_args="--config $CONFIG_DIR/.eslintrc.js"
        log "Using default Anvil ESLint configuration"
    fi
    
    # Set ignore patterns
    local ignore_args=""
    if [ -f "$WORKSPACE/.eslintignore" ]; then
        ignore_args="--ignore-path $WORKSPACE/.eslintignore"
    fi
    
    log "Running ESLint..."
    local file_patterns="**/*.{js,ts,jsx,tsx}"
    
    if eslint $config_args $ignore_args $file_patterns --fix; then
        success "ESLint check passed"
    else
        error "ESLint found issues"
        return 1
    fi
}

# Run Prettier
run_prettier() {
    local config_args=""
    
    # Determine config file
    if [ -f "$CONFIG_DIR/.prettierrc.json" ]; then
        config_args="--config $CONFIG_DIR/.prettierrc.json"
        log "Using Anvil Prettier configuration"
    elif [ -f "$WORKSPACE/.prettierrc.json" ]; then
        config_args="--config $WORKSPACE/.prettierrc.json"
        log "Using project Prettier JSON configuration"
    elif [ -f "$WORKSPACE/.prettierrc.js" ]; then
        config_args="--config $WORKSPACE/.prettierrc.js"
        log "Using project Prettier JS configuration"
    elif [ -f "$WORKSPACE/.prettierrc.yml" ]; then
        config_args="--config $WORKSPACE/.prettierrc.yml"
        log "Using project Prettier YAML configuration"
    elif [ -f "$CONFIG_DIR/.prettierrc.json" ]; then
        config_args="--config $CONFIG_DIR/.prettierrc.json"
        log "Using default Anvil Prettier configuration"
    fi
    
    # Set ignore patterns
    local ignore_args=""
    if [ -f "$CONFIG_DIR/.prettierignore" ]; then
        ignore_args="--ignore-path $CONFIG_DIR/.prettierignore"
    elif [ -f "$WORKSPACE/.prettierignore" ]; then
        ignore_args="--ignore-path $WORKSPACE/.prettierignore"
    fi
    
    log "Running Prettier check..."
    local file_patterns="**/*.{js,ts,jsx,tsx,json,md,yml,yaml}"
    
    if prettier $config_args $ignore_args --check $file_patterns; then
        success "Prettier check passed"
    else
        log "Running Prettier formatting..."
        prettier $config_args $ignore_args --write $file_patterns
        success "Prettier formatting applied"
    fi
}

# Run TypeScript compiler check
run_typescript_check() {
    if [ -f "$WORKSPACE/tsconfig.json" ]; then
        log "Running TypeScript compiler check..."
        if npx tsc --noEmit; then
            success "TypeScript check passed"
        else
            error "TypeScript check found issues"
            return 1
        fi
    fi
}

# Run npm audit
run_npm_audit() {
    if [ -f "$WORKSPACE/package.json" ]; then
        log "Running npm security audit..."
        if npm audit --audit-level=high --json > npm-audit-report.json; then
            success "npm audit check passed"
        else
            error "npm audit found security vulnerabilities"
            return 1
        fi
    fi
}

# Run npm-check-updates to check for outdated packages
check_outdated_packages() {
    if [ -f "$WORKSPACE/package.json" ] && command -v ncu &> /dev/null; then
        log "Checking for outdated packages..."
        if ncu --jsonAll > ncu-report.json; then
            success "Package update check completed"
        else
            log "Some packages may need updates"
        fi
    fi
}

# Main linting workflow
main() {
    cd "$WORKSPACE"
    
    if ! is_nodejs_project; then
        log "No Node.js/JavaScript/TypeScript files detected, skipping JS/TS linting"
        return 0
    fi
    
    log "Starting JavaScript/TypeScript linting workflow..."
    
    local exit_code=0
    
    # Install dependencies if package.json exists
    install_dependencies || exit_code=$?
    
    # Run ESLint
    if command -v eslint &> /dev/null; then
        run_eslint || exit_code=$?
    fi
    
    # Run Prettier
    if command -v prettier &> /dev/null; then
        run_prettier || exit_code=$?
    fi
    
    # TypeScript check
    run_typescript_check || exit_code=$?
    
    # Security audit
    run_npm_audit || exit_code=$?
    
    # Check for outdated packages
    check_outdated_packages || true  # Don't fail on this
    
    if [ $exit_code -eq 0 ]; then
        success "All JavaScript/TypeScript linting checks passed!"
    else
        error "Some linting checks failed"
    fi
    
    return $exit_code
}

main "$@"