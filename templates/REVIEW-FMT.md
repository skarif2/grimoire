# Review File Format

Review files live in `docs/[group]/[project]/reviews/`. Use file naming:
- Local/staged: `[date]-[branch-slug]-review-1.md`, `[date]-[branch-slug]-review-2.md`, etc. (counter always included, starts at 1)
- PR: `[date]-pr-[number].md`

Create the `reviews/` directory lazily — only when the first review is saved.

## Template

```md
# {PR title or branch name}

**Mode:** staged | local | PR #{number}
**Date:** {YYYY-MM-DD}
**Files changed:** {N}
**CI:** ✅ passing | ❌ failing | ⏳ pending | — (not applicable)

## Summary

{One short paragraph describing what the change does and whether it achieves its stated goal.}

## Risks

{Specific concerns that could cause bugs, regressions, or production issues. Point to the exact file and line. If none, write "None identified."}

## Missing or weak test coverage

{Flag only when source changes have no corresponding test changes and the logic is non-trivial. Don't flag for config changes, type-only changes, or pure UI. If coverage looks adequate, write "Adequate."}

## Conflicts with project decisions

{Flag if any change contradicts an ADR or established pattern from context files. Include the ADR filename. If none, omit this section.}

## Nitpicks

{Minor style or naming issues. Clearly labelled so they're easy to distinguish from real issues. If none, omit this section.}

## Verdict

**Approve** | **Request changes** | **Needs discussion**

{One sentence justifying the verdict.}
```

## Rules

- Be specific — file names and line numbers, not vague statements like "this could be improved."
- Distinguish signal from noise — a missing semicolon is not the same as a missing null check.
- Don't flag deliberate decisions — check ADRs and context files before calling something wrong.
- Don't suggest unrelated improvements — review what's in the diff, not the surrounding code.
- Adapt depth to diff size — a 2-file staged change doesn't need the same structure as a 30-file PR.

## Wikilinks & distillation

A review is a **raw source**, not a wiki page — it is *not* listed in `index.md`. But durable learnings in it should be distilled:

- **Check the wiki before flagging.** When verifying against decisions/patterns, link the `[[adr_{slug}]]` or `[[concept_{slug}]]` you checked, so "Conflicts with project decisions" is traceable.
- **At close, `/review` distils durable PR learnings** — new gotchas, component notes, lessons — into the wiki layer (draft → you confirm), linking those pages back to this review via their `Source:` line. The review file stays a dated record.
