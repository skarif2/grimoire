---
description: Reindex, rebuild the context-mode FTS5 index from all GRIMOIRE docs
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
      adr|context|plans|reviews|handoffs|concepts|components|lessons)
        source="$p1:$p2"
        ;;
      gotchas.md) source="$p1:gotchas" ;;
      index.md)   source="$p1:index" ;;
      *)
        case "$p3" in
          adr|context|plans|reviews|handoffs|concepts|components|lessons) source="$p1/$p2:$p3" ;;
          gotchas.md) source="$p1/$p2:gotchas" ;;
          index.md)   source="$p1/$p2:index" ;;
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

## 3. Lint the wiki

Health-check the distilled layer (Karpathy's lint). Run in the sandbox, only the report enters context:

```
ctx_execute("javascript", `
  const fs = require('fs'), path = require('path');
  const ROOT = process.env.HOME + '/GRIMOIRE/docs';
  const arg = "${ARGUMENTS}".trim();
  const base = arg ? path.join(ROOT, arg) : ROOT;
  const walk = d => { let r = []; for (const e of fs.readdirSync(d, { withFileTypes: true })) {
    const p = path.join(d, e.name);
    if (e.isDirectory()) r = r.concat(walk(p)); else if (e.name.endsWith('.md')) r.push(p);
  } return r; };
  let files = []; try { files = walk(base); } catch (e) { console.log('no docs at', base); }
  const slugs = new Set(files.map(f => path.basename(f, '.md')));
  const distilled = ['concepts', 'components', 'lessons', 'adr', 'context'];
  const linkRe = /\\[\\[([^\\]]+)\\]\\]/g;
  const linked = new Set(); const broken = []; const stale = [];
  for (const f of files) {
    const t = fs.readFileSync(f, 'utf8'); const rel = path.relative(ROOT, f);
    if (/Status:\\**\\s*(stale|needs-verification)/i.test(t)) stale.push(rel);
    let m; while ((m = linkRe.exec(t))) {
      const tgt = m[1].split('#')[0].split('|')[0].trim(); if (!tgt) continue;
      linked.add(tgt);
      if (!slugs.has(tgt) && tgt !== 'index' && !tgt.endsWith('gotchas')) broken.push(rel + ' -> [[' + m[1] + ']]');
    }
  }
  const orphans = files.filter(f => distilled.includes(path.basename(path.dirname(f))) && !linked.has(path.basename(f, '.md'))).map(f => path.relative(ROOT, f));
  console.log('LINT, ' + (arg || 'all vault'));
  console.log('Files: ' + files.length + ' | Orphans (distilled, never linked): ' + orphans.length + ' | Broken links: ' + broken.length + ' | Stale/unverified: ' + stale.length);
  if (orphans.length) console.log('\\nOrphans (add an index/backlink, or remove):\\n' + orphans.join('\\n'));
  if (broken.length) console.log('\\nBroken [[wikilinks]] (target missing):\\n' + broken.slice(0, 40).join('\\n'));
  if (stale.length) console.log('\\nStale / needs-verification (review freshness):\\n' + stale.join('\\n'));
`)
```

Surface the lint summary to the user. Orphans and broken links are fixable now (add the missing `index.md` entry / backlink, or correct the link); stale pages are flagged for the user to re-verify. Do not auto-edit pages during reindex, report only.

## 4. Report

Once all files are processed, print:
- Total files indexed
- Breakdown by project (e.g. `acme/frontend: 8 files`)
- Any files skipped (empty or unreadable)
