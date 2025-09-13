#!/bin/bash

# Anvil - Simple, Powerful, Containerized Code Quality

# --- Configuration ---
IMAGE_NAME="anvil"

# --- Helper Functions ---

print_info() { echo -e "\033[1;34m[INFO] $1\033[0m"; }
print_success() { echo -e "\033[1;32m[SUCCESS] $1\033[0m"; }
print_warning() { echo -e "\033[1;33m[WARNING] $1\033[0m"; }
print_error() { echo -e "\033[1;31m[ERROR] $1\033[0m"; exit 1; }

# --- Docker Functions ---

build_image() {
    if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
        print_info "Anvil image not found. Building..."
        docker build -t $IMAGE_NAME . > /dev/null || print_error "Failed to build Anvil image."
        print_success "Anvil image built successfully."
    fi
}

# --- Tool Execution ---

run_checks() {
    local command=$1
    print_info "Running $command checks..."

    local project_type=""
    if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
        project_type="python"
    elif [ -f "package.json" ]; then
        project_type="nodejs"
    fi

    if [ -z "$project_type" ]; then
        print_warning "No supported project type detected (Python or Node.js)."
        return
    fi

    local docker_command=""
    case "$project_type-$command" in
        python-lint)
            docker_command="ruff check . && black --check ."
            ;;
        python-security)
            docker_command="bandit -r . && safety check"
            ;;
        nodejs-lint)
            docker_command="npm install && eslint . && prettier --check ."
            ;;
        nodejs-security)
            docker_command="npm audit"
            ;;
        *)
            print_warning "No specific $command checks for $project_type."
            return
            ;;
    esac

    print_info "$project_type project detected. Running checks..."
    docker run --rm -v "$(pwd)":/app $IMAGE_NAME /bin/bash -c "$docker_command" || print_warning "$project_type $command issues found."

}

run_all_checks() {
    run_checks "lint"
    run_checks "security"
    print_info "Running general security checks..."
    docker run --rm -v "$(pwd)":/app $IMAGE_NAME /bin/bash -c "semgrep --config=auto ." || print_warning "Semgrep issues found."
    docker run --rm -v "$(pwd)":/app $IMAGE_NAME /bin/bash -c "detect-secrets scan ." || print_warning "Secrets detected."
    print_success "All checks completed."
}


# --- Help Message ---

show_help() {
    cat << EOF

🔨 Anvil - A simple, containerized tool for code quality and security.

USAGE:
  ./anvil.sh [COMMAND]

COMMANDS:
  (no command)    Run all checks (linting, formatting, and security).
  lint            Run linting and formatting checks.
  security        Run security scans.
  help            Show this help message.

DESCRIPTION:
  Anvil automatically detects the project type (Python or Node.js) and runs a
  suite of best-practice tools within a Docker container. This ensures
  consistent code quality without needing to install tools on your host machine.

EOF
}

# --- Main Logic ---

build_image

case "$1" in
    lint)
        run_checks "lint"
        ;;
    security)
        run_checks "security"
        ;;
    help|--help)
        show_help
        ;;
    ""|*)
        run_all_checks
        ;;
esac