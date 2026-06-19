# Gotcha File Format

Gotchas are **sharp, one-line traps** — "don't touch X, it's load-bearing", "Y looks unused but isn't", "Z silently fails when W". They are the fastest-payoff knowledge in the vault: a single line can save hours.

Unlike concepts/components/lessons (one file each), gotchas live in a **single `gotchas.md` per project** at `docs/[group]/[project]/gotchas.md`, as a list of short entries. Each entry is a `###` heading so it can be linked precisely: `[[gotchas#{heading}]]`.

Create `gotchas.md` lazily — only when the first gotcha is distilled.

## Template

```md
# {Project} — Gotchas

_Last updated: {YYYY-MM-DD}_

Sharp traps for this project. Each entry: the trap, then why, then the source.

### {Short trap title — e.g. "LINE_BREAK_ANCHOR is load-bearing"}

{One or two sentences: what the trap is and what NOT to do.} Why: {the reason in a clause}.
**Source:** [[{plan-or-review-filename}]] · `path/to/file.ts:line` · PR #{N} · _{YYYY-MM-DD}_

### {Next trap title}

{...}
**Source:** [[...]] · `...` · _{YYYY-MM-DD}_
```

## Rules

- **One trap per entry, one or two sentences.** If it needs more, it's a lesson or a concept — write that instead and leave a one-line gotcha pointing to it.
- **Lead with the don't.** The first words should tell the reader what not to do. They may only read that far.
- **Provenance + date inline.** Each entry carries its `Source:` and the date it was learned, so stale traps can be pruned.
- **Link from the relevant pages.** The `concept_`/`component_` page for the area links to its gotcha via `[[gotchas#{heading}]]`, so the trap surfaces whenever that code is touched.
- **List in `index.md`** under a Gotchas heading, linking each entry by its anchor.
- **Prune dead traps.** When a gotcha no longer applies (the bug was fixed, the file removed), delete the entry — don't leave stale warnings. The lint pass flags gotchas whose cited `file:line` no longer exists.
