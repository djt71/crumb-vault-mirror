---
type: reference
domain: software
status: active
created: 2026-04-21
updated: 2026-04-21
tags:
  - index
  - tess-v2
  - durable-patterns
  - compound-engineering
---

# Tess v2 — Durable Engineering Patterns

## Purpose

Tess v2 produced a large body of design artifacts (55+ documents in
`Projects/tess-v2/design/`). Most of that work encodes engineering patterns
that apply beyond tess-v2 itself — contract schemas, Ralph loops,
staging/promotion, escalation policies, observability design. This index
catalogs those patterns so the knowledge isn't invisible if the project
is ever narrowed, archived, or restructured.

The narrowing of tess-v2 by Amendment AC (2026-04-21) — retracting Tess's
orchestrator role and scoping it to autonomous scheduled services — does
*not* retire any of the patterns below. They continue to drive the
production contract runner at `/Users/tess/crumb-apps/tess-v2/` and remain
applicable to any future LLM-in-a-role design work.

## Curation Status

- **Tagged in place:** Each document below carries `scope: general` in its
  frontmatter and a `## Scope` section noting its applicability beyond
  tess-v2. Search with `obsidian properties scope=general` to surface them
  without going through the project folder.
- **Extracted to `_system/docs/solutions/`:** Three patterns were distilled
  into dedicated solution docs because they are compressed enough to stand
  alone. See "Extracted patterns" below.
- **Not extracted:** The remaining patterns have too much detail for clean
  extraction without loss. The source docs are the canonical home.

## Extracted Patterns

Three patterns lifted to `_system/docs/solutions/` for standalone findability:

| Pattern | Solution doc | Source |
|---|---|---|
| Live soak > synthetic benchmark for role-fit | [live-soak-beats-benchmark.md](solutions/live-soak-beats-benchmark.md) | `model-hermes-crumb-evaluation-frame-2026-04-20.md` |
| Staged spike with bail checkpoints | [staged-spike-with-bail.md](solutions/staged-spike-with-bail.md) | `paperclip-spike-decision-2026-04-12.md` |
| Lenient parsing before contract evaluation | [lenient-parsing-before-evaluation.md](solutions/lenient-parsing-before-evaluation.md) | `response-harness-analysis.md`, `spec-amendments-harness.md` |

## Patterns Tagged In Place

Categorized by area. All paths are relative to vault root.

### Contract execution

| Pattern | Source |
|---|---|
| Contract YAML schema (tests / artifacts / quality_checks; closed schemas; V1/V2/V3 verifiability) | `Projects/tess-v2/design/contract-schema.md` |
| Ralph loop: one contract per session, fresh context, hard stop, cumulative failure-context compaction | `Projects/tess-v2/design/ralph-loop-spec.md` |
| Contract lifecycle state machine: states, transitions, immutability rules, mid-loop escalation | `Projects/tess-v2/design/state-machine-design.md` |
| Harness amendments: structured diagnostics, closed-schema principle, convergence rate as escalation signal, verifiability tiers, plan-before-request | `Projects/tess-v2/design/spec-amendments-harness.md` |
| AutoBE harness analysis (parser quirks, recoverable errors, per-executor profiles) | `Projects/tess-v2/design/response-harness-analysis.md` |
| Interactive-dispatch schemas (superseded thesis, retained schemas: dispatch queue, claims, session report, startup hook) | `Projects/tess-v2/design/spec-amendment-Z-interactive-dispatch.md` |

### Prompt composition

| Pattern | Source |
|---|---|
| Five-layer prompt architecture (header / service / overlay / vault / failure); token budgets per layer; compaction priority | `Projects/tess-v2/design/system-prompt-architecture.md` |

### Staging and vault writes

| Pattern | Source |
|---|---|
| Staging → promotion: write-lock table, hash-based conflict detection, atomic promotion, crash-recovery manifest | `Projects/tess-v2/design/staging-promotion-design.md` |

### Escalation and load management

| Pattern | Source |
|---|---|
| Three-gate hybrid escalation (deterministic boundary / structured confidence / risk-based policy) | `Projects/tess-v2/design/escalation-design.md` |
| Escalation storm policy: 2-of-4 trigger detection, three-level load shedding, gradual recovery | `Projects/tess-v2/design/escalation-storm-policy.md` |
| Queue fairness: priority classes, per-class max-age, pathological-contract detection, round-robin with age-boost | `Projects/tess-v2/design/queue-fairness-policy.md` |

### Observability and cost

| Pattern | Source |
|---|---|
| Observability: logs outside vault (symlinked), structured ledger, dead-letter queue, 8-section health digest, 12-surface alert thresholds | `Projects/tess-v2/design/observability-design.md` |
| Bursty cost model: 3-tier alerts, daily/monthly caps, escalation-chain overhead calculation | `Projects/tess-v2/design/bursty-cost-model.md` |
| Confidence calibration drift: 7-day rolling window, re-calibration triggers, five-step procedure | `Projects/tess-v2/design/calibration-drift-plan.md` |
| Value density metric: revenue-weighted completions / total; surfaces-without-re-prioritizing principle | `Projects/tess-v2/design/value-density-metric.md` |

### Credentials and runtime

| Pattern | Source |
|---|---|
| Credential management: Keychain single-store, runner-mediated retrieval, env var injection, expiry monitoring | `Projects/tess-v2/design/credential-management.md` |
| Local model failover: health check + auto-restart + cloud fallback routing | `Projects/tess-v2/design/local-model-failover.md` |
| Local model evaluation protocol | `Projects/tess-v2/design/local-model-eval-protocol.md` |
| Cloud eval battery methodology | `Projects/tess-v2/design/tv2-cloud-eval-spec.md` |

### Scheduling

| Pattern | Source |
|---|---|
| Readiness engine: dependency-graph scheduling layer | `Projects/tess-v2/design/readiness-engine-spec.md` |

### Research / methodology

| Pattern | Source |
|---|---|
| External systems evaluation (10 agent systems analyzed, convergent patterns) | `Projects/tess-v2/design/external-systems-evaluation-2026-04-04.md` |
| Pedro autopilot extraction (signal-injection, auto-resolver, People+Programs filters) | `Projects/tess-v2/design/pedro-autopilot-extraction-2026-04-04.md` |

## Archival Policy

If `Projects/tess-v2/` is ever archived, the documents listed above (both
extracted and tagged-in-place) must first be reviewed to ensure durable
preservation. The index here is the canonical pointer; losing access to
the source docs without re-homing the patterns is a regression.

## Related

- `_system/docs/solutions/` — compound patterns home (destination for
  future extractions)
- `Projects/tess-v2/design/spec-amendment-AC-execution-surfaces.md` — the
  amendment that narrowed tess-v2's scope and triggered this preservation
  pass
