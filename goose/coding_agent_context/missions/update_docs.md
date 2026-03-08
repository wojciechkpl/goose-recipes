# MISSION: Deep Code Analysis & Documentation Update

> **Type:** Documentation Maintenance | **Scope:** All Agent Documentation | **Method:** Identify-Analyze-Critique-Update Loop

---

## CONFIGURATION

Obtain `DOC_SCOPE` from the environment variable `${DOC_SCOPE}`.

`DOC_SCOPE` controls which documentation files are processed:

| DOC_SCOPE Value | Behavior |
|-----------------|----------|
| `all` (default) | Process every `*_Agent.md` file in `coding_agent_context/docs/` |
| `<AgentName>` | Process only `coding_agent_context/docs/${DOC_SCOPE}_Agent.md` |
| `changed` | Process only Agent docs whose source files appear in `git diff --name-only HEAD~1` |

### Docker Constraints

| Constraint | Rule | Rationale |
|------------|------|-----------|
| **No host code execution** | NEVER run `python`, `pytest`, `pip` on the host | Doc analysis may require running code to verify behavior; all execution must happen in Docker |
| **Docker verification** | Use `dev_container.sh --action exec` to confirm code behavior when docs are ambiguous | Ensures documented behavior matches actual runtime |
| Files per turn | Read at most 4 files per turn | AWS Bedrock crashes on 5+ |
| File reading | Use `cat` for bulk reads | Avoid `text_editor view` for multiple files |

---

## OBJECTIVE

Synchronize all `*_Agent.md` documentation files with the actual codebase implementation.
Detect and eliminate documentation drift: wrong class names, missing methods, outdated flow
diagrams, deleted code still referenced, and undocumented new code.

**Target Files:** `coding_agent_context/docs/*_Agent.md`

**Session Artifacts:** `coding_agent_context/specs/doc_updates/`

---

## SAFETY CONSTRAINTS

| Constraint | Rule | Recovery |
|------------|------|----------|
| File limit | Process ONE agent doc at a time | Prevents context overflow and partial updates |
| Path verification | Use `ls` to verify all paths before passing to tools | Avoids silent failures on missing files |
| Skip unknown | If source code cannot be found, skip to next agent | Do not fabricate documentation |
| No code edits | This mission edits ONLY `coding_agent_context/docs/` files | Never modify `src/`, `tests/`, `dags/`, or `scripts/` |
| Preserve structure | Keep existing doc section ordering unless structure is broken | Minimizes diff noise for reviewers |
| Backup before overwrite | Record the original state in the session artifact before applying changes | Enables rollback if update introduces errors |
| Docker-only execution | If verifying code behavior, run inside Docker only | See CONVENTIONS.md Universal Docker-Only Execution Policy |

### Docker-Only Execution Policy

> ALL code execution during documentation verification MUST happen inside Docker.
> This applies when you need to confirm actual runtime behavior (e.g., checking a
> method's return type, verifying an API endpoint exists, confirming import paths).

```bash
# CORRECT: Verify behavior inside Docker
./coding_agent_context/tools/dev_container.sh --action exec --cmd "python -c 'from src.module import ClassName; print(dir(ClassName))'"

# FORBIDDEN: Never run on host
python -c "from src.module import ClassName; print(dir(ClassName))"
```

If no Docker environment is needed (pure doc-vs-source text comparison), Docker is
not required. Docker is ONLY needed when the agent must execute code to resolve
ambiguity in documentation.

---

## MEMORY FILE RESOLUTION

> This mission uses a memory file to persist decisions, discovered patterns, and
> cross-session knowledge about the documentation structure. This is especially
> useful when processing many Agent files across multiple sessions.

### Determine the memory file path

```bash
MEMORY_FILE="coding_agent_context/specs/doc_updates/memory.md"
echo "Memory file: ${MEMORY_FILE}"
```

### Load existing memory

```bash
if [ -f "${MEMORY_FILE}" ]; then
    echo "MEMORY FOUND: Loading existing doc-update knowledge"
    cat "${MEMORY_FILE}"
else
    echo "NO MEMORY FILE: Will create one during this session."
fi
```

### Memory file template

If no memory file exists, create one at the end of the first agent processed:

```markdown
# Documentation Update Memory

> **Last Updated:** [CURRENT_DATE]

---

## Naming Conventions Discovered

| Pattern | Example | Notes |
|---------|---------|-------|
| | | |

---

## Cross-Agent Relationships

| Agent A | Relationship | Agent B | Notes |
|---------|-------------|---------|-------|
| | | | |

---

## Known Documentation Gaps

| Agent | Gap Description | Priority | Status |
|-------|----------------|----------|--------|
| | | | |

---

## Source Code Mapping

| Agent Doc | Primary Source Files | Last Verified |
|-----------|-------------------|---------------|
| | | |

---

## Session Log

| Date | Agents Processed | Changes Made | Notes |
|------|-----------------|--------------|-------|
| | | | |
```

### How to use loaded memory

- **Source Code Mapping**: Use verified paths from prior sessions instead of re-discovering them.
- **Known Documentation Gaps**: Check whether gaps identified in prior sessions have been addressed by new code.
- **Cross-Agent Relationships**: When updating one Agent doc, check if related Agents need corresponding updates.
- **Naming Conventions**: Apply consistent naming discovered in prior sessions.

---

## INITIALIZATION

### Step 0: Load INDEX_Agent.md (Mandatory)

> **CONVENTIONS.md requires this as the first step of every workflow.**

```bash
if [ -f "coding_agent_context/docs/INDEX_Agent.md" ]; then
    echo "INDEX found - loading master reference"
    cat coding_agent_context/docs/INDEX_Agent.md
else
    echo "No INDEX_Agent.md found - proceed without master reference"
fi
```

### Step 1: List All Agent Documentation Files

```bash
# Create output directory for session artifacts
mkdir -p coding_agent_context/specs/doc_updates

# Find all agent documentation files
ls coding_agent_context/docs/*_Agent.md
```

### Step 2: Determine Scope

```bash
# If DOC_SCOPE is "changed", find affected agents from git
if [ "${DOC_SCOPE}" = "changed" ]; then
    echo "Finding agents affected by recent code changes..."
    CHANGED_FILES=$(git diff --name-only HEAD~1)
    echo "Changed source files:"
    echo "${CHANGED_FILES}"
    # Match changed source files to Agent docs by reading each Agent doc header
fi
```

**Decision Tree:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ What is DOC_SCOPE?                                                          │
├──────────────────────┬──────────────────────┬───────────────────────────────┤
│ "all"                │ "<AgentName>"         │ "changed"                     │
│ Process every        │ Process only that     │ Find agents whose source      │
│ *_Agent.md file      │ single Agent doc      │ files changed in last commit  │
└──────────────────────┴──────────────────────┴───────────────────────────────┘
```

---

## EXECUTION LOOP

> **Repeat for each `*_Agent.md` file in scope**

### Step 1: Identify Source Code

**Goal:** Determine which source files the agent documentation covers.

```bash
# Read the agent doc to find source file references
cat coding_agent_context/docs/${AGENT_NAME}_Agent.md | head -50
```

**Look for:**
- File paths mentioned in the document (e.g., `src/processing/pipeline.py`)
- Class/module names that imply source locations (e.g., `SparkProcessor` implies `src/spark_processor.py`)
- Import statements or code examples (e.g., `from src.auth import AuthManager`)
- Mermaid diagrams referencing components
- Dependency lists naming other modules

**Verification:**

```bash
# Verify each discovered source path actually exists
ls src/${SOURCE_FILE1}.py
ls src/${SOURCE_FILE2}.py
# Also check other code folders per CONVENTIONS.md
ls dags/${SOURCE_FILE}.py 2>/dev/null
ls scripts/${SOURCE_FILE}.py 2>/dev/null
```

**If source files cannot be identified:** Skip this agent, log it in the session artifact, and move to next.

---

### Step 2: Analyze Source Code (Analyst)

**Goal:** Generate current understanding of the code's actual responsibilities, classes, methods, and data flow.

Use the **analyst** sub-agent tool with these parameters:
- focus: "Analyze this code for documentation comparison. Provide: 1. All public classes with their public methods (name, parameters, return type, one-line description), 2. Module-level functions, 3. Data flow between components, 4. External dependencies and imports, 5. Any decorators, ABCs, or protocols that define interfaces, 6. Constants and configuration values"
- read_files: `src/${SOURCE_FILE1}.py,src/${SOURCE_FILE2}.py`
- output_file: `coding_agent_context/specs/doc_updates/${AGENT_NAME}_analysis.md`

```bash
# Read analysis results
cat coding_agent_context/specs/doc_updates/${AGENT_NAME}_analysis.md
```

**For large modules (4+ source files), analyze in chunks:**

First chunk (files 1-3):
- read_files: `src/${FILE1}.py,src/${FILE2}.py,src/${FILE3}.py`
- output_file: `coding_agent_context/specs/doc_updates/${AGENT_NAME}_analysis_part1.md`

Second chunk (files 4-6):
- read_files: `src/${FILE4}.py,src/${FILE5}.py,src/${FILE6}.py`
- output_file: `coding_agent_context/specs/doc_updates/${AGENT_NAME}_analysis_part2.md`

Then consolidate before proceeding to Step 3.

---

### Step 3: Critique (Compare Analysis vs Documentation)

**Goal:** Systematically identify every discrepancy between the actual code and its documentation.

#### Comparison Template

Use this structured comparison to ensure nothing is missed:

```markdown
# Documentation Critique: ${AGENT_NAME}_Agent.md

## Section-by-Section Comparison

### 1. Overview / Purpose
- [ ] Doc description matches actual behavior?
- [ ] Scope statement accurate (not too broad, not too narrow)?
- Finding: [MATCH | DRIFT | MISSING]
- Details: ...

### 2. Classes & Methods
| Class | In Code? | In Doc? | Status | Notes |
|-------|----------|---------|--------|-------|
| ClassName | Yes | Yes | MATCH | |
| OldClass | No | Yes | STALE | Deleted in commit abc123 |
| NewClass | Yes | No | MISSING | Added but not documented |

### 3. Method Signatures
| Method | Code Signature | Doc Signature | Status |
|--------|---------------|---------------|--------|
| process() | process(data: pd.DataFrame, strict: bool = True) -> Result | process(data) -> dict | DRIFT |

### 4. Data Flow Diagrams
- [ ] Mermaid diagram matches actual component interactions?
- [ ] All nodes in diagram exist in code?
- [ ] No orphaned nodes (in diagram but not in code)?
- Finding: [MATCH | DRIFT | MISSING]

### 5. Dependencies
| Dependency | In Code? | In Doc? | Status |
|------------|----------|---------|--------|
| pandas | Yes | Yes | MATCH |
| numpy | Yes | No | MISSING |
| scipy | No | Yes | STALE |

### 6. Usage Examples
- [ ] Code examples use current API signatures?
- [ ] Import paths correct?
- [ ] Example output matches actual behavior?
- Finding: [MATCH | DRIFT | MISSING]

### 7. Configuration / Constants
- [ ] Config values documented match code defaults?
- [ ] Environment variables listed are current?

## Summary of Findings

| Category | Count | Details |
|----------|-------|---------|
| Matches | N | Sections that are accurate |
| Drifted | N | Sections that need updating |
| Missing | N | Code elements not documented |
| Stale | N | Doc elements with no code counterpart |

## Recommended Updates (Priority Order)
1. [Highest impact change]
2. [Next change]
3. ...
```

**Document findings clearly** -- these feed directly into Step 4.

---

### Step 4: Update Documentation (Doc Writer)

> **Skip if** no discrepancies found in Step 3.

#### 4.1: Formulate Update Instructions

Before invoking the doc_writer, compose a precise instruction set from the critique findings:

```
UPDATE INSTRUCTIONS for ${AGENT_NAME}_Agent.md:

1. [Section]: [Specific change] — e.g., "Overview: Replace 'handles CSV parsing' with 'handles CSV and Parquet parsing via UnifiedLoader'"
2. [Section]: [Specific change] — e.g., "Classes: Add NewProcessor class with methods: run(), validate(), report()"
3. [Section]: [Specific change] — e.g., "Data Flow: Update Mermaid diagram to add NewProcessor between Loader and Writer"
4. [Section]: [Specific change] — e.g., "Dependencies: Remove scipy, add polars"
```

#### 4.2: Apply Updates

Use the **doc_writer** sub-agent tool with these parameters:
- task: "Update the documentation to reflect these specific changes: [PASTE UPDATE INSTRUCTIONS FROM 4.1]. Preserve existing section ordering. Do not remove accurate content. For each change, ensure surrounding context remains coherent."
- target_file: `coding_agent_context/docs/${AGENT_NAME}_Agent.md`
- read_files: `coding_agent_context/specs/doc_updates/${AGENT_NAME}_analysis.md`
- output_file: `coding_agent_context/specs/doc_updates/${AGENT_NAME}_doc_session.md`

#### 4.3: Verify the Update

```bash
# Read session log to confirm what was changed
cat coding_agent_context/specs/doc_updates/${AGENT_NAME}_doc_session.md

# Read the updated doc to verify correctness
cat coding_agent_context/docs/${AGENT_NAME}_Agent.md
```

**Post-update verification checklist:**

| Check | How |
|-------|-----|
| No broken Mermaid | Visually scan diagram syntax for unclosed brackets |
| No orphaned references | Grep for class/method names mentioned in doc but not in code |
| Consistent formatting | Compare section structure with other Agent docs |
| Links valid | Check any file path references with `ls` |

---

### Step 5: Move to Next Agent

```bash
# Log completion for this agent
echo "| $(date -Iseconds) | ${AGENT_NAME} | COMPLETE | [SUMMARY_OF_CHANGES] |" >> \
    coding_agent_context/specs/doc_updates/session_log.md

# Update memory with source-code mapping
# (see Memory Persistence section)

# Process next agent in the list
```

**Cleanup policy:** Keep analysis and session files until the entire mission is complete.
They serve as an audit trail and enable cross-agent consistency checks. Clean up only
after all agents have been processed and EXIT CRITERIA are met.

```bash
# Optional: Clean up after ALL agents processed (not between agents)
rm -f coding_agent_context/specs/doc_updates/*_analysis.md
rm -f coding_agent_context/specs/doc_updates/*_doc_session.md
```

---

## ERROR HANDLING

### Source Code Not Found

**Trigger:** Step 1 cannot locate any source files referenced by the Agent doc.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Source files referenced in doc do not exist on disk                          │
├─────────────────────────────────────────────────────────────────────────────┤
│ 1. Check if files were renamed:                                             │
│    git log --diff-filter=R --summary -- src/ | grep <old_filename>          │
│ 2. Check if files were deleted:                                             │
│    git log --diff-filter=D --summary -- src/ | grep <old_filename>          │
│ 3. Search for class/function names in current codebase:                     │
│    grep -r "class ClassName" src/ dags/ scripts/                            │
├─────────────────────────────────────────────────────────────────────────────┤
│ OUTCOME A: Files renamed → Update doc with new paths, continue loop         │
│ OUTCOME B: Files deleted → Mark doc as STALE in session log, flag for       │
│            human review (do not delete the doc autonomously)                 │
│ OUTCOME C: Code moved to different module → Update doc references           │
│ OUTCOME D: Cannot resolve → Skip agent, log in session_log.md              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Documentation References Deleted Code

**Trigger:** Step 3 finds classes/methods in the doc that no longer exist in code.

| Situation | Action |
|-----------|--------|
| Class deleted entirely | Remove from doc; add note in "Change History" if doc has one |
| Method removed from class | Remove from method list; check if replacement method exists |
| Module split into multiple files | Update doc to reflect new structure; may need to split Agent doc |
| Module merged into another | Consider merging Agent docs or redirecting |

### Analyst Sub-Agent Returns Incomplete Analysis

**Trigger:** Analysis output is missing sections or truncated.

1. Check if source files exceed the 4-file-per-turn limit
2. Re-run analyst on a subset of files
3. Combine partial analyses manually before proceeding to Step 3

### Doc Writer Produces Malformed Output

**Trigger:** Updated doc has broken Mermaid, missing sections, or formatting issues.

1. Read the doc_writer session log to understand what happened
2. Re-invoke doc_writer with more specific instructions
3. If repeated failure, apply the update manually via direct file editing

### INDEX_Agent.md Needs Updating

**Trigger:** After updating individual Agent docs, the INDEX may reference stale information.

- After processing ALL agents, re-read INDEX_Agent.md
- Compare its agent list and descriptions against the updated docs
- If discrepancies exist, update INDEX as the final step before exit

---

## OUTPUT FORMAT SPECIFICATION

### Session Artifacts

All artifacts are written to `coding_agent_context/specs/doc_updates/`:

| Artifact | Filename Pattern | Purpose |
|----------|-----------------|---------|
| Analysis report | `${AGENT_NAME}_analysis.md` | Raw analyst output for each agent |
| Critique report | `${AGENT_NAME}_critique.md` | Structured comparison (Step 3 template) |
| Doc writer session | `${AGENT_NAME}_doc_session.md` | Log of what the doc_writer changed |
| Session log | `session_log.md` | Running log of all agents processed |
| Memory file | `memory.md` | Persistent cross-session knowledge |

### Session Log Format

```markdown
# Documentation Update Session Log

> **Started:** [DATE]
> **Scope:** [DOC_SCOPE value]

| Timestamp | Agent | Status | Changes Summary |
|-----------|-------|--------|-----------------|
| 2024-01-15T10:30:00 | Spark | COMPLETE | Updated 3 method signatures, added BatchProcessor class |
| 2024-01-15T10:45:00 | API | SKIPPED | Source files not found (deleted in v2.0) |
| 2024-01-15T11:00:00 | Auth | COMPLETE | No changes needed (docs accurate) |
```

---

## LOOP SUMMARY

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ INITIALIZATION (RUN ONCE PER SESSION):                                      │
│   Load INDEX_Agent.md → Load memory.md → List Agent docs → Determine scope  │
├─────────────────────────────────────────────────────────────────────────────┤
│ FOR EACH *_Agent.md FILE IN SCOPE:                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│ 1. IDENTIFY:  Find source code paths from doc                               │
│               ├─ Paths found     → Continue to step 2                       │
│               ├─ Paths renamed   → Update paths, continue to step 2         │
│               ├─ Paths deleted   → Log as STALE, flag for review, skip      │
│               └─ Cannot resolve  → Log, skip to next agent                  │
│                                                                             │
│ 2. ANALYZE:   analyst sub-agent on source files                             │
│               → Output: ${AGENT_NAME}_analysis.md                           │
│               ├─ Analysis complete → Continue to step 3                     │
│               └─ Analysis partial  → Re-run on file subsets, combine        │
│                                                                             │
│ 3. CRITIQUE:  Compare analysis vs documentation using template              │
│               → Output: ${AGENT_NAME}_critique.md                           │
│               ├─ Discrepancies found → Continue to step 4                   │
│               └─ No discrepancies    → Log "accurate", skip to step 5       │
│                                                                             │
│ 4. UPDATE:    doc_writer sub-agent with specific update instructions        │
│               → Output: ${AGENT_NAME}_doc_session.md                        │
│               → Verify updated doc with cat                                 │
│                                                                             │
│ 5. NEXT:      Log completion → Update memory → Process next agent           │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ FINALIZATION:                                                               │
│   Update INDEX_Agent.md if needed → Finalize memory.md → Clean up artifacts │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Decision Tree Diagram

```
                        START
                          │
                          ▼
                  ┌───────────────┐
                  │ Load INDEX &  │
                  │ memory.md     │
                  └───────┬───────┘
                          │
                          ▼
                  ┌───────────────┐
                  │ List agents   │
                  │ in scope      │
                  └───────┬───────┘
                          │
                  ┌───────▼───────┐
              ┌───│ More agents?  │───┐
              │   └───────────────┘   │
             YES                      NO
              │                       │
              ▼                       ▼
      ┌───────────────┐       ┌───────────────┐
      │ IDENTIFY      │       │ Update INDEX  │
      │ source files  │       │ Finalize mem  │
      └───────┬───────┘       │ Clean up      │
              │               └───────┬───────┘
        ┌─────┴─────┐                │
        │           │                ▼
      FOUND     NOT FOUND          DONE
        │           │
        ▼           ▼
   ┌─────────┐  ┌─────────┐
   │ ANALYZE │  │ Log &   │
   │ source  │  │ skip    │──────┐
   └────┬────┘  └─────────┘      │
        │                        │
        ▼                        │
   ┌─────────┐                   │
   │ CRITIQUE│                   │
   │ compare │                   │
   └────┬────┘                   │
        │                        │
   ┌────┴────┐                   │
   │         │                   │
 DRIFT    ACCURATE               │
   │         │                   │
   ▼         ▼                   │
┌──────┐  ┌──────┐              │
│UPDATE│  │ Log  │              │
│ doc  │  │ skip │              │
└──┬───┘  └──┬───┘              │
   │         │                   │
   └────┬────┘                   │
        │                        │
        ▼                        │
   ┌─────────┐                   │
   │ NEXT    │◄──────────────────┘
   │ agent   │
   └────┬────┘
        │
        └──────────► (back to "More agents?")
```

---

## EXIT CRITERIA

| Criterion | Validation |
|-----------|------------|
| All agents in scope processed | Each `*_Agent.md` in scope reviewed and logged in session_log.md |
| Docs accurate | Documentation matches current code for all processed agents |
| No drift | Class names, methods, data flows, dependencies all correct |
| INDEX consistent | INDEX_Agent.md reflects any changes made to individual Agent docs |
| Memory updated | Source code mappings and session log recorded in memory.md |
| Session log complete | Every agent has an entry with status and change summary |

---

## EXAMPLE WALKTHROUGH

### Scenario 1: Standard Update (Drift Detected)

```bash
# 1. Initialize
ls coding_agent_context/docs/*_Agent.md
# Output: Spark_Agent.md, API_Agent.md, Auth_Agent.md

# 2. Process Spark_Agent — IDENTIFY
cat coding_agent_context/docs/Spark_Agent.md | head -50
# Found references: src/spark_utils.py, src/spark_processor.py

# Verify paths exist
ls src/spark_utils.py src/spark_processor.py
# Both exist
```

3. ANALYZE using the **analyst** sub-agent tool:
   - focus: "Analyze for documentation comparison. Provide all public classes, methods, data flow, dependencies."
   - read_files: `src/spark_utils.py,src/spark_processor.py`
   - output_file: `coding_agent_context/specs/doc_updates/Spark_analysis.md`

```bash
cat coding_agent_context/specs/doc_updates/Spark_analysis.md
```

4. CRITIQUE — Compare analysis against doc:

```markdown
# Critique: Spark_Agent.md

## Classes & Methods
| Class | In Code? | In Doc? | Status |
|-------|----------|---------|--------|
| SparkProcessor | Yes | Yes | MATCH |
| SparkBatchProcessor | Yes | No | MISSING |
| SparkStreamProcessor | No | Yes | STALE |

## Summary: 1 MISSING class, 1 STALE class, 2 drifted method signatures
```

5. UPDATE using the **doc_writer** sub-agent tool:
   - task: "Apply these updates: 1. Add SparkBatchProcessor class with methods run_batch(), get_status(). 2. Remove SparkStreamProcessor (deleted from codebase). 3. Update SparkProcessor.process() signature from process(data) to process(data: pd.DataFrame, mode: str = 'default') -> BatchResult"
   - target_file: `coding_agent_context/docs/Spark_Agent.md`
   - read_files: `coding_agent_context/specs/doc_updates/Spark_analysis.md`
   - output_file: `coding_agent_context/specs/doc_updates/Spark_doc_session.md`

```bash
# Verify update
cat coding_agent_context/specs/doc_updates/Spark_doc_session.md
cat coding_agent_context/docs/Spark_Agent.md
```

6. Log and move to next:

```bash
echo "| $(date -Iseconds) | Spark | COMPLETE | Added SparkBatchProcessor, removed SparkStreamProcessor, updated 2 signatures |" >> \
    coding_agent_context/specs/doc_updates/session_log.md

# Move to API_Agent...
```

### Scenario 2: Source Code Deleted

```bash
# Process API_Agent — IDENTIFY
cat coding_agent_context/docs/API_Agent.md | head -50
# Found reference: src/api_gateway.py

ls src/api_gateway.py
# ls: cannot access 'src/api_gateway.py': No such file or directory

# Check if renamed
git log --diff-filter=R --summary -- src/ | grep api_gateway
# No results

# Check if deleted
git log --diff-filter=D --summary -- src/ | grep api_gateway
# delete mode 100644 src/api_gateway.py  (commit def456)

# Search for the class name
grep -r "class APIGateway" src/ dags/ scripts/
# No results — code is truly gone
```

**Action:** Log as STALE, flag for human review.

```bash
echo "| $(date -Iseconds) | API | STALE | Source file src/api_gateway.py deleted in commit def456. Agent doc may need removal. Flagged for human review. |" >> \
    coding_agent_context/specs/doc_updates/session_log.md
```

### Scenario 3: No Changes Needed

```bash
# Process Auth_Agent — IDENTIFY, ANALYZE, CRITIQUE
# Critique result: all sections match, no drift detected

echo "| $(date -Iseconds) | Auth | ACCURATE | No changes needed — docs match code |" >> \
    coding_agent_context/specs/doc_updates/session_log.md

# Skip UPDATE step, proceed to next agent
```

### Scenario 4: Behavior Verification via Docker

When documentation claims a method returns a specific type but the code is ambiguous
(e.g., type hints are missing):

```bash
# Verify actual behavior inside Docker
./coding_agent_context/tools/dev_container.sh --action exec \
    --cmd "python -c \"from src.processor import Processor; p = Processor(); print(type(p.run([])))\""
# Output: <class 'src.result.BatchResult'>

# Now update the doc to reflect the verified return type
```

---

## MEMORY PERSISTENCE

### When to Update Memory

| Event | Memory Update Action |
|-------|---------------------|
| Source files identified for an agent | Add to `Source Code Mapping` table |
| Cross-agent dependency discovered | Add to `Cross-Agent Relationships` table |
| Known gap found but deferred | Add to `Known Documentation Gaps` table |
| Naming pattern discovered | Add to `Naming Conventions Discovered` table |
| Session completes | Add entry to `Session Log` table |

### How to Update Memory

Use the **doc_writer** sub-agent tool with these parameters:
- task: "Update the documentation memory file with these findings: [LIST_OF_UPDATES]. Update the 'Last Updated' timestamp."
- target_file: `coding_agent_context/specs/doc_updates/memory.md`
- read_files: (none)
- output_file: `coding_agent_context/specs/doc_updates/memory_update_session.md`

### Memory on Session Resume

When starting a new session that continues a prior doc-update effort:

1. Load `memory.md` to recover source-code mappings and known gaps
2. Load `session_log.md` to see which agents were already processed
3. Resume from the first unprocessed agent in scope

---

## FINALIZATION

### Update INDEX_Agent.md

After all agents in scope have been processed, check whether INDEX needs updating:

```bash
# Re-read the INDEX
cat coding_agent_context/docs/INDEX_Agent.md

# Compare against session log for any structural changes
cat coding_agent_context/specs/doc_updates/session_log.md
```

If any Agent docs had structural changes (new classes, removed components), update
INDEX_Agent.md using the **doc_writer** sub-agent tool.

### Finalize Memory

```bash
# Update memory with final session summary
# Add all source-code mappings discovered
# Record session completion
```

### Verify Final State

```bash
# List all Agent docs and confirm they exist
ls -la coding_agent_context/docs/*_Agent.md

# Spot-check a few updated docs
cat coding_agent_context/docs/${FIRST_UPDATED_AGENT}_Agent.md | head -30

# Review session log for completeness
cat coding_agent_context/specs/doc_updates/session_log.md
```

---

## RESUMPTION QUICK REFERENCE

| Scenario | Action |
|----------|--------|
| Fresh start (no session_log.md) | Run full initialization, process all agents in scope |
| Resume (session_log.md exists) | Load memory.md, read session_log.md, find first unprocessed agent |
| Single agent update | Set `DOC_SCOPE=<AgentName>`, run loop once |
| Post-code-change update | Set `DOC_SCOPE=changed`, auto-detect affected agents |
| INDEX needs refresh only | Skip agent loop, go directly to Finalization |
