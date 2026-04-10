---
project: tess-operations
type: review-synthesis
domain: software
created: 2026-02-26
updated: 2026-02-26
status: active
tags:
  - tess
  - peer-review
  - feed-intel
  - specification
---

# Feed-Intel Ownership Proposal — Peer Review Synthesis

Consolidated findings from 4 independent peer reviews of the `tess-feed-intel-ownership-proposal.md`. Reviews conducted by DeepSeek, Gemini, ChatGPT, and Perplexity. Synthesis prepared by Claude Opus with editorial filtering for hallucination risk, signal quality, and alignment with existing spec content.

## Reviewer Verdict

All four reviewers recommend **adopting the proposal**. The ownership split (Tess runs operations, Crumb retains governance) is unanimously endorsed as the correct architectural decision. Disagreements are on implementation details, not direction.

## Review Quality Assessment

| Reviewer | Signal Quality | Key Strength | Key Weakness |
|----------|---------------|--------------|--------------|
| DeepSeek | Medium-high | Credential access nuance, chief-of-staff gate dependency, phasing discipline | "Broader implications" section restates what the proposal already says |
| Gemini | Low-medium | Isolated session → morning briefing context gap | Webhook recommendation unsupported, urgency to "adopt immediately" ignores phasing, invented terminology ("Session Paradox") |
| ChatGPT | High | Runtime Config Contract, feedback verb contract, cron guardrails, health signal specification | Pipeline-as-role-agents framing restates existing proposal with different labels |
| Perplexity | High | Telegram delivery gotchas (best unique finding), degraded state definitions, per-run cost caps with concrete numbers | External alignment section is validation, not new information |

**Methodology:** Same as the operational spec synthesis. Findings included only if they identify a genuine gap verified against the proposal text, were raised by 2+ reviewers or represent a clearly sound point from one, and are actionable. Hallucinated or unverifiable claims excluded.

---

## Tier 1 — Structural Gaps Worth Addressing Before PLAN

### 1.1 Runtime Config Contract

**Raised by:** ChatGPT (primary), Perplexity (supporting)
**Gap:** The proposal claims "pipeline reads config from vault specs at runtime" and "spec is single source of truth; no fork possible." This is aspirational without formalization. In practice, config can fragment across three locations: vault spec values, `.env`/JSON config under `/feed-intel-framework/`, and OpenClaw cron definitions (schedule, target chat ID).

**Recommended addition:** A "Runtime Config Contract" section specifying:

- `config_sources[]` — exact file paths the pipeline reads at runtime
- `schema_version` — how spec versions are tracked and validated
- `validation` — what happens on parse failure (fallback to last-good? hard fail?)
- `last_good_cache` — whether a known-good config snapshot is maintained
- `rollback behavior` — how to revert to a previous config state
- `atomic updates` — how partial reads are prevented during spec edits

**Enforcement rule (Perplexity):** Any change to feed-intel runtime behavior (schedule, destinations, triage rubric) must be reflected in the vault spec and committed before deployment. Cron definitions are generated from that spec, not hand-edited. Even if generation isn't automated in Phase B, make it policy now to prevent drift.

### 1.2 Telegram Delivery Mechanics

**Raised by:** Perplexity (primary)
**Gap:** The proposal assumes "cron job runs → pipeline runs → digest shows up in Telegram" but doesn't specify delivery mechanics. This is a documented OpenClaw failure mode: cron jobs execute successfully but don't deliver to Telegram because the session wasn't truly isolated, the delivery target wasn't specified in the payload, or the job relied on `systemEvent` instead of an explicit `agentTurn` with `delivery` settings.

**Recommended change to §3.2:** Replace bare `openclaw cron add ... --message` patterns with explicit JSON payloads that include:

- `sessionTarget: "isolated"` — mandatory for all feed-intel cron jobs
- `payload.kind: "agentTurn"` — not `systemEvent`
- `delivery` block with explicit `channel`, `to` (chat ID or topic), and `announce: true`

Do not rely on implicit HEARTBEAT routing for feed-intel delivery.

### 1.3 Feedback Verb Contract

**Raised by:** ChatGPT (primary)
**Gap:** The proposal describes a feedback reply listener and mentions an "Investigate" action, but doesn't define the full set of feedback verbs, their resulting actions, or the logging contract. The reply listener is a mechanism without a defined behavioral interface.

**Recommended addition:** A feedback DSL section defining:

| Verb | Action | Routing |
|------|--------|---------|
| `investigate` | Flag item, write to Crumb inbox (`_openclaw/inbox/feed-intel-investigate-<date>.md`) with YAML frontmatter | Crumb picks up in next session |
| `ignore` | Deboost topic/source in triage scoring | Tess processes locally |
| `more like this` | Boost topic/source weight | Tess processes locally |
| `mute <source>` | Suppress source from future capture | Tess processes locally, log to config |
| `summarize deeper` | Re-run attention on item with expanded depth | Tess queues for next attention run |

Each verb should have: input format, resulting state change, where it's logged, and how it's verified.

### 1.4 Machine-Checkable Health Signals

**Raised by:** ChatGPT (primary), Perplexity (supporting)
**Gap:** The proposal states "mechanic detects stale cursors within 60 minutes" but doesn't define what a cursor is, where the canonical indicator lives, or what the SLA is. Without defined metrics, the mechanic can't be tested.

**Recommended replacement for §5 health monitoring:** Define specific signals with thresholds:

| Signal | Source | Alert Threshold |
|--------|--------|----------------|
| `last_capture_run_at` | Capture job log / timestamp file | >25 hours since last successful run |
| `last_attention_run_at` | Attention job log / timestamp file | >25 hours since last successful run |
| `queue_depth` | Capture output directory item count | >N items unprocessed (tunable) |
| `last_successful_delivery_at` | Telegram delivery confirmation log | >25 hours since last delivery |
| `last_processed_feedback_at` | Feedback queue log | >48 hours if feedback exists in queue |
| `error_rate_by_adapter` | Per-adapter error counts | >3 consecutive failures per adapter |
| `daily_token_spend` | Cost telemetry log | Exceeds daily cap (see §1.6) |

Mechanic checks these on every heartbeat cycle. Alerts route to Telegram and morning briefing.

### 1.5 Cron Guardrails and Failure Handling

**Raised by:** ChatGPT (primary), Perplexity (supporting)
**Gap:** The proposal defines cron schedules but not the operational guardrails that make cron reliable for unattended execution.

**Recommended additions:**

**Locking and overlap prevention:**
- Single-flight lock (file lock or SQLite lock) per pipeline stage — no overlapping runs
- Max wall time per job + kill policy (e.g., capture: 10 min, attention: 15 min, digest: 5 min)

**Missed-run catch-up policy:**
- If Mac Studio was asleep at scheduled time, run on wake if missed within X hours (e.g., 4 hours)
- If multiple days missed, backfill up to N days (e.g., 2), then skip older — don't generate mega-digest
- If attention runs without fresh capture data, skip and log (don't triage stale content)

**Degraded state definitions (Perplexity):**

| State | Trigger | Mechanic Response |
|-------|---------|-------------------|
| Capture degraded | Capture job failed 2 consecutive days | Log, alert in morning briefing: "Feed-intel capture degraded — run manually or investigate" |
| Attention degraded | Triage job failed 2 consecutive days | Log, alert in morning briefing |
| Delivery degraded | Digest generated but no Telegram message confirmed | Log, alert — check delivery config |
| Pipeline paused | Any single stage fails 3 consecutive runs | Auto-pause that stage, require human un-pause via Telegram command or Crumb session |

---

## Tier 2 — Sound Hardening, Incorporate Selectively

### 2.1 Chief-of-Staff Gate Dependency

**Raised by:** DeepSeek
**Recommendation:** Phase B (ownership transition) begins only after the chief-of-staff spec §14 Week 1 gate is satisfied (5 days of stable briefing, alerts, heartbeat). This ensures the underlying Tess infrastructure is proven before adding the feed-intel workload. Add as an explicit dependency in §6.

### 2.2 Cost Caps with Automatic Behavioral Changes

**Raised by:** Perplexity (primary), ChatGPT (supporting)
**Recommendation:** Add a "Cost and Limits" subsection:

- **Per-run caps:** Attention/triage: max token ceiling per run (e.g., 30-50k); digest delivery: single Haiku call with strict output length
- **Per-day cap:** Hard daily token ceiling for all feed-intel operations (e.g., $1-2 equivalent)
- **Behavior on breach:** Tess stops triage, notes in morning briefing "feed-intel paused due to cost cap," mechanic logs to cost report
- **Weekly cost report:** Mandatory (not optional as currently specified), included in mechanic's standard health checks

### 2.3 Credential Access Detail

**Raised by:** DeepSeek (primary), ChatGPT (supporting)
**Gap:** Cron jobs running as `openclaw` user may not have an unlocked login keychain. macOS cron jobs typically cannot trigger keychain unlock prompts.

**Recommendation:** Document the chosen credential access approach:

- Option A: Store credentials in `openclaw` user's login keychain, ensure keychain unlocked at boot via launchd
- Option B: Environment variables in a secure file (600 permissions, owned by `openclaw`), sourced by cron scripts

Also document: which keychain items are needed, who can read them, how rotation/breakage is detected, and how secrets are kept out of logs.

### 2.4 Isolated Session → Morning Briefing Context

**Raised by:** Gemini (primary), Perplexity (supporting)
**Gap:** If triage runs in `--session isolated`, the morning briefing agent won't have context about what was triaged unless it explicitly reads the digest output.

**Recommendation:** The morning briefing cron job or prompt must explicitly include a step to read the latest feed-intel digest file. Additionally, add a "feed-intel status" line to the morning briefing template: last run time, item count, health status.

### 2.5 Feedback Listener Default

**Raised by:** All four reviewers (all recommend deciding now rather than deferring)

Three different recommendations were given:

| Reviewer | Recommendation | Reasoning |
|----------|---------------|-----------|
| DeepSeek | Heartbeat polling | Simplest, no new infrastructure, 30-min latency acceptable |
| Gemini | Webhook (`/hooks/wake`) | Real-time, cleanest UX |
| ChatGPT | Launchd | Proven, low novelty |
| Perplexity | Heartbeat + inbox pattern | Stays within OpenClaw patterns, `!feed` prefix → JSONL queue |

**Synthesis recommendation:** Choose **heartbeat polling** (DeepSeek/Perplexity approach) for Phase B. Rationale: requires no new infrastructure, stays within existing OpenClaw patterns, and 30-minute feedback latency is acceptable for a non-time-critical loop. Perplexity's refinement (tagged replies → JSONL queue → mechanic processes on heartbeat) adds useful implementation specificity. Document the upgrade path to webhook if latency becomes problematic.

---

## Tier 3 — Future Phases

### 3.1 Approval-Gated Delivery Tiers

**Raised by:** ChatGPT
**Assessment:** Distinguishing normal daily digest (auto-send) from sensitive/reputational content (approval required) from cost-spike runs (approval required) is architecturally sound but overengineering for Phase B. Revisit for Phase C+ when operational data shows whether false-positive digest content is a real problem.

### 3.2 Investigate → Subagent Spawning

**Raised by:** Gemini
**Assessment:** "Reply 'Investigate' → Tess spawns a subagent for 15 minutes of research → posts results to Discord" is the right long-term direction, but depends on Parallel Research Swarm (frontier idea #5) validation. For Phase B, `investigate` should simply flag the item and write it to Crumb's inbox per the feedback verb contract (§1.3).

### 3.3 x-feed-intel Project Status

**Raised by:** DeepSeek
**Recommendation:** After Phase B migration and successful 3-day parallel run, mark x-feed-intel as **ARCHIVED** in project-state.yaml with a pointer to `feed-intel-framework`. Preserves history while clearly indicating the project is no longer active.

### 3.4 Lobster Workflow Evaluation

**Raised by:** DeepSeek
**Recommendation:** Explicitly state that Phase B uses raw cron jobs. Lobster can be evaluated as an optimization in a future phase but is not a requirement or dependency for the ownership transition. Removes a potential blocker.

---

## Recommended Action Sequence

For the operator review before advancing to PLAN:

1. **Add Runtime Config Contract** (§1.1) — formalize what's read at runtime, validation behavior, and the enforcement rule against hand-editing cron definitions
2. **Rewrite cron examples with explicit delivery** (§1.2) — JSON payloads with `sessionTarget: "isolated"` and explicit `delivery` block; don't rely on implicit routing
3. **Define feedback verb contract** (§1.3) — the DSL of reply commands and their resulting actions
4. **Replace vague health monitoring with specific signals** (§1.4) — named metrics, thresholds, alert routing
5. **Add cron guardrails and degraded state definitions** (§1.5) — locking, catch-up policy, auto-pause rules
6. **Add chief-of-staff gate dependency** (§2.1) — Phase B begins after Week 1 gate
7. **Add cost caps section** (§2.2) — per-run and per-day limits with defined behavior on breach
8. **Pick heartbeat polling as feedback listener default** (§2.5) — document upgrade path to webhook
9. **Ensure morning briefing reads feed-intel digest** (§2.4) — explicit context injection for isolated sessions
10. **Document credential access approach** (§2.3) — keychain unlock or secure env file
