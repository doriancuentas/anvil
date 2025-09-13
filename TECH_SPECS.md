
# Anvil Technical Specifications

This document outlines the technical specifications for a simplified and refactored version of the Anvil project.

## 1. Project Vision

Anvil is a powerful, yet simple, containerized tool that ensures code quality and security for any project. It provides a single, intelligent Docker container that automatically detects the project's language and frameworks, and runs a suite of best-practice linters, formatters, and security scanners.

## 2. Core Principles

*   **Simplicity:** A single command to check your code. A single container to manage.
*   **Intelligence:** Automatically detects project type (Python, Node.js, etc.) and applies the correct tools.
*   **Encapsulation:** All dependencies are managed within a single Docker container, preventing conflicts with the host system.
*   **Convention over Configuration:** Sensible defaults are provided, with minimal configuration required.

## 3. Proposed Changes

### 3.1. Unified Docker Container

The current `linting`, `nodejs`, and `security` containers will be merged into a single `anvil` container. This container will include all the necessary tools for linting, formatting, and security scanning for all supported languages.

**Dockerfile:**

*   A new `Dockerfile` will be created in the root of the project.
*   This `Dockerfile` will install all the necessary tools, such as:
    *   **Python:** Ruff, Black, Bandit, Safety
    *   **Node.js:** Prettier, ESLint, `npm audit`
    *   **General:** Semgrep, `detect-secrets`

### 3.2. Simplified Directory Structure

The project structure will be simplified as follows:

```
anvil/
├── Dockerfile
├── anvil.sh
├── install.sh
├── README.md
├── TECH_SPECS.md
└── templates/
    ├── .bandit
    ├── .eslintrc.js
    ├── .gitignore
    ├── .prettierignore
    ├── .prettierrc.json
    ├── pyproject.toml
    └── ruff.toml
```

*   The `containers` and `scripts` directories will be removed.
*   The main `anvil.sh` script will be moved to the root of the project.
*   The `env-detect.py` script will be integrated into the `anvil.sh` script.

### 3.3. Refactored `anvil.sh` Script

The `anvil.sh` script will be the single entry point for the tool. It will be responsible for:

1.  **Building the Docker image:** If the `anvil` image doesn't exist, it will be built automatically.
2.  **Detecting the project environment:** It will analyze the project's files to determine the language and framework.
3.  **Running the tools:** It will execute the appropriate tools inside the `anvil` container.
4.  **Reporting results:** It will output a clear and concise summary of the results.

### 3.4. LLM Integration

The LLM integration will be simplified. Instead of writing results to a YAML file, the `anvil.sh` script will output a clean, human-readable summary that can be easily parsed by an LLM. The `anvil.md` agent definition will be updated to reflect this.

## 4. Recommended Coding Practices and Security Checks

Anvil will enforce the following best practices:

*   **Code Formatting:** Consistent code style using Black for Python and Prettier for Node.js.
*   **Linting:**
    *   **Python:** PEP 8 compliance, unused imports, and other common issues using Ruff.
    *   **Node.js:** Best practices and error prevention using ESLint.
*   **Security:**
    *   **Static Application Security Testing (SAST):** Using Semgrep and Bandit to find security vulnerabilities in the code.
    *   **Dependency Scanning:** Using Safety for Python and `npm audit` for Node.js to find vulnerabilities in dependencies.
    *   **Secret Detection:** Using `detect-secrets` to prevent committing secrets into the repository.

## 5. User Experience

The user experience will be streamlined:

1.  The user runs a single command: `./anvil.sh`
2.  The tool automatically checks the code and provides a summary of the results.
3.  The user can then use the output to fix the issues, or feed it to an LLM for automated remediation.

This simplified approach will make Anvil a much more intuitive and effective tool for maintaining code quality and security.
