# Context File Format

Context files live in `context/` under either a project (`docs/[group]/[project]/context/`) or a group-level shared pool (`docs/[group]/context/`). Use file naming `context_[slug].md` where the slug describes the area (e.g. `context_auth.md`, `context_api-contracts.md`).

Create the `context/` directory lazily — only when the first term is resolved.

## Template

```md
# {Context Area Name}

{One sentence describing what this area covers.}

## Language

**{Term}**:
{One or two sentence definition of what it IS, not what it does.}
_Avoid_: {comma-separated list of synonyms to avoid}

**{Term}**:
{Definition.}
_Avoid_: {synonyms}
```

## Rules

- **Glossary only.** No implementation details, no specs, no architecture. Those belong in ADRs or plan files.
- **Be opinionated.** When multiple words exist for the same concept, pick the canonical one and list the others under `_Avoid_`.
- **Tight definitions.** One or two sentences max. Define what it IS, not what it does.
- **Project-specific only.** General programming concepts (timeouts, error types, utility functions) don't belong. Ask: is this concept unique to this domain? Only if yes does it belong.
- **Group terms under subheadings** when natural clusters emerge. Flat list is fine if all terms belong to one cohesive area.
- **Update inline.** When a term is resolved during a session, update the file immediately — don't batch updates.

## Group-level vs project-level

- **Group-level** (`docs/[group]/context/`): Terms shared across multiple projects in the group — API contracts, shared data models, cross-service terminology.
- **Project-level** (`docs/[group]/[project]/context/`): Terms specific to one project's domain — component names, feature terminology, local patterns.

When a term applies group-wide, put it in the group-level file, not duplicated per project.

## Wikilinks

Context files are part of the **distilled wiki layer**. When a term has a deeper page, link it inline so the glossary becomes an entry point into the graph:

```md
**{Term}**:
{Definition.} See [[concept_{slug}]] for how it works.
```

Every context file must be listed in the project's `index.md` under **Context**.
