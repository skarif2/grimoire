---
name: grill-plan
description: Pre-planning interview that explores the codebase, challenges assumptions, and sharpens the approach before committing to a plan. Drafts the plan in chat and refines it in a loop until you approve, then writes the plan file (and optionally an ADR). Stays in refinement mode for further tweaks. Use with /plan to stress-test an idea.
---

<what-to-do>

Before writing any plan, run a focused interview to understand the task properly. Ask questions one at a time, waiting for an answer before continuing. Explore the codebase instead of asking when the answer can be found there.

</what-to-do>

<project-detection>

Detect the project path from the folder structure. See `~/GRIMOIRE/templates/PROJECT-INIT.md` for the full spec.

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

Examples: `~/Projects/acme/frontend` → `docs/acme/frontend/`, `~/Projects/initech/scanner` → `docs/initech/scanner/`

</project-detection>

<context-mode-rules>

ALL codebase exploration and file analysis MUST use context-mode tools. Never use raw `read` for analysis or `bash` with large output. Raw output floods the context window.

### Exploring the codebase

Use `ctx_batch_execute` to gather everything in one call:
```
ctx_batch_execute(
  commands: [
    { label: "Find related files", command: "grep -rl '[keyword]' src/ --include='*.tsx' 2>/dev/null" },
    { label: "Existing patterns", command: "grep -rl '[pattern]' src/ --include='*.ts' 2>/dev/null" }
  ],
  queries: ["[relevant concept]", "[existing pattern]"]
)
```

### Reading files for analysis

Use `ctx_execute_file`, never `read` for analysis. Extract by relevance, not a fixed slice:
```
// Exports and type signatures only:
ctx_execute_file(path, "javascript", `
  const lines = FILE_CONTENT.split('\n')
  const relevant = lines.filter(l => /^export|^interface|^type |^class |^function |^const [A-Z]/.test(l.trim()))
  console.log(relevant.join('\n') || FILE_CONTENT.slice(0, 1500))
`)

// Find a named function or component:
ctx_execute_file(path, "javascript", `
  const match = FILE_CONTENT.match(/(?:function|const|class)\s+[TargetName][^{]*\{[\s\S]{0,600}/)
  console.log(match ? match[0] : FILE_CONTENT.slice(0, 1500))
`)

// Find a specific section by heading (markdown/comment):
ctx_execute_file(path, "javascript", `
  const idx = FILE_CONTENT.indexOf('[keyword]')
  console.log(idx >= 0 ? FILE_CONTENT.slice(idx, idx + 800) : 'section not found')
`)
```

### Searching indexed knowledge

Use `ctx_search` to check prior session decisions and indexed content:
```
ctx_search(queries: ["[task keyword]", "[component name]", "[pattern]"], source: "$PROJECT_ID", sort: "timeline")
```

### Checking existing context and ADR files

Use `ctx_batch_execute` to read project-level and group-level knowledge files in one call:
```
ctx_batch_execute(
  commands: [
    { label: "Project context", command: "cat $DOCS_ROOT/context/*.md 2>/dev/null || echo 'none'" },
    { label: "Project ADRs", command: "cat $DOCS_ROOT/adr/*.md 2>/dev/null || echo 'none'" },
    { label: "Shared context", command: "cat $SHARED_ROOT/context/*.md 2>/dev/null || echo 'none'" },
    { label: "Shared ADRs", command: "cat $SHARED_ROOT/adr/*.md 2>/dev/null || echo 'none'" }
  ],
  queries: ["domain terms", "architecture decisions", "API contracts", "rejected alternatives"]
)
```

</context-mode-rules>

<existing-knowledge>

Before asking anything, load existing knowledge in this order:

1. **Check for a relevant handoff file**, list what exists:
```bash
ls $DOCS_ROOT/handoffs/*.md 2>/dev/null || echo 'none'
```
If a filename looks relevant to the current task, ask the user before loading:
> "Found a handoff that might be related: `[filename]`. Load it as context for this plan?"

Only load if the user confirms, never load silently, even if the user mentioned the handoff in their request. If the user confirms, load the file and store its full path as `HANDOFF_FILE` for cleanup at the end. If no filenames match, skip entirely.

2. **Query indexed knowledge**, search for prior decisions, patterns, and context related to the task:
```
ctx_search(queries: ["[task keyword]", "[component name]", "[pattern]"], source: "$PROJECT_ID")
```
If `$GROUP` is set (project is inside `~/Projects/`), also search the group-level shared pool:
```
ctx_search(queries: ["[task keyword]"], source: "$GROUP")
```

3. **Load files**, use `ctx_batch_execute` as shown in `<context-mode-rules>` above.

4. Context files define the domain language, use terms exactly as defined, never introduce synonyms.
5. ADR files are past decisions, don't re-litigate them unless the user explicitly wants to.
6. If neither folder exists, proceed without, don't create them yet.

</existing-knowledge>

<interview-process>

## Step 1, Understand the scope

Explore the codebase using context-mode tools (see `<context-mode-rules>` above). Never use raw `read` or large `bash` output for this, use `ctx_batch_execute`, `ctx_execute_file`, and `ctx_search`. Build understanding silently, don't dump file contents to the user, just extract what's relevant.

## Step 2, Ask clarifying questions

Ask the questions most likely to affect the plan. Prioritise:

- **Scope**, what's in, what's out
- **Approach**, is there an existing pattern to follow or a new one needed
- **Constraints**, performance, accessibility, backward compatibility
- **Edge cases**, what happens in the unusual scenarios

Ask one question at a time. Provide your recommended answer with each question. Stop when you have enough to write a precise plan.

## Step 3, Surface conflicts

If the task conflicts with an existing ADR or context definition, call it out immediately before continuing. "ADR `adr_radix-over-mui.md` says we don't use MUI, this approach would use MUI. Do you want to revisit that decision or change the approach?"

## Step 4, Offer an ADR if warranted

Only offer to create an ADR if ALL THREE are true:

1. **Hard to reverse**, changing this decision later would be expensive
2. **Surprising without context**, a future reader would wonder why
3. **Real trade-off**, genuine alternatives were considered and rejected

If you create an ADR, first load `~/GRIMOIRE/templates/ADR-FMT.md` for the format rules. Then:

```bash
mkdir -p "$DOCS_ROOT/adr"
```

Save to: `$DOCS_ROOT/adr/adr_[slug].md`

Index the decision for future sessions:
```
ctx_index(
  content: "ADR: [title]\n\n[decision and why in 2-3 sentences]",
  source: "$PROJECT_ID:adr"
)
```

Then open it:
```bash
open_in_editor "$DOCS_ROOT/adr/adr_[slug].md"
```

Use this format:
```md
# [Short title of the decision]

[1-3 sentences: context, what was decided, and why.]
```

Only add **Considered Options** or **Consequences** sections if they add genuine value. Most ADRs are a single paragraph.

## Step 5, Update context if a new term was resolved

If the interview resolved a domain term that isn't in any context file yet, first load `~/GRIMOIRE/templates/CONTEXT-FMT.md` for the format rules. Then offer to add it.

Check if a context file for this area already exists (`ls $DOCS_ROOT/context/*.md 2>/dev/null`). If yes, add the new term to that file. If no, create one:

```bash
mkdir -p "$DOCS_ROOT/context"
```

Save to: `$DOCS_ROOT/context/context_[slug].md`

Use this format:
```md
# [Context Area Name]

[One sentence description of what this area covers.]

## Language

**[Term]**:
[One or two sentence definition of what it IS, not what it does.]
_Avoid_: [alternative terms to avoid]
```

Only add terms that are specific to this project, not general programming concepts.

Index the new term for future sessions:
```
ctx_index(
  content: "[term]: [definition]",
  source: "$PROJECT_ID:context"
)
```

Then open the context file:
```bash
open_in_editor "$DOCS_ROOT/context/context_[slug].md"
```

</interview-process>

<draft-review-loop>

When the interview has surfaced enough, **do NOT write the plan file yet.** First present the full plan as a **draft in chat** and refine it with the user in a loop. The file is created only on approval, so changes stay cheap and nothing hits disk prematurely.

1. Load `~/GRIMOIRE/templates/PLAN-FMT.md` for the format. Render the **complete** plan inline in chat using that structure: Title, Goal, Context, Tasks (each with a `verify:`), Decisions, Out of scope. Clearly label it a draft, e.g. a leading line: `📋 Draft plan, not saved yet`. Keep it tight per PLAN-FMT (one-sentence goal, 3 to 5 context bullets) so the whole draft fits the terminal at a glance. On later edits, re-render only the changed sections, not the whole plan, so the loop stays scannable.

   **Single-phase vs phased.** Default to a single-phase plan (a flat `## Tasks` list). Only when the ticket is genuinely large (many tasks, several components, multi-day, hard to finish in one clean context) draft it as **phased**: replace `## Tasks` with a `## Phases` section of dependency-ordered `### Phase N: <name>` blocks, each with `**Depends on:**`, `**Status:** pending`, empty `**Baseline:**` and `**Notes:**`, and its own task list (every task keeps `verify:`). Order phases by real dependencies, set `Baseline` and `Notes` later (at execution, by `/gg`). A small or medium ticket stays single-phase, do not invent phases. See the "Phased plans" section of PLAN-FMT.

2. **Pick a recommendation, then ask.** Judge the draft's risk first:
   - **Non-trivial** (touches several files or components, has multiple tasks, sits in an area with a known gotcha or ADR, or involves a migration / auth / data / irreversible change) → recommend **attack** first.
   - **Small and low-risk** (one file, a task or two, no sensitive area) → recommend **save**.

   Then ask in options style (three choices, marking the one you would pick and why):
   > Refine anything, attack it, or save?  **Recommended: <attack | save>** (one-line reason)
   > - **save**: write the plan file (you choose whether to run it after)
   > - **change: `<what>`**: revise scope / tasks / approach / decisions
   > - **attack**: run `/adversary` on this draft to red-team it before saving

   The recommendation is a nudge, not a gate. The user can pick anything, including something not listed. Do not offer `/gg` here: that choice comes after the file is saved (see `<output>`).

3. **Loop:** when the user asks for a change, revise the draft **in chat** (re-render the whole plan, or just the affected sections for small tweaks) and re-ask. Stay here as long as the user is changing the plan. Every task keeps its `verify:` condition; if a change adds a task, add its `verify:` too.

   **On `attack`:** run the `adversary` skill against the current draft, passing the draft plan text as the inline target. Surface its findings in chat. Write nothing and save nothing. Then fold any findings the user chooses to address back into the draft (still in the loop) and re-ask. The adversary is read-only; the user decides which findings matter.

4. **Exit the loop only on explicit save approval:** "save", "write it", "looks good". Then proceed to `<output>` and write the file once. (`/gg` and `done` are not draft-loop choices; they appear in the post-save prompt after the file is written.)

Do **not** generate the filename, write the plan file, or `ctx_index` the plan during this loop, all of that lives in `<output>`, after approval. (ADRs / context terms from interview Steps 4–5 are separate durable artifacts and may still be written during the interview once the user okays them.)

</draft-review-loop>

<output>

Only after the user approves the draft (see `<draft-review-loop>`), load `~/GRIMOIRE/templates/PLAN-FMT.md` for the format rules. Then generate the filename:

```bash
# 1. Date
DATE=$(date +%Y-%m-%d)

# 2. Task slug, derived from the plan title: lowercase, hyphenated, max 40 chars
TASK_SLUG=$(echo "[plan title]" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | cut -c1-40)

# 3. Dedup, if same slug exists today, append -2, -3 etc.
PLAN_DIR="$DOCS_ROOT/plans"
mkdir -p "$PLAN_DIR"
FILENAME="${DATE}-${TASK_SLUG}.md"
if [ -f "$PLAN_DIR/$FILENAME" ]; then
  N=2
  while [ -f "$PLAN_DIR/${DATE}-${TASK_SLUG}-${N}.md" ]; do N=$((N+1)); done
  FILENAME="${DATE}-${TASK_SLUG}-${N}.md"
fi
```

Before writing, check the active plan count:
```bash
ACTIVE=$(ls "$PLAN_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
[ "$ACTIVE" -ge 5 ] && echo "Warning: $ACTIVE active plans already exist, consider archiving one before adding more"
```

Write the plan file to: `$DOCS_ROOT/plans/$FILENAME`

Plan format:
```md
# [Task Title]

**Date:** [YYYY-MM-DD]
**Project:** [group/project]
**Status:** In Progress

## Goal
[One sentence describing what done looks like, verifiable, not vague]

## Context
[Key findings from the codebase exploration and interview, what exists, what patterns apply]

## Tasks
- [ ] Step 1, verify: [concrete check e.g. "component renders without errors", "tests pass", "no type errors"]
- [ ] Step 2, verify: [concrete check]
- [ ] Step 3, verify: [concrete check]

## Decisions
[Any decisions made during the interview that shaped this plan]

## Out of scope
[Explicitly what is NOT being done in this plan]
```

If the draft was phased (see `<draft-review-loop>`), write `## Phases` instead of `## Tasks`, using the phased structure from `~/GRIMOIRE/templates/PLAN-FMT.md` (each `### Phase N` with `Depends on`, `Status: pending`, empty `Baseline` and `Notes`, and its task list).

Every task MUST have a `verify:` condition. Vague criteria like "make it work" are not allowed. Transform them:
- "Add validation" → verify: failing inputs are rejected and error messages show
- "Fix bug" → verify: the specific scenario that triggered the bug no longer does
- "Refactor X" → verify: all existing tests pass before and after

Index the plan for future sessions:
```
ctx_index(
  content: "Plan: [plan title]\nGoal: [one-sentence goal]\nDecisions: [key decisions made during the interview]",
  source: "$PROJECT_ID:plans"
)
```

Tell the user the plan file path and any ADR/context files created. Then open the plan file:
```bash
open_in_editor "$DOCS_ROOT/plans/$FILENAME"
```

Then present the post-save choice (the file is written; the user decides whether to run it now):
> Plan saved at `$DOCS_ROOT/plans/$FILENAME`.
> - **gg**: execute the plan now (runs `/gg`)
> - **done**: stop here; the plan is saved to run later
>
> Still in refinement mode: any further tweaks fold straight into the file. Pick **gg** or **done** when ready.

On **gg**, invoke `/gg` against this plan. On **done**, confirm the plan is saved and stop without executing. (See `<refinement-mode>` below.)

</output>

<refinement-mode>

After the plan file is written, the conversation enters **refinement mode**. The plan file is now the working document, keep it as the source of truth so it never drifts out of sync with what was actually decided.

**While in refinement mode:**

- When the user refines scope, approach, tasks, or decisions, edit the plan file directly with the `Edit` tool, don't just discuss the change in chat. After editing, confirm in one line what changed (e.g. "Updated, added a task for the migration step").
- Use judgment: edit the file when the user is changing the plan; just answer when the user is only asking a question about it. Not every message is a plan edit.
- Every task MUST keep its `verify:` condition. If a refinement adds a task, add a `verify:` for it too.
- After a substantive change, re-index the plan so future sessions see the current version:
```
ctx_index(
  content: "Plan: [plan title]\nGoal: [one-sentence goal]\nDecisions: [current key decisions]",
  source: "$PROJECT_ID:plans"
)
```

**Exit refinement mode** when the user signals completion ("done", "looks good", "that's it"), switches to an unrelated task, or runs `/gg`. On exit:

If a handoff file was loaded at the start, ask before deleting:
> "Delete the handoff file `[filename]`? The plan supersedes it."

Only delete if the user confirms, never delete silently.

</refinement-mode>
