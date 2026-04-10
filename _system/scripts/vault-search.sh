#!/usr/bin/env bash
# vault-search.sh — QMD wrapper for vault semantic search
# Used by: Hermes orchestrator tool, Claude Code executor tool, dispatch enrichment
#
# Usage:
#   vault-search.sh "<query>" [--mode hybrid|bm25|semantic] [--limit N] [--timeout S] [--trigger TYPE]
#
# Output: YAML to stdout (result schema or error schema)
# Exit 0 on success (including zero results), exit 1 on argument error only
# All QMD failures return error schema on stdout with exit 0 (fail-open)

set -euo pipefail

VAULT_ROOT="/Users/tess/crumb-vault"
QMD_BIN="/opt/homebrew/bin/qmd"
QMD_INDEX="/Users/tess/.cache/qmd/index.sqlite"
FEEDBACK_LOG="$VAULT_ROOT/_system/logs/akm-feedback.jsonl"
LOW_CONFIDENCE_THRESHOLD="0.3"

# --- Argument parsing ---
QUERY=""
MODE="hybrid"
LIMIT=10
TIMEOUT=5
TRIGGER="unknown"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode) MODE="$2"; shift 2 ;;
        --limit) LIMIT="$2"; shift 2 ;;
        --timeout) TIMEOUT="$2"; shift 2 ;;
        --trigger) TRIGGER="$2"; shift 2 ;;
        --help)
            echo "Usage: vault-search.sh \"<query>\" [--mode hybrid|bm25|semantic] [--limit N] [--timeout S] [--trigger TYPE]"
            exit 0
            ;;
        -*)
            echo "Unknown flag: $1" >&2
            exit 1
            ;;
        *)
            if [[ -z "$QUERY" ]]; then
                QUERY="$1"
            else
                echo "Error: unexpected positional argument: $1" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$QUERY" ]]; then
    echo "Error: query argument required" >&2
    echo "Usage: vault-search.sh \"<query>\" [--mode hybrid|bm25|semantic]" >&2
    exit 1
fi

if [[ "$MODE" != "hybrid" && "$MODE" != "bm25" && "$MODE" != "semantic" ]]; then
    echo "Error: --mode must be hybrid, bm25, or semantic (got: $MODE)" >&2
    exit 1
fi

# --- Helper: escape for YAML double-quoted string ---
yaml_escape() {
    echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# --- Helper: emit error schema (fail-open) ---
emit_error() {
    local error_type="$1"
    local message="$2"
    local escaped_query
    escaped_query="$(yaml_escape "$QUERY")"
    echo "query: \"$escaped_query\""
    echo "error: \"$error_type\""
    echo "message: \"$message\""
    # Log the failure
    local ts
    ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '{"timestamp":"%s","trigger":"%s","event":"%s-failure","error":"%s","query":"%s"}\n' \
        "$ts" "$TRIGGER" "$TRIGGER" "$error_type" "$(echo "$QUERY" | tr '"' "'")" \
        >> "$FEEDBACK_LOG" 2>/dev/null || true
}

# --- QMD availability check ---
if [[ ! -x "$QMD_BIN" ]]; then
    emit_error "qmd_unavailable" "QMD binary not found at $QMD_BIN"
    exit 0
fi

if [[ ! -f "$QMD_INDEX" ]]; then
    emit_error "index_corrupt" "QMD index not found at $QMD_INDEX"
    exit 0
fi

# --- Index freshness ---
index_mtime=$(stat -f "%m" "$QMD_INDEX" 2>/dev/null || echo 0)
now=$(date +%s)
index_age_hours=$(( (now - index_mtime) / 3600 ))
index_stale="false"
if [[ $index_age_hours -ge 24 ]]; then
    index_stale="true"
fi
index_updated_at=$(date -r "$index_mtime" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "unknown")

# --- Map mode to QMD subcommand ---
case "$MODE" in
    hybrid)   qmd_cmd="query" ;;
    bm25)     qmd_cmd="search" ;;
    semantic) qmd_cmd="vsearch" ;;
esac

# --- Execute QMD with timeout (no coreutils timeout on macOS) ---
tmpout="$TMPDIR/vault-search-$$.json"
trap 'rm -f "$tmpout" "$TMPDIR/vault-search-meta.json"' EXIT

"$QMD_BIN" "$qmd_cmd" "$QUERY" -n "$LIMIT" --json >"$tmpout" 2>/dev/null &
qmd_pid=$!

# Wait up to TIMEOUT seconds (check 5x per second)
ticks=0
max_ticks=$(( TIMEOUT * 5 ))
while kill -0 "$qmd_pid" 2>/dev/null; do
    if [[ $ticks -ge $max_ticks ]]; then
        kill "$qmd_pid" 2>/dev/null || true
        wait "$qmd_pid" 2>/dev/null || true
        rm -f "$tmpout"
        emit_error "timeout" "QMD query timed out after ${TIMEOUT}s"
        exit 0
    fi
    sleep 0.2
    ticks=$(( ticks + 1 ))
done

wait "$qmd_pid" 2>/dev/null
qmd_exit=$?

if [[ $qmd_exit -ne 0 ]]; then
    rm -f "$tmpout"
    emit_error "qmd_unavailable" "QMD returned exit code $qmd_exit"
    exit 0
fi

raw_json=$(cat "$tmpout" 2>/dev/null || true)
rm -f "$tmpout"

if [[ -z "$raw_json" ]]; then
    emit_error "qmd_unavailable" "QMD returned empty output"
    exit 0
fi

# --- Parse and emit via Python (handles JSON→YAML, URI mapping, snippet cleaning) ---
echo "$raw_json" | python3 -c "
import sys, json

COLLECTION_MAP = {
    'sources': 'Sources',
    'projects': 'Projects',
    'domains': 'Domains',
    'system': '_system/docs',
}
LOW_CONF = $LOW_CONFIDENCE_THRESHOLD

try:
    results = json.load(sys.stdin)
except (json.JSONDecodeError, ValueError):
    # Signal malformed JSON back to caller
    sys.exit(2)

query = '''$QUERY'''.replace('\"', '\\\\\"')
result_count = len(results)
max_score = max((r.get('score', 0) for r in results), default=0)
low_confidence = result_count == 0 or max_score < LOW_CONF

print(f'query: \"{query}\"')
print(f'mode: \"$MODE\"')
print(f'index_updated_at: \"$index_updated_at\"')
print(f'index_stale: $index_stale')
print(f'result_count: {result_count}')
print(f'low_confidence: {str(low_confidence).lower()}')

if results:
    print('results:')
    for r in results:
        file_uri = r.get('file', '')
        collection = 'unknown'
        vault_path = file_uri
        if file_uri.startswith('qmd://'):
            remainder = file_uri[6:]
            parts = remainder.split('/', 1)
            collection = parts[0]
            rest = parts[1] if len(parts) > 1 else ''
            if collection in COLLECTION_MAP:
                vault_path = COLLECTION_MAP[collection] + '/' + rest

        title = r.get('title', '').replace('\"', '\\\\\"')
        score = r.get('score', 0)
        docid = r.get('docid', '')

        # Clean snippet: strip @@ context markers, take first meaningful lines
        snippet = r.get('snippet', '')
        excerpt_lines = []
        for line in snippet.split('\n'):
            line = line.strip()
            if line and not line.startswith('@@') and not line.startswith('(') and len(line) > 2:
                excerpt_lines.append(line)
        excerpt = ' '.join(excerpt_lines[:3])
        if len(excerpt) > 300:
            excerpt = excerpt[:297] + '...'
        excerpt = excerpt.replace('\"', '\\\\\"')

        print(f'  - path: \"{vault_path}\"')
        print(f'    title: \"{title}\"')
        print(f'    collection: \"{collection}\"')
        print(f'    score: {score}')
        print(f'    excerpt: \"{excerpt}\"')
        print(f'    chunk_id: \"{docid}\"')

# Emit surfaced paths as JSON for logging
paths = []
for r in results:
    f = r.get('file', '')
    if f.startswith('qmd://'):
        parts = f[6:].split('/', 1)
        col = parts[0]
        rest = parts[1] if len(parts) > 1 else ''
        if col in COLLECTION_MAP:
            paths.append(COLLECTION_MAP[col] + '/' + rest)
        else:
            paths.append(f)
    else:
        paths.append(f)
# Write log data to fd 3
print(json.dumps({'paths': paths, 'count': result_count, 'low_confidence': low_confidence}), file=sys.stderr)
" 3>/dev/null 2>"$TMPDIR/vault-search-meta.json"

py_exit=$?
if [[ $py_exit -eq 2 ]]; then
    emit_error "qmd_unavailable" "QMD returned malformed JSON"
    exit 0
elif [[ $py_exit -ne 0 ]]; then
    emit_error "qmd_unavailable" "Result parsing failed"
    exit 0
fi

# --- Log to akm-feedback.jsonl ---
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
if [[ -f "$TMPDIR/vault-search-meta.json" ]]; then
    meta=$(cat "$TMPDIR/vault-search-meta.json")
    surfaced_paths=$(echo "$meta" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin).get('paths',[])))" 2>/dev/null || echo "[]")
    result_count=$(echo "$meta" | python3 -c "import sys,json; print(json.load(sys.stdin).get('count',0))" 2>/dev/null || echo 0)
    low_confidence=$(echo "$meta" | python3 -c "import sys,json; print(str(json.load(sys.stdin).get('low_confidence',False)).lower())" 2>/dev/null || echo "false")
    rm -f "$TMPDIR/vault-search-meta.json"
else
    surfaced_paths="[]"
    result_count=0
    low_confidence="false"
fi

printf '{"timestamp":"%s","trigger":"%s","mode":"%s","query":"%s","result_count":%s,"low_confidence":%s,"surfaced":%s}\n' \
    "$ts" "$TRIGGER" "$MODE" "$(echo "$QUERY" | tr '"' "'")" \
    "$result_count" "$low_confidence" "$surfaced_paths" \
    >> "$FEEDBACK_LOG" 2>/dev/null || true
