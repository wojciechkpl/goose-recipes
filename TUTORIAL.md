# Goose Recipes — Step-by-Step Tutorial

A practical guide to using these recipes with the [Goose CLI](https://github.com/block/goose). Each section is a real use case with exact commands.

---

## Table of Contents

1. [Setup](#1-setup)
2. [Use Case: Review Code Before a PR](#2-use-case-review-code-before-a-pr)
3. [Use Case: Debug a Failing Test](#3-use-case-debug-a-failing-test)
4. [Use Case: Bootstrap a New Python Project](#4-use-case-bootstrap-a-new-python-project)
5. [Use Case: Optimize Slow Database Queries](#5-use-case-optimize-slow-database-queries)
6. [Use Case: Security Audit Before Release](#6-use-case-security-audit-before-release)
7. [Use Case: ML Research — From Literature to Docker-based Experiments](#7-use-case-ml-research--from-literature-to-docker-based-experiments)
8. [Use Case: Write API Documentation](#8-use-case-write-api-documentation)
9. [Use Case: Design a REST API](#9-use-case-design-a-rest-api)
10. [Use Case: Audit Dependencies](#10-use-case-audit-dependencies)
11. [Use Case: Refactor with a Language Expert](#11-use-case-refactor-with-a-language-expert)
12. [Advanced: Chaining Recipes](#12-advanced-chaining-recipes)
13. [Advanced: Team Setup with Shared Recipes](#13-advanced-team-setup-with-shared-recipes)
14. [Advanced: Scheduled Recipes](#14-advanced-scheduled-recipes)
15. [Recipe Reference](#15-recipe-reference)

---

## 1. Setup

### Install Goose

```bash
# macOS
brew install block/tap/goose

# Or via shell script
curl -fsSL https://github.com/block/goose/releases/latest/download/install.sh | bash
```

### Clone this recipe repository

```bash
git clone https://github.com/wojciechkpl/goose-recipes.git ~/goose-recipes
```

### Configure recipe path (optional, enables running recipes by name)

```bash
# Add to your shell profile (~/.zshrc, ~/.bashrc)
export GOOSE_RECIPE_PATH="$HOME/goose-recipes/general"
```

Or set the GitHub repo for remote access:

```bash
# In ~/.config/goose/config.yaml
GOOSE_RECIPE_GITHUB_REPO: "wojciechkpl/goose-recipes"
```

### Verify setup

```bash
goose recipe validate ~/goose-recipes/general/code-reviewer.yaml
```

---

## 2. Use Case: Review Code Before a PR

**Scenario**: You've made changes to your project and want a thorough code review before opening a PR.

### Step 1: Navigate to your project

```bash
cd ~/my-project
```

### Step 2: Run the Code Reviewer recipe

```bash
goose run --recipe ~/goose-recipes/general/code-reviewer.yaml
```

### Step 3: When prompted for parameters

The recipe will ask for:
- **`target_path`**: The file or directory to review (e.g., `src/auth/` or `src/api/users.py`)
- **`review_focus`**: Choose from `general`, `security`, `performance`, or `modularity`

### What happens

1. The agent auto-detects your project language (via the `language-detection` subrecipe)
2. Runs static analysis (linters, type checkers) for your language
3. Checks against a language-specific review checklist
4. Produces a structured report: **Critical Issues → Warnings → Suggestions → Positive Observations**
5. Verifies TDD compliance (are tests written for changed code?)

### Example output

```
## Code Review: src/auth/

### Critical Issues
1. `login()` at line 45: SQL query uses f-string interpolation — vulnerable to SQL injection
2. `create_user()` missing input validation on email field

### Warnings
1. `auth_service.py` is 520 lines — exceeds 400-line limit, split into auth + session modules

### Suggestions
1. Consider using `@dataclass(frozen=True, slots=True)` for `UserCredentials`

### Positive Observations
1. Good use of dependency injection in `AuthRouter`
2. Type hints on all public functions
```

---

## 3. Use Case: Debug a Failing Test

**Scenario**: A test is failing and you can't figure out why.

### Run the Debugging Agent

```bash
goose run --recipe ~/goose-recipes/general/debugging-agent.yaml
```

### Parameters

- **`target_path`**: Path to the failing test or module (e.g., `tests/test_payments.py`)
- **`bug_description`**: Describe the failure (e.g., `"test_charge_card fails with timeout after upgrading stripe SDK"`)

### What the agent does (Scientific Debugging Method)

```
Phase 1: OBSERVE
  → Reads the failing test, error traceback, recent git changes

Phase 2: HYPOTHESIZE
  → Generates ranked hypotheses with testable predictions

Phase 3: TEST
  → Writes a minimal reproduction script
  → Tests each hypothesis systematically (no random guessing!)

Phase 4: FIX
  → Writes the failing test FIRST (TDD — red)
  → Implements the fix (green)
  → Runs full test suite to verify no regressions

Phase 5: VERIFY
  → Confirms the original test passes
  → Documents root cause for future reference
```

---

## 4. Use Case: Bootstrap a New Python Project

**Scenario**: You want to start a new Python project with proper structure, testing, CI/CD, and Docker.

### Run the Project Bootstrapper

```bash
goose run --recipe ~/goose-recipes/general/project-bootstrapper.yaml
```

### Parameters

- **`project_name`**: e.g., `"my-ml-service"`
- **`project_type`**: `api`, `library`, `cli`, `mobile_app`, `data_pipeline`
- **`language`**: `python` (auto-detected if existing project, or specify for new)
- **`extras`**: `full` (includes Docker, CI/CD, docs) or `minimal`

### What gets generated

```
my-ml-service/
├── src/my_ml_service/
│   ├── __init__.py
│   ├── main.py
│   └── config.py
├── tests/
│   ├── conftest.py
│   └── test_main.py          # ← Tests are generated FIRST (TDD!)
├── pyproject.toml             # Modern Python packaging
├── Dockerfile                 # Multi-stage build
├── docker-compose.yml
├── .github/workflows/ci.yml  # GitHub Actions CI/CD
├── Makefile                   # make test, make lint, make build
├── .pre-commit-config.yaml
└── README.md
```

---

## 5. Use Case: Optimize Slow Database Queries

**Scenario**: Your API endpoints are slow and you suspect database queries are the bottleneck.

### Option A: Use the Performance Optimizer

```bash
goose run --recipe ~/goose-recipes/general/performance-optimizer.yaml
```

### Option B: Use the PostgreSQL Expert (for deep DB-specific optimization)

```bash
goose run --recipe ~/goose-recipes/general/languages/postgresql-expert.yaml
```

### Performance Optimizer workflow

```
Phase 1: MEASURE
  → Profiles the slow endpoints
  → Identifies the actual bottleneck (not guessing!)

Phase 2: ANALYZE
  → Runs EXPLAIN ANALYZE on slow queries
  → Checks for N+1 queries, missing indexes, full table scans

Phase 3: OPTIMIZE
  → Writes benchmark test FIRST (TDD)
  → Implements optimizations (indexes, query rewrites, caching)

Phase 4: VALIDATE
  → Runs benchmark to confirm improvement
  → Ensures no correctness regressions
```

---

## 6. Use Case: Security Audit Before Release

**Scenario**: You're about to ship a release and want to verify there are no security vulnerabilities.

### Run the Security Auditor

```bash
goose run --recipe ~/goose-recipes/general/security-auditor.yaml
```

### Parameters

- **`target_path`**: Root of the project (e.g., `.` or `src/`)
- **`audit_scope`**: `full`, `owasp_top_10`, `secrets`, `dependencies`, `infrastructure`

### What gets checked

| Category | Checks |
|----------|--------|
| **OWASP Top 10** | Injection, broken auth, XSS, SSRF, insecure deserialization |
| **Secrets** | API keys, passwords, tokens in code or config files |
| **Dependencies** | Known CVEs via `pip-audit`, `npm audit`, `cargo audit` |
| **Infrastructure** | Docker (no `--privileged`, no root), compose (no hardcoded secrets) |
| **Code** | Input validation, parameterized queries, proper auth checks |

### TDD enforcement

The agent writes **security regression tests** for each finding — so vulnerabilities can't be silently reintroduced:

```python
# Example: generated security test
def test_sql_injection_prevented():
    """Regression test: SQL injection in user search (found in audit)."""
    malicious_input = "'; DROP TABLE users; --"
    response = client.get(f"/api/users?q={malicious_input}")
    assert response.status_code == 422  # Validation error, not 500
```

---

## 7. Use Case: ML Research — From Literature to Docker-based Experiments

**Scenario**: You want to research recommendation systems, find the best approach, implement it with proper experiment tracking, all running in Docker containers.

This is the most comprehensive recipe — it chains multiple subrecipes together.

### Step 1: Literature Review

```bash
goose run --recipe ~/goose-recipes/general/ai-researcher.yaml \
  --params research_phase=literature_review \
  --params research_question="collaborative filtering vs content-based for cold-start users" \
  --params ml_domain=recommendation_systems
```

**What happens**:
- Searches arXiv API for relevant papers (structured Boolean queries)
- Builds citation graph via Semantic Scholar (PageRank, cluster detection)
- Produces PRISMA-compliant systematic review with taxonomy mindmap

### Step 2: Solution Design with Tradeoff Analysis

```bash
goose run --recipe ~/goose-recipes/general/ai-researcher.yaml \
  --params research_phase=solution_design \
  --params research_question="collaborative filtering vs content-based for cold-start users" \
  --params ml_domain=recommendation_systems \
  --params constraints="<100ms inference latency, 10M users, cold-start problem"
```

**What happens**:
- Identifies 3-5 candidate solutions from the literature
- Generates weighted decision matrix (10 criteria)
- Produces Mermaid quadrant chart for visual tradeoff comparison
- Recommends approach with sensitivity analysis

### Step 3: Implementation with Docker + MLflow

```bash
goose run --recipe ~/goose-recipes/general/ai-researcher.yaml \
  --params research_phase=implementation \
  --params research_question="hybrid collaborative filtering with content features" \
  --params ml_domain=recommendation_systems \
  --params project_path=./my-recsys \
  --params mlflow_experiment=recsys-hybrid-v1
```

**What happens**:
1. Sets up Docker ML environment (via `docker-ml-environment` subrecipe):
   - `Dockerfile.base` (CUDA + Python + deps)
   - `Dockerfile.train` (training image)
   - `Dockerfile.serve` (slim inference image)
   - `docker-compose.yaml` with MLflow + PostgreSQL + MinIO
   - `Makefile` with `make train`, `make serve`, `make test`
2. Writes tests FIRST (TDD)
3. Implements model matching the mathematical formulation
4. Sets up MLflow experiment tracking (params, metrics, artifacts)
5. All training runs inside Docker: `docker compose run --rm train`

### Step 4: Evaluation

```bash
goose run --recipe ~/goose-recipes/general/ai-researcher.yaml \
  --params research_phase=evaluation \
  --params research_question="hybrid collaborative filtering with content features" \
  --params ml_domain=recommendation_systems \
  --params project_path=./my-recsys \
  --params mlflow_experiment=recsys-hybrid-v1
```

**What happens**:
- Runs evaluation inside Docker containers
- Produces results table with statistical significance (paired t-tests, confidence intervals)
- Generates MLflow comparison dashboard
- Creates ablation study and error analysis

### Or run the full pipeline at once

```bash
goose run --recipe ~/goose-recipes/general/ai-researcher.yaml \
  --params research_phase=full_pipeline \
  --params research_question="hybrid collaborative filtering with content features" \
  --params ml_domain=recommendation_systems \
  --params project_path=./my-recsys \
  --params mlflow_experiment=recsys-hybrid-v1
```

---

## 8. Use Case: Write API Documentation

**Scenario**: Your API lacks documentation and you need to generate it.

```bash
goose run --recipe ~/goose-recipes/general/documentation-agent.yaml
```

### Parameters

- **`target_path`**: Path to the codebase (e.g., `src/api/`)
- **`doc_type`**: `api`, `inline`, `readme`, `architecture`, `changelog`

### What gets generated

| Doc Type | Output |
|----------|--------|
| `api` | OpenAPI spec, endpoint docs with request/response examples |
| `inline` | Docstrings on all public functions/classes |
| `architecture` | Mermaid architecture diagrams + written descriptions |
| `readme` | Project README with setup, usage, contributing guide |
| `changelog` | Conventional Commits-based changelog |

---

## 9. Use Case: Design a REST API

**Scenario**: You need to design a new API endpoint (or redesign an existing one) with proper HTTP semantics.

```bash
goose run --recipe ~/goose-recipes/general/api-designer.yaml
```

### Parameters

- **`target_path`**: Where to create/modify the API code
- **`api_style`**: `rest`, `graphql`, or `grpc`
- **`api_description`**: What the API should do (e.g., `"user management with CRUD, pagination, filtering"`)

### What the agent produces

1. OpenAPI spec (or GraphQL schema, or .proto file)
2. **Contract tests FIRST** (TDD — tests the API spec before implementing)
3. Route handlers with proper HTTP status codes
4. Input validation (Pydantic, zod, serde — depends on language)
5. Error response format (RFC 7807 Problem Details)

---

## 10. Use Case: Audit Dependencies

**Scenario**: You want to check for vulnerabilities, outdated packages, and license compliance.

```bash
goose run --recipe ~/goose-recipes/general/dependency-auditor.yaml
```

### Parameters

- **`target_path`**: Project root
- **`audit_scope`**: `full`, `vulnerabilities`, `licenses`, `outdated`, `unused`, `size`

### What gets checked

```
1. VULNERABILITIES
   → pip-audit / npm audit / cargo audit
   → CVE database lookup with severity scores

2. LICENSES
   → Checks all transitive dependencies
   → Flags GPL/AGPL in proprietary projects
   → Generates license compliance report

3. OUTDATED
   → Lists all outdated packages with changelogs
   → Prioritizes security updates

4. UNUSED
   → Detects imported-but-unused dependencies
   → Estimates size savings from removal

5. SIZE
   → Analyzes bundle/package size
   → Identifies heavy dependencies with lighter alternatives
```

---

## 11. Use Case: Refactor with a Language Expert

**Scenario**: You have Python code that needs modernization (e.g., old-style type hints, no dataclasses, poor async patterns).

### Run the Python Expert

```bash
goose run --recipe ~/goose-recipes/general/languages/python-expert.yaml
```

### Parameters

- **`target_path`**: File or directory to refactor
- **`task_type`**: `refactor`, `review`, `implement`, `debug`, `optimize`

### Other language experts work the same way

```bash
# Flutter/Dart
goose run --recipe ~/goose-recipes/general/languages/flutter-expert.yaml

# Rust
goose run --recipe ~/goose-recipes/general/languages/rust-expert.yaml

# PostgreSQL
goose run --recipe ~/goose-recipes/general/languages/postgresql-expert.yaml

# Bash
goose run --recipe ~/goose-recipes/general/languages/bash-expert.yaml
```

### What makes language experts different from general recipes

| General Recipe | Language Expert |
|---|---|
| Knows *about* Python | Knows Python **deeply** |
| Runs `ruff` | Knows PEP 604 (`str \| None` not `Optional[str]`) |
| Suggests "add tests" | Knows `pytest.mark.parametrize` + `hypothesis` |
| Suggests "use async" | Knows `asyncio.TaskGroup` > `gather` for structured concurrency |

---

## 12. Advanced: Chaining Recipes

For complex workflows, you can chain recipes in a shell script:

```bash
#!/bin/bash
# full-review.sh — Run security + code review + dependency audit

PROJECT_PATH="$(pwd)"

echo "=== Step 1: Security Audit ==="
goose run --recipe ~/goose-recipes/general/security-auditor.yaml \
  --params target_path="$PROJECT_PATH" \
  --params audit_scope=full

echo "=== Step 2: Code Review ==="
goose run --recipe ~/goose-recipes/general/code-reviewer.yaml \
  --params target_path="$PROJECT_PATH/src" \
  --params review_focus=general

echo "=== Step 3: Dependency Audit ==="
goose run --recipe ~/goose-recipes/general/dependency-auditor.yaml \
  --params target_path="$PROJECT_PATH" \
  --params audit_scope=full

echo "=== All checks complete ==="
```

---

## 13. Advanced: Team Setup with Shared Recipes

### Option A: Set `GOOSE_RECIPE_PATH` (local)

```bash
# In team's shared shell profile or .envrc
export GOOSE_RECIPE_PATH="/path/to/goose-recipes/general"

# Now anyone can run by filename
goose run --recipe code-reviewer.yaml
goose run --recipe security-auditor.yaml
```

### Option B: Set GitHub repo (remote)

```bash
# In ~/.config/goose/config.yaml
GOOSE_RECIPE_GITHUB_REPO: "your-org/goose-recipes"

# Now anyone can run by recipe name (auto-downloaded from GitHub)
goose run --recipe code-reviewer
goose run --recipe ai-researcher
```

### Option C: Share via deeplink

```bash
# Generate a shareable link for a specific recipe + params
goose recipe deeplink ~/goose-recipes/general/code-reviewer.yaml \
  --param review_focus=security

# Output: goose://recipe?...  (clickable in Goose Desktop)
```

---

## 14. Advanced: Scheduled Recipes

Run recipes on a schedule (e.g., daily security audit, weekly dependency check):

```bash
# Daily security scan at 9 AM
goose schedule add \
  --schedule-id daily-security \
  --cron "0 0 9 * * *" \
  --recipe-source ~/goose-recipes/general/security-auditor.yaml

# Weekly dependency audit on Monday at 8 AM
goose schedule add \
  --schedule-id weekly-deps \
  --cron "0 0 8 * * 1" \
  --recipe-source ~/goose-recipes/general/dependency-auditor.yaml
```

---

## 15. Recipe Reference

### All CLI Commands

| Command | Description |
|---------|-------------|
| `goose run --recipe <file>` | Run a recipe once and exit |
| `goose run --recipe <file> --interactive` | Run with interactive prompts |
| `goose run --recipe <file> --params key=value` | Pass parameters |
| `goose recipe validate <file>` | Validate recipe YAML format |
| `goose recipe open <file>` | Open recipe in Goose Desktop |
| `goose recipe deeplink <file>` | Generate shareable link |
| `goose schedule add --recipe-source <file> --cron "..."` | Schedule a recipe |
| `goose configure` | Interactive setup (provider, model, recipe repo) |

### Environment Variables

| Variable | Purpose |
|----------|---------|
| `GOOSE_RECIPE_PATH` | Local directories to search for recipes |
| `GOOSE_RECIPE_GITHUB_REPO` | GitHub repo for remote recipe access (e.g., `org/repo`) |

### Recipe YAML Schema (Quick Reference)

```yaml
version: "1.0.0"              # Required
title: "Recipe Name"           # Required
description: "What it does"    # Required

parameters:                     # Optional — dynamic inputs
  - key: target_path
    input_type: string          # string, number, select
    requirement: required       # required, optional, user_prompt
    description: "..."
    default: "..."              # Required for optional params
    options: [a, b, c]          # Only for select type

instructions: |                 # Required (or use prompt)
  You are an expert...

prompt: "Do the thing"          # Required (or use instructions)

extensions:                     # Optional — tools the agent needs
  - type: builtin
    name: developer
    timeout: 300

sub_recipes:                    # Optional — delegate to other recipes
  - name: "tdd_generic"
    path: "./subrecipes/tdd-generic.yaml"
    description: "..."

activities:                     # Optional — example prompts (UI buttons)
  - "Review code at src/"
  - "Audit dependencies"

retry:                          # Optional — validation with retry
  max_retries: 2
  checks:
    - type: shell
      command: "pytest tests/ -v"
  on_failure: "echo 'Tests failed, fixing...'"

settings:                       # Optional
  temperature: 0.3
  max_turns: 100
```

---

## Tips

1. **Always start with the right recipe** — Don't use the generic Code Reviewer for deep Python-specific issues. Use the Python Expert instead.

2. **Use `--interactive` for exploration** — When you're not sure what to ask for, interactive mode lets you have a conversation with the agent.

3. **Chain recipes for thorough reviews** — Security Audit → Code Review → Dependency Audit before every release.

4. **Set `GOOSE_RECIPE_PATH`** — So you can run recipes by name instead of full path.

5. **Docker-based ML is non-negotiable** — The AI Researcher recipe enforces containerized training. This prevents "works on my machine" issues and ensures reproducibility.

6. **TDD is enforced, not suggested** — Every recipe has `retry` blocks that verify tests pass. You literally can't succeed with broken tests.
