# Admin Agent - Troubleshooting Guide

Solutions for common issues with the Research Agent.

---

## Table of Contents

1. [Research Report Issues](#research-report-issues)
2. [Recipe Execution Issues](#recipe-execution-issues)
3. [Diagnostic Commands](#diagnostic-commands)
4. [Reset Procedures](#reset-procedures)

---

## Research Report Issues

### Research Stuck / Not Progressing

**Symptoms**: Agent seems stuck at a particular phase

**Solutions**:

1. **Check progress state**:
   ```bash
   cat ./admin_agent_context/specs/research/<topic>/progress/orchestrator_state.md
   ```

2. **Check reference queue**:
   ```bash
   cat ./admin_agent_context/specs/research/<topic>/progress/reference_queue.md
   # Look for sources stuck in "pending" or "in_progress"
   ```

3. **Resume from checkpoint**:
   ```bash
   # Just re-run - it will resume automatically
   goose run --recipe ./admin_agent_context/recipes/mission_research_report.yaml \
     --params run_dir="./admin_agent_context/specs/research/<topic>"
   ```

### Source Access Failures

**Symptoms**: Investigator can't access certain URLs

**Solutions**:

1. **Check source_access.md for known issues**:
   ```bash
   cat ./admin_agent_context/specs/research/memory/source_access.md
   ```

2. **Verify URL is accessible** manually in browser

3. **Check if authentication required** - some internal sites need VPN

### Report Quality Issues

**Symptoms**: Report missing content, wrong audience tone

**Solutions**:

1. **Check requirements.md** has correct audience and structure

2. **Review deep-dive outputs**:
   ```bash
   ls ./admin_agent_context/specs/research/<topic>/sources/deep_dive/
   # Review individual files for content quality
   ```

3. **Adjust storyline** in requirements.md for better focus

### Reference Limits Reached

**Symptoms**: Important sources being excluded

**Solutions**:

1. **Increase limits** in requirements.md:
   ```yaml
   max_total_sources: 75  # Increase from 50
   default_max_sub_refs: 15  # Increase from 10
   ```

2. **Check relevance decisions**:
   ```bash
   cat ./admin_agent_context/specs/research/<topic>/progress/relevance_decisions.md
   ```

---

## Recipe Execution Issues

### "Invalid recipe" Errors

**Common error patterns and solutions**:

| Error | Solution |
|-------|----------|
| `missing field 'title'` | Add `title: "Recipe Name"` to recipe |
| `missing field 'key'` | Parameters need `key:` not `name:` |
| `invalid type: map, expected sequence` | Parameters should be array `- key: x` not map |
| `invalid type: string, expected internally tagged enum` | Extensions need full format with `type: builtin` or `type: stdio` |

**Correct recipe format**:
```yaml
version: "1.0.0"
title: "Recipe Title"
description: |
  Description here

extensions:
  - type: builtin
    name: developer
    timeout: 300
    bundled: true
  - type: stdio
    name: builder-mcp
    cmd: builder-mcp
    args: []
    timeout: 600

parameters:
  - key: param_name
    input_type: string
    requirement: required
    description: "Parameter description"

prompt: |
  Your prompt with {{ param_name }}

settings:
  max_turns: 100
```

### Extension Not Starting

**Symptoms**: `Warning: Failed to start extension 'X'`

**Solutions**:

1. **Check extension type** matches your goose config:
   ```bash
   cat ~/.config/goose/config.yaml
   # See how the extension is defined (builtin vs stdio)
   ```

2. **Use correct format** in recipe:
   - `builtin` extensions: `type: builtin, name: developer`
   - `stdio` extensions: `type: stdio, name: builder-mcp, cmd: builder-mcp`

---

### Master Memory Corrupted

**Symptoms**: Source access patterns not working

**Solution**:
```bash
# Reset master memory
cat > ./admin_agent_context/specs/research/memory/source_access.md << 'EOF'
# Source Access Patterns
*Reset - patterns will be re-learned*
EOF
```

---

## Diagnostic Commands

### Check Directory Structure
```bash
# Research
find ./admin_agent_context/specs/research -type f | head -20
```

### Verify Recipe Files
```bash
# List all recipes
ls -la ./admin_agent_context/recipes/

# Check a specific recipe for YAML errors
python3 -c "import yaml; yaml.safe_load(open('./admin_agent_context/recipes/mission_research_report.yaml'))"
```

### View Recent Runs
```bash
# Research projects
ls -lt ./admin_agent_context/specs/research/ | head -5
```

---

## Reset Procedures

### Reset Research Progress
```bash
# Restart a specific research project
rm -rf ./admin_agent_context/specs/research/<topic>/progress/
rm -rf ./admin_agent_context/specs/research/<topic>/sources/

# Keep requirements.md, regenerate everything else
```

---

## Getting More Help

- Check [Detailed Workflows](./02_detailed_workflows.md) for correct usage patterns
- Review [Framework Overview](./04_framework_overview.md) to understand architecture
- Examine recipe files in `./admin_agent_context/recipes/` for configuration details
