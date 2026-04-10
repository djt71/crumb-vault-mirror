---
type: review
review_type: code
review_mode: diff
scope: milestone
project: tess-operations
domain: software
language: shell
framework: bash/launchd/openclaw
diff_stats:
  files_changed: 11
  insertions: 1022
  deletions: 0
skill_origin: code-review
created: 2026-02-26
updated: 2026-02-26
reviewers:
  - anthropic/claude-opus-4-6
  - codex/gpt-5.3-codex
config_snapshot:
  curl_timeout: 120
  codex_timeout: 180
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: true
  user_override: false
  warnings:
    - "localhost URLs: 2 (expected — gateway health checks on 127.0.0.1:18789)"
    - "home directory paths: 34 (expected — scripts target specific macOS user paths)"
reviewer_meta:
  anthropic:
    http_status: 200
    latency_ms: 105000
    attempts: 1
    token_usage:
      input_tokens: 14892
      output_tokens: 4926
    raw_json: Projects/tess-operations/reviews/raw/2026-02-26-code-review-milestone-anthropic.json
  codex:
    exit_code: 0
    latency_ms: 122000
    tools_run:
      - "bash -n (all 4 scripts)"
      - "plutil -lint (plist)"
      - "npm test (no package.json)"
      - "pytest -q (not installed)"
      - "shellcheck --version (not installed)"
      - "rg (file discovery, function signature verification)"
      - "nl -ba (source inspection of all 11 files)"
    token_usage:
      input_tokens: 398300
      output_tokens: 6905
    jsonl_log: Projects/tess-operations/reviews/raw/2026-02-26-code-review-milestone-codex.jsonl
    raw_text: Projects/tess-operations/reviews/raw/2026-02-26-code-review-milestone-codex.txt
tags:
  - review
  - code-review
status: active
---

# Code Review: tess-operations M0+M1 Milestone

**Scope:** Milestone review of M0+M1 implementation (11 files, +1022 lines)
**Date:** 2026-02-26
**Reviewers:** Claude Opus 4.6 (API), Codex GPT-5.3 (CLI)

---

## Anthropic (Claude Opus 4.6)

### ANT-F1 — CRITICAL: Race condition in stale lock recovery
- **File:** `_openclaw/scripts/cron-lib.sh`, lines 63-82
- **Finding:** Between `rm -rf "$lock_path"` and `mkdir "$lock_path"`, another process could acquire the lock. The PID check `kill -0 "$old_pid"` only verifies *a* process with that PID exists -- PIDs are recycled by the OS.
- **Why:** On macOS, PID space is relatively small. A long-lived lock from a dead process could appear "alive" if the PID was reassigned.
- **Fix:** Write both PID and timestamp to the lock. Check process name matches via `ps -p "$old_pid" -o args=`.

### ANT-F2 — CRITICAL: JSON injection via printf in metrics logging
- **File:** `_openclaw/scripts/cron-lib.sh`, lines 150-159
- **Finding:** `_log_metrics` constructs JSON via `printf` without escaping string values. Special characters in job IDs would produce malformed JSONL, breaking all downstream consumers.
- **Why:** Any future job ID with special characters would silently produce invalid JSON, breaking the entire metrics pipeline.
- **Fix:** Use `jq -n` with `--arg` for safe JSON construction.

### ANT-F3 — SIGNIFICANT: Cleanup trap can mislog "interrupted" status
- **File:** `_openclaw/scripts/cron-lib.sh`, lines 169-177
- **Finding:** If a user calls `exit 0` after `cron_init` without calling `cron_finish`, it logs as "interrupted". The trap fires on any exit.
- **Fix:** Add a `_CRON_FINISHED` flag set at the start of `cron_finish`; check it in `_cron_cleanup`.

### ANT-F4 — SIGNIFICANT: Weekly report stores filtered entries in shell variable
- **File:** `_openclaw/scripts/weekly-ops-report.sh`, lines 46-50
- **Finding:** `PERIOD_ENTRIES` stores all filtered JSONL in a shell variable. Large logs could hit memory limits or cause word-splitting issues.
- **Fix:** Write filtered entries to a temp file instead.

### ANT-F5 — SIGNIFICANT: Hard-coded jq path in health-ping.sh
- **File:** `_openclaw/scripts/health-ping.sh`, line 78
- **Finding:** Uses `/opt/homebrew/bin/jq` while rest of codebase uses bare `jq`.
- **Fix:** Use bare `jq` -- the plist already sets PATH to include `/opt/homebrew/bin`.

### ANT-F6 — SIGNIFICANT: jq path-update pattern may corrupt openclaw config
- **File:** `_openclaw/scripts/m1-deploy.sh`, lines 133-137
- **Finding:** The `jq` filter `(.agents.list[]? | select(...)).heartbeat.every = "30m"` may produce multiple output documents or fail to update correctly.
- **Fix:** Use `jq`'s `map` + `if-then-else` pattern for safe array element updates.

### ANT-F7 — SIGNIFICANT: Multi-line prompt passed as CLI --message argument
- **File:** `_openclaw/scripts/m1-deploy.sh`, lines 147-158
- **Finding:** Prompt markdown may contain `--` sequences that the CLI interprets as flags.
- **Fix:** Consider `--message-file` if OpenClaw supports it.

### ANT-F8 — SIGNIFICANT (Retracted): Double logging from TERM+EXIT traps
- **File:** `_openclaw/scripts/cron-lib.sh`, lines 89-99
- **Finding:** Initially identified potential double logging, but retracted after deeper analysis -- the `_CRON_INITIALIZED=false` guard prevents it. Recommendation: use `trap ... EXIT` only.

### ANT-F9 — MINOR: Integer division in missed-run age calculation
- **File:** `_openclaw/scripts/cron-lib.sh`, lines 103-120
- **Finding:** Floor division means 3599s = 0 hours. Slightly lenient boundary.

### ANT-F10 — MINOR: Alert count inflation in weekly report
- **File:** `_openclaw/scripts/weekly-ops-report.sh`, lines 58-63
- **Finding:** `jq -r 'select(...)' | wc -l` counts lines, not entries. Use `jq -c`.

### ANT-F11 — MINOR: $RANDOM limited to 0-32767 for jitter
- **File:** `_openclaw/scripts/cron-lib.sh`, line 127

### ANT-F12 — MINOR: Deploy script hangs on non-interactive input
- **File:** `_openclaw/scripts/m1-deploy.sh`, lines 81-84
- **Fix:** Add `[[ -t 0 ]]` check for non-interactive mode.

### ANT-F13 — MINOR: Silent failure on corrupted metrics log in health-ping
- **File:** `_openclaw/scripts/health-ping.sh`, lines 74-76
- **Fix:** Use `tail -5 | jq -c 'select(.status)' | tail -1` to find last valid entry.

### ANT-F14 — MINOR: No RunAtLoad in health-ping plist
- **File:** `_openclaw/staging/m1/ai.openclaw.health-ping.plist`
- **Fix:** Add `RunAtLoad` for immediate check on boot.

### ANT-F15 — MINOR: Mechanic heartbeat uses sudo launchctl
- **File:** `_openclaw/staging/m1/mechanic-HEARTBEAT.md`, line 16
- **Fix:** Use non-sudo `launchctl list` or configure sudoers.

### ANT-F16 — STRENGTH: Clean public API in cron-lib.sh
Well-ordered initialization sequence with documented rationale.

### ANT-F17 — STRENGTH: Push-model dead man's switch design
Correctly implements silence = alert pattern with graceful M0-to-M1 degradation.

### ANT-F18 — STRENGTH: Idempotent deployment script
Checks for existing jobs, verifies prerequisites, provides rollback instructions.

### ANT-F19 — STRENGTH: Consistent prompt design patterns
All prompts include maintenance pre-check, token budgets, and response format.

**Anthropic Summary: CRITICAL: 2 | SIGNIFICANT: 5 | MINOR: 7 | STRENGTH: 4**

---

## Codex (GPT-5.3-Codex)

### Tool Execution

Codex executed 27 unique commands in 122 seconds:
- **Syntax validation:** `bash -n` on all 4 shell scripts (all passed), `plutil -lint` on plist (OK)
- **Test discovery:** `npm test`, `pytest -q`, `shellcheck --version` -- none available in repo
- **Source inspection:** Read all 11 new files with `nl -ba` for line-numbered review
- **Cross-reference:** `rg` searches for function signatures, config references, env vars

### CDX-F1 — CRITICAL: Dead man's switch silently disabled when URL unset
- **File:** `_openclaw/scripts/health-ping.sh`, lines 31, 100; plist line 21
- **Finding:** Missing `TESS_HEALTH_PING_URL` returns success (SKIP), and the plist does not provide that env var.
- **Why:** Monitoring can be silently disabled while health checks appear "healthy."
- **Fix:** Fail hard when URL is unset, or add `TESS_HEALTH_PING_URL` to LaunchAgent EnvironmentVariables.

### CDX-F2 — SIGNIFICANT: Job-ran-recently check is fail-open
- **File:** `_openclaw/scripts/health-ping.sh`, lines 75, 83
- **Finding:** Empty/unparseable metrics returns 0 (pass), hiding cron outages.
- **Fix:** Return failure after a defined grace period for parse/missing-data states.

### CDX-F3 — SIGNIFICANT: Alert count wrong in weekly report
- **File:** `_openclaw/scripts/weekly-ops-report.sh`, line 68
- **Finding:** `jq -r 'select(...)' | wc -l` counts lines, not objects. (Corroborates ANT-F10.)
- **Fix:** Use `jq -s '[.[] | select(...)] | length'` or `jq -c | wc -l`.

### CDX-F4 — SIGNIFICANT: Vault-health prompt references wrong script path
- **File:** `_openclaw/staging/m1/vault-health-prompt.md`, line 12
- **Finding:** References `/Users/tess/crumb-vault/scripts/vault-check.sh` but actual path is `_system/scripts/vault-check.sh`.
- **Why:** Nightly vault-health task will fail at runtime.
- **Fix:** Update to `/Users/tess/crumb-vault/_system/scripts/vault-check.sh`.

### CDX-F5 — SIGNIFICANT: Heartbeat update may silently succeed with no match
- **File:** `_openclaw/scripts/m1-deploy.sh`, lines 135, 141
- **Finding:** If no agent matches the jq selector, the config is unchanged but script reports success.
- **Fix:** Pre-validate agent existence with `jq -e`, post-verify heartbeat value.

### CDX-F6 — SIGNIFICANT: Unvalidated job-id used in filesystem paths
- **File:** `_openclaw/scripts/cron-lib.sh`, lines 210, 58, 85, 143
- **Finding:** `cron_init` accepts unvalidated job-id used in `rm -rf` paths.
- **Why:** Path traversal or malformed IDs could delete/write outside intended directories.
- **Fix:** Enforce strict job-id regex `^[a-z0-9][a-z0-9_-]*$` and reject `/` or `..`.

### CDX-F7 — MINOR: Logger writes without ensuring parent directory exists
- **File:** `_openclaw/scripts/health-ping.sh`, line 46
- **Fix:** Add `mkdir -p "$(dirname "$LOG_FILE")"`.

### CDX-F8 — MINOR: Heartbeat prompts lack explicit age-check commands
- **File:** `_openclaw/staging/m1/voice-HEARTBEAT.md`, line 17; `pipeline-monitoring-prompt.md`, line 21
- **Fix:** Provide explicit `stat`/epoch math commands instead of relying on agent interpretation.

### CDX-F9 — MINOR: No test suite for shell behaviors
- **File:** All scripts
- **Fix:** Add `bats` tests and `shellcheck` CI step.

### CDX-S1 — STRENGTH: Locking + cleanup trap + wall-time watchdog
Solid shared abstraction for cron safety.

### CDX-S2 — STRENGTH: Syntax/format validation passed
All scripts pass `bash -n`, plist passes `plutil -lint`.

**Codex Summary: CRITICAL: 1 | SIGNIFICANT: 5 | MINOR: 3 | STRENGTH: 2**

---

## Cross-Reviewer Analysis

### Corroborated Findings (both reviewers independently identified)
1. **Alert count bug** (ANT-F10 / CDX-F3) -- `wc -l` on non-compact jq output
2. **No test suite** (ANT test coverage section / CDX-F9)
3. **Health-ping fail-open** (ANT-F13 / CDX-F2) -- corrupted/empty metrics passes silently

### Unique to Anthropic
- F1: Lock PID-reuse race condition
- F2: JSON injection via printf (metrics logging)
- F3: Cleanup trap mislogging
- F5: Hard-coded jq path
- F6: jq path-update config corruption risk
- F8: TERM+EXIT double logging (retracted)

### Unique to Codex
- F1: Dead man's switch silently disabled (missing env var in plist)
- F4: Wrong script path in vault-health prompt
- F5: Heartbeat update silent no-match
- F6: Unvalidated job-id path traversal

### Test Coverage Gaps (both reviewers agree)
No test suite exists. Priority test targets:
1. cron-lib.sh core flows (locking, metrics, kill-switch)
2. health-ping.sh edge cases (down gateway, corrupted log)
3. weekly-ops-report.sh data handling

---

## Synthesis

### Consensus Findings

1. **Alert count bug** (ANT-F10 + CDX-F3): `jq -r 'select(.alert_emitted == true)' | wc -l` counts output lines, not JSONL entries. `jq -r` without `-c` pretty-prints, so each matching entry produces multiple lines. Fix: `jq -c 'select(...)' | wc -l`.

2. **Health-ping fail-open design** (ANT-F13 + CDX-F2): When `ops-metrics.jsonl` is empty, corrupt, or parse-fails, `check_job_ran` returns 0 (pass). This means if cron jobs stop running entirely and the metrics log becomes stale, the health-ping still fires successfully — hiding the outage from the dead man's switch. Both reviewers flagged this independently.

3. **No test suite** (both): No automated tests exist for any shell behavior. Both reviewers agree this is a gap, though both correctly note it's expected for M0/M1 and should be addressed before M2.

### Unique Findings

- **CDX-F4** (wrong vault-check.sh path): **Genuine bug, tool-verified.** Codex ran `rg` to locate the actual file. The vault-health prompt references `scripts/vault-check.sh` but the file lives at `_system/scripts/vault-check.sh`. Nightly vault health check will fail at runtime.

- **ANT-F2** (JSON injection via printf): **Genuine insight.** `_log_metrics` constructs JSON with `printf` — any special characters in values (quotes, backslashes) would produce malformed JSONL. Job IDs are currently controlled strings, but the pattern is fragile. Using `jq -n --arg` is the idiomatic safe approach.

- **CDX-F1** (missing env var in plist): **Genuine insight.** The LaunchAgent plist doesn't include `TESS_HEALTH_PING_URL`, so the health-ping script defaults to empty string, logs SKIP, and returns 0. The dead man's switch is silently disabled until the operator manually adds the env var. Design intent is deliberate (URL unknown until Uptime Robot setup), but the failure mode should be louder.

- **CDX-F6** (unvalidated job-id): **Genuine insight.** `_CRON_JOB_ID` flows into `rm -rf "$LOCK_DIR/$_CRON_JOB_ID"` and file paths without validation. Path traversal risk if a malformed ID were passed. Low practical risk since callers are our own scripts, but worth adding a regex guard.

- **ANT-F6** (jq config corruption): **Genuine insight.** The `jq` filter for updating agent heartbeat intervals may not behave correctly on all config structures. The `(.agents.list[]? | select(...)).field = value` pattern is a jq footgun — it can produce multiple output documents. Using `map(if ... then ... else . end)` is safer.

- **ANT-F3** (cleanup trap mislogging): **Genuine insight.** If a script exits normally but forgets to call `cron_finish`, the trap logs status as "interrupted" — misleading metrics. Adding a `_CRON_FINISHED` flag is the clean fix.

- **ANT-F5** (hard-coded jq path): **Noise-adjacent but valid.** The plist already sets PATH to include `/opt/homebrew/bin`, so the hard-coded path is redundant and inconsistent with the rest of the codebase. Easy fix.

- **CDX-F5** (silent no-match heartbeat update): **Genuine insight.** If the agent ID doesn't match any entry in `openclaw.json`, the jq filter silently outputs unchanged config, and the script reports success. The operator would think the heartbeat was configured when it wasn't.

### Contradictions

No direct contradictions between reviewers. ANT-F8 (double logging from TERM+EXIT traps) was self-retracted by Opus after deeper analysis — the `_CRON_INITIALIZED=false` guard prevents it.

### Action Items

**Must-fix** — blocking correctness:

| ID | Source | File:Line | Action |
|----|--------|-----------|--------|
| A1 | CDX-F4 | `vault-health-prompt.md:12` | Fix path: `scripts/vault-check.sh` → `_system/scripts/vault-check.sh` |
| A2 | ANT-F10, CDX-F3 | `weekly-ops-report.sh:68` | Fix alert count: use `jq -c 'select(.alert_emitted == true)' \| wc -l` |

**Should-fix** — significant but not blocking deployment:

| ID | Source | File:Line | Action |
|----|--------|-----------|--------|
| A3 | ANT-F2 | `cron-lib.sh:150-159` | Replace `printf` JSON construction with `jq -n --arg` for safe JSONL generation |
| A4 | ANT-F13, CDX-F2 | `health-ping.sh:75-83` | Add grace period logic: if metrics log is missing/empty AND script has been running >24h, return failure instead of pass |
| A5 | CDX-F1 | `health-ping.plist` | Add `TESS_HEALTH_PING_URL` key to plist EnvironmentVariables (empty string as placeholder) |
| A6 | ANT-F5 | `health-ping.sh:73` | Replace `/opt/homebrew/bin/jq` with bare `jq` (PATH already includes /opt/homebrew/bin) |
| A7 | CDX-F6 | `cron-lib.sh:210` | Add job-id validation regex `^[a-z0-9][a-z0-9_-]*$` at start of `cron_init` |
| A8 | ANT-F3 | `cron-lib.sh:169-177` | Add `_CRON_FINISHED` flag, check in `_cron_cleanup` to avoid mislogging |
| A9 | ANT-F6, CDX-F5 | `m1-deploy.sh:133-141` | Use `jq 'map(if ... then ... else . end)'` pattern + post-verify heartbeat value was set |

**Defer** — minor or not blocking:

| ID | Source | File:Line | Action |
|----|--------|-----------|--------|
| A10 | ANT-F14 | `health-ping.plist` | Add `RunAtLoad` key for immediate check on boot |
| A11 | CDX-F7 | `health-ping.sh:46` | Add `mkdir -p "$(dirname "$LOG_FILE")"` for log directory creation |
| A12 | ANT-F15 | `mechanic-HEARTBEAT.md:16` | Replace `sudo launchctl print` with non-sudo alternative or document sudoers requirement |
| A13 | CDX-F9 | all scripts | Add `bats` test suite and `shellcheck` CI step (scope for later milestone) |
| A14 | ANT-F7 | `m1-deploy.sh:147-158` | Investigate `--message-file` flag for OpenClaw cron; test multi-line prompt at deploy time |
| A15 | ANT-F4 | `weekly-ops-report.sh:46-50` | Move `PERIOD_ENTRIES` to temp file for large-log resilience |
| A16 | ANT-F12 | `m1-deploy.sh:81-84` | Add `[[ -t 0 ]]` guard for non-interactive environments |

### Considered and Declined

| Finding | Justification | Reason |
|---------|---------------|--------|
| ANT-F1 (PID-reuse race) | macOS PID ceiling is 99998; with ~5 cron jobs the collision probability is negligible. The lock exists to prevent double-run of the same job, not defend against adversarial scheduling. The TOCTOU gap between `rm` and `mkdir` is real but requires millisecond-scale scheduling coincidence in a system with minute-scale cron intervals. | overkill |
| ANT-F9 (integer division in age) | Floor division means 3599s = 0 hours. This is slightly lenient at the boundary but functionally harmless — the missed-run check is a courtesy skip, not a safety invariant. | overkill |
| ANT-F11 ($RANDOM range) | `$RANDOM` produces 0-32767, more than adequate for jitter values of 5-60 seconds. The jitter is a thundering-herd mitigation, not a security mechanism. | overkill |
| ANT-F8 (TERM+EXIT double logging) | Self-retracted by Opus — the `_CRON_INITIALIZED=false` guard in `_cron_cleanup` prevents double logging. | incorrect |
| CDX-F8 (explicit age-check commands) | Heartbeat prompts deliberately delegate time-math to the LLM agent. Hardcoding epoch-based comparisons in the prompt would be more brittle than the current natural-language approach. | constraint |
