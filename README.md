# Goose Recipes

A collection of specialized [Goose](https://github.com/block/goose) agent recipes for software development workflows. These recipes enforce **Test-Driven Development**, **code modularity**, and **language-specific best practices** across full-stack projects.

## Overview

This recipe system uses a **hub-and-spoke architecture** — four main agent recipes that can delegate to three shared subrecipes for cross-cutting concerns.

```
┌─────────────────────┐     ┌──────────────────────┐
│ Solution Architect  │◄───►│  Refactoring Agent   │
│  (system design)    │     │  (code improvement)  │
└────────┬────────────┘     └──────────┬───────────┘
         │                             │
         ▼                             ▼
┌─────────────────────┐     ┌──────────────────────┐
│   AI Researcher     │◄───►│  Data Exploration    │
│  (ML experiments)   │     │  (data analysis)     │
└─────────────────────┘     └──────────────────────┘
         │                             │
         └──────────┬──────────────────┘
                    ▼
        ┌───────────────────────┐
        │    Shared Subrecipes  │
        │  • TDD Workflow       │
        │  • Code Review        │
        │  • Test Validation    │
        └───────────────────────┘
```

## Recipes

### Main Agents

| Recipe | File | Purpose | Temperature |
|--------|------|---------|-------------|
| **Solution Architect** | `solution-architect.yaml` | System design, ADRs, interface contracts, implementation planning | 0.3 |
| **AI Researcher** | `ai-researcher.yaml` | ML research, experiments, prototyping, evaluation | 0.4 |
| **Data Exploration** | `data-exploration.yaml` | Data profiling, analysis, notebooks, quality assessment | 0.3 |
| **Refactoring Agent** | `refactoring-agent.yaml` | Code improvement with strict TDD discipline | 0.2 |

### Shared Subrecipes

| Subrecipe | File | Purpose |
|-----------|------|---------|
| **TDD Workflow** | `subrecipes/tdd-workflow.yaml` | Red-Green-Refactor cycle enforcement |
| **Code Review** | `subrecipes/code-review.yaml` | Automated code quality review |
| **Test Validation** | `subrecipes/test-validation.yaml` | Test suite execution and reporting |

## Cross-Delegation Matrix

| Recipe | Can delegate to |
|--------|-----------------|
| **Solution Architect** | Refactoring Agent, AI Researcher, Data Exploration + all 3 subrecipes |
| **AI Researcher** | Data Exploration, Solution Architect + all 3 subrecipes |
| **Data Exploration** | AI Researcher, Solution Architect + TDD + Test Validation |
| **Refactoring Agent** | Solution Architect + all 3 subrecipes |

## Enforced Practices

| Practice | How enforced |
|----------|-------------|
| **TDD** | Shared `tdd-workflow` subrecipe with retry logic — tests must pass |
| **Language best practices** | Per-language checklists (Python PEP 484/604, Dart Effective Dart) |
| **Modularity** | Hard limits: max 400 lines/file, 30 lines/function, 7 public methods/class |
| **Correctness** | `test-validation` subrecipe + `retry` blocks on Refactoring and TDD |
| **Code quality** | `code-review` subrecipe with language-specific checklists |

## Usage

### Run from CLI

```bash
goose run --recipe recipes/solution-architect.yaml
goose run --recipe recipes/ai-researcher.yaml
goose run --recipe recipes/data-exploration.yaml
goose run --recipe recipes/refactoring-agent.yaml
```

### Import into Goose Desktop

1. Open **Goose Desktop** → **Settings** → **Recipe Library**
2. Add from local path or import the YAML file

### Customize for Your Project

The recipes reference RiseRally-specific paths. To adapt for your project:

1. Update the **System Context** sections with your tech stack
2. Change file paths in `instructions` to match your project structure
3. Adjust `retry.checks` commands to your test runners
4. Modify language-specific best practices as needed

## File Structure

```
goose-recipes/
├── README.md
├── solution-architect.yaml      # System design & architecture
├── ai-researcher.yaml           # ML research & experimentation
├── data-exploration.yaml        # Data profiling & analysis
├── refactoring-agent.yaml       # Code improvement with TDD
└── subrecipes/
    ├── tdd-workflow.yaml        # Red-Green-Refactor cycle
    ├── code-review.yaml         # Automated code review
    └── test-validation.yaml     # Test suite runner
```

## License

MIT
