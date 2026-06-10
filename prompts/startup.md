---
description: Startup — load project knowledge and query indexed context before starting work
---

Before starting work, identify the current project and load what's known about it.

## 1. Detect project

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
echo "Project: $PROJECT_ID"
```

## 2. Load files and query indexed knowledge

```
ctx_batch_execute(
  commands: [
    { label: "Project context", command: "cat $DOCS_ROOT/context/*.md 2>/dev/null || echo 'none'" },
    { label: "Project ADRs", command: "cat $DOCS_ROOT/adr/*.md 2>/dev/null || echo 'none'" },
    { label: "Active plans", command: "ls $DOCS_ROOT/plans/*.md 2>/dev/null || echo 'none'" },
    { label: "Pending handoffs", command: "ls $DOCS_ROOT/handoffs/*.md 2>/dev/null || echo 'none'" },
    { label: "Shared context", command: "cat $SHARED_ROOT/context/*.md 2>/dev/null || echo 'none'" },
    { label: "Shared ADRs", command: "cat $SHARED_ROOT/adr/*.md 2>/dev/null || echo 'none'" }
  ],
  queries: ["domain terms", "architecture decisions", "active tasks", "API contracts", "pending handoffs"]
)
```

Then query the index for recent decisions, patterns, and pending work:
```
ctx_search(queries: ["decision", "pattern", "recent", "pending", "handoff"], source: "$PROJECT_ID", sort: "timeline")
```
If `$GROUP` is set (project is inside `~/Projects/`), also search the group-level shared pool:
```
ctx_search(queries: ["decision", "pattern", "shared"], source: "$GROUP", sort: "timeline")
```

## 3. Summarise in 3–5 bullets

Cover what you found: domain terms defined, active plan filenames, architecture decisions in place, past review patterns, and shared cross-project context. List plan and handoff filenames — don't load their content.

Then ask: "What are we working on today?"
