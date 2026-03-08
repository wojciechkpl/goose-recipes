# MISSION: Code Review Analysis

> **Type:** Code Review | **Scope:** CR Change Analysis with Critique

---

## OBJECTIVE

Conduct a comprehensive code review of changes between a target branch (baseline) and a 
code change branch. Generate documentation updates, diff analysis, and a detailed review 
document with critical and nit-pick comments.

**Prerequisites:**
- This mission is executed from within a code review workspace created by `setup_cr.sh`
- Current working directory: `<workspace>/codeChange/<cloned-repo>/`
- Target branch available at: `../../target/`
- The `coding_agent_context` folder has been copied to this location

---

## CONTEXT DETECTION

### Step 0: Determine Focus Path

The review should focus ONLY on the subfolder containing the `coding_agent_context` directory.

```bash
# Find the relative path to coding_agent_context from repo root
FOCUS_PATH=$(dirname "$(find . -type d -name "coding_agent_context" -not -path "*/.git/*" | head -1)" | sed 's|^\./||')
echo "Focus path: $FOCUS_PATH"

# Verify target exists
ls -la "../../target/${FOCUS_PATH}" 2>/dev/null || echo "WARNING: Target path may not exist"
```

**Store this path** - it will be used throughout the mission as `${FOCUS_PATH}`.

---

## SAFETY CONSTRAINTS

| Constraint | Rule |
|------------|------|
| File limit | Process max 4 files per tool invocation |
| Focus scope | Only analyze files within `${FOCUS_PATH}` |
| Excluded | `coding_agent_context/` and `cr_review/` are auto-excluded from diffs |
| Output files | Write all outputs to `cr_review/` subdirectory |
| Preserve target | Do NOT modify files in `../../target/` |

> **Note:** The `coding_agent_context/` folder is automatically excluded from diff analysis
> because it is copied from the setup process and is not part of the actual code change.

---

## INITIALIZATION

### Create Output Directory

```bash
# Create directory for review artifacts
mkdir -p cr_review
```

---

## PHASE 1: DOCUMENTATION UPDATE

> **Goal:** Ensure `*_Agent.md` documentation is current with the code change branch.

This phase follows the same workflow as the `update_docs.md` mission, applied to the 
code change branch.

### Step 1.1: List Agent Documentation

```bash
# Find all agent documentation files
ls coding_agent_context/docs/*_Agent.md 2>/dev/null || echo "No agent docs found"
```

### Step 1.2: Update Loop (For Each Agent Doc)

For each `*_Agent.md` file found:

```bash
# Set agent name (e.g., "API", "Spark", "Auth")
AGENT_NAME="<agent_name>"

# 1. Read the doc to find source file references
cat coding_agent_context/docs/${AGENT_NAME}_Agent.md | head -50
```

2. Analyze source code using the **analyst** sub-agent tool with these parameters:
   - focus: "Summarize responsibilities, key classes, public methods, and data flow"
   - read_files: `<source_files_from_doc>`
   - output_file: `cr_review/${AGENT_NAME}_analysis.md`

```bash
# 3. Read analysis
cat cr_review/${AGENT_NAME}_analysis.md
```

4. Compare analysis vs documentation and update if needed.
   If discrepancies found, use the **doc_writer** sub-agent tool with these parameters:
   - task: "Update documentation to reflect: <list_discrepancies>"
   - target_file: `coding_agent_context/docs/${AGENT_NAME}_Agent.md`
   - read_files: `cr_review/${AGENT_NAME}_analysis.md`
   - output_file: `cr_review/${AGENT_NAME}_doc_update.md`

**Skip to Phase 2** once all agent docs have been processed.

---

## PHASE 2: DIFF ANALYSIS

> **Goal:** Generate a comprehensive diff report between target and change branches.

### Step 2.1: Run Diff Analyzer

```bash
# Get tool usage
./coding_agent_context/tools/diff_analyzer.sh --help

# Generate diff report (focus only on relevant subpath)
./coding_agent_context/tools/diff_analyzer.sh \
    -o cr_review/diff_report.md \
    -t "../../target" \
    -c "." \
    -f "${FOCUS_PATH}"

# Review the diff report
cat cr_review/diff_report.md
```

### Step 2.2: Verify Diff Coverage

Check that the diff report captured all relevant changes:

```bash
# Quick sanity check - compare file counts
echo "=== Target files ==="
find "../../target/${FOCUS_PATH}" -type f -name "*.py" -o -name "*.sh" -o -name "*.md" 2>/dev/null | wc -l

echo "=== Change files ==="
find "./${FOCUS_PATH}" -type f -name "*.py" -o -name "*.sh" -o -name "*.md" 2>/dev/null | wc -l
```

---

## PHASE 3: CODE REVIEW GENERATION

> **Goal:** Generate comprehensive review document with critique sections.

### Step 3.1: Gather Context

Before generating the review, collect relevant context:

```bash
# List available documentation for context
ls coding_agent_context/docs/*.md

# Identify key docs to include as context
# (Pick most relevant 2-3 docs based on what the changes affect)
```

### Step 3.2: Generate Review Document

Use the **code_reviewer** sub-agent tool with these parameters:
- focus: "Conduct a comprehensive code review of the changes described in the diff report. Follow the output structure in your role definition."
- read_files: `cr_review/diff_report.md,coding_agent_context/docs/INDEX_Agent.md`
- output_file: `cr_review/CODE_REVIEW.md`

```bash
# Read the generated review
cat cr_review/CODE_REVIEW.md
```

### Step 3.3: Enhance Review (Manual Refinement)

Review the generated document and enhance if needed:

1. **Verify code references** - Ensure file paths and line numbers are accurate
2. **Add missing context** - Include any domain-specific insights
3. **Prioritize issues** - Reorder critical issues by severity
4. **Cross-reference** - Link related issues together

```bash
# If updates needed, edit directly or regenerate specific sections
cat cr_review/CODE_REVIEW.md
```

---

## PHASE 4: FINAL ASSEMBLY

> **Goal:** Create the final review package.

### Step 4.1: Create Review Summary

```bash
# Create a summary file pointing to all artifacts
cat > cr_review/REVIEW_SUMMARY.md << 'SUMMARY'
# Code Review Summary

## Review Artifacts

| Artifact | Description |
|----------|-------------|
| [CODE_REVIEW.md](./CODE_REVIEW.md) | Main review document with critique |
| [diff_report.md](./diff_report.md) | Detailed diff analysis |
| [*_analysis.md](.) | Individual component analyses |

## Quick Links

- **Critical Issues:** See CODE_REVIEW.md § "Critical Issues"
- **Nit-picks:** See CODE_REVIEW.md § "Nit-picks"
- **Change Summary:** See diff_report.md § "Summary Statistics"

## Reviewer Instructions

1. Start with CODE_REVIEW.md Executive Summary
2. Review Critical Issues first
3. Walk through Change Description sequentially
4. Address Nit-picks as time permits

SUMMARY

echo "Review package created in: cr_review/"
```

### Step 4.2: Verify Package Completeness

```bash
# List all generated artifacts
ls -la cr_review/

# Verify main review document exists and has content
wc -l cr_review/CODE_REVIEW.md
```

---

## EXECUTION FLOW DIAGRAM

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CODE REVIEW MISSION                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐                                                            │
│  │   PHASE 0   │  Detect focus path (where coding_agent_context lives)     │
│  └──────┬──────┘                                                            │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────┐                                                            │
│  │   PHASE 1   │  Update *_Agent.md documentation                          │
│  │             │  (analyst → compare → doc_writer sub-agents)              │
│  └──────┬──────┘                                                            │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────┐                                                            │
│  │   PHASE 2   │  Generate diff report                                     │
│  │             │  (diff_analyzer.sh)                                       │
│  └──────┬──────┘                                                            │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────┐                                                            │
│  │   PHASE 3   │  Generate review document                                 │
│  │             │  (code_reviewer sub-agent → manual refinement)            │
│  └──────┬──────┘                                                            │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────┐                                                            │
│  │   PHASE 4   │  Assemble final review package                            │
│  │             │  (cr_review/ directory)                                   │
│  └─────────────┘                                                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## EXIT CRITERIA

| Criterion | Validation |
|-----------|------------|
| Docs updated | All `*_Agent.md` files reflect current code |
| Diff generated | `cr_review/diff_report.md` exists with content |
| Review complete | `cr_review/CODE_REVIEW.md` has all sections |
| Critical issues listed | Section 5 present (even if "none found") |
| Nit-picks listed | Section 6 present (even if empty) |
| Package assembled | `cr_review/REVIEW_SUMMARY.md` exists |

---

## TROUBLESHOOTING

### Issue: Focus path not found

```bash
# If coding_agent_context not found, check directory structure
find . -type d -name "coding_agent_context" 2>/dev/null
pwd
ls -la
```

### Issue: Target directory structure differs

```bash
# Compare directory structures
ls -la "../../target/"
ls -la "."

# May need to adjust FOCUS_PATH based on actual structure
```

### Issue: Diff report is empty

```bash
# Verify paths exist
ls -la "../../target/${FOCUS_PATH}" 
ls -la "./${FOCUS_PATH}"

# Check for hidden files or permission issues
find "../../target/${FOCUS_PATH}" -type f | head -10
```

### Issue: Review generation fails

```bash
# Verify diff report has content
cat cr_review/diff_report.md | head -50
```

---

## EXAMPLE EXECUTION

```bash
# === PHASE 0: Detect Focus Path ===
FOCUS_PATH=$(dirname "$(find . -type d -name "coding_agent_context" | head -1)" | sed 's|^\./||')
echo "Focus: $FOCUS_PATH"  # e.g., "prototype/evaluation"

# === PHASE 1: Update Docs (example for one agent) ===
mkdir -p cr_review
ls coding_agent_context/docs/*_Agent.md
# Found: API_Agent.md

cat coding_agent_context/docs/API_Agent.md | head -50
# Found source: src/api/routes.py, src/api/handlers.py

Use the **analyst** sub-agent tool with these parameters:
- focus: "Summarize API responsibilities and endpoints"
- read_files: `src/api/routes.py,src/api/handlers.py`
- output_file: `cr_review/API_analysis.md`

cat cr_review/API_analysis.md
# Compare with doc, update if needed...

# === PHASE 2: Generate Diff Report ===
./coding_agent_context/tools/diff_analyzer.sh \
    -o cr_review/diff_report.md \
    -t "../../target" \
    -c "." \
    -f "$FOCUS_PATH"

cat cr_review/diff_report.md

# === PHASE 3: Generate Review ===

Use the **code_reviewer** sub-agent tool with these parameters:
- diff_file: `cr_review/diff_report.md`
- read_files: `coding_agent_context/docs/API_Agent.md`
- output_file: `cr_review/CODE_REVIEW.md`

cat cr_review/CODE_REVIEW.md

# === PHASE 4: Finalize ===
ls -la cr_review/
# Done! Review package ready at cr_review/
```
