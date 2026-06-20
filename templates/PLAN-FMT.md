# Plan File Format

Plan files live in `docs/[group]/[project]/plans/`. Use file naming `[date]-[task-slug].md` where the task slug is derived from the plan title (lowercase, hyphenated, max 40 chars).

Create the `plans/` directory lazily, only when the first plan is written. Keep at most 5 active plan files. When a task is done, delete the plan or move it to `plans/archived/` if it documents a significant approach worth keeping.

## Template

```md
# {Task Title}

**Date:** {YYYY-MM-DD}
**Project:** {group/project}
**Status:** In Progress

## Goal

{One sentence describing what done looks like, verifiable and concrete, not vague.}

## Context

{Key findings from codebase exploration and the planning interview: what exists, what patterns apply, what constraints were found.}

## Tasks

- [ ] {Step 1}, verify: {concrete check, e.g. "component renders without errors", "test passes", "no TypeScript errors"}
- [ ] {Step 2}, verify: {concrete check}
- [ ] {Step 3}, verify: {concrete check}

## Decisions

{Any decisions made during the interview that shaped this plan. If an ADR was written, reference it here.}

## Out of scope

{Explicitly what is NOT being done in this plan.}
```

## Phased plans (optional)

Most plans are **single-phase**: a flat `## Tasks` list, executed in one session, exactly as above. A big ticket (many tasks, several components, multi-day) may instead be split into dependency-ordered **phases**, each executed in its own session with a clean context.

A plan is phased **only** when it contains a literal `## Phases` section. Detection is **structural**, never a keyword: a plan that merely says "phase" somewhere in prose is *not* phased. No `## Phases` section means single-phase.

When phased, replace `## Tasks` with `## Phases`. Each phase is:

```md
## Phases

### Phase 1: {name}

**Depends on:** none
**Status:** pending
**Baseline:**
**Notes:**

- [ ] {Step 1}, verify: {concrete check}
- [ ] {Step 2}, verify: {concrete check}

### Phase 2: {name}

**Depends on:** Phase 1
**Status:** pending
**Baseline:**
**Notes:**

- [ ] {Step 1}, verify: {concrete check}
```

Per-phase fields:
- **Depends on:** comma-separated phase names (or `none`). A phase runs only when every dependency is `done`.
- **Status:** `pending` | `done`. Starts `pending`; `/gg` flips it to `done` when the phase completes.
- **Baseline:** empty at authoring. `/gg` fills it with a working-tree snapshot ref when the phase starts, scoping that phase's diff.
- **Notes:** empty at authoring. `/gg` fills it at phase completion with decisions, gotchas, and surprises, so rationale survives a compacted session.

Every task still carries a `verify:`, phased or not. `## Decisions` and `## Out of scope` stay at the plan level (not per-phase). `/gg` executes one ready phase per session and stops with a resume handoff; see `prompts/gg.md`.

## Rules

- Every task **must** have a `verify:` condition. Vague criteria are not allowed. Transform them:
  - "Add validation" → verify: invalid inputs are rejected and error messages display correctly
  - "Fix bug" → verify: the specific scenario that triggered the bug no longer reproduces
  - "Refactor X" → verify: all existing tests pass before and after, behaviour is unchanged
- The Goal must be a single verifiable sentence. "Make it work" is not a goal.
- Context should be brief, 3 to 5 bullets or a short paragraph. Not a design doc.
- Out of scope is mandatory. Explicit scope prevents creep.

## Wikilinks & distillation

A plan is a **raw source**, not a wiki page, so it is *not* listed in `index.md`. But it is the primary input to distillation:

- **Link the distilled pages it relied on.** When the planning interview used a `[[concept_{slug}]]`, `[[component_{slug}]]`, or `[[adr_{slug}]]`, reference it in Context so the trail is explicit.
- **At close, `/gg` distils this plan** into the wiki layer (new/updated concept, component, lesson, gotcha pages) and links those pages back to the plan via their `Source:` line. The plan itself stays a dated, write-once record.
