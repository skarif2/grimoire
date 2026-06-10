---
name: improve-architecture
description: Find architectural friction in a codebase — shallow modules, poor locality, testability problems. Produces a visual HTML report with before/after diagrams, then grills you on the candidate you pick. Updates context files and ADRs as decisions crystallise. Use when you want to improve architecture, find refactoring opportunities, or make a codebase more testable.
---

# Improve Codebase Architecture

Surface architectural friction and propose **deepening opportunities** — refactors that turn shallow modules into deep ones. The aim is testability and AI-navigability.

Use the vocabulary in [LANGUAGE.md](./LANGUAGE.md) exactly in every suggestion. Full definitions there — don't drift into "component," "service," "API," or "boundary."

Key terms: **module**, **interface**, **implementation**, **depth**, **seam**, **adapter**, **leverage**, **locality**.

Key principles:
- **Deletion test**: imagine deleting the module. If complexity vanishes, it was a pass-through. If it reappears across N callers, it was earning its keep.
- **The interface is the test surface.**
- **One adapter = hypothetical seam. Two adapters = real seam.**

## Process

### 1. Detect project and load domain knowledge

```bash
PROJECTS_ROOT="$HOME/Projects"
CWD=$(pwd)
if [[ "$CWD" == "$PROJECTS_ROOT/"* ]]; then
  RELATIVE="${CWD#$PROJECTS_ROOT/}"
  GROUP=$(echo "$RELATIVE" | cut -d'/' -f1 | tr '[:upper:]' '[:lower:]')
  PROJ=$(echo "$RELATIVE" | cut -d'/' -f2 | tr '[:upper:]' '[:lower:]')
  DOCS_ROOT="$HOME/GRIMOIRE/docs/$GROUP/$PROJ"
  SHARED_ROOT="$HOME/GRIMOIRE/docs/$GROUP"
  PROJECT_ID="$GROUP/$PROJ"
else
  PROJ=$(basename "$CWD" | tr '[:upper:]' '[:lower:]')
  DOCS_ROOT="$HOME/GRIMOIRE/docs/$PROJ"
  SHARED_ROOT=""
  PROJECT_ID="$PROJ"
fi

open_in_editor() {
  if [ -n "${VSCODE_GIT_IPC_HANDLE:-}" ] || [ "${TERM_PROGRAM:-}" = "vscode" ]; then
    echo "  saved: $1"
  else
    code "$(pwd)" "$1" 2>/dev/null || echo "  saved: $1"
  fi
}
```

Load domain glossary and existing decisions before exploring the codebase:

```
ctx_batch_execute(
  commands: [
    { label: "Project context", command: "cat $DOCS_ROOT/context/*.md 2>/dev/null || echo 'none'" },
    { label: "Project ADRs", command: "cat $DOCS_ROOT/adr/*.md 2>/dev/null || echo 'none'" },
    { label: "Shared context", command: "cat $SHARED_ROOT/context/*.md 2>/dev/null || echo 'none'" },
    { label: "Shared ADRs", command: "cat $SHARED_ROOT/adr/*.md 2>/dev/null || echo 'none'" }
  ],
  queries: ["architecture", "module", "seam", "domain terms", "rejected alternatives"]
)
```

Also query indexed knowledge:
```
ctx_search(queries: ["architecture", "module", "seam", "decision"], source: "$PROJECT_ID")
```
If `$GROUP` is set (project is inside `~/Projects/`), also search the group-level shared pool:
```
ctx_search(queries: ["architecture", "decision", "shared"], source: "$GROUP")
```

The domain language from context files gives names to good seams. ADRs record decisions not to re-litigate — only surface a candidate that contradicts an ADR when the friction is real enough to warrant revisiting it.

### 2. Explore

Use the Agent tool with `subagent_type=Explore` to walk the codebase. Don't follow rigid heuristics — explore organically and note where you experience friction:

- Where does understanding one concept require bouncing between many small modules?
- Where are modules **shallow** — interface nearly as complex as the implementation?
- Where have pure functions been extracted just for testability, but the real bugs hide in how they're called (no **locality**)?
- Where do tightly-coupled modules leak across their seams?
- Which parts of the codebase are untested, or hard to test through their current interface?

Apply the **deletion test** to anything you suspect is shallow.

See [DEEPENING.md](./DEEPENING.md) for how to classify dependencies and what deepening looks like per category.

### 3. Present candidates as an HTML report

Write a self-contained HTML file to the OS temp directory:

```bash
REPORT_PATH="${TMPDIR:-/tmp}/architecture-review-$(date +%Y%m%d-%H%M%S).html"
```

See [HTML-REPORT.md](./HTML-REPORT.md) for the full scaffold, diagram patterns, and styling guidance.

For each candidate, render a card with:
- **Files** — which files/modules are involved
- **Problem** — why the current architecture is causing friction (one sentence)
- **Solution** — plain English description of what would change (one sentence)
- **Benefits** — in terms of locality and leverage, and how tests would improve
- **Before / After diagram** — side-by-side, illustrating the shallowness and the deepening
- **Recommendation strength** — `Strong`, `Worth exploring`, or `Speculative`

Use domain vocabulary from context files for domain concepts. Use [LANGUAGE.md](./LANGUAGE.md) vocabulary for structural concepts.

**ADR conflicts**: if a candidate contradicts an existing ADR, only surface it when the friction is real enough to warrant revisiting. Mark it with a warning callout in the card.

End with a **Top recommendation** section.

Open the report:
```bash
open "$REPORT_PATH"
```

Do NOT propose interfaces yet. After opening the report, ask: "Which of these would you like to explore?"

### 4. Grilling loop

Once the user picks a candidate, drop into a grilling conversation. Walk the design tree — constraints, dependencies, the shape of the deepened module, what sits behind the seam, what tests survive.

Any codebase exploration during the grilling — reading a specific file, finding call sites, checking test coverage — must route through context-mode. Never use raw `read` or bash with large output mid-conversation.

- **Read a specific file**: `ctx_execute_file(path, "javascript", \`console.log(FILE_CONTENT.match(/export[^}]+}/g)?.join('\\n'))\`)` — extract only the interface, not the full file
- **Find call sites or patterns**: `ctx_execute("shell", \`grep -r "ModuleName" src/ --include="*.ts" -l\`)`
- **Search indexed knowledge**: `ctx_search(queries: ["[candidate module name]", "[seam concept]"], source: "$PROJECT_ID")` — if `$GROUP` is set, also search `source: "$GROUP"` for group-level decisions

See [INTERFACE-DESIGN.md](./INTERFACE-DESIGN.md) when the user wants to explore alternative interfaces.

**Side effects happen inline as decisions crystallise:**

#### New domain term resolved

If the grilling names a concept not in any context file, add it immediately. Load `~/GRIMOIRE/templates/CONTEXT-FMT.md`, then check if a context file for this area already exists (`ls $DOCS_ROOT/context/*.md 2>/dev/null`). If yes, add the term to that file. If no, create one:

```bash
mkdir -p "$DOCS_ROOT/context"
```

Save to: `$DOCS_ROOT/context/context_[slug].md`

Index the term:
```
ctx_index(
  content: "[term]: [definition]",
  source: "$PROJECT_ID:context"
)
```

Open it:
```bash
open_in_editor "$DOCS_ROOT/context/context_[slug].md"
```

#### User rejects a candidate with a load-bearing reason

Only offer an ADR when the reason would help a future explorer avoid re-suggesting the same thing — skip ephemeral reasons ("not worth it right now") and self-evident ones.

Load `~/GRIMOIRE/templates/ADR-FMT.md`, then:

```bash
mkdir -p "$DOCS_ROOT/adr"
```

Save to: `$DOCS_ROOT/adr/adr_[slug].md`

Index the decision:
```
ctx_index(
  content: "ADR: [title]\n\n[decision and why in 2-3 sentences]",
  source: "$PROJECT_ID:adr"
)
```

Open it:
```bash
open_in_editor "$DOCS_ROOT/adr/adr_[slug].md"
```
