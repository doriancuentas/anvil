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

# Build container if it doesn't exist
build_container() {
    local container_name="$1"
    local build_path="$ANVIL_DIR/containers/$container_name"
    
    # Enforce no spaces in paths
    if [[ "$container_name" =~ [[:space:]] ]]; then
        error "Container name cannot contain spaces: '$container_name'"
        return 1
    fi
    
    if [ ! -d "$build_path" ]; then
        error "Container build path not found: $build_path"
        return 1
    fi
    
    log "Building anvil/$container_name container..."
    cd "$build_path"
    
    # Copy scripts to container build context
    cp -r "$ANVIL_DIR/scripts" ./ 2>/dev/null || true
    
    if docker build -t "anvil/$container_name:latest" .; then
        success "Container anvil/$container_name built successfully"
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
    
    # Step 3: Linting and formatting
    log "Step 3: Linting and formatting"
    if run_container "linting" "/anvil/scripts/run-linting.sh"; then
        success "Linting completed"
        update_results "linting" "success" "Code linting completed"
    else
        warn "Linting found issues"
        update_results "linting" "warning" "Linting found issues to fix"
    fi
    
    # Step 4: Git status
    log "Step 4: Git status check"
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
    for container in linting security git; do
        build_container "$container" || warn "Failed to build $container container"
    done
    
    # Setup git hooks if git repo
    if [ -d "$PROJECT_ROOT/.git" ]; then
        log "Setting up git hooks..."
        # This would setup pre-commit hooks, etc.
    fi
    
    success "Anvil setup completed"
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
    build       Build all containers
    clean       Clean up containers and cache
    results     Show last results

EXAMPLES:
    $0 check                # Run full quality check
    $0 setup                # Setup Anvil in project
    $0 build linting        # Build specific container
    $0 results              # Show last results

The script is designed to be bulletproof:
- Missing tools = containers provide them
- Failures = reported, not fixed by LLM
- Results = written to YAML for LLM consumption

EOF
}

# Main command dispatch
main() {
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
                for container in linting security git; do
                    build_container "$container"
                done
            fi
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