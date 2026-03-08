# MISSION: Iterative Data Exploration

> **Type:** Data Analysis & Exploration | **Method:** Interactive Loop with Reproducible Outputs

---

## CONFIGURATION

Obtain `EXPLORATION_NAME` from the environment variable `${EXPLORATION_NAME}`.

All other configuration is read from the **exploration brief** file:

```
coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}/exploration.md
```

### Exploration Brief File

This file is the **single input** that defines the exploration session — equivalent to
`requirements.md` for implementation missions. The agent MUST read it before doing
anything else.

**Expected format:**

```markdown
# Data Exploration Brief: <name>

## Data Sources
List every data source to explore, one per bullet. Include format, location,
and approximate size when known.

- `s3://my-bucket/path/to/data.csv` — CSV, ~8 GB, seller transaction records
- `local_file.parquet` — Parquet, ~500 MB, feature matrix
- ...

## Environment & Credentials
Any runtime configuration the Docker container needs to access the data.

| Variable / Setting | Value | Description |
|--------------------|-------|-------------|
| `AWS_PROFILE` | `spascience` | AWS profile for S3 access |
| `AWS_DEFAULT_REGION` | `us-west-2` | AWS region |
| ... | ... | ... |

## Context
Free-form background information that helps the agent understand what
this data is, why it matters, and what kind of exploration is useful.

(e.g., "This dataset powers the SHERPA seller-risk model.
We want to understand feature distributions before retraining.")

## Initial Questions (optional)
Specific questions the user wants answered in the first exploration pass.

- What is the class distribution across the 7 risk categories?
- Are there columns with >50 % missing values?
- ...

## Docker Preferences
| Setting | Value | Notes |
|---------|-------|-------|
| `USE_PACKAGE_DOCKER` | `true` / `false` | Extend existing project Dockerfile or create dedicated one |
| Extra pip packages | `plotly`, `geopandas` | Additional packages needed beyond defaults |
| GPU required | `false` | Whether GPU support is needed |
```

### How the agent uses the exploration brief

| Brief Section | Used For |
|---------------|----------|
| **Data Sources** | Passed to `docker_manager.sh --data-sources` for dependency detection; drives initial loading code |
| **Environment & Credentials** | Injected into Docker `run.sh` as `-e` flags and mounted credential paths |
| **Context** | Fed to the architect and analyst tools so generated code is domain-aware |
| **Initial Questions** | Shape the first iteration's analysis targets (Phase 1) |
| **Docker Preferences** | Controls `USE_PACKAGE_DOCKER` logic and extra pip installs |

---

## CRITICAL: DOCKER-ONLY EXECUTION POLICY

> **🚫 ABSOLUTE RULE — NO EXCEPTIONS:**
> ALL data exploration code execution (Python scripts, data loading, analysis, debugging)
> MUST happen **exclusively inside a Docker container**. The agent MUST NEVER run any
> `python` command, data processing script, or exploration code directly on the host machine.
>
> **This applies to:**
> - Initial data loading and structure analysis
> - Every follow-up iteration's data processing
> - Ad-hoc debugging or testing of exploration code
> - Any `python` invocation related to data exploration
>
> **The ONLY permitted execution methods are:**
> 1. `./coding_agent_context/tools/data_explorer.sh --action run ...` (uses Docker internally)
> 2. `./coding_agent_context/tools/data_explorer.sh --action run-script ...` (uses Docker internally)
> 3. `docker/data_exploration_${EXPLORATION_NAME}/run.sh process` (direct Docker run)
> 4. `docker exec` into a running daemon container
>
> **If Docker is not yet set up:** Set it up FIRST (Phase 1 Step 1.1) before executing ANY code.
> **If Docker image is missing on resume:** Rebuild it FIRST before executing ANY code.
>
> **NEVER do this:**
> ```bash
> # ❌ FORBIDDEN — direct host execution
> python src/data_exploration/my_analysis/run_exploration.py
> python -c "import pandas; ..."
> cd src/data_exploration && python anything.py
> ```
>
> **ALWAYS do this:**
> ```bash
> # ✅ CORRECT — Docker execution via tool
> ./coding_agent_context/tools/data_explorer.sh --action run --exploration-name my_analysis
>
> # ✅ CORRECT — Docker execution via run.sh
> docker/data_exploration_my_analysis/run.sh process
>
> # ✅ CORRECT — Docker exec into daemon
> docker exec -i data-exploration-my_analysis python /workspace/src/data_exploration/my_analysis/run_exploration.py
> ```

---

## OBJECTIVE

Perform iterative, interactive data exploration on provided data sources. All analysis code must be:
1. **Reproducible** — runnable via CLI scripts even after the agent session ends
2. **Backwards-compatible** — each iteration preserves all previous analysis outputs unless the user explicitly requests removal
3. **Resumable** — a memory file tracks exploration history so the agent can pick up where it left off
4. **Docker-contained** — ALL code execution happens inside Docker containers, NEVER on the host

**Output Locations:**

| Output | Path | Description |
|--------|------|-------------|
| Exploration brief | `coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}/exploration.md` | User-authored input defining data sources, credentials, context |
| Exploration root | `coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}/` | Memory file and exploration brief |
| Iteration specs | `coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}_iteration_${N}/` | Per-iteration: requirements.md, design.md, progress.md |
| Analysis results | `data_exploration_output/${EXPLORATION_NAME}/` | Markdown reports generated by data processing code |
| Memory file | `coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}/memory.md` | Session history, exploration timeline, and **current iteration counter** |
| Processing code | `src/data_exploration/${EXPLORATION_NAME}/` | Python scripts that perform the analysis |
| Docker artifacts | `docker/data_exploration_${EXPLORATION_NAME}/` | Dockerfile + build/run scripts (if dedicated docker) |

### Iteration-Based Folder Structure

Each implementation cycle (Phase 1 initial + every Phase 2 loop iteration) gets its **own spec subfolder**.
This keeps each architecture_design → implement_tdd cycle cleanly separated and easy to follow.

```
coding_agent_context/specs/
├── data_exploration_${EXPLORATION_NAME}/           # Root: brief + memory
│   ├── exploration.md                               # User-authored exploration brief
│   └── memory.md                                    # Session history + iteration counter
├── data_exploration_${EXPLORATION_NAME}_iteration_0/ # Phase 1 (initial exploration)
│   ├── requirements.md                              # Generated from exploration brief
│   ├── design.md                                    # architecture_design output
│   └── progress.md                                  # implement_tdd progress tracker
├── data_exploration_${EXPLORATION_NAME}_iteration_1/ # Phase 2, first user iteration
│   ├── requirements.md
│   ├── design.md
│   └── progress.md
├── data_exploration_${EXPLORATION_NAME}_iteration_2/ # Phase 2, second user iteration
│   ├── requirements.md
│   ├── design.md
│   └── progress.md
└── ...
```

The `architecture_design.md` and `implement_tdd.md` missions are invoked with:
```bash
export FEATURE="data_exploration_${EXPLORATION_NAME}_iteration_${ITERATION_NUM}"
```
This causes them to read `requirements.md` from and write `design.md`/`progress.md` into
the iteration-specific subfolder automatically.

---

## OVERVIEW

> **🔗 STRICT MISSION RE-USE POLICY:**
> This mission does NOT define its own architecture design or TDD implementation process.
> Whenever implementation is needed (Phase 1 Step 1.2b/1.2c, Phase 2 Step C.3/C.4),
> the agent MUST:
> 1. `cat coding_agent_context/missions/architecture_design.md` — read the full mission file
> 2. Follow every step in that file exactly as written
> 3. Then `cat coding_agent_context/missions/implement_tdd.md` — read the full mission file
> 4. Follow every step in that file exactly as written
>
> **Why:** Changes to `architecture_design.md` or `implement_tdd.md` must automatically
> apply to data exploration iterations. If this mission inlined or paraphrased those
> processes, updates would not propagate.
>
> **The agent MUST NOT:**
> - Summarize, abbreviate, or paraphrase the architecture_design or implement_tdd missions
> - Skip steps defined in those mission files
> - Substitute its own design or implementation process
> - Rely on its memory of what those missions contain — always re-read the file

```
┌─────────────────────────────────────────────────────────────┐
│ PHASE 0: RESUME CHECK                                       │
│ • Check for existing memory.md                              │
│ • If found: load history, skip to Phase 2 interactive loop  │
│ • If not found: fresh start, proceed to Phase 1             │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ PHASE 1: INITIAL DATA EXPLORATION                           │
│ • Set up Docker execution environment                       │
│ • Write initial data loading + structure analysis code      │
│ • Execute code → produce initial markdown reports           │
│ • Create memory file with initial findings                  │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ PHASE 2: INTERACTIVE EXPLORATION LOOP                       │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ A. SUGGEST: Propose 3-5 next exploration directions     │ │
│ │ B. WAIT:    User selects / provides feedback            │ │
│ │ C. IMPLEMENT: Write code via architecture + TDD agents  │ │
│ │ D. EXECUTE: Run processing code in Docker               │ │
│ │ E. REPORT:  Present findings, update memory file        │ │
│ │ F. LOOP:    Return to A (until user says stop)          │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## PHASE 0: RESUME CHECK

> **CRITICAL:** Always start here. This enables resumption after session interruption.

### Step 0.1: Read the Exploration Brief

```bash
BRIEF_FILE="coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}/exploration.md"

if [ ! -f "$BRIEF_FILE" ]; then
    echo "❌ ERROR: Exploration brief not found: $BRIEF_FILE"
    echo "Create it before running this mission. See CONFIGURATION section for format."
    exit 1
fi

cat "$BRIEF_FILE"
```

**Parse the brief and extract key values:**
- **DATA_SOURCES**: list of paths/URIs from the `## Data Sources` section
- **ENV_VARS**: key-value pairs from `## Environment & Credentials` table
- **USE_PACKAGE_DOCKER**: from `## Docker Preferences` table (default: `false`)
- **EXTRA_PIP_PACKAGES**: from `## Docker Preferences` table (if any)
- **CONTEXT**: the free-form text from `## Context`
- **INITIAL_QUESTIONS**: from `## Initial Questions` (if present)

These parsed values are used throughout all subsequent phases.

### Step 0.2: Check for Existing Memory

```bash
MEMORY_FILE="coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}/memory.md"

if [ -f "$MEMORY_FILE" ]; then
    echo "RESUMING: Found existing exploration memory"
    cat "$MEMORY_FILE"
else
    echo "FRESH START: No previous exploration found"
fi
```

**Decision Tree:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Does memory.md exist?                                                       │
├──────────────────────────────────┬──────────────────────────────────────────┤
│ NO → Go to Phase 1               │ YES → Read memory, go to Phase 2        │
│      (Fresh start)                │       (Resume at last exploration step)  │
└──────────────────────────────────┴──────────────────────────────────────────┘
```

**When resuming (memory.md exists):**
1. Read the memory file to understand exploration history
2. Re-read the exploration brief (it may have been updated between sessions)
3. Read the latest analysis outputs in `data_exploration_output/${EXPLORATION_NAME}/`
4. **🚫 MANDATORY: Verify Docker environment is available BEFORE any code execution:**
   ```bash
   # Check Docker image exists — if not, rebuild it
   ./coding_agent_context/tools/docker_manager.sh --action status --exploration-name "${EXPLORATION_NAME}"

   # If image is missing, rebuild:
   ./coding_agent_context/tools/docker_manager.sh --action setup --exploration-name "${EXPLORATION_NAME}"
   ```
   The agent MUST NOT execute any exploration code until Docker is confirmed ready.
   Read the `## Docker Execution Commands` section from memory.md for the exact execution commands.
5. Resume at Phase 2 Step A — propose next directions based on what was already explored
6. **Do NOT re-run previous exploration steps** unless the user requests it

---

## PHASE 1: INITIAL DATA EXPLORATION

### Step 1.1: Set Up Docker Execution Environment

**Goal:** Ensure a Docker container is available for running data processing code.

First, extract Docker-relevant values from the exploration brief:
- `USE_PACKAGE_DOCKER` from `## Docker Preferences` table
- `EXTRA_PIP_PACKAGES` from `## Docker Preferences` table
- `DATA_SOURCES` from `## Data Sources` section (for dependency auto-detection)
- `ENV_VARS` from `## Environment & Credentials` table (for run.sh generation)

```bash
# Get tool usage
./coding_agent_context/tools/docker_manager.sh --help

# Set USE_PACKAGE_DOCKER from the exploration brief (default: false)
export USE_PACKAGE_DOCKER="<value from brief>"

# Set up docker environment
# Pass the data source list extracted from exploration.md
# This handles USE_PACKAGE_DOCKER logic automatically
./coding_agent_context/tools/docker_manager.sh \
    --action setup \
    --exploration-name "${EXPLORATION_NAME}" \
    --data-sources "<comma-separated list from ## Data Sources>"
```

**The docker_manager.sh tool will:**
1. Check if `USE_PACKAGE_DOCKER` is `true`:
   - **YES:** Inspect existing project `docker/Dockerfile`, extend it for data exploration needs
   - **NO:** Create a dedicated `docker/data_exploration_${EXPLORATION_NAME}/Dockerfile`
2. Generate `build.sh` and `run.sh` interface scripts
3. Build the Docker image
4. Verify the container can start

**After setup, apply brief-specific customizations:**
1. If `## Docker Preferences` lists extra pip packages, add them to the Dockerfile and rebuild
2. If `## Environment & Credentials` lists env vars or credential paths, update `run.sh` to include them as `-e` flags or volume mounts (e.g., `-e AWS_PROFILE=spascience`, `-v "$HOME/.aws:/root/.aws:ro"`)

**Verify:**
```bash
cat docker/data_exploration_${EXPLORATION_NAME}/build.sh
cat docker/data_exploration_${EXPLORATION_NAME}/run.sh
```

---

### Step 1.2: Create Initial Data Loading Code

**Goal:** Write Python code that reads the data sources and generates basic structure analysis.

> **Iteration counter:** The initial exploration is **iteration 0**.
> All spec files go into a dedicated iteration subfolder.

#### Step 1.2a: Create iteration folder and requirements for initial exploration

```bash
# Phase 1 is always iteration 0
ITERATION_NUM=0
ITERATION_FEATURE="data_exploration_${EXPLORATION_NAME}_iteration_${ITERATION_NUM}"
ITERATION_SPEC_DIR="coding_agent_context/specs/${ITERATION_FEATURE}"

mkdir -p "${ITERATION_SPEC_DIR}"
```

Using the data sources, context, and initial questions parsed from the exploration brief,
create `${ITERATION_SPEC_DIR}/requirements.md`:

```markdown
# Data Exploration: ${EXPLORATION_NAME} — Iteration 0: Initial Structure Analysis

## Source
This requirements file was generated from the exploration brief:
`coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}/exploration.md`

## Context
[Copy the ## Context section from the exploration brief here — this gives
 the architect and developer agents domain awareness]

## Objective
Write Python code that loads the following data sources and produces a basic
structural analysis written to markdown files.

## Data Sources
[Copy each bullet from ## Data Sources in the exploration brief, e.g.:]
- `s3://my-bucket/path/to/data.csv` — CSV, ~8 GB, seller transaction records
- `local_file.parquet` — Parquet, ~500 MB, feature matrix

## Initial Questions
[Copy from ## Initial Questions in the exploration brief, if present.
 These should be answered in the initial analysis output.]

## Environment Notes
[List any environment/credential details from the brief that affect code,
 e.g. "Data on S3 requires AWS_PROFILE=spascience".]

## Required Outputs (all written to data_exploration_output/${EXPLORATION_NAME}/)

### For each data source, produce a markdown file with:
1. **File metadata:** path, size, format, encoding (if applicable)
2. **Schema / Structure:**
   - Column names + data types (for tabular data)
   - Key structure (for JSON/dict data)
   - Nested structure depth (for hierarchical data)
3. **Basic statistics:**
   - Row count / record count
   - Column count / field count
   - Null/missing value counts per field
   - Unique value counts for categorical fields (top 20)
   - Min/max/mean/median/std for numeric fields
4. **Sample data:** First 5 rows/records (formatted as markdown table)
5. **Data quality flags:**
   - Columns with >50% missing values
   - Constant columns (single unique value)
   - Potential ID columns (all unique)
   - Date/timestamp columns detected

### Produce a summary index file:
- `data_exploration_output/${EXPLORATION_NAME}/INDEX.md`
- Links to each data source analysis
- Cross-reference table showing shared columns across sources

## Implementation Requirements
- All code in `src/data_exploration/${EXPLORATION_NAME}/`
- Main entry point: `src/data_exploration/${EXPLORATION_NAME}/run_exploration.py`
- Must be executable via Docker: `docker exec -i <container> python run_exploration.py` (NEVER on host)
- All outputs written to `data_exploration_output/${EXPLORATION_NAME}/`
- Use existing data loading infrastructure if available (check src/ for loaders)
- CLI-reproducible: running the script again produces the same outputs
```

#### Step 1.2b: Run architecture design mission

> **STRICT DELEGATION:** Do NOT paraphrase or improvise the architecture design process.
> You MUST read and follow `coding_agent_context/missions/architecture_design.md` exactly.

```bash
# Set FEATURE so the architecture_design mission operates on the correct iteration folder
export FEATURE="data_exploration_${EXPLORATION_NAME}_iteration_0"

# Now READ and EXECUTE the architecture_design mission file step by step:
cat coding_agent_context/missions/architecture_design.md
```

**Follow every step in `architecture_design.md` as written.** The mission will:
- Read requirements from `coding_agent_context/specs/${FEATURE}/requirements.md` (the file you just created)
- Write the design to `coding_agent_context/specs/${FEATURE}/design.md`
- Produce a granular, checkboxed Implementation Plan suitable for TDD

Do NOT skip steps, summarize the mission, or substitute your own design process.
Only after `architecture_design.md` is fully complete (all exit criteria met), proceed to Step 1.2c.

#### Step 1.2c: Run TDD implementation mission

> **STRICT DELEGATION:** Do NOT paraphrase or improvise the TDD implementation process.
> You MUST read and follow `coding_agent_context/missions/implement_tdd.md` exactly.

```bash
# FEATURE is still set to the iteration-specific value
export FEATURE="data_exploration_${EXPLORATION_NAME}_iteration_0"

# Now READ and EXECUTE the implement_tdd mission file step by step:
cat coding_agent_context/missions/implement_tdd.md
```

**Follow every step in `implement_tdd.md` as written.** The mission will:
- Read the design from `coding_agent_context/specs/${FEATURE}/design.md` (produced by Step 1.2b)
- Create/update `coding_agent_context/specs/${FEATURE}/progress.md`
- Implement the code using the strict Red-Green-Refactor TDD cycle

Do NOT skip the TDD loop, write code without failing tests first, or substitute your own implementation process.
Only after `implement_tdd.md` is fully complete (all exit criteria met), proceed to Step 1.3.

---

### Step 1.3: Execute Initial Data Processing

**Goal:** Run the newly created code in Docker and verify outputs.

> **🚫 REMINDER: Docker-Only Execution.**
> The ONLY way to run the exploration code is through `data_explorer.sh` or the Docker `run.sh` scripts.
> Do NOT run `python run_exploration.py` directly on the host. If you are tempted to
> "quickly test" something, use `data_explorer.sh --action run-script` instead.

```bash
# ✅ Execute data processing in Docker (the ONLY permitted method)
./coding_agent_context/tools/data_explorer.sh \
    --action run \
    --exploration-name "${EXPLORATION_NAME}" \
    --output data_exploration_output/${EXPLORATION_NAME}/

# Read the results (reading output files on host is fine — only EXECUTION must be in Docker)
cat data_exploration_output/${EXPLORATION_NAME}/INDEX.md
```

**Verify outputs exist:**
```bash
ls -la data_exploration_output/${EXPLORATION_NAME}/
```

**If execution fails:** debug by fixing code, rebuilding Docker if needed, then re-run
via `data_explorer.sh`. Do NOT bypass Docker to test locally.

---

### Step 1.4: Initialize Memory File

**Goal:** Create the exploration memory file to enable session resumption.

Create `coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}/memory.md`:

```markdown
# Data Exploration Memory: ${EXPLORATION_NAME}

> **Status:** IN_PROGRESS
> **Started:** [CURRENT_DATE]
> **Last Updated:** [CURRENT_DATE]
> **Data Sources:** [Copy data source list from exploration.md]
> **Next Iteration:** 1

---

## Docker Execution Commands

> **🚫 ALL code execution MUST use these commands. NEVER run Python directly on the host.**

| Action | Command |
|--------|---------|
| Run full exploration | `./coding_agent_context/tools/data_explorer.sh --action run --exploration-name ${EXPLORATION_NAME}` |
| Run specific script | `./coding_agent_context/tools/data_explorer.sh --action run-script --exploration-name ${EXPLORATION_NAME} --script <path>` |
| Verify outputs | `./coding_agent_context/tools/data_explorer.sh --action verify --exploration-name ${EXPLORATION_NAME}` |
| Rebuild Docker image | `./coding_agent_context/tools/docker_manager.sh --action build --exploration-name ${EXPLORATION_NAME}` |
| Check Docker status | `./coding_agent_context/tools/docker_manager.sh --action status --exploration-name ${EXPLORATION_NAME}` |
| Interactive shell | `./coding_agent_context/tools/docker_manager.sh --action shell --exploration-name ${EXPLORATION_NAME}` |

**Docker image:** `data-exploration-${EXPLORATION_NAME}:latest`
**Dockerfile:** `docker/data_exploration_${EXPLORATION_NAME}/Dockerfile`
**Build script:** `docker/data_exploration_${EXPLORATION_NAME}/build.sh`
**Run script:** `docker/data_exploration_${EXPLORATION_NAME}/run.sh`

---

## Exploration Timeline

| # | Date | Phase | Iteration Folder | Description | Output Files | Key Findings |
|---|------|-------|------------------|-------------|--------------|--------------|
| 0 | [DATE] | Initial Structure | `data_exploration_${EXPLORATION_NAME}_iteration_0` | Basic schema, stats, quality flags | INDEX.md, [source]_structure.md | [2-3 sentence summary of what was found] |

---

## Current State

### What We Know
- [Bullet list of key findings from initial exploration]

### What We Haven't Explored Yet
- [Bullet list of obvious next directions]

### Active Analysis Files
| File | Description | Created |
|------|-------------|---------|
| `run_exploration.py` | Main entry point | [DATE] |
| ... | ... | ... |

---

## User Decisions Log

| # | Date | User Request | Action Taken |
|---|------|-------------|--------------|
| | | | |
```

---

### Step 1.5: Present Initial Findings & Enter Interactive Mode

**Goal:** Summarize initial findings and transition to Phase 2.

**Present to the user:**
1. Summary of each data source (schema, size, quality)
2. Any notable findings (data quality issues, interesting patterns, cross-source relationships)
3. **Suggest 3-5 next exploration directions** (see Phase 2 Step A)

**Then ask:** "Which direction would you like to explore next? You can also suggest your own direction, or type 'stop' to end the exploration."

---

## PHASE 2: INTERACTIVE EXPLORATION LOOP

### Step A: Suggest Next Exploration Directions

**Goal:** Based on current knowledge (memory file + latest outputs), propose actionable next steps.

**Read current state:**
```bash
cat coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}/memory.md
ls data_exploration_output/${EXPLORATION_NAME}/
```

**Generate suggestions.** Consider these categories:

| Category | Example Suggestions |
|----------|-------------------|
| **Distribution Analysis** | "Examine the distribution of column X — it has high variance" |
| **Correlation Analysis** | "Check correlations between numeric columns to find relationships" |
| **Temporal Patterns** | "Analyze trends over time in the date column Y" |
| **Outlier Detection** | "Investigate outliers in column Z (values beyond 3σ)" |
| **Cross-Source Joins** | "Join sources A and B on shared column C to explore relationships" |
| **Category Deep-Dive** | "Break down metrics by category column W" |
| **Missing Data Analysis** | "Investigate patterns in missing data — is it random or systematic?" |
| **Feature Engineering** | "Derive new features from existing columns for deeper insight" |

**Present 3-5 numbered suggestions** to the user with brief rationale for each.

**Then WAIT for user input.** Do not proceed without user feedback.

---

### Step B: Receive User Feedback

**The user may:**
1. **Select a suggestion** (e.g., "Let's do #2")
2. **Provide custom direction** (e.g., "I want to see the top 10 sellers by revenue")
3. **Request modification** (e.g., "#3 but only for the last 6 months")
4. **Ask to remove previous analysis** (e.g., "Remove the outlier analysis from step 3")
5. **Say 'stop'** → End exploration, finalize memory file, exit

**If user says 'stop':**
```bash
# Update memory file status
sed -i 's/> \*\*Status:\*\* IN_PROGRESS/> **Status:** PAUSED/' \
    coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}/memory.md
```
Then present a final summary and exit.

---

### Step C: Implement New Analysis Code

**Goal:** Extend the data processing code to perform the requested analysis.

> **CRITICAL: Backwards Compatibility Rule**
> The new code MUST preserve all existing analysis outputs. When `run_exploration.py`
> is executed, it must still produce every markdown file from previous iterations
> PLUS the new analysis. The only exception is if the user explicitly requests
> removal of a specific previous analysis.

#### Step C.1: Determine iteration number and create iteration folder

Read the **Next Iteration** counter from the memory file header and create a new
iteration-specific spec folder:

```bash
# Read the next iteration number from the memory file header
ITERATION_NUM=$(grep -oP '(?<=\*\*Next Iteration:\*\* )\d+' \
    coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}/memory.md)

ITERATION_FEATURE="data_exploration_${EXPLORATION_NAME}_iteration_${ITERATION_NUM}"
ITERATION_SPEC_DIR="coding_agent_context/specs/${ITERATION_FEATURE}"

mkdir -p "${ITERATION_SPEC_DIR}"

echo "Creating iteration ${ITERATION_NUM} in: ${ITERATION_SPEC_DIR}"
```

#### Step C.2: Create requirements for this iteration

Create `${ITERATION_SPEC_DIR}/requirements.md`:

```markdown
# Data Exploration: ${EXPLORATION_NAME} — Iteration ${ITERATION_NUM}: [USER_REQUEST_SUMMARY]

## Source
This is iteration ${ITERATION_NUM} of data exploration `${EXPLORATION_NAME}`.
- Exploration brief: `coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}/exploration.md`
- Memory file: `coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}/memory.md`
- Previous iteration specs: `coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}_iteration_0/` through `..._iteration_$((ITERATION_NUM-1))/`

## Context
- Previous analyses: [list from memory file timeline]
- User request: [exact user feedback from Step B]

## Requirements
- [Specific analysis to implement]
- Output file: data_exploration_output/${EXPLORATION_NAME}/[descriptive_name].md
- MUST NOT break existing outputs (backwards compatibility)

## Backwards Compatibility Check
All of these files must still be generated:
- [list all existing output files from previous iterations]

## Implementation Requirements
- Extend existing code in `src/data_exploration/${EXPLORATION_NAME}/`
- New analysis added to `run_exploration.py` pipeline (additive, not replacing)
- All outputs written to `data_exploration_output/${EXPLORATION_NAME}/`
- Must be executable via Docker: `docker exec -i <container> python run_exploration.py` (NEVER on host)
```

#### Step C.3: Run architecture design for the iteration

> **STRICT DELEGATION:** Do NOT paraphrase or improvise the architecture design process.
> You MUST read and follow `coding_agent_context/missions/architecture_design.md` exactly.

```bash
# Set FEATURE to the iteration-specific folder
export FEATURE="${ITERATION_FEATURE}"

# Now READ and EXECUTE the architecture_design mission file step by step:
cat coding_agent_context/missions/architecture_design.md
```

**Follow every step in `architecture_design.md` as written.** The mission will:
- Read requirements from `coding_agent_context/specs/${FEATURE}/requirements.md` (the file you just created in C.2)
- Write the design to `coding_agent_context/specs/${FEATURE}/design.md`
- Produce a granular, checkboxed Implementation Plan suitable for TDD

**Additional context for the architect (pass as reference files where applicable):**
- The memory file `coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}/memory.md` — for exploration history
- Previous iteration design files — for context on what code already exists
- The implementation plan MUST extend (not replace) existing code

Do NOT skip steps, summarize the mission, or substitute your own design process.
Only after `architecture_design.md` is fully complete (all exit criteria met), proceed to Step C.4.

#### Step C.4: Run TDD implementation for the iteration

> **STRICT DELEGATION:** Do NOT paraphrase or improvise the TDD implementation process.
> You MUST read and follow `coding_agent_context/missions/implement_tdd.md` exactly.

```bash
# FEATURE remains set to the iteration-specific value
export FEATURE="${ITERATION_FEATURE}"

# Now READ and EXECUTE the implement_tdd mission file step by step:
cat coding_agent_context/missions/implement_tdd.md
```

**Follow every step in `implement_tdd.md` as written.** The mission will:
- Read the design from `coding_agent_context/specs/${FEATURE}/design.md` (produced by Step C.3)
- Create/update `coding_agent_context/specs/${FEATURE}/progress.md`
- Implement the code using the strict Red-Green-Refactor TDD cycle

Each iteration gets its own `progress.md` — previous iterations' progress files
are untouched and serve as a historical record.

Do NOT skip the TDD loop, write code without failing tests first, or substitute your own implementation process.
Only after `implement_tdd.md` is fully complete (all exit criteria met), proceed to Step C.5.

#### Step C.5: Verify backwards compatibility

```bash
# List expected outputs from memory file
# After implementation, verify all previous output files are still generated
```

---

### Step D: Execute Data Processing

**Goal:** Run the updated code in Docker and capture results.

> **🚫 REMINDER: Docker-Only Execution.**
> Use ONLY the commands listed in the `## Docker Execution Commands` section of memory.md.
> Do NOT run Python directly on the host, even for "quick tests" or debugging.

```bash
# ✅ Execute in Docker (the ONLY permitted method)
./coding_agent_context/tools/data_explorer.sh \
    --action run \
    --exploration-name "${EXPLORATION_NAME}" \
    --output data_exploration_output/${EXPLORATION_NAME}/

# Verify ALL outputs (old + new)
ls -la data_exploration_output/${EXPLORATION_NAME}/

# Read the new analysis (reading files on host is fine — only EXECUTION must be in Docker)
cat data_exploration_output/${EXPLORATION_NAME}/[NEW_OUTPUT_FILE].md
```

**If execution fails:**
1. Read error output from the data_explorer tool
2. Debug the issue (fix code, rebuild docker if needed)
3. Re-run execution **via data_explorer.sh** — do NOT bypass Docker to test locally
4. Do NOT proceed to Step E until execution succeeds

---

### Step E: Report Findings & Update Memory

**Goal:** Present results to user and update the exploration memory.

#### Step E.1: Update memory file

Append to the Exploration Timeline table and **increment the iteration counter**:

Use the **doc_writer** sub-agent tool with these parameters:
- task: "Add new exploration entry to the timeline: Iteration ${ITERATION_NUM}, Iteration Folder: data_exploration_${EXPLORATION_NAME}_iteration_${ITERATION_NUM}, Phase: [DESCRIPTION], Output files: [LIST], Key findings: [SUMMARY]. Also update the 'Current State' sections. Also update the 'Next Iteration' counter in the header from ${ITERATION_NUM} to $((ITERATION_NUM + 1))."
- target_file: `coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}/memory.md`
- output_file: `coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}/memory_update_session.md`

```bash
cat coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}/memory_update_session.md
```

**CRITICAL:** Verify the **Next Iteration** counter was incremented:
```bash
# Must now show ITERATION_NUM + 1
grep "Next Iteration" coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}/memory.md
```

Also append to the User Decisions Log:

```markdown
| ${ITERATION_NUM} | [DATE] | [USER_REQUEST] | [ACTION_TAKEN] |
```

#### Step E.2: Present findings to user

**Format:**
```
## Iteration ${ITERATION_NUM} Results

### Analysis: [Title]

[Key findings — 3-5 bullet points]

### Output Files
- `data_exploration_output/${EXPLORATION_NAME}/[file].md` — [description]

### Notable Observations
- [Anything surprising or noteworthy]
```

---

### Step F: Loop Back

**Return to Step A** — Suggest new directions based on updated knowledge.

---

## DOCKER EXECUTION STRATEGY

### Decision Flow for Docker Setup

```
┌─────────────────────────────────────────────────────────────┐
│ Does docker/Dockerfile exist in project?                    │
└─────────────────────────────────────────────────────────────┘
         │
    ┌────┴────┐
    ▼         ▼
   NO        YES
    │         │
    ▼         ▼
 Create     Check USE_PACKAGE_DOCKER
 dedicated  environment variable
 Dockerfile        │
    │         ┌────┴────┐
    │         ▼         ▼
    │       true      false (or unset)
    │         │         │
    │         ▼         ▼
    │      Extend     Create
    │      existing   dedicated
    │      Dockerfile Dockerfile
    │         │         │
    └─────────┴─────────┘
              │
              ▼
     Generate build.sh + run.sh
     Build image, verify container
```

### Dedicated Dockerfile (default path)

When creating a dedicated Dockerfile, it should:
1. Be based on `python:3.12-slim`
2. Install data science dependencies (pandas, numpy, matplotlib, pyarrow, etc.)
3. Install any project-specific dependencies found in existing `requirements.txt`
4. Set `WORKDIR /workspace`
5. Allow interactive shell access (`CMD ["/bin/bash"]`)
6. Mount the project directory as a volume

### Extended Dockerfile (USE_PACKAGE_DOCKER=true)

When extending the existing project Dockerfile:
1. Read existing `docker/Dockerfile` to understand base setup
2. Add any missing data exploration dependencies
3. Ensure the exploration code directory is accessible
4. Preserve all existing functionality

### Generated Interface Scripts

#### build.sh
```bash
#!/bin/bash
# Build the data exploration Docker image
docker build -t "data-exploration-${EXPLORATION_NAME}:latest" \
    -f docker/data_exploration_${EXPLORATION_NAME}/Dockerfile .
```

#### run.sh
```bash
#!/bin/bash
# Run data exploration container
# Usage: ./run.sh [shell|process|daemon]
MODE="${1:-shell}"
case "$MODE" in
    shell)   docker run -it --rm -v "$(pwd):/workspace" ... /bin/bash ;;
    process) docker run --rm -v "$(pwd):/workspace" ... python run_exploration.py ;;
    daemon)  docker run -d -v "$(pwd):/workspace" ... tail -f /dev/null ;;
esac
```

---

## MEMORY FILE FORMAT

The memory file is the **single source of truth** for exploration state. It must always contain:

1. **Header:** Status, dates, data sources, **Next Iteration counter**
2. **Docker Execution Commands:** Table of EXACT commands for running code in Docker — the agent MUST consult this section before every execution and MUST NOT run Python outside Docker
3. **Exploration Timeline:** Ordered table of every exploration step taken (including iteration folder name)
4. **Current State:** What is known, what hasn't been explored
5. **Active Analysis Files:** Map of all code and output files
6. **User Decisions Log:** Record of every user choice

The **Docker Execution Commands** section is critical — it serves as the persistent reminder
of HOW to execute code. On every session resume, the agent reads this section first and uses
ONLY the listed commands. This prevents the agent from "forgetting" the Docker requirement
across session boundaries.

The **Next Iteration** counter in the header is critical — it tells the agent which iteration
number to use for the next implementation cycle. It starts at `1` after Phase 1 (which uses
iteration `0`) and is incremented by `1` after every Phase 2 cycle completes.

This file is what enables the agent to resume after interruption. It must be updated after EVERY exploration iteration.

---

## BACKWARDS COMPATIBILITY PROTOCOL

> **RULE:** Every execution of `run_exploration.py` must produce ALL previously generated outputs unless the user explicitly requests removal.

### How to maintain backwards compatibility:

1. **Additive code changes only:** New analysis functions are ADDED, never replace existing ones
2. **Output registry:** The `run_exploration.py` main function calls each analysis in sequence
3. **Removal by request only:** If the user says "remove the outlier analysis", then:
   - Remove the analysis function call from the main sequence
   - Log the removal in the memory file User Decisions Log
   - Do NOT delete the old output file (let the user decide)

### Verification after each iteration:

```bash
# List expected outputs from memory file
EXPECTED_FILES=$(grep -oP '`data_exploration_output/[^`]+`' \
    coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}/memory.md)

# Verify each exists after execution
for f in $EXPECTED_FILES; do
    if [ ! -f "$f" ]; then
        echo "BACKWARDS COMPATIBILITY VIOLATION: Missing $f"
    fi
done
```

---

## EXIT CRITERIA

### For Phase 1 (Initial Exploration)
| Criterion | Validation |
|-----------|------------|
| Docker environment ready | Container builds and runs |
| Docker commands in memory | `memory.md` contains `## Docker Execution Commands` section |
| Iteration 0 folder created | `coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}_iteration_0/` exists with requirements.md, design.md, progress.md |
| architecture_design.md followed | Agent read (`cat`) and executed every step of `coding_agent_context/missions/architecture_design.md` for iteration 0 |
| implement_tdd.md followed | Agent read (`cat`) and executed every step of `coding_agent_context/missions/implement_tdd.md` for iteration 0 |
| Code implemented via TDD | Tests pass for all initial analysis |
| Initial outputs generated via Docker | INDEX.md + per-source structure files exist (produced by `data_explorer.sh`, NOT host Python) |
| Memory file created | `memory.md` has initial timeline entry and `Next Iteration: 1` |
| Interactive mode entered | Suggestions presented to user |

### For Each Iteration (Phase 2)
| Criterion | Validation |
|-----------|------------|
| Docker ready before execution | `docker_manager.sh --action status` confirms image exists |
| Iteration folder created | `coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}_iteration_${N}/` exists with requirements.md, design.md, progress.md |
| architecture_design.md followed | Agent read (`cat`) and executed every step of `coding_agent_context/missions/architecture_design.md` for iteration N |
| implement_tdd.md followed | Agent read (`cat`) and executed every step of `coding_agent_context/missions/implement_tdd.md` for iteration N |
| Code extends existing | New analysis added without breaking old |
| Tests pass | All tests (new + existing) pass |
| Outputs generated via Docker | New markdown files produced by `data_explorer.sh` (NOT host Python) |
| Backwards compatible | All previous outputs still generated |
| Memory updated | Timeline includes iteration folder reference, Next Iteration counter incremented |

### For Session End (User says 'stop')
| Criterion | Validation |
|-----------|------------|
| Memory file finalized | Status set to PAUSED, timeline complete |
| All outputs present | Every analysis file from all iterations exists |
| Reproducible | Running `run_exploration.py` regenerates all outputs |

---

## LOOP SUMMARY

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 🚫 DOCKER-ONLY EXECUTION: ALL Python/data processing runs in Docker.       │
│    NEVER run exploration code directly on the host.                          │
├─────────────────────────────────────────────────────────────────────────────┤
│ 🔗 STRICT MISSION RE-USE: Implementation phases delegate to external        │
│    mission files. The agent MUST `cat` and follow them — never paraphrase.  │
│    • coding_agent_context/missions/architecture_design.md                   │
│    • coding_agent_context/missions/implement_tdd.md                         │
├─────────────────────────────────────────────────────────────────────────────┤
│ PHASE 0: RESUME CHECK                                                       │
│   memory.md exists? → NO: Phase 1 | YES: Load history, Phase 2              │
│   If resuming: verify Docker ready (docker_manager.sh --action status)      │
│                read "Docker Execution Commands" from memory.md              │
├─────────────────────────────────────────────────────────────────────────────┤
│ PHASE 1: INITIAL EXPLORATION (RUN ONCE, ITERATION 0)                        │
│   1. docker_manager.sh setup  ← MUST complete before ANY code execution     │
│   2. mkdir specs/data_exploration_${NAME}_iteration_0/                       │
│   3. Create requirements.md in iteration_0 folder                           │
│   4. export FEATURE=...iteration_0                                          │
│      cat coding_agent_context/missions/architecture_design.md → follow it   │
│      cat coding_agent_context/missions/implement_tdd.md → follow it         │
│   5. data_explorer.sh run → initial markdown reports (Docker execution)     │
│   6. Create memory.md WITH Docker Execution Commands section                │
│   7. Present findings → Enter Phase 2                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│ PHASE 2: INTERACTIVE LOOP (REPEAT UNTIL USER STOPS)                         │
│   A. SUGGEST:   3-5 next directions based on memory + outputs               │
│   B. WAIT:      User feedback (select / custom / stop)                      │
│   C. IMPLEMENT:                                                             │
│      C.1 Read Next Iteration counter N from memory.md                       │
│      C.2 mkdir specs/data_exploration_${NAME}_iteration_${N}/               │
│      C.3 Create requirements.md in iteration_${N} folder                    │
│      C.4 export FEATURE=...iteration_${N}                                   │
│          cat coding_agent_context/missions/architecture_design.md → follow   │
│      C.5 cat coding_agent_context/missions/implement_tdd.md → follow it     │
│   D. EXECUTE:   data_explorer.sh run (Docker ONLY, verify backwards compat) │
│   E. REPORT:    Present findings, update memory.md, increment Next Iteration│
│   F. LOOP:      → back to A                                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## QUICK START

```bash
# 1. Set the exploration name
export EXPLORATION_NAME="my_analysis"

# 2. Create the exploration brief (the agent's input file)
mkdir -p coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}
cat > coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}/exploration.md << 'EOF'
# Data Exploration Brief: my_analysis

## Data Sources
- `s3://my-bucket/path/to/data.csv` — CSV, ~8 GB, transaction records
- `local_data/features.parquet` — Parquet, ~500 MB, feature matrix

## Environment & Credentials
| Variable / Setting | Value | Description |
|--------------------|-------|-------------|
| `AWS_PROFILE` | `spascience` | AWS profile for S3 access |
| `AWS_DEFAULT_REGION` | `us-west-2` | AWS region |

## Context
This dataset powers the SHERPA seller-risk model. We want to understand
feature distributions and data quality before the next retraining cycle.

## Initial Questions
- What is the class distribution across the 7 risk categories?
- Are there columns with >50% missing values?
- Which features have the highest variance?

## Docker Preferences
| Setting | Value | Notes |
|---------|-------|-------|
| `USE_PACKAGE_DOCKER` | `false` | Create a dedicated exploration Dockerfile |
| Extra pip packages | | None beyond defaults |
| GPU required | `false` | |
EOF

# 3. Run this mission via agent-manager
agent-manager coding_agent_context/missions/data_exploration.md
```
