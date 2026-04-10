#!/bin/bash
# OpenClaw Colocation — Mandatory Isolation Test Suite
# Go/no-go gate: ALL 9 tests must pass before messaging platform setup.
# Run as the primary user (tess) with sudo access.

set -eu

PRIMARY_USER=$(logname)
PASS=0
FAIL=0
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

echo "=== ISOLATION TEST SUITE — OpenClaw Colocation ==="
echo "Date: $TIMESTAMP"
echo "Primary user: $PRIMARY_USER"
echo "Testing user: openclaw"
echo ""

# --- Tests that MUST FAIL (isolation boundary) ---
echo "--- Deny tests (openclaw must be blocked) ---"

if sudo -u openclaw cat "/Users/$PRIMARY_USER/.config/crumb/.env" 2>&1 | grep -q "Permission denied"; then
  echo "PASS [1/9]: openclaw blocked from ~/.config/crumb/.env"
  PASS=$((PASS + 1))
else
  echo "FAIL [1/9]: openclaw CAN READ ~/.config/crumb/.env — ISOLATION BROKEN"
  FAIL=$((FAIL + 1))
fi

if sudo -u openclaw ls "/Users/$PRIMARY_USER/.ssh/" 2>&1 | grep -q "Permission denied"; then
  echo "PASS [2/9]: openclaw blocked from ~/.ssh/"
  PASS=$((PASS + 1))
else
  echo "FAIL [2/9]: openclaw CAN READ ~/.ssh/ — ISOLATION BROKEN"
  FAIL=$((FAIL + 1))
fi

if sudo -u openclaw cat "/Users/$PRIMARY_USER/.zshrc" 2>&1 | grep -q "Permission denied"; then
  echo "PASS [3/9]: openclaw blocked from ~/.zshrc"
  PASS=$((PASS + 1))
else
  echo "FAIL [3/9]: openclaw CAN READ ~/.zshrc — ISOLATION BROKEN"
  FAIL=$((FAIL + 1))
fi

if sudo -u openclaw ls "/Users/$PRIMARY_USER/Library/Keychains/" 2>&1 | grep -qE "Permission denied|Operation not permitted"; then
  echo "PASS [4/9]: openclaw blocked from ~/Library/Keychains/"
  PASS=$((PASS + 1))
else
  echo "FAIL [4/9]: openclaw CAN READ ~/Library/Keychains/"
  FAIL=$((FAIL + 1))
fi

# --- Tests that MUST SUCCEED (vault read access) ---
echo ""
echo "--- Read tests (openclaw must succeed) ---"

if sudo -u openclaw ls "/Users/$PRIMARY_USER/crumb-vault/_system/docs/" >/dev/null 2>&1; then
  echo "PASS [5/9]: openclaw can read vault _system/docs/"
  PASS=$((PASS + 1))
else
  echo "FAIL [5/9]: openclaw cannot read vault _system/docs/"
  FAIL=$((FAIL + 1))
fi

if sudo -u openclaw cat "/Users/$PRIMARY_USER/crumb-vault/CLAUDE.md" >/dev/null 2>&1; then
  echo "PASS [6/9]: openclaw can read CLAUDE.md"
  PASS=$((PASS + 1))
else
  echo "FAIL [6/9]: openclaw cannot read CLAUDE.md"
  FAIL=$((FAIL + 1))
fi

# --- Tests that MUST FAIL (vault write boundary) ---
echo ""
echo "--- Write-deny test (openclaw must be blocked) ---"

if sudo -u openclaw touch "/Users/$PRIMARY_USER/crumb-vault/test-isolation.txt" 2>&1 | grep -q "Permission denied"; then
  echo "PASS [7/9]: openclaw blocked from vault write"
  PASS=$((PASS + 1))
else
  echo "FAIL [7/9]: openclaw CAN WRITE to vault root — WRITE BOUNDARY BROKEN"
  FAIL=$((FAIL + 1))
  rm -f "/Users/$PRIMARY_USER/crumb-vault/test-isolation.txt"
fi

# --- Tests that MUST SUCCEED (sandbox write) ---
echo ""
echo "--- Sandbox write tests (openclaw must succeed) ---"

if sudo -u openclaw touch "/Users/$PRIMARY_USER/crumb-vault/_openclaw/test-isolation.txt" 2>/dev/null; then
  echo "PASS [8/9]: openclaw can write to _openclaw/ sandbox"
  PASS=$((PASS + 1))
  rm -f "/Users/$PRIMARY_USER/crumb-vault/_openclaw/test-isolation.txt"
else
  echo "FAIL [8/9]: openclaw cannot write to _openclaw/ sandbox"
  FAIL=$((FAIL + 1))
fi

if sudo -u openclaw mkdir "/Users/$PRIMARY_USER/crumb-vault/_openclaw/test-isolation-dir" 2>/dev/null; then
  echo "PASS [9/9]: openclaw can mkdir in _openclaw/ sandbox"
  PASS=$((PASS + 1))
  rmdir "/Users/$PRIMARY_USER/crumb-vault/_openclaw/test-isolation-dir"
else
  echo "FAIL [9/9]: openclaw cannot mkdir in _openclaw/ sandbox"
  FAIL=$((FAIL + 1))
fi

# --- Gate ---
echo ""
echo "=== RESULTS: $PASS passed, $FAIL failed ==="
if [ "$FAIL" -gt 0 ]; then
  echo "*** STOP: $FAIL test(s) failed. Fix permissions before proceeding. ***"
  echo "*** Do NOT connect messaging platforms until all tests pass.      ***"
  exit 1
else
  echo "All isolation tests passed. Safe to proceed with messaging setup."
  exit 0
fi
