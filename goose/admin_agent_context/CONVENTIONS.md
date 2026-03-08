# Administrative Agent Context - Conventions

> **Purpose:** Agent framework for research workflows — compiling references and generating comprehensive reports from multiple sources.

---

## Base Paths

| Path | Purpose |
|------|---------|
| `./admin_agent_context/` | Framework root |
| `./admin_agent_context/specs/` | Mission inputs and outputs |
| `./admin_agent_context/missions/` | Step-by-step mission instructions |
| `./admin_agent_context/roles/` | Specialized agent personas |
| `./admin_agent_context/recipes/` | Machine-readable mission/role configs |
| `./admin_agent_context/user_guides/` | Documentation |

---

## Critical Constraints

### 1. Read Before Write
Always read and understand input files completely before processing them.

### 2. Preserve Original Content
When processing documents, always preserve the original content in a retrievable form (comments, backup sections, etc.).

### 3. No Hallucination
Only add information that can be directly derived from or linked to source materials. When summarizing or expanding, cite sources.

### 4. Maintain Format Integrity
Respect the format conventions of the input (Markdown, etc.) and produce output in the expected format.

### 5. File reading
Use the shell command `cat` and avoid `text_editor view` for bulk reads

---

## Role Boundaries

| Role | Can Do | Cannot Do |
|------|--------|-----------|
| **Research Assistant** | Follow links, extract context, summarize documents | Make claims without sources |
| **Reference Compiler** | Discover, catalog, score, and rank sources | Make relevance decisions beyond scoring |
| **Research Orchestrator** | Manage references, dispatch investigators, decide relevance, track progress | Investigate sources directly (must use sub-agents) |
| **Source Investigator** | Examine individual sources (first-pass or deep-dive) | Make relevance decisions, follow references beyond reporting them |
| **Report Writer** | Synthesize research into polished, audience-appropriate reports | Add unsourced claims, skip citations |

---

## File Conventions

### Spec Folders
```
specs/<mission_name>/
├── input/           # Original files to process
├── output/          # Processed results
└── memory.md        # Accumulated knowledge (if multi-session)
```

---

## Research Workflow

### Overview

The research workflow discovers sources and generates reports through a two-step process:

```
┌──────────────────────────┐       ┌──────────────────────────┐
│ compile_references        │──────▶│ research_report           │
│ → compiled_references.md  │       │ → final_report.md         │
│ → requirements_template.md│       │                           │
└──────────────────────────┘       └──────────────────────────┘
```

1. **Compile References** discovers and catalogs sources for a research topic
2. **Research Report** coordinates multi-source investigation and report generation

### Per-Research Workspace

```
specs/research/<topic>/
├── requirements.md         # User input (topic, audience, structure)
├── compiled_references.md  # From compile step
├── requirements_template.md# Generated template for research_report
├── progress/               # Checkpoints
│   ├── orchestrator_state.md
│   ├── reference_queue.md
│   ├── relevance_decisions.md
│   └── tasks/              # Task files for sub-agents
├── sources/                # Investigations
│   ├── first_pass/
│   └── deep_dive/
└── report/                 # Final output
    ├── writing_brief.md
    └── final_report.md
```

---

## Quick Reference

### Starting a Mission

```bash
export MISSION_PARAM="value"
mkdir -p ./admin_agent_context/specs/${MISSION_NAME}/

goose run --recipe ./admin_agent_context/recipes/mission_<name>.yaml \
  --params param=${MISSION_PARAM}
```

### Available Missions

| Mission | Recipe | Purpose |
|---------|--------|---------|
| Compile References | `mission_compile_references.yaml` | Discover and catalog research sources |
| Research Report | `mission_research_report.yaml` | Multi-source research and report generation |

---

## Sub-Agent Dispatch (Research Report)

### Sub-Recipe Tools

The research report mission registers sub-recipe tools for context-isolated sub-agent dispatch:

| Mission | Sub-Recipe Tools |
|---------|-----------------|
| `mission_research_report` | `source_investigator`, `report_writer` |

### How to Dispatch — Task-File Indirection Protocol

**CRITICAL**: Never pass task descriptions as inline string parameters to sub-agents.
Instead, always use **task-file indirection**: write the task to a file first, then pass
the file path.

**Step 1 — Write the task file:**

```bash
mkdir -p ${RUN_DIR}/progress/tasks
cat > ${RUN_DIR}/progress/tasks/<task_name>.md << 'TASK_EOF'
<Full task description here>
TASK_EOF
```

**Step 2 — Dispatch the sub-agent with the file path:**

    Use the **<role_name>** sub-agent tool with these parameters:
    - task_file: `${RUN_DIR}/progress/tasks/<task_name>.md`
    - output_file: `${RUN_DIR}/<output_path>`
    - (plus any role-specific parameters)

**Step 3 — Read the output:**

```bash
cat ${RUN_DIR}/<output_path>
```

### Orchestrator-Specific: Goose Sub-Recipe Mechanism

When encountering a sub-agent dispatch instruction:
1. Use the corresponding **sub-recipe tool** (registered from `recipes/roles/*.yaml`)
2. Each sub-recipe provides context isolation (separate session)
3. The sub-recipe reads the role file, context files, and performs the task
4. Results are written to the specified output file
