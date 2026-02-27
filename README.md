# AI Agent Recipes

A curated collection of AI agent configurations for **Goose** (by Block) and **Claude Code** (by Anthropic). Each agent enforces best practices, TDD, and language-specific conventions.

## Repository Structure

```
.
├── goose/              # Goose agent recipes (YAML)
│   ├── README.md       # Goose-specific documentation
│   ├── TUTORIAL.md     # Step-by-step usage guide
│   └── general/
│       ├── *.yaml              # 10 core recipes
│       ├── languages/*.yaml    # 5 language experts
│       └── subrecipes/*.yaml   # 10 shared subrecipes
│
├── claude/             # Claude Code agents (Markdown)
│   ├── README.md       # Claude-specific documentation
│   └── agents/
│       ├── *.md                # 8 core agents
│       ├── languages/*.md      # 5 language experts
│       └── specialized/*.md    # 2 specialized agents
│
└── README.md           # This file
```

## Quick Start

### Goose (Block)
```bash
# Run a recipe directly
goose run --recipe goose/general/code-reviewer.yaml

# With parameters
goose run --recipe goose/general/debugging-agent.yaml \
  --params symptom="TypeError in auth middleware" project_path="."
```

### Claude Code (Anthropic)
```bash
# Install agents (project-level)
mkdir -p .claude/agents
cp claude/agents/*.md .claude/agents/
cp -r claude/agents/languages .claude/agents/
cp -r claude/agents/specialized .claude/agents/

# Or user-level (available in all projects)
cp claude/agents/*.md ~/.claude/agents/
cp -r claude/agents/languages ~/.claude/agents/
cp -r claude/agents/specialized ~/.claude/agents/

# Agents activate automatically — just describe your task
claude
> Review the auth module for security issues
# → Delegates to security-auditor agent

> Debug the failing test in user_service
# → Delegates to debugger agent
```

## Agent Catalog

### Core Agents (8)
| Agent | Goose | Claude | Purpose |
|-------|-------|--------|---------|
| Code Reviewer | ✅ | ✅ | Correctness, security, performance, maintainability review |
| Debugger | ✅ | ✅ | Scientific debugging: observe → hypothesize → test → fix |
| Security Auditor | ✅ | ✅ | OWASP Top 10, secret detection, CVE scanning, compliance |
| Performance Optimizer | ✅ | ✅ | Measure → analyze → optimize → validate (data-driven) |
| Documentation Agent | ✅ | ✅ | API docs, READMEs, Mermaid diagrams, changelogs |
| API Designer | ✅ | ✅ | REST/GraphQL/gRPC with proper HTTP semantics, OpenAPI |
| Dependency Auditor | ✅ | ✅ | Vulnerability, license, unused deps, size analysis |
| Project Bootstrapper | ✅ | ✅ | Scaffold projects with TDD, CI/CD, Docker, linting |

### Language Experts (5)
| Agent | Languages/Focus |
|-------|----------------|
| Python Expert | Modern Python 3.10+, PEP 604/612/695, pytest, FastAPI/Django/PyTorch |
| Flutter Expert | Dart 3.x sealed classes, Riverpod, go_router, clean architecture |
| Rust Expert | Ownership/lifetimes, tokio async, thiserror/anyhow, proptest |
| PostgreSQL Expert | Schema design, keyset pagination, RLS, BRIN indexes, partitioning |
| Bash Expert | Defensive scripting, CI/CD pipelines, bats-core testing |

### Specialized Agents (2)
| Agent | Goose | Claude | Purpose |
|-------|-------|--------|---------|
| AI/ML Researcher | ✅ (1165 lines) | ✅ | Literature review, ML design, math formulation, MLflow, Docker |
| UX Designer | ✅ (863 lines) | ✅ | Journey mapping, wireframes, design systems, WCAG 2.2 |

### Goose-Only Subrecipes (10)
Shared workflows that Goose recipes delegate to:
| Subrecipe | Purpose |
|-----------|---------|
| `language-detection` | Auto-detect language, framework, toolchain |
| `tdd-generic` | Red-Green-Refactor cycle for any language |
| `static-analysis` | Linters, formatters, type checkers |
| `git-best-practices` | Conventional commits, PR prep |
| `arxiv-search` | arXiv API integration for paper discovery |
| `citation-graph` | Semantic Scholar citation graph + PageRank |
| `mlflow-tracking` | MLflow experiment tracking + Optuna HPO |
| `docker-ml-environment` | Docker-based ML development setup |
| `literature-review` | PRISMA-inspired systematic review |
| `design-system` | Design tokens and component specs |

## Enforced Practices

All agents enforce these principles regardless of platform:

| Practice | How Enforced |
|----------|-------------|
| **TDD** | Every agent requires tests FIRST — Red-Green-Refactor is mandatory |
| **Language best practices** | Per-language checklists (PEP 484 for Python, Effective Dart, etc.) |
| **Modularity** | Max 400 lines/file, 30 lines/function, 7 public methods/class |
| **Security** | Secret detection, OWASP checks, regression tests for vulnerabilities |
| **Docker** | ML work requires Docker environments for reproducibility |
| **Accessibility** | UX work requires WCAG 2.2 AA compliance |

## Format Comparison

| Feature | Goose (YAML) | Claude Code (Markdown) |
|---------|-------------|----------------------|
| File format | `.yaml` with structured fields | `.md` with YAML frontmatter |
| Parameters | Typed `parameters:` with defaults | Natural language in prompt |
| Sub-delegation | `sub_recipes:` paths | Chain agents via main conversation |
| Retry logic | `retry:` with shell checks | `hooks:` with exit codes |
| Tool access | `extensions:` (builtin/MCP) | `tools:` allowlist |
| Persistent memory | None | `memory: user/project/local` |
| Model control | `settings.temperature` | `model: sonnet/opus/haiku` |

## Contributing

1. Fork the repository
2. Add or modify agents in both `goose/` and `claude/` directories
3. Ensure TDD is enforced in every new agent
4. Submit a PR with description of the agent's purpose

## License

MIT
