---
project: agent-to-agent-communication
type: specification-summary
domain: software
status: reviewed
created: 2026-03-04
updated: 2026-03-04
source_updated: 2026-03-04
tags:
  - tess
  - openclaw
  - agent-communication
  - architecture
---

# Agent-to-Agent Communication — Specification Summary

## Problem

Danny manually routes work between Tess and Crumb. Multi-step workflows stall at human handoffs, preventing the agent ecosystem from compounding insights autonomously.

## Solution

Shift Tess into an orchestrator role: hold Danny's context, dispatch scoped work to Crumb, make intermediate decisions within defined authority, deliver artifacts through channel-agnostic delivery (Telegram now, mission control web UI planned, Discord future).

## Key Architectural Decisions

- **Channel-agnostic delivery layer** with 5 intents (notify, present, approve, feedback, converse) and pluggable adapters per channel. Channel-neutral artifact model: vault artifact first, adapters own truncation/formatting.
- **Mission control web UI** evolves from read surface → approval/status → full control plane
- **Three-tier HITL authority** (auto-approve, approval contract AID-*, always escalate) with mechanical enforcement (§9.2): tool guardrails, filesystem path allowlists, budget thresholds, approval token TTL/idempotency, kill switch
- **Sequential multi-dispatch** — Claude Code is single-threaded; "multi-dispatch" means sequential dispatches with Tess holding orchestration context across them. Generic dispatch-group infrastructure deferred to Phase 4 (conditional).
- **Distributed code** — orchestration lands where it belongs (OpenClaw skills, bridge, feed-intel), no standalone repo
- **Progressive trust** via 3-day gate evaluations per workflow
- **Capability-based skill dispatch (P7)** — workflows depend on capabilities (`domain.purpose.variant` ID format), not named skills. Skills declare capability manifests with rigor dimension; Tess resolves capability → skill at dispatch time. Brief schema registry (`_system/schemas/briefs/`) provides shared contracts. Exception: Workflow 1 (simple template-write, no capability dispatch)
- **Orchestration artifact lifecycle** — strict durable vs. ephemeral split with retention policy (30-day dispatch state archival, 90-day learning log archival)

## Four Core Workflows

1. **Feed Intel → Compound Insights** (Phase 1) — pipeline captures → Tess cross-references (tier-based selection: all T1 + T2 matching project tags) → Crumb writes insight → delivers. Minimum utility threshold from feedback.
2. **Research → Tess → Vault** (Phase 1b) — Tess formulates brief → resolves `research.external.*` capability → adaptive quality gate → delivers. Tess-initiated research capped at 3/day.
3. **SE Account Prep** (Phase 2) — sequential dispatch (`vault.query.facts` → `research.external.*`) → synthesis → pre-call brief. Deadline-aware scheduling from learning log averages.
4. **Vault Gardening** (Phase 3) — tiered auto-fix (purely additive only) / review / approval for vault health

## Build Order

- **Phase 1:** Delivery abstraction, context model (tiered staleness), feedback infra (mechanical coupling to learning log), Workflow 1 (with A/B Haiku vs Sonnet gate), gate
- **Phase 1b:** Capability manifest schema + brief schemas, skill manifests, capability resolution, quality schema (adaptive), escalation logic (with calibration), learning log, Workflow 2, critic skill
- **Phase 2** (realistic: Q2-Q3 2026): Mission control (read + feedback), account dossier schema, Workflow 3 (sequential dispatch), mission control (approvals)
- **Phase 3** (realistic: Q3 2026+): Gardening, retrospective, cost routing, stall detection, mission control (control)
- **Phase 4:** Multi-dispatch CTB-016 amendment (conditional), advanced patterns — each needs own spec cycle

## Key Dependencies

- crumb-tess-bridge: DONE ✓
- researcher-skill M5: DONE ✓ (promoted Workflow 2 to Phase 1b)
- feed-intel-framework M3: DONE ✓
- TOP-049 approval contract: blocks Tier 2 HITL (deep dependency chain through tess-ops M1-M3)
- TOP-027 calendar: blocks Workflow 3 (depends on tess-ops M2 Google integration)

## Task Count

25 tasks (A2A-001 through A2A-025) across 4 phases. Phase 4 task (A2A-025) is conditional.

## Open Questions

9 open questions + 11 deferred review items (§20.1). Key: orchestration logic hosting model, mission control tech stack, Sonnet cost (A/B comparison first).

## Review Status

Peer reviewed by 6 models (2026-03-04). 34 action items applied: 5 must-fix, 18 should-fix, 11 deferred.
