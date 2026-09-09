<div align="center">

# 📜 Grimoire ✨

### Your agent relearns the codebase every session.

Give it somewhere to remember.

<br/>

[![version](https://img.shields.io/badge/version-26.910.0-6366f1?style=flat-square)](https://github.com/skarif2/GRIMOIRE)
[![license](https://img.shields.io/badge/license-MIT-22c55e?style=flat-square)](#license)
[![claude code](https://img.shields.io/badge/Claude%20Code-plugin-f59e0b?style=flat-square)](https://claude.com/claude-code)
[![status](https://img.shields.io/badge/status-early-64748b?style=flat-square)](#status)

</div>

<br/>

You explain the architecture. You explain the trap in the date handling. You explain why that module looks wrong but is load bearing.

Then the context window fills, the session ends, and tomorrow you explain all of it again.

<br/>

<table>
<tr>
<td width="50%" valign="top">

**`.grimoire/`**

What you are working on today. The plan, the review, the PR draft. Gitignored, and it dies with the branch.

</td>
<td width="50%" valign="top">

**`.wiki/`**

What this project has learned. Concepts, decisions, traps. Shared by every worktree, and it outlives all of them.

</td>
</tr>
</table>

Two folders at the root of your repo. That is the whole idea.

```mermaid
flowchart LR
    T["your ticket"] --> P["/plan"]
    P --> F[".grimoire/plan.md"]
    F --> B["/build"]
    B --> V["/review"]
    V --> PR["pull request"]

    B -. "what it learned" .-> W[".wiki/"]
    V -. "what it learned" .-> W
    W -. "read before planning" .-> P

    style W fill:#6366f1,stroke:#4f46e5,color:#ffffff
    style T fill:#334155,stroke:#475569,color:#f8fafc
    style PR fill:#334155,stroke:#475569,color:#f8fafc
```

> The solid line is one ticket, start to finish. The dotted line is the part that usually goes missing: what the work taught you, going somewhere it can be found again.

<br/>

## Install

### What you need

| Tool | Needed for |
|:--|:--|
| **Claude Code** | Everything. It is the plugin host. |
| **git** | Everything. Worktrees are optional, but this is better with them. |
| **gh** | Reading your tickets and drafting pull requests. Skip it and those steps go quiet. |

<br/>

### 1. Add it

Inside a Claude Code session:

```bash
/plugin marketplace add skarif2/GRIMOIRE
/plugin install grimoire
```

Or from your shell, without opening a session:

```bash
claude plugin marketplace add skarif2/GRIMOIRE
claude plugin install grimoire
```

The first command registers the catalog, the second installs the plugin from it. Restart Claude Code so it loads.

<br/>

### 2. Check it landed

```bash
claude plugin list
```

`grimoire` should be there and enabled. In a session, typing `/` now offers `/plan`, `/build` and `/review`.

<br/>

### 3. Give a project a memory

Once per repository, from anywhere inside it:

```bash
/wiki-init
```

That creates the wiki branch, checks it out a single time, points every worktree at that one copy, and hides both folders from git. Nothing to configure, no files to edit, no paths to set.

Skip this step and everything still works, you simply get no wiki. That is a supported way to run, not a broken install.

<br/>

### Try it without installing

To load it for one session and leave your setup untouched:

```bash
claude --plugin-dir /path/to/GRIMOIRE/claude-kit
```

Nothing is written to your config, and it is gone when the session ends.

<br/>

### Update, disable, remove

```bash
claude plugin update grimoire
claude plugin disable grimoire
claude plugin uninstall grimoire
claude plugin marketplace remove skarif2
```

Updating needs a restart to take effect. Disabling keeps it installed but dormant, which is the fastest way to tell whether Grimoire is behind some behaviour you did not expect. The last line drops the catalog itself, which registers under the name `skarif2` rather than the name of the repo.

<br/>

## The five minute version

<table>
<tr><td>

**1. Start a ticket**

```bash
/plan add rate limiting to the upload endpoint
```

It reads your ticket from the tracker, asks a handful of sharp questions, argues with your assumptions, and writes a plan only once you have actually approved it. Not "sounds good". Actually approved.

</td></tr>
<tr><td>

**2. Do the work**

```bash
/build
```

It executes the plan, verifies every step, reviews its own diff, and drafts the pull request. It never commits. It hands you the command and lets you run it.

</td></tr>
<tr><td>

**3. Check the work**

```bash
/review
```

Five reviewers read your diff at once: correctness, quality, architecture, tests, security. They report side by side, and none of them is allowed to bury another's findings.

</td></tr>
</table>

<br/>

## Everything it can do

#### Plan and build

| Command | What it does |
|:--|:--|
| **`/plan`** | Interviews you before writing anything. Reads the ticket. Splits work too big for one sitting. |
| **`/build`** | Runs the plan, verifies every step, reviews itself, drafts the PR. |

#### Check the work

| Command | What it does |
|:--|:--|
| **`/review`** | Five lenses in parallel, severity rated, each finding labelled with how strong its evidence is. |
| **`/adversary`** | Assumes your plan is wrong and tries to prove it. Reports only what survives its own refutation. |
| **`/debug`** | Refuses to guess. No hypothesis until it has a command that reproduces the bug on demand. |

#### Keep what you learned

| Command | What it does |
|:--|:--|
| **`/wiki-init`** | Gives this project a wiki. Once per repo. |
| **`/handoff`** | Catches an idea that surfaced mid task and packages it for later. |
| **`/retro`** | Looks at how the session went and improves the setup, not the code. |

#### Write like a person

| Command | What it does |
|:--|:--|
| **`/unslop`** | Strips the tells out of anything a human will read. |
| **`/bro`** | Says your own message back to you in plain words, so you can see what landed. |

#### Quick answers

| Command | What it does |
|:--|:--|
| **`/skim`** | Fast answer. Touches nothing. |
| **`/dig`** | Deep answer. Touches nothing. |

<br/>

---

<br/>

## The part nobody else does

If you use git worktrees, you know the problem. Notes in one worktree are invisible from the others. Commit them and they ride a feature branch. Merge them and they conflict, because everyone is appending to the same file.

Grimoire puts the wiki on its own orphan branch, checks it out exactly once, and points every worktree at that single copy.

```mermaid
flowchart TD
    subgraph repo[" your repo "]
        direction LR
        M["main/"]
        A["feature-a/"]
        B["feature-b/"]
    end

    W[(".wiki/<br/>one checkout<br/>branch: wiki")]

    M -- ".wiki" --> W
    A -- ".wiki" --> W
    B -- ".wiki" --> W

    style W fill:#6366f1,stroke:#4f46e5,color:#ffffff
    style M fill:#334155,stroke:#475569,color:#f8fafc
    style A fill:#334155,stroke:#475569,color:#f8fafc
    style B fill:#334155,stroke:#475569,color:#f8fafc
```

**Every worktree points at the same folder. Not a copy of it, the same one.**

Write a page while working on one branch and it is readable from every other branch immediately. No commit. No merge. No pull.

The branch shares no history with `main`, so a wiki page can never appear in a feature diff and can never cause a conflict. Your teammates get it with one command, and their normal clone stays exactly as clean as it was.

<br/>

## Four promises

> **It never commits.**
> It writes the message, scopes the files, and hands you a command. You run it. Every time.

> **It never writes comments you did not ask for.**
> There is a closed list of three cases where a comment earns its place. Everything else is deleted by an agent that never wrote the code and has nothing to defend.

> **It never writes tests you did not ask for.**
> It tells you in one line what is worth covering, then stops and waits.

> **It never writes to the wiki behind your back.**
> It drafts the pages, shows you, and waits.

<br/>

## Your workplace may not allow this

Plenty of teams cannot put engineering notes in a branch, and plenty of codebases are not yours to annotate. So the wiki is off until you turn it on.

No `.wiki` folder means the project never opted in. Every skill notices, stays quiet, and gets on with the work. It will not create one, will not write to one, will not offer, and will not remark on its absence.

You can run `/plan`, `/build`, `/review` and everything else on a repo with no wiki at all. You simply get less prior knowledge, which is exactly what you have today.

<br/>

## Status

**Version 26.910.0.** Dated, not semantic: year, month, day. Young, and honest about it.

The design is settled and every piece has been checked, but it has not yet been run in anger across a long stretch of real work. Expect rough edges, and please report them.

<br/>

---

<br/>

## Why "Grimoire"

A grimoire is a book you keep, add to, and consult before attempting something difficult.

It is not a manual someone handed you. It is the one you wrote, from things that actually happened.

That is the entire pitch. Your agent should have one.

<br/>

## Standing on other people's work

Very little here is original. Most of it is an idea someone else had, adapted to fit two folders and a rule against doing anything without asking. Naming names, because vague thanks is worth nothing.

<details open>
<summary><b>mattpocock/skills</b> &nbsp;&middot;&nbsp; the largest debt</summary>

<br/>

`/adversary`, `/handoff` and the shape of `/plan` all began [there](https://github.com/mattpocock/skills). So did four ideas that changed the design: posting a brief as a ticket comment that supersedes a stale description, treating phases as a dependency graph with a takeable frontier rather than a queue, the fog test that separates a decision from a build step, and `/debug` refusing to form a hypothesis until it has a command that reproduces the bug. `/retro`, and the rule that coding standards belong to the reviewer rather than the implementer, are his too.

</details>

<details>
<summary><b>addyosmani/agent-skills</b> &nbsp;&middot;&nbsp; taught /plan how to interview</summary>

<br/>

Attaching a guess to every question so you react instead of composing, and refusing to accept "sounds good" as approval, both come from [there](https://github.com/addyosmani/agent-skills). So does the list of signals that work is too big for one sitting, the habit of watching a diff for a quietly lowered bar, and the change summary section that says what was deliberately left alone.

</details>

<details>
<summary><b>cursor/plugins</b> &nbsp;&middot;&nbsp; gave us /unslop almost whole</summary>

<br/>

Including the stable rule numbers that let other skills cite a rule instead of restating it. [Their](https://github.com/cursor/plugins/tree/main/pstack) comment agent is the ancestor of ours, and its best idea survives intact: when a comment explains a surprise in your own code, do not delete the comment, name the rename or extraction that would make the prose unnecessary. `/bro`, the evidence ladder, and the rule that a judge should run on a different model family than the author are all theirs.

</details>

<details>
<summary><b>Andrej Karpathy</b> &nbsp;&middot;&nbsp; <b>Martin Fowler</b></summary>

<br/>

Karpathy for the compiled wiki pattern, the idea that raw notes and distilled pages are different layers, and that mixing them is what makes a knowledge base rot. Fowler for the smell catalogue the quality reviewer reads verbatim.

</details>

<br/>

Where an idea was worth taking but came wrapped in a fixed sequence of steps or a mandated folder layout, we took the idea and left the rest. That is a compliment to the thinking, not a criticism of the packaging.

<br/>

## License

MIT.

<br/>

<div align="center">

Built by [Sk Arif](https://github.com/skarif2)

</div>
