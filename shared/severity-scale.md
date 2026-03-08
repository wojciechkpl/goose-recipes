# Severity Classification Standard

Shared severity scale used by all auditing, review, and security recipes across both Claude Code and Goose platforms.

## Levels

| Level | Emoji | Label | CVSS Range | Action Required |
|-------|-------|-------|------------|-----------------|
| **Critical** | 🔴 | Critical | 9.0–10.0 | MUST fix before merge/deploy. Security vulnerability, data loss, crash. |
| **High** | 🟠 | Major / High | 7.0–8.9 | SHOULD fix before merge. Logic error, missing error handling, performance regression. |
| **Medium** | 🟡 | Minor / Medium | 4.0–6.9 | CAN fix in follow-up. Naming, style, minor optimization. |
| **Low** | 🔵 | Suggestion / Low | 0.1–3.9 | OPTIONAL. Alternative approach, educational note. |
| **Info** | ℹ️ | Informational | — | No action required. Context, best practice notes. |

## Usage in Reports

```markdown
## Critical Issues (🔴)
[file:line] — [description + suggested fix]

## Major Issues (🟠)
[file:line] — [description + suggested fix]

## Minor Issues (🟡)
[file:line] — [description + suggested fix]

## Suggestions (🔵)
[file:line] — [description + rationale]
```

## Recipes Using This Scale

- **Code Reviewer** — classifies review findings
- **Security Auditor** — classifies vulnerabilities with CVSS scores
- **Dependency Auditor** — classifies CVE severity
- **Static Analysis** — classifies linter/type-checker findings (🔴 Errors, 🟡 Warnings, 🔵 Info)
