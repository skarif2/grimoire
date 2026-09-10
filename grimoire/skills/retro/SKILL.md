---
name: retro
description: Retrospective on a coding session that improves the agent's environment rather than the code. Looks for missing navigation pointers, missing automated checks, review rules, bloated instruction files, expensive tool calls, no-op instructions, and blocked information. Proposes changes to the kit, to AGENTS.md or CLAUDE.md, and to the wiki when one exists. Use after a session that went badly, or one that went well for reasons worth keeping.
argument-hint: "[nothing, for the current session | a description of the session to review]"
disable-model-invocation: true
---

# Retro

You are not fixing the code from the session. You are fixing the environment the next agent will work in, so that the same session goes better next time.

Read the session first: the transcript, the diff it produced, the plan or review it worked from, and the instruction files that were in context. Default to the current session unless the user names another. Then work the categories below, each of which has a trigger that says when it applies. A category with no trigger fired is a category with nothing to report.

## Categories

**Navigation.** Was the right file hard to find? Are there dependencies between files that nothing points at? *Fires when* the session spent real time hunting for something it eventually found. The fix is a pointer from where the agent looked to where the thing lives.

**Automated checks.** Could a linter, a type, a test, or a filesystem check have caught the mistake? *Fires when* the agent made an error a machine could have caught.

**Coding standards.** Should the review agent get a new rule, or should an existing one be clarified or dropped? *Fires when* review let a mistake through, or flagged something that was fine.

**Oversized instruction files.** Is a file that gets pushed into every agent's context carrying content that belongs in a check or a standard instead? *Fires when* `rules/`, a repo `AGENTS.md`, or a global `CLAUDE.md` has grown large. These files cost tokens on every single run, so the bar for a line staying in one is high.

**Tool economy.** Did the agent make expensive calls it did not need? Is some CLI or MCP server token-inefficient enough to be worth wrapping or replacing? *Fires when* one tool call dominated the context budget.

**No-op instructions.** Which lines in the instruction files did not change the agent's behaviour at all? *Fires when* an instruction file is large and you can point at text the session ignored or would have followed anyway.

**Information access.** Could the agent have been given something it lacked? Dev server logs teed to a file, read access to a service, a fixture, a saved trace. *Fires when* a crucial fact was simply not reachable from where the agent sat.

## Where each fix belongs

**Standards belong to the review agent, never to the implementer.** The implementer is under context pressure: it is exploring, holding a plan, reading files, writing code. The review agent has the least context pressure of anything in the loop, because it receives a diff and needs no exploration to judge it. A rule handed to the implementer competes with the task. The same rule handed to review costs nothing until there is something to check. When a lesson can be phrased as "the diff should not contain X", it is a review rule.

Targets in this kit, roughly in order of how much they cost to read:

- `${CLAUDE_PLUGIN_ROOT}/rules/` loads on every run. Only durable, short, universal rules. Adding a line here is the most expensive fix available.
- A skill or command under `${CLAUDE_PLUGIN_ROOT}/` loads only when invoked, and its description is the only part that is always resident. This is where procedures go.
- A project's `AGENTS.md` or `CLAUDE.md` loads for every agent in that repo. Treat it as navigation pointers to other files, not as a manual.
- `.wiki/`, only when the folder exists. Gate on `[ -d .wiki ]`. Absent means the project never opted in, so do not create it, do not write to it, and do not remark on its absence. Present means durable per-project knowledge belongs there, one page per idea, reached from the pointers above.

## Prefer the strongest mechanism

When more than one fix would work, take the strongest the situation allows:

1. **Make the bad state unrepresentable.** A type, a signature, or a data shape where the mistake does not compile.
2. **A lint rule or a banned API that fails CI.** The mistake compiles but does not merge.
3. **A canonical helper.** One obvious right way to do the thing, sitting where the agent will find it.
4. **A runtime check.** The mistake ships but announces itself loudly.

Agents copy whatever the surrounding code already does, so a weak guard becomes the template for the next twenty instances.

**If a structural fix exists, use only the structural fix.** Do not also write the instruction down. A written rule next to a mechanism that already enforces it is dead weight that still costs tokens, and it will drift out of sync with the mechanism. The urge to write the instruction is the symptom, not the cure. Text is the last resort, for the cases where nothing can be enforced.

## Output

Propose the changes. Show the diff you would make to each file and say which category and which mechanism level it came from. Wait for confirmation before writing anything, and never write to `.wiki/` without it.
