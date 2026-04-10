#!/usr/bin/env bash
# meeting-prep.sh — Assemble customer meeting prep context + launch Tess synthesis
#
# Source: tess-operations TOP-047 fn2 (session prep & debrief)
# Design: Projects/tess-operations/design/session-prep-design.md
#
# Gathers vault intelligence (dossier, SE inventory, FIF notes) for an
# account. Constructs a focused prompt and launches a dedicated Tess
# session via openclaw agent. Tess synthesizes the brief; script handles
# Telegram delivery via direct curl (bypasses OpenClaw delivery.to bug).
#
# Pattern: haiku-soul-behavior-injection.md — dedicated session invocation,
# not SOUL.md injection. Data gathering is deterministic bash; only
# synthesis requires the LLM.
#
# Usage:
#   bash meeting-prep.sh <account-name> [--skip-web] [--dry-run]
#   bash meeting-prep.sh "Auto Club"
#   bash meeting-prep.sh ACG --dry-run
#
# Flags:
#   --skip-web   Skip last30days external signal (vault-only brief)
#   --dry-run    Gather data and build prompt, but don't launch Tess session.
#                Prints the context file path for manual review.
#
# Output:
#   1. Telegram inline brief (via Tess synthesis)
#   2. Vault copy: _openclaw/research/output/meeting-prep-<slug>-<date>.md

set -eu

# === Constants ===
VAULT_ROOT="/Users/tess/crumb-vault"
DOSSIER_DIR="$VAULT_ROOT/Projects/customer-intelligence/dossiers"
SE_INVENTORY="$VAULT_ROOT/Domains/Career/se-management-inventory.md"
SIGNAL_NOTES_DIR="$VAULT_ROOT/_system/signal-notes"
FIF_DB="$HOME/openclaw/feed-intel-framework/state/pipeline.db"
FIF_DIGEST_DIR="$HOME/openclaw/feed-intel-framework/state/digests"
LAST30DAYS_ENGINE="/Users/openclaw/.claude/skills/last30days/scripts/last30days.py"
DAILY_ARTIFACT_DIR="$VAULT_ROOT/_system/daily"
TODAY=$(date +%Y-%m-%d)
TIMEOUT_SECS=120

# === Argument parsing ===
SKIP_WEB=false
DRY_RUN=false
ACCOUNT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-web) SKIP_WEB=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        -*) echo "ERROR: Unknown flag: $1" >&2; exit 1 ;;
        *) ACCOUNT="${ACCOUNT:+$ACCOUNT }$1"; shift ;;
    esac
done

if [[ -z "$ACCOUNT" ]]; then
    echo "Usage: meeting-prep.sh <account-name> [--skip-web] [--dry-run]"
    echo ""
    echo "Available accounts:"
    ls "$DOSSIER_DIR" 2>/dev/null | sed 's/\.md$//' || echo "  (no dossiers found)"
    exit 1
fi

# === Account matching ===
# Three-tier matching: exact slug → partial filename → frontmatter customer field.
# Handles abbreviations like "ACG" that appear in `customer: Auto Club Group (ACG)`
# but not in the filename `auto-club-group.md`.
account_slug=$(echo "$ACCOUNT" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

DOSSIER_FILE=""

# Tier 1: exact filename match
if [[ -f "$DOSSIER_DIR/${account_slug}.md" ]]; then
    DOSSIER_FILE="$DOSSIER_DIR/${account_slug}.md"
else
    # Tier 2: partial filename match
    matches=""
    match_count=0
    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        matches+="$f"$'\n'
        match_count=$((match_count + 1))
    done < <(ls "$DOSSIER_DIR" 2>/dev/null | grep -i "$account_slug" || true)
    matches=$(echo "$matches" | sed '/^$/d')

    if [[ "$match_count" -eq 1 ]]; then
        DOSSIER_FILE="$DOSSIER_DIR/$matches"
    elif [[ "$match_count" -gt 1 ]]; then
        echo "Multiple matches for '$ACCOUNT':" >&2
        echo "$matches" | sed 's/\.md$//; s/^/  /' >&2
        echo "Be more specific." >&2
        exit 1
    else
        # Tier 3: search dossier frontmatter `customer:` field for the input string
        # Catches abbreviations (ACG), alternate names, parenthetical aliases
        fm_matches=""
        fm_count=0
        while IFS= read -r f; do
            [[ -z "$f" ]] && continue
            fm_matches+="$(basename "$f")"$'\n'
            fm_count=$((fm_count + 1))
        done < <(grep -rli "^customer:.*$ACCOUNT" "$DOSSIER_DIR"/*.md 2>/dev/null || true)
        fm_matches=$(echo "$fm_matches" | sed '/^$/d')

        if [[ "$fm_count" -eq 1 ]]; then
            DOSSIER_FILE="$DOSSIER_DIR/$fm_matches"
        elif [[ "$fm_count" -gt 1 ]]; then
            echo "Multiple frontmatter matches for '$ACCOUNT':" >&2
            echo "$fm_matches" | sed 's/\.md$//; s/^/  /' >&2
            echo "Be more specific." >&2
            exit 1
        else
            echo "No dossier found for '$ACCOUNT'." >&2
            echo "Available accounts:" >&2
            ls "$DOSSIER_DIR" 2>/dev/null | sed 's/\.md$//' >&2
            exit 1
        fi
    fi
fi

# Extract display name from dossier frontmatter
account_display=$(grep '^customer:' "$DOSSIER_FILE" | head -1 | sed 's/^customer: *//')
if [[ -z "$account_display" ]]; then
    account_display=$(basename "$DOSSIER_FILE" .md | tr '-' ' ')
fi

file_slug=$(basename "$DOSSIER_FILE" .md)

echo "=== Meeting Prep: $account_display ==="
echo "Date: $TODAY"
echo "Dossier: $(basename "$DOSSIER_FILE")"
echo ""

# === Output paths ===
CONTEXT_FILE="/tmp/meeting-prep-context-${file_slug}-${TODAY}.md"
OUTPUT_DIR="$VAULT_ROOT/_openclaw/research/output"
OUTPUT_FILE="$OUTPUT_DIR/meeting-prep-${file_slug}-${TODAY}.md"
mkdir -p "$OUTPUT_DIR"

# === [1/5] Read dossier ===
echo "[1/5] Reading dossier..."
dossier_content=$(cat "$DOSSIER_FILE")

# === [2/5] Read SE inventory ===
echo "[2/5] Reading SE inventory..."
se_content=""
if [[ -f "$SE_INVENTORY" ]]; then
    se_content=$(cat "$SE_INVENTORY")
fi

# === [3/5] Check FIF for account references ===
echo "[3/5] Checking FIF for account references..."
fif_content=""

# Check digest files (last 30 days)
if [[ -d "$FIF_DIGEST_DIR" ]]; then
    fif_matches=""
    while IFS= read -r digest_file; do
        [[ -z "$digest_file" ]] && continue
        match_lines=$(grep -B1 -A3 -i "$account_display\|$file_slug" "$digest_file" 2>/dev/null | head -20) || true
        if [[ -n "$match_lines" ]]; then
            fif_matches+="### $(basename "$digest_file")"$'\n'
            fif_matches+="$match_lines"$'\n\n'
        fi
    done < <(find "$FIF_DIGEST_DIR" -name "*.md" -mtime -30 2>/dev/null | head -10)

    if [[ -n "$fif_matches" ]]; then
        fif_content="$fif_matches"
        echo "  Found FIF digest matches."
    fi
fi

# Check signal-notes
signal_content=""
if [[ -d "$SIGNAL_NOTES_DIR" ]]; then
    signal_matches=""
    while IFS= read -r note_file; do
        [[ -z "$note_file" ]] && continue
        signal_matches+="- $(basename "$note_file")"$'\n'
    done < <(find "$SIGNAL_NOTES_DIR" -name "*.md" -mtime -30 2>/dev/null | xargs grep -li "$account_display\|$file_slug" 2>/dev/null | head -3)

    if [[ -n "$signal_matches" ]]; then
        signal_content="$signal_matches"
        echo "  Found signal-note matches."
    fi
fi

if [[ -z "$fif_content" && -z "$signal_content" ]]; then
    echo "  No FIF or signal-note matches."
fi

# === [4/5] Check daily attention artifact ===
echo "[4/5] Checking daily attention artifact..."
attention_content=""
daily_file="$DAILY_ARTIFACT_DIR/$TODAY.md"
if [[ -f "$daily_file" ]]; then
    attention_mention=$(grep -i "$account_display\|$file_slug" "$daily_file" 2>/dev/null | head -3) || true
    if [[ -n "$attention_mention" ]]; then
        attention_content="$attention_mention"
        echo "  Account appears in today's daily plan."
    else
        echo "  Account not in today's daily plan."
    fi
else
    echo "  No daily plan for today."
fi

# === [5/5] External signal (last30days) ===
echo "[5/5] External signal (last30days)..."
last30days_content=""

if [[ "$SKIP_WEB" == "false" && -f "$LAST30DAYS_ENGINE" ]]; then
    last30days_output="/tmp/meeting-prep-last30days-${file_slug}-${TODAY}.txt"

    # Run as openclaw user — .env API keys are 600 (owner-only).
    # macOS has no `timeout` — use perl alarm.
    # --include-web is mandatory for B2B queries (validated 2026-03-09c).
    if perl -e 'alarm shift; exec @ARGV' "$TIMEOUT_SECS" \
        sudo -u openclaw env HOME=/Users/openclaw \
        python3 "$LAST30DAYS_ENGINE" "$account_display" --emit context --include-web \
        > "$last30days_output" 2>/dev/null; then

        output_size=$(wc -c < "$last30days_output" | tr -d ' ')
        if [[ "$output_size" -gt 100 ]]; then
            last30days_content=$(cat "$last30days_output")
            echo "  Got ${output_size} bytes of external signal."
        else
            echo "  No meaningful signal returned."
        fi
    else
        echo "  last30days failed or timed out (${TIMEOUT_SECS}s). Proceeding vault-only."
    fi
elif [[ "$SKIP_WEB" == "true" ]]; then
    echo "  Skipped (--skip-web)."
else
    echo "  last30days engine not available."
fi

# === Assemble context file ===
# Build context incrementally to avoid complex heredoc expansions.
{
    echo "# Meeting Prep Context — $account_display — $TODAY"
    echo ""
    echo "## Account Dossier"
    echo ""
    echo "$dossier_content"
    echo ""
    echo "---"
    echo ""
    echo "## SE Management Context"
    echo ""
    if [[ -n "$se_content" ]]; then
        echo "$se_content"
    else
        echo "No SE inventory available."
    fi
    echo ""
    echo "---"
    echo ""
    echo "## Feed Intelligence"
    echo ""
    if [[ -n "$fif_content" ]]; then
        echo "$fif_content"
    else
        echo "No FIF digest matches in last 30 days."
    fi
    if [[ -n "$signal_content" ]]; then
        echo ""
        echo "### Signal Notes"
        echo "$signal_content"
    fi
    echo ""
    echo "---"
    echo ""
    echo "## Attention Context"
    echo ""
    if [[ -n "$attention_content" ]]; then
        echo "$attention_content"
    else
        echo "Account not in today's daily plan."
    fi
    echo ""
    echo "---"
    echo ""
    echo "## External Signal (last30days)"
    echo ""
    if [[ -n "$last30days_content" ]]; then
        echo "$last30days_content"
    else
        echo "No external signal available. Brief is vault-intelligence only."
    fi
} > "$CONTEXT_FILE"

context_bytes=$(wc -c < "$CONTEXT_FILE" | tr -d ' ')
echo ""
echo "Context assembled: ${context_bytes} bytes"
echo "Context file: $CONTEXT_FILE"

# === Construct synthesis prompt ===
# The prompt combines instructions + data context into a single message
# passed to `openclaw agent -m`. Instructions first, data after the
# separator, so the model reads instructions before data.

PROMPT_FILE="/tmp/meeting-prep-prompt-${file_slug}-${TODAY}.md"

cat > "$PROMPT_FILE" << ENDPROMPT
You are assembling a pre-meeting brief for Danny about $account_display.
Be concise, actionable, and scannable. Danny will read this on his phone
in 5 minutes before walking into the meeting.

Synthesize the context below into a meeting prep brief. Write the brief
in markdown with these exact sections:

## Quick Context
2-3 sentences: who they are, relationship status, last interaction.

## Recent Intelligence
- Bullet per signal — include source attribution (dossier, FIF, last30days)
- If no recent intelligence exists, say "No recent signals."

## Key People
Names, titles, last interaction date — from dossier.

## Open Items
Action items, pending proposals, follow-ups — from SE inventory + dossier.

## Talking Points
3-5 suggested conversation topics based on intelligence + relationship context.

## External Signal
If last30days data is present, include a compact summary with source links.
If not, say "Vault intelligence only — no external signal available."

Rules:
- Max 2000 tokens output
- Do NOT hallucinate information not present in the context below
- If a section has no supporting data, say so briefly — don't fill with generic advice
- Attribute all intelligence to its source
- Use wikilinks for vault references (e.g., [[auto-club-group]])
- Output ONLY the brief — no commentary, no "here's your brief", just the content

---

$(cat "$CONTEXT_FILE")
ENDPROMPT

prompt_bytes=$(wc -c < "$PROMPT_FILE" | tr -d ' ')
echo "Prompt file: $PROMPT_FILE (${prompt_bytes} bytes)"

# === Token budget check ===
# Design specifies 20k token ceiling. Rough estimate: 4 chars/token.
estimated_tokens=$((prompt_bytes / 4))
if [[ "$estimated_tokens" -gt 18000 ]]; then
    echo "WARNING: Estimated ${estimated_tokens} tokens — approaching 20k ceiling." >&2
    echo "Consider trimming dossier or using --skip-web." >&2
fi

# === Launch or dry-run ===
if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo "DRY RUN — not launching Tess session."
    echo "Review context: cat $CONTEXT_FILE"
    echo "Review prompt:  cat $PROMPT_FILE"
    echo ""
    echo "To invoke manually:"
    echo "  cd /tmp && sudo -u openclaw env HOME=/Users/openclaw \\"
    echo "    /Users/openclaw/.local/bin/openclaw agent \\"
    echo "    --agent voice -m \"\$(cat $PROMPT_FILE)\" \\"
    echo "    --timeout 120"
    exit 0
fi

# === Telegram delivery ===
# Direct curl to Telegram Bot API — bypasses OpenClaw delivery pipeline
# (delivery.to bug + in-memory DM pairings lost on restart).
# Same pattern as vault-health.sh and awareness-check.sh.
TELEGRAM_BOT_TOKEN="${TESS_AWARENESS_BOT_TOKEN:-$(security find-generic-password -a tess-bot -s tess-awareness-bot-token -w 2>/dev/null || echo "")}"
TELEGRAM_CHAT_ID="7754252365"

send_telegram() {
    local text="$1"

    if [[ -z "$TELEGRAM_BOT_TOKEN" ]]; then
        echo "WARNING: TESS_AWARENESS_BOT_TOKEN not set — skipping Telegram delivery." >&2
        return 1
    fi

    # Telegram message limit is 4096 chars. Truncate with notice if needed.
    if [[ ${#text} -gt 4000 ]]; then
        text="${text:0:3950}

[truncated — full brief in vault]"
    fi

    local response http_code
    response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
        --connect-timeout 10 \
        --max-time 15 \
        -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d parse_mode="Markdown" \
        --data-urlencode text="$text" \
        2>/dev/null)

    http_code=$(echo "$response" | tail -1 | sed 's/HTTP_CODE://')

    if [[ "$http_code" == "200" ]]; then
        echo "  Telegram delivery: OK"
        return 0
    else
        # Retry without parse_mode — Markdown escaping issues
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
            --connect-timeout 10 \
            --max-time 15 \
            -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d chat_id="$TELEGRAM_CHAT_ID" \
            --data-urlencode text="$text" \
            2>/dev/null)
        http_code=$(echo "$response" | tail -1 | sed 's/HTTP_CODE://')
        if [[ "$http_code" == "200" ]]; then
            echo "  Telegram delivery: OK (plain text fallback)"
            return 0
        fi
        echo "  Telegram delivery: FAILED (HTTP $http_code)" >&2
        return 1
    fi
}

# === Agent invocation ===
# Verified against `openclaw agent --help` (v2026.2.25):
#   --agent <id>       Agent id (voice = Tess)
#   -m, --message      Message body
#   --timeout          Override timeout in seconds (default 600)
#
# No --deliver flag: we handle Telegram delivery ourselves via direct curl.
#
# Known issues:
#   - --model override broken in isolated sessions (#9556/#14279)
#     Model is determined by the agent's config, not overridable here.
#
# The prompt is passed as the message body via -m "$(cat file)".
# Shell ARG_MAX on macOS is ~256KB; our prompts are ~14KB — well within limits.

AGENT_OUTPUT="/tmp/meeting-prep-agent-${file_slug}-${TODAY}.txt"

echo ""
echo "Launching Tess synthesis session..."

cd /tmp
sudo -u openclaw env HOME=/Users/openclaw \
    /Users/openclaw/.local/bin/openclaw agent \
    --agent voice \
    -m "$(cat "$PROMPT_FILE")" \
    --timeout 120 \
    > "$AGENT_OUTPUT" 2>/dev/null

agent_exit=$?

if [[ "$agent_exit" -ne 0 ]]; then
    echo "ERROR: Agent exited with code $agent_exit" >&2
    exit 1
fi

agent_bytes=$(wc -c < "$AGENT_OUTPUT" | tr -d ' ')
if [[ "$agent_bytes" -lt 50 ]]; then
    echo "ERROR: Agent produced insufficient output (${agent_bytes} bytes)" >&2
    exit 1
fi

echo "Agent output: ${agent_bytes} bytes"

# === Vault copy (written as tess — no permission issues) ===
mkdir -p "$OUTPUT_DIR"
cp "$AGENT_OUTPUT" "$OUTPUT_FILE"
echo "Vault copy: $OUTPUT_FILE"

# === Telegram delivery ===
brief_content=$(cat "$AGENT_OUTPUT")
send_telegram "$brief_content" || true

echo ""
echo "Done."
