# Admin Agent Context - User Guides

Welcome to the Research Agent framework documentation.

---

## Quick Navigation

| Guide | Description |
|-------|-------------|
| [01 Quick Start](./01_quick_start.md) | Get running in 3 minutes |
| [02 Detailed Workflows](./02_detailed_workflows.md) | Advanced patterns and tips |
| [03 Troubleshooting](./03_troubleshooting.md) | Common issues and solutions |
| [04 Framework Overview](./04_framework_overview.md) | Architecture and design |

---

## Standard Workflow Pattern

```bash
# For missions with input files:
export INPUT_FILE="/path/to/input"
goose run --recipe ./admin_agent_context/recipes/mission_<type>.yaml \
  --params <param>="${INPUT_FILE}"

# For missions without required params:
goose run --recipe ./admin_agent_context/recipes/mission_<type>.yaml
```

---

## Mission Quick Reference

### Research & Reports

| Mission | Recipe | Required Params | Description |
|---------|--------|-----------------|-------------|
| **Compile References** | `mission_compile_references.yaml` | `run_dir` | Discover sources for a research topic |
| **Research Report** | `mission_research_report.yaml` | `run_dir` | Generate report from compiled sources |

---

## Key Concepts

### Source Everything
All summaries include citations back to original:
- `[Source: <url>]` for external references
- `[Source: <file>]` for local files

### Directory Structure

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

## Quick Commands

### Research Workflow
```bash
# 1. Compile references (optional - can skip if you have sources)
goose run --recipe ./admin_agent_context/recipes/mission_compile_references.yaml \
  --params run_dir="./admin_agent_context/specs/research/YYYYMMDD_topic"

# 2. Create requirements (use generated template or create manually)
export TOPIC="your_topic"
mkdir -p ./admin_agent_context/specs/research/$(date +%Y%m%d)_${TOPIC}
vim ./admin_agent_context/specs/research/$(date +%Y%m%d)_${TOPIC}/requirements.md

# 3. Generate report
export RUN_DIR="./admin_agent_context/specs/research/YYYYMMDD_topic"
goose run --recipe ./admin_agent_context/recipes/mission_research_report.yaml \
  --params run_dir="${RUN_DIR}"
```

---

## Need Help?

- Check [Troubleshooting](./03_troubleshooting.md) for common issues
- See [Detailed Workflows](./02_detailed_workflows.md) for advanced patterns
- Read [Framework Overview](./04_framework_overview.md) to understand the architecture
