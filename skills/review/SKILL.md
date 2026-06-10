---
name: review
description: Code review for staged changes, local branch diffs, or open PRs. Use /review for local diff, /review staged for pre-commit, /review <number or URL> for a GitHub PR.
---

<modes>

Detect mode from the argument:

- No argument → **local** mode: diff of current branch against base
- Argument is `staged` → **staged** mode: review staged changes before commit
- Argument is `current` → **pr** mode: find the open PR for the current branch and review it
- Argument is a PR number or GitHub PR URL → **pr** mode: full GitHub PR review

</modes>

<noise-exclusions>

Always exclude these from diffs — they add noise without signal:

```
:(exclude)*lock.json
:(exclude)*.lock
:(exclude)pnpm-lock.yaml
:(exclude)bun.lockb
:(exclude)dist/*
:(exclude)build/*
:(exclude).next/*
:(exclude)coverage/*
:(exclude)*.svg
:(exclude)*.png
:(exclude)*.min.js
:(exclude)*.map
:(exclude)__snapshots__/*
```

</noise-exclusions>

<context-mode-rules>

All diff fetching and file analysis MUST use context-mode tools. Never dump raw git output or file contents directly into context.

- Fetch diffs via `ctx_execute(shell, "git diff ...")` — only stdout enters context
- Analyse files via `ctx_execute_file(path, javascript, ...)` — raw content stays in sandbox
- Batch multiple commands via `ctx_batch_execute(commands, queries)`
- Index large diffs via `ctx_index(content, source)` then retrieve with `ctx_search(queries)`

</context-mode-rules>

<project-detection>

Detect the project path before running any mode. All mode steps reference these variables.

```bash
PROJECTS_ROOT="$HOME/Projects"
CWD=$(pwd)
if [[ "$CWD" == "$PROJECTS_ROOT/"* ]]; then
  RELATIVE="${CWD#$PROJECTS_ROOT/}"
  GROUP=$(echo "$RELATIVE" | cut -d'/' -f1 | tr '[:upper:]' '[:lower:]')
  PROJ=$(echo "$RELATIVE" | cut -d'/' -f2 | tr '[:upper:]' '[:lower:]')
  DOCS_ROOT="$HOME/GRIMOIRE/docs/$GROUP/$PROJ"
  SHARED_ROOT="$HOME/GRIMOIRE/docs/$GROUP"
  PROJECT_ID="$GROUP/$PROJ"
else
  PROJ=$(basename "$CWD" | tr '[:upper:]' '[:lower:]')
  DOCS_ROOT="$HOME/GRIMOIRE/docs/$PROJ"
  SHARED_ROOT=""
  PROJECT_ID="$PROJ"
fi

open_in_editor() {
  if [ -n "${VSCODE_GIT_IPC_HANDLE:-}" ] || [ "${TERM_PROGRAM:-}" = "vscode" ]; then
    echo "  saved: $1"
  else
    code "$(pwd)" "$1" 2>/dev/null || echo "  saved: $1"
  fi
}
```

</project-detection>

<staged-mode>

Review staged changes before a commit.

1. Fetch diff and changed files in one call:
```
ctx_batch_execute(
  commands: [
    { label: "Staged diff", command: "git diff --staged -U3 -- . :(exclude)*lock.json :(exclude)*.lock :(exclude)pnpm-lock.yaml :(exclude)bun.lockb :(exclude)dist/* :(exclude)build/* :(exclude).next/* :(exclude)coverage/* :(exclude)*.svg :(exclude)*.png :(exclude)*.min.js :(exclude)*.map :(exclude)__snapshots__/*" },
    { label: "Changed files", command: "git diff --staged --name-only" }
  ],
  queries: ["changes", "risks", "missing tests"]
)
```

2. Check project knowledge:
```
ctx_batch_execute(
  commands: [
    { label: "Project ADRs", command: "cat $DOCS_ROOT/adr/*.md 2>/dev/null || echo 'none'" },
    { label: "Project context", command: "cat $DOCS_ROOT/context/*.md 2>/dev/null || echo 'none'" },
    { label: "Shared ADRs", command: "cat $SHARED_ROOT/adr/*.md 2>/dev/null || echo 'none'" },
    { label: "Shared context", command: "cat $SHARED_ROOT/context/*.md 2>/dev/null || echo 'none'" }
  ],
  queries: ["architecture decisions", "deliberate patterns", "rejected alternatives"]
)
```

3. Query indexed patterns from past reviews:
```
ctx_search(queries: ["[changed component names]", "patterns", "anti-patterns"], source: "$PROJECT_ID:patterns")
```

4. Review and output (see `<output>`).

</staged-mode>

<local-mode>

Review the current branch diff against the base branch.

1. Detect base branch:
```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"
```

2. Fetch diff and changed files in one call:
```
ctx_batch_execute(
  commands: [
    { label: "Diff", command: "git diff origin/<base>...HEAD -U3 -- . :(exclude)*lock.json :(exclude)*.lock :(exclude)pnpm-lock.yaml :(exclude)bun.lockb :(exclude)dist/* :(exclude)build/* :(exclude).next/* :(exclude)coverage/* :(exclude)*.svg :(exclude)*.png :(exclude)*.min.js :(exclude)*.map :(exclude)__snapshots__/*" },
    { label: "Changed files", command: "git diff origin/<base>...HEAD --name-only" }
  ],
  queries: ["changes", "risks", "patterns"]
)
```

3. Run heuristic checks — output is flags only, not file content:
```
ctx_execute("shell", `
  CHANGED=$(git diff origin/<base>...HEAD --name-only 2>/dev/null)
  COUNT=$(echo "$CHANGED" | grep -c . || echo 0)
  [ "$COUNT" -gt 20 ] && echo "Large diff: $COUNT files — consider focused review"
  echo "$CHANGED" | grep -E '^src/.*\.(ts|tsx|js|jsx)$' | grep -Ev '\.(test|spec)\.' | while read -r f; do
    STEM=$(basename "$f" | sed 's/\..*//')
    echo "$CHANGED" | grep -qE "$STEM\.(test|spec)\." || echo "No test counterpart: $f"
  done
`)
```

4. Check project knowledge:
```
ctx_batch_execute(
  commands: [
    { label: "Project ADRs", command: "cat $DOCS_ROOT/adr/*.md 2>/dev/null || echo 'none'" },
    { label: "Project context", command: "cat $DOCS_ROOT/context/*.md 2>/dev/null || echo 'none'" },
    { label: "Shared ADRs", command: "cat $SHARED_ROOT/adr/*.md 2>/dev/null || echo 'none'" },
    { label: "Shared context", command: "cat $SHARED_ROOT/context/*.md 2>/dev/null || echo 'none'" }
  ],
  queries: ["architecture decisions", "deliberate patterns", "rejected alternatives"]
)
```

5. Query indexed patterns from past reviews:
```
ctx_search(queries: ["[changed component names]", "patterns", "anti-patterns"], source: "$PROJECT_ID:patterns")
```

6. Review and output (see `<output>`).

</local-mode>

<pr-mode>

Full PR review using GitHub MCP and context-mode. Requires a PR number or URL.

1. Extract the PR number from the argument:
   - If a URL — parse the number from the end. If parsing fails, abort: "Could not parse a PR number from that URL."
   - If a number — use directly. Fetch the PR with `github_get_pull_request`. If it returns a 404 or error, abort: "PR #[number] not found in [owner/repo]."
   - If `current` — first run step 2 to get the repo owner, then detect from the current branch:
     ```bash
     git branch --show-current
     ```
     Then use `github_list_pull_requests` with `head: "[owner]:[branch]"` and `state: "open"` to find the PR.
     - If one PR found — proceed with that PR number
     - If multiple found — show the list and ask which one to review
     - If none found — tell the user no open PR exists for this branch, then fall back to local mode automatically

2. Detect the repo owner/name:
```bash
git remote get-url origin 2>/dev/null | sed 's/.*github.com[:\/]//' | sed 's/\.git//'
```

3. Fetch **small metadata via GitHub MCP** (these responses are small, safe to receive directly):
   - `github_get_pull_request` — title, body, author, base/head branch, state
   - `github_get_pull_request_status` — CI checks
   - `github_get_pull_request_reviews` — submitted reviews and verdicts

4. Fetch **file patches via ctx_execute** — never via MCP, patches can be hundreds of KB:
```javascript
ctx_execute("javascript", `
  const token = process.env.GITHUB_PERSONAL_ACCESS_TOKEN;
  const [owner, repo] = "<owner/repo>".split("/");
  const pr = <number>;
  const res = await fetch(
    \`https://api.github.com/repos/\${owner}/\${repo}/pulls/\${pr}/files?per_page=100\`,
    { headers: { Authorization: \`Bearer \${token}\`, Accept: "application/vnd.github+json" } }
  );
  const files = await res.json();
  files.forEach(f => {
    console.log(\`\\n### \${f.filename} [\${f.status}] +\${f.additions} -\${f.deletions}\`);
    if (f.patch) console.log(f.patch);
  });
`, intent: "changed files patches risks")
```
   The `intent` param triggers auto-indexing into FTS5 — only relevant snippets come back.

5. Fetch **comments via ctx_execute** if the PR has more than 5 comments:
```javascript
ctx_execute("javascript", `
  const token = process.env.GITHUB_PERSONAL_ACCESS_TOKEN;
  const [owner, repo] = "<owner/repo>".split("/");
  const pr = <number>;
  const res = await fetch(
    \`https://api.github.com/repos/\${owner}/\${repo}/pulls/\${pr}/comments\`,
    { headers: { Authorization: \`Bearer \${token}\` } }
  );
  const comments = await res.json();
  comments.forEach(c => console.log(\`[\${c.path}] \${c.user.login}: \${c.body}\`));
`, intent: "existing review comments feedback")
```
   For 5 or fewer comments, `github_get_pull_request_comments` via MCP is fine.

6. Check project knowledge via `ctx_batch_execute`:
```
ctx_batch_execute(
  commands: [
    { label: "Project ADRs", command: "cat $DOCS_ROOT/adr/*.md 2>/dev/null || echo 'none'" },
    { label: "Project context", command: "cat $DOCS_ROOT/context/*.md 2>/dev/null || echo 'none'" },
    { label: "Shared ADRs", command: "cat $SHARED_ROOT/adr/*.md 2>/dev/null || echo 'none'" },
    { label: "Shared context", command: "cat $SHARED_ROOT/context/*.md 2>/dev/null || echo 'none'" }
  ],
  queries: ["architecture decisions", "deliberate patterns", "rejected alternatives"]
)
```

7. Query indexed patterns from past reviews:
```
ctx_search(queries: ["[changed component names]", "patterns", "anti-patterns"], source: "$PROJECT_ID:patterns")
```

8. Check for linked issues in the PR body (`#NNN`, `fixes #NNN`, `closes #NNN`). If found, fetch with `github_get_issue` — issue descriptions are small, MCP is fine here.

9. Review and output (see `<output>`).

</pr-mode>

<output>

Structure the review clearly. Adapt depth to the size of the diff — a 2-file staged change doesn't need the same structure as a 30-file PR.

# [PR title or branch name]

**Mode:** staged | local | PR #{number}
**Date:** [YYYY-MM-DD]
**Files changed:** N
**CI:** ✅ passing | ❌ failing | ⏳ pending | — (not applicable)

## Summary
One short paragraph describing what the change does and whether it achieves its goal.

## Risks
Specific concerns that could cause bugs, regressions, or production issues. Be concrete — point to the exact file and line. If none, say so.

## Missing or weak test coverage
Only flag if source changes have no corresponding test changes and the logic is non-trivial. Don't flag test absence for config changes, type-only changes, or pure UI.

## Conflicts with project decisions
If any change contradicts an ADR or established pattern from context files, flag it here with the ADR name.

## Nitpicks
Minor style or naming issues. Low priority — clearly labelled so they're easy to distinguish from real issues.

## Verdict
**Approve** | **Request changes** | **Needs discussion**
One sentence justifying the verdict.

---

After writing the review, save it to a file and open it.

Generate the filename:
```bash
REVIEW_DIR="$DOCS_ROOT/reviews"
mkdir -p "$REVIEW_DIR"
DATE=$(date +%Y-%m-%d)

# For staged/local mode:
BRANCH=$(git branch --show-current 2>/dev/null | sed 's|^feature/||;s|^fix/||;s|^chore/||;s|^refactor/||;s|^hotfix/||' | tr '/_' '-' | tr '[:upper:]' '[:lower:]')
[ -z "$BRANCH" ] && BRANCH="no-branch"
COUNT=$(ls "$REVIEW_DIR"/${DATE}-${BRANCH}-review-*.md 2>/dev/null | wc -l | tr -d ' ')
COUNT=$((COUNT + 1))
FILENAME="${DATE}-${BRANCH}-review-${COUNT}.md"

# For PR mode:
# FILENAME="${DATE}-pr-[number].md"
```

Load `~/GRIMOIRE/templates/REVIEW-FMT.md` for the output format, then write the full review content to `$REVIEW_DIR/$FILENAME` and open it:
```bash
open_in_editor "$REVIEW_DIR/$FILENAME"
```

After saving, scan the findings for reusable patterns — anti-patterns caught, conventions violated, recurring issues. Index each one that a future session should know about:
```
ctx_index(
  content: "Pattern: [description of the pattern or anti-pattern]",
  source: "$PROJECT_ID:patterns"
)
```

Also index a brief review summary:
```
ctx_index(
  content: "Review [date] [branch/PR]: [one-line summary of what was reviewed and the main finding]",
  source: "$PROJECT_ID:reviews"
)
```

Skip indexing if the review found only one-off issues with no reusable signal.

</output>

<guidelines>

- Be specific — point to file names and what the issue is, not vague statements like "this could be improved"
- Distinguish signal from noise — a missing semicolon is not the same as a missing null check
- Don't flag deliberate decisions — check ADRs and context files before calling something wrong
- Don't suggest unrelated improvements — review what's in the diff, not the surrounding code
- Existing comments from reviewers — acknowledge them, don't repeat what's already been said

</guidelines>
