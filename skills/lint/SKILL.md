---
name: lint
description: Read-only health check for the GRIMOIRE toolkit's own files (skills, prompts, AGENTS.md). Flags em dash usage (the global no-em-dash rule), absolute home-path leaks that should be $HOME or ~, and broken template references. Reports findings with file:line; it never edits. Use after editing skills or prompts to keep the toolkit files clean.
argument-hint: "[optional path under ~/GRIMOIRE to scope the scan]"
---

Read-only lint of the GRIMOIRE toolkit's own files. It reports problems and recommends fixes; it does not apply them, you decide. Runs the same on Claude Code and PI (it is a sandbox scan, no persisted script).

## What it checks

1. **Em dash character** (U+2014): the global rule in `AGENTS.md` bans it in anything written. Flag every occurrence, except the single literal reference inside the rule definition itself.
2. **Absolute home-path leaks**: a hardcoded path under the current home directory that should be `$HOME` or `~`, so the toolkit stays portable across machines.
3. **Broken template references**: any `~/GRIMOIRE/templates/<name>.md` referenced by a skill or prompt that does not exist on disk.

## Scope

Default: `AGENTS.md`, every file under `prompts/`, and every `*.md` under `skills/`. If `$ARGUMENTS` names a path under `~/GRIMOIRE`, scope to that instead.

## Run the scan

One sandbox pass, read-only, only the report enters context:

```
ctx_execute("javascript", `
  const fs=require('fs'), path=require('path');
  const G=process.env.HOME+'/GRIMOIRE';
  const home=process.env.HOME;
  const EM=String.fromCharCode(0x2014);   // em dash, by code so this file is not self-flagged
  const BT=String.fromCharCode(96);        // backtick
  const arg=("${ARGUMENTS}"||"").trim();
  const roots = arg ? [path.join(G,arg)] : [path.join(G,'AGENTS.md'), path.join(G,'prompts'), path.join(G,'skills')];
  const walk=p=>{let r=[],st;try{st=fs.statSync(p)}catch(e){return r}
    if(st.isDirectory()){for(const e of fs.readdirSync(p)) r=r.concat(walk(path.join(p,e)))}
    else if(p.endsWith('.md')) r.push(p); return r;};
  let files=[]; for(const root of roots) files=files.concat(walk(root));
  const emdash=[], abspath=[], brokenref=[];
  for(const f of files){
    const rel=f.replace(G+'/','');
    fs.readFileSync(f,'utf8').split('\\n').forEach((ln,i)=>{
      const at=ln.indexOf(EM);
      if(at>=0 && !(ln[at-1]===BT && ln[at+1]===BT)) emdash.push(rel+':'+(i+1));
      if(ln.includes(home+'/')) abspath.push(rel+':'+(i+1));
      const refs=ln.match(/GRIMOIRE\\/templates\\/([A-Za-z0-9_-]+\\.md)/g);
      if(refs) refs.forEach(r=>{const fn=r.split('/').pop(); if(!fs.existsSync(path.join(G,'templates',fn))) brokenref.push(rel+':'+(i+1)+' '+fn);});
    });
  }
  const show=(t,a)=>{console.log('\\n'+t+': '+a.length); a.slice(0,40).forEach(x=>console.log('  '+x)); if(a.length>40) console.log('  ...and '+(a.length-40)+' more');};
  console.log('LINT, files scanned: '+files.length);
  show('Em dash (violates the no-em-dash rule)', emdash);
  show('Absolute home-path leaks (use $HOME or ~)', abspath);
  show('Broken template references', brokenref);
  const total=emdash.length+abspath.length+brokenref.length;
  console.log('\\nTotal: '+total+' issue(s)'+(total? '': ', clean'));
`)
```

## Report

Surface the scan output grouped by check, with the `file:line` for each hit so they are jump-to-able. Recommend the fix (swap the em dash for a comma, colon, or hyphen; replace the absolute path with `$HOME` or `~`; fix or remove the broken reference) but do not apply it. The user decides.

## Constraints

- Read-only. Never edit a file.
- Always report `file:line`.
- The em-dash check must not flag the single literal reference inside the ban rule in `AGENTS.md` (the code excludes a backtick-wrapped occurrence).
