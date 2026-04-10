#!/usr/bin/env bash
# knowledge-retrieve.sh — AKM retrieval engine wrapper
# Translates focus signals into QMD queries and outputs a knowledge brief.
#
# Usage:
#   knowledge-retrieve.sh --trigger skill-activation --project <name> --task "<desc>"
#   knowledge-retrieve.sh --trigger new-content --note-path "<path>" --note-tags "kb/x,kb/y"
#
# Output: knowledge brief to stdout (see design/brief-format.md)
# Exit 0 on success (including empty brief), exit 1 on error

set -e

VAULT_ROOT="/Users/tess/crumb-vault"
QMD_BIN="$(command -v qmd 2>/dev/null || true)"
FEEDBACK_LOG="$VAULT_ROOT/_system/logs/akm-feedback.jsonl"
DEDUP_FILE="/tmp/akm-surfaced-$(date +%Y%m%d).txt"

# --- Chronic-miss suppression: removed ---
# Consumption tracking (hit-rate measurement) was removed — the Read-tool-based
# metric couldn't distinguish "brief consumed in context" from "full file opened",
# producing 0% hit rates across all sessions. Without consumption data, chronic-miss
# suppression has no input. Retrieval logging continues in akm-feedback.jsonl.
load_chronic_misses() {
    echo "{}"
}

# Budgets per trigger
BUDGET_SESSION_START=5
BUDGET_SKILL_ACTIVATION=3
BUDGET_NEW_CONTENT=5

# Decay half-lives in days
HALFLIFE_FAST=90        # customer-engagement, training-delivery
HALFLIFE_REFERENCE=730  # software-dev, networking, dns, security — technical reference, not timeless but long-lived
HALFLIFE_SLOW=365       # politics, business, lifestyle
# Timeless categories have no decay

# Category classification
FAST_TAGS="customer-engagement training-delivery"
REFERENCE_TAGS="software-dev dns networking security"
SLOW_TAGS="politics business lifestyle"
TIMELESS_TAGS="philosophy religion biography poetry writing creative fiction inspiration history psychology"

# Personal writing boost
PW_BOOST=0.3
PW_THRESHOLD=3

# Diversity limits
MAX_PER_SOURCE=1
MAX_PER_TAG_CLUSTER=2

# Project tags flow directly into the query as search terms.
# No static mapping — tags like "dashboard", "dataviz" match KB content directly,
# and hybrid mode's query expansion handles semantic neighbors.

# --- Argument parsing ---
TRIGGER=""
PROJECT=""
TASK_DESC=""
SKILL_NAME=""
NOTE_PATH=""
NOTE_TAGS=""
NOTE_FIRST_PARA=""
CONTRACT_DESC=""
SEARCH_HINTS=""
SERVICE=""
DISPATCH_BUDGET=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --trigger) TRIGGER="$2"; shift 2 ;;
        --project) PROJECT="$2"; shift 2 ;;
        --task) TASK_DESC="$2"; shift 2 ;;
        --skill) SKILL_NAME="$2"; shift 2 ;;
        --note-path) NOTE_PATH="$2"; shift 2 ;;
        --note-tags) NOTE_TAGS="$2"; shift 2 ;;
        --note-first-para) NOTE_FIRST_PARA="$2"; shift 2 ;;
        --contract-desc) CONTRACT_DESC="$2"; shift 2 ;;
        --search-hints) SEARCH_HINTS="$2"; shift 2 ;;
        --service) SERVICE="$2"; shift 2 ;;
        --budget) DISPATCH_BUDGET="$2"; shift 2 ;;
        *) echo "Unknown flag: $1" >&2; exit 1 ;;
    esac
done

if [[ -z "$TRIGGER" ]]; then
    echo "Error: --trigger required (skill-activation|new-content|dispatch)" >&2
    exit 1
fi

# Session-start trigger removed — no session context to target against.
# AKM retrieval continues via skill-activation and new-content triggers.
if [[ "$TRIGGER" == "session-start" ]]; then
    exit 0
fi

# --- Dispatch trigger (Amendment AA) ---
# Constructs query from contract description + search_hints, runs hybrid mode,
# applies post-processing. Fail-open: errors produce empty brief, exit 0.
if [[ "$TRIGGER" == "dispatch" ]]; then
    if [[ -z "$CONTRACT_DESC" && -z "$SEARCH_HINTS" ]]; then
        echo "### Knowledge Brief (dispatch)"
        echo "(no contract description or search hints — skipping enrichment)"
        exit 0
    fi

    # QMD check — fail-open
    if [[ -z "$QMD_BIN" ]] || ! "$QMD_BIN" status >/dev/null 2>&1; then
        echo "### Knowledge Brief (dispatch)"
        echo "(QMD not available — dispatch enrichment skipped)"
        # Log the failure
        mkdir -p "$(dirname "$FEEDBACK_LOG")"
        printf '{"timestamp":"%s","trigger":"dispatch","service":"%s","surfaced":[],"empty_reason":"qmd_unavailable"}\n' \
            "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$SERVICE" \
            >> "$FEEDBACK_LOG" 2>/dev/null || true
        exit 0
    fi

    # Build query: contract description + search hints
    DISPATCH_QUERY="$CONTRACT_DESC"
    if [[ -n "$SEARCH_HINTS" ]]; then
        # Hints are comma-separated; append as additional query terms
        DISPATCH_QUERY="$DISPATCH_QUERY $(echo "$SEARCH_HINTS" | tr ',' ' ')"
    fi

    # Budget override or default
    BUDGET="${DISPATCH_BUDGET:-$BUDGET_NEW_CONTENT}"

    # Run hybrid mode (always — cross-domain matching is the point)
    RAW_RESULTS="$("$QMD_BIN" query "$DISPATCH_QUERY" -n 20 --json 2>/dev/null || echo "[]")"

    RESULT_COUNT="$(echo "$RAW_RESULTS" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")"

    if [[ "$RESULT_COUNT" -eq 0 ]]; then
        echo "### Knowledge Brief (dispatch)"
        echo "(no relevant vault content for this contract)"
        printf '{"timestamp":"%s","trigger":"dispatch","service":"%s","surfaced":[],"empty_reason":"no_qmd_results"}\n' \
            "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$SERVICE" \
            >> "$FEEDBACK_LOG" 2>/dev/null || true
        exit 0
    fi

    # Reuse post-filter pipeline: set environment and fall through to the
    # shared post-processing code below. Override budget and dedup behavior.
    TRIGGER_FOR_POSTPROCESS="dispatch"
    # Dispatch enrichment doesn't dedup against prior session surfacing
    DEDUP_FILE="/dev/null"
    # Continue to shared post-processing at "# 3. Post-filter"
fi

# --- QMD availability check with FTS5 fallback ---
USE_FTS5_FALLBACK=""
OBSIDIAN_BIN="$(command -v obsidian 2>/dev/null || true)"

if [[ -z "$QMD_BIN" ]] || ! "$QMD_BIN" status >/dev/null 2>&1; then
    # QMD unavailable — try Obsidian CLI FTS5 as fallback
    if [[ -n "$OBSIDIAN_BIN" ]] && "$OBSIDIAN_BIN" status >/dev/null 2>&1; then
        USE_FTS5_FALLBACK="true"
    else
        case "$TRIGGER" in
            new-content) echo "### Related Knowledge" ;;
            skill-activation) echo "### Knowledge Brief (ambient)" ;;
            *) echo "### Knowledge Brief" ;;
        esac
        echo "(QMD not available — skipping knowledge retrieval)"
        exit 0
    fi
fi

# --- Build focus signal ---
# Extract meaningful keywords from project state for QMD queries.
# Strategy: project names are the strongest signal (domain-specific terms).
# next_action text is noisy (task IDs, filenames) — only extract clean words.

# Enhanced stop words — includes task-noise patterns.
# Uses bash case statements (builtins) instead of grep (process spawn per call).
# Critical for performance: ~50+ words processed per invocation.
is_stop_word() {
    local word="$1"
    # Too short
    [[ ${#word} -le 3 ]] && return 0
    # Common stop words (case is a bash builtin — no process spawn)
    case "$word" in
        the|and|for|with|from|into|that|this|will|have|been|does|also|just|more|than|them|then|what|when|each|only|very|some|next|done|todo|task|after|before|still|need|make|take|keep|move|continue|phase|complete|remaining|working|stage|start|begin|first|last|commit|update|gate|transition|null|true|false)
            return 0 ;;
    esac
    # Task IDs: 2+ letters, dash, digits (e.g., am-004, fif-033)
    case "$word" in
        [a-z][a-z]-[0-9]*|[a-z][a-z][a-z]-[0-9]*|[a-z][a-z][a-z][a-z]-[0-9]*)
            return 0 ;;
    esac
    # Compound task IDs with + (fn1+fn2)
    case "$word" in *[0-9]*+*) return 0 ;; esac
    # Paths (contains / or .)
    case "$word" in */* | *.*) return 0 ;; esac
    # Pure numbers
    case "$word" in [0-9]*) return 0 ;; esac
    # Version-like (v2026)
    case "$word" in v[0-9]*) return 0 ;; esac
    return 1
}

# Clean a word: lowercase, strip punctuation
clean_word() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr -d '()"\,:;!?—–.'
}

build_skill_activation_signal() {
    local keywords=""

    # Project name words
    if [[ -n "$PROJECT" ]]; then
        for word in $(echo "$PROJECT" | tr '-' ' '); do
            local cw
            cw="$(clean_word "$word")"
            if ! is_stop_word "$cw"; then
                keywords="$keywords $cw"
            fi
        done
    fi

    # Task description — extract clean words only
    if [[ -n "$TASK_DESC" ]]; then
        for word in $TASK_DESC; do
            local cw
            cw="$(clean_word "$word")"
            if ! is_stop_word "$cw"; then
                keywords="$keywords $cw"
            fi
        done
    fi

    # Skill name
    if [[ -n "$SKILL_NAME" ]]; then
        for word in $(echo "$SKILL_NAME" | tr '-' ' '); do
            local cw
            cw="$(clean_word "$word")"
            if ! is_stop_word "$cw"; then
                keywords="$keywords $cw"
            fi
        done
    fi

    local unique
    unique="$(echo "$keywords" | tr ' ' '\n' | grep -v '^$' | sort -u | head -15 | tr '\n' ' ')"
    echo "$unique|"
}

build_new_content_signal() {
    local keywords=""

    # Note filename words
    if [[ -n "$NOTE_PATH" ]]; then
        local bname
        bname="$(basename "$NOTE_PATH" .md)"
        for word in $(echo "$bname" | tr '-' ' '); do
            local cw
            cw="$(clean_word "$word")"
            if ! is_stop_word "$cw"; then
                keywords="$keywords $cw"
            fi
        done
    fi

    # Note tags as search terms (strip kb/ prefix)
    if [[ -n "$NOTE_TAGS" ]]; then
        IFS=',' read -ra tag_arr <<< "$NOTE_TAGS"
        for tag in "${tag_arr[@]}"; do
            tag="$(echo "$tag" | xargs | sed 's|^kb/||')"
            if [[ -n "$tag" ]]; then
                keywords="$keywords $tag"
            fi
        done
    fi

    # First paragraph words
    if [[ -n "$NOTE_FIRST_PARA" ]]; then
        for word in $NOTE_FIRST_PARA; do
            local cw
            cw="$(clean_word "$word")"
            if ! is_stop_word "$cw"; then
                keywords="$keywords $cw"
            fi
        done
    fi

    local unique
    unique="$(echo "$keywords" | tr ' ' '\n' | grep -v '^$' | sort -u | head -15 | tr '\n' ' ')"
    echo "$unique|"
}

# --- Execute QMD query ---
# Per-trigger mode selection (AKM-EVL findings, AKM-009):
#   session-start  → hybrid (qmd query): cross-domain matching, query expansion
#   skill-activation → BM25 (qmd search): within-domain keywords, 3× faster
#   new-content    → hybrid (qmd query): cross-domain connections are the point
#
# BM25 needs keyword splitting (3-4 terms per query — long queries return nothing).
# Hybrid handles query expansion internally — pass full query string.

# Determine QMD search mode from trigger
qmd_mode_for_trigger() {
    case "$1" in
        session-start)    echo "hybrid" ;;
        skill-activation) echo "bm25" ;;
        new-content)      echo "hybrid" ;;
        *)                echo "bm25" ;;
    esac
}

run_qmd_query() {
    local query_terms="$1"
    local result_count="${2:-20}"
    local mode
    mode="$(qmd_mode_for_trigger "$TRIGGER")"

    if [[ "$mode" == "hybrid" ]]; then
        # Hybrid: pass full query to qmd query (does its own expansion + reranking)
        "$QMD_BIN" query "$query_terms" -n "$result_count" --json 2>/dev/null || echo "[]"
    else
        # BM25: split into groups of 3 for focused queries, merge results
        local tmpdir="/tmp/akm-query-$$"
        mkdir -p "$tmpdir"

        local terms_array
        read -ra terms_array <<< "$query_terms"
        local group_idx=0
        local i=0
        local group=""

        for term in "${terms_array[@]}"; do
            group="$group $term"
            i=$((i + 1))
            if [[ $i -ge 3 ]]; then
                "$QMD_BIN" search "$group" -n 10 --json 2>/dev/null > "$tmpdir/g${group_idx}.json" || echo "[]" > "$tmpdir/g${group_idx}.json"
                group_idx=$((group_idx + 1))
                group=""
                i=0
            fi
        done
        if [[ -n "$group" ]]; then
            "$QMD_BIN" search "$group" -n 10 --json 2>/dev/null > "$tmpdir/g${group_idx}.json" || echo "[]" > "$tmpdir/g${group_idx}.json"
        fi

        # Merge all result files, deduplicate by filepath, keep highest score
        python3 -c "
import json, glob, os

merged = {}
for f in sorted(glob.glob('$tmpdir/g*.json')):
    try:
        with open(f) as fh:
            results = json.load(fh)
        for r in results:
            fp = r.get('file', '')
            score = r.get('score', 0)
            if fp not in merged or score > merged[fp]['score']:
                merged[fp] = r
    except:
        pass

all_results = sorted(merged.values(), key=lambda x: x.get('score', 0), reverse=True)
print(json.dumps(all_results[:$result_count]))
" 2>/dev/null || echo "[]"

        rm -rf "$tmpdir"
    fi
}

# --- Check personal writing boost ---
# Cached daily to avoid scanning ~1800 files on every invocation
check_personal_writing_boost() {
    local cache_file="/tmp/akm-pw-count-$(date +%Y%m%d).txt"
    local count
    if [[ -f "$cache_file" ]]; then
        count="$(cat "$cache_file")"
    else
        count="$(grep -rl '^type: personal-writing' "$VAULT_ROOT" --include='*.md' 2>/dev/null | wc -l | tr -d ' ')"
        echo "$count" > "$cache_file" 2>/dev/null || true
    fi
    if [[ "$count" -ge "$PW_THRESHOLD" ]]; then
        echo "active"
    else
        echo "inactive"
    fi
}

# --- Main flow ---

# Non-dispatch triggers: signal building + query execution
# (Dispatch trigger already set RAW_RESULTS above and skips this block)
if [[ "$TRIGGER" != "dispatch" ]]; then

# 1. Build signal
case "$TRIGGER" in
    skill-activation) SIGNAL="$(build_skill_activation_signal)" ;;
    new-content) SIGNAL="$(build_new_content_signal)" ;;
    *) echo "Error: unknown trigger '$TRIGGER'" >&2; exit 1 ;;
esac

QUERY_KEYWORDS="$(echo "$SIGNAL" | cut -d'|' -f1)"
QUERY_TAGS="$(echo "$SIGNAL" | cut -d'|' -f2)"

# Load chronic-miss data for post-filter penalty
CHRONIC_MISSES="$(load_chronic_misses)"

# If no keywords, produce empty brief
if [[ -z "$(echo "$QUERY_KEYWORDS" | xargs)" ]]; then
    case "$TRIGGER" in
        new-content) echo "### Related Knowledge" ;;
        skill-activation) echo "### Knowledge Brief (ambient)" ;;
        *) echo "### Knowledge Brief" ;;
    esac
    echo "(no relevant knowledge items for current context)"
    # Log empty-result retrieval for observability
    mkdir -p "$(dirname "$FEEDBACK_LOG")"
    export AKM_FEEDBACK_LOG="$FEEDBACK_LOG"
    export AKM_EMPTY_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    export AKM_EMPTY_TRIGGER="$TRIGGER"
    python3 -c "
import json, os
entry = {
    'timestamp': os.environ['AKM_EMPTY_TS'],
    'trigger': os.environ['AKM_EMPTY_TRIGGER'],
    'surfaced': [],
    'empty_reason': 'no_keywords',
    'query_keywords': ''
}
with open(os.environ['AKM_FEEDBACK_LOG'], 'a') as f:
    f.write(json.dumps(entry) + '\n')
" 2>/dev/null || true
    exit 0
fi

# 2. Run query — QMD primary, Obsidian CLI FTS5 fallback
if [[ -n "$USE_FTS5_FALLBACK" ]]; then
    # FTS5 fallback: use Obsidian CLI search, convert to QMD-like JSON
    # Take first 3 keywords for focused FTS5 query
    FTS5_QUERY="$(echo "$QUERY_KEYWORDS" | tr ' ' '\n' | head -3 | tr '\n' ' ' | xargs)"
    RAW_RESULTS="$("$OBSIDIAN_BIN" search query="$FTS5_QUERY" format=json limit=20 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    results = []
    for item in data.get('results', data) if isinstance(data, dict) else data:
        path = item.get('path', item.get('file', ''))
        # Only include Sources/ and Domains/ (KB content)
        if path.startswith('Sources/') or path.startswith('Domains/'):
            results.append({'file': 'qmd://sources/' + path if path.startswith('Sources/') else 'qmd://domains/' + path.replace('Domains/', ''), 'score': 0.5, 'snippet': item.get('content', '')[:200]})
    print(json.dumps(results[:20]))
except:
    print('[]')
" 2>/dev/null || echo "[]")"
else
    RAW_RESULTS="$(run_qmd_query "$QUERY_KEYWORDS" 20)"
fi

# Parse results count
RESULT_COUNT="$(echo "$RAW_RESULTS" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")"

if [[ "$RESULT_COUNT" -eq 0 ]]; then
    case "$TRIGGER" in
        new-content) echo "### Related Knowledge" ;;
        skill-activation) echo "### Knowledge Brief (ambient)" ;;
        *) echo "### Knowledge Brief" ;;
    esac
    echo "(no relevant knowledge items for current context)"
    # Log empty-result retrieval for observability
    mkdir -p "$(dirname "$FEEDBACK_LOG")"
    export AKM_FEEDBACK_LOG="$FEEDBACK_LOG"
    export AKM_EMPTY_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    export AKM_EMPTY_TRIGGER="$TRIGGER"
    export AKM_EMPTY_KEYWORDS="$QUERY_KEYWORDS"
    python3 -c "
import json, os
entry = {
    'timestamp': os.environ['AKM_EMPTY_TS'],
    'trigger': os.environ['AKM_EMPTY_TRIGGER'],
    'surfaced': [],
    'empty_reason': 'no_qmd_results',
    'query_keywords': os.environ['AKM_EMPTY_KEYWORDS']
}
with open(os.environ['AKM_FEEDBACK_LOG'], 'a') as f:
    f.write(json.dumps(entry) + '\n')
" 2>/dev/null || true
    exit 0
fi

fi  # end non-dispatch trigger block

# 3. Post-filter: decay, diversity, personal writing boost
# Use python3 for JSON parsing and scoring (available on macOS)
# For dispatch trigger, BUDGET was set above; for others, set from trigger type.
if [[ "$TRIGGER" != "dispatch" ]]; then
    BUDGET=5
    case "$TRIGGER" in
        session-start) BUDGET=$BUDGET_SESSION_START ;;
        skill-activation) BUDGET=$BUDGET_SKILL_ACTIVATION ;;
        new-content) BUDGET=$BUDGET_NEW_CONTENT ;;
    esac
fi

PW_STATUS="$(check_personal_writing_boost)"

# Session-start resets the dedup file so each session gets fresh results.
# Within-session dedup still works (session-start → skill-activation), but
# cross-session dedup is removed: morning and afternoon sessions with different
# work contexts should independently surface relevant KB content.
if [[ "$TRIGGER" == "session-start" ]]; then
    > "$DEDUP_FILE" 2>/dev/null || true
fi

DEDUP_PATHS=""
if [[ -f "$DEDUP_FILE" ]]; then
    DEDUP_PATHS="$(cat "$DEDUP_FILE")"
fi

# A3: Pass config to Python via environment variables (not string interpolation)
# A7: Python validates resolved paths stay within VAULT_ROOT
# A8: Surfaced paths written to a dedicated file (not stderr)
SURFACED_FILE="/tmp/akm-surfaced-paths-$$.txt"
export AKM_VAULT_ROOT="$VAULT_ROOT"
export AKM_TRIGGER="$TRIGGER"
export AKM_BUDGET="$BUDGET"
export AKM_PW_STATUS="$PW_STATUS"
export AKM_PW_BOOST="$PW_BOOST"
export AKM_MAX_PER_SOURCE="$MAX_PER_SOURCE"
export AKM_MAX_PER_TAG_CLUSTER="$MAX_PER_TAG_CLUSTER"
export AKM_DEDUP_PATHS="$DEDUP_PATHS"
export AKM_FAST_TAGS="$FAST_TAGS"
export AKM_REFERENCE_TAGS="$REFERENCE_TAGS"
export AKM_SLOW_TAGS="$SLOW_TAGS"
export AKM_TIMELESS_TAGS="$TIMELESS_TAGS"
export AKM_HALFLIFE_FAST="$HALFLIFE_FAST"
export AKM_HALFLIFE_REFERENCE="$HALFLIFE_REFERENCE"
export AKM_HALFLIFE_SLOW="$HALFLIFE_SLOW"
export AKM_SURFACED_FILE="$SURFACED_FILE"
export AKM_CHRONIC_MISSES="$CHRONIC_MISSES"

# Post-filter and format in python3
BRIEF="$(echo "$RAW_RESULTS" | python3 -c "
import sys, json, os, time
from datetime import datetime

VAULT_ROOT = os.environ['AKM_VAULT_ROOT']
TRIGGER = os.environ['AKM_TRIGGER']
BUDGET = int(os.environ['AKM_BUDGET'])
PW_STATUS = os.environ['AKM_PW_STATUS']
PW_BOOST = float(os.environ['AKM_PW_BOOST'])
MAX_PER_SOURCE = int(os.environ['AKM_MAX_PER_SOURCE'])
MAX_PER_TAG_CLUSTER = int(os.environ['AKM_MAX_PER_TAG_CLUSTER'])
dedup_raw = os.environ.get('AKM_DEDUP_PATHS', '').strip()
DEDUP_PATHS = dedup_raw.split('\n') if dedup_raw else []
SURFACED_FILE = os.environ['AKM_SURFACED_FILE']

# Chronic-miss suppression: {vault_path: net_miss_count}
try:
    CHRONIC_MISSES = json.loads(os.environ.get('AKM_CHRONIC_MISSES', '{}'))
except:
    CHRONIC_MISSES = {}

# Category decay config
FAST_TAGS = set(os.environ['AKM_FAST_TAGS'].split())
REFERENCE_TAGS = set(os.environ['AKM_REFERENCE_TAGS'].split())
SLOW_TAGS = set(os.environ['AKM_SLOW_TAGS'].split())
TIMELESS_TAGS = set(os.environ['AKM_TIMELESS_TAGS'].split())
HALFLIFE_FAST = int(os.environ['AKM_HALFLIFE_FAST'])
HALFLIFE_REFERENCE = int(os.environ['AKM_HALFLIFE_REFERENCE'])
HALFLIFE_SLOW = int(os.environ['AKM_HALFLIFE_SLOW'])

# Canonical vault root for path traversal guard (A7)
VAULT_ROOT_REAL = os.path.realpath(VAULT_ROOT) + os.sep

results = json.load(sys.stdin)

def qmd_to_vault_path(filepath):
    if filepath.startswith('qmd://'):
        parts = filepath[6:].split('/', 1)
        collection = parts[0]
        rest = parts[1] if len(parts) > 1 else ''
        mapping = {'sources': 'Sources/', 'projects': 'Projects/', 'domains': 'Domains/', 'system': '_system/docs/'}
        return mapping.get(collection, '') + rest
    return filepath

def qmd_to_real_path(filepath):
    vault_path = qmd_to_vault_path(filepath)
    candidate = os.path.realpath(os.path.join(VAULT_ROOT, vault_path))
    # A7: path traversal guard — reject paths outside vault root
    if not candidate.startswith(VAULT_ROOT_REAL):
        return None
    return candidate

def extract_source_id(vault_path):
    basename = os.path.basename(vault_path).replace('.md', '')
    for suffix in ['-chapter-digest', '-digest', '-summary', '-notes']:
        if basename.endswith(suffix):
            basename = basename[:-len(suffix)]
            break
    return basename

def get_kb_tags(real_path):
    tags = []
    try:
        in_fm = False
        in_tags = False
        with open(real_path, 'r') as f:
            for line in f:
                line = line.rstrip()
                if line == '---':
                    if not in_fm:
                        in_fm = True
                        continue
                    else:
                        break
                if in_fm:
                    if line.startswith('tags:'):
                        in_tags = True
                        continue
                    if in_tags:
                        if line.startswith('  - ') or line.startswith('- '):
                            tag = line.strip().lstrip('- ').strip().strip('\"')
                            if tag.startswith('kb/'):
                                tags.append(tag)
                        else:
                            in_tags = False
    except Exception:
        pass
    return tags

def get_note_type(real_path):
    try:
        in_fm = False
        with open(real_path, 'r') as f:
            for line in f:
                line = line.rstrip()
                if line == '---':
                    if not in_fm:
                        in_fm = True
                        continue
                    else:
                        break
                if in_fm and line.startswith('type:'):
                    return line.split(':', 1)[1].strip().strip('\"')
    except Exception:
        pass
    return ''

def get_note_date(real_path):
    try:
        in_fm = False
        updated = None
        created = None
        with open(real_path, 'r') as f:
            for line in f:
                line = line.rstrip()
                if line == '---':
                    if not in_fm:
                        in_fm = True
                        continue
                    else:
                        break
                if in_fm:
                    if line.startswith('updated:'):
                        updated = line.split(':', 1)[1].strip().strip('\"')
                    elif line.startswith('created:'):
                        created = line.split(':', 1)[1].strip().strip('\"')
        date_str = updated or created
        if date_str:
            note_date = datetime.strptime(date_str[:10], '%Y-%m-%d')
            today = datetime.now()
            return (today - note_date).days
    except Exception:
        pass
    # Fallback: file mtime
    try:
        mtime = os.path.getmtime(real_path)
        return int((time.time() - mtime) / 86400)
    except Exception:
        return 0

def compute_decay(tags, age_days, note_type=''):
    # Book/chapter digests are reference material — recency is not a
    # relevance proxy. Diversity constraints and budget caps prevent
    # flooding; decay just silently buries older library content.
    if note_type in ('book-digest', 'chapter-digest'):
        return 1.0

    tag_names = [t.replace('kb/', '') for t in tags]
    # Check timeless first
    for t in tag_names:
        if t in TIMELESS_TAGS:
            return 1.0
    # Find slowest decay (reference > slow > fast)
    halflife = 0
    for t in tag_names:
        if t in REFERENCE_TAGS:
            halflife = max(halflife, HALFLIFE_REFERENCE)
        elif t in SLOW_TAGS:
            halflife = max(halflife, HALFLIFE_SLOW)
        elif t in FAST_TAGS:
            if halflife == 0:
                halflife = HALFLIFE_FAST
    if halflife == 0:
        return 1.0  # no matching tags = timeless
    return 0.5 ** (age_days / halflife)

def extract_summary(real_path):
    try:
        with open(real_path, 'r') as f:
            lines = f.readlines()
    except Exception:
        return ''

    # Chain 1: frontmatter summary
    in_fm = False
    fm_end = 0
    for i, line in enumerate(lines):
        stripped = line.rstrip()
        if stripped == '---':
            if not in_fm:
                in_fm = True
                continue
            else:
                fm_end = i
                break
        if in_fm and stripped.startswith('summary:'):
            val = stripped.split(':', 1)[1].strip().strip('\"')
            if val:
                return val[:120]

    # Chain 2: first non-heading paragraph after frontmatter
    para = []
    for line in lines[fm_end+1:]:
        stripped = line.rstrip()
        if not stripped or stripped.startswith('#'):
            if para:
                break
            continue
        # Skip list items and metadata-like lines
        if stripped.startswith('- ') or stripped.startswith('  - '):
            continue
        para.append(stripped)

    if para:
        text = ' '.join(para)
        # Strip markdown
        for ch in ['**', '*', '[', ']', '\`']:
            text = text.replace(ch, '')
        text = text.strip()
        if len(text) > 120:
            return text[:117] + '...'
        return text

    # Chain 3: title
    for line in lines:
        if line.startswith('# '):
            return line[2:].strip()

    return ''

# Score and filter results
scored = []
for r in results:
    vault_path = qmd_to_vault_path(r['file'])
    real_path = qmd_to_real_path(r['file'])

    # A7: skip if path resolved outside vault
    if real_path is None:
        continue

    # Only keep KB content (Sources/, Domains/) — skip project/system docs
    if not (vault_path.startswith('Sources/') or vault_path.startswith('Domains/')):
        continue

    # Skip if deduped (skill-activation exempt — intentional re-surfacing at task time)
    if vault_path in DEDUP_PATHS and TRIGGER != 'skill-activation':
        continue

    tags = get_kb_tags(real_path)
    age = get_note_date(real_path)
    note_type = get_note_type(real_path)
    decay = compute_decay(tags, age, note_type)

    # Base score from QMD
    base_score = r.get('score', 0)

    # Apply decay
    adjusted_score = base_score * decay

    # Personal writing boost (note_type already read above for decay)
    if PW_STATUS == 'active' and note_type == 'personal-writing':
        adjusted_score *= (1.0 + PW_BOOST)

    # Chronic-miss suppression: penalize items surfaced repeatedly but never read
    net_misses = CHRONIC_MISSES.get(vault_path, 0)
    if net_misses >= 3:
        continue  # Exclude: surfaced 3+ times in session-ends, never read
    elif net_misses >= 2:
        adjusted_score *= 0.5  # Moderate penalty

    source_id = extract_source_id(vault_path)
    tag_l2 = set()
    for t in tags:
        parts = t.split('/')
        if len(parts) >= 2:
            tag_l2.add(parts[1])

    summary = extract_summary(real_path)
    tag_str = ', '.join(tags) if tags else ''

    scored.append({
        'vault_path': vault_path,
        'score': adjusted_score,
        'source_id': source_id,
        'tag_l2': tag_l2,
        'summary': summary,
        'tag_str': tag_str,
        'is_pw': note_type == 'personal-writing',
    })

# Sort by adjusted score descending
scored.sort(key=lambda x: x['score'], reverse=True)

# Apply diversity constraints
source_counts = {}
tag_cluster_counts = {}
filtered = []

for item in scored:
    # Max per source
    sid = item['source_id']
    if source_counts.get(sid, 0) >= MAX_PER_SOURCE:
        continue

    # Max per tag cluster
    skip = False
    for tc in item['tag_l2']:
        if tag_cluster_counts.get(tc, 0) >= MAX_PER_TAG_CLUSTER:
            skip = True
            break
    if skip:
        continue

    filtered.append(item)
    source_counts[sid] = source_counts.get(sid, 0) + 1
    for tc in item['tag_l2']:
        tag_cluster_counts[tc] = tag_cluster_counts.get(tc, 0) + 1

    if len(filtered) >= BUDGET:
        break

# Format brief
if TRIGGER == 'new-content':
    header = '### Related Knowledge'
elif TRIGGER == 'skill-activation':
    header = '### Knowledge Brief (ambient)'
else:
    header = '### Knowledge Brief'

print(header)
if not filtered:
    print('(no relevant knowledge items for current context)')
else:
    for i, item in enumerate(filtered, 1):
        tag_part = f\" ({item['tag_str']})\" if item['tag_str'] else ''
        summary_part = f\" -- {item['summary']}\" if item['summary'] else ''
        print(f\"[{i}] {item['vault_path']}{summary_part}{tag_part}\")

    # Cross-domain flag
    all_l2 = set()
    for item in filtered:
        all_l2.update(item['tag_l2'])
    if len(all_l2) >= 2:
        tag_list = ' + '.join(f'kb/{t}' for t in sorted(all_l2))
        print(f'[cross-domain: {tag_list} — potential compound insight]')

    # A8: Write surfaced paths to a dedicated file (not stderr)
    paths = [item['vault_path'] for item in filtered]
    try:
        with open(SURFACED_FILE, 'w') as sf:
            for p in paths:
                sf.write(p + '\n')
    except Exception:
        pass
" 2>/dev/null)"

# Append surfaced paths to dedup file and log feedback
if [[ -f "$SURFACED_FILE" ]]; then
    # Append to dedup file for cross-trigger dedup within session
    cat "$SURFACED_FILE" >> "$DEDUP_FILE"
    # A2: Use python3 for proper JSON serialization in feedback log
    CROSS_DOMAIN="false"
    if echo "$BRIEF" | grep -q '\[cross-domain:'; then
        CROSS_DOMAIN="true"
    fi
    mkdir -p "$(dirname "$FEEDBACK_LOG")"
    export AKM_SURFACED_FILE="$SURFACED_FILE"
    export AKM_FEEDBACK_LOG="$FEEDBACK_LOG"
    export AKM_CROSS_DOMAIN="$CROSS_DOMAIN"
    export AKM_TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    python3 -c "
import json, os
paths = [line.strip() for line in open(os.environ['AKM_SURFACED_FILE']) if line.strip()]
if paths:
    entry = {
        'timestamp': os.environ['AKM_TIMESTAMP'],
        'trigger': os.environ['AKM_TRIGGER'],
        'surfaced': paths,
        'cross_domain': os.environ['AKM_CROSS_DOMAIN'] == 'true'
    }
    with open(os.environ['AKM_FEEDBACK_LOG'], 'a') as f:
        f.write(json.dumps(entry) + '\n')
" 2>/dev/null || true
    rm -f "$SURFACED_FILE"
fi

echo "$BRIEF"
