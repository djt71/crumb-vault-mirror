---
type: summary
project: x-feed-intel
domain: software
skill_origin: action-architect
created: 2026-02-23
updated: 2026-02-23
source_updated: 2026-02-23
tags:
  - action-plan
---

# X Feed Intel — Action Plan Summary

## Core Content

The action plan decomposes the x-feed-intel spec v0.4.2 into 4 milestones and 32 tasks (1 optional) covering Phase 0 (validation) and Phase 1 (core pipeline). Phases 2 and 3 are out of scope — they'll be planned after Phase 1 stabilizes. Post-peer-review (5 models, 10 action items applied): dependency fix for XFI-006, tightened AC for XFI-017, new digest item mapping task (XFI-019b), WAL mode for SQLite concurrency, launchd daemon for feedback listener, normalizer risk elevated, M1→M2 dependency encoded, benchmark set capture for drift validation, ops guide AC enumerated, launchd plist inventory documented.

**Milestone 0 — Foundation & Validation (Size: S):** 12 tasks (1 optional). Scaffold the Node.js/TypeScript pipeline repo (ADR-001), set up SQLite schema, verify Telegram bot, set up TwitterAPI.io account, implement OAuth and API connectivity, run benchmark pulls (~200 bookmarks + ~200 search results per topic), verify search operators and thread fields, create vault directory structure (Crumb-governed), and get Danny's sign-off on query quality. Estimated API cost: $1-2.

**Milestone 1 — Capture Clock (Size: M):** 5 tasks. Build the normalizer, bookmark puller, topic scanner, and global dedup engine. Wire them into a scheduled capture clock via launchd (daily bookmarks at 6 AM, topic scanner per-config frequency) with retry, error logging, and partial-success handling.

**Milestone 2 — Attention Clock (Size: L):** 8 tasks. Build the vault snapshot generator, triage engine (Haiku 4.5 batch mode, depends on M1 data), triage prompt (2-3 iteration cycles), vault router, daily Telegram digest with persistent item ID mapping (XFI-019b), cost telemetry, and attention clock scheduling via launchd (daily 7 AM). Triage prompt engineering is the highest-risk deliverable — likely the longest milestone.

**Milestone 3 — Feedback & Ops (Size: M):** 7 tasks. Build the Telegram feedback listener as a KeepAlive daemon (all 5 commands, item IDs resolved via digest_item_map), cost guardrail ($6/month ceiling), queue health monitoring with differentiated expiry, pipeline liveness check, and runtime operations guide (enumerated runbooks). Pipeline runs as 5 independent launchd processes (capture, attention, feedback daemon, liveness, queue health).

## Key Decisions

- **Language:** Node.js/TypeScript — aligns with OpenClaw stack. Recorded as ADR-001. Resolves governance note G-06.
- **Scheduling:** launchd (not cron) — Mac Studio native service management
- **Triage risk:** Budget 3-6 prompt iterations per `claude-print-automation-patterns.md` Pattern 4
- **Operator gate:** XFI-009 (benchmark review) is a blocking dependency for triage prompt validation — Danny must review results before M2 begins
- **Vault governance:** XFI-008 handles G-04 (type taxonomy) and G-05 (directory structure) as a Crumb-governed task, parallelizable with API work

## Interfaces & Dependencies

- M0 → M1: Repo scaffold, schema, API verification, topic config, Telegram + TwitterAPI.io accounts must exist
- M0 XFI-009 → M2 XFI-017: Refined benchmark sample needed for prompt validation
- M1 XFI-013 → M2 XFI-016: Pending queue must be populated (explicit cross-milestone dep encoded in task table)
- M2 → M3: Digest must exist for feedback listener; triage data needed for routing commands
- XFI-008 (vault dirs) has no external dependencies — can run in parallel with all M0 API tasks
- External prerequisites: X Developer Account (Danny creates), TwitterAPI.io account (XFI-00B), Telegram bot verification (XFI-00A)

## Next Actions

- Apply peer review findings (done — 5-model review, 10 action items applied)
- Present plan for approval
- On approval: begin XFI-001 (repo scaffold), XFI-008 (vault dirs), XFI-00A (Telegram verify), XFI-00B (TwitterAPI.io setup) in parallel
- XFI-004 (OAuth setup) requires Danny's X Developer Account — may be a blocking external dependency
