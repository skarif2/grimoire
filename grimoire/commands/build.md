---
description: "Plan approved: execute it, self-review the change, distil into the wiki, then draft the PR"
argument-hint: "(no arguments, the active plan is .grimoire/plan.md)"
---

Plan approved. Execute now.

## Instructions

1. Locate the plan. There is **one active plan per repo or worktree**, the single file `.grimoire/plan.md`. No partial name matching, and `/build` takes no arguments. Then **ensure `.grimoire/` is excluded from git**, idempotently: only `/wiki-init` writes that exclude line and the wiki is opt in, so on a project that never ran it the plan file would otherwise land in the baseline snapshot and in every `git add`.
   ```bash
   ROOT=$(git rev-parse --show-toplevel)
   PLAN_FILE="$ROOT/.grimoire/plan.md"
   PR_FILE="$ROOT/.grimoire/pr.md"
   [ -f "$PLAN_FILE" ] || echo "No active plan at $PLAN_FILE, run /plan first."   # then stop
   EXCLUDE="$(git rev-parse --git-common-dir)/info/exclude"
   grep -qxF '.grimoire' "$EXCLUDE" 2>/dev/null || printf '.grimoire\n' >> "$EXCLUDE"
   ```
2. Read the plan file with Read, since we edit it later. If its Context section names wiki pages and `.wiki/` exists, read those pages too.

   **Detect phased vs single phase (structural, not a keyword).** If the plan contains a literal `## Phases` section, it is **phased**: follow the **Phased execution** section below instead of steps 3 to 7, then stop. A plan that merely mentions "phase" in prose is *not* phased. With no `## Phases` section, the plan is single phase, continue with steps 3 to 7.
3. Add all tasks to the todo overlay. Then capture a **start of run baseline** before editing anything, using the same non mutating snapshot mechanism as a phase baseline (see **Phased execution, 2. Set the phase baseline**), under the ref `refs/grimoire/baseline/<plan-slug>-run`. This scopes the run's commit proposal later. Non mutating, so the user's index and the manual git invariant are untouched.
4. Execute each task one by one. After completing each task:
   - **Before writing code against a third party library or framework whose current API matters** (a recent version, an unfamiliar call), optionally ground it in current docs via context7 (`resolve-library-id` then `get-library-docs`) to avoid hallucinated or outdated signatures. Pull only the topic you need. Skip for std lib or stable code.
   - Run the task's `verify:` condition to confirm it actually worked
   - If verification fails, fix it before moving on, do not tick off an unverified task
   - Mark it done in the todo overlay only after verification passes
   - Update the plan file: `- [ ]` becomes `- [x]`
5. **Self-review the change (reflect).** Before wrapping up, review your own work once across the same lenses as `/review`, so structural and convention issues get caught here, not by you later. Scope the review to this run's changes via the tree versus tree form against the `-run` baseline (see **Propose commit(s), Scope the run's changes**), so pre-existing dirt and unrelated edits stay out. Adapt depth to the diff: skip for a trivial one file change, run it for anything non trivial. See **Self-review (reflect)** below.
6. When all tasks are complete and the self-review is resolved, first **propose commit(s) for this run** (scope to the `-run` baseline ref, see **Propose commit(s)**, propose only). Then update plan `**Status:** Done`, clean up the run baseline ref, and **prune the plan file** (full prune, no archive, its durable value goes into the wiki in step 7):

   **Before pruning, read the plan's `**Companion:**` line.** When it names a sibling repo's `.grimoire/plan.md`, that ticket has a second half in another repository, and pruning this plan is the last moment anyone is looking. Print the companion path and say plainly whether the other half is still outstanding. Do not go read it, and do not act on it.

   ```bash
   # Stable slug from the plan title (plan.md's basename is not unique across worktrees sharing one .git)
   PLAN_SLUG=$(grep -m1 '^# ' "$PLAN_FILE" | sed 's/^# *//;s/[^A-Za-z0-9 -]//g' | tr '[:upper:] ' '[:lower:]-' | tr -s '-' | cut -c1-40 | sed 's/^-*//;s/-*$//')
   [ -z "$PLAN_SLUG" ] && PLAN_SLUG="plan"
   for ref in $(git for-each-ref --format='%(refname)' "refs/grimoire/baseline/${PLAN_SLUG}-*"); do
     git update-ref -d "$ref"
   done
   rm -f "$PLAN_FILE"   # prune on Done
   ```
7. **Distil into the wiki (draft, then confirm).** See **Deferred distillation** below. **Gate it on `.wiki/` existing.** If the directory is absent the project has not opted in: skip this step entirely and silently, do not create the directory, do not write to it, do not offer to, and do not mention its absence.
8. **Draft the PR and the change summary.** As the last wrap-up step, draft a `pr.md` from the project's PR template (if any) and the three part change summary (files changed, things I did not touch, potential concerns), then end on one line offering a recap. See **PR draft and change summary** below.

## Execution guidelines

- Make the minimum change that solves the problem, nothing speculative
- Touch only what the task requires, don't improve adjacent code or reformat unrelated things
- Match the existing code style
- Remove imports, variables and functions your changes made unused
- If you notice a simpler approach mid execution, mention it but keep going unless it changes scope

## Self-review (reflect)

After all tasks pass their `verify:`, run one self-review pass on the change before wrap-up. This catches structure, naming and convention issues that `verify:` conditions (which are functional) do not. Skip it for a trivial one file change, run it for anything non trivial.

1. **Review the diff once.** Get the diff: when the caller scopes to a baseline (a phase baseline, or the single phase `-run` baseline), use that run's **tree versus tree** diff (see **Propose commit(s), Scope the run's changes**) so pre-existing dirt stays out. For an ad hoc review with no baseline, fall back to `git diff -U3 -- . ':(exclude)*lock.json' ':(exclude)dist/*' ':(exclude)build/*'`. Review across the `/review` lenses: correctness, quality and conventions, spec, tests, security. **The plan is the spec here**, so the spec lens checks the diff against its `Goal:` and its tasks: what the plan asked for and the diff does not do, and what the diff does that no task called for. When `.wiki/` exists, load the project's context pages and the touched components' gotchas and lessons (Grep or Glob under `.wiki/`, or an Explore subagent when the sweep would be wide). Tag each finding Critical, Major, Minor or Nit, and raise it one level if it matches a known gotcha or lesson (name the page).

   **The tests lens is suggestion only inside `/build`.** `rules/code.md` says no tests unprompted, so a coverage gap is never Critical or Major here: report it in **one line** (what is worth covering and why) and let the user decide. **fix safe** never writes a new test. Repairing a test this run broke is repair, not a new test, so it stays in scope.

   Comments, unrequested tests and a quietly lowered bar are the comment police's beat (step 2). Do not re-derive them here.

2. **Call the comment police.** Hand this run's diff, the same one from step 1, to the read-only `comment-police` agent: the Agent tool with `subagent_type: "grimoire:comment-police"` (fall back to the bare `comment-police` if the host does not namespace agents). It is pinned to Haiku and its tools are read only, so it is cheap and structurally cannot edit. It hunts what a long session erodes: comments against `rules/code.md`, tests nobody asked for, a quietly lowered bar. The agent holds the exact contract, so do not restate it here.

   It **reports, it never edits**. Merge its findings into step 1's list, same severity tags and same id scheme, deduping anything you already caught. Skip the call on the same trivial diff that skips the whole pass.

3. **Surface findings and ask.** List them in chat grouped by severity, each with its id, then ask with one `AskUserQuestion`:
   - **Four findings or fewer**: `multiSelect: true`, one checkbox per finding, label the id and a few words, description the fix. Fix what is checked. Skipping them all goes through Other.
   - **More than four**: single choice, "Self-review found N issues. Fix which?"
     - **Fix safe (Recommended)**: I fix the Critical and Major and the clear cut Minor, you keep the judgment calls (never a new test)
     - **Pick by id**: fix only the ones you name, then ask which ids in plain text
     - **Skip**: leave them and proceed (they are still noted at wrap-up)

   **The question is the turn's last action.** Once you have written "Self-review found N issues", the next thing that happens is the user's answer. No Edit, no Write, no re-running a `verify:` between the list and the reply, and never an edit "while waiting". Six of thirty-nine recorded self-reviews fixed code before the user answered, and every one of them took a judgement call away from the user. If there are zero findings, say so and proceed.

4. **Apply approved fixes.** Minimum change per finding, same discipline as the tasks: touch only what the fix needs, match the surrounding style, remove anything the fix made unused.

   **Reach for the strongest mechanism the fix allows**: unrepresentable state beats a lint rule or banned API, which beats a canonical helper, which beats a runtime check.
   The `retro` skill owns that ladder and the reasoning behind each rung, see `${CLAUDE_PLUGIN_ROOT}/skills/retro/SKILL.md`.

   Whatever you leave behind becomes the template, since the next writer copies the surrounding code, so a weak guard propagates itself. And when the fix is structural, ship **only** the structural fix: a comment, a doc line or a rule written down telling the next person to remember is the symptom, not the cure, and it does not survive a fresh context. If the strongest mechanism is out of this run's scope (a new lint rule, a schema change), take the strongest one that fits, say so in one line, and record the gap under **Things I did not touch** rather than silently dropping to prose.

5. **One re-check (bounded loop).** After applying fixes, re-review only the changed lines and re-run the `verify:` of any task whose code you touched.
   - **Clean**: done, proceed to wrap-up and distillation.
   - **A fix introduced a new issue**: surface it and stop. Do not auto loop again.
   - **A prior finding reappears after its fix** (recurring finding tripwire): stop and surface it, the fix is not converging, so the user decides.

   Never run more than this one automatic re-check. Beyond it, the user drives.

## Deferred distillation

Runs once, at ticket close, never mid ticket and never per phase. **Only when `.wiki/` exists.** Check first, and if it does not, skip the whole section without a word.

The finished plan is a raw source. Compile its durable knowledge into the wiki so future work benefits. Load `${CLAUDE_PLUGIN_ROOT}/templates/WIKI-PAGE-FMT.md` before writing any page.

1. Re-read the finished plan **and the actual diff** (the tree versus tree form, see **Propose commit(s), Scope the run's changes**). Identify durable knowledge: a mechanism learned is a **concept**, a module created or heavily touched is a **component**, a non obvious root cause or rejected approach is a **lesson**, a decision with alternatives is an **adr**, a domain term is **context**, a sharp trap is a **gotcha**.
2. For each, decide **new page versus update existing**. Check `.wiki/{concepts,components,lessons,adr,context,gotchas}/` for a page on the same topic. Never duplicate, revise in place. Create a kind folder lazily, only when writing the first page into it.
3. Draft each page at the matching folder (`concepts/`, `components/`, `lessons/`, `adr/`, `context/`, `gotchas/`) as `{kind}_{slug}.md` with the mandatory frontmatter: `summary` (one line under 120 characters, it carries the payload, this is what a session greps), `status` (`current`, `needs-verification` or `stale`), `updated`, and `source`. `source` **names** the originating plan, branch or task as plain text plus durable anchors (`path:line`, PR, commit). Never `[[link]]` the plan: it lives in `.grimoire/`, is gitignored and gets pruned on Done, so the link would dangle. Link related pages with `[[slug]]`, and draft the backlinks on the pages you point at, since a page with no inbound and no outbound link is an orphan. One trap per gotcha file.
4. **Present the drafts as a confirm batch**, each proposed page listed NEW or UPDATE with a one line summary. Do **not** write until the user approves. On `approve`: write the pages. On `revise: <note>`: adjust and re-present.
5. If the change produced nothing durable (a trivial fix), **say so and skip**, never manufacture pages.
6. After the pages are written, **propose the final doc-commit** covering the wiki changes, see **Propose commit(s), Final doc-commit**.

## PR draft and change summary

The final wrap-up step, after distillation and the doc-commit proposal. Both artifacts here, and the recap if the user takes it, are drawn from the **same material**: the plan `Goal:`, the run's cumulative diff (the tree versus tree form, see **Propose commit(s), Scope the run's changes**), and the plan or phase `Notes:`. Do not invent facts (ticket numbers, PR links, deploy order, screenshots), leave the template's placeholders for the user to fill.

These are prose other people read, so both prose skills apply: the `voice` skill when one is installed owns the **register** (how it sounds), the `unslop` skill owns the **tells** (what must not appear). Same pair governs the commit subject and body in **Propose commit(s)**.

### 1. Draft `pr.md` from the project's template

1. **Find the template** (first match wins, case insensitive):
   ```bash
   PR_TEMPLATE=$(find .github docs . -maxdepth 2 -iname 'pull_request_template.md' 2>/dev/null | head -1)
   # also a multi-template dir: .github/PULL_REQUEST_TEMPLATE/*.md (prefer default.md, else the first)
   [ -z "$PR_TEMPLATE" ] && PR_TEMPLATE=$(find .github -maxdepth 2 -ipath '*pull_request_template/*.md' 2>/dev/null | sort | head -1)
   ```
2. **Fill it.** Copy the template **verbatim**, then complete only the prose sections (summary, what changed, why, type of change, test scenarios) from the run's material. **Write every prose section through the `voice` skill when one is installed, and apply the `unslop` skill**: the template owns the structure, `voice` owns the wording inside it, `unslop` owns what must not survive into it. **Keep every section and checklist**, tick a checkbox only when you can do so truthfully (for example tests added), leave the rest unchecked and leave placeholders (`<ticket>`, PR links, deploy order, screenshots) untouched for the user.
3. **No template found**, fall back to a minimal structure:
   ```markdown
   ## Summary
   ## What changed
   ## Why
   ## How to test
   ```
4. **Write it.** Write the filled draft to `$PR_FILE`, overwriting any previous. Like `plan.md` and `review.md` it is per worktree, gitignored and `@` mentionable. Create the folder if needed, then tell the user the path and stop. Never open it in an editor.
   ```bash
   mkdir -p "$ROOT/.grimoire"
   ```

### 2. Change summary

Present it in chat, after the draft. It does not go into `pr.md`. Three parts, in this order, always all three.

**Files changed.** The run's changed file list (tree versus tree), one line each on what changed in it. Not a diff replay.

**Things I did not touch (intentionally).** Every adjacent thing you deliberately left alone, one line each **with its reason**: out of scope for this plan, belongs to a separate ticket, needs a decision from the user, or the strongest fix did not fit this run (see **Self-review, Apply approved fixes**). This is the load-bearing part. It is the receipt for *make the minimum change* and *touch only what the task requires* in **Execution guidelines**, and it surfaces the adjacent problems you found **without acting on any of them**. If there was genuinely nothing adjacent, say that in one line. Never drop the heading.

**Potential concerns.** What could bite: a strictness you chose, a dependency added and its weight, a behaviour change a caller may not expect, an assumption you could not verify. Facts and open questions, no reassurance.

```
Files changed:
- <path>: <what changed>

Things I did not touch (intentionally):
- <path>: <reason>

Potential concerns:
- <concern>
```

### 3. Offer a recap

The last line of the run, after the change summary, and only an offer: `Want a recap? It writes what we did and a short version to paste.` Never produce one unasked. On a yes, run the `recap` skill with this run as its material. Silence is a no.

## Propose commit(s)

After a phase completes (phased) or a single phase run finishes its self-review, build **proposes** a commit for that run's work and lets the user run it. build never runs `git commit` itself and never `git add -A` (the manual git invariant). A proposal reflects the working tree at the moment it is generated, so if the user keeps editing before running it, the proposal can go stale.

### Scope the run's changes (tree versus tree)

A bare `git diff <baseline ref>` compares a tree to the working tree and **omits untracked files**, so it would silently drop files the run created. Instead snapshot the current tree the same non mutating way the baseline was taken, then diff the two trees:

```bash
SCRATCH=$(mktemp -u)
GIT_INDEX_FILE="$SCRATCH" git read-tree HEAD 2>/dev/null   # seed from HEAD, else force added (tracked but gitignored) files drop out
GIT_INDEX_FILE="$SCRATCH" git add -A
CUR=$(GIT_INDEX_FILE="$SCRATCH" git write-tree)
rm -f "$SCRATCH"
BASE=$(git rev-parse <the run's baseline ref>)   # phase baseline, or the single phase run baseline
git diff --name-only "$BASE" "$CUR"              # files changed by this run, new files included
git diff "$BASE" "$CUR" [-- <file>]              # the run's patch (whole run, or one file)
```

`git diff <tree> <tree>` compares two full snapshots, so files the run created appear as additions. This same tree versus tree form is what the cumulative distillation diff uses.

`read-tree HEAD` is what keeps the snapshot honest: `git add -A` alone starts from an empty index and skips ignored paths, so a **force added** file (tracked, but matching `.gitignore`) would be missing from the tree and read as a change on every single run. Both commands write only to `$SCRATCH`, so the user's real index is untouched.

### Build the proposal

1. **Files.** Take the run's changed file list above. `.grimoire` is added to the git common dir's `info/exclude` in step 1, when the plan is located, and `/wiki-init` adds `.wiki` when a project opts into one. With that exclusion in place the plan file never appears in the tree versus tree diff or any `git add`. If step 1's guard did not run (an ad hoc invocation), apply it before snapshotting.
2. **Subject.** Infer the subject style from recent history (`git log --oneline -10`). If there is no history yet, fall back to a plain imperative subject (for example `Add <thing>`). Keep it short. The repo's existing convention wins on **structure** (a `feat(scope):` prefix stays a `feat(scope):` prefix), `voice` governs the **wording** after it and the `unslop` skill applies to it too.
3. **Body.** Draw the why from the phase's `Notes:` (phased) or the plan `Goal:` (single phase), plus what changed. **Write the body through the `voice` skill and apply the `unslop` skill**, it is prose other people read.
4. **Commands.** Emit copy pasteable commands for the user to run or edit, do not run them:
   ```bash
   git add <files of this commit>
   git commit -m "<subject>" -m "<body>"
   ```

### Mixed files (pre-existing dirt)

A file is **mixed** when it was already dirty before the run, that is, it appears in `git diff HEAD <baseline ref> --name-only` (it differs between `HEAD` and the baseline tree). A whole file `git add <file>` would also stage the user's unrelated prior edits, so do **not** propose a plain add for it. Flag it and show its run scoped patch (`git diff "$BASE" "$CUR" -- <file>`) so the user can stage just the run's hunks with `git add -p <file>`. (Known limitation: if the mixed file was *untracked* at baseline, `git add -p` needs a prior `git add -N <file>`.)

### Multiple commits (file disjoint split)

Default to **one** commit per run. When the run's changes fall into clearly separable concerns that map to **disjoint file sets**, propose a grouped split instead, one `git add <group> && git commit` per group, each with its own subject and body. Concerns that share a file cannot be split at the file level: keep them in one commit, or flag that file for manual `git add -p`. Never propose a split that would need the same file in two commits.

### Final doc-commit (after distillation)

Only when `.wiki/` exists and distillation actually wrote pages. The per run proposal covers code and work only. `.wiki/` is its own checkout on the orphan `wiki` branch, so the doc-commit runs there, separate from the feature branch. The pruned plan was in `.grimoire/`, excluded from git, so it never enters this commit and there is no rename to stage:

```bash
git -C .wiki add <written pages: concepts/..., gotchas/...>
git -C .wiki commit -m "wiki: distil <ticket>"
```

Propose only. The user runs it.

## Phased execution

When the plan has a `## Phases` section (detected in step 2), `/build` computes the frontier, runs **one takeable phase per run**, marks it done, and stops with a resume handoff. The user decides whether the next phase runs in this session or a clean one. Single phase plans never enter this section. State lives entirely in the plan file (per phase `Status`, `Baseline`, `Notes`, plus task checkboxes), no separate state file.

### 1. Compute the frontier, pick a phase, or report the plan's state

Each phase carries a stable kebab-case `**Id:**` and a `**Depends on:**` list of ids (see `templates/PLAN-FMT.md`). Selection goes by id, never by position, so reordering or inserting phases changes nothing. The number in each heading is reading order for the user; show it, never select or key anything on it.

Read the phase headers only and decide before touching anything:

- **All phases `Status: done`**: the ticket is complete. Do **not** error. Run the final self-review if not already resolved, then go to *End of ticket* below.
- **Otherwise compute the frontier**: every phase that is `pending` and whose `Depends on` ids are **all** `done`. `none` means no dependency, so it is on the frontier from the start.
  - **Exactly one phase on the frontier**: that is the phase to run.
  - **More than one**: **ask which**, do not assume the first in file order. Say in chat what is still blocked and on what, then one `AskUserQuestion` with an option per takeable phase, labelled `Phase <n>: <name>`, its id and task count in the description. The answer maps back to the id. More than four takeable: the box cannot hold them, so list them in chat as `Phase <n> (<id>)` with task counts and ask for the id in plain text.
  - **Frontier is empty but phases remain**: a dependency cycle, a `Depends on` id that is still `pending` and itself unreachable, or a `Depends on` naming an id that does not exist. **Stop and surface the exact offending phases by id**, do not loop, stall, or guess. The user fixes the plan.

If a phase has no `**Id:**` (a plan authored before ids), derive one from the name in its heading, write it into the plan file, and rewrite any `Depends on` that referenced it by name or number. A heading with no number gets one in file order. Do this before selecting, so baseline refs and later sessions stay stable.

### 2. Set the phase baseline (non mutating working tree snapshot)

When the chosen phase has an empty `**Baseline:**`, snapshot the **full** working tree (including untracked files) without touching the user's real index, then anchor it under a ref so it survives gc on a long ticket:

```bash
SCRATCH=$(mktemp -u)
GIT_INDEX_FILE="$SCRATCH" git read-tree HEAD 2>/dev/null   # seed from HEAD, else force added (tracked but gitignored) files drop out
GIT_INDEX_FILE="$SCRATCH" git add -A
TREE=$(GIT_INDEX_FILE="$SCRATCH" git write-tree)
rm -f "$SCRATCH"
# Stable slug from the plan title (plan.md's basename is not unique across worktrees sharing one .git)
PLAN_SLUG=$(grep -m1 '^# ' "$PLAN_FILE" | sed 's/^# *//;s/[^A-Za-z0-9 -]//g' | tr '[:upper:] ' '[:lower:]-' | tr -s '-' | cut -c1-40 | sed 's/^-*//;s/-*$//')
[ -z "$PLAN_SLUG" ] && PLAN_SLUG="plan"
PHASE_ID=<the chosen phase's Id, e.g. import-csv-endpoint>
git update-ref "refs/grimoire/baseline/${PLAN_SLUG}-${PHASE_ID}" "$TREE"
```

Use the **chosen phase's own id** for `${PHASE_ID}` so each phase gets a distinct ref. A shared literal would make every phase overwrite the same ref and break per phase and cumulative diffs, and a positional number would break the moment phases are reordered or one is inserted. Record `refs/grimoire/baseline/${PLAN_SLUG}-${PHASE_ID}` as that phase's `**Baseline:**` in the plan file. This never stages anything in the user's index and respects the manual git invariant. If the phase already has a `Baseline` (a resumed phase), reuse it, do not re-snapshot.

**Record the ticket baseline once.** The plan carries a plan level `**Ticket baseline:**` line next to `**Status:**` (`templates/PLAN-FMT.md` carries the field). If it is still empty, this is the **first** phase of the ticket to run: write the ref you just created into it with Edit. If it already holds a ref, leave it alone, never overwrite. A plan authored before the field simply gets the line added. This is the only record of which phase ran first, so it has to be written when it happens: a ref pointing at a tree has no `%(creatordate)`, and `refs/grimoire/*` gets no reflog either, since `core.logAllRefUpdates` covers only heads, remotes, notes and `HEAD`. Ref order is not recoverable after the fact.

- That phase's diff and the cumulative diff are taken **tree versus tree** (snapshot the current tree, then `git diff <baseline-tree> <current-tree>`) so files the run created are included, see **Propose commit(s), Scope the run's changes**. A bare `git diff <baseline ref>` omits untracked files. The phase diff uses its own baseline ref. The cumulative diff uses the ref read back from the plan's `**Ticket baseline:**` line, which is the baseline of the phase that ran **first**, not the first phase in file order, since the frontier may have been taken out of order.

### 3. Run the phase (resumable)

1. Add the phase's tasks to the todo overlay.
2. **Re-verify already checked tasks.** For each `- [x]` task in this phase, re-run its `verify:`. If it now fails, un-check it (`- [x]` becomes `- [ ]`) and run it again. This makes a mid phase kill resumable without redoing still passing work.
3. Run each remaining `- [ ]` task with the same execution discipline as a single phase plan (minimum change, match style, run `verify:`, only tick `- [x]` after `verify:` passes).
4. **Per phase self-review (reflect).** Run the **Self-review (reflect)** pass above, scoped to this phase's diff (the tree versus tree form against its baseline ref, see **Propose commit(s), Scope the run's changes**), not deferred to the end. Resolve it as usual before marking the phase done.
5. **Record per phase notes.** Fill the phase's `**Notes:**` with the decisions made, gotchas discovered, and surprises from this phase, so the rationale survives even after this session is compacted. End of ticket distillation reads these notes.
6. Set the phase's `**Status:** done`.
7. **Propose commit(s) for this phase.** Scope to this phase's baseline ref and propose the commit(s), see **Propose commit(s)**. Propose only, the user runs them.

### 4. Offer downstream phase revision

If running this phase changed the picture (an assumption broke, the approach shifted, a later phase now looks wrong), ask before continuing, one `AskUserQuestion`: say in one line what changed and which phase it touches, then **Revise now** (fold the change into the remaining phases) or **Proceed as planned**. Skip the question when nothing changed.

The plan is a living document (refinement mode applies). Fold any approved revisions into the remaining phases. Declining proceeds normally.

### 5. Stop with a resume handoff

If phases still remain, do **not** continue into the next phase and do **not** distil or prune yet. Stop and tell the user, in plain text, since silence means nothing happens:

> Phase <n> (`<id>`) done and marked. Takeable now: Phase <n> (`<id>`), one per takeable phase. Say `continue` or run `/build` to take it here, `/compact` then `/build` for a clean window, or start a fresh session.

Add one nudge when the phase just finished was heavy (many files, several review rounds, a long back and forth): "this one was big, a clean window is probably worth it". It is a hint from the phase's shape, never a gate, because a session cannot measure its own context.

On `continue`, or on `/build` in the same session, re-enter step 1: re-read the plan, recompute the frontier, and snapshot a fresh baseline for the chosen phase. That baseline includes the previous phase's uncommitted work, so the new phase's diff stays scoped to itself. A skill cannot compact or spawn a session, so the clean window is the user's action.

### End of ticket (only when every phase is `done`)

Reached only when step 1 found all phases `done`. Gate both steps on **every** phase being `done`, not on file order or position.

1. **Distil from the cumulative diff plus per phase notes.** Intermediate phases skip distillation entirely, it runs once here, and only when `.wiki/` exists. Distil the whole ticket from the cumulative diff (the **tree versus tree** form against the ref in the plan's `**Ticket baseline:**` line, the baseline of the phase that ran first, so new files are included, see **Propose commit(s), Scope the run's changes**) **and** every phase's `**Notes:**`, so a fresh session that never saw the earlier phases recovers both *what* changed and *why*. Follow the same draft, then confirm flow as **Deferred distillation** above. If the plan carries no `**Ticket baseline:**` (authored before the field, or every phase was already done before this mechanism existed), say so and ask the user which phase ran first, listing the phase `**Baseline:**` refs. Do not guess the order from the refs, it is not stored there.
2. **Prune the plan and clean up baseline refs.** Set the plan `**Status:** Done`, remove this plan's baseline refs, **Before pruning, read the plan's `**Companion:**` line.** When it names a sibling repo's `.grimoire/plan.md`, that ticket has a second half in another repository, and pruning this plan is the last moment anyone is looking. Print the companion path and say plainly whether the other half is still outstanding. Do not go read it, and do not act on it.

   Then **prune the plan file** (full prune, no archive). Re-derive `PLAN_SLUG` here, since a fresh all done session never ran section 2, and grep the title *before* pruning:
   ```bash
   PLAN_SLUG=$(grep -m1 '^# ' "$PLAN_FILE" | sed 's/^# *//;s/[^A-Za-z0-9 -]//g' | tr '[:upper:] ' '[:lower:]-' | tr -s '-' | cut -c1-40 | sed 's/^-*//;s/-*$//')
   [ -z "$PLAN_SLUG" ] && PLAN_SLUG="plan"
   for ref in $(git for-each-ref --format='%(refname)' "refs/grimoire/baseline/${PLAN_SLUG}-*"); do
     git update-ref -d "$ref"
   done
   rm -f "$PLAN_FILE"   # prune on Done
   ```
3. **Propose the final doc-commit.** After the wiki pages are written, propose the doc-commit covering those wiki changes, see **Propose commit(s), Final doc-commit**. Skipped when `.wiki/` does not exist.
4. **Draft the PR and the change summary.** As the last wrap-up step, draft a `pr.md` from the project's PR template (if any) and the three part change summary, all derived from the cumulative diff plus every phase's `Notes:`, then end on one line offering a recap. See **PR draft and change summary** above.
