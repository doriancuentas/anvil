# CLAUDE.md

## Coding Philosophy & Preferences

### Code Approach
- **Convention over configuration**: Follow established patterns, minimize decision fatigue
- **Simplicity over complexity**: Don’t over-engineer solutions
- **Single implementation**: When multiple approaches exist, give alternatives or ask for choice
- **Practical solutions**: Solve the actual problem without gold-plating
- **Clean, readable code**: Avoid verbose debugging or complex abstractions
- **History in git, not folders**: No parallel implementations or backup directories
- **Keep comments to a minimum**: Comments should exists only when they say something the code does not

### Problem Solving Process
1. Implement the simplest working solution first
2. When uncertain or alternatives, ask specific numbered questions with clear options
3. Avoid try/catch blocks with multiple fallback libraries unless necessary

### Communication Style
- **Enforce criticism**: Don’t just align, challenge assumptions with reasons
- **Concise responses**: Only essential information, no fluff
- **Structured format**: Use sections and clear organization
- **No validation phrases**: Skip human-like acknowledgments
- **Direct feedback**: Expect and follow blunt corrections immediately

### Code Quality
- Always run `../scripts/anvil.sh check` after making changes
- **ALWAYS commit current state to git before making significant changes**
  - Creates rollback points for safe experimentation

### Examples of What NOT to Do
- Multiple logic inside try/catch blocks when one works
- Adding sudo when not required
- Long unreadable verbose debugging output when a clean summary suffices
- **NEVER hardcode IPs, hostnames, ports, or environment-specific values in code or configs**
- **ALWAYS use environment variables, dynamic detection, or config files for deployment-specific values**
