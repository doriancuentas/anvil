# Changelog

All notable changes to Anvil will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-09-12

### Added
- 🚀 **One-line installation**: `curl -sSL https://raw.githubusercontent.com/doriancuentas/anvil/main/install.sh | bash`
- 🔍 **Auto-detection** for LLM agent directories (Claude Code, Gemini, Cursor)
- 🤖 **Automatic agent installation** to detected LLM tools
- ⚡ **Convenience wrapper script** - use `./anvil` instead of full path
- 📁 **Clean .anvil installation** - scripts and containers in project subdirectory
- 🛡️ **Claude Code hooks configuration** to prevent linting conflicts
- 🐳 **Containerized development tools** for consistent environments
- 🔧 **Environment detection** with automatic project structure analysis
- 📊 **Structured results output** in YAML format for LLM consumption

### Features
- **Python tooling**: black, isort, flake8, mypy, bandit, safety
- **Node.js tooling**: prettier, eslint, npm audit
- **Security scanning**: semgrep, OWASP checks, dependency scanning
- **Multi-language support**: Go, Rust, Shell script linting
- **Git integration**: Status checks and workflow integration
- **Docker-first approach**: All tools run in containers for consistency

### Installation Methods
- **Curl installer**: One-line installation with auto-detection
- **Manual setup**: Clone repository for development/customization
- **LLM integration**: Automatic agent deployment to LLM tools

### Documentation
- Complete README with installation and usage instructions
- Agent documentation with hooks configuration
- Troubleshooting guide for common issues
- Contributing guidelines for development

### Repository Structure
```
anvil/
├── install.sh              # One-line installer
├── agents/anvil.md         # LLM agent definition
├── scripts/anvil.sh        # Main orchestration script
├── scripts/env-detect.py   # Environment detection
├── containers/             # Docker containers for tools
└── README.md               # Complete documentation
```

### Breaking Changes
- None (initial release)

### Migration Guide
- None (initial release)

---

## How to Update

When a new version is released:

```bash
# Re-run the installer to update
curl -sSL https://raw.githubusercontent.com/doriancuentas/anvil/main/install.sh | bash

# Or manually update
rm -rf .anvil && curl -sSL https://raw.githubusercontent.com/doriancuentas/anvil/main/install.sh | bash
```