# Claude Code Agents

Specialized AI agents for [Claude Code](https://code.claude.com) — the CLI tool from Anthropic.

Each agent is a Markdown file with YAML frontmatter that defines a focused subagent with its own system prompt, tool access, model selection, and optional persistent memory.

## Installation

### Option 1: Project-Level (recommended for teams)
Copy agents into your project's `.claude/agents/` directory:

```bash
# From your project root
mkdir -p .claude/agents/languages .claude/agents/specialized

# Copy core agents
cp /path/to/goose-recipes/claude/agents/*.md .claude/agents/

# Copy language experts
cp /path/to/goose-recipes/claude/agents/languages/*.md .claude/agents/languages/

# Copy specialized agents
cp /path/to/goose-recipes/claude/agents/specialized/*.md .claude/agents/specialized/
```

Then commit `.claude/agents/` to version control — your team gets the agents automatically.

### Option 2: User-Level (personal, all projects)
Copy to `~/.claude/agents/` for availability across all projects:

```bash
mkdir -p ~/.claude/agents/languages ~/.claude/agents/specialized
cp claude/agents/*.md ~/.claude/agents/
cp claude/agents/languages/*.md ~/.claude/agents/languages/
cp claude/agents/specialized/*.md ~/.claude/agents/specialized/
```

### Option 3: One-Shot via CLI
Use inline JSON for a single session:

```bash
claude --agents '{
  "code-reviewer": {
    "description": "Expert code reviewer. Use proactively after code changes.",
    "prompt": "You are a senior code reviewer...",
    "tools": ["Read", "Grep", "Glob", "Bash"],
    "model": "sonnet"
  }
}'
```

## Usage

### Automatic Delegation
Claude automatically delegates based on agent descriptions:
```
Review the auth module for security issues
→ Claude delegates to security-auditor agent

Debug this failing test
→ Claude delegates to debugger agent
```

### Explicit Invocation
```
Use the code-reviewer agent to check my recent changes
Have the python-expert agent refactor this module
Use the ai-researcher agent to find the best recommendation algorithm
```

### Managing Agents
```bash
# List all agents (interactive)
/agents

# List agents (CLI)
claude agents
```

## Agent Catalog

### Core Agents
| Agent | Model | Tools | Memory | Description |
|-------|-------|-------|--------|-------------|
| `code-reviewer` | Sonnet | Read-only | Project | Code review for quality, security, performance |
| `debugger` | Inherit | All | Project | Scientific debugging: observe → hypothesize → test → fix |
| `security-auditor` | Sonnet | Read + Bash | Project | OWASP Top 10, secret detection, CVE scanning |
| `performance-optimizer` | Inherit | All | Project | Measure → analyze → optimize → validate |
| `documentation-agent` | Inherit | All | — | API docs, READMEs, architecture diagrams, changelogs |
| `api-designer` | Sonnet | All | — | REST/GraphQL/gRPC design with OpenAPI generation |
| `dependency-auditor` | Haiku | Read + Bash | — | Vulnerability, license, unused, size analysis |
| `project-bootstrapper` | Sonnet | All | — | Scaffold new projects with TDD, CI/CD, Docker |

### Language Experts
| Agent | Description |
|-------|-------------|
| `python-expert` | Modern Python 3.10+, type hints, pytest, FastAPI/Django/PyTorch |
| `flutter-expert` | Dart 3.x, Riverpod, go_router, clean architecture, widget testing |
| `rust-expert` | Ownership, lifetimes, tokio async, thiserror/anyhow, proptest |
| `postgresql-expert` | Schema design, query optimization, RLS, partitioning, monitoring |
| `bash-expert` | Defensive scripting, CI/CD pipelines, bats-core testing |

### Specialized Agents
| Agent | Model | Description |
|-------|-------|-------------|
| `ai-researcher` | Opus | Literature review, ML solution design, tradeoff analysis, MLflow |
| `ux-designer` | Sonnet | Journey mapping, wireframes, design systems, WCAG 2.2 audit |

## Key Differences from Goose Recipes

| Feature | Goose Recipe (YAML) | Claude Code Agent (Markdown) |
|---------|--------------------|-----------------------------|
| Parameters | Explicit typed params | Natural language in prompt |
| Sub-delegation | `sub_recipes:` | Can't spawn subagents; chain via main conversation |
| Retry/validation | `retry:` block with checks | `hooks:` with PreToolUse/PostToolUse |
| Tool control | `extensions:` | `tools:` allowlist / `disallowedTools:` denylist |
| Memory | None | `memory: user/project/local` — persistent cross-session |
| Background | N/A | `background: true` for concurrent work |
| Model | `settings.temperature` | `model: sonnet/opus/haiku/inherit` |
