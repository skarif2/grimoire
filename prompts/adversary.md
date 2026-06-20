---
description: Adversary, assume the artifact is wrong, try to break it, report only findings that survive self-refutation
argument-hint: "[staged | local | PR number/URL | plan filename | file path | inline text]"
---
$ARGUMENTS

Load and follow the `adversary` skill.

- No argument → attack the current branch diff (local), or ask what to attack if there is nothing to diff
- `staged` → attack the staged changes
- PR number or URL → attack the PR diff (needs `gh`)
- a plan filename or file path → attack that file at full fidelity
- inline text → attack the text

Read-only. It reports findings with a concrete break scenario each, drops anything it can refute, and ends with `found problems` or `could not find a problem`. It never edits; you decide what to fix.
