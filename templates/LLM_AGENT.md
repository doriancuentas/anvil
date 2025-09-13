# LLM Agent Configuration for Anvil

## Hooks Configuration

Configure these hooks to work harmoniously with Anvil:

```yaml
hooks:
  user_prompt_submit:
    # Remind about Anvil workflow before git operations
    - pattern: "git (add|commit|push)"
      command: "echo '💡 Consider: ./anvil check before committing for quality assurance'"
  
  tool_use_pre:
    # Suggest Anvil for quality tasks while allowing manual tools
    - pattern: "(lint|format|prettier|eslint|black|isort)"
      command: "echo '🔧 Tip: ./anvil lint provides comprehensive quality checks'"
```

## Manual Workflow Considerations

When working manually (outside LLM assistance):

**Before Committing:**
- Run `./anvil check` or `./anvil lint` to catch issues early
- Review `.anvil/results.yml` for detailed findings
- Anvil auto-fixes formatting, you handle logic issues

**Git Worktrees Compatible:**
- Each worktree maintains separate `.anvil/` directory
- Containers are global (shared across worktrees for efficiency)
- Run quality checks independently per worktree: `./anvil check`

**Branch Workflow:**
- Create feature branch: `git worktree add ../feature-name -b feature-name`
- Quality check: `cd ../feature-name && ./anvil check`
- Commit with confidence after Anvil validation

### Code Quality

This project uses **Anvil** for bulletproof code quality management through containerized tools.

**Development Workflow:**

1. **Branch Creation**: `git checkout -b feature/new-feature` or `git worktree add ../feature-name -b feature-name`
2. **Code & Quality**: Make changes, then `./anvil check` before commits  
3. **Review Results**: Check `.anvil/results.yml` for issues and suggestions
4. **Commit**: Use meaningful messages after Anvil validation passes
5. **Integration**: Merge/rebase with clean quality checks

**Key Commands:**

- `./anvil check [path]` - Complete quality workflow (linting, security, formatting)
- `./anvil lint [path]` - Fast linting and formatting only
- `./anvil create_report` - Generate markdown report in `.anvil/report.md`
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