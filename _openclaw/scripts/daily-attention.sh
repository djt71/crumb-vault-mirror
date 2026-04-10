#!/usr/bin/env bash
# daily-attention.sh — Generate daily attention artifact before morning briefing
#
# Source: tess-operations TOP-056
# Model: Claude Opus (direct API — no claude CLI dependency)
# Schedule: every 30 min via LaunchAgent (StartInterval 1800s + RunAtLoad)
#   Script is idempotent — exits immediately if today's artifact already exists.
#   Generates once per day on first run after midnight.
#
# Architecture (Option A): bash gathers all context, builds prompt,
# single API call for synthesis, bash writes artifact. No tool calls.
#
# Usage (manual): bash daily-attention.sh [--dry-run]

source "/Users/tess/crumb-vault/_openclaw/scripts/cron-lib.sh"
source "/Users/tess/crumb-vault/_openclaw/scripts/attention-lib.sh"
source "$VAULT_ROOT/_openclaw/lib/gws-token.sh"

# === Constants ===
TODAY=$(date +%Y-%m-%d)
DAY_OF_WEEK=$(date +%A)
DAILY_DIR="$VAULT_ROOT/_system/daily"
OUTPUT_FILE="$DAILY_DIR/${TODAY}.md"
SIDECAR_DIR="$ATTN_DATA_DIR/sidecar"
SIDECAR_FILE="$SIDECAR_DIR/${TODAY}.json"
MAX_INPUT_ESTIMATE=7000  # chars / 3.5 ≈ tokens; truncate if exceeded (raised from 6000 for AO-003 dedup context)
MAX_OUTPUT_TOKENS=4500   # increased from 4000 to accommodate JSON block
MAX_API_RETRIES=3

# API config — keychain first, env var fallback
ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-$(security find-generic-password -a crumb -s anthropic-api-key -w 2>/dev/null || echo "")}"
API_MODEL="claude-opus-4-6"

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
    cron_init "daily-attention" --wall-time 120
fi

# === Init replay database ===
attn_init_db

# Skip if artifact already exists (manual generation earlier in the day)
# Dry-run bypasses this check to allow prompt testing
if [[ -f "$OUTPUT_FILE" && "$DRY_RUN" == "false" ]]; then
    echo "Artifact already exists: $OUTPUT_FILE — skipping."
    cron_set_cost "0.00"
    cron_finish 0
fi

# ===========================================================================
# Pre-Processing: Correlation (AO-004)
# ===========================================================================
# Run correlation for items whose windows closed since last cycle.
# Non-fatal: if correlation fails, continue with artifact generation.

echo "=== Daily Attention — $TODAY ($DAY_OF_WEEK) ==="

if [[ "$DRY_RUN" == "false" ]]; then
    echo "Running correlation engine..."
    bash "$VAULT_ROOT/_openclaw/scripts/attention-correlate.sh" 2>&1 || echo "WARNING: Correlation failed (non-fatal)" >&2
fi

# ===========================================================================
# Pre-Processing: Dedup Context (AO-003)
# ===========================================================================

dedup_context=""
dedup_section=""
if [[ $(attn_cycle_count) -gt 0 ]]; then
    recent_json=$(attn_recent_items 3 20)
    if [[ -n "$recent_json" && "$recent_json" != "[]" ]]; then
        item_cnt=$(echo "$recent_json" | jq 'length' 2>/dev/null || echo "0")
        if [[ "$item_cnt" -gt 0 ]]; then
            dedup_context="$recent_json"
            dedup_section="
## Recent History (machine use only)
<historical_context purpose=\"dedup reference only — do not copy these items into your output\">
${recent_json}
</historical_context>"
            echo "Dedup context: $item_cnt items from last 3 cycles"
        fi
    fi
fi

# ===========================================================================
# Context Gathering
# ===========================================================================

echo "Gathering context..."

# Goal tracker
goal_tracker=""
if [[ -f "$VAULT_ROOT/_system/docs/goal-tracker.yaml" ]]; then
    goal_tracker=$(cat "$VAULT_ROOT/_system/docs/goal-tracker.yaml")
fi

# SE inventory — recurring obligations only
se_inventory=""
if [[ -f "$VAULT_ROOT/Domains/Career/se-management-inventory.md" ]]; then
    se_inventory=$(sed -n '/^## Recurring/,/^## Ad-hoc/p' "$VAULT_ROOT/Domains/Career/se-management-inventory.md" | head -40)
fi

# Strategic priorities (just that section from personal-context.md)
strategic_priorities=""
if [[ -f "$VAULT_ROOT/_system/docs/personal-context.md" ]]; then
    strategic_priorities=$(sed -n '/^## Strategic Priorities/,/^## Professional Context/p' "$VAULT_ROOT/_system/docs/personal-context.md" | head -20)
fi

# Most recent daily artifact within 3 days (carry-forward source)
previous_artifact=""
previous_date=""
for days_ago in 1 2 3; do
    check_date=$(date -v-${days_ago}d +%Y-%m-%d)
    check_file="$DAILY_DIR/${check_date}.md"
    if [[ -f "$check_file" ]]; then
        previous_artifact=$(cat "$check_file")
        previous_date="$check_date"
        break
    fi
done

# Active project states — extract phase + next_action from each
project_states=""
while IFS= read -r pstate; do
    [[ -z "$pstate" ]] && continue
    # Name field varies: name:, project:, or fall back to directory name
    local_name=$(grep -E "^(name|project):" "$pstate" 2>/dev/null | head -1 | sed 's/^[a-z_]*: *//')
    if [[ -z "$local_name" ]]; then
        local_name=$(basename "$(dirname "$pstate")")
    fi
    local_phase=$(grep "^phase:" "$pstate" 2>/dev/null | head -1 | awk '{print $2}')
    local_next=$(grep "^next_action:" "$pstate" 2>/dev/null | head -1 | sed 's/^next_action: *//' | tr -d '"')
    if [[ "$local_phase" != "DONE" && "$local_phase" != "ARCHIVED" && -n "$local_name" ]]; then
        # Vault-relative path for downstream structured extraction
        local_relpath="${pstate#$VAULT_ROOT/}"
        project_states="${project_states}
- **${local_name}** (${local_phase}) [${local_relpath}]: ${local_next}"
    fi
done < <(find "$VAULT_ROOT/Projects" -name "project-state.yaml" -not -path "*/Archived/*" 2>/dev/null)

proj_count=$(echo "$project_states" | grep -c '^\-' || true)

# Today's calendar events (Google Calendar via REST API)
calendar_events=""
calendar_status="unavailable"
if gws_get_token > /dev/null 2>&1; then
    tomorrow=$(date -v+1d +%Y-%m-%d)
    raw_events=$(gws_calendar_events "$TODAY" "$tomorrow" "primary" 2>/dev/null) || true
    if [[ -n "$raw_events" ]]; then
        event_count=$(echo "$raw_events" | jq '.items // [] | length' 2>/dev/null || echo "0")
        if [[ "$event_count" -gt 0 ]]; then
            calendar_events=$(echo "$raw_events" | jq -r '
                .items[] |
                (.start.dateTime // .start.date) as $start |
                (.end.dateTime // .end.date) as $end |
                "- " +
                (if .start.dateTime then
                    ($start | split("T")[1] | split("-")[0] | split("+")[0] | .[0:5])
                    + "–" +
                    ($end | split("T")[1] | split("-")[0] | split("+")[0] | .[0:5])
                else "all-day" end)
                + " — " + .summary
            ' 2>/dev/null) || true
            calendar_status="$event_count events"
        else
            calendar_events="No events scheduled today."
            calendar_status="empty"
        fi
    fi
else
    calendar_events="Google auth unavailable — calendar not loaded."
fi

echo "Context: goal-tracker, SE inventory, strategic priorities, previous artifact (${previous_date:-none}), ${proj_count} active projects, calendar ($calendar_status)"

# ===========================================================================
# Prompt Construction
# ===========================================================================

system_prompt="You are generating a daily attention artifact for a personal attention management system. You curate the operator's daily attention — producing an opinionated short list of 5-8 items that deserve focus today, applying philosophical and professional lenses.

Governing principle: 'I run the 24 hours. The 24 hours doesn't run me.'

The operator is a customer-facing Solutions Engineer at Infoblox (DDI/DNS security). He also runs personal software projects (Crumb multi-agent OS) and values Zen practice (twice-daily zazen), walking, and wide reading. He is a solo operator with limited time outside customer work.

Key personal philosophy notes:
- Creation is spiritual practice — building things is how he processes the world
- 'Most people are asleep' — the edge is knowing you don't know
- Trust yourself — comfortable at odds with popular opinion
- Show up — presence is the foundation, especially when you don't feel like it
- Walking is medicine — the body knows things the mind doesn't"

# Build user message with all context
if [[ -n "$previous_date" ]]; then
    prev_section="## Previous Daily Artifact ($previous_date — carry-forward source)
$previous_artifact"
else
    prev_section="## Previous Daily Artifact
No artifact found within 3 days. Produce a fresh list from all input sources. Note the gap in the artifact."
fi

user_message="## Today
Date: ${TODAY} (${DAY_OF_WEEK})

## Today's Calendar (Google Calendar — real-time)
${calendar_events}

## Goal Tracker [_system/docs/goal-tracker.yaml]
${goal_tracker}

## SE Recurring Obligations [Domains/Career/se-management-inventory.md]
${se_inventory}

## Strategic Priorities
${strategic_priorities}

${prev_section}

## Active Projects
${project_states}
${dedup_section}

---

## Procedure

### Carry-Forward
- Extract all Focus items from the previous artifact that are NOT checked off (\`- [ ]\`)
- For each unchecked item, increment the carry counter:
  - If it has 'carried N days', increment N
  - If no annotation, this is the first carry — set to 1 day
  - Track original date (from 'originally YYYY-MM-DD' or infer)
- Items carried 5+ days get an escalation note: 'This has been deferred for N days. Is it still a priority, or should it be dropped/rescheduled?'
- Checked off items (\`- [x]\`) or deleted items are done — do not carry

### Recurrence Detection
If a <historical_context> block is present above, use it to detect recurring items:
- If an item matches a historical object_id, keep the same object_id and set is_recurrence to true in the JSON.
- Do NOT copy historical items verbatim — only surface items relevant today.
- Each object_id must appear exactly once in the JSON output — no duplicates.

### SE Cadence Check
For each recurring obligation with a cadence:
- Monday: flag weekly planning
- Mid-week (Wed/Thu): flag inspects, health check, AM session if not done
- Thursday/Friday: flag time tracking if not mentioned recently
- Monthly items: flag if approaching deadline

### Prioritization Lenses

**Life Coach lens:**
1. Values alignment: does today's list reflect personal philosophy?
2. Whole-person impact: what does this cost in domains OTHER than the one it serves?
3. The 'enough' test: is the list trying to do too much?

**Career Coach lens:**
1. Skill leverage: are SE tasks crowding out skill-building?
2. Relationship capital: are customer engagement items getting attention?
3. Opportunity cost: is admin dominating?

**Calendar lens:**
1. Meeting density: a packed calendar day limits deep-work capacity — be realistic about what else fits
2. Meeting prep: flag Focus items that should happen BEFORE a specific meeting
3. Open blocks: if the calendar is light, surface higher-effort items that need uninterrupted time

**Priority resolution heuristic:**
- Non-negotiable commitments (family, health, hard deadlines) always make the list
- Among discretionary items, bias toward items with external visibility or time decay over items with only internal accountability
- Calendar conflicts: if a Focus item needs deep work but the calendar is packed, flag the tension
- 'Walk' is a standing health-domain item — include unless day is dominated by non-work priorities already

### Domain Balance
9 domains: software, career, learning, health, financial, relationships, creative, spiritual, lifestyle.
Flag if work domains (career + software) >60% today AND in the previous artifact.
Distinguish 'no input source exists' (health, financial, creative, spiritual may have nothing to surface) from 'input exists but was deprioritized.'

## Output

Output ONLY the artifact content — no commentary, no meta-text, no wrapping code fences.
Start directly with the YAML frontmatter (the --- line), then the markdown body.

Use this exact structure:

---
type: daily-attention
status: active
created: ${TODAY}
updated: ${TODAY}
skill_origin: attention-manager
---

# Daily Attention — ${TODAY}

> [Optional 1-2 sentence context note about what makes today distinct]

## Focus (N items)

- [ ] **[Item description]**
  - Why now: [specific reasoning — not generic]
  - Domain: [one of the 8 domains]
  - Action: [one of: do, decide, plan, track, review, wait]
  - Source: [[exact vault-relative path from context brackets, e.g. _system/docs/goal-tracker.yaml or Projects/deck-intel/project-state.yaml — use the EXACT path shown in square brackets in the input, not an abbreviated or invented name. Omit this line if no vault path applies.]]
  - Goal: GN *(only if item directly advances an active goal)*

## Domain Balance

[Table showing domain distribution. Assessment of work/life ratio.]

## Carry-Forward

[Items rolled from previous artifact with day counts and original dates]

## Deferred

[Items considered but excluded, with brief reasoning]

## Goal Alignment

[Table: Goal | Today's Items | Status — cover ALL active goals]

## Structured Data (REQUIRED — machine-readable)

After ALL the markdown content above, emit a fenced JSON block containing every Focus item as structured data. This block is consumed by downstream automation — do NOT omit it.

\`\`\`json
[
  {
    \"object_id\": \"vault-relative/path/to/source.md\",
    \"source_path\": \"vault-relative/path/to/source.md\",
    \"domain\": \"one of: software, career, learning, health, financial, relationships, creative, spiritual, lifestyle\",
    \"title\": \"Short item title matching the Focus item description\",
    \"action_class\": \"one of: do, decide, plan, track, review, wait\",
    \"urgency\": \"one of: low, medium, high, critical\"
  }
]
\`\`\`

Rules for the JSON block:
- One entry per Focus item, in the same order as the Focus section
- \`object_id\` and \`source_path\` are identical: the vault-relative file path shown in square brackets in the context (e.g., \`Projects/deck-intel/project-state.yaml\`, \`_system/docs/goal-tracker.yaml\`, \`Domains/Career/se-management-inventory.md\`). Use the EXACT path from the brackets — do not abbreviate or paraphrase. For items with no vault file source, set both to empty string \"\".
- \`domain\` must be one of the 8 canonical values listed above
- \`action_class\` must match the Action field from the Focus item
- \`urgency\` reflects time-sensitivity: critical (today or overdue), high (this week), medium (this month), low (ongoing/flexible)
- The JSON block must be the LAST thing in your output — nothing after the closing \`\`\`"

# ===========================================================================
# Token Budget Guard
# ===========================================================================

total_prompt_chars=$(( ${#system_prompt} + ${#user_message} ))
estimated_tokens=$(( total_prompt_chars * 10 / 35 ))  # chars / 3.5
truncation_note=""

if [[ "$estimated_tokens" -gt "$MAX_INPUT_ESTIMATE" ]]; then
    echo "WARNING: Estimated input tokens ($estimated_tokens) exceeds budget ($MAX_INPUT_ESTIMATE)"
    # Truncate priority: dedup context → SE inventory → previous artifact
    if [[ -n "$dedup_context" ]]; then
        echo "Truncating: dedup context removed"
        truncation_note="dedup context removed (token budget)"
        user_message=$(printf '%s\n' "$user_message" | sed '/^## Recent History/,/<\/historical_context>/d')
        dedup_context=""
        dedup_section=""
        total_prompt_chars=$(( ${#system_prompt} + ${#user_message} ))
        estimated_tokens=$(( total_prompt_chars * 10 / 35 ))
    fi
    if [[ "$estimated_tokens" -gt "$MAX_INPUT_ESTIMATE" && -n "$se_inventory" ]]; then
        echo "Truncating: SE inventory removed"
        truncation_note="${truncation_note:+$truncation_note; }SE inventory truncated (token budget)"
        user_message="${user_message//$se_inventory/[SE inventory truncated for token budget]}"
    fi
    # Recheck
    total_prompt_chars=$(( ${#system_prompt} + ${#user_message} ))
    estimated_tokens=$(( total_prompt_chars * 10 / 35 ))
    if [[ "$estimated_tokens" -gt "$MAX_INPUT_ESTIMATE" ]]; then
        echo "Truncating: previous artifact to 2000 chars"
        truncation_note="${truncation_note:+$truncation_note; }previous artifact truncated"
        if [[ -n "$previous_artifact" && ${#previous_artifact} -gt 2000 ]]; then
            user_message="${user_message//$previous_artifact/${previous_artifact:0:2000}... [truncated]}"
        fi
    fi
fi

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
    echo "=== System Prompt ==="
    echo "$system_prompt"
    echo ""
    echo "=== User Message (first 500 chars) ==="
    echo "${user_message:0:500}..."
    exit 0
fi

# ===========================================================================
# API Call (with retry)
# ===========================================================================

# Check API key (after dry-run exit so dry-run doesn't need credentials)
if [[ -z "$ANTHROPIC_API_KEY" ]]; then
    echo "ERROR: ANTHROPIC_API_KEY not available (set env var or add to keychain as 'crumb/anthropic-api-key')" >&2
    cron_mark_alert
    cron_finish 1
fi

# Compute prompt hash for replay log tracking
prompt_hash=$(echo "${system_prompt}${user_message}" | shasum -a 256 | cut -c1-12)

echo "Calling Anthropic API ($API_MODEL)..."

payload=$(jq -n \
    --arg model "$API_MODEL" \
    --argjson max_tokens "$MAX_OUTPUT_TOKENS" \
    --arg system "$system_prompt" \
    --arg user_msg "$user_message" \
    '{model: $model, max_tokens: $max_tokens, system: $system, messages: [{role: "user", content: $user_msg}]}')

# Retry loop: 3 attempts with exponential backoff (2s, 5s)
response=""
api_success=false
backoff_delays=(0 2 5)

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
        --max-time 90 \
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
    attn_log_cycle "api_error" "" "" "$prompt_hash" "$API_MODEL" 0 0 "[]" "API call failed after $MAX_API_RETRIES attempts: ${api_error:-curl exit $curl_exit}"
    cron_mark_alert
    cron_finish 1
fi

# Extract text content
full_response=$(echo "$response" | jq -r '.content[0].text // empty')
if [[ -z "$full_response" || ${#full_response} -lt 200 ]]; then
    echo "ERROR: Insufficient output (${#full_response} chars)" >&2
    attn_log_cycle "api_error" "" "" "$prompt_hash" "$API_MODEL" 0 0 "[]" "Insufficient output: ${#full_response} chars"
    cron_mark_alert
    cron_finish 1
fi

# Extract token usage
input_tokens=$(echo "$response" | jq -r '.usage.input_tokens // 0')
output_tokens=$(echo "$response" | jq -r '.usage.output_tokens // 0')

echo "API response: ${#full_response} chars, ${input_tokens} in / ${output_tokens} out"

# ===========================================================================
# Post-Processing: Split Artifact + Sidecar JSON
# ===========================================================================

parse_warnings="[]"
cycle_status="ok"

# Extract the JSON block from the end of the response
sidecar_json=$(echo "$full_response" | sed -n '/^```json$/,/^```$/p' | sed '1d;$d')

# Separate the markdown artifact (everything before the JSON block)
artifact_content=$(echo "$full_response" | sed '/^```json$/,$d')
# Strip leading/trailing blank lines and any stray code fences
artifact_content=$(echo "$artifact_content" | sed '1{/^```/d;}' | sed '/./,$!d')
# Trim trailing blank lines (macOS sed compatible)
while [[ "$artifact_content" == *$'\n' ]]; do
    artifact_content="${artifact_content%$'\n'}"
done

# ===========================================================================
# Write Artifact (always — not gated on JSON parse success)
# ===========================================================================

mkdir -p "$DAILY_DIR"
# Atomic write: temp file then mv
tmp_artifact=$(mktemp "${DAILY_DIR}/.tmp.XXXXXX")
echo "$artifact_content" > "$tmp_artifact"
mv "$tmp_artifact" "$OUTPUT_FILE"
chmod 644 "$OUTPUT_FILE"
echo "Artifact written: $OUTPUT_FILE"

# ===========================================================================
# Validate + Write Sidecar JSON
# ===========================================================================

sidecar_valid=false

if [[ -z "$sidecar_json" ]]; then
    echo "WARNING: No JSON block found in response" >&2
    parse_warnings=$(echo "$parse_warnings" | jq -c '. + ["No JSON block found in response"]')
    cycle_status="parse_error"
else
    # Validate JSON syntax
    if echo "$sidecar_json" | jq -e '.' > /dev/null 2>&1; then
        # Validate each item has required keys
        validated_items="[]"
        item_count=$(echo "$sidecar_json" | jq 'length')
        valid_count=0

        for i in $(seq 0 $((item_count - 1))); do
            item=$(echo "$sidecar_json" | jq -c ".[$i]")
            has_keys=$(echo "$item" | jq 'has("object_id") and has("source_path") and has("domain") and has("title") and has("action_class") and has("urgency")')

            if [[ "$has_keys" == "true" ]]; then
                validated_items=$(echo "$validated_items" | jq -c --argjson item "$item" '. + [$item]')
                valid_count=$((valid_count + 1))
            else
                missing=$(echo "$item" | jq -r '[("object_id","source_path","domain","title","action_class","urgency") as $k | select(has($k) | not) | $k] | join(", ")')
                warning="Item $i missing keys: $missing"
                echo "WARNING: $warning" >&2
                parse_warnings=$(echo "$parse_warnings" | jq -c --arg w "$warning" '. + [$w]')
            fi
        done

        echo "Sidecar: $valid_count/$item_count items validated"

        if [[ "$valid_count" -gt 0 ]]; then
            sidecar_valid=true
        else
            cycle_status="parse_error"
        fi
    else
        echo "WARNING: JSON block failed jq validation" >&2
        parse_warnings=$(echo "$parse_warnings" | jq -c '. + ["JSON block failed jq validation"]')
        cycle_status="parse_error"
    fi
fi

# Quarantine on parse failure
if [[ "$cycle_status" == "parse_error" ]]; then
    mkdir -p "$ATTN_QUARANTINE_DIR"
    echo "$full_response" > "$ATTN_QUARANTINE_DIR/${TODAY}-raw.txt"
    echo "Quarantined: $ATTN_QUARANTINE_DIR/${TODAY}-raw.txt"
fi

# ===========================================================================
# Post-Processing: Dedup Within Cycle (AO-003)
# ===========================================================================

if [[ "$sidecar_valid" == "true" && "$valid_count" -gt 1 ]]; then
    dedup_count=0
    deduped_items="[]"
    seen_oids=""

    for i in $(seq 0 $((valid_count - 1))); do
        item=$(echo "$validated_items" | jq -c ".[$i]")
        raw_sp=$(echo "$item" | jq -r '.source_path // empty')
        raw_domain=$(echo "$item" | jq -r '.domain // empty')
        raw_title=$(echo "$item" | jq -r '.title // empty')

        norm_sp=""
        [[ -n "$raw_sp" ]] && norm_sp=$(attn_normalize_path "$raw_sp")
        oid=$(attn_make_object_id "$norm_sp" "$raw_domain" "$raw_title")
        oid=$(attn_resolve_id "$oid")

        if echo "$seen_oids" | grep -qxF "$oid"; then
            dedup_count=$((dedup_count + 1))
            parse_warnings=$(echo "$parse_warnings" | jq -c --arg w "dedup_event: dropped duplicate '$oid' (index $i)" '. + [$w]')
        else
            seen_oids="${seen_oids}
${oid}"
            deduped_items=$(echo "$deduped_items" | jq -c --argjson item "$item" '. + [$item]')
        fi
    done

    if [[ "$dedup_count" -gt 0 ]]; then
        validated_items="$deduped_items"
        valid_count=$(echo "$validated_items" | jq 'length')
        echo "Dedup: removed $dedup_count duplicates, $valid_count items remaining"
    fi
fi

# ===========================================================================
# Write Sidecar JSON (after dedup)
# ===========================================================================

if [[ "$sidecar_valid" == "true" ]]; then
    mkdir -p "$SIDECAR_DIR"
    tmp_sidecar=$(mktemp "${SIDECAR_DIR}/.tmp.XXXXXX")
    echo "$validated_items" | jq '.' > "$tmp_sidecar"
    mv "$tmp_sidecar" "$SIDECAR_FILE"
    chmod 644 "$SIDECAR_FILE"
    echo "Sidecar written: $SIDECAR_FILE"
fi

# ===========================================================================
# Log to Replay Database
# ===========================================================================

sidecar_path_for_db=""
if [[ "$sidecar_valid" == "true" ]]; then
    sidecar_path_for_db=$(attn_normalize_path "$SIDECAR_FILE")
fi

cycle_id=$(attn_log_cycle \
    "$cycle_status" \
    "$(attn_normalize_path "$OUTPUT_FILE")" \
    "$sidecar_path_for_db" \
    "$prompt_hash" \
    "$API_MODEL" \
    "$input_tokens" \
    "$output_tokens" \
    "$parse_warnings")

echo "Logged cycle: $cycle_id (status: $cycle_status)"

# Log individual items to SQLite
if [[ "$sidecar_valid" == "true" ]]; then
    items_logged=0
    for i in $(seq 0 $((valid_count - 1))); do
        item=$(echo "$validated_items" | jq -c ".[$i]")

        raw_object_id=$(echo "$item" | jq -r '.object_id // empty')
        raw_source_path=$(echo "$item" | jq -r '.source_path // empty')
        raw_domain=$(echo "$item" | jq -r '.domain // empty')
        raw_title=$(echo "$item" | jq -r '.title // empty')
        raw_action_class=$(echo "$item" | jq -r '.action_class // empty')
        raw_urgency=$(echo "$item" | jq -r '.urgency // empty')

        # Normalize paths
        if [[ -n "$raw_source_path" ]]; then
            norm_source=$(attn_normalize_path "$raw_source_path")
        else
            norm_source=""
        fi

        # Generate object_id
        object_id=$(attn_make_object_id "$norm_source" "$raw_domain" "$raw_title")

        item_id=$(attn_log_item "$cycle_id" "$object_id" "$norm_source" "$raw_domain" "$raw_title" "$raw_action_class" "$raw_urgency" "$item")

        if [[ -n "$item_id" ]]; then
            items_logged=$((items_logged + 1))
        fi
    done
    echo "Items logged: $items_logged/$valid_count"
fi

# Add truncation note to warnings if applicable
if [[ -n "$truncation_note" ]]; then
    _attn_append_warning "$cycle_id" "$truncation_note"
fi

# ===========================================================================
# Metrics
# ===========================================================================

# Opus pricing: $15/Mtok input, $75/Mtok output
cost_estimate=$(awk "BEGIN {printf \"%.4f\", ($input_tokens * 15 + $output_tokens * 75) / 1000000}")
cron_set_tokens "$input_tokens" "$output_tokens"
cron_set_cost "$cost_estimate"

echo "Done. Cost: ~\$${cost_estimate}"
cron_finish 0
