# MISSION: Model Architecture Research

> **Type:** ML Research & Architecture Ideation | **Method:** Interactive Research Loop

---

## CONFIGURATION

Obtain `RESEARCH_NAME` from the environment variable `${RESEARCH_NAME}`.

All configuration is read from the **ideation brief** file:

    coding_agent_context/specs/model_arch_research_${RESEARCH_NAME}/ideation.md

---

## IDEATION BRIEF FORMAT

This file is the **single input** that defines the research session — equivalent to
`exploration.md` for data exploration missions. The agent MUST read it before doing
anything else.

**Expected format:**

```markdown
# Model Architecture Ideation Brief: <name>

## Problem Description
What ML problem are we solving? (classification, regression, sequence modeling, etc.)
What are the key characteristics of the task?

## Data Characteristics
- Input shape / dimensionality
- Output format (classes, continuous values, sequences, etc.)
- Dataset size (samples, features)
- Key data properties (sequential, tabular, image, graph, multi-modal, etc.)
- Class balance / distribution information

## Performance Context (optional)
- Current model metrics and baselines (if any)
- Known bottlenecks or failure modes
- Performance targets to beat

## Previous Analysis Reports (optional)
Links or paths to data exploration outputs or other analysis documents that
provide context for the architecture research.

- `coding_agent_context/specs/data_exploration_<name>/memory.md`
- `data_exploration_output/<name>/feature_importance.md`
- ...

## Codebase Analysis
| Setting | Value | Notes |
|---------|-------|-------|
| `ANALYZE_CODEBASE` | `true` / `false` | Whether to analyze existing model code |
| Starting files | `src/models/base_model.py, src/training/trainer.py` | Specific files/classes to examine |
| Focus areas | `model architecture, loss functions, data pipeline` | What to look for in the codebase |

## Architecture Constraints
- Framework preference (PyTorch, TensorFlow, JAX, etc.)
- Inference latency requirements
- Training budget (time, compute, GPU memory)
- Deployment environment (edge, cloud, batch, real-time)
- Must integrate with existing components? (specify which)
- Maximum model size / parameter count

## Initial Architecture Ideas (optional)
Any starting hypotheses or architectures the user already wants to investigate.

- "Transformer-based approach with tabular embeddings"
- "Graph neural network for relational features"
- ...

## Seed Papers (optional)
Papers to use as starting points for the literature search.

| Title | URL | Why Relevant |
|-------|-----|--------------|
| "TabNet: Attentive Interpretable Tabular Learning" | https://arxiv.org/abs/1908.07442 | Attention for tabular data |
| ... | ... | ... |

## Research Scope
- Specific architecture families to investigate (if any)
- Areas to explicitly NOT explore (if any)
- Preference: how novel vs. proven should the approach be?
- Max number of candidate architectures to carry forward

## Initial Questions (optional)
Specific questions to start the research with.

- "How do transformer-based approaches compare to tree ensembles on tabular data?"
- "What is the current SOTA for multi-class classification with imbalanced classes?"
- ...
```

---

## HOW THE AGENT USES THE IDEATION BRIEF

| Brief Section | Used For |
|---------------|----------|
| **Problem Description** | Frames all search queries and applicability assessments |
| **Data Characteristics** | Filters architectures by compatibility with data type/shape |
| **Performance Context** | Sets baselines; helps assess whether a candidate is worth pursuing |
| **Previous Analysis Reports** | Read via analyst sub-agent for additional context |
| **Codebase Analysis** | If `ANALYZE_CODEBASE=true`, triggers analyst sub-agent on listed files |
| **Architecture Constraints** | Hard filters on candidate architectures (latency, framework, etc.) |
| **Initial Architecture Ideas** | Starting points for first research iteration |
| **Seed Papers** | Fetched and analyzed in Phase 1 before broader search |
| **Research Scope** | Bounds the search space |
| **Initial Questions** | Shape the first iteration's research targets |

---

## MEMORY FILE RESOLUTION

> **🧠 MEMORY PERSISTENCE:** This mission maintains a memory file that captures research
> discoveries, explored papers, architecture comparisons, user decisions, and iteration
> history. This knowledge persists across sessions so the agent can resume seamlessly.

### Determine the memory file path

The memory file always lives in the **base research's** spec folder.

    MEMORY_FILE="coding_agent_context/specs/model_arch_research_${RESEARCH_NAME}/memory.md"

### Load existing memory (if any)

```bash
if [ -f "$MEMORY_FILE" ]; then
    echo "RESUMING: Found existing research memory"
    cat "$MEMORY_FILE"
else
    echo "FRESH START: No previous research found"
fi
```

---

## PHASE 0: RESUME CHECK

```
memory.md exists?
  NO  → Phase 1 (fresh start)
  YES → Load history, go to Phase 2 (resume at last research step)
```

When resuming:
1. Read memory file for research history
2. Re-read ideation brief (may have been updated)
3. Read latest research notes from the most recent iteration folder
4. Resume at Phase 2 Step A — propose next directions

---

## PHASE 1: INITIAL RESEARCH

### Step 1.1: Parse Ideation Brief

Read and extract:
- PROBLEM_DESCRIPTION, DATA_CHARACTERISTICS, CONSTRAINTS
- ANALYZE_CODEBASE flag + starting files
- SEED_PAPERS list
- INITIAL_IDEAS list
- INITIAL_QUESTIONS list

### Step 1.2: Codebase Analysis (Conditional)

**Only if `ANALYZE_CODEBASE` is `true` in the ideation brief.**

Use the **analyst** sub-agent tool with these parameters:
- focus: "Analyze the existing model architecture and modeling approaches.
  Identify: model classes, layer structures, loss functions, training loops,
  data pipeline patterns. Focus areas: {focus_areas from brief}"
- read_files: "{starting files from brief}"
- output_file: `coding_agent_context/specs/model_arch_research_${RESEARCH_NAME}_iteration_0/codebase_analysis.md`

If `ANALYZE_CODEBASE` is `false`, skip this step entirely.

### Step 1.3: Seed Paper Analysis

For each paper in the `## Seed Papers` section:
Use the **ml_researcher** sub-agent tool:
- task: "Fetch and analyze this seed paper: {paper_url}. Summarize the
  architecture, key innovations, and how it relates to our problem:
  {PROBLEM_DESCRIPTION}. Data characteristics: {DATA_CHARACTERISTICS}"
- output_file: `coding_agent_context/specs/model_arch_research_${RESEARCH_NAME}_iteration_0/seed_paper_{N}.md`

### Step 1.4: Broad Literature Search

Use the **ml_researcher** sub-agent tool:
- task: "Search for model architectures relevant to: {PROBLEM_DESCRIPTION}.
  Data type: {DATA_CHARACTERISTICS}. Constraints: {CONSTRAINTS}.
  Initial ideas to investigate: {INITIAL_IDEAS}.
  Initial questions: {INITIAL_QUESTIONS}.
  Search arxiv, Semantic Scholar, and Papers with Code.
  Produce a landscape overview of applicable architectures."
- output_file: `coding_agent_context/specs/model_arch_research_${RESEARCH_NAME}_iteration_0/literature_survey.md`

### Step 1.5: Initialize Memory File

Create memory.md using the template at the end of this document.

### Step 1.6: Present Initial Findings & Enter Interactive Mode

Present to user:
1. Summary of codebase analysis (if done)
2. Seed paper findings
3. Literature survey highlights
4. Initial architecture candidates table
5. **Suggest 3-5 next research directions**

Ask: "Which direction would you like to explore next? You can also suggest
your own direction, or type 'finalize' to synthesize results."

---

## PHASE 2: INTERACTIVE RESEARCH LOOP

### Step A: Suggest Next Research Directions

Based on memory + latest research notes, propose 3-5 actionable directions:
- Deeper dive into a specific architecture family
- Comparison study between top N candidates
- Search for ablation studies / practical implementation experiences
- Investigate specific component (attention mechanism, loss function, etc.)
- Look for adaptation strategies (how to adapt architecture X to our data type)

### Step B: Wait for User Input

Options:
- Select a suggested direction (number)
- Provide custom research direction
- "finalize" → proceed to Phase 3

### Step C: Execute Research Iteration

C.1 Read Next Iteration counter N from memory.md
C.2 mkdir coding_agent_context/specs/model_arch_research_${RESEARCH_NAME}_iteration_${N}/
C.3 Use **ml_researcher** sub-agent:
    - task: "{user's chosen direction}. Problem context: {PROBLEM_DESCRIPTION}.
      Known candidates so far: {from memory}. Constraints: {CONSTRAINTS}"
    - output_file: `coding_agent_context/specs/model_arch_research_${RESEARCH_NAME}_iteration_${N}/research_notes.md`
C.4 (Optional) If user's direction requires codebase understanding:
    Use **analyst** sub-agent to read relevant source files

### Step D: Report & Update Memory

D.1 Use **doc_writer** sub-agent tool to update memory.md:
    - Update Architecture Candidates table (add/revise entries)
    - Update Key Papers & References
    - Add to Research Timeline
    - Add to User Decisions Log
    - Increment Next Iteration counter
D.2 Present findings to user (key findings, updated candidates table)

### Step E: Loop Back → Step A

---

## PHASE 3: FINALIZE

**Triggered when user says "finalize".**

### Step 3.1: Synthesize Architecture Brief

Use the **ml_researcher** sub-agent tool:
- task: "Synthesize all research iterations into a final architecture brief.
  Read all iteration research notes and the memory file.
  Produce a comprehensive architecture_brief.md that includes:
  1. Executive Summary of research findings
  2. Problem & Data Summary (from ideation brief)
  3. Architecture Candidates Comparison (final ranked table)
  4. Recommended Architecture with justification
  5. Key Design Decisions and trade-offs
  6. Implementation Considerations (framework, libraries, components)
  7. Risk Assessment (what could go wrong with each approach)
  8. Complete References (all papers cited)"
- read_files: memory.md + all iteration research_notes.md files
- output_file: `coding_agent_context/specs/model_arch_research_${RESEARCH_NAME}/architecture_brief.md`

### Step 3.2: Generate requirements.md for architecture_design mission

Use the **doc_writer** sub-agent tool:
- task: "Transform the architecture_brief.md into a requirements.md file that
  follows the EXACT format expected by coding_agent_context/missions/architecture_design.md.
  The requirements.md must include:
  - Summary (from executive summary)
  - Background / Motivation (from problem description + research justification)
  - Functional Requirements (derived from recommended architecture's components)
  - Non-Functional Requirements (from constraints in ideation brief)
  - Constraints (from architecture constraints + deployment requirements)
  - Acceptance Criteria (testable criteria for the architecture implementation)
  - New Dependencies (framework, libraries identified during research)
  - Out of Scope (architectures that were considered but rejected, and why)"
- target_file: `coding_agent_context/specs/model_arch_research_${RESEARCH_NAME}/requirements.md`
- read_files: architecture_brief.md, ideation.md
- output_file: `coding_agent_context/specs/model_arch_research_${RESEARCH_NAME}/requirements_session.md`

### Step 3.3: Update Memory & Print Next Steps

Update memory.md status to COMPLETED.

Print to user:

    ## Research Complete ✅

    ### Output Files
    - Architecture Brief: `coding_agent_context/specs/model_arch_research_${RESEARCH_NAME}/architecture_brief.md`
    - Requirements (for implementation): `coding_agent_context/specs/model_arch_research_${RESEARCH_NAME}/requirements.md`

    ### Next Steps — Run Architecture Design Mission

        export FEATURE="model_arch_research_${RESEARCH_NAME}"
        # Then run: coding_agent_context/missions/architecture_design.md

    This will use the generated requirements.md to produce a detailed
    design.md and implementation plan, which can then feed into
    implement_tdd.md for actual coding.

---

## MEMORY FILE TEMPLATE

```markdown
# Model Architecture Research Memory: ${RESEARCH_NAME}

> **Status:** IN_PROGRESS
> **Started:** [CURRENT_DATE]
> **Last Updated:** [CURRENT_DATE]
> **Next Iteration:** 1

---

## Research Timeline

| # | Date | Iteration Folder | Topic | Key Papers Found | Key Findings |
|---|------|------------------|-------|------------------|--------------|
| 0 | [DATE] | `model_arch_research_${RESEARCH_NAME}_iteration_0` | Initial survey | [list] | [2-3 sentence summary] |

---

## Architecture Candidates

| # | Name | Key Innovation | Source Paper(s) | Strengths | Weaknesses | Applicability (1-5) | Status |
|---|------|----------------|-----------------|-----------|------------|---------------------|--------|

> **Status values:** INVESTIGATING | PROMISING | REJECTED | RECOMMENDED

---

## Key Papers & References

| # | Title | Authors | Year | URL | Relevance | Iteration Found |
|---|-------|---------|------|-----|-----------|-----------------|

---

## Codebase Analysis Summary (if applicable)

> Populated only if `ANALYZE_CODEBASE=true` in the ideation brief.

- **Current model architecture:** [summary]
- **Key files:** [list]
- **Patterns identified:** [list]
- **Integration points for new architecture:** [list]

---

## User Decisions Log

| # | Date | User Request | Action Taken |
|---|------|-------------|--------------|

---

## Current State

### What We Know
- [Bullet list of established findings]

### What We Haven't Explored Yet
- [Bullet list of open research directions]

### Leading Candidates
- [Top 1-3 architectures with brief justification]
```

---

## EXIT CRITERIA

### For Each Iteration
| Criterion | Validation |
|-----------|------------|
| Research notes produced | iteration folder contains research_notes.md |
| Memory updated | Timeline includes iteration, candidates table updated |
| Sources cited | Every claim links to a paper or source URL |

### For Finalization (User says 'finalize')
| Criterion | Validation |
|-----------|------------|
| architecture_brief.md complete | All sections populated with cited sources |
| requirements.md generated | Follows architecture_design.md expected format exactly |
| Memory finalized | Status set to COMPLETED |
| Candidates ranked | Architecture Candidates table has final Applicability scores |
| Next steps printed | User knows how to run architecture_design mission |

### For Session Pause (User says 'stop')
| Criterion | Validation |
|-----------|------------|
| Memory file saved | Status remains IN_PROGRESS, timeline complete |
| All iteration outputs present | Every research_notes.md from all iterations exists |
| Current state updated | "What We Know" and "Leading Candidates" are current |

---

## LOOP SUMMARY

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 0: RESUME CHECK                                                       │
│   memory.md exists? → NO: Phase 1 | YES: Load history, Phase 2              │
├─────────────────────────────────────────────────────────────────────────────┤
│ PHASE 1: INITIAL RESEARCH (RUN ONCE, ITERATION 0)                           │
│   1.1 Parse ideation brief                                                   │
│   1.2 Codebase analysis (if ANALYZE_CODEBASE=true)                          │
│   1.3 Seed paper analysis                                                    │
│   1.4 Broad literature search                                                │
│   1.5 Initialize memory.md                                                   │
│   1.6 Present findings → Enter Phase 2                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│ PHASE 2: INTERACTIVE RESEARCH LOOP (REPEAT UNTIL USER STOPS)                │
│   A. SUGGEST:   3-5 next research directions based on memory                │
│   B. WAIT:      User feedback (select / custom / finalize / stop)           │
│   C. EXECUTE:   ml_researcher sub-agent → iteration folder                  │
│   D. REPORT:    Present findings, update memory.md                          │
│   E. LOOP:      → back to A                                                │
├─────────────────────────────────────────────────────────────────────────────┤
│ PHASE 3: FINALIZE (TRIGGERED BY "finalize")                                 │
│   3.1 Synthesize architecture_brief.md                                      │
│   3.2 Generate requirements.md for architecture_design mission              │
│   3.3 Update memory, print next steps                                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## QUICK START

```bash
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
```
