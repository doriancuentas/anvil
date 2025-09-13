# 🔨 Anvil - Bulletproof Development Tooling

Anvil provides containerized development tools and intelligent LLM integration for consistent code quality across any project.

## ⚡ Quick Start

```bash
# Install in your project (future - installer coming soon)
curl -sSL https://raw.githubusercontent.com/your-org/anvil/main/install.sh | bash

# Or manually copy anvil/ folder to your project root
cp -r /path/to/anvil ./anvil

# Run quality check
./anvil/scripts/anvil.sh check

# Setup containers and git hooks  
./anvil/scripts/anvil.sh setup
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
./anvil/scripts/anvil.sh help

# Run full quality check
./anvil/scripts/anvil.sh check

# Setup project with Anvil
./anvil/scripts/anvil.sh setup

# Build specific container
./anvil/scripts/anvil.sh build linting

# Build all containers
./anvil/scripts/anvil.sh build

# View last results
./anvil/scripts/anvil.sh results

# Clean up containers
./anvil/scripts/anvil.sh clean
```

### Environment Detection

```bash
# Detect project structure and suggest improvements
python3 anvil/scripts/env-detect.py --check-versions --suggest-isolation

# Output as JSON
python3 anvil/scripts/env-detect.py --format json
```

## 🔧 Configuration

Anvil auto-creates `anvil/anvil.yml` on first run. Customize it for your project:

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

Copy the Anvil agent to Claude Code:

```bash
# Copy agent to .claude/agents/
cp anvil/agents/anvil.md .claude/agents/

# Or install via Claude Code command
# /install-agent anvil
```

### Usage in Claude Code

```
User: "Run quality check on my Python project"
Claude: *executes ./anvil/scripts/anvil.sh check*
Claude: *reads anvil/results.yml*
Claude: "Found 3 formatting issues (auto-fixed) and 1 security alert in requirements.txt"
```

## 📁 Project Structure

```
your-project/
├── anvil/                          # ← Anvil installation (modifiable)
│   ├── anvil.yml                   # Configuration
│   ├── results.yml                 # Latest results (LLM reads this)
│   ├── scripts/
│   │   ├── anvil.sh               # Main orchestration script
│   │   └── env-detect.py          # Environment detection
│   ├── containers/
│   │   ├── linting/               # Python/Node linting tools
│   │   └── security/              # Security scanning tools
│   └── README.md                  # This file
├── .claude/agents/                 # ← LLM agent integration
│   └── anvil.md                   # Anvil LLM agent
└── your-app/                      # Your actual project
    ├── src/
    └── tests/
```

## 🏁 Workflow Examples

### Daily Development

```bash
# Before starting work
./anvil/scripts/anvil.sh check

# After making changes  
./anvil/scripts/anvil.sh check

# Let LLM agent handle issues
# "Claude, fix the linting issues found by anvil"
```

### CI/CD Integration

```bash
# In your CI pipeline
./anvil/scripts/anvil.sh check --fail-on-issues

# Or just check without auto-fixing
./anvil/scripts/anvil.sh check --check-only
```

### New Project Setup

```bash
# Clone project
git clone your-repo
cd your-repo

# Install Anvil
curl -sSL https://install-anvil.sh | bash

# Setup tooling
./anvil/scripts/anvil.sh setup

# First quality check
./anvil/scripts/anvil.sh check
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

1. Check container builds: `./anvil/scripts/anvil.sh build`
2. Verify Docker has enough resources
3. Check anvil.yml configuration

### Permission Issues

```bash
# Make scripts executable
chmod +x anvil/scripts/*.sh

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
3. Run `./anvil/scripts/anvil.sh check` before committing
4. Submit pull request

## 📄 License

MIT License - see LICENSE file for details

---

**🔨 Anvil: Where code quality is forged**