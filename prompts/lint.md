---
description: Lint, read-only check of the GRIMOIRE toolkit files for em dashes, absolute-path leaks, and broken template references
argument-hint: "[optional path under ~/GRIMOIRE]"
---
$ARGUMENTS

Load and follow the `lint` skill.

It scans the toolkit's own files (`AGENTS.md`, `prompts/`, `skills/`) and reports, with `file:line`:
- em dash characters that violate the global no-em-dash rule,
- absolute home-path leaks that should be `$HOME` or `~`,
- broken `~/GRIMOIRE/templates/*.md` references.

Read-only. It reports and recommends fixes; you decide what to change. Pass a path to scope the scan.
