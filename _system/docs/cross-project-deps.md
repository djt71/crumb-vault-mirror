---
type: reference
domain: software
status: active
created: 2026-03-07
updated: 2026-03-07
tags:
  - system
  - cross-project
---

# Cross-Project Dependencies

Tracks specific, directional blocking relationships between projects with resolution tracking.

**Distinct from `related_projects`** in `project-state.yaml`: `related_projects` captures general affinity between projects (bidirectional, informational). This file captures specific blocking relationships — item X cannot proceed until upstream project Y completes task Z — with status tracking and resolution dates.

## Maintenance

**When to add rows:** During action-architect or systems-analyst work that creates a cross-project dependency. Also when a spec amendment references another project's deliverable, a peer review identifies a missing dependency, or the operator directs a feature that depends on upstream work.

**When to update rows:** When upstream project completes the referenced task (status -> resolved, move to Resolved table). When upstream project scopes previously unscoped work (update task ID). When a design change eliminates the dependency (status -> removed).

**Who maintains it:** Crumb, during the skill invocations that create or resolve dependencies (action-architect, systems-analyst). Operator can update directly for decisions made outside Crumb sessions.

## Active Dependencies

| ID | Blocked Item | Waiting On | Upstream Project | Upstream Task/Milestone | Status | Notes |
|----|-------------|------------|-----------------|------------------------|--------|-------|
| XD-001 | MC Ops: Operational Efficiency panel | Self-optimization loop | tess-operations | not yet scoped | blocked | |
| XD-002 | MAD Phase 3 (H4): cold artifact availability | New Scout candidates, new signal notes | opportunity-scout, feed-intel-framework | Live pipeline output | pending | Cold artifacts needed for Phase 3 synthesis testing. Start collecting early. |
| XD-003 | A2A: deliberation capability integration | Validated deliberation framework | multi-agent-deliberation | MAD-016 (H5 gate pass) | pending | Integration deferred until experiment validates. |
| XD-022 | MC Ops: Tempo panel | Tempo adaptation | tess-operations | not yet scoped | blocked | |
| XD-023 | MC Ops: Degradation panel | Degradation-aware routing | tess-operations | not yet scoped | blocked | |
| XD-024 | tess-v2 Phase 4 (Migration) | Platform + LLM evaluation results | tess-v2 | TV2-006, TV2-011 | gated | Migration design and execution gated by evaluation go/no-go decisions |
| XD-025 | tess-operations: service continuity | tess-v2 migration complete | tess-v2 | TV2-019 | pending | Existing TOP services must maintain continuity during tess-v2 migration. No service interruption. |
| XD-004 | MC Intel: Tuning panel | FIF feedback analysis | feed-intel-framework | not yet scoped | blocked | |
| XD-005 | MC Customer: Relationship Heat Map | Google/Apple integration | — | not yet scoped | blocked | No upstream project exists |
| XD-006 | MC Customer: Pre-Brief | A2A Workflow 3 | agent-to-agent-communication | A2A Phase 2-3 | blocked | |
| XD-007 | MC Customer: Comms Cadence | Google/Apple integration | — | not yet scoped | blocked | No upstream project exists |
| XD-008 | MC Agent Activity: Session Cards | TOP-047 | tess-operations | TOP-047 | blocked | |
| XD-009 | MC Knowledge: Decision Journal | Decision journal impl | — | not yet scoped | blocked | No upstream project exists |
| XD-010 | MC Phase 4 (M11-M13) | A2A feedback/approval | agent-to-agent-communication | A2A-003, A2A Phase 2-3 | gated | Delivery layer exists (M1/M2 live) |
| XD-011 | MC M-Web absorption (MC-053) | — | feed-intel-framework | FIF M-Web tasks | pending | FIF tasks superseded, amendment not yet applied |
| XD-012 | MC A2A absorption (MC-053) | — | agent-to-agent-communication | A2A-015.x | pending | A2A tasks superseded, amendment not yet applied |
| XD-013 | MC M9: Skill telemetry | skill-telemetry.jsonl | crumb (system) | convention not yet spec'd | blocked | Tess-side emission is tess-operations dependency |
| XD-016 | TOP-046 reactive stream (§8.1) | `research` triage action in dashboard | mission-control | MC-068 | blocked | TOP-046 scheduled streams (§8.2/§8.3) can proceed without MC-068. Only the FIF reactive intake path requires the dashboard research action. |
| XD-017 | MC-067 action_class display | Daily artifact action_class field | autonomous-operations | AO-002 | pending | MC-067 reads daily artifact. action_class is an additive field — non-breaking. Dashboard can optionally display routing indicators once AO-002 ships. |
| XD-018 | AO Phase 2 task registry | Replay log schema stability | autonomous-operations | AO-001 complete + Phase 1 exit | gated | Phase 2 task registry extends the SQLite schema from AO-001. Schema must be stable (14-day operation) before Phase 2 design begins. |
| XD-019 | MC Customer: Relationship Heat Map (XD-005) | Google Workspace MCP access | mcp-workspace-integration | MWI-005 (concurrent access validated) | blocked | MCP integration provides the Google/Apple integration XD-005 was waiting on (Google side). Apple side still unscoped. |
| XD-020 | MC Customer: Comms Cadence (XD-007) | Google Workspace MCP access | mcp-workspace-integration | MWI-005 (concurrent access validated) | blocked | Same as XD-019 — Google side addressed by MCP integration. |
| XD-021 | pydantic-ai-adoption ADR §2.2 resolution | MCP feasibility findings | mcp-workspace-integration | MWI-002 (spike validation) | blocked | Spike results resolve the feasibility brief that ADR §2.2 deferred. |

## Resolved Dependencies

| ID | Blocked Item | Resolution | Date |
|----|-------------|-----------|------|
| XD-014 | MC Daily Attention panel (MC-067) | AM-003 done, schema live. MC-067 registered as consumer. | 2026-03-09 |
| XD-015 | Tess morning briefing — daily attention (TOP-055) | AM-003 done. TOP-055 registered. | 2026-03-09 |

## Future Integration (deferred)

- **Morning briefing (Tess):** Scan for rows where upstream project's recent run-log contains a milestone completion matching the "Waiting On" column. Requires structured milestone data in run-logs — not yet available.
- **Attention aggregator (MC-030):** Scan this file as a source — blocked dependencies where the upstream just completed something become attention items. Deferred until Mission Control M4.
