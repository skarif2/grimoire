# Concept File Format

Concept pages are **durable domain knowledge** — the "how this works / why it is this way" that outlives any single ticket. They live in `concepts/` under a project (`docs/[group]/[project]/concepts/`) or group (`docs/[group]/concepts/`). File naming `concept_[slug].md`.

A concept is what a plan should *link to and read from* instead of re-deriving. The scroll-anchoring mechanism, the instance-type model, an auth flow — these are concepts. If a future task in this area would benefit from knowing it, it's a concept.

Create the `concepts/` directory lazily — only when the first concept is distilled.

## Template

```md
# {Concept Name}

**Status:** current | needs-verification | stale
**Updated:** {YYYY-MM-DD}
**Source:** [[{plan-or-review-filename}]] · `path/to/file.ts:line` · PR #{N}

{One-paragraph synthesis of what this is and why it works the way it does — the compiled understanding, not a transcript.}

## How it works

{The mechanism, in durable terms. Reference real code by `path:line`. Keep it current — revise when new sources contradict it.}

## Why it's this way

{The reasoning / constraints / trade-offs that make it non-obvious. Link decisions: [[adr_{slug}]].}

## Related

- [[component_{slug}]] — {why related}
- [[gotchas#{heading}]] — {the trap that lives here}
- [[concept_{slug}]] — {neighbouring concept}
```

## Rules

- **Compiled, not episodic.** Synthesise the understanding; don't paste the plan. A concept reflects *everything learned so far*, updated in place when new sources arrive.
- **Provenance is mandatory.** The `Source:` line cites where the knowledge came from (plan/review/`file:line`/PR) so claims are traceable and the gist's "stale synthesis looks authoritative" failure mode is avoided.
- **Freshness is mandatory.** `Status:` + `Updated:` on every page. Flag `needs-verification` for provisional synthesis; `stale` when newer sources may have superseded it (the lint pass surfaces these).
- **Link generously.** Every concept links to its components, gotchas, decisions, and neighbouring concepts. A concept with no `[[ ]]` links is an orphan.
- **Must appear in `index.md`.** Add the entry in the same pass that creates the page.
- **Revise, don't duplicate.** If a concept exists, update it. Two pages for one concept is a lint failure.
