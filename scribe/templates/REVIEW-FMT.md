# Review Format

The review is a single working file at `.scribe/review.md`, gitignored and per worktree. Each run overwrites it. No dated filenames, no counters, no accumulation. For a PR you re-review, GitHub holds the durable record.

Create `.scribe/` lazily, only when the first review is saved.

## Template

```md
# {PR title or branch name}

**Mode:** staged | local | PR #{number}
**Date:** {YYYY-MM-DD}
**Files changed:** {N}
**CI:** passing | failing | pending | not applicable

## Summary

{One short paragraph on what the change does and whether it achieves its stated goal.}

## Risks

{Specific concerns that could cause bugs, regressions or production issues. Point to the exact file and line. If none, write "None identified."}

## Missing or weak test coverage

{Flag only when source changes have no corresponding test changes and the logic is non trivial. Do not flag config changes, type only changes or pure UI. If coverage is adequate, write "Adequate."}

## Conflicts with project decisions

{Flag any change that contradicts an ADR or an established pattern. Name the page. Omit this section if none.}

## Nitpicks

{Minor style or naming issues, clearly labelled so they are easy to tell apart from real issues. Omit if none.}

## Verdict

**Approve** | **Request changes** | **Needs discussion**

{One sentence justifying the verdict.}
```

## Rules

- Be specific. File names and line numbers, not "this could be improved".
- Distinguish signal from noise. A missing semicolon is not a missing null check.
- Do not flag deliberate decisions. Check the wiki before calling something wrong.
- Do not suggest unrelated improvements. Review what is in the diff.
- Adapt depth to diff size. A two file staged change does not need the structure of a thirty file PR.

## Relationship to the wiki

A review is a raw source, so it never becomes a wiki page.

When `.wiki/` exists, link the `[[adr_slug]]` or `[[concept_slug]]` you checked, so the conflicts section is traceable. At close, `/review` distils durable learnings into wiki pages that name this review as `source` in plain text, never as a link, because `.scribe/review.md` is overwritten every run.

When `.wiki/` does not exist, skip both. Do not mention distillation.
