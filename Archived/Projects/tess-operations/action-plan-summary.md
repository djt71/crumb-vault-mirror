---
project: tess-operations
type: summary
domain: software
status: active
created: 2026-02-26
updated: 2026-02-27
source_updated: 2026-02-27
skill_origin: action-architect
tags:
  - tess
  - openclaw
  - operations
---

# tess-operations — Action Plan Summary

## Scope

52 tasks across 9 milestones + 1 cross-cutting protocol, transforming Tess from a Telegram relay to an active chief-of-staff operator with Google services, Apple services, multi-channel communications, feed-intel ownership, and an intelligence layer.

## Milestone Map

| Milestone | Description | Tasks | Depends On | Risk Profile |
|-----------|-------------|-------|------------|-------------|
| M0 | Infrastructure Foundation (Week 0) | TOP-001–005, TOP-050, TOP-051 | — | 1 high, 4 medium, 2 low |
| M1 | Chief-of-Staff MVP (Week 1) | TOP-006 to TOP-014 | M0 | 5 medium, 4 low |
| — | Approval Contract Protocol | TOP-049 | M1 gate | 1 high |
| M2 | Service Prerequisites (Phase 0s) | TOP-015 to TOP-026 | M1 gate | 3 high (OAuth, TCC, sudoers), 6 medium, 3 low |
| M3 | Read-Only Integration (Phase 1s) | TOP-027 to TOP-030 | M2 gates | 0 high, 3 medium, 1 low |
| M4 | Active Operations (Phase 2s) | TOP-031 to TOP-035 | M3 gates + TOP-049 | 0 high, 3 medium, 2 low |
| M5 | Advanced Operations (Phase 3s) | TOP-036 to TOP-041 | M4 gates | 3 high (sends, iMessage, cross-context), 1 medium, 2 low |
| M6 | Extended Capabilities (Phase 4s) | TOP-042 to TOP-043 | M5 gates | 1 high (iMessage send), 1 medium |
| M7 | Feed-Intel Ownership | TOP-044, TOP-052, TOP-045 | M1 gate + FIF M2 | 1 high, 1 medium, 1 low |
| M8 | Intelligence Layer | TOP-046 to TOP-048 | M1 gate | 0 high, 3 medium |

## Critical Path

```
TOP-001 (upgrade) → TOP-006/007 (heartbeat) → TOP-009 (briefing) → TOP-014 (Week 1 gate)
    → TOP-015/016 (Google OAuth) → TOP-027 (email in briefing) → TOP-030 (Phase 1 gate)
    → TOP-031 (triage) → TOP-035 (Phase 2 gate) → TOP-037 (email send) → TOP-041 (Phase 3 gate)
    → [2-WEEK STABILIZATION HOLD] → TOP-043 (iMessage send)
```

Estimated total timeline: **8-12 weeks minimum** from M0 start to M6 completion. The 2-week stabilization hold between email send and iMessage send is the longest single-segment delay on the critical path.

## Parallel Execution Windows

- **M2:** Google Phase 0 (TOP-015–018) | Apple Phase 0 (TOP-019–023) | Comms Phase 0 (TOP-024–026) — all independent
- **M3:** Google Phase 1 (TOP-027) | Apple Phase 1 (TOP-028) | Comms Phase 1 (TOP-029) — all independent
- **M4:** Google Phase 2 (TOP-031) | Apple Phase 2 (TOP-032–033) | Comms Phase 2 (TOP-034) — all independent
- **M7/M8:** Feed-intel monitoring (TOP-044), parallel verification (TOP-052), and intelligence tasks (TOP-046–048) can start after M1 gate, parallel with M2+
- **Approval Contract (TOP-049):** Can be built in parallel with M2/M3; must complete before M4

## Cost Envelope

| Phase | Monthly Estimate |
|-------|-----------------|
| M1 operational (chief-of-staff only) | $30–70 |
| M3+ (add Google + Apple + Comms) | $34–80 |
| M7+ (add feed-intel ownership) | $75–115 |
| Provider hard cap | $100/month |
| Rollback trigger | $120/month combined |

## High-Risk Tasks (10)

| ID | Description | Why High Risk |
|----|-------------|---------------|
| TOP-001 | OpenClaw upgrade | Infrastructure foundation — failure blocks everything |
| TOP-016 | Google OAuth cross-user flow | Novel credential pattern (file-backend + openclaw user) |
| TOP-019 | Sudoers entry for Apple CLIs | Security-sensitive: scoped privilege escalation |
| TOP-021 | TCC permission grants | Requires GUI session, non-automatable, macOS-update fragile |
| TOP-037 | Email send with enforcement | Write operation on Danny's email; technical enforcement critical |
| TOP-039 | iMessage search (BlueBubbles) | Full Disk Access + unverified BlueBubbles integration |
| TOP-040 | Multi-agent cross-context routing | New architectural component (local bridge for Discord) |
| TOP-043 | iMessage send | Highest-sensitivity write operation; requires proven send governance |
| TOP-045 | Feed-intel cron ownership | Operational ownership transfer with cost and reliability stakes |
| TOP-049 | Approval Contract protocol | Governance backbone — all Phase 2+ write operations depend on it |

## Key Planning Assumptions

1. **Live deployment iteration:** 3-6 iterations per new cron job pattern (per `claude-print-automation-patterns.md` Pattern 4). First heartbeat, briefing, and triage each need calibration.
2. **Gate durations:** 3 days each. Gate failures extend by 2 days. Two consecutive failures → descope and diagnose.
3. **Danny GUI session:** Studio Mac always logged in to Danny's account. Health check verifies.
4. **Feed-intel M2:** Must complete before TOP-045 (ownership transfer). Currently in TASK phase.
5. **BlueBubbles:** Must verify colocation inclusion before TOP-039. OpenClaw docs confirm recommendation but installation status unknown.
6. **Feed-intel framework M2:** External dependency — `Projects/feed-intel-framework/` must complete Milestone 2 (pipeline migration) before TOP-045. Currently in TASK phase.
7. **M1 morning briefing:** Week 1 briefing does NOT include calendar or reminders data — those require M3 (Google/Apple integration). Week 1 scope: vault status, pipeline health, project status, overnight alerts only.
8. **Parallel service cap:** Never advance more than 2 service families (Google, Apple, Comms) through Phase 1+ simultaneously. Phase 0 setup can run all 3 in parallel.
9. **Feed-intel parallel verification:** 3-day parity run (TOP-052) required between monitoring (TOP-044) and full ownership (TOP-045).
