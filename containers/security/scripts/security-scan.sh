#!/bin/bash
# Security scanning script for Anvil
# Multi-language security analysis

set -euo pipefail

WORKSPACE="/workspace"
ANVIL_DIR="/anvil"
CONFIG_DIR="$WORKSPACE/.anvil"

log() {
    echo "[SECURITY] $1"
}

error() {
    echo "[ERROR] $1" >&2
}

success() {
    echo "[SUCCESS] $1"
}

# Run Semgrep security analysis
run_semgrep() {
    log "Running Semgrep security analysis..."
    
    local config_args="--config=auto"  # Auto-detect language rules
    local output_file=".anvil/reports/semgrep-report.json"
    
    if semgrep $config_args --json --output="$output_file" .; then
        success "Semgrep scan completed"
        
        # Check if any findings were reported
        local findings_count
        findings_count=$(jq '.results | length' "$output_file" 2>/dev/null || echo "0")
        
        if [ "$findings_count" -gt 0 ]; then
            error "Semgrep found $findings_count security issues"
            return 1
        else
            success "No security issues found by Semgrep"
        fi
    else
        error "Semgrep scan failed"
        return 1
    fi
}

# Run Bandit for Python files (if already done in linting, skip)
run_bandit_security() {
    if find . -name "*.py" -not -path "*/.*" | head -1 | grep -q .; then
        if [ ! -f ".anvil/reports/bandit-report.json" ]; then
            log "Running Bandit security scan for Python..."
            
            local config_args=""
            if [ -f "$CONFIG_DIR/.bandit" ]; then
                config_args="-c $CONFIG_DIR/.bandit"
            fi
            
            if bandit $config_args -r . -f json -o .anvil/reports/bandit-report.json; then
                success "Bandit security scan completed"
            else
                error "Bandit found security issues"
                return 1
            fi
        else
            log "Bandit report already exists, skipping"
        fi
    fi
}

# Run npm audit for Node.js projects (if already done in linting, skip)
run_npm_audit_security() {
    if [ -f "package.json" ]; then
        if [ ! -f ".anvil/reports/npm-audit-report.json" ]; then
            log "Running npm audit for Node.js security..."
            
            if npm audit --audit-level=moderate --json > .anvil/reports/npm-audit-report.json; then
                success "npm audit completed"
            else
                error "npm audit found security vulnerabilities"
                return 1
            fi
        else
            log "npm audit report already exists, skipping"
        fi
    fi
}

# Check for common security files and configurations
check_security_configs() {
    log "Checking security configurations..."
    
    local issues=()
    
    # Check for .env files that might be committed
    if find . -name ".env*" -not -path "*/node_modules/*" -not -path "*/.git/*" | grep -q .; then
        issues+=("Found .env files - ensure they're in .gitignore")
    fi
    
    # Check for potential secrets in code
    if grep -r -i "password\|secret\|api_key\|token" --include="*.py" --include="*.js" --include="*.ts" . | grep -v "example\|placeholder\|TODO" | head -5 | grep -q .; then
        issues+=("Potential hardcoded secrets found in code")
    fi
    
    # Check for weak file permissions (if applicable)
    if find . -type f -perm 777 2>/dev/null | head -5 | grep -q .; then
        issues+=("Files with overly permissive permissions (777) found")
    fi
    
    # Report issues
    if [ ${#issues[@]} -gt 0 ]; then
        error "Security configuration issues found:"
        for issue in "${issues[@]}"; do
            echo "  - $issue"
        done
        return 1
    else
        success "Security configuration check passed"
    fi
}

# Scan for known vulnerable patterns
scan_vulnerable_patterns() {
    log "Scanning for vulnerable code patterns..."
    
    local findings=()
    
    # SQL injection patterns
    if grep -r -n "execute.*%" --include="*.py" . | head -5 | grep -q .; then
        findings+=("Potential SQL injection pattern found")
    fi
    
    # Command injection patterns
    if grep -r -n "os\.system\|subprocess\.call" --include="*.py" . | head -5 | grep -q .; then
        findings+=("Command execution patterns found - review for injection risks")
    fi
    
    # XSS patterns in templates
    if grep -r -n "innerHTML\|document\.write" --include="*.js" --include="*.ts" . | head -5 | grep -q .; then
        findings+=("Potential XSS patterns found in JavaScript")
    fi
    
    # Report findings
    if [ ${#findings[@]} -gt 0 ]; then
        error "Vulnerable patterns detected:"
        for finding in "${findings[@]}"; do
            echo "  - $finding"
        done
        return 1
    else
        success "No vulnerable patterns detected"
    fi
}

# Generate security summary report
generate_security_summary() {
    local summary_file=".anvil/reports/security-summary.json"
    
    log "Generating security summary..."
    
    cat > "$summary_file" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "reports": {
    "semgrep": $([ -f ".anvil/reports/semgrep-report.json" ] && echo "true" || echo "false"),
    "bandit": $([ -f ".anvil/reports/bandit-report.json" ] && echo "true" || echo "false"),
    "npm_audit": $([ -f ".anvil/reports/npm-audit-report.json" ] && echo "true" || echo "false")
  },
  "summary": {
    "total_issues": 0,
    "high_severity": 0,
    "medium_severity": 0,
    "low_severity": 0
  }
}
EOF
    
    success "Security summary generated: $summary_file"
}

# Main security scanning workflow
main() {
    mkdir -p .anvil/reports
    cd "$WORKSPACE"
    
    log "Starting security scanning workflow..."
    
    local exit_code=0
    
    # Run Semgrep (universal security scanner)
    if command -v semgrep &> /dev/null; then
        run_semgrep || exit_code=$?
    else
        log "Semgrep not available, skipping"
    fi
    
    # Language-specific security scans
    run_bandit_security || exit_code=$?
    run_npm_audit_security || exit_code=$?
    
    # Custom security checks
    check_security_configs || exit_code=$?
    scan_vulnerable_patterns || exit_code=$?
    
    # Generate summary
    generate_security_summary
    
    if [ $exit_code -eq 0 ]; then
        success "All security scans completed successfully!"
    else
        error "Some security issues were found"
    fi
    
    return $exit_code
}

main "$@"