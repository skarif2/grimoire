---
description: Reindex — rebuild the context-mode FTS5 index from all GRIMOIRE docs
argument-hint: "[group/project to reindex, or leave blank for all]"
---
$ARGUMENTS

Re-index all knowledge files from `~/GRIMOIRE/docs/` into context-mode. Run this on a new machine after setup, or any time the index feels stale.

## 1. Discover files and source labels

```
ctx_execute("shell", `
  find $HOME/GRIMOIRE/docs/${ARGUMENTS} -name "*.md" 2>/dev/null | sort | while read -r file; do
    relative="${file#$HOME/GRIMOIRE/docs/}"
    # Use cut for portability across bash/zsh/sh
    p1=$(echo "$relative" | cut -d'/' -f1)
    p2=$(echo "$relative" | cut -d'/' -f2)
    p3=$(echo "$relative" | cut -d'/' -f3)
    # Detect layout: single-level (proj/folder/file) vs group (group/proj/folder/file)
    # Single-level: second segment is a known folder name
    case "$p2" in
      adr|context|plans|reviews|handoffs)
        source="$p1:$p2"
        ;;
      *)
        case "$p3" in
          adr|context|plans|reviews|handoffs) source="$p1/$p2:$p3" ;;
          *) source="$p1/$p2" ;;
        esac
        ;;
    esac
    echo "$source|$file"
  done
`)
```

This returns a list of `source|filepath` pairs.

## 2. Index each file

For each pair from step 1, read and index the file:

```
ctx_execute_file(filepath, "javascript", `
  if (FILE_CONTENT.trim()) console.log(FILE_CONTENT)
`)
```

Then index the output:

```
ctx_index(
  content: [output from above],
  source: "[source label from step 1]"
)
```

Work through all files. Skip any that returned empty content.

## 3. Report

Once all files are processed, print:
- Total files indexed
- Breakdown by project (e.g. `acme/frontend: 8 files`)
- Any files skipped (empty or unreadable)
