# Project Initialisation

When a skill writes its first file for a project, create the necessary folders on demand. Nothing is pre-created.

## Folder structure

All knowledge lives under `~/GRIMOIRE/docs/`, mirroring `~/Projects/`:

```
~/GRIMOIRE/docs/
├── {group}/                    ← e.g. acme, initech, personal
│   ├── index.md                ← group-level catalog of shared distilled pages
│   ├── context/                ← group-level shared context (API contracts, cross-project terms)
│   ├── adr/                    ← group-level shared decisions
│   ├── concepts/               ← group-level shared concepts
│   └── {project}/              ← e.g. frontend, scanner, pipeline
│       ├── index.md            ← MAP: catalog of this project's distilled pages (read first)
│       │                          ── distilled wiki layer (durable, interlinked, read later) ──
│       ├── context/            ← glossary / domain terms
│       ├── adr/                ← decisions
│       ├── concepts/           ← how-it-works domain knowledge (concept_{slug}.md)
│       ├── components/         ← entity pages for real modules (component_{slug}.md)
│       ├── lessons/            ← what-we-learned takeaways (lesson_{slug}.md)
│       ├── gotchas.md          ← single file of one-line traps (### entries)
│       │                          ── raw source layer (episodic, dated, write-once) ──
│       ├── handoffs/
│       ├── plans/
│       │   └── archived/
│       └── reviews/
```

**Two layers, one boundary.** The **raw source** layer (`plans/`, `reviews/`, `handoffs/`) is written by `/plan`, `/gg`, `/review` as a dated record and is *never* listed in `index.md`. The **distilled wiki** layer (`context/`, `adr/`, `concepts/`, `components/`, `lessons/`, `gotchas.md`) is compiled *from* the raw layer at ticket close (draft → user confirms), is fully interlinked with `[[wikilinks]]`, carries provenance + freshness markers, and *is* what the AI loads on future work. `index.md` is the map between them.

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
| Concept page | `$DOCS_ROOT/concepts/` |
| Component page | `$DOCS_ROOT/components/` |
| Lesson page | `$DOCS_ROOT/lessons/` |
| Gotcha entry | `$DOCS_ROOT/gotchas.md` (single file) |
| Index | `$DOCS_ROOT/index.md` (single file) |
| Handoff file | `$DOCS_ROOT/handoffs/` |
| Review file | `$DOCS_ROOT/reviews/` |
| Group-level context/ADR/concept | `$SHARED_ROOT/context/`, `$SHARED_ROOT/adr/`, or `$SHARED_ROOT/concepts/` |

## Template references

Before writing any file, load the relevant format template:

| File type | Template |
|---|---|
| Index | `~/GRIMOIRE/templates/INDEX-FMT.md` |
| ADR | `~/GRIMOIRE/templates/ADR-FMT.md` |
| Context file | `~/GRIMOIRE/templates/CONTEXT-FMT.md` |
| Concept | `~/GRIMOIRE/templates/CONCEPT-FMT.md` |
| Component | `~/GRIMOIRE/templates/COMPONENT-FMT.md` |
| Lesson | `~/GRIMOIRE/templates/LESSON-FMT.md` |
| Gotcha | `~/GRIMOIRE/templates/GOTCHA-FMT.md` |
| Handoff | `~/GRIMOIRE/templates/HANDOFF-FMT.md` |
| Plan | `~/GRIMOIRE/templates/PLAN-FMT.md` |
| Review | `~/GRIMOIRE/templates/REVIEW-FMT.md` |
