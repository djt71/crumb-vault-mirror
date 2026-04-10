#!/usr/bin/env bash
# skill-preflight.sh — PreToolUse hook for Skill tool
# Fires before every skill invocation. Injects additionalContext with:
#   - KB brief (for KB-eligible skills, via knowledge-retrieve.sh)
#   - Procedural reminders (from skill-preflight-map.yaml)
#   - Input validation warnings (required files missing)
#
# Fast path: skip-entirely skills exit immediately (no subprocesses).
# Graceful degradation: any failure → exit 0 with no output (skill proceeds).
#
# Hook input (stdin): JSON with tool_name="Skill", tool_input={skill, args}
# Hook output (stdout): JSON with hookSpecificOutput.additionalContext

set -e

VAULT_ROOT="/Users/tess/crumb-vault"
KR_SCRIPT="$VAULT_ROOT/_system/scripts/knowledge-retrieve.sh"
MAP_FILE="$VAULT_ROOT/_system/docs/skill-preflight-map.yaml"
ACTIVE_PHASES="SPECIFY|PLAN|TASK|IMPLEMENT|ACT|CLARIFY"

# --- Parse stdin ---
INPUT=$(cat)

SKILL_NAME=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('skill', ''))
except:
    print('')
" 2>/dev/null) || SKILL_NAME=""

SKILL_ARGS=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('args', ''))
except:
    print('')
" 2>/dev/null) || SKILL_ARGS=""

# --- Fast path: skip-entirely skills (no map read, no Python, no subprocesses) ---
case "$SKILL_NAME" in
    sync|checkpoint|startup|diagram-capture|\
loop|simplify|keybindings-help|claude-api|statusline-setup)
        exit 0 ;;
esac

# --- Read map file and build all context in one Python call ---
# This single invocation handles: map parsing, input validation, query hints,
# reminders, and context assembly. Avoids multiple Python/subprocess calls.
export VAULT_ROOT MAP_FILE SKILL_NAME SKILL_ARGS
PREFLIGHT_OUTPUT=$(python3 << 'PYEOF'
import sys, json, os

VAULT_ROOT = os.environ.get("VAULT_ROOT", "/Users/tess/crumb-vault")
MAP_FILE = os.environ.get("MAP_FILE", "")
SKILL_NAME = os.environ.get("SKILL_NAME", "")
SKILL_ARGS = os.environ.get("SKILL_ARGS", "")

# --- Load map file ---
config = {}
try:
    import yaml
    with open(MAP_FILE) as f:
        raw = yaml.safe_load(f) or {}
    config = raw.get(SKILL_NAME, {})
except Exception:
    pass  # Map unavailable — fall back to defaults

kb_eligible = config.get("kb_eligible", True)  # default: eligible
query_hints = config.get("query_hints", [])
reminders = config.get("reminders", [])
required_inputs = config.get("required_inputs", [])
critical_inputs = config.get("critical_inputs", [])

# --- Input validation ---
missing_inputs = []
for rel_path in required_inputs:
    full_path = os.path.join(VAULT_ROOT, rel_path)
    if not os.path.exists(full_path):
        missing_inputs.append(rel_path)

missing_critical = []
for rel_path in critical_inputs:
    full_path = os.path.join(VAULT_ROOT, rel_path)
    if not os.path.exists(full_path):
        missing_critical.append(rel_path)

# --- Build query hint string ---
hint_str = " ".join(query_hints) if query_hints else ""

# --- Output as JSON for bash to consume ---
output = {
    "kb_eligible": kb_eligible,
    "hint_str": hint_str,
    "reminders": reminders,
    "missing_inputs": missing_inputs,
    "missing_critical": missing_critical,
}
print(json.dumps(output))
PYEOF
) || PREFLIGHT_OUTPUT=""

# If Python failed, fall back to phase 1 behavior (KB-eligible, no extras)
if [[ -z "$PREFLIGHT_OUTPUT" ]]; then
    PREFLIGHT_OUTPUT='{"kb_eligible":true,"hint_str":"","reminders":[],"missing_inputs":[]}'
fi

# Extract fields from Python output
KB_ELIGIBLE=$(echo "$PREFLIGHT_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['kb_eligible'])" 2>/dev/null) || KB_ELIGIBLE="True"
HINT_STR=$(echo "$PREFLIGHT_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['hint_str'])" 2>/dev/null) || HINT_STR=""

# --- Infer active project ---
infer_active_project() {
    local cutoff_ts
    cutoff_ts=$(date -v-3d +%s 2>/dev/null || date -d '3 days ago' +%s 2>/dev/null || echo 0)

    local best_name="" best_mtime=0

    for psy in "$VAULT_ROOT"/Projects/*/project-state.yaml; do
        [[ -f "$psy" ]] || continue
        [[ "$psy" == *"Archived/"* ]] && continue

        local phase
        phase=$(grep '^phase:' "$psy" 2>/dev/null | head -1 | sed 's/^phase: *//; s/"//g; s/ *$//') || continue
        echo "$phase" | grep -qE "^($ACTIVE_PHASES)$" || continue

        local mtime
        mtime=$(stat -f %m "$psy" 2>/dev/null || stat -c %Y "$psy" 2>/dev/null || echo 0)

        [[ "$mtime" -lt "$cutoff_ts" ]] && continue

        if [[ "$mtime" -gt "$best_mtime" ]]; then
            best_mtime=$mtime
            best_name=$(basename "$(dirname "$psy")")
        fi
    done

    echo "$best_name"
}

PROJECT=$(infer_active_project)

# --- KB retrieval (if eligible and script exists) ---
KB_BRIEF=""
if [[ "$KB_ELIGIBLE" == "True" ]] && [[ -x "$KR_SCRIPT" ]]; then
    KR_ARGS=(--trigger skill-activation)

    if [[ -n "$PROJECT" ]]; then
        KR_ARGS+=(--project "$PROJECT")
    fi

    # Task description: args + query hints
    TASK_DESC=""
    if [[ -n "$SKILL_ARGS" ]]; then
        TASK_DESC="$SKILL_ARGS"
    fi
    if [[ -n "$HINT_STR" ]]; then
        TASK_DESC="$TASK_DESC $HINT_STR"
    fi
    if [[ -z "$TASK_DESC" ]]; then
        TASK_DESC="$SKILL_NAME"
    fi
    KR_ARGS+=(--task "$TASK_DESC")
    KR_ARGS+=(--skill "$SKILL_NAME")

    KB_BRIEF=$("$KR_SCRIPT" "${KR_ARGS[@]}" 2>/dev/null) || KB_BRIEF=""

    # Strip empty briefs (header only, no items)
    if [[ -n "$KB_BRIEF" ]] && ! echo "$KB_BRIEF" | grep -q '^\['; then
        KB_BRIEF=""
    fi
fi

# --- Assemble final context ---
# Uses one Python call to build the additionalContext string and JSON output
export VAULT_ROOT SKILL_NAME PROJECT KB_BRIEF
FINAL_OUTPUT=$(python3 -c "
import sys, json, os

preflight = json.loads(sys.stdin.read())
kb_brief = os.environ.get('KB_BRIEF', '')
project = os.environ.get('PROJECT', '')
skill = os.environ.get('SKILL_NAME', '')

reminders = preflight.get('reminders', [])
missing = preflight.get('missing_inputs', [])
missing_critical = preflight.get('missing_critical', [])

# --- Critical input check: deny the skill with actionable guidance ---
if missing_critical:
    lines = [f'{skill} blocked: critical inputs missing.']
    for m in missing_critical:
        lines.append(f'  - {m}')
    lines.append(f'Create the missing file(s) or ask the operator before retrying {skill}.')
    reason = '\n'.join(lines)
    output = {
        'hookSpecificOutput': {
            'hookEventName': 'PreToolUse',
            'permissionDecision': 'deny',
            'permissionDecisionReason': reason
        }
    }
    print(json.dumps(output))
    sys.exit(0)

sections = []

# Soft input validation warnings
if missing:
    lines = ['[PREFLIGHT WARNING] Required inputs missing:']
    for m in missing:
        lines.append(f'  - {m}')
    lines.append('Verify these files exist before proceeding. Stop and flag if critical.')
    sections.append('\n'.join(lines))

# KB brief
if kb_brief:
    header = '[Skill Preflight — KB retrieval]'
    if project:
        header += f' (active project: {project})'
    sections.append(header + '\n' + kb_brief)

# Reminders
if reminders:
    lines = [f'[Skill Preflight — reminders for {skill}]']
    for r in reminders:
        lines.append(f'  - {r}')
    sections.append('\n'.join(lines))

# If nothing to inject, output nothing
if not sections:
    sys.exit(0)

context = '\n\n'.join(sections)

output = {
    'hookSpecificOutput': {
        'hookEventName': 'PreToolUse',
        'permissionDecision': 'allow',
        'additionalContext': context
    }
}
print(json.dumps(output))
" <<< "$PREFLIGHT_OUTPUT" 2>/dev/null) || exit 0

# Only output if we have content
if [[ -n "$FINAL_OUTPUT" ]]; then
    echo "$FINAL_OUTPUT"
fi
