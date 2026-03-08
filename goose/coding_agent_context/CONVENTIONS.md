# Project Conventions & Agent Protocols

> **Purpose:** Rules and workflows for autonomous agent operation in this codebase.

---

## BASE PATHS

> **IMPORTANT:** This conventions file is located in `./coding_agent_context/`. All relative paths in this document are relative to that folder. When running from the parent directory, prefix all paths with `coding_agent_context/`.

| Resource | Path from parent directory |
|----------|----------------------------|
| Roles | `./coding_agent_context/roles/` |
| Recipes | `./coding_agent_context/recipes/` |
| Tools | `./coding_agent_context/tools/` |
| Missions | `./coding_agent_context/missions/` |
| Specs | `./coding_agent_context/specs/` |
| Docs | `./coding_agent_context/docs/` |

---

## CODE FOLDERS

> **IMPORTANT:** When analyzing code, investigating bugs, or understanding the codebase, the agent MUST consider ALL folders listed below. Do not limit analysis to just `src/`.

| Folder | Description |
|--------|-------------|
| `src/` | Main source code |
| `dags/` | Airflow DAG definitions and related code |
| `tests/` | Test files and test utilities |
| `scripts/` | Helper script files |

<!-- To add more code folders, simply add a new row to the table above following the same format -->

---

## CRITICAL CONSTRAINTS (Read First)

| Constraint | Limit | Consequence |
|------------|-------|-------------|
| **Docker-only execution** | ALL code runs in Docker | NEVER run `pytest`, `python`, `pip` on host — use `run_tests.sh` / `dev_container.sh` |
| Files per turn | ≤ 4 files | AWS Bedrock crashes on 5+ |
| File reading | Use `cat` | Avoid `text_editor view` for bulk reads |
| Code changes | Requires plan | Never edit `src/` without `coding_agent_context/specs/.../plan.md` |
| Test breakage | Forbidden | Never commit code that breaks existing tests |

---

## WORKFLOW INITIALIZATION (Always First)

> **MANDATORY:** Before starting ANY workflow (A through F), check for and load the INDEX_Agent.md file if it exists.

### Why INDEX_Agent.md?

The `INDEX_Agent.md` file serves as the **master reference** for all `*_Agent.md` documentation. It provides:
- Overview of all documented components
- Navigation links between Agent docs
- High-level architecture understanding
- Cross-component relationships

### Initialization Protocol

```bash
# ALWAYS run this check at the START of any workflow:
if [ -f "coding_agent_context/docs/INDEX_Agent.md" ]; then
    echo "INDEX found - loading master reference"
    cat coding_agent_context/docs/INDEX_Agent.md
else
    echo "No INDEX_Agent.md found - proceed without master reference"
fi
```

### Rule

| Condition | Action |
|-----------|--------|
| INDEX_Agent.md exists | Load it FIRST before any other workflow steps |
| INDEX_Agent.md missing | Proceed with workflow (consider generating docs - Section F) |

**NOTE:** This step counts toward your 4-file-per-turn limit. Plan accordingly.

---

## ROLE BOUNDARIES

| Role | Owns | Can Edit | Cannot Edit |
|------|------|----------|-------------|
| **Analyst** | Investigation | stdout, markdown reports | Any code |
| **Architect** | Design | `coding_agent_context/specs/`, `coding_agent_context/docs/` | `src/`, `tests/` |
| **Builder** | Implementation | `src/`, `dags/`, `tests/` | `coding_agent_context/specs/` |
| **QA Engineer** | Tests | `tests/` | `src/` |
| **Doc Writer** | Documentation | `coding_agent_context/docs/` | `src/`, `tests/` |
| **ML Researcher** | Research | stdout, markdown reports | Any code |

---

## TECHNICAL STANDARDS

```
Language:     Python 3.12+
Type Hints:   REQUIRED (strict)
Style:        PEP8 via `ruff`
Testing:      pytest via run_tests.sh (Docker-only, 100% coverage for new features)
Docs:         `coding_agent_context/docs/*_Agent.md` = source of truth
```

---

## TESTING PHILOSOPHY

> **CRITICAL:** All tests MUST focus on **behavior and public interfaces**, NOT implementation details.

### Core Principle: Test Behavior, Not Implementation

Tests should verify WHAT the code does, not HOW it does it. This ensures:
- **Flexibility:** Implementation can be refactored without breaking tests
- **Maintainability:** Tests remain stable when internals change
- **Clarity:** Tests document the public contract
- **Value:** Tests verify what users/callers actually care about

### DO Test (Public Contracts)

| Category | Examples |
|----------|----------|
| Public methods | `obj.process()`, `obj.validate()`, `obj.get_result()` |
| Return values | What the method returns |
| Side effects | Files created, API calls made, database changes |
| Error handling | Exceptions raised through public interfaces |
| Edge cases | Via public interfaces only |

### DO NOT Test (Implementation Details)

| Category | Why Avoid |
|----------|-----------|
| Private methods (`_method`) | Internal; testing couples tests to implementation |
| Internal data structures | May change during refactoring |
| Exact algorithms | Test WHAT not HOW |
| Source code structure | File organization is not behavior |
| Number of internal calls | Call counts are implementation details |
| Internal state | Only test observable outcomes |

### Example: Good vs Bad Tests

```python
# ❌ BAD: Testing private implementation
def test_internal_cache():
    processor = DataProcessor()
    processor.process('input')
    assert processor._cache['input'] is not None  # Private attribute!
    assert processor._helper_called == True  # Implementation detail!

# ✅ GOOD: Testing public behavior
def test_process_returns_expected_result():
    processor = DataProcessor()
    result = processor.process('input')
    assert result.success is True
    assert result.data == 'expected_output'

# ✅ GOOD: Testing observable side effect
def test_process_creates_output_file():
    processor = DataProcessor()
    processor.process('input')
    assert os.path.exists('output.txt')  # Observable outcome
```

### Why This Matters for TDD

| TDD Phase | Focus |
|-----------|-------|
| RED | Write tests that define the PUBLIC CONTRACT |
| GREEN | Implement ANY solution that satisfies the contract |
| REFACTOR | Safely refactor internals without breaking tests |

---

## WORKFLOW SELECTION

```
┌─────────────────────────────────────────────────────────────┐
│ What type of change?                                        │
└─────────────────────────────────────────────────────────────┘
                              │
    ┌─────────────┬───────────┼───────────┬──────────────┬─────────────┐
    ▼             ▼           ▼           ▼              ▼             ▼
┌────────┐  ┌─────────┐  ┌────────┐  ┌─────────┐  ┌──────────┐  ┌─────────┐
│ Bug    │  │ Feature │  │ Docs   │  │ Docs    │  │ Arch     │  │ Docs    │
│ Tweak  │  │ Refactor│  │ Update │  │ Generate│  │ Research │  │ None    │
└───┬────┘  └────┬────┘  └───┬────┘  └────┬────┘  └─────┬────┘  └────┬────┘
    │            │           │            │              │            │
    ▼            ▼           ▼            ▼              ▼            ▼
 TACTICAL    FULL RFC     DOC MAINT    DOC GEN     ARCH RESEARCH  NO DOCS
 (Sec. A)    (Sec. B)     (Sec. C)     (Sec. F)    (Sec. H)      EXIST
```

**Mission Files:**

| Workflow | Mission File |
|----------|--------------|
| Tactical Mode | `coding_agent_context/missions/tactical_update.md` |
| Full RFC Mode | `coding_agent_context/missions/architecture_design.md` → `implement_tdd.md` |
| Doc Maintenance | `coding_agent_context/missions/update_docs.md` |
| Doc Generation | `coding_agent_context/missions/generate_docs.md` |
| Architecture Research | `coding_agent_context/missions/model_architecture_research.md` |

---

## A. TACTICAL MODE (Small Changes)

**USE WHEN:** Bug fixes, wording changes, minor logic tweaks.

### Checklist

1. [ ] Check mission file for `RUN_TESTS` flag
2. [ ] **IF `RUN_TESTS: false`:** Skip QA, apply changes directly
3. [ ] **IF `RUN_TESTS: true`:** Follow TDD loop (Section D)
4. [ ] Verify with `cat` that changes are correct

---

## B. FULL RFC MODE (Features/Refactors)

**USE WHEN:** New features, architectural changes, complex refactors.

### Phase Flow

```
RESEARCH → DRAFT → CRITIQUE → APPROVE → IMPLEMENT
```

### Phase 1: Research

Use the **analyst** sub-agent tool:
- focus: "Explain [topic]"
- read_files: `path/to/relevant/files.py`
- output_file: `coding_agent_context/specs/feature/research_output.md`

```bash
cat coding_agent_context/specs/feature/research_output.md
```
- Goal: Understand existing system before designing

### Phase 2: Draft

Use the **architect** sub-agent tool:
- task: "Draft design for [feature]"
- target_file: `coding_agent_context/specs/feature/design.md`
- output_file: `coding_agent_context/specs/feature/design_session.md`

```bash
cat coding_agent_context/specs/feature/design_session.md
cat coding_agent_context/specs/feature/design.md
```
- MUST include: Implementation Plan section
- MUST include: Integration points (Mermaid diagrams)

### Phase 3: Critique
- Self-review: "What did I miss? What could break?"
- Update design doc with findings

### Phase 4: Approve
- Design doc complete → Create `coding_agent_context/specs/.../plan.md` checklist
- Then proceed to TDD (Section D)

---

## C. DOCUMENTATION MAINTENANCE

**USE WHEN:** Code changed, docs need sync.

### Steps

| Step | Action | Tool |
|------|--------|------|
| 1. Identify | Find Agent doc + source files | `grep`, `ls` |
| 2. Analyze | Understand code changes | **analyst** sub-agent tool |
| 3. Synthesize | Formulate update instruction | (manual) |
| 4. Write | Apply doc update | **doc_writer** sub-agent tool |
| 5. Verify | Confirm update | `cat coding_agent_context/docs/X_Agent.md` |

**RULE:** Code and docs must never drift. Update docs in same session as code changes.

---

## D. TDD PROTOCOL (Red-Green-Refactor)

**RULE:** Never write implementation code without a failing test.

**MISSION FILE:** `coding_agent_context/missions/implement_tdd.md`

### Resumable Progress Tracking

TDD execution supports **resumption after interruption** via a progress tracker file.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ ALWAYS START BY CHECKING FOR EXISTING PROGRESS:                             │
│                                                                             │
│ if [ -f "coding_agent_context/specs/${FEATURE}/progress.md" ]; then        │
│     echo "RESUMING: Found existing progress"                                │
│     cat coding_agent_context/specs/${FEATURE}/progress.md                  │
│ else                                                                        │
│     echo "FRESH START: Create progress.md from design.md"                   │
│ fi                                                                          │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Progress Files

| File | Purpose |
|------|---------|
| `coding_agent_context/specs/${FEATURE}/design.md` | High-level step completion (human readable) |
| `coding_agent_context/specs/${FEATURE}/progress.md` | Detailed execution state (machine resumable) |
| `coding_agent_context/specs/templates/progress_tracker.md` | Template for progress.md |

### Status Values

| Status | Meaning | Action |
|--------|---------|--------|
| `[ ] PENDING` | Not started | Start at RED phase |
| `[~] IN_PROGRESS` | Partially done | Check Execution Log, resume at last phase |
| `[x] COMPLETE` | Finished | Skip to next step |

### The Loop

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ 0. CHECK PROGRESS: Read progress.md → Find first non-COMPLETE step          │
├──────────────────────────────────────────────────────────────────────────────┤
│ 1. RED: Write failing test                                                   │
│    Mark step [~] IN_PROGRESS                                                │
│    qa_engineer sub-agent → write test                                        │
│    run_tests.sh → cat test_results.md → MUST FAIL                           │
│    Log: TEST_RED confirmed                                                   │
├──────────────────────────────────────────────────────────────────────────────┤
│ 2. GREEN: Write code to pass                                                 │
│    developer sub-agent → implement code                                      │
│    run_tests.sh → cat test_results.md → MUST PASS                           │
│    Log: TEST_GREEN confirmed                                                 │
├──────────────────────────────────────────────────────────────────────────────┤
│ 3. REFACTOR: Clean up (optional)                                             │
│    developer sub-agent → refactor code                                       │
│    run_tests.sh → cat test_results.md → STILL PASS                          │
├──────────────────────────────────────────────────────────────────────────────┤
│ 4. TRACK: Mark step [x] COMPLETE → Update progress summary → Next step      │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Resumption Quick Reference

| Last Logged Phase | Resume At |
|-------------------|-----------|
| `TEST_WRITTEN` | Run test to confirm RED |
| `TEST_RED` | GREEN phase (write code) |
| `CODE_WRITTEN` | Run test to confirm GREEN |
| `TEST_GREEN` | Mark step complete |

### Debug Mode

**TRIGGER:** Tests fail after GREEN step.

**ACTIONS:**
1. Log DEBUG phase in progress.md
2. Read traceback
3. Call developer with **specific** fix: "Fix KeyError on line 40"
4. Never say just "fix it"
5. Log DEBUG resolved when fixed

---

## E. MANAGEMENT LOOP (Orchestration)

**USE WHEN:** You are the orchestrator managing a mission.

### Loop

```
1. ORIENT   → ls, grep to find relevant files
2. PLAN     → Call Architect to write plan
3. EXECUTE  → Loop through plan items with Builder
4. VERIFY   → Run run_tests.sh (Docker) after each Builder step
             ├─ PASS → Next item
             └─ FAIL → Analyst to debug → Builder to fix
5. TRACK    → Create task files in coding_agent_context/missions/${MISSION_NAME}/
```

### Mission File Location
```
coding_agent_context/missions/${MISSION_NAME}/${MISSION_NAME}.md
```

---

## F. DOCUMENTATION GENERATION (From Scratch)

**USE WHEN:** No `*_Agent.md` documentation exists, or starting fresh on a new codebase.

**Mission File:** `coding_agent_context/missions/generate_docs.md`

### Overview

This is a **two-phase mission** that creates comprehensive documentation from scratch:

```
┌─────────────────────────────────────────────────────────────┐
│ PHASE 1: ANALYZE & PLAN                                     │
│ • Explore codebase structure                                │
│ • Determine Agent granularity                               │
│ • Create plan.md with checklist                             │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ PHASE 2: EXECUTE PLAN                                       │
│ • Create each *_Agent.md file                               │
│ • Create INDEX_Agent.md master index                        │
└─────────────────────────────────────────────────────────────┘
```

### Quick Start

```bash
# Check if docs exist
ls coding_agent_context/docs/*_Agent.md 2>/dev/null

# If no docs exist, read the generation mission
cat coding_agent_context/missions/generate_docs.md

# Follow Phase 1 to create plan
# Then follow Phase 2 to execute plan
```

### Key Outputs

| Output | Path | Description |
|--------|------|-------------|
| Plan | `coding_agent_context/specs/doc_generation/plan.md` | Checklist of Agent files to create |
| Agent Docs | `coding_agent_context/docs/*_Agent.md` | Individual component documentation |
| Master Index | `coding_agent_context/docs/INDEX_Agent.md` | Links all Agents, provides overview |

### When to Use Each Doc Mission

| Situation | Use This |
|-----------|----------|
| No docs exist | Section F (generate_docs.md) |
| Docs exist but outdated | Section C (update_docs.md) |
| Single doc needs update | Section C directly |

---

## H. MODEL ARCHITECTURE RESEARCH (Ideation & Literature Survey)

**USE WHEN:** You need to research and compare model architectures before implementation.

**Mission File:** `coding_agent_context/missions/model_architecture_research.md`

### Overview

This is an **interactive research loop** that helps you explore ML architectures
through literature survey, paper analysis, and systematic comparison. It produces
a `requirements.md` that feeds directly into the architecture_design mission.

### Pipeline

    ideation.md → model_architecture_research.md → requirements.md → architecture_design.md → implement_tdd.md

### Quick Start

    # 1. Set the research name
    export RESEARCH_NAME="my_architecture"

    # 2. Create the ideation brief
    mkdir -p coding_agent_context/specs/model_arch_research_${RESEARCH_NAME}
    # Edit: coding_agent_context/specs/model_arch_research_${RESEARCH_NAME}/ideation.md

    # 3. Run the research mission
    agent-manager coding_agent_context/missions/model_architecture_research.md

    # 4. After finalization, run architecture design
    export FEATURE="model_arch_research_${RESEARCH_NAME}"
    agent-manager coding_agent_context/missions/architecture_design.md

---

## SUB-AGENT DISPATCH

### Roles (LLM-based sub-agents)

Role definitions live in `coding_agent_context/roles/`. Each role file defines identity,
constraints, and output format for a specialized sub-agent.

| Role | File | Can Edit Files? | Use For |
|------|------|----------------|---------|
| Analyst | `roles/analyst.md` | No | Code investigation, analysis |
| Architect | `roles/architect.md` | Yes (design docs) | System design, implementation plans |
| Developer | `roles/developer.md` | Yes (source code) | TDD GREEN step, implementation |
| QA Engineer | `roles/qa_engineer.md` | Yes (test files) | TDD RED step, test writing |
| Doc Writer | `roles/doc_writer.md` | Yes (doc files) | Documentation updates |
| Code Reviewer | `roles/code_reviewer.md` | No | Code review analysis |
| ML Researcher | `roles/ml_researcher.md` | No (output file only) | Literature search, architecture research |

### How to Dispatch

Use this format in missions to invoke a sub-agent:

    Use the **<role_name>** sub-agent tool with these parameters:
    - task/focus: "<description>"
    - target_file: `<file>` (omit for read-only roles)
    - read_files: `<file1>,<file2>`
    - output_file: `<output_file.md>`

The orchestrating agent MUST:
1. Read the role file to understand the sub-agent's identity and constraints
2. Read all listed read files and include their content in the sub-agent's context
3. Pass the task description as the primary instruction
4. If target_file is specified, the sub-agent should modify that file
5. Write the sub-agent's response/summary to the output_file
6. Use a sub-agent mechanism that provides context isolation (separate context window)

### Infrastructure Tools (Shell scripts — call directly)

| Tool | Script | Use For |
|------|--------|---------|
| Dev Container | `tools/dev_container.sh` | Docker lifecycle management |
| Run Tests | `tools/run_tests.sh` | Execute pytest in Docker |
| Docker Manager | `tools/docker_manager.sh` | Data exploration Docker setup |
| Data Explorer | `tools/data_explorer.sh` | Run exploration scripts in Docker |
| Diff Analyzer | `tools/diff_analyzer.sh` | Generate diff reports |
| Setup CR | `tools/setup_cr.sh` | Code review workspace setup |

Infrastructure tools are called directly as shell commands. Get usage with `--help`:

```bash
./coding_agent_context/tools/<tool_name>.sh --help
```

### Infrastructure Tool Quick Examples

```bash
# Run Tests (always executes inside Docker — never on host)
./coding_agent_context/tools/run_tests.sh -o coding_agent_context/specs/${FEATURE}/results.md -t tests/test_auth.py

# Dev Container (manage the development Docker container)
./coding_agent_context/tools/dev_container.sh --action ensure      # Start/create dev container (MANDATORY first step)
./coding_agent_context/tools/dev_container.sh --action exec --cmd "pytest tests/ -v"   # Run command inside container
./coding_agent_context/tools/dev_container.sh --action rebuild     # Rebuild after Dockerfile/requirements changes

# Docker Manager (data exploration environments)
./coding_agent_context/tools/docker_manager.sh --action setup --exploration-name my_analysis

# Data Explorer (run processing in Docker)
./coding_agent_context/tools/data_explorer.sh --action run --exploration-name my_analysis

# Diff Analyzer
./coding_agent_context/tools/diff_analyzer.sh -o cr_review/diff_report.md -t "../../target" -c "." -f "${FOCUS_PATH}"
```

---

## ORCHESTRATOR-SPECIFIC: Sub-Agent Mechanism

The current orchestrator is **goose**. When encountering a sub-agent dispatch instruction:

1. Use the corresponding **subrecipe tool** (registered from `recipes/roles/*.yaml`)
2. Each subrecipe provides context isolation (separate session)
3. The subrecipe reads the role file, context files, and performs the task
4. Results are written to the specified output file

**Recipes** live in `coding_agent_context/recipes/`:
- `recipes/roles/*.yaml` — Goose subrecipe wrappers for each role
- `recipes/mission_*.yaml` — Goose recipe entry points for each mission

**To run a mission:**
```bash
goose run --recipe coding_agent_context/recipes/mission_tdd.yaml \
    --params feature=my_feature
```

**If switching orchestrators**, only the `recipes/` directory needs to change.
Everything else (roles, missions, tools, conventions) remains identical.

---

## FILE READING PROTOCOL

### DO
```bash
cat path/to/file.py           # Single file
cat file1.py file2.py         # Multiple (≤4)
```

### DON'T
```bash
# AVOID: text_editor view for bulk reads (API limits)
# AVOID: Reading 5+ files in single turn (Bedrock crash)
```

### Batch Reading (>4 files)
```
Turn 1: cat file1.py file2.py file3.py file4.py
[wait for response]
Turn 2: cat file5.py file6.py file7.py file8.py
```

---

## QUICK REFERENCE CARD

### Before Coding
- [ ] Load `coding_agent_context/docs/INDEX_Agent.md` (if exists) - **MANDATORY FIRST STEP**
- [ ] Read relevant `coding_agent_context/docs/*_Agent.md`
- [ ] Read `coding_agent_context/specs/.../plan.md`
- [ ] Understand existing patterns

### During Coding
- [ ] Respect role boundaries
- [ ] Follow TDD loop
- [ ] Stay within 4-file limit

### After Coding
- [ ] Run tests **inside Docker**: `./coding_agent_context/tools/run_tests.sh -o coding_agent_context/specs/${FEATURE}/results.md -t tests/`
- [ ] Update documentation
- [ ] Verify with `cat`

---

## DECISION QUICK-REF

| Situation | Action |
|-----------|--------|
| Need to understand code | **analyst** sub-agent tool |
| Need to design feature | **architect** sub-agent tool |
| Need to write test | **qa_engineer** sub-agent tool |
| Need to write code | **developer** sub-agent tool |
| Need to update docs | **doc_writer** sub-agent tool |
| Need code review | **code_reviewer** sub-agent tool |
| Need to run tests (Docker) | `./coding_agent_context/tools/run_tests.sh -o ... -t tests/` |
| Need dev container running | `./coding_agent_context/tools/dev_container.sh --action ensure` |
| Need to run arbitrary cmd in Docker | `./coding_agent_context/tools/dev_container.sh --action exec --cmd "..."` |
| Need to rebuild Docker after dep change | `./coding_agent_context/tools/dev_container.sh --action rebuild` |
| Need Docker for data exploration | `./coding_agent_context/tools/docker_manager.sh --action setup ...` |
| Need to run data processing | `./coding_agent_context/tools/data_explorer.sh --action run ...` |
| No docs exist | Follow Section F (generate_docs.md) |
| Data exploration needed | Follow Section G (data_exploration.md) |
| Need to research model architectures | Follow Section H (model_architecture_research.md) |
| Tests failing | Enter DEBUG MODE |
| Stuck on problem | Request "Human Review" |
| Architecture unclear | Check `coding_agent_context/docs/*_Agent.md` Mermaid diagrams |

---

## UNIVERSAL DOCKER-ONLY EXECUTION POLICY

> **🚫 ABSOLUTE RULE — NO EXCEPTIONS — APPLIES TO ALL MISSIONS:**
> ALL Python code execution — tests, scripts, linting, data processing, debugging —
> MUST run **exclusively inside Docker containers**. The agent MUST NEVER execute
> `python`, `pytest`, `pip install`, or any code-execution command directly on the host.

### Why?
- The host environment is not the execution environment. Packages, versions, and
  configurations may differ from what the project expects.
- Installing packages on the host pollutes the system and creates unreproducible results.
- The Docker dev container is the single source of truth for the runtime environment.

### Permitted vs Forbidden

| ✅ Permitted (Docker execution) | ❌ Forbidden (host execution) |
|--------------------------------|-------------------------------|
| `./coding_agent_context/tools/run_tests.sh -o coding_agent_context/specs/${FEATURE}/r.md -t tests/` | `pytest tests/` |
| `./coding_agent_context/tools/dev_container.sh --action exec --cmd "pytest tests/ -v"` | `python -m pytest tests/` |
| `./coding_agent_context/tools/dev_container.sh --action exec --cmd "python script.py"` | `python script.py` |
| `docker exec -i dev-container-<project> python -c "..."` | `python -c "import pandas; ..."` |
| `./coding_agent_context/tools/dev_container.sh --action exec --cmd "pip install X"` | `pip install X` |
| `./coding_agent_context/tools/data_explorer.sh --action run ...` | `cd src && python anything.py` |

### Before ANY Code Execution

Always ensure the dev container is running first:

```bash
./coding_agent_context/tools/dev_container.sh --action ensure
```

This is idempotent. If no Docker environment exists, it auto-generates one.
If the container is already running, it verifies health and returns immediately.

### On Session Resume

1. Run `dev_container.sh --action ensure` to confirm the dev container is up
2. For data exploration: read the `## Docker Execution Commands` section from
   the exploration's `memory.md` file
3. For implementation missions (architecture_design, implement_tdd, tactical_update):
   read the feature's `memory.md` file for known issues, Docker notes, and learnings
4. If Docker is not set up yet, set it up FIRST before any code execution
