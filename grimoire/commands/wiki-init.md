---
description: Wiki init, opt this repo into a shared .wiki on an orphan branch
---

Opt the current repo into a wiki. Run once per repo.

Only do this when the user asks. A repo without `.wiki/` has deliberately not opted in, and sharing knowledge may be against that project's policy.

## What it does

One wiki checkout per repo, on an orphan branch named `wiki`, placed beside the git common directory. Every worktree points at that single checkout, so a page written from one branch is readable from all of them with no commit, no merge and no pull. The orphan branch shares no history with `main`, so no feature branch ever contains a wiki file and there is nothing to conflict.

```bash
set -e
COMMON=$(cd "$(git rev-parse --git-common-dir)" && pwd)
WIKI_HOME="$(dirname "$COMMON")/.wiki"
WIKI_PARENT=$(dirname "$WIKI_HOME")

if [ ! -e "$WIKI_HOME" ]; then
  git worktree add --orphan -b wiki "$WIKI_HOME"
  git -C "$WIKI_HOME" commit --allow-empty -m "wiki: init"
fi

grep -qxF '.grimoire' "$COMMON/info/exclude" 2>/dev/null || printf '.grimoire\n' >> "$COMMON/info/exclude"
grep -qxF '.wiki' "$COMMON/info/exclude" 2>/dev/null || printf '.wiki\n' >> "$COMMON/info/exclude"

git worktree list --porcelain | sed -n 's/^worktree //p' | while read -r WT; do
  [ -e "$WT/.git" ] || continue
  [ "$WT" = "$WIKI_HOME" ] && continue
  [ "$WT" = "$WIKI_PARENT" ] && continue
  ln -sfn "$WIKI_HOME" "$WT/.wiki"
done

echo "wiki at $WIKI_HOME"
git -C "$WIKI_HOME" status --short --branch | head -1
```

The branch name is explicit because git rejects a ref whose path component starts with a dot, so `--orphan .wiki` on its own fails.

Exclusion goes in the common git directory, never a tracked `.gitignore`. It is untracked, it covers both folders together, and every worktree created later inherits it, so nothing you add here can reach a shared file in a company repo.

The patterns carry no trailing slash on purpose. A pattern ending in `/` matches directories only, and in a multi worktree repo `.wiki` is a symlink, which git does not count as one. With the slash it shows up as untracked in every worktree.

The link loop walks **every** worktree, not just the one you ran from, which is what makes the single checkout readable from all of them. `git worktree list --porcelain` enumerates them; the `.git` test drops the bare repository entry, which is a git directory and not a checkout; the two path tests skip the wiki checkout itself and the directory `.wiki` already sits in. `ln -sfn` replaces an existing link in place, so re-running the command changes nothing.

In a repo laid out as a bare directory beside its worktrees, `.wiki` lands as a sibling of the worktrees and each one gets a symlink. In an ordinary single tree repo, `.wiki` sits at the repo root and no symlink is needed.

A worktree added later has no link, since the loop only sees what existed when it ran. Run `/wiki-init` again, or create the link at worktree creation time with `ln -sfn "$WIKI_HOME" <new-worktree>/.wiki`.

## Pushing it

Only when the project permits sharing. Propose the command, never run it.

```
git -C .wiki push -u origin wiki
```

A coworker then gets it with `git worktree add ../wiki wiki`. Their plain clone stays clean, since nothing on `main` changes. Worth adding a line to the project README pointing at the branch, because they will not find it otherwise.

Before proposing a push, check that the repo actually allows it. Branch protection rules that require a naming pattern, or CI that builds every branch, will both trip on an orphan branch.

## After it exists

Report the path and stop. Do not create any pages. Do not scaffold folders. They get created lazily when the first page is distilled, by `/build` or `/review`.
