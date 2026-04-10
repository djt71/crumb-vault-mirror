---
type: tasks
domain: software
project: researcher-skill
status: active
created: 2026-02-27
updated: 2026-02-27
skill_origin: action-architect
# RS-007, RS-008 completed 2026-02-27 (M4 Evidence Integrity)
---

# Researcher Skill — Tasks

## Milestone 1: Skill Definition + Data Infrastructure

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|---------------------|
| RS-001 | Create researcher skill definition (SKILL.md) — identity, context contract, procedure skeleton with 6 stage structure, activation signals | complete | — | low | software | SKILL.md exists at `.claude/skills/researcher/SKILL.md`; skill loads when activation signals match ("research", "investigate", "find evidence"); context contract specifies required docs (specification-summary, dispatch-protocol summary) and optional docs; procedure has 6 named stages matching spec §3.1 |
| RS-005 | Implement fact ledger + handoff schema I/O — ledger YAML create/append/read/supersede with claim_key and stance fields; handoff serialization with ≤8KB enforcement and 7KB overflow fallback to vault file | complete | RS-001 | low | software | Ledger YAML created with all required fields (source_id, claim_key, stance, confidence, quote_snippet, tier, ingestion_class, content_path, content_hash); append adds entries without overwriting; supersede creates new entry with `supersedes` field and marks original `status: deprecated`; handoff serializes to JSON ≤8KB; overflow at 7KB writes coverage to vault file and replaces handoff value with `{"ref": "path"}` |

## Milestone 2: Input Stages + Vault Input

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|---------------------|
| RS-002 | Implement Scoping stage — prompt template, brief validation, scope boundary identification, exclusion list, initial vault coverage check; writes handoff snapshot and research status file | complete | RS-001 | low | software | Scoping stage prompt template defined; stage validates brief has required fields (question, deliverable_format); produces refined scope with ≥1 inclusion and ≥1 exclusion; writes handoff with `research_plan` skeleton; handoff snapshot written to `research/handoff-snapshots/`; research status file created at `research/research-status-[dispatch].md`; stage output validates against dispatch handoff schema |
| RS-012 | Implement vault-as-input — Scoping stage queries vault knowledge notes and source indices for existing coverage; vault coverage structured in scope output; contradictions between vault knowledge and new findings flagged | complete | RS-002 | low | software | Scoping stage queries vault via Obsidian CLI or Grep for relevant knowledge notes; scope output includes `vault_coverage` object with `notes_found` (integer), `sources_found` (integer), `gaps` (list); Planning receives `skip_queries` list populated from vault sources; contradiction between vault knowledge and new evidence recorded in handoff `open_questions` with source references |
| RS-003 | Implement Planning stage — prompt template, sub-question decomposition (≥2), search strategy per sub-question, convergence criteria from rigor profile (light/standard/deep), max_research_iterations, source tier targets | complete | RS-002, RS-012 | medium | software | Planning stage prompt template defined; decomposes question into ≥2 sub-questions with `id`, `text`, `status: open`; reads `rigor` from brief (default: standard) and writes corresponding thresholds to handoff; sets `max_research_iterations`; sets `source_tier_targets` (tier_a, tier_b, tier_c counts); supports `convergence_overrides` from brief; Planning accepts Scoping's handoff (including vault_coverage) without repair; handoff snapshot written |

## Milestone 3a: Research Loop + Failure Handling

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|---------------------|
| RS-004 | Implement Research Loop stage — prompt template, web search via WebSearch/WebFetch, source tier classification (A/B/C), ingestion class assignment (FullText/AbstractOnly/SecondaryCitation/ToolLimited), source content storage to `research/sources/[source_id].md` with content_hash (runner-computed), fact ledger population with all required fields | complete | RS-003, RS-005 | medium | software | Research Loop prompt template defined; stage executes ≥1 web search per iteration with query logged in research status; each source classified by tier and ingestion class; FullText sources stored to `research/sources/` with content_hash in metadata; ledger entries have source_id, claim_key, stance, confidence, quote_snippet, tier; coverage_score updated per sub-question in handoff; stage output validates against dispatch handoff schema; handoff snapshot written; research status updated |
| RS-009 | Implement failure mode handling — garbage result detection (each candidate result has `relevance: pass\|fail` with logged reason; fail results never become ledger entries), paywall/bot-block classification via ingestion class, rate limit backoff, timeout cascade graceful degradation (>50% timeout triggers degradation) | complete | RS-004 | medium | software | Each candidate result classified with `relevance: pass\|fail` and reason logged; fail results excluded from ledger; paywalled sources classified as AbstractOnly or ToolLimited (not FullText); >50% source fetch timeout triggers graceful degradation — research status updated with `degradation_note` field, handoff `quality_ceiling_reason` set; rate limit errors trigger backoff before retry; partial telemetry snapshot written (sources_attempted, sources_failed, failure_types) for dispatches that terminate before output pipeline |

## Milestone 3b: Convergence + Loop Control + Escalation

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|---------------------|
| RS-006 | Implement convergence scoring — two-tier check: minimum bar (≥2 entries, ≥2 distinct sources, ≥1 Tier A/B) plus weighted formula (tier_weight × confidence_weight); rigor profile threshold lookup; Tier A fallback quality ceiling at 0.8 after 2 failed attempts; sub-question status transitions (open→covered, open→blocked) | complete | RS-004 | medium | software | Minimum bar gate evaluates correctly for all threshold combinations; weighted formula produces score 0-1; rigor profile thresholds applied (light: 0.5, standard: 0.7, deep: 0.85); Tier A fallback caps score at 0.8 and records quality_ceiling_reason; sub-question transitions to `covered` only when both minimum bar AND score threshold met; `convergence_overrides` respected when present |
| RS-010 | Implement runaway loop detection — diminishing returns (<2 new entries AND <0.05 score improvement), max_research_iterations enforcement from handoff | complete | RS-006 | low | software | Loop terminates when iteration adds <2 entries AND score improves <0.05; loop terminates when iteration count equals max_research_iterations; termination advances to Synthesis with incomplete coverage note in handoff; diminishing returns condition logged in research status |
| RS-011 | Implement 4 researcher-specific escalation gates — scope (brief ambiguous), access (source unavailable), conflict (contradictory authoritative sources), risk (research touches sensitive topics); map 1:1 to CTB-016 §6 gate_type enum; batching (≤3 questions per escalation); min-evidence-before-escalation with critical-path exception; escalation handoff updates | complete | RS-001 | medium | software | All 4 gate types trigger on correct conditions; gate_type values match CTB-016 enum exactly (scope/access/conflict/risk); escalation questions follow CTB-016 format (≤3 questions, choice/confirm only, ASCII regex); min-evidence rule respected (don't escalate on first missing source); critical-path exception allows immediate escalation for uniquely authoritative sources; escalation handoff updates sub-question status to `blocked` and records in open_questions; partial telemetry snapshot written (escalation_type, sub_question_id, resolution_pending) for dispatches that block before output pipeline |

## Milestone 4: Evidence Integrity

RS-007 and RS-008 are parallel tracks — no dependency between them. Both dependencies satisfied after M3a.

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|---------------------|
| RS-007 | Implement Citation Verification stage — prompt template, quote_snippet substring check against stored source content using normalized matching (lowercase, collapse whitespace, strip punctuation except intra-word hyphens; tokens = split on whitespace; overlap = \|snippet_tokens ∩ window_tokens\| / \|snippet_tokens\|; window = best-matching contiguous window of ±20% snippet token count), over-confidence detection (verified + non-FullText), supersede corrections, verification summary | complete | RS-004, RS-005 | medium | software | Verification stage prompt template defined; checks quote_snippet against stored content using defined normalization algorithm; ≥80% token overlap = pass, 50-80% = flagged for review, <50% = match failure; detects `verified` confidence on non-FullText sources and creates supersede entry; produces verification summary with pass/flag/fail counts and supersede operations list; stage output validates against dispatch handoff schema |
| RS-008 | Implement write-only-from-ledger enforcement — `[^FL-NNN]` citation format definition, Writing Validation with 4 checks: citation coverage (no uncited claims), resolution (all [^FL-NNN] resolve to ledger entries), source chain (each cited entry traces to a scored source via source_id), orphan detection (no [^FL-NNN] references to non-existent ledger entries) | complete | RS-005 | medium | software | `[^FL-NNN]` format documented in skill procedure; Writing Validation checks all 4 dimensions; uncited claims detected and flagged; unresolved [^FL-NNN] references detected; broken source chains detected (cited entry missing source_id or source_id not in source index); orphan citations detected; Writing stage cannot declare `status: done` with any validation failure |

## Milestone 5: Output Pipeline + Vault Output

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|---------------------|
| RS-013 | Implement Synthesis stage — prompt template, cross-reference all evidence by claim_key, contradiction clustering with stance counts (supports/refutes/mixed) weighted by source tier, quality ceiling notes for affected sub-questions, confidence rollup | complete | RS-006, RS-010 | medium | software | Synthesis prompt template defined; all ledger entries mapped to claim_keys; contradiction clusters produced for claim_keys with mixed stances; stance counts weighted by tier (A=1.0, B=0.7, C=0.4); quality ceiling sub-questions have dedicated source quality note; output includes `overall_confidence` object with `score` (0-1), `rationale` (≤1200 chars), `drivers` (list of claim_keys driving the score); stage output validates against dispatch handoff schema; handoff snapshot written |
| RS-014 | Implement Writing stage — prompt template, deliverable production from synthesis using `[^FL-NNN]` citations, Writing Validation execution (RS-008), deliverable format from brief | complete | RS-013, RS-007, RS-008 | medium | software | Writing prompt template defined; deliverable uses only `[^FL-NNN]` citations; Writing Validation passes all 4 checks; deliverable format matches brief specification; stage declares `status: done` only after validation passes; if validation fails, stage declares `status: next` with fix instructions |
| RS-015 | Implement vault-as-output — research note routing (knowledge notes to `Sources/`, source indices alongside), source index creation with all scored sources, dispatch telemetry YAML (§3.10: sources per tier, iterations to converge, quality ceiling frequency, verification stats, writing validation attempts) | complete | RS-014 | medium | software | Research deliverable written to vault with valid YAML frontmatter (type, status, created, updated, topics, tags); vault-check passes on generated files; source index created with all sources (tier, ingestion, confidence); dispatch telemetry written to `research/telemetry-[dispatch].yaml` with all §3.10 fields; all file paths are vault-relative |

## Milestone 6: MCP Source Tools (Deferred)

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|---------------------|
| RS-016 | Design MCP tool integration layer — tool selection logic per sub-question, structured metadata ingestion mapping to source scoring dimensions | pending | RS-004 | medium | software | Tool selection criteria defined per source tier; MCP metadata fields mapped to existing source scoring dimensions (authority, venue, recency); integration layer documented with clear API surface |
| RS-017 | Implement Tier A MCP tools — arXiv, PubMed, Semantic Scholar integration | pending | RS-016 | high | software | API authentication works for all 3 services; structured results populate fact ledger with correct tier/ingestion classification; paywall detection accurate for each service |
| RS-018 | Update Planning stage for multi-tool selection — Planning considers available MCP tools when setting source tier targets and search strategy | pending | RS-016 | low | software | Planning stage checks for available MCP tools; tool availability influences source tier targets (higher Tier A targets when MCP available); search strategy includes tool-specific queries |

## Dependency Summary

```
Critical path: RS-001 → RS-002 → RS-012 → RS-003 → RS-004 → RS-006 → RS-010 → RS-013 → RS-014 → RS-015

Milestones:
- M1: RS-001, RS-005
- M2: RS-002, RS-012, RS-003
- M3a: RS-004, RS-009
- M3b: RS-006, RS-010, RS-011
- M4: RS-007 ∥ RS-008 (parallel — no dependency between them)
- M5: RS-013, RS-014, RS-015

Parallel tracks after RS-001:
- Track A (data): RS-005 (merges at RS-004)
- Track B (escalation): RS-011 (merges at M3b)

After RS-004 (Research Loop):
- Track C (verification): RS-007 (depends RS-004 + RS-005, parallel with RS-008)
- Track D (validation rules): RS-008 (depends RS-005 only, parallel with RS-007)
- Track E (failure handling): RS-009 (M3a, alongside RS-004)

After RS-010 (converged ledger) + M4 (verified + validated):
- Track F (output): RS-013 → RS-014 → RS-015
```
