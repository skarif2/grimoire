# Handoff Format

Handoffs live in `.desk/handoffs/`, named `handoff_{YYYY-MM-DD}-{slug}.md`. Create the folder lazily, only when the first handoff is written.

They are per worktree, like everything else in `.desk/`. A handoff captured while working one ticket stays with that worktree. If the idea needs to outlive the worktree, promote it: turn it into a plan, or distil it into `.wiki/` if the project has one.

When a plan is created from a handoff, ask before deleting the handoff. The plan supersedes it.

## Template

```md
# {Short title of the idea}

**Branch:** {branch name}
**Date:** {YYYY-MM-DD}

## The idea

{Two or three sentences. What it is and why it is worth doing.}

## Why it came up

{One or two sentences. What we were doing when this surfaced, and what made it relevant.}

## Context the next session will need

{Only what is necessary. Reference existing files by path, never copy their content.}

- `.wiki/adr/{file}.md`: {one line on relevance}
- `.wiki/concepts/{file}.md`: {one line on relevance}

Omit this section when nothing in the wiki is relevant, or when the project has no wiki. Never reference `.desk/plan.md` or `.desk/review.md`: they are overwritten and pruned, so the pointer would dangle by the time this handoff is picked up.

## Suggested starting point

Run /plan to grill and scope the idea.
```

## Rules

- Keep it short. A fresh agent reads it in 30 seconds and knows exactly what to do.
- Do not duplicate content from plans, ADRs or wiki pages. Reference by path.
- Redact anything sensitive: API keys, tokens, personal data.
