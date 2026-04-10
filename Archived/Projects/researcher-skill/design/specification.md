---
type: specification
domain: software
project: researcher-skill
skill_origin: systems-analyst
review_round: 1
created: 2026-02-27
updated: 2026-02-27
tags:
  - researcher
  - deep-research
  - skill-design
---

# Researcher Skill — Specification

## 1. Problem Statement

Manual research and chat-based LLM research share four structural gaps: no provenance chain from claims to sources, no convergence criteria to know when research is sufficient, no structured escalation when access barriers or contradictions arise, and no resumability when a session is interrupted. These gaps produce research artifacts that are plausible but ungroundable — the operator cannot trace a claim back to a verified source, and the system cannot distinguish between well-sourced findings and hallucinated citations.

This skill builds a stage-separated research pipeline that produces evidence-grounded deliverables with mechanical citation integrity, consuming the dispatch protocol (CTB-016) for lifecycle management, budget enforcement, and structured escalation.

## 2. Facts vs Assumptions

### Facts

- **F1:** The dispatch protocol (CTB-016) is complete — provides stage lifecycle, budget enforcement, structured escalation, and stage I/O contracts.
- **F2:** Claude Code provides built-in `WebSearch` and `WebFetch` tools for source gathering.
- **F3:** The vault structure supports knowledge notes (`Sources/[type]/`), source indices, and `#kb/` tagged documents per file-conventions.md.
- **F4:** No MCP source tools exist yet — academic APIs, specialized databases, and curated archives are not currently accessible.
- **F5:** The citation verification gap analysis (`design/citation-verification-gap-findings.md`) documents the closed-loop problem: models reviewing models creates no grounding.
- **F6:** The Perplexity deep research prior art (`design/perplexity-deep-research.md`) establishes the industry pattern: scoping → planning → research loops → synthesis → writing.
- **F7:** Peer review consensus: single-agent, stage-separated pipeline — not ODR multi-agent. Borrow ODR patterns (stage separation, convergence criteria, evidence discipline) as a pattern library.
- **F8:** The skill operates within Crumb — dispatched by the operator or by Tess via the bridge. It is a Crumb skill with agent-like properties (structured procedure with branching, convergence evaluation, escalation points), not a standalone agent.

### Assumptions

- **A-1:** A single agent (one `claude --print` invocation per stage) is sufficient for V1 research tasks. Multi-agent parallelism (supervisor + sub-agents) is deferred. *Validate:* monitor stage counts and wall-time for research dispatches; if consistently hitting budget caps, reconsider.
- **A-2:** Built-in `WebSearch` and `WebFetch` are adequate for initial source gathering without MCP tools. *Validate:* track "access gate" escalation frequency; high rates signal tool inadequacy.
- **A-3:** The fact ledger pattern (structured evidence store) works for citation grounding at the scale of a typical research task (10-50 sources). *Validate:* monitor ledger size and observe whether the synthesis stage can consume it within context limits.
- **A-4:** The dispatch protocol's stage budget (default 10, hard cap 25) provides sufficient stages for a research pipeline. *Validate:* observe actual stage counts in practice.

### Unknowns

- **U-1:** Academic API access patterns — which APIs are available via MCP, authentication requirements, rate limits, cost models.
- **U-2:** Optimal convergence thresholds — how many sources, what coverage level, what contradiction threshold constitutes "sufficient research."
- **U-3:** Fact ledger size limits — at what point does the accumulated evidence exceed what a synthesis stage can consume in-context.
- **U-4:** MCP tool development timeline — when shared MCP infrastructure will support academic sources (JSTOR, PubMed, arXiv, Google Scholar).
- **U-5:** Context window pressure under research workloads — how many previous stage summaries + handoffs + evidence can fit alongside active work. **V1.1 escape valve:** If context pressure materializes (ledger too large for Synthesis stage to consume in-context), a pre-Synthesis compression pass could group low-value Tier C entries under summary meta-entries — reducing token count while preserving provenance via rollup references. Not built for V1, but noted as the structural fix if U-5 becomes a real constraint.

## 3. System Map

### 3.1 Pipeline Architecture (A2)

The researcher skill operates as a stage-separated pipeline consuming the dispatch protocol (CTB-016). Each stage is a single `claude --print` invocation. Stages are dynamically sequenced — the planning stage determines the research plan, and each stage's output determines the next.

#### Stage Definitions

| Stage | Purpose | Input | Output | Convergence Criteria |
|-------|---------|-------|--------|---------------------|
| **Scoping** | Validate the research brief, identify scope boundaries, check vault for existing knowledge | Dispatch brief, vault context | Refined scope, exclusions, existing vault coverage report | Scope is bounded and unambiguous |
| **Planning** | Decompose research question into sub-questions, plan search strategy | Scoped brief, vault coverage | Research plan: ordered sub-questions, source tier targets, stage sequence | All sub-questions traceable to the original brief |
| **Research Loop** | Execute search, read sources, extract evidence, populate fact ledger | Sub-question(s), search strategy | Fact ledger entries, source metadata, coverage assessment | Coverage threshold met per sub-question (see §3.6) |
| **Synthesis** | Cross-reference evidence, identify contradictions, assess confidence, produce structured findings | Complete fact ledger, source index | Synthesis document with claim-evidence mapping | All claims mapped to ledger entries; contradiction clusters surfaced per claim_key |
| **Citation Verification** | Audit fact ledger integrity — verify quotes against stored source content, flag over-confidence, produce verification summary | Fact ledger, stored source content files | Verified ledger with verification summary appended | No `verified` entries with non-`FullText` sources; all flagged entries resolved or noted |
| **Writing** | Produce the final research deliverable from synthesized findings using only ledger-backed citations | Synthesis document, verified fact ledger, brief (deliverable format) | Research note/knowledge note in vault format | Every citation uses `[^FL-NNN]` format; writing validation passes; vault-check passes |

#### Stage Flow

```
Scoping ──▶ Planning ──▶ Research Loop (1..N) ──▶ Synthesis ──▶ Verification ──▶ Writing
   │            │              │                       │                             │
   ▼            ▼              ▼                       ▼                             ▼
 [blocked]   [blocked]     [blocked]              [blocked]                     [blocked]
 (scope       (access      (access/                (conflict/                    (risk)
  confirm)    gate)         conflict)               risk)
```

**Research Loop convergence ownership:** The Planning stage defines convergence criteria (sub-questions, source tier targets, thresholds) and writes them to the handoff. Each Research Loop stage evaluates convergence *internally* using the handoff data — Planning is NOT re-invoked. After completing its search work, the Research Loop stage computes coverage scores per sub-question (see §3.1.1), updates the handoff, and declares either `next` (targeting the weakest sub-question) or advances to Synthesis when all sub-questions meet coverage thresholds or `max_research_iterations` is reached.

#### Stage I/O Contracts

Stages consume and produce the dispatch protocol's standard stage output schema (CTB-016 §4.3). Researcher-specific data flows through two channels:

1. **Handoff** (≤8KB structured state) — carries decisions, file paths, coverage status between stages.
2. **Vault files** — fact ledger, source index, and intermediate notes written to `Projects/[project]/research/` and referenced via `next_stage.context_files`.

#### Researcher-Specific Handoff Schema

```json
{
  "research_plan": {
    "sub_questions": [
      {
        "id": "sq-1",
        "text": "string — the sub-question",
        "status": "open | covered | blocked",
        "coverage_score": "number 0-1 — evidence coverage",
        "source_count": "integer — sources found",
        "ledger_entry_count": "integer — fact ledger entries"
      }
    ],
    "source_tier_targets": {
      "tier_a": "integer — target count for academic/primary sources",
      "tier_b": "integer — target count for expert/institutional sources",
      "tier_c": "integer — target count for community/secondary sources"
    }
  },
  "coverage_assessment": {
    "overall_score": "number 0-1",
    "gaps": ["array of strings — identified gaps"],
    "contradictions": ["array of strings — contradictory findings"],
    "quality_ceiling_reason": "string | null — why a sub-question converged under quality ceiling",
    "tier_a_attempts": "object | null — per sub-question count of failed Tier A access attempts"
  },
  "rigor": "light | standard | deep — from brief, determines convergence thresholds (default: standard)",
  "convergence_overrides": "object | null — per-field threshold overrides from brief (coverage_score, min_entries, min_sources)",
  "max_research_iterations": "integer — from Planning stage, enforced by Research Loop",
  "decisions": { "...inherited from dispatch handoff schema..." },
  "files_created": ["...inherited..."],
  "files_modified": ["...inherited..."],
  "key_facts": ["...inherited..."],
  "open_questions": ["...inherited..."]
}
```

**Handoff size management:** The 8KB serialized limit is a hard constraint from CTB-016 §4.5. For research tasks with 8-10 sub-questions and detailed coverage tracking, this budget can get tight — especially as `gaps` and `contradictions` arrays accumulate across iterations. Overflow prevention rules:

1. **Sub-question text:** The `text` field carries the full sub-question on first write. Subsequent Research Loop stages may truncate to the first 80 characters + `sq-N` reference — the full text is in the Planning stage's vault output, not repeated in every handoff.
2. **Gaps and contradictions:** These arrays are rolling — each Research Loop stage writes only *current* gaps and contradictions, not cumulative history. Historical entries are in the fact ledger (vault file), not the handoff.
3. **Quality ceiling reasons:** One short string per affected sub-question, not per access attempt. Attempt counts tracked separately in `tier_a_attempts` (compact integer map).
4. **Overflow fallback:** If serialized handoff exceeds 7KB (soft warning threshold), the Research Loop stage writes the full coverage assessment to a vault file (`research/coverage-[dispatch-id-short].yaml`) and replaces the `coverage_assessment` handoff value with `{"ref": "path/to/coverage-file.yaml"}`. The next stage reads the file via `context_files`.

#### Handoff Snapshot Logging

Each stage writes a timestamped copy of its handoff output to `research/handoff-snapshots/[dispatch-id-short]/stage-[N]-[stage-name].yaml`. These snapshots are append-only diagnostic artifacts — they capture the handoff state at each stage exit for debugging convergence progression, coverage drift, and escalation decisions. The snapshots are not consumed by the pipeline (stages read from the live handoff, not from snapshots) and carry no size constraint beyond vault capacity.

This is low-cost operational hygiene: one small YAML per stage, negligible disk, high debugging value when a research dispatch produces surprising convergence behavior or stalls.

#### Research Status Snapshot

Each stage writes (or updates) a human-readable status file at `research/research-status-[dispatch-id-short].md` on stage exit. This is the operator's window into an in-flight research dispatch — readable via Obsidian or Tess without parsing YAML handoffs.

Contents:
- Current stage name and number
- Sub-question list with status (`open`/`covered`/`blocked`) and coverage scores
- Source count by tier
- Ledger entry count
- Active escalations (if any)
- Elapsed stages / budget remaining

The file is overwritten on each stage exit (not append — the current snapshot replaces the previous one). After the Writing stage completes, it serves as the dispatch summary. For bridge dispatches via Tess, this file is what Tess reads to relay research progress to the operator on Telegram.

#### Convergence Scoring (§3.1.1)

The Research Loop uses a two-tier convergence check: a simple minimum bar (hard gate) and a weighted scoring formula (quality signal). Both must be satisfied.

**V1 minimum bar (hard gate):**

A sub-question is eligible for `covered` status only if:
- `ledger_entry_count ≥ 2` (at least 2 entries)
- Entries come from `≥ 2 distinct sources` (not the same source twice)
- At least one source is Tier A or Tier B

This is the implementable floor. A sub-question that meets the minimum bar but not the scoring threshold stays `open` — the Research Loop continues searching.

**Weighted scoring formula (quality signal):**

```
coverage_score = min(1.0, weighted_evidence / target_evidence)

where:
  weighted_evidence = Σ (tier_weight × confidence_weight) for each ledger entry
  target_evidence = tier_a_target × 1.0 + tier_b_target × 0.7 + tier_c_target × 0.4

  tier_weight:       A=1.0, B=0.7, C=0.4
  confidence_weight: verified=1.0, supported=0.7, plausible=0.4, contested=0.2, unverifiable=0
```

**Provisional weights:** The tier and confidence weights above are untested assumptions. They provide a structured heuristic to prevent ad-hoc "good enough" judgments in the Research Loop, but they are not empirically validated. After V1 produces real research dispatches, calibrate weights against observed coverage quality. If the formula produces clearly wrong convergence decisions, fall back to the minimum bar only and defer formula tuning to V1.1.

**Default thresholds:**

| Criterion | Threshold | Effect |
|-----------|-----------|--------|
| Sub-question `covered` | Minimum bar met AND `coverage_score ≥ 0.7` | Sub-question status transitions to `covered` |
| Overall convergence | All sub-questions `covered` or `blocked` | Pipeline advances to Synthesis |
| Diminishing returns | Research Loop adds <2 entries AND score improves <0.05 | Advance to Synthesis with incomplete coverage note |

**Brief-tunable convergence (rigor profiles):**

The default thresholds above assume a standard research dispatch. The brief can override them via a `rigor` field that selects a named profile:

| Profile | `coverage_score` threshold | `min_entries` | `min_sources` | Tier A/B required | Use case |
|---------|---------------------------|---------------|---------------|-------------------|----------|
| `light` | 0.5 | 1 | 1 | No | Quick lookup, background context, low-stakes questions |
| `standard` | 0.7 | 2 | 2 | Yes (≥1) | Default — general research tasks |
| `deep` | 0.85 | 3 | 3 | Yes (≥2) | High-stakes claims, technical accuracy, publishable research |

The Planning stage reads the `rigor` field from the brief (default: `standard`) and writes the corresponding thresholds to the handoff. This is a natural extension of the existing `max_research_iterations` brief override — the Planning stage already parameterizes convergence from the brief.

Custom thresholds are also permitted: the brief may include a `convergence_overrides` object with individual field overrides (e.g., `{"coverage_score": 0.6, "min_entries": 1}`). Named profiles are sugar — they expand to the corresponding overrides.

**Tier A fallback policy:** When Tier A sources are unavailable for a sub-question (common in V1 due to paywalls and tool limitations), the pipeline applies a quality ceiling:
- After 2 failed Tier A access attempts per sub-question, allow convergence using Tier B/C sources.
- Cap the sub-question's maximum `coverage_score` at 0.8 (quality ceiling).
- Record `quality_ceiling_reason` in the handoff coverage assessment.
- The synthesis must include a "source quality note" for any sub-question that converged under a quality ceiling.

**Sub-question status transitions:**

| From | To | Condition |
|------|-----|-----------|
| `open` | `covered` | `coverage_score ≥ 0.7` AND `ledger_entry_count ≥ 2` |
| `open` | `blocked` | Escalation declared for this sub-question (awaiting operator input) |
| `blocked` | `open` | Escalation resolved; research resumes |
| `open` | `covered` (with ceiling) | Quality ceiling applied; `coverage_score ≥ 0.7` using Tier B/C |

**Contradiction handling:** If a sub-question has `contested` entries (contradictions), it can still reach `covered` status, but the synthesis MUST produce a dedicated contradiction section per contested `claim_key` (see §3.3) with stance counts weighted by source tier.

### 3.2 Source Provenance (A3)

Every source encountered during research is classified, scored, and tracked. The provenance chain runs from raw URL through ingestion to every claim that cites it.

#### Source Scoring

| Dimension | Description | Values |
|-----------|-------------|--------|
| **Authority** | Who produced it | Academic institution, government, established media, industry expert, community, unknown |
| **Venue** | Where it was published | Peer-reviewed journal, preprint (arXiv), institutional report, major tech blog, personal blog, forum, social media |
| **Methodology** | How claims are supported | Empirical study, systematic review, expert analysis, anecdotal, opinion |
| **Recency** | Publication date relative to the research question's temporal scope | Current (≤1yr), recent (1-3yr), dated (3-5yr), historical (>5yr) |

#### Source Tiers

| Tier | Description | Authority + Venue Profile | Default Weight |
|------|-------------|---------------------------|----------------|
| **A** | Primary/academic | Peer-reviewed, institutional, government, established systematic analysis | 1.0 |
| **B** | Expert/institutional | Named-expert analysis, major tech blogs, official documentation, conference talks | 0.7 |
| **C** | Community/secondary | Forum posts, personal blogs, social media, aggregator summaries, vendor content | 0.4 |

Source tier is used for two purposes: (1) convergence weighting — a sub-question covered by 3 Tier A sources converges faster than one covered by 10 Tier C sources, and (2) citation confidence scoring in the fact ledger (§3.4).

#### Ingestion Classification

Every source is classified by access level at the point of ingestion:

| Classification | Meaning | Provenance Implication |
|----------------|---------|----------------------|
| **FullText** | Complete text retrieved and read | Claims can be quote-verified |
| **AbstractOnly** | Only abstract/summary accessible (paywall, login wall) | Claims attributed to abstract; deeper claims flagged as unverifiable |
| **SecondaryCitation** | Source referenced by another source but not directly accessed | Claims carry "secondary citation" confidence ceiling |
| **ToolLimited** | Source exists but `WebFetch` cannot extract meaningful content (JS-heavy, anti-bot) | Triggers access gate escalation if source is critical |

#### Source Metadata Schema

Written to the fact ledger alongside each source entry:

```yaml
source_id: "string — kebab-case slug (author-short-title or domain-slug)"
url: "string — canonical URL"
title: "string — page/article title"
author: "string | null"
publication_date: "string | null — YYYY-MM-DD or YYYY"
venue: "string — where published"
tier: "A | B | C"
ingestion: "FullText | AbstractOnly | SecondaryCitation | ToolLimited"
authority_signals:
  - "string — e.g., 'peer-reviewed', '.edu domain', 'cited by 3 other sources'"
retrieved_at: "string — ISO 8601 timestamp"
content_path: "string | null — vault-relative path to stored source content"
content_hash: "string | null — sha256 of stored content (first 12 chars)"
content_extracted_at: "string | null — ISO 8601 timestamp of extraction"
```

#### Source Content Storage

When a source is ingested as `FullText`, the Research Loop stage MUST store the fetched content to a file for later verification. Content is stored at:

```
Projects/[project]/research/sources/[source_id].md
```

The stored file contains the extracted text content (not raw HTML). The `content_path`, `content_hash`, and `content_extracted_at` fields in source metadata reference this file. The Citation Verifier (§3.3) uses stored content to verify that `quote_snippet` values are genuine substrings of the source text.

Sources with `ingestion` other than `FullText` have `content_path: null` — no stored content is available, which constrains the maximum confidence level of entries citing them (see §3.3 Confidence Scoring).

**Storage budget:** Source content files are typically 5-50KB of extracted text, though long-form articles and documentation pages can exceed 100KB. For a research dispatch with 20-30 sources, total storage is ~0.5-2MB — within vault capacity but worth monitoring.

**Known growth vector:** V1 stores source content per-dispatch under each project's `research/sources/` directory. If multiple dispatches cite the same source, it is stored separately each time. The `content_hash` field enables future dedup (a shared `Sources/cache/` with hash-based dedup), but V1 does not implement this. The audit skill should monitor `research/sources/` volume as part of its weekly review.

### 3.3 Citation Grounding (A4)

Citation grounding is the mechanical answer to the closed-loop problem identified in `design/citation-verification-gap-findings.md`: models reviewing models creates no grounding. The researcher skill grounds citations at the point of production, not at review time.

#### Core Principle: Write-Only-From-Ledger

The Writing stage can ONLY cite claims that exist in the fact ledger. No ad-hoc claims, no "common knowledge" assertions without ledger backing, no citations synthesized during writing. The fact ledger is the single source of truth for all claims in the deliverable.

#### Quote-Level Evidence Mapping

Every fact ledger entry maps a claim to its evidence:

```yaml
entry_id: "FL-NNN"
statement: "string — the factual claim"
source_id: "string — references source metadata"
quote_snippet: "string — verbatim text from source supporting the claim (≤500 chars)"
confidence: "verified | supported | plausible | contested | unverifiable"
claim_key: "string — stable normalized identifier for 'same claim' across entries (kebab-case)"
stance: "supports | refutes | mixed"
contradicts: ["FL-NNN — entry IDs of contradictory claims, if any"]
notes: "string | null — analyst notes on interpretation or context"
```

**Schema invariant:** An entry's effective ingestion class is always derived from its source: `sources[source_id].ingestion`. There is no separate `ingestion_class` field on entries — this prevents drift between source and entry classifications. The confidence constraints (e.g., `verified` requires `FullText`) are checked against the source's `ingestion` field at entry creation time.

**Contradiction modeling:** The `claim_key` field clusters entries about the same factual claim across sources. Entries with the same `claim_key` but different `stance` values form a contradiction cluster. The Synthesis stage MUST produce a dedicated section per contested `claim_key`, showing stance counts weighted by source tier. Example `claim_key` values: `llm-context-window-scaling`, `react-server-component-adoption-rate`.

#### Confidence Scoring

| Level | Definition | Ingestion Requirement |
|-------|------------|----------------------|
| **Verified** | Claim directly confirmed by quote from FullText source | FullText only |
| **Supported** | Claim consistent with source content; quote provides partial support | FullText or AbstractOnly |
| **Plausible** | Claim consistent with known facts but not directly quoted | Any ingestion class |
| **Contested** | Multiple sources disagree; contradictions field populated | Any — must have ≥2 entries |
| **Unverifiable** | Specific reference (issue number, version, paper title) that cannot be confirmed | Any — flagged for operator review |

#### Citation Format

All deliverables produced by the Writing stage MUST use footnote-style citation references linking claims to fact ledger entry IDs:

```
The transformer architecture uses attention mechanisms for sequence modeling.[^FL-003]
Recent work suggests scaling laws plateau above 100B parameters.[^FL-017][^FL-022]
```

Every factual sentence or paragraph with factual claims MUST include at least one `[^FL-NNN]` reference. The citation format is machine-checkable — the Writing Validation step (below) enforces it.

#### Citation Verifier Pass

The Citation Verifier is a dedicated pipeline stage (see stage table above), consuming one stage budget unit. It runs between Synthesis and Writing and operates solely on the existing fact ledger and stored source content — no new web searches.

Verification steps:

1. For each entry with `confidence: verified`, confirm that `quote_snippet` matches the stored source content at `sources[source_id].content_path`. **Match semantics:** `WebFetch` text extraction produces inconsistent whitespace, encoding artifacts, and sometimes partial content. Exact substring matching will produce false negatives. The verifier uses normalized matching: collapse whitespace, strip non-printable characters, and compare. If normalized match fails, check for high overlap (≥80% of snippet tokens appear in the same order in the source content). Near-misses (50-80% overlap) are flagged for review rather than auto-downgraded. Below 50% is treated as a match failure. If `content_path` is null (source not `FullText`), downgrade to `supported` with a revision note.
2. Flag entries where `confidence: verified` but source `ingestion` is not `FullText` — these are over-confident and must be downgraded.
3. Flag entries with `source_id` referencing a source whose `ingestion` is `ToolLimited` — these need operator attention.
4. Produce a verification summary: counts by confidence level, flagged entries, contradiction clusters (grouped by `claim_key`).
5. Write corrections using the ledger audit model (see §3.6 Mutation and Audit).

#### Writing Validation

After the Writing stage produces a deliverable, a validation check runs (within the same stage, not a separate dispatch stage):

1. **Citation coverage:** Every factual claim must have at least one `[^FL-NNN]` reference. Heuristic triggers for uncited claims: numbers, dates, "according to", superlatives, comparative claims.
2. **Citation resolution:** Every `[^FL-NNN]` reference must resolve to an existing entry in the fact ledger.
3. **Source chain:** Every referenced entry's `source_id` must exist in the ledger's `sources[]` array.
4. **No orphan entries:** Flag any entries in the ledger that are never cited in the deliverable (informational, not blocking).

If checks 1-3 fail, the Writing stage must correct the deliverable before declaring `done`. This is the mechanical enforcement of write-only-from-ledger — violations are caught structurally, not by relying on model compliance.

### 3.4 Failure Modes (A5)

#### Budget Enforcement

The researcher skill consumes the dispatch protocol's budget framework (CTB-016 §8). Researcher-specific budget considerations:

- **Default budget:** 10 stages, 600s wall time (dispatch defaults). Research tasks may need more — the brief can override to 15-20 stages for complex topics.
- **Research loop cap:** The planning stage sets a maximum Research Loop iteration count (default: 5) based on the number of sub-questions. This is a pipeline-internal cap, separate from the dispatch stage budget.
- **Budget warning behavior:** When the dispatch budget reaches ≤20% remaining (runner injects warning per CTB-016 §8.2), the active Research Loop stage MUST prioritize coverage breadth over depth — fill remaining gaps with available sources rather than pursuing exhaustive search on one sub-question.

#### Runaway Loop Detection

The Research Loop can theoretically run indefinitely if convergence criteria are never met. Safeguards:

1. **Planning-stage cap:** The planning stage declares `max_research_iterations` in the handoff. Default: 5, hard maximum: 10.
2. **Diminishing returns detection:** If a Research Loop stage adds <2 new fact ledger entries AND coverage score improves by <0.05, the pipeline declares diminishing returns and advances to Synthesis with a note about incomplete coverage.
3. **Dispatch budget:** The runner's stage budget provides an outer bound regardless of pipeline-internal logic.

#### Garbage Result Handling

When `WebSearch` or `WebFetch` returns content that is clearly irrelevant, paywalled, or bot-blocked:

1. **Irrelevant results:** Skip and log. Do not create fact ledger entries for off-topic content.
2. **Paywall/login wall:** Classify source as `AbstractOnly` or `ToolLimited`. If the source is Tier A and critical to a sub-question, trigger access gate escalation (§3.5).
3. **Bot-blocked (403, CAPTCHA, JS-rendered):** Classify as `ToolLimited`. Log the URL for potential future MCP tool access.
4. **Rate limiting (429):** Back off and retry once. If still limited, log and move to next source. Do not retry indefinitely — the dispatch wall-time budget provides the outer bound.

#### Timeout Cascades

Stage-level timeouts are runner-managed (CTB-016). Within a stage, `WebFetch` timeouts are tool-level. If >50% of fetch attempts in a single Research Loop stage timeout, the stage should:
1. Log the timeout pattern.
2. Complete with available results rather than retrying.
3. Flag affected sub-questions as `coverage_score` degraded in the handoff.

### 3.5 Escalation Gates (A7)

The researcher skill defines four escalation gate types, consuming the dispatch protocol's structured escalation framework (CTB-016 §6). All escalations use the `choice` or `confirm` question types — no free-text per the dispatch protocol's injection prevention rules.

**Gate type mapping to CTB-016:** The dispatch protocol (CTB-016 §6.1) defines four gate types: `scope`, `access`, `conflict`, `risk`. The researcher skill's gate types map 1:1 to these protocol-defined types. No custom gate types are introduced — the researcher uses the protocol's enumeration directly. The escalation request schema (`gate_type` field in CTB-016 §6.2) accepts these exact string values.

| Gate Type | Trigger | CTB-016 `gate_type` | Question Type | Typical Questions |
|-----------|---------|---------------------|---------------|-------------------|
| **Scope Confirmation** | Research brief is ambiguous; sub-question generation reveals scope larger than expected | `scope` | `choice` | "Should I include [topic X] or limit to [topic Y]?"; "The question spans [N] sub-domains — proceed with all or prioritize?" |
| **Access Gate** | Tier A source behind paywall/login; critical source returns `ToolLimited` | `access` | `choice` | "Key source [title] is paywalled. Proceed with abstract only, or skip?"; "No academic sources found for [sub-question] — accept community sources?" |
| **Material Contradiction** | Two Tier A/B sources make incompatible claims on a key sub-question | `conflict` | `choice` | "Source A says X, Source B says Y. Which framing should the deliverable use?" |
| **High-Impact Claim** | Research finding has significant implications for a decision or action | `risk` | `confirm` | "Finding suggests [significant conclusion]. Include with caveats, or flag for deeper investigation?" |

**Escalation handoff update:** When an escalation is resolved and the pipeline resumes, the runner includes the user's answers in the next stage prompt (per CTB-016 §6.5). The Research Loop stage updates the handoff accordingly: scope answers adjust sub-question list, access answers update source tier targets, conflict answers set authoritative stance for contested `claim_key`s.

#### Escalation Discipline

- **Minimum evidence before escalation:** Do not escalate on the first access failure or first contradiction. Attempt at least 2 alternative sources before declaring an access gate, and find at least 2 contradicting sources before declaring a material contradiction. **Critical-path exception:** If a blocked source is uniquely authoritative (referenced by multiple secondary sources as a primary reference, or the only known source for a specific claim), escalate after one failed fetch + one alternate access attempt (e.g., alternate URL, DOI landing page). This prevents burning budget on futile alternative searches when the source is irreplaceable.
- **Batch escalation:** If a single Research Loop stage encounters multiple escalation triggers, batch them into one escalation request (up to the 3-question limit per CTB-016 §6.2).
- **Escalation budget awareness:** Each escalation pauses the pipeline for up to 30 minutes (escalation timeout per CTB-016 §6.6). Excessive escalation degrades the research experience. Target ≤2 escalations per research dispatch. This is advisory, not enforced — the dispatch protocol imposes no hard escalation count limit, and some research topics may legitimately require 3+ escalations. The Planning stage should set a `max_escalations` guideline in the handoff based on topic complexity; exceeding it triggers a log warning but does not block execution.

### 3.6 Evidence Store / Fact Ledger (A6)

The fact ledger is the central artifact of the research pipeline — a structured evidence store that accumulates during Research Loop stages and is consumed by Synthesis and Writing.

#### Schema

Written as YAML to `Projects/[project]/research/fact-ledger-[dispatch-id-short].yaml`:

```yaml
---
type: fact-ledger
project: project-name
dispatch_id: "string — full dispatch UUIDv7"
created: 2026-02-27
updated: 2026-02-27
---

sources:
  - source_id: "string"
    url: "string"
    title: "string"
    author: "string | null"
    publication_date: "string | null"
    venue: "string"
    tier: "A | B | C"
    ingestion: "FullText | AbstractOnly | SecondaryCitation | ToolLimited"
    authority_signals: ["..."]
    retrieved_at: "string"
    content_path: "string | null — vault-relative path to stored content"
    content_hash: "string | null — sha256[:12] of stored content"
    content_extracted_at: "string | null — ISO 8601"

entries:
  - entry_id: "FL-001"
    statement: "string"
    source_id: "string"
    quote_snippet: "string"
    confidence: "verified | supported | plausible | contested | unverifiable"
    claim_key: "string — normalized claim identifier for contradiction clustering"
    stance: "supports | refutes | mixed"
    contradicts: []
    notes: "string | null"
    sub_question: "sq-1"
    added_at_stage: 3
    supersedes: "FL-NNN | null — if this entry corrects a previous entry"
    status: "active | deprecated — deprecated entries are superseded"

verification:
  total_entries: 0
  by_confidence:
    verified: 0
    supported: 0
    plausible: 0
    contested: 0
    unverifiable: 0
  flags: []
```

#### Lifecycle

1. **Created** at the end of the Scoping stage (empty, with metadata).
2. **Populated** during Research Loop stages. Each stage appends sources and entries. The stage handoff references the ledger file path.
3. **Verified** during the Citation Verification stage. Verification summary written to the `verification` section. Corrections applied via the audit model (below).
4. **Consumed** by the Writing stage as the exclusive source of citable claims. Only `status: active` entries are citable.
5. **Preserved** after dispatch completion. The fact ledger is a permanent vault artifact — it's the provenance chain for every claim in the deliverable.

#### Mutation and Audit

The ledger uses an **append-with-supersede** model rather than in-place edits. During Research Loop stages, entries are append-only. During the Citation Verification stage, corrections are applied by creating new entries that supersede the originals:

1. The verifier creates a new entry with corrected fields (e.g., downgraded `confidence`).
2. The new entry's `supersedes` field references the original `entry_id`.
3. The original entry's `status` is set to `deprecated`.
4. Only `status: active` entries are citable by the Writing stage.

This preserves full provenance — the original entry, its correction, and the reason for correction are all retained. The verification summary records all supersede operations for audit visibility.

**Invariant:** A `deprecated` entry MUST have exactly one `active` entry that `supersedes` it. Orphaned deprecated entries (no superseding active entry) are a verification error.

#### Checkpoint Before Writing

The pipeline MUST NOT advance to the Writing stage until:
1. The fact ledger has ≥1 `status: active` entry per sub-question (or the sub-question is marked `blocked` via escalation).
2. The Citation Verification stage has run and produced a verification summary.
3. The verification summary contains no `confidence: verified` entries whose source `ingestion` is not `FullText` (over-confidence flags resolved via supersede).
4. No orphaned `deprecated` entries exist (every deprecated entry has a superseding active entry).

If the Tess review gate is active (bridge dispatch via Tess), the synthesized findings are relayed to Tess for operator review before Writing proceeds. This is an optional gate — direct Crumb invocation skips it.

### 3.7 MCP Source Tools — Future Architecture (A8)

V1 relies exclusively on built-in `WebSearch` and `WebFetch`. This section documents the migration path for when MCP infrastructure becomes available.

#### Source Tier Mapping to Tools

| Tier | V1 Tool | Future MCP Tool | Priority |
|------|---------|-----------------|----------|
| **A** | `WebSearch` + `WebFetch` (limited by paywalls) | Academic APIs: arXiv, PubMed, Semantic Scholar, JSTOR, Google Scholar | High — biggest quality gap |
| **B** | `WebSearch` + `WebFetch` (adequate) | Documentation APIs, GitHub API, conference proceedings | Medium |
| **C** | `WebSearch` + `WebFetch` (adequate) | Social APIs (Reddit, HN, Twitter) | Low |

#### Migration Path

1. **V1 (current):** `WebSearch` + `WebFetch` only. Source tier scoring is based on URL/domain analysis of web results.
2. **V2 (MCP available):** Add MCP source tools alongside web tools. The planning stage selects tools per sub-question based on source tier targets. MCP tools provide structured metadata (authors, citations, DOI) that `WebFetch` cannot.
3. **V3 (MCP mature):** Deprecate `WebFetch` for Tier A sources entirely. MCP tools become the primary source for academic/institutional content. `WebSearch` remains for discovery and Tier C content.

#### Tool Selection Logic (V2+)

The planning stage will include a tool selection step:
- For each sub-question, identify target source tiers.
- Map tiers to available tools (MCP + built-in).
- If MCP tools are unavailable for a needed tier, fall back to web tools and note the quality ceiling in the coverage assessment.

### 3.8 Vault Integration (A9)

Research operates on a dual-source model: public evidence (web/MCP) and personal knowledge (vault). The vault is both an input (existing knowledge) and an output (new research artifacts).

#### Vault as Input — Existing Knowledge

The Scoping stage queries the vault for existing coverage:

1. **Knowledge note search:** Query vault for `#kb/[topic]` tagged notes. In operator-dispatched sessions (Obsidian running), use `obsidian tag name=kb/[topic]`. In bridge-dispatched sessions (Tess dispatch via `claude --print`), Obsidian CLI is not available — fall back to `grep -r "kb/[topic]" Sources/ Domains/` or equivalent Grep tool patterns. The stage should check tool availability and adapt.
2. **Source index search:** Glob `Sources/**/*-index.md` for source indices covering the topic.
3. **Project design docs:** If the research serves a specific project, read relevant design docs for context and constraints.

Existing vault knowledge serves two purposes:
- **Coverage baseline:** Sub-questions already answered by high-quality vault notes may not need new web research. The planning stage adjusts the research plan accordingly.
- **Contradiction detection:** New evidence is cross-referenced against vault knowledge. Contradictions are flagged (in the fact ledger, not silently resolved).

#### Vault as Output — Research Artifacts

The Writing stage produces artifacts routed to the vault:

| Deliverable Type | Vault Location | Format |
|------------------|----------------|--------|
| **Research note** (project-scoped) | `Projects/[project]/research/` | Markdown with `type: research-note`, citations from fact ledger |
| **Knowledge note** (durable knowledge) | `Sources/[type]/` | Knowledge note format per file-conventions.md, `type: knowledge-note` |
| **Source index** (new source aggregation) | `Sources/[type]/` | Source index format per file-conventions.md, `type: source-index` |
| **Fact ledger** (evidence chain) | `Projects/[project]/research/` | YAML per §3.6 schema |

The deliverable type is determined by the research brief:
- **Project-scoped research** (answering a specific project question): produces a research note + fact ledger.
- **Knowledge acquisition** (building vault knowledge on a topic): produces knowledge note(s) + source index + fact ledger.

#### Research Programs (Future — A11)

A research program is a persistent research agenda that spans multiple dispatches. Programs define:
- Ongoing sub-questions to monitor
- Source freshness requirements
- Periodic re-research triggers

This is deferred to future work. The V1 pipeline handles single-dispatch research. The fact ledger and source index artifacts are designed to be composable across dispatches, enabling future program support.

### 3.9 Stage Prompt Design (Deferred to PLAN)

Each pipeline stage is a `claude --print` invocation whose behavior is entirely determined by its prompt. This spec defines *what* each stage does (inputs, outputs, convergence criteria) but does not define *how* each stage is prompted. Prompt design is deferred to the PLAN phase, which will address:

- **Injection context:** What gets injected per the dispatch protocol (CTB-016 §4.2) — system prompt (safety directives, budget remaining), user prompt (brief, previous stage summaries + handoffs, next-stage instructions).
- **Stage role identification:** How each stage knows its role — the `next_stage.instructions` field from the previous stage tells the current stage what to do, supplemented by the brief's `intent` and `scope`.
- **Ledger interaction pattern:** How stages read from and append to the fact ledger — file path passed in `context_files`, append pattern documented in stage instructions.
- **Convergence evaluation:** How the Research Loop stage receives the convergence formula and thresholds — serialized in the handoff, evaluated via inline computation within the stage.

The researcher skill SKILL.md procedure will contain the stage prompt templates. The dispatch protocol's two-layer prompt structure (system prompt for safety, user prompt for instructions) is the delivery mechanism.

### 3.10 Research Dispatch Telemetry

After the Writing stage completes (or the dispatch terminates early), the pipeline writes a telemetry file to `research/telemetry-[dispatch-id-short].yaml`. This is the calibration mechanism for the provisional convergence weights (§3.1.1) — without per-dispatch metrics, those weights remain untested assumptions indefinitely.

```yaml
---
type: research-telemetry
dispatch_id: "string"
completed_at: "ISO 8601"
rigor: "light | standard | deep"
---

timing:
  total_stages: 4
  research_loop_iterations: 3
  wall_time_seconds: 180

sources:
  total: 12
  by_tier: { A: 2, B: 5, C: 5 }
  by_ingestion: { FullText: 7, AbstractOnly: 3, SecondaryCitation: 1, ToolLimited: 1 }

evidence:
  total_entries: 18
  active_entries: 16
  deprecated_entries: 2
  by_confidence: { verified: 5, supported: 8, plausible: 2, contested: 1, unverifiable: 0 }

convergence:
  sub_questions: 4
  covered: 3
  blocked: 1
  quality_ceilings_applied: 1
  diminishing_returns_triggered: false
  iterations_to_converge:
    sq-1: 2
    sq-2: 1
    sq-3: 3
    sq-4: null  # blocked

escalations:
  total: 1
  by_type: { access: 1 }

verification:
  entries_checked: 16
  supersede_corrections: 2
  near_miss_flags: 1

writing:
  citation_count: 14
  orphan_entries: 2
  validation_passes: 1  # how many attempts before Writing Validation passed
```

The telemetry schema is intentionally flat and mechanical — no prose, no interpretation. The PLAN phase will specify how telemetry files are consumed for weight calibration (likely: aggregate across dispatches, compare predicted vs actual convergence, adjust tier/confidence weights).

## 4. Domain Classification & Workflow Depth

- **Domain:** Software
- **Workflow:** Full four-phase (SPECIFY → PLAN → TASK → IMPLEMENT)
- **Rationale:** The researcher skill is a code artifact (skill definition + procedure) that requires architecture, implementation, and testing. The pipeline has non-trivial state management (fact ledger, stage handoffs, convergence criteria) that demands formal decomposition.

## 5. Task Decomposition

### Phase 1: Core Pipeline + Evidence Store + Basic Provenance (A2, A6, A3)

| Task | Description | Risk | Acceptance Criteria |
|------|-------------|------|---------------------|
| RS-001 | Create skill definition (`SKILL.md`) with identity, context contract, and procedure skeleton | Low | Skill loads correctly; context contract specifies required/optional docs; procedure has stage structure |
| RS-002 | Implement Scoping stage — brief validation, vault knowledge query, scope output | Low | Scoping stage produces refined scope, exclusions, vault coverage report; writes initial fact ledger |
| RS-003 | Implement Planning stage — sub-question decomposition, search strategy, convergence criteria and thresholds per §3.1.1 | Medium | Planning stage decomposes question into ≥2 sub-questions; sets source tier targets and coverage thresholds; declares max_research_iterations; writes convergence criteria to handoff |
| RS-004 | Implement Research Loop stage — web search, source scoring, source content storage, fact ledger population | Medium | Research stage populates fact ledger with ≥1 entry per search; stores FullText source content to `research/sources/`; classifies sources by tier and ingestion; computes coverage scores per §3.1.1 |
| RS-005 | Implement fact ledger and handoff schema I/O — ledger create/append/read/supersede, handoff serialization/deserialization with ≤8KB enforcement and overflow fallback | Low | Ledger YAML valid; entries have all required fields including claim_key and stance; supersede operations create new entries and deprecate old ones; verification summary computable; handoff round-trips correctly; coverage_score, sub-question statuses, and quality_ceiling_reason preserved; overflow fallback to vault file triggers at 7KB |
| RS-006 | Implement Research Loop convergence — coverage scoring formula per §3.1.1, gap detection, quality ceiling fallback, loop termination | Medium | Coverage score computed per sub-question using weighted formula; Tier A fallback applies quality ceiling at 0.8; diminishing returns detected; loop terminates at threshold or cap |

### Phase 2: Citation Grounding + Failure Modes (A4, A5)

| Task | Description | Risk | Acceptance Criteria |
|------|-------------|------|---------------------|
| RS-007 | Implement Citation Verification stage — quote substring check against stored source content, confidence audit, over-confidence detection, supersede corrections, verification summary | Medium | Verifier checks `quote_snippet` against stored content; catches `verified` + non-`FullText` mismatch and creates supersede entries; produces verification summary with counts, flags, and supersede operations |
| RS-008 | Implement write-only-from-ledger enforcement — `[^FL-NNN]` citation format, Writing Validation checks (citation coverage, resolution, source chain) | Medium | Writing stage uses `[^FL-NNN]` format; validation catches uncited claims, unresolved references, and broken source chains; stage cannot declare `done` with validation failures |
| RS-009 | Implement failure mode handling — garbage results, rate limiting, timeout cascades | Medium | Irrelevant results skipped; paywalled sources classified correctly; >50% timeout triggers graceful degradation |
| RS-010 | Implement runaway loop detection — diminishing returns, planning-stage cap enforcement via handoff `max_research_iterations` | Low | Loop terminates on diminishing returns (<2 entries, <0.05 score improvement); respects `max_research_iterations` from handoff; Research Loop stage checks counter against cap |

### Phase 3: Synthesis + Writing + Escalation + Vault Integration (A7, A9)

| Task | Description | Risk | Acceptance Criteria |
|------|-------------|------|---------------------|
| RS-011 | Implement researcher-specific escalation gates — scope, access, conflict, risk (mapped 1:1 to CTB-016 gate types); critical-path exception for uniquely authoritative sources | Medium | Escalation triggers correctly identified; gate_type values match CTB-016 §6 enum; batching works; min-evidence-before-escalation respected with critical-path exception; escalation handoff updates sub-question list and stance |
| RS-012 | Implement vault-as-input — knowledge note search, source index lookup, coverage baseline | Low | Scoping stage queries vault; existing coverage reduces redundant research; contradictions flagged |
| RS-013 | Implement Synthesis stage — cross-referencing, contradiction clustering by claim_key, stance-weighted analysis, confidence rollup | Medium | Synthesis maps all claims to ledger entries; contradiction clusters identified per claim_key with stance counts weighted by tier; quality ceiling notes included for affected sub-questions; overall confidence assessed |
| RS-014 | Implement Writing stage — deliverable production from synthesis using `[^FL-NNN]` citations, Writing Validation enforcement | Medium | Final deliverable uses ledger-backed citations; Writing Validation passes (all 4 checks); vault-check validates |
| RS-015 | Implement vault-as-output — research note routing, knowledge note production, source index creation | Medium | Deliverables written to correct vault locations with valid frontmatter; vault-check passes |

### Phase 4: MCP Source Tools (A8) — Deferred

| Task | Description | Risk | Acceptance Criteria |
|------|-------------|------|---------------------|
| RS-016 | Design MCP tool integration layer — tool selection logic, structured metadata ingestion | Medium | Tool selection per sub-question; MCP metadata maps to source scoring dimensions |
| RS-017 | Implement Tier A MCP tools — arXiv, PubMed, Semantic Scholar | High | API authentication works; structured results populate fact ledger; paywall detection accurate |
| RS-018 | Update planning stage for multi-tool selection | Low | Planning stage selects tools per sub-question based on tier targets and tool availability |

### Future Work (A10-A12)

- **A10 — Evaluation Harness:** Automated testing of research pipeline quality. Requires ground-truth test cases with known answers and source sets. Design deferred until V1 produces enough research artifacts to establish quality baselines.
- **A11 — Research Program Reusability:** Persistent research agendas that span multiple dispatches. Requires program state management beyond single-dispatch fact ledgers. Design deferred until single-dispatch pipeline is validated.
- **A12 — Source Freshness:** Monitoring source staleness and triggering re-research when sources age past relevance thresholds. Related to A11 (programs). Design deferred.

## 6. Dependencies

### Consumed (upstream)

| Dependency | Source | Status |
|------------|--------|--------|
| Dispatch protocol (lifecycle, budget, escalation, stage I/O) | CTB-016 (`Projects/crumb-tess-bridge/design/dispatch-protocol.md`) | Complete |
| Vault file conventions (frontmatter, knowledge notes, source indices) | `_system/docs/file-conventions.md` | Stable |
| Bridge schema (request/response, operation allowlist) | `Projects/crumb-tess-bridge/design/bridge-schema.md` | Stable |
| Built-in `WebSearch` / `WebFetch` tools | Claude Code | Available |

### Consumed by (downstream)

| Consumer | Relationship |
|----------|-------------|
| Knowledge note pipeline | Research deliverables feed vault knowledge |
| Peer review skill | Research artifacts submitted for review |
| Tess dispatch | Research dispatched via bridge for Tess-initiated queries |
| Future MCP source tools | Researcher is the primary consumer when available |

## 7. Constraints

- **Context budget:** Each stage operates within a single `claude --print` context window. The fact ledger and stage handoffs must be designed to avoid exceeding context limits.
- **Tool limitations:** V1 is constrained to `WebSearch` (no direct API access) and `WebFetch` (cannot handle JS-rendered pages, paywalls, or CAPTCHA). These limitations are documented in source tier scoring, not worked around.
- **Dispatch budget:** Default 10 stages, 600s wall time. Research tasks consuming more must override in the brief. Hard caps (25 stages, 3600s) are absolute limits.
- **Escalation latency:** Each escalation blocks the pipeline for up to 30 minutes. Excessive escalation makes the pipeline unusable for time-sensitive research.
- **Single-agent:** V1 has no parallelism. Sub-questions are researched serially within Research Loop stages. This bounds throughput but simplifies state management.

## 8. Levers (High-Impact Intervention Points)

1. **Convergence thresholds** — Tuning coverage score thresholds and diminishing returns detection directly controls research depth vs. speed.
2. **Source tier weighting** — Adjusting tier weights changes how quickly sub-questions converge and what quality floor the pipeline enforces.
3. **Planning-stage decomposition quality** — Better sub-question generation produces more focused Research Loop stages, reducing wasted searches.
4. **Fact ledger schema** — The ledger is the central artifact. Schema changes affect every downstream stage.
5. **Write-only-from-ledger discipline** — This is the primary hallucination prevention mechanism. Relaxing it degrades citation integrity.

## 9. Second-Order Effects

- **Compound engineering:** The fact ledger pattern and write-only-from-ledger discipline may generalize to other Crumb skills that produce evidence-backed deliverables (e.g., competitive analysis, technical evaluations). If validated, propose as a reusable pattern in `_system/docs/solutions/`.
- **Peer review synergy:** The citation confidence taxonomy (§3.3) aligns with the peer review skill's unverifiable claims dimension (Rec 1 from `design/citation-verification-gap-findings.md`). A shared vocabulary benefits both skills.
- **Vault growth:** Active use of the researcher skill will accelerate vault growth (knowledge notes, source indices, fact ledgers). The audit skill's weekly review should monitor research artifact volume.
- **Context pressure:** Research dispatches are among the most context-intensive operations in the system. The dispatch protocol's budget enforcement and the fact ledger's structured format are the primary mitigation — but U-5 (context window pressure) needs monitoring.
