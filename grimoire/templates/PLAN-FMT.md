# Plan Format

The plan is a single working file at `.grimoire/plan.md`, gitignored and per worktree. There is one active plan per worktree, so there is no dated filename and no dedup. Create `.grimoire/` lazily, only when the first plan is written.

`/build` prunes the plan on Done. Anything worth keeping is carried into `.wiki/` by distillation, not by keeping the plan file around.

## Template

```md
# {Task Title}

**Date:** {YYYY-MM-DD}
**Branch:** {branch name}
**Status:** In Progress
**Ticket baseline:**
**Companion:**

## Goal

{One sentence describing what done looks like. Verifiable and concrete, not vague.}

## Context

{Key findings from exploration and the planning interview: what exists, what patterns apply, what constraints were found.}

## Tasks

- [ ] {Step 1}, verify: {concrete check, such as "component renders without errors" or "test passes"}
- [ ] {Step 2}, verify: {concrete check}

## Decisions

{Decisions made during the interview that shaped this plan. If an ADR was written, name it here.}

## Out of scope

{Explicitly what is NOT being done.}
```

Plan level fields:

- **Ticket baseline:** empty at authoring. `/build` fills it with the first phase's baseline ref name and reads it back to diff the whole ticket, since tree refs carry no creation date and `refs/grimoire/*` has no reflog to recover an ordering from.
- **Companion:** optional, the path to a sibling repo's `.grimoire/plan.md` when one ticket spans two repositories. `.grimoire/` is per worktree, so neither half sees the other; `/build` prints this path at Done so the other half is not forgotten. Leave it empty otherwise.

## Phased plans

Most plans are single phase: a flat `## Tasks` list executed in one session. A big ticket (many tasks, several components, multi day) may instead be split into phases wired by **blocking edges**, each executed in its own session with clean context.

A plan is phased **only** when it contains a literal `## Phases` section. Detection is structural, never a keyword. A plan that merely says "phase" in prose is not phased.

```md
## Phases

### Phase 1: {name}

**Id:** {kebab-case-id}
**Depends on:** none
**Status:** pending
**Baseline:**
**Notes:**

- [ ] {Step 1}, verify: {concrete check}

### Phase 2: {name}

**Id:** {another-kebab-id}
**Depends on:** {kebab-case-id}
**Status:** pending
**Baseline:**
**Notes:**

- [ ] {Step 1}, verify: {concrete check}
```

Per phase fields:

- **The number** in the heading is reading order, top to bottom, so a person can say "phase 2". Nothing references it: `Depends on`, baseline refs, the resume handoff and `/build` all go through the id. Reordering or inserting a phase renumbers the headings and changes nothing else.
- **Id:** stable kebab-case identifier, unique within the plan, derived from the phase name (`import-csv-endpoint`, not `phase-2`). Set once at authoring and **never changed**, even when phases are reordered, renamed, split or inserted. Every later reference (dependencies, baseline refs, the resume handoff) goes through the id, so a session picks work by id instead of by position.
- **Depends on:** a list of phase ids this phase is blocked by, comma separated, or `none`. Ids only, never a name or a number.
- **Status:** `pending` or `done`. `/build` flips it when the phase completes.
- **Baseline:** empty at authoring. `/build` fills it with a working tree snapshot ref, keyed by the phase id, when the phase starts. It scopes that phase's diff.
- **Notes:** empty at authoring. `/build` fills it at phase completion with decisions, gotchas and surprises, so rationale survives a compacted session.

Every task carries a `verify:`, phased or not. `## Decisions` and `## Out of scope` stay at plan level, not per phase.

### The frontier

The **frontier** is the set of phases that are `pending` and whose every `Depends on` id is already `done`. Those are takeable right now. Everything else is blocked, and the difference is computable from the plan alone.

That is what makes a multi session ticket resumable: a fresh session reads the phase headers, computes the frontier, and knows what is live without rereading the whole plan or reconstructing where the last session stopped. `/build` computes it, and when more than one phase is takeable it asks which rather than assuming the first.

Two authoring consequences. Declare only real blockers, since a padded `Depends on` collapses the frontier to a single file ordered chain and throws the whole mechanism away. Declare every real one, since a missing edge makes a phase look takeable before its ground exists.

### Phases are vertical slices

Each phase cuts a **narrow but complete path through every layer it touches** (schema, API, UI, tests), is demoable or verifiable on its own, and is sized to fit one fresh context window. That is what makes its `verify:` conditions meaningful and its diff reviewable in isolation.

Not a horizontal layer. "All the types", "all the endpoints", "then wire the UI" is a plan whose phases cannot be demoed, cannot be verified until the last one lands, and cannot be reordered. Any prefactoring the slices need goes first, in its own phase.

### Exception: wide refactors

One mechanical change whose **blast radius** fans across the codebase (rename a column, retype a shared symbol, swap a logging call) cannot be a vertical slice. A single edit breaks thousands of call sites at once, so no slice of it lands green. Sequence it **expand, migrate, contract** instead:

1. **Expand.** Add the new form beside the old. Nothing breaks, nothing migrates yet. One phase, depends on `none`.
2. **Migrate.** Move call sites over in batches, each batch its own phase depending on the expand phase. **Size the batch by blast radius**, per package or per directory, small enough that the batch lands green on its own. CI stays green batch to batch because the old form still exists. Independent batches share one dependency, so they sit on the frontier together and can run in any order.
3. **Contract.** Delete the old form once no caller remains, in one phase depending on **every** migrate phase.

When even a single batch cannot stay green alone, keep the sequence and add a final integrate-and-verify phase depending on all of them. Green is promised only there, and the plan says so.

## Rules

- Every task **must** have a `verify:` condition. Transform vague ones:
  - "Add validation" becomes verify: invalid inputs are rejected and error messages display
  - "Fix bug" becomes verify: the scenario that triggered the bug no longer reproduces
  - "Refactor X" becomes verify: existing tests pass before and after, behaviour unchanged
- The Goal is a single verifiable sentence. "Make it work" is not a goal.
- Context is brief. Three to five bullets or a short paragraph, not a design doc.
- Out of scope is mandatory. Explicit scope prevents creep.
- Phase ids are kebab-case, unique within the plan, and permanent. Reordering, renaming or inserting a phase renumbers the headings and nothing else, because nothing points at a number.

## Relationship to the wiki

A plan is a raw source, so it never becomes a wiki page. It is the primary input to distillation.

When `.wiki/` exists, reference the pages the interview relied on by `[[slug]]` in Context, so the trail is explicit. At close, `/build` distils the plan into wiki pages that name this plan as `source` in plain text, never as a link, because `.grimoire/plan.md` is pruned on Done.

When `.wiki/` does not exist, the plan is the only record. Say nothing about distillation.

Because `/build` prunes `plan.md` on Done unconditionally, that record dies with it, taking `## Decisions`, `## Out of scope` and every phase `Notes:` along. So when `.wiki/` does not exist, carry `## Decisions` and `## Out of scope` into `.grimoire/pr.md` before the plan is pruned. That file survives, and the PR body built from it becomes the durable record.
