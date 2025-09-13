#!/bin/bash
# Anvil Installation Script
# Curl-friendly installer: curl -sSL https://raw.githubusercontent.com/doriancuentas/anvil/main/install.sh | bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[ANVIL INSTALL]${NC} $1"
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

# Detect current directory and installation type
INSTALL_DIR="$(pwd)"
TEMP_DIR=""

# Function to cleanup temp directory on exit
cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check for required commands
    for cmd in git curl; do
        if ! command -v "$cmd" &> /dev/null; then
            error "$cmd is required but not installed"
            exit 1
        fi
    done
    
    # Docker check (with helpful message if missing)
    if ! command -v docker &> /dev/null; then
        warn "Docker not found - Anvil containers will not work without Docker"
        echo "Install Docker: https://docs.docker.com/get-docker/"
        echo "You can continue installation, but will need Docker to run quality checks"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    success "Prerequisites checked"
}

# Download Anvil from GitHub
download_anvil() {
    log "Downloading Anvil from GitHub..."
    
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Clone the repository
    if git clone --depth=1 https://github.com/doriancuentas/anvil.git .; then
        success "Anvil downloaded successfully"
    else
        error "Failed to download Anvil from GitHub"
        exit 1
    fi
}

# Detect LLM agent directories
detect_llm_agents() {
    local dirs=""
    
    # Check global directories
    [ -d "$HOME/.claude/agents" ] && dirs="$dirs $HOME/.claude/agents"
    [ -d "$HOME/.gemini/agents" ] && dirs="$dirs $HOME/.gemini/agents"
    [ -d "$HOME/.cursor/agents" ] && dirs="$dirs $HOME/.cursor/agents"
    
    # Check current project directories
    [ -d "$INSTALL_DIR/.claude/agents" ] && dirs="$dirs $INSTALL_DIR/.claude/agents"
    [ -d "$INSTALL_DIR/.gemini/agents" ] && dirs="$dirs $INSTALL_DIR/.gemini/agents"
    [ -d "$INSTALL_DIR/.cursor/agents" ] && dirs="$dirs $INSTALL_DIR/.cursor/agents"
    
    echo "${dirs# }"  # Remove leading space
}

# Install LLM agents
install_agents() {
    local llm_dirs_string
    llm_dirs_string=$(detect_llm_agents)
    
    if [ -z "$llm_dirs_string" ]; then
        warn "No LLM agent directories found"
        log "You can manually copy agents/anvil.md to your LLM agent directory later"
        return 0
    fi
    
    # Convert string to array
    local llm_dirs=($llm_dirs_string)
    
    log "Found LLM agent directories: ${llm_dirs[*]}"
    
    for agent_dir in "${llm_dirs[@]}"; do
        if cp "$TEMP_DIR/agents/anvil.md" "$agent_dir/anvil.md"; then
            success "Installed Anvil agent to: $agent_dir"
        else
            warn "Failed to install agent to: $agent_dir"
        fi
    done
}

# Install Anvil scripts and containers
install_anvil() {
    local target_dir="$INSTALL_DIR/.anvil"
    
    log "Installing Anvil to: $target_dir"
    
    # Create .anvil directory
    mkdir -p "$target_dir"
    
    # Copy essential files
    cp -r "$TEMP_DIR/scripts" "$target_dir/"
    cp -r "$TEMP_DIR/containers" "$target_dir/"
    
    # Make scripts executable
    chmod +x "$target_dir/scripts"/*.sh
    
    # Copy documentation for reference
    cp "$TEMP_DIR/README.md" "$target_dir/"
    
    success "Anvil installed to: $target_dir"
}

# Create convenience wrapper script
create_wrapper() {
    local wrapper_script="$INSTALL_DIR/anvil"
    
    cat > "$wrapper_script" << 'EOF'
#!/bin/bash
# Anvil wrapper script - calls .anvil/scripts/anvil.sh
exec "$(dirname "$0")/.anvil/scripts/anvil.sh" "$@"
EOF
    
    chmod +x "$wrapper_script"
    success "Created convenience wrapper: $wrapper_script"
}

# Display post-install information
show_post_install() {
    echo
    success "🔨 Anvil installation complete!"
    echo
    echo "Quick start:"
    echo "  ./anvil check          # Run quality check"
    echo "  ./anvil setup          # Setup containers"
    echo "  ./anvil help           # Show all commands"
    echo
    echo "Or use the full path:"
    echo "  ./.anvil/scripts/anvil.sh check"
    echo
    
    local llm_dirs_string
    llm_dirs_string=$(detect_llm_agents)
    if [ -n "$llm_dirs_string" ]; then
        echo "LLM Integration:"
        echo "  Anvil agent installed for your LLM tools"
        echo "  Try: 'Run anvil quality check on my project'"
        echo
    fi
    
    if command -v docker &> /dev/null; then
        echo "Next steps:"
        echo "  1. Run './anvil setup' to build containers"
        echo "  2. Run './anvil check' for your first quality check"
    else
        echo "⚠️  Install Docker to use Anvil's containerized tools"
        echo "   https://docs.docker.com/get-docker/"
    fi
    echo
}

# Main installation function
main() {
    echo "🔨 Anvil Installation Script"
    echo "Installing bulletproof development tooling..."
    echo
    
    check_prerequisites
    download_anvil
    install_anvil
    install_agents
    create_wrapper
    show_post_install
}

# Run main function
main "$@"