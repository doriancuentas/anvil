# Claude Code Configuration

## Hooks Configuration

Configure these hooks to prevent conflicts with Anvil tooling:

```yaml
hooks:
  user_prompt_submit:
    # Skip git operations to avoid conflicts with Anvil
    - command: "echo 'Anvil handles git status - skipping automatic git operations'"
    - prevent: ["git add", "git commit", "git push"]

  tool_use_pre:
    # Skip automatic linting - let Anvil handle it
    - command: "echo 'Using Anvil for code quality checks'"
    - prevent: ["lint", "format", "prettier", "eslint", "black", "isort"]
```

### Code Quality

This project uses **Anvil** for bulletproof code quality management through containerized tools.

**Development Workflow:**

- Create a branch for new features or big changes: `git checkout -b feature/your-feature`
- Apply linting before commits: `./anvil check` (runs comprehensive quality checks)
- Commit on important epics with meaningful messages
- Use Anvil's structured results from `results.yml` to address issues

**Key Commands:**

- `./anvil check` - Complete quality workflow (linting, security, formatting)
- `./anvil setup` - Initialize containers and configuration
- `./anvil results` - Show last quality check results

**Code Quality Tools (via Anvil containers):**

- **Python**: ruff, black, isort, mypy, bandit, safety
- **JavaScript/TypeScript**: eslint, prettier, npm audit
- **Security**: semgrep, detect-secrets, dependency scanning
- **Environment**: Automatic project structure detection

**Important Notes:**

- All tools run in containers - no local installation required
- Anvil auto-fixes formatting and provides structured issue reports
- Always review `results.yml` after running quality checks
- Follow branch → lint → commit workflow for best practices

**Code Style Guidelines:**
- **NEVER add comments to code** - Commands should be self-descriptive
- Examples: `chmod +x scripts/*.sh` is clear, no need for "# Make scripts executable"
- Focus on writing clear, readable code rather than explaining it with comments
- Only add comments for complex business logic or algorithms, never for basic commands
