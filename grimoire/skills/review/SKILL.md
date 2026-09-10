---
name: review
description: Multi-lens code review (correctness, quality, spec, tests, security) for staged changes, local branch diffs, or open PRs. Defaults to one budgeted inline pass and fans out to parallel lens agents only when the diff is wide enough to say why. Severity-rated, escalates findings that match the project's own gotchas and lessons, and writes the paste-ready message the verdict calls for, an approval on Approve or a change request on Request changes. Use /review for local diff, /review staged for pre-commit, /review <number or URL> for a GitHub PR.
argument-hint: "[staged | current | PR number | PR URL]"
---

# Review

## Modes

Detect the mode from the argument.

- No argument: **local**, the current branch diffed against its base.
- `staged`: **staged**, what is about to be committed.
- `current`: **pr**, find the open PR for the current branch and review that.
- A PR number or a GitHub PR URL: **pr**, full PR review with CI status, existing comments and linked issues.

## Noise exclusions

Every diff command carries these pathspecs. They add bytes without signal.

```
-- . :(exclude)*lock.json :(exclude)*.lock :(exclude)pnpm-lock.yaml :(exclude)bun.lockb :(exclude)dist/* :(exclude)build/* :(exclude).next/* :(exclude)coverage/* :(exclude)*.svg :(exclude)*.png :(exclude)*.min.js :(exclude)*.map :(exclude)__snapshots__/*
```

## Gathering the diff

Write the diff to a temp file and keep the path, and keep the changed-file list in `$CHANGED`, because triage and every dispatch below read both. Parallel reviewers open the file themselves, so a large diff is never pasted into the conversation once per lens.

```bash
DIFF=$(mktemp -t review-diff)
```

**staged**

```bash
git diff --staged -U3 <exclusions> > "$DIFF"
CHANGED=$(git diff --staged --name-only)
```

**local**

```bash
BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
BASE=${BASE:-main}
if git rev-parse --verify --quiet "origin/$BASE" >/dev/null; then
  REF="origin/$BASE"
elif git rev-parse --verify --quiet "$BASE" >/dev/null; then
  REF="$BASE"
else
  REF=""
fi
[ -n "$REF" ] && git diff "$REF...HEAD" -U3 <exclusions> > "$DIFF"
CHANGED=$(git diff "$REF...HEAD" --name-only)
```

**The base ref has to resolve.** `origin/HEAD` is unset on a manually added remote and in most bare-repo worktree layouts, so the `main` fallback can name a ref that does not exist: `git diff` then exits 128, the redirect leaves a zero byte file, and the lenses review nothing and report a clean branch. Verify the ref first, fall back to the local branch, and if neither resolves, stop and ask the user for the base instead of guessing.

**An empty diff is never a clean review.** After writing `$DIFF`, check it: `[ -s "$DIFF" ] || echo "empty diff"`. Empty means say so, name the base you tried, and stop. Never dispatch a lens against an empty file.


**pr**

Resolve the number first. From a URL, parse the trailing number, and if that fails abort with "Could not parse a PR number from that URL." From `current`, resolve the branch:

```bash
gh pr list --head "$(git branch --show-current)" --state open --json number,title
```

One hit, use it. Several, list them and ask which. None, say there is no open PR for this branch and fall back to local mode.

Then fetch metadata and the diff:

```bash
gh pr view <number> --json number,title,body,author,baseRefName,headRefName,state,statusCheckRollup,reviews,files
gh pr diff <number> > "$DIFF"
CHANGED=$(gh pr view <number> --json files --jq '.files[].path')
```

If the PR does not exist, abort with "PR #<number> not found."

**Whose PR is it.** This decides what the review is allowed to do, so settle it here, not later:

```bash
ME=$(gh api user --jq .login 2>/dev/null)
AUTHOR=$(gh pr view <number> --json author --jq .author.login)
```

`AUTHOR` is not `ME` means you are a reviewer on someone else's work. You do not touch their code, you do not offer to, and you do not propose a plan to. The deliverable is the review file plus one postable message, nothing else. See **Fix, plan, or leave it**.

Inline review comments, only if there are more than a handful:

```bash
gh api "repos/{owner}/{repo}/pulls/<number>/comments" --jq '.[] | "[\(.path)] \(.user.login): \(.body)"'
```

**Re-review tracking.** When prior review comments exist, they are the change request of record and GitHub is the source of truth, not any local file. Cross-check each prior finding against the updated diff and classify it resolved, still-open or newly-introduced. Lead the review with that summary, then review the new delta. **The delta is also what the engine is sized on**, see **Review engine**: a second round is nearly always an inline pass, because what moved since the last one is nearly always small.

Linked issues in the PR body (`#NNN`, `fixes #NNN`, `closes #NNN`) are worth pulling: `gh issue view <n> --json title,body`.

## The spec

The most useful finding a review produces is often not a bug, it is that the change does something nobody asked for, or quietly skips something they did. That needs a written spec to check against, so find one before dispatching. In order:

1. The linked issue from the PR body or the branch name (`gh issue view <n> --json title,body`), which pr mode has already fetched.
2. `.grimoire/plan.md` in this worktree, when the branch was built from a plan.
3. A path the user passed as an argument.
4. Ask the user, once, only if the diff is large enough to be worth it.

Found one, the spec lens runs against its text. Found none, the spec lens is skipped and the review says so in one line. Never reconstruct a spec from the diff and then grade the diff against it, because that always passes.

## Triage

These are **signals, not gates**. They tell you what the diff contains so you can judge the engine and the lens set; they do not decide it for you. Run once, on flags only, before any dispatch. A file count cannot tell that three of five changed files are a barrel export, a styled block and a snapshot, and that judgement is the whole job here.

```bash
LINES=$(wc -l < "$DIFF" | tr -d ' ')
COUNT=$(printf '%s\n' "$CHANGED" | grep -c . || echo 0)

printf '%s\n' "$CHANGED" | grep -Ev '\.(md|json|ya?ml|toml|lock|snap|txt)$|^docs/|^\.github/' | grep -q . \
  || echo "TRIAGE no-source"

printf '%s\n' "$CHANGED" | grep -qE '\.(test|spec)\.|_test\.|/(tests?|__tests__)/' \
  && echo "TRIAGE tests-moved" || echo "TRIAGE no-test-touched"

printf '%s\n' "$CHANGED" | grep -Eiq 'auth|login|session|token|password|crypt|secret|permission|policy|role|acl|sql|migration|api/|route|endpoint|middleware|upload|sanitiz|escape|cors|csrf' \
  && echo "TRIAGE security-path"
awk '/^\+\+\+ b\// { f=$2; skip = (f ~ /(\.(test|spec)\.|_test\.|\/(tests?|__tests__)\/)/) }
     !skip && /^\+/ && /child_process|eval\(|dangerouslySetInnerHTML|innerHTML|process\.env|\.raw\(|execSync/ \
       { print "TRIAGE security-pattern " f ":" $0; exit }' "$DIFF"
```

**Reading the signals.**

- `TRIAGE no-source`: docs, config or lockfiles only. Read it yourself, no lenses, say so.
- `TRIAGE no-test-touched`: the change moved no test. Worth the tests lens if it changed behaviour, not if it is styling, types or copy. `tests-moved` means the author already thought about it, so the lens is checking their work rather than hunting an absence.
- `TRIAGE security-path` and `security-pattern`: a name matched, which is not the same as a surface. The pattern scan prints the offending line so you can dismiss it in one look, since `document.body.innerHTML = ''` in a teardown is not an attack surface. No signal at all is a real answer: skip the lens.

**A flag is a prompt, not a verdict.** Every one of these is cheap to overrule with a reason. What you must not do is treat a firing signal as an obligation, because two of them fire on almost every real diff and a rule built on them is a constant wearing a signal's clothing.

**Budget per lens**, counted in tool calls. Pass it in the dispatch, because the agent treats it as a ceiling.

| diff size | correctness, quality | spec, tests, security |
|---|---|---|
| under 300 lines | 8 tool calls | 6 |
| 300 to 1500 lines | 12 | 8 |
| over 1500 lines | 15 | 10 |

These are calibrated, not guessed. A lens spends about two turns per tool call, and its whole context is re-read on every one of them, so cost climbs with the square of the dig while findings flatten out early. On a 2000 line diff a fifteen call correctness lens costs 45% of an uncapped one and still reaches the third-hop file where the real bug usually sits. Twelve does not. Raise a budget when a lens says it was cut short on something load bearing, never by default.

**State the engine in one line at the top of the review**, naming the path and why, the lenses that ran, the ones skipped and why, and the budget. "Inline, 5 files but 3 substantive" and "Path A, 62 files across four subsystems" are both good lines. The user has to be able to see what was not looked at, and to disagree with the call.


## Project knowledge

Only when `.wiki/` exists. Check first, and if it is absent skip this whole section silently.

```bash
[ -d .wiki ] && grep -r '^summary: ' .wiki/ --include='*.md'
```

There is no index file: each page's `summary` line is the map. From the touched paths pick the pages whose summaries match, then Read only those and follow their `[[slug]]` links. Decisions live in `.wiki/adr/`, domain terms in `.wiki/context/`, mechanisms in `.wiki/concepts/`, traps in `.wiki/gotchas/`, hard-won history in `.wiki/lessons/`. When the diff touches many areas and picking pages by hand would mean opening a dozen files, send an Explore subagent at `.wiki/` with the changed-file list and ask it to return the relevant slugs plus one line each.

**Verifying library API usage.** When correctness hinges on a third-party API being current rather than remembered, confirm it against real docs before flagging or clearing it: context7 (`resolve-library-id` then `get-library-docs`) for the one symbol, or WebFetch on the doc page. Skip for standard library and stable APIs.

## Review engine

The lenses, in this fixed order. Correctness and quality carry any review. Spec runs when a spec was found, tests and security when the signals and your own read of the diff say there is something there.

**One inline pass is the default.** Fan out only when you can say why in a sentence, and put that sentence in the engine line. This is the opposite of the usual instinct and it is deliberate: across 27 recorded reviews the inline pass returned a median of 12 findings, the same as the fan-outs, at a third of the cost. When you cannot name the reason, there is no reason.

**The test is signal, not size.** Ask whether parallel agents would find anything you would not, which is a different question from how many lines changed. A wide diff whose changes are all the same kind of change is one reader's job; a narrow diff where the security surface and the test story genuinely sit in different code is not. Two things to weigh before the line count:

- **How much of it is substantive.** Count the files that carry logic, not the files git listed. Five changed files where three are a barrel export, a styled block and a snapshot is a three file review.
- **Whether one reader can hold it at once.** If you can read the whole diff and keep it in your head, lenses are five readings of the same thing, and their reports will overlap rather than divide.

**On a re-review, the unit is the delta, not the PR.** When a previous round exists, the engine is sized on what changed since it, and the older findings are re-checked rather than re-derived. A 2000 line PR whose second round moved 90 lines is a 90 line review. Cross-check the prior findings against the current files, then review the delta, and say in the engine line which delta you sized on.

- **correctness**: logic errors, null and undefined, race conditions, edge cases, and performance defects (N+1, unbounded work, needless re-renders)
- **quality**: naming, duplication, complexity, convention compliance, module boundaries and layering, plus the smell baseline below
- **spec**: requirements missed, behaviour nobody asked for, requirements implemented wrong
- **tests**: coverage gaps for the diff, mock completeness, determinism. Do not demand tests for config-only, type-only or pure UI changes.
- **security**: input validation, authz gaps, secret and PII exposure, injection

**Path B, single inline pass. The default.** Same lenses, same smell baseline, done yourself in one sequential pass, with the budget below as a ceiling you hold yourself to. Everything downstream is identical, including the no-rerank rule.

**Path A, parallel reviewers. The exception.** Only with a stated reason, and only when the host exposes sub-agent dispatch. Run the selected lenses in parallel through the dedicated reviewer agent: the Agent tool with `subagent_type: "grimoire:review-lens"` (fall back to the bare `review-lens` if the host does not namespace agents), one dispatch per lens. That agent is read-only, so no reviewer can edit. Do not improvise a reviewer prompt. Pass each dispatch the lens name, the diff temp file path, **the budget from triage**, and the changed-file list, plus the wiki pages loaded above. Pass the spec text to the spec lens and the smell baseline below, in full, to the quality lens, because neither agent has any other access to them.

**Give each lens the diff once and let it stop.** The whole diff is re-read on every turn a lens takes, so an unbudgeted lens pays for the diff again on turn forty. That is what the budget is for, and it is not negotiable to buy thoroughness.

**Do not re-derive what the lenses already evidenced.** Every finding arrives with an evidence level, which exists so the caller does not have to go and look again. Reading the files yourself after four agents just read them is the most expensive way to run this skill: it is serial where they were parallel, unbudgeted where they were capped, and it lands in the one context that carries the whole review. Take the findings as reported and put the evidence level on the page.

Two exceptions, both narrow. **A finding at evidence level 1** is unverified by its own admission, so either get it to level 2 with a single targeted read or report it as unverified in those words. **A lens that says its budget cut it short** on something load bearing gets that one lens re-dispatched, with a larger budget and a narrowed brief. One targeted second pass costs less than doing every lens's job again yourself.

**Never rerank across lenses.** Collect every agent's findings and report them side by side, one block per lens, in the fixed order above. Deduplicate an identical finding raised by two lenses, and do nothing else to the set: never merge the lenses into one list, never reorder them against each other, never pick a single worst finding across lenses. The lenses are separate on purpose, and the failure mode is one axis masking another, a correctness finding burying a spec mismatch it has nothing to do with. Severity ranks findings inside a lens, never between lenses.

A host with no sub-agent dispatch has no choice: Path B, always.

## Smell baseline

The quality lens always carries this fixed set of Fowler code smells (_Refactoring_, ch.3). It applies even when the repo documents nothing. Two rules bind it, and both must be honoured:

- **A documented repo standard always overrides the baseline.** Where the wiki, a linter config or a written convention endorses something the baseline would flag, the standard wins and the smell is suppressed.
- **Every smell is a judgement call, never a violation.** Report it as a labelled heuristic ("possible Feature Envy"), Minor or Nit by default, and skip anything tooling already enforces.

Each smell reads *what it is* then *how to fix*. Match against the diff, not the surrounding code.

- **Mysterious Name**: a function, variable, or type whose name does not reveal what it does or holds. Fix: rename it; if no honest name comes, the design is murky.
- **Duplicated Code**: the same logic shape appears in more than one hunk or file in the change. Fix: extract the shared shape, call it from both.
- **Feature Envy**: a method that reaches into another object's data more than its own. Fix: move the method onto the data it envies.
- **Data Clumps**: the same few fields or params keep travelling together (a type wanting to be born). Fix: bundle them into one type, pass that.
- **Primitive Obsession**: a primitive or string standing in for a domain concept that deserves its own type. Fix: give the concept its own small type.
- **Repeated Switches**: the same `switch` or `if` cascade on the same type recurs across the change. Fix: replace with polymorphism, or one map both sites share.
- **Shotgun Surgery**: one logical change forces scattered edits across many files in the diff. Fix: gather what changes together into one module.
- **Divergent Change**: one file or module is edited for several unrelated reasons. Fix: split so each module changes for one reason.
- **Speculative Generality**: abstraction, parameters, or hooks added for needs the spec does not have. Fix: delete it; inline back until a real need shows.
- **Message Chains**: long `a.b().c().d()` navigation the caller should not depend on. Fix: hide the walk behind one method on the first object.
- **Middle Man**: a class or function that mostly just delegates onward. Fix: cut it, call the real target direct.
- **Refused Bequest**: a subclass or implementer that ignores or overrides most of what it inherits. Fix: drop the inheritance, use composition.

## Severity and escalation

Tag every finding.

- **Critical**: must fix before merge (bugs, security, data loss, regressions)
- **Major**: should fix before merge (convention violations, missing tests, architectural smells)
- **Minor**: nice to fix (style, naming, small improvements)
- **Nit**: optional

Then escalate against the project's own knowledge, when `.wiki/` exists. If a finding matches a known gotcha or lesson, raise its severity one level and name the page: "Major (escalated from Minor): trips [[gotcha_mdf_visibility_needs_search_view]]." The review gets sharper as the wiki grows.

## Evidence ladder

A review that sounds right reads the same whether it is true or not. So every safety or correctness claim carries a label saying where its evidence stopped. Get each claim as far down the ladder as is cheap, then say where it landed.

1. **You said so.** Worthless on its own.
2. **You pointed at the line.** A real `file:line`, or the library's own source.
3. **You showed the bad case cannot happen.** You walked the failure step by step and it does not reach.
4. **You ran it.** A script or test that calls the real code and fails loud if you are wrong.
5. **You reproduced it in the running app.**

Label every Critical and Major finding `evidence: 2` and so on, and label the verdict with the lowest level any blocking finding reached. A claim that stopped at 1 is stated as unverified, in those words, never as settled prose. Levels 4 and 5 are optional: this is a read-only review and running code is a bonus, not a requirement. The point is that an unverified claim looks unverified on the page.

## Output

Load `${CLAUDE_PLUGIN_ROOT}/templates/REVIEW-FMT.md` for the format. Adapt depth to diff size. Sections in short:

Title, then **Mode**, **Date**, **Files changed**, **CI** (passing, failing, pending, not applicable). Then Summary, Risks (each with severity, `file:line` and its evidence level, flagging the escalated ones), Missing or weak test coverage, Conflicts with project decisions, Nitpicks, Verdict. Keep the Risks grouped by lens so the no-rerank rule survives into the file.

Derive the verdict from the worst severity present. Any Critical means **Request changes**. A Major with no Critical is a judgment call, default to **Needs discussion** unless the Majors are clearly optional. Only Minor and Nit means **Approve**. One sentence justifying it, plus the verdict's own evidence label.

**The bar is code health, not perfection.** Approve a change that definitely leaves the codebase better off, even when it is not how you would have written it. Preference is not a defect: a finding that cannot name what breaks, what it costs to live with, or which documented standard it violates is a Nit at most, and a pile of Nits never adds up to Needs discussion. Before settling on anything worse than Approve, check that each blocking finding names a real consequence. If the honest count of those is zero, the verdict is Approve with the rest carried as follow-up.

Save the review to `.grimoire/review.md`, overwriting the previous run. No dated filenames, no accumulation. For a PR you re-review, GitHub holds the durable record.

```bash
mkdir -p .grimoire
```

Then tell the user the path. Never open it in an editor: the file is `@` mentionable and the user opens what they want to read.

Give every finding an id in the file (`C1`, `M2`, `N3`, severity letter plus a number) so the user can name it in the next step.

Then produce the message the verdict calls for: the approval message on **Approve**, the change request on **Request changes** or **Needs discussion**. Never both. Produce the daily update too, whatever the verdict, but only if a `voice` skill is installed.

## Fix, plan, or leave it

**Someone else's PR ends here.** When `AUTHOR` is not `ME`, the review is finished the moment the file is saved and the message is drafted. Do not offer to fix, do not offer a plan, do not suggest edits the author did not ask for, do not open their files to prepare one. Say what you found, hand over the change request or the approval message, and stop. A reviewer who arrives with patches has stopped reviewing and started taking over, and it is the author's PR to change. This is the common case for `/review <number>`, so treat the offer below as the exception rather than the default.

For your own work (local mode, staged mode, or a PR you authored), a review that stops at the file is a dead end, so after saving it present the findings grouped by severity and ask, in the same options style `/build` uses:

> Review found N issues. What next?
> - **fix safe**: I fix the Critical and Major and the clear cut Minor, you keep the judgment calls
> - **fix: `<ids>`**: fix only the ones you name
> - **plan**: run `/plan` seeded with the Critical and Major findings
> - **skip**: leave them, the file keeps the record

**Fix nothing until the user chooses.** Zero findings, say so and move on.

**The tests lens is report only.** A coverage gap is reported, never fixed, because `rules/code.md` forbids tests nobody asked for. **fix safe** never writes a test: say the gap stands and let the user ask for it.

On a fix, minimum change per finding, match the surrounding style, then re-check the changed lines once and stop. In **pr** mode this only ever applies to a PR you authored, and only when its branch is checked out here; otherwise say so and stop. On **plan**, hand `/plan` the Critical and Major findings with their `file:line` as the seed and let it drive.

## Approval message

Only for **Approve**. Skip it entirely for Request changes and Needs discussion. This one gets posted under the user's own name, so **write it through the `voice` skill when one is installed, and apply the `unslop` skill**. `voice` owns how it sounds, `unslop` owns the tells it must not carry, the rules below own what goes in it. Without a `voice` skill, keep it plain and first person.

- One or two lines. No headers, no bullets.
- Never mention CI, checks, pipelines or build status.
- Clean PR: just the approval line.
- Leftover Minor or Nit findings, or a pending Copilot or other review, still approve, then add one `NOTE:` line framing them as a follow-up and explicitly not a blocker. Several small things get summarised in that one line, not listed. Critical and Major findings never appear here, because they change the verdict.

```
Approval message:
> LGTM, clean and well scoped, happy to approve.
> NOTE: the inline type-guard tidy-up is a nice-to-have follow-up, not a blocker.
```

Write it to `.grimoire/message.md` as well, so posting it is one flag away. See **Posting it**.

## Change request

Only for **Request changes** and **Needs discussion**. Skip it entirely for Approve, which has its own message above. This one gets posted under the user's own name, so **write it through the `voice` skill when one is installed, and apply the `unslop` skill**. `voice` owns how it sounds, `unslop` owns the tells it must not carry, the rules below own what goes in it. Without a `voice` skill, keep it plain and first person.

**Write it for the author, not for the reviewer.** The person reading it did not run the review, does not have the file open, and may not share your first language. Plain words, short sentences, no severity labels, no evidence levels, no lens names, no finding ids. Those belong in `.grimoire/review.md`, which is yours. Say what goes wrong, say when it goes wrong, say what would fix it.

**What earns a place.** Only these three, and nothing else:

- A blocker: the change does not work, or breaks something that worked.
- A regression **this PR introduced**. A problem the diff merely sits next to is not one.
- Something promised in an earlier round of review and still not delivered.

Everything else stays out, including every Minor and Nit, every judgement call, and every pre-existing problem the author did not cause. A change request that lists twelve things trains the author to skim it. Three real ones get fixed.

If nothing survives that filter, the verdict was wrong. Say so, and go back and settle it before writing anything to post.

**Shape.** One line saying what the PR does and that it is close. Then one bullet per item: what breaks, when, and the fix direction in a few words. Reference the file plainly (`TreeView.tsx`), not as `path/to/file.ts:451`, unless the line number is the only way to find it. No headers. Never mention CI, checks, pipelines or build status. Close with one line making clear the rest is fine, so a request for changes does not read as a rejection.

On a re-review, lead instead with what is now resolved, then list only what is still open and what is newly broken. Never repeat a point the author already fixed, and never repeat a point another reviewer already made.

Write it to `.grimoire/message.md` too, and list the findings that earned an inline anchor with their `file:line`. See **Posting it**.

```
Change request:
> Nice fix, the tree part works well. Two things before I approve.
>
> - In the list view, rescheduling from the right click menu loses focus
>   now. The dialog used to put focus back and this change turns that off
>   for the list. Passing undefined instead of the no-op restorer should
>   sort it.
> - The date shortcut in the account selector is not part of this ticket.
>   Happy either way, but it is easier to review and revert on its own.
>
> Rest looks good to me.
```

## Posting it

A review is one GitHub review, not a body plus a scattering of loose comments. Bundle the verdict, the message and every inline note into a single API call, so the author gets one notification and one thread to answer.

**Draft, show, confirm, post. In that order, every time.** Posting is outward facing and it is under the user's name, so it never happens on the same turn it was drafted and never without an explicit yes. Show the message and the inline comments in chat first, offer to post, and if the user says nothing about posting, hand over the command and stop. Same rule the ticket brief follows in `/plan`.

**Which findings go inline.** Only the ones the message already names: a blocker, a regression this PR introduced, or a promise not kept. Each needs a real `file:line` inside the diff. Everything else stays in `.grimoire/review.md`, which is yours. A review carrying twelve inline nits trains the author to collapse the whole thread.

**Body only**, when nothing needs anchoring to a line:

```bash
gh pr review <number> --approve         --body-file .grimoire/message.md
gh pr review <number> --request-changes --body-file .grimoire/message.md
gh pr review <number> --comment         --body-file .grimoire/message.md
```

**Body plus inline comments**, one review:

```bash
cat > /tmp/review.json <<'JSON'
{
  "event": "REQUEST_CHANGES",
  "body": "<the change request, voice applied>",
  "comments": [
    { "path": "src/hooks/useSingleLinearScheduling.ts", "line": 225, "side": "RIGHT",
      "body": "<one finding, in plain words>" }
  ]
}
JSON
gh api "repos/{owner}/{repo}/pulls/<number>/reviews" --method POST --input /tmp/review.json
```

`event` is `APPROVE`, `REQUEST_CHANGES` or `COMMENT`, and it has to agree with the verdict the review file already reached.

**Check every anchor before you post.** `line` is the line number on the post-change side, and GitHub rejects the **entire** review with a 422 if one comment points outside the diff hunks. One bad number loses the whole thing, so verify first rather than find out from the API:

```bash
awk '/^\+\+\+ b\// { path=substr($2,3); next }
     /^@@ / { match($0, /\+[0-9]+(,[0-9]+)?/); spec=substr($0,RSTART+1,RLENGTH-1)
              n=split(spec,p,","); start=p[1]+0; len=(n>1?p[2]+0:1)
              if (path!="" && len>0) print path"\t"start"\t"(start+len-1) }' "$DIFF" > /tmp/hunks.tsv

python3 - /tmp/review.json <<'PY'
import json,sys
rows=[l.split("\t") for l in open("/tmp/hunks.tsv").read().splitlines() if l]
ok=lambda p,n: any(r[0]==p and int(r[1])<=n<=int(r[2]) for r in rows)
bad=[f'{c["path"]}:{c["line"]}' for c in json.load(open(sys.argv[1])).get("comments",[])
     if not ok(c["path"], int(c["line"]))]
print("OUTSIDE DIFF: "+", ".join(bad) if bad else "all anchors inside the diff")
sys.exit(1 if bad else 0)
PY
```

Non-zero means do not post. Move each named finding into the body and re-check, rather than nudging its line number until it passes. Take anchors from `$DIFF` in the first place, never from reading the file at HEAD, and never from a lens that cited a line it inferred.

**You cannot review your own PR.** GitHub rejects approve and request-changes from the author, so gate on the variables the pr mode already resolved:

```bash
[ "$ME" = "$AUTHOR" ] && echo "own PR: message is for reading, not posting" && exit 0
```

On your own PR the authorship gate has already ended the posting path anyway; this is the belt to its braces.

## Daily update (only with a `voice` skill)

**Presence is the switch.** No `voice` skill installed means no daily update: do not produce one, do not offer, do not mention its absence.

With one installed, produce a standup line whatever the verdict, through `voice`, with the `unslop` skill applied. `/build`'s daily update owns the canonical wording and the shared rules (no CI, no headers, no bullets, one short paragraph); only what differs for a review is repeated here.

- Lead with the PR title verbatim and its number, then say what the PR actually does in one or two lines, pulled from the diff and description, not from a finding-by-finding log.
- Approve: `Reviewed and approved <title> (#<num>). <one or two lines on what changed and why>.`
- Request changes or Needs discussion, one line: `Reviewed <title> (#<num>), sent feedback on <the gist>.`

```
Daily update:
> Reviewed and approved <title> (#<num>). <one or two lines on what changed and why>.
```

Write it to `.grimoire/standup.md`, next to `message.md`, so it survives the session and can be pasted or piped without scrolling back for it. There is no API for this one: standup lives in Slack or Discord, so posting it is always the user's own hand.

## Distillation

Only when `.wiki/` exists. If it does not, stop after the messages above and do not mention it.

A review is a raw source. Its lasting value, not the per-line nits, compounds into the wiki. Most useful in pr and local mode, usually skip for staged.

`/build`'s deferred distillation owns the flow: folder choice, new versus update, the confirm batch, and never writing before approval. Page format and frontmatter live in `${CLAUDE_PLUGIN_ROOT}/templates/WIKI-PAGE-FMT.md`. Only the review specific parts are here.

- Pick durable items out of the **findings and the diff** only: a recurring trap is a gotcha, a non-obvious behaviour of a module is a component page, a root cause or pattern worth remembering is a lesson or a concept. Per-PR nitpicks never qualify.
- `source` names this review, the branch or the PR as plain text plus durable anchors (`path:line`, PR, commit), never a link, because `.grimoire/review.md` is overwritten every run.
- If nothing durable surfaced, say so and skip. Never manufacture pages.

The review guidelines (be specific, signal over noise, do not flag deliberate decisions, stay inside the diff) live in `REVIEW-FMT.md`, already loaded above. One more holds only here: acknowledge existing reviewer comments, do not repeat what has already been said.
