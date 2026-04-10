---
project: tess-operations
type: proposal
domain: software
skill_origin: inbox-processor
created: 2026-02-25
updated: 2026-02-26
tags:
  - tess
  - feed-intel
  - openclaw
  - operations
---

# Feed Intelligence Ownership Realignment — Proposal

## Summary

Migrate operational ownership of the feed intelligence pipeline from Crumb (Claude Code sessions) to Tess (OpenClaw voice + mechanic agents). Crumb retains design governance, deep synthesis, and vault filing authority. Tess becomes the active research intake layer — polling, triaging, and delivering content intelligence as part of her chief-of-staff role.

This is not a rewrite. The existing feed-intel-framework codebase (2,301 tests, M2 9/11 complete) stays intact. The change is about *who runs it and where it lives in the system*.

---

## 1. The Problem with Current Ownership

The feed-intel pipeline is architecturally operational — it's cron-driven, it polls APIs, it applies triage logic, it delivers digests, it processes feedback. But it's governed as a Crumb project, which creates a structural mismatch:

**Crumb is session-based.** It wakes up when you open a Claude Code terminal. Feed-intel needs to run whether or not you're at the desk.

**Tess is always-on.** She has cron scheduling, heartbeat monitoring, Telegram delivery, and shell execution. These are exactly the runtime primitives feed-intel needs.

**The current model requires you to be the orchestrator.** You have to remember to run captures, check digests, process feedback. This defeats the purpose of an automated intelligence pipeline.

The result: feed-intel is a well-specified, well-tested system that can't fulfill its core value proposition (ambient, autonomous content intelligence) because it's housed in the wrong agent.

## 2. Proposed Ownership Split

| Layer | Owner | Rationale |
|-------|-------|-----------|
| **Source polling + capture clock** | Tess (cron) | Operational, scheduled, no human judgment needed |
| **Triage (LLM-based)** | Tess (attention clock) | Runs on schedule, uses Haiku 4.5, prompt is already defined |
| **Digest assembly + delivery** | Tess (Telegram) | She already owns the delivery channel |
| **Feedback processing** | Tess (Telegram reply listener) | Real-time response to your replies |
| **Cost telemetry + guardrails** | Tess (mechanic agent) | Health monitoring is mechanic's domain |
| **Queue health + degraded state** | Tess (mechanic heartbeat) | Infrastructure health check |
| **Vault snapshot generation** | Tess | Reads vault state for triage context — mechanical, no judgment |
| **Vault routing (file creation)** | Tess | Writes to `_openclaw/inbox/` per existing convention |
| **Research promotion flagging** | Tess | Identifies candidates per rubric — doesn't decide |
| | | |
| **Triage rubrics + prompt engineering** | Crumb | Design artifacts, version-controlled in vault specs |
| **Source configs + adapter manifests** | Crumb | Design artifacts, reviewed through project workflow |
| **Pipeline specs + architecture** | Crumb | Governed by SPECIFY → PLAN → TASK → IMPLEMENT |
| **Deep synthesis of routed content** | Crumb (Claude Code session) | Requires your attention + larger model reasoning |
| **Filing into MOCs, KB, domain overviews** | Crumb | Vault structure is Crumb's domain |
| **Research promotion decisions** | Crumb (operator-confirmed) | Tess flags, you + Crumb decide |
| **Adapter development (new sources)** | Crumb | New code = project workflow |
| **Web UI development** | Crumb | Frontend design work |

### The Principle

**Tess does the intake and prep.** She polls, triages, digests, delivers, and processes your feedback. She flags things that need deeper attention.

**Crumb goes deep when something warrants it.** He synthesizes, routes to the right vault location, evolves the pipeline design, and builds new capabilities.

**You decide what crosses the boundary.** The "investigate" feedback action, research promotion, and deep-synthesis triggers are all operator-initiated or operator-confirmed.

## 3. Implementation Mechanics

### 3.1 Where the Code Lives

The framework codebase stays at `/Users/tess/openclaw/feed-intel-framework/`. This is already on the Mac Studio (Tess's machine). No code move needed.

### 3.2 How Tess Runs It

All cron jobs use explicit JSON payloads with isolated sessions and delivery blocks. Do not rely on implicit HEARTBEAT routing for feed-intel delivery.

**Capture clock:**
```json
{
  "name": "feed-intel-capture",
  "schedule": { "kind": "cron", "expr": "0 6 * * *", "tz": "America/Detroit" },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Run feed-intel capture clock: node /Users/tess/openclaw/feed-intel-framework/dist/capture/cli.js"
  }
}
```

**Attention clock:**
```json
{
  "name": "feed-intel-attention",
  "schedule": { "kind": "cron", "expr": "30 7 * * *", "tz": "America/Detroit" },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Run feed-intel attention clock: node /Users/tess/openclaw/feed-intel-framework/dist/attention/cli.js. After triage, generate digest and deliver to Telegram."
  },
  "delivery": {
    "channel": "telegram",
    "to": "<danny-telegram-id>",
    "announce": true
  }
}
```

**Feedback listener — heartbeat polling (resolved):**

Heartbeat polling is the default for Phase B. Rationale: requires no new infrastructure, stays within existing OpenClaw patterns, and 30-minute feedback latency is acceptable for a non-time-critical loop.

Implementation: Tess's voice agent heartbeat checks for unprocessed feedback replies. Tagged replies (e.g., `!feed investigate`, `!feed ignore`) are written to a JSONL queue file (`_openclaw/state/feed-intel-feedback.jsonl`). The mechanic processes the queue on each heartbeat cycle.

Upgrade path: if 30-minute latency becomes problematic, migrate to webhook (`/hooks/wake`) for real-time feedback processing. The feedback verb contract (§3.7) is transport-agnostic.

**Phase B uses raw cron jobs.** Lobster can be evaluated as an optimization in a future phase but is not a requirement or dependency for the ownership transition.

### 3.3 How Crumb Governs It

Pipeline specs remain in the vault at `Projects/feed-intel-framework/design/specification.md`. Changes go through the normal project workflow.

Triage prompt changes require a Crumb session — edit the spec, update the preamble file, run the benchmark, deploy.

New adapter development (RSS, YouTube, etc.) follows standard SPECIFY → PLAN → TASK → IMPLEMENT. Crumb builds, tests, and deploys. Tess runs it once deployed.

### 3.4 Credential Access

The X API tokens, TwitterAPI.io keys, and Telegram bot token are already in macOS Keychain on the Studio. Tess's runtime environment has access via `security find-generic-password`. No credential migration needed.

**Cron job access detail:** OpenClaw cron jobs run as the `openclaw` user. The Keychain items are stored in the `openclaw` user's login keychain (`x-feed-intel.telegram-bot-token`, `x-feed-intel.x-api-bearer-token`, etc.). For LaunchAgent-managed sessions, the login keychain is unlocked automatically by launchd. For isolated cron sessions, the cron wrapper must ensure keychain access — either the login keychain is kept unlocked at boot, or credentials are retrieved and passed as environment variables at job start.

**Rotation detection:** If a Keychain item is rotated or removed, the pipeline's API calls will fail with auth errors. The health signal `error_rate_by_adapter` (§5) catches this within one heartbeat cycle. Mechanic alerts via Telegram with the specific adapter and error type.

**Secret hygiene:** API tokens must not appear in cron job logs, OpenClaw session transcripts, or digest output. The pipeline CLI already reads tokens from Keychain at runtime and does not echo them. Verify this invariant after any CLI changes.

### 3.5 Model Capacity for Triage

Triage currently uses Haiku 4.5 (as specified in x-feed-intel). Tess's voice agent also runs Haiku 4.5. Two options:

1. **Triage runs within the voice agent session** — simpler, but burns voice agent context on triage work
2. **Triage runs as isolated cron session** — cleaner separation, triage uses its own context window

Option 2 is better. Cron jobs with `--session isolated` keep triage work out of the conversational context.

### 3.6 Runtime Config Contract

The proposal claims "pipeline reads config from vault specs at runtime" and "spec is single source of truth." This must be formalized to prevent config drift across three potential locations: vault spec values, `.env`/JSON config under `/feed-intel-framework/`, and OpenClaw cron definitions.

**Config source hierarchy:**

| Config Type | Canonical Source | Read At |
|-------------|-----------------|---------|
| Triage rubric + prompt | `Projects/feed-intel-framework/design/specification.md` (preamble section) | Attention clock start |
| Source configs + adapter manifests | `Projects/feed-intel-framework/design/specification.md` (adapter section) | Capture clock start |
| Schedule (cron expressions) | OpenClaw cron definitions (generated from spec) | Cron scheduler |
| API credentials | macOS Keychain (openclaw user) | CLI start |
| Delivery targets (Telegram chat ID, topic) | OpenClaw cron payload `delivery` block | Cron scheduler |

**Validation on parse failure:** If a config file is malformed or missing, the pipeline falls back to the last-known-good snapshot (`_openclaw/state/feed-intel-config-cache.json`). If no cache exists, the job fails and alerts via the health signal system (§5).

**Enforcement rule:** Any change to feed-intel runtime behavior (schedule, destinations, triage rubric) must be reflected in the vault spec and committed before deployment. Cron definitions are generated from that spec, not hand-edited. Even if generation isn't automated in Phase B, this is policy — violations are spec drift.

### 3.7 Feedback Verb Contract

The feedback reply listener (§3.2) needs a defined behavioral interface — the set of reply verbs, their actions, and logging.

| Verb | Input Format | Action | Routing | Log Entry |
|------|-------------|--------|---------|-----------|
| `investigate` | `!feed investigate` (reply to digest item) | Flag item, write to Crumb inbox (`_openclaw/inbox/feed-intel-investigate-<date>.md`) with YAML frontmatter | Crumb picks up in next session | `feedback.jsonl`: `{verb, item_id, timestamp}` |
| `ignore` | `!feed ignore` | Deboost topic/source in triage scoring | Tess processes locally, writes weight adjustment | `feedback.jsonl` |
| `more` | `!feed more` | Boost topic/source weight in triage scoring | Tess processes locally, writes weight adjustment | `feedback.jsonl` |
| `mute <source>` | `!feed mute @techcrunch` | Suppress source from future capture | Tess processes locally, writes to source config | `feedback.jsonl` + config change logged |
| `deeper` | `!feed deeper` | Re-run attention on item with expanded depth | Tess queues for next attention run | `feedback.jsonl` |

Each verb produces: a state change (scoring weight, source config, or Crumb inbox file), a log entry in `_openclaw/state/feed-intel-feedback.jsonl`, and a Telegram acknowledgment ("Got it — boosted [topic]").

Unrecognized verbs get a help message: "Available: investigate, ignore, more, mute <source>, deeper".

### 3.8 Cron Guardrails and Failure Handling

**Locking and overlap prevention:**
- Single-flight lock (file lock) per pipeline stage — no overlapping runs
- Max wall time per job: capture 10 min, attention 15 min, digest 5 min. Jobs exceeding the limit are killed and logged as failures.

**Missed-run catch-up policy:**
- If Mac Studio was asleep at scheduled time, run on wake if missed within 4 hours
- If multiple days missed, backfill up to 2 days, then skip older — don't generate mega-digest
- If attention runs without fresh capture data, skip and log (don't triage stale content)

**Degraded state definitions:**

| State | Trigger | Mechanic Response |
|-------|---------|-------------------|
| Capture degraded | Capture job failed 2 consecutive days | Log, alert in morning briefing: "Feed-intel capture degraded — run manually or investigate" |
| Attention degraded | Triage job failed 2 consecutive days | Log, alert in morning briefing |
| Delivery degraded | Digest generated but no Telegram message confirmed | Log, alert — check delivery config |
| Pipeline paused | Any single stage fails 3 consecutive runs | Auto-pause that stage, require human un-pause via Telegram command or Crumb session |

### 3.9 Cost and Limits

**Per-run caps:**
- Capture: no LLM cost (shell/API calls only)
- Attention/triage: max 30k tokens per run (Haiku 4.5)
- Digest delivery: single Haiku call, strict output length (max 5k tokens)

**Per-day cap:** Hard daily ceiling of $1.50 equivalent for all feed-intel operations. If breached, Tess pauses triage, notes in morning briefing "feed-intel paused due to cost cap," mechanic logs to cost report.

**Weekly cost report:** Mandatory (included in mechanic's standard health checks). Reported in morning briefing every Monday: total tokens, cost, items processed, signal quality score.

## 4. What Changes in the Spec

The feed-intel-framework spec (v0.3.5) doesn't need major revision. The architecture is already designed for cron-driven, autonomous execution. The changes are:

1. **§1 Problem Statement** — Add: "The pipeline's operational runtime is Tess (OpenClaw). Crumb governs design and evolution."
2. **§4 Architecture Overview** — Add a note: capture and attention clocks are Tess cron jobs, not Crumb-initiated sessions
3. **New §X: Operational Ownership Model** — Document the Tess/Crumb split table from §2 above
4. **§13 Phasing** — Add deployment notes: post-M2 live migration, pipeline runtime transitions from x-feed-intel launchd services to OpenClaw cron jobs

These are additive amendments, not structural rewrites. A spec patch (v0.3.6), not a new version.

## 5. What Changes in Tess's Configuration

### HEARTBEAT.md additions — machine-checkable health signals:

The mechanic checks these signals on every heartbeat cycle. Alerts route to Telegram and morning briefing.

| Signal | Source | Alert Threshold |
|--------|--------|----------------|
| `last_capture_run_at` | Capture job log / timestamp file | >25 hours since last successful run |
| `last_attention_run_at` | Attention job log / timestamp file | >25 hours since last successful run |
| `queue_depth` | Capture output directory item count | >50 items unprocessed (tunable) |
| `last_successful_delivery_at` | Telegram delivery confirmation log | >25 hours since last delivery |
| `last_processed_feedback_at` | Feedback queue log | >48 hours if feedback exists in queue |
| `error_rate_by_adapter` | Per-adapter error counts | >3 consecutive failures per adapter |
| `daily_token_spend` | Cost telemetry log | Exceeds daily cap (§3.9) |

Each signal has a canonical source file. The mechanic reads the source, compares against the threshold, and alerts on breach. No vague "check status" — every check is a comparison against a defined threshold.

### Cron jobs (added after M2 live migration):
- `feed-intel-capture` — daily at 06:00 ET
- `feed-intel-attention` — daily at 07:30 ET
- `feed-intel-cost-report` — weekly Monday 09:00 ET (mandatory, per §3.9)

### Mechanic agent additions:
- Feed-intel health signals (table above) added to service monitoring checklist
- Disk usage for feed-intel SQLite DB + vault files
- Degraded state detection and auto-pause per §3.8

### Morning briefing context injection:

Because triage runs in `--session isolated`, the morning briefing agent has no context about what was triaged. The morning briefing cron job or prompt must explicitly include a step to read the latest feed-intel digest file. Additionally, the morning briefing template includes a "feed-intel status" line: last run time, item count, health status (from the signals table above).

## 6. Migration Path

This isn't a flag day. It's a phased transition that piggybacks on work already planned.

### Phase A: Complete M2 (current work)
FIF-028 (live migration) and FIF-029 (parity gate) finish the x-feed-intel → framework migration. This is already in progress and doesn't change.

### Phase B: Transition runtime to Tess (post-M2)

**Prerequisite gate:** Phase B begins only after the chief-of-staff spec §14 Week 1 gate is satisfied (5 days of stable heartbeat, morning briefing, vault health, pipeline monitoring). This ensures the underlying Tess infrastructure is proven before adding the feed-intel workload.

1. Retire x-feed-intel launchd services (capture-clock, attention-clock, feedback-listener)
2. Add OpenClaw cron jobs for capture and attention clocks (explicit JSON payloads per §3.2)
3. Configure heartbeat-based feedback processing (§3.2, §3.7)
4. Add feed-intel health signals to mechanic heartbeat (§5)
5. Add feed-intel status line to morning briefing template (§5)
6. Run both in parallel for 3 days (launchd + cron), verify identical behavior
7. Disable launchd services, cron is now authoritative

### Phase C: Evolve under new ownership model
- New adapters (RSS, YouTube) developed by Crumb, deployed to Tess
- Triage prompt iterations: Crumb edits + benchmarks, Tess runs updated prompts
- Web UI (M-Web) built by Crumb, served from Studio, Tess manages deployment health

## 7. What This Unlocks

**For Tess's chief-of-staff role:**
- Feed-intel becomes her first real operational workload beyond relay
- Proves the cron + heartbeat + Telegram delivery pattern for future workloads
- Builder ecosystem monitoring (from earlier research) uses the same pipeline architecture
- "Investigate" action becomes a natural Tess → Crumb handoff protocol

**For Crumb:**
- Sheds operational toil (no more "remember to run the pipeline")
- Focuses on design, synthesis, and vault governance — his actual strengths
- Deep synthesis of routed content becomes a distinct, intentional activity rather than a side effect of running the pipeline

**For the system as a whole:**
- Clean separation of concerns: always-on operations (Tess) vs. governed design (Crumb)
- Pattern for future ownership splits: any operational workload that Crumb builds can be handed to Tess once stable
- Validates the two-agent architecture for production workloads

## 8. Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Tess cron misses a run (crash, restart) | Mechanic heartbeat detects stale cursors within 60 min. Framework has retry + idempotency baked in. |
| Triage quality degrades without oversight | Weekly cost report includes signal quality score. Operator reviews digest daily. Feedback loop adjusts weights. |
| Spec drift between what Tess runs and what Crumb governs | Pipeline reads config from vault specs at runtime. Spec is single source of truth. No fork possible. |
| Context pressure in voice agent from pipeline work | Use `--session isolated` for all cron jobs. Pipeline never touches conversational context. |
| Credential rotation breaks pipeline | Mechanic health check detects API errors within 60 min. Alert Danny. |
| Framework bug needs fixing | Crumb fixes and deploys. Tess picks up changes on next cron cycle. Standard code → deploy → run flow. |

## 9. Open Questions

1. ~~**Feedback listener runtime model.**~~ **Resolved:** Heartbeat polling for Phase B (§3.2). Upgrade path to webhook documented.

2. ~~**Lobster workflow vs. raw cron.**~~ **Resolved:** Phase B uses raw cron jobs. Lobster can be evaluated as a future optimization but is not a dependency (§3.2).

3. **x-feed-intel project status.** After Phase B migration and successful 3-day parallel run, mark x-feed-intel as ARCHIVED in project-state.yaml with a pointer to `feed-intel-framework`. Preserves history while clearly indicating the project is no longer active.

4. **Project governance.** Does `feed-intel-framework` stay as a Crumb project with Tess as runtime? Or does it need a new project classification? Current project-state.yaml tracks it as a software project in TASK phase — this seems fine since Crumb still governs the design/code lifecycle.

---

## Decision Requested

This proposal reframes feed-intel's operational home without changing its architecture, codebase, or governance model. The code is already on the Studio. The runtime primitives (cron, heartbeat, Telegram) are already in Tess. The split is clean.

Want to:
1. Adopt this as the operating model going forward (informal — no spec change yet)?
2. Formalize as a spec amendment (v0.3.6) now?
3. Defer until M2 completes and revisit at Phase B?
