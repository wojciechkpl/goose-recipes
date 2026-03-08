# Compile References Mission

Discover and catalog relevant sources for a research topic based on requirements.

---

## Configuration

```yaml
mission_type: compile_references
input: specs/research/<topic>/requirements.md
output: specs/research/<topic>/compiled_references.md
```

---

## Phase 1: Initialize

### Step 1.1: Load Requirements

```bash
# Read requirements file
cat ./admin_agent_context/specs/research/<topic>/requirements.md
```

**Expected requirements.md format:**
```yaml
# Reference Compilation Requirements

## Topic
topic: "Main research topic"
description: |
  Brief description of what you're researching and why.

## Search Configuration
search_topics:
  - "subtopic 1"
  - "subtopic 2"
  - "subtopic 3"

search_domains:
  internal: true                    # Search internal sources (wiki, builder hub, code)
  external:
    - arxiv.org
    - docs.aws.amazon.com
    - kubernetes.io
  enable_web_search: false          # Must be explicitly enabled

## Limits
max_references: 20                  # Maximum references to compile

## Seed Sources (Optional)
# Specific sources to include and expand from
seed_sources:
  - url: "https://quip-amazon.com/abc123"
    note: "Team design doc"
  - url: "https://w.amazon.com/wiki/SomePage"
    note: "Related wiki"

## Exclusions (Optional)
exclude_patterns:
  - "*.test.*"
  - "deprecated"
```

### Step 1.2: Create Progress Tracking

```bash
mkdir -p ./admin_agent_context/specs/research/<topic>/progress
```

Write initial state to `progress/compiler_state.md`:
```markdown
## Compile References Progress

### Status
phase: searching
started: <timestamp>

### Search Progress
- [ ] Internal wiki search
- [ ] Internal code search
- [ ] Seed source expansion
- [ ] External domain searches

### References Found
total: 0
scored: 0
```

---

## Phase 2: Internal Search

### Step 2.1: Search Internal Sources

If `search_domains.internal: true`:

1. **Wiki Search** (InternalSearch with domain WIKI):
   - Search for each topic in search_topics
   - Collect URLs and titles

2. **Builder Hub Search** (InternalSearch with domain BUILDER_HUB):
   - Search for technical documentation

3. **Code Search** (InternalCodeSearch):
   - Search for relevant code examples
   - Look for README files, design docs in repos

4. **Sage Search** (InternalSearch with domain SAGE_HORDE):
   - Find Q&A related to topics

### Step 2.2: Checkpoint
Update `progress/compiler_state.md` after each search type.

---

## Phase 3: Seed Source Expansion

### Step 3.1: Process Seed Sources

For each source in `seed_sources`:

1. Fetch the source using appropriate tool
2. Extract outbound references
3. Add to candidate list with note: "Found in seed: <source>"

### Step 3.2: Checkpoint
Update progress with seed expansion status.

---

## Phase 4: External Search

### Step 4.1: Search External Domains

For each domain in `search_domains.external`:

**arxiv.org**:
- Search arxiv for academic papers
- Extract: title, authors, abstract URL, PDF URL

**docs.aws.amazon.com**:
- Search AWS documentation
- Focus on service guides, best practices

**Other domains**:
- Use ReadInternalWebsites where possible
- Collect relevant pages

### Step 4.2: Web Search (If Enabled)

Only if `enable_web_search: true`:
- Use general search for topics
- Filter to reputable sources

### Step 4.3: Checkpoint
Update progress after external searches.

---

## Phase 5: Score and Rank

### Step 5.1: Apply Scoring

For each candidate reference:

| Factor | Score |
|--------|-------|
| Direct topic keyword match | +3 |
| Multiple topic matches | +1 per additional |
| Authoritative source (official docs) | +2 |
| Recent (< 1 year) | +2 |
| Internal source | +1 |
| From seed source | +1 |
| Mentioned in multiple searches | +1 per mention |

### Step 5.2: Apply Exclusions

Remove references matching `exclude_patterns`.

### Step 5.3: Rank and Trim

1. Sort by score descending
2. Keep top `max_references` items
3. Ensure diversity (not all from same domain)

---

## Phase 6: Generate Output

### Step 6.1: Write Compiled References

Write to `compiled_references.md`:

```markdown
# Compiled References

**Topic**: <topic>
**Compiled**: <timestamp>
**Total References**: <count>

---

## Summary

Brief summary of what was found and where.

---

## References

### High Relevance (Score 8+)

1. **Title of Reference**
   - URL: <url>
   - Type: wiki | quip | code | arxiv | aws_docs | external
   - Score: X
   - Topics: topic1, topic2
   - Notes: <any notes>

2. ...

### Medium Relevance (Score 5-7)

1. ...

### Additional Sources (Score < 5)

1. ...

---

## Search Summary

| Source | Searched | Results |
|--------|----------|---------|
| Internal Wiki | Yes | 12 |
| Builder Hub | Yes | 5 |
| Code Search | Yes | 8 |
| arxiv.org | Yes | 6 |
| ... | ... | ... |

---

## Excluded

References excluded by pattern matching:
- <url> (matched: <pattern>)
```

### Step 6.2: Generate Requirements Template

Write to `requirements_template.md` (for research_report mission):

```yaml
# Research Report Requirements
# Generated from compile_references on <timestamp>

## Report Configuration
topic: "<topic>"
audience:
  primary: technical_ic    # self, technical_ic, technical_management, non_technical_management
  secondary: null
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

## Sources (from compiled references)
sources:
  # High Relevance
  - url: "<url1>"
  - url: "<url2>"
  # ... include all compiled references

## Story and Focus
storyline: |
  # TODO: Describe the narrative arc of your report

deep_dive_topics:
  # TODO: Specify topics for detailed analysis
  - "Topic 1"
  - "Topic 2"
```

### Step 6.3: Final Checkpoint

Update `progress/compiler_state.md`:
```markdown
## Status
phase: complete
completed: <timestamp>

## Output
- compiled_references.md: <count> references
- requirements_template.md: generated
```

---

## Exit Criteria

- [ ] All configured searches completed
- [ ] References scored and ranked
- [ ] `compiled_references.md` written
- [ ] `requirements_template.md` generated
- [ ] Progress shows complete status

---

## Output Files

| File | Purpose |
|------|---------|
| `compiled_references.md` | Scored and ranked reference list |
| `requirements_template.md` | Template for research_report mission |
| `progress/compiler_state.md` | Compilation progress and status |
