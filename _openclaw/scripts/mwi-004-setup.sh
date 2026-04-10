#!/bin/bash
# MWI-004: Configure MCP server for Tess (openclaw user)
# Run as: sudo bash _openclaw/scripts/mwi-004-setup.sh
# Required env vars: GOOGLE_OAUTH_CLIENT_ID, GOOGLE_OAUTH_CLIENT_SECRET
set -eu

: "${GOOGLE_OAUTH_CLIENT_ID:?Set GOOGLE_OAUTH_CLIENT_ID before running}"
: "${GOOGLE_OAUTH_CLIENT_SECRET:?Set GOOGLE_OAUTH_CLIENT_SECRET before running}"

echo "=== MWI-004: Tess MCP Server Setup ==="

# --- Step 1: Install workspace-mcp for openclaw user ---
echo ""
echo "--- Step 1: Install workspace-mcp for openclaw user ---"

# sudo -u doesn't reset HOME — must set explicitly
export OPENCLAW_HOME="/Users/openclaw"
PIPX="/opt/homebrew/bin/pipx"

sudo -u openclaw env \
  HOME="$OPENCLAW_HOME" \
  PIPX_HOME="$OPENCLAW_HOME/.local/pipx" \
  PIPX_BIN_DIR="$OPENCLAW_HOME/.local/bin" \
  "$PIPX" install workspace-mcp 2>&1 || {
    echo "pipx install failed — trying upgrade in case already installed"
    sudo -u openclaw env \
      HOME="$OPENCLAW_HOME" \
      PIPX_HOME="$OPENCLAW_HOME/.local/pipx" \
      PIPX_BIN_DIR="$OPENCLAW_HOME/.local/bin" \
      "$PIPX" upgrade workspace-mcp 2>&1
  }

# Verify installation
WORKSPACE_MCP="$OPENCLAW_HOME/.local/bin/workspace-mcp"
if [ -x "$WORKSPACE_MCP" ]; then
  echo "OK: workspace-mcp installed at $WORKSPACE_MCP"
  sudo -u openclaw env HOME="$OPENCLAW_HOME" "$WORKSPACE_MCP" --version 2>&1 || echo "(version flag may not be supported)"
else
  echo "FAIL: workspace-mcp not found at $WORKSPACE_MCP"
  exit 1
fi

# --- Step 2: Add MCP server config to openclaw.json ---
echo ""
echo "--- Step 2: Add MCP server to openclaw.json ---"

OPENCLAW_JSON="$OPENCLAW_HOME/.openclaw/openclaw.json"

if [ ! -f "$OPENCLAW_JSON" ]; then
  echo "FAIL: openclaw.json not found at $OPENCLAW_JSON"
  exit 1
fi

# Back up before modifying
cp "$OPENCLAW_JSON" "${OPENCLAW_JSON}.bak-mwi004"
echo "Backup: ${OPENCLAW_JSON}.bak-mwi004"

# Use python3 to safely merge MCP config into existing JSON
python3 << 'PYEOF'
import json, sys

config_path = "/Users/openclaw/.openclaw/openclaw.json"

with open(config_path, "r") as f:
    config = json.load(f)

# Add mcpServers key if not present
if "mcpServers" not in config:
    config["mcpServers"] = {}

# Check if already configured
if "google-workspace" in config.get("mcpServers", {}):
    print("google-workspace MCP server already configured — updating")

# Core tier for Tess: gmail, drive, calendar, contacts (no docs/sheets)
config["mcpServers"]["google-workspace"] = {
    "type": "stdio",
    "command": "/Users/openclaw/.local/bin/workspace-mcp",
    "args": [
        "--tools", "gmail", "drive", "calendar", "contacts",
        "--single-user"
    ],
    "env": {
        "GOOGLE_OAUTH_CLIENT_ID": "$GOOGLE_OAUTH_CLIENT_ID",
        "GOOGLE_OAUTH_CLIENT_SECRET": "$GOOGLE_OAUTH_CLIENT_SECRET",
        "USER_GOOGLE_EMAIL": "danny@dfriedrich.me"
    }
}

with open(config_path, "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")

print("OK: google-workspace MCP server added to openclaw.json (core tier)")
PYEOF

# Fix ownership in case anything got created as root
chown openclaw:openclaw "$OPENCLAW_JSON" "${OPENCLAW_JSON}.bak-mwi004"

echo ""
echo "--- Step 3: Verify ---"
echo "MCP config in openclaw.json:"
python3 -c "
import json
with open('$OPENCLAW_JSON') as f:
    c = json.load(f)
mcp = c.get('mcpServers', {}).get('google-workspace', {})
print(json.dumps(mcp, indent=2))
"

echo ""
echo "=== MWI-004 setup complete ==="
echo ""
echo "Next steps:"
echo "  1. Restart OpenClaw gateway to pick up the new MCP config"
echo "  2. OAuth: Tess will need to complete browser consent on first MCP tool use"
echo "     (same as Crumb did — the server will prompt with an auth URL)"
echo "  3. Test via Telegram: ask Tess to check your calendar or search email"
