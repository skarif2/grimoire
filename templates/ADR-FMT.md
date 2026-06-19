# ADR Format

ADRs live in `adr/` under either a project (`docs/[group]/[project]/adr/`) or a group-level shared pool (`docs/[group]/adr/`). Use file naming `adr_[slug].md`.

Create the `adr/` directory lazily — only when the first ADR is needed.

## Template

```md
# {Short title of the decision}

{1-3 sentences: what's the context, what did we decide, and why.}
```

That's it. An ADR can be a single paragraph. The value is in recording *that* a decision was made and *why* — not in filling out sections.

## Optional sections

Only include these when they genuinely add value. Most ADRs won't need them.

- **Considered Options** — only when the rejected alternatives are worth remembering
- **Consequences** — only when non-obvious downstream effects need to be called out

## When to write an ADR

All three must be true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful
2. **Surprising without context** — a future reader will wonder "why on earth did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons

If any one is missing, skip it.

### What qualifies

- Architectural shape: "We use a monorepo." "The API is REST, not GraphQL."
- Technology choices with real lock-in: database, auth provider, deployment target — not every library.
- Boundary decisions: "User data is owned by the auth service; other services reference by ID only."
- Deliberate deviations from the obvious path — stops the next engineer from "fixing" something intentional.
- Constraints not visible in the code: compliance requirements, partner API contracts, performance SLAs.
- Rejected alternatives when the rejection is non-obvious.

### What does NOT qualify

- Anything easy to reverse
- Implementation details or patterns (those belong in context files or comments)
- Decisions that are self-evident from the code

## Wikilinks

ADRs are part of the **distilled wiki layer**. When an ADR governs a concept or component, end it with a `## Related` line linking them, and ensure the governed page links back (`Governed by [[adr_{slug}]]`):

```md
## Related

- [[component_{slug}]] — what this decision shapes
- [[concept_{slug}]] — the mechanism it constrains
```

Every ADR must be listed in the project's `index.md` under **Decisions**.
