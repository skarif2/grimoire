# Wiki Page Format

Every page in `.wiki/` shares one frontmatter block and differs only in its body. Six kinds:

| Kind | Folder | Filename | Answers |
|---|---|---|---|
| Concept | `concepts/` | `concept_{slug}.md` | how something works and why it is that way |
| Component | `components/` | `component_{slug}.md` | what a real module is and does |
| Lesson | `lessons/` | `lesson_{slug}.md` | what we learned the hard way |
| ADR | `adr/` | `adr_{slug}.md` | a decision, its alternatives, its consequences |
| Context | `context/` | `context_{slug}.md` | domain terms and glossary |
| Gotcha | `gotchas/` | `gotcha_{slug}.md` | one sharp trap |

Create the folder lazily, only when writing the first page into it.

## Frontmatter, mandatory on every page

```yaml
---
summary: One line under 120 characters. This is what a session greps to decide whether to open the page.
status: current
updated: 2026-09-09
source: feat/in-app-chat plan; src/chat/store.ts:142; PR #1204
---
```

`summary` is the only thing a future session sees before deciding to open the page, so it carries the payload, not the topic. Write "scroll anchoring holds position by pinning the first visible node, not by offset" rather than "about scroll anchoring".

`status` is `current`, `needs-verification` or `stale`. Use `needs-verification` for provisional synthesis and `stale` when newer sources may have superseded the page. Lint surfaces both.

`source` names the originating plan, branch or task as plain text and adds durable anchors. Never `[[link]]` a plan or review file: those live in `.scribe/`, are gitignored and get pruned, so the link would dangle.

## Bodies

**Concept**

```md
# {Concept Name}

{One paragraph of compiled understanding. What this is, why it works this way.}

## How it works

{The mechanism in durable terms. Cite real code as `path/to/file.ts:142`.}

## Why it is this way

{Constraints and tradeoffs that make it non-obvious. Link decisions.}

## Related

- [[component_{slug}]] {why related}
- [[gotcha_{slug}]] {the trap that lives here}
```

**Component**

```md
# {Component Name}

`path/to/module` {one line on what it is}

## Responsibility

{What it owns, and just as importantly what it does not.}

## Interface

{Public surface. Who calls it, what it calls.}

## Related
```

**Lesson**

```md
# {What we learned}

## What happened

{The situation, briefly.}

## What we learned

{The durable takeaway, stated so it applies beyond the original case.}

## What to do differently

{Concrete guidance for next time.}

## Related
```

**ADR**

```md
# {Decision title}

## Context

{The forces in play when this was decided.}

## Decision

{What was chosen, stated in the active voice.}

## Alternatives rejected

{Each option and the reason it lost. This is the part future readers need.}

## Consequences

{What this makes easy, what it makes hard, what it locks in.}

## Related
```

**Context**

```md
# {Term or domain area}

## {Term}

{Definition as this codebase uses it, which may differ from the industry usage.}

## Related
```

**Gotcha**

```md
# {Short trap title}

{One or two sentences. Lead with what NOT to do, because the reader may stop there.} Why: {the reason in a clause}.

## Related
```

## Rules

- **Compiled, not episodic.** Synthesise the understanding, do not paste the plan. A page reflects everything learned so far, updated in place when new sources arrive.
- **Revise, do not duplicate.** If a page for this topic exists, update it. Two pages on one topic is a lint failure.
- **Link generously.** Every page links out to its neighbours. A page with no inbound and no outbound link is an orphan, and lint flags it.
- **The summary is the lookup key.** Sessions find pages by grepping `^summary: `, so a vague summary makes the page invisible. There is no index file to add it to.
- **Gotchas stay one trap per file.** If it needs more room, it is a lesson or a concept. Write that instead and leave a gotcha pointing at it.
- **Prune dead pages.** When a gotcha no longer applies or a component is deleted, remove the page. Lint flags pages whose cited `file:line` no longer exists.
