---
description: Plan, explore, interview, then create a scoped plan file
argument-hint: "<task description>"
---
$ARGUMENTS

Load and follow the `grill-plan` skill to run a pre-planning interview before writing the plan.

The skill will:
1. Detect the project path from the folder structure (e.g. `~/Projects/acme/frontend` → `acme/frontend`)
2. Query indexed knowledge and load context/ADR files for this project
3. Explore the codebase to understand what already exists
4. Ask clarifying questions one at a time
5. Optionally create an ADR or update context if warranted
6. **Draft the full plan in chat and refine it in a loop**, make changes until you approve; nothing is written to disk yet
7. Only on approval ("save" / "looks good" / `/gg`), write the plan to `~/GRIMOIRE/docs/[group]/[project]/plans/[date]-[task-slug].md` and index it

Do not write any application code. Knowledge files (ADRs, context) may be created during the interview. The plan file itself is written only after you approve the draft.
