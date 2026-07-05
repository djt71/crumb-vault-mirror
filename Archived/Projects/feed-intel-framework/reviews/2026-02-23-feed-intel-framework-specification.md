---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/feed-intel-framework/design/specification.md
artifact_type: spec
artifact_hash: a8c96259
prompt_hash: null
base_ref: null
project: feed-intel-framework
domain: software
skill_origin: peer-review
created: 2026-02-23
updated: 2026-02-23
status: active
reviewers:
  - openai/gpt-5.2
  - google/gemini-3-pro-preview
  - deepseek/deepseek-reasoner
  - grok/grok-4-1-fast-reasoning
  - perplexity/sonar-reasoning-pro
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
  warnings: []
reviewer_meta:
  openai:
    http_status: 200
    model: gpt-5.2-2025-12-11
    prompt_tokens: 22545
    completion_tokens: 3364
    raw_json: Projects/feed-intel-framework/reviews/raw/2026-02-23-feed-intel-framework-specification-openai.json
  google:
    http_status: 200
    model: gemini-3-pro-preview
    prompt_tokens: 24136
    completion_tokens: 1602
    thoughts_tokens: 3424
    raw_json: Projects/feed-intel-framework/reviews/raw/2026-02-23-feed-intel-framework-specification-google.json
  deepseek:
    http_status: 200
    model: deepseek-reasoner
    system_fingerprint: fp_eaab8d114b_prod0820_fp8_kvcache
    prompt_tokens: 23281
    completion_tokens: 4200
    reasoning_tokens: 1962
    raw_json: Projects/feed-intel-framework/reviews/raw/2026-02-23-feed-intel-framework-specification-deepseek.json
  grok:
    http_status: 200
    model: grok-4-1-fast-reasoning
    prompt_tokens: 22227
    completion_tokens: 1995
    reasoning_tokens: 806
    raw_json: Projects/feed-intel-framework/reviews/raw/2026-02-23-feed-intel-framework-specification-grok.json
  perplexity:
    dispatch: manual
    model: sonar-reasoning-pro
    raw_json: Projects/feed-intel-framework/reviews/raw/2026-02-23-feed-intel-framework-specification-perplexity.md
tags:
  - review
  - peer-review
---

# Peer Review: Feed Intelligence Framework Specification v0.3.1

**Artifact:** `Projects/feed-intel-framework/design/specification.md`
**Mode:** Full
**Reviewed:** 2026-02-23
**Reviewers:** GPT-5.2, Gemini 3 Pro Preview, DeepSeek V3.2-Thinking, Grok 4.1 Fast, Sonar Reasoning Pro (manual)

**Review prompt focus areas:**
1. Implementation reality check (spec vs live X adapter)
2. Research promotion path gap (companion design note)
3. Premature abstraction risk (untested multi-source abstractions)
4. Schema completeness (recently patched digest_messages)

---

## OpenAI (gpt-5.2)

23 findings: 5 CRITICAL, 12 SIGNIFICANT, 2 MINOR, 3 STRENGTH.

**OAI-F1** [CRITICAL]: `adapter_state.component` enum is inconsistent — schema allows `curated | discovery | digest`, but migration step §8.1 includes `component='feedback'`. Migration will fail schema constraints.

**OAI-F2** [CRITICAL]: `digest_messages` maps single `telegram_message_id` to `(source_type, digest_date)`, but digests can split into multiple Telegram messages; replies may target any part. Feedback resolution for parts 2/3 will break.

**OAI-F3** [CRITICAL]: Weekly digests and retries need a stable "digest instance" identity, but schema only has `digest_date`. Partial send or retry can corrupt cutoffs or misattribute feedback.

**OAI-F4** [CRITICAL]: Vault router collision merge requires locating the existing file, but schema doesn't store the routed file path — only `routed_at`. Suggests adding `vault_path TEXT` to `posts`.

**OAI-F5** [CRITICAL]: Cross-source collision query can return multiple rows. Spec assumes a single "existing file." Needs deterministic selection (earliest `routed_at`, `ORDER BY routed_at ASC LIMIT 1`).

**OAI-F6** [SIGNIFICANT]: Late digest ordering undefined — "immediately upon completion in configured order" doesn't specify the order. Fix: primary sort by `digest.time`, secondary by adapter id.

**OAI-F7** [SIGNIFICANT]: No `digested_at` marker. Items marked `triaged` may never be delivered if digest fails; weekly cutoff could skip or double-send.

**OAI-F8** [SIGNIFICANT]: Migration claims "atomic and comprehensive" but file renames can't be in a SQLite transaction. Needs staged, restartable procedure with checkpoints.

**OAI-F9** [SIGNIFICANT]: `id_aliases` only maps bare IDs → canonical IDs, but feedback may reference filenames or shortcodes. Need to verify what identifiers the live system uses in Telegram.

**OAI-F10** [SIGNIFICANT]: No global run-level token/cost budget. Per-adapter caps exist but a single day's backlog across sources can blow aggregate cost.

**OAI-F11** [SIGNIFICANT]: Research promotion path gap — no durable artifact path for research outputs. Recommends hybrid: reuse `save` with `promotion_type: research`.

**OAI-F12** [SIGNIFICANT]: Feedback schema lacks storage for research content beyond short `argument` string.

**OAI-F13** [SIGNIFICANT]: "Primary URL" selection rules undefined for items with multiple URLs. `url_hash` collision detection depends on consistent selection.

**OAI-F14** [SIGNIFICANT]: RSS canonical_id uses `sha256[:12]` but `url_hash` uses `sha256[:16]`. Inconsistent truncation lengths.

**OAI-F15** [MINOR]: `source_instances` JSON not indexed/queryable for per-query feedback analysis.

**OAI-F16** [MINOR]: `archived` queue_status lifecycle undefined — no documentation of when/why items transition to archived.

**OAI-F17** [STRENGTH]: Two-clock model generalized cleanly with strong consistency story.

**OAI-F18** [STRENGTH]: Content tiering + `effective_tier` override is practical.

**OAI-F19** [STRENGTH]: Cost telemetry design is unusually actionable.

**OAI-F20** [SIGNIFICANT]: Premature abstraction risk — spec assumes clean monolith carve without naming current module boundaries. Suggests "Implementation extraction map" appendix.

**OAI-F21** [SIGNIFICANT]: UNVERIFIABLE CLAIM: X adapter completion (32 tasks, soak period).

**OAI-F22** [SIGNIFICANT]: UNVERIFIABLE CLAIM: Cost estimates per source.

**OAI-F23** [SIGNIFICANT]: UNVERIFIABLE CLAIM: External API quotas and rate limits.

---

## Google (gemini-3-pro-preview)

9 findings: 1 CRITICAL, 3 SIGNIFICANT, 2 MINOR, 3 STRENGTH.

**GEM-F1** [CRITICAL]: Attention clock delivery model is fragile — script must sleep/block for up to an hour between triage and final delivery. Recommends decoupling via `pending_deliveries` table and separate delivery agent.

**GEM-F2** [SIGNIFICANT]: Research feedback command results have no persistence mechanism. No schema or path for storing generated analysis content.

**GEM-F3** [SIGNIFICANT]: Vault file rename via external script won't trigger Obsidian's internal link updater. All wikilinks to old filenames will break. Migration script must also grep/replace `[[feed-intel-{id}]]` → `[[feed-intel-x-{id}]]` across the vault.

**GEM-F4** [SIGNIFICANT]: Cross-source collision merge doesn't specify frontmatter handling. Original file's `source: x` becomes misleading when RSS discovery is appended.

**GEM-F5** [MINOR]: No explicit error isolation in attention clock loop — one adapter's crash could abort triage for subsequent sources.

**GEM-F6** [MINOR]: `topic_weights` referential integrity — renaming a topic in YAML orphans DB records with no cleanup path.

**GEM-F7** [STRENGTH]: Phase 0 verification gates for risky APIs.

**GEM-F8** [STRENGTH]: YouTube transcript circuit breaker.

**GEM-F9** [STRENGTH]: Curated vs Discovery separation maps well to platform reality.

---

## DeepSeek (deepseek-reasoner / V3.2-Thinking)

12 findings: 0 CRITICAL, 7 SIGNIFICANT, 2 MINOR, 3 STRENGTH.

**DS-F1** [SIGNIFICANT]: Migration plan assumes live X pipeline conforms to earlier spec. Real implementation may have diverged. Need pre-migration audit.

**DS-F2** [SIGNIFICANT]: Feedback protocol (§5.7) doesn't address research promotion path. Gap would be discovered during implementation; extending later would be a breaking change.

**DS-F3** [SIGNIFICANT]: `triage_attempts` and `transcript_status` stored in JSON fields (`triage_json`, `content_json`). Operational queries require full table scans. Should be columns.

**DS-F4** [SIGNIFICANT]: Cost guardrail (§5.8) makes runtime adjustments to manifest parameters, but configuration snapshot rule (§4.1) says manifests only load at cycle boundaries. Contradiction.

**DS-F5** [SIGNIFICANT]: Collision handling sets `routed_at` for first item but not the appended item. Future collision checks for the same `url_hash` would miss the appended item, potentially creating duplicate files for a third source.

**DS-F6** [SIGNIFICANT]: UNVERIFIABLE CLAIM: YouTube transcript library behavior and Phase 0 quantification not yet performed.

**DS-F7** [SIGNIFICANT]: `effective_tier` invariant says it only affects triage path, but heavy-tier summary overwrites `content.excerpt` — a normalization output. Contradicts the invariant.

**DS-F8** [MINOR]: `adapter_state` table relies on composite primary key for indexing. Queries filtering only on `source_type` may not be efficient.

**DS-F9** [MINOR]: Partial success — unclear whether failed items are omitted from `pull_*` return or included with error flags.

**DS-F10** [STRENGTH]: Adapter contract and lifecycle management exceptionally well-designed.

**DS-F11** [STRENGTH]: Attention clock single-phase model is robust for consistency.

**DS-F12** [STRENGTH]: Cost control architecture is comprehensive and multi-layered.

---

## Grok (grok-4-1-fast-reasoning)

15 findings: 0 CRITICAL, 8 SIGNIFICANT, 3 MINOR, 4 STRENGTH.

**GRK-F1** [SIGNIFICANT]: Research promotion path absent from spec. Feedback protocol §5.7 needs extension. Recommends new `research` feedback command.

**GRK-F2** [SIGNIFICANT]: UNVERIFIABLE CLAIM: Reddit API "Free for personal use" with 100 req/min rate limit.

**GRK-F3** [SIGNIFICANT]: UNVERIFIABLE CLAIM: YouTube transcript library reliability. Phase 0 quantification not yet performed.

**GRK-F4** [SIGNIFICANT]: Migration plan assumes file-based state and bare canonical_id. Live X impl may already use DB. Recommends quiescing pipeline, backup, offline migration.

**GRK-F5** [SIGNIFICANT]: `triage_attempts` missing from `posts` schema despite §5.3.1 requiring it. Needs column + partial index.

**GRK-F6** [SIGNIFICANT]: Premature abstraction — manifest system untested vs live X monolith. No fallback for legacy X during Phase 1b transition.

**GRK-F7** [SIGNIFICANT]: Cost guardrail references undefined D8 `reduce_load()` callback. RSS curated adapters unthrottled despite potential volume spikes.

**GRK-F8** [SIGNIFICANT]: Weekly quality score (`promotes / total_items`) requires cross-table join with no supporting index or materialized table.

**GRK-F9** [MINOR]: No manifest validation of `digest.time` >= triage start + budget.

**GRK-F10** [MINOR]: `content.media` array unused downstream. `duration_seconds` not validated.

**GRK-F11** [MINOR]: Changelog references peer review synthesis doc without link.

**GRK-F12** [STRENGTH]: Phasing pragmatic — extract after X live + RSS validates.

**GRK-F13** [STRENGTH]: Per-source digests + independent lifecycle enable evaluation/drop.

**GRK-F14** [STRENGTH]: Risk register + cost model with headroom.

**GRK-F15** [STRENGTH]: Unified format + tiers flexible with determinism invariants.

---

## Perplexity (sonar-reasoning-pro) — Manual Submission

18 findings: 0 CRITICAL, 7 SIGNIFICANT, 8 MINOR, 3 STRENGTH.

**PPLX-F1** [STRENGTH]: Abstraction split (two clocks, unified format, adapter contract) is coherent and aligns with how X pipeline evolved.

**PPLX-F2** [SIGNIFICANT]: No explicit adapter health interface (readiness probe, self-check). Hard to detect "auth silently expired but API returns 200 with empty data."

**PPLX-F3** [SIGNIFICANT]: Error propagation across adapters underspecified. Persistent failures need "degraded" state with operator alerting.

**PPLX-F4** [MINOR]: Collision race conditions need explicit write ordering.

**PPLX-F5** [SIGNIFICANT]: Migration needs explicit rollback hooks and shadow-run validation period.

**PPLX-F6** [MINOR]: Cursor migration for multi-topic discovery needs concrete mapping rule.

**PPLX-F7** [MINOR]: Cap enforcement boundary — adapters shouldn't perform own LLM work outside shared infrastructure.

**PPLX-F8** [STRENGTH]: Manifest abstraction well designed and phase-friendly.

**PPLX-F9** [SIGNIFICANT]: Research promotion path missing from spec entirely. Recommends new §5.x subsection.

**PPLX-F10** [MINOR]: Adapter contract lacks research hook in manifest.

**PPLX-F11** [SIGNIFICANT]: Per-source adapter specs rely on optimistic API assumptions for Reddit and arxiv.

**PPLX-F12** [SIGNIFICANT]: YouTube quota risk underplayed for search-heavy discovery.

**PPLX-F13** [MINOR]: RSS needs per-feed `max_items_per_cycle` for pathological feeds.

**PPLX-F14** [MINOR]: Schema lacks foreign-key consistency stance.

**PPLX-F15** [MINOR]: `id_aliases` 45-day window may be too short.

**PPLX-F16** [SIGNIFICANT]: Phase 1b couples framework extraction with RSS implementation. Should split into 1b.1 (extraction) and 1b.2 (RSS).

**PPLX-F17** [MINOR]: Configuration management lacks environment story.

**PPLX-F18** [MINOR]: Attention clock mid-run failure semantics need one more edge case.

**Dimension Ratings:** Abstraction quality: Strong. Migration feasibility: Adequate. Adapter contract: Adequate. Per-source specs: Needs Work. Schema: Strong. Phasing: Adequate.

**Verdict:** Needs rework.

---

## Synthesis

### Consensus Findings

**1. Research promotion path missing from spec** [5/5 reviewers]
Sources: OAI-F11, GEM-F2, DS-F2, GRK-F1, PPLX-F9

Universal consensus. Every reviewer independently identified this as a gap. The companion design note's hybrid approach (reuse `save` command, `promotion_candidate` frontmatter) needs to be formalized in the spec before PLAN. Reviewers differ on mechanism (new command vs. extended save, new section vs. §5.7 extension) but agree on the gap.

**2. Migration plan needs fundamental rework** [5/5 reviewers]
Sources: OAI-F8, GEM-F3, DS-F1, GRK-F4, PPLX-F5

Universal consensus on different facets:
- **Atomicity fiction** (OAI-F8): File renames can't be in a SQLite transaction. Needs staged procedure.
- **Obsidian link breakage** (GEM-F3): Script-based renames don't trigger Obsidian's link updater. Wikilinks break.
- **Live pipeline divergence** (DS-F1, GRK-F4): Actual X implementation may not match spec assumptions. Pre-migration audit required.
- **Rollback capability** (PPLX-F5): No way to revert if migration causes runtime issues.

**3. Unverifiable API and cost claims** [4/5 reviewers]
Sources: OAI-F21/F22/F23, GRK-F2/F3, DS-F6, PPLX-F11/F12

Reddit API terms, YouTube transcript library behavior, per-source cost estimates, and external API quotas are all flagged as unverified. The Phase 0 gates address some of these, but the spec presents current-state assumptions as facts without "last verified" dates or citations.

**4. triage_attempts should be a schema column** [2/5 reviewers]
Sources: DS-F3, GRK-F5

Both independently identified that `triage_attempts` buried in `triage_json` is operationally problematic. Need a dedicated column plus index for deferred retry queries.

**5. Collision handling routed_at semantics incomplete** [2/5 reviewers]
Sources: DS-F5, OAI-F4/F5

Two distinct issues: (a) appended items don't get `routed_at` set, breaking future collision checks for a third source; (b) collision query can return multiple rows with no deterministic resolution rule.

**6. Cost guardrail vs configuration snapshot conflict** [2/5 reviewers]
Sources: DS-F4, GRK-F7

If manifests load at cycle start and mid-cycle changes are ignored, runtime guardrail adjustments to `max_results` and `max_items_per_cycle` can't take effect until the next cycle — defeating the guardrail's purpose.

**7. Premature abstraction concerns** [3/5 reviewers]
Sources: OAI-F20, GRK-F6, PPLX-F16

All three flag different aspects: OAI wants an extraction map tying current code to target modules; GRK wants phased manifest adoption; PPLX wants Phase 1b split into extraction-only and RSS-only sub-phases.

**8. Attention clock failure isolation** [2/5 reviewers]
Sources: GEM-F5, PPLX-F18

One adapter's triage failure shouldn't abort the run for other sources. Needs explicit try/catch specification.

### Unique Findings

**OAI-F1** [CRITICAL]: `adapter_state.component` enum inconsistency — schema says `curated | discovery | digest` but governance-review migration step adds `component='feedback'`. **Genuine catch.** The governance review (G-03) introduced this inconsistency by specifying feedback cursor migration into adapter_state without updating the schema comment.

**OAI-F2/F3** [CRITICAL]: Digest delivery needs stable instance identity — multi-part messages, weekly digests, and retry semantics all require more than `(source_type, digest_date)`. **Genuine architectural gap.** Only OpenAI caught the multi-part digest feedback resolution problem.

**OAI-F14** [SIGNIFICANT]: RSS canonical_id uses `sha256[:12]` truncation but `url_hash` uses `sha256[:16]`. **Genuine inconsistency.** Different truncation lengths for the same hash algorithm in the same schema.

**DS-F7** [SIGNIFICANT]: `effective_tier` invariant says it "must not alter normalization outputs" but heavy-tier summary overwrites `content.excerpt`. **Subtle and correct.** The invariant text needs refinement.

**GEM-F1** [CRITICAL]: Digest delivery model requires long-lived script sleeping between triage and delivery. **Genuine concern** for launchd-based deployment. The x-feed-intel implementation uses a separate launchd service for digest delivery, so this is already solved in practice but the spec's "single orchestrated run" framing is misleading.

**GEM-F4** [SIGNIFICANT]: Collision merge doesn't address vault file frontmatter updates. **Genuine gap** — existing file's metadata becomes incomplete.

**GRK-F8** [SIGNIFICANT]: Weekly quality score computation requires cross-table join (`posts` + `feedback`) with no supporting infrastructure. **Valid operational gap.**

**PPLX-F2** [SIGNIFICANT]: Adapter health interface (readiness probes, degraded state) missing from contract. **Valid but borderline scope** — liveness via `adapter_runs` may be sufficient for Phase 1.

### Contradictions

**Delivery model architecture:** GEM-F1 says the triage+delivery coupling is a CRITICAL flaw requiring decoupled services. DS-F11 rates the same attention clock model as a STRENGTH for consistency. **Resolution:** Both are right — the consistency model is good but the spec's "single run" framing should clarify that delivery is a separate scheduled event (which it already is in the live x-feed-intel implementation).

**Premature abstraction severity:** GRK-F6 calls the manifest system premature and wants a legacy fallback; PPLX-F1 and PPLX-F8 rate the abstraction split and manifest design as STRENGTHs. **Resolution:** The abstractions are well-designed but the *transition path* from monolith to framework is underspecified. The design is not premature, but the migration plan needs to account for the transition.

**Verdict divergence:** Perplexity says "Needs rework"; others assess significant issues but not at the "needs rework" level. **Resolution:** The spec doesn't need architectural rework — the core design is sound (consensus across all 5 reviewers). It needs targeted fixes for schema gaps, migration plan, and the research promotion path. "Ready with significant fixes" is the accurate assessment.

### Action Items

#### Must-fix (blocking PLAN advancement)

**A1: Fix `adapter_state.component` enum** [OAI-F1]
Expand the §8 schema comment from `curated | discovery | digest` to `curated | discovery | digest | feedback`. The governance review (G-03) added feedback migration without updating this.

**A2: Add research promotion path to spec** [OAI-F11, GEM-F2, DS-F2, GRK-F1, PPLX-F9]
Incorporate the hybrid approach from `research-promotion-path.md`: extend §5.7 to define `save` behavior for research-promoted items, add `save_reason: "research-promoted"` and `promotion_candidate` to the vault router's output. Resolve the 4 open design questions in the design note.

**A3: Rework migration plan §8.1** [OAI-F8, GEM-F3, DS-F1, GRK-F4, PPLX-F5]
Replace "atomic" framing with staged, restartable procedure: (1) quiesce X pipeline, (2) DB migration transaction, (3) vault file rename pass with wikilink grep/replace across vault, (4) verification, (5) enable alias resolution, (6) restart. Add rollback notes. Add pre-migration audit prerequisite: verify live X state store matches assumptions.

**A4: Add `triage_attempts` column to `posts`** [DS-F3, GRK-F5]
Move from `triage_json` to a proper column: `triage_attempts INTEGER DEFAULT 0`. Add index for deferred retry queries.

**A5: Fix collision handling `routed_at` semantics** [DS-F5, OAI-F4/F5]
(a) Set `routed_at` for appended items too. (b) Add deterministic resolution: `ORDER BY routed_at ASC LIMIT 1`. (c) Consider adding `vault_path TEXT` to avoid filename reconstruction.

**A6: Tighten `digest_messages` for multi-part digests** [OAI-F2/F3]
Add `part_index INTEGER`, `part_count INTEGER` to `digest_messages`. For weekly digests, consider a `digest_runs` join to track delivery instance identity separately from `digest_date`.

#### Should-fix (address before PLAN if practical, or early in PLAN)

**A7: Refine `effective_tier` invariant** [DS-F7]
Amend §5.1: "effective_tier determines the triage processing path and may influence `content.excerpt` generation for heavy-tier items where a summary replaces the mechanical excerpt. It must not alter `canonical_id` or other core identity fields."

**A8: Standardize hash truncation** [OAI-F14]
RSS `canonical_id` uses `sha256[:12]`, `url_hash` uses `sha256[:16]`. Pick one length (recommend 16 for both) and document it once.

**A9: Clarify cost guardrail timing** [DS-F4, GRK-F7]
Define guardrail adjustments as runtime overrides that apply at the next capture/attention cycle boundary — not mid-cycle. The configuration snapshot rule already supports this; just clarify that the guardrail writes a runtime override file/flag that's read at snapshot time.

**A10: Specify attention clock failure isolation** [GEM-F5, PPLX-F18]
Add to §4.1 or §5.10: each source's triage is wrapped in error isolation. A crash in one source's triage logs to `adapter_runs` and proceeds to the next source.

**A11: Clarify digest delivery architecture** [GEM-F1, OAI-F6]
Reframe §4.1 to clarify that delivery is a separate scheduled event (consistent with x-feed-intel's actual implementation). Define late-mode ordering: primary sort by `digest.time`, secondary by adapter id.

**A12: Address premature abstraction transition** [OAI-F20, GRK-F6, PPLX-F16]
Either: (a) add an "Implementation extraction map" appendix listing current X modules → target framework components, or (b) split Phase 1b into 1b.1 (framework extraction, X on new infra) and 1b.2 (RSS plugged in). The split approach is cleaner.

**A13: Define collision merge frontmatter strategy** [GEM-F4]
Specify how the vault file's frontmatter updates when a cross-source collision appends: add `additional_sources` list or update `source` to array.

**A14: Add adapter health/degraded state** [PPLX-F2/F3]
Define persistent failure threshold (>N failed runs in M hours) that moves an adapter to "degraded" state with Telegram alerting and digest status line. Optional `health_check()` hook.

#### Defer (revisit in PLAN or Phase 2)

**A15: Run-level token/cost budget** [OAI-F10]
Defer to PLAN phase cost sizing. Per-adapter caps + framework ceiling may be sufficient for Phase 1.

**A16: `source_instances` queryability** [OAI-F15]
Accept as Phase 2 analytics work. JSON field is fine for Phase 1.

**A17: Research content storage in feedback schema** [OAI-F12]
Defer to research promotion path design. The `save` command routes to a vault file — the feedback table doesn't need to store the full research content.

**A18: Environment-specific config management** [PPLX-F17]
Single-operator deployment on one machine. Not needed for Phase 1.

**A19: Weekly quality score materialization** [GRK-F8]
Implementation detail for PLAN phase. Cross-table join is fine at the volumes described.

**A20: Foreign-key consistency stance** [PPLX-F14]
Application-level integrity is standard for SQLite personal projects. Not a spec concern.

### Considered and Declined

**GRK-F6** (manifest `fallback_mode` for legacy X): `constraint` — Phase 1b is when X gets a manifest. The framework extraction is the migration point; there's no period where X needs both a legacy and new mode simultaneously. The extraction either works or it doesn't, and the pre-extraction X pipeline is the rollback.

**PPLX-F7** (prohibit adapter LLM usage): `overkill` — the adapter contract's extractor/normalizer interfaces don't have LLM access. Adapters return raw items; the framework runs triage. Adding an explicit prohibition to something that's structurally impossible is unnecessary.

**PPLX-F15** (`id_aliases` 45-day window too short): `incorrect` — single-operator personal system. Telegram feedback replies to 45-day-old digests are extremely unlikely. The alias table is a migration safety net, not a permanent feature.

**GRK-F10** (`content.media` unused): `out-of-scope` — placeholder for future media handling. Removing it now and re-adding it later is churn for no benefit.

**GEM-F6** (topic_weights referential integrity on rename): `out-of-scope` — operational note, not a spec concern. Topics rarely rename, and when they do, a manual SQL update is fine.

**OAI-F9** (id_aliases may not cover all identifier forms): `incorrect` — the live x-feed-intel system uses positional item IDs in digests (A1, A2, B3, etc.) that map to canonical_ids in the feedback table. The alias table maps `canonical_id` → `canonical_id`, which is the correct layer. Positional IDs are resolved before the canonical_id lookup.

**PPLX-F4** (collision write ordering): `constraint` — triage batches are already per-source and sequential per §4.1. The router processes items within a batch sequentially. Write ordering is deterministic by construction.
