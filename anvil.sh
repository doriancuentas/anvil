#!/bin/bash

# Anvil - Simple, Powerful, Containerized Code Quality

# --- Configuration ---
IMAGE_NAME="anvil"
CONTAINER_NAME="anvil-container"

# --- Helper Functions ---

# Function to print colored output
print_info() {
    echo -e "\033[1;34m[INFO] $1\033[0m"
}

print_success() {
    echo -e "\033[1;32m[SUCCESS] $1\033[0m"
}

print_warning() {
    echo -e "\033[1;33m[WARNING] $1\033[0m"
}

print_error() {
    echo -e "\033[1;31m[ERROR] $1\033[0m"
    exit 1
}

# --- Docker Functions ---

# Function to build the Docker image if it doesn't exist
build_image() {
    if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
        print_info "Anvil image not found. Building..."
        docker build -t $IMAGE_NAME . > /dev/null || print_error "Failed to build Anvil image."
        print_success "Anvil image built successfully."
    fi
}

# --- Tool Execution ---

# Function to run all checks
run_all_checks() {
    print_info "Running all checks..."
    run_lint_checks
    run_security_checks
    print_success "All checks completed."
}

# Function to run linting and formatting checks
run_lint_checks() {
    print_info "Running linting and formatting checks..."

    # Detect project type
    if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
        print_info "Python project detected."
        docker run --rm -v "$(pwd)":/app $IMAGE_NAME /bin/bash -c "ruff check . && black --check ." || print_warning "Python linting/formatting issues found."
    fi

    if [ -f "package.json" ]; then
        print_info "Node.js project detected."
        docker run --rm -v "$(pwd)":/app $IMAGE_NAME /bin/bash -c "npm install && eslint . && prettier --check ." || print_warning "Node.js linting/formatting issues found."
    fi
}

# Function to run security checks
run_security_checks() {
    print_info "Running security checks..."

    # Detect project type
    if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
        print_info "Python project detected."
        docker run --rm -v "$(pwd)":/app $IMAGE_NAME /bin/bash -c "bandit -r . && safety check" || print_warning "Python security issues found."
    fi

    if [ -f "package.json" ]; then
        print_info "Node.js project detected."
        docker run --rm -v "$(pwd)":/app $IMAGE_NAME /bin/bash -c "npm audit" || print_warning "Node.js security issues found."
    fi

    print_info "Running general security checks..."
    docker run --rm -v "$(pwd)":/app $IMAGE_NAME /bin/bash -c "semgrep --config=auto ." || print_warning "Semgrep issues found."
    docker run --rm -v "$(pwd)":/app $IMAGE_NAME /bin/bash -c "detect-secrets scan ." || print_warning "Secrets detected."
}

# --- Main Logic ---

# Build the image first
build_image

# Parse command-line arguments
case "$1" in
    --lint)
        run_lint_checks
        ;;
    --security)
        run_security_checks
        ;;
    --help)
        echo "Usage: ./anvil.sh [ --lint | --security | --help ]"
        ;;
    *)
        run_all_checks
        ;;
esac
