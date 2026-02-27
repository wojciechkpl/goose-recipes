# Goose Recipes

A collection of specialized [Goose](https://github.com/block/goose) agent recipes for software development workflows. These recipes enforce **Test-Driven Development**, **code modularity**, and **language-specific best practices**.

## Repository Structure

This repo contains two sets of recipes:

1. **Project-Specific** (root `/`) — Tailored for RiseRally (FastAPI + Flutter + PyTorch)
2. **General-Purpose** (`general/`) — Language-agnostic, works with any project

```
goose-recipes/
├── README.md
│
├── # ── Project-Specific (RiseRally) ──────────
├── solution-architect.yaml
├── ai-researcher.yaml
├── data-exploration.yaml
├── refactoring-agent.yaml
├── subrecipes/
│   ├── tdd-workflow.yaml
│   ├── code-review.yaml
│   └── test-validation.yaml
│
└── # ── General-Purpose ───────────────────────
    general/
    ├── code-reviewer.yaml
    ├── security-auditor.yaml
    ├── documentation-agent.yaml
    ├── debugging-agent.yaml
    ├── performance-optimizer.yaml
    ├── api-designer.yaml
    ├── dependency-auditor.yaml
    ├── project-bootstrapper.yaml
    └── subrecipes/
        ├── language-detection.yaml
        ├── static-analysis.yaml
        ├── git-best-practices.yaml
        └── tdd-generic.yaml
```

---

## General-Purpose Recipes

These recipes work with **any project** in any language. They auto-detect your tech stack and adapt their behavior accordingly.

### Main Agents

| Recipe | File | Purpose | Temp |
|--------|------|---------|------|
| **Code Reviewer** | `general/code-reviewer.yaml` | Comprehensive code review: correctness, security, performance, maintainability | 0.3 |
| **Security Auditor** | `general/security-auditor.yaml` | OWASP Top 10, secret detection, dependency CVEs, infrastructure review | 0.2 |
| **Documentation Agent** | `general/documentation-agent.yaml` | API docs, inline docs, READMEs, architecture diagrams, changelogs | 0.3 |
| **Debugging Agent** | `general/debugging-agent.yaml` | Scientific debugging: observe → hypothesize → test → fix → verify | 0.2 |
| **Performance Optimizer** | `general/performance-optimizer.yaml` | Profile → analyze → optimize → validate (DB, API, memory, rendering) | 0.2 |
| **API Designer** | `general/api-designer.yaml` | REST/GraphQL/gRPC design with proper HTTP semantics and OpenAPI specs | 0.3 |
| **Dependency Auditor** | `general/dependency-auditor.yaml` | Vulnerability scanning, license compliance, update planning, size analysis | 0.1 |
| **Project Bootstrapper** | `general/project-bootstrapper.yaml` | Scaffold new projects with CI/CD, testing, Docker, linting setup | 0.2 |

### Shared Subrecipes

| Subrecipe | File | Purpose |
|-----------|------|---------|
| **Language Detection** | `general/subrecipes/language-detection.yaml` | Auto-detect project language, framework, toolchain |
| **Static Analysis** | `general/subrecipes/static-analysis.yaml` | Run linters, formatters, type checkers per language |
| **Git Best Practices** | `general/subrecipes/git-best-practices.yaml` | Conventional commits, PR prep, branch hygiene, hooks |
| **TDD Generic** | `general/subrecipes/tdd-generic.yaml` | Red-Green-Refactor cycle for any language |

### Supported Languages

All general recipes support these languages (auto-detected):

| Language | Linter | Formatter | Type Checker | Test Runner |
|----------|--------|-----------|-------------|-------------|
| Python | ruff / flake8 | ruff / black | mypy / pyright | pytest |
| TypeScript | eslint | prettier | tsc | jest / vitest |
| JavaScript | eslint | prettier | — | jest / vitest |
| Dart/Flutter | dart analyze | dart format | dart analyzer | flutter_test |
| Rust | clippy | rustfmt | (built-in) | cargo test |
| Go | golangci-lint | gofmt | (built-in) | go test |
| Java | checkstyle | google-java-format | (compiler) | JUnit 5 |
| Ruby | rubocop | rubocop | sorbet | RSpec |
| C# | roslyn analyzers | dotnet format | (compiler) | xUnit / NUnit |

### Cross-Delegation Map

```
Code Reviewer ──→ Language Detection, Static Analysis
Security Auditor ──→ Language Detection, Static Analysis
Documentation Agent ──→ Language Detection
Debugging Agent ──→ Language Detection, TDD Generic, Static Analysis
Performance Optimizer ──→ Language Detection, TDD Generic, Static Analysis
API Designer ──→ Language Detection, TDD Generic, Code Reviewer
Dependency Auditor ──→ Language Detection
Project Bootstrapper ──→ Language Detection, TDD Generic, Git Best Practices
```

---

## Project-Specific Recipes (RiseRally)

These recipes are tailored for the RiseRally fitness platform (FastAPI + Flutter + PyTorch).

### Main Agents

| Recipe | File | Purpose | Temp |
|--------|------|---------|------|
| **Solution Architect** | `solution-architect.yaml` | System design, ADRs, interface contracts | 0.3 |
| **AI Researcher** | `ai-researcher.yaml` | ML research, experiments, prototyping | 0.4 |
| **Data Exploration** | `data-exploration.yaml` | Data profiling, analysis, notebooks | 0.3 |
| **Refactoring Agent** | `refactoring-agent.yaml` | Code improvement with strict TDD | 0.2 |

### Shared Subrecipes

| Subrecipe | File | Purpose |
|-----------|------|---------|
| **TDD Workflow** | `subrecipes/tdd-workflow.yaml` | Red-Green-Refactor (Python/Dart/SQL) |
| **Code Review** | `subrecipes/code-review.yaml` | Quality review for RiseRally patterns |
| **Test Validation** | `subrecipes/test-validation.yaml` | Test suite execution |

---

## Best Practices Enforced

| Practice | How Enforced |
|----------|-------------|
| **TDD** | Red-Green-Refactor subrecipes with retry logic — tests MUST pass |
| **Modularity** | Hard limits: max 400 lines/file, 30 lines/function, 7 public methods/class |
| **Type Safety** | Language-appropriate type checkers run via static-analysis subrecipe |
| **Security** | OWASP Top 10 checks, secret detection, dependency CVE scanning |
| **Git Hygiene** | Conventional Commits, PR templates, pre-commit hooks |
| **Documentation** | API docs, inline docs, architecture diagrams (Mermaid) |
| **Performance** | Measure-first methodology, benchmark tests, profiling |
| **Dependencies** | Vulnerability audits, license compliance, unused detection |

---

## Usage

### Run from CLI

```bash
# General-purpose (any project)
goose run --recipe general/code-reviewer.yaml
goose run --recipe general/security-auditor.yaml
goose run --recipe general/debugging-agent.yaml
goose run --recipe general/performance-optimizer.yaml
goose run --recipe general/api-designer.yaml
goose run --recipe general/dependency-auditor.yaml
goose run --recipe general/documentation-agent.yaml
goose run --recipe general/project-bootstrapper.yaml

# Project-specific (RiseRally)
goose run --recipe solution-architect.yaml
goose run --recipe ai-researcher.yaml
goose run --recipe data-exploration.yaml
goose run --recipe refactoring-agent.yaml
```

### Import into Goose Desktop

1. Open **Goose Desktop** → **Settings** → **Recipe Library**
2. Add from local path or import the YAML file

### Customize for Your Project

To create project-specific versions of the general recipes:
1. Copy the `general/` recipe to your project root
2. Update the **instructions** section with your project context
3. Hardcode paths for your project structure
4. Adjust the `retry.checks` commands to your test runners

---

## License

MIT
