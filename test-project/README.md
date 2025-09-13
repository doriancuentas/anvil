# Anvil Test Project

This is a test project for testing Anvil's linting and security scanning capabilities.

## Files included:

- `app.py` - Python file with intentional linting and security issues
- `script.js` - JavaScript file with linting and security issues
- `package.json` - Node.js project configuration
- `requirements.txt` - Python dependencies

## Expected Issues:

### Python (app.py):

- Formatting issues (spacing, line length)
- Security issues (os.system, eval usage)
- Import sorting issues
- Missing type hints

### JavaScript (script.js):

- ESLint rule violations
- Security issues (eval, document.write, innerHTML)
- Missing semicolons
- Unused variables
- Promise without error handling

## Testing Anvil:

1. Install Anvil in this directory
2. Run `./anvil check` to see all issues detected
3. Check that both Python and JavaScript issues are found
4. Verify security scanning detects the intentional vulnerabilities
