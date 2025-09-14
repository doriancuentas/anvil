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

run_lint_checks() {
    print_info "Running all linting and security checks..."

    local project_type=""
    if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
        project_type="python"
    elif [ -f "package.json" ]; then
        project_type="nodejs"
    elif ls ./*.sh &> /dev/null; then
        project_type="shell"
    fi

    if [ -z "$project_type" ]; then
        print_warning "No supported project type detected (Python, Node.js, or Shell)."
    else
        print_info "$project_type project detected. Running checks..."
        case "$project_type" in
            python)
                docker run --rm -v "$(pwd)":/app $IMAGE_NAME /bin/bash -c "ruff check . && black --check . && bandit -r . && safety check" || print_warning "Python linting/security issues found."
                ;;
            nodejs)
                docker run --rm -v "$(pwd)":/app $IMAGE_NAME /bin/bash -c "npm install && eslint . && prettier --check . && npm audit" || print_warning "Node.js linting/security issues found."
                ;;
            shell)
                docker run --rm -v "$(pwd)":/app $IMAGE_NAME /bin/bash -c "shellcheck *.sh" || print_warning "Shell script linting issues found."
                ;;
        esac
    fi

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
  lint            Run all checks (linting, formatting, and security).
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
        run_lint_checks
        ;;
    help|--help)
        show_help
        ;;
    ""|*)
        run_lint_checks
        ;;
esac
