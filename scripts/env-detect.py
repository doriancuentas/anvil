#!/usr/bin/env python3
"""
Smart Environment Detection for CodeSteward
Detects project structure, dependencies, and environment requirements
"""

import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple


class EnvironmentDetector:
    def __init__(self, project_path: str = "."):
        self.project_path = Path(project_path).resolve()
        self.detection_results = {}
    
    def detect_languages(self) -> Dict[str, Dict]:
        """Detect programming languages and their versions"""
        languages = {}
        
        # Python detection
        python_files = list(self.project_path.rglob("*.py"))
        if python_files:
            languages["python"] = {
                "files_count": len(python_files),
                "current_version": self._get_python_version(),
                "virtual_env": self._detect_python_env(),
                "requirements": self._find_requirements(),
                "package_manager": self._detect_python_package_manager()
            }
        
        # Node.js detection
        package_json = self.project_path / "package.json"
        if package_json.exists() or list(self.project_path.rglob("*.ts")) or list(self.project_path.rglob("*.js")):
            languages["nodejs"] = {
                "files_count": len(list(self.project_path.rglob("*.ts")) + list(self.project_path.rglob("*.js"))),
                "current_version": self._get_node_version(),
                "package_json": package_json.exists(),
                "package_manager": self._detect_node_package_manager(),
                "framework": self._detect_js_framework()
            }
        
        # Go detection
        go_files = list(self.project_path.rglob("*.go"))
        if go_files or (self.project_path / "go.mod").exists():
            languages["go"] = {
                "files_count": len(go_files),
                "current_version": self._get_go_version(),
                "go_mod": (self.project_path / "go.mod").exists()
            }
        
        # Rust detection
        cargo_toml = self.project_path / "Cargo.toml"
        if cargo_toml.exists() or list(self.project_path.rglob("*.rs")):
            languages["rust"] = {
                "files_count": len(list(self.project_path.rglob("*.rs"))),
                "current_version": self._get_rust_version(),
                "cargo_toml": cargo_toml.exists()
            }
        
        return languages
    
    def detect_infrastructure(self) -> Dict[str, Dict]:
        """Detect infrastructure and deployment tools"""
        infra = {}
        
        # Docker
        dockerfile_patterns = ["Dockerfile*", "docker-compose*.yml", "docker-compose*.yaml"]
        docker_files = []
        for pattern in dockerfile_patterns:
            docker_files.extend(list(self.project_path.rglob(pattern)))
        
        if docker_files:
            infra["docker"] = {
                "files": [str(f.relative_to(self.project_path)) for f in docker_files],
                "compose_files": [f for f in docker_files if "compose" in f.name],
                "dockerfiles": [f for f in docker_files if f.name.startswith("Dockerfile")]
            }
        
        # Git
        if (self.project_path / ".git").exists():
            infra["git"] = {
                "current_branch": self._get_git_branch(),
                "remote_url": self._get_git_remote(),
                "uncommitted_changes": self._has_uncommitted_changes()
            }
        
        # CI/CD
        ci_patterns = [".github/workflows", ".gitlab-ci.yml", "Jenkinsfile", ".travis.yml"]
        ci_files = []
        for pattern in ci_patterns:
            if (self.project_path / pattern).exists():
                ci_files.append(pattern)
        
        if ci_files:
            infra["ci_cd"] = {"detected": ci_files}
        
        return infra
    
    def suggest_environment_isolation(self) -> Dict[str, List[str]]:
        """Suggest environment isolation strategies"""
        suggestions = {}
        languages = self.detect_languages()
        
        for lang, details in languages.items():
            lang_suggestions = []
            
            if lang == "python":
                if not details["virtual_env"]:
                    lang_suggestions.append("Create Python virtual environment (venv/virtualenv)")
                if not details.get("requirements"):
                    lang_suggestions.append("Create requirements.txt or pyproject.toml")
                lang_suggestions.append("Consider pyenv for Python version management")
            
            elif lang == "nodejs":
                if not details.get("package_json"):
                    lang_suggestions.append("Initialize package.json")
                lang_suggestions.append("Consider nvm for Node.js version management")
                if details.get("framework") in ["react", "vue", "angular"]:
                    lang_suggestions.append("Use framework-specific dev containers")
            
            elif lang == "go":
                if not details.get("go_mod"):
                    lang_suggestions.append("Initialize go.mod")
                lang_suggestions.append("Consider Go workspace for multi-module projects")
            
            elif lang == "rust":
                if not details.get("cargo_toml"):
                    lang_suggestions.append("Initialize Cargo.toml")
            
            if lang_suggestions:
                suggestions[lang] = lang_suggestions
        
        # Docker suggestions
        infra = self.detect_infrastructure()
        if "docker" not in infra and len(languages) > 1:
            suggestions["general"] = suggestions.get("general", [])
            suggestions["general"].append("Consider Docker for consistent development environment")
        
        return suggestions
    
    def check_security_tools(self) -> Dict[str, bool]:
        """Check availability of security scanning tools"""
        tools = {
            "bandit": self._command_exists("bandit"),  # Python security
            "safety": self._command_exists("safety"),  # Python dependencies
            "npm_audit": self._command_exists("npm") and self._has_npm_audit(),
            "snyk": self._command_exists("snyk"),
            "semgrep": self._command_exists("semgrep"),
            "gosec": self._command_exists("gosec"),  # Go security
        }
        return tools
    
    def generate_report(self, format_type: str = "console") -> str:
        """Generate detection report"""
        languages = self.detect_languages()
        infra = self.detect_infrastructure()
        suggestions = self.suggest_environment_isolation()
        security_tools = self.check_security_tools()
        
        if format_type == "json":
            return json.dumps({
                "languages": languages,
                "infrastructure": infra,
                "suggestions": suggestions,
                "security_tools": security_tools
            }, indent=2)
        
        # Console format
        report = []
        report.append("🔍 ENVIRONMENT DETECTION REPORT")
        report.append("=" * 50)
        
        # Languages section
        report.append("\n📚 DETECTED LANGUAGES:")
        for lang, details in languages.items():
            report.append(f"  {lang.upper()}:")
            report.append(f"    Files: {details['files_count']}")
            if 'current_version' in details:
                report.append(f"    Version: {details['current_version']}")
            for key, value in details.items():
                if key not in ['files_count', 'current_version']:
                    report.append(f"    {key.replace('_', ' ').title()}: {value}")
        
        # Infrastructure section
        if infra:
            report.append("\n🏗️  INFRASTRUCTURE:")
            for component, details in infra.items():
                report.append(f"  {component.upper()}:")
                for key, value in details.items():
                    report.append(f"    {key.replace('_', ' ').title()}: {value}")
        
        # Suggestions section
        if suggestions:
            report.append("\n💡 ENVIRONMENT ISOLATION SUGGESTIONS:")
            for category, items in suggestions.items():
                report.append(f"  {category.upper()}:")
                for item in items:
                    report.append(f"    • {item}")
        
        # Security tools section
        report.append("\n🛡️  SECURITY TOOLS AVAILABILITY:")
        for tool, available in security_tools.items():
            status = "✅" if available else "❌"
            report.append(f"  {status} {tool}")
        
        return "\n".join(report)
    
    # Helper methods
    def _get_python_version(self) -> Optional[str]:
        try:
            result = subprocess.run([sys.executable, "--version"], 
                                  capture_output=True, text=True)
            return result.stdout.strip()
        except:
            return None
    
    def _detect_python_env(self) -> Optional[str]:
        if os.environ.get("VIRTUAL_ENV"):
            return os.environ["VIRTUAL_ENV"]
        if (self.project_path / "venv").exists():
            return str(self.project_path / "venv")
        if (self.project_path / ".venv").exists():
            return str(self.project_path / ".venv")
        return None
    
    def _find_requirements(self) -> Optional[str]:
        req_files = ["requirements.txt", "pyproject.toml", "setup.py", "Pipfile"]
        for req_file in req_files:
            if (self.project_path / req_file).exists():
                return req_file
        return None
    
    def _detect_python_package_manager(self) -> str:
        if (self.project_path / "Pipfile").exists():
            return "pipenv"
        if (self.project_path / "pyproject.toml").exists():
            return "poetry/pip"
        if (self.project_path / "requirements.txt").exists():
            return "pip"
        return "unknown"
    
    def _get_node_version(self) -> Optional[str]:
        try:
            result = subprocess.run(["node", "--version"], 
                                  capture_output=True, text=True)
            return result.stdout.strip()
        except:
            return None
    
    def _detect_node_package_manager(self) -> str:
        if (self.project_path / "yarn.lock").exists():
            return "yarn"
        if (self.project_path / "pnpm-lock.yaml").exists():
            return "pnpm"
        if (self.project_path / "package-lock.json").exists():
            return "npm"
        return "unknown"
    
    def _detect_js_framework(self) -> Optional[str]:
        package_json = self.project_path / "package.json"
        if not package_json.exists():
            return None
        
        try:
            with open(package_json) as f:
                data = json.load(f)
                deps = {**data.get("dependencies", {}), **data.get("devDependencies", {})}
                
                if "react" in deps:
                    return "react"
                if "vue" in deps:
                    return "vue"
                if "@angular/core" in deps:
                    return "angular"
                if "svelte" in deps:
                    return "svelte"
        except:
            pass
        
        return None
    
    def _get_go_version(self) -> Optional[str]:
        try:
            result = subprocess.run(["go", "version"], 
                                  capture_output=True, text=True)
            return result.stdout.strip()
        except:
            return None
    
    def _get_rust_version(self) -> Optional[str]:
        try:
            result = subprocess.run(["rustc", "--version"], 
                                  capture_output=True, text=True)
            return result.stdout.strip()
        except:
            return None
    
    def _get_git_branch(self) -> Optional[str]:
        try:
            result = subprocess.run(["git", "branch", "--show-current"], 
                                  capture_output=True, text=True, cwd=self.project_path)
            return result.stdout.strip()
        except:
            return None
    
    def _get_git_remote(self) -> Optional[str]:
        try:
            result = subprocess.run(["git", "remote", "get-url", "origin"], 
                                  capture_output=True, text=True, cwd=self.project_path)
            return result.stdout.strip()
        except:
            return None
    
    def _has_uncommitted_changes(self) -> bool:
        try:
            result = subprocess.run(["git", "status", "--porcelain"], 
                                  capture_output=True, text=True, cwd=self.project_path)
            return bool(result.stdout.strip())
        except:
            return False
    
    def _command_exists(self, command: str) -> bool:
        try:
            subprocess.run([command, "--version"], 
                          capture_output=True, check=True)
            return True
        except:
            return False
    
    def _has_npm_audit(self) -> bool:
        try:
            result = subprocess.run(["npm", "audit", "--help"], 
                                  capture_output=True, text=True)
            return "audit" in result.stdout
        except:
            return False


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Smart Environment Detection")
    parser.add_argument("--path", default=".", help="Project path to analyze")
    parser.add_argument("--format", choices=["console", "json"], default="console", 
                       help="Output format")
    parser.add_argument("--check-versions", action="store_true", 
                       help="Check current tool versions")
    parser.add_argument("--suggest-isolation", action="store_true", 
                       help="Suggest environment isolation strategies")
    
    args = parser.parse_args()
    
    detector = EnvironmentDetector(args.path)
    report = detector.generate_report(args.format)
    print(report)


if __name__ == "__main__":
    main()