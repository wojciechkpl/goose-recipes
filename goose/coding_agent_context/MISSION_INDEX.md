# Mission Quick-Reference Index

---

## Decision Tree

```
What do you want to do?
|
|-- Fix a bug / make a small tweak?
|   --> tactical_update.md
|
|-- Build a new feature or do a complex refactor?
|   --> architecture_design.md --> implement_tdd.md
|
|-- Research ML model architectures before building?
|   --> model_architecture_research.md --> architecture_design.md --> implement_tdd.md
|
|-- Explore and understand a dataset?
|   --> data_exploration.md
|
|-- Analyse existing Jupyter notebooks?
|   --> analyse_jupyterNotebooks.md
|
|-- Review someone else's code change?
|   --> review_code_change.md
|
|-- Generate docs from scratch (no *_Agent.md files exist)?
|   --> generate_docs.md
|
|-- Update existing docs after code changed?
|   --> update_docs.md
```

---

## Mission Summary Table

| Mission | File | When to Use | Prerequisites | Key Outputs | Next Mission |
|---------|------|-------------|---------------|-------------|--------------|
| **Tactical Update** | `tactical_update.md` | Bug fixes, minor tweaks, small changes | `specs/${FEATURE}/requirements.md` | `todo.md`, changed code, `memory.md` | `update_docs.md` (if needed) |
| **Architecture Design** | `architecture_design.md` | New features, complex refactors | `specs/${FEATURE}/requirements.md` | `design.md`, `memory.md` | `implement_tdd.md` |
| **TDD Implementation** | `implement_tdd.md` | Execute a design via Red-Green-Refactor | `specs/${FEATURE}/design.md` | Working code, `progress.md`, `memory.md` | `update_docs.md` |
| **Update Docs** | `update_docs.md` | Code changed, docs need sync | Existing `*_Agent.md` files + changed code | Updated `*_Agent.md` files | -- |
| **Generate Docs** | `generate_docs.md` | No docs exist, start from scratch | Codebase with source files | `*_Agent.md` files, `INDEX_Agent.md` | -- |
| **Code Review** | `review_code_change.md` | Review a branch/PR against baseline | CR workspace via `setup_cr.sh` | `cr_review/CODE_REVIEW.md`, diff report | -- |
| **Data Exploration** | `data_exploration.md` | Understand a dataset interactively | `specs/data_exploration_${NAME}/exploration.md` | Scripts, outputs, `memory.md` | `model_architecture_research.md` (if ML) |
| **ML Architecture Research** | `model_architecture_research.md` | Research model architectures before building | `specs/model_arch_research_${NAME}/ideation.md` | `architecture_brief.md`, `requirements.md` | `architecture_design.md` |
| **Analyse Notebooks** | `analyse_jupyterNotebooks.md` | Document existing Jupyter notebooks | `Model Training *.ipynb` files in folder | Walkthrough docs, `remaining_files.md`, `INDEX.md` | -- |

---

## Role Assignment Matrix

| Role | tactical | arch_design | implement_tdd | update_docs | generate_docs | code_review | data_exploration | ml_arch_research | notebooks |
|------|:--------:|:-----------:|:-------------:|:-----------:|:-------------:|:-----------:|:----------------:|:----------------:|:---------:|
| **Analyst** | x | x | -- | x | x | x | x | x | x |
| **Architect** | x | x | -- | -- | x | -- | -- | -- | -- |
| **Developer** | x | -- | x | -- | -- | -- | -- | -- | -- |
| **QA Engineer** | x | -- | x | -- | -- | -- | -- | -- | -- |
| **Doc Writer** | x | x | x | x | x | x | -- | x | x |
| **Code Reviewer** | -- | -- | -- | -- | -- | x | -- | -- | -- |
| **ML Researcher** | -- | -- | -- | -- | -- | -- | -- | x | -- |

---

## Mission Chains

**Feature development (full lifecycle):**
```
architecture_design --> implement_tdd --> update_docs
```

**ML model development:**
```
data_exploration --> model_architecture_research --> architecture_design --> implement_tdd --> update_docs
```

**Quick fix:**
```
tactical_update --> update_docs (if docs affected)
```

**Greenfield documentation:**
```
generate_docs  (standalone, run once)
```

**Code review:**
```
review_code_change  (standalone, includes doc update internally)
```

**Notebook analysis:**
```
analyse_jupyterNotebooks  (standalone)
```

---

## Key Environment Variables

| Variable | Used By | Purpose |
|----------|---------|---------|
| `FEATURE` | tactical, arch_design, implement_tdd | Feature folder name under `specs/` |
| `RESEARCH_NAME` | ml_arch_research | Research session name |
| `EXPLORATION_NAME` | data_exploration | Exploration session name |
| `RUN_TESTS` | tactical_update | `true`/`false` -- whether to follow TDD |

---

## File Locations

| Resource | Path |
|----------|------|
| Missions | `coding_agent_context/missions/` |
| Roles | `coding_agent_context/roles/` |
| Specs/Plans | `coding_agent_context/specs/${FEATURE}/` |
| Agent Docs | `coding_agent_context/docs/` |
| Tools | `coding_agent_context/tools/` |
| Conventions | `coding_agent_context/CONVENTIONS.md` |
