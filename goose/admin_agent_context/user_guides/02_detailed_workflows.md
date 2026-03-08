# Admin Agent - Detailed Workflows Guide

Advanced patterns and workflows for power users.

---

## Table of Contents

1. [Research Workflows](#research-workflows)
2. [Automation Patterns](#automation-patterns)
3. [Troubleshooting](#troubleshooting)

---

## Research Workflows

### Full Research Pipeline

```bash
# Step 1: Compile references (discovery phase)
goose run --recipe ./admin_agent_context/recipes/mission_compile_references.yaml \
  --params run_dir="./admin_agent_context/specs/research/YYYYMMDD_topic"

# Step 2: Review and edit requirements
# The compile step creates: specs/research/YYYYMMDD_topic/requirements_template.md
export RUN_DIR="./admin_agent_context/specs/research/20260226_kubernetes_autoscaling"
mv "${RUN_DIR}/requirements_template.md" "${RUN_DIR}/requirements.md"
vim "${RUN_DIR}/requirements.md"
# - Set audience
# - Adjust sources
# - Add storyline
# - Define deep_dive_topics

# Step 3: Generate report
goose run --recipe ./admin_agent_context/recipes/mission_research_report.yaml \
  --params run_dir="${RUN_DIR}"
```

### Requirements.md Template

```yaml
# Research Report Requirements

## Report Configuration
topic: "Your Topic"
audience:
  primary: technical_ic    # self, technical_ic, technical_management, non_technical_management
  secondary: null          # Optional second audience for appendix
report_length_pages: 5
structure:
  - "Executive Summary"
  - "Background/Context"
  - "Key Findings"
  - "Deep Dives"
  - "Recommendations"
  - "References"

## Research Configuration
max_reference_depth: 3
max_total_sources: 50
default_max_sub_refs: 10

## Sources
sources:
  - url: "https://quip-amazon.com/abc123"
    max_depth: 1          # Override: only follow refs 1 level deep
    max_sub_refs: 5       # Override: max 5 sub-refs from this source
  - url: "https://w.amazon.com/wiki/SomePage"
    # Uses defaults
  - url: "/local/path/to/code"
    max_depth: 0          # Don't follow refs from code

## Story and Focus
storyline: |
  This report should establish the current state of X,
  compare approaches A vs B, and recommend a path forward.

deep_dive_topics:
  - "Performance comparison"
  - "Implementation complexity"
  - "Operational considerations"
```

### Research Recovery

If research is interrupted:

```bash
# Just re-run with the same RUN_DIR - it will resume
goose run --recipe ./admin_agent_context/recipes/mission_research_report.yaml \
  --params run_dir="${RUN_DIR}"
```

The orchestrator reads `progress/orchestrator_state.md` and continues from the last checkpoint.

### Research Output Structure

```
specs/research/20260226_topic/
├── requirements.md              # Your input
├── progress/
│   ├── orchestrator_state.md    # Current phase, for recovery
│   ├── reference_queue.md       # All sources with status
│   └── relevance_decisions.md   # Why sources included/excluded
├── sources/
│   ├── first_pass/              # Quick surveys of each source
│   │   ├── 001_source_name.md
│   │   └── ...
│   └── deep_dive/               # Detailed extractions
│       ├── 001_source_name.md
│       └── ...
└── report/
    ├── writing_brief.md         # Compilation for writer
    └── final_report.md          # Final output
```

---

## Automation Patterns

### Shell Aliases

Add to `~/.zshrc` or `~/.bashrc`:

```bash
# Research
alias research-compile='goose run --recipe ./admin_agent_context/recipes/mission_compile_references.yaml --params run_dir'
alias research-report='goose run --recipe ./admin_agent_context/recipes/mission_research_report.yaml --params run_dir'
```

Usage:
```bash
research-compile="./admin_agent_context/specs/research/20260226_distributed_systems"
research-report="./admin_agent_context/specs/research/20260226_distributed_systems"
```

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "Extension not found" | Check recipe has correct extension format |
| Research stuck | Check `progress/orchestrator_state.md` for phase |

### Reset Commands

```bash
# Reset research progress (start over)
rm -rf ./admin_agent_context/specs/research/<topic>/progress/
```

See [Troubleshooting Guide](./03_troubleshooting.md) for more details.
