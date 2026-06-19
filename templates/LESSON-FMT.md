# Lesson File Format

Lesson pages capture **what we learned the hard way** — a distilled takeaway that should change how future work is done. They live in `lessons/` under a project (`docs/[group]/[project]/lessons/`). File naming `lesson_[slug].md`.

A lesson is born when a ticket surfaces something non-obvious: a root cause that took digging, an approach that failed, a constraint discovered mid-implementation. Where a concept says "how it works," a lesson says "what bit us and what to do about it."

Create the `lessons/` directory lazily — only when the first lesson is distilled.

## Template

```md
# {Lesson — short imperative title, e.g. "Guard degenerate caret rects before scrolling"}

**Status:** current | needs-verification | stale
**Updated:** {YYYY-MM-DD}
**Source:** [[{plan-or-review-filename}]] · `path/to/file.ts:line` · PR #{N}

## What happened

{1–3 sentences. The situation and the surprise.}

## Why

{The root cause, in durable terms. Link the mechanism: [[concept_{slug}]].}

## What to do next time

{The actionable takeaway — the rule a future task should follow. This is the payload.}

## Related

- [[concept_{slug}]] — {underlying mechanism}
- [[gotchas#{heading}]] — {the trap, if this hardened into one}
```

## Rules

- **The payload is "what to do next time."** If a lesson doesn't change future behaviour, it's not a lesson — it's a note. Make the takeaway concrete and imperative.
- **Provenance + freshness mandatory.** Cite the ticket/PR/`file:line` it came from; carry `Status:` / `Updated:`.
- **Distinct from gotchas.** A lesson is a *narrative takeaway* (what happened → why → do this). A gotcha is a *one-line trap*. A lesson often spawns a gotcha; link them.
- **Link to the mechanism.** A lesson should point at the `concept_` or `component_` it concerns, so it surfaces when that area is touched.
- **Must appear in `index.md`.** Added in the same distillation pass.
