---
name: recap
description: Recap what got done, in two parts from the same material, a brief for you (a paragraph, then one bullet per change) and a short version to paste for other people. Covers the whole conversation, or only the part the argument names. Lands in chat and in .grimoire/recap.md. Use for /recap, and whenever the user asks for a recap, a summary of what we did, a daily update or a standup line. /build and /review offer it when they finish.
argument-hint: "[the part of the conversation to recap, e.g. the retry fix]"
---

# Recap

Two parts, one source. The brief is for the user, a record of what was done. The short version is for pasting where other people read it. Both come from the same material, so they never disagree.

## Scope

No argument means the whole conversation. An argument names a topic ("the retry fix", "the follow-up on the PR"): recap only the part of the conversation about it and leave the rest out, even though it happened in the same session. If the argument matches nothing in the conversation, say so and stop. Never widen a scoped recap back to everything.

## Material

The conversation is the primary source. It holds why each change was made, what was tried and dropped, and what was decided, none of which the diff can show. The repo backs it with facts:

```bash
ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
BRANCH=$(git branch --show-current 2>/dev/null)
git status --short
gh pr list --head "$BRANCH" --state all --json number,title,state,reviews --jq '.[0]' 2>/dev/null
```

A change belongs in the recap only if the conversation made it. Commits on the branch from before the session, or from someone else, stay out even though they sit in the diff.

Called from `/build` or `/review` right after a run, that run is the material: `/build`'s cumulative diff, the plan `Goal:` and `Notes:`, and the `pr.md` title; `/review`'s PR title and number, verdict and the gist of its findings.

Never invent facts. No ticket numbers, PR links or results nobody produced. A PR number appears only when `gh` returned one.

## The brief

For the user, so `unslop` applies and `voice` does not.

One short paragraph on what the work was for and where it ended up: done, committed, pushed, a PR open, or waiting on someone. Then one bullet per change: what changed and where, with a `path` or `path:line` when it helps, and the reason when the reason is not obvious from the change. A change is one logical change, not one file. Three files edited for one fix are one bullet.

## The short version

Posted under the user's name, so write it through `voice` when one is installed, then apply `unslop`. Without `voice`, keep it plain and first person, and never mention the absence.

- One short paragraph, one or two lines. No headers, no bullets.
- Never mention CI, checks, pipelines or build status.
- Lead with what the work was: the PR title verbatim when there is one, `(#<num>)` only when a number exists. Then what it does and why, for a reader who never opened it. Not a file by file log.

Pick the opening from what happened:

- Work finished, PR new or not opened yet: `Wrapped up <title>. <what it does and why>.`
- Changes to a PR that already had review: `Followed up on <title> (#<num>), <what changed in response>.`
- A review that approved: `Reviewed and approved <title> (#<num>). <what the PR does and why>.`
- A review that asked for changes or a discussion: `Reviewed <title> (#<num>), sent feedback on <the gist>.`
- Work still in progress, no PR: `Worked on <topic>, <where it stands>.`

## Output

In chat, in this order, with nothing after it:

```
**Recap: <PR title, branch or topic>**

<the paragraph>

- <change>
- <change>

Short version (to paste):
> Wrapped up <title>. <what it does and why>.
```

Then save the same to `$ROOT/.grimoire/recap.md`, overwriting the previous run, with `**Date:**` and `**Scope:**` (whole conversation, or the argument) under the title, the brief under `## What we did` and the short version under `## Short version`. Say the absolute path in one line. Never open it in an editor. No `$ROOT` means chat only: write no file, and say so in one line.

```bash
mkdir -p "$ROOT/.grimoire"
EXCLUDE="$(git rev-parse --git-common-dir)/info/exclude"
grep -qxF '.grimoire' "$EXCLUDE" 2>/dev/null || printf '.grimoire\n' >> "$EXCLUDE"
```

There is nothing to post. The short version goes wherever the user shares progress, and that is always their own hand.
