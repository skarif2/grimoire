# Project knowledge

Two root folders, different lifetimes.

- `.grimoire/` ephemeral, per worktree, gitignored, always available. Holds `plan.md`, `review.md`, `pr.md`, `handoffs/`. Per worktree, so `plan.md` always means the current branch.
- `.wiki/` durable, shared, committed. **Optional.**

**Presence is the switch.** No `.wiki/`: never create it, never write to it, never offer, never mention its absence. `/wiki-init` creates it, and only when asked.

At session start, if `.wiki/` exists, find the pages that bear on the task with `grep -r '^summary: ' .wiki/ --include='*.md'` filtered by task keywords, open only those, follow their links. Otherwise start work.

There is no index file. Each page's `summary` line is the map, so nothing can drift out of date.

Never auto-write the wiki. Draft, confirm, write.
