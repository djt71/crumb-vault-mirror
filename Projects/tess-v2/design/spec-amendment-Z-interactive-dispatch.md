---
project: tess-v2
type: design-input
domain: software
status: superseded
created: 2026-04-04
updated: 2026-04-21
superseded_by: spec-amendment-AC-execution-surfaces.md
superseded_date: 2026-04-21
source: external-systems-evaluation-2026-04-04, operator-directed architectural analysis
tags:
  - spec-amendment
  - orchestration
  - interactive-dispatch
  - session-management
  - superseded
---

# Spec Amendment Z: Interactive Dispatch & Orchestrator Authority

> **⚠ SUPERSEDED 2026-04-21 by Amendment AC** (`spec-amendment-AC-execution-surfaces.md`).
>
> Two weeks of live operation falsified Z's load-bearing thesis — that Tess should
> be the dispatch authority for operator-interactive work. Kimi K2.5 and GPT-5.4
> both failed the orchestrator role by operator standards despite passing synthetic
> evaluation. Amendment AC retracts **AD-013 (Interactive Dispatch Authority)** and
> narrows Tess's role to autonomous execution of scheduled launchd services only.
>
> **Retained from Z** (repurposed with writer inversion — upstream surfaces write,
> Crumb reads):
> - §Z1 dispatch queue schema
> - §Z1b claims file
> - §Z2 session report schema (including Z2's storage model and compliance mechanism)
> - §Z3 startup hook integration + orphaned-session detection
> - Task class taxonomy (Z1) as vocabulary
> - AD-014 (Structured Session Reporting) — still active
>
> **Retired from Z:**
> - **AD-013 (Interactive Dispatch Authority)** — reversed by AC's AD-017
> - §Z4 Tess Planning Cycle — no autonomous planning over operator work
> - §Z4 graduated autonomy promotion/demotion for operator-facing task classes
> - The "hierarchy inversion" framing of the problem statement
>
> The original Z text is preserved below for provenance. Do not treat it as the
> current design — read AC first.

---

## Problem Statement

The spec defines Tess as the orchestrator (§3.1 line 85) and lists "Claude Code
(interactive)" as an executor (§3.1 line 107). §16 states the overall success
criterion: "Tess operates as an autonomous orchestrator, not a notification layer"
and "Danny's role shifts from session driver to strategic director."

But the spec provides no mechanism for Tess to:
1. Queue work that requires interactive Claude Code execution
2. Receive structured results from interactive sessions
3. Maintain orchestrator authority when the operator works interactively with Crumb

**The result: Tess is the orchestrator in name. Crumb is the orchestrator in
practice.** Danny opens Claude Code, decides what to work on, drives the session.
Tess runs mechanical tasks in the background. The hierarchy is inverted.

### Evidence from Current Operations

- Session-start: Crumb reads vault state and surfaces options. Danny picks.
  Tess is not consulted.
- Session-end: Crumb writes a prose run-log entry and updates `next_action`
  in project-state.yaml. Tess can read these, but they aren't structured for
  machine ingestion — she'd be doing fuzzy context reconstruction.
- Between sessions: Tess executes LaunchAgent contracts. She has no awareness
  of what interactive sessions accomplished or what work is pending for
  interactive execution.

### External Validation

Evaluated 10 external agent systems (MiroFish, LangSmith, Slate V1, Karpathy
Wiki, Cabinet, Swarm Wiki, Pedro's Autopilot, Subconscious Agent, Gkisokay
Stack, Compound Engineering Plugin). All systems that separate orchestration
from execution assume the orchestrator maintains continuous authority. None solve
for the specific case of an orchestrator maintaining authority across both
autonomous and human-interactive execution modes. This is a novel architectural
requirement.

The closest analog is Pedro's Autopilot pattern: signal injection pipeline
passively observes all operator activity channels. The orchestrator never loses
awareness because it's always watching. The structured session-report mechanism
proposed below is Crumb's version of this pattern.

---

## Proposed Architectural Changes

### AD-013: Interactive Dispatch Authority

Tess is the dispatch authority for all execution modes — autonomous (LaunchAgent
contracts) and interactive (Claude Code sessions). Interactive sessions operate
against Tess's dispatch queue by default. The operator may override priorities
(operator sits above Tess in the hierarchy), but the default flow is: Tess
plans, executors execute.

This formalizes what §3.4 point 1 ("Danny's role shifts") and §16 ("autonomous
orchestrator") already intend. The mechanism was missing; the intent was not.

### AD-014: Structured Session Reporting

Every interactive Claude Code session produces a machine-readable session report
alongside the existing prose run-log entry. The session report uses a defined
schema that Tess can ingest mechanically. This closes the observability gap
between autonomous execution (which already produces structured outcomes via
run_history) and interactive execution (which currently produces only prose).

### AD-008 Scope Clarification

AD-008 (Staging → Promotion Write Model) constrains **autonomous executors**:
"Executors write to isolated staging directories, never to canonical vault
paths." This prevents unsupervised agents from writing directly to the
canonical vault.

Interactive sessions (Crumb/Claude Code with the operator present) have
always had direct vault write access — the human operator serves as the
quality gate. AD-008 does not restrict interactive writes and never did.

Session reports (Z2) are written to SQLite at `~/.tess/state/` — outside
the vault entirely. No AD-008 consideration applies. Prose run-log entries
continue to be written directly to the vault under existing session-end
protocol, as they always have been.

---

## Z1: Interactive Dispatch Queue

**Sections affected:** §3.1 (System Map), §11 (Service Model), §10b (Prompt
Architecture)

### Schema

Tess writes the dispatch queue to a known vault location. Crumb reads it at
session start.

```yaml
# _tess/dispatch/queue.yaml
# Written by: Tess (orchestrator)
# Read by: Crumb (session-start hook) + planning service (autonomous dispatch)
# Updated: each Tess planning cycle

queue:
  - id: IDQ-001
    project: tess-v2
    task_ref: TV2-036        # links to tasks.md, nullable for ad-hoc
    task_class: service_migration  # see Task Class Taxonomy below
    summary: "Migrate email triage service — wrapper, contract, plist, live test"
    priority: high           # high | medium | low
    status: queued           # queued | in_progress | completed | failed
    dispatch_type: interactive  # interactive | autonomous
    depends_on: [IDQ-003]    # structured dependency on other queue items
    reason: "Next on critical path. Blocked until TV2-034/035 gates clear."
    blocked_until: 2026-04-06  # if present and future-dated, item is blocked
    context_files:
      - Projects/tess-v2/design/service-interfaces.md §4
      - Projects/tess-v2/design/tasks.md TV2-036
    decisions_made:           # from prior sessions — Crumb must respect these
      - "FIF wrapper pattern: structured YAML to stdout"
      - "Timing: tess-v2 runs 5min before OpenClaw"
    acceptance_criteria:
      - "email triage service wrapper passes live test"
      - "72h parallel run started, LaunchAgent bootstrapped"
    estimated_effort: "half-day interactive session"

  - id: IDQ-002
    project: tess-v2
    task_ref: null            # independent research, no task
    task_class: eval_benchmark
    summary: "Benchmark MiniMax M2.7 via TV2-Cloud battery"
    priority: medium
    status: queued
    dispatch_type: autonomous   # deterministic criteria, no design judgment
    executor: claude-p          # claude -p with TV2-Cloud eval spec
    depends_on: []
    reason: "Untested model with strong agent benchmarks. Could inform AD-011."
    blocked_until: null
    context_files:
      - Projects/tess-v2/design/tv2-cloud-eval-spec.md
      - Projects/tess-v2/eval-results/
    decisions_made: []
    acceptance_criteria:
      - "Scored against full TV2-Cloud battery"
      - "Decision document in eval-results/"
    estimated_effort: "half-day"

updated_by: tess
updated_at: 2026-04-04T08:00:00Z
planning_cycle: daily       # how often Tess refreshes this queue
version: 1                  # incremented each planning cycle
```

### Dispatch Queue Rules

1. **Tess writes, Crumb reads.** Crumb never modifies the dispatch queue
   directly. If interactive work produces new queue items, they go through
   the session report (Z2) and Tess adds them in her next planning cycle.
2. **Operator override is always valid.** Danny can ignore the queue and work
   on something else. The queue is Tess's recommendation, not a mandate.
   When the operator overrides, the session report (Z2) records the override
   with rationale so Tess can adjust future planning.
3. **Blocked items are visible but not actionable.** Items with
   `blocked_until` in the future are shown in the startup summary as
   upcoming, not active.
4. **Priority sequencing.** High items surface first. Within a priority tier,
   items are ordered by Tess's judgment (critical path, dependency chains,
   liberation directive alignment).
5. **Queue is a materialized view.** Tess regenerates the full queue each
   planning cycle. During regeneration, Tess reads the existing queue and
   preserves items with `status: in_progress` and active claims (from
   `claims.yaml`). Completed/failed items are folded into the new queue
   or dropped. Autonomous execution results and session reports are the
   events that drive status transitions.
6. **Event-based claims (single-writer preserved).** Crumb never writes to
   `queue.yaml`. Instead, Crumb emits claim events to a separate file:
   `_tess/dispatch/claims.yaml` (append-only between planning cycles).
   Tess reads and merges claims into the queue during each planning cycle.
   See Z1b for the claims schema.
7. **Blocked state is derived.** Items with `blocked_until` in the future
   are blocked. No separate `blocked` status — one source of truth.

### Z1b: Claims File

Claims are emitted by Crumb at session start and end. This preserves the
single-writer invariant on `queue.yaml` (Tess only) while allowing Crumb
to communicate intent and outcomes.

```yaml
# _tess/dispatch/claims.yaml
# Written by: Crumb (session-start and session-end)
# Read by: Tess (planning cycle merges into queue.yaml)
# Reset: Tess clears after merging into queue

claims:
  - session_id: "20260406T091523"  # ISO timestamp, generated at session start
    item_id: IDQ-001
    action: claim                   # claim | release | complete | fail
    timestamp: "2026-04-06T09:15:23Z"
  - session_id: "20260406T091523"
    item_id: IDQ-001
    action: complete
    timestamp: "2026-04-06T11:42:00Z"
```

**Session ID** is the durable correlation key between claims and session
reports. Generated once at session start (`date -u +%Y%m%dT%H%M%S`),
carried through `claimed_by` in claims and `session.id` in session reports.
The date-sequence format (`2026-04-06-1`) remains as a human-friendly
display label.

**Stale claim recovery:** If a claim exists without a corresponding
`release`, `complete`, or `fail` action, and no matching session report
exists in `session_reports.db`, the claim is stale. The startup hook
detects this and auto-emits a `release` event (see Crashed Session
Detection in Z3). Hard ceiling: claims older than 8 hours are always
treated as stale regardless of session state.

### Task Class Taxonomy

Queue items carry a `task_class` field from a defined enumeration. This
drives graduated autonomy promotion/demotion tracking.

```
task_class:
  # Pre-approved for autonomous execution (no precedent required):
  eval_benchmark        — model evaluation, scoring
  service_health_check  — health monitoring, status checks
  data_aggregation      — feed capture, stats collection

  # Eligible for graduated promotion (requires precedent + approval):
  service_migration     — wrapping existing services in new platform
  research              — information gathering, analysis

  # Permanently interactive (never autonomous):
  architecture_change   — system design, AD modifications
  spec_modification     — spec/amendment authoring
  credential_operation  — auth tokens, API keys, certificates
  destructive_action    — file deletion, service decommission
  creative              — writing, design with aesthetic judgment
```

Tess assigns `task_class` during queue materialization. Operator can
override via session report feedback.

### System Map Update (§3.1)

The system map gains a bidirectional arrow between Tess and Crumb:

```
┌──────────────────────────────────────────────────────────────────┐
│                     OPERATOR (Danny)                             │
│  Strategic direction, override authority, spot-checks            │
└──────────────┬───────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────┐
│                     TESS (Orchestrator)                          │
│                                                                  │
│  Responsibilities (updated):                                     │
│  - Everything in current §3.1, PLUS:                             │
│  - Maintain dispatch queue (autonomous + interactive)             │
│  - Dispatch autonomous items directly (claude -p, contracts)      │
│  - Queue interactive items for operator's next session             │
│  - Ingest session reports from interactive execution              │
│  - Plan across ALL execution surfaces                             │
│  - Track work regardless of which executor performed it           │
└────────┬────────────────────┬───────────────────────┬────────────┘
         │                    │                       │
         ▼                    ▼                       ▼
┌─────────────────┐  ┌────────────────┐  ┌─────────────────────────┐
│  CRUMB VAULT    │  │ AUTONOMOUS     │  │ CRUMB (Interactive      │
│                 │  │ EXECUTORS      │  │        Executor)        │
│  Single source  │  │                │  │                         │
│  of truth.      │  │ Nemotron,Kimi, │  │ Claude Code + Operator  │
│                 │  │ Sonnet, etc.   │  │                         │
│  Autonomous     │  │                │  │ Reads: dispatch queue   │
│  writes via     │  │ Contract-based │  │ Writes: session report  │
│  staging only   │  │ execution      │  │   (SQLite, not vault)   │
│  (AD-008).      │  │                │  │ Direct vault writes     │
│  Interactive    │  │                │  │   (operator supervised) │
│  writes direct. │  │                │  │                         │
└─────────────────┘  └────────────────┘  └─────────────────────────┘
```

Note: Crumb (the vault) and Crumb (the interactive executor) are distinct
roles that share a name. The vault is the noun — persistent state. The
interactive executor is the verb — Claude Code sessions that read from
and produce artifacts for the vault.

---

## Z2: Session Report Schema

**Sections affected:** §18 (Observability), session-end protocol

Every interactive Claude Code session produces a structured session report.
This is the interactive equivalent of the run_history record that autonomous
contracts already produce.

### Schema

```yaml
# Logical schema — stored in SQLite at ~/.tess/state/session_reports.db
# Table: session_reports (one row per session, JSON columns for nested fields)
# Written by: Crumb (session-end)
# Read by: Tess (next planning cycle, via SQL queries)

# --- Required fields (every session) ---

session:
  id: "20260404T091523"      # durable correlation key (matches claims)
  date: 2026-04-04
  sequence: 1               # human-friendly disambiguator
  duration_minutes: 135
  operator_present: true
  incomplete: false          # true if fast-exit mode (see Session Report Compliance)

dispatch:
  queue_items_executed:
    - id: IDQ-001
      outcome: completed     # completed | partial | blocked | deferred
      notes: "TV2-036 migrated, 72h parallel run started"
    - id: IDQ-002
      outcome: deferred
      notes: "Deprioritized — focused on TV2-036"
  operator_overrides:        # work done outside the queue
    - summary: "Investigated fd isolation pattern for backup-status"
      rationale: "Blocking bug discovered during TV2-036 work"
      project: tess-v2
      outcome: resolved

decisions:
  made:
    - context: "TV2-036 email triage"
      decision: "30min polling interval matches OpenClaw baseline"
      rationale: "No reason to change cadence during parallel run"
  deferred:
    - context: "Email triage error handling"
      question: "Should transient Gmail API failures retry or dead-letter?"
      blocker: "Need to observe failure patterns during soak"

remaining_work:
  - task: TV2-036
    status: "72h soak in progress, gate ~Apr 9"
    next_action: "Monitor soak data, call gate when criteria met"

# --- Optional fields (include when applicable) ---

execution:                   # optional — detailed execution metrics
  projects_touched:
    - project: tess-v2
      tasks_completed: [TV2-036]
      tasks_started: []
      tasks_blocked: []
  files_created: 3
  files_modified: 7

model_routing:               # optional — cost/routing tracking
  opus_tasks: ["TV2-036 implementation, debugging, live testing"]
  delegated: []
  cost_estimate_usd: 0.85   # best-effort estimate
```

### Session Report Rules

1. **Written at session end, before the prose run-log entry.** The session
   report is the machine-readable record; the run-log entry is the
   human-readable narrative. Both are produced; they serve different consumers.
   Sequence: session report → run-log entry → conditional commit.
2. **Session report is authoritative for planning.** The prose run-log is
   the human-readable narrative and does not feed Tess's planning cycle.
   When the two diverge, the session report governs Tess's behavior.
3. **Required vs. optional fields.** The `session`, `dispatch`, `decisions`,
   and `remaining_work` sections are required every session. The `execution`
   and `model_routing` sections are optional — include when applicable.
4. **Operator overrides are first-class.** When Danny works on something
   outside the dispatch queue, it's recorded with rationale. This is not an
   error — it's data that helps Tess calibrate future planning.
5. **Decisions section prevents re-litigation.** When Tess dispatches
   follow-up work related to a prior interactive session, she includes
   `decisions.made` from the session report in the dispatch context. This
   ensures subsequent executors (autonomous or interactive) respect decisions
   already made.
6. **Storage:** SQLite at `~/.tess/state/session_reports.db`, alongside
   `run_history.db` and write-locks. Session reports are structured,
   append-heavy, and need cross-record queries ("decisions in last N
   sessions", "override frequency"). The YAML schema above is the logical
   schema — nested fields are stored as JSON columns. This matches
   run_history's proven pattern.

### Session Report Compliance

Session reports must be produced reliably. Sessions end in many ways —
clean wrap-up, context exhaustion, operator closing the terminal. Relying
on behavioral compliance alone will fail over time.

**Primary mechanism:** A session-end hook in the Claude Code harness
(`settings.json` PostToolUse or custom hook) that extracts required fields
from session context and writes the report to `session_reports.db`.

**Fast-exit mode:** When a session must end quickly (context pressure,
operator closing), a minimal report is acceptable: session ID, timestamp,
claimed items with `outcome: unknown`, and `incomplete: true`. The next
startup hook prompts the operator to elaborate before proposing new work.

**Fallback:** If neither mechanism fires, the next startup treats the
previous session as orphaned (see Crashed Session Detection in Z3).

---

## Z3: Startup Hook Integration

**Sections affected:** Session-start protocol, CLAUDE.md Session Startup

The session-startup hook gains a step: read the interactive dispatch queue
and surface Tess's priorities in the startup summary.

### Startup Summary Addition

Current startup summary shows: vault-check, Obsidian CLI, rotation, overlay
index, audit status, stale summaries, feed intel counts, research pending.

Add after existing items:

```
- **Tess dispatch:** 2 items queued (updated 2h ago)
  - Ready now:
    - [MED] MiniMax M2.7 benchmark
  - Upcoming:
    - [HIGH] TV2-036: Migrate email triage service (blocked until Apr 6)
```

If `updated_at` is older than the staleness threshold (default 36 hours,
configurable per project via `dispatch_freshness_hours` in project-state.yaml)
or older than the last session report timestamp, show `STALE DISPATCH`
warning and treat queue recommendations as advisory only:

```
- **Tess dispatch:** STALE (last updated 38h ago) — queue is advisory only
```

If the queue is empty, show: `No items queued — Tess has no pending work.`

### Behavioral Change

Today, Crumb's session-start surfaces vault health and lets Danny (or Crumb)
decide what to work on. With this amendment:

1. Crumb reads `_tess/dispatch/queue.yaml`
2. Freshness check: if queue `updated_at` > 36h (configurable), show `STALE DISPATCH`
3. Startup summary shows Tess's priorities (ready vs. upcoming/blocked)
4. Crumb proposes starting with Tess's top unblocked item
5. Operator confirms, overrides, or directs other work
6. If operator overrides, session report records the override

This makes Tess's orchestration visible and default without removing operator
authority.

### Crashed Session Detection

If the startup hook finds a claim in `claims.yaml` with no corresponding
`complete`, `fail`, or `release` action, and no matching session report
exists in `session_reports.db`, the previous session is orphaned. The hook:

1. **Releases the claim** — appends a `release` event to `claims.yaml`
   with `reason: orphaned_session`.
2. **Generates a minimal orphaned-session record** in `session_reports.db`:

```yaml
session:
  id: "20260405T091523"      # from the orphaned claim
  date: 2026-04-05
  sequence: 1
  duration_minutes: null
  operator_present: true
  orphaned: true             # flags this as auto-generated, not observed
dispatch:
  queue_items_executed:
    - id: IDQ-001
      outcome: unknown       # session terminated without reporting
      notes: "Previous session claimed this item but produced no report"
```

3. **Attempts reconciliation** — checks `git diff` and file modification
   times against the claim period to infer what work may have occurred.
   Reconciliation evidence is added to the orphan record's `notes` field.

The startup summary shows: `⚠ Previous session (IDQ-001) ended without
report — results unknown. Claim released.`

**Note:** Orphaned session records are stored in the same `session_reports`
table but flagged with `orphaned: true`. The planning service must treat
these as "unknown outcome" — not as confirmed completions or failures.

---

## Z4: Tess Planning Cycle

**Sections affected:** §11 (Service Model — new service), §18 (Observability)

### New Service: Interactive Planning

Tess gains a planning service that refreshes the interactive dispatch queue.
This runs on a schedule (daily) or is triggered by session report ingestion.

```yaml
service_name: interactive-planning
description: "Refresh interactive dispatch queue based on project state, 
  gate timelines, session reports, and strategic priorities"
trigger: scheduled + event
schedule: "daily, 06:00 (before likely interactive session start)"
event_trigger: "new row in session_reports.db (poll or sentinel file)"
input:
  - project-state.yaml files (all active projects)
  - gate timelines (from run_history + soak start times)
  - session reports (from session_reports.db)
  - claims (from _tess/dispatch/claims.yaml)
  - liberation directive (strategic priority filter)
  - run_history summary (autonomous execution state)
  - existing queue.yaml (for claim preservation)
output: _tess/dispatch/queue.yaml
contract: "Queue reflects current project state. No stale items. 
  Priority ordering consistent with liberation directive.
  Autonomous items dispatched immediately after queue refresh."
```

### Autonomous Dispatch Routing

After refreshing the queue, the planning service processes autonomous items
immediately:

1. Filter queue for `dispatch_type: autonomous` + `blocked_until: null` (or past)
2. For each autonomous item, transition status to `in_progress` and dispatch
   to the specified `executor`:
   - `claude-p` → `claude -p` with context_files and acceptance_criteria
   - `contract` → standard contract runner (ShellExecutor / Ralph loop)
   - `nemotron` → local executor dispatch
3. Record dispatch in run_history (same outcome schema as all other executions)
4. On completion, transition item status to `completed` or `failed` and log
   results. Items remain in the queue until the next planning cycle
   materializes a fresh queue (per Rule 5).

Items that fail autonomous execution are reclassified as `interactive` with
the failure context attached, so the operator can diagnose during their next
session. This is the same escalation pattern as AD-009 (risk-based
escalation gate) applied to the interactive/autonomous boundary.

Interactive items remain in the queue untouched, surfaced at the next
session start.

**Autonomous eligibility criteria** (planning service applies these when
classifying new work):
- Task class is in the pre-approved list OR has been promoted via the
  graduated autonomy process (see below)
- Acceptance criteria are deterministic (tests pass, file exists, score
  computed — not "is this good enough?")
- No design decisions required during execution
- Failure is recoverable (dead-letter, retry, or report results)

**Pre-approved autonomous task classes** (no precedent required):
`eval_benchmark`, `service_health_check`, `data_aggregation`. These are
mechanical by nature and have been validated through existing contract
runner operation.

**Graduated autonomy with safeguards** (Phase C — see Implementation
Phasing): Each non-pre-approved task class can be promoted to autonomous
execution, subject to:

1. **Interactive-first requirement:** The task class must have been
   executed interactively at least 3 times successfully, demonstrating
   the work is mechanical and suitable for autonomous execution.
2. **Operator approval gate:** First autonomous promotion of any task
   class requires explicit operator approval. The planning service
   proposes; the operator confirms via session report.
3. **Promotion threshold:** After operator approval, 5 consecutive
   autonomous successes required before operator review of results can
   be skipped.
4. **Demotion trigger:** Any failure in a promoted task class immediately
   reverts it to interactive for 3 cycles. Two failures within 5 cycles
   reverts permanently until operator re-approves.
5. **Spot-check rate:** Even for promoted classes, 1 in 5 successful
   executions is flagged for operator review in the startup summary.
6. **Permanently interactive list:** `architecture_change`,
   `credential_operation`, `destructive_action`, `spec_modification`,
   and `creative` task classes are never eligible for autonomous execution
   regardless of success history (see Task Class Taxonomy in Z1).

### Planning Inputs

The planning cycle reads:
1. **Project state** — active projects, current phase, next_action
2. **Gate timelines** — when soak runs complete, what they unblock
3. **Session reports** — what interactive sessions accomplished, what remains
4. **Autonomous execution results** — run_history summary, service health
5. **Liberation directive** — revenue-generating prompts get priority claim
6. **Blocked/unblocked status** — dependency chains across tasks

### Planning Service Failure Handling

The planning service is a critical component. Failure modes and mitigations:

1. **Service crash / missed schedule:** Queue retains last-known-good state.
   Startup hook detects staleness via `updated_at` (see Z3). Crumb proposes
   manual queue refresh or proceeds with stale queue as advisory.
2. **Malformed session report:** Planning service validates report structure
   before ingestion. Malformed reports are logged to dead-letter with the
   parsing error. Planning cycle continues with available data.
3. **Malformed queue output:** Queue file is written via atomic replacement
   (write to temp, rename). If the planning service produces invalid YAML,
   the old queue survives. Health monitoring (existing awareness-check
   contract) includes queue freshness as a check dimension.
4. **Conflicting project priorities:** When multiple projects have
   high-priority items, ordering follows: liberation directive strategic
   class → unblock count (items this unblocks) → item age → operator-set
   project weight (if specified in project-state.yaml) → lexical ID as
   final tiebreaker.

### Capability Requirement

Default orchestration is continuity-driven scheduling under explicit policy.
It requires:
- Reading structured YAML files
- Evaluating temporal conditions (gate dates vs. current date)
- Applying priority rules (liberation directive, dependency ordering)
- Producing structured YAML output

This is within Kimi K2.5's demonstrated capability (scored 76/95 on the
TV2-Cloud eval battery; see `eval-results/cloud-eval-results-kimi-2026-03-30.md`).
The orchestrator doesn't need to understand *how* to migrate an email service
— it needs to know *that* the email service migration is next, *when* it's
unblocked, and *what context* the interactive executor needs.

Complex prioritization — multi-project arbitration, strategic re-sequencing,
ambiguous dependency resolution — may exceed this baseline. For these cases,
the planning service uses Amendment Y's plan-before-request pattern or
escalates to the operator via the startup summary.

---

## Implementation Sequencing

This amendment introduces no new external infrastructure. It adds one new
internal service (planning cycle), one new SQLite table (session reports),
and one new YAML artifact (dispatch queue), all using existing runtime and
execution mechanisms.

### Implementation Phasing

Each phase validates its data layer before the next phase depends on it.

**Phase A: Core Loop** (implement now)
- Dispatch queue schema with corrected write model (Z1, Z1b)
- Session reports with compliance mechanism and trimmed schema (Z2)
- Startup hook with queue display, freshness check, orphan detection (Z3)
- Session ID correlation keys throughout
- Bootstrap: operator writes initial `queue.yaml` manually (Z-5)
- Manual refresh trigger (`tess plan --refresh` or equivalent)

**Phase B: Planning Service** (implement after Phase A runs for 2+ weeks)
- Tess planning cycle (Z4) with claim preservation during regeneration
- Decision provenance (timestamps, source session on `decisions_made`)
- Liberation directive override surfacing in startup summary
- Configurable staleness thresholds per project

**Phase C: Graduated Autonomy** (implement after Phase B has clean history)
- Task class tracking and promotion/demotion mechanics
- Pre-approved base set activation
- Spot-check enforcement
- Requires: clean session report history + defined task classes from Phase B

**Z-5 (bootstrap) is the cold-start mechanism.** Before Tess's planning
service is operational, the operator (via Crumb) writes the initial dispatch
queue manually. This is acceptable because:
- The queue schema is simple YAML
- The operator already maintains this state mentally
- It makes the queue immediately useful before the full loop is automated

Once Phase B deploys, Tess maintains the queue autonomously.

### Relationship to Existing Amendments

- **Amendment Y (plan-before-request):** The planning service (Z4) is a
  consumer of Amendment Y's two-turn dispatch pattern. When the planning
  task is complex (multiple projects, competing priorities), the orchestrator
  uses Y's plan schema before producing the queue.
- **run_history (built 2026-04-03):** Provides the autonomous execution state
  that the planning cycle reads. Without run_history, Tess couldn't assess
  gate timelines or service health — the timing of this amendment is enabled
  by run_history's existence.
- **Session-end protocol:** The session report (Z2) is a new step in the
  existing session-end sequence: session report → run-log entry →
  conditional commit (per Z2 Rule 1).
- **Services vs. roles analysis** (`design/services-vs-roles-analysis.md`):
  Paperclip evaluation (2026-03-31) identified the same hierarchy Z
  formalizes. Z establishes orchestrator authority at the Tess → Crumb
  boundary. The services-vs-roles analysis extends it one level down
  (sub-orchestrators for future ventures like Firekeeper Books). Z is
  the prerequisite; sub-orchestrators are the natural next step when
  coordination cost exceeds bandwidth. TV2-045 tracks the integration spike.
- **Pedro autopilot extraction** (`design/pedro-autopilot-extraction-2026-04-04.md`):
  Pedro's auto-resolver maps directly to Z4 autonomous dispatch. His
  People + Programs declarative filters inform the planning service's
  input model.
- **External systems evaluation** (`design/external-systems-evaluation-2026-04-04.md`):
  10 systems evaluated, all converge on orchestrator-maintains-authority.
  This evaluation surfaced the hierarchy inversion that Z corrects.

---

## Architectural Implications

### The Capability Inversion Is a Feature

Tess's orchestrator model (Kimi K2.5, scored 76/95 on TV2-Cloud eval; see
`eval-results/cloud-eval-results-kimi-2026-03-30.md`) is less capable than
Crumb's executor model (Opus). This seems inverted — why would a less-capable
model direct a more-capable one?

Because orchestration authority comes from **continuity**, not intelligence.
Tess is always on. She sees every autonomous execution result, every session
report, every gate outcome, every service health check. She has the full
timeline. Crumb has deep intelligence for 2 hours at a time and then starts
fresh.

The default planning decisions are state-aware routing:
- "TV2-034 gate clears Sunday"
- "TV2-036 is next on critical path"
- "Email triage needs interactive session"
- "MiniMax benchmark is independent, can fill a gap"

This is within Kimi's capability. The hard reasoning — *how* to implement
email triage, *how* to debug fd inheritance — stays with Crumb/Opus.

**Boundary condition:** Not all planning is pure routing. Multi-project
arbitration, strategic re-sequencing under the liberation directive, and
ambiguous dependency resolution require judgment. For these cases, the
planning service applies Amendment Y's plan-before-request pattern (explicit
reasoning step before queue output) or escalates to the operator. The
planning service's contract should include a complexity heuristic: if
planning inputs span >3 projects or require trade-off evaluation, trigger
the plan-before-request path.

The separation maps directly to the five converging patterns identified in
the external systems evaluation (`design/external-systems-evaluation-2026-04-04.md`):
**separate strategy from execution** (Pattern 1), with the nuance that
"strategy" here means "state-aware scheduling under explicit policy," not
"deep architectural reasoning."

### What Changes for the Operator

Danny's daily flow shifts from:
1. Open Claude Code → decide what to work on → work on it → close

To:
1. Open Claude Code → see Tess's priorities → confirm or override → work → close

The difference is small in ceremony but significant in authority. Tess is the
default planner. Danny retains veto power. The system's strategic coherence
no longer depends on Danny remembering what's next — Tess tracks it.

### What Changes for Crumb

Crumb shifts from:
- Autonomous decision-maker that reads vault state and proposes work
To:
- Informed executor that reads Tess's dispatch queue and executes work

Crumb retains all of its capability — deep reasoning, debugging, design,
compound reflection. What changes is the *source of work direction*. Today
Crumb decides. After this amendment, Tess decides (subject to operator
override).

Crumb's session-end gains one new obligation: produce a structured session
report. This is low-ceremony — the information already exists in the run-log
entry, it just needs a second output in machine-readable format.

---

## Provenance

- **External systems evaluation (2026-04-04):** 10 systems analyzed, all
  converge on orchestrator-maintains-authority pattern.
  Vault: `design/external-systems-evaluation-2026-04-04.md`
- **Pedro autopilot extraction (2026-04-04):** Signal injection pipeline,
  auto-resolver, People+Programs declarative filters.
  Vault: `design/pedro-autopilot-extraction-2026-04-04.md`
- **Kimi K2.5 evaluation:** Scored 76/95 on TV2-Cloud battery.
  Vault: `eval-results/cloud-eval-results-kimi-2026-03-30.md`
- **Operator architectural analysis (2026-04-04):** Danny identified the
  hierarchy inversion and directed the correction
- **Crumb diagnostic (2026-04-04):** Identified the three-artifact solution
  (dispatch queue, session report, startup hook integration)
- **Prior art:** Pedro's Autopilot (passive observation), Swarm Wiki
  (structured output dumps), Amendment Y (plan-before-request)

## Peer Review

**Round 1 (Crumb panel, 2026-04-06):** GPT-5.4, Gemini 3.1 Pro, DeepSeek
V3.2, Grok 4.1 Fast. 4 must-fix and 6 should-fix items applied. Review
note: `reviews/2026-04-06-spec-amendment-Z-interactive-dispatch.md`

**Round 2 (external synthesis, 2026-04-06):** Opus (pre-review), Gemini 3.1
Pro, DeepSeek V3.2, GPT-5.4, Perplexity. 8 must-fix and 13 should-fix
items. Significant findings beyond Round 1: multi-writer contradiction
(MF-1), correlation ID gap (MF-3), queue regeneration clobber (MF-4),
graduated autonomy bootstrap deadlock (MF-5), undefined task class (MF-6),
session report compliance (MF-8). Three-phase implementation recommended.
Synthesis: `_inbox/amendment-z-peer-review-synthesis.md`
