---
type: summary
domain: software
status: draft
created: 2026-02-19
updated: 2026-02-19
source: Projects/crumb-tess-bridge/design/specification.md
source_updated: 2026-02-19
project: crumb-tess-bridge
tags:
  - openclaw
  - security
  - integration
---

# Crumb–Tess Bridge — Specification Summary

## Problem
Crumb is session-bound — it only works when a human starts a terminal session. The user needs to approve phase gates, check status, and delegate tasks from a phone via Telegram, using Tess (OpenClaw) as transport. This creates a new Telegram → Tess → Crumb → governed vault write path that materially changes the colocation threat model.

## Core Design Decisions

1. **Tess is transport, Crumb is governance.** Tess never interprets intent or makes approval decisions. She relays structured requests and waits for user confirmation.
2. **Confirmation echo with hash-bound confirmation** is the primary security control. Every write-escalation request echoes the exact JSON payload with a `payload_sha256[:12]` confirmation code. User must reply `CONFIRM <code>` — bare CONFIRM is rejected.
3. **Phased approach:** Phase 1 (async file exchange) → Phase 2 (automated async via file watcher) → Phase 3 (hardening). Phase 1 protocol is reused in Phase 2 — only the transport changes.
4. **Operation allowlist** bounds the blast radius. Phase 1: approvals + status queries. Phase 2 adds task delegation.
5. **Model B4 (launchd file watcher)** is the recommended execution model for Phase 2 — eliminates the cross-user execution problem by keeping Claude Code in the primary user's domain. B4 is automated async (not synchronous real-time); true real-time deferred.

## Key Unknowns

| ID | Unknown | Impact | Resolution Path |
|----|---------|--------|-----------------|
| U1 | Crumb execution model — 4 candidates (A-D), recommending B4 | Blocks Phase 2 architecture | Research task CTB-001 |
| U2 | Claude Code `--print` mode capabilities | Blocks Phase 2 feasibility | Research task CTB-001 |
| U3 | Session lifecycle under automation | Blocks Phase 2 implementation | Research task CTB-001 |
| U5 | File-watch latency | Affects Phase 2 responsiveness | Research task CTB-009 |
| U6 | Token cost per bridge session | Affects Phase 2 viability at scale | Research task CTB-010 |
| U7 | **Claude Code session concurrency (CRITICAL)** | Phase 2 blocker — bridge + interactive sessions share `~/.claude/` | Research task CTB-011 prereq |

## Threat Model (Bridge-Specific)

| Threat | Rating | Key Mitigation |
|--------|--------|----------------|
| BT1. Injection surviving confirmation echo (compromised account) | HIGH | Phase 1 scope limits + rate limiting |
| BT2. Echo bypass via injection formatting | MEDIUM | Hash-bound confirmation code, canonical JSON serialization |
| BT3. Governance degradation in automated sessions | HIGH | Two-tier verification: runner-side hash check + in-session canary + output schema validation |
| BT4. Transcript injection / log poisoning | MEDIUM | Crumb writes own transcripts + run-log as authority |
| BT5. Bridge flooding / DoS | LOW | Rate limiting, confirmation as natural throttle |
| BT6. NLU misparse / ambiguous intent | HIGH | JSON-in-echo (hard requirement), hash-bound confirmation, strict field validation |
| BT7. Tess process compromise | HIGH | Operation allowlist, schema validation, kill-switch file, runner-side rate limits |

## Protocol Highlights (R1 additions)

- **UUIDv7 message IDs** — time-ordered, globally unique, idempotent via `.processed-ids` log
- **`payload_hash`** — `sha256(canonical_json(operation+params))[:12]` ties echo→confirm→inbox
- **Schema versioning** — `schema_version: "1.0"` in all messages
- **Original message preservation** — raw user text/STT transcript logged alongside parsed request
- **Processed file handling** — inbox files moved to `.processed/` (not deleted) after handling

## Task Summary

14 tasks across 3 phases. Phase 1 critical path: CTB-001 → CTB-003 → CTB-004/005/006 → CTB-007. Three research tasks (CTB-001, CTB-009, CTB-010) can start immediately in parallel. Phase 2 is blocked on Phase 1 validation + research resolution + U7.

## R1 Peer Review Status

Round 1 complete (2026-02-19). 3 reviewers: GPT-5.2, Gemini 3 Pro Preview, Perplexity Sonar Reasoning Pro. 5 must-fix findings applied:
- A1: BT6 added (NLU misparse), JSON-in-echo hardened to hard requirement
- A2: BT3 rewritten with two-tier governance verification
- A3: Hash-bound confirmation codes + UUIDv7 idempotency throughout schema
- A4: U7 added (session concurrency — critical Phase 2 blocker)
- A5: BT7 added (Tess process compromise + kill-switch)

Review note: `_system/reviews/2026-02-19-crumb-tess-bridge-spec.md`

## Open Questions for R2 Peer Review

Five author notes (AN1–AN5) are included in the spec. AN1–AN3 document R1 resolutions; AN4–AN5 are new R2 questions:
- AN4: Is `pgrep -f claude` sufficient for session concurrency detection, or should the runner use a lockfile?
- AN5: Should the bridge have a separate auth token between runner and inbox (shared secret, rotated)?

## Next Actions

1. Peer review round 2 (diff mode — review R1 changes only)
2. Resolve research unknowns (CTB-001, CTB-002, CTB-009) in parallel
3. Advance to PLAN phase after R2 findings addressed
