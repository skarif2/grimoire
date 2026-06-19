---
description: Go — plan approved, execute immediately
argument-hint: "[plan filename or partial name]"
---
$ARGUMENTS

Plan approved. Execute now.

## Instructions

1. Detect the project path (see `~/GRIMOIRE/templates/PROJECT-INIT.md` for the full spec):
   ```bash
   PROJECTS_ROOT="$HOME/Projects"
   CWD=$(pwd)
   if [[ "$CWD" == "$PROJECTS_ROOT/"* ]]; then
     RELATIVE="${CWD#$PROJECTS_ROOT/}"
     GROUP=$(echo "$RELATIVE" | cut -d'/' -f1 | tr '[:upper:]' '[:lower:]')
     PROJ=$(echo "$RELATIVE" | cut -d'/' -f2 | tr '[:upper:]' '[:lower:]')
     DOCS_ROOT="$HOME/GRIMOIRE/docs/$GROUP/$PROJ"
     PROJECT_ID="$GROUP/$PROJ"
   else
     PROJ=$(basename "$CWD" | tr '[:upper:]' '[:lower:]')
     DOCS_ROOT="$HOME/GRIMOIRE/docs/$PROJ"
     PROJECT_ID="$PROJ"
   fi
   ```
2. Locate the plan file:
   ```bash
   PLAN_DIR="$DOCS_ROOT/plans"

   if [ -n "$ARGUMENTS" ]; then
     # Partial match on filename — e.g. /gg auth → matches 2026-05-22-add-auth-flow.md
     PLAN_FILE=$(ls "$PLAN_DIR"/*.md 2>/dev/null | grep -i "$ARGUMENTS" | head -1)
     # If nothing matched, tell the user and stop
   else
     # No argument — find all open plans
     OPEN_PLANS=$(grep -rl 'Status.*In Progress' "$PLAN_DIR"/*.md 2>/dev/null)
     # One found → set PLAN_FILE automatically
     # Multiple found → show a numbered list, ask which to execute
     # None found → tell the user no active plans exist for this project
   fi
   ```
3. Read the plan file (use `read` — we will edit it later). If the plan references project ADRs or context in its Context section, load those via `ctx_batch_execute` to avoid flooding context with raw reads.
4. Add all tasks to the todo overlay.
5. Execute each task one by one. After completing each task:
   - Run the task's `verify:` condition to confirm it actually worked
   - If verification fails, fix it before moving on — do not tick off an unverified task
   - Mark it done in the todo overlay only after verification passes
   - Update the plan file: `- [ ]` → `- [x]`
6. When all tasks are complete, update plan `**Status:** Done`, then archive it:
   ```bash
   mkdir -p "$PLAN_DIR/archived"
   mv "$PLAN_FILE" "$PLAN_DIR/archived/"
   ```
7. **Distil into the wiki layer (draft → confirm).** The finished plan is a *raw source*; now compile its durable knowledge into the distilled wiki so future work benefits. (See the "Compiled Wiki Layer" section of `~/GRIMOIRE/AGENTS.md` and the page formats in `~/GRIMOIRE/templates/{CONCEPT,COMPONENT,LESSON,GOTCHA,INDEX}-FMT.md`.)
   - Re-read the finished plan **and the actual diff** (`ctx_execute(shell, "git diff …")`). Identify durable knowledge: a mechanism learned → **concept**; a module created/heavily touched → **component**; a non-obvious root cause or rejected approach → **lesson**; a sharp trap → **gotcha** entry.
   - For each, decide **new page vs. update existing** — check `$DOCS_ROOT/{concepts,components,lessons}/` and `$DOCS_ROOT/gotchas.md`. Never duplicate; revise in place.
   - Draft each page with mandatory `Source:` (this plan + `path:line`/PR), `Status:`/`Updated:`, and `[[wikilinks]]` to related pages. Draft the matching `index.md` entries and any backlinks on existing pages.
   - **Present the drafts as a confirm batch** — list each proposed page (NEW or UPDATE) with a one-line summary. Do **not** write until the user approves. On `approve`: write the pages, update `$DOCS_ROOT/index.md`, and `ctx_index` each with its `$PROJECT_ID:<type>` source (e.g. `:concepts`, `:gotchas`, `:index`). On `revise: <note>`: adjust and re-present.
   - If the change produced nothing durable (trivial fix), **say so and skip** — never manufacture pages.

## Execution guidelines

- Make the minimum change that solves the problem — nothing speculative
- Touch only what the task requires — don't improve adjacent code or reformat unrelated things
- Match the existing code style
- Remove imports/variables/functions your changes made unused
- If you notice a simpler approach mid-execution, mention it but keep going unless it changes scope
