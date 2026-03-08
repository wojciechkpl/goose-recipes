# Admin Agent - Framework Overview

Understanding the architecture and design of the Research Agent.

---

## Purpose

The Research Agent is a framework for conducting multi-source research and generating comprehensive reports. It coordinates specialized sub-agents for source investigation, reference compilation, and report writing.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              USER                                           │
│                                │                                            │
│                    ┌───────────┴───────────┐                                │
│                    ▼                       ▼                                │
│            ┌──────────────┐       ┌──────────────┐                          │
│            │   COMPILE    │       │   RESEARCH   │                          │
│            │  REFERENCES  │       │   REPORT     │                          │
│            └──────────────┘       └──────────────┘                          │
│                    │                       │                                │
│                    └───────────┬───────────┘                                │
│                                ▼                                            │
│                    ┌───────────────────────┐                                │
│                    │       RECIPES         │                                │
│                    │  (goose run --recipe) │                                │
│                    └───────────────────────┘                                │
│                                │                                            │
│              ┌─────────────────┼─────────────────┐                          │
│              ▼                 ▼                 ▼                          │
│     ┌─────────────┐   ┌─────────────┐   ┌─────────────┐                    │
│     │   MISSION   │   │    ROLES    │   │   MEMORY    │                    │
│     │  (defines   │   │ (sub-agents │   │ (source     │                    │
│     │  workflow)  │   │  personas)  │   │  access)    │                    │
│     └─────────────┘   └─────────────┘   └─────────────┘                    │
│                                │                                            │
│                                ▼                                            │
│                    ┌───────────────────────┐                                │
│                    │        OUTPUT         │                                │
│                    │ (references, reports) │                                │
│                    └───────────────────────┘                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Directory Structure

```
admin_agent_context/
├── CONVENTIONS.md              # Framework rules and constraints
│
├── missions/                   # Workflow definitions
│   ├── compile_references.md
│   └── research_report.md
│
├── roles/                      # Agent personas
│   ├── reference_compiler.md
│   ├── research_assistant.md
│   ├── research_orchestrator.md
│   ├── source_investigator.md
│   └── report_writer.md
│
├── recipes/                    # Goose execution configs
│   ├── mission_compile_references.yaml
│   ├── mission_research_report.yaml
│   └── roles/                  # Role recipes (sub-agent configs)
│       ├── reference_compiler.yaml
│       ├── report_writer.yaml
│       ├── research_assistant.yaml
│       └── source_investigator.yaml
│
├── specs/                      # Mission data and state
│   └── research/
│       ├── memory/             # Source access patterns
│       └── <topic>/            # Individual research projects
│
└── user_guides/                # Documentation
```

---

## Core Components

### Missions

Missions define **what** to accomplish and the workflow steps:

| Mission | Purpose |
|---------|---------|
| `compile_references` | Discover and catalog sources for a research topic |
| `research_report` | Generate comprehensive research report from compiled sources |

### Roles

Roles define **how** tasks are performed (agent personas):

| Role | Purpose |
|------|---------|
| `research_assistant` | Follow links and extract information |
| `reference_compiler` | Discover and catalog sources |
| `research_orchestrator` | Coordinate multi-source research |
| `source_investigator` | Examine individual sources in detail |
| `report_writer` | Synthesize research into polished reports |

### Recipes

Recipes are the **executable configurations** for goose:
- Define which extensions to enable
- Set parameters and prompts
- Reference missions and roles for context
- Configure settings like max_turns

### Memory

Memory persists knowledge across sessions:

| Memory Type | Location | Purpose |
|-------------|----------|---------|
| Source access | `specs/research/memory/` | How to access different URLs |
| Mission progress | `specs/research/<topic>/progress/` | Recovery checkpoints |

---

## Data Flow

### Compile References Flow

```
1. User creates requirements.md (topic, search domains, seed sources)
2. Reference compiler searches configured domains
3. Scores and ranks discovered references
4. Outputs:
   - compiled_references.md (scored reference list)
   - requirements_template.md (template for research_report mission)
```

### Research Report Flow

```
1. User creates/edits requirements.md (topic, audience, sources, structure)
2. Research orchestrator initializes reference queue
3. Phase 1: First-pass investigation
   └── Source investigators survey each source
4. Phase 2: Relevance evaluation
   └── Orchestrator scores and decides deep-dive vs skip
5. Phase 3: Deep-dive investigation
   └── Source investigators extract detailed content
6. Phase 4: Report generation
   └── Report writer synthesizes into final report
7. Output: report/final_report.md
```

### Sub-Agent Architecture (Research Report)

```
┌─────────────────────────────┐
│   Research Orchestrator      │ ← Mission recipe (main agent)
│   (mission_research_report)  │
└─────────┬───────────────────┘
          │
          ├── source_investigator  ← Sub-recipe tool (first-pass + deep-dive)
          │   (recipes/roles/source_investigator.yaml)
          │
          └── report_writer        ← Sub-recipe tool (final report)
              (recipes/roles/report_writer.yaml)
```

---

## Extension Points

### Adding a New Role

1. Create `roles/new_role.md`:
   - Define persona and constraints
   - Specify output format
   - Document capabilities

2. Create `recipes/roles/new_role.yaml`:
   - Configure for sub-agent dispatch

### Adding a New Source Type

1. Update `specs/research/memory/source_access.md`:
   - Add standard access pattern
   - Document tool to use

2. Update `roles/source_investigator.md`:
   - Add handling instructions

---

## Memory Systems

### Source Access Patterns
```markdown
### Wiki (w.amazon.com)
Tool: ReadInternalWebsites

### Quip (quip-amazon.com)
Tool: QuipEditor or ReadInternalWebsites

### URL-Specific Patterns
url: https://specific-service.amazon.com/api
Tool: ReadInternalWebsites
Notes: Use /v2/ path
```

### Research Progress
```markdown
## Current Phase
deep_dive_investigation

## Reference Queue Status
- Total: 32
- First-pass complete: 28
- Deep-dive complete: 12
- Pending: 4

## Last Checkpoint
2026-02-26 08:45:00
Source: https://quip-amazon.com/abc123
Action: deep_dive_complete
```

---

## Further Reading

- [Quick Start Guide](./01_quick_start.md) - Get running fast
- [Detailed Workflows](./02_detailed_workflows.md) - Advanced patterns
- [Troubleshooting](./03_troubleshooting.md) - Common issues
