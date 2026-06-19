# Index File Format

The `index.md` is the **map** of a project's wiki — a catalog the AI reads *first* (before drilling into pages or running `ctx_search`). One per project at `docs/[group]/[project]/index.md`, and optionally one per group at `docs/[group]/index.md` for shared pages.

It lists every **distilled** page (concept, component, lesson, gotcha, ADR, context) with a one-line summary and a `[[wikilink]]`. It does **not** list raw sources (plans, reviews, handoffs) — those are inputs, not knowledge.

The index is maintained on every distillation pass (by `/gg` and `/review`). It is the single most important file for making the vault useful to the AI later.

## Template

```md
# {Project} — Index

_Last updated: {YYYY-MM-DD}_

One-line description of what this project is.

## Concepts

- [[concept_{slug}]] — {one-line summary}
- [[concept_{slug}]] — {one-line summary}

## Components

- [[component_{slug}]] — {one-line summary}

## Decisions (ADR)

- [[adr_{slug}]] — {one-line summary}

## Context

- [[context_{slug}]] — {one-line summary}

## Lessons

- [[lesson_{slug}]] — {one-line summary}

## Gotchas

- [[gotchas#{heading}]] — {one-line summary}
```

## Rules

- **Read first, drill second.** A session loads `index.md`, picks relevant pages by their one-line summaries, then opens only those. This replaces embedding-RAG at this scale.
- **Distilled pages only.** Never list plans/reviews/handoffs — they're raw sources. If a category has no pages yet, omit the heading.
- **One line per entry.** The summary is for *triage*, not content. Keep it scannable.
- **Every distilled page must be listed.** A page not in the index is an orphan — the lint pass flags it.
- **Update on every distillation.** When `/gg` or `/review` adds or revises a page, the same pass updates this file. Stale index = broken map.
- **Group-level index** (`docs/[group]/index.md`) catalogs only shared pages; project indexes link up to it when a shared page is relevant.
