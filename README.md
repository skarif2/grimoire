# GRIMOIRE

GRIMOIRE is a shared knowledge vault for pi and Claude Code. Project context, architecture decisions, plans, reviews, and handoffs live here, structured to mirror ~/Projects/, indexed into a persistent FTS5 database, and symlinked into both agents so a decision made in one session is searchable in the next.


## What lives here

```
GRIMOIRE/
├── AGENTS.md           ← global rules for both agents (symlinked as CLAUDE.md for Claude)
├── docs/               ← project knowledge, mirroring ~/Projects/ structure
│   ├── {group}/
│   │   ├── index.md · context/ · adr/ · concepts/  ← group-level shared distilled pages
│   │   └── {project}/
│   │       ├── index.md            ← the MAP: catalog of distilled pages, read first
│   │       │  ── distilled wiki (durable, interlinked, loaded on every task) ──
│   │       ├── context/ · adr/ · concepts/ · components/ · lessons/ · gotchas.md
│   │       │  ── raw sources (episodic, dated, write-once, inputs to distillation) ──
│   │       ├── handoffs/       ← from /handoff - deleted after /plan supersedes it (with confirmation)
│   │       ├── plans/          ← active; plans/archived/ when done via /gg
│   │       └── reviews/
├── skills/             ← reusable agent skills (grill-plan, review, improve-architecture, handoff, adversary, lint)
├── templates/          ← format templates for index, ADRs, plans, reviews, context, concepts, components, lessons, gotchas, handoffs
├── prompts/            ← slash commands (symlinked as commands/ for Claude)
├── setup-pi.sh         ← one-time setup for pi
├── setup-claude.sh     ← one-time setup for Claude Code
└── .gitignore
```

### The compiled wiki layer

Each project's `docs/` has two tiers with a hard boundary:

- **Raw sources** (`plans/`, `reviews/`, `handoffs/`) - episodic, dated, write-once records of a moment, produced by `/plan`, `/gg`, and `/review`. They are the inputs to distillation, never loaded directly on future work.
- **Distilled wiki** (`context/`, `adr/`, `concepts/`, `components/`, `lessons/`, `gotchas.md`) - durable, interlinked pages kept current, compiled from the raw sources. This is what the agent loads on every task.
- **The map** (`index.md`) - catalogs every distilled page with a one-line summary. Read first, then drill into the pages that matter via their `[[wikilinks]]`.

Distillation runs at ticket close (folded into `/gg` and `/review`): the agent drafts new or updated distilled pages plus `index.md` entries and presents them for confirmation before writing.

## New machine setup

### 1. Clone this vault

```bash
git clone <repo-url> ~/GRIMOIRE
```

### 2. Pull your dotfiles

Make sure your `.zshrc` exports are in place - these are needed before running the setup scripts:

```bash
GITHUB_PERSONAL_ACCESS_TOKEN  # from Keychain
CONTEXT7_API_KEY               # from Keychain
CONTEXT_MODE_DIR="$HOME/GRIMOIRE/.context-mode"  # shared db for pi and Claude
```

### 3. Store API keys in macOS Keychain

```bash
security add-generic-password -a "$USER" -s "github-mcp-token" -w "<your-github-pat>"
security add-generic-password -a "$USER" -s "context7-api-key" -w "<your-context7-key>"
```

### 4. Run the setup script

For pi (make sure pi is installed first):
```bash
bash ~/GRIMOIRE/setup-pi.sh
```

For Claude Code (make sure `claude` CLI is installed first):
```bash
bash ~/GRIMOIRE/setup-claude.sh
```

Both scripts are safe to re-run - they skip anything already in place and back up any existing files before overwriting.

### 5. Install extensions and plugins

These can't be automated by the setup scripts - install them manually after running setup.

#### Pi extensions

In pi settings, add to the `packages` list:

```json
"npm:pi-web-access",
"npm:pi-powerline-footer",
"npm:context-mode",
"npm:@juicesharp/rpiv-ask-user-question",
"npm:@samfp/pi-memory",
"npm:pi-mcp-adapter",
"npm:@juicesharp/rpiv-todo",
"npm:@gotgenes/pi-anthropic-auth"
```

#### Claude plugins

_To be documented._

---

## What the setup scripts do

- Symlink GRIMOIRE folders into the agent's config directory
- Write the MCP config with GitHub and Context7 (if it doesn't already exist)
- Verify keychain entries and `CONTEXT_MODE_DIR` are set, warn if missing

| GRIMOIRE | pi (`~/.pi/agent/`) | Claude (`~/.claude/`) |
|---|---|---|
| `AGENTS.md` | `AGENTS.md` | `CLAUDE.md` |
| `skills/` | `skills/` | `skills/` |
| `prompts/` | `prompts/` | `commands/` |

`docs/` and `templates/` are not symlinked - skills reference them directly via `~/GRIMOIRE/docs/` and `~/GRIMOIRE/templates/`.

## MCP servers

Both agents use the same two MCP servers:

| Server | Purpose | API key |
|---|---|---|
| `mcp-server-github` | GitHub PRs, issues, repos | `github-mcp-token` in Keychain |
| `context7-mcp` | Up-to-date library documentation | `context7-api-key` in Keychain |

context-mode is installed as a native plugin in each agent, not as an MCP server:
- **pi**: `npm:context-mode` in `settings.json` packages
- **Claude**: `/plugin marketplace add mksglu/context-mode` then `/plugin install context-mode@context-mode`

Both agents share the same FTS5 database via `CONTEXT_MODE_DIR=$HOME/GRIMOIRE/.context-mode` - knowledge indexed in one session is searchable in the other.

## Skills

| Skill | Command | Purpose |
|---|---|---|
| `grill-plan` | `/plan` | Pre-planning interview - explores codebase, challenges assumptions, writes a plan |
| `review` | `/review` | Code review for staged changes, local branch, or GitHub PR |
| `improve-architecture` | `/improve-architecture` | Find architectural friction, produce HTML report, grill on candidates |
| `handoff` | `/handoff` | Capture a new idea that emerged mid-session for a fresh conversation |
| `adversary` | `/adversary` | Red-team an artifact (plan, PR, doc, claim) - assumes it is wrong and tries to prove it |
| `lint` | `/lint` | Read-only health check of the toolkit's own files (em dashes, path leaks, broken template refs) |

## Utility commands

| Command | Purpose |
|---|---|
| `/startup` | Load project knowledge and indexed context at the start of a session |
| `/gg [partial name]` | Execute the active plan - runs tasks (one ready phase per session for phased plans), self-reviews the diff, distils into the wiki, proposes commits, archives on completion |
| `/reindex [group/project]` | Rebuild the FTS5 index from all GRIMOIRE docs - run once after setup on a new machine |
| `/da <question>` | Deep answer - research mode, no code, no file changes |
| `/fa <question>` | Fast answer - concise, no code, no file changes |

## Adding a new skill

1. Create `skills/{name}/SKILL.md`
2. Create `prompts/{name}.md` to register the slash command
3. Both agents pick it up automatically via the symlink - no re-running the setup script needed
