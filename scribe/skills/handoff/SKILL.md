---
name: handoff
description: Capture a new idea or task that emerged mid-conversation and package it for a fresh session to pick up. Writes to .scribe/handoffs/ in the current worktree. Use when you discover something worth doing separately rather than now.
argument-hint: "[the new idea or task to hand off]"
---

<what-to-do>

A new idea surfaced during this conversation that belongs in its own session. Capture it with just enough context for a fresh agent to start cold, no more.

Do not summarise the current session. Focus entirely on the new idea. If the user passed an argument, that IS the idea; do not invent a different framing.

</what-to-do>

<is-a-handoff-even-the-right-move>

A handoff is one of five moves at a phase boundary, and usually the wrong one. A phase is a chunk of work inside a session (the grilling, the implementation, the QA) and it ends when you think "ok, we're done with that". The gap between two phases is the only place this decision belongs. Mid-phase there is nothing to decide: keep going, or fork the leftover work to a subagent.

The five moves: **continue** (stay put, no context switch), **`/clear`** (empty the window, start from nothing), **handoff** (write a portable file and seed a session anywhere with it), **subagent** (send the task to its own window, get a report back), **`/compact`** (compress this context and seed a fresh session with the summary).

Walk the tree top to bottom. The first yes wins.

1. **Can you continue in this session?** Yes when the next phase needs this one as a primary source (the implementation wants the reasoning verbatim, not a summary of it), or when enough window is left for the next phase to fit. Continue is ruled out first because it is the only move that costs nothing and loses nothing: every other move turns a primary source into a lossy secondary one, and no amount of reading the diff back returns the *why*.
2. **Is the context irrelevant to what comes next?** If the exploration, the decisions and the dead ends are all disposable, `/clear`. Cheapest move on the board, hands back the whole window, and the old session stays resumable. Getting it wrong is one-way, so only when genuinely disposable.
3. **Do you need to hand off?** Only when something is travelling. The whole list: a **new harness** (Claude to Codex), a **new directory** or repo, a **colleague** picking it up, or **forking a side task** you found mid-phase without derailing the current one. What a handoff buys is portability, a file that travels. Nothing travelling means no handoff.
4. **Can the task run AFK?** Scoped tightly enough to finish with nobody steering? Send a **subagent** and leave this session untouched. Automated review is the standard case.
5. **Otherwise `/compact`.** Relevant context, same harness, same directory, and you need to stay in the loop. Pass it an instruction so the summary keeps what the next phase needs. It is the default, not the first reach: it sits last because the four above it are cheaper or more precise.

So this skill should not fire most of the time. When it was invoked and question 1, 2 or 4 answers yes first, say which one and why in a sentence, and do not write a file unless the user still wants one. These are judgement calls, not objective tests. The value is asking them in order, at a boundary, rather than in the middle of the work.

</is-a-handoff-even-the-right-move>

<where-it-goes>

`.scribe/handoffs/handoff_{YYYY-MM-DD}-{slug}.md`, in the current worktree. `.scribe/` is gitignored and per worktree, so a handoff captured while working one ticket stays with that worktree.

Load `${CLAUDE_PLUGIN_ROOT}/templates/HANDOFF-FMT.md` and follow it exactly before writing anything.

```bash
SLUG=$(echo "[short title]" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | cut -c1-40)
DATE=$(date +%Y-%m-%d)
ROOT=$(git rev-parse --show-toplevel)
mkdir -p "$ROOT/.scribe/handoffs"
EXCLUDE="$(git rev-parse --git-common-dir)/info/exclude"
grep -qxF '.scribe' "$EXCLUDE" 2>/dev/null || printf '.scribe\n' >> "$EXCLUDE"
HANDOFF_PATH="$ROOT/.scribe/handoffs/handoff_${DATE}-${SLUG}.md"
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "no branch")
```

Create `.scribe/handoffs/` lazily, only for the first handoff. Write the file with the Write tool.

</where-it-goes>

<context-section>

The template's "Context the next session will need" section points at wiki pages, and the wiki is optional:

```bash
[ -d .wiki ] && ls .wiki
```

If `.wiki/` exists, run `grep -r '^summary: ' .wiki/ --include='*.md'` and pick only the pages whose summaries bear on this idea, and reference them by path with one line each on why they matter. If it does not exist, omit the section. Do not create the folder and do not remark on its absence.

Never reference `.scribe/plan.md` or `.scribe/review.md`: both get overwritten or pruned, so the pointer would dangle by the time this handoff is picked up. Reference by path, never copy content. Redact API keys, tokens and personal data.

</context-section>

<hand-it-over>

Tell the user the handoff path and that `/plan` in a fresh session picks it up. Nothing else: never open the file in an editor, never spawn a window, never start the work. Writing the file is the whole job, and where the user reads it or continues from it is theirs to choose.

</hand-it-over>

<lifecycle>

The handoff is an input, not knowledge. It is superseded the moment a plan exists for it.

When a plan is created from a handoff, **ask before deleting the handoff.** Never delete it silently, and never delete it before the plan file is written.

If the idea needs to outlive the worktree, promote it: turn it into a plan, or, when `.wiki/` exists, distil it into a page. A handoff sitting in `.scribe/` disappears with the worktree.

</lifecycle>

<constraints>

- Short. A fresh agent reads it in 30 seconds and knows exactly what to do.
- No session summary, no duplicated plan or wiki content.
- One handoff per invocation.
- Never write to `.wiki/`, and never create it.

</constraints>
