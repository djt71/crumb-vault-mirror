#!/usr/bin/env bash
# connections-brainstorm.sh — Weekly cross-domain connections brainstorm
#
# Source: tess-operations TOP-048
# Spec: tess-chief-of-staff-spec.md §8.4
# Model: Claude Sonnet 4.6 (synthesis quality justifies weekly cost)
# Schedule: Weekly, Monday early morning (via LaunchAgent, same as daily-attention)
#   Script is idempotent — exits if this week's artifact already exists.
#
# Architecture (Option A): bash gathers all context, builds prompt,
# single API call for synthesis, bash writes artifact + sends notification.
#
# Usage (manual): bash connections-brainstorm.sh [--dry-run]

source "/Users/tess/crumb-vault/_openclaw/scripts/cron-lib.sh"
source "$VAULT_ROOT/_openclaw/lib/gws-token.sh"

# === Constants ===
TODAY=$(date +%Y-%m-%d)
DAY_OF_WEEK=$(date +%A)
WEEK_NUM=$(date +%Y-W%V)
OUTPUT_DIR="$BRIDGE_DIR/inbox"
OUTPUT_FILE="$OUTPUT_DIR/brainstorm-${TODAY}.md"
MAX_OUTPUT_TOKENS=8000
MAX_API_RETRIES=3

# API config
ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-$(security find-generic-password -a crumb -s anthropic-api-key -w 2>/dev/null || echo "")}"
API_MODEL="claude-sonnet-4-6"

# Telegram
TELEGRAM_BOT_TOKEN="${TESS_AWARENESS_BOT_TOKEN:-$(security find-generic-password -a tess-bot -s tess-awareness-bot-token -w 2>/dev/null || echo "")}"
TELEGRAM_CHAT_ID="7754252365"

# === Argument parsing ===
DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        *) echo "ERROR: Unknown flag: $1" >&2; exit 1 ;;
    esac
done

# === Init cron infrastructure ===
if [[ "$DRY_RUN" == "false" ]]; then
    cron_init "connections-brainstorm" --wall-time 300 --jitter 120
fi

# === Idempotency: check if this week's brainstorm already exists ===
if [[ "$DRY_RUN" == "false" ]]; then
    existing=$(grep -rl "week: ${WEEK_NUM}" "$OUTPUT_DIR"/brainstorm-*.md 2>/dev/null | head -1)
    if [[ -n "$existing" ]]; then
        echo "This week's brainstorm already exists: $existing — skipping."
        cron_set_cost "0.00"
        cron_finish 0
    fi
fi

echo "=== Connections Brainstorm — $TODAY ($DAY_OF_WEEK, $WEEK_NUM) ==="

# ===========================================================================
# Context Gathering
# ===========================================================================

echo "Gathering context..."

# --- Recent vault additions (last 7 days) ---
recent_signals=""
if [[ -d "$VAULT_ROOT/_system/signal-notes" ]]; then
    recent_signals=$(find "$VAULT_ROOT/_system/signal-notes" -name "*.md" -mtime -7 2>/dev/null | while read f; do
        title=$(head -20 "$f" | grep -E "^(title|#)" | head -1 | sed 's/^[#]* *//' | sed 's/^title: *//' | tr -d '"')
        tags=$(head -20 "$f" | grep "^tags:" | head -1 | sed 's/^tags: *//')
        echo "- ${title:-$(basename "$f")} ${tags:+($tags)}"
    done | head -15)
fi

recent_research=""
if [[ -d "$VAULT_ROOT/Sources/research" ]]; then
    recent_research=$(find "$VAULT_ROOT/Sources/research" -name "*.md" -not -name "*source-index*" -mtime -7 2>/dev/null | while read f; do
        title=$(head -10 "$f" | grep -E "^(title|#)" | head -1 | sed 's/^[#]* *//' | sed 's/^title: *//' | tr -d '"')
        echo "- ${title:-$(basename "$f")}"
    done | head -10)
fi

recent_insights=""
if [[ -d "$VAULT_ROOT/Sources/insights" ]]; then
    recent_insights=$(find "$VAULT_ROOT/Sources/insights" -name "*.md" -mtime -7 2>/dev/null | while read f; do
        title=$(head -10 "$f" | grep -E "^(title|#)" | head -1 | sed 's/^[#]* *//' | sed 's/^title: *//' | tr -d '"')
        echo "- ${title:-$(basename "$f")}"
    done | head -10)
fi

# --- Active project states ---
project_states=""
while IFS= read -r pstate; do
    [[ -z "$pstate" ]] && continue
    local_name=$(grep -E "^(name|project):" "$pstate" 2>/dev/null | head -1 | sed 's/^[a-z_]*: *//')
    [[ -z "$local_name" ]] && local_name=$(basename "$(dirname "$pstate")")
    local_phase=$(grep "^phase:" "$pstate" 2>/dev/null | head -1 | awk '{print $2}')
    local_next=$(grep "^next_action:" "$pstate" 2>/dev/null | head -1 | sed 's/^next_action: *//' | tr -d '"' | head -c 200)
    if [[ "$local_phase" != "DONE" && "$local_phase" != "ARCHIVED" && -n "$local_name" ]]; then
        project_states="${project_states}
- **${local_name}** (${local_phase}): ${local_next}"
    fi
done < <(find "$VAULT_ROOT/Projects" -name "project-state.yaml" -not -path "*/Archived/*" 2>/dev/null)

# --- Calendar (next 14 days) ---
calendar_events=""
if gws_get_token > /dev/null 2>&1; then
    end_date=$(date -v+14d +%Y-%m-%d)
    raw_events=$(gws_calendar_events "$TODAY" "$end_date" "primary" 2>/dev/null) || true
    if [[ -n "$raw_events" ]]; then
        event_count=$(echo "$raw_events" | jq '.items // [] | length' 2>/dev/null || echo "0")
        if [[ "$event_count" -gt 0 ]]; then
            calendar_events=$(echo "$raw_events" | jq -r '
                .items[] |
                (.start.dateTime // .start.date) as $start |
                ($start | split("T")[0]) as $date |
                "- " + $date + " — " + .summary +
                (if .attendees then " (with: " + ([.attendees[].email // empty] | join(", ")) + ")" else "" end)
            ' 2>/dev/null | head -20) || true
        fi
    fi
fi
[[ -z "$calendar_events" ]] && calendar_events="No calendar events in the next 14 days."

# --- Account intelligence (customer dossiers) ---
account_intel=""
DOSSIER_DIR="$VAULT_ROOT/Projects/customer-intelligence/dossiers"
if [[ -d "$DOSSIER_DIR" ]]; then
    account_intel=$(find "$DOSSIER_DIR" -name "*.md" 2>/dev/null | while read f; do
        name=$(head -5 "$f" | grep -E "^(title|#)" | head -1 | sed 's/^[#]* *//' | sed 's/^title: *//' | tr -d '"')
        echo "- ${name:-$(basename "$f" .md)}"
    done | head -10)
fi

# --- Feed-intel digests (last 7 days) ---
feed_intel=""
DIGEST_DIR="$VAULT_ROOT/_openclaw/data/scout-digests"
if [[ -d "$DIGEST_DIR" ]]; then
    feed_intel=$(find "$DIGEST_DIR" -name "*.md" -mtime -7 2>/dev/null | sort -r | head -3 | while read f; do
        echo "### $(basename "$f" .md)"
        head -50 "$f" | tail -40
        echo ""
    done)
fi

# --- Strategic priorities ---
strategic_priorities=""
if [[ -f "$VAULT_ROOT/_system/docs/personal-context.md" ]]; then
    strategic_priorities=$(sed -n '/^## Strategic Priorities/,/^## /p' "$VAULT_ROOT/_system/docs/personal-context.md" | head -20)
fi

proj_count=$(echo "$project_states" | grep -c '^\-' || true)
signal_count=$(echo "$recent_signals" | grep -c '^\-' || true)
echo "Context: $proj_count active projects, $signal_count signal notes, calendar, account intel, feed-intel digests"

# ===========================================================================
# Prompt Construction
# ===========================================================================

system_prompt="You are generating a weekly connections brainstorm for a personal intelligence system. Your job is to find unexpected connections, relationship opportunities, and cross-domain patterns that the operator would not notice on their own.

The operator is a customer-facing Solutions Engineer at Infoblox (DDI/DNS security). He runs personal software projects (Crumb multi-agent OS), values Zen practice, walking, and wide reading. He is building in public and developing autonomous agent infrastructure.

Your value is SYNTHESIS — connecting dots across domains, surfacing relationship opportunities, identifying people who should be introduced or re-engaged, and spotting patterns that suggest timing advantages.

Quality rules:
- **Variable output:** Include only connections that are genuinely non-obvious. This may be 1, or 5, or zero. Never pad to hit a number.
- **Read, don't guess:** If you reference a vault artifact, base the connection on its actual content (provided below), not on what the filename suggests it might contain. If the content is not provided, say so — do not speculate with hedging language like 'presumably' or 'likely contains'.
- **Novelty required:** Do not propose a connection that an experienced operator would already see from reading the project states. The bar is: would this change someone's behavior or just confirm what they already know?
- **Relationship section gated on new data:** Only include relationship suggestions when there is a new signal (calendar event, project milestone, feed-intel item) that creates a specific reason to engage now. Do not recycle contacts from previous brainstorms without new information.

Focus areas:
1. **Cross-domain patterns:** What themes connect across different projects, readings, or feed-intel items? What surprising overlaps exist?
2. **Relationship opportunities:** Who should be contacted, re-engaged, or introduced? Only when a specific trigger exists.
3. **Timing advantages:** What's happening in the next 2 weeks that creates an opening? Calendar events, industry trends, seasonal patterns?
4. **Knowledge leverage:** What recent reading/research could be shared with specific contacts or applied to customer conversations?
5. **Builder community:** What recent signals suggest collaboration opportunities in the AI/agent ecosystem?"

user_message="## Week of ${TODAY} (${WEEK_NUM})

## Strategic Priorities
${strategic_priorities:-No strategic priorities loaded.}

## Calendar — Next 14 Days
${calendar_events}

## Active Projects (${proj_count})
${project_states:-No active projects.}

## Recent Signal Notes (last 7 days)
${recent_signals:-No recent signal notes.}

## Recent Research (last 7 days)
${recent_research:-No recent research.}

## Recent Insights (last 7 days)
${recent_insights:-No recent insights.}

## Account Intelligence
${account_intel:-No customer dossiers available.}

## Feed-Intel Digests (last 7 days)
${feed_intel:-No recent feed-intel digests.}

---

## Output Format

Produce a brainstorm document with these sections. Sections with no quality content should be omitted entirely — an empty section is worse than a missing one.

### Cross-Domain Connections
As many surprising connections as genuinely exist (may be zero). For each:
- What two domains or topics connect
- Why the connection is non-obvious (would the operator miss this?)
- What specific action it suggests

### Relationship Opportunities
Only people where a specific, new trigger exists. For each:
- Who and why NOW (the trigger, not generic 'stay in touch')
- Suggested action
- What to share or discuss

### Timing Advantages
Things where timing creates an opening in the next 2 weeks. Only include if genuinely time-sensitive.

### One Surprising Idea
One connection or idea that doesn't fit neatly into the above categories but is worth noting. If nothing qualifies, omit this section.

Be specific. Name names when you have them. Reference specific vault artifacts. Avoid generic advice. Quality over quantity — a brainstorm with 2 strong insights is better than one with 5 mediocre observations."

# ===========================================================================
# Token Budget Guard
# ===========================================================================

total_prompt_chars=$(( ${#system_prompt} + ${#user_message} ))
estimated_tokens=$(( total_prompt_chars * 10 / 35 ))

echo "Prompt size: ~${estimated_tokens} tokens (system: ${#system_prompt} chars, user: ${#user_message} chars)"

# ===========================================================================
# Dry-Run Exit
# ===========================================================================

if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo "DRY RUN — prompt constructed but not sent."
    echo "System prompt: ${#system_prompt} chars"
    echo "User message: ${#user_message} chars"
    echo "Estimated tokens: ~$estimated_tokens"
    echo ""
    echo "=== User Message (first 1000 chars) ==="
    echo "${user_message:0:1000}..."
    exit 0
fi

# ===========================================================================
# API Call (with retry)
# ===========================================================================

if [[ -z "$ANTHROPIC_API_KEY" ]]; then
    echo "ERROR: ANTHROPIC_API_KEY not available" >&2
    cron_mark_alert
    cron_finish 1
fi

echo "Calling Anthropic API ($API_MODEL)..."

payload=$(jq -n \
    --arg model "$API_MODEL" \
    --argjson max_tokens "$MAX_OUTPUT_TOKENS" \
    --arg system "$system_prompt" \
    --arg user_msg "$user_message" \
    '{model: $model, max_tokens: $max_tokens, system: $system, messages: [{role: "user", content: $user_msg}]}')

response=""
api_success=false
backoff_delays=(0 3 8)

for attempt in $(seq 0 $((MAX_API_RETRIES - 1))); do
    if [[ "$attempt" -gt 0 ]]; then
        echo "Retry $attempt (backoff: ${backoff_delays[$attempt]}s)..."
        sleep "${backoff_delays[$attempt]}"
    fi

    response=$(curl -s -X POST "https://api.anthropic.com/v1/messages" \
        -H "content-type: application/json" \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        --connect-timeout 30 \
        --max-time 120 \
        -d "$payload")

    curl_exit=$?
    if [[ "$curl_exit" -ne 0 ]]; then
        echo "WARNING: curl failed with exit code $curl_exit (attempt $((attempt+1))/$MAX_API_RETRIES)" >&2
        continue
    fi

    api_error=$(echo "$response" | jq -r '.error.message // empty' 2>/dev/null)
    if [[ -n "$api_error" ]]; then
        echo "WARNING: API error: $api_error (attempt $((attempt+1))/$MAX_API_RETRIES)" >&2
        continue
    fi

    api_success=true
    break
done

if [[ "$api_success" != "true" ]]; then
    echo "ERROR: API call failed after $MAX_API_RETRIES attempts" >&2
    cron_mark_alert
    cron_finish 1
fi

# Extract text content
full_response=$(echo "$response" | jq -r '.content[0].text // empty')
if [[ -z "$full_response" || ${#full_response} -lt 200 ]]; then
    echo "ERROR: Insufficient output (${#full_response} chars)" >&2
    cron_mark_alert
    cron_finish 1
fi

# Extract token usage
input_tokens=$(echo "$response" | jq -r '.usage.input_tokens // 0')
output_tokens=$(echo "$response" | jq -r '.usage.output_tokens // 0')

echo "API response: ${#full_response} chars, ${input_tokens} in / ${output_tokens} out"

# ===========================================================================
# Write Artifact
# ===========================================================================

mkdir -p "$OUTPUT_DIR"

# Add frontmatter
artifact="---
type: connections-brainstorm
status: pending-review
created: ${TODAY}
updated: ${TODAY}
week: ${WEEK_NUM}
model: ${API_MODEL}
skill_origin: connections-brainstorm
---

${full_response}"

echo "$artifact" > "$OUTPUT_FILE"
chmod 644 "$OUTPUT_FILE"
echo "Artifact written: $OUTPUT_FILE"

# ===========================================================================
# Telegram Notification
# ===========================================================================

if [[ -n "$TELEGRAM_BOT_TOKEN" ]]; then
    # Count sections for summary
    connections_count=$(echo "$full_response" | grep -c "^###\|^[0-9]\." || true)
    notify_text="🧠 <b>Connections Brainstorm</b> — ${WEEK_NUM}

${connections_count} insights generated. Review: <code>_openclaw/inbox/brainstorm-${TODAY}.md</code>"

    curl -s -o /dev/null \
        --connect-timeout 10 --max-time 15 \
        -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d parse_mode="HTML" \
        --data-urlencode text="$notify_text" \
        2>/dev/null || echo "WARNING: Telegram notification failed" >&2
fi

# ===========================================================================
# Metrics
# ===========================================================================

# Sonnet 4.6 pricing: $3/Mtok input, $15/Mtok output
cost_estimate=$(awk "BEGIN {printf \"%.4f\", ($input_tokens * 3 + $output_tokens * 15) / 1000000}")
cron_set_tokens "$input_tokens" "$output_tokens"
cron_set_cost "$cost_estimate"

echo "Done. Cost: ~\$${cost_estimate}"
cron_finish 0
