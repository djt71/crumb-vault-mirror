#!/usr/bin/env bash
# reminder-write.sh — Add or complete Apple Reminders with approval gating
#
# Source: tess-operations TOP-032 (Reminders write operations)
# Spec: tess-apple-services-spec.md §3.1
#
# Autonomous (no approval): add to Inbox or Agent lists
# Approval required: add to other lists, complete reminders
# Prohibited: delete reminders, delete lists
#
# Usage:
#   reminder-write.sh add "Buy milk" [--list Groceries] [--due tomorrow] [--notes "..."] [--priority medium]
#   reminder-write.sh complete <id>
#   reminder-write.sh execute <AID>   # Called by approval-executor after approval
#
# Exit: 0 on success, 1 on error
# Output: For gated ops, prints AID on stdout

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_ROOT="/Users/tess/crumb-vault"
BRIDGE_DIR="$VAULT_ROOT/_openclaw"
APPLE_CMD="$BRIDGE_DIR/bin/apple-cmd.sh"
LOG_FILE="$BRIDGE_DIR/logs/reminder-write.log"

# Autonomous lists (no approval needed for add)
AUTONOMOUS_LISTS="Inbox|Agent"

# === Logging ===
log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") $1" >> "$LOG_FILE"
}

# === Execute remindctl add via apple-cmd wrapper ===
do_add() {
    local title="$1"
    local list="${2:-Inbox}"
    local due="${3:-}"
    local notes="${4:-}"
    local priority="${5:-}"

    local args=("$title" --list "$list" --json --no-input --no-color)
    [[ -n "$due" ]] && args+=(--due "$due")
    [[ -n "$notes" ]] && args+=(--notes "$notes")
    [[ -n "$priority" ]] && args+=(--priority "$priority")

    local output
    output=$(bash "$APPLE_CMD" remindctl add "${args[@]}" 2>&1) || {
        log "ERROR: remindctl add failed: $output"
        echo "ERROR: remindctl add failed" >&2
        return 1
    }

    log "OK: added reminder '$title' to list '$list'"
    echo "$output"
}

# === Execute remindctl complete via apple-cmd wrapper ===
do_complete() {
    local id="$1"

    local output
    output=$(bash "$APPLE_CMD" remindctl complete "$id" --json --no-input --no-color 2>&1) || {
        log "ERROR: remindctl complete failed for '$id': $output"
        echo "ERROR: remindctl complete failed" >&2
        return 1
    }

    log "OK: completed reminder '$id'"
    echo "$output"
}

# === Subcommand routing ===
subcmd="${1:-}"
shift || true

case "$subcmd" in

# ─── ADD ─────────────────────────────────────────────────────────────────
add)
    TITLE=""
    LIST="Inbox"
    DUE=""
    NOTES=""
    PRIORITY=""

    # First positional arg is title
    if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
        TITLE="$1"
        shift
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --title) TITLE="$2"; shift 2 ;;
            --list|-l) LIST="$2"; shift 2 ;;
            --due|-d) DUE="$2"; shift 2 ;;
            --notes|-n) NOTES="$2"; shift 2 ;;
            --priority|-p) PRIORITY="$2"; shift 2 ;;
            *) echo "ERROR: Unknown flag: $1" >&2; exit 1 ;;
        esac
    done

    if [[ -z "$TITLE" ]]; then
        echo "Usage: reminder-write.sh add \"title\" [--list Name] [--due date] [--notes text] [--priority level]" >&2
        exit 1
    fi

    # Check if autonomous (Inbox/Agent) or needs approval
    if echo "$LIST" | grep -qiE "^($AUTONOMOUS_LISTS)$"; then
        # Autonomous — execute directly
        log "AUTONOMOUS: add '$TITLE' to '$LIST'"
        do_add "$TITLE" "$LIST" "$DUE" "$NOTES" "$PRIORITY"
    else
        # Approval required — create request with payload
        log "GATED: add '$TITLE' to '$LIST' — requesting approval"
        summary="Add reminder to $LIST: $TITLE"
        [[ -n "$DUE" ]] && summary+=" (due: $DUE)"

        payload=$(jq -n -c \
            --arg command "reminder-add" \
            --arg title "$TITLE" \
            --arg list "$LIST" \
            --arg due "$DUE" \
            --arg notes "$NOTES" \
            --arg priority "$PRIORITY" \
            '{command: $command, title: $title, list: $list, due: $due, notes: $notes, priority: $priority}')

        bash "$SCRIPT_DIR/approval-request.sh" \
            --action-type REMINDER_ADD \
            --service apple \
            --target "$LIST" \
            --summary "$summary" \
            --risk-level low \
            --cooldown 0 \
            --payload "$payload"
    fi
    ;;

# ─── COMPLETE ────────────────────────────────────────────────────────────
complete)
    ID="${1:-}"
    if [[ -z "$ID" ]]; then
        echo "Usage: reminder-write.sh complete <id>" >&2
        exit 1
    fi

    # Always requires approval
    log "GATED: complete reminder '$ID' — requesting approval"

    payload=$(jq -n -c \
        --arg command "reminder-complete" \
        --arg id "$ID" \
        '{command: $command, id: $id}')

    bash "$SCRIPT_DIR/approval-request.sh" \
        --action-type REMINDER_COMPLETE \
        --service apple \
        --target "$ID" \
        --summary "Complete reminder: $ID" \
        --risk-level low \
        --cooldown 0 \
        --payload "$payload"
    ;;

# ─── EXECUTE (called by approval-executor after approval) ────────────────
execute)
    AID="${1:-}"
    if [[ -z "$AID" ]]; then
        echo "Usage: reminder-write.sh execute <AID>" >&2
        exit 1
    fi

    # Validate approval (check-only — don't mark executed yet)
    if ! bash "$SCRIPT_DIR/approval-check.sh" --validate-only "$AID" 2>&1; then
        log "BLOCKED: $AID not approved or cooldown active"
        exit 1
    fi

    # Read payload from approval file
    APPROVAL_FILE="$BRIDGE_DIR/state/approvals/$AID.json"
    command=$(jq -r '.payload.command // empty' "$APPROVAL_FILE")

    # Execute the action
    case "$command" in
        reminder-add)
            title=$(jq -r '.payload.title' "$APPROVAL_FILE")
            list=$(jq -r '.payload.list' "$APPROVAL_FILE")
            due=$(jq -r '.payload.due // empty' "$APPROVAL_FILE")
            notes=$(jq -r '.payload.notes // empty' "$APPROVAL_FILE")
            priority=$(jq -r '.payload.priority // empty' "$APPROVAL_FILE")
            do_add "$title" "$list" "$due" "$notes" "$priority"
            ;;
        reminder-complete)
            id=$(jq -r '.payload.id' "$APPROVAL_FILE")
            do_complete "$id"
            ;;
        *)
            log "ERROR: unknown payload command '$command' in $AID"
            echo "ERROR: unknown payload command '$command'" >&2
            exit 1
            ;;
    esac

    # Action succeeded — now mark executed (with full audit trail)
    bash "$SCRIPT_DIR/approval-check.sh" "$AID" >/dev/null 2>&1 || true
    ;;

*)
    echo "Usage: reminder-write.sh {add|complete|execute} [args...]" >&2
    exit 1
    ;;
esac
