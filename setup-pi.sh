#!/usr/bin/env bash
set -euo pipefail

GRIMOIRE="$(cd "$(dirname "$0")" && pwd)"
AGENT="$HOME/.pi/agent"

echo "GRIMOIRE: $GRIMOIRE"
echo "Target:   $AGENT"
echo ""

# ── Agent folder ──────────────────────────────────────────────────────────────
mkdir -p "$AGENT"

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
link "$GRIMOIRE/AGENTS.md"   "$AGENT/AGENTS.md"
link "$GRIMOIRE/skills"      "$AGENT/skills"
link "$GRIMOIRE/prompts"     "$AGENT/prompts"
echo ""

# ── MCP config ────────────────────────────────────────────────────────────────
MCP_FILE="$HOME/.pi/mcp.json"

write_mcp() {
  cat > "$MCP_FILE" << 'EOF'
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

if [ ! -f "$MCP_FILE" ]; then
  echo "Writing MCP config: $MCP_FILE"
  write_mcp
  echo "  done."
else
  echo "  skip (already exists): $MCP_FILE"
fi

echo ""
echo "Done. Pi agent is pointed at GRIMOIRE."
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

echo "  context-mode is a pi extension — install it from pi settings if missing."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
