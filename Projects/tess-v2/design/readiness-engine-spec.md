---
type: design
status: draft
scope: general
created: 2026-04-01
updated: 2026-04-02
domain: software
skill_origin: external
project: tess-v2
tags:
  - architecture
  - scheduling
---

# Readiness Engine — Dependency Graph Scheduling Layer

> **Scope:** Generally applicable beyond tess-v2. Dependency-graph scheduling for contract sequencing is a reusable pattern for any multi-step autonomous system where downstream work depends on upstream outcomes. See `_system/docs/tess-v2-durable-patterns.md`.

**Spec Version:** 0.1.0-draft  
**Status:** Draft  
**Author:** Danny + Claude  
**Date:** 2026-04-01  
**Parent:** Tess v2 Architecture / Liberation Directive  
**Governs:** All agent-to-agent workflow composition  
**Target Phase:** Post-cutover (after Phase 4b)

> **Crumb Assessment (2026-04-02):** Architecturally sound — planning/scheduling separation, lease-based containment, SQLite state store are all correct. Temporally premature: the dependency graph becomes load-bearing when services start composing (FIF → Scout → briefing chains), which is Phase 5 work. Current Phase 4 services (heartbeats, vault gardening) are independent cron jobs that don't need DAG scheduling. Key gaps to resolve before implementation: (1) enumerate the concrete chains that justify a general DAG engine vs. purpose-built pipelines, (2) define contract ↔ work_item relationship, (3) confirm crumb-tess-bridge is truly subsumed vs. orthogonal. Open question #4: strongly recommend immutable graphs for V1. Open question #5: run-history.db pattern (built 2026-04-02) is the observability template.

---

## 1. Problem Statement

Tess v2 currently relies on the orchestrator (Kimi K2.5) for both **planning** (deciding what work to do) and **scheduling** (deciding when to execute it). This violates two Crumb design principles:

- **Mechanical enforcement over behavioral instructions.** Scheduling logic embedded in LLM prompts is subject to drift, hallucination, and the known tool-call loop bug (TV2-008). Scheduling is deterministic — it should be code, not conversation.
- **Ceremony Budget Principle.** The current standalone-pipeline approach (FIF, Attention Manager, Opportunity Scout on cron schedules) works for independent jobs but cannot express dynamic composition — e.g., "FIF found a high-signal opportunity → trigger Opportunity Scout → Tess generates a briefing, but only if the opportunity matches active account criteria." That chain requires a dependency graph, not a cron table.

As the architecture moves toward **agents-as-services**, every service-to-service chain is a DAG. The system needs a mechanical layer that resolves "what's ready to run next?" without asking an LLM.

---

## 2. Design Principles

1. **The graph is the source of truth.** The orchestrator's job is to *plan* the graph (create work items, declare edges). The Readiness Engine's job is to *resolve* the graph (determine what's runnable). These are separate concerns with separate failure modes.

2. **No LLM in the scheduling path.** The Readiness Engine is pure deterministic code. It cannot drift, hallucinate, or loop. If the orchestrator hangs, scheduling still works for everything already planned.

3. **Durable state, not in-memory state.** Waits, dependencies, and run status survive crashes and restarts. "Waiting" means a persisted record in a table, not a promise in memory.

4. **Single-node first.** This is designed for a Mac Studio, not a multi-tenant cloud. No CQRS, no event sourcing, no projection read-models. SQLite is the state store. The design should be *promotable* to Postgres later but must not require it now.

5. **Lease, don't lock.** Exclusive execution ownership via time-bounded leases with heartbeat renewal. Stale runs get reaped automatically — this is the containment boundary for TV2-008 and any future model misbehavior.

6. **Route by context dependency.** If a task needs the orchestrator's accumulated context to produce a good result, it should execute inline — serializing rich context into a JSON payload for a stateless executor is lossy and wasteful. If a task is self-contained given its payload, it should be delegated — isolation, independent failure, and parallelism are free. This is the fundamental routing heuristic.

---

## 3. Core Primitives

### 3.1 Work Items

A **work_item** is a unit of plannable work. It is the node in the dependency graph.

```
work_items
├── id              TEXT PRIMARY KEY (ULID)
├── session_id      TEXT NOT NULL        -- groups items into a workflow session
├── kind            TEXT NOT NULL        -- e.g., "fif_scan", "opportunity_score", "tess_briefing"
├── status          TEXT NOT NULL        -- planned | ready | running | completed | failed | cancelled
├── payload         TEXT (JSON)          -- input data for the executor
├── result          TEXT (JSON)          -- output data after completion
├── created_at      TEXT NOT NULL        -- ISO 8601
├── updated_at      TEXT NOT NULL
├── ttl_seconds     INTEGER              -- max allowed execution time before lease reap
└── retry_count     INTEGER DEFAULT 0
```

**Status transitions:**

```
planned ──→ ready ──→ running ──→ completed
                  │          └──→ failed ──→ ready (retry)
                  └──→ cancelled
```

- `planned`: has unresolved inbound edges. Cannot run yet.
- `ready`: all inbound edges satisfied. Eligible for execution.
- `running`: claimed by an executor via lease.
- `completed` / `failed` / `cancelled`: terminal states.

The transition from `planned` → `ready` is the Readiness Engine's core responsibility.

### 3.2 Edges

An **edge** declares a dependency between two work items.

```
work_item_edges
├── id              TEXT PRIMARY KEY (ULID)
├── source_id       TEXT NOT NULL REFERENCES work_items(id)  -- upstream (must complete first)
├── target_id       TEXT NOT NULL REFERENCES work_items(id)  -- downstream (blocked until source completes)
├── condition       TEXT (JSON)          -- optional: only satisfied if source result matches condition
└── created_at      TEXT NOT NULL
```

An edge from A → B means "B cannot become ready until A is completed."

**Conditional edges** allow branching: the `condition` field is a JSON expression evaluated against the source work_item's `result`. If the condition evaluates to false, the edge is treated as satisfied (the downstream item doesn't need to wait for it). This enables patterns like "only run Opportunity Scout if FIF found items above threshold X."

```json
// Example condition: source result must have opportunities with score > 0.7
{ "op": "exists", "path": "$.opportunities[?(@.score > 0.7)]" }
```

If `condition` is null, the edge is unconditional — downstream waits for upstream completion regardless of result content.

### 3.3 Runs

A **run** is a single execution attempt against a work item. A work item may have multiple runs (retries).

```
runs
├── id              TEXT PRIMARY KEY (ULID)
├── work_item_id    TEXT NOT NULL REFERENCES work_items(id)
├── executor        TEXT NOT NULL        -- "kimi", "nemotron", "local_script", etc.
├── status          TEXT NOT NULL        -- claimed | running | completed | failed
├── started_at      TEXT
├── completed_at    TEXT
├── lease_id        TEXT                 -- current lease holder
├── lease_expires   TEXT                 -- ISO 8601; null if not leased
├── heartbeat_at    TEXT                 -- last heartbeat from executor
├── error           TEXT (JSON)          -- failure details if failed
└── output          TEXT (JSON)          -- execution output, promoted to work_item.result on completion
```

### 3.4 Wait Entries

A **wait_entry** represents a durable pause — the run cannot continue until an external condition is met.

```
wait_entries
├── id              TEXT PRIMARY KEY (ULID)
├── run_id          TEXT NOT NULL REFERENCES runs(id)
├── wait_type       TEXT NOT NULL        -- "child_run" | "human_input" | "external_api" | "timer"
├── target_ref      TEXT                 -- e.g., child run ID, API callback ID
├── status          TEXT NOT NULL        -- pending | resolved | expired
├── resolved_at     TEXT
├── result          TEXT (JSON)          -- resolution payload
├── expires_at      TEXT                 -- optional TTL for the wait itself
└── created_at      TEXT NOT NULL
```

When a run creates a wait entry, the run moves to `waiting` status (an extension of `running` — the lease is maintained but the executor is paused). The Readiness Engine monitors wait entries and resumes the run when all waits for that run are resolved.

---

## 4. The Readiness Engine

### 4.1 Core Loop

The Readiness Engine is a **poll loop** (not event-driven). It runs on a configurable interval (default: 1 second for interactive workflows, 30 seconds for background pipelines).

Each tick:

```
1. PROMOTE READY ITEMS
   For each work_item with status = "planned":
     - Collect all inbound edges (where target_id = this item)
     - For each edge:
       - If source work_item status = "completed":
         - If edge has no condition → edge is satisfied
         - If edge has condition → evaluate against source result
       - If source work_item status = "cancelled" → edge is satisfied (skip path)
       - If source work_item status = "failed" and no retry pending → edge blocks (propagate failure)
       - Otherwise → edge is not yet satisfied
     - If ALL inbound edges are satisfied → transition to "ready"

2. REAP STALE LEASES
   For each run where lease_expires < now():
     - Release the lease
     - If run.retry_count < max_retries:
       - Increment retry_count on work_item
       - Set work_item.status = "ready" (re-eligible for claiming)
       - Set run.status = "failed" with error = "lease_expired"
     - Else:
       - Set work_item.status = "failed"
       - Set run.status = "failed"

3. RESOLVE WAITS
   For each wait_entry with status = "pending":
     - Check resolution condition by wait_type:
       - child_run: target run completed/failed?
       - human_input: input received? (checked via external flag)
       - external_api: callback received?
       - timer: expires_at reached?
     - If resolved → set wait_entry.status = "resolved", populate result
   For each run in "waiting" status:
     - If all wait_entries for this run are resolved → resume run

4. EXPIRE WAITS
   For each wait_entry where expires_at < now() and status = "pending":
     - Set status = "expired"
     - Handle per policy (fail the run, or treat as resolved-with-timeout)
```

### 4.2 Claim Protocol

When an executor wants to pick up work:

```
1. SELECT work_items WHERE status = "ready" ORDER BY priority, created_at
2. Attempt to claim: INSERT run with lease_id, lease_expires = now() + ttl_seconds
3. SET work_item.status = "running"
4. On success → executor begins work
5. On conflict → another executor claimed it; retry with next item

Heartbeat:
- Executor sends heartbeat every ttl_seconds / 3
- Readiness Engine updates lease_expires = now() + ttl_seconds on heartbeat
- If heartbeat stops → lease expires → item becomes re-claimable (step 2 in core loop)
```

For single-node operation, contention is minimal — but the protocol is correct for future multi-worker promotion.

---

## 5. Orchestrator Integration

### 5.1 Kimi's Role (Planning + Inline Execution)

The orchestrator has two modes of engagement with work items:

**Planning mode:** Kimi receives a planning prompt and outputs a **graph plan** — a schema-constrained JSON structure declaring work items and edges. This is Kimi's primary function.

**Inline execution mode:** Some work items should be executed by the orchestrator itself rather than delegated to an external executor. The deciding factor is **context dependency** — if the task requires the orchestrator's accumulated thread context (upstream results, session history, user preferences) and produces a decision or transformation rather than a heavy compute artifact, serializing that context into a payload for an external executor adds overhead for no gain.

Work items eligible for inline execution:

- **Sub-planning.** A plan that needs a sub-plan. Rather than spawning a child work item to "plan phase 2," Kimi just thinks longer within the current turn.
- **Triage and classification.** "Is this FIF result worth escalating?" "Does this opportunity match active account criteria?" Judgment calls against context Kimi already holds.
- **Context synthesis.** Merging results from completed upstream work items into a coherent summary, briefing draft, or decision. The orchestrator has the thread context; delegating means losing it.
- **Routing decisions.** Deciding which executor should handle a downstream item when routing is conditional on payload characteristics or upstream results.
- **Light reformatting and templating.** Reshaping structured output from a completed work item for a specific surface (Obsidian note, notification, morning briefing block) when it's just slotting values into a known template.
- **Human wait interpretation.** When a `human_input` wait resolves, the orchestrator interprets the response and decides what happens next. This is inherently orchestrator-level reasoning.

Work items that should **not** be inline:

- Schema-constrained repetitive tasks (scoring, extraction, classification at scale) → Nemotron
- External API calls and data fetching (FIF scans, tool calls) → local scripts
- Any task where failure should be isolated from the orchestrator's thread → delegated executor

The inline/delegate distinction is declared in the executor registry (see §5.2) and can be overridden per work item in the graph plan.

**Graph plan output:**

```json
{
  "session_id": "sess_01J...",
  "work_items": [
    {
      "id": "wi_01",
      "kind": "fif_scan",
      "payload": { "sources": ["x", "rss", "youtube"], "filters": ["ai", "security"] },
      "ttl_seconds": 120
    },
    {
      "id": "wi_02",
      "kind": "opportunity_score",
      "payload": { "threshold": 0.7, "account_filter": "active" },
      "ttl_seconds": 60
    },
    {
      "id": "wi_03",
      "kind": "tess_briefing",
      "payload": { "format": "morning_briefing", "surfaces": ["obsidian", "notification"] },
      "ttl_seconds": 90
    }
  ],
  "edges": [
    { "source": "wi_01", "target": "wi_02" },
    {
      "source": "wi_02",
      "target": "wi_03",
      "condition": { "op": "exists", "path": "$.scored_opportunities[?(@.score > 0.7)]" }
    }
  ]
}
```

Kimi's output is validated against a JSON schema (enforced mechanically via the contract runner). If the output doesn't conform, the plan is rejected — no partial execution, no "best effort" interpretation.

### 5.2 Executor Routing

The Readiness Engine doesn't execute work — it only determines *what's ready*. A separate **Executor Router** maps `work_item.kind` to an executor and a **routing mode**:

```
executor_registry:
  kind                → executor        mode
  ──────────────────────────────────────────────
  fif_scan            → local_script    delegate
  opportunity_score   → nemotron        delegate
  tess_briefing       → kimi            delegate
  triage              → kimi            inline
  context_synthesis   → kimi            inline
  reformat            → kimi            inline
  human_review        → wait            delegate  (creates wait_entry of type human_input)
  delegate_agent      → spawn           delegate  (creates child work_items with edges)
```

**Routing modes:**

- **`delegate`**: The Readiness Engine dispatches the work item to an external executor via the standard claim protocol (§4.2). The executor gets the work item's `payload` as its full input context. A run record is created with a lease. This is the default.
- **`inline`**: The Readiness Engine returns the work item to the orchestrator's current execution turn. Kimi executes it synchronously within its existing thread context — no payload serialization, no lease, no separate run record. The orchestrator has direct access to all upstream results and session state. The work item transitions directly from `ready` → `running` → `completed` within a single orchestrator turn.

**Inline execution mechanics:**

When the Readiness Engine promotes an inline work item to `ready`, it does not enter the claim queue. Instead, it is returned to the orchestrator as part of the "next actions" response. The orchestrator processes it immediately, writes the result back, and the Readiness Engine continues resolving the graph. This is functionally equivalent to a synchronous function call — the orchestrator blocks on it, but since it's the orchestrator doing the work, there's no deadlock risk.

Inline items still get a run record for observability and audit trail, but the lease/heartbeat mechanism is skipped. If the orchestrator fails mid-inline-execution, the run is marked failed on the next Readiness Engine tick (detected via the orchestrator's own heartbeat, not a per-run lease).

A work item's routing mode can be overridden in the graph plan by including `"mode": "inline"` or `"mode": "delegate"` on the work item. This allows the orchestrator to promote a normally-delegated task to inline when it judges that context continuity matters more than isolation for a specific instance.

---

## 6. Failure Modes and Containment

| Failure | Containment |
|---|---|
| **Kimi tool-call loop (TV2-008)** | Lease TTL expires → run reaped → work item re-queued or failed after max retries. Loop cannot block the readiness engine or other work items. |
| **Inline execution failure** | Orchestrator's own heartbeat expires → Readiness Engine marks all in-progress inline items as failed. Since inline items share the orchestrator's fate, a stuck orchestrator fails all its inline work but does not affect delegated work items running on other executors. Retry promotes the item to `delegate` mode to avoid repeated inline failure. |
| **Nemotron produces invalid output** | Contract runner rejects output → run fails → retry or propagate failure through graph. |
| **Orchestrator plans invalid graph** | JSON schema validation rejects the plan before any work items are created. No partial execution. |
| **Circular dependency in graph** | Cycle detection at plan submission time. Reject plans with cycles. |
| **Wait never resolves** | Wait entry TTL expires → configurable policy (fail run or resolve with timeout marker). |
| **Crash / restart** | All state is in SQLite. On boot: reap expired leases, re-resolve readiness, resume. No in-memory state to lose. |

---

## 7. Scope Boundaries

### In Scope (This Spec)

- Work item / edge / run / wait_entry schema and lifecycle
- Readiness resolution algorithm
- Lease/claim protocol with heartbeat
- Orchestrator plan schema and validation
- Executor routing (static registry with inline/delegate modes)
- SQLite as state store
- Single-node operation

### Out of Scope (Future)

- Event outbox / side-effect fanout (CQRS pattern from reference architecture)
- Projection read-models
- Multi-worker / distributed execution
- Dynamic executor routing (model selection based on task)
- Usage ledger / cost accounting per work item
- UI dashboard for graph visualization (could integrate with Mission Control later)
- Context compaction / summary management (existing AKM/QMD handles this)

---

## 8. Relationship to Existing Systems

| Existing Component | Relationship |
|---|---|
| **FIF** | Becomes a `work_item.kind` ("fif_scan"). Pipeline code unchanged; invocation shifts from cron to Readiness Engine. |
| **Attention Manager** | Becomes a work_item kind. Can be wired as downstream of FIF via edges. |
| **Opportunity Scout** | Becomes a work_item kind. Conditional edge from FIF or Attention Manager. |
| **Tess (Kimi K2.5)** | Serves as orchestrator (graph planner) AND as one possible executor for complex generation tasks. Dual role is fine — planning and execution are separated by the Readiness Engine. |
| **Nemotron Cascade 2** | Executor for schema-constrained leaf tasks (scoring, classification, extraction). |
| **Contract Runner** | Validates orchestrator plan output AND executor task output. Mechanical enforcement at both boundaries. |
| **AKM / QMD** | Unchanged. Work items can reference AKM context in their payload; QMD search remains the knowledge retrieval layer. |
| **crumb-tess-bridge** | May be simplified or retired — the Readiness Engine subsumes the dispatch/routing function. Evaluate after implementation. |

---

## 9. Implementation Sequence

**Phase 1 — Schema + Readiness Core**
- Define SQLite schema (work_items, work_item_edges, runs, wait_entries)
- Implement readiness resolver (pure function: given current state, which items should transition to ready?)
- Implement cycle detection for plan validation
- Unit tests for all status transitions and edge conditions

**Phase 2 — Lease + Claim**
- Implement claim protocol with lease TTL
- Implement heartbeat mechanism
- Implement stale lease reaper
- Integration test: simulate executor crash, verify reap and re-queue

**Phase 3 — Orchestrator Integration**
- Define JSON schema for graph plans
- Wire Kimi plan output through contract runner → Readiness Engine
- Implement executor router (static registry)
- Integration test: Kimi plans a graph, Readiness Engine resolves it, executors complete work

**Phase 4 — Wait / Delegation**
- Implement wait_entry lifecycle
- Implement child work_item creation (delegation)
- Wire human_input wait type to existing approval flows
- Integration test: parent delegates to child, child completes, parent resumes

**Phase 5 — Migration**
- Move FIF from cron to Readiness Engine
- Move Attention Manager and Opportunity Scout
- Evaluate crumb-tess-bridge for retirement
- Soak test: run full pipeline through Readiness Engine for one week

---

## 10. Open Questions

1. **Condition expression language.** The spec uses JSONPath-style conditions on edges. Is this expressive enough, or do we need a small DSL? JSONPath keeps it simple but may not handle complex branching predicates.

2. **Priority model.** The claim protocol says "ORDER BY priority, created_at" but priority isn't defined on work_items yet. Options: static priority per kind, dynamic priority from orchestrator, or FIFO only for now.

3. **Retry policy.** Should retry policy (max retries, backoff) live on the work_item, the kind registry, or both? Leaning toward kind registry with per-item override.

4. **Graph plan mutability.** Can the orchestrator amend a running graph (add items/edges to an active session)? Or is the plan immutable once submitted? Immutable is simpler and safer; mutable enables adaptive workflows.

5. **Observability.** What's the minimum viable observability for Phase 1? Structured logs to stdout? A simple status query endpoint? Integration with Mission Control dashboard?
