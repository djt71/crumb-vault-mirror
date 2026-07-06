---
type: reference
domain: software
status: active
created: 2026-03-07
updated: 2026-07-05
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
| XD-005 | MC Customer: Relationship Heat Map | Google/Apple integration | — | not yet scoped | blocked | No upstream project exists. (AS-030 2026-06-14: reviewed — kept as dormant MC backlog, not teardown-mooted; dormant while MC paused.) |
| XD-007 | MC Customer: Comms Cadence | Google/Apple integration | — | not yet scoped | blocked | No upstream project exists. (AS-030 2026-06-14: reviewed — kept as dormant MC backlog, not teardown-mooted; dormant while MC paused.) |
| XD-009 | MC Knowledge: Decision Journal | Decision journal impl | — | not yet scoped | blocked | No upstream project exists. (AS-030 2026-06-14: reviewed — kept as dormant MC backlog, not teardown-mooted; dormant while MC paused.) |
| XD-019 | MC Customer: Relationship Heat Map (XD-005) | Google Workspace MCP access | mcp-workspace-integration | MWI-005 (concurrent access validated) | blocked | MCP integration provides the Google/Apple integration XD-005 was waiting on (Google side). Apple side still unscoped. (Upstream survives — Google Workspace MCP is now native/live; dormant while MC paused.) |
| XD-020 | MC Customer: Comms Cadence (XD-007) | Google Workspace MCP access | mcp-workspace-integration | MWI-005 (concurrent access validated) | blocked | Same as XD-019 — Google side addressed by MCP integration. (Upstream survives; dormant while MC paused.) |
| XD-021 | pydantic-ai-adoption ADR §2.2 resolution | MCP feasibility findings | mcp-workspace-integration | MWI-002 (spike validation) | blocked | Spike results resolve the feasibility brief that ADR §2.2 deferred. (Upstream survives.) |
| XD-027 | vault-optimization VO-031/032 (B4/B5 primitive batches) + VO-026/033 (ceremony changeset/batch) | CLAUDE.md diff, skills+memory cleanup, directory archival complete | agentic-sunset | AS-025–029 (M6) | pending | Boundary settled at VO TASK (2026-06-10): VO-010–030 proceed during AS M3–M5; VO-031/032 blocked on Appendix A ownership matrix frozen (VO-016) + AS M6 sign-off in AS run-log; VO-026/033 additionally on AS-025. AS-side now satisfied: AS M6 (AS-025–029) complete 2026-06-12 + AS-021 reboot passed 2026-06-14 — VO-031/032 now gated only on VO-016. See Projects/vault-optimization/tasks.md. |

## Mooted (resolved)

| ID | Blocked Item | Waiting On | Upstream Project | Upstream Task/Milestone | Status | Notes |
|----|-------------|------------|-----------------|------------------------|--------|-------|
| XD-001 | MC Ops: Operational Efficiency panel | Self-optimization loop | tess-operations | not yet scoped | mooted | MOOTED AS-030 2026-06-14: tess-operations decommissioned (agentic-sunset); MC dashboard paused. |
| XD-002 | MAD Phase 3 (H4): cold artifact availability | New Scout candidates, new signal notes | opportunity-scout, feed-intel-framework | Live pipeline output | mooted | Cold artifacts needed for Phase 3 synthesis testing. MOOTED AS-030 2026-06-14: FIF live pipeline frozen/dead — no new pipeline output; MAD Phase 3 experiment shelved. |
| XD-003 | A2A: deliberation capability integration | Validated deliberation framework | multi-agent-deliberation | MAD-016 (H5 gate pass) | mooted | MOOTED AS-030 2026-06-14: A2A decommissioned; deliberation is now a native Crumb skill — no A2A integration target. |
| XD-022 | MC Ops: Tempo panel | Tempo adaptation | tess-operations | not yet scoped | mooted | MOOTED AS-030 2026-06-14: tess-operations decommissioned; MC dashboard paused. |
| XD-023 | MC Ops: Degradation panel | Degradation-aware routing | tess-operations | not yet scoped | mooted | MOOTED AS-030 2026-06-14: tess-operations decommissioned; MC dashboard paused. |
| XD-024 | tess-v2 Phase 4 (Migration) | Platform + LLM evaluation results | tess-v2 | TV2-006, TV2-011 | mooted | MOOTED AS-030 2026-06-14: tess-v2 closed DONE; migration delivered via tess-danny-migration and the Tess layer is decommissioned. |
| XD-025 | tess-operations: service continuity | tess-v2 migration complete | tess-v2 | TV2-019 | mooted | MOOTED AS-030 2026-06-14: both tess-operations and tess-v2 decommissioned. |
| XD-004 | MC Intel: Tuning panel | FIF feedback analysis | feed-intel-framework | not yet scoped | mooted | MOOTED AS-030 2026-06-14: feed-intel-framework decommissioned; MC dashboard paused. |
| XD-006 | MC Customer: Pre-Brief | A2A Workflow 3 | agent-to-agent-communication | A2A Phase 2-3 | mooted | MOOTED AS-030 2026-06-14: A2A decommissioned; MC dashboard paused. |
| XD-008 | MC Agent Activity: Session Cards | TOP-047 | tess-operations | TOP-047 | mooted | MOOTED AS-030 2026-06-14: tess-operations decommissioned. |
| XD-010 | MC Phase 4 (M11-M13) | A2A feedback/approval | agent-to-agent-communication | A2A-003, A2A Phase 2-3 | mooted | Delivery layer exists (M1/M2 live). MOOTED AS-030 2026-06-14: A2A decommissioned. |
| XD-011 | MC M-Web absorption (MC-053) | — | feed-intel-framework | FIF M-Web tasks | mooted | FIF tasks superseded, amendment not yet applied. MOOTED AS-030 2026-06-14: feed-intel-framework decommissioned. |
| XD-012 | MC A2A absorption (MC-053) | — | agent-to-agent-communication | A2A-015.x | mooted | A2A tasks superseded. MOOTED AS-030 2026-06-14: A2A decommissioned. |
| XD-013 | MC M9: Skill telemetry | skill-telemetry.jsonl | crumb (system) | convention not yet spec'd | mooted | Tess-side emission is tess-operations dependency. MOOTED AS-030 2026-06-14: tess-side emission dead + MC dashboard paused. A native skill-telemetry convention could be revisited independently if ever needed. |
| XD-016 | TOP-046 reactive stream (§8.1) | `research` triage action in dashboard | mission-control | MC-068 | mooted | TOP-046 scheduled streams (§8.2/§8.3) can proceed without MC-068. MOOTED AS-030 2026-06-14: TOP-046 (tess-operations) decommissioned — the blocked item itself is dead. |
| XD-017 | MC-067 action_class display | Daily artifact action_class field | autonomous-operations | AO-002 | mooted | MC-067 reads daily artifact; action_class was an additive field. MOOTED AS-030 2026-06-14: autonomous-operations decommissioned. |
| XD-018 | AO Phase 2 task registry | Replay log schema stability | autonomous-operations | AO-001 complete + Phase 1 exit | mooted | MOOTED AS-030 2026-06-14: autonomous-operations decommissioned. |

## Resolved Dependencies

| ID | Blocked Item | Resolution | Date |
|----|-------------|-----------|------|
| XD-014 | MC Daily Attention panel (MC-067) | AM-003 done, schema live. MC-067 registered as consumer. | 2026-03-09 |
| XD-015 | Tess morning briefing — daily attention (TOP-055) | AM-003 done. TOP-055 registered. | 2026-03-09 |
| XD-026 | tess-danny-migration P7 closeout (DONE-superseded) | agentic-sunset executed tess-plist retirement: daemon teardown (AS-013/014) + tess/openclaw user-domain LaunchAgent archival (AS-022) + reboot resurrection verification (AS-021). tess-danny-migration closed DONE under AS-030; the mooted-row sweep this row called for was completed in the same task (XD-001/002/003/004/006/008/010/011/012/013/016/017/018/022/023/024/025 → mooted). | 2026-06-14 |

## Future Integration (deferred)

- **Morning briefing (Tess):** Scan for rows where upstream project's recent run-log contains a milestone completion matching the "Waiting On" column. Requires structured milestone data in run-logs — not yet available.
- **Attention aggregator (MC-030):** Scan this file as a source — blocked dependencies where the upstream just completed something become attention items. Deferred until Mission Control M4.
