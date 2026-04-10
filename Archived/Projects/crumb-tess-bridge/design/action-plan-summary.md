---
type: summary
domain: software
status: draft
created: 2026-02-19
updated: 2026-02-22
source: Projects/crumb-tess-bridge/design/action-plan.md
source_updated: 2026-02-22
project: crumb-tess-bridge
tags:
  - openclaw
  - security
  - integration
---

# Crumb–Tess Bridge — Action Plan Summary

## Structure

13 milestones, 31 tasks across Phase 1 (complete) and Phase 2 (dispatch implementation).

### Phase 1 (M1-M6) — Complete

| Milestone | Tasks | Focus | Status |
|-----------|-------|-------|--------|
| M1: Research & Unknowns | CTB-001, 002, 009, 010 | Resolve U1-U6 blocking unknowns | done |
| M2: Protocol Design | CTB-003 | JSON schema, allowlist, canonical serialization | done |
| M3: Phase 1 Implementation | CTB-004, 015, 005, 006 | Tess bridge skill + Crumb processor | done |
| M4: Phase 1 Validation | CTB-007, 008, 013 | E2E integration, injection testing, colocation | done |
| M5: Phase 2 Automation | CTB-011, 012 | File watcher, bridge runner, governance | done |
| M6: Peer Review | CTB-014, 016 | 4-model review + dispatch protocol design | done |

### Phase 2 (M7-M13) — Dispatch Protocol Implementation

| Milestone | Tasks | Focus |
|-----------|-------|-------|
| M7: Foundation | CTB-017, 018 | Schema extensions + dispatch state module |
| M8: Walking Skeleton | CTB-019, 020, 021 | Brief/prompt construction, stage runner, engine + routing |
| M9: Multi-Stage & Budget | CTB-022, 023 | Multi-stage lifecycle, budget enforcement, status updates |
| M10: Escalation & Cancel | CTB-024, 025 | Structured escalation flow, cancel-dispatch, kill-switch |
| M11: Tess Integration & Audit | CTB-026, 027 | Tess CLI dispatch support, audit hash, final response |
| M12: Validation | CTB-028 | E2E dispatch + injection tests — **gates Phase 2 daily use** |
| M13: Deferred Hardening | CTB-029, 030, 031 | Telegram alerts, Set optimization, sender allowlist |

## Phase 2 Critical Path

CTB-017 → CTB-019 → CTB-020 → CTB-021 → CTB-022 → CTB-024 → CTB-027 → CTB-028

Walking skeleton approach: single-stage dispatch works at M8, multi-stage at M9.
Early architectural validation before layering on controls. CTB-020 now sequential
after CTB-019 (needs prompt builder). CTB-027 after CTB-024 (needs multi-stage +
escalation data).

## Phase 2 Risk Distribution

- **High risk (4 tasks):** CTB-019 (prompt injection separation), CTB-020 (stage runner
  + governance), CTB-024 (escalation injection surface), CTB-028 (validation gate)
- **Medium risk (7 tasks):** CTB-017 (schema), CTB-018 (state machine + crash recovery),
  CTB-021 (engine), CTB-022 (budget), CTB-025 (cancel), CTB-026 (Tess CLI), CTB-027 (audit)
- **Low risk (4 tasks):** CTB-023 (status updates), CTB-029 (alerts),
  CTB-030 (optimization), CTB-031 (allowlist)

## Key Decision Points

1. **After M8 (CTB-021):** Does single-stage dispatch work? If `claude --print` + prompt
   construction reveals issues, we catch them before investing in multi-stage.
2. **After M12 (CTB-028):** Go/no-go on Phase 2 daily use. Injection tests must pass.
3. **Feature gap:** File transfer (PDF analysis via Telegram) identified in live testing —
   candidate for Phase 3 if demand validates.

## Immediate Next Steps

Two tasks can start in parallel with zero Phase 2 dependencies:
- CTB-017: Phase 2 schema extensions (medium risk, Tess-side)
- CTB-018: Dispatch state module (medium risk, Python)

CTB-029-031 (deferred hardening) are also independent — can interleave any time.

## Priority Signal

Live testing debrief (2026-02-22): `invoke-skill` is highest-value Phase 2 operation —
covers both file analysis and skill delegation. Walking skeleton targets invoke-skill first.
