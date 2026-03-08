# MISSION: Architectural Design Phase

> **Type:** Feature Design | **Output:** Design Document + Implementation Plan

---
Obtain FEATURE from the environment variable ${FEATURE}

---

## MEMORY FILE RESOLUTION

> **🧠 MEMORY PERSISTENCE:** This mission maintains a memory file that captures design
> discoveries, encountered issues and their solutions, environment-specific knowledge
> (e.g., Docker commands, dependency quirks), and other learnings that are NOT part of
> `requirements.md`, `design.md`, or the progress tracker. This knowledge persists across
> sessions and across the `architecture_design.md` → `implement_tdd.md` workflow.

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
    echo "NO MEMORY FILE: Will create one after design phase completes."
fi
```

> **How to use loaded memory during design:**
> - If memory contains **Docker Execution Notes**, factor them into the design
>   (e.g., known container mount paths, rebuild commands, package constraints).
> - If memory contains **Known Issues & Solutions**, check whether the new design
>   touches the same areas — reuse the solutions, avoid the same pitfalls.
> - If memory contains **Environment Setup Notes**, ensure the design is compatible.
> - If this is an iteration, review **what was learned in prior iterations** to
>   inform design decisions for this one.

---

## OBJECTIVE

Create a comprehensive Design Document and Implementation Plan for a new feature.

**Output Location:** `coding_agent_context/specs/${FEATURE}/design.md`

---

## CRITICAL: DOCKER EXECUTION AWARENESS

> **⚠️ IMPORTANT FOR DESIGN DECISIONS:**
> The implementation that follows this design phase (via `implement_tdd.md`) will
> execute ALL code — tests, scripts, linting — exclusively inside the dev Docker
> container. The architect MUST account for this:
>
> 1. **Dependencies:** Any new Python packages MUST be added to the project's
>    `requirements.txt` (or equivalent) so they are installed in the Docker image.
>    Do NOT assume packages are available on the host.
> 2. **Docker rebuild:** If the design introduces new dependencies, the
>    Implementation Plan MUST include a step to rebuild the Docker image
>    (`dev_container.sh --action rebuild`) before running tests.
> 3. **File paths:** All code paths should be relative to the project root
>    (which is mounted at `/app/workspace` in the container).
> 4. **No host-side tooling:** Do not design solutions that require host-side
>    package installations, virtual environments, or host-only commands.

---

## INPUTS

| Input | Path | Description |
|-------|------|-------------|
| Requirements | `coding_agent_context/specs/${FEATURE}/requirements.md` | Feature requirements |
| Template | `coding_agent_context/specs/templates/design_doc.md` | Design document template |
| Memory (if exists) | `coding_agent_context/specs/${BASE_FEATURE}/memory.md` | Accumulated knowledge from prior sessions/iterations |

---

## Expected `requirements.md` Format

The file `coding_agent_context/specs/${FEATURE}/requirements.md` drives this mission.
It should follow this structure:

```markdown
# Feature: <FEATURE_NAME>

## Summary
One-paragraph description of the feature and its purpose.

## Background / Motivation
Why this feature is needed. Link to relevant tickets, discussions, or prior work.

## Functional Requirements
- [ ] FR-1: Description of a required behavior
- [ ] FR-2: Description of another required behavior
- ...

## Non-Functional Requirements (optional)
- Performance: e.g., "Must process 10k records in < 5s"
- Scalability: e.g., "Must support datasets up to 50 GB"
- Compatibility: e.g., "Must work with Python 3.10+"

## Constraints
- Any hard constraints on the design (e.g., "Must use existing DataLoader class")
- Dependencies on external systems or APIs

## Acceptance Criteria
- [ ] AC-1: Testable criterion that proves the feature works
- [ ] AC-2: Another testable criterion
- ...

## New Dependencies (if any)
List any new Python packages or system dependencies the feature requires.
These MUST be added to `requirements.txt` / `docker/requirements.txt` so the
Docker environment includes them.

- `package-name>=version` — reason for dependency

## Out of Scope
What this feature intentionally does NOT cover (helps bound the design).
```

---

## EXECUTION STEPS

### Step 1: Initialize

Copy the template to create the design document:

```bash
cp coding_agent_context/specs/templates/design_doc.md coding_agent_context/specs/${FEATURE}/design.md
```

---

### Step 2: Discovery (Analyst)

**Goal:** Understand where this feature fits in the existing codebase.

Use the **analyst** sub-agent tool with these parameters:
- focus: "How does the current system handle ${TOPIC}? Identify integration points."
- read_files: `src/relevant_file1.py,src/relevant_file2.py`
- output_file: `coding_agent_context/specs/${FEATURE}/discovery_output.md`

```bash
# Read results
cat coding_agent_context/specs/${FEATURE}/discovery_output.md
```

---

### Step 3: Draft Context & Architecture (Architect)

**Goal:** Fill out the Context and Architecture sections of the design doc.

Use the **architect** sub-agent tool with these parameters:
- task: "Fill out the Context and Architecture sections based on discovery findings"
- target_file: `coding_agent_context/specs/${FEATURE}/design.md`
- read_files: `coding_agent_context/specs/${FEATURE}/discovery_output.md`
- output_file: `coding_agent_context/specs/${FEATURE}/architect_session_1.md`

```bash
# Read session log
cat coding_agent_context/specs/${FEATURE}/architect_session_1.md
```

---

### Step 4: Detailed Design (Architect)

**Goal:** Define Data Models and API Interfaces.

Use the **architect** sub-agent tool with these parameters:
- task: "Define the Data Models and API Interfaces sections"
- target_file: `coding_agent_context/specs/${FEATURE}/design.md`
- output_file: `coding_agent_context/specs/${FEATURE}/architect_session_2.md`

```bash
cat coding_agent_context/specs/${FEATURE}/architect_session_2.md
```

---

### Step 5: Critique & Refine (Architect)

**Goal:** Review for edge cases and add risk assessment.

Use the **architect** sub-agent tool with these parameters:
- task: "Review the design for missing edge cases. Add a Risk Assessment section."
- target_file: `coding_agent_context/specs/${FEATURE}/design.md`
- output_file: `coding_agent_context/specs/${FEATURE}/architect_session_3.md`

```bash
cat coding_agent_context/specs/${FEATURE}/architect_session_3.md
```

---

### Step 6: TDD Planning (Architect)

**Goal:** Create step-by-step Implementation Plan for TDD execution.

> **IMPORTANT:** The implementation plan MUST account for Docker execution:
> - If the design introduces new dependencies, the FIRST implementation step
>   must be: "Update requirements.txt and rebuild Docker image"
> - All test execution steps reference `run_tests.sh` (Docker-only)
> - No steps should assume host-side Python execution

Use the **architect** sub-agent tool with these parameters:
- task: "Create the step-by-step TDD Implementation Plan at the bottom of the doc. Each step must be atomic and testable. If new dependencies are needed, the first step MUST be updating requirements.txt and rebuilding the Docker image. All test steps use run_tests.sh (Docker execution)."
- target_file: `coding_agent_context/specs/${FEATURE}/design.md`
- output_file: `coding_agent_context/specs/${FEATURE}/architect_session_4.md`

```bash
cat coding_agent_context/specs/${FEATURE}/architect_session_4.md
```

---

## Step 7: Update Memory File

**Goal:** Capture design-phase discoveries, environment knowledge, and any issues encountered
during discovery/design that are NOT already in `requirements.md` or `design.md`. This knowledge
will carry forward into `implement_tdd.md` and future iterations.

> **What to record in memory (examples):**
> - Docker execution notes (e.g., container mount paths, rebuild commands needed)
> - Dependency discoveries (e.g., "package X requires system lib Y in Docker image")
> - Codebase insights that influenced the design but aren't in the design doc
> - Known gotchas or pitfalls discovered during analysis
> - Environment setup steps that were non-obvious
> - Integration points that required investigation
>
> **What NOT to record (already tracked elsewhere):**
> - Requirements (in `requirements.md`)
> - Design decisions (in `design.md`)
> - Implementation plan (in `design.md`)
> - Progress tracking (in `progress.md` — created by `implement_tdd.md`)

```bash
# Resolve MEMORY_FILE path (same logic as Memory File Resolution above)
if [[ "${FEATURE}" =~ ^(.+)_iteration_[0-9]+$ ]]; then
    BASE_FEATURE="${BASH_REMATCH[1]}"
else
    BASE_FEATURE="${FEATURE}"
fi
MEMORY_FILE="coding_agent_context/specs/${BASE_FEATURE}/memory.md"
```

### If memory file does NOT exist — create it:

```bash
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
| 0 | [CURRENT_DATE] | `${FEATURE}` | Design | Initial architecture design |

MEMORY_EOF
    echo "Created new memory file: ${MEMORY_FILE}"
fi
```

### Update memory with design-phase learnings:

Use the **doc_writer** sub-agent tool with these parameters:
- task: "Update the memory file with any design-phase discoveries. Add entries to: 1. 'Docker Execution Notes' — if any Docker-specific knowledge was discovered. 2. 'Known Issues & Solutions' — if any issues were encountered during discovery/design. 3. 'Environment Setup Notes' — if any non-obvious setup was identified. 4. 'Iteration History' — add/update entry for this design phase (feature: ${FEATURE}). 5. Update 'Last Updated' timestamp. Do NOT duplicate information that is already in requirements.md or design.md. Only record supplementary knowledge that helps future sessions."
- target_file: `${MEMORY_FILE}`
- read_files: `coding_agent_context/specs/${FEATURE}/design.md`
- output_file: `coding_agent_context/specs/${FEATURE}/memory_design_update_session.md`

```bash
cat coding_agent_context/specs/${FEATURE}/memory_design_update_session.md
```

---

## EXIT CRITERIA

| Criterion | Validation |
|-----------|------------|
| Design doc complete | All sections of `design.md` are populated |
| Implementation Plan granular | Each step is atomic (e.g., "Create class X", not "Build feature") |
| Plan is checkboxed | Each step has `[ ]` for progress tracking |
| Docker-aware | New deps → first step updates requirements.txt + Docker rebuild |
| No host assumptions | No steps require host-side `pip install`, `python`, or `pytest` |
| Memory file updated | `memory.md` exists in base feature folder and contains design-phase learnings |

---

## NEXT MISSION

After completion, proceed to: **`implement_tdd.md`**

> **Reminder:** `implement_tdd.md` will start by ensuring the dev Docker container is
> running (Step 0). If this design introduced new dependencies, the container will be
> rebuilt automatically when the image is missing or out of date.
