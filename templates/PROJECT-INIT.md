# Project Initialisation

When a skill writes its first file for a project, create the necessary folders on demand. Nothing is pre-created.

## Folder structure

All knowledge lives under `~/GRIMOIRE/docs/`, mirroring `~/Projects/`:

```
~/GRIMOIRE/docs/
├── {group}/                    ← e.g. acme, initech, personal
│   ├── context/                ← group-level shared context (API contracts, cross-project terms)
│   ├── adr/                    ← group-level shared decisions
│   └── {project}/              ← e.g. frontend, scanner, pipeline
│       ├── context/
│       ├── adr/
│       ├── handoffs/
│       ├── plans/
│       │   └── archived/
│       └── reviews/
```

## Detecting the project path

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
```

## Lazy creation rules

Create directories only when about to write into them — never speculatively:

| Writing a… | Create if missing |
|---|---|
| Plan file | `$DOCS_ROOT/plans/` |
| Archived plan | `$DOCS_ROOT/plans/archived/` |
| ADR | `$DOCS_ROOT/adr/` |
| Context file | `$DOCS_ROOT/context/` |
| Handoff file | `$DOCS_ROOT/handoffs/` |
| Review file | `$DOCS_ROOT/reviews/` |
| Group-level context/ADR | `$SHARED_ROOT/context/` or `$SHARED_ROOT/adr/` |

## Template references

Before writing any file, load the relevant format template:

| File type | Template |
|---|---|
| ADR | `~/GRIMOIRE/templates/ADR-FMT.md` |
| Context file | `~/GRIMOIRE/templates/CONTEXT-FMT.md` |
| Handoff | `~/GRIMOIRE/templates/HANDOFF-FMT.md` |
| Plan | `~/GRIMOIRE/templates/PLAN-FMT.md` |
| Review | `~/GRIMOIRE/templates/REVIEW-FMT.md` |
