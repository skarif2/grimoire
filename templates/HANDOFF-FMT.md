# Handoff File Format

Handoff files live in `docs/[group]/[project]/handoffs/`. Use file naming `handoff_[date]-[slug].md`.

Create the `handoffs/` directory lazily — only when the first handoff is written.

When a plan is created from a handoff, ask before deleting the handoff file — the plan supersedes it.

## Template

```md
# {Short title of the idea}

**Project:** {group/project}
**Date:** {YYYY-MM-DD}

## The idea

{2-3 sentences. What it is and why it's worth doing.}

## Why it came up

{1-2 sentences. What were we doing when this surfaced, and what made it relevant.}

## Context the next session will need

{Only what's necessary to understand the idea. Reference existing files by path — do not copy their content.}

- {~/GRIMOIRE/docs/[group]/[project]/plans/filename.md} — {one line on relevance}
- {~/GRIMOIRE/docs/[group]/[project]/adr/filename.md} — {one line on relevance}

Omit if nothing in docs/ is relevant.

## Suggested starting point

Run /startup to load project knowledge, then /plan to grill and scope the idea.
```

## Rules

- Keep it short — a fresh agent should read it in 30 seconds and know exactly what to do
- Do not duplicate content from plans, ADRs, or context files — reference by path
- Redact any sensitive information (API keys, tokens, PII)
