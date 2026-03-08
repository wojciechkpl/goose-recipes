# AI Agent Recipes

A curated collection of AI agent configurations for **Goose** (by Block) and **Claude Code** (by Anthropic). Each agent enforces best practices, TDD, and language-specific conventions.

Both platforms share the same best practices and domain knowledge — only the format differs: YAML for Goose, Markdown for Claude Code.

## Repository Structure

```
.
├── shared/                 # Cross-platform standards
│   ├── severity-scale.md       # Shared 🔴🟠🟡🔵ℹ️ severity classification
│   └── naming-conventions.md   # Shared naming standards
│
├── goose/                  # Goose agent recipes (YAML)
│   ├── README.md               # Goose-specific documentation
│   ├── TUTORIAL.md             # Step-by-step Goose usage guide
│   ├── general/
│   │   ├── *.yaml              # 10 core recipes
│   │   ├── languages/*.yaml    # 5 language experts
│   │   └── subrecipes/*.yaml   # 10 shared subrecipes
│   └── coding_agent_context/   # Portable orchestration framework
│       ├── missions/           # Step-by-step workflow instructions
│       ├── roles/              # Sub-agent identity definitions
│       ├── recipes/            # Goose execution configs
│       └── tools/              # Docker infrastructure scripts
│
├── claude/                 # Claude Code agents (Markdown)
│   ├── README.md               # Claude-specific documentation
│   ├── CONVENTIONS.md          # Global rules for all Claude agents
│   └── agents/
│       ├── *.md                # 8 core agents
│       ├── languages/*.md      # 5 language experts
│       ├── specialized/*.md    # 2 specialized agents
│       └── subrecipes/*.md     # 6 shared subrecipes
│
└── README.md               # This file
```

---

## Quick Start

### Goose (Block)
```bash
# Install Goose
brew install block/tap/goose

# Run a recipe directly
goose run --recipe goose/general/code-reviewer.yaml

# With parameters
goose run --recipe goose/general/debugger.yaml \
  --params symptom="TypeError in auth middleware" project_path="."

# Language expert
goose run --recipe goose/general/languages/python-expert.yaml

# ML research
goose run --recipe goose/general/ai-researcher.yaml
```

See [goose/TUTORIAL.md](goose/TUTORIAL.md) for 15 detailed use-case walkthroughs.

### Claude Code (Anthropic)
```bash
# Install agents (project-level — recommended for teams)
mkdir -p .claude/agents/languages .claude/agents/specialized .claude/agents/subrecipes
cp claude/agents/*.md .claude/agents/
cp claude/agents/languages/*.md .claude/agents/languages/
cp claude/agents/specialized/*.md .claude/agents/specialized/
cp claude/agents/subrecipes/*.md .claude/agents/subrecipes/

# Or user-level (available in all your projects)
mkdir -p ~/.claude/agents/languages ~/.claude/agents/specialized ~/.claude/agents/subrecipes
cp claude/agents/*.md ~/.claude/agents/
cp claude/agents/languages/*.md ~/.claude/agents/languages/
cp claude/agents/specialized/*.md ~/.claude/agents/specialized/
cp claude/agents/subrecipes/*.md ~/.claude/agents/subrecipes/

# Agents activate automatically — just describe your task
claude
> Review the auth module for security issues
# → Delegates to security-auditor agent

> Debug the failing test in user_service
# → Delegates to debugger agent
```

See [claude/README.md](claude/README.md) for full installation and usage details.

---

## Agent Catalog

### Core Agents (10)
| Agent | Goose | Claude | Purpose |
|-------|-------|--------|---------|
| Code Reviewer | `general/code-reviewer.yaml` | `agents/code-reviewer.md` | Correctness, security, performance, maintainability review |
| Debugger | `general/debugger.yaml` | `agents/debugger.md` | Scientific debugging: observe → hypothesize → test → fix |
| Security Auditor | `general/security-auditor.yaml` | `agents/security-auditor.md` | OWASP Top 10, secret detection, CVE scanning, compliance |
| Performance Optimizer | `general/performance-optimizer.yaml` | `agents/performance-optimizer.md` | Measure → analyze → optimize → validate (data-driven) |
| Documentation Agent | `general/documentation-agent.yaml` | `agents/documentation-agent.md` | API docs, READMEs, Mermaid diagrams, changelogs |
| API Designer | `general/api-designer.yaml` | `agents/api-designer.md` | REST/GraphQL/gRPC with proper HTTP semantics, OpenAPI |
| Dependency Auditor | `general/dependency-auditor.yaml` | `agents/dependency-auditor.md` | Vulnerability, license, unused deps, size analysis |
| Project Bootstrapper | `general/project-bootstrapper.yaml` | `agents/project-bootstrapper.md` | Scaffold projects with TDD, CI/CD, Docker, linting |
| AI/ML Researcher | `general/ai-researcher.yaml` | `agents/specialized/ai-researcher.md` | Literature review, ML design, math formulation, MLflow |
| UX Designer | `general/ux-designer.yaml` | `agents/specialized/ux-designer.md` | Journey mapping, wireframes, design systems, WCAG 2.2 |

### Language Experts (5)
| Agent | Goose | Claude | Focus |
|-------|-------|--------|-------|
| Python Expert | `languages/python-expert.yaml` | `languages/python-expert.md` | Python 3.10+, PEP 604/612/695, pytest, FastAPI/Django/PyTorch |
| Flutter Expert | `languages/flutter-expert.yaml` | `languages/flutter-expert.md` | Dart 3.x sealed classes, Riverpod, go_router, clean architecture |
| Rust Expert | `languages/rust-expert.yaml` | `languages/rust-expert.md` | Ownership/lifetimes, tokio async, thiserror/anyhow, proptest |
| PostgreSQL Expert | `languages/postgresql-expert.yaml` | `languages/postgresql-expert.md` | Schema design, keyset pagination, RLS, BRIN indexes |
| Bash Expert | `languages/bash-expert.yaml` | `languages/bash-expert.md` | Defensive scripting, CI/CD pipelines, bats-core testing |

### Subrecipes / Shared Workflows
| Subrecipe | Goose | Claude | Purpose |
|-----------|-------|--------|---------|
| TDD Generic | `subrecipes/tdd-generic.yaml` | `subrecipes/tdd-generic.md` | Red-Green-Refactor cycle for any language |
| Language Detection | `subrecipes/language-detection.yaml` | `subrecipes/language-detection.md` | Auto-detect project stack |
| Static Analysis | `subrecipes/static-analysis.yaml` | `subrecipes/static-analysis.md` | Linters, formatters, type checkers |
| Git Best Practices | `subrecipes/git-best-practices.yaml` | `subrecipes/git-best-practices.md` | Conventional commits, branch naming, PR hygiene |
| Docker ML Environment | `subrecipes/docker-ml-environment.yaml` | `subrecipes/docker-ml-environment.md` | Containerized ML with GPU support |
| MLflow Tracking | `subrecipes/mlflow-tracking.yaml` | `subrecipes/mlflow-tracking.md` | Experiment tracking, model registry, HPO |
| arXiv Search | `subrecipes/arxiv-search.yaml` | — | arXiv API paper discovery |
| Citation Graph | `subrecipes/citation-graph.yaml` | — | Semantic Scholar citation analysis |
| Literature Review | `subrecipes/literature-review.yaml` | — | PRISMA-inspired systematic review |
| Design System | `subrecipes/design-system.yaml` | — | Design tokens, component specs |

### Goose-Only: Coding Agent Context
A portable orchestration framework for complex multi-step workflows. See [goose/coding_agent_context/](goose/coding_agent_context/).

| Component | Purpose |
|-----------|---------|
| **Missions** (9) | Step-by-step workflows: tactical updates, TDD, architecture, data exploration, ML research, docs, code review |
| **Roles** (7) | Sub-agent identities: analyst, architect, developer, QA, doc writer, code reviewer, ML researcher |
| **Tools** (6) | Docker-based infrastructure: test runner, dev container, data explorer |

---

## Tutorial

### 1. Review Code Before a PR

**Goose:**
```bash
goose run --recipe goose/general/code-reviewer.yaml \
  --params target_path="src/" review_depth="deep" focus_areas="all"
```

**Claude Code:**
```
> Use the code-reviewer agent to review src/ with deep focus on all areas
```

Both produce a structured report:
```
# Code Review: src/
## Verdict: REQUEST CHANGES
## Critical Issues (🔴)
  src/auth/handler.py:45 — SQL injection via string interpolation
## Major Issues (🟠)
  src/api/users.py:23 — N+1 query in user list endpoint
## Suggestions (🔵)
  src/models/user.py:12 — Consider using dataclass instead of dict
```

### 2. Debug a Failing Test

**Goose:**
```bash
goose run --recipe goose/general/debugger.yaml \
  --params symptom="test_user_auth fails with 401" bug_type="logic_error"
```

**Claude Code:**
```
> Debug why test_user_auth fails with a 401 error
```

The debugger follows a scientific method:
1. **OBSERVE** — Reproduce the failure, read error output
2. **HYPOTHESIZE** — Rank likely causes (expired token? wrong endpoint? missing header?)
3. **TEST** — Isolate and test each hypothesis
4. **FIX** — Write regression test FIRST (RED), then apply minimal fix (GREEN)
5. **VERIFY** — Run full test suite, confirm no regressions

### 3. Bootstrap a New Project

**Goose:**
```bash
goose run --recipe goose/general/project-bootstrapper.yaml \
  --params project_name="my-api" language="python" project_type="api_service"
```

**Claude Code:**
```
> Use the project-bootstrapper agent to create a Python API service called "my-api"
```

Creates a production-ready scaffold:
```
my-api/
├── src/my_api/
│   ├── api/v1/routes/
│   ├── services/
│   ├── models/
│   └── schemas/
├── tests/
├── pyproject.toml          # ruff + mypy strict
├── Dockerfile              # Multi-stage, non-root
├── docker-compose.yaml
├── .github/workflows/ci.yml
├── Makefile
└── .pre-commit-config.yaml
```

### 4. Security Audit Before Release

**Goose:**
```bash
goose run --recipe goose/general/security-auditor.yaml \
  --params audit_scope="full" compliance_framework="owasp"
```

**Claude Code:**
```
> Run a full OWASP security audit on this project
```

Produces:
```
# Security Audit Report
## Risk Score: 6.2/10
## Critical (🔴): 2 findings
  - Hardcoded AWS key in src/config.py:12
  - SQL injection in src/api/search.py:34
## High (🟠): 3 findings
  - Missing rate limiting on /api/auth/login
  - Session tokens not rotated after password change
  - Debug mode enabled in production config
```

### 5. ML Research Workflow

**Goose:**
```bash
goose run --recipe goose/general/ai-researcher.yaml \
  --params research_topic="contrastive learning for recommendations" \
          research_type="literature_review" scope="focused"
```

**Claude Code:**
```
> Use the ai-researcher agent to survey contrastive learning for recommendation systems
```

Delivers:
1. PRISMA-style literature review with arXiv search
2. Citation graph analysis (PageRank, influence flow)
3. 3-5 solution candidates with architecture diagrams
4. Weighted tradeoff decision matrix
5. Mathematical formulation with gradient computation
6. Docker-based experiment setup with MLflow tracking

### 6. Design a REST API

**Goose:**
```bash
goose run --recipe goose/general/api-designer.yaml \
  --params api_name="user-service" api_style="rest" api_maturity="production"
```

**Claude Code:**
```
> Use the api-designer agent to design a production REST API for the user service
```

Produces: domain model (Mermaid ER), endpoint specs, OpenAPI 3.1 schema, RFC 7807 error format, cursor-based pagination, auth patterns, and contract-first TDD plan.

### 7. UX Design with Accessibility

**Goose:**
```bash
goose run --recipe goose/general/ux-designer.yaml \
  --params task_type="full_ux_process" platform="mobile" wcag_level="AA"
```

**Claude Code:**
```
> Use the ux-designer agent for a full UX process on the mobile onboarding flow, targeting WCAG AA
```

Delivers: user personas, journey maps (Mermaid), information architecture, ASCII wireframes for all 7 screen states, design tokens as CSS/Dart code, WCAG 2.2 AA audit, responsive breakpoints, and TDD test plan.

### 8. Use Language Experts

**Goose:**
```bash
# Refactor Python code
goose run --recipe goose/general/languages/python-expert.yaml \
  --params target_path="src/services/" task="refactor"

# Optimize PostgreSQL queries
goose run --recipe goose/general/languages/postgresql-expert.yaml \
  --params target_path="migrations/" task="optimize_queries"
```

**Claude Code:**
```
> Have the python-expert agent refactor src/services/
> Use the postgresql-expert to optimize the slow queries in our migrations
```

### 9. Chain Multiple Agents

**Goose** (sequential recipe execution):
```bash
# Design → Implement → Review → Document
goose run --recipe goose/general/api-designer.yaml \
  --params api_name="orders" api_style="rest"

goose run --recipe goose/general/languages/python-expert.yaml \
  --params task="implement" target_path="src/api/orders/"

goose run --recipe goose/general/code-reviewer.yaml \
  --params target_path="src/api/orders/" review_depth="deep"

goose run --recipe goose/general/documentation-agent.yaml \
  --params target_path="src/api/orders/" doc_type="api_reference"
```

**Claude Code** (agents chain automatically via conversation):
```
> Design a REST API for the orders service, then implement it in Python,
  review the code, and generate API documentation
```

### 10. Goose: Coding Agent Context (Multi-Step Missions)

For complex workflows that need persistent state, sub-agent dispatch, and Docker execution:

```bash
# Architecture design for a new feature
goose run --recipe goose/coding_agent_context/recipes/mission_architecture_design.yaml \
  --params feature="user-recommendations"

# TDD implementation (reads the design doc from previous step)
goose run --recipe goose/coding_agent_context/recipes/mission_tdd.yaml \
  --params feature="user-recommendations"

# Code review
goose run --recipe goose/coding_agent_context/recipes/mission_review_code_change.yaml \
  --params feature="user-recommendations"
```

See [goose/coding_agent_context/MISSION_INDEX.md](goose/coding_agent_context/MISSION_INDEX.md) for the full mission selection guide.

---

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
| **Severity scale** | Shared 🔴🟠🟡🔵ℹ️ classification (see `shared/severity-scale.md`) |
| **Naming** | Consistent conventions across platforms (see `shared/naming-conventions.md`) |

---

## Format Comparison

| Feature | Goose (YAML) | Claude Code (Markdown) |
|---------|-------------|----------------------|
| File format | `.yaml` with structured fields | `.md` with YAML frontmatter |
| Parameters | Typed `parameters:` with defaults and options | Natural language in prompt |
| Sub-delegation | `sub_recipes:` with file paths | Chain agents via main conversation |
| Retry logic | `retry:` block with shell checks | `hooks:` with exit codes |
| Tool access | `extensions:` (builtin/MCP) | `tools:` allowlist |
| Persistent memory | None | `memory: user/project/local` |
| Model control | `settings.temperature` | `model: sonnet/opus/haiku` |
| Composability | Recipe chaining via CLI | Automatic delegation in conversation |

---

## Choosing Between Platforms

| If you need... | Use |
|----------------|-----|
| Parameterized recipes with typed inputs | **Goose** |
| Persistent agent memory across sessions | **Claude Code** |
| Sub-agent orchestration with role isolation | **Goose** (coding_agent_context) |
| Automatic delegation based on task description | **Claude Code** |
| Docker-based execution with safety constraints | **Goose** (coding_agent_context) |
| CI/CD integration with recipe execution | **Goose** |
| Interactive development with conversation context | **Claude Code** |
| Multi-step missions with progress tracking | **Goose** (coding_agent_context) |

---

## Contributing

1. Fork the repository
2. Add or modify agents in both `goose/` and `claude/` directories
3. Ensure TDD is enforced in every new agent
4. Follow naming conventions in `shared/naming-conventions.md`
5. Update agent catalogs in this README and platform-specific READMEs
6. Submit a PR with description of the agent's purpose

When adding a new recipe:
- Create it in both `goose/general/` (YAML) and `claude/agents/` (Markdown)
- If it's a shared workflow, add it to `subrecipes/` on both platforms
- Update the Agent Catalog tables in all three READMEs

---

## License

MIT
