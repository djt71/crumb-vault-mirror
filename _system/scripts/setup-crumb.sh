#!/bin/bash
# setup-crumb.sh — New machine setup for Crumb vault
# Crumb Design Spec §2.1
#
# Run after cloning the vault on a fresh machine. Verifies dependencies,
# fixes permissions, installs the pre-commit hook, and validates the vault.
#
# Usage:
#   bash _system/scripts/setup-crumb.sh              # Run from vault root
#   bash _system/scripts/setup-crumb.sh /path/to/vault  # Explicit vault path

set -uo pipefail

VAULT_ROOT="${1:-$(pwd)}"
if [ ! -f "$VAULT_ROOT/CLAUDE.md" ]; then
    echo "ERROR: Cannot find CLAUDE.md at $VAULT_ROOT — is this the vault root?"
    exit 1
fi

PASS=0
FAIL=0

check() {
    local label="$1"
    shift
    if "$@" &>/dev/null; then
        echo "  ✓ $label"
        PASS=$((PASS + 1))
    else
        echo "  ✗ $label"
        FAIL=$((FAIL + 1))
    fi
}

check_with_version() {
    local label="$1"
    local cmd="$2"
    shift 2
    if command -v "$cmd" &>/dev/null; then
        local ver
        ver=$("$@" 2>&1 | head -1)
        echo "  ✓ $label ($ver)"
        PASS=$((PASS + 1))
    else
        echo "  ✗ $label — not found"
        FAIL=$((FAIL + 1))
    fi
}

# ============================================================================
# Phase 1: System dependencies
# ============================================================================
echo "=== Phase 1: System Dependencies ==="

check_with_version "git" "git" git --version
check_with_version "node" "node" node --version
check_with_version "python3" "python3" python3 --version
check_with_version "jq" "jq" jq --version
check_with_version "curl" "curl" curl --version

# ============================================================================
# Phase 2: Brew packages
# ============================================================================
echo ""
echo "=== Phase 2: Brew Packages ==="

check_with_version "imagemagick" "magick" magick --version
check_with_version "exiftool" "exiftool" exiftool -ver
check_with_version "ffmpeg" "ffmpeg" ffmpeg -version
check_with_version "repomix" "repomix" repomix --version

# ============================================================================
# Phase 3: Python tools
# ============================================================================
echo ""
echo "=== Phase 3: Python Tools ==="

check_with_version "markitdown" "markitdown" markitdown --version
check "Pillow" python3 -c "from PIL import Image"

# ============================================================================
# Phase 4: Claude Code
# ============================================================================
echo ""
echo "=== Phase 4: Claude Code ==="

check_with_version "claude" "claude" claude --version

# ============================================================================
# Phase 5: File permissions
# ============================================================================
echo ""
echo "=== Phase 5: File Permissions ==="

SCRIPTS_FIXED=0
for script in "$VAULT_ROOT"/_system/scripts/*.sh; do
    [ -f "$script" ] || continue
    if [ ! -x "$script" ]; then
        chmod +x "$script"
        SCRIPTS_FIXED=$((SCRIPTS_FIXED + 1))
    fi
done

if [ $SCRIPTS_FIXED -gt 0 ]; then
    echo "  Fixed execute bit on $SCRIPTS_FIXED script(s)"
else
    echo "  All scripts already executable"
fi
PASS=$((PASS + 1))

# ============================================================================
# Phase 6: Pre-commit hook
# ============================================================================
echo ""
echo "=== Phase 6: Pre-commit Hook ==="

HOOK_FILE="$VAULT_ROOT/.git/hooks/pre-commit"
HOOK_CONTENT='#!/bin/bash
./_system/scripts/vault-check.sh
exit_code=$?
if [ $exit_code -eq 2 ]; then
  exit 1
fi
exit 0'

if [ -f "$HOOK_FILE" ]; then
    if [ -x "$HOOK_FILE" ]; then
        echo "  ✓ Pre-commit hook exists and is executable"
        PASS=$((PASS + 1))
    else
        chmod +x "$HOOK_FILE"
        echo "  ✓ Pre-commit hook exists (fixed execute bit)"
        PASS=$((PASS + 1))
    fi
else
    echo "$HOOK_CONTENT" > "$HOOK_FILE"
    chmod +x "$HOOK_FILE"
    echo "  ✓ Pre-commit hook installed"
    PASS=$((PASS + 1))
fi

# ============================================================================
# Phase 7: Config files (outside vault)
# ============================================================================
echo ""
echo "=== Phase 7: Config Files ==="

if [ -f "$HOME/.config/crumb/.env" ]; then
    echo "  ✓ Crumb API keys (~/.config/crumb/.env)"
    PASS=$((PASS + 1))
else
    echo "  ✗ Crumb API keys missing (~/.config/crumb/.env)"
    echo "    Create with: OPENAI_API_KEY, GEMINI_API_KEY, DEEPSEEK_API_KEY"
    FAIL=$((FAIL + 1))
fi

if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    echo "  ✓ ANTHROPIC_API_KEY set in environment"
    PASS=$((PASS + 1))
else
    echo "  ~ ANTHROPIC_API_KEY not set (optional — only needed if not using subscription auth)"
fi

if grep -q 'LUCID_API_KEY' "$HOME/.config/crumb/.env" 2>/dev/null; then
    echo "  ✓ Lucidchart API key present"
    PASS=$((PASS + 1))
else
    echo "  ~ Lucidchart API key not set (lucidchart skill won't work — optional)"
fi

# ============================================================================
# Phase 8: Vault validation
# ============================================================================
echo ""
echo "=== Phase 8: Vault Validation ==="

if bash "$VAULT_ROOT/_system/scripts/vault-check.sh" "$VAULT_ROOT" >/dev/null 2>&1; then
    echo "  ✓ vault-check.sh passed (exit 0)"
    PASS=$((PASS + 1))
else
    VC_EXIT=$?
    if [ $VC_EXIT -eq 1 ]; then
        echo "  ~ vault-check.sh passed with warnings (exit 1)"
        PASS=$((PASS + 1))
    else
        echo "  ✗ vault-check.sh found errors (exit 2)"
        echo "    Run: bash _system/scripts/vault-check.sh for details"
        FAIL=$((FAIL + 1))
    fi
fi

# ============================================================================
# Phase 9: GitHub Mirror (optional)
# ============================================================================
echo ""
echo "=== Phase 9: GitHub Mirror (Optional) ==="

MIRROR_PATH="$HOME/crumb-vault-mirror"
if [ -d "$MIRROR_PATH/.git" ]; then
    check "Mirror repo exists" test -d "$MIRROR_PATH/.git"
    check "Mirror remote configured" git -C "$MIRROR_PATH" remote get-url origin

    if grep -q "mirror-sync" "$VAULT_ROOT/.git/hooks/post-commit" 2>/dev/null; then
        echo "  ✓ Post-commit hook includes mirror-sync"
        PASS=$((PASS + 1))
    else
        echo "  ~ Post-commit hook missing mirror-sync (auto-sync disabled)"
    fi
else
    echo "  — Mirror repo not found at $MIRROR_PATH (optional, skipping)"
fi

# ============================================================================
# Phase 10: OpenClaw hardening (optional)
# ============================================================================
echo ""
echo "=== Phase 10: OpenClaw Hardening (Optional) ==="

OC_INSTALLED=false
if command -v openclaw &>/dev/null || [ -d "/Users/openclaw" ]; then
    OC_INSTALLED=true
fi

if [ "$OC_INSTALLED" = false ]; then
    echo "  — OpenClaw not installed (optional, skipping)"
else
    # Dedicated user
    check "Dedicated openclaw user exists" id openclaw

    # OpenClaw binary
    check "OpenClaw binary on PATH" command -v openclaw

    # Loopback binding (only if daemon is listening)
    if lsof -iTCP:18789 -sTCP:LISTEN &>/dev/null; then
        if lsof -iTCP:18789 -sTCP:LISTEN 2>/dev/null | grep -q '127.0.0.1'; then
            echo "  ✓ Daemon bound to loopback (127.0.0.1:18789)"
            PASS=$((PASS + 1))
        else
            echo "  ✗ Daemon listening but NOT bound to loopback"
            FAIL=$((FAIL + 1))
        fi
    else
        echo "  — Daemon not running (loopback check skipped)"
    fi

    # workspaceOnly
    OC_CONFIG="/Users/openclaw/.openclaw/openclaw.json"
    if grep -q '"workspaceOnly": true' "$OC_CONFIG" 2>/dev/null; then
        echo "  ✓ workspaceOnly is enabled"
        PASS=$((PASS + 1))
    else
        echo "  ✗ workspaceOnly not set in $OC_CONFIG"
        FAIL=$((FAIL + 1))
    fi

    # Browser disabled
    if grep -q '"enabled": false' "$OC_CONFIG" 2>/dev/null; then
        echo "  ✓ Browser disabled in config"
        PASS=$((PASS + 1))
    else
        echo "  ✗ Browser not disabled in $OC_CONFIG"
        FAIL=$((FAIL + 1))
    fi

    # Credential isolation — .env should be 600 or 700 (no group/world read)
    CRED_FILE="$HOME/.config/crumb/.env"
    if [ -f "$CRED_FILE" ]; then
        PERMS=$(stat -f '%Lp' "$CRED_FILE" 2>/dev/null)
        if [ "$PERMS" = "600" ] || [ "$PERMS" = "700" ]; then
            echo "  ✓ Credential isolation ($CRED_FILE is $PERMS)"
            PASS=$((PASS + 1))
        else
            echo "  ✗ Credential isolation ($CRED_FILE is $PERMS, expected 600 or 700)"
            FAIL=$((FAIL + 1))
        fi
    else
        echo "  — Credential file not found (checked in Phase 7)"
    fi
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "=========================================="
echo "Setup Summary"
echo "=========================================="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"

if [ $FAIL -gt 0 ]; then
    echo ""
    echo "RESULT: $FAIL issue(s) to resolve"
    echo "Fix the items marked ✗ above and re-run this script."
    exit 1
else
    echo ""
    echo "RESULT: All checks passed — vault is ready"
    exit 0
fi
