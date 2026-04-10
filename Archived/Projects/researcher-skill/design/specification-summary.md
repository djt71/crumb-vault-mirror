---
type: summary
domain: software
project: researcher-skill
skill_origin: systems-analyst
created: 2026-02-27
updated: 2026-02-27
source_updated: 2026-02-27
---

# Researcher Skill — Specification Summary

## Core Content

The researcher skill is a stage-separated research pipeline that produces evidence-grounded deliverables with mechanical citation integrity. It operates within Crumb as a skill with agent-like properties — structured procedure with branching, convergence evaluation, and escalation points — consuming the dispatch protocol (CTB-016) for lifecycle management. The pipeline follows six stages: Scoping (validate brief, query vault), Planning (decompose into sub-questions, set convergence thresholds), Research Loop (iterative search, source scoring, source content storage, fact ledger population), Synthesis (cross-reference evidence, cluster contradictions by claim_key), Citation Verification (audit quotes against stored source content, apply supersede corrections), and Writing (produce deliverable using `[^FL-NNN]` citations with mechanical validation).

The central artifact is the fact ledger — a structured evidence store using an append-with-supersede audit model. During Research Loop stages, entries are append-only. During Citation Verification, corrections create new entries that supersede originals, preserving full provenance. Every claim maps to a source with provenance metadata (authority, venue, recency) and a confidence level (verified, supported, plausible, contested, unverifiable). The write-only-from-ledger discipline is mechanically enforced: the Writing stage uses `[^FL-NNN]` citation format, and a Writing Validation step checks citation coverage, resolution, and source chain integrity.

V1 uses built-in `WebSearch` and `WebFetch` for source gathering. Sources are classified into three tiers (A: academic/primary, B: expert/institutional, C: community/secondary) and four ingestion classes (FullText, AbstractOnly, SecondaryCitation, ToolLimited). FullText sources have content stored to vault files for quote verification via normalized matching (whitespace-collapsed, with near-miss flagging). Convergence uses a two-tier check: a hard minimum bar plus a weighted formula with provisional weights, tunable via brief-level rigor profiles (light/standard/deep) that adjust thresholds, minimum entry counts, and Tier A/B requirements. Per-stage handoff snapshots and a human-readable research status file provide operator visibility into in-flight dispatches. Post-dispatch telemetry captures per-dispatch metrics (sources per tier, iterations to converge, quality ceiling frequency) for calibrating provisional convergence weights.

## Key Decisions

- **Single-agent pipeline, not multi-agent** — peer review consensus. Borrow ODR patterns (stage separation, convergence, evidence discipline) without the multi-agent supervisor complexity.
- **Fact ledger with append-with-supersede audit model** — entries are append-only during research, corrections during verification create superseding entries. Full provenance preserved; deprecated entries retained.
- **Mechanical write-only-from-ledger enforcement** — `[^FL-NNN]` citation format with Writing Validation checks (coverage, resolution, source chain). Violations caught structurally, not by model compliance.
- **Two-tier convergence** — hard minimum bar (≥2 entries, ≥2 sources, ≥1 Tier A/B) plus weighted formula (provisional weights, calibrate after V1). Tier A fallback caps at 0.8. Sub-question status transitions formally defined.
- **Source content storage** — FullText sources stored to `research/sources/[source_id].md` with content_hash. Citation Verifier checks quote_snippet as substring of stored content.
- **Contradiction modeling** — `claim_key` clusters entries about same claim; `stance` (supports/refutes/mixed) enables systematic synthesis per contested claim.
- **Four escalation gate types** — scope, access, conflict, risk — mapped 1:1 to CTB-016 §6 gate_type enum. Critical-path exception for uniquely authoritative sources.
- **Six pipeline stages** (added Citation Verification between Synthesis and Writing after peer review).
- **Normalized quote verification** — Citation Verifier uses whitespace-collapsed matching with ≥80% token overlap for near-matches; 50-80% flagged for review; <50% is match failure. Accounts for WebFetch extraction artifacts.
- **Handoff overflow strategy** — 8KB hard limit from CTB-016; rolling arrays, truncated sub-question text, vault-file fallback at 7KB soft threshold.
- **Brief-tunable convergence** — rigor profiles (light/standard/deep) adjust convergence thresholds from the brief. Custom per-field overrides also supported.
- **Operational observability** — handoff snapshot logging per stage (diagnostic), research status snapshot (operator-facing), dispatch telemetry YAML (calibration data for provisional weights).
- **Ledger compression escape valve** — pre-Synthesis rollup of low-value Tier C entries noted as V1.1 option if context pressure materializes (U-5).
- **Stage prompt design deferred to PLAN** — spec defines what each stage does, not how it's prompted. PLAN phase will design prompt templates.
- **Phased implementation** — Phase 1 (core pipeline + evidence store + provenance, 6 tasks), Phase 2 (citation grounding + failure modes, 4 tasks), Phase 3 (synthesis + writing + escalation + vault integration, 5 tasks), Phase 4 (MCP tools, deferred, 3 tasks).

## Interfaces / Dependencies

- **Upstream:** Dispatch protocol (CTB-016) for lifecycle, budget, escalation (gate_type enum: scope/access/conflict/risk), stage I/O. Built-in WebSearch/WebFetch for source gathering. Vault file conventions for output formatting.
- **Downstream:** Knowledge note pipeline (research feeds vault knowledge), peer review skill (research artifacts reviewed), Tess dispatch (research initiated via bridge), future MCP source tools (researcher is primary consumer).
- **Key schemas:** Researcher handoff schema extends dispatch handoff (adds coverage_assessment, max_research_iterations, rigor, convergence_overrides, quality_ceiling_reason). Fact ledger YAML schema (sources with content_path/content_hash, entries with claim_key/stance/supersedes/status). `[^FL-NNN]` citation format in deliverables. Research telemetry YAML (per-dispatch metrics for weight calibration).

## Next Actions

- Peer review round 1 complete (3/4 reviewers). All must-fix and should-fix items applied. Operator review applied additional refinements (convergence minimum bar, quote matching semantics, handoff overflow, stage prompt design deferral, rigor profiles, observability artifacts, telemetry, ledger compression escape valve).
- Ready to advance to PLAN phase — decompose specification tasks into implementation milestones
- Phase 1 implementation targets: skill definition (RS-001), scoping (RS-002), planning with convergence (RS-003), research loop with content storage (RS-004), fact ledger + handoff I/O with supersede model (RS-005), convergence scoring (RS-006)
