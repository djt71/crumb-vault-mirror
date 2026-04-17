---
type: design
domain: software
status: draft
created: 2026-04-01
updated: 2026-04-01
project: tess-v2
skill_origin: null
task: TV2-021b
---

# Tess v2 — Service Interfaces (Finalized)

Extends TV2-021a draft interfaces with contract templates, executor assignments, and token budget estimates for all 14 migrating services. Contract templates are valid against the contract-schema.md (TV2-019) schema v1.0.0.

**Sources:** service-interfaces-draft.md (TV2-021a), contract-schema.md (TV2-019), specification.md (§8, §10b, §17), system-prompt-architecture.md (TV2-023), escalation-design.md (TV2-018), bursty-cost-model.md (TV2-028).

---

## 1. Heartbeats (TV2-032)

### 1a. Health Ping (`ai.openclaw.health-ping`)

| Field | Value |
|-------|-------|
| **Inputs** | None (self-contained liveness check) |
| **Outputs** | HTTP ping to hc-ping.com dead man's switch |
| **Cadence** | Every 900s |
| **Monitoring** | hc-ping.com alerts on missed ping (external) |
| **Overlay** | None |
| **Rollback** | Re-enable OpenClaw LaunchAgent plist. MTTR: <2 min. |
| **Idempotency** | Inherently idempotent -- duplicate pings are harmless. No dedup needed. |

#### Contract Template

```yaml
schema_version: "1.0.0"
contract_id: "TV2-032-C1"
task_id: "TV2-032"
description: "Ping hc-ping.com dead man's switch"
service: "health-ping"
created: "2026-04-01T00:00:00Z"

action_class: "shell-execute"
verifiability: "V1"
priority: "normal"

staging_path: "_staging/TV2-032-C1/"

read_paths: []

tests:
  - id: "test_ping_exit"
    type: "command_exit_zero"
    params:
      command: "curl -fsS -o /dev/null https://hc-ping.com/$HC_PING_UUID"

artifacts: []
quality_checks: []

partial_promotion: "discard"
retry_budget: 3
quality_retry_budget: 0
max_queue_age: "PT1H"
timeout: "PT1M"
escalation: "tess"
convergence_mode: "adaptive"
```

#### Executor Assignment

| Field | Value |
|-------|-------|
| **Primary** | Tier 1 (Nemotron local) |
| **Rationale** | Pure shell execution -- curl to external URL. No judgment, no vault context. `shell-execute` action class routes to Tier 1 via Gate 1. |
| **Fallback** | Tier 3 Claude Code (`claude --print`) -- only if Nemotron is unavailable (DEGRADED-LOCAL). |

#### Token Budget Estimate

| Component | Tokens |
|-----------|--------|
| L1: Stable header | 1,500 |
| L2: Service context | 1,000 |
| L3: Overlays | 0 |
| L4: Contract | 400 |
| L5: Vault context | 0 |
| L6: Failure context | 0 (iteration 1) |
| **Total per invocation** | **~2,900** |
| Invocations/day | 96 (every 900s) |
| Monthly tokens | ~8.4M |
| **Monthly cost** | **$0.00** (Tier 1 local) |

---

### 1b. Awareness Check (`ai.openclaw.awareness-check`)

| Field | Value |
|-------|-------|
| **Inputs** | Vault state files, system health data |
| **Outputs** | Telegram alerts (anomaly detection) |
| **Cadence** | Every 1800s |
| **Monitoring** | Alert delivery confirmation via Telegram API response |
| **Overlay** | None (structural check, no domain judgment) |
| **Rollback** | Re-enable OpenClaw LaunchAgent. MTTR: <2 min. |
| **Idempotency** | Run-ID timestamp prevents duplicate alerts within window. Overlapping runs: skip if lock file exists (stale lock timeout: 2x cadence). |

#### Contract Template

```yaml
schema_version: "1.0.0"
contract_id: "TV2-032-C2"
task_id: "TV2-032"
description: "Check vault and system state, alert on anomalies"
service: "awareness-check"
created: "2026-04-01T00:00:00Z"

action_class: "vault-read-analyze"
verifiability: "V1"
priority: "normal"

side_effects:
  - "send_telegram"
requires_human_approval: false

staging_path: "_staging/TV2-032-C2/"

read_paths:
  - "_system/logs/system-stats.json"
  - "_system/logs/service-status.json"
  - "_openclaw/state/last-run/"

tests:
  - id: "test_report_exists"
    type: "file_exists"
    path: "awareness-report.yaml"
  - id: "test_report_parseable"
    type: "yaml_parseable"
    path: "awareness-report.yaml"

artifacts:
  - id: "artifact_check_count"
    description: "Report covers at least 5 health checks"
    verification: "grep -c 'check:' awareness-report.yaml >= 5"
    executor: "runner"

quality_checks: []

partial_promotion: "discard"
retry_budget: 3
quality_retry_budget: 0
max_queue_age: "PT2H"
timeout: "PT2M"
escalation: "tess"
convergence_mode: "adaptive"
```

#### Executor Assignment

| Field | Value |
|-------|-------|
| **Primary** | Tier 1 (Nemotron local) |
| **Rationale** | Reads vault state files and applies deterministic health checks. `vault-read-analyze` maps to Tier 1. Side effect (Telegram) is declared but Gate 3 does not escalate because `send_telegram` rule only applies to `external-communication` action class -- awareness check alerts are operational, not user-facing communications. |
| **Fallback** | Tier 3 Kimi (cloud orchestration) if Nemotron unavailable. |

#### Token Budget Estimate

| Component | Tokens |
|-----------|--------|
| L1: Stable header | 1,500 |
| L2: Service context | 1,500 |
| L3: Overlays | 0 |
| L4: Contract | 600 |
| L5: Vault context | 3,000 |
| L6: Failure context | 0 (iteration 1) |
| **Total per invocation** | **~6,600** |
| Invocations/day | 48 (every 1800s) |
| Monthly tokens | ~9.5M |
| **Monthly cost** | **$0.00** (Tier 1 local) |

---

### 1c. Backup Status (`com.tess.backup-status`)

| Field | Value |
|-------|-------|
| **Inputs** | Backup job status (vault-backup, system backups) |
| **Outputs** | Status update to dashboard/Telegram on failure |
| **Cadence** | Every 900s |
| **Monitoring** | Dashboard backup panel |
| **Overlay** | None |
| **Rollback** | Re-enable existing LaunchAgent. MTTR: <2 min. |
| **Idempotency** | Status checks are read-only and naturally idempotent. |

#### Contract Template

```yaml
schema_version: "1.0.0"
contract_id: "TV2-032-C3"
task_id: "TV2-032"
description: "Check backup job status, alert on failure"
service: "backup-status"
created: "2026-04-01T00:00:00Z"

action_class: "shell-execute"
verifiability: "V1"
priority: "normal"

side_effects:
  - "send_telegram"
requires_human_approval: false

staging_path: "_staging/TV2-032-C3/"

read_paths: []

tests:
  - id: "test_status_exit"
    type: "command_exit_zero"
    params:
      command: "bash check-backup-status.sh"
  - id: "test_report_exists"
    type: "file_exists"
    path: "backup-status.yaml"
  - id: "test_report_parseable"
    type: "yaml_parseable"
    path: "backup-status.yaml"

artifacts: []
quality_checks: []

partial_promotion: "discard"
retry_budget: 3
quality_retry_budget: 0
max_queue_age: "PT1H"
timeout: "PT1M"
escalation: "tess"
convergence_mode: "adaptive"
```

#### Executor Assignment

| Field | Value |
|-------|-------|
| **Primary** | Tier 1 (Nemotron local) |
| **Rationale** | Shell script execution checking backup timestamps. `shell-execute` maps to Tier 1. Deterministic, no judgment. |
| **Fallback** | Tier 3 Claude Code if Nemotron unavailable. |

#### Token Budget Estimate

| Component | Tokens |
|-----------|--------|
| L1: Stable header | 1,500 |
| L2: Service context | 1,000 |
| L3: Overlays | 0 |
| L4: Contract | 500 |
| L5: Vault context | 0 |
| L6: Failure context | 0 (iteration 1) |
| **Total per invocation** | **~3,000** |
| Invocations/day | 96 (every 900s) |
| Monthly tokens | ~8.6M |
| **Monthly cost** | **$0.00** (Tier 1 local) |

---

## 2. Vault Gardening (TV2-033)

### 2a. Vault Health (`ai.openclaw.vault-health`)

> **Class status (2026-04-17, TV2-057b):** Effectively Class C from Tess v2's perspective. The Tess v2 wrapper (`com.tess.v2.vault-health`) produces only `vault-check-output.txt` in staging. The canonical `_openclaw/state/vault-health-notes.md` is still written by the legacy OpenClaw plist. `canonical_outputs` declaration deferred to TV2-040 (OpenClaw decommission), when canonical-artifact ownership transfers to Tess v2. See `tv2-057-promotion-integration-note.md` §1.1.

| Field | Value |
|-------|-------|
| **Inputs** | Vault files (full scan) |
| **Outputs** | `vault-health-notes.md` (state file), Telegram alerts for findings |
| **Cadence** | Daily 02:00 |
| **Monitoring** | Output file freshness (mtime < 26h). Telegram delivery. |
| **Overlay** | None (mechanical checks: frontmatter, links, staleness) |
| **Rollback** | Re-enable OpenClaw LaunchAgent. Output file is append/replace, no destructive state. MTTR: <5 min. |
| **Idempotency** | Run-ID = date stamp. Re-running same day overwrites same output file. Overlapping-run prevention: lock file with stale timeout 30 min. |

#### Contract Template

```yaml
schema_version: "1.0.0"
contract_id: "TV2-033-C1"
task_id: "TV2-033"
description: "Run vault health check and produce findings report"
service: "vault-health"
created: "2026-04-01T02:00:00Z"

action_class: "shell-execute"
verifiability: "V1"
priority: "normal"

side_effects:
  - "send_telegram"
requires_human_approval: false

staging_path: "_staging/TV2-033-C1/"

read_paths:
  - "_system/scripts/vault-check.sh"

tests:
  - id: "test_report_exists"
    type: "file_exists"
    path: "vault-health-notes.md"
  - id: "test_report_parseable"
    type: "yaml_parseable"
    path: "vault-health-notes.md"
  - id: "test_frontmatter"
    type: "frontmatter_valid"
    path: "vault-health-notes.md"
    params:
      required_fields: [type, status, created, updated]
  - id: "test_exit_code"
    type: "command_exit_zero"
    params:
      command: "bash vault-check.sh --report"

artifacts:
  - id: "artifact_finding_count"
    description: "Report contains at least one finding section"
    verification: "grep -c '^## ' vault-health-notes.md >= 1"
    executor: "runner"

quality_checks: []

partial_promotion: "discard"
retry_budget: 3
quality_retry_budget: 0
max_queue_age: "PT4H"
timeout: "PT5M"
escalation: "tess"
convergence_mode: "adaptive"
```

#### Executor Assignment

| Field | Value |
|-------|-------|
| **Primary** | Tier 1 (Nemotron local) |
| **Rationale** | Executes `vault-check.sh` and structures findings. `shell-execute` action class, V1 verifiability. All checks are mechanical (frontmatter validation, link checking, staleness scans). |
| **Fallback** | Tier 3 Claude Code (`claude --print`) -- vault-check requires bash execution and file system access. |

#### Token Budget Estimate

| Component | Tokens |
|-----------|--------|
| L1: Stable header | 1,500 |
| L2: Service context | 1,500 |
| L3: Overlays | 0 |
| L4: Contract | 700 |
| L5: Vault context | 2,000 |
| L6: Failure context | 0 (iteration 1) |
| **Total per invocation** | **~5,700** |
| Invocations/day | 1 |
| Monthly tokens | ~171K |
| **Monthly cost** | **$0.00** (Tier 1 local) |

---

### 2b. Vault GC (`com.crumb.vault-gc`)

| Field | Value |
|-------|-------|
| **Inputs** | Vault files (orphan detection, temp file cleanup) |
| **Outputs** | Deleted orphan/temp files, log entry |
| **Cadence** | Daily 04:00 |
| **Monitoring** | Log file for deleted items count |
| **Overlay** | None |
| **Rollback** | Git restore for accidentally deleted files. Conservative matching. |
| **Idempotency** | Inherently idempotent -- deleting already-deleted files is a no-op. |

#### Contract Template

```yaml
schema_version: "1.0.0"
contract_id: "TV2-033-C2"
task_id: "TV2-033"
description: "Clean orphan and temp files from vault"
service: "vault-gc"
created: "2026-04-01T04:00:00Z"

action_class: "shell-execute"
verifiability: "V1"
priority: "low"

staging_path: "_staging/TV2-033-C2/"

read_paths: []

tests:
  - id: "test_gc_exit"
    type: "command_exit_zero"
    params:
      command: "bash vault-gc.sh --dry-run"
  - id: "test_log_exists"
    type: "file_exists"
    path: "gc-log.yaml"
  - id: "test_log_parseable"
    type: "yaml_parseable"
    path: "gc-log.yaml"

artifacts:
  - id: "artifact_log_structure"
    description: "GC log contains deleted_count and scanned_count fields"
    verification: "grep -c 'deleted_count\\|scanned_count' gc-log.yaml >= 2"
    executor: "runner"

quality_checks: []

partial_promotion: "discard"
retry_budget: 2
quality_retry_budget: 0
max_queue_age: "PT4H"
timeout: "PT3M"
escalation: "tess"
convergence_mode: "adaptive"
```

#### Executor Assignment

| Field | Value |
|-------|-------|
| **Primary** | Tier 1 (Nemotron local) |
| **Rationale** | File system operations with conservative matching. `shell-execute`, V1. No judgment required -- pattern-matched orphan detection. |
| **Fallback** | Tier 3 Claude Code. GC requires file system access for actual deletions. |

#### Token Budget Estimate

| Component | Tokens |
|-----------|--------|
| L1: Stable header | 1,500 |
| L2: Service context | 1,000 |
| L3: Overlays | 0 |
| L4: Contract | 500 |
| L5: Vault context | 0 |
| L6: Failure context | 0 (iteration 1) |
| **Total per invocation** | **~3,000** |
| Invocations/day | 1 |
| Monthly tokens | ~90K |
| **Monthly cost** | **$0.00** (Tier 1 local) |

---

## 3. Feed Intel Framework (TV2-034)

### 3a. FIF Capture (`ai.openclaw.fif.capture`)

| Field | Value |
|-------|-------|
| **Inputs** | RSS feeds (configured list), X bookmarks (OAuth), YouTube API |
| **Outputs** | SQLite DB rows (new items), `_openclaw/inbox/` files |
| **Cadence** | Daily 06:05 |
| **Monitoring** | Item count delta in SQLite. Capture log. Feed error rates. |
| **Overlay** | None (mechanical: fetch, dedup, store) |
| **Rollback** | Re-enable OpenClaw LaunchAgent + FIF services. SQLite is append-only for captures. MTTR: <5 min. |
| **Idempotency** | Item URL/ID is dedup key in SQLite. Re-running same day re-fetches but skips existing items. Run-ID = `capture-{date}`. |
| **Credentials** | TwitterAPI.io, X OAuth (rotating -- dynamic store), YouTube API |

#### Contract Template

```yaml
schema_version: "1.0.0"
contract_id: "TV2-034-C1"
task_id: "TV2-034"
description: "Capture RSS, X bookmarks, YouTube items to SQLite"
service: "fif-capture"
created: "2026-04-01T06:05:00Z"

action_class: "shell-execute"
verifiability: "V1"
priority: "normal"

side_effects:
  - "sqlite_write"
requires_human_approval: false

staging_path: "_staging/TV2-034-C1/"

read_paths: []

tests:
  - id: "test_capture_exit"
    type: "command_exit_zero"
    params:
      command: "bash fif-capture.sh"
  - id: "test_capture_log"
    type: "file_exists"
    path: "capture-log.yaml"
  - id: "test_log_parseable"
    type: "yaml_parseable"
    path: "capture-log.yaml"
  - id: "test_item_count"
    type: "content_contains"
    path: "capture-log.yaml"
    params:
      substring: "items_captured:"

artifacts:
  - id: "artifact_feed_coverage"
    description: "All configured feeds were attempted"
    verification: "grep -c 'feed:' capture-log.yaml >= 3"
    executor: "runner"

quality_checks: []

partial_promotion: "promote_passing"
retry_budget: 3
quality_retry_budget: 0
max_queue_age: "PT4H"
timeout: "PT5M"
escalation: "tess"
convergence_mode: "adaptive"
```

#### Executor Assignment

| Field | Value |
|-------|-------|
| **Primary** | Tier 1 (Nemotron local) |
| **Rationale** | Mechanical feed fetching and SQLite insertion. `shell-execute`, V1. Dedup is by URL/ID in SQLite -- idempotent by design. Credentials injected via environment variables at dispatch. |
| **Fallback** | Tier 3 Claude Code -- requires network access and SQLite writes. |

#### Token Budget Estimate

| Component | Tokens |
|-----------|--------|
| L1: Stable header | 1,500 |
| L2: Service context | 1,500 |
| L3: Overlays | 0 |
| L4: Contract | 600 |
| L5: Vault context | 0 |
| L6: Failure context | 0 (iteration 1) |
| **Total per invocation** | **~3,600** |
| Invocations/day | 1 |
| Monthly tokens | ~108K |
| **Monthly cost** | **$0.00** (Tier 1 local) |

---

### 3b. FIF Attention (`ai.openclaw.fif.attention`)

| Field | Value |
|-------|-------|
| **Inputs** | Captured items from SQLite (unscored) |
| **Outputs** | Attention scores, tier classification in SQLite |
| **Cadence** | Daily 07:05 (after capture) |
| **Monitoring** | Scored item count. Score distribution (detect model quality drift). |
| **Overlay** | Tier configuration (T1/T2 thresholds, scoring weights) -- shared with dashboard |
| **Rollback** | Scores are overwritable. Re-running rescores. No destructive side effects. |
| **Idempotency** | Per-item scoring is deterministic given same model + prompt. Re-run overwrites scores (acceptable -- scores are not user-facing until review). |
| **Credentials** | Anthropic (for LLM scoring) |

#### Contract Template

```yaml
schema_version: "1.0.0"
contract_id: "TV2-034-C2"
task_id: "TV2-034"
description: "Score captured feed items with attention tiers"
service: "fif-attention"
created: "2026-04-01T07:05:00Z"

action_class: "feed-intel-classify"
verifiability: "V2"
priority: "normal"

side_effects:
  - "sqlite_write"
requires_human_approval: false

staging_path: "_staging/TV2-034-C2/"

read_paths: []

tests:
  - id: "test_scoring_exit"
    type: "command_exit_zero"
    params:
      command: "bash fif-attention.sh"
  - id: "test_scoring_log"
    type: "file_exists"
    path: "scoring-log.yaml"
  - id: "test_log_parseable"
    type: "yaml_parseable"
    path: "scoring-log.yaml"

artifacts:
  - id: "artifact_score_count"
    description: "At least one item scored"
    verification: "grep -c 'items_scored:' scoring-log.yaml >= 1"
    executor: "runner"
  - id: "artifact_tier_distribution"
    description: "Scoring log includes tier distribution breakdown"
    verification: "grep -c 'tier_distribution:' scoring-log.yaml >= 1"
    executor: "runner"

quality_checks:
  - id: "qc_score_distribution"
    description: "Score distribution is plausible (not all T1 or all T3)"
    evaluator: "tess"

partial_promotion: "promote_passing"
retry_budget: 3
quality_retry_budget: 0
max_queue_age: "PT4H"
timeout: "PT10M"
escalation: "tess"
convergence_mode: "adaptive"
```

#### Executor Assignment

| Field | Value |
|-------|-------|
| **Primary** | Tier 1 (Nemotron local) |
| **Rationale** | `feed-intel-classify` maps to Tier 1 in the routing table. V2 (heuristic verification) -- scores can be checked mechanically for plausibility but ultimate quality requires judgment (quality_check). The `reclassifiable: true` flag on this action class means Gate 4 may promote it to Tier 3 if quality drift is detected. |
| **Fallback** | Tier 3 Kimi (cloud orchestration) if Nemotron scoring quality degrades. |

#### Token Budget Estimate

| Component | Tokens |
|-----------|--------|
| L1: Stable header | 1,500 |
| L2: Service context | 2,000 |
| L3: Overlays | 1,000 (tier config) |
| L4: Contract | 700 |
| L5: Vault context | 2,000 (scoring prompt + item batch) |
| L6: Failure context | 0 (iteration 1) |
| **Total per invocation** | **~7,200** |
| Invocations/day | 1 |
| Monthly tokens | ~216K |
| **Monthly cost** | **$0.00** (Tier 1 local; $0.004 if escalated to Kimi) |

---

### 3c. FIF Feedback (`ai.openclaw.fif.feedback`)

| Field | Value |
|-------|-------|
| **Inputs** | Telegram feedback commands (user-initiated) |
| **Outputs** | Score adjustments in SQLite |
| **Cadence** | KeepAlive (event-driven) |
| **Monitoring** | Process liveness. Command response latency. |
| **Overlay** | None |
| **Rollback** | Restart service. Feedback is idempotent per-item (latest feedback wins). |
| **Idempotency** | Feedback keyed by item ID -- latest adjustment overwrites previous. No duplicate risk. |
| **Credentials** | FIF Telegram bot token |

#### Contract Template

```yaml
schema_version: "1.0.0"
contract_id: "TV2-034-C3"
task_id: "TV2-034"
description: "Process Telegram feedback commands for FIF items"
service: "fif-feedback"
created: "2026-04-01T00:00:00Z"

action_class: "shell-execute"
verifiability: "V1"
priority: "normal"

side_effects:
  - "sqlite_write"
  - "send_telegram"
requires_human_approval: false

staging_path: "_staging/TV2-034-C3/"

read_paths: []

tests:
  - id: "test_service_running"
    type: "command_exit_zero"
    params:
      command: "pgrep -f fif-feedback || echo 'not running'"
  - id: "test_response_log"
    type: "file_exists"
    path: "feedback-log.yaml"

artifacts: []
quality_checks: []

partial_promotion: "discard"
retry_budget: 3
quality_retry_budget: 0
max_queue_age: "PT1H"
timeout: "PT2M"
escalation: "tess"
convergence_mode: "adaptive"
```

**Note:** FIF Feedback is a KeepAlive event-driven service. The contract template above covers the health check / restart contract. Actual feedback processing is event-driven and does not flow through the Ralph loop -- item-level feedback is a synchronous SQLite write within the running service.

#### Executor Assignment

| Field | Value |
|-------|-------|
| **Primary** | Tier 1 (Nemotron local) |
| **Rationale** | Event-driven SQLite writes. No judgment -- feedback commands map directly to score adjustments. `shell-execute`, V1. |
| **Fallback** | Tier 3 Claude Code for service restart if Nemotron cannot manage process lifecycle. |

#### Token Budget Estimate

| Component | Tokens |
|-----------|--------|
| L1: Stable header | 1,500 |
| L2: Service context | 1,000 |
| L3: Overlays | 0 |
| L4: Contract | 400 |
| L5: Vault context | 0 |
| L6: Failure context | 0 (iteration 1) |
| **Total per invocation** | **~2,900** |
| Invocations/day | ~1 (health check only; actual feedback is event-driven) |
| Monthly tokens | ~87K |
| **Monthly cost** | **$0.00** (Tier 1 local) |

---

## 4. Daily Attention & Research (TV2-035)

### 4a. Daily Attention (`ai.openclaw.daily-attention`)

> **Class status (2026-04-17, TV2-057b):** Class A (has canonical vault output). Current wrapper (`daily-attention.sh`) writes directly to `_system/daily/{date}.md` via the OpenClaw-scripted path, bypassing staging. This is the §4.4 direct-to-canonical landmine. TV2-057d will migrate the wrapper to produce the plan in `_staging/` and let the promotion engine atomically rename into the canonical path. Migration spec: `tv2-057d-daily-attention-migration.md`.

| Field | Value |
|-------|-------|
| **Inputs** | Goal tracker, project states, personal context, Apple snapshots (calendar, reminders) |
| **Outputs** | Attention plan artifact in vault |
| **Cadence** | Every 1800s |
| **Monitoring** | Output artifact freshness. Input staleness detection (Apple snapshots > 2h old). |
| **Overlay** | Life Coach + Career Coach lenses (from attention-manager skill) |
| **Rollback** | Re-enable OpenClaw LaunchAgent. Attention plan is overwritten each run. |
| **Idempotency** | Run-ID = timestamp. Each run produces fresh plan -- no accumulation. Overlapping-run prevention: skip if prior run's lock file < 15 min old. |

#### Contract Template

```yaml
schema_version: "1.0.0"
contract_id: "TV2-035-C1"
task_id: "TV2-035"
description: "Generate daily attention plan from goals, projects, calendar"
service: "daily-attention"
created: "2026-04-01T00:00:00Z"

action_class: "structured-report"
verifiability: "V2"
priority: "normal"

staging_path: "_staging/TV2-035-C1/"

read_paths:
  - "Domains/career/goal-tracker.md"
  - "_openclaw/state/apple-calendar.txt"
  - "_openclaw/state/apple-reminders.json"

tests:
  - id: "test_plan_exists"
    type: "file_exists"
    path: "attention-plan.md"
  - id: "test_frontmatter"
    type: "frontmatter_valid"
    path: "attention-plan.md"
    params:
      required_fields: [type, status, created]
  - id: "test_min_length"
    type: "line_count_range"
    path: "attention-plan.md"
    params:
      min: 10

artifacts:
  - id: "artifact_sections"
    description: "Plan contains priority and calendar sections"
    verification: "grep -cE '^## (Priority|Calendar|Focus)' attention-plan.md >= 2"
    executor: "runner"

quality_checks:
  - id: "qc_input_freshness"
    description: "Plan reflects today's calendar and current project states"
    evaluator: "tess"

partial_promotion: "promote_passing"
retry_budget: 3
quality_retry_budget: 0
max_queue_age: "PT2H"
timeout: "PT3M"
escalation: "tess"
convergence_mode: "adaptive"

# Class A declaration — TV2-057b.
# Wrapper must produce `attention-plan.md` in the contract's staging_path;
# promotion engine atomically renames into the canonical destination.
canonical_outputs:
  - staging_name: "attention-plan.md"
    destination: "_system/daily/{date}.md"
```

#### Executor Assignment

| Field | Value |
|-------|-------|
| **Primary** | Tier 1 (Nemotron local) |
| **Rationale** | `structured-report` maps to Tier 1 in the routing table. V2 -- output structure is mechanically verifiable, but content quality (relevance to current goals) needs heuristic evaluation. Overlays (Life Coach + Career Coach) add ~2K tokens but remain within the 16K local budget. |
| **Fallback** | Tier 3 Kimi (cloud orchestration) if Nemotron cannot produce coherent structured plans. |

#### Token Budget Estimate

| Component | Tokens |
|-----------|--------|
| L1: Stable header | 1,500 |
| L2: Service context | 2,000 |
| L3: Overlays | 2,000 (Life Coach + Career Coach) |
| L4: Contract | 700 |
| L5: Vault context | 5,000 (goal tracker, calendar, reminders) |
| L6: Failure context | 0 (iteration 1) |
| **Total per invocation** | **~11,200** |
| Invocations/day | 48 (every 1800s) |
| Monthly tokens | ~16.1M |
| **Monthly cost** | **$0.00** (Tier 1 local) |

---

### 4b. Overnight Research (`ai.openclaw.overnight-research`)

| Field | Value |
|-------|-------|
| **Inputs** | Research queue (vault), topic context |
| **Outputs** | Research artifacts in vault (`_openclaw/research/output/`) |
| **Cadence** | Daily 23:00 |
| **Monitoring** | Output artifact count. Research queue drain rate. Error log for failed topics. |
| **Overlay** | Topic-specific overlays (loaded per research item) |
| **Rollback** | Research output is additive. Re-enable OpenClaw service. No destructive state. |
| **Idempotency** | Research topic + date = dedup key. Re-running same night overwrites same output. Queue items marked as in-progress to prevent overlapping runs. |
| **Credentials** | Anthropic, Perplexity (web search) |

#### Contract Template

```yaml
schema_version: "1.0.0"
contract_id: "TV2-035-C2"
task_id: "TV2-035"
description: "Execute overnight research queue and produce artifacts"
service: "overnight-research"
created: "2026-04-01T23:00:00Z"

action_class: "structured-report"
verifiability: "V3"
executor_target: "claude-code"
priority: "normal"

staging_path: "_staging/TV2-035-C2/"

read_paths:
  - "_openclaw/research/queue/"

tests:
  - id: "test_output_exists"
    type: "file_exists"
    path: "research-output/"
  - id: "test_summary_exists"
    type: "file_exists"
    path: "research-summary.yaml"
  - id: "test_summary_parseable"
    type: "yaml_parseable"
    path: "research-summary.yaml"

artifacts:
  - id: "artifact_topic_coverage"
    description: "At least one research topic completed"
    verification: "grep -c 'status: completed' research-summary.yaml >= 1"
    executor: "runner"

quality_checks:
  - id: "qc_depth"
    description: "Research artifacts demonstrate substantive analysis, not summaries"
    evaluator: "tess"
  - id: "qc_sourcing"
    description: "Claims are grounded in cited sources"
    evaluator: "tess"

partial_promotion: "promote_passing"
retry_budget: 3
quality_retry_budget: 1
max_queue_age: "PT6H"
timeout: "PT15M"
escalation: "tess"
convergence_mode: "fixed"
```

#### Executor Assignment

| Field | Value |
|-------|-------|
| **Primary** | Tier 3 Claude Code (`claude --print` with Sonnet) |
| **Rationale** | Research requires web search (Perplexity), multi-file vault writes, and substantive reasoning. V3 -- quality is judgment-dependent. `executor_target: claude-code` forces Tier 3. Claude Code has tool access (Read, Write, Grep, Bash) needed for research artifact production. |
| **Fallback** | Tier 3 Kimi (cloud orchestration) -- can produce research artifacts but without tool access, quality may degrade. |

#### Token Budget Estimate

| Component | Tokens |
|-----------|--------|
| L1: CLAUDE.md (loaded automatically) | ~4,000 |
| L4: Contract (system prompt) | 800 |
| L5: Vault context (read by Claude Code) | ~5,000 |
| Output tokens | ~3,000 |
| **Total per invocation** | **~12,800** |
| Invocations/day | 1 |
| Monthly tokens | ~384K |
| **Monthly cost** | **~$3.90** ($0.13/call x 30 days, Sonnet pricing) |

---

## 5. Email Triage (TV2-036)

### 5a. Email Triage (`ai.openclaw.email-triage`)

| Field | Value |
|-------|-------|
| **Inputs** | Gmail API (unread messages) |
| **Outputs** | Labels applied, urgent alerts via Telegram |
| **Cadence** | Every 1800s |
| **Monitoring** | Processed message count. Auth status (current: FAILING). Label application success rate. |
| **Overlay** | None (rule-based classification) |
| **Rollback** | Labels are additive (non-destructive). Re-enable OpenClaw service. Gmail labels can be batch-reverted if needed. MTTR: <5 min. |
| **Idempotency** | Message ID is dedup key. Already-labeled messages skipped. Overlapping-run prevention: lock file. |
| **Credentials** | Google OAuth (rotating -- requires danny login for TCC) |
| **Current Issue** | Auth failure flag set. Needs OAuth reauthorization before migration. |

#### Contract Template

```yaml
schema_version: "1.0.0"
contract_id: "TV2-036-C1"
task_id: "TV2-036"
description: "Triage unread Gmail, apply labels, alert on urgent items"
service: "email-triage"
created: "2026-04-01T08:00:00Z"

action_class: "external-communication"
verifiability: "V2"
priority: "normal"

requires_human_approval: true
side_effects:
  - "gmail_label"
  - "send_telegram"
confidence_threshold: "high"

staging_path: "_staging/TV2-036-C1/"

read_paths:
  - "Domains/career/career-overview.md"

tests:
  - id: "test_triage_report"
    type: "file_exists"
    path: "triage-report.yaml"
  - id: "test_report_parseable"
    type: "yaml_parseable"
    path: "triage-report.yaml"
  - id: "test_report_schema"
    type: "content_contains"
    path: "triage-report.yaml"
    params:
      substring: "messages_processed:"

artifacts:
  - id: "artifact_label_set"
    description: "All applied labels are from the approved label set"
    verification: "bash validate-labels.sh triage-report.yaml"
    executor: "runner"

quality_checks:
  - id: "qc_classification_accuracy"
    description: "Label assignments match message content (spot-check 3 messages)"
    evaluator: "tess"
  - id: "qc_no_false_urgents"
    description: "Urgent alerts are genuinely urgent, not routine"
    evaluator: "tess"

partial_promotion: "hold_for_review"
retry_budget: 3
quality_retry_budget: 0
max_queue_age: "PT2H"
timeout: "PT5M"
escalation: "danny"
convergence_mode: "adaptive"
```

#### Executor Assignment

| Field | Value |
|-------|-------|
| **Primary** | Tier 3 Kimi (cloud orchestration) |
| **Rationale** | `external-communication` action class routes to Tier 3 via Gate 1. Gate 3 additionally sets `requires_human_approval: true` for external communication. V2 verifiability -- label application is heuristic (mechanically checkable against approved set, but classification accuracy needs judgment). `escalation: danny` because email triage failures affect Danny directly. `confidence_threshold: high` -- no room for uncertainty on side-effecting operations. |
| **Fallback** | Tier 3 Claude Code if Kimi cannot access Gmail API integration. |

#### Token Budget Estimate

| Component | Tokens |
|-----------|--------|
| L1: Stable header | 1,500 |
| L2: Service context | 3,500 |
| L3: Overlays | 0 |
| L4: Contract | 800 |
| L5: Vault context | 5,000 (career overview + email batch) |
| L6: Failure context | 0 (iteration 1) |
| **Total per invocation** | **~10,800** |
| Invocations/day | 48 (every 1800s) |
| Monthly tokens | ~15.6M |
| **Monthly cost** | **~$5.76** ($0.004/call x 48/day x 30 days, Kimi pricing) |

---

## 6. Morning Briefing (TV2-037)

### 6a. Morning Briefing (OpenClaw cron)

| Field | Value |
|-------|-------|
| **Inputs** | Apple snapshots (calendar, reminders), vault state, overnight research output, feed intel digest, email triage results, account-prep data |
| **Outputs** | Briefing artifact, Telegram delivery, Discord delivery |
| **Cadence** | Daily 07:00 |
| **Monitoring** | Delivery confirmation (Telegram + Discord). Briefing completeness (section count). |
| **Overlay** | Career Coach lens (account prep, meeting context) |
| **Rollback** | Re-enable OpenClaw cron job. Briefing is generated fresh each day. |
| **Idempotency** | Date-keyed. Re-running same morning overwrites briefing. Delivery dedup: check message history before re-sending. |
| **Credentials** | Anthropic, Telegram bot, Discord webhooks |
| **Dependencies** | Runs after: email-triage, FIF attention, overnight-research, apple-snapshot |

#### Contract Template

```yaml
schema_version: "1.0.0"
contract_id: "TV2-037-C1"
task_id: "TV2-037"
description: "Generate morning briefing with calendar, research, and feed intel"
service: "morning-briefing"
created: "2026-04-01T07:00:00Z"

action_class: "structured-report"
verifiability: "V3"
executor_target: "tier3"
priority: "normal"

side_effects:
  - "send_telegram"
  - "send_discord"
requires_human_approval: false

staging_path: "_staging/TV2-037-C1/"

read_paths:
  - "_openclaw/state/apple-calendar.txt"
  - "_openclaw/state/apple-reminders.json"
  - "_openclaw/research/output/"
  - "Domains/career/goal-tracker.md"

tests:
  - id: "test_briefing_exists"
    type: "file_exists"
    path: "morning-briefing.md"
  - id: "test_frontmatter"
    type: "frontmatter_valid"
    path: "morning-briefing.md"
    params:
      required_fields: [type, status, created]
  - id: "test_min_length"
    type: "line_count_range"
    path: "morning-briefing.md"
    params:
      min: 20

artifacts:
  - id: "artifact_sections"
    description: "Briefing contains calendar, research, and intel sections"
    verification: "grep -cE '^## (Calendar|Research|Feed Intel)' morning-briefing.md >= 3"
    executor: "runner"

quality_checks:
  - id: "qc_relevance"
    description: "Briefing content is relevant to today's calendar and active goals"
    evaluator: "tess"
  - id: "qc_actionability"
    description: "Briefing includes actionable items, not just summaries"
    evaluator: "tess"
  - id: "qc_no_stale_data"
    description: "No references to events or data older than 48h presented as current"
    evaluator: "tess"

partial_promotion: "hold_for_review"
retry_budget: 3
quality_retry_budget: 1
max_queue_age: "PT2H"
timeout: "PT5M"
escalation: "tess"
convergence_mode: "fixed"
```

#### Executor Assignment

| Field | Value |
|-------|-------|
| **Primary** | Tier 3 Kimi (cloud orchestration) |
| **Rationale** | V3 verifiability -- briefing quality is judgment-dependent (relevance, actionability, staleness). `structured-report` normally routes Tier 1, but `executor_target: tier3` forces cloud execution because briefing synthesis requires cross-domain reasoning across calendar, research, feed intel, and career goals. Quality checks require Tess as evaluator. `quality_retry_budget: 1` allows one re-attempt after quality feedback. |
| **Fallback** | Tier 3 Claude Code (`claude --print`) if Kimi fails to produce adequate briefing quality. |

#### Token Budget Estimate

| Component | Tokens |
|-----------|--------|
| L1: Stable header | 1,500 |
| L2: Service context | 3,000 |
| L3: Overlays | 1,000 (Career Coach) |
| L4: Contract | 900 |
| L5: Vault context | 15,000 (calendar, reminders, research output, goal tracker) |
| L6: Failure context | 0 (iteration 1) |
| **Total per invocation** | **~21,400** |
| Invocations/day | 1 |
| Monthly tokens | ~642K |
| **Monthly cost** | **~$0.12** ($0.004/call x 30 days, Kimi pricing) |

---

## 7. Opportunity Scout (TV2-043)

### 7a. Daily Pipeline (`com.scout.daily-pipeline`)

| Field | Value |
|-------|-------|
| **Inputs** | Job boards (configured URLs), Brave Search API |
| **Outputs** | Digests via Telegram + Discord, SQLite scoring DB |
| **Cadence** | Daily 07:00 |
| **Monitoring** | Digest delivery. Opportunity count. Source error rates. |
| **Overlay** | None (mechanical: scrape, score, deliver) |
| **Rollback** | Re-enable existing LaunchAgent. Digests are additive. |
| **Idempotency** | Opportunity URL is dedup key. Re-running skips known items. Date-stamped digest files. |
| **Credentials** | Anthropic, Brave Search, Scout Telegram bot, Discord webhook |

#### Contract Template

```yaml
schema_version: "1.0.0"
contract_id: "TV2-043-C1"
task_id: "TV2-043"
description: "Scrape job boards, score opportunities, deliver daily digest"
service: "scout-daily-pipeline"
created: "2026-04-01T07:00:00Z"

action_class: "structured-report"
verifiability: "V2"
priority: "normal"

side_effects:
  - "send_telegram"
  - "send_discord"
  - "sqlite_write"
requires_human_approval: false

staging_path: "_staging/TV2-043-C1/"

read_paths: []

tests:
  - id: "test_pipeline_exit"
    type: "command_exit_zero"
    params:
      command: "bash scout-pipeline.sh"
  - id: "test_digest_exists"
    type: "file_exists"
    path: "daily-digest.md"
  - id: "test_scoring_log"
    type: "file_exists"
    path: "scoring-log.yaml"
  - id: "test_log_parseable"
    type: "yaml_parseable"
    path: "scoring-log.yaml"

artifacts:
  - id: "artifact_source_coverage"
    description: "Pipeline attempted all configured job board sources"
    verification: "grep -c 'source:' scoring-log.yaml >= 2"
    executor: "runner"

quality_checks:
  - id: "qc_scoring_quality"
    description: "Opportunity scores reflect role fit and compensation alignment"
    evaluator: "tess"

partial_promotion: "promote_passing"
retry_budget: 3
quality_retry_budget: 0
max_queue_age: "PT4H"
timeout: "PT10M"
escalation: "tess"
convergence_mode: "adaptive"
```

#### Executor Assignment

| Field | Value |
|-------|-------|
| **Primary** | Tier 1 (Nemotron local) |
| **Rationale** | `structured-report` maps to Tier 1. V2 -- mechanical scraping with heuristic scoring. The scoring component uses LLM classification but the pipeline itself is mechanical. Dedup by URL is idempotent. Side effects (Telegram/Discord delivery) are operational notifications, not external communications requiring Gate 3 escalation. |
| **Fallback** | Tier 3 Kimi if scoring quality degrades (Gate 4 reclassification). |

#### Token Budget Estimate

| Component | Tokens |
|-----------|--------|
| L1: Stable header | 1,500 |
| L2: Service context | 2,000 |
| L3: Overlays | 0 |
| L4: Contract | 700 |
| L5: Vault context | 3,000 (scoring prompt + opportunity batch) |
| L6: Failure context | 0 (iteration 1) |
| **Total per invocation** | **~7,200** |
| Invocations/day | 1 |
| Monthly tokens | ~216K |
| **Monthly cost** | **$0.00** (Tier 1 local) |

---

### 7b. Feedback Poller (`com.scout.feedback-poller`)

| Field | Value |
|-------|-------|
| **Inputs** | Telegram feedback commands |
| **Outputs** | Score adjustments in Scout DB |
| **Cadence** | KeepAlive (event-driven) |
| **Monitoring** | Process liveness. Command response latency. |
| **Overlay** | None |
| **Rollback** | Restart service. Latest feedback wins per-item. |
| **Idempotency** | Item-keyed feedback, latest overwrites. |

#### Contract Template

```yaml
schema_version: "1.0.0"
contract_id: "TV2-043-C2"
task_id: "TV2-043"
description: "Process Telegram feedback for opportunity scoring"
service: "scout-feedback-poller"
created: "2026-04-01T00:00:00Z"

action_class: "shell-execute"
verifiability: "V1"
priority: "normal"

side_effects:
  - "sqlite_write"
  - "send_telegram"
requires_human_approval: false

staging_path: "_staging/TV2-043-C2/"

read_paths: []

tests:
  - id: "test_service_running"
    type: "command_exit_zero"
    params:
      command: "pgrep -f scout-feedback || echo 'not running'"
  - id: "test_response_log"
    type: "file_exists"
    path: "feedback-log.yaml"

artifacts: []
quality_checks: []

partial_promotion: "discard"
retry_budget: 3
quality_retry_budget: 0
max_queue_age: "PT1H"
timeout: "PT2M"
escalation: "tess"
convergence_mode: "adaptive"
```

**Note:** Same pattern as FIF Feedback -- KeepAlive service with contract governing health check / restart, not individual feedback events.

#### Executor Assignment

| Field | Value |
|-------|-------|
| **Primary** | Tier 1 (Nemotron local) |
| **Rationale** | Event-driven SQLite writes. Pure mechanical feedback processing. `shell-execute`, V1. |
| **Fallback** | Tier 3 Claude Code for service restart. |

#### Token Budget Estimate

| Component | Tokens |
|-----------|--------|
| L1: Stable header | 1,500 |
| L2: Service context | 1,000 |
| L3: Overlays | 0 |
| L4: Contract | 400 |
| L5: Vault context | 0 |
| L6: Failure context | 0 (iteration 1) |
| **Total per invocation** | **~2,900** |
| Invocations/day | ~1 (health check only) |
| Monthly tokens | ~87K |
| **Monthly cost** | **$0.00** (Tier 1 local) |

---

### 7c. Weekly Heartbeat (`com.scout.weekly-heartbeat`)

| Field | Value |
|-------|-------|
| **Inputs** | Pipeline health data, scoring stats |
| **Outputs** | Summary via Telegram |
| **Cadence** | Monday 08:00 |
| **Monitoring** | Delivery confirmation. |
| **Overlay** | None |
| **Rollback** | Re-enable existing LaunchAgent. |
| **Idempotency** | Weekly date-keyed. Re-running is harmless. |

#### Contract Template

```yaml
schema_version: "1.0.0"
contract_id: "TV2-043-C3"
task_id: "TV2-043"
description: "Generate weekly scout pipeline health summary"
service: "scout-weekly-heartbeat"
created: "2026-04-01T08:00:00Z"

action_class: "structured-report"
verifiability: "V1"
priority: "low"

side_effects:
  - "send_telegram"
requires_human_approval: false

staging_path: "_staging/TV2-043-C3/"

read_paths: []

tests:
  - id: "test_summary_exists"
    type: "file_exists"
    path: "weekly-summary.md"
  - id: "test_min_length"
    type: "line_count_range"
    path: "weekly-summary.md"
    params:
      min: 5

artifacts:
  - id: "artifact_stats"
    description: "Summary includes opportunity count and scoring stats"
    verification: "grep -cE '(opportunities|scored|delivered)' weekly-summary.md >= 2"
    executor: "runner"

quality_checks: []

partial_promotion: "discard"
retry_budget: 2
quality_retry_budget: 0
max_queue_age: "PT4H"
timeout: "PT3M"
escalation: "tess"
convergence_mode: "adaptive"
```

#### Executor Assignment

| Field | Value |
|-------|-------|
| **Primary** | Tier 1 (Nemotron local) |
| **Rationale** | `structured-report`, V1. Weekly aggregation of pipeline stats -- mechanical data collection and formatting. No judgment required. |
| **Fallback** | Tier 3 Kimi if Nemotron is unavailable. |

#### Token Budget Estimate

| Component | Tokens |
|-----------|--------|
| L1: Stable header | 1,500 |
| L2: Service context | 1,500 |
| L3: Overlays | 0 |
| L4: Contract | 500 |
| L5: Vault context | 2,000 (pipeline stats) |
| L6: Failure context | 0 (iteration 1) |
| **Total per invocation** | **~5,500** |
| Invocations/week | 1 |
| Monthly tokens | ~22K |
| **Monthly cost** | **$0.00** (Tier 1 local) |

---

## 8. Connections Brainstorm (TV2-044)

### 8a. Connections Brainstorm (`com.tess.connections-brainstorm`)

> **Class status (2026-04-17, TV2-057b):** Reclassified A → C. Wrapper writes to `_openclaw/inbox/brainstorm-{date}.md`. Per `tv2-057-promotion-integration-note.md` §5, `_openclaw/` is mirror space, not canonical — so this is a side-effect-only contract with no canonical promotion. Added to the Class C allowlist in `classifier.py`; 13 historical staged rows folded into the TV2-057a backfill. No `canonical_outputs` declaration.

| Field | Value |
|-------|-------|
| **Inputs** | Networking contacts (vault), personal context |
| **Outputs** | Brainstorm artifacts in vault |
| **Cadence** | Daily (86400s) |
| **Monitoring** | Output artifact freshness. |
| **Overlay** | Networking context (if relevant overlay exists) |
| **Rollback** | Re-enable existing LaunchAgent. Output is additive. |
| **Idempotency** | Date-keyed output. Re-running overwrites same-day artifact. |
| **Credentials** | Anthropic |

#### Contract Template

```yaml
schema_version: "1.0.0"
contract_id: "TV2-044-C1"
task_id: "TV2-044"
description: "Generate networking connection brainstorm based on contacts"
service: "connections-brainstorm"
created: "2026-04-01T00:00:00Z"

action_class: "structured-report"
verifiability: "V3"
executor_target: "tier3"
priority: "low"

staging_path: "_staging/TV2-044-C1/"

read_paths:
  - "Domains/relationships/networking-contacts.md"
  - "_system/docs/personal-context.md"

tests:
  - id: "test_brainstorm_exists"
    type: "file_exists"
    path: "connections-brainstorm.md"
  - id: "test_frontmatter"
    type: "frontmatter_valid"
    path: "connections-brainstorm.md"
    params:
      required_fields: [type, status, created]
  - id: "test_min_length"
    type: "line_count_range"
    path: "connections-brainstorm.md"
    params:
      min: 15

artifacts:
  - id: "artifact_contacts_referenced"
    description: "Brainstorm references at least 3 contacts"
    verification: "grep -c '\\[\\[' connections-brainstorm.md >= 3"
    executor: "runner"

quality_checks:
  - id: "qc_relevance"
    description: "Brainstorm ideas are contextually relevant to current goals and contacts"
    evaluator: "tess"
  - id: "qc_actionability"
    description: "At least one brainstorm idea has a concrete next step"
    evaluator: "tess"

partial_promotion: "hold_for_review"
retry_budget: 3
quality_retry_budget: 1
max_queue_age: "PT6H"
timeout: "PT5M"
escalation: "tess"
convergence_mode: "fixed"
```

#### Executor Assignment

| Field | Value |
|-------|-------|
| **Primary** | Tier 3 Kimi (cloud orchestration) |
| **Rationale** | V3 verifiability -- brainstorm quality is judgment-dependent. Requires reasoning about interpersonal context, career goals, and networking strategy. `executor_target: tier3` forces cloud execution. Quality checks require evaluator judgment on relevance and actionability. |
| **Fallback** | Tier 3 Claude Code if Kimi produces shallow output. |

#### Token Budget Estimate

| Component | Tokens |
|-----------|--------|
| L1: Stable header | 1,500 |
| L2: Service context | 2,500 |
| L3: Overlays | 1,000 (networking context) |
| L4: Contract | 700 |
| L5: Vault context | 8,000 (contacts, personal context) |
| L6: Failure context | 0 (iteration 1) |
| **Total per invocation** | **~13,700** |
| Invocations/day | 1 |
| Monthly tokens | ~411K |
| **Monthly cost** | **~$0.12** ($0.004/call x 30 days, Kimi pricing) |

---

## Cross-Cutting Concerns

### Credential Access Pattern

All services currently use env files or plist-embedded credentials. Tess v2 consolidates to macOS Keychain per spec §10b.3. Each service needs a credential manifest listing required keys. The orchestrator injects credentials at dispatch time via environment variables scoped to the Ralph loop session.

### Overlapping-Run Prevention

Three patterns available (choose per service):
1. **Lock file** -- simple, filesystem-based. Stale timeout = 2x cadence. Used by: heartbeats, vault health, email triage, daily attention.
2. **SQLite advisory lock** -- for DB-backed services. Used by: FIF, Scout.
3. **Run-ID dedup** -- for idempotent services where re-running is safe. Used by: overnight research, morning briefing.

### Rollback Sequence (all services)

1. Stop Tess v2 service instance
2. Re-enable OpenClaw LaunchAgent/cron (preserved during parallel run)
3. Verify service responds (Telegram ping or health check)
4. Target MTTR: <5 min for low-risk, <15 min for medium-risk

### Monitoring Surfaces (common)

- **Process liveness:** launchd exit code (KeepAlive services), last-run timestamp (interval services)
- **Output freshness:** mtime of output artifacts vs. expected cadence
- **Error rate:** stderr log line count per run
- **Delivery confirmation:** Telegram/Discord API response codes

### Autonomous-Ops Idempotency Patterns

Contract templates reference idempotency through multiple mechanisms:

1. **Dedup keys in data stores:** Item URL/ID (FIF, Scout), Message ID (email triage). Re-running the same contract skips already-processed items. Enforced at the data layer (SQLite UNIQUE constraints), not the contract layer.
2. **Date-keyed outputs:** Morning briefing, overnight research, daily attention, connections brainstorm. Re-running overwrites the same-day artifact. No accumulation of stale outputs.
3. **Lock-file prevention:** High-frequency services (heartbeats, daily attention, email triage) use lock files with stale timeout = 2x cadence to prevent overlapping concurrent runs. Contract retry budgets are per-contract -- a new contract dispatch after the prior one completes is a fresh contract, not a retry.
4. **Harmless duplicates:** Health pings, backup status checks. Re-running is a no-op or produces identical side effects. No dedup needed.
5. **Side-effect dedup:** Services that send Telegram/Discord (morning briefing, awareness check) should check message history before re-sending on contract retry. This prevents duplicate notifications when a contract succeeds on retry after a transient delivery failure.

---

## Summary Table

| Service | Verifiability | Primary Executor | Fallback | Invocations/Day | Monthly Tokens | Monthly Cost |
|---------|--------------|-----------------|----------|-----------------|----------------|-------------|
| health-ping | V1 | Tier 1 (Nemotron) | Tier 3 (Claude Code) | 96 | 8.4M | $0.00 |
| awareness-check | V1 | Tier 1 (Nemotron) | Tier 3 (Kimi) | 48 | 9.5M | $0.00 |
| backup-status | V1 | Tier 1 (Nemotron) | Tier 3 (Claude Code) | 96 | 8.6M | $0.00 |
| vault-health | V1 | Tier 1 (Nemotron) | Tier 3 (Claude Code) | 1 | 171K | $0.00 |
| vault-gc | V1 | Tier 1 (Nemotron) | Tier 3 (Claude Code) | 1 | 90K | $0.00 |
| fif-capture | V1 | Tier 1 (Nemotron) | Tier 3 (Claude Code) | 1 | 108K | $0.00 |
| fif-attention | V2 | Tier 1 (Nemotron) | Tier 3 (Kimi) | 1 | 216K | $0.00 |
| fif-feedback | V1 | Tier 1 (Nemotron) | Tier 3 (Claude Code) | ~1 | 87K | $0.00 |
| daily-attention | V2 | Tier 1 (Nemotron) | Tier 3 (Kimi) | 48 | 16.1M | $0.00 |
| overnight-research | V3 | Tier 3 (Claude Code) | Tier 3 (Kimi) | 1 | 384K | $3.90 |
| email-triage | V2 | Tier 3 (Kimi) | Tier 3 (Claude Code) | 48 | 15.6M | $5.76 |
| morning-briefing | V3 | Tier 3 (Kimi) | Tier 3 (Claude Code) | 1 | 642K | $0.12 |
| scout-daily-pipeline | V2 | Tier 1 (Nemotron) | Tier 3 (Kimi) | 1 | 216K | $0.00 |
| scout-feedback-poller | V1 | Tier 1 (Nemotron) | Tier 3 (Claude Code) | ~1 | 87K | $0.00 |
| scout-weekly-heartbeat | V1 | Tier 1 (Nemotron) | Tier 3 (Kimi) | ~0.14 | 22K | $0.00 |
| connections-brainstorm | V3 | Tier 3 (Kimi) | Tier 3 (Claude Code) | 1 | 411K | $0.12 |
| **Totals** | | | | **~346** | **~60.7M** | **~$9.90** |

**Cost notes:**
- $9.90/month baseline excludes escalation overhead. With 5-10% escalation rate per bursty-cost-model.md, add ~$4-7/month for escalated Sonnet dispatches.
- Projected steady-state range: **$14-17/month**, consistent with bursty-cost-model.md normal scenario ($14.10/month).
- All Tier 1 services are free (local Nemotron execution). 87% of invocations (301/346 daily) run locally.
- Email triage dominates cloud cost because of its 48x/day cadence at Tier 3. If email triage moves to Tier 1 after Gate 4 calibration, monthly cost drops to ~$4.14.
- Monthly token volume is dominated by high-frequency Tier 1 services (heartbeats, daily attention, email triage) which cost $0.
