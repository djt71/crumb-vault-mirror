---
type: task
project: x-feed-intel
domain: software
skill_origin: action-architect
created: 2026-02-23
updated: 2026-02-23
tags:
  - action-plan
---

# X Feed Intel — Action Plan

## Planning Inputs

- Specification v0.4.2 (governance-reviewed, 2 rounds of 5-model peer review)
- Governance notes: G-04 (type taxonomy), G-05 (directory structure), G-06 (Node.js/TypeScript), G-08 (outbox dependency soft)
- Solution pattern: `claude-print-automation-patterns.md` Pattern 4 — budget 3-6 iterations for first live deployment of structured output (applies to triage prompt)
- Implementation language decision: **Node.js / TypeScript** — aligns with OpenClaw stack, shared dependency ecosystem, Keychain access via `keytar` or native bindings, launchd scheduling. Recorded as ADR-001. Resolves governance note G-06.

## Milestone 0: Foundation & Validation (Phase 0)

**Goal:** Verify API connectivity, benchmark data quality, refine topic queries, establish project scaffold.

**Size: S** — Scaffolding, account setup, and benchmark scripts. Mostly boilerplate + API integration.

**Success criteria:**
- Pipeline repo exists with TypeScript project scaffold and passing type checks
- SQLite schema created with all 5 tables (§7.2 + digest_item_map), WAL mode enabled
- Telegram bot verified working (send + receive)
- TwitterAPI.io account exists with credits and API key in Keychain
- X API OAuth flow completes, tokens stored in Keychain
- ~200 bookmarks and ~200 search results per topic collected
- TwitterAPI.io search operator support documented
- Thread heuristic fields documented
- Topic queries refined based on benchmark review
- Labeled benchmark set captured as `xfi-triage-benchmark-YYYYMMDD.json` for Phase 2 drift validation
- Vault directory structure (`_openclaw/feeds/`, `_openclaw/config/`) created
- `type: x-feed-intel` registered in vault type taxonomy

**Tasks:** XFI-001 through XFI-009, XFI-00A, XFI-00B, XFI-00C *(optional: dev/test harness)*

**Estimated cost:** ~$1–2 (benchmark API pulls)

**Key risk:** XFI-004 (OAuth complexity) and XFI-006 (search operator support unknown). Both are validation tasks — failures here shape Phase 1 design, not block it.

**Optional: XFI-00C (dev/test harness)** — Record API responses from benchmark runs as fixture files; add dry-run mode flag that reads fixtures instead of live APIs; fake Telegram sink logs to file. Enables offline development and prompt iteration without consuming API credits. Recommended if prompt engineering iterations will be intensive.

---

## Milestone 1: Capture Clock (Phase 1a)

**Goal:** Automated daily extraction of bookmarks and search content into a normalized, deduplicated pending queue.

**Size: M** — Five components with API integration, scheduling, and error handling. Normalizer is the foundational piece.

**Success criteria:**
- Bookmark puller runs daily at 6 AM, authenticates via OAuth, handles token refresh failures
- Topic scanner runs per-topic schedule, applies config-level filters, deduplicates per-run
- Normalizer (medium risk — foundational data model) converts both API formats to unified schema with canonical_id, thread heuristic, append-only matched_topics
- Global dedup engine prevents re-queuing of known posts, updates source_instances on re-encounter
- Capture clock runs via launchd with retry and error logging
- Partial success handled (one source down doesn't block the other)

**Tasks:** XFI-010 through XFI-014

**Dependencies:** Milestone 0 complete (repo, schema, API verification, topic config, Telegram + TwitterAPI.io accounts)

---

## Milestone 2: Attention Clock (Phase 1b)

**Goal:** Daily triage of pending items, vault routing for high-signal content, and Telegram digest delivery.

**Size: L** — Seven tasks including triage prompt engineering (highest-risk deliverable). Budget 3-6 prompt iterations. This is likely the longest milestone.

**Success criteria:**
- Vault snapshot generated with ≤600 tokens, fallback rules operational
- Triage engine processes batches of 10-20 posts via Haiku 4.5 with structured output
- Per-post failure isolation works (malformed output → individual retry → triage_failed)
- Triage prompt validated against labeled benchmark sample: structural checks (JSON parse, schema fields) + semantic eval (≥N of 20 items match operator-assigned priority/tags) with 2+ iteration cycles
- Vault router places crumb-architecture items in `_openclaw/inbox/` with correct frontmatter
- Idempotent writes with operator notes protection
- Daily digest delivered to Telegram with high/medium/low sections, item IDs, cost footer
- Digest item ID → canonical_id mapping persisted for feedback loop correctness
- Degraded mode notes included when upstream source failed
- Cost telemetry tracks per-run, MTD, and projected costs
- Attention clock runs daily at 7 AM via launchd

**Tasks:** XFI-015 through XFI-021, XFI-019b (digest item mapping)

**Dependencies:** Milestone 1 complete (pending queue populated), Milestone 0 XFI-009 (refined benchmark sample for prompt validation)

**Key risk:** XFI-016/XFI-017 (triage prompt engineering) is the highest-uncertainty deliverable. Budget 3-6 iterations per Pattern 4 from `claude-print-automation-patterns.md`.

---

## Milestone 3: Feedback & Operations (Phase 1c)

**Goal:** Complete feedback loop via Telegram replies, cost guardrails, queue health enforcement, and operational documentation.

**Size: M** — Seven tasks but mostly straightforward: command parsing, threshold logic, monitoring, and documentation. Lower uncertainty than M2.

**Success criteria:**
- All 5 feedback commands work (promote, save, ignore, add-topic, expand placeholder)
- `expand` recognized but returns "Phase 2 — not yet available"
- Promote uses conditional confirmation via routing bar
- Save stages to `_openclaw/feeds/kb-review/` with save_reason frontmatter
- All feedback logged to feedback table
- Cost guardrail activates at 90% of $6 budget, reverts at 80%
- Queue health: 7-day search expiry, 30-day bookmark expiry, backlog summary at 50+ pending, alert at 100+
- Pipeline liveness check runs independently, alerts on 24h gap
- Runtime operations guide covers OAuth re-auth, topic config editing, alert response per type, launchd plist inventory, troubleshooting with explicit checklists

**Tasks:** XFI-022 through XFI-028

**Dependencies:** Milestone 2 complete (digest exists for replies, triage data for routing)

---

## Dependency Graph

The visual graph below is a simplification — it shows the primary dependency flow, not every cross-link. **The task table (`tasks.md`) is authoritative for dependencies.**

```
M0: Foundation & Validation
├── XFI-001 (scaffold) ─┬── XFI-002 (schema) ──┬── XFI-005 (bookmark benchmark)
│                        ├── XFI-003 (config)   │
│                        └── XFI-004 (OAuth) ───┘
│                                                 ├── XFI-006 (search benchmark)
│   XFI-00A (Telegram)                            ├── XFI-007 (thread fields)
│   XFI-00B (TwitterAPI.io) ──── XFI-006          └── XFI-009 (operator review)
│   XFI-008 (vault dirs — Crumb-governed)
│
M1: Capture Clock
├── XFI-010 (normalizer) ─┬── XFI-011 (bookmark puller) ──┐
│                          ├── XFI-012 (topic scanner) ────┤
│                          └── XFI-013 (dedup engine) ─────┤
│                                                          └── XFI-014 (scheduling)
│
M2: Attention Clock
├── XFI-015 (vault snapshot) ──┐
├── XFI-020 (cost telemetry) ──┤
│   M1 XFI-013 (dedup) ────────┤
│                               ├── XFI-016 (triage engine)
│                               │     └── XFI-017 (prompt engineering)
│                               ├── XFI-018 (vault router)
│                               └── XFI-019 (digest) ─┬── XFI-021 (scheduling)
│                                                      └── XFI-019b (item ID mapping)
│
M3: Feedback & Operations
├── XFI-022 (feedback listener + daemon) ─┬── XFI-023 (promote)
│                                 ├── XFI-024 (save/ignore/add-topic)
│                                 └── XFI-025 (cost guardrail)
├── XFI-026 (queue health)
├── XFI-027 (liveness check)
└── XFI-028 (ops guide)
```

## Notes

- **Phase 2 and 3 are out of scope for this plan.** They will be planned separately after Phase 1 stabilizes.
- **Triage prompt engineering (XFI-017)** is budgeted for multiple iterations. Do not treat first-attempt output as final.
- **Operator tasks (XFI-009)** require Danny's manual review of benchmark data. This is a blocking dependency for triage prompt validation in M2.
- **Vault-side work (XFI-008)** is independent of pipeline repo work and can run in parallel with M0 API tasks. Must run in a Crumb session — it's governed vault modification.
- **External prerequisites:** X Developer Account (Danny creates), TwitterAPI.io account (XFI-00B), Telegram bot verification (XFI-00A) must all be complete before capture clock components can run.
- **XFI-014 may need splitting at TASK phase.** Peer review flagged scope bloat (launchd plists + runner orchestration + retry logic + error handling in one task). Monitor during TASK entry — if >5 files, split into XFI-014a (runner logic + retry/backoff) and XFI-014b (launchd plists + install scripts).

## launchd Process Inventory

The pipeline runs as **5 independent launchd-managed processes**, not a single daemon. Each gets its own plist:

| Process | Task | Schedule | Type | Plist |
|---------|------|----------|------|-------|
| Capture clock | XFI-014 | Daily 6 AM + per-topic frequency | Periodic (StartCalendarInterval) | `ai.openclaw.xfi.capture.plist` |
| Attention clock | XFI-021 | Daily 7 AM | Periodic (StartCalendarInterval) | `ai.openclaw.xfi.attention.plist` |
| Feedback listener | XFI-022 | Continuous | Daemon (KeepAlive: true) | `ai.openclaw.xfi.feedback.plist` |
| Liveness check | XFI-027 | Daily (separate from above) | Periodic (StartCalendarInterval) | `ai.openclaw.xfi.liveness.plist` |
| Queue health + expiry | XFI-026 | Daily (or tied to attention chain) | Periodic (StartCalendarInterval) | `ai.openclaw.xfi.queuehealth.plist` |

**Cost guardrail (XFI-025)** runs inline as a pre-check within the capture clock — it reads the cost_log before each scanner invocation and adjusts max_results. It does not need its own plist.

This inventory should be documented in XFI-028 (ops guide) so the operator knows what's running and how to manage each process.
