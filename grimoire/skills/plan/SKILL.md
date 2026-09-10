---
name: plan
description: Pre-planning interview that explores the codebase, challenges assumptions, and sharpens the approach before committing to a plan. Reads the branch's ticket when there is one, drafts the plan in chat and refines it in a loop until you approve, then writes .grimoire/plan.md (and optionally an ADR, plus a ticket brief to post). Stays in refinement mode for further tweaks. Use with /plan to stress-test an idea.
argument-hint: "<task description>"
---

<what-to-do>

Before writing any plan, run a focused interview to understand the task properly. Ask questions one at a time, waiting for an answer before continuing. One question means one: an `AskUserQuestion` call carries exactly one entry in `questions`, never a bundle, because a bundle is a form and a form gets filled in without thought. A third of recorded question calls bundled several. Explore the codebase instead of asking when the answer can be found there.

</what-to-do>

<exploration>

Use Bash, Grep and Glob to locate things, Read to open the files that matter, and WebFetch for anything on the web. When a question needs a wide sweep across many files or naming conventions, launch an Explore subagent (Agent tool, `subagent_type: "Explore"`) and work from its conclusion instead of reading everything yourself.

Build understanding silently. Do not dump file contents at the user, surface only what changes the plan.

**Grounding library APIs.** When the task hinges on a third-party library whose *current* API matters (a recent version, or one you are unsure of), check real docs rather than memory, so the plan does not bake in a hallucinated API. Use context7 (`resolve-library-id`, then `get-library-docs` for the one topic you need) or WebFetch on the official docs page. Skip this for standard library or stable code.

</exploration>

<existing-knowledge>

Before asking anything, load what is already known.

1. **Handoffs.** `ls .grimoire/handoffs/*.md 2>/dev/null`. If a filename looks related to the task, ask before loading:
   > "Found a handoff that might be related: `[filename]`. Load it as context for this plan?"

   Only load on confirmation, never silently, even if the user mentioned the handoff in their request. If loaded, remember its path for cleanup at the end. If nothing matches, skip.

2. **Wiki, only if it exists.** Every wiki access sits behind `[ -d .wiki ]`. When it exists, run `grep -r '^summary: ' .wiki/ --include='*.md'` filtered by task keywords, open only the pages that match, and follow their `[[slug]]` links. Prioritise `context/` (the domain language) and `adr/` (past decisions), then whatever the task points at.

   Context pages define the domain language: use those terms exactly, never introduce synonyms. ADRs are settled decisions: do not re-litigate them unless the user explicitly wants to.

   When `.wiki/` does not exist, skip this step entirely. Do not create it, do not offer to, do not mention it.

</existing-knowledge>

<ticket-context>

Best effort, and completely silent when it does not apply. Before the interview, try to find the ticket this branch belongs to.

1. **Ticket id from the branch name.**

   ```bash
   git branch --show-current | sed -nE 's|^(([a-z]+)/)?([0-9]{2,6})-.*|\3|p'
   ```

   `feat/1234-slug` and `1234-slug` yield `1234`. Everything else yields nothing, which is the common case, not an error.

2. **Ticket repo, derived, never configured.** Tickets often live in a different repo from the code, and the PR template usually already names it in a `Closes owner/repo#<id>` line:

   ```bash
   find .github -maxdepth 2 -type f -ipath '*pull_request_template*' -exec grep -ohE '[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+#' {} + 2>/dev/null | sed 's/#$//' | sort -u | head -1
   ```

   `find` covers both layouts (`pull_request_template.md` and a `PULL_REQUEST_TEMPLATE/` directory) and stays quiet when `.github` is absent. Do not pass an unquoted glob here: zsh aborts the whole command on a no-match, before `2>/dev/null` can swallow anything.

   No template, no match, or nothing that looks like `owner/repo`: treat it as not found.

3. **Read the ticket**, only when both are known and `gh` is available (`command -v gh`):

   ```bash
   gh issue view <id> --repo <owner/repo> --json number,title,state,body
   ```

With a ticket in hand, its description is your starting context. Do not ask the user to paste what you just read. Interview from it instead: confirm what it leaves open, challenge what it assumes, and treat it as possibly stale rather than as truth.

Anything missing (no id, no repo, no `gh`, a failed lookup) means say nothing at all and interview as normal. Never guess an id out of branch text that does not match, and never go searching the tracker for a ticket with a similar title.

Keep the id and repo. The brief at the end needs them.

</ticket-context>

<interview-process>

## Step 1, Understand the scope

Explore the codebase (see `<exploration>`) until you know what already exists, which patterns apply, and where the change lands.

## Step 2, Ask clarifying questions

Before asking anything, commit to a read of the task in one sentence, with an honest confidence number:

```
HYPOTHESIS: {one sentence, what the user actually wants}
CONFIDENCE: ~{n}%
```

Below 70, append on the same line what is still missing, so the number carries information instead of being a vibe. A high number you cannot defend is simply the wrong number.

Then ask one question at a time, each carrying your own proposed answer, so the user reacts instead of composing from scratch:

```
Q: {the one question most likely to change the plan}
GUESS: {your answer, and the reasoning that produced it}
```

Wait for the reaction before the next question. The guess is the point: a wrong guess gets corrected faster than a blank question gets answered, and it puts your assumptions somewhere the user can see them. The failure mode is a polite user agreeing with a bad guess, so be visibly willing to be wrong and sometimes guess where you expect pushback.

Prioritise:

- **Scope**, what is in, what is out
- **Approach**, an existing pattern to follow or a new one needed
- **Constraints**, performance, accessibility, backward compatibility
- **Edge cases**, what happens in the unusual scenarios

**When to stop.** One checkable test, not a feeling: can you predict the user's reaction to the next three questions you would ask? Yes, stop and draft. No, ask the next one. If several rounds in you still cannot predict, say so plainly ("five questions in and I still cannot predict your reactions, something foundational is missing, want to step back?") rather than grinding through more questions.

## Step 3, Decision slice or build slice

Some work is not ready to be built, because the question at the centre of it is still fogged. The test is whether the question can be **stated sharply now**, not whether it can be answered now. Answering it is what the work is for.

- **Sharp question, or no open question left** -> build slice. The plan describes a change and its tasks produce code.
- **Cannot phrase it sharply yet** -> decision slice. The plan's output is an answer, not code. Tasks are the investigation (read the callers, prototype the two candidates, measure the slow path), and every `verify:` is written in terms of the question being settled, "the choice between X and Y is made and recorded", never "the feature works".

Say which of the two you are proposing, and why, in one line, before drafting. Do not pre-slice fog into build tasks: tasks written against a question nobody can state yet get thrown away when the answer lands.

When a decision slice resolves and `.wiki/` exists, the answer belongs in `.wiki/adr/`, which Step 5 already covers. Without a wiki it lives in the plan's `## Decisions` and nowhere else.

## Step 4, Surface conflicts

If the task conflicts with an existing ADR or context definition, call it out immediately, before continuing. "`adr_radix_over_mui` says we do not use MUI, this approach would. Revisit that decision, or change the approach?"

## Step 5, Offer an ADR if warranted

Only offer one when ALL THREE hold:

1. **Hard to reverse**, changing it later would be expensive
2. **Surprising without context**, a future reader would wonder why
3. **Real trade-off**, genuine alternatives were considered and rejected

If `.wiki/` exists and the user agrees, load `${CLAUDE_PLUGIN_ROOT}/templates/WIKI-PAGE-FMT.md` and write `.wiki/adr/adr_[slug].md` with the mandatory frontmatter (`summary`, `status`, `updated`, `source`) and the ADR body. `source` names this plan in plain text, never as a link. Link out to related pages so it is not an orphan. The `summary` line is how future sessions find it.

Most ADRs are short. Add "Alternatives rejected" and "Consequences" only where they carry real weight.

If `.wiki/` does not exist, record the decision in the plan's `## Decisions` section instead and say nothing further.

## Step 6, Capture a resolved domain term

If the interview settled a domain term that is not written down anywhere, and `.wiki/` exists, offer to capture it. Check for an existing page first (`ls .wiki/context/*.md 2>/dev/null`) and update that one rather than creating a second page on the same topic. Otherwise write `.wiki/context/context_[slug].md` per WIKI-PAGE-FMT.

Only terms specific to this project, never general programming concepts. Without a wiki, the term lives in the plan's Context section.

</interview-process>

<draft-review-loop>

When the interview has surfaced enough, **do not write the plan file yet.** Present the full plan as a **draft in chat** and refine it with the user in a loop. The file is created only on approval, so changes stay cheap and nothing hits disk prematurely.

1. Load `${CLAUDE_PLUGIN_ROOT}/templates/PLAN-FMT.md` for the format. Render the **complete** plan inline using that structure: Title, Goal, Context, Tasks (each with a `verify:`), Decisions, Out of scope. Label it clearly, a leading line `Draft plan, not saved yet`. Keep it tight per PLAN-FMT (one sentence goal, three to five context bullets) so the whole draft fits the terminal at a glance. On later edits re-render only the changed sections, so the loop stays scannable.

   When `.wiki/` exists, reference the pages the interview relied on by `[[slug]]` in Context, so the trail is explicit.

   **Single phase vs phased.** Default to single phase, a flat `## Tasks` list. Four signals decide it, each one checkable rather than a matter of taste:

   1. The work would take more than one focused session.
   2. Its acceptance criteria need more than three bullets.
   3. It touches two or more independent subsystems (auth and billing, worker and UI).
   4. Its title contains the word "and", usually a sign it is two tickets.

   Zero or one signal, single phase. Two or more, recommend **phased** and name the signals that fired, so the user argues with the test rather than with your judgement. One signal firing hard (a genuine multi day migration) can still justify phasing, but say that is what you are doing instead of pretending the count decided it.

   That decision is all this skill owns. PLAN-FMT owns the shape of a `## Phases` section (headings, ids, dependency edges, the fields `/build` fills), `/build` owns the mechanics. Follow PLAN-FMT exactly rather than reconstructing phase syntax from memory. A plan is phased **only** when it holds a literal `## Phases` section, so never write "phase" in prose and call it phased.

2. **Pick a recommendation, then ask.** Judge the draft's risk first:
   - **Non-trivial** (several files or components, multiple tasks, an area with a known gotcha or ADR, or a migration / auth / data / irreversible change) -> recommend **attack** first.
   - **Small and low risk** (one file, a task or two, nothing sensitive) -> recommend **save**.

   Then ask, three choices, marking the one you would pick and why:
   > Refine anything, attack it, or save?  **Recommended: {attack | save}** (one line reason)
   > - **save**: write the plan file (you choose whether to run it after)
   > - **change: `{what}`**: revise scope / tasks / approach / decisions
   > - **attack**: run `/adversary` on this draft to red-team it before saving

   The recommendation is a nudge, not a gate. The user can pick anything, including something not listed. Do not offer `/build` here, that comes after the file is saved.

3. **Loop.** When the user asks for a change, revise the draft **in chat** (whole plan, or just the affected sections for small tweaks) and re-ask. Stay here as long as the user keeps changing the plan. Every task keeps its `verify:`, and a new task arrives with one.

   **On `attack`:** run the `adversary` skill against the current draft, passing the draft plan text as the inline target. Surface its findings in chat. Write nothing, save nothing. Fold the findings the user chooses to address back into the draft, still in the loop, and re-ask. The adversary is read-only, the user decides which findings matter.

4. **Exit only on an explicit, specific yes.** "save", "write it", "save the plan" are approval. These are not, and each gets one scripted follow-up before you go anywhere near the file:

   - "whatever you think" / "you decide" -> delegation, which means the user is not confident either. Re-ask as a concrete choice: "Two ways to go: {A} or {B}. Which?"
   - "sounds good" -> ambiguous. "Anything you would refine before I save it?"
   - "sure, let's go" -> often politeness, not endorsement. Same follow-up, plus name the part of the draft you are least sure about, so there is something specific to push on.
   - silence, then "ok start" -> the user has given up on the loop, not converged. Stop and ask what you missed.
   - approval of the idea rather than the draft ("yeah, that approach is right") -> ask whether the tasks and the out of scope list, as written, are what should hit disk.

   One follow-up each, not an interrogation. If the answer to that follow-up is save, save. Then go to `<output>` and write the file once.

Do not write the plan file during this loop. ADRs and context pages from Steps 5 and 6 are separate durable artifacts and may still be written during the interview once the user okays them.

</draft-review-loop>

<output>

Only after the user approves the draft, load `${CLAUDE_PLUGIN_ROOT}/templates/PLAN-FMT.md` and write the plan to `.grimoire/plan.md` at the repo root.

There is one active plan per worktree, so there is no dated filename and no dedup. If an unfinished plan is already there, ask before overwriting:

```bash
mkdir -p .grimoire
if [ -f .grimoire/plan.md ] && grep -q '^\*\*Status:\*\* In Progress' .grimoire/plan.md 2>/dev/null; then
  echo "An active plan already exists at .grimoire/plan.md; overwrite it?"
fi
```

Write the file to PLAN-FMT exactly: its section order, its field names, its phased structure when the draft was phased, and its `verify:` rules. The template is the format contract, so do not restate or improvise it here.

Tell the user the plan path and any wiki pages created. If `<ticket-context>` found a ticket, draft the brief now, see `<ticket-brief>`. Then present the post-save choice:

> Plan saved at `.grimoire/plan.md` (you can `@.grimoire/plan.md` it).
> - **build**: execute the plan now (runs `/build`)
> - **done**: stop here, the plan is saved to run later
>
> Still in refinement mode: any further tweaks fold straight into the file. Pick **build** or **done** when ready.

On **build**, invoke `/build` against this plan. On **done**, confirm it is saved and stop without executing.

</output>

<ticket-brief>

Only when `<ticket-context>` found a ticket, and only once the plan file is written. No ticket, no mention of any of this.

Planning surfaces things that belong in the ticket: a constraint found in the code, an edge case settled, scope cut. The description was written before any of that, so it is now partly wrong, and the next person to read the ticket reads the wrong thing. Do not edit the description. Post a **comment**, and declare the comment authoritative, demoting the description in the same breath:

> The description above is context. This comment is the contract.

**Durability.** The comment outlives the branch, and the code moves underneath it, so write only what survives that:

- Describe interfaces, types and behavioural contracts. Name the type, the signature, the config shape, the thing to go looking for.
- No file paths, no line numbers. They go stale, and they tell whoever picks this up to stop thinking.
- Behavioural, not procedural. What the system should do, not the steps to make it do it. "`SkillConfig` accepts an optional `schedule` field of type `CronExpression`" beats "add a field to the config type".
- Acceptance criteria are independently checkable. "Triage works correctly" is not a criterion.
- **Out of scope** is mandatory. It is the only thing stopping the reader from gold plating an adjacent feature.

Shape:

```md
## Brief

The description above is context. This comment is the contract.

**Summary:** one line, what needs to happen

**Current behaviour:** what happens today, the status quo this builds on

**Desired behaviour:** what should happen once this is done, including the edge cases and error paths the interview settled

**Key interfaces:** the types, signatures and config shapes that change, and why

**Acceptance criteria:**
- [ ] checkable criterion
- [ ] checkable criterion

**Out of scope:**
- what is deliberately not being done
- the adjacent thing that looks related and is not
```

Same source as the plan, different reader. The plan carries `verify:` steps for whoever executes it, the brief carries a contract for whoever opens the ticket. Do not paste the plan in, and do not reference `.grimoire/plan.md`, which the ticket's reader cannot see.

This one gets posted under the user's own name, so both prose skills apply: the `voice` skill when one is installed owns the **register** (how it sounds), the `unslop` skill owns the **tells** (what must not appear). They govern the prose the brief is filled with, never its shape: the headings, the bold labels and the checkboxes above stay verbatim, because the contract is only readable if every brief looks the same. Without a `voice` skill, keep it plain and first person.

Write it to `.grimoire/brief.md`, show it in chat, and hand over the command:

```bash
gh issue comment <id> --repo <owner/repo> --body-file .grimoire/brief.md
```

**Never run it.** Posting to a ticket is the user's, exactly like committing. Offer once, and drop it without comment if the user is not interested.

</ticket-brief>

<refinement-mode>

After the plan file is written, the conversation enters **refinement mode**. The file is now the working document, keep it the source of truth so it never drifts from what was actually decided.

- When the user refines scope, approach, tasks or decisions, edit `.grimoire/plan.md` directly with `Edit`, do not just discuss the change in chat. Confirm in one line what changed, "Updated, added a task for the migration step".
- Use judgment. Edit the file when the user is changing the plan, just answer when the user is only asking about it. Not every message is a plan edit.
- Every task keeps its `verify:`. A refinement that adds a task adds a `verify:` too.

**Exit refinement mode** when the user signals completion ("done", "looks good", "that's it"), switches to an unrelated task, or runs `/build`. On exit, if a handoff was loaded at the start, ask before deleting it:

> "Delete the handoff `[filename]`? The plan supersedes it."

Only delete on confirmation, never silently.

</refinement-mode>
