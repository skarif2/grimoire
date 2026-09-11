# Project knowledge

Two root folders, different lifetimes.

- `.scribe/` ephemeral, per worktree, gitignored, always available. Holds `plan.md`, `review.md`, `pr.md`, `brief.md`, `message.md`, `recap.md` and `handoffs/`. Per worktree, so `plan.md` always means the current branch. Everything but `handoffs/` is overwritten each run: nothing there is a durable record.
- `.wiki/` durable, shared, committed. **Optional.**

**Presence is the switch.** No `.wiki/`: never create it, write to it, offer it, or mention its absence. Only `/wiki-init` creates it, only when asked.

At session start, if `.wiki/` exists, find the pages that bear on the task with `grep -r '^summary: ' .wiki/ --include='*.md'` filtered by task keywords, open only those, follow their links. Otherwise start work.

There is no index file. Each page's `summary` line is the map, so nothing can drift out of date.

Never auto-write the wiki. Draft, confirm, write.
