# MISSION: Generate Agent Documentation from Scratch

> **Type:** Documentation Generation | **Scope:** Full Codebase | **Phases:** Analyze → Plan → Execute

---

## OBJECTIVE

Generate comprehensive `*_Agent.md` documentation files for the entire codebase, starting from scratch.

**Output Location:** `coding_agent_context/docs/`

**Master Index:** `coding_agent_context/docs/INDEX_Agent.md` (always created)

---

## OVERVIEW

This mission has **two phases** that run sequentially:

```
┌─────────────────────────────────────────────────────────────┐
│ PHASE 1: ANALYZE & PLAN                                     │
│ ─────────────────────────────────────────────────────────── │
│ • Analyze codebase structure                                │
│ • Determine appropriate Agent granularity                   │
│ • Create documentation plan                                 │
│ Output: coding_agent_context/specs/doc_generation/plan.md   │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ PHASE 2: EXECUTE PLAN                                       │
│ ─────────────────────────────────────────────────────────── │
│ • Create each *_Agent.md file                               │
│ • Create INDEX_Agent.md master index                        │
│ Output: coding_agent_context/docs/*_Agent.md                │
└─────────────────────────────────────────────────────────────┘
```

---

## PHASE 1: ANALYZE & PLAN

### Step 1.1: Explore Codebase Structure

**Goal:** Understand the overall structure and identify logical components.

```bash
# List top-level structure
ls -la src/
ls -la dags/
ls -la scripts/

# Find all Python files
find src/ -name "*.py" -type f | head -50
find dags/ -name "*.py" -type f | head -50
find scripts/ -name "*.py" -type f | head -50

# Identify modules/packages
ls -la src/*/
ls -la dags/*/
ls -la scripts/*/

# Count lines per file to identify major components
find src/ -name "*.py" -exec wc -l {} \; | sort -rn | head -20
find dags/ -name "*.py" -exec wc -l {} \; | sort -rn | head -20
find scripts/ -name "*.py" -exec wc -l {} \; | sort -rn | head -20
```

---

### Step 1.2: Deep Analysis of Components (Analyst)

**Goal:** Understand responsibilities of each major component.

Use the **analyst** sub-agent tool with these parameters:
- focus: "Analyze the codebase structure. Identify: 1) Major modules/packages, 2) Key classes and their responsibilities, 3) Data flow between components, 4) External interfaces (APIs, databases, etc.), 5) Logical groupings that could each have their own documentation."
- read_files: `src/__init__.py,src/main.py`
- output_file: `coding_agent_context/specs/doc_generation/codebase_analysis.md`

```bash
cat coding_agent_context/specs/doc_generation/codebase_analysis.md
```

**For large codebases, analyze in chunks:**

Use the **analyst** sub-agent tool multiple times:

First chunk:
- focus: "Analyze this module: responsibilities, key classes, public interfaces"
- read_files: `src/module1/*.py`
- output_file: `coding_agent_context/specs/doc_generation/module1_analysis.md`

```bash
cat coding_agent_context/specs/doc_generation/module1_analysis.md
```

Second chunk:
- focus: "Analyze this module: responsibilities, key classes, public interfaces"
- read_files: `src/module2/*.py`
- output_file: `coding_agent_context/specs/doc_generation/module2_analysis.md`

```bash
cat coding_agent_context/specs/doc_generation/module2_analysis.md

# Continue for other modules...
```

---

### Step 1.3: Determine Agent Granularity (Architect)

**Goal:** Decide how to split documentation into logical Agent files.

**Granularity Guidelines:**

| Codebase Size | Recommended Approach |
|---------------|---------------------|
| Small (<10 files) | 1-2 Agent files + INDEX |
| Medium (10-50 files) | 3-7 Agent files by module + INDEX |
| Large (50+ files) | Agent per major subsystem + INDEX |

**Considerations:**
- Each Agent should cover a **cohesive domain** (e.g., "Data Processing", "API Layer", "Authentication")
- Avoid too fine-grained (1 Agent per file) or too coarse (1 Agent for everything)
- Each Agent doc should be **readable in isolation** but reference others

---

### Step 1.4: Create Documentation Plan (Architect)

**Goal:** Create a detailed plan for which Agent files to generate.

```bash
# Create specs directory for this mission
mkdir -p coding_agent_context/specs/doc_generation
```

Use the **architect** sub-agent tool with these parameters:
- task: "Create a documentation generation plan. Based on the codebase analysis, define: 1. List of *_Agent.md files to create (with naming convention), 2. For each Agent file: scope, source files covered, key sections to include, 3. INDEX_Agent.md structure (master index), 4. Order of creation (dependencies first). Format as a checklist with [ ] for each file to create. Include the specific source files each Agent should document."
- target_file: `coding_agent_context/specs/doc_generation/plan.md`
- read_files: `coding_agent_context/specs/doc_generation/codebase_analysis.md`
- output_file: `coding_agent_context/specs/doc_generation/doc_plan_session.md`

```bash
# Read the session log
cat coding_agent_context/specs/doc_generation/doc_plan_session.md

# Read the generated plan
cat coding_agent_context/specs/doc_generation/plan.md
```

**Expected Plan Format:**

```markdown
# Documentation Generation Plan

## Agent Files to Create

### 1. Core Agents
- [ ] `DataProcessing_Agent.md` - Covers: src/processing/*.py
- [ ] `API_Agent.md` - Covers: src/api/*.py
- [ ] `Storage_Agent.md` - Covers: src/storage/*.py

### 2. Supporting Agents
- [ ] `Utils_Agent.md` - Covers: src/utils/*.py
- [ ] `Config_Agent.md` - Covers: src/config/*.py

### 3. Master Index
- [ ] `INDEX_Agent.md` - Links to all agents, provides overview

## Creation Order
1. Config_Agent.md (no dependencies)
2. Utils_Agent.md (no dependencies)
3. Storage_Agent.md (depends on Config)
4. DataProcessing_Agent.md (depends on Storage, Utils)
5. API_Agent.md (depends on DataProcessing)
6. INDEX_Agent.md (created last, links all)

## Per-Agent Template
Each Agent file should include:
- Overview & Purpose
- Key Classes/Functions
- Data Flow Diagram (Mermaid)
- Dependencies
- Usage Examples
```

---

### Phase 1 Exit Criteria

| Criterion | Validation |
|-----------|------------|
| Analysis complete | `codebase_analysis.md` exists with component breakdown |
| Plan created | `coding_agent_context/specs/doc_generation/plan.md` exists |
| Plan is actionable | Each Agent file has defined scope and source files |
| INDEX planned | Master index structure defined |

---

## PHASE 2: EXECUTE PLAN

> **Prerequisite:** Phase 1 complete with `plan.md` generated

### Step 2.1: Read the Plan

```bash
cat coding_agent_context/specs/doc_generation/plan.md
```

Extract:
- List of Agent files to create
- Creation order
- Source files for each Agent

---

### Step 2.2: Create Agent Files (Loop)

> **Repeat for each unchecked `[ ]` Agent in the plan (except INDEX)**

#### 2.2.1: Analyze Source Files for This Agent

Use the **analyst** sub-agent tool with these parameters:
- focus: "Provide detailed analysis for documentation: 1. Purpose and responsibilities, 2. Key classes with their methods, 3. Data flow and dependencies, 4. Public interfaces, 5. Usage patterns"
- read_files: `src/${SOURCE_FILES}`
- output_file: `coding_agent_context/specs/doc_generation/${AGENT_NAME}_analysis.md`

```bash
cat coding_agent_context/specs/doc_generation/${AGENT_NAME}_analysis.md
```

#### 2.2.2: Generate Agent Documentation

Use the **doc_writer** sub-agent tool with these parameters:
- task: "Create comprehensive Agent documentation including: Overview section with purpose, Architecture diagram (Mermaid), Key Classes section with descriptions, Public API/Interfaces, Data Flow, Dependencies on other agents, Usage Examples"
- target_file: `coding_agent_context/docs/${AGENT_NAME}_Agent.md`
- read_files: `coding_agent_context/specs/doc_generation/${AGENT_NAME}_analysis.md`
- output_file: `coding_agent_context/specs/doc_generation/${AGENT_NAME}_doc_session.md`

```bash
cat coding_agent_context/specs/doc_generation/${AGENT_NAME}_doc_session.md
cat coding_agent_context/docs/${AGENT_NAME}_Agent.md
```

#### 2.2.3: Mark Complete in Plan

```bash
sed -i 's/\[ \] `'${AGENT_NAME}'_Agent.md`/[x] `'${AGENT_NAME}'_Agent.md`/' \
    coding_agent_context/specs/doc_generation/plan.md
```

---

### Step 2.3: Create Master Index (INDEX_Agent.md)

> **Execute after all other Agent files are created**

```bash
# List all created Agent files
ls coding_agent_context/docs/*_Agent.md
```

Use the **doc_writer** sub-agent tool with these parameters:
- task: "Create the master INDEX_Agent.md that: 1. Provides a high-level system overview, 2. Lists all Agent documentation files with brief descriptions, 3. Shows the relationship between agents (dependency diagram in Mermaid), 4. Provides navigation links to each Agent file, 5. Includes a 'Getting Started' section for new developers"
- target_file: `coding_agent_context/docs/INDEX_Agent.md`
- read_files: `coding_agent_context/docs/*_Agent.md`
- output_file: `coding_agent_context/specs/doc_generation/index_doc_session.md`

```bash
cat coding_agent_context/specs/doc_generation/index_doc_session.md
cat coding_agent_context/docs/INDEX_Agent.md
```

**Expected INDEX_Agent.md Structure:**

```markdown
# System Documentation Index

## Overview
Brief description of the entire system.

## Architecture Diagram
[Mermaid diagram showing agent relationships]

## Agent Documentation

| Agent | Description | Key Components |
|-------|-------------|----------------|
| [DataProcessing_Agent](DataProcessing_Agent.md) | Data pipeline | Processor, Transformer |
| [API_Agent](API_Agent.md) | REST API layer | Routes, Controllers |
| ...

## Getting Started
1. Start with INDEX_Agent.md (this file)
2. Read relevant Agent docs based on your task
3. ...

## Dependencies
[Mermaid diagram of agent dependencies]
```

---

### Step 2.4: Mark INDEX Complete

```bash
sed -i 's/\[ \] `INDEX_Agent.md`/[x] `INDEX_Agent.md`/' \
    coding_agent_context/specs/doc_generation/plan.md
```

---

## EXECUTION LOOP SUMMARY

```
┌─────────────────────────────────────────────────────────────┐
│ PHASE 1: ANALYZE & PLAN                                     │
├─────────────────────────────────────────────────────────────┤
│ 1. EXPLORE:   ls, find to understand structure              │
│ 2. ANALYZE:   analyst tool on major components              │
│ 3. PLAN:      architect tool to create plan.md              │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ PHASE 2: EXECUTE (for each Agent in plan)                   │
├─────────────────────────────────────────────────────────────┤
│ 1. ANALYZE:   analyst tool on Agent's source files          │
│ 2. WRITE:     doc_writer tool to create *_Agent.md          │
│ 3. TRACK:     Mark [x] in plan.md                           │
│ 4. REPEAT:    Until all Agents created                      │
│ 5. INDEX:     Create INDEX_Agent.md last                    │
└─────────────────────────────────────────────────────────────┘
```

---

## EXIT CRITERIA

| Criterion | Validation |
|-----------|------------|
| All Agents created | All items in plan.md marked `[x]` |
| INDEX exists | `coding_agent_context/docs/INDEX_Agent.md` created |
| INDEX complete | Links to all Agent files, has overview diagram |
| Docs consistent | All Agent files follow same structure |
| No orphans | Every source file covered by at least one Agent |

---

## QUICK START

```bash
# Run Phase 1: Analyze & Plan
# (Follow steps 1.1 through 1.4)

# Verify plan created
cat coding_agent_context/specs/doc_generation/plan.md

# Run Phase 2: Execute Plan
# (Follow steps 2.1 through 2.4, looping for each Agent)

# Verify completion
ls -la coding_agent_context/docs/*_Agent.md
cat coding_agent_context/docs/INDEX_Agent.md
```
