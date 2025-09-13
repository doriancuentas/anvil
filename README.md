# 🔨 Anvil - Simple, Powerful, Containerized Code Quality

Anvil is a single, intelligent Docker container that automatically detects your project's language and frameworks to lint, format, and scan for security vulnerabilities. No complex configuration, no dependency hell—just straightforward code quality.

## ⚡ Quick Start

### One-Line Installation

```bash
curl -sSL https://raw.githubusercontent.com/doriancuentas/anvil/main/install.sh | bash
```

This will install the `anvil` script to your current directory.

### Run the Check

```bash
./anvil.sh
```

That's it. Anvil will automatically build the necessary Docker image, detect your project's environment, and run the appropriate checks.

## 📋 Prerequisites

- **Docker** - Required to run the Anvil container.

## 🏗️ What Anvil Does

### 🐳 Unified Containerized Tooling

Anvil uses a single Docker container with a comprehensive suite of best-practice tools:

- **Python:** Ruff, Black, Bandit, Safety
- **Node.js:** Prettier, ESLint, `npm audit`
- **General:** Semgrep, `detect-secrets`

This approach ensures consistent results and eliminates the need to install and manage these tools on your host machine.

### 🧠 Smart Environment Detection

Anvil automatically detects the languages and frameworks in your project. It intelligently selects and configures the right tools for your codebase, whether it's a Python script, a Node.js application, or a mix of both.

### ⚙️ Convention over Configuration

Anvil is designed to work out of the box with sensible defaults. It will use the configuration files in the `templates` directory as a base, and you can override them by placing your own configuration files in your project's root directory.

## 📖 Usage Guide

The primary way to use Anvil is with the `anvil.sh` script.

```bash
# Run all checks (linting, formatting, security)
./anvil.sh

# Run only linting and formatting
./anvil.sh --lint

# Run only security scans
./anvil.sh --security

# See all available options
./anvil.sh --help
```

## 🚀 Integration with LLM Agents

Anvil's output is designed to be clean, concise, and easily understood by both humans and LLMs. You can simply copy and paste the output into your favorite LLM and ask it to fix the identified issues.

**Example:**

```
User: "Fix the following issues found by Anvil:"

<paste Anvil output here>
```

## 📁 Project Structure

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

## 🤝 Contributing

1.  Fork the repository.
2.  Create a feature branch.
3.  Run `./anvil.sh` to ensure your changes pass the quality checks.
4.  Submit a pull request.

## 📄 License

MIT License - see LICENSE file for details.

---

**🔨 Anvil: Where code quality is forged**