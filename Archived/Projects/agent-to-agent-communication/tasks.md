---
project: agent-to-agent-communication
type: tasks
domain: software
status: active
created: 2026-03-04
updated: 2026-03-04
tags:
  - tess
  - openclaw
  - agent-communication
---

# Agent-to-Agent Communication — Tasks

## Phase 1: Foundation + Compound Insights (M1 + M2)

| ID | Description | State | Depends On | Risk | Acceptance Criteria |
|----|-------------|-------|------------|------|---------------------|
| A2A-001 | Implement delivery layer abstraction — Phase 1 (Telegram) | done | — | medium | Abstract `deliver(intent, content, artifact_path?)` interface defined in SOUL.md. Telegram adapter wraps existing delivery. Delivery envelope schema at `_system/schemas/a2a/delivery-envelope.yaml` (correlation_id, dispatch_id, workflow, intent, timestamps, artifact_paths, cost, model). Channel-neutral artifact model in AC. No workflow code branches on channel capabilities. Verify existing OpenClaw Telegram delivery supports correlation_id/intent metadata passthrough. |
| A2A-002 | Build Tess persistent context model | done | — | medium | `_openclaw/state/tess-context.md` created with schema. `refreshed_at` timestamp present. Morning briefing (TOP-009) refreshes it. 8K token ceiling enforced. Tiered staleness: soft >24h warn, hard >72h disallow time-sensitive workflows. |
| A2A-003 | Build feedback signal infrastructure | done | A2A-001 | medium | `_openclaw/state/feedback-ledger.yaml` operational. Verbs: useful, not-useful, edited (with optional free-text on edited). Correlation ID links feedback to dispatch. Channel provenance recorded. Append-only. Mechanical coupling rule documented: learning log entry only after dispatch + (feedback OR timeout). Timeout: 24h per workflow, pending items tracked with `awaiting_feedback` status, `no-feedback` outcome signal on timeout (silent close, no reminder nudge). |
| A2A-004.1 | Define compound insight schema + dispatch template | done | A2A-001 | medium | Compound insight frontmatter schema defined (type, source_item, cross_references, confidence, provenance). Crumb dispatch template created in `_openclaw/dispatch/templates/`. Dedup rules documented: exact source_item + 7-day temporal on same cross-reference pair. |
| A2A-004.2 | Implement compound insight orchestration trigger | done | A2A-001, A2A-002, A2A-003, A2A-004.1 | high | SOUL.md instructions for compound insight workflow. Tier-based selection: all T1 + T2 matching active project tags. Cross-reference against tess-context.md projects. Noise ceiling: 3/day during gate, 5/day after. Disable threshold: >50% not-useful over window of last 20 items or 7 days (whichever larger), minimum N=10 items, scope=per-pattern key (not global). |
| A2A-004.3 | End-to-end compound insight integration + smoke test | done | A2A-004.2 | high | One real compound insight through full pipeline: feed trigger → Tess cross-reference → Crumb dispatch → vault write → delivery → feedback request. Vault-check passes on output. Budget 4-6 live iterations. |
| A2A-005 | Workflow 1 gate evaluation | done | A2A-004.3 | low | 3-day observation completed. Haiku vs Sonnet A/B: 5 items each, measured as first gate activity. Utility rate, false positive rate, noise ceiling adequacy measured. **SOUL.md drift gate question:** "Did any SOUL.md-instructed deterministic operations (envelope format, ledger schema, correlation ID format) produce inconsistent outputs requiring manual correction?" If yes → build targeted bash helpers before M3. Gate decision documented in run-log. |

## Phase 1b: Research Pipeline (M3 + M4)

| ID | Description | State | Depends On | Risk | Acceptance Criteria |
|----|-------------|-------|------------|------|---------------------|
| A2A-006 | Define capability manifest schema + first brief schema | done | M1 built | medium | Capability manifest YAML schema defined with concrete example at `_system/schemas/capabilities/manifest.yaml`. ID namespace: `domain.purpose.variant`. No-synonym rule. Rigor dimension: `supported_rigor` in manifest, `rigor:` in briefs. `_system/schemas/briefs/research-brief.yaml` extracted from researcher-skill. Required fields only. Substitution test documented. |
| A2A-006.5 | Build manifest validation script | done | A2A-006 | low | `_system/scripts/manifest-check.sh` loads all SKILL.md files with `capabilities` frontmatter, validates against manifest schema, fails hard on mismatch. Run as part of vault-check or standalone. |
| A2A-007 | Add capability manifests to existing dispatch-target skills | done | A2A-006, A2A-006.5 | low | Researcher-skill SKILL.md: `research.external.standard`. Feed-pipeline SKILL.md: `feed.triage.standard`, `feed.promotion.signal`. All manifests pass manifest-check.sh validation. Operator-only skills exempt. Critic manifest deferred to A2A-014. |
| A2A-007.5 | Create vault-query skill | done | A2A-006 | medium | `.claude/skills/vault-query/SKILL.md` created. Declares `vault.query.facts` capability. Accepts `_system/schemas/briefs/vault-query-brief.yaml` (account/topic, output format, scope constraints). Uses obsidian-cli internally for vault searches. Produces structured output (relevant notes, recent activity, open items). Manifest passes validation. |
| A2A-008 | Implement capability resolution in Tess orchestration layer | done | A2A-005, A2A-006.5, A2A-007, A2A-007.5 | high | Pre-computed `_openclaw/state/capabilities.json` index built from SKILL.md manifests (reduces runtime parsing for Haiku). SOUL.md instructions: Tess reads capabilities index. Filter by `supported_rigor` compatibility. Initial ranking uses manifest `cost_profile` (learning log fallback when A2A-011 populated). Deterministic tiebreaker: alphabetical. Zero matches → escalate. Cold-start restriction: capabilities with <3 learning log entries cannot be auto-selected for `rigor: deep` — escalate to operator. Dispatch request includes resolved skill name + originating capability ID. |
| A2A-009 | Implement quality review schema (adaptive) | done | A2A-005, A2A-007 | medium | Quality gate checks: convergence, citation, writing, format, length, relevance. Filtered by `quality_signals` manifest. Relevance always applies. Researcher-skill output format validated against gate expectations. Auto-deliver / re-dispatch / escalate logic. Re-dispatch: first failure → refine brief; second → alternative skill or escalate. Max 2 re-dispatches enforced via dispatch state (not just prompted). |
| A2A-010 | Build escalation auto-resolution logic | done | A2A-002 | high | SOUL.md escalation rules: scope + access → auto-resolve using context. Conflict + risk → always escalate. Low confidence → escalate regardless. N-entries heuristic: < N learning log entries → escalate (N calibrated during gate). Catch-all: resolution failure → Conflict escalation with error details. Audit trail logged. |
| A2A-011 | Build dispatch learning log | done | A2A-005 | low | `_openclaw/state/dispatch-learning.yaml` schema defined and operational. Entries: correlation_id, workflow, brief_params, outcome_signal, pattern_note, crash. SOUL.md instructions: Tess appends after dispatch + feedback. Consulted at brief formulation time. |
| A2A-012.1 | Research dispatch brief template + orchestration instructions | done | A2A-008, A2A-011 | medium | Research dispatch template in `_openclaw/dispatch/templates/`. SOUL.md instructions for brief formulation: consult learning log, conform to `research-brief` schema, set rigor level. Tess-initiated research constraints: active-workflow-only or explicit "investigate" flag. Daily cap: 3/day. |
| A2A-012.2 | Research pipeline end-to-end integration | done | A2A-009, A2A-010, A2A-012.1 | high | One real research dispatch through full pipeline: request → brief → resolve capability → dispatch → escalation handling → quality gate → deliver → feedback. Crash policy: re-dispatch once (same correlation_id) or escalate. Budget 3-4 live iterations. |
| A2A-013 | Workflow 2 gate evaluation | in-progress | A2A-012.2 | low | 3-day observation completed. Research quality, escalation accuracy, re-dispatch rate, feedback measured. Gate decision documented in run-log. |
| A2A-014 | Build critic skill | done | A2A-012.2 | medium | `.claude/skills/critic/SKILL.md` created. Declares `review.adversarial.standard` capability. Accepts `review-brief` schema. Structured critique with severity ratings (minor/significant/critical). Independent citation verification. Invocation criteria codified: rigor profile, downstream impact, budget threshold. |

## Phase 2: Mission Control + SE Prep (M5 + M6 + M7 — sketched)

| ID | Description | State | Depends On | Risk | Acceptance Criteria |
|----|-------------|-------|------------|------|---------------------|
| A2A-015.1 | Mission control scaffolding + auth | sketched | A2A-005, A2A-011 | high | Express + SSR skeleton. Cloudflare Tunnel + Access. Mobile-friendly baseline. |
| A2A-015.2 | Mission control read UI | sketched | A2A-015.1 | medium | Artifact browser (filterable). Feed-intel digest view. |
| A2A-015.3 | Mission control feedback + adapter | sketched | A2A-015.2 | medium | Per-item feedback actions. Web UI delivery adapter integration. |
| A2A-016 | Define account dossier schema | sketched | — | low | Frontmatter schema defined. Tess-queryable. Staleness signal > 30 days. |
| A2A-017 | Build SE account prep workflow (Workflow 3) | sketched | A2A-008, A2A-016, TOP-027 | high | Sequential dispatch: vault query → external research → synthesize. Deadline-aware scheduling using observed runtimes from `dispatch-learning.yaml`. |
| A2A-018 | Workflow 3 gate evaluation | done | A2A-017 | low | 3-day observation. Gate decision documented. Crumb-side PASS (2 dispatches: ACG rich + Steelcase thin). Tess-side delivery deferred to tess-operations. |
| A2A-019 | Build mission control — Phase 2 (approval + status) | sketched | A2A-015.3, TOP-049 | high | AID-* approval panel. Multi-channel approval with TTL/idempotency. |

## Phase 3: Gardening + Operational Intelligence (M8 — sketched)

| ID | Description | State | Depends On | Risk | Acceptance Criteria |
|----|-------------|-------|------------|------|---------------------|
| A2A-020 | Build vault gardening workflow (Workflow 4) | sketched | TOP-049 | medium | Tiered auto-fix (additive only) / review / approval. |
| A2A-021 | Build dispatch retrospective | sketched | 2+ weeks data, <10% malformed | medium | Weekly review. Failure modes, improvements, patterns. Danny approval required. |
| A2A-022 | Implement cost-aware routing | sketched | Multi-workflow | medium | Model tier by work type. Daily tracking. 80% alert. Degradation mode. |
| A2A-023 | Build stall detection | sketched | Morning briefing | low | Detects stalls. Diagnoses cause. Single recommended action. |
| A2A-024 | Build mission control — Phase 3 (control) | sketched | A2A-019, A2A-021 | high | Dispatch initiation. Workflow config. Feedback visualization. |

## Phase 4: Advanced Patterns (M9 — conditional)

| ID | Description | State | Depends On | Risk | Acceptance Criteria |
|----|-------------|-------|------------|------|---------------------|
| A2A-025 | Amend CTB-016 for multi-dispatch (conditional) | sketched | A2A-012.2 proven, concrete need | high | Only if Research Council or cascading chains warrant. Max 3 branches/group (sequential). |
