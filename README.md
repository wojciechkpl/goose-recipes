# Goose Recipes

A collection of specialized [Goose](https://github.com/block/goose) agent recipes for software development workflows. These recipes enforce **Test-Driven Development**, **code modularity**, and **language-specific best practices**.

## Repository Structure

This repo contains three sets of recipes:

1. **Project-Specific** (root `/`) — Tailored for RiseRally (FastAPI + Flutter + PyTorch)
2. **General-Purpose** (`general/`) — Language-agnostic, works with any project
3. **Language-Specific** (`general/languages/`) — Deep-expert agents for individual languages

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
    ├── ai-researcher.yaml          # ML Research Scientist (publication review, math, diagrams)
    ├── code-reviewer.yaml
    ├── security-auditor.yaml
    ├── documentation-agent.yaml
    ├── debugging-agent.yaml
    ├── performance-optimizer.yaml
    ├── api-designer.yaml
    ├── dependency-auditor.yaml
    ├── project-bootstrapper.yaml
    ├── subrecipes/
    │   ├── language-detection.yaml
    │   ├── literature-review.yaml
    │   ├── static-analysis.yaml
    │   ├── git-best-practices.yaml
    │   └── tdd-generic.yaml
    └── languages/                  # Language-specific deep experts
        ├── python-expert.yaml      # Python 3.10+ / pytest / type system
        ├── flutter-expert.yaml     # Flutter/Dart / Riverpod / go_router
        ├── rust-expert.yaml        # Rust / ownership / tokio / cargo
        ├── postgresql-expert.yaml  # PostgreSQL / schema / query optimization
        └── bash-expert.yaml        # Bash / shellcheck / bats-core
```

---

## General-Purpose Recipes

These recipes work with **any project** in any language. They auto-detect your tech stack and adapt their behavior accordingly.

### Main Agents

| Recipe | File | Purpose | Temp |
|--------|------|---------|------|
| **AI/ML Researcher** | `general/ai-researcher.yaml` | Scientific ML research: lit review, publication critique, tradeoff analysis, LaTeX math, Mermaid diagrams, IEEE citations | 0.3 |
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
| **Literature Review** | `general/subrecipes/literature-review.yaml` | PRISMA-inspired systematic review with structured extraction |
| **Static Analysis** | `general/subrecipes/static-analysis.yaml` | Run linters, formatters, type checkers per language |
| **Git Best Practices** | `general/subrecipes/git-best-practices.yaml` | Conventional commits, PR prep, branch hygiene, hooks |
| **TDD Generic** | `general/subrecipes/tdd-generic.yaml` | Red-Green-Refactor cycle for any language |

---

## Language-Specific Expert Agents

Deep-expert agents for individual languages. Each one encodes **idiomatic patterns**, **common pitfalls**, **ecosystem conventions**, and **testing culture** unique to that language. They can be used standalone or as delegates from other recipes.

### Agents

| Agent | File | Lines | Key Expertise |
|-------|------|-------|--------------|
| **Python Expert** | `general/languages/python-expert.yaml` | 459 | PEP 484/604/612/695, async/await, pytest, dataclasses, Pydantic, FastAPI/Django/PyTorch patterns |
| **Flutter Expert** | `general/languages/flutter-expert.yaml` | 537 | Dart 3.x (sealed classes, records, patterns), Riverpod, go_router, clean architecture, mocktail, golden tests |
| **Rust Expert** | `general/languages/rust-expert.yaml` | 485 | Ownership/lifetimes, thiserror/anyhow, tokio async, traits, zero-cost abstractions, property testing, unsafe audit |
| **PostgreSQL Expert** | `general/languages/postgresql-expert.yaml` | 550 | Schema design (3NF+), EXPLAIN ANALYZE, indexing (B-tree/GIN/BRIN), RLS, partitioning, CTEs, window functions |
| **Bash Expert** | `general/languages/bash-expert.yaml` | 618 | `set -euo pipefail`, shellcheck compliance, proper quoting, bats-core testing, CI/CD patterns, security hardening |

### Language Agent Features

| Feature | Python | Flutter | Rust | PostgreSQL | Bash |
|---------|--------|---------|------|------------|------|
| **Type system** | PEP 484/604/695 + mypy strict | Dart sealed + records + patterns | Ownership + lifetimes + traits | Column types + constraints + domains | ShellCheck SC rules |
| **Testing** | pytest + parametrize + hypothesis | flutter_test + mocktail + golden | cargo test + rstest + proptest | pgTAP + migration testing | bats-core + mocking |
| **Linting** | ruff + mypy --strict | dart analyze | clippy -D warnings | N/A | shellcheck |
| **Error handling** | Custom hierarchy + chaining | sealed Result\<T\> pattern | thiserror (lib) / anyhow (bin) | CHECK + RLS + exclusion | trap EXIT + cleanup |
| **Performance** | slots, polars, generators, cProfile | const widgets, RepaintBoundary, select() | Zero-cost iterators, criterion benchmarks | EXPLAIN ANALYZE, index strategy | Parameter expansion, process substitution |
| **Modularity** | 400 lines/file, 30 lines/fn | 300 lines/file, 80 lines/build | 500 lines/mod, 40 lines/fn | One migration per change | 200 lines/script, 50 lines/fn |
| **TDD enforced** | ✅ retry block | ✅ retry block | ✅ retry block | ✅ via app-level tests | ✅ shellcheck + bats retry |

### Cross-Delegation

Language agents can be invoked by general agents and vice versa:

```
General Agent ──→ Language Agent
  Code Reviewer ──→ Python/Flutter/Rust Agent (for language-specific checks)
  Debugging Agent ──→ Python/Rust Agent (for language-specific debugging tools)

Language Agent ──→ Shared Subrecipes
  Python Expert ──→ TDD Generic, Static Analysis, Code Reviewer, Debugging Agent
  Flutter Expert ──→ TDD Generic, Static Analysis, Code Reviewer, Debugging Agent
  Rust Expert ──→ TDD Generic, Static Analysis, Code Reviewer, Debugging Agent
  PostgreSQL Expert ──→ Security Auditor, Performance Optimizer, Code Reviewer
  Bash Expert ──→ Static Analysis, Code Reviewer, Security Auditor
```

---

## AI/ML Research Scientist — Detailed Capabilities

The `general/ai-researcher.yaml` recipe (817 lines) is a peer-reviewer-caliber research agent with:

### Research Phases
| Phase | Purpose | Key Output |
|-------|---------|-----------|
| **Literature Review** | Systematic PRISMA search | Taxonomy mindmap, performance landscape, timeline |
| **Publication Review** | Peer-review quality critique | Strengths/weaknesses, math verification, scores |
| **Solution Design** | Multi-criteria tradeoff analysis | Weighted decision matrix, Pareto analysis, risk assessment |
| **Mathematical Formulation** | Full derivations from first principles | LaTeX equations, gradient computation, complexity analysis |
| **Experimental Design** | Statistically rigorous protocols | Hypothesis, baselines, metrics, power analysis |
| **Implementation** | TDD-driven ML code | Tested components with config management |
| **Evaluation** | Results with statistical significance | Tables, ablations, error analysis, computational profile |

### Output Formats
- **Technical Report** — NeurIPS-style structure with abstract, methodology, results
- **Paper Draft** — Full paper formatting
- **Design Document** — Production-focused with engineering tradeoffs
- **Jupyter Notebook** — Executable cells with explanations
- **Peer Review** — Structured critique with scoring

### Standards Enforced
- IEEE citation format with DOI/arXiv IDs
- Consistent LaTeX notation (vectors bold, matrices bold uppercase, sets calligraphic)
- Mermaid diagrams: architecture, pipeline, taxonomy, tradeoff quadrants, timeline, sequence
- Statistical methodology: paired t-tests, Bonferroni correction, effect sizes, confidence intervals
- Reproducibility checklist: seeds, hardware, library versions, compute budget

---

## Supported Languages

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
| **PostgreSQL** | — | — | — | pgTAP |
| **Bash** | shellcheck | shfmt | — | bats-core |

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
| **Scientific Rigor** | PRISMA literature review, IEEE citations, statistical significance testing |
| **Mathematical Precision** | LaTeX notation conventions, derivations from first principles |

---

## Usage

### Run from CLI

```bash
# General-purpose (any project)
goose run --recipe general/ai-researcher.yaml
goose run --recipe general/code-reviewer.yaml
goose run --recipe general/security-auditor.yaml
goose run --recipe general/debugging-agent.yaml
goose run --recipe general/performance-optimizer.yaml
goose run --recipe general/api-designer.yaml
goose run --recipe general/dependency-auditor.yaml
goose run --recipe general/documentation-agent.yaml
goose run --recipe general/project-bootstrapper.yaml

# Language-specific experts
goose run --recipe general/languages/python-expert.yaml
goose run --recipe general/languages/flutter-expert.yaml
goose run --recipe general/languages/rust-expert.yaml
goose run --recipe general/languages/postgresql-expert.yaml
goose run --recipe general/languages/bash-expert.yaml

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
