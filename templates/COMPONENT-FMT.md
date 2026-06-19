# Component File Format

Component pages are **entity pages for real modules/systems** in the codebase — the durable "what this part is, what it owns, how it connects" reference. They live in `components/` under a project (`docs/[group]/[project]/components/`). File naming `component_[slug].md`.

Where a concept explains a *mechanism or idea*, a component documents a *thing in the code*: a module, a service, a key file or cluster of files, a subsystem. The editor's `CustomEditable`, the instance-body routing, an API client — these are components.

Create the `components/` directory lazily — only when the first component is distilled.

## Template

```md
# {Component Name}

**Status:** current | needs-verification | stale
**Updated:** {YYYY-MM-DD}
**Location:** `path/to/component/` (key files: `file.ts`, `other.ts`)
**Source:** [[{plan-or-review-filename}]] · PR #{N}

{One-paragraph description of what this component is and the role it plays.}

## Responsibilities

- {What it owns / does}
- {Boundaries — what it deliberately does NOT do}

## Key files & entry points

- `path/to/file.ts:line` — {what lives here}

## Connections

- Depends on [[component_{slug}]] — {how}
- Used by [[component_{slug}]] — {how}
- Governed by [[adr_{slug}]] — {which decision shapes it}

## Related

- [[concept_{slug}]] — {mechanism it implements}
- [[gotchas#{heading}]] — {trap when working here}
```

## Rules

- **Anchor to real code.** Always cite `path:line` and the key files. A component page that doesn't point at the code is useless.
- **Provenance + freshness mandatory.** Same `Source:` / `Status:` / `Updated:` discipline as concepts.
- **Document boundaries.** "What it does NOT do" prevents the next engineer (or agent) from putting logic in the wrong place.
- **Map the connections.** The `Connections` section is what makes the graph navigable — link dependencies, consumers, and governing decisions.
- **Must appear in `index.md`.** Add the entry in the same distillation pass.
- **One page per component.** Update in place; don't fork a second page for the same module.
