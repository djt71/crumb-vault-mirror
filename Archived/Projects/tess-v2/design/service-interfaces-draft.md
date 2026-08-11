---
project: tess-v2
type: design-artifact
domain: software
status: draft
created: 2026-03-30
updated: 2026-03-30
task: TV2-021a
---

# Tess v2 — Service Interface Draft

Drafted from TV2-001 migration inventory. Platform-agnostic — no assumptions about Hermes vs. custom orchestrator. Finalization (TV2-021b) adds contract templates, executor assignments, and token budgets after GO/NO-GO decisions.

## Interface Template

Each service defines: inputs, outputs, monitoring surfaces, overlay requirements, rollback procedure, idempotency requirements.

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
| **Idempotency** | Inherently idempotent — duplicate pings are harmless. No dedup needed. |

### 1b. Awareness Check (`ai.openclaw.awareness-check`)

| Field | Value |
|-------|-------|
| **Inputs** | Vault state files, system health data |
| **Outputs** | Telegram alerts (anomaly detection) |
| **Cadence** | Every 1800s |
| **Monitoring** | Alert delivery confirmation via Telegram API response |
| **Overlay** | None (structural check, no domain judgment) |
| **Rollback** | Re-enable OpenClaw LaunchAgent. MTTR: <2 min. |
| **Idempotency** | Run-ID timestamp prevents duplicate alerts within window. Overlapping runs: skip if lock file exists (stale lock timeout: 2× cadence). |

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

---

## 2. Vault Gardening (TV2-033)

### 2a. Vault Health (`ai.openclaw.vault-health`)

| Field | Value |
|-------|-------|
| **Inputs** | Vault files (full scan) |
| **Outputs** | `vault-health-notes.md` (state file), Telegram alerts for findings |
| **Cadence** | Daily 02:00 |
| **Monitoring** | Output file freshness (mtime < 26h). Telegram delivery. |
| **Overlay** | None (mechanical checks: frontmatter, links, staleness) |
| **Rollback** | Re-enable OpenClaw LaunchAgent. Output file is append/replace, no destructive state. MTTR: <5 min. |
| **Idempotency** | Run-ID = date stamp. Re-running same day overwrites same output file. Overlapping-run prevention: lock file with stale timeout 30 min. |

### 2b. Vault GC (`com.crumb.vault-gc`)

| Field | Value |
|-------|-------|
| **Inputs** | Vault files (orphan detection, temp file cleanup) |
| **Outputs** | Deleted orphan/temp files, log entry |
| **Cadence** | Daily 04:00 |
| **Monitoring** | Log file for deleted items count |
| **Overlay** | None |
| **Rollback** | Git restore for accidentally deleted files. Conservative matching. |
| **Idempotency** | Inherently idempotent — deleting already-deleted files is a no-op. |

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
| **Credentials** | TwitterAPI.io, X OAuth (rotating — dynamic store), YouTube API |

### 3b. FIF Attention (`ai.openclaw.fif.attention`)

| Field | Value |
|-------|-------|
| **Inputs** | Captured items from SQLite (unscored) |
| **Outputs** | Attention scores, tier classification in SQLite |
| **Cadence** | Daily 07:05 (after capture) |
| **Monitoring** | Scored item count. Score distribution (detect model quality drift). |
| **Overlay** | Tier configuration (T1/T2 thresholds, scoring weights) — shared with dashboard |
| **Rollback** | Scores are overwritable. Re-running rescores. No destructive side effects. |
| **Idempotency** | Per-item scoring is deterministic given same model + prompt. Re-run overwrites scores (acceptable — scores are not user-facing until review). |
| **Credentials** | Anthropic (for LLM scoring) |

### 3c. FIF Feedback (`ai.openclaw.fif.feedback`)

| Field | Value |
|-------|-------|
| **Inputs** | Telegram feedback commands (user-initiated) |
| **Outputs** | Score adjustments in SQLite |
| **Cadence** | KeepAlive (event-driven) |
| **Monitoring** | Process liveness. Command response latency. |
| **Overlay** | None |
| **Rollback** | Restart service. Feedback is idempotent per-item (latest feedback wins). |
| **Idempotency** | Feedback keyed by item ID — latest adjustment overwrites previous. No duplicate risk. |
| **Credentials** | FIF Telegram bot token |

---

## 4. Daily Attention & Research (TV2-035)

### 4a. Daily Attention (`ai.openclaw.daily-attention`)

| Field | Value |
|-------|-------|
| **Inputs** | Goal tracker, project states, personal context, Apple snapshots (calendar, reminders) |
| **Outputs** | Attention plan artifact in vault |
| **Cadence** | Every 1800s |
| **Monitoring** | Output artifact freshness. Input staleness detection (Apple snapshots > 2h old). |
| **Overlay** | Life Coach + Career Coach lenses (from attention-manager skill) |
| **Rollback** | Re-enable OpenClaw LaunchAgent. Attention plan is overwritten each run. |
| **Idempotency** | Run-ID = timestamp. Each run produces fresh plan — no accumulation. Overlapping-run prevention: skip if prior run's lock file < 15 min old. |

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
| **Credentials** | Google OAuth (rotating — requires danny login for TCC) |
| **Current Issue** | Auth failure flag set. Needs OAuth reauthorization before migration. |

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

---

## 8. Connections Brainstorm (TV2-044)

### 8a. Connections Brainstorm (`com.tess.connections-brainstorm`)

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

---

## Cross-Cutting Concerns

### Credential Access Pattern
All services currently use env files or plist-embedded credentials. Tess v2 consolidates to macOS Keychain per spec §10b.3. Each service needs a credential manifest listing required keys. The orchestrator injects credentials at dispatch time.

### Overlapping-Run Prevention
Three patterns available (choose per service):
1. **Lock file** — simple, filesystem-based. Stale timeout = 2× cadence. Used by: heartbeats, vault health, email triage, daily attention.
2. **SQLite advisory lock** — for DB-backed services. Used by: FIF, Scout.
3. **Run-ID dedup** — for idempotent services where re-running is safe. Used by: overnight research, morning briefing.

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
