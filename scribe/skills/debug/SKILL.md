---
name: debug
description: Diagnose a hard bug or a performance regression by first building a reproduction loop, then hypothesising against it. Gates every hypothesis and every fix behind one named command that already failed once with its output shown. Use for "debug this", "why is this broken", "this throws", "this is slow", or any flaky failure.
argument-hint: "[the symptom, an error message, a failing test name, or a file path]"
---

# Debug

The bug is not the hard part. Guessing without a loop is.

## The gate

**Name one command that reproduces the bug. Run it. Show its output. Only then form a hypothesis.**

No hypothesis, no theory of the cause, no edit to source, no fix attempt of any kind before the gate is satisfied. This is not skippable and it is not a formality. If you catch yourself explaining what is probably wrong and you have not yet run a red command, stop and go build the loop.

The command has to be all four of these:

- **Red-capable.** It fails right now, on this bug, and it asserts the user's exact symptom. Not "runs without erroring". It must be able to catch *this* bug and go green when the bug is gone.
- **Deterministic.** Same verdict every run. For an intermittent bug, determinism means a pinned and high reproduction rate: loop the trigger, parallelise it, inject sleeps to widen the timing window, add stress. A bug that fails 50 percent of runs is debuggable. One percent is not, so raise the rate before you do anything else.
- **Fast.** Seconds, not minutes. You are going to run it dozens of times.
- **Agent-runnable.** You can run it unattended, with no human clicking anything.

State the command, its exit status, and the failing output before continuing. That output is the baseline every later claim is measured against.

## Building the loop

Pick the highest option on this list that can reach the bug. Higher is better because it is cheaper to rerun and harder to fool.

1. **A failing test** at whatever seam reaches the bug, unit, integration, or end to end.
2. **A curl or HTTP call** against a running dev server.
3. **A CLI invocation** on a fixture input, diffing stdout against a known-good snapshot.
4. **Replaying a captured trace.** Save the real request, payload, or event log to disk, then push it through the code path in isolation.
5. **A property or fuzz loop.** For "sometimes the output is wrong", run a thousand random inputs and look for the failure mode.
6. **A bisection harness.** If the bug appeared between two known states (a commit, a dataset version, a dependency version), automate "boot at state X, check, repeat" so the search runs itself.
7. **A differential loop.** Run the same input through the old version and the new one, or through two configs, or against a known-good implementation, and diff the outputs.

**If no correct seam exists, that absence is the finding.** Say so, name what would have to change to make the code reachable from a test, and report it. Do not substitute a guess for the loop you could not build. An unreachable code path is a real architectural result and it is worth more to the user than a plausible-sounding cause.

## Instrumenting

Tag every temporary log with a short random marker, `[DEBUG-a4f2]`, and use the same marker for the whole investigation. Cleanup is then one grep, and an untagged log is the one that survives into production.

Before you wrap up, grep the marker and remove every hit. Delete throwaway harnesses and prototypes too, or move them somewhere clearly marked. A fix is not done while instrumentation is still in the tree.

## Evidence ladder

Every claim you make about this bug states where it stopped. Say the level out loud.

1. **You said so.** Worthless on its own.
2. **You pointed at the line.** A real `file:line`, or the dependency's own source.
3. **You showed the bad case cannot happen.** You walked the failure step by step and it does not reach.
4. **You ran it.** A script or test that calls the real code and fails loud if you are wrong.
5. **You reproduced it in the running app.**

A root cause claimed at level 1 or 2 is a hypothesis. Call it one. The fix is verified only when the gate command, unchanged, goes green and you can say so at level 4 or 5.

## Wrapping up

Re-run the original gate command and show it green. Confirm the instrumentation is gone. State the hypothesis that turned out correct, in one or two sentences, so the next person debugging this does not start from zero. Follow `rules/code.md` on tests and on git: a regression test is worth proposing, but you do not add one unprompted, and you never commit.
