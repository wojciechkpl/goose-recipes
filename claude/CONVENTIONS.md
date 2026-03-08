# Claude Code Agent Conventions

Global rules and standards shared across all Claude Code agents in this collection.

## Core Principles

### 1. TDD Is Mandatory
Every agent that writes or modifies code enforces Test-Driven Development:
- **RED**: Write a failing test FIRST
- **GREEN**: Write minimal code to pass the test
- **REFACTOR**: Improve code while keeping tests green

Never skip the RED phase. Never write implementation before the test.

### 2. Measure Before Optimizing
Never optimize without profiling data. Establish baselines, identify the 20% causing 80% of issues, optimize one thing at a time, and validate with benchmarks.

### 3. Security by Default
- No hardcoded secrets — use environment variables or secret managers
- Validate at system boundaries (user input, external APIs)
- Parameterized queries for all database access
- HTTPS/TLS for all external communication

### 4. Reproducibility
- Pin all dependency versions (no `>=`, no `latest`)
- Lock files committed to version control
- Deterministic seeds for ML experiments
- Docker environments for ML workloads

## Severity Classification

All auditing and review agents use a shared severity scale:
- **🔴 Critical**: MUST fix — security vulnerabilities, data loss, crashes (CVSS 9.0–10.0)
- **🟠 Major**: SHOULD fix — logic errors, missing error handling, performance (CVSS 7.0–8.9)
- **🟡 Minor**: CAN fix — naming, style, minor optimization (CVSS 4.0–6.9)
- **🔵 Suggestion**: OPTIONAL — alternative approaches, educational notes (CVSS 0.1–3.9)
- **ℹ️ Info**: No action — context, best practice notes

See `shared/severity-scale.md` for full specification.

## Agent Composition

Agents are organized by scope:
- **Core agents** (`agents/*.md`): General-purpose workflow agents
- **Language experts** (`agents/languages/*.md`): Deep language/domain specialization
- **Specialized agents** (`agents/specialized/*.md`): Research and design
- **Subrecipes** (`agents/subrecipes/*.md`): Shared workflows referenced by multiple agents

### Subrecipe Usage
Subrecipes contain reusable protocols that main agents reference:
- `tdd-generic.md` — Red-Green-Refactor cycle for any language
- `language-detection.md` — Auto-detect project stack
- `static-analysis.md` — Language-appropriate linting and type checking
- `git-best-practices.md` — Conventional commits, branch naming, PR hygiene
- `docker-ml-environment.md` — Containerized ML infrastructure
- `mlflow-tracking.md` — ML experiment tracking and model registry

## Naming Conventions

See `shared/naming-conventions.md` for the full standard. Key rules:
- Recipe files: `kebab-case.md`
- Recipe identifiers (frontmatter `name`): `kebab-case`
- Display names: Title Case

## Quality Standards

### File Size Limits
- Max 400 lines per source file
- Max 30 lines per function (50 for Bash, 40 for Rust)
- Max 7 public methods per class

### Test Coverage
- Minimum 80% line coverage for production code
- 90% for security-critical paths
- Every bug fix requires a regression test

### Documentation
- Public APIs must have docstrings
- Complex logic must have explanatory comments
- Architecture decisions documented in design docs
