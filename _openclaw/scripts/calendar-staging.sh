#!/usr/bin/env bash
# calendar-staging.sh — Calendar staging holds and approval-gated promotion to Primary
#
# Source: tess-operations TOP-036 (Calendar staging and approval-to-Primary promotion)
# Spec: tess-google-services-spec.md §3.3
#
# Three-calendar architecture:
#   Agent — Staging: holds, proposals (autopilot — no approval)
#   Agent — Followups: reminders, nudges (autopilot — no approval)
#   Dan — Primary: authoritative, external-facing (approval required for all mutations)
#
# Usage:
#   calendar-staging.sh create --summary "Q2 Planning" --start "2026-03-25T14:00:00" --end "2026-03-25T15:00:00" [--description "..."] [--location "..."]
#   calendar-staging.sh promote <event_id>           # Request approval to move staging → Primary
#   calendar-staging.sh execute <AID>                # Called by approval-executor after approval
#   calendar-staging.sh cleanup                      # Delete staging holds older than 48 hours
#   calendar-staging.sh list                         # List current staging holds
#
# Exit: 0 on success, 1 on error
# Output: For create, prints event_id on stdout. For promote, prints AID on stdout.

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_ROOT="/Users/tess/crumb-vault"
BRIDGE_DIR="$VAULT_ROOT/_openclaw"
LOG_FILE="$BRIDGE_DIR/logs/calendar-staging.log"
CALENDARS_CONFIG="$BRIDGE_DIR/config/google-calendars.json"

source "$BRIDGE_DIR/lib/gws-token.sh"

# Read calendar IDs from config
STAGING_CAL=$(jq -r '.staging' "$CALENDARS_CONFIG")
PRIMARY_CAL=$(jq -r '.primary' "$CALENDARS_CONFIG")

# Staging hold max age (hours)
STAGING_MAX_AGE_HOURS=48

# === Logging ===
log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") $1" >> "$LOG_FILE"
}

# === Subcommand routing ===
subcmd="${1:-}"
shift || true

case "$subcmd" in

# ─── CREATE ────────────────────────────────────────────────────────────────
create)
    SUMMARY=""
    START=""
    END=""
    DESCRIPTION=""
    LOCATION=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --summary|-s) SUMMARY="$2"; shift 2 ;;
            --start) START="$2"; shift 2 ;;
            --end) END="$2"; shift 2 ;;
            --description|-d) DESCRIPTION="$2"; shift 2 ;;
            --location|-l) LOCATION="$2"; shift 2 ;;
            *) echo "ERROR: Unknown flag: $1" >&2; exit 1 ;;
        esac
    done

    if [[ -z "$SUMMARY" || -z "$START" || -z "$END" ]]; then
        echo "Usage: calendar-staging.sh create --summary \"...\" --start \"YYYY-MM-DDTHH:MM:SS\" --end \"YYYY-MM-DDTHH:MM:SS\" [--description \"...\"] [--location \"...\"]" >&2
        exit 1
    fi

    # Build event JSON — dateTime format with timezone
    event_json=$(jq -n -c \
        --arg summary "$SUMMARY" \
        --arg description "$DESCRIPTION" \
        --arg location "$LOCATION" \
        --arg start "$START" \
        --arg end "$END" \
        '{
            summary: $summary,
            start: {dateTime: $start, timeZone: "America/New_York"},
            end: {dateTime: $end, timeZone: "America/New_York"},
            description: (if $description != "" then $description else null end),
            location: (if $location != "" then $location else null end),
            reminders: {useDefault: false}
        } | with_entries(select(.value != null))')

    log "CREATING: staging hold '$SUMMARY' ($START — $END)"

    response=$(gws_calendar_create_event "$event_json" "$STAGING_CAL") || {
        log "ERROR: Calendar API create failed"
        echo "ERROR: Calendar API create failed" >&2
        exit 1
    }

    event_id=$(echo "$response" | jq -r '.id // empty')
    if [[ -z "$event_id" ]]; then
        error=$(echo "$response" | jq -r '.error.message // "unknown error"')
        log "ERROR: create failed: $error"
        echo "ERROR: create failed: $error" >&2
        exit 1
    fi

    log "OK: created staging hold '$SUMMARY' (id: $event_id)"
    echo "$event_id"
    ;;

# ─── PROMOTE ──────────────────────────────────────────────────────────────
promote)
    EVENT_ID="${1:-}"
    if [[ -z "$EVENT_ID" ]]; then
        echo "Usage: calendar-staging.sh promote <event_id>" >&2
        exit 1
    fi

    # Fetch event details for the approval summary
    event_data=$(gws_calendar_get_event "$EVENT_ID" "$STAGING_CAL") || {
        log "ERROR: failed to fetch staging event $EVENT_ID"
        echo "ERROR: failed to fetch staging event" >&2
        exit 1
    }

    event_error=$(echo "$event_data" | jq -r '.error.message // empty')
    if [[ -n "$event_error" ]]; then
        log "ERROR: event fetch failed: $event_error"
        echo "ERROR: $event_error" >&2
        exit 1
    fi

    event_summary=$(echo "$event_data" | jq -r '.summary // "Untitled"')
    event_start=$(echo "$event_data" | jq -r '.start.dateTime // .start.date // "unknown"')
    event_end=$(echo "$event_data" | jq -r '.end.dateTime // .end.date // "unknown"')
    event_location=$(echo "$event_data" | jq -r '.location // empty')

    # Build human-readable summary
    summary="Promote '${event_summary}' to Primary calendar"
    preview="Start: ${event_start}\nEnd: ${event_end}"
    [[ -n "$event_location" ]] && preview+="\nLocation: ${event_location}"

    log "GATED: promote '$event_summary' ($EVENT_ID) — requesting approval"

    payload=$(jq -n -c \
        --arg command "cal-promote" \
        --arg event_id "$EVENT_ID" \
        '{command: $command, event_id: $event_id}')

    bash "$SCRIPT_DIR/approval-request.sh" \
        --action-type CAL_PROMOTE \
        --service google \
        --target "Agent — Staging → Primary" \
        --summary "$summary" \
        --risk-level low \
        --cooldown 0 \
        --preview "$preview" \
        --payload "$payload"
    ;;

# ─── EXECUTE (called by approval-executor after approval) ─────────────────
execute)
    AID="${1:-}"
    if [[ -z "$AID" ]]; then
        echo "Usage: calendar-staging.sh execute <AID>" >&2
        exit 1
    fi

    # Validate approval (check-only — don't mark executed yet)
    if ! bash "$SCRIPT_DIR/approval-check.sh" --validate-only "$AID" 2>&1; then
        log "BLOCKED: $AID not approved or cooldown active"
        exit 1
    fi

    # Read payload from approval file
    APPROVAL_FILE="$BRIDGE_DIR/state/approvals/$AID.json"
    event_id=$(jq -r '.payload.event_id // empty' "$APPROVAL_FILE")

    if [[ -z "$event_id" ]]; then
        log "ERROR: no event_id in payload for $AID"
        echo "ERROR: no event_id in payload" >&2
        exit 1
    fi

    # Verify event still exists on staging calendar
    event_data=$(gws_calendar_get_event "$event_id" "$STAGING_CAL") || {
        log "ERROR: failed to fetch staging event $event_id for promotion"
        echo "ERROR: staging event fetch failed" >&2
        exit 1
    }

    event_error=$(echo "$event_data" | jq -r '.error.message // empty')
    if [[ -n "$event_error" ]]; then
        log "ERROR: staging event $event_id no longer exists: $event_error"
        echo "ERROR: staging event no longer exists — may have been auto-deleted (48h)" >&2
        exit 1
    fi

    event_summary=$(echo "$event_data" | jq -r '.summary // "Untitled"')

    # Move event from staging to primary (atomic)
    log "PROMOTING: '$event_summary' ($event_id) staging → primary"

    move_response=$(gws_calendar_move_event "$event_id" "$STAGING_CAL" "$PRIMARY_CAL") || {
        log "ERROR: Calendar API move failed for $event_id"
        echo "ERROR: Calendar API move failed" >&2
        exit 1
    }

    new_event_id=$(echo "$move_response" | jq -r '.id // empty')
    if [[ -z "$new_event_id" ]]; then
        error=$(echo "$move_response" | jq -r '.error.message // "unknown error"')
        log "ERROR: promote failed: $error"
        echo "ERROR: promote failed: $error" >&2
        exit 1
    fi

    log "OK: promoted '$event_summary' to Primary (new id: $new_event_id)"

    # Mark executed (with full audit trail)
    bash "$SCRIPT_DIR/approval-check.sh" "$AID" >/dev/null 2>&1 || true
    ;;

# ─── CLEANUP (delete staging holds older than 48h) ────────────────────────
cleanup)
    log "CLEANUP: scanning staging calendar for holds older than ${STAGING_MAX_AGE_HOURS}h"

    # Get all events from staging calendar (past 7 days to catch stale ones)
    past_date=$(date -v-7d +"%Y-%m-%d")
    future_date=$(date -v+30d +"%Y-%m-%d")

    events_response=$(gws_calendar_events "$past_date" "$future_date" "$STAGING_CAL") || {
        log "ERROR: failed to list staging events"
        exit 0  # Non-fatal — cleanup is best-effort
    }

    event_count=$(echo "$events_response" | jq -r '.items | length // 0')
    if [[ "$event_count" -eq 0 ]]; then
        log "CLEANUP: no staging events found"
        exit 0
    fi

    now_epoch=$(date +%s)
    deleted=0
    warned=0

    echo "$events_response" | jq -c '.items[]' | while IFS= read -r event; do
        event_id=$(echo "$event" | jq -r '.id')
        event_summary=$(echo "$event" | jq -r '.summary // "Untitled"')
        created_str=$(echo "$event" | jq -r '.created // empty')

        [[ -z "$created_str" ]] && continue

        # Parse created timestamp (ISO 8601)
        created_epoch=$(date -jf "%Y-%m-%dT%H:%M:%S" "${created_str%%.*}" +%s 2>/dev/null || echo 0)
        age_hours=$(( (now_epoch - created_epoch) / 3600 ))

        if [[ "$age_hours" -ge "$STAGING_MAX_AGE_HOURS" ]]; then
            # Delete stale hold
            http_code=$(gws_calendar_delete_event "$event_id" "$STAGING_CAL")
            if [[ "$http_code" == "204" || "$http_code" == "200" ]]; then
                log "CLEANUP: deleted stale hold '$event_summary' ($event_id, ${age_hours}h old)"
                deleted=$((deleted + 1))
            else
                log "ERROR: failed to delete '$event_summary' ($event_id): HTTP $http_code"
            fi
        elif [[ "$age_hours" -ge $(( STAGING_MAX_AGE_HOURS - 6 )) ]]; then
            # Warn for holds approaching expiry (within 6 hours)
            remaining=$(( STAGING_MAX_AGE_HOURS - age_hours ))
            log "WARN: staging hold '$event_summary' ($event_id) expires in ~${remaining}h"
            warned=$((warned + 1))
        fi
    done

    log "CLEANUP: done (deleted: $deleted, warned: $warned)"
    ;;

# ─── LIST ─────────────────────────────────────────────────────────────────
list)
    future_date=$(date -v+30d +"%Y-%m-%d")
    today=$(date +"%Y-%m-%d")

    events_response=$(gws_calendar_events "$today" "$future_date" "$STAGING_CAL") || {
        echo "ERROR: failed to list staging events" >&2
        exit 1
    }

    echo "$events_response" | jq -r '.items[] | "\(.id)\t\(.summary // "Untitled")\t\(.start.dateTime // .start.date)\t\(.created)"' 2>/dev/null || echo "(no staging events)"
    ;;

*)
    echo "Usage: calendar-staging.sh {create|promote|execute|cleanup|list} [args...]" >&2
    exit 1
    ;;
esac
