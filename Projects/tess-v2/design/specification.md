---
project: tess-v2
type: specification
domain: software
skill_origin: systems-analyst
status: active
created: 2026-03-28
updated: 2026-04-21
tags:
  - tess
  - orchestration
  - local-llm
  - hermes-agent
  - autonomous-operations
---

# Tess v2 — Specification

> **⚠ Scope narrowed 2026-04-21 by Amendment AC** (`spec-amendment-AC-execution-surfaces.md`).
>
> Two weeks of live operation falsified the load-bearing thesis that Tess
> should become the autonomous orchestrator over operator-facing strategic
> work. Amendment AC retracts the orchestrator role (see AD-017) and narrows
> Tess to **autonomous execution of scheduled launchd services only** (15
> `com.tess.v2.*` LaunchAgents). Operator-facing planning and dispatch move
> to the Level 2 upstream surfaces (claude.ai, Cowork, Remote Control) and
> Crumb / Claude Code as the Level 3 execution surface.
>
> The spec text below is preserved as original intent. Where it conflicts
> with AC — specifically §1 (problem framing), §3.1 system map, §3.5
> second-order effects, §16 success criteria — AC governs. Re-read AC
> before acting on spec text in those sections.

## 1. Problem Statement

> **AC note:** "Nothing gets built in Crumb unless Danny drives an interactive
> session" is no longer framed as the problem. Interactive Crumb is now the
> preferred mode, supported by upstream strategic surfaces (claude.ai,
> Cowork). The scheduled-services side of this spec continues to apply.

Nothing gets built in Crumb unless Danny drives an interactive session. Tess, running as a LaunchDaemon via OpenClaw, operates as a notification/digest layer — not the autonomous operator she was designed to become. OpenClaw's model routing is confirmed broken (v2026.3.24), making it unsuitable as the orchestration platform for a multi-model Tess.

This matters because the liberation directive requires the system to generate value without Danny at the keyboard. Every hour Tess can't autonomously dispatch, execute, and evaluate work is an hour of compounding opportunity cost across all six revenue prompts.

## 2. Facts, Assumptions, Unknowns

### 2.1 Facts

- F1: OpenClaw model routing broken — fallback chains fail silently, cross-provider failover doesn't trigger, generic errors bypass failover classifier (v2026.3.24)
- F2: Mac Studio M3 Ultra: 96GB unified memory, 800 GB/s bandwidth, ~85-90GB usable for inference
- F3: Qwen3.5 27B went all-green on independent tool-calling tests (15 scenarios, 12 tools, temperature 0). Larger models (397B, 122B, 35B) all failed at least one test — they ignored tool output and substituted from memory
- F4: Ollama routes Qwen3.5 through wrong tool-calling pipeline as of March 2026 (trained on Qwen3-Coder XML format, Ollama maps to Hermes-style JSON). Tracked at ollama/ollama#14493
- F5: Hermes Agent by Nous Research: MIT license, 8.8k stars, v0.3.0, ~1 month old. Supports Telegram/Discord/Slack, OpenRouter native, built-in memory, skill generation, subagent delegation, cron scheduling, fine-tuning pipeline
- F6: Crumb's spec-first four-phase workflow already produces detailed action plans with acceptance criteria — the content of contracts already exists
- F7: Existing Tess services via OpenClaw: feed-intel pipeline, email triage, morning briefing, overnight research, daily attention, apple data snapshots, vault gardening, heartbeat mechanics
- F8: Crumb's overlay system is operational and composable in interactive sessions
- F9: Haiku cannot reliably execute procedures from SOUL.md in conversational sessions — dedicated session prompts are required for reliable procedure execution (solution: `haiku-soul-behavior-injection`)
- F10: `claude --print` structured output requires 3-6 live deployment iterations per operation class to calibrate prompt-model contract (solution: `claude-print-automation-patterns`)
- F11: Behavioral triggers fail silently under task momentum; mechanical enforcement (hooks, gates, contracts) is the only reliable pattern (solution: `behavioral-vs-automated-triggers`)
- F12: Gate evaluation pattern validated across multiple Crumb projects — criteria defined before execution, evaluator separated from executor, criteria fixed during autonomous period (solution: `gate-evaluation-pattern`)

### 2.2 Assumptions (marked for validation)

- A1: Hermes Agent can connect to local llama.cpp/vLLM servers via OpenAI-compatible API endpoints (not just Ollama) — **validate in Phase 1**
- A2: Qwen3.5 27B tool-calling reliability holds with production-length system prompts (not just clean isolated tests) — **validate in Phase 2**
- A3: A 27B model can reliably assess its own confidence and signal when it's out of its depth — **validate in Phase 2, requires design work**
- A4: The staging → promotion write model (AD-008) is sufficient for vault integrity under concurrent executor operation — **validate in Phase 3 design**
- A5: Contracts derived from action plans provide sufficient completion criteria for fully autonomous execution — **validate incrementally during migration**
- A6: Hermes Agent's memory system can coexist with the vault without creating split-brain state — **validate in Phase 1, constrained by AD-001**
- A7: Tess's personality (SOUL.md, voice, Telegram identity) can transfer intact to a new platform — **validate in Phase 1**

### 2.3 Unknowns

- U1: Hermes Agent stability under sustained 72-hour continuous operation
- U2: Whether GLM-4.7-Flash provides enough performance advantage over Qwen3.5 27B to justify dual-model local routing complexity
- U3: The concrete mechanism for confidence-aware escalation (structured output field? logprob threshold? prompt-engineered self-assessment? hybrid?)
- U4: Staging → promotion implementation details — directory lifecycle, conflict detection for overlapping promotions, cleanup policy
- U5: Real-world token cost of Tess operating 24/7 at moderate volume through OpenRouter
- U6: Whether Hermes Agent's subagent model supports dispatching to Claude Code or Codex specifically
- U7: Contract/Ralph loop/three-gate state machine integration — state diagram, mid-loop escalation behavior, contract immutability rules (PLAN phase design)
- U8: Cost model under bursty conditions — retry storms, escalation cascades, first-instance task classes (PLAN phase design)
- U9: Confidence calibration drift — what happens when production task distribution diverges from calibration set (PLAN phase design)

### 2.4 Known Failure Modes (from external peer review)

Identified by external reviewers. Each should be addressed in Phase 3 design or monitored in production.

| Failure Mode | Description | Mitigation |
|---|---|---|
| **Silent stagnation** | Tess stays busy with maintenance. All metrics green. No revenue-relevant work advances. | Value density metric in health digest (PLAN) |
| **Escalation storm collapse** | Degrading local model → more escalations → higher cost → longer queues → cascading | Load shedding policy (PLAN) |
| **Bad-spec infinite loop** | Contradictory spec → contract can never be satisfied → exhausts retries → re-dispatches without diagnosing root cause | Dead-letter analysis, contract retry class (§9.4) |
| **Observability feedback loop** | Logs in vault → more churn → more validation → degrades system being observed | Logs outside vault (§18.1) |
| **Credential expiry cascade** | Refresh fails → all executors of that type fail → classified as tool failures → retries exhaust | Proactive expiry monitoring (§10b.3) |
| **Promotion race via stale reads** | Two contracts read same artifact, both pass, later promotion silently invalidates earlier | Write-lock table (C9) |
| **Silent contract drift** | Contract passes all checks but output is wrong because source spec was flawed | Evaluator-executor separation (AD-007), periodic spot-checks |
| **Queue poisoning** | Pathological contracts monopolize executor slots | Max-age policy, scheduler fairness (PLAN) |

## 3. System Map

### 3.1 Components

```
┌──────────────────────────────────────────────────────────────────┐
│                        TESS (Orchestrator)                       │
│                                                                  │
│  Platform: Hermes Agent (candidate) or OpenClaw (fallback)       │
│  Brain: Local LLM (Qwen3.5 27B) + frontier escalation           │
│  Personality: SOUL.md (carried forward intact)                   │
│  Interfaces: Telegram, Discord, cron, vault triggers             │
│                                                                  │
│  Responsibilities:                                               │
│  - Classify incoming work (action classes)                       │
│  - Assess complexity + own confidence                            │
│  - Dispatch contracts to executors with overlay injection         │
│  - Monitor executor progress, evaluate returns                   │
│  - Manage dependency ordering between tasks                      │
│  - Escalate to frontier when confidence is low                   │
│  - Surface results to Danny when human decision required         │
│  - Write all state back to vault                                 │
└────────────┬──────────────────────────────┬──────────────────────┘
             │                              │
             ▼                              ▼
┌────────────────────────┐    ┌────────────────────────────────────┐
│     CRUMB VAULT        │    │          EXECUTORS                  │
│                        │    │                                    │
│  Knowledge, specs,     │    │  Claude Code (interactive)         │
│  artifacts, context.   │    │  Codex (OpenAI subscription)       │
│  Single source of      │    │  Claude Sonnet/Opus (OpenRouter)   │
│  truth.                │    │  Gemini (OpenRouter)               │
│                        │    │  Local LLM (routine tasks)         │
│  The noun.             │    │                                    │
│                        │    │  Each receives:                    │
│  Read by Tess +        │    │  - Scoped contract                 │
│  all executors.        │    │  - Relevant overlays               │
│  Written to by Tess    │    │  - Vault read paths                │
│  ONLY (AD-008).        │    │  - Staging write path              │
│  Executors write to    │    │  - Stop conditions                 │
│  isolated staging.     │    │                                    │
└────────────────────────┘    └────────────────────────────────────┘
```

### 3.2 Dependencies

| This depends on | For |
|---|---|
| Hermes Agent (or alternative) | Platform layer — messaging, model routing, scheduling, subagent management |
| Local LLM (Qwen3.5 27B) | Tier 1-2 orchestration decisions at zero marginal cost |
| OpenRouter | Tier 3 frontier escalation, executor routing to Claude/Gemini |
| OpenAI Codex subscription | Code implementation executor (bridge-state) |
| llama.cpp or vLLM | Local LLM serving with correct tool-calling pipeline |
| Crumb vault | All persistent state, specs, artifacts, knowledge |

| Depends on this | For |
|---|---|
| All existing Tess services | Autonomous operation of feed-intel, email triage, briefings, etc. |
| Liberation directive prompts | Revenue-generating autonomous work |
| Danny (human) | High-risk decisions, strategic direction, quality spot-checks |

### 3.3 Constraints

- C1: **Vault authority is non-negotiable.** The Crumb vault is the single source of truth. No executor or platform owns state. (AD-001)
- C2: **Parallel operation during evaluation.** OpenClaw runs production workloads throughout the evaluation period. No flag-day cutover. (AD-002)
- C3: **Tess personality carries forward.** Same SOUL.md, same Telegram bot identity, same voice. New platform, same Tess.
- C4: **Ollama is not usable for Qwen3.5 tool calling** until the pipeline bug is resolved. Use llama.cpp or vLLM.
- C5: **Budget constraint.** Total orchestration cost target under $50/month; hard ceiling $75/month during evaluation and migration periods. The economic case for local LLM is zero marginal cost for 70-90% of decisions.
- C6: **No behavioral triggers for critical operations.** Contracts, stop conditions, and escalation logic must be mechanically enforced, not behaviorally relied upon. (Informed by F11)
- C7: **Evaluator-executor separation.** The agent doing the work must not be the sole judge of whether the work is good. Tess evaluates executor output; executors don't self-certify. (Informed by F12)
- C8: **Staging → promotion write model.** Executors write only to isolated staging directories scoped to their contract ID. Tess is the sole writer to canonical vault paths, promoting artifacts only after contract evaluation passes. No executor writes directly to canonical vault locations. (AD-008)
- C9: **No promotion collisions.** No two active contracts may target the same canonical vault path. Tess maintains a write-lock table: when a contract is dispatched, its target canonical paths are registered. New contracts targeting already-locked paths queue until the first contract's promotion completes or fails. Before promoting, Tess checks the canonical file hasn't changed since dispatch (hash comparison); if it has → conflict, route to dead-letter with "promotion conflict" class. Promotion is atomic per contract — all artifacts move together or none do.

### 3.4 High-Leverage Intervention Points

1. **Contract schema design** — Gets this right and every service, every executor dispatch, every Ralph loop benefits. Gets it wrong and nothing terminates cleanly.
2. **Confidence-aware escalation** — The mechanism that determines whether 70% of decisions are free (local) or expensive (frontier). The entire cost model hinges on this.
3. **Migration sequencing** — Migrating services in the right order (low-risk first, critical last) determines whether the transition is smooth or catastrophic.

### 3.5 Second-Order Effects

> **AC note:** The first bullet below is partially retracted. Danny remains
> session driver *within Crumb*; strategic direction happens on Level 2
> upstream surfaces (claude.ai, Cowork) which feed work into Crumb. The
> other three effects still apply to the scheduled-services side.

- **Danny's role shifts.** From session-by-session driver to strategic director + spot-checker. This changes how Crumb sessions are used — less operational, more architectural.
- **Vault write volume increases.** Multiple executors writing artifacts means more frequent commits, potential merge conflicts, vault-check running more often.
- **Failure modes become distributed.** Instead of one agent failing visibly in a session, failures can be silent across multiple services. Monitoring and alerting become critical.
- **Overlay system must scale.** Currently overlays are loaded manually in Crumb sessions. With dispatch injection, the overlay index becomes runtime routing infrastructure.

## 4. Domain Classification & Workflow

- **Domain:** software
- **Type:** system (infrastructure — Tess is operational infrastructure)
- **Workflow:** Full four-phase (SPECIFY → PLAN → TASK → IMPLEMENT)
- **Rationale:** New architecture, new platform, new execution model. Multiple evaluation phases gate whether migration proceeds. Full rigor justified.
- **External repo:** Hybrid — evaluation phase is vault-native. If migration proceeds, orchestration logic (Hermes config, Ralph loop scripts, contract templates) moves to external repo.

## 5. Architectural Decisions

### AD-001: Vault Authority
Crumb vault is the authoritative source of truth. Hermes Agent memory is session-level convenience only. Executors read from and write to vault paths. Split-brain is the failure mode to prevent.

### AD-002: Parallel Operation
OpenClaw runs in parallel throughout Hermes evaluation. No flag-day cutover. Decommission only after production parity is demonstrated across all migrated services.

### AD-003: Spec + Eval Integration
Tess v2 integrates spec-based and eval-based building. Specs prescribe the work (SPECIFY/PLAN phases produce the blueprint). Contracts derived from specs provide mechanical completion verification (the eval layer). Phase transition gates are eval checkpoints. This is what enables the shift from interactive Crumb sessions to autonomous Tess dispatch.

### AD-004: Ralph Loop Execution
Each dispatched task runs as a Ralph loop — one contract per session, fresh context, hard stop on contract satisfaction. No long-running multi-task sessions. Context bloat is prevented by construction: each contract runs in isolation, Tess orchestrates the sequence.

### AD-005: Overlay Injection at Dispatch
When Tess dispatches a contract to an executor, she passes relevant overlays alongside the task and contract. Overlays shape how the executor reasons during implementation. This extends the existing Crumb overlay system from interactive sessions to autonomous dispatch. Overlays are dispatch metadata — Tess decides which overlays apply based on task classification and project context.

### AD-006: Mechanical Enforcement Over Behavioral Compliance
All critical operations — contract stop conditions, escalation triggers, service health checks, vault write coordination — are mechanically enforced. No critical path depends on an LLM remembering to do something. Informed by `behavioral-vs-automated-triggers` pattern.

### AD-007: Evaluator-Executor Separation
Tess evaluates executor output. Executors do not self-certify completion. A contract being "met" is determined by Tess (or by deterministic checks Tess delegates), not by the executor claiming it's done. Informed by `gate-evaluation-pattern`.

### AD-008: Staging → Promotion Write Model
Executors write to isolated staging directories (`_staging/{contract-id}/`), never to canonical vault paths. Tess evaluates staged artifacts against the contract, then promotes to canonical locations. This ensures: (a) no concurrent writes to the real vault, (b) failed contracts leave no mess, (c) evaluation happens before artifacts are committed. Detailed staging lifecycle (directory cleanup, retention, conflict detection for overlapping promotions to the same canonical path) is Phase 3 design (TV2-015).

### AD-009: Risk-Based Escalation Gate
In addition to the deterministic boundary check (Gate 1) and structured confidence field (Gate 2), a third gate escalates based on task risk class regardless of model confidence. Tasks touching credentials, destructive file operations, external communications, financial actions, or first-instance task classes require frontier review or deterministic policy checks. This catches dangerous failures within known task classes that the model might handle confidently but incorrectly.

### ADs introduced by amendments (pointers)

Subsequent amendments have introduced additional ADs. Load the amendment
docs to get the full text; summaries here for navigation:

- **AD-010** (routing by verifiability) — spec §9 / Amendment X
- **AD-013** (Interactive Dispatch Authority) — **retracted 2026-04-21**
  by AD-017 in Amendment AC. See `spec-amendment-Z-interactive-dispatch.md`
  (superseded) for original framing.
- **AD-014** (Structured Session Reporting) — Amendment Z, retained
- **AD-015** (Vault semantic search three-layer integration) — Amendment AA
- **AD-016** (Tess native tool access admission criteria; *also* staging-to-
  canonical mapping as first-class contract field — numbering collision
  between AA and AB)
- **AD-017** (Orchestrator Role Retraction — retires AD-013) — Amendment AC.
  Tess's role scoped to autonomous execution of 15 scheduled launchd
  services. Not a dispatch authority for operator-interactive work.
- **AD-018** (Execution Surface Division of Labor) — Amendment AC.
  Four-level stack: Operator → Upstream surfaces (claude.ai / Cowork /
  Remote Control) → Crumb / Claude Code → Tess scheduled services.

## 6. Architecture: Three-Tier Decision Model

### 6.1 Tier 1 — Local (free, 70-80% of decisions)

Routine triage, known task-type routing, scheduling, monitoring, status checks, filing, basic context packaging, heartbeats, vault gardening.

**Model:** Qwen3.5 27B (non-thinking mode) — local, always-on, zero marginal cost.

**Characteristics:** Well-defined decision space, structured inputs, low ambiguity. The decision tree is known; the model is executing it, not inventing it.

### 6.2 Tier 2 — Local + Structure (free, 15-20% of decisions)

Semi-novel decomposition where task types are known but the combination is new. Model has structured context: action classes, routing table, executor profiles, project specs from vault.

**Model:** Qwen3.5 27B (thinking mode enabled) — still local, zero marginal cost.

**Characteristics:** Requires reasoning over structured inputs. The decision tree has branches the model hasn't seen in this exact combination, but the components are familiar.

### 6.3 Tier 3 — Frontier Escalation (paid, 5-10% of decisions)

Genuinely novel planning, ambiguous objectives, quality evaluation of complex artifacts, decisions where the local model's confidence is low.

**Model:** Claude Sonnet/Opus via OpenRouter.

**Trigger:** Local model signals low confidence via the escalation mechanism (see §7).

**Characteristics:** Open-ended reasoning, novel problem shapes, high-stakes quality judgments. The local model's structured decision space is insufficient.

### 6.4 Evaluation Note: Single vs. Dual Local Model

The research spike identified GLM-4.7-Flash (~3B active, 60-80+ tok/s) as a potential Tier 1 speed model alongside Qwen3.5 27B for Tier 2. The operator flagged concern about added routing complexity.

**Decision:** Evaluate both models. Compare Tier 1 task performance. Only adopt dual-model routing if the performance delta is large enough to justify the added complexity. The default architecture is single-model (Qwen3.5 27B for both Tier 1 and 2). GLM earns its place with evidence, not with architecture diagrams.

### 6.5 Local Model Runtime Failover

The three-tier model assumes the local model server is available. When it isn't — llama.cpp crashes, OOMs, hangs, or starts returning malformed output after hours of uptime — Tess must degrade gracefully rather than stop operating.

**Health check:** Tess pings the local model server every 60 seconds with a lightweight test prompt (e.g., `{"role":"user","content":"ping"}`). Two consecutive failures → trigger failover.

**Failover sequence:**
1. Attempt automatic restart of the local model server (one attempt)
2. If restart succeeds within 90 seconds → resume normal operation, log the restart
3. If restart fails → attempt backup local model swap (Qwen 3.5 35B MoE), then cloud fallback: all Tier 1 and Tier 2 decisions route to OpenRouter (Kimi K2.5 / Qwen 397B). All services continue at full functionality on cloud routing.
4. If local model remains down > 4 hours → alert Danny. All services continue — cloud cost is negligible (~$0.77/day on Kimi). No service reduction.

**Cost impact of outage:** With Kimi K2.5 pricing ($0.60/$2.40 per M tokens), ~193 daily LLM calls cost ~$0.77/day on full cloud routing. Well within the $75 ceiling. The cost tracker (§18.2) flags extended fallback periods. See `design/local-model-failover.md` for the full five-stage failover design.

**Soak test extension:** The 72-hour soak (§12.2) must also cover the local LLM server. Track: memory growth over time, TTFT drift, malformed output frequency, restart behavior.

## 7. Architecture: Confidence-Aware Escalation

This is the hardest design problem in the spec and requires dedicated attention.

### 7.1 The Problem

The local model must reliably know when it's out of its depth and hand off to a frontier model rather than guessing badly. A 27B model that confidently makes wrong orchestration decisions is worse than one that says "I'm not sure, escalating."

### 7.2 Design Candidates

| Mechanism | How it works | Pros | Cons |
|---|---|---|---|
| **Structured output field** | Every orchestration response includes a `confidence: high/medium/low` field. `low` triggers escalation. | Simple, inspectable, loggable. | Model may not calibrate well — confident when wrong, uncertain when right. |
| **Logprob threshold** | Monitor token-level logprobs on the decision tokens. Low logprobs → escalation. | Objective, not self-reported. | Requires logprob access from serving layer. May not correlate with decision quality. |
| **Prompt-engineered self-assessment** | After generating a decision, model evaluates its own reasoning in a second pass. | Catches some errors. Cheap (same model). | Same model, same blind spots. Sycophancy risk — it wants to confirm its own answer. |
| **Decision-space boundary check** | Tess checks whether the task maps cleanly to a known action class. If not, escalate. | Deterministic, no model judgment needed. | Rigid — misses edge cases within known classes. |
| **Hybrid: boundary check + structured confidence** | Deterministic check first (is this a known task type?). If known, execute. If novel or if model reports low confidence on a known type, escalate. | Covers both structured and fuzzy cases. | Two mechanisms to maintain. |

### 7.3 Recommendation

**Three-gate hybrid approach** — deterministic boundary check, structured confidence field, and risk-based policy gate. (AD-009)

**Gate 1: Deterministic boundary check.** Tess classifies the incoming task against the executor routing table. If the task type is known and the action class is unambiguous → Tier 1, no escalation needed. This is a mechanical check, not a model judgment.

**Gate 2: Structured confidence field.** For tasks that map to known types but have unusual characteristics, or for Tier 2 decisions, the model includes a `confidence` field in its structured output. `low` triggers escalation to Tier 3. For tasks that don't map to any known type → automatic Tier 3 escalation. Novel task types are not the local model's job.

**Gate 3: Risk-based policy escalation.** Regardless of Gates 1 and 2, certain task classes always escalate to Tier 3:
- Tasks touching credentials or secrets
- Destructive file operations (deletion, overwrite of canonical vault paths)
- External communications (email, Telegram messages to Danny, Slack posts)
- Financial actions or commitments
- First-instance task classes (never seen before by this orchestrator)
- Tasks where prior similar contracts scored low on quality evaluation

This gate is deterministic — it checks task metadata against a policy table, not model judgment. It catches dangerous failures within known task classes that a confident-but-wrong local model would mishandle.

**Confidence field schema:**
```yaml
# Included in every Tier 1-2 orchestration response
orchestration_response:
  action_class: "email-triage"        # from routing table
  decision: "route to executor X"
  confidence: "high"                   # high | medium | low
  confidence_reason: "known class, standard parameters"
  risk_flags: []                       # populated by Gate 3 policy check
```

This minimizes the surface area where the model's self-assessment matters — Gate 1 covers known/unknown, Gate 3 covers high-risk regardless, and Gate 2 only needs to be accurate for the middle band of semi-novel, non-high-risk decisions.

### 7.4 Validation Requirements

- Phase 2 Test 6 (Confidence Threshold) is necessary but not sufficient
- Additional tests needed: scenarios where the model *should* be confident (known task types) and scenarios where it *should not* be (novel, ambiguous). Measure calibration: does confidence correlate with actual decision quality?
- Production-length prompt test: does confidence calibration hold when the system prompt is 8-15K tokens (realistic Tess context)?

### 7.5 Human Escalation Taxonomy

When Tess determines a decision requires Danny (via Gate 3 risk policy, quality check failure, or retry budget exhaustion), she classifies the escalation. This is a permanent cross-cutting runtime policy, not migration-specific.

| Class | Response Time | Channel | Timeout Behavior |
|---|---|---|---|
| **Urgent/blocking** | ASAP | Telegram push notification | Queue task, re-alert after 4 hours. Do not auto-resolve. |
| **Review-within-24h** | Within 24 hours | Telegram message + vault flag in daily attention | If no response in 24h, reclassify to FYI digest. Log the reclassification. Don't execute autonomously — stop holding the queue. |
| **FYI digest** | No response needed | Batch into daily attention digest | Auto-archive after 7 days if no action taken. |

**Danny-unavailable graceful degradation (tiered timeout):**

| Task class | Timeout | Behavior |
|---|---|---|
| **Truly blocked** (credentials, destructive ops, financial) | None — queue indefinitely | Danny must act. No timeout. No auto-resolution. |
| **Time-sensitive review** (email triage results, meeting prep) | 24 hours | Reclassify to FYI digest. Log reclassification. Stop holding queue. |
| **Low-risk review** (vault gardening results, routine quality checks) | 48 hours | Tess promotes if quality checks passed, with `auto-promoted-after-timeout` flag in ledger. Danny can review and revert during next attention cycle. |

**Contract schema integration:** Add `requires_human_approval: true` flag to contracts targeting destructive operations, `_system/` modifications, or first-instance task classes (set automatically via Gate 3 policy). This flag blocks promotion even if Tess approves quality.

## 8. Architecture: Contract-Based Execution

### 8.1 What Is a Contract

A contract is a machine-readable specification of what must be true before a dispatched task is considered complete. It is the eval layer on top of the spec layer.

**Provenance:** This pattern integrates eval-based building with Crumb's existing spec-first workflow. The spec defines *how* to build. The contract defines *when done* and *whether good*. Crumb's action plans already contain the content of contracts — the integration adds mechanical enforcement as hard termination gates.

### 8.2 Contract Schema

```yaml
contract_id: TV2-001-C
task_id: TV2-001
description: "Migration inventory of all existing Tess operational wiring"
created: 2026-04-01
staging_path: "_staging/TV2-001-C/"  # executor writes here, not canonical vault

# Deterministic checks — mechanically verified by runner (BLOCKING)
# Executor cannot terminate until ALL pass
tests:
  - type: file_exists
    path: "_staging/TV2-001-C/migration-inventory.md"
  - type: frontmatter_valid
    path: "_staging/TV2-001-C/migration-inventory.md"
    required_fields: [type, status, created]

# Artifact verification — structured checks run by runner (BLOCKING)
# Must pass before executor can terminate
artifacts:
  - description: "Inventory covers all OpenClaw cron jobs"
    verification: "grep -c 'ai.openclaw' migration-inventory.md >= 5"
    executor: runner  # deterministic shell check
  - description: "Each service has migrate/rebuild/drop classification"
    verification: "frontmatter action_class present on all service entries"
    executor: runner

# Quality checks — requires judgment (ADVISORY, post-termination)
# Evaluated by Tess AFTER executor terminates and artifacts are staged
# Does NOT block executor termination — blocks vault PROMOTION
quality_checks:
  - description: "No critical service missed"
    evaluator: tess
  - description: "Classifications are reasonable"
    evaluator: tess

# Partial completion policy
partial_promotion: hold_for_review  # discard | hold_for_review | promote_passing
# - discard: staging abandoned on contract failure
# - hold_for_review: Danny reviews during dead-letter processing, can promote passing artifacts
# - promote_passing: artifacts that individually passed promote; failing artifacts stay in staging
# Promotion is ATOMIC per contract — all promotable artifacts move together or none do

# Stop condition for executor (tests + artifacts only)
termination: "ALL tests pass AND ALL artifacts verified"
# Promotion condition (adds quality_checks)
promotion: "termination satisfied AND ALL quality_checks pass"
retry_budget: 3  # Max Ralph loop iterations before escalation
escalation: "tess"  # Who to notify if retry budget exhausted
```

**Check type semantics:**
- **tests**: Deterministic, mechanically verified by the runner. BLOCKING — executor cannot terminate.
- **artifacts**: Structured checks, run by the runner or Tess. BLOCKING — executor cannot terminate.
- **quality_checks**: Judgment-dependent, evaluated by Tess after executor completes. ADVISORY for executor termination, BLOCKING for vault promotion. This preserves evaluator-executor separation (AD-007) — the executor doesn't wait for Tess's judgment, but artifacts don't land in the canonical vault until Tess approves.

### 8.3 Contract Derivation

Contracts are derived from action plans during the TASK phase. The action-architect skill produces tasks with acceptance criteria; contract generation transforms those criteria into the schema above. This is a mechanical transformation, not a creative act.

### 8.4 Relationship to Phase Gates

Phase transition gates in Crumb's four-phase workflow are themselves contracts:
- SPECIFY gate: spec completeness criteria → contract
- PLAN gate: plan coverage and feasibility criteria → contract
- TASK gate: task decomposition quality criteria → contract
- IMPLEMENT gate: all task contracts satisfied → phase contract

## 9. Architecture: Ralph Loop Execution

### 9.1 What Is a Ralph Loop

The execution primitive for contract-based work. A focused iteration loop where an agent works on a single contract with accumulated failure context until the contract is satisfied.

**Provenance:** Named after the "Ralph Wiggum loop" pattern. The conversation analysis identified that Crumb's contract + fresh-session model is already building toward this pattern. Ralph loops are what falls out of asking "how do we integrate eval-based building with spec-first workflow at the execution layer?"

### 9.2 Mechanics

```
Tess dispatches contract + overlays + vault context
    │
    ▼
┌─────────────────────────────────────────────┐
│  RALPH LOOP (one contract, fresh context)   │
│                                             │
│  Iteration 1:                               │
│    Agent receives: contract + context        │
│    Agent executes: work toward contract      │
│    Check: contract satisfied?                │
│      YES → terminate, return artifacts       │
│      NO  → capture failure context           │
│                                             │
│  Iteration 2:                               │
│    Agent receives: contract + context         │
│                    + iteration 1 failure      │
│    Agent executes: adjusted approach          │
│    Check: contract satisfied?                │
│      YES → terminate, return artifacts       │
│      NO  → capture failure context           │
│                                             │
│  ... (up to retry_budget iterations)         │
│                                             │
│  Retry budget exhausted:                     │
│    Escalate to Tess with failure summary     │
└─────────────────────────────────────────────┘
    │
    ▼
Tess receives artifacts (or escalation)
Tess evaluates against contract quality_checks
Tess files artifacts to vault
```

### 9.3 Design Principles

- **One contract per session.** No cross-task context contamination. Each Ralph loop is isolated.
- **Fresh context per iteration.** The loop feeds back failure context, not the entire previous session. Keeps context focused.
- **Hard stop on contract satisfaction.** The loop terminates mechanically, not by agent judgment.
- **Retry budget prevents infinite loops.** If the contract can't be satisfied in N iterations, escalate — don't loop forever.
- **Tess orchestrates the sequence.** Ralph loops don't know about each other. Tess manages dependency ordering and sequencing across contracts.

### 9.4 Retry Failure Classes

Not all failures should be retried the same way. When a Ralph loop iteration fails, classify the failure before retrying:

| Failure Class | Cause | Retry Strategy |
|---|---|---|
| **Deterministic** | Bad input, missing file, schema error | Fix input/environment, retry same executor |
| **Reasoning** | Wrong approach, hallucinated logic, missed requirement | Escalate model tier (Tier 1 → 2 → 3) |
| **Tool** | API down, timeout, rate limit | Defer/requeue with backoff |
| **Semantic** | Repeated identical failure across 2+ iterations | Route to alternate executor or escalate to human |

The retry budget (default 3) applies across all classes. If iteration 1 fails with a reasoning error, iteration 2 should escalate the model, not repeat the same approach at the same tier.

### 9.5 Prior Art Integration

From `claude-print-automation-patterns`:
- **Runner owns deterministic fields.** Tess injects contract metadata, executor focuses on content (Pattern 1).
- **Contract file as durable instruction surface.** The contract YAML serves the same role as CLAUDE.md for `--print` sessions — authoritative, machine-readable, not conversational suggestion (Pattern 2).
- **Budget 3-6 iterations for first operation class.** New executor types will need calibration (Pattern 4).

## 10. Architecture: Overlay Injection at Dispatch

### 10.1 How It Works

When Tess dispatches a contract, she determines which overlays apply based on:
1. Task type → default overlays from routing table
2. Project context → project-specific overlays
3. Explicit overlay requests from the operator

**Token budget constraint:** The total dispatch context (contract + overlays + vault context + failure context from prior iterations) must not exceed the executor's effective reasoning window. For local LLM (Qwen3.5 27B): hard cap of 16K tokens for dispatch context, leaving the remaining context window for the executor's working memory. For frontier executors: 32K token cap. Tess validates the dispatch envelope against this budget before sending — if it exceeds the cap, reduce overlays (least-specific first) or truncate vault context.

**Maximum overlays per dispatch:** 3. If more than 3 overlays are relevant, Tess selects the 3 most specific to the task. This prevents silent instruction-ignoring from context overload.

The dispatch envelope includes:
```yaml
dispatch:
  contract: TV2-001-C
  executor: claude-sonnet
  staging_path: "_staging/TV2-001-C/"
  overlays:
    - security  # task involves auth or data handling
    - cost-optimization  # budget-constrained project
  vault_context:
    read_paths: [...]
  token_budget:
    limit: 32000  # frontier executor
    estimated: 14200  # contract + overlays + context
```

### 10.2 Two Layers

- **Tess's orchestration overlays** inform *what* work gets done and in *what* order (priority, risk assessment, resource allocation).
- **Executor's injected overlays** inform *how* that work gets done (implementation approach, quality criteria, domain perspective).

Both layers use the same overlay files from `_system/docs/overlays/`. The overlay index gains a new column: `dispatch_eligible: true/false` — not all overlays make sense for automated dispatch (e.g., Life Coach is interactive-only).

### 10.3 Executor Return Envelope

Every executor returns a structured result that Tess can parse mechanically:

```yaml
execution_result:
  contract_id: TV2-001-C
  status: completed | failed | escalated
  iterations: 2
  staging_path: "_staging/TV2-001-C/"
  artifacts_produced:
    - path: "_staging/TV2-001-C/migration-inventory.md"
      sha256: "a1b2c3..."
  test_results:
    - test: file_exists
      result: pass
    - test: frontmatter_valid
      result: pass
  failure_summary: null  # populated on failure/escalation
  failure_class: null     # deterministic | reasoning | tool | semantic
  token_usage:
    input: 12400
    output: 3200
```

This standardizes how Tess evaluates returns, manages retries, and tracks costs across all executor types. Detailed schema finalized in Phase 3 (TV2-013).

## 10b. Tess Prompt Architecture

The three-tier decision model and executor dispatch both depend on Tess having the right context. How that context is composed, versioned, and managed is a cross-cutting concern.

### 10b.1 Prompt Layers

| Layer | Contents | Budget | Always present? |
|---|---|---|---|
| **Stable header** | Identity (SOUL.md excerpt), role definition, current date/time, active constraints | <2K tokens | Yes |
| **Service context** | Routing table entries, action class definitions, executor profiles relevant to current task | 2-4K tokens | Per-dispatch |
| **Overlays** | Injected behavioral overlays (max 3 per dispatch) | 1-3K tokens | Per-dispatch |
| **Vault context** | Read paths specified per-contract — specs, project state, relevant artifacts | Remaining budget | Per-dispatch |
| **Failure context** | Prior iteration failures (Ralph loop iterations 2+) | 1-2K tokens | Iterations 2+ only |

### 10b.2 Composition Rules

- Total envelope must fit within dispatch token budget: 16K (local executor), 32K (frontier executor). Calibrate based on Phase 2 Test 8 results.
- **Compaction order** when envelope exceeds budget: (1) vault context — most distant files first, (2) overlays — least specific first, (3) service context — truncate routing table to relevant entries only. Never truncate the stable header.
- Prompt components live in the vault as markdown files. Changes are tracked by vault-check and picked up on next dispatch cycle. No restart required.

### 10b.3 Credential Injection

Executors need API keys (OpenRouter, Google Workspace, Telegram). These are handled separately from the prompt:

- **Credential store:** macOS Keychain for secrets. The vault stores credential *metadata* (which services need which credentials, expiry dates) but **never** the secrets themselves.
- **Injection:** Tess passes credentials to executors via environment variables scoped to the Ralph loop session. Credentials never appear in logs, contracts, staging artifacts, or vault files.
- **Refresh:** Google OAuth refresh handled by existing gws tooling. OpenRouter/Telegram keys are long-lived. For any credential with an expiry, Tess checks expiry dates daily and alerts Danny 7 days before expiration.
- **Audit:** Credential *type* (not value) logged in the contract execution ledger.
- **Detailed design** (injection mechanism, refresh failure handling, least-privilege scoping per executor): Phase 3 (TV2-015).

## 11. Architecture: Service Model

### 11.1 What Is a Tess Service

A named, always-available operational function with a defined contract, input interface, output interface, and health check. Services are the unit of Tess's operational capacity.

### 11.2 Current Services (Migration Candidates)

| Service | Current Platform | Trigger | Status |
|---|---|---|---|
| Feed-intel pipeline | OpenClaw cron | Scheduled (hourly) | Active, 148 items in queue |
| Email triage | OpenClaw cron | Scheduled (every 30 min) | Active, soak-validated |
| Morning briefing | OpenClaw cron | Scheduled (daily 7am) | Active |
| Overnight research | OpenClaw cron | Scheduled (nightly) | Disabled (broken data sources) |
| Daily attention | OpenClaw cron | Scheduled (daily) | Active |
| Apple data snapshots | LaunchAgent (danny) | Scheduled (every 30 min) | Active (stays — danny's domain) |
| Heartbeat mechanics | OpenClaw cron | Scheduled (every 15 min) | Active |

### 11.3 Service Schema

Each service will be documented with:
```yaml
service_name: email-triage
description: "Classify incoming email, route actions, alert on urgent"
trigger: scheduled
schedule: "*/30 * * * *"
input: Gmail API (via gws)
output: classification log, urgent alerts to Telegram
contract: "All emails since last run classified. Zero @Risk/High emails missed."
health_check: "Last successful run < 60 minutes ago"
failure_mode: "Alert Danny via Telegram. Queue emails for next run."
dependencies: [gws OAuth token, Gmail API access]
```

### 11.4 New Services (Post-Migration)

Tess v2 enables new service types that aren't possible with the current architecture:
- **Contract executor service** — dispatches and monitors Ralph loops
- **Quality evaluation service** — evaluates executor returns against contracts
- **Vault coordination service** — manages write ordering when multiple executors are active

## 12. Platform Evaluation: Hermes Agent

### 12.1 Evaluation Criteria

Score each 1-5 (detailed scenarios in research spike):
1. Installation & setup on macOS
2. Telegram reliability (message delivery, latency, voice memos)
3. Model switching (OpenAI, OpenRouter, local Ollama/llama.cpp/vLLM)
4. Tool calling reliability with chosen model
5. Memory persistence across sessions (vault is authoritative — Hermes memory is convenience)
6. Skill generation (auto-generates reusable skill docs from experience)
7. Cron scheduling with delivery to Telegram
8. Subagent delegation (parallel task dispatch and report-back)
9. Vault integration (read/write Obsidian markdown via file tools)
10. Stability (crash frequency, error handling, memory leaks)
11. Ralph loop support — can Hermes natively support strict iteration budgets, failure context injection between iterations, and mechanical hard stops based on contract satisfaction? Or must Ralph loops be implemented as external scripts that Hermes triggers?

### 12.2 72-Hour Soak Test (Added per Crumb feedback)

After feature evaluation, run Hermes + local LLM server for 72 hours continuously:
- Track: crashes, recovery behavior, memory usage over time, silent failures, message delivery reliability
- Track local LLM server specifically: memory growth, TTFT drift over time, malformed output frequency
- Simulate moderate load: 2-3 cron jobs running, periodic Telegram interactions, model switches
- Compare against OpenClaw's known stability profile

### 12.3 Pass/Fail Criteria

- No single criterion below 3/5
- Average across all criteria ≥ 3.5/5
- 72-hour soak — **recoverability over zero-crashes:**
  - ≤2 crashes with clean recovery (no data loss, no state corruption, auto-restart within 60 seconds)
  - Memory growth <20% over 72 hours (both Hermes and local LLM server)
  - No silent message drops (Telegram delivery verified)
  - No missed scheduled tasks
  - MTTR < 2 minutes (mean time to recovery from any failure)
- Must confirm: can connect to local llama.cpp/vLLM via OpenAI-compatible API (A1)
- Must confirm: SOUL.md personality transfer viable (A7)

### 12.4 If Hermes Fails

Stay on OpenClaw for messaging. Build custom orchestration logic between OpenClaw and models. Use OpenRouter as model routing layer (bypassing OpenClaw's broken routing). Same three-tier architecture applies — different platform layer.

## 13. Local LLM Evaluation

Evaluation has two layers: a **benchmark harness** that tests model capabilities mechanically (throughput, tool-call formatting, structured output), and **orchestration decision tests** that evaluate situational judgment. Both must pass. Full benchmark protocol: `design/local-model-eval-protocol.md`.

### 13.1 Candidate Models

| Model | Quant | Size Est. | Why test it |
|---|---|---|---|
| **Qwen 3.5 27B dense** | Q4_K_M | ~18GB | Leading candidate — all-green on independent tool-calling tests. Dense (all 27B active). 262K native context. |
| **Qwen 3.5 27B dense** | Q6_K | ~22GB | 96GB unified memory can afford higher quant — measure the quality delta vs Q4 |
| **Qwen 3.5 35B MoE** | Q4_K_M | ~20GB | Speed comparison vs dense; does MoE routing hurt tool-call reliability? |
| **GLM-4.7-Flash** | Q4_K_M / Q8 | ~10-18GB | Purpose-built for agentic workflows. MoE 30B-A3B (~3B active). Very fast. Dual-model candidate. |
| **Nemotron Cascade 2** | IQ4_XS | TBD | High tok/s reports; needs quality validation on our workloads |
| **Qwen3-coder 30B** | Q4_K_M | ~20GB | Already deployed as tess-mechanic — establishes the baseline for comparison |

### 13.2 Benchmark Harness

Single entry point: `benchmark-model.sh <path-to-gguf>` → scorecard row in SQLite.

**Throughput tests** (automated via llama-bench):
- tok/s and TTFT at 4 context lengths: 4K, 16K, 64K, 128K
- Peak memory at each context length
- Context ceiling (binary search for max before OOM or >50% degradation)
- 60-second thermal cooldown between context lengths (M3 Ultra throttles under sustained load)

**Quality tests** (21 prompts, scored):
- Tool-call formatting (5 prompts) — must produce parseable, correct tool calls
- Routing decision (5 prompts) — correct executor selection given intent + descriptions
- Structured output (5 prompts) — valid JSON/YAML on demand
- Multi-step planning (3 prompts) — sensible task decomposition (scored 1-5)
- Refusal/guardrail (3 prompts) — correct escalation of out-of-scope requests

All prompts include the actual Tess system prompt — testing the model *in situ*, not in isolation.

**Pass thresholds** (from protocol):
- tok/s ≥ 20 @ 4K, ≥ 10 @ 64K
- TTFT ≤ 500ms @ 4K, ≤ 2000ms @ 64K
- Tool-call formatting ≥ 0.8, routing ≥ 0.8, structured output ≥ 0.8
- Guardrail = 1.0 (non-negotiable)
- Context ceiling ≥ 64K
- `viable` flag set only if ALL thresholds pass

**Backend consideration:** llama.cpp is the default. MLX (Apple-native) may extract more from the M3 Ultra's GPU cores. Run the same battery on both backends for at least one model to quantify the difference.

### 13.3 Orchestration Decision Tests

These test situational judgment — the kind of decisions Tess makes in production. Complement the benchmark harness (which tests mechanical capability).

Seven orchestration decision tests (detailed in research spike): tool-calling chain (CRITICAL gate), task triage, context packaging, model routing, quality evaluation, confidence threshold, multi-step tool chain.

**Added per Crumb feedback:**
- **Test 8: Production-length prompt degradation.** Run Tests 1, 2, and 7 with a realistic production-length system prompt (8-15K tokens including SOUL.md, routing table, service definitions, vault context). Compare results against clean isolated prompts. If structured reasoning degrades significantly (>20% quality drop), the three-tier architecture collapses — flag and reassess.

### 13.4 Combined Pass Criteria

**Benchmark harness:** All thresholds in §13.2 must pass (`viable` = 1).

**Orchestration tests:**
- Tests 1 & 7 (tool calling) must score 5/5 on tool fidelity — **non-negotiable**
- Average correctness ≥ 4.0 across all tests
- No test scores below 3 on correctness
- At least 2/3 consistency on repeated runs
- **Test 8 must not show >20% quality degradation** from isolated to production-length prompts

A model must pass BOTH the harness AND the orchestration tests to be viable for Tess v2 orchestration.

### 13.5 Dual-Model Decision

After both models are tested:
- If GLM-4.7-Flash scores ≥ Qwen3.5 on Tier 1 tasks AND is ≥2x faster → dual-model stack justified
- If the delta is marginal → single-model (Qwen3.5 for both tiers). Simplicity wins.
- Document the decision with data, not opinion.

### 13.6 If Local LLM Fails

Tess orchestrates via OpenRouter (Sonnet default, Opus for hard decisions). Local model handles only Tier 1 mechanical tasks (heartbeats, basic filing). Tiers 2 and 3 both go to frontier — higher cost but reliable. Re-evaluate when next generation of local models ships.

## 14. Migration

### 14.1 Migration Inventory (Pre-Evaluation Task)

Before evaluating Hermes or local LLMs, catalog everything that needs to migrate:

| Category | Items | Action Classes |
|---|---|---|
| Cron jobs | All `ai.openclaw.*` launchd services | migrate / rebuild / drop |
| SOUL.md | Personality, voice, behavioral rules | migrate intact (C3) |
| Prompt configs | Morning briefing, email triage, overnight research, daily attention | migrate (adapt to new platform format) |
| Scripts | `_openclaw/scripts/` — snapshot, triage, pipeline scripts | evaluate — some are bash (platform-independent), some are OpenClaw-specific |
| State files | `_openclaw/state/` — context, health notes, last-run timestamps | migrate (directory may change) |
| OAuth/credentials | Google workspace tokens, Telegram bot token | migrate (credential store may change) |
| Data files | `_openclaw/data/` — scout digests, feed databases | migrate (path references may change) |

### 14.2 Migration Sequence

Low-risk services first, critical services last:
1. **Heartbeats** — lowest risk, easiest to verify
2. **Vault gardening** — low risk, deterministic
3. **Feed-intel pipeline** — moderate complexity, well-understood
4. **Daily attention / overnight research** — moderate complexity
5. **Email triage** — higher risk (soak-validated, production quality requirements)
6. **Morning briefing** — highest visibility (Danny relies on this daily)

**Non-migrating services (retained on current platform):**
- **Apple data snapshots** — stays on LaunchAgent in danny's domain. Platform-independent.

Each service migrates through: configure on new platform → parallel run → compare output → cut over → decommission old.

### 14.3 Parallel Operation Protocol

During migration, both OpenClaw and the new platform run simultaneously:
- New platform outputs go to a staging directory, not production paths
- Compare staging vs. production output for each service
- Cut over only when staging output matches or exceeds production quality
- Rollback: re-enable OpenClaw service, disable new platform service

## 15. Task Decomposition

### Phase 0: Pre-Evaluation
| ID | Task | Type | Risk | Depends On |
|---|---|---|---|---|
| TV2-001 | Migration inventory — catalog all existing Tess operational wiring | #research | low | — |
| TV2-002 | Establish evaluation environment — build llama.cpp, download models | #code | low | — |

### Phase 1: Platform Evaluation
| ID | Task | Type | Risk | Depends On |
|---|---|---|---|---|
| TV2-003 | Install and configure Hermes Agent on Mac Studio | #code | medium | — |
| TV2-004 | Run 7 Hermes evaluation scenarios, score results | #research | medium | TV2-003 |
| TV2-005 | 72-hour Hermes stability soak test | #research | low | TV2-003 |
| TV2-006 | Hermes go/no-go decision with documented rationale | #decision | high | TV2-004, TV2-005 |

### Phase 2: Local LLM Evaluation
| ID | Task | Type | Risk | Depends On |
|---|---|---|---|---|
| TV2-007 | Qwen3.5 27B setup via llama.cpp or vLLM with correct chat template | #code | medium | TV2-002 |
| TV2-008 | Run 8 orchestration decision tests against Qwen3.5 27B | #research | medium | TV2-007 |
| TV2-009 | GLM-4.7-Flash setup and comparative testing | #code #research | medium | TV2-002 |
| TV2-010 | Single vs. dual local model decision with data | #decision | medium | TV2-008, TV2-009 |
| TV2-011 | Local LLM go/no-go decision | #decision | high | TV2-008, TV2-010 |

### Phase 3: Architecture Design (gated by Phase 1-2 results)
| ID | Task | Type | Risk | Depends On |
|---|---|---|---|---|
| TV2-012 | Confidence-aware escalation mechanism — detailed design + validation | #research #code | high | TV2-011 |
| TV2-013 | Contract schema design — finalize YAML schema, build validation tooling | #code | medium | TV2-006 |
| TV2-014 | Service interface definitions for all migrating services | #research | medium | TV2-001 |
| TV2-015 | Vault concurrent access model design | #research | medium | — |

### Phase 4: Migration (gated by Phase 3)
| ID | Task | Type | Risk | Depends On |
|---|---|---|---|---|
| TV2-016 | Initialize external repo for orchestration logic | #code | low | TV2-006, TV2-013 |
| TV2-017 | Migrate services (sequence per §14.2) | #code | high | TV2-014, TV2-015, TV2-016 |
| TV2-018 | Parallel operation validation — all services running on both platforms | #research | high | TV2-017 |
| TV2-019 | Production cutover — decommission OpenClaw for migrated services | #decision | high | TV2-018 |

**Note:** Phases 1 and 2 can run in parallel — they are independent evaluations.

**Task ID reconciliation:** The preliminary IDs above (TV2-001 through TV2-019) are superseded by the refined 49-task decomposition in `design/tasks.md`. The task list is authoritative for task IDs, dependencies, acceptance criteria, and current state. See tasks.md for the mapping.

## 16. Success Criteria

### Evaluation Success (Phases 1-2)
- Clear go/no-go on Hermes Agent with documented rationale
- Clear go/no-go on Qwen3.5 27B (and GLM if tested) with documented rationale
- All test results documented in vault

### Architecture Success (Phase 3)
- Confidence-aware escalation mechanism designed and validated
- Contract schema finalized with working validation tooling
- All services have defined interfaces

### Migration Success (Phase 4)
- All migrated services running on new platform with quality ≥ OpenClaw baseline
- No missed user-critical outputs during cutover; no interruption > 30 minutes for non-critical services; automatic rollback on two consecutive failed runs
- Total orchestration cost under $50/month target (hard ceiling $75 during migration)
- Tess autonomously dispatching contracts and evaluating results without Danny in the loop

### Overall Project Success

> **AC note (2026-04-21):** The orchestrator framing below is retracted.
> Revised success criteria under AC:
> - The 15 scheduled `com.tess.v2.*` services run reliably without operator
>   attention (health-ping, vault-health, FIF capture/attention, Scout
>   pipeline, daily-attention, overnight-research, connections-brainstorm,
>   etc.)
> - Work from Level 2 upstream surfaces (claude.ai, Cowork) flows cleanly
>   into Crumb execution via the upstream work bridge (design deferred).
> - The vault remains the single source of truth.
> - Danny remains session driver in Crumb, with strategic thinking on
>   upstream surfaces.

- Tess operates as an autonomous orchestrator, not a notification layer
- Work gets done while Danny sleeps
- The vault remains the single source of truth
- Danny's role shifts from session driver to strategic director

## 17. Cost Model

| Tier | Volume | Cost | Monthly Estimate |
|---|---|---|---|
| Tier 1 (local, non-thinking) | 70-80% of ~100 decisions/day | Free | $0 |
| Tier 2 (local, thinking) | 15-20% of ~100 decisions/day | Free | $0 |
| Tier 3 (frontier escalation) | 5-10% of ~100 decisions/day | ~$0.01-0.05/decision via OpenRouter | $1.50-15 |
| Executor: Codex | Variable | OpenAI subscription | Included |
| Executor: Claude API | Variable | Per-token via OpenRouter | $5-30 (usage dependent) |
| Executor: Gemini | Variable | Per-token via OpenRouter | $2-10 (usage dependent) |
| **Total estimated** | | | **$10-55/month** |

## 18. Observability and Failure Detection

Autonomous operation with distributed executors creates failure modes that are invisible without deliberate monitoring. This section defines minimum observability requirements.

### 18.1 Storage Separation

**Raw operational telemetry lives outside the vault** at `~/.tess/logs/`. Writing high-volume logs to the vault bloats Git history and creates an observability feedback loop (more vault writes → more validation → larger contexts → degraded performance of the system being observed).

**Semantic summaries live in the vault.** The daily health digest (§18.2) is a semantic artifact — it belongs in the vault. Raw run logs, ledger entries, and cost data do not.

A symlink from `_tess/logs/` → `~/.tess/logs/` provides convenience access from the vault without Git tracking.

### 18.2 Monitoring Surfaces

| Surface | What it captures | Storage | Alert threshold |
|---|---|---|---|
| **Service run log** | Per-service execution: start time, duration, outcome, errors | `~/.tess/logs/services/{service-name}.log` | 2 consecutive failures → Telegram alert |
| **Contract execution ledger** | Every dispatched contract: ID, executor, iterations, outcome, cost | `~/.tess/logs/contract-ledger.yaml` | Retry budget exhausted → Telegram alert |
| **Escalation log** | Every Tier 3 escalation: trigger gate (1/2/3), task, model used, cost | `~/.tess/logs/escalation-log.yaml` | Escalation rate > 20% over 24h → review |
| **Vault write log** | Every staging → promotion: contract ID, paths promoted, timestamp | `~/.tess/logs/vault-writes.yaml` | Promotion failure → Telegram alert |
| **Cost tracker** | Daily token usage and cost by tier and executor | `~/.tess/logs/cost-tracker.yaml` | Daily cost > $5 → Telegram alert |

### 18.3 Health Digest

Tess produces a daily health digest (folded into morning briefing or standalone):
- Services: which ran, which failed, which were skipped
- Contracts: dispatched, completed, failed, escalated
- Escalation rate: % of decisions that went to Tier 3
- Cost: daily and rolling 7-day average
- Anomalies: any service that hasn't run in > 2x its expected interval

### 18.4 Dead-Letter Queue

Failed contracts that exhaust their retry budget and cannot be resolved by escalation are moved to a dead-letter queue (`~/.tess/dead-letter/`). Each entry includes the contract, failure summary, all iteration logs, and the escalation attempt. Danny reviews dead-letter items during daily attention.

### 18.5 Implementation Note

Observability infrastructure is a Phase 3 task. Extend TV2-014 (service interface definitions) to include monitoring surfaces for each service. The logging paths above are directional — exact locations finalized during implementation.
