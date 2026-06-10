# Plan File Format

Plan files live in `docs/[group]/[project]/plans/`. Use file naming `[date]-[task-slug].md` where the task slug is derived from the plan title (lowercase, hyphenated, max 40 chars).

Create the `plans/` directory lazily — only when the first plan is written. Keep at most 5 active plan files. When a task is done, delete the plan or move it to `plans/archived/` if it documents a significant approach worth keeping.

## Template

```md
# {Task Title}

**Date:** {YYYY-MM-DD}
**Project:** {group/project}
**Status:** In Progress

## Goal

{One sentence describing what done looks like — verifiable and concrete, not vague.}

## Context

{Key findings from codebase exploration and the planning interview — what exists, what patterns apply, what constraints were found.}

## Tasks

- [ ] {Step 1} — verify: {concrete check, e.g. "component renders without errors", "test passes", "no TypeScript errors"}
- [ ] {Step 2} — verify: {concrete check}
- [ ] {Step 3} — verify: {concrete check}

## Decisions

{Any decisions made during the interview that shaped this plan. If an ADR was written, reference it here.}

## Out of scope

{Explicitly what is NOT being done in this plan.}
```

## Rules

- Every task **must** have a `verify:` condition. Vague criteria are not allowed. Transform them:
  - "Add validation" → verify: invalid inputs are rejected and error messages display correctly
  - "Fix bug" → verify: the specific scenario that triggered the bug no longer reproduces
  - "Refactor X" → verify: all existing tests pass before and after, behaviour is unchanged
- The Goal must be a single verifiable sentence. "Make it work" is not a goal.
- Context should be brief — 3–5 bullets or a short paragraph. Not a design doc.
- Out of scope is mandatory. Explicit scope prevents creep.
