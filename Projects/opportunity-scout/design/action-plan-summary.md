---
project: opportunity-scout
domain: software
type: summary
skill_origin: action-architect
created: 2026-03-14
updated: 2026-03-14
source_updated: 2026-03-14
tags:
  - automation
  - tess
  - openclaw
---

# Opportunity Scout — Action Plan Summary

## Structure

20 atomic tasks across 4 milestones (M0–M3), 11 phases. M4 (Steady State) is operational with no implementation tasks.

| Milestone | Tasks | Phase(s) | Key Risk |
|-----------|-------|----------|----------|
| M0: Source + Scoring Validation | OSC-001–009 (9 tasks) | 1–4 | Haiku triage quality (A2) |
| M1: First Digest Production | OSC-010–016 (7 tasks) | 5–8 | Pipeline reliability, live deployment iteration (Pattern 4) |
| M2: Feedback Loop + Calibration | OSC-017–018 (2 tasks) | 9–10 | Behavioral adoption — project's existential gate (A1) |
| M3: Monthly Evaluation | OSC-019–020 (2 tasks) | 11 | Low risk |

## Critical Path

```
OSC-001/002 (parallel) → OSC-003 → OSC-004/005 (parallel) → OSC-009 → OSC-010 → OSC-012 → OSC-013 → OSC-014/015 (parallel) → OSC-016 → OSC-017 → OSC-018 → OSC-019
```

## High-Risk Tasks

- **OSC-012 (pipeline script):** HIGH — idempotency, run IDs, data retention, multi-component coordination
- **OSC-013 (LaunchAgent + multi-model):** HIGH — live deployment iterations (Pattern 4), error isolation
- **OSC-017 (30-day behavioral validation):** HIGH — project's existential gate. Abort if <20% engagement

## Key Changes from r1 Peer Review

- Split OSC-012 (pipeline) into OSC-012 (script) + OSC-013 (LaunchAgent) — all 4 reviewers flagged
- Split OSC-013 (feedback) into OSC-014 (poller) + OSC-015 (commands) — 3 reviewers flagged
- Fixed OSC-005 dependency: interface contract only, not full RSS adapter (enables parallelism)
- Added OSC-009 → OSC-010 dependency (M0 gates M1)
- Added OSC-011 → OSC-016 dependency (soak validates heartbeat/alerts)
- Feedback poller is persistent process (LaunchAgent), not cron — ≤60s latency impossible with 1-min cron resolution
- 21/30-day mismatch resolved: OSC-017 is 30-day window with 21-day interim checkpoint
- Config/secrets scaffolding added to OSC-002
- ACs tightened: agreement metric defined (exact match ≥43/50), ingestion path validation, alert false-positive distinction

## Parallelization Opportunities

- **M0 Phase 1:** OSC-001 + OSC-002 (independent workstreams)
- **M0 Phase 2:** OSC-004 + OSC-005 (parallel after interface contract, not sequential)
- **M0 Phase 3:** OSC-006 + OSC-008 (independent, both need OSC-001)
- **M1 Phase 7:** OSC-014 + OSC-015 can overlap once poller core is stable
- **M3 Phase 11:** OSC-019 + OSC-020 (independent)
