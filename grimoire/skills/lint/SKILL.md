---
name: lint
description: Read-only health check for the toolkit's own files at ${CLAUDE_PLUGIN_ROOT} (rules, skills, commands, templates) and for a project's .wiki/ when one exists. Flags dashes used as punctuation, non-ASCII characters, absolute home-path leaks, broken template references, and for the wiki, missing frontmatter, orphans, dead file:line citations, stale status and duplicate pages. Reports findings with file:line; it never edits. Use after editing skills, commands or wiki pages.
argument-hint: "[kit | wiki | a path to scope the scan]"
---

Read-only lint. It reports problems and recommends fixes; it never applies them, you decide.

## Scope

Two targets, both scanned by default:

**Kit**: `${CLAUDE_PLUGIN_ROOT}/rules/`, and every `*.md` under `${CLAUDE_PLUGIN_ROOT}/skills/`, `${CLAUDE_PLUGIN_ROOT}/commands/`, `${CLAUDE_PLUGIN_ROOT}/templates/`.

**Wiki**: every `*.md` under `.wiki/` in the current repo, **only when the folder exists**:

```bash
[ -d .wiki ] || echo "no wiki"
```

If `.wiki/` is absent, scan the kit only and say nothing about the wiki. Never create it.

`$ARGUMENTS` narrows the scan: `kit`, `wiki`, or an explicit path.

## Checks that run on both targets

**1. Dashes used as punctuation.** Em dash (U+2014), en dash (U+2013), and a double hyphen that is not a command flag. A style convention that bans all three in prose. Drop this check if it is not yours.

```bash
find ${CLAUDE_PLUGIN_ROOT}/ -name '*.md' -print0 | xargs -0 perl -ne \
  'BEGIN{$D=chr(45)x2} next if /^\s*-{3,}\s*$/; close ARGV if eof; print "$ARGV:$.: $_" if /\x{2014}|\x{2013}/ || /(?<!\w)$D(?!\w)/ || /(?<=[A-Za-z])$D(?=[A-Za-z])/'
```

Flag form (`--verbose`), decrement (`i--`) and a line of only hyphens (YAML frontmatter, a horizontal rule) are excluded by the pattern. A backtick-quoted end-of-options marker inside a code fence still matches, so eyeball those before reporting them.

**2. Non-ASCII characters.** Box drawing, arrows, typographic quotes, middots, emoji. Same rule, wider net.

```bash
find ${CLAUDE_PLUGIN_ROOT}/ -name '*.md' -print0 | xargs -0 perl -ne 'close ARGV if eof; print "$ARGV:$.: $_" if /[^\x00-\x7F]/'
```

**3. Absolute home-path leaks.** A hardcoded path under the current home directory that should be `$HOME` or `~`, so the toolkit stays portable across machines.

```bash
grep -rnF "$HOME/" --include='*.md' ${CLAUDE_PLUGIN_ROOT}/
```

**4. Broken template references.** Every `*-FMT` name a skill or command cites must exist in `${CLAUDE_PLUGIN_ROOT}/templates/`.

```bash
grep -rnoE '[A-Z][A-Z0-9-]*-FMT' --include='*.md' ${CLAUDE_PLUGIN_ROOT}/ | sort -u
ls ${CLAUDE_PLUGIN_ROOT}/templates
```

Compare the two lists and report any cited name with no file behind it, at the `file:line` that cites it.

## Checks that run on the wiki only

All of these sit behind `[ -d .wiki ]`. Skip the whole section otherwise.

**5. Missing frontmatter.** Every page needs `summary`, `status`, `updated` and `source`. A page missing `summary` is invisible to the grep that sessions use to find pages, so it is effectively lost.

```bash
for f in .wiki/*/*.md; do
  for k in summary status updated source; do
    grep -q "^$k:" "$f" || echo "$f: missing $k"
  done
done
```

**6. Orphan pages.** No inbound `[[slug]]` from another page and no outbound `[[slug]]` of its own.

```bash
for f in .wiki/*/*.md; do
  s=$(basename "$f" .md)
  out=$(grep -c '\[\[' "$f")
  in=$(grep -rl "\[\[$s\]\]" .wiki/ --include='*.md' | grep -v "^$f$" | wc -l)
  [ "$out" -eq 0 ] && [ "$in" -eq 0 ] && echo "$f: orphan"
done
```

**7. Dead citations.** A cited `path/to/file.ts:142` whose file no longer exists, or whose line number is past the end of the file.

```bash
grep -rhoE '[A-Za-z0-9_./-]+\.[a-z]{2,4}:[0-9]+' .wiki/ --include='*.md' | sort -u | while IFS=: read -r p l; do
  [ -f "$p" ] || { echo "missing file: $p:$l"; continue; }
  [ "$l" -gt "$(wc -l < "$p")" ] && echo "line past EOF: $p:$l"
done
```

Report the citing page's `file:line`, not just the dead path, so the hit is jump-to-able.

**8. Stale status.**

```bash
grep -rn '^status: \(stale\|needs-verification\)' .wiki/ --include='*.md'
```

These are not errors, they are a worklist. Report them with the `updated:` date so the oldest ones stand out.

**9. Duplicate pages.** Two pages covering one topic is a format failure: pages get revised, not duplicated. This one needs judgement, not a regex. Collect the summaries and compare them:

```bash
grep -rn '^summary:' .wiki/ --include='*.md'
```

For a large wiki, hand this to an Explore subagent (Agent tool, `subagent_type: "Explore"`) and ask it to return only the suspected duplicate pairs with a one-line reason each. Report a pair only when both pages genuinely answer the same question; near neighbours that link to each other are fine.

## Report

Group findings by check. Every hit carries `file:line` so it is jump-to-able. Recommend the fix (swap the dash for a comma, colon or parentheses; replace the absolute path with `$HOME` or `~`; add the missing frontmatter key; link the orphan or delete it; re-anchor or prune the dead citation; merge the duplicate) and do not apply it.

Close with a count per check and a total. Zero findings means say so in one line.

## Constraints

- Read-only. Never edit a file, never write into `.wiki/`.
- Always report `file:line`.
- The dash and non-ASCII patterns in this file match themselves by construction only where a literal example is unavoidable. Ignore self-hits from the check definitions above.
- Never touch anything outside the scanned roots.
