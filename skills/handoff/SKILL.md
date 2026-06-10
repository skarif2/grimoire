---
name: handoff
description: Capture a new idea or task that emerged mid-conversation and package it for a fresh session to pick up. Use when you discover something worth doing separately rather than now.
argument-hint: "[the new idea or task to hand off]"
---

<what-to-do>

A new idea surfaced during this conversation that belongs in its own session. Capture it with just enough context for a fresh agent to start cold — no more.

Do not summarise the current session. Focus entirely on the new idea.

</what-to-do>

<project-detection>

```bash
PROJECTS_ROOT="$HOME/Projects"
CWD=$(pwd)
if [[ "$CWD" == "$PROJECTS_ROOT/"* ]]; then
  RELATIVE="${CWD#$PROJECTS_ROOT/}"
  GROUP=$(echo "$RELATIVE" | cut -d'/' -f1 | tr '[:upper:]' '[:lower:]')
  PROJ=$(echo "$RELATIVE" | cut -d'/' -f2 | tr '[:upper:]' '[:lower:]')
  DOCS_ROOT="$HOME/GRIMOIRE/docs/$GROUP/$PROJ"
  PROJECT_ID="$GROUP/$PROJ"
else
  PROJ=$(basename "$CWD" | tr '[:upper:]' '[:lower:]')
  DOCS_ROOT="$HOME/GRIMOIRE/docs/$PROJ"
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

<index-the-idea>

Index the new idea so it's discoverable in future sessions:

```
ctx_index(
  content: "Handoff: [one-sentence description of the idea and why it's worth doing]",
  source: "$PROJECT_ID:handoffs"
)
```

</index-the-idea>

<handoff-doc>

Load `~/GRIMOIRE/templates/HANDOFF-FMT.md` for the format rules. Then generate the filename and create the folder:

```bash
SLUG=$(echo "[short title]" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | cut -c1-40)
DATE=$(date +%Y-%m-%d)
HANDOFF_DIR="$DOCS_ROOT/handoffs"
mkdir -p "$HANDOFF_DIR"
HANDOFF_PATH="$HANDOFF_DIR/handoff_${DATE}-${SLUG}.md"
```

If the user passed an argument, that IS the idea — don't invent a different framing.

After writing the file, open it:

```bash
open_in_editor "$HANDOFF_PATH"
```

</handoff-doc>

<new-session>

Open a new tmux window at the same working directory, named after the handoff slug:

```bash
tmux new-window -n "handoff-${SLUG}" -c "$CWD"
```

Tell the user:
- The handoff file path
- That a new tmux window `handoff-[slug]` is ready at `$CWD`
- To run `/startup` then `/plan` when they're ready to pick it up

</new-session>
