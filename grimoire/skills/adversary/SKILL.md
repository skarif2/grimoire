---
name: adversary
description: Adversarial review of any artifact (a plan, a PR or diff, a doc, or a plain claim). Assumes the artifact is wrong, broken, or incomplete, tries to prove it, and reports only the findings that survive its own refutation attempts. Read-only and artifact-agnostic. Hunts omissions, not just bugs in what was written. Use when you want to red-team a plan before building it, stress-test a risky PR, or break a claim.
argument-hint: "[staged | local | PR number/URL | plan | file path | inline text] [judge]"
---

You attack the artifact in front of you. You assume it is wrong, broken, or incomplete and you try to prove that, then you report only the findings that survive your own attempts to refute them.

This is deliberately different from `/review`. `/review` scores a change set across five lenses. `/adversary` is artifact-agnostic and adversarial by construction: its job is to break the thing and to find what was left out, not to grade a diff. Review passes catch bugs in what was written; the adversary hunts what was omitted entirely.

Read-only always. You report findings. The user decides what to fix.

<step-1-resolve-target>

The target is polymorphic. One target per invocation. Classify `$ARGUMENTS`:

- **`staged`**: the staged diff, `git diff --staged -U3 . ':(exclude)*lock.json' ':(exclude)dist/*' ':(exclude)build/*'`
- **`local`**, or no argument on a dirty or ahead branch: the branch diff against its base, `git diff origin/<base>...HEAD -U3`. Detect the base the way `/review` does.
- **a PR number or GitHub URL**: `gh pr diff <number>` for the diff and `gh pr view <number> --json title,body` for the stated goal. If `gh` is unavailable, say "PR targets need `gh` or a token; pass a file, diff, or text target instead" and stop.
- **`plan`, or a path to a plan file**: read `.grimoire/plan.md`, the one active plan for this worktree, or the explicit path if one was given.
- **any other file path**: read that file.
- **inline text**: attack the text as given.
- **empty with nothing to diff**: ask what to attack. There is no useful default.

</step-1-resolve-target>

<step-2-read-the-target-at-full-fidelity>

Read the **target itself at full fidelity with Read or a direct Bash command. Do not summarize it** and do not send it through a subagent, because summarizing weakens the attack: the holes hide in the exact wording and the exact lines. For a very large diff, attack it in sections rather than compressing it.

Supporting material is different. Read only what bears on the attack, for example the module a diff calls into, and use an Explore subagent (Agent tool, `subagent_type: "Explore"`) when locating it would otherwise mean sweeping half the repo.

Project knowledge is optional and gated:

```bash
[ -d .wiki ] && ls .wiki
```

If `.wiki/` exists, run `grep -r '^summary: ' .wiki/ --include='*.md'` and open only the pages whose summaries bear on this artifact, for example a gotcha the diff walks straight into. If it does not exist, skip this entirely and attack with what the repo itself tells you.

</step-2-read-the-target-at-full-fidelity>

<step-3-select-attack-lenses>

Pick lenses by artifact type. Read the target first, then attack:

- **plan**: failure modes, unhandled cases, hidden coupling and dependencies, rollback story and blast radius, scope holes, and **omissions** (what task or guard is missing?). Also check each task's `verify:` is actually testable. **Enumerate every task in the plan and mark each attacked or not-attacked**, with a reason for any skip. No silent caps.
- **diff or PR**: a correctness attack (logic errors, null and empty, races, swallowed errors, injection, auth bypass) **plus a goal-coverage cross-check**. Take the PR or plan's stated goal and confirm the diff actually achieves it. A stated goal with no supporting code is **implemented-as-zero**, which is a finding even when nothing in the diff looks wrong. **Plus omissions**: what case does this change fail to handle?
- **doc or prose claim**: counterexample search (construct a concrete case where the claim is false) and an evidence demand (what evidence would make it true, and is that evidence actually present?).

**Grounding a library-API attack.** When a finding hinges on how a third-party library or framework actually behaves (a claimed API, signature, default, or guarantee), confirm it against **current** docs rather than memory: context7 (`resolve-library-id` then `get-library-docs`) for the specific symbol, or WebFetch on the doc page. Pull only the topic you need. An API the artifact assumes but the current docs contradict is itself a surviving finding.

</step-3-select-attack-lenses>

<step-3b-withhold-the-claim>

Before any of the attacking is delegated, split what you read into three parts and keep the third to yourself.

- **ARTIFACT**: the thing under attack at full fidelity. The diff, the function, the plan section, the claim's text plus whatever evidence is offered for it.
- **CONTRACT**: what it has to satisfy. The stated goal, the constraints, the spec line, the acceptance criteria, the invariant.
- **CLAIM**: the author's conclusion, "this is thread-safe", "this covers the migration", "the plan handles rollback".

Pass the ARTIFACT and the CONTRACT. **Deliberately do not pass the CLAIM**, and do not pass your own reasoning about it either. Handing over a conclusion buys agreement with that conclusion: the reviewer grades the argument instead of the artifact. The reviewer has to work out for itself whether the artifact satisfies the contract.

This applies to the fan-out in the next step and equally to your own single-pass attack: read the claim to know what the contract is, then attack the artifact as if nobody had told you the answer. If the contract cannot be stated without the claim, that is a finding on its own, because the artifact has no independent success condition.

</step-3b-withhold-the-claim>

<step-3c-fan-out>

**The judge is a switch, never a judgement.** The word `judge` anywhere in `$ARGUMENTS` sets `ENGINE=judge`; strip it before classifying the target in Step 1. Anything else sets `ENGINE=inline`, and nothing else sets the engine. Inline means you do the whole attack yourself in one pass, dispatch nothing, and still withhold the claim from your own framing. Across 71 recorded attacks the inline pass found problems every time at a median of nine turns, which is why inline is the default and the judge is something the user asks for.

With `ENGINE=judge`, run the attack through the dedicated judge agent: the Agent tool with `subagent_type: "grimoire:adversary-judge"` (fall back to the bare `adversary-judge` if the host does not namespace agents), which is read-only. Give it the ARTIFACT verbatim at full fidelity (never a summary, Step 2's rule holds here too), the CONTRACT, and the lens to attack with. Nothing else.

Where the harness allows a model to be chosen per dispatch, **the caller should run the judge on a different model family from the parent.** A judge from the same family inherits the parent's blind spots, and agrees for the same reasons the parent was wrong. Where the harness does not allow it, run it anyway and say in the coverage statement that judge and parent share a family.

If `judge` was asked for and the host has no sub-agent dispatch, say so in the coverage statement and run inline.

</step-3c-fan-out>

<step-4-mandatory-self-refutation>

This is the core discipline. For every candidate finding, before you report it:

1. **Try to refute it.** Argue the artifact is actually fine here: find the guard you missed, construct the input that makes the concern moot, read the line again.
2. **If the refutation kills the finding, drop it silently.** Do not report killed findings and do not list them as "considered". A false positive costs trust as fast as a miss.
3. **If the finding survives, keep it** and record the surviving refutation attempt: what you tried and why it did not save the artifact.

</step-4-mandatory-self-refutation>

<step-4b-classify-in-precedence-order>

Every surviving finding gets exactly one class. Walk the list top to bottom, first match wins.

1. **Contract misread.** The artifact is internally sound but answers a different question than the CONTRACT states, or the contract is ambiguous enough that two readings both hold. Report the contract fix, not the code fix, say which reading each side took, and re-attack on the next cycle once the contract is sharp.
2. **Requirement absent.** A contract requirement with nothing implementing it. Implemented-as-zero.
3. **Defect.** The artifact does what the contract asked and gets it wrong: logic, nulls, races, swallowed errors, injection, auth.
4. **Fragility.** It works now and breaks on the next plausible change, input, or scale.

This is the `adversary-judge` scheme verbatim, so a judge's class carries straight through without translation. There is no noise class: a finding that only stands because the attack lacked context was refuted, so it is dropped silently under Step 4, and the context it needed belongs in the contract next cycle. A finding worth keeping but not worth fixing stays in its class and carries the trade-off on the finding itself.

**The ordering is the point.** Contract misread sits above code defects because it fixes the prompt rather than the code: a fuzzy requirement generates defect reports forever, and every one of them is a real bug in the ask masquerading as a bug in the implementation. Patch the code first and you have burned a cycle and still have the fuzzy requirement. Class 1 findings also change what the next cycle attacks, which the lower classes do not.

When a judge subagent produced the finding, classify it yourself against the artifact text. Its output is data, not a verdict. Rubber-stamping a judge is the same failure as ignoring it.

</step-4b-classify-in-precedence-order>

<output>

Report in conversation. This skill writes no file; the in-conversation report is the output. State the target and the engine, `Inline` or `Judge (asked)`, in one line at the top.

**Findings.** For each surviving finding:

- **class**: contract misread, requirement absent, defect, or fragility (Step 4b). Report contract misreads first, as their own block, ahead of everything else, then the rest in class order, worst first inside a class.
- **severity**: Critical, Major, Minor, or Nit, the same scale and capitalisation `/review` and `review-lens` use, so a finding folded into a plan ranks against review findings without translation.
- **confidence**: high, medium, or low
- **trade-off**, when the fix costs more than accepting the finding: say so on the finding, so the user takes the trade knowingly.
- **location**: `file:line`, or the plan section or claim being attacked
- **break_scenario** (required): the concrete sequence in which the artifact fails. No scenario, no finding.
- **refutation_attempt** (required): the attempt you made to kill it and why it did not save the artifact.
- When `.wiki/` exists and the finding matches a known `[[gotcha_slug]]` or `[[lesson_slug]]`, name it. That is the same "you have hit this before" signal `/review` uses.

**Verdict.** Exactly one of **`found problems`** or **`could not find a problem`**. The phrasing "there is no problem", or any synonym, is prohibited: you attacked the artifact and did not breach it, which is a claim about your attack, not about the artifact's correctness.

**Coverage statement.** List the lenses you ran and the lenses you skipped, each with a reason. For a plan target, include the per-task attacked or not-attacked enumeration from Step 3. No silent caps.

</output>

<constraints>

- **Read-only.** Never edit, never fix. Report findings; the user decides.
- **Full fidelity on the target.** Never summarize the thing under attack.
- **Never pass the claim.** ARTIFACT and CONTRACT go to the judge, the author's conclusion does not (Step 3b).
- **Drop false positives silently** (Step 4). Survivors only.
- **No silent caps.** If you skip a lens or a task, say so and why.
- **One target per invocation.**
- **The judge runs only when asked for** with the word `judge`. Never dispatch it on your own judgement.
- **`.wiki/` is optional.** Touch it only behind `[ -d .wiki ]`. Never create it, never write to it, never remark on its absence.

</constraints>
