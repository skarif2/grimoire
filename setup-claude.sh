#!/usr/bin/env bash
set -euo pipefail

GRIMOIRE="$(cd "$(dirname "$0")" && pwd)"
CLAUDE="$HOME/.claude"

echo "GRIMOIRE: $GRIMOIRE"
echo "Target:   $CLAUDE"
echo ""

# ── Claude folder ─────────────────────────────────────────────────────────────
mkdir -p "$CLAUDE"

link() {
  local src="$1" dst="$2"
  if [ -L "$dst" ]; then
    echo "  skip (already linked): $dst"
  elif [ -e "$dst" ]; then
    echo "  backup: $dst → ${dst}.bak"
    mv "$dst" "${dst}.bak"
    ln -sf "$src" "$dst" && echo "  linked: $dst → $src"
  else
    ln -sf "$src" "$dst" && echo "  linked: $dst → $src"
  fi
}

echo "Symlinking agent files..."
link "$GRIMOIRE/AGENTS.md"   "$CLAUDE/CLAUDE.md"    # pi: AGENTS.md → Claude: CLAUDE.md
link "$GRIMOIRE/skills"      "$CLAUDE/skills"
link "$GRIMOIRE/prompts"     "$CLAUDE/commands"     # pi: prompts → Claude: commands
echo ""

# ── MCP config ────────────────────────────────────────────────────────────────
SETTINGS_FILE="$CLAUDE/settings.json"

write_settings() {
  cat > "$SETTINGS_FILE" << 'EOF'
{
  "mcpServers": {
    "github": {
      "command": "mcp-server-github",
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    },
    "context7": {
      "command": "context7-mcp",
      "env": {
        "CONTEXT7_API_KEY": "${CONTEXT7_API_KEY}"
      }
    }
  }
}
EOF
}

if [ ! -f "$SETTINGS_FILE" ]; then
  echo "Writing settings: $SETTINGS_FILE"
  write_settings
  echo "  done."
else
  echo "  skip (already exists): $SETTINGS_FILE"
fi

echo ""
echo "Done. Claude is pointed at GRIMOIRE."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Post-setup checks:"
echo ""

# Keychain
for entry in "github-mcp-token" "context7-api-key"; do
  if security find-generic-password -a "$USER" -s "$entry" -w &>/dev/null; then
    echo "  ✓ keychain: $entry"
  else
    echo "  ✗ keychain: $entry — missing, add with:"
    echo "    security add-generic-password -a \"\$USER\" -s \"$entry\" -w \"<token>\""
  fi
done
echo ""

# CONTEXT_MODE_DIR
if [ -n "${CONTEXT_MODE_DIR:-}" ]; then
  echo "  ✓ CONTEXT_MODE_DIR=$CONTEXT_MODE_DIR"
else
  echo "  ✗ CONTEXT_MODE_DIR not set — pi and Claude will use separate databases"
  echo "    Add to ~/.zshrc: export CONTEXT_MODE_DIR=\"\$HOME/GRIMOIRE/.context-mode\""
fi
echo ""

echo "  context-mode is a Claude plugin — install it after setup:"
echo "  /plugin marketplace add mksglu/context-mode"
echo "  /plugin install context-mode@context-mode"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
