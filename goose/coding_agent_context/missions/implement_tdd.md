# MISSION: TDD Execution Phase

> **Type:** Implementation | **Method:** Red-Green-Refactor TDD

---

## CONFIGURATION

Obtain FEATURE from the environment variable ${FEATURE}

---

## MEMORY FILE RESOLUTION

> **🧠 MEMORY PERSISTENCE:** This mission uses the same memory file created by
> `architecture_design.md`. It records implementation learnings — encountered issues
> and their solutions, Docker execution discoveries, environment quirks, and other
> knowledge that is NOT part of `requirements.md`, `design.md`, or `progress.md`.
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

### Load existing memory

```bash
if [ -f "${MEMORY_FILE}" ]; then
    echo "MEMORY FOUND: Loading existing knowledge from ${MEMORY_FILE}"
    cat "${MEMORY_FILE}"
else
    echo "NO MEMORY FILE: Will create one during implementation."
fi
```

> **How to use loaded memory during implementation:**
> - If memory contains **Docker Execution Notes**, use those exact commands for
>   running tests and code — do NOT guess or re-derive Docker commands.
> - If memory contains **Known Issues & Solutions**, check whether the current
>   implementation step touches the same areas — apply known solutions proactively.
> - If memory contains **Environment Setup Notes**, verify the environment matches
>   before running tests.
> - If this is an iteration, review **Implementation Learnings** from prior iterations
>   to avoid repeating mistakes.

---

## CRITICAL: DOCKER-ONLY EXECUTION POLICY

> **🚫 ABSOLUTE RULE — NO EXCEPTIONS:**
> ALL code execution during TDD (running tests, running scripts, linting, debugging)
> MUST happen **exclusively inside the dev Docker container**. The agent MUST NEVER:
> - Run `pytest`, `python`, `pip`, or any code-execution command directly on the host
> - Install Python packages on the host (e.g., `pip install`)
> - Execute test files on the host for "quick checks"
>
> **The ONLY permitted execution methods are:**
> 1. `./coding_agent_context/tools/run_tests.sh` (runs pytest inside Docker automatically)
> 2. `./coding_agent_context/tools/dev_container.sh --action exec --cmd "<command>"` (arbitrary command in Docker)
> 3. `docker exec -i <container_name> <command>` (direct Docker exec)
>
> **If the dev container is not running:** The tools will auto-start it.
> **If no Docker environment exists:** `dev_container.sh --action ensure` will auto-generate one.
>
> **NEVER do this:**
> ```bash
> # ❌ FORBIDDEN — direct host execution
> pytest tests/test_auth.py
> python -m pytest tests/
> python -c "import mymodule; ..."
> pip install pandas
> cd tests && python -m pytest
> ```
>
> **ALWAYS do this:**
> ```bash
> # ✅ CORRECT — Docker execution via run_tests.sh
> ./coding_agent_context/tools/run_tests.sh -o coding_agent_context/specs/${FEATURE}/results.md -t tests/test_auth.py
>
> # ✅ CORRECT — Docker execution via dev_container.sh
> ./coding_agent_context/tools/dev_container.sh --action exec --cmd "pytest tests/test_auth.py -v"
>
> # ✅ CORRECT — Docker execution via docker exec
> docker exec -i dev-container-<project> pytest tests/test_auth.py -v
> ```

---

## OBJECTIVE

Execute the Implementation Plan from the Design Document using strict TDD methodology.

**Constraint:** Every code change MUST follow the Red-Green-Refactor cycle.
**Constraint:** Every test/code execution MUST happen inside Docker.

---

## TEST QUALITY PRINCIPLES

> **CRITICAL:** Tests written during TDD MUST focus on **behavior and public interfaces**, NOT implementation details.
> This ensures the implementation remains flexible and tests remain maintainable.

### Golden Rules for TDD Tests

| Rule | Description |
|------|-------------|
| **Test Behavior** | Test WHAT the code does, not HOW it does it |
| **Public APIs Only** | Only test public methods and functions |
| **Observable Outcomes** | Assert on return values, side effects, and state changes visible through public interfaces |
| **Implementation Freedom** | Tests should pass regardless of internal refactoring |

### DO Test:
- Public methods and their return values
- Error handling (exceptions raised by public methods)
- Observable side effects (files created, API calls made, etc.)
- Integration between public components
- Edge cases through public interfaces

### DO NOT Test:
- Private methods (methods starting with `_`)
- Internal data structures or private attributes
- Exact implementation algorithms
- Source code structure or file organization
- Number of internal function calls
- Specific internal state that isn't exposed publicly

### Why This Matters for TDD:
1. **RED phase**: Write tests that define the PUBLIC CONTRACT
2. **GREEN phase**: Implement ANY solution that satisfies the contract
3. **REFACTOR phase**: Safely refactor internals without breaking tests

### Example:
```python
# ❌ BAD: Test couples to implementation
def test_uses_internal_cache():
    service = DataService()
    service.fetch('key')
    assert service._cache['key'] is not None  # Tests internal!

# ✅ GOOD: Test verifies behavior
def test_fetch_returns_data_for_valid_key():
    service = DataService()
    result = service.fetch('key')
    assert result is not None
    assert result.data == 'expected_value'
```

---

## INPUTS

| Input | Path | Description |
|-------|------|-------------|
| Design Document | `coding_agent_context/specs/${FEATURE}/design.md` | Contains Implementation Plan in Section 6 |
| Progress Tracker | `coding_agent_context/specs/${FEATURE}/progress.md` | Tracks step completion status |
| Memory (if exists) | `coding_agent_context/specs/${BASE_FEATURE}/memory.md` | Accumulated knowledge from design and prior sessions/iterations |
| Source Directory | `src/` | Production code location |
| Test Directory | `tests/` | Test code location |

---

## INITIALIZATION (START HERE)

### Step 0: Ensure Docker Dev Container is Running

> **MANDATORY FIRST STEP — Before ANY code execution, before writing tests,
> before doing anything else.** The dev container MUST be confirmed running.

```bash
# Ensure the dev container is running (idempotent — safe to call repeatedly)
./coding_agent_context/tools/dev_container.sh --action ensure
```

**What this does:**
1. Checks if the dev container is already running → if yes, verifies health
2. Checks if the Docker image exists → if not, builds it
3. Checks if a Dockerfile exists → if not, **auto-generates** one from the project
4. Starts the container in daemon mode with the project mounted
5. Verifies Python and pytest are available inside the container

**If this step fails:**
- Check that Docker is installed and running on the host
- Check `docker/Dockerfile` for syntax errors
- Run `./coding_agent_context/tools/dev_container.sh --action rebuild` to force a fresh build

**DO NOT PROCEED** to Step 1 until the dev container is confirmed running.

---

### Step 1: Check for Existing Progress

> **CRITICAL:** Always check for existing progress before starting work. This enables resumption after interruption.

```bash
# Check if progress tracker exists
if [ -f "coding_agent_context/specs/${FEATURE}/progress.md" ]; then
    echo "RESUMING: Found existing progress tracker"
    cat coding_agent_context/specs/${FEATURE}/progress.md
else
    echo "FRESH START: No progress tracker found"
fi
```

**Decision Tree:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Does coding_agent_context/specs/${FEATURE}/progress.md exist?               │
├──────────────────────────────────┬──────────────────────────────────────────┤
│ NO → Go to Step 2 (Initialize)   │ YES → Go to Step 3 (Find Resume Point)  │
└──────────────────────────────────┴──────────────────────────────────────────┘
```

---

### Step 2: Initialize Progress Tracker (Fresh Start Only)

**Skip this step if progress.md already exists.**

```bash
# Read the design document to extract Implementation Plan
cat coding_agent_context/specs/${FEATURE}/design.md
```

Create `coding_agent_context/specs/${FEATURE}/progress.md` with this structure:

```markdown
# TDD Progress Tracker: ${FEATURE}

> **Status:** IN_PROGRESS
> **Started:** [CURRENT_DATE]
> **Last Updated:** [CURRENT_DATE]

---

## Progress Summary

| Metric | Value |
|--------|-------|
| Total Steps | [N] |
| Completed | 0 |
| Remaining | [N] |
| Current Step | 1.1 |

---

## Implementation Checklist

> Copy items from Section 6 (Implementation Plan) of design.md
> Each item has four phases: TEST_WRITTEN, TEST_RED, CODE_WRITTEN, TEST_GREEN

### Phase 1: Foundation

| Step | Status | Task | Test File | Source File |
|------|--------|------|-----------|-------------|
| 1.1 | `[ ] PENDING` | [Task description] | `tests/test_x.py` | `src/x.py` |
| 1.2 | `[ ] PENDING` | [Task description] | `tests/test_y.py` | `src/y.py` |

### Phase 2: Integration

| Step | Status | Task | Test File | Source File |
|------|--------|------|-----------|-------------|
| 2.1 | `[ ] PENDING` | [Task description] | `tests/test_z.py` | `src/z.py` |

---

## Execution Log

| Timestamp | Step | Phase | Result | Notes |
|-----------|------|-------|--------|-------|
| | | | | |
```

**Action:**

Use the **doc_writer** sub-agent tool with these parameters:
- task: "Create progress tracker from Implementation Plan in design.md. Use the template structure above."
- target_file: `coding_agent_context/specs/${FEATURE}/progress.md`
- read_files: `coding_agent_context/specs/${FEATURE}/design.md`
- output_file: `coding_agent_context/specs/${FEATURE}/init_progress_session.md`

```bash
cat coding_agent_context/specs/${FEATURE}/init_progress_session.md
```

---

### Step 3: Find Resume Point (Resuming Existing Work)

```bash
# Read progress tracker to find current state
cat coding_agent_context/specs/${FEATURE}/progress.md
```

**Locate the first step with status `[ ] PENDING` or `[~] IN_PROGRESS`.**

Status meanings:
| Status | Meaning | Next Action |
|--------|---------|-------------|
| `[ ] PENDING` | Not started | Begin at Step A (RED) |
| `[~] IN_PROGRESS` | Partially complete | Check Execution Log for last completed phase |
| `[x] COMPLETE` | Finished | Skip to next step |

**For `[~] IN_PROGRESS` steps, check Execution Log:**
| Last Logged Phase | Resume At |
|-------------------|-----------|
| `TEST_WRITTEN` | Verify RED (run test, should fail) |
| `TEST_RED` | Step B (GREEN - write code) |
| `CODE_WRITTEN` | Verify GREEN (run test, should pass) |
| `TEST_GREEN` | Step D (Mark complete) |

---

## THE BUILD LOOP

> **Repeat for each step that is NOT marked `[x] COMPLETE`**
>
> **🚫 REMINDER:** Every `run_tests.sh` invocation below runs tests inside Docker.
> NEVER bypass it by running `pytest` directly on the host.

### Step A: RED (Write Failing Test)

**Goal:** Create a test that defines expected behavior. Test MUST fail.

```bash
# Update progress: Mark step as IN_PROGRESS
sed -i 's/| STEP_ID | `\[ \] PENDING`/| STEP_ID | `[~] IN_PROGRESS`/' \
    coding_agent_context/specs/${FEATURE}/progress.md

# Log the start
echo "| $(date -Iseconds) | STEP_ID | TEST_WRITING | STARTED | |" >> \
    coding_agent_context/specs/${FEATURE}/progress.md
```

Use the **qa_engineer** sub-agent tool with these parameters:
- task: "Implement test for: [PLAN_ITEM_DESCRIPTION]"
- target_file: `tests/test_${COMPONENT}.py`
- read_files: `coding_agent_context/specs/${FEATURE}/design.md`
- output_file: `coding_agent_context/specs/${FEATURE}/qa_session.md`

```bash
cat coding_agent_context/specs/${FEATURE}/qa_session.md

# Log test written
echo "| $(date -Iseconds) | STEP_ID | TEST_WRITTEN | SUCCESS | |" >> \
    coding_agent_context/specs/${FEATURE}/progress.md

# Verify test FAILS (runs inside Docker via run_tests.sh)
./coding_agent_context/tools/run_tests.sh \
    -o coding_agent_context/specs/${FEATURE}/test_red_results.md \
    -t tests/test_${COMPONENT}.py

cat coding_agent_context/specs/${FEATURE}/test_red_results.md

# Log RED confirmed
echo "| $(date -Iseconds) | STEP_ID | TEST_RED | CONFIRMED | Test fails as expected |" >> \
    coding_agent_context/specs/${FEATURE}/progress.md
```

**Constraint:** If test passes, it is invalid—the code already exists or test is wrong.

---

### Step B: GREEN (Write Minimal Code)

**Goal:** Write the minimum code to make the test pass.

Use the **developer** sub-agent tool with these parameters:
- task: "Implement logic for: [PLAN_ITEM_DESCRIPTION]"
- target_file: `src/${COMPONENT}.py`
- read_files: `tests/test_${COMPONENT}.py,coding_agent_context/specs/${FEATURE}/design.md`
- output_file: `coding_agent_context/specs/${FEATURE}/dev_session.md`

```bash
cat coding_agent_context/specs/${FEATURE}/dev_session.md

# Log code written
echo "| $(date -Iseconds) | STEP_ID | CODE_WRITTEN | SUCCESS | |" >> \
    coding_agent_context/specs/${FEATURE}/progress.md

# Verify test PASSES (runs inside Docker via run_tests.sh)
./coding_agent_context/tools/run_tests.sh \
    -o coding_agent_context/specs/${FEATURE}/test_green_results.md \
    -t tests/test_${COMPONENT}.py

cat coding_agent_context/specs/${FEATURE}/test_green_results.md
```

**Constraint:** Test MUST pass. If it fails, enter Debug Mode.

---

### Step C: DEBUG (If GREEN Fails)

**Trigger:** Test fails after Step B implementation.

**Actions:**

1. Read the failure output:
   ```bash
   cat test_green_results.md
   ```

2. Log debug attempt:
   ```bash
   echo "| $(date -Iseconds) | STEP_ID | DEBUG | STARTED | [ERROR_SUMMARY] |" >> \
       coding_agent_context/specs/${FEATURE}/progress.md
   ```

3. Call developer with **specific** fix using the **developer** sub-agent tool:
   - task: "Fix: [SPECIFIC_ERROR_FROM_TRACEBACK]"
   - target_file: `src/${COMPONENT}.py`
   - read_files: `tests/test_${COMPONENT}.py`
   - output_file: `coding_agent_context/specs/${FEATURE}/dev_fix_session.md`

   ```bash
   cat coding_agent_context/specs/${FEATURE}/dev_fix_session.md
   ```

4. Re-run tests (inside Docker):
   ```bash
   ./coding_agent_context/tools/run_tests.sh \
       -o coding_agent_context/specs/${FEATURE}/test_retry_results.md \
       -t tests/test_${COMPONENT}.py
   
   cat test_retry_results.md
   ```

5. Repeat until GREEN, then log success:
   ```bash
   echo "| $(date -Iseconds) | STEP_ID | DEBUG | RESOLVED | Fixed after N attempts |" >> \
       coding_agent_context/specs/${FEATURE}/progress.md
   ```

6. **Update memory with the issue and solution:**
   > Every resolved debug cycle is valuable knowledge. Record the issue and its fix
   > so future sessions (and iterations) don't re-discover the same problems.

   ```bash
   # Resolve MEMORY_FILE path
   if [[ "${FEATURE}" =~ ^(.+)_iteration_[0-9]+$ ]]; then
       BASE_FEATURE="${BASH_REMATCH[1]}"
   else
       BASE_FEATURE="${FEATURE}"
   fi
   MEMORY_FILE="coding_agent_context/specs/${BASE_FEATURE}/memory.md"

   # If memory file doesn't exist yet, create it (see template in architecture_design.md Step 7)
   if [ ! -f "${MEMORY_FILE}" ]; then
       mkdir -p "$(dirname "${MEMORY_FILE}")"
       # Create with the standard template (see architecture_design.md Step 7 for full template)
       cat > "${MEMORY_FILE}" << 'MEMORY_EOF'
# Implementation Memory: ${BASE_FEATURE}

> **Status:** IN_PROGRESS
> **Created:** [CURRENT_DATE]
> **Last Updated:** [CURRENT_DATE]
> **Feature:** ${BASE_FEATURE}

---

## Docker Execution Notes

| Topic | Details |
|-------|---------|
| | |

---

## Known Issues & Solutions

| # | Date | Phase | Issue | Solution | Affected Files |
|---|------|-------|-------|----------|----------------|
| | | | | | |

---

## Environment Setup Notes

- [To be populated during design/implementation]

---

## Implementation Learnings

- [To be populated during implementation]

---

## Iteration History

| # | Date | Feature Folder | Phase | Summary |
|---|------|----------------|-------|---------|
| | | | | |

MEMORY_EOF
       echo "Created new memory file: ${MEMORY_FILE}"
   fi

   Use the **doc_writer** sub-agent tool with these parameters:
   - task: "Add a new entry to 'Known Issues & Solutions' in the memory file: Issue: [SPECIFIC_ERROR_SUMMARY], Solution: [WHAT_FIXED_IT], Phase: TDD Implementation (Step STEP_ID), Affected Files: [FILES_MODIFIED_TO_FIX]. Also update 'Last Updated' timestamp."
   - target_file: `${MEMORY_FILE}`
   - read_files: (none)
   - output_file: `coding_agent_context/specs/${FEATURE}/memory_debug_update_session.md`

   ```bash
   cat coding_agent_context/specs/${FEATURE}/memory_debug_update_session.md
   ```

> **🚫 REMINDER:** During debugging, do NOT attempt to run Python or pytest on the host
> to "quickly check" something. Always use `run_tests.sh` or `dev_container.sh --action exec`.

---

### Step D: Mark Complete & Update Progress

**Goal:** Mark the step as complete and update progress summary.

```bash
# Mark step as COMPLETE in progress tracker
sed -i 's/| STEP_ID | `\[~\] IN_PROGRESS`/| STEP_ID | `[x] COMPLETE`/' \
    coding_agent_context/specs/${FEATURE}/progress.md

# Log completion
echo "| $(date -Iseconds) | STEP_ID | TEST_GREEN | CONFIRMED | Step complete |" >> \
    coding_agent_context/specs/${FEATURE}/progress.md
```

Update Progress Summary (increment Completed, decrement Remaining, update Current Step):

Use the **doc_writer** sub-agent tool with these parameters:
- task: "Update Progress Summary: increment Completed count, decrement Remaining count, set Current Step to next PENDING step"
- target_file: `coding_agent_context/specs/${FEATURE}/progress.md`
- output_file: `coding_agent_context/specs/${FEATURE}/progress_update_session.md`

```bash
# Also mark in design.md for reference
sed -i 's/\[ \] PLAN_ITEM_DESCRIPTION/[x] PLAN_ITEM_DESCRIPTION/' \
    coding_agent_context/specs/${FEATURE}/design.md
```

**Why track in both files?**
- `progress.md`: Detailed execution state for resumption
- `design.md`: High-level progress view for humans

---

## FINALIZATION

### Run Full Test Suite (Inside Docker)

```bash
./coding_agent_context/tools/run_tests.sh \
    -o coding_agent_context/specs/${FEATURE}/final_test_results.md \
    -t tests/

cat coding_agent_context/specs/${FEATURE}/final_test_results.md
```

### Mark Mission Complete

```bash
# Update progress tracker status
sed -i 's/> \*\*Status:\*\* IN_PROGRESS/> **Status:** COMPLETE/' \
    coding_agent_context/specs/${FEATURE}/progress.md

# Update Last Updated timestamp
sed -i "s/> \*\*Last Updated:\*\*.*/> **Last Updated:** $(date -Iseconds)/" \
    coding_agent_context/specs/${FEATURE}/progress.md

# Final log entry
echo "| $(date -Iseconds) | FINAL | COMPLETE | SUCCESS | All steps complete, all tests pass |" >> \
    coding_agent_context/specs/${FEATURE}/progress.md
```

### Update Memory File (Final)

**Goal:** Capture all implementation learnings from this session — especially things
that would help a future session or iteration avoid re-work.

```bash
# Resolve MEMORY_FILE path
if [[ "${FEATURE}" =~ ^(.+)_iteration_[0-9]+$ ]]; then
    BASE_FEATURE="${BASH_REMATCH[1]}"
else
    BASE_FEATURE="${FEATURE}"
fi
MEMORY_FILE="coding_agent_context/specs/${BASE_FEATURE}/memory.md"

# If memory file still doesn't exist (e.g., architecture_design was skipped), create it
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

| Topic | Details |
|-------|---------|
| | |

---

## Known Issues & Solutions

| # | Date | Phase | Issue | Solution | Affected Files |
|---|------|-------|-------|----------|----------------|
| | | | | | |

---

## Environment Setup Notes

- [To be populated during design/implementation]

---

## Implementation Learnings

- [To be populated during implementation]

---

## Iteration History

| # | Date | Feature Folder | Phase | Summary |
|---|------|----------------|-------|---------|
| | | | | |

MEMORY_EOF
    echo "Created new memory file: ${MEMORY_FILE}"
fi

Use the **doc_writer** sub-agent tool with these parameters:
- task: "Update the memory file with implementation-phase learnings. Add/update: 1. 'Docker Execution Notes' — any Docker commands, mount paths, rebuild steps discovered. 2. 'Known Issues & Solutions' — any NEW issues encountered (skip if already logged during DEBUG). 3. 'Environment Setup Notes' — any environment quirks discovered. 4. 'Implementation Learnings' — insights that would help future iterations: How commands need to be executed in the Docker environment, How to update the Docker environment, Non-obvious patterns or constraints in the codebase, Anything the agent had to figure out that isn't in requirements.md or design.md. 5. 'Iteration History' — add/update entry for this implementation (feature: ${FEATURE}). 6. Update 'Last Updated' timestamp, set Status to COMPLETE (if no more iterations expected). Do NOT duplicate information already in requirements.md, design.md, or progress.md."
- target_file: `${MEMORY_FILE}`
- read_files: `coding_agent_context/specs/${FEATURE}/progress.md`
- output_file: `coding_agent_context/specs/${FEATURE}/memory_final_update_session.md`

```bash
cat coding_agent_context/specs/${FEATURE}/memory_final_update_session.md
```

**Exit Criteria:**
- Dev container confirmed running (Step 0 completed)
- All tests pass (executed inside Docker, never on host)
- All steps marked `[x] COMPLETE` in progress.md
- All Implementation Plan items marked `[x]` in design.md
- Progress tracker status is `COMPLETE`
- Memory file updated with implementation learnings
- No regressions introduced

---

## LOOP SUMMARY

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 🚫 DOCKER-ONLY EXECUTION: ALL tests and code run inside the dev container. │
│    NEVER run pytest, python, or pip directly on the host.                    │
│    Use run_tests.sh or dev_container.sh --action exec for all execution.     │
├─────────────────────────────────────────────────────────────────────────────┤
│ 🧠 MEMORY: Load memory.md at start. Update on DEBUG resolutions.            │
│    Finalize memory with implementation learnings at end.                     │
│    Memory file: coding_agent_context/specs/${BASE_FEATURE}/memory.md        │
│    (For iterations: BASE_FEATURE strips _iteration_<N> suffix)              │
├─────────────────────────────────────────────────────────────────────────────┤
│ 0. DOCKER:   dev_container.sh --action ensure → MUST succeed first          │
├─────────────────────────────────────────────────────────────────────────────┤
│ INITIALIZATION (RUN ONCE PER SESSION):                                      │
│   Load memory.md → Check progress.md exists?                                │
│   → NO: Create it | YES: Find resume point                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│ FOR EACH STEP NOT MARKED [x] COMPLETE:                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│ 1. RED:    Mark [~] IN_PROGRESS → qa_engineer tool → run_tests.sh → MUST FAIL │
│ 2. GREEN:  developer tool → run_tests.sh → MUST PASS                         │
│ 3. DEBUG:  (if needed) → developer tool → run_tests.sh → repeat until PASS   │
│            → UPDATE MEMORY with issue & solution on each DEBUG resolution     │
│ 4. TRACK:  Mark [x] COMPLETE → Update progress summary → Log completion      │
├─────────────────────────────────────────────────────────────────────────────┤
│ FINALIZATION:                                                               │
│   Run full test suite (Docker) → Mark progress.md COMPLETE                  │
│   → Update memory.md with final implementation learnings                    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## RESUMPTION QUICK REFERENCE

| Scenario | Action |
|----------|--------|
| Fresh start (no progress.md) | **Step 0: ensure dev container** → Load memory.md → Create progress.md from design.md, start at Step 1.1 |
| Resume (progress.md exists) | **Step 0: ensure dev container** → Load memory.md (consult Known Issues) → Read progress.md, find first non-COMPLETE step |
| Step is `[ ] PENDING` | Start at Step A (RED) |
| Step is `[~] IN_PROGRESS` | Check Execution Log, resume at appropriate phase |
| All steps `[x] COMPLETE` | Run finalization only (including final memory update) |
| Dev container not running | `dev_container.sh --action ensure` (auto-starts or creates Docker env) |
