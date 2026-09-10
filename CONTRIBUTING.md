# Contributing

Grimoire is a Claude Code plugin: mostly markdown (skills, commands, rules, templates) plus two small node scripts. It is opinionated on purpose. A change that makes it more configurable is usually a change that makes it worse.

## Before you write code

Open an issue first for anything beyond a typo or a broken link. A skill that does not fit the way the toolkit already works is a fork, not a PR, and that is a fine outcome.

Good PRs: a skill that misfires on a real repo, a command that documents behaviour it does not have, a prompt that reads worse than it should, a bug in `hooks/` or `scripts/`.

## The flow

`main` is protected and takes no direct pushes. Fork, branch, open a PR against `main`.

## House rules

Match the surrounding prose. Concretely:

- ASCII only. No box drawing, no typographic quotes, no arrows. Write `->` if you need one.
- No dash punctuation. No em dash, no en dash, no `--` standing in for a comma. Use a comma, a colon, parentheses, or end the sentence. Flags like `--verbose` are fine, they are not punctuation.
- Comments earn their place. The rule the toolkit enforces on your code is the rule it holds itself to, so read `grimoire/rules/code.md` before adding one.

## Two things that need extra care

**`grimoire/hooks/` and `scripts/`.** This is the only executable code in the repo, and it runs on the machine of everyone who installs the plugin. Changes here get reviewed as a supply chain, not as a feature. Expect slow, sceptical review, and expect to justify any new dependency. There are currently zero.

**Version numbers.** Do not touch them. `grimoire/.claude-plugin/plugin.json` owns the version and the README quotes it twice. Stamping is a release step the maintainer runs with `node scripts/version.mjs`. A PR that bumps a version will be asked to drop that hunk.

## Reviews

Reviews are direct and go after the work, never the person. If a PR is not going to land, you will be told that plainly and early rather than left to guess.
