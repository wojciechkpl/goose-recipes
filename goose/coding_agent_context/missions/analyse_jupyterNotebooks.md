# MISSION: Analyse Jupyter Notebooks

> **Type:** Analysis & Documentation | **Scope:** Jupyter Notebooks + Surrounding Files | **Phases:** Convert → Analyse Notebooks → Analyse Remaining Files

---

## OBJECTIVE

Analyse the Jupyter notebooks matching `Model Training *.ipynb` and all other files in the same folder. Produce detailed walkthrough documents with code pointer references.

**Output Location:** `coding_agent_context/specs/notebook_analysis/`

**Deliverables:**
- One detailed walkthrough document per notebook
- One summary document cataloguing all remaining (non-notebook) files
- A master index linking all produced documents

---

## OVERVIEW

This mission has **three phases** that run sequentially:

```
┌─────────────────────────────────────────────────────────────┐
│ PHASE 1: CONVERT NOTEBOOKS                                  │
│ ─────────────────────────────────────────────────────────── │
│ • Identify all target notebooks (Model Training *.ipynb)    │
│ • Convert each to a .py script via nbconvert                │
│ Output: .py files alongside original notebooks              │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ PHASE 2: ANALYSE NOTEBOOKS                                  │
│ ─────────────────────────────────────────────────────────── │
│ • Deep-dive analysis of each converted notebook             │
│ • Produce detailed walkthrough docs with code pointers      │
│ • Document packages used & cross-references                 │
│ Output: coding_agent_context/specs/notebook_analysis/       │
│         <NotebookName>_walkthrough.md (one per notebook)    │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ PHASE 3: CATALOGUE REMAINING FILES                          │
│ ─────────────────────────────────────────────────────────── │
│ • Identify all files NOT covered by Phase 2                 │
│ • For each, write a 3-4 sentence purpose/origin description │
│ • Produce a single remaining_files.md summary               │
│ Output: coding_agent_context/specs/notebook_analysis/       │
│         remaining_files.md                                  │
└─────────────────────────────────────────────────────────────┘
```

---

If a plan.md already exist pick up the work where it has been left during the last run. Don't start all over from the beginning again.

## PHASE 1: CONVERT NOTEBOOKS

### Step 1.1: Identify Target Notebooks

**Goal:** Find all Jupyter notebooks that match the `Model Training *.ipynb` pattern and understand the folder structure.

```bash
# Navigate to the folder containing the notebooks
ls -la

# Find all matching notebooks
find . -maxdepth 1 -name "Model Training *.ipynb" -type f | sort

# List ALL files in the folder for later reference (Phase 3)
ls -la | tee all_files_listing.txt
```

**Record the results:** Note down every matching notebook filename. These are the targets for Phase 2.

---

### Step 1.2: Convert Notebooks to Python Scripts

**Goal:** Convert each `.ipynb` to a `.py` file so the code is easier to analyse as plain text.

```bash
# Convert each notebook
# Repeat for every notebook identified in Step 1.1

jupyter nbconvert --to python "Model Training <NAME>.ipynb"

# Verify conversion succeeded
ls -la "Model Training <NAME>.py"
```

**For batch conversion (if many notebooks):**

```bash
# Convert all matching notebooks at once
for nb in Model\ Training\ *.ipynb; do
    echo "Converting: $nb"
    jupyter nbconvert --to python "$nb"
done

# Verify all conversions
ls -la Model\ Training\ *.py
```

---

### Phase 1 Exit Criteria

| Criterion | Validation |
|-----------|------------|
| All notebooks identified | Complete list of `Model Training *.ipynb` files |
| All converted | A `.py` file exists for each `.ipynb` |
| No conversion errors | `jupyter nbconvert` exited successfully for each |

---

## PHASE 2: ANALYSE NOTEBOOKS

> **Prerequisite:** Phase 1 complete — all `.py` conversions exist

### Step 2.1: Create Output Directory & Plan

**Goal:** Prepare the output location and create a tracking checklist.

```bash
# Create output directory
mkdir -p coding_agent_context/specs/notebook_analysis

# Create a plan/checklist from the identified notebooks
cat > coding_agent_context/specs/notebook_analysis/plan.md << 'EOF'
# Notebook Analysis Plan

## Notebooks to Analyse

### Walkthrough Documents
- [ ] `<NotebookName1>_walkthrough.md`
- [ ] `<NotebookName2>_walkthrough.md`
- [ ] ... (one entry per notebook)

### Remaining Files Summary
- [ ] `remaining_files.md`

### Master Index
- [ ] `INDEX.md`
EOF

# Verify
cat coding_agent_context/specs/notebook_analysis/plan.md
```

---

### Step 2.2: Analyse Each Notebook (Loop)

> **Repeat for each unchecked `[ ]` notebook in the plan**

#### 2.2.1: Read and Understand the Notebook

```bash
# Read the converted Python script
cat "Model Training <NAME>.py"

# Also open the original notebook for markdown/narrative cells
# (The .py conversion loses markdown cells — check the original for context)
cat "Model Training <NAME>.ipynb" | python3 -c "
import sys, json
nb = json.load(sys.stdin)
for cell in nb['cells']:
    if cell['cell_type'] == 'markdown':
        print('--- MARKDOWN CELL ---')
        print(''.join(cell['source']))
        print()
" 2>/dev/null || echo "Fallback: inspect .ipynb directly"
```

#### 2.2.2: Perform Deep Analysis (Analyst)

Use the **analyst** sub-agent tool with these parameters:
- focus: "Provide a detailed analysis of this Jupyter notebook converted to Python: 1. High-level purpose — what is this notebook trying to achieve? 2. Step-by-step walkthrough — explain each logical section/cell group 3. Python packages used — list every import with a brief description of why it is used 4. Data inputs — what data does it load, from where? 5. Model/algorithm details — what model(s) are trained, with what parameters? 6. Outputs — what does it produce (models, plots, metrics, files)? 7. Cross-references — identify any calls, imports, or references to OTHER files in this folder 8. Key code pointers — reference specific line numbers or function names for each section"
- read_files: `Model Training <NAME>.py`
- output_file: `coding_agent_context/specs/notebook_analysis/${NOTEBOOK_NAME}_analysis.md`

```bash
cat coding_agent_context/specs/notebook_analysis/${NOTEBOOK_NAME}_analysis.md
```

#### 2.2.3: Write the Walkthrough Document (Doc Writer)

Use the **doc_writer** sub-agent tool with these parameters:
- task: "Create a detailed walkthrough document for this notebook. Include: Title and one-paragraph summary, Table of Contents, Step-by-step walkthrough with code pointers (file:line references), Section: Python Packages Used (table: package | purpose), Section: Data Inputs & Outputs, Section: Model / Algorithm Details, Section: Cross-References to Other Files in This Folder, Section: Key Observations & Notes"
- target_file: `coding_agent_context/specs/notebook_analysis/${NOTEBOOK_NAME}_walkthrough.md`
- read_files: `coding_agent_context/specs/notebook_analysis/${NOTEBOOK_NAME}_analysis.md`
- output_file: `coding_agent_context/specs/notebook_analysis/${NOTEBOOK_NAME}_doc_session.md`

```bash
cat coding_agent_context/specs/notebook_analysis/${NOTEBOOK_NAME}_doc_session.md
cat coding_agent_context/specs/notebook_analysis/${NOTEBOOK_NAME}_walkthrough.md
```

**Expected Walkthrough Structure:**

```markdown
# Walkthrough: Model Training <NAME>

## Summary
One-paragraph description of what this notebook does.

## Table of Contents
1. [Setup & Imports](#setup--imports)
2. [Data Loading](#data-loading)
3. ...

## Step-by-Step Walkthrough

### 1. Setup & Imports
**Lines:** 1–25 in `Model Training <NAME>.py`

Description of what is set up...

### 2. Data Loading
**Lines:** 26–48 in `Model Training <NAME>.py`

Description of data loading logic...

...

## Python Packages Used

| Package | Version (if pinned) | Purpose |
|---------|-------------------|---------|
| pandas | — | Data manipulation and loading |
| scikit-learn | — | Model training and evaluation |
| ... | | |

## Data Inputs & Outputs

| Direction | Name | Format | Description |
|-----------|------|--------|-------------|
| Input | training_data.csv | CSV | Training dataset with features X, Y |
| Output | model.pkl | Pickle | Trained model artifact |
| ... | | | |

## Model / Algorithm Details
- Algorithm: ...
- Hyperparameters: ...
- Training approach: ...

## Cross-References to Other Files

| Referenced File | How It Is Used | Line(s) |
|-----------------|---------------|---------|
| utils.py | Imported for `clean_data()` | 12 |
| config.json | Loaded for hyperparameters | 34 |
| ... | | |

## Key Observations & Notes
- ...
```

#### 2.2.4: Mark Complete in Plan

```bash
sed -i 's/\[ \] `'${NOTEBOOK_NAME}'_walkthrough.md`/[x] `'${NOTEBOOK_NAME}'_walkthrough.md`/' \
    coding_agent_context/specs/notebook_analysis/plan.md
```

---

### Phase 2 Exit Criteria

| Criterion | Validation |
|-----------|------------|
| All walkthroughs created | One `*_walkthrough.md` per notebook |
| Code pointers included | Each walkthrough references specific lines/functions |
| Packages documented | Every import listed with purpose |
| Cross-references captured | References to other folder files identified |
| Plan updated | All notebook items in plan.md marked `[x]` |

---

## PHASE 3: CATALOGUE REMAINING FILES

> **Prerequisite:** Phase 2 complete — all notebook walkthroughs exist

### Step 3.1: Identify Remaining Files

**Goal:** List every file in the folder that was **not** part of the notebook analysis.

```bash
# List all files in the folder
ls -la

# Exclude: the .ipynb notebooks, their .py conversions, and any temp/analysis files
# The remaining files are the targets for this phase
```

Build a list of files to catalogue. This includes (but is not limited to):
- Standalone `.py` scripts
- Data files (`.csv`, `.json`, `.parquet`, etc.)
- Configuration files (`.yaml`, `.json`, `.cfg`, etc.)
- Model artifacts (`.pkl`, `.h5`, `.pt`, etc.)
- Documentation or README files
- Any other files present

---

### Step 3.2: Analyse Each Remaining File

**Goal:** For each file, write a 3–4 sentence description of its most likely purpose or origin.

```bash
# For code files — read and summarise
cat <filename>

# For binary/data files — inspect metadata
file <filename>
wc -l <filename> 2>/dev/null
head -5 <filename> 2>/dev/null
```

**Guiding questions for each file:**
- What does this file contain?
- Is it generated output, manual input, or a utility?
- Does it relate to a specific notebook? Which one?
- What is its role in the overall workflow?

---

### Step 3.3: Write the Remaining Files Document

Use the **doc_writer** sub-agent tool with these parameters:
- task: "Create a catalogue of non-notebook files. For each file provide: Filename, File type/format, 3-4 sentence description of purpose or origin. Format as a table or a series of short entries."
- target_file: `coding_agent_context/specs/notebook_analysis/remaining_files.md`
- output_file: `coding_agent_context/specs/notebook_analysis/remaining_files_session.md`

```bash
cat coding_agent_context/specs/notebook_analysis/remaining_files_session.md
cat coding_agent_context/specs/notebook_analysis/remaining_files.md
```

**Expected remaining_files.md Structure:**

```markdown
# Remaining Files in Notebook Folder

## Overview
This document catalogues all files in the folder that are not
`Model Training *.ipynb` notebooks.

## File Catalogue

### `utils.py`
**Type:** Python script
This utility module provides helper functions for data cleaning and
feature engineering. It is imported by several of the Model Training
notebooks (see cross-references). Key functions include `clean_data()`
and `generate_features()`.

### `config.json`
**Type:** JSON configuration
This configuration file stores hyperparameter settings used across
multiple training notebooks. It appears to be manually maintained and
is loaded at the start of each training run. The structure maps model
names to their respective parameter dictionaries.

### `training_data.csv`
**Type:** CSV data file
This is the primary training dataset used by the notebooks. It contains
N rows and M columns representing [features]. It is likely generated
by an upstream ETL process or exported from a database.

...
```

### Step 3.4: Mark Complete in Plan

```bash
sed -i 's/\[ \] `remaining_files.md`/[x] `remaining_files.md`/' \
    coding_agent_context/specs/notebook_analysis/plan.md
```

---

### Phase 3 Exit Criteria

| Criterion | Validation |
|-----------|------------|
| All non-notebook files covered | Every file in the folder has an entry |
| Descriptions adequate | Each entry is 3–4 sentences with purpose/origin |
| Document created | `remaining_files.md` exists in output directory |
| Plan updated | `remaining_files.md` marked `[x]` in plan.md |

---

## FINALIZATION: CREATE MASTER INDEX

### Step 4.1: Create INDEX.md

Use the **doc_writer** sub-agent tool with these parameters:
- task: "Create a master index that: 1. Summarises the analysis mission and its scope, 2. Lists all walkthrough documents with one-line descriptions, 3. Links to remaining_files.md, 4. Provides a high-level overview diagram (Mermaid) of how the notebooks relate to each other and to supporting files"
- target_file: `coding_agent_context/specs/notebook_analysis/INDEX.md`
- read_files: `coding_agent_context/specs/notebook_analysis/*_walkthrough.md,coding_agent_context/specs/notebook_analysis/remaining_files.md`
- output_file: `coding_agent_context/specs/notebook_analysis/index_session.md`

```bash
cat coding_agent_context/specs/notebook_analysis/index_session.md
cat coding_agent_context/specs/notebook_analysis/INDEX.md
```

**Expected INDEX.md Structure:**

```markdown
# Notebook Analysis Index

## Overview
Summary of what was analysed and why.

## Notebook Walkthroughs

| Notebook | Walkthrough | Summary |
|----------|-------------|---------|
| Model Training A.ipynb | [Walkthrough](A_walkthrough.md) | Trains model X using ... |
| Model Training B.ipynb | [Walkthrough](B_walkthrough.md) | Fine-tunes model Y on ... |
| ... | | |

## Supporting Files
See [remaining_files.md](remaining_files.md) for a catalogue of all
non-notebook files in the folder.

## Relationship Diagram
[Mermaid diagram showing notebook → data / config / utility dependencies]
```

### Step 4.2: Mark INDEX Complete

```bash
sed -i 's/\[ \] `INDEX.md`/[x] `INDEX.md`/' \
    coding_agent_context/specs/notebook_analysis/plan.md
```

---

## EXECUTION LOOP SUMMARY

```
┌─────────────────────────────────────────────────────────────┐
│ PHASE 1: CONVERT                                            │
├─────────────────────────────────────────────────────────────┤
│ 1. IDENTIFY:  find all Model Training *.ipynb               │
│ 2. CONVERT:   jupyter nbconvert --to python for each        │
│ 3. VERIFY:    .py file exists for every .ipynb              │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ PHASE 2: ANALYSE NOTEBOOKS (for each notebook)              │
├─────────────────────────────────────────────────────────────┤
│ 1. READ:      cat the .py and inspect .ipynb markdown cells │
│ 2. ANALYSE:   analyst sub-agent for deep-dive               │
│ 3. WRITE:     doc_writer sub-agent to create *_walkthrough  │
│ 4. TRACK:     Mark [x] in plan.md                           │
│ 5. REPEAT:    Until all notebooks documented                │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ PHASE 3: CATALOGUE REMAINING FILES                          │
├─────────────────────────────────────────────────────────────┤
│ 1. IDENTIFY:  list files not covered by Phase 2             │
│ 2. INSPECT:   cat / file / head for each                    │
│ 3. WRITE:     doc_writer sub-agent for remaining_files.md   │
│ 4. TRACK:     Mark [x] in plan.md                           │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ FINALIZATION                                                │
├─────────────────────────────────────────────────────────────┤
│ 1. INDEX:     Create INDEX.md linking all documents         │
│ 2. VERIFY:    All items in plan.md marked [x]               │
└─────────────────────────────────────────────────────────────┘
```

---

## EXIT CRITERIA

| Criterion | Validation |
|-----------|------------|
| All notebooks converted | `.py` file for every `Model Training *.ipynb` |
| All walkthroughs created | One `*_walkthrough.md` per notebook in output dir |
| Walkthroughs detailed | Each contains code pointers, packages, cross-refs |
| Remaining files catalogued | `remaining_files.md` covers every non-notebook file |
| Remaining file entries adequate | Each entry is 3–4 sentences |
| INDEX exists | `INDEX.md` created with links and overview |
| Plan complete | All items in `plan.md` marked `[x]` |

---

## QUICK START

```bash
# Phase 1: Convert
for nb in Model\ Training\ *.ipynb; do
    jupyter nbconvert --to python "$nb"
done

# Phase 2: Analyse (follow steps 2.1 through 2.2 for each notebook)
cat coding_agent_context/specs/notebook_analysis/plan.md

# Phase 3: Catalogue remaining files (follow steps 3.1 through 3.4)
cat coding_agent_context/specs/notebook_analysis/remaining_files.md

# Verify completion
ls -la coding_agent_context/specs/notebook_analysis/
cat coding_agent_context/specs/notebook_analysis/INDEX.md
```
