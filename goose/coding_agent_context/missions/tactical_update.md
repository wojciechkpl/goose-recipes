# MISSION: Tactical Update (Small Change)

> **Type:** Quick Fix / Minor Enhancement | **Overhead:** Minimal

---

## CONFIGURATION

Obtain FEATURE from the environment variable ${FEATURE}
Obtain RUN_TESTS from the environment variable ${RUN_TESTS}
Obtain details of the task from `coding_agent_context/specs/${FEATURE}/requirements.md`

| Setting | Value | Description |
|---------|-------|-------------|
| `FEATURE` | Name of the feature/fix | Used for file paths |
| `RUN_TESTS` | `true` or `false` | Whether to follow TDD for this change |

---

## MEMORY FILE RESOLUTION

> **🧠 MEMORY PERSISTENCE:** This mission maintains a memory file that captures encountered
> issues and their solutions, environment-specific knowledge (e.g., Docker commands,
> dependency quirks), and other learnings that are NOT part of `requirements.md` or `todo.md`.
> This knowledge persists across sessions and carries forward to future iterations.

### Determine the memory file path

The memory file always lives in the **base feature's** spec folder — never in an iteration
subfolder. This ensures knowledge accumulates across iterations.

```bash
# --- Resolve MEMORY_FILE from FEATURE ---
# If FEATURE matches *_iteration_<N>, derive the base feature name.
# Otherwise, the base feature IS the FEATURE itself.
if [[ "${FEATURE}" =~ ^(.+)_iteration_[0-9]+$ ]]; then
    BASE_FEATURE="${BASH_REMATCH[1]}"
else
    BASE_FEATURE="${FEATURE}"
fi

MEMORY_FILE="coding_agent_context/specs/${BASE_FEATURE}/memory.md"
echo "Memory file: ${MEMORY_FILE}  (base feature: ${BASE_FEATURE})"
```

### Load existing memory (if any)

```bash
if [ -f "${MEMORY_FILE}" ]; then
    echo "MEMORY FOUND: Loading existing knowledge from ${MEMORY_FILE}"
    cat "${MEMORY_FILE}"
else
    echo "NO MEMORY FILE: Will create one after tactical update completes."
fi
```

> **How to use loaded memory during tactical updates:**
> - If memory contains **Docker Execution Notes**, use those exact commands —
>   do NOT guess or re-derive Docker commands.
> - If memory contains **Known Issues & Solutions**, check whether the current
>   change touches the same areas — apply known solutions proactively.
> - If memory contains **Environment Setup Notes**, verify the environment matches
>   before running tests.
> - If this is an iteration, review **Implementation Learnings** from prior iterations.

---

## CRITICAL: DOCKER-ONLY EXECUTION POLICY

> **🚫 ABSOLUTE RULE — NO EXCEPTIONS:**
> ALL code execution during tactical updates (running tests, running scripts, linting,
> debugging) MUST happen **exclusively inside the dev Docker container**. The agent
> MUST NEVER run `pytest`, `python`, `pip`, or any code-execution command directly
> on the host machine.
>
> **The ONLY permitted execution methods are:**
> 1. `./coding_agent_context/tools/run_tests.sh` (runs pytest inside Docker automatically)
> 2. `./coding_agent_context/tools/dev_container.sh --action exec --cmd "<command>"`
> 3. `docker exec -i <container_name> <command>`
>
> **NEVER do this:**
> ```bash
> # ❌ FORBIDDEN — direct host execution
> pytest tests/test_auth.py
> python -m pytest tests/
> ruff check src/module.py          # ← use dev_container exec instead
> pip install some-package
> ```
>
> **ALWAYS do this:**
> ```bash
> # ✅ CORRECT — run tests in Docker
> ./coding_agent_context/tools/run_tests.sh -o coding_agent_context/specs/${FEATURE}/results.md -t tests/test_auth.py
>
> # ✅ CORRECT — run linting in Docker
> ./coding_agent_context/tools/dev_container.sh --action exec --cmd "ruff check src/module.py"
> ```

---

## OBJECTIVE

Implement a small change with minimal overhead. No full design document required.

**Output:** `coding_agent_context/specs/${FEATURE}/todo.md` (task checklist)

---

## Expected `requirements.md` Format

The file `coding_agent_context/specs/${FEATURE}/requirements.md` drives this mission.
It should follow this structure:

```markdown
# Tactical Update: <FEATURE_NAME>

## Summary
One-paragraph description of what needs to change and why.

## Change Type
Bug fix | Minor enhancement | Config change | Refactor

## Affected Files (if known)
- `src/path/to/file.py` — description of change
- `tests/path/to/test.py` — test updates needed
- (or "To be determined by analysis")

## Acceptance Criteria
- [ ] Criterion 1: describe expected behavior after the change
- [ ] Criterion 2: ...

## Testing Requirements
- `RUN_TESTS`: `true` or `false`
- If true: describe what tests should verify
- If false: explain why tests are not needed (e.g., docs-only change)

## Context (optional)
Any additional context: related tickets, previous changes, constraints.
```

---

## DECISION FLOW

```
┌─────────────────────────────────────────┐
│ Does todo.md exist?                     │
└─────────────────────────────────────────┘
         │
    ┌────┴────┐
    ▼         ▼
   NO        YES
    │         │
    ▼         ▼
 Step 0    Step 0
 + Step 1  + Step 2
 (Docker   (Docker
  + Plan)   + Execute)
```

---

## STEP 0: Ensure Docker Dev Container (MANDATORY FIRST STEP)

> **ALWAYS run this before any code execution, regardless of RUN_TESTS setting.**

```bash
# Ensure the dev container is running (idempotent — safe to call repeatedly)
./coding_agent_context/tools/dev_container.sh --action ensure
```

**What this does:**
1. Checks if dev container is already running → verifies health
2. If no Docker image → builds it (auto-generates Dockerfile if none exists)
3. Starts container in daemon mode with project mounted
4. Verifies Python and pytest are available inside

**DO NOT PROCEED** until the dev container is confirmed running.

---

## STEP 1: Tactical Planning

> **Skip if** `coding_agent_context/specs/${FEATURE}/todo.md` already exists.

### 1.1 Analyze Current Code (Analyst)

Use the **analyst** sub-agent tool with these parameters:
- focus: "How does the current system handle [CHANGE_TOPIC]? Identify files to modify."
- read_files: `src/relevant_file1.py,src/relevant_file2.py`
- output_file: `coding_agent_context/specs/${FEATURE}/tactical_analysis.md`

```bash
cat coding_agent_context/specs/${FEATURE}/tactical_analysis.md
```

### 1.2 Create Task List (Architect)

Use the **architect** sub-agent tool with these parameters:
- task: "Create a minimal task checklist for: [CHANGE_DESCRIPTION]. Include: 1) Files to modify, 2) Logic changes, 3) Test adjustments if needed. Do NOT create a full design document."
- target_file: `coding_agent_context/specs/${FEATURE}/todo.md`
- read_files: `coding_agent_context/specs/${FEATURE}/tactical_analysis.md,coding_agent_context/specs/${FEATURE}/requirements.md`
- output_file: `coding_agent_context/specs/${FEATURE}/tactical_plan_session.md`

```bash
# Read session and todo
cat coding_agent_context/specs/${FEATURE}/tactical_plan_session.md
cat coding_agent_context/specs/${FEATURE}/todo.md
```

**Constraint:** The `todo.md` should be a simple checklist, NOT a full design document.

**Expected format:**
```markdown
# Tactical Update: ${FEATURE}

## Files to Modify
- [ ] src/file1.py - Add validation logic
- [ ] src/file2.py - Update handler

## Test Updates (if RUN_TESTS=true)
- [ ] tests/test_file1.py - Add validation tests
```

---

## STEP 2: Incremental Implementation

> **Repeat for each unchecked `[ ]` item in `todo.md`**

### If RUN_TESTS = true

Follow mini-TDD cycle:

**2a. Write/update test:**

Use the **qa_engineer** sub-agent tool with these parameters:
- task: "Add test for: [TASK_DESCRIPTION]"
- target_file: `tests/test_${COMPONENT}.py`
- output_file: `coding_agent_context/specs/${FEATURE}/qa_tactical_session.md`

```bash
cat coding_agent_context/specs/${FEATURE}/qa_tactical_session.md
```

**2b. Implement change:**

Use the **developer** sub-agent tool with these parameters:
- task: "Implement: [TASK_DESCRIPTION]"
- target_file: `src/${COMPONENT}.py`
- read_files: `tests/test_${COMPONENT}.py`
- output_file: `coding_agent_context/specs/${FEATURE}/dev_tactical_session.md`

```bash
cat coding_agent_context/specs/${FEATURE}/dev_tactical_session.md
```

**2c. Verify tests pass (inside Docker — NEVER on host):**

```bash
./coding_agent_context/tools/run_tests.sh \
    -o coding_agent_context/specs/${FEATURE}/tactical_test_results.md \
    -t tests/test_${COMPONENT}.py

cat coding_agent_context/specs/${FEATURE}/tactical_test_results.md
```

### If RUN_TESTS = false

Direct implementation only:

Use the **developer** sub-agent tool with these parameters:
- task: "Implement: [TASK_DESCRIPTION]"
- target_file: `src/${COMPONENT}.py`
- output_file: `coding_agent_context/specs/${FEATURE}/dev_tactical_session.md`

```bash
cat coding_agent_context/specs/${FEATURE}/dev_tactical_session.md
```

### Mark Task Complete

```bash
# Mark item as done in todo.md
sed -i 's/\[ \] TASK_DESCRIPTION/[x] TASK_DESCRIPTION/' \
    coding_agent_context/specs/${FEATURE}/todo.md
```

---

## STEP 3: Verification

### If RUN_TESTS = true

```bash
# Run full test suite for affected module (inside Docker)
./coding_agent_context/tools/run_tests.sh \
    -o coding_agent_context/specs/${FEATURE}/final_tactical_results.md \
    -t tests/

cat coding_agent_context/specs/${FEATURE}/final_tactical_results.md
```

### If RUN_TESTS = false

```bash
# Verify syntax/linting (inside Docker — NEVER on host)
./coding_agent_context/tools/dev_container.sh --action exec --cmd "ruff check src/${COMPONENT}.py"
```

---

## STEP 4: Update Memory File

**Goal:** Capture any issues encountered, solutions found, and environment knowledge gained
during this tactical update. This ensures future sessions (and iterations) benefit from
what was learned.

> **What to record in memory (examples):**
> - Docker execution notes (e.g., how to run specific commands in the container)
> - How to update the Docker environment (adding deps, rebuilding)
> - Issues encountered during implementation and how they were resolved
> - Environment quirks or non-obvious setup steps
> - Codebase patterns discovered that aren't documented elsewhere
>
> **What NOT to record (already tracked elsewhere):**
> - Requirements (in `requirements.md`)
> - Task list (in `todo.md`)

```bash
# Resolve MEMORY_FILE path
if [[ "${FEATURE}" =~ ^(.+)_iteration_[0-9]+$ ]]; then
    BASE_FEATURE="${BASH_REMATCH[1]}"
else
    BASE_FEATURE="${FEATURE}"
fi
MEMORY_FILE="coding_agent_context/specs/${BASE_FEATURE}/memory.md"

# If memory file does NOT exist — create it
if [ ! -f "${MEMORY_FILE}" ]; then
    mkdir -p "$(dirname "${MEMORY_FILE}")"
    cat > "${MEMORY_FILE}" << 'MEMORY_EOF'
# Implementation Memory: ${BASE_FEATURE}

> **Status:** IN_PROGRESS
> **Created:** [CURRENT_DATE]
> **Last Updated:** [CURRENT_DATE]
> **Feature:** ${BASE_FEATURE}

---

## Docker Execution Notes

> Commands, mount paths, rebuild procedures, and other Docker-specific knowledge
> discovered during design and implementation.

| Topic | Details |
|-------|---------|
| | |

---

## Known Issues & Solutions

> Problems encountered during design/implementation and how they were resolved.
> These persist across sessions so the agent does not re-discover the same issues.

| # | Date | Phase | Issue | Solution | Affected Files |
|---|------|-------|-------|----------|----------------|
| | | | | | |

---

## Environment Setup Notes

> Non-obvious environment configuration, dependency quirks, or setup steps
> that are not captured in requirements.md or design.md.

- [To be populated during design/implementation]

---

## Implementation Learnings

> Insights gained during implementation that may help future iterations.
> E.g., "The DataLoader class requires batch_size to be a power of 2",
> "Docker container needs --network host for S3 access".

- [To be populated during implementation]

---

## Iteration History

| # | Date | Feature Folder | Phase | Summary |
|---|------|----------------|-------|---------|
| 0 | [CURRENT_DATE] | `${FEATURE}` | Tactical Update | [SUMMARY] |

MEMORY_EOF
    echo "Created new memory file: ${MEMORY_FILE}"
fi

# Update memory with learnings from this tactical update
```

Use the **doc_writer** sub-agent tool with these parameters:
- task: "Update the memory file with learnings from this tactical update. Add/update: 1. 'Docker Execution Notes' — any Docker commands or environment knowledge discovered. 2. 'Known Issues & Solutions' — any issues encountered and how they were resolved. 3. 'Environment Setup Notes' — any non-obvious setup discovered. 4. 'Implementation Learnings' — insights that would help future sessions/iterations. 5. 'Iteration History' — add/update entry for this tactical update (feature: ${FEATURE}). 6. Update 'Last Updated' timestamp. Do NOT duplicate information already in requirements.md or todo.md."
- target_file: `${MEMORY_FILE}`
- read_files: `coding_agent_context/specs/${FEATURE}/todo.md`
- output_file: `coding_agent_context/specs/${FEATURE}/memory_tactical_update_session.md`

```bash
cat coding_agent_context/specs/${FEATURE}/memory_tactical_update_session.md
```

---

## EXIT CRITERIA

| Criterion | RUN_TESTS=true | RUN_TESTS=false |
|-----------|----------------|-----------------|
| Dev container running | Step 0 completed | Step 0 completed |
| All tasks complete | All `[x]` in todo.md | All `[x]` in todo.md |
| Tests pass (in Docker) | Full suite passes | N/A |
| Code quality (in Docker) | Tests + linting | Linting only |
| No host execution | Zero `pytest`/`python` on host | Zero `pytest`/`python` on host |
| Memory file updated | `memory.md` exists in base feature folder with session learnings |

---

## QUICK REFERENCE

```
TACTICAL UPDATE FLOW:
┌─────────────────────────────────────────────────────────────────────────────┐
│ 🚫 DOCKER-ONLY: ALL execution in dev container. NEVER on the host.         │
├─────────────────────────────────────────────────────────────────────────────┤
│ 🧠 MEMORY: Load memory.md at start. Update with learnings at end.           │
│    Memory file: coding_agent_context/specs/${BASE_FEATURE}/memory.md        │
│    (For iterations: BASE_FEATURE strips _iteration_<N> suffix)              │
├─────────────────────────────────────────────────────────────────────────────┤
│ 0. DOCKER:   dev_container.sh --action ensure → MUST succeed first         │
│ 1. PLAN:     analyst → architect sub-agents → todo.md                      │
│ 2. EXECUTE:  FOR EACH task:                                                │
│              ├─ IF RUN_TESTS: qa_engineer → developer → run_tests.sh       │
│              └─ ELSE:         developer only                               │
│ 3. VERIFY:   run_tests.sh (if RUN_TESTS) or dev_container exec ruff       │
│ 4. MEMORY:   Update memory.md with issues, solutions, learnings            │
└─────────────────────────────────────────────────────────────────────────────┘
```
