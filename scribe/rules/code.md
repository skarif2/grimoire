# Code

## Comments

Closed list of exceptions. If the comment does not name one, delete it.

1. A *why* the code cannot show: workaround for an external bug, deliberate choice that looks wrong, constraint invisible at that spot. Reason, never mechanism.
2. A toolchain marker: pragma, lint suppression, license header, type escape.
3. A doc comment on a public API, only where every sibling in the file has one.

Never restate the line. No section banners. No edit narration, so no "new", "added to fix X", "changed from". No doc blocks on internal functions. Explaining *what* means the name is wrong: fix the name.

Ceiling is three lines, on kinds 1 and 2 only. Past three the reason is usually not worked out yet, so cut it back to the reason. When it genuinely needs more and `.wiki/` exists, it is a wiki page: propose one, and link it once written. No wiki, the ceiling stands.

Kind 3 is not counted. A doc block is already bounded by the shape its siblings use, which is the condition it was admitted under, so match that and stop. Counting its lines would only force it to contradict the convention it is there to follow.

## Tests

None unprompted. Write one when asked, or when a plan task names it in `verify:`. Repairing tests the change broke is repair, not new tests, and is expected. Otherwise say in one line what is worth covering and why, then stop and wait. That answer is the instruction.

## Git

Never commit. Propose the message plus a copy-pasteable `git add ... && git commit` scoped to that run's files. Never run it. Never `git add -A`. The user drives git.
