# 🔨 Anvil - Bulletproof Development Tooling

Anvil provides containerized development tools and intelligent LLM integration for consistent code quality across any project.

## ⚡ Quick Start

### One-Line Installation

```bash
# Install Anvil in any project directory
curl -sSL https://raw.githubusercontent.com/doriancuentas/anvil/main/install.sh | bash
```

This will:
- 🔍 Auto-detect LLM agents (Claude Code, Gemini, Cursor)
- 📁 Install Anvil to `.anvil/` directory  
- 🤖 Copy agent definitions to your LLM tools
- ⚡ Create convenience `anvil` wrapper script

### Manual Installation

```bash
# Clone and setup manually
git clone https://github.com/doriancuentas/anvil.git
cd anvil
chmod +x scripts/anvil.sh
./scripts/anvil.sh setup
```

### First Run

```bash
# Run quality check
./anvil check

# Or use full path
./.anvil/scripts/anvil.sh check
```

## 📋 Prerequisites

- **Docker** - Required for containerized tools
- **Git** - For version control integration
- **Python 3.8+** - For environment detection scripts

## 🏗️ What Anvil Does

### 🐳 Containerized Tools
- **Python**: black, isort, flake8, mypy, bandit, safety
- **Node.js**: prettier, eslint, npm audit  
- **Security**: semgrep, OWASP checks, dependency scanning
- **Multi-language**: Go, Rust, Shell script linting

### 🤖 LLM Integration
- Token-efficient: Scripts do heavy work, LLM reads YAML results
- Intelligent decisions based on detected issues
- Orchestrates workflows without re-executing tools

### ⚙️ Smart Environment Detection
- Auto-detects project languages and frameworks
- Suggests environment isolation (venv, nvm, etc.)
- Configures appropriate tooling containers

## 📖 Usage Guide

### Basic Commands

```bash
# Show help
./anvil help

# Run full quality check
./anvil check

# Setup project with Anvil
./anvil setup

# Build specific container
./anvil build linting

# Build all containers
./anvil build

# View last results
./anvil results

# Clean up containers
./anvil clean
```

### Environment Detection

```bash
# Detect project structure and suggest improvements
python3 scripts/env-detect.py --check-versions --suggest-isolation

# Output as JSON
python3 scripts/env-detect.py --format json
```

## 🔧 Configuration

Anvil auto-creates `anvil.yml` on first run. Customize it for your project:

```yaml
project:
  name: "my-project"
  type: "python"  # or "nodejs", "go", "rust", "auto-detect"
  root: "."

containers:
  linting:
    image: "anvil/linting:latest"
    tools: ["black", "isort", "flake8", "mypy"]
  
  security:
    image: "anvil/security:latest" 
    tools: ["bandit", "safety", "semgrep"]

workflows:
  quality_check:
    steps:
      - "env-detect"
      - "security-scan" 
      - "lint-format"
      - "git-status"
    fail_fast: false
```

## 🚀 Integration with LLM Agents

### Claude Code Integration

Copy the Anvil agent to your LLM agent directory:

```bash
# For Claude Code
cp agents/anvil.md ~/.claude/agents/

# For Gemini
cp agents/anvil.md ~/.gemini/agents/

# Or copy to project-specific directory
mkdir -p .claude/agents && cp agents/anvil.md .claude/agents/
```

### Usage in Claude Code

```
User: "Run quality check on my Python project"
Claude: *executes ./anvil check*
Claude: *reads .anvil/results.yml*
Claude: "Found 3 formatting issues (auto-fixed) and 1 security alert in requirements.txt"
```

## 📁 Project Structure

```
anvil/                              # ← Anvil repository
├── anvil.yml                       # Configuration (auto-created)
├── results.yml                     # Latest results (LLM reads this)
├── scripts/
│   ├── anvil.sh                   # Main orchestration script
│   └── env-detect.py              # Environment detection
├── containers/
│   ├── linting/                   # Python/Node linting tools
│   └── security/                  # Security scanning tools
├── agents/
│   └── anvil.md                   # LLM agent definition
└── README.md                      # This file

# When used in projects:
your-project/
├── .claude/agents/                 # ← Copy agent here
│   └── anvil.md                   # Anvil LLM agent
└── src/                           # Your project files
```

## 🏁 Workflow Examples

### Daily Development

```bash
# Before starting work
./anvil check

# After making changes  
./anvil check

# Let LLM agent handle issues
# "Claude, fix the linting issues found by anvil"
```

### CI/CD Integration

```bash
# In your CI pipeline
./anvil check --fail-on-issues

# Or just check without auto-fixing
./anvil check --check-only
```

### New Project Setup

```bash
# Clone project
git clone https://github.com/doriancuentas/anvil.git
cd anvil

# Install Anvil
curl -sSL https://raw.githubusercontent.com/doriancuentas/anvil/main/install.sh | bash

# Setup tooling
./anvil setup

# First quality check
./anvil check
```

## 🐛 Troubleshooting

### Docker Issues

```bash
# Check Docker is running
docker info

# Rebuild containers
./anvil/scripts/anvil.sh clean
./anvil/scripts/anvil.sh build
```

### Missing Tools

Anvil containers provide all tools. If something's missing:

1. Check container builds: `./anvil build`
2. Verify Docker has enough resources
3. Check anvil.yml configuration

### Permission Issues

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Fix container permissions
docker run --rm -v $(pwd):/workspace anvil/linting:latest chown -R $(id -u):$(id -g) /workspace
```

## 🔒 Security

- Containers run with project files mounted read-write
- No network access required for most operations
- Security scans check for known vulnerabilities
- Results stored locally in `anvil/results.yml`

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Run `./anvil check` before committing
4. Submit pull request

## 📄 License

MIT License - see LICENSE file for details

---

**🔨 Anvil: Where code quality is forged**