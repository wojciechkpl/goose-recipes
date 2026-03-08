# Mission: Research Report

## Overview

Conduct comprehensive research on a topic using multiple sources, then generate a polished report tailored to a specific audience. This mission coordinates investigators to examine sources, decides relevance, and produces a final report.

---

## Configuration

```yaml
master_memory: ./admin_agent_context/specs/research/memory/source_access.md
mission_dir: {provided as run_dir parameter}
progress_dir: {mission_dir}/progress/
sources_dir: {mission_dir}/sources/
report_dir: {mission_dir}/report/
max_concurrent_investigators: 2
```

---

## Input: requirements.md Template

```yaml
# Research Report Requirements

## Report Configuration
topic: "Research topic title"
audience:
  primary: technical_ic  # Options: self, technical_ic, technical_management, non_technical_management
  secondary: null        # Optional second audience for appendix
report_length_pages: 5   # Target page count
structure:               # Report structure (defaults shown)
  - "Executive Summary"
  - "Background/Context"
  - "Key Findings"
  - "Deep Dives"
  - "Recommendations"
  - "References"

## Research Configuration
max_reference_depth: 3      # How deep to follow references (0 = original only)
max_total_sources: 50       # Maximum sources to investigate
default_max_sub_refs: 10    # Max sub-references per original source
min_first_pass_sources: 20  # Minimum sources to first-pass before relevance evaluation
                            # Ensures rich pool for deep-dive selection

## Sources
sources:
  - url: "https://example.com/doc1"
    max_depth: 1            # Override depth for this source (optional)
    max_sub_refs: 5         # Override sub-ref limit (optional)
  - url: "https://example.com/doc2"
    # Uses defaults
  - url: "/local/path/to/code"
    max_depth: 0            # Don't follow references from code

## Story and Focus (optional but recommended)
storyline: |
  This report should focus on...
  The narrative arc should...

deep_dive_topics:
  - "Specific topic to explore in depth"
  - "Another deep dive area"
```

---

## Audience Adaptation Reference

| Audience | Tone | Detail Level | Jargon | Focus |
|----------|------|--------------|--------|-------|
| self | Informal | Maximum | Use freely | Completeness |
| technical_ic | Peer-to-peer | Full technical | Domain terms | Implementation |
| technical_management | Executive-friendly | High-level + drill-down | Explain terms | Decisions, trade-offs |
| non_technical_management | Business-focused | Conceptual | Avoid/explain | Impact, risks, costs |

---

## Workflow

### Phase 1: Initialization

#### Step 1.1: Load Requirements
```
Read: {mission_dir}/requirements.md
Parse: All configuration values
```

#### Step 1.2: Load Master Memory
```
Read: {master_memory}
Note: Known source access patterns
```

#### Step 1.3: Initialize Progress Tracking

Create `{progress_dir}/orchestrator_state.md`:
```markdown
## Orchestrator State

- Phase: initialization
- Started: {timestamp}
- Last Checkpoint: {timestamp}

## Configuration Loaded
- Topic: {topic}
- Max Depth: {max_reference_depth}
- Max Sources: {max_total_sources}

## Next Actions
- [ ] Initialize reference queue
- [ ] Begin first-pass investigations
```

Create `{progress_dir}/reference_queue.md`:
```markdown
## Reference Queue

| ID | URL | Type | Depth | Parent | Max Sub-Refs | Status | Relevance | Notes |
|----|-----|------|-------|--------|--------------|--------|-----------|-------|
| 1  | {url} | {type} | 0 | - | {limit} | pending | - | Original source |
...
```

Create `{progress_dir}/relevance_decisions.md`:
```markdown
## Relevance Decisions Log

*Decisions are logged as they are made*
```

#### Step 1.4: Create Directory Structure
```bash
mkdir -p {mission_dir}/progress
mkdir -p {mission_dir}/sources/first_pass
mkdir -p {mission_dir}/sources/deep_dive
mkdir -p {mission_dir}/report
```

---

### Phase 2: First-Pass Investigation

For each source in queue with status=pending (max 2 concurrent):

#### Step 2.1: Dispatch Investigator

Write a task file to `{progress_dir}/tasks/investigate_{id}.md` containing the investigation request details. Then use the **source_investigator** sub-agent tool with:
- source_url: "{url}"
- investigation_type: "first_pass"
- topic: "{topic}"
- output_file: "{sources_dir}/first_pass/{id}_{sanitized_title}.md"

#### Step 2.2: Process Results

Save to `{sources_dir}/first_pass/{id}_{sanitized_title}.md`

#### Step 2.3: Extract New References

For each outbound reference found:
1. Check if within depth limit (`max_reference_depth` from requirements)
2. Check if parent's sub-ref limit reached:
   - First check if source has `max_sub_refs` override in requirements
   - If not, use `default_max_sub_refs` from requirements (NOT hardcoded 10!)
3. Check if total source limit reached (`max_total_sources` from requirements)
4. If all checks pass → add to queue with status=pending
5. If limit reached → evaluate for replacement (see Phase 3)

**CRITICAL**: Always use the limits specified in requirements.md, not defaults!

#### Step 2.4: Checkpoint

Update orchestrator_state.md:
```markdown
- Phase: first_pass
- Last Checkpoint: {timestamp}
- Sources Processed: {N} / {total}
- New References Queued: {M}
```

Update reference_queue.md with new statuses.

#### Step 2.5: Repeat

Continue until all sources at current depth are processed, then proceed to newly queued sources, until:
- All sources processed, OR
- Max depth reached for all branches, OR
- Max total sources reached

#### Step 2.6: Enforce Minimum First-Pass

**CRITICAL**: Before proceeding to Phase 3, verify:
```
first_pass_completed_count >= min_first_pass_sources (from requirements)
```

If NOT met and more sources are available:
- Continue first-pass on remaining pending sources
- Expand to next depth level if needed
- Only proceed to relevance evaluation when minimum is reached OR no more sources available

This ensures a rich pool of sources for deep-dive selection, even if the orchestrator thinks fewer sources would suffice for the report length.

---

### Phase 3: Relevance Evaluation

#### Step 3.1: Score All First-Pass Sources

For each source with status=first_pass_complete:

| Factor | Score |
|--------|-------|
| Topic keyword match | +3 |
| Storyline alignment | +3 |
| Deep-dive topic match | +2 |
| Authoritative source | +2 |
| Recency (< 1 year) | +1 |
| Cross-referenced by others | +1 |

#### Step 3.2: Apply Inclusion Rules

1. **Depth 0 (original) sources**: ALWAYS include (user-specified)
2. **Score ≥ 6**: Include for deep-dive
3. **Score 3-5**: Include if under limits
4. **Score < 3**: Exclude

#### Step 3.3: Handle Limit Overflow

If max_total_sources reached and new high-scoring source found:
1. Find lowest-scoring non-original source
2. If new source scores higher → replace
3. Log decision in relevance_decisions.md

#### Step 3.4: Log All Decisions

For each source, log in relevance_decisions.md:
```markdown
### {timestamp} - {source_title}
- URL: {url}
- Score: {N}
- Decision: include_deep_dive | include_skim | exclude | replace:{other}
- Reasoning: {brief explanation}
```

#### Step 3.5: Checkpoint

Update orchestrator_state.md:
```markdown
- Phase: relevance_evaluation
- Last Checkpoint: {timestamp}
- Total Sources Evaluated: {N}
- Selected for Deep-Dive: {M}
- Excluded: {K}
```

---

### Phase 4: Deep-Dive Investigation

For each source marked for deep-dive (max 2 concurrent):

#### Step 4.1: Prepare Deep-Dive Request

Analyze what's needed for the report:
- Which deep_dive_topics does this source address?
- What specific questions should be answered?
- What content gaps exist?

#### Step 4.2: Dispatch Investigator

Write a task file to `{progress_dir}/tasks/deep_dive_{id}.md` containing the deep-dive request details. Then use the **source_investigator** sub-agent tool with:
- source_url: "{url}"
- investigation_type: "deep_dive"
- topic: "{topic}"
- output_file: "{sources_dir}/deep_dive/{id}_{sanitized_title}.md"
- questions: "{comma-separated specific questions}"
- deep_dive_topics: "{comma-separated relevant topics for this source}"

#### Step 4.3: Process Results

Save to `{sources_dir}/deep_dive/{id}_{sanitized_title}.md`

#### Step 4.4: Checkpoint

Update orchestrator_state.md after each deep-dive completes.

---

### Phase 5: Coverage Assessment

#### Step 5.1: Map Coverage

Create coverage matrix:

| Deep-Dive Topic | Sources | Coverage Level | Gaps |
|-----------------|---------|----------------|------|
| Topic A | source1, source2 | Strong | None |
| Topic B | source3 | Moderate | Missing X |
| Topic C | - | Weak | Need more research |

#### Step 5.2: Address Gaps (if critical)

If coverage is weak for critical topics:
1. Check if any excluded sources might help
2. Consider re-scoring with adjusted criteria
3. Note gaps for report writer to acknowledge

#### Step 5.3: Checkpoint

Update orchestrator_state.md:
```markdown
- Phase: coverage_assessment
- Coverage: {summary}
- Ready for Writing: {yes/no}
```

---

### Phase 6: Report Generation

#### Step 6.1: Compile Materials for Writer

Create `{report_dir}/writing_brief.md`:
```markdown
## Research Compilation for Report Writer

### Configuration
- Topic: {topic}
- Audience: Primary: {primary}, Secondary: {secondary}
- Target Length: {pages} pages (CONTENT ONLY - references unlimited)
- Structure: {list}
- Storyline: {storyline}

### Source Summary
- Total Investigated: {N}
- Deep-Dives Completed: {M}
- Original Sources: {K}

### Materials
- First-pass summaries: {sources_dir}/first_pass/
- Deep-dive extractions: {sources_dir}/deep_dive/

### Coverage Assessment
{coverage matrix}

### Writing Guidance
{based on what was found, suggest focus areas}

### Citation Instructions
- Use science-style numbered references: [1], [2], [3], etc.
- Number references in order of first appearance
- Every factual claim needs a citation
- Direct quotes must always cite the source immediately after
- Page limit applies to CONTENT ONLY (References section is unlimited)

### Mathematical Equations (LaTeX)
If the report contains mathematical content, use LaTeX notation:

**Display equations** (centered, own line):
```
$$\text{Attention}(Q, K, V) = \text{softmax}\left(\frac{QK^T}{\sqrt{d_k}}\right)V$$
```

**Inline equations**:
```
The learning rate $\alpha = 0.001$ and complexity is $O(n^2)$.
```

Rules:
- Use `$$equation$$` for display equations (important formulas)
- Use `$expression$` for inline math (variables, simple expressions)
- Define variables when first introduced: "where $n$ is the sample size"

### Reference List Template
At end of report, include complete reference list:

## References

[1] {Author/Source}. "{Title}"
    {URL}
    Accessed: {Date}

[2] ...
```

#### Step 6.2: Invoke Report Writer

Use the **report_writer** sub-agent tool with:
- writing_brief: "{report_dir}/writing_brief.md"
- output_file: "{report_dir}/final_report.md"

#### Step 6.3: Verify Citation Compliance

Before saving, verify:
- [ ] All factual claims have numbered citations [N]
- [ ] References numbered in order of first appearance  
- [ ] Complete reference list at end with URLs and dates
- [ ] Content within page limit (excluding references)

#### Step 6.4: Save Final Report

Write output to `{report_dir}/final_report.md`

Expected format:
```markdown
# {Report Title}

*Research Report - {Date}*
*Audience: {Primary Audience}*
*Page Target: {N} pages (content)*

---

## Executive Summary
{Summary with citations where needed [1]}

## Background/Context
{Context with citations [2][3]}

## Key Findings
{Findings with citations [1][4][5]}

## Deep Dives
### {Topic}
{Detailed content with citations [6][7]}

> "Direct quotes always have citations immediately after" [8]

## Recommendations
{Recommendations}

---

## References

[1] {Author}. "{Title}"
    {URL}
    Accessed: {Date}

[2] {Author}. "{Title}"
    {URL}
    Accessed: {Date}

...

---

*Report generated from {N} sources with {M} deep-dive investigations.*
```

#### Step 6.4: Final Checkpoint

Update orchestrator_state.md:
```markdown
- Phase: complete
- Completed: {timestamp}
- Report Location: {path}
```

---

### Phase 7: Memory Update

#### Step 7.1: Update Source Access Memory

If new access patterns were discovered:
```
Read: {master_memory}
Append: New patterns learned during this research
Write: {master_memory}
```

---

## Progress Recovery

On mission start, check for existing progress:

```
If {progress_dir}/orchestrator_state.md exists:
  1. Read current phase and state
  2. Load reference_queue.md
  3. Resume from last checkpoint
Else:
  1. Start fresh initialization
```

### Recovery by Phase

| Phase | Recovery Action |
|-------|-----------------|
| initialization | Restart from beginning |
| first_pass | Continue with pending sources |
| relevance_evaluation | Re-evaluate if needed, or continue |
| deep_dive | Continue with pending deep-dives |
| coverage_assessment | Re-assess coverage |
| report_generation | Re-invoke writer if incomplete |
| complete | Report already done |

---

## Output Structure

```
{mission_dir}/
├── requirements.md              # User input
├── progress/
│   ├── orchestrator_state.md    # Current state for recovery
│   ├── reference_queue.md       # All sources with status
│   └── relevance_decisions.md   # Decision log
├── sources/
│   ├── first_pass/              # Initial summaries
│   │   ├── 001_source_title.md
│   │   └── ...
│   └── deep_dive/               # Detailed extractions
│       ├── 001_source_title.md
│       └── ...
└── report/
    ├── writing_brief.md         # Compilation for writer
    └── final_report.md          # Final output
```

---

## Exit Criteria

- [ ] All sources processed to appropriate depth
- [ ] Relevance decisions logged for all sources
- [ ] Deep-dives completed for relevant sources
- [ ] Coverage assessment shows adequate coverage
- [ ] Final report generated and saved
- [ ] Progress files reflect completion
- [ ] Master memory updated if new patterns found

---

## Limits Reference

| Limit | Default | Description |
|-------|---------|-------------|
| max_reference_depth | 3 | How many levels deep to follow references |
| max_total_sources | 50 | Maximum sources to investigate |
| default_max_sub_refs | 10 | Sub-references per original source |
| min_first_pass_sources | 20 | Minimum sources to first-pass before relevance evaluation |
| max_concurrent_investigators | 2 | Parallel investigations |

**Note on min_first_pass_sources**: This ensures the orchestrator builds a rich pool of sources before deciding which to deep-dive. Even if the orchestrator thinks it has "enough" sources for the report length, it must continue first-pass until this minimum is reached (or until no more sources are available).

### Limit Interaction Example

```
Original Source A (depth 0, max_sub_refs=10)
├── Ref A.1 (depth 1) ─ counts toward A's 10
├── Ref A.2 (depth 1) ─ counts toward A's 10
│   ├── Ref A.2.1 (depth 2) ─ counts toward A.2's default 10
│   └── Ref A.2.2 (depth 2) ─ counts toward A.2's default 10
...
└── Ref A.10 (depth 1) ─ A's limit reached, no more from A

If max_reference_depth=2, then A.2.1 and A.2.2 won't spawn children
If max_total_sources=50 reached, new sources must beat existing scores
```
