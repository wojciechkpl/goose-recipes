# Admin Agent Quick Start Guide

Get up and running with the Research Agent in 3 minutes.

---

## Available Missions

### Research & Reports
| Mission | Purpose |
|---------|---------|
| Compile References | Discover sources for a research topic |
| Research Report | Generate comprehensive report from sources |

---

## Workflow Pattern

All missions follow the same pattern:

```bash
# 1. Create mission directory
export FEATURE="<feature_name>"
export RUN_DIR="./admin_agent_context/specs/research/$(date +%Y%m%d)_${FEATURE}"
mkdir -p "${RUN_DIR}"

# 2. Create requirements file
vim "${RUN_DIR}/requirements.md"

# 3. Run the mission
goose run --recipe ./admin_agent_context/recipes/mission_<type>.yaml \
  --params run_dir="${RUN_DIR}"
```

---

## Quick Examples

### Compile References (Research)

```bash
# 1. Create a research directory
export TOPIC="kubernetes_autoscaling"
export RUN_DIR="./admin_agent_context/specs/research/$(date +%Y%m%d)_${TOPIC}"
mkdir -p "${RUN_DIR}"

# 2. Create requirements.md:
# ---
# topic: "Kubernetes Autoscaling Strategies"
# description: |
#   Research different autoscaling approaches for Kubernetes workloads.
#
# search_topics:
#   - "HPA horizontal pod autoscaler"
#   - "VPA vertical pod autoscaler"
#   - "cluster autoscaler"
#   - "KEDA event-driven autoscaling"
#
# search_domains:
#   internal: true
#   external:
#     - arxiv.org
#     - docs.aws.amazon.com
#     - kubernetes.io
#   enable_web_search: false
#
# max_references: 20
#
# seed_sources:
#   - url: "https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/"
#     note: "Official HPA docs"
#
# exclude_patterns:
#   - "deprecated"
# ---

# 3. Run compile references
goose run --recipe ./admin_agent_context/recipes/mission_compile_references.yaml \
  --params run_dir="${RUN_DIR}"
```

### Research Report

```bash
# 1. Create mission directory (or reuse from compile_references)
export TOPIC="kubernetes_autoscaling"
export RUN_DIR="./admin_agent_context/specs/research/$(date +%Y%m%d)_${TOPIC}"
mkdir -p "${RUN_DIR}"

# 2. Create or edit requirements.md:
#    (If you ran compile_references, use the generated requirements_template.md)
# ---
# topic: "Kubernetes Autoscaling Strategies"
# audience:
#   primary: technical_ic
#   secondary: null
# report_length_pages: 5
# structure:
#   - "Executive Summary"
#   - "Background/Context"
#   - "Key Findings"
#   - "Deep Dives"
#   - "Recommendations"
#   - "References"
#
# max_reference_depth: 3
# max_total_sources: 50
# default_max_sub_refs: 10
#
# sources:
#   - url: "https://kubernetes.io/docs/..."
#     note: "Official docs"
#
# storyline: |
#   Compare approaches and recommend for our use case.
#
# deep_dive_topics:
#   - "Performance comparison"
#   - "Implementation complexity"
# ---

# 3. Run research report
goose run --recipe ./admin_agent_context/recipes/mission_research_report.yaml \
  --params run_dir="${RUN_DIR}"
```

---

## File Structure

```
admin_agent_context/
├── specs/
│   └── research/
│       ├── memory/
│       │   └── source_access.md        # How to access sources
│       └── <topic_folders>/            # Individual research projects
│           ├── requirements.md         # Your input
│           ├── compiled_references.md  # From compile step
│           ├── progress/               # Checkpoints
│           ├── sources/                # Investigations
│           └── report/                 # Final output
├── missions/                           # Mission definitions
├── roles/                              # Role definitions
├── recipes/                            # Goose recipe files
└── user_guides/                        # This documentation
```

---

## Key Principles

1. **Everything sourced**: Citations link back to original documents
2. **Progress recoverable**: Interrupted missions can resume from checkpoints
3. **Requirements-driven**: All missions start from a requirements.md file

---

## Next Steps

- Read [Detailed Workflows](./02_detailed_workflows.md) for advanced patterns
- Check [Troubleshooting](./03_troubleshooting.md) if you hit issues
- See [Framework Overview](./04_framework_overview.md) to understand the architecture
