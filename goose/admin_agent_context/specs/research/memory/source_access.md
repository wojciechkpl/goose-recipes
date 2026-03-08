# Source Access Patterns

Memory file tracking known access patterns for different URL types and domains.
Updated automatically as investigators discover successful access methods.

---

## Known Patterns

| Domain Pattern | Source Type | Recommended Tool | Notes |
|----------------|------------|-----------------|-------|
| `w.amazon.com/*` | wiki | ReadInternalWebsites | Internal wiki pages |
| `quip-amazon.com/*` | quip | QuipEditor or ReadInternalWebsites | Quip documents |
| `code.amazon.com/*` | code_remote | developer__analyze | Code browser |
| `github.com/*` | code_remote | developer__analyze | GitHub repositories |
| `*.md`, `*.py`, etc. (local) | code_local | analyst sub-agent | Local code files |
| `arxiv.org/*` | academic | ReadInternalWebsites | Academic papers |
| `docs.aws.amazon.com/*` | aws_docs | ReadInternalWebsites | AWS documentation |
| `broadcast.amazon.com/*` | video | ReadInternalWebsites | Video content pages |
| `design-inspector.a2z.com/*` | diagram | ReadInternalWebsites | Design diagrams |
| `*.pdf` | pdf | download + extract | PDF documents |
| `http*` (other) | web | ReadInternalWebsites | General web pages |

---

## Access Issues Log

Track any domain-specific access issues or workarounds discovered during investigations.

| Date | Domain/URL | Issue | Workaround | Investigator Notes |
|------|-----------|-------|------------|-------------------|
| _(none yet)_ | | | | |

---

## Tips

- When a new access pattern is discovered, add it to the Known Patterns table above
- If a tool fails for a known pattern, document the issue in the Access Issues Log
- Investigators should check this file before attempting access to avoid repeating failed approaches
