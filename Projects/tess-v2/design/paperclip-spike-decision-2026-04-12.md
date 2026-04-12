---
project: tess-v2
type: decision
domain: software
status: active
created: 2026-04-12
updated: 2026-04-12
skill_origin: manual
task_ref: TV2-045
tags:
  - architecture
  - scaling
  - external-evaluation
related:
  - design/paperclip-relevance-check-2026-04-06.md
  - design/services-vs-roles-analysis.md
---

# TV2-045 Decision: Paperclip Integration Spike

## Summary Recommendation

**Defer.** Paperclip's adapter architecture is more opinionated than prior analysis assumed. It does not offer a generic dispatch surface (Bash, HTTP, or webhook adapter) — every adapter is tied to a specific agent runtime. tess-v2's Python contract runner doesn't fit any existing adapter shape. Integration would require writing a custom adapter, which reintroduces the paradigm mismatch the peer review flagged as CRITICAL. None of the three scaling triggers are firing. There is no justified reason to invest further.

## Evidence

### Stage 0 Findings (bail triggered)

The spike executed Stage 0 (Install + Schema Audit) and bailed at the checkpoint.

| Finding | Detail |
|---------|--------|
| **Bash adapter does not exist** | Prior memo and web research claimed adapters for "Claude Code, Codex, Cursor, Bash, and HTTP." Actual adapters in `packages/adapters/`: `claude-local`, `codex-local`, `cursor-local`, `gemini-local`, `openclaw-gateway`, `opencode-local`, `pi-local`. No generic Bash, HTTP, or webhook adapter. Every adapter is runtime-specific. |
| **Version unchanged** | Still `v2026.403.0` (Apr 4). No new release in 8 days despite "weekly calver" claim from the Apr 6 memo. Development pace may have slowed. |
| **npm package confirmed** | `paperclipai` on npm, version `2026.403.0`. Install command `npx paperclipai onboard --yes` verified correct. |

### 5-Criteria Evaluation

Evaluated at the architectural level based on Stage 0 adapter analysis. No hands-on integration test was possible without writing a custom adapter.

| Criterion | Verdict | Reasoning |
|-----------|---------|-----------|
| **(a) Vault authority** | Not testable | No adapter exists that can call tess-v2's CLI without custom glue. Custom adapter reintroduces paradigm mismatch. |
| **(b) Contract verification** | Not testable | Same — adapter gap blocks testing. |
| **(c) Scheduling ownership** | **FAIL (architectural)** | Paperclip's model assumes it owns the agent runtime via its adapter. tess-v2 uses macOS LaunchAgents for scheduling. These are fundamentally different scheduling models. Coexistence creates a dual-scheduler with duplicate execution risk. |
| **(d) Dashboard visibility** | Unknown | Would require running Paperclip instance, which depends on adapter integration. Dashboard value is moot without a viable adapter path. |
| **(e) State ownership** | **FAIL (architectural)** | Paperclip expects to track task lifecycle (checkout, progress, completion) through its adapter contract. tess-v2's Ralph loop independently tracks iteration budget, failure classification, and terminal outcomes (STAGED/ESCALATED/DEAD_LETTER). No mapping exists without a translation layer, creating dual-master state. |

### Abstraction Collision Inventory

1. **Adapter model mismatch.** Paperclip adapters wrap agent runtimes (Claude Code sessions, Codex processes, Cursor instances). tess-v2 is not an agent runtime — it's an orchestration system with its own dispatch queue, contract lifecycle, and staging engine. Paperclip wants to be the orchestrator; tess-v2 already is one.

2. **Dual scheduler.** Paperclip schedules via heartbeats to its adapters. tess-v2 schedules via LaunchAgent plists with `StartInterval`. Running both creates two independent systems deciding when work runs.

3. **Dual state machine.** Paperclip tracks task states (assigned → in-progress → completed/failed). tess-v2's Ralph loop tracks iteration states (dispatched → evaluated → STAGED/ESCALATED/DEAD_LETTER). These state machines overlap but don't align. Neither can be made advisory-only without losing its core function.

4. **Budget enforcement overlap.** Paperclip enforces per-agent budgets with hard-stop auto-pause. tess-v2 has its own bursty cost model with $75/month ceiling and per-contract token budgets. Layering both creates authority ambiguity.

## Cost/Benefit Matrix

| Capability | Paperclip | tess-v2 already has | Delta |
|------------|-----------|---------------------|-------|
| Task dispatch | Role-based, adapter-mediated | Contract-based, LaunchAgent-driven | Different paradigm, not additive |
| Budget enforcement | Per-agent, hard-stop | Per-contract, bursty cost model | Overlap — conflict risk |
| Approval gates | Board-style governance | Gate 3 risk policy + PENDING_APPROVAL | Overlap — authority ambiguity |
| Dashboard | React UI, real-time | `tess history` CLI + SQLite + health digest | **Paperclip advantage** — only genuine add |
| Scheduling | Heartbeat-based | LaunchAgent plists (OS-level) | Dual-scheduler risk |
| Retry/failure | Task-level retry | Ralph loop with failure classification (DETERMINISTIC/REASONING/TOOL/SEMANTIC) | tess-v2 significantly richer |
| Staging/promotion | None | Atomic 12-step promotion, hash verification, crash recovery | tess-v2 unique — Paperclip has nothing comparable |
| Audit trail | Activity log, immutable records | Contract execution ledger, session reports, run history DB | Comparable |

**Net assessment:** Paperclip's only genuine addition is the dashboard. Everything else either overlaps with existing tess-v2 capabilities or conflicts with them. The dashboard alone does not justify the integration cost and ongoing maintenance of a custom adapter against a fast-moving, bus-factor-1 dependency.

## Patterns Worth Copying Locally

If tess-v2 ever needs these capabilities, Paperclip's design is useful reference material — but direct adoption is not the path.

| Pattern | Paperclip approach | Local build consideration |
|---------|-------------------|--------------------------|
| Dashboard | React + PGlite, real-time task view | When triggered: lightweight web UI over tess-v2's existing SQLite DBs (run-history, session-reports). Estimated: 1-2 day build. |
| Dependency-wake semantics | Event-driven dependency graphs with wake-on-completion | Relevant for Amendment Z Phase B planning service. Watch as reference, don't adopt. |
| Hierarchical roles | Org chart model, role-based delegation | Only needed when scaling triggers fire. tess-v2's contract model already supports sub-orchestrators as executors. |
| Adapter heartbeat pattern | "If it can receive a heartbeat, it's hired" | Interesting for multi-runtime coordination. Not needed at current scale. |

## Scaling Trigger Status (updated 2026-04-12)

| Trigger | Status | Evidence |
|---------|--------|----------|
| Domain depth exceeds summarization | **Not firing** | 14 services running, no domain requires its own orchestrator. Firekeeper Books not at production scale. |
| Concurrent workstreams need independent judgment | **Not firing** | Single orchestrator (Tess) handles all coordination. No serialization bottleneck reported. |
| Context window becomes bottleneck | **Not firing** | 16K/32K envelope budgets have headroom. No contract hitting token ceiling. |

## Conditions for Revisiting

1. **Any scaling trigger fires** — re-evaluate sub-orchestrator need (could be Paperclip, could be native build)
2. **Paperclip ships a generic adapter** (Bash, HTTP, or webhook) — removes the primary integration barrier
3. **Firekeeper Books reaches production scale** — first named candidate for sub-orchestrator, per services-vs-roles analysis
4. **Dashboard need becomes acute** — if `tess history` CLI proves insufficient for operational visibility, a native dashboard build is cheaper than Paperclip integration

## Next state-check: ~2026-07-12 (90 days)

## Spike Cost

- **Planned:** ~4.5 hours (5 stages)
- **Actual:** ~45 minutes (Stage 0 only + decision doc)
- **Outcome:** Bail at Stage 0 checkpoint — adapter architecture incompatible with tess-v2's execution model. Early bail validated the staged approach design.

## Prior Art

- `design/paperclip-relevance-check-2026-04-06.md` — desk analysis, correctly predicted deferral but overestimated adapter availability
- `design/services-vs-roles-analysis.md` — three scaling triggers (unchanged, none firing)
- `Projects/tess-v2/reviews/2026-04-12-paperclip-spike-plan.md` — 4-model peer review of spike plan
