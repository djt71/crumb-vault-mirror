#!/usr/bin/env bash
# overnight-research.sh — Nightly autonomous research sessions
#
# Source: tess-operations TOP-046
# Design: Projects/tess-operations/design/overnight-research-design.md
#
# Three streams by cadence:
#   - Reactive (any night, priority): FIF research queue + manual filesystem requests
#   - Competitive/Account (Sunday): last30days + FIF digests + vault context
#   - Builder Ecosystem (Wednesday): last30days + FIF digests + vault projects
#
# Execution model (Option A): script orchestrates data gathering, then launches
# a single Tess/Sonnet session for synthesis. Tess does NOT orchestrate.
#
# Usage (manual):
#   bash overnight-research.sh [--dry-run] [--stream reactive|competitive|builder]
#
# Cron: 11 PM ET nightly via LaunchAgent

source "/Users/tess/crumb-vault/_openclaw/scripts/cron-lib.sh"

# === Constants ===
FIF_DB="$HOME/openclaw/feed-intel-framework/state/pipeline.db"
RESEARCH_DIR="$BRIDGE_DIR/research"
RESEARCH_OUTPUT_DIR="$RESEARCH_DIR/output"
PROCESSED_DIR="$RESEARCH_DIR/.processed"
LAST30DAYS_ENGINE="/Users/openclaw/.claude/skills/last30days/scripts/last30days.py"
DOSSIER_DIR="$VAULT_ROOT/Domains/Career/accounts"
SIGNAL_NOTES_DIR="$VAULT_ROOT/Sources/signals"
VAULT_RESEARCH_DIR="$VAULT_ROOT/Sources/research"
TODAY=$(date +%Y-%m-%d)
DAY_OF_WEEK=$(date +%A)  # Monday, Tuesday, etc.

# Telegram — direct curl delivery (same pattern as vault-health, awareness-check)
TELEGRAM_BOT_TOKEN="${TESS_AWARENESS_BOT_TOKEN:-$(security find-generic-password -a tess-bot -s tess-awareness-bot-token -w 2>/dev/null || echo "")}"
TELEGRAM_CHAT_ID="7754252365"

# === Argument parsing ===
DRY_RUN=false
FORCE_STREAM=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --stream) FORCE_STREAM="$2"; shift 2 ;;
        *) echo "ERROR: Unknown flag: $1" >&2; exit 1 ;;
    esac
done

# === Init cron infrastructure ===
# Skip cron_init in dry-run mode (no lock, no jitter, no wall time)
if [[ "$DRY_RUN" == "false" ]]; then
    cron_init "overnight-research" --wall-time 600 --jitter 300
fi

# === Ensure directories ===
mkdir -p "$RESEARCH_OUTPUT_DIR" "$PROCESSED_DIR"

# ===========================================================================
# Stream Selection
# ===========================================================================

STREAM=""
REACTIVE_SOURCE=""     # "filesystem" or "fif" — tracks where reactive item came from
REACTIVE_FILE=""       # filesystem path for manual requests
REACTIVE_CANONICAL=""  # canonical_id for FIF items

_check_reactive_queues() {
    # Check filesystem research requests
    local fs_request
    fs_request=$(find "$RESEARCH_DIR" -maxdepth 1 -name "*.md" -not -name ".*" 2>/dev/null | head -1)
    if [[ -n "$fs_request" ]]; then
        if grep -q "^type: research-request" "$fs_request" 2>/dev/null; then
            REACTIVE_SOURCE="filesystem"
            REACTIVE_FILE="$fs_request"
            return 0
        fi
    fi

    # Check FIF research queue (dashboard_actions where action='research')
    # MC-068 adds the 'research' action type. Until then, this query returns nothing.
    if [[ -f "$FIF_DB" ]]; then
        local fif_item
        fif_item=$(sqlite3 "$FIF_DB" "SELECT da.canonical_id FROM dashboard_actions da WHERE da.action = 'research' AND da.consumed_at IS NULL ORDER BY da.created_at ASC LIMIT 1;" 2>/dev/null || echo "")
        if [[ -n "$fif_item" ]]; then
            REACTIVE_SOURCE="fif"
            REACTIVE_CANONICAL="$fif_item"
            return 0
        fi
    fi

    return 1
}

select_stream() {
    # Always check reactive queues (needed even for forced reactive)
    _check_reactive_queues || true

    # Force override
    if [[ -n "$FORCE_STREAM" ]]; then
        STREAM="$FORCE_STREAM"
        echo "Stream forced: $STREAM"
        return 0
    fi

    # Priority 1: Reactive (filesystem or FIF)
    if [[ -n "$REACTIVE_SOURCE" ]]; then
        STREAM="reactive"
        if [[ "$REACTIVE_SOURCE" == "filesystem" ]]; then
            echo "Stream: reactive (filesystem request: $(basename "$REACTIVE_FILE"))"
        else
            echo "Stream: reactive (FIF research queue: $REACTIVE_CANONICAL)"
        fi
        return 0
    fi

    # Priority 2: Scheduled streams (day-of-week rotation)
    case "$DAY_OF_WEEK" in
        Sunday)    STREAM="competitive"; echo "Stream: competitive (Sunday rotation)" ;;
        Wednesday) STREAM="builder";     echo "Stream: builder (Wednesday rotation)" ;;
        *)
            echo "No stream selected: no reactive items, not a scheduled day ($DAY_OF_WEEK)."
            return 1
            ;;
    esac
    return 0
}

# ===========================================================================
# Data Gathering — per stream
# ===========================================================================

CONTEXT_FILE="/tmp/overnight-research-context-${TODAY}.md"
GATHERED_SECTIONS=0

gather_reactive() {
    {
        echo "# Research Context — Reactive"
        echo ""

        if [[ "$REACTIVE_SOURCE" == "filesystem" ]]; then
            echo "## Research Request"
            echo ""
            cat "$REACTIVE_FILE"
            echo ""
            GATHERED_SECTIONS=$((GATHERED_SECTIONS + 1))

            # Extract topic from frontmatter for FIF cross-reference
            local topic
            topic=$(grep "^topic:" "$REACTIVE_FILE" | head -1 | sed 's/^topic: *//' | tr -d '"')
            if [[ -n "$topic" ]]; then
                gather_fif_digest_matches "$topic"
                gather_signal_notes "$topic"
            fi

        elif [[ "$REACTIVE_SOURCE" == "fif" ]]; then
            echo "## FIF Item"
            echo ""
            # Get source type to determine extraction strategy
            local source_type
            source_type=$(sqlite3 "$FIF_DB" "SELECT source_type FROM posts WHERE canonical_id = '$REACTIVE_CANONICAL';" 2>/dev/null || echo "")

            if [[ "$source_type" == "x" ]]; then
                # X/Twitter: extract full_text (not fetchable live)
                local full_text
                full_text=$(sqlite3 "$FIF_DB" "SELECT json_extract(content_json, '$.full_text') FROM posts WHERE canonical_id = '$REACTIVE_CANONICAL';" 2>/dev/null || echo "")
                local excerpt
                excerpt=$(sqlite3 "$FIF_DB" "SELECT json_extract(content_json, '$.excerpt') FROM posts WHERE canonical_id = '$REACTIVE_CANONICAL';" 2>/dev/null || echo "")
                local author_name
                author_name=$(sqlite3 "$FIF_DB" "SELECT json_extract(author_json, '$.name') FROM posts WHERE canonical_id = '$REACTIVE_CANONICAL';" 2>/dev/null || echo "")

                echo "Source: X/Twitter (content below is authoritative — URL is not fetchable)"
                echo "Author: $author_name"
                echo "ID: $REACTIVE_CANONICAL"
                echo ""
                if [[ -n "$full_text" && "$full_text" != "null" ]]; then
                    echo "### Full Post Text"
                    echo "$full_text"
                elif [[ -n "$excerpt" && "$excerpt" != "null" ]]; then
                    echo "### Post Text (excerpt)"
                    echo "$excerpt"
                else
                    echo "(No post text captured at ingestion)"
                fi
                GATHERED_SECTIONS=$((GATHERED_SECTIONS + 1))
            else
                # Non-X sources: standard extraction
                local post_data
                post_data=$(sqlite3 "$FIF_DB" "SELECT canonical_id, source_type, json_extract(content_json, '$.title') as title, json_extract(content_json, '$.text') as text, url_hash FROM posts WHERE canonical_id = '$REACTIVE_CANONICAL';" 2>/dev/null || echo "")
                if [[ -n "$post_data" ]]; then
                    echo "$post_data"
                    GATHERED_SECTIONS=$((GATHERED_SECTIONS + 1))
                fi
            fi

            # Get any source URLs
            local source_urls
            source_urls=$(sqlite3 "$FIF_DB" "SELECT json_extract(source_instances, '$[0].url') FROM posts WHERE canonical_id = '$REACTIVE_CANONICAL';" 2>/dev/null || echo "")
            if [[ -n "$source_urls" ]]; then
                echo ""
                echo "Source URL: $source_urls"
            fi

            # Get metadata (matched topics, engagement)
            local metadata
            metadata=$(sqlite3 "$FIF_DB" "SELECT metadata_json FROM posts WHERE canonical_id = '$REACTIVE_CANONICAL';" 2>/dev/null || echo "")
            if [[ -n "$metadata" ]]; then
                echo ""
                echo "Metadata: $metadata"
            fi
            echo ""
        fi
    } > "$CONTEXT_FILE"
}

gather_competitive() {
    {
        echo "# Research Context — Competitive/Account Intelligence"
        echo "Date: $TODAY"
        echo ""

        # FIF items from last 7 days (DB-direct — no dependency on digest file writes)
        echo "## Recent FIF Signal (7 days, HIGH + MEDIUM)"
        echo ""
        if [[ -f "$FIF_DB" ]]; then
            local fif_items
            fif_items=$(sqlite3 "$FIF_DB" "
                SELECT
                    json_extract(triage_json, '\$.priority') as priority,
                    source_type,
                    json_extract(content_json, '\$.title') as title,
                    json_extract(triage_json, '\$.why_now') as why_now,
                    json_extract(triage_json, '\$.tags') as tags
                FROM posts
                WHERE queue_status='triaged'
                  AND json_extract(triage_json, '\$.priority') IN ('high', 'medium')
                  AND triaged_at >= datetime('now', '-7 days')
                ORDER BY triaged_at DESC
                LIMIT 20;
            " 2>/dev/null || echo "")
            if [[ -n "$fif_items" ]]; then
                echo "$fif_items" | while IFS='|' read -r priority stype title why tags; do
                    echo "- **[$priority/$stype]** ${title:-[untitled]}: $why"
                done
                GATHERED_SECTIONS=$((GATHERED_SECTIONS + 1))
            else
                echo "No HIGH/MEDIUM items in last 7 days."
            fi
        else
            echo "FIF database not found."
        fi
        echo ""
        echo "---"
        echo ""

        # Vault dossiers
        echo "## Account Dossiers"
        echo ""
        local dossier_count=0
        if [[ -d "$DOSSIER_DIR" ]]; then
            while IFS= read -r dossier; do
                [[ -z "$dossier" ]] && continue
                local account_name
                account_name=$(basename "$(dirname "$dossier")")
                echo "### $account_name"
                head -40 "$dossier" 2>/dev/null || true
                echo ""
                dossier_count=$((dossier_count + 1))
            done < <(find "$DOSSIER_DIR" -name "dossier.md" 2>/dev/null | head -10)
            if [[ $dossier_count -gt 0 ]]; then
                GATHERED_SECTIONS=$((GATHERED_SECTIONS + 1))
            else
                echo "No dossiers found."
            fi
        else
            echo "No accounts directory found."
        fi
        echo ""
        echo "---"
        echo ""

        # Signal notes (last 30 days)
        echo "## Recent Signal Notes"
        echo ""
        if [[ -d "$SIGNAL_NOTES_DIR" ]]; then
            local signal_count=0
            while IFS= read -r note; do
                [[ -z "$note" ]] && continue
                echo "- $(basename "$note")"
                signal_count=$((signal_count + 1))
            done < <(find "$SIGNAL_NOTES_DIR" -name "*.md" -mtime -30 2>/dev/null | head -10)
            if [[ $signal_count -gt 0 ]]; then
                GATHERED_SECTIONS=$((GATHERED_SECTIONS + 1))
            else
                echo "No signal notes in last 30 days."
            fi
        else
            echo "No signal-notes directory."
        fi
        echo ""
        echo "---"
        echo ""

        # last30days competitive intelligence
        echo "## External Signal (last30days)"
        echo ""
        gather_last30days "BlueCat Networks EfficientIP Infoblox DDI DNS security IPAM network automation" "competitive" "--search web"
    } > "$CONTEXT_FILE"
}

gather_builder() {
    {
        echo "# Research Context — Builder Ecosystem Intelligence"
        echo "Date: $TODAY"
        echo ""

        # FIF items from last 7 days (DB-direct)
        echo "## Recent FIF Signal (7 days, HIGH + MEDIUM)"
        echo ""
        if [[ -f "$FIF_DB" ]]; then
            local fif_items
            fif_items=$(sqlite3 "$FIF_DB" "
                SELECT
                    json_extract(triage_json, '\$.priority') as priority,
                    source_type,
                    json_extract(content_json, '\$.title') as title,
                    json_extract(triage_json, '\$.why_now') as why_now,
                    json_extract(triage_json, '\$.tags') as tags
                FROM posts
                WHERE queue_status='triaged'
                  AND json_extract(triage_json, '\$.priority') IN ('high', 'medium')
                  AND triaged_at >= datetime('now', '-7 days')
                ORDER BY triaged_at DESC
                LIMIT 20;
            " 2>/dev/null || echo "")
            if [[ -n "$fif_items" ]]; then
                echo "$fif_items" | while IFS='|' read -r priority stype title why tags; do
                    echo "- **[$priority/$stype]** ${title:-[untitled]}: $why"
                done
                GATHERED_SECTIONS=$((GATHERED_SECTIONS + 1))
            else
                echo "No HIGH/MEDIUM items in last 7 days."
            fi
        else
            echo "FIF database not found."
        fi
        echo ""
        echo "---"
        echo ""

        # Active project state
        echo "## Active Projects"
        echo ""
        local proj_count=0
        while IFS= read -r pstate; do
            [[ -z "$pstate" ]] && continue
            local proj_name
            proj_name=$(grep "^name:" "$pstate" | head -1 | sed 's/^name: *//')
            local phase
            phase=$(grep "^phase:" "$pstate" | head -1 | awk '{print $2}')
            local next_action
            next_action=$(grep "^next_action:" "$pstate" | head -1 | sed 's/^next_action: *//')
            if [[ "$phase" != "DONE" && "$phase" != "ARCHIVED" ]]; then
                echo "- **$proj_name** ($phase): $next_action"
                proj_count=$((proj_count + 1))
            fi
        done < <(find "$VAULT_ROOT/Projects" -name "project-state.yaml" -not -path "*/Archived/*" 2>/dev/null)
        if [[ $proj_count -gt 0 ]]; then
            GATHERED_SECTIONS=$((GATHERED_SECTIONS + 1))
        fi
        echo ""
        echo "---"
        echo ""

        # last30days builder ecosystem
        echo "## External Signal (last30days)"
        echo ""
        gather_last30days "Claude Code MCP servers local LLM inference OpenClaw Obsidian plugins AI agents" "builder" "--search web,hn,reddit"
    } > "$CONTEXT_FILE"
}

# ===========================================================================
# Shared data-gathering helpers
# ===========================================================================

gather_last30days() {
    local query="$1"
    local label="$2"
    local extra_flags="${3:-}"

    if [[ ! -f "$LAST30DAYS_ENGINE" ]]; then
        echo "last30days engine not available."
        return 0
    fi

    local output_file="/tmp/overnight-research-last30days-${label}-${TODAY}.txt"

    # Build command args — extra_flags allows per-stream source selection
    local cmd_args="$query --emit context"
    if [[ -n "$extra_flags" ]]; then
        cmd_args="$query --emit context $extra_flags"
    else
        cmd_args="$query --emit context --include-web"
    fi

    # Run as openclaw user (API keys are 600 owner-only)
    # macOS has no `timeout` — use perl alarm. 300s budget for data gathering.
    if perl -e 'alarm shift; exec @ARGV' 300 \
        sudo -u openclaw env HOME=/Users/openclaw \
        python3 "$LAST30DAYS_ENGINE" $cmd_args \
        > "$output_file" 2>/dev/null; then

        local output_size
        output_size=$(wc -c < "$output_file" | tr -d ' ')
        if [[ "$output_size" -gt 100 ]]; then
            cat "$output_file"
            GATHERED_SECTIONS=$((GATHERED_SECTIONS + 1))
            echo "  last30days: ${output_size} bytes ($label)" >&2
        else
            echo "No meaningful signal from last30days for $label."
        fi
    else
        echo "last30days failed or timed out for $label query."
    fi
}

gather_fif_digest_matches() {
    local topic="$1"
    echo "## FIF Matches for '$topic'"
    echo ""
    if [[ -f "$FIF_DB" ]]; then
        local fif_matches
        fif_matches=$(sqlite3 "$FIF_DB" "
            SELECT
                json_extract(triage_json, '\$.priority') as priority,
                source_type,
                json_extract(content_json, '\$.title') as title,
                json_extract(triage_json, '\$.why_now') as why_now
            FROM posts
            WHERE queue_status='triaged'
              AND json_extract(triage_json, '\$.priority') IN ('high', 'medium')
              AND triaged_at >= datetime('now', '-7 days')
              AND (
                json_extract(content_json, '\$.title') LIKE '%${topic}%'
                OR json_extract(triage_json, '\$.why_now') LIKE '%${topic}%'
                OR json_extract(triage_json, '\$.tags') LIKE '%${topic}%'
              )
            ORDER BY triaged_at DESC
            LIMIT 10;
        " 2>/dev/null || echo "")
        if [[ -n "$fif_matches" ]]; then
            echo "$fif_matches" | while IFS='|' read -r priority stype title why; do
                echo "- **[$priority/$stype]** ${title:-[untitled]}: $why"
            done
            GATHERED_SECTIONS=$((GATHERED_SECTIONS + 1))
        else
            echo "No FIF matches for '$topic'."
        fi
    fi
    echo ""
}

gather_signal_notes() {
    local topic="$1"
    if [[ -d "$SIGNAL_NOTES_DIR" ]]; then
        local matches
        matches=$(find "$SIGNAL_NOTES_DIR" -name "*.md" -mtime -30 2>/dev/null | xargs grep -li "$topic" 2>/dev/null | head -3)
        if [[ -n "$matches" ]]; then
            echo "## Related Signal Notes"
            echo ""
            while IFS= read -r note; do
                echo "- [[$(basename "$note" .md)]]"
            done <<< "$matches"
            echo ""
            GATHERED_SECTIONS=$((GATHERED_SECTIONS + 1))
        fi
    fi
}

# ===========================================================================
# Prompt Templates — per stream
# ===========================================================================

build_prompt() {
    local prompt_file="/tmp/overnight-research-prompt-${TODAY}.md"

    case "$STREAM" in
        reactive)
            cat > "$prompt_file" << 'ENDPROMPT'
You are conducting a focused investigation on a specific topic flagged for research.

Your job is SYNTHESIS and INVESTIGATION — not signal collection. The data below
was gathered by automated tools. Your unique value is:
- Following links and reading source material in depth (use browser)
- Cross-referencing with vault knowledge
- Assessing significance and confidence
- Writing a structured brief with source attribution

Convergence rules:
- 5 sources max per topic. Stop searching, start synthesizing.
- 3 clicks max per source (prevent rabbit holes)
- If you find contradictory information, note it — don't resolve it without evidence
- If this topic needs deeper investigation than a single session can provide,
  mark it for escalation to Crumb's researcher skill

ENDPROMPT
            ;;
        competitive)
            cat > "$prompt_file" << 'ENDPROMPT'
You are conducting a weekly competitive/account intelligence rotation.

Review the FIF digests, last30days signal, and vault context below. Your job is
to synthesize — not re-scan sources FIF already monitors (X feeds, RSS).

Cover 2-3 topics from this data. Focus on:
- Competitor product launches, partnerships, hiring signals
- Account technology investments, vendor changes, org moves
- Industry trends that affect Danny's SE practice

Convergence rules:
- 5 sources per topic, 3 clicks max per source
- 2-3 topics per session (not exhaustive — these accumulate weekly)
- If a signal has strategic implications beyond operational scope, flag for
  Crumb escalation

ENDPROMPT
            ;;
        builder)
            cat > "$prompt_file" << 'ENDPROMPT'
You are conducting a weekly builder ecosystem intelligence rotation.

Review the FIF digests, project state, and last30days signal below. Your job is
to connect external developments to Danny's active projects and tools.

Cover 2-3 topics from this data. Focus on:
- New capabilities in tools Danny uses (Claude Code, OpenClaw, Obsidian, MCP)
- Emerging patterns in AI agent development
- Open-source projects or techniques relevant to active projects
- Community discussions about problems Danny's projects solve

Convergence rules:
- 5 sources per topic, 3 clicks max per source
- 2-3 topics per session (not exhaustive — these accumulate weekly)
- If a finding has architectural implications for an active project, flag it

ENDPROMPT
            ;;
    esac

    # Append common output format instructions
    cat >> "$prompt_file" << 'ENDFORMAT'

Output format — write a research brief with these exact sections:

## Summary
2-3 sentence executive summary.

## Key Findings
- Finding with source attribution (URL or vault reference)
- Finding with source attribution
- (up to 5 findings)

## Sources
1. [URL or vault reference] — relevance note
2. [URL or vault reference] — relevance note

## Vault Connections
Wikilinks to relevant vault notes — dossiers, signal-notes, project docs.

## Assessment
Your judgment: significance, confidence level, recommended action.

## Escalation Note (if applicable)
Why this needs Crumb's researcher skill — too broad, contradictory sources,
strategic implications, etc. Only include if escalation is warranted.

Rules:
- Max 3000 tokens output
- Do NOT hallucinate information not in the context or your browser research
- Attribute all intelligence to its source
- Use path-based wikilinks for project references (e.g., [[Projects/project-name/design/specification|project-name]])
- "Crumb" is the system, NOT a project. There is no Projects/Crumb/ directory. Valid projects: agent-to-agent-communication, tess-operations, feed-intel-framework, mission-control, opportunity-scout, customer-intelligence, etc.
- X/Twitter URLs cannot be fetched live — use the post text from the provided context. Do not attempt to retrieve X content via browser.
- Output ONLY the brief — no commentary, no meta-text

---

ENDFORMAT

    # Append gathered context
    cat "$CONTEXT_FILE" >> "$prompt_file"

    echo "$prompt_file"
}

# ===========================================================================
# Post-processing
# ===========================================================================

write_research_brief() {
    local agent_output_file="$1"
    local output_file=""

    # All streams stage to output/ for operator review before vault entry
    mkdir -p "$RESEARCH_OUTPUT_DIR"

    # Generate filename slug
    local slug=""
    if [[ "$STREAM" == "reactive" ]]; then
        if [[ "$REACTIVE_SOURCE" == "fif" && -n "$REACTIVE_CANONICAL" ]]; then
            local title
            title=$(sqlite3 "$FIF_DB" "SELECT json_extract(content_json, '$.title') FROM posts WHERE canonical_id = '$REACTIVE_CANONICAL';" 2>/dev/null || echo "")
            if [[ -n "$title" ]]; then
                slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//' | cut -c1-60)
            fi
        elif [[ "$REACTIVE_SOURCE" == "filesystem" && -n "$REACTIVE_FILE" ]]; then
            local topic
            topic=$(grep "^topic:" "$REACTIVE_FILE" | head -1 | sed 's/^topic: *//' | tr -d '"')
            if [[ -n "$topic" ]]; then
                slug=$(echo "$topic" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//' | cut -c1-60)
            fi
        fi
    fi
    [[ -z "$slug" ]] && slug="research-brief-${TODAY}-${STREAM}"

    output_file="$RESEARCH_OUTPUT_DIR/${slug}.md"

    {
        echo "---"
        echo "type: research-brief"
        echo "stream: $STREAM"
        echo "status: pending-review"
        echo "created: $TODAY"
        echo "updated: $TODAY"
        echo "skill_origin: tess-overnight-research"
        if [[ "$REACTIVE_SOURCE" == "fif" && -n "$REACTIVE_CANONICAL" ]]; then
            echo "fif_canonical_id: \"$REACTIVE_CANONICAL\""
        fi
        echo "---"
        echo ""
        cat "$agent_output_file"
    } > "$output_file"

    echo "$output_file"
}

mark_consumed() {
    if [[ "$STREAM" == "reactive" ]]; then
        if [[ "$REACTIVE_SOURCE" == "filesystem" && -n "$REACTIVE_FILE" ]]; then
            mv "$REACTIVE_FILE" "$PROCESSED_DIR/"
            echo "Moved $(basename "$REACTIVE_FILE") to .processed/"
        elif [[ "$REACTIVE_SOURCE" == "fif" && -n "$REACTIVE_CANONICAL" ]]; then
            sqlite3 "$FIF_DB" "UPDATE dashboard_actions SET consumed_at = datetime('now') WHERE canonical_id = '$REACTIVE_CANONICAL' AND consumed_at IS NULL;" 2>/dev/null
            echo "Marked FIF item $REACTIVE_CANONICAL as consumed"
        fi
    fi
}

send_notification() {
    local brief_path="$1"
    local brief_name
    brief_name=$(basename "$brief_path")

    if [[ -z "$TELEGRAM_BOT_TOKEN" ]]; then
        echo "No Telegram token — skipping notification." >&2
        return 0
    fi

    local text="Overnight research complete ($STREAM stream).
Brief: $brief_name"

    curl -s -o /dev/null -w "" \
        --connect-timeout 10 \
        --max-time 15 \
        -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        --data-urlencode text="$text" \
        2>/dev/null || true
}

# ===========================================================================
# Main
# ===========================================================================

TOTAL_INPUT_TOKENS=0
TOTAL_OUTPUT_TOKENS=0
ITEMS_PROCESSED=0
ITEMS_FAILED=0

echo "=== Overnight Research — $TODAY ($DAY_OF_WEEK) ==="

# 1. Select stream
if ! select_stream; then
    echo "Nothing to do tonight."
    if [[ "$DRY_RUN" == "false" ]]; then
        cron_set_cost "0.00"
        cron_finish 0
    fi
    exit 0
fi

# Per-item pipeline: gather → prompt → agent → write → consume → notify
run_single_item() {
    local item_label="$1"
    GATHERED_SECTIONS=0

    echo ""
    echo "--- Processing: $item_label ---"

    # Gather data
    case "$STREAM" in
        reactive)    gather_reactive ;;
        competitive) gather_competitive ;;
        builder)     gather_builder ;;
    esac

    local context_bytes
    context_bytes=$(wc -c < "$CONTEXT_FILE" | tr -d ' ')
    echo "Context assembled: ${context_bytes} bytes, ${GATHERED_SECTIONS} sections with data"

    if [[ "$GATHERED_SECTIONS" -eq 0 ]]; then
        echo "No useful data gathered — skipping."
        return 0
    fi

    # Build prompt
    local prompt_file
    prompt_file=$(build_prompt)
    local prompt_bytes
    prompt_bytes=$(wc -c < "$prompt_file" | tr -d ' ')
    echo "Prompt: ${prompt_bytes} bytes"

    local estimated_tokens=$((prompt_bytes / 4))
    if [[ "$estimated_tokens" -gt 45000 ]]; then
        echo "WARNING: Estimated ${estimated_tokens} tokens — approaching 50k ceiling." >&2
    fi

    # Dry-run: show context and skip agent
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "DRY RUN — skipping agent launch."
        echo "Review context: cat $CONTEXT_FILE"
        echo "Review prompt:  cat $prompt_file"
        return 0
    fi

    # Launch Tess session
    echo "Launching Tess synthesis session (Sonnet 4.6)..."
    local agent_output="/tmp/overnight-research-agent-${TODAY}-${ITEMS_PROCESSED}.txt"

    cd /tmp
    sudo -u openclaw env HOME=/Users/openclaw \
        /Users/openclaw/.local/bin/openclaw agent \
        --agent voice \
        -m "$(cat "$prompt_file")" \
        --timeout 300 \
        > "$agent_output" 2>/dev/null

    local agent_exit=$?
    if [[ "$agent_exit" -ne 0 ]]; then
        echo "ERROR: Agent exited with code $agent_exit" >&2
        ITEMS_FAILED=$((ITEMS_FAILED + 1))
        return 1
    fi

    local agent_bytes
    agent_bytes=$(wc -c < "$agent_output" | tr -d ' ')
    if [[ "$agent_bytes" -lt 50 ]]; then
        echo "ERROR: Agent produced insufficient output (${agent_bytes} bytes)" >&2
        ITEMS_FAILED=$((ITEMS_FAILED + 1))
        return 1
    fi

    echo "Agent output: ${agent_bytes} bytes"

    # Write brief
    local brief_path
    brief_path=$(write_research_brief "$agent_output")
    echo "Brief: $brief_path"

    # Mark consumed
    mark_consumed

    # Notify
    send_notification "$brief_path"

    # Accumulate cost metrics
    local input_tokens=$((prompt_bytes / 4))
    local output_tokens=$((agent_bytes / 4))
    TOTAL_INPUT_TOKENS=$((TOTAL_INPUT_TOKENS + input_tokens))
    TOTAL_OUTPUT_TOKENS=$((TOTAL_OUTPUT_TOKENS + output_tokens))
    ITEMS_PROCESSED=$((ITEMS_PROCESSED + 1))
}

# 2. Run pipeline — loop for reactive, single pass for scheduled
if [[ "$STREAM" == "reactive" ]]; then
    # Process all filesystem requests
    while IFS= read -r req_file; do
        [[ -z "$req_file" ]] && continue
        REACTIVE_SOURCE="filesystem"
        REACTIVE_FILE="$req_file"
        REACTIVE_CANONICAL=""
        run_single_item "$(basename "$req_file")" || true
    done < <(find "$RESEARCH_DIR" -maxdepth 1 -name "*.md" -not -name ".*" 2>/dev/null | while IFS= read -r f; do
        grep -q "^type: research-request" "$f" 2>/dev/null && echo "$f"
    done)

    # Process all FIF dashboard-queued items
    if [[ -f "$FIF_DB" ]]; then
        while IFS= read -r canonical_id; do
            [[ -z "$canonical_id" ]] && continue
            REACTIVE_SOURCE="fif"
            REACTIVE_CANONICAL="$canonical_id"
            REACTIVE_FILE=""
            item_title=$(sqlite3 "$FIF_DB" "SELECT json_extract(content_json, '$.title') FROM posts WHERE canonical_id = '$canonical_id';" 2>/dev/null || echo "$canonical_id")
            run_single_item "${item_title:-$canonical_id}" || true
        done < <(sqlite3 "$FIF_DB" "SELECT canonical_id FROM dashboard_actions WHERE action = 'research' AND consumed_at IS NULL ORDER BY created_at ASC;" 2>/dev/null)
    fi
else
    # Scheduled streams: single pass
    run_single_item "$STREAM rotation"
fi

# 3. Final metrics
if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    echo "DRY RUN complete."
    exit 0
fi

if [[ "$ITEMS_PROCESSED" -eq 0 && "$ITEMS_FAILED" -eq 0 ]]; then
    echo "No items processed."
    if [[ "$DRY_RUN" == "false" ]]; then
        cron_set_cost "0.00"
        cron_finish 0
    fi
    exit 0
fi

# Rough cost estimate for Sonnet 4.6: ~$0.003/1k input + ~$0.015/1k output
cost_estimate=$(awk "BEGIN {printf \"%.4f\", ($TOTAL_INPUT_TOKENS * 0.003 + $TOTAL_OUTPUT_TOKENS * 0.015) / 1000}")
cron_set_tokens "$TOTAL_INPUT_TOKENS" "$TOTAL_OUTPUT_TOKENS"
cron_set_cost "$cost_estimate"

if [[ "$ITEMS_FAILED" -gt 0 ]]; then
    cron_mark_alert
fi

echo ""
echo "Done. Stream: $STREAM, items: $ITEMS_PROCESSED processed / $ITEMS_FAILED failed, cost: ~\$${cost_estimate}"
cron_finish "$( [[ "$ITEMS_FAILED" -gt 0 ]] && echo 1 || echo 0 )"
