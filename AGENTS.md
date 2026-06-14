## OS & Environment Setup
Assume macOS for terminal commands, paths, operations. Default `zsh`. Use Homebrew (`brew`) for system packages.

## Project Knowledge Structure

All project-specific knowledge lives under `~/GRIMOIRE/docs/`, mirroring the `~/Projects/` folder structure. See `~/GRIMOIRE/templates/PROJECT-INIT.md` for the full path detection spec and lazy folder creation rules.

```
~/GRIMOIRE/docs/
├── {group}/                    ← e.g. acme, initech, personal
│   ├── context/                ← group-level shared context (API contracts, cross-project terms)
│   ├── adr/                    ← group-level shared decisions
│   └── {project}/              ← e.g. frontend, scanner, pipeline
│       ├── context/
│       ├── adr/
│       ├── handoffs/           ← ideas from /handoff — deleted after /plan supersedes it (with confirmation)
│       ├── plans/              ← active tasks only (≤5); archived/ when done via /gg
│       └── reviews/
```

Key variables (derived from the current working directory):
- `DOCS_ROOT` — path to project-specific docs (e.g. `~/GRIMOIRE/docs/acme/frontend`)
- `SHARED_ROOT` — path to group-level shared pool (e.g. `~/GRIMOIRE/docs/acme`)
- `PROJECT_ID` — identifier used for ctx labels (e.g. `acme/frontend`)

At the start of any session:
1. Load files from `$DOCS_ROOT/context/`, `$DOCS_ROOT/adr/`, `$SHARED_ROOT/context/`, `$SHARED_ROOT/adr/`
2. Query indexed knowledge: `ctx_search(queries: ["[task keywords]"], source: "$PROJECT_ID")`

## Knowledge Indexing

Skills index files when they create them. Source label uses `PROJECT_ID` format (e.g. `acme/frontend`):

- Plans → `source: "$PROJECT_ID:plans"`
- ADRs → `source: "$PROJECT_ID:adr"`
- Context terms → `source: "$PROJECT_ID:context"`
- Review patterns → `source: "$PROJECT_ID:patterns"`
- Review summaries → `source: "$PROJECT_ID:reviews"`
- Handoffs → `source: "$PROJECT_ID:handoffs"`

## Templates

Before writing any knowledge file, load the relevant format template from `~/GRIMOIRE/templates/`:

| File type | Template |
|---|---|
| ADR | `ADR-FMT.md` |
| Context file | `CONTEXT-FMT.md` |
| Handoff | `HANDOFF-FMT.md` |
| Plan | `PLAN-FMT.md` |
| Review | `REVIEW-FMT.md` |

# context-mode — MANDATORY routing rules

context-mode MCP tools are available. These rules protect the context window from flooding. One unrouted command can dump 56 KB into context.

## Think in Code — MANDATORY

When analyzing, counting, filtering, comparing, or processing data — write code via `ctx_execute(language, code)` and `console.log()` only the answer. Do not read raw data into context. Pure JavaScript, Node.js built-ins only (`fs`, `path`, `child_process`). Always use `try/catch` and handle `null`/`undefined`.

## BLOCKED — do not use

- **curl / wget** in bash — use `ctx_fetch_and_index(url, source)` instead
- **Inline HTTP** (`node -e "fetch(..."`, `python -c "requests.get(..."`) — use `ctx_execute(language, code)`
- **Direct web fetching** — use `ctx_fetch_and_index(url, source)` then `ctx_search(queries)`

## REDIRECTED — use sandbox

- **bash with >20 lines output** — use `ctx_batch_execute(commands, queries)` or `ctx_execute(language: "shell", code: "...")`
- **bash** is only for: `git`, `mkdir`, `rm`, `mv`, `cd`, `ls`, `npm install`, `pip install`
- **read for analysis** — use `ctx_execute_file(path, language, code)`. Use `read` only when you intend to edit the file.
- **grep / find with large results** — use `ctx_execute(language: "shell", code: "grep ...")`

## Tool selection

0. **On resume** — `ctx_search(sort: "timeline")` first. Check prior context before asking the user anything.
1. **Gather** — `ctx_batch_execute(commands, queries)` — runs all commands, auto-indexes, returns search results. One call replaces many.
2. **Follow-up search** — `ctx_search(queries: ["q1", "q2"])` — batch all questions in one call.
3. **Processing** — `ctx_execute(language, code)` or `ctx_execute_file(path, language, code)` — only stdout enters context.
4. **Web** — `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` — raw HTML never enters context.
5. **Index** — `ctx_index(content, source)` — store content in FTS5 for later search.

## Parallel I/O

For multi-URL fetches or multi-API calls always pass `concurrency: N` (1-8):

- Use concurrency 4-8 for I/O-bound work (network calls, API queries, gh commands)
- Keep concurrency 1 for CPU-bound work (npm test, build, lint) or commands sharing state
- GitHub API: cap at 4

## Output

Two separate disciplines — do not let the first suppress the second:

**Context discipline** — keep raw bytes OUT of context. Write artifacts to files, never inline; return the file path and a one-line description. Process data in the sandbox and surface only the result.

**Presentation discipline** — format the answer you DO surface; "one-line" means concise, not unstyled:
- Multi-row or multi-field results → markdown table.
- Grouped findings → `##` headings + bullets; code, paths, and commands → fenced blocks or backticks.
- Use **bold** for key terms and inline links; never emit a bare wall of plain text.

> Agent-specific (Claude Code only — PI ignores): when using the `AskUserQuestion` tool, keep option labels ≤5 words and descriptions ≤1 sentence; never paste raw tool output or snippets into options. The question box is harness-rendered and cannot be themed, so its readability depends entirely on short, clean content.

## Session Continuity

Skills, roles, and decisions set during a session persist until the user revokes them. Do not drop them as the conversation grows.

On resume, search before asking the user:
- What did we decide? → `ctx_search(queries: ["decision"], sort: "timeline")`
- What constraints exist? → `ctx_search(queries: ["constraint"])`

If search returns no results, proceed as a fresh session.

## ctx commands

| Command | Action |
|---------|--------|
| `ctx stats` | Show context savings and session statistics |
| `ctx doctor` | Diagnose runtimes, hooks, FTS5, versions |
| `ctx upgrade` | Update to latest version, rebuild, fix hooks |
| `ctx purge` | Permanently delete all indexed content |

After /clear or /compact: knowledge base is preserved. Use `ctx purge` to start fresh.
