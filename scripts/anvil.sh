#!/bin/bash
# Anvil Main Script - Bulletproof, container-based development tooling
# This script does ALL the work, LLM just reads results

set -euo pipefail

ANVIL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="$(dirname "$ANVIL_DIR")"
CONFIG_FILE="$ANVIL_DIR/anvil.yml"
RESULTS_FILE="$ANVIL_DIR/results.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[ANVIL]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Ensure anvil.yml config exists
ensure_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log "Creating default anvil.yml configuration..."
        cat > "$CONFIG_FILE" << 'EOF'
# Anvil Configuration
# Auto-generated default config
project:
  name: "$(basename "$PROJECT_ROOT")"
  type: "auto-detect"
  root: "."

# Container configuration for isolated tool execution
containers:
  linting:
    image: "anvil/linting:latest"
    build_path: "./anvil/containers/linting"
    tools: ["ruff", "black", "isort", "flake8", "mypy", "bandit", "safety"]
    mount_path: "/workspace"
  
  nodejs:
    image: "anvil/nodejs:latest"
    build_path: "./anvil/containers/nodejs"
    tools: ["eslint", "prettier", "typescript", "npm-audit"]
    mount_path: "/workspace"
  
  security:
    image: "anvil/security:latest" 
    build_path: "./anvil/containers/security"
    tools: ["bandit", "safety", "semgrep", "detect-secrets", "truffleHog"]
    mount_path: "/workspace"
  

# Script execution flow
workflows:
  quality_check:
    steps:
      - "env-detect"
      - "security-scan" 
      - "lint-format"
      - "git-status"
    fail_fast: false

# Tool availability (updated by scripts)
tools:
  python: {}
  security: {}
  git: {}

# Results (populated by scripts)
results:
  last_run: null
  environment: {}
  issues: []
  suggestions: []
  security_alerts: []
EOF
        success "Default configuration created at $CONFIG_FILE"
    fi
}

# Check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker is required but not installed"
        echo "Install Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        error "Docker daemon is not running"
        echo "Start Docker daemon and try again"
        exit 1
    fi
}

# Build container globally if it doesn't exist
build_container() {
    local container_name="$1"
    
    # Enforce no spaces in paths
    if [[ "$container_name" =~ [[:space:]] ]]; then
        error "Container name cannot contain spaces: '$container_name'"
        return 1
    fi
    
    # Check if container already exists
    if docker image inspect "anvil/$container_name:latest" &> /dev/null; then
        log "Container anvil/$container_name already exists, skipping build"
        return 0
    fi
    
    # Find build path - either from current .anvil or from installer temp
    local build_path=""
    if [ -d "$ANVIL_DIR/containers/$container_name" ]; then
        build_path="$ANVIL_DIR/containers/$container_name"
    elif [ -d "$PROJECT_ROOT/.anvil/containers/$container_name" ]; then
        build_path="$PROJECT_ROOT/.anvil/containers/$container_name"
    else
        error "Container build path not found for: $container_name"
        return 1
    fi
    
    log "Building global anvil/$container_name container..."
    cd "$build_path"
    
    # Copy scripts to container build context
    if [ -d "$ANVIL_DIR/scripts" ]; then
        cp -r "$ANVIL_DIR/scripts" ./ 2>/dev/null || true
    elif [ -d "$PROJECT_ROOT/.anvil/scripts" ]; then
        cp -r "$PROJECT_ROOT/.anvil/scripts" ./ 2>/dev/null || true
    fi
    
    if docker build -t "anvil/$container_name:latest" .; then
        success "Global container anvil/$container_name built successfully"
        return 0
    else
        error "Failed to build container anvil/$container_name"
        return 1
    fi
}

# Run containerized command
run_container() {
    local container_name="$1"
    shift
    local cmd="$*"
    
    log "Running $container_name container: $cmd"
    
    # Ensure container exists
    if ! docker image inspect "anvil/$container_name:latest" &> /dev/null; then
        build_container "$container_name" || return 1
    fi
    
    # Run container with project mounted
    docker run --rm \
        -v "$PROJECT_ROOT:/workspace" \
        -v "$ANVIL_DIR:/anvil" \
        -w /workspace \
        "anvil/$container_name:latest" \
        $cmd
}

# Update results YAML with findings
update_results() {
    local category="$1"
    local status="$2"
    local message="$3"
    
    # Create results file if it doesn't exist
    if [ ! -f "$RESULTS_FILE" ]; then
        cat > "$RESULTS_FILE" << EOF
# Anvil Results - Updated by scripts, read by LLM
last_run: "$(date -Iseconds)"
status: "unknown"
issues: []
suggestions: []
security_alerts: []
environment: {}
EOF
    fi
    
    # Simple YAML append (bulletproof, no complex parsing)
    echo "  - category: $category" >> "$RESULTS_FILE"
    echo "    status: $status" >> "$RESULTS_FILE"
    echo "    message: \"$message\"" >> "$RESULTS_FILE"
    echo "    timestamp: \"$(date -Iseconds)\"" >> "$RESULTS_FILE"
}

# Main quality check workflow
run_quality_check() {
    log "Starting quality check workflow..."
    
    # Clear previous results
    > "$RESULTS_FILE"
    cat > "$RESULTS_FILE" << EOF
# Anvil Results - Updated $(date -Iseconds)
last_run: "$(date -Iseconds)"
workflow: "quality_check"
issues: []
suggestions: []
security_alerts: []
environment: {}
EOF
    
    # Step 1: Environment detection
    log "Step 1: Environment detection"
    if python3 "$ANVIL_DIR/scripts/env-detect.py" --format json > "$ANVIL_DIR/env-detection.json"; then
        success "Environment detection completed"
        update_results "environment" "success" "Environment detected successfully"
    else
        error "Environment detection failed"
        update_results "environment" "failed" "Environment detection failed"
        return 1
    fi
    
    # Step 2: Security scan (if tools missing, skip with warning)
    log "Step 2: Security scan"
    if run_container "security" "/anvil/scripts/security-scan.sh"; then
        success "Security scan completed"
        update_results "security" "success" "Security scan completed"
    else
        warn "Security scan failed - tools may be missing"
        update_results "security" "warning" "Security scan failed, tools missing"
    fi
    
    # Step 3: Python linting and formatting
    log "Step 3: Python linting and formatting"
    if run_container "linting" "/anvil/scripts/run-linting.sh"; then
        success "Python linting completed"
        update_results "python_linting" "success" "Python code linting completed"
    else
        warn "Python linting found issues"
        update_results "python_linting" "warning" "Python linting found issues to fix"
    fi
    
    # Step 4: JavaScript/TypeScript linting and formatting
    log "Step 4: JavaScript/TypeScript linting and formatting"
    if run_container "nodejs" "/anvil/scripts/run-nodejs-linting.sh"; then
        success "JavaScript/TypeScript linting completed"
        update_results "js_linting" "success" "JavaScript/TypeScript linting completed"
    else
        warn "JavaScript/TypeScript linting found issues"
        update_results "js_linting" "warning" "JavaScript/TypeScript linting found issues to fix"
    fi
    
    # Step 5: Git status
    log "Step 5: Git status check"
    if [ -d "$PROJECT_ROOT/.git" ]; then
        cd "$PROJECT_ROOT"
        if git status --porcelain | grep -q .; then
            update_results "git" "warning" "Uncommitted changes detected"
        else
            update_results "git" "success" "Working directory clean"
        fi
    else
        update_results "git" "info" "Not a git repository"
    fi
    
    success "Quality check workflow completed"
    log "Results written to: $RESULTS_FILE"
}

# Setup project with Anvil
setup_project() {
    log "Setting up project with Anvil..."
    
    # Build all containers (no spaces in names)
    for container in linting nodejs security; do
        build_container "$container" || warn "Failed to build $container container"
    done
    
    # Setup git hooks if git repo
    if [ -d "$PROJECT_ROOT/.git" ]; then
        log "Setting up git hooks..."
        # This would setup pre-commit hooks, etc.
    fi
    
    success "Anvil setup completed"
}

# Update Anvil installation
update_anvil() {
    log "Updating Anvil installation..."
    
    # Check if we're in a project with .anvil directory
    if [ ! -d "$PROJECT_ROOT/.anvil" ]; then
        error "No .anvil directory found. Run the installer first:"
        echo "curl -sSL https://raw.githubusercontent.com/doriancuentas/anvil/main/install.sh | bash"
        exit 1
    fi
    
    # Backup existing configs if they exist
    local backup_dir="$PROJECT_ROOT/.anvil-backup-$(date +%Y%m%d-%H%M%S)"
    local configs_to_backup=("ruff.toml" "pyproject.toml" ".eslintrc.js" ".prettierrc.json" ".bandit" ".gitignore")
    local has_custom_configs=false
    
    log "Checking for custom configuration files..."
    for config in "${configs_to_backup[@]}"; do
        if [ -f "$PROJECT_ROOT/.anvil/$config" ]; then
            has_custom_configs=true
            break
        fi
    done
    
    if [ "$has_custom_configs" = true ]; then
        echo
        warn "Custom configuration files detected in .anvil/"
        echo "These files may have been manually modified:"
        for config in "${configs_to_backup[@]}"; do
            if [ -f "$PROJECT_ROOT/.anvil/$config" ]; then
                echo "  - $config"
            fi
        done
        echo
        echo "Options:"
        echo "  1) Keep existing configs (recommended if you've made customizations)"
        echo "  2) Replace with latest Anvil templates (get new features/fixes)"
        echo "  3) Backup existing and replace with templates"
        echo
        read -p "Choose option (1/2/3) [1]: " config_choice
        config_choice=${config_choice:-1}
        
        case $config_choice in
            1)
                log "Keeping existing configuration files"
                ;;
            2)
                log "Will replace configs with latest templates"
                ;;
            3)
                log "Creating backup and replacing configs"
                mkdir -p "$backup_dir"
                for config in "${configs_to_backup[@]}"; do
                    if [ -f "$PROJECT_ROOT/.anvil/$config" ]; then
                        cp "$PROJECT_ROOT/.anvil/$config" "$backup_dir/"
                    fi
                done
                success "Configs backed up to: $backup_dir"
                ;;
            *)
                log "Invalid choice, keeping existing configs"
                config_choice=1
                ;;
        esac
    fi
    
    # Clean up old containers
    log "Cleaning up old containers..."
    docker rmi $(docker images "anvil/*" -q) 2>/dev/null || true
    
    # Download latest Anvil from GitHub
    log "Downloading latest Anvil from GitHub..."
    local temp_dir
    temp_dir=$(mktemp -d)
    
    if ! git clone --depth=1 https://github.com/doriancuentas/anvil.git "$temp_dir"; then
        error "Failed to download latest Anvil from GitHub"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Update scripts and containers
    log "Updating Anvil components..."
    cp -r "$temp_dir/scripts/"* "$PROJECT_ROOT/.anvil/scripts/"
    cp -r "$temp_dir/containers/"* "$PROJECT_ROOT/.anvil/containers/"
    
    # Update configs based on user choice
    if [ "$config_choice" = "2" ] || [ "$config_choice" = "3" ]; then
        log "Updating configuration templates..."
        if [ -d "$temp_dir/templates" ]; then
            cp -r "$temp_dir/templates/"* "$PROJECT_ROOT/.anvil/"
        fi
    fi
    
    # Clean up
    rm -rf "$temp_dir"
    
    # Make scripts executable
    chmod +x "$PROJECT_ROOT/.anvil/scripts"/*.sh
    
    success "Anvil updated to latest version"
    
    # Rebuild containers
    log "Rebuilding all containers with latest updates..."
    for container in linting nodejs security; do
        build_container "$container" || warn "Failed to rebuild $container container"
    done
    
    success "All containers rebuilt with latest updates"
    
    if [ "$config_choice" = "3" ]; then
        echo
        success "Update complete! Your old configs are backed up in:"
        echo "  $backup_dir"
    fi
}

# Uninstall Anvil
uninstall_anvil() {
    log "Uninstalling Anvil..."
    
    echo
    warn "This will remove:"
    echo "  - .anvil/ directory and all configurations"
    echo "  - anvil wrapper script"
    echo "  - All Anvil Docker containers"
    echo "  - Anvil LLM agents (if found)"
    echo
    echo "Your project files will NOT be affected."
    echo
    read -p "Are you sure you want to uninstall Anvil? (y/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log "Uninstall cancelled"
        return 0
    fi
    
    local uninstall_errors=0
    
    # Remove .anvil directory
    if [ -d "$PROJECT_ROOT/.anvil" ]; then
        log "Removing .anvil directory..."
        if rm -rf "$PROJECT_ROOT/.anvil"; then
            success "Removed .anvil directory"
        else
            error "Failed to remove .anvil directory"
            uninstall_errors=$((uninstall_errors + 1))
        fi
    fi
    
    # Remove anvil wrapper script
    if [ -f "$PROJECT_ROOT/anvil" ]; then
        log "Removing anvil wrapper script..."
        if rm -f "$PROJECT_ROOT/anvil"; then
            success "Removed anvil wrapper script"
        else
            error "Failed to remove anvil wrapper script"
            uninstall_errors=$((uninstall_errors + 1))
        fi
    fi
    
    # Remove Docker containers
    log "Removing Anvil Docker containers..."
    local containers_removed=0
    if docker images "anvil/*" -q | head -1 | grep -q .; then
        if docker rmi $(docker images "anvil/*" -q) 2>/dev/null; then
            containers_removed=1
            success "Removed Anvil Docker containers"
        else
            warn "Some Docker containers may not have been removed"
        fi
    else
        log "No Anvil Docker containers found"
    fi
    
    # Look for and offer to remove LLM agents
    local agent_dirs=()
    [ -d "$HOME/.claude/agents" ] && agent_dirs+=("$HOME/.claude/agents")
    [ -d "$HOME/.gemini/agents" ] && agent_dirs+=("$HOME/.gemini/agents")
    [ -d "$HOME/.cursor/agents" ] && agent_dirs+=("$HOME/.cursor/agents")
    [ -d "$PROJECT_ROOT/.claude/agents" ] && agent_dirs+=("$PROJECT_ROOT/.claude/agents")
    [ -d "$PROJECT_ROOT/.gemini/agents" ] && agent_dirs+=("$PROJECT_ROOT/.gemini/agents")
    [ -d "$PROJECT_ROOT/.cursor/agents" ] && agent_dirs+=("$PROJECT_ROOT/.cursor/agents")
    
    for agent_dir in "${agent_dirs[@]}"; do
        if [ -f "$agent_dir/anvil.md" ]; then
            log "Found Anvil agent in: $agent_dir"
            read -p "Remove Anvil agent from $agent_dir? (y/N): " remove_agent
            if [[ "$remove_agent" =~ ^[Yy]$ ]]; then
                if rm -f "$agent_dir/anvil.md"; then
                    success "Removed Anvil agent from $agent_dir"
                else
                    error "Failed to remove agent from $agent_dir"
                    uninstall_errors=$((uninstall_errors + 1))
                fi
            fi
        fi
    done
    
    echo
    if [ $uninstall_errors -eq 0 ]; then
        success "🗑️  Anvil uninstalled successfully!"
        echo
        echo "To reinstall Anvil:"
        echo "  curl -sSL https://raw.githubusercontent.com/doriancuentas/anvil/main/install.sh | bash"
    else
        warn "Uninstall completed with $uninstall_errors errors"
        echo "You may need to manually remove some components"
    fi
}

# Show help
show_help() {
    cat << EOF
Anvil - Bulletproof Development Tooling

USAGE:
    $0 <command> [options]

COMMANDS:
    check       Run quality check workflow
    setup       Setup Anvil for this project
    build       Build containers (global, shared across projects)
    rebuild     Force rebuild all containers
    update      Update Anvil installation and rebuild containers
    uninstall   Remove Anvil completely from this project
    clean       Clean up containers and cache
    results     Show last results

EXAMPLES:
    $0 check                # Run full quality check
    $0 setup                # Setup Anvil in project
    $0 build linting        # Build specific container
    $0 rebuild              # Force rebuild all containers
    $0 update               # Update Anvil and rebuild containers
    $0 uninstall            # Remove Anvil completely
    $0 results              # Show last results

The script is designed to be bulletproof:
- Global containers = shared across all projects (efficient)
- Missing tools = containers provide them
- Project configs = mounted as volumes in containers
- Failures = reported, not fixed by LLM
- Results = written to YAML for LLM consumption

EOF
}

# Main command dispatch
main() {
    ensure_config
    check_docker
    
    case "${1:-help}" in
        "check")
            run_quality_check
            ;;
        "setup")
            setup_project
            ;;
        "build")
            if [ -n "${2:-}" ]; then
                build_container "$2"
            else
                for container in linting nodejs security; do
                    build_container "$container"
                done
            fi
            ;;
        "rebuild")
            log "Force rebuilding all containers..."
            docker rmi $(docker images "anvil/*" -q) 2>/dev/null || true
            for container in linting nodejs security; do
                build_container "$container"
            done
            ;;
        "update")
            update_anvil
            ;;
        "uninstall")
            uninstall_anvil
            ;;
        "clean")
            log "Cleaning up Anvil containers..."
            docker rmi $(docker images "anvil/*" -q) 2>/dev/null || true
            ;;
        "results")
            if [ -f "$RESULTS_FILE" ]; then
                cat "$RESULTS_FILE"
            else
                warn "No results file found. Run 'anvil check' first."
            fi
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
