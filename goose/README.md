# Goose Recipes

A collection of specialized [Goose](https://github.com/block/goose) agent recipes for software development workflows. These recipes enforce **Test-Driven Development**, **code modularity**, **Docker-based ML development**, and **language-specific best practices**.

All recipes are **general-purpose** — they auto-detect your project's tech stack and adapt behavior accordingly. No project-specific hardcoding.

## Repository Structure

```
goose-recipes/
├── README.md
├── TUTORIAL.md                           # Step-by-step usage guide with examples
│
├── general/
│   ├── ai-researcher.yaml                # ML Research Scientist (arXiv, citations, MLflow, Docker)
│   ├── code-reviewer.yaml                # Comprehensive code review
│   ├── security-auditor.yaml             # OWASP Top 10, secrets, CVEs, infrastructure
│   ├── documentation-agent.yaml          # API docs, inline docs, READMEs, Mermaid diagrams
│   ├── debugging-agent.yaml              # Scientific debugging: observe → hypothesize → test → fix
│   ├── performance-optimizer.yaml        # Profile → analyze → optimize → validate
│   ├── api-designer.yaml                 # REST/GraphQL/gRPC with OpenAPI specs
│   ├── dependency-auditor.yaml           # Vulnerabilities, licenses, unused, size analysis
│   ├── project-bootstrapper.yaml         # Scaffold projects with CI/CD, Docker, testing
│   ├── ux-designer.yaml                  # UX design: wireframes, a11y, design systems, heuristics
│   │
│   ├── subrecipes/                       # Shared building blocks (delegated to by main recipes)
│   │   ├── language-detection.yaml       # Auto-detect language, framework, toolchain
│   │   ├── tdd-generic.yaml             # Red-Green-Refactor for any language
│   │   ├── static-analysis.yaml          # Linters, formatters, type checkers
│   │   ├── git-best-practices.yaml       # Conventional commits, PR prep, hooks
│   │   ├── literature-review.yaml        # PRISMA-inspired systematic review
│   │   ├── arxiv-search.yaml             # arXiv API paper search with relevance ranking
│   │   ├── citation-graph.yaml           # Semantic Scholar citation analysis (PageRank, clusters)
│   │   ├── mlflow-tracking.yaml          # MLflow: params, metrics, artifacts, registry, HPO
│   │   ├── docker-ml-environment.yaml    # Containerized ML: Dockerfiles, compose, GPU, MLflow
│   │   └── design-system.yaml           # Design tokens, component inventory, consistency checks
│   │
│   └── languages/                        # Language-specific deep expert agents
│       ├── python-expert.yaml            # Python 3.10+ / pytest / type system / FastAPI / PyTorch
│       ├── flutter-expert.yaml           # Flutter / Dart 3.x / Riverpod / go_router
│       ├── rust-expert.yaml              # Rust / ownership / tokio / cargo
│       ├── postgresql-expert.yaml        # PostgreSQL / schema / indexing / query optimization
│       └── bash-expert.yaml              # Bash / shellcheck / bats-core / CI patterns
```

---

## Main Agent Recipes

| Recipe | File | Purpose | Temp |
|--------|------|---------|------|
| **AI/ML Researcher** | `general/ai-researcher.yaml` | Scientific ML research: lit review, arXiv API, citation graph, tradeoff analysis, LaTeX math, Mermaid diagrams, Docker-based experiments, MLflow tracking | 0.3 |
| **Code Reviewer** | `general/code-reviewer.yaml` | Comprehensive code review: correctness, security, performance, maintainability | 0.3 |
| **Security Auditor** | `general/security-auditor.yaml` | OWASP Top 10, secret detection, dependency CVEs, infrastructure review | 0.2 |
| **Documentation Agent** | `general/documentation-agent.yaml` | API docs, inline docs, READMEs, architecture diagrams, changelogs | 0.3 |
| **Debugging Agent** | `general/debugging-agent.yaml` | Scientific debugging: observe → hypothesize → test → fix → verify | 0.2 |
| **Performance Optimizer** | `general/performance-optimizer.yaml` | Profile → analyze → optimize → validate (DB, API, memory, rendering) | 0.2 |
| **API Designer** | `general/api-designer.yaml` | REST/GraphQL/gRPC design with proper HTTP semantics and OpenAPI specs | 0.3 |
| **Dependency Auditor** | `general/dependency-auditor.yaml` | Vulnerability scanning, license compliance, update planning, size analysis | 0.1 |
| **Project Bootstrapper** | `general/project-bootstrapper.yaml` | Scaffold new projects with CI/CD, testing, Docker, linting setup | 0.2 |
| **UX Designer** | `general/ux-designer.yaml` | User research, wireframes (ASCII/Mermaid), design systems, accessibility (WCAG 2.2), Nielsen's heuristics, interaction design, responsive specs, design handoff | 0.3 |

---

## Language-Specific Expert Agents

Deep-expert agents for individual languages. Each encodes **idiomatic patterns**, **common pitfalls**, **ecosystem conventions**, and **testing culture** unique to that language.

| Agent | File | Key Expertise |
|-------|------|--------------|
| **Python Expert** | `general/languages/python-expert.yaml` | PEP 484/604/612/695, async/await, pytest, dataclasses, Pydantic, FastAPI/Django/PyTorch |
| **Flutter Expert** | `general/languages/flutter-expert.yaml` | Dart 3.x (sealed classes, records, patterns), Riverpod, go_router, clean architecture, golden tests |
| **Rust Expert** | `general/languages/rust-expert.yaml` | Ownership/lifetimes, thiserror/anyhow, tokio async, traits, zero-cost abstractions, property testing |
| **PostgreSQL Expert** | `general/languages/postgresql-expert.yaml` | Schema design (3NF+), EXPLAIN ANALYZE, indexing (B-tree/GIN/BRIN), RLS, partitioning, CTEs |
| **Bash Expert** | `general/languages/bash-expert.yaml` | `set -euo pipefail`, shellcheck, proper quoting, bats-core testing, CI/CD patterns |

---

## Shared Subrecipes

Building blocks that main recipes delegate to. Can also be used standalone.

| Subrecipe | File | Purpose |
|-----------|------|---------|
| **Language Detection** | `general/subrecipes/language-detection.yaml` | Auto-detect language, framework, toolchain from project files |
| **TDD Generic** | `general/subrecipes/tdd-generic.yaml` | Red-Green-Refactor cycle for any language |
| **Static Analysis** | `general/subrecipes/static-analysis.yaml` | Run linters, formatters, type checkers per language |
| **Git Best Practices** | `general/subrecipes/git-best-practices.yaml` | Conventional commits, PR prep, branch hygiene, hooks |
| **Literature Review** | `general/subrecipes/literature-review.yaml` | PRISMA-inspired systematic review with structured extraction |
| **arXiv Search** | `general/subrecipes/arxiv-search.yaml` | Programmatic arXiv paper search with relevance ranking |
| **Citation Graph** | `general/subrecipes/citation-graph.yaml` | Semantic Scholar citation analysis — PageRank, clusters, velocity |
| **MLflow Tracking** | `general/subrecipes/mlflow-tracking.yaml` | MLflow: params, metrics, artifacts, Model Registry, Optuna HPO |
| **Docker ML Environment** | `general/subrecipes/docker-ml-environment.yaml` | Containerized ML: multi-stage Dockerfiles, compose, GPU, MLflow server |
| **Design System** | `general/subrecipes/design-system.yaml` | Token audit, component inventory, magic value detection, consistency checks |

---

## Cross-Delegation Architecture

Recipes delegate to each other for complex workflows:

```
                    ┌─────────────────────┐
                    │  Language Detection  │ ◄── All main recipes start here
                    └──────────┬──────────┘
                               │
          ┌────────────────────┼────────────────────┐
          ▼                    ▼                     ▼
  ┌───────────────┐   ┌──────────────┐    ┌─────────────────┐
  │ Main Recipes  │   │  Language     │    │ ML Subrecipes   │
  │               │   │  Experts     │    │                 │
  │ • Code Review │   │ • Python     │    │ • arXiv Search  │
  │ • Security    │   │ • Flutter    │    │ • Citation Graph│
  │ • Debugging   │   │ • Rust       │    │ • MLflow Track  │
  │ • Performance │   │ • PostgreSQL │    │ • Docker ML Env │
  │ • API Design  │   │ • Bash       │    │ • Lit Review    │
  │ • UX Designer │   │              │    │ • Design System │
  └───────┬───────┘   └──────┬───────┘    └────────┬────────┘
          │                   │                      │
          └───────────────────┼──────────────────────┘
                              ▼
                  ┌───────────────────────┐
                  │   Shared Subrecipes   │
                  │ • TDD Generic         │
                  │ • Static Analysis     │
                  │ • Git Best Practices  │
                  └───────────────────────┘
```

---

## Best Practices Enforced

| Practice | How Enforced |
|----------|-------------|
| **TDD** | Red-Green-Refactor subrecipes with `retry` blocks — tests MUST pass |
| **Docker-Based ML** | All ML training/serving/evaluation runs inside containers via `docker-ml-environment` subrecipe |
| **Modularity** | Hard limits: max 400 lines/file, 30 lines/function, 7 public methods/class |
| **Type Safety** | Language-appropriate type checkers run via `static-analysis` subrecipe |
| **Security** | OWASP Top 10, secret detection, dependency CVE scanning, no hardcoded credentials |
| **Git Hygiene** | Conventional Commits, PR templates, pre-commit hooks |
| **Documentation** | API docs, inline docs, architecture diagrams (Mermaid) |
| **Performance** | Measure-first methodology, benchmark tests, profiling |
| **Dependencies** | Vulnerability audits, license compliance, unused detection |
| **Scientific Rigor** | PRISMA lit review, IEEE citations, statistical significance testing |
| **Mathematical Precision** | LaTeX notation conventions, derivations from first principles |
| **Accessibility** | WCAG 2.2 AA audit, keyboard navigation, screen reader support, contrast verification |
| **UX Quality** | Nielsen's 10 heuristics, JTBD user research, responsive specs, design token consistency |
| **Reproducibility** | Docker containers, MLflow experiment tracking, seed management |

---

## Supported Languages

All general recipes auto-detect and support these languages:

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
| PostgreSQL | — | — | — | pgTAP |
| Bash | shellcheck | shfmt | — | bats-core |

---

## Quick Start

See **[TUTORIAL.md](TUTORIAL.md)** for step-by-step usage with Goose CLI, including real use-case examples.

### Run from CLI

```bash
# Run any recipe
goose run --recipe general/code-reviewer.yaml

# Language expert
goose run --recipe general/languages/python-expert.yaml

# ML research
goose run --recipe general/ai-researcher.yaml
```

### Import into Goose Desktop

1. Open **Goose Desktop** → **Settings** → **Recipe Library**
2. Add from local path or import the YAML file

### Customize for Your Project

1. Fork this repo
2. Copy the recipe you want to customize
3. Update the `instructions` section with your project context
4. Adjust `retry.checks` commands for your test runners

---

## License

MIT
