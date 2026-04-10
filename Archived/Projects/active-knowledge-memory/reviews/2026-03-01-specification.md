---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/active-knowledge-memory/specification.md
artifact_type: spec
artifact_hash: f9de8adb
prompt_hash: 600cc028
base_ref: null
project: active-knowledge-memory
domain: software
skill_origin: peer-review
created: 2026-03-01
updated: 2026-03-01
status: active
reviewers:
  - openai/gpt-5.2
  - google/gemini-3-pro-preview
  - deepseek/deepseek-reasoner
  - grok/grok-4-1-fast-reasoning
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
    latency_ms: 48353
    attempts: 1
    raw_json: Projects/active-knowledge-memory/reviews/raw/2026-03-01-specification-openai.json
  google:
    http_status: 200
    latency_ms: 43121
    attempts: 2
    raw_json: Projects/active-knowledge-memory/reviews/raw/2026-03-01-specification-google.json
  deepseek:
    http_status: 200
    latency_ms: 68755
    attempts: 1
    raw_json: Projects/active-knowledge-memory/reviews/raw/2026-03-01-specification-deepseek.json
  grok:
    http_status: 200
    latency_ms: 30995
    attempts: 1
    raw_json: Projects/active-knowledge-memory/reviews/raw/2026-03-01-specification-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Active Knowledge Memory Specification

**Artifact:** Projects/active-knowledge-memory/specification.md
**Mode:** full
**Reviewed:** 2026-03-01
**Reviewers:** OpenAI gpt-5.2, Google gemini-3-pro-preview, DeepSeek deepseek-reasoner, Grok grok-4-1-fast-reasoning
**Review prompt:** Structured review of AKM specification evaluating correctness, completeness, internal consistency, feasibility, clarity. Focus areas: surfacing modality framework, FTS5 evaluation gate design, ceremony budget claim, personal writing boost timing, cross-agent Tess advisory risks.

---

## OpenAI (gpt-5.2)

### Summary Assessment
The spec is directionally sound: it frames the right problem (passive KB), proposes a pragmatic v1 (Obsidian CLI/FTS5 + tags/topics/MOCs), and defines clear trigger points with an explicit relevance budget. The architecture is feasible at the stated scale and has a credible path to v2 (embeddings/hybrid retrieval) without rewrite.

Main weaknesses are: (1) ambiguity around "active focus" extraction and ranking signals (what exactly is queried, how combined, and how to avoid duplicate/noisy results), (2) potential hidden ceremony (operational ownership, tuning, evaluation, drift), and (3) under-specified cross-agent delivery/security and attention-management risks (Tess batching, operator trust, failure modes).

---

### Findings

- **[F1]**
  - **Severity:** SIGNIFICANT
  - **Finding:** The "active focus" context signal is the linchpin but is under-specified in terms of *deterministic extraction rules* and *precedence* across inputs (project state vs. task text vs. priorities vs. session history).
  - **Why:** Retrieval quality hinges on stable, repeatable context signals. If the extractor is fuzzy or shifts between runs, ranking will feel random and will be ignored (a core risk the spec itself calls out).
  - **Fix:** In AKM-001, explicitly define:
    - Required vs optional fields (e.g., `project_ids`, `task_summary`, `tags`, `keywords`, `time_horizon`, `excluded_terms`)
    - Precedence rules (e.g., task > current project > priorities > history)
    - Token/length caps per field
    - A canonical "context compilation" algorithm with 2-3 fixtures (golden test inputs/outputs).

- **[F2]**
  - **Severity:** SIGNIFICANT
  - **Finding:** v1 retrieval signals list "MOC proximity" and "wikilink traversal," but earlier facts state wikilink density is low and digests link nowhere--so those signals are likely misleading/ineffective initially.
  - **Why:** If the ranking algorithm gives weight to weak signals, it can bury genuinely relevant tag/FTS matches and increase noise.
  - **Fix:** In AKM-004, explicitly gate/weight signals based on corpus reality:
    - Default v1 weights: FTS5/BM25 + tags/topics >> MOC membership >> backlinks >> wikilinks
    - Add an *automatic "signal availability" check* (e.g., if wikilink graph degree is near-zero, clamp its weight to 0).

- **[F3]**
  - **Severity:** SIGNIFICANT
  - **Finding:** "No external services for v1" conflicts slightly with "keyword grep" in AKM-004; grep is local, but it risks bypassing the "index-backed" performance promise and may become the slow path at 1000+ notes.
  - **Why:** Using grep as a primary signal can create unpredictable latency and encourages adding ad-hoc heuristics that become maintenance-heavy.
  - **Fix:** Make "grep" explicitly a last-resort fallback with strict caps:
    - Only on a narrowed candidate set (e.g., notes returned by tag/topics search)
    - Or remove grep entirely and rely on Obsidian FTS5 + property/tag queries for v1.

- **[F4]**
  - **Severity:** CRITICAL
  - **Finding:** The spec promises "zero new maintenance rituals," yet introduces components that inherently require tuning and ongoing care: ranking weights, relevance thresholds, brief formatting, and a periodic evaluation gate (plus potential embedding index freshness later).
  - **Why:** If "zero ceremony" is interpreted literally, reality will violate the spec and erode trust. If interpreted as "no manual steps during normal work," it can be true--but it must be stated precisely.
  - **Fix:** Redefine the constraint as: "no recurring manual actions required to *operate* AKM during normal sessions." Then explicitly list acceptable maintenance:
    - One-time setup
    - Occasional tuning triggered only by measured failure (noise/ignored)
    - Automated evaluation harness (push-button) rather than manual procedures.

- **[F5]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Surfacing modalities (proactive/ambient/batched) are conceptually strong but missing key edge-case handling: what happens during rapid task switching, multi-task sessions, or when "ambient" content actually should interrupt (high criticality).
  - **Why:** Without guardrails, proactive surfacing can distract, and ambient surfacing can silently fail (never seen), while batched surfacing can become a "graveyard log."
  - **Fix:** Add modality-specific failure mode policies:
    - **Debounce** task-change trigger (e.g., min 10-20 minutes or explicit task boundary)
    - **Escalation rule** (if retrieval score above threshold X, allow a soft proactive nudge even in ambient mode)
    - **Batched digest SLA** (e.g., Tess delivers daily/next-conversation summary with max N items + "why now").

- **[F6]**
  - **Severity:** SIGNIFICANT
  - **Finding:** The spec doesn't define *deduplication and diversity* constraints (e.g., avoid returning 5 digests from the same book/MOC or 5 near-duplicates).
  - **Why:** Even with a relevance budget, homogenous results feel noisy and reduce perceived value.
  - **Fix:** Add ranking post-processing:
    - Max 1 item per source book/video unless explicitly requested
    - Max 2 items per tag/topic cluster
    - Prefer 1 "overview/MOC" + 1-2 "specific notes" mix when available.

- **[F7]**
  - **Severity:** SIGNIFICANT
  - **Finding:** The knowledge brief format target (<=500 tokens for 5 items) is good, but the spec doesn't define how summaries are produced without adding compute/LLM calls (especially under "no external services for v1").
  - **Why:** If one-line descriptions require generation at runtime, you either add latency/cost or you end up with low-quality truncations.
  - **Fix:** In AKM-002/004, specify summary source order:
    1. Existing frontmatter fields (e.g., `summary:` if present)
    2. First non-heading paragraph heuristic (local)
    3. Fallback: note title + matched terms
    And optionally add an *offline* summarization/enrichment step later (not in v1).

- **[F8]**
  - **Severity:** SIGNIFICANT
  - **Finding:** The FTS5 evaluation gate is directionally good but under-specified in methodology: what counts as "miss," how relevance is judged, and how to control for query formulation bias.
  - **Why:** A weak evaluation can trigger premature embeddings work (cost/complexity) or delay it too long (continued poor cross-domain recall).
  - **Fix:** Strengthen AKM-EVL protocol with:
    - A rubric: relevant / somewhat / irrelevant; and "miss" defined as "no relevant in top K (e.g., K=5 or 10)"
    - Separate metrics: Precision@5, Recall@50 (or Recall@K), and "novel cross-domain hit rate"
    - A blinded evaluation step (write expected relevant notes before running retrieval, when feasible)
    - Fixed query set + fixed context signals, stored as fixtures.

- **[F9]**
  - **Severity:** MINOR
  - **Finding:** The 40% cross-domain miss-rate threshold is plausible but not justified relative to baseline expectations and the cost of v2.
  - **Why:** Without rationale, the threshold may be debated endlessly or gamed by query selection.
  - **Fix:** Add a short justification and/or a two-tier decision:
    - >40% = start v2 implementation now
    - 25-40% = do a smaller semantic pilot (subset embeddings)
    - <25% = defer and re-evaluate at 500+ notes

- **[F10]**
  - **Severity:** SIGNIFICANT
  - **Finding:** "Completes in <5s" for retrieval is generous; session start + skill activation integrations add up. There's no explicit budget per trigger (e.g., <1s for ambient).
  - **Why:** Latency during skill activation can degrade the whole operating loop even if under 5 seconds.
  - **Fix:** Define performance SLOs per trigger:
    - Session start: <3s added
    - Skill activation (ambient): <1s typical, <2s p95
    - New content arrival (batched): <5s acceptable

- **[F11]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Cross-agent (Tess) mechanism is not sufficiently threat-modeled/governed: what files Tess can read, whether Tess can indirectly cause sensitive data leakage into briefs/logs, and how to prevent Tess from being overloaded by batched items.
  - **Why:** Even with "read-only," a summarization/logging path can expose more than intended, and batching can become unmanageable.
  - **Fix:** In AKM-010 add:
    - An explicit "Tess-visible surface area" (allowed directories/tags/types)
    - Redaction rules (exclude private journals or specific tags)
    - Rate limits + digest formatting rules (top N + grouped by theme + "actionability" flag)

- **[F12]**
  - **Severity:** SIGNIFICANT
  - **Finding:** "Personal writing boost" is a ranking lever but personal writing doesn't exist yet. The spec risks prematurely encoding weights/conventions that later don't match reality.
  - **Why:** Over-optimizing for a nonexistent category can distort early retrieval results (e.g., if misclassified notes get boosted).
  - **Fix:** Keep AKM-003 now (convention is cheap and avoids later migration), but implement boosting as:
    - Off by default until >=X notes exist (e.g., X=10)
    - Or a small boost with strict classification rules and tests in vault-check.

- **[F13]**
  - **Severity:** MINOR
  - **Finding:** The spec asserts MOCs as "compression layer," but doesn't specify how retrieval chooses between returning a MOC vs. returning leaf notes, nor how it avoids returning both redundantly.
  - **Why:** Without policy, you'll waste the relevance budget on navigation artifacts rather than actionable content.
  - **Fix:** Add a rule: for each cluster, return either the MOC (if broad) or leaf note (if specific). Optionally: "MOC first, then 1 best child note" max.

- **[F14]**
  - **Severity:** SIGNIFICANT
  - **Finding:** There is no explicit feedback loop for "noise/ignored" beyond vague recalibration. Given the stated primary risk is being ignored, this is a gap.
  - **Why:** Without minimal feedback capture, you can't tune ranking thresholds confidently.
  - **Fix:** Add a lightweight, zero-ceremony feedback capture:
    - A single command/flag: "useful / not useful" logged per brief
    - Or implicit signals (whether any surfaced note was opened within N minutes)

- **[F15]**
  - **Severity:** STRENGTH
  - **Finding:** Clear phased delivery (session start -> skill activation -> new content) with an explicit evaluation gate is a strong rollout strategy.
  - **Why:** Reduces integration risk and ensures learning before expanding surface area.
  - **Fix:** None.

- **[F16]**
  - **Severity:** STRENGTH
  - **Finding:** The modality framework (proactive/ambient/batched) is coherent and maps well to attention economics.
  - **Why:** Treating delivery as part of design (not just scheduling) prevents a common failure mode of "always-on suggestions."
  - **Fix:** None (but implement the debouncing/escalation improvements from F5).

- **[F17]**
  - **Severity:** STRENGTH
  - **Finding:** Good constraint hygiene: infrastructure separation, stable retrieval interface with evolving implementation, relevance budget, and "no external services for v1."
  - **Why:** Supports scale and avoids early over-engineering.
  - **Fix:** None.

- **[F18]**
  - **Severity:** SIGNIFICANT -- UNVERIFIABLE CLAIM
  - **Finding:** **UNVERIFIABLE CLAIM:** "LoCoMo benchmark: file-system agents achieved 74%..."
  - **Why:** This statistic influences architectural confidence; without citation it's hard to weigh.
  - **Fix:** Add a source citation (paper/link) or move to "anecdotal/observed" with context.

- **[F19]**
  - **Severity:** SIGNIFICANT -- UNVERIFIABLE CLAIM
  - **Finding:** **UNVERIFIABLE CLAIM:** "qmd... 96% token reduction vs. grep-based retrieval reported by a 600-note user."
  - **Why:** This is used as evidence for v2 viability; needs attribution.
  - **Fix:** Add URL/reference, or rephrase as anecdotal and non-decision-critical.

- **[F20]**
  - **Severity:** SIGNIFICANT -- UNVERIFIABLE CLAIM
  - **Finding:** **UNVERIFIABLE CLAIM:** "Anthropic's contextual retrieval technique... reduced failed retrievals by 49-67%..."
  - **Why:** Strong quantitative claim affecting v2 design choices; requires citation.
  - **Fix:** Link the Anthropic post/paper and clarify experimental conditions.

- **[F21]**
  - **Severity:** MINOR -- UNVERIFIABLE CLAIM
  - **Finding:** **UNVERIFIABLE CLAIM:** "Obsidian CLI... backed by Obsidian's SQLite FTS5 index... ~190ms per query..."
  - **Why:** Likely true in the author's environment but not verifiable here; it's also environment-dependent.
  - **Fix:** Note test conditions (machine, vault size, query types) and treat as local benchmark.

---

### Focus Area Responses

1) **Surfacing modalities:** Holds up conceptually (F16), but needs debouncing/escalation/SLA and "graveyard log" prevention (F5), plus dedupe/diversity (F6).

2) **FTS5 evaluation gate:** Good idea but needs stronger methodology and metrics (F8). Threshold is plausible but should be justified and tiered (F9).

3) **"Zero maintenance rituals" realism:** As written, it's internally risky (F4). Clarify what "ceremony" excludes, and formalize lightweight/automated maintenance boundaries.

4) **Personal writing boost forward-looking:** Convention now is sensible; boosting should be deferred/guarded until there's enough data (F12).

5) **Cross-agent risks:** Need governance of Tess-visible data, redaction, rate limits, and batching discipline (F11).

---

## Google (gemini-3-pro-preview)

### Executive Summary
The specification is **high-quality, well-structured, and pragmatically phased**. It correctly identifies the core problem of PKM (passive accumulation vs. active use) and proposes a solution that respects the constraints of a local, file-based OS. The distinction between v1 (vault-native FTS5) and v2 (embeddings) with a clear evaluation gate is a strong engineering decision that prevents premature optimization.

However, there is a **conflict between the "Zero Maintenance" constraint and the reliance on manually maintained MOCs** as a retrieval lever. Additionally, the definition of the "Ambient" modality in a text-based/CLI agent environment requires clearer mechanical definition to ensure it doesn't become invisible or hallucinatory.

---

### Findings

#### 1. Unverifiable Claims

*   **[F1] [SIGNIFICANT] UNVERIFIABLE CLAIM: LoCoMo Benchmark**
    *   **Finding:** The spec cites "LoCoMo benchmark: file-system agents achieved 74% with basic operations."
    *   **Why:** This appears to be a specific external benchmark or internal metric not standard in public literature. Reliance on this metric to justify the "memory stratification pattern" introduces risk if the benchmark is flawed or contextually different.
    *   **Fix:** Add a citation (URL/Paper) or internal reference note clarifying the source of this benchmark.

*   **[F2] [SIGNIFICANT] UNVERIFIABLE CLAIM: qmd performance stats**
    *   **Finding:** Claims "96% token reduction vs. grep-based retrieval reported by a 600-note user."
    *   **Why:** This statistic drives the decision to consider `qmd` for v2. If this is anecdotal or based on a different corpus structure, the efficiency gains may not translate to this vault.
    *   **Fix:** Treat `qmd` as a candidate requiring independent validation, rather than accepting the 96% figure as a planning constant.

*   **[F3] [SIGNIFICANT] UNVERIFIABLE CLAIM: Anthropic Contextual Retrieval stats**
    *   **Finding:** Claims "Anthropic's contextual retrieval technique... reduced failed retrievals by 49-67%."
    *   **Why:** While Anthropic has published on this, the specific percentages depend heavily on the dataset.
    *   **Fix:** Rephrase to "industry research suggests significant reduction in failure rates" or cite the specific Anthropic blog post/paper.

#### 2. Critical & Significant Findings

*   **[F4] [SIGNIFICANT] Contradiction: MOC Reliance vs. Zero Maintenance**
    *   **Finding:** Section 4.3 sets a constraint of "No new maintenance rituals." However, Section 4.4 lists "MOCs as compression layer" as a high-impact lever. MOCs (Maps of Content) are historically manual curation structures.
    *   **Why:** If retrieval relies on MOCs to be current, but there is no automation for MOC updates (Knowledge-Navigation Phase 4 is listed as "future"), the retrieval quality will degrade rapidly as the "Zero Maintenance" rule prevents the operator from updating MOCs manually.
    *   **Fix:** Explicitly define fallback behavior for retrieval when MOCs are stale, OR admit that MOC maintenance is a required ritual for v1 success.

*   **[F5] [SIGNIFICANT] Ambiguity in "Ambient" Modality for LLM Agents**
    *   **Finding:** Section 6 describes the "Ambient" modality (Skill Activation) as "available but not pushed." In a GUI (Obsidian), ambient means visible in a sidebar. In a CLI/Agent flow (Crumb), "available" usually means injected into the context window.
    *   **Why:** If the "Brief" is injected into the context window, it consumes tokens and attention regardless of whether the agent "uses" it. It is *mechanically* proactive (it is there), even if *behaviorally* passive. There is a risk of "Context Pressure" (mentioned in 4.5) causing the agent to hallucinate connections or get distracted by the KB content.
    *   **Fix:** Define the mechanism for "Ambient" more rigorously. Does the agent perform a distinct "Check KB" step (optional tool use) or is the context forcibly injected? If injected, rename "Ambient" to "Context Injection" to reflect the token cost reality.

*   **[F6] [SIGNIFICANT] Inconsistency in Tess Interaction Model**
    *   **Finding:** Section 6 (Surfacing Modality) lists "New Content Arrival" as the only trigger for Batched/Tess delivery. However, Section 4.1 shows Tess as a general "Consumer," and AKM-011 involves implementing "Tess-facing surfacing" for advisory purposes.
    *   **Why:** It is unclear if Tess can query the KB to advise on *current* work (not just new content). If Tess is to be an effective advisor, she needs read-access during the "Task Change" trigger, not just "New Content."
    *   **Fix:** Update the Modality Table (Section 6) to include a "Tess Advisory" row, or clarify that Tess accesses the "Ambient" signal generated for Crumb.

#### 3. Minor Findings & Strengths

*   **[F7] [STRENGTH] Phased Delivery & FTS5 Gate**
    *   **Finding:** The decision to gate v2 (Embeddings) behind an empirical evaluation of v1 (FTS5) using the incoming book batch is excellent.
    *   **Why:** It avoids "Resume Driven Development" and ensures the complex solution is only built if the simple solution fails.

*   **[F8] [MINOR] Vague "Active Focus" Definition**
    *   **Finding:** AKM-001 aims to define "Active Focus."
    *   **Why:** This is the prompt engineering pivot point. If the system cannot translate "Project State: Beta" + "Task: Fix bug" into a semantic search query, the system fails.
    *   **Fix:** Ensure AKM-001 includes "Query Translation" logic -- transforming state into search terms (e.g., "Fix bug" -> "Software debugging patterns").

---

### Focus Area Review

**1. Does the surfacing modality framework hold up?**
*   **Assessment:** Mostly yes, with the caveat regarding "Ambient" (F5).
*   **Edge Cases:** The spec does not address "Context Flooding." If "Session Start" brings up 5 items, "Task Change" brings up 5 items, and the agent has a long conversation history, the "Ambient" data might get truncated or confuse the agent.
*   **Verdict:** Needs mechanical clarification on how "Ambient" is exposed to a text-based agent.

**2. Is the FTS5 evaluation gate well-designed?**
*   **Assessment:** Yes.
*   **Sufficiency:** 10-15 queries is a small sample but sufficient for a "go/no-go" decision.
*   **Threshold:** A 40% miss rate for *cross-domain* connections via FTS5 is a reasonable (perhaps even optimistic) threshold. FTS5 excels at lexical recall but fails at semantic bridging. The evaluation is likely to fail, which correctly justifies the move to v2.

**3. Is "zero new maintenance rituals" realistic?**
*   **Assessment:** No (see F4).
*   **Hidden Ceremony:** The spec relies on MOCs (Maps of Content) to compress context. MOCs do not maintain themselves. Unless the system *only* queries the auto-generated indexes, the quality of retrieval depends on the manual hygiene of the MOCs. If the user stops updating MOCs, v1 retrieval performance degrades.

**4. The personal writing boost (forward-looking). Defer or keep?**
*   **Assessment:** Keep.
*   **Rationale:** Establishing the convention (`type: personal-writing`) costs nothing now. It prevents a future migration/refactor when that content type is introduced. It allows the ranking logic to be "correct" from day one.

**5. Risks in Cross-Agent (Tess) design?**
*   **Assessment:** Yes, under-specified (see F6).
*   **Risk:** The bridge protocol governs communication. If Tess "advises," she usually sends a message to Crumb. If the KB retrieval happens *inside* Tess's process, she needs to know what Crumb is doing to query relevantly. The spec implies Tess has "vault read access," but to provide relevant advice, she needs "Context Read Access" (what is Crumb doing right now?). The synchronization of context between the working agent (Crumb) and the advising agent (Tess) regarding KB queries is a gap.

---

## DeepSeek (deepseek-reasoner)

### Overall Assessment
This is a well-structured, comprehensive specification demonstrating strong systems analysis. The problem statement is clear, the architecture is thoughtfully layered, and the phased delivery approach is pragmatic. The document successfully balances ambition with feasibility and grounds decisions in existing infrastructure. Below are findings organized by severity.

---

### Findings

**F1**
- **Severity:** SIGNIFICANT
- **Finding:** The surfacing modality framework lacks a clear "off-ramp" for irrelevant results. The spec emphasizes avoiding noise but doesn't specify what happens when the system surfaces items the operator consistently ignores. This could lead to gradual distrust and eventual disabling of the feature.
- **Why:** A system that cannot learn from negative feedback will not improve its signal-to-noise ratio over time, violating Success Criterion #7 ("Not ignored").
- **Fix:** Add a lightweight feedback mechanism (e.g., a `kb-ignore` tag or a simple log of dismissed items) to the design of the trigger integrations (AKM-005, AKM-006). This data can later train a relevance classifier or calibrate ranking weights.

**F2**
- **Severity:** MINOR
- **Finding:** The FTS5 evaluation gate is well-designed but the "cross-domain miss rate >40%" threshold lacks justification. Why 40% and not 30% or 50%? The decision criterion feels arbitrary.
- **Why:** An arbitrary threshold could lead to premature acceleration of the v2 embedding work or unjustified delay, both incurring cost.
- **Fix:** During the PLAN phase for AKM-EVL, define the threshold based on the *cost of a miss* (e.g., "If we miss more than X cross-domain connections per week, we are losing Y hours of re-derivation effort"). Ground the percentage in a unit of work.

**F3**
- **Severity:** SIGNIFICANT
- **Finding:** The claim of "zero new maintenance rituals" is optimistic. The retrieval engine script (AKM-004), its potential configuration, the evaluation gate (AKM-EVL), and any embedding index (future v2) all constitute new maintenance surfaces. While automated, they are new components that can break, require updates, or need monitoring.
- **Why:** Overclaiming on this core design constraint risks undermining the "Ceremony Budget Principle." Acknowledging minimal, unavoidable maintenance is more honest and sets better expectations.
- **Fix:** Amend Section 10 or the success criteria to clarify "near-zero" or "minimal, automated maintenance." Specify that maintenance is limited to script updates and potential index rebuilds, not daily/weekly manual rituals.

**F4**
- **Severity:** STRENGTH
- **Finding:** The decision to establish a personal writing convention (AKM-003) forward-looking is correct and proactive.
- **Why:** Personal writing is identified as the highest-value content. Defining its convention *before* it arrives ensures it will be immediately discoverable by the retrieval engine, securing the "personal writing boost" lever from the start. Deferring would create technical debt and require retroactive tagging.
- **Fix:** None. This is a good design choice.

**F5**
- **Severity:** SIGNIFICANT
- **Finding:** The cross-agent (Tess advisory) design underestimates the risk of context mismatch. Tess's "current work" context (e.g., reviewing a project state) may differ significantly from the context signal generated for Crumb (e.g., active task). The spec mentions "Tess can access KB context relevant to her current work" but doesn't define how Tess's context is derived.
- **Why:** If Tess uses an inappropriate context signal, her advisory surfacing will be irrelevant, breaking the curation boundary (she becomes a source of noise).
- **Fix:** In AKM-010, explicitly define the context signal extraction for Tess. Likely, it should be based on the content of her current advisory task or the project she is reviewing, mirroring but not identical to Crumb's signal.

**F6**
- **Severity:** MINOR
- **Finding:** The dependency graph shows AKM-007 (new content arrival) depending only on AKM-004. However, its acceptance criterion mentions appending a "Related knowledge" section to the "run-log entry." This implies a dependency on the structure and location of the run-log, which is an external system detail not specified here.
- **Why:** This creates a hidden dependency that could break integration or complicate implementation.
- **Fix:** In the AKM-007 description, specify the integration point more clearly (e.g., "appends to the feed-pipeline skill's run-log output in `_system/logs/`") or note it as an interface to be confirmed during PLAN.

**F7**
- **Severity:** STRENGTH
- **Finding:** The three-tiered surfacing modality (Proactive/Ambient/Batched) is a robust framework that thoughtfully matches interaction patterns to cognitive load and workflow.
- **Why:** It recognizes that not all information needs immediate attention. Pushing at session start, making available during tasks, and batching for external review is a nuanced approach that respects attention and aligns with natural work rhythms.
- **Fix:** None. This is a key strength of the design.

**F8**
- **Severity:** SIGNIFICANT
- **UNVERIFIABLE CLAIM:** The specification cites: "LoCoMo benchmark: file-system agents achieved 74% with basic operations, outperforming specialized memory tools" and "qmd... 96% token reduction vs. grep-based retrieval reported by a 600-note user." These are specific performance metrics without cited sources.
- **Why:** While not critical to the spec's logic, verifiable benchmarks would strengthen the justification for architectural choices (reliance on file-system queries, consideration of qmd for v2).
- **Fix:** If these are internal benchmarks, reference the internal doc or test. If external, add a citation footnote.

**F9**
- **Severity:** MINOR
- **Finding:** The "Category-aware relevance" constraint states "no uniform temporal decay" but the ranking description in AKM-004 only mentions a "personal writing boost." The mechanism for implementing category-aware decay (or lack thereof) for other categories (e.g., philosophical vs. operational) is not specified.
- **Why:** This is a nuanced requirement that could be overlooked during implementation, leading to a uniform date-sort bias.
- **Fix:** In AKM-004's description, explicitly state that ranking should *not* use note-creation/modification date as a factor, or specify a category-based date-weighting table (weight=1 for personal/philosophical, weight<1 for operational/news).

**F10**
- **Severity:** STRENGTH
- **Finding:** The phased delivery plan (Milestone 1 -> 2 -> 3 with an evaluation gate) is excellent. It delivers increasing value while de-risking the project. Each phase validates a core assumption before moving to the next, more complex integration.
- **Why:** This is a disciplined, iterative approach that aligns with the project's "system" class and complex dependencies. It allows for empirical course correction (via the FTS5 gate) before major investment in v2.
- **Fix:** None.

### Summary
The Active Knowledge Memory specification is **largely correct, complete, and feasible**. Its main strengths are a clear problem definition, a pragmatic phased architecture, and thoughtful integration patterns. The primary risks lie in potentially hidden maintenance, undefined feedback loops, and some ambiguous cross-agent mechanics. These are addressable in the subsequent PLAN phase without requiring a spec rewrite.

**Recommended next steps:** Address findings F1, F3, and F5 during the PLAN phase for the affected tasks (AKM-005/006/010). Findings F2 and F9 should be noted for detailed design work. The unverifiable claims (F8) should be sourced if possible.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]
  [Severity]: SIGNIFICANT
  [Finding]: Multiple unverifiable factual claims about vault state and performance, e.g., "KB corpus composition (verified): 43 notes in Sources/...", "~190ms per query at current scale", "LoCoMo benchmark: file-system agents achieved 74%...", "96% token reduction vs. grep-based retrieval reported by a 600-note user".
  [Why]: These underpin assumptions (A1, A2) and feasibility claims (scale to 1000+ notes); if inaccurate, the entire v1 retrieval rationale collapses, risking overconfidence in vault-native queries.
  [Fix]: Prefix with "SELF-REPORTED:" or remove "verified" language; require empirical validation in a pre-PLAN vault snapshot script.

- [F2]
  [Severity]: SIGNIFICANT
  [Finding]: Surfacing modality framework (proactive/ambient/batched) lacks handling for overlapping triggers, e.g., new content arrives during session start or skill activation -- does it deduplicate briefs, suppress duplicates, or compound them?
  [Why]: Overlaps are inevitable (e.g., feed-pipeline runs mid-session), leading to redundant or noisy output that erodes trust and violates relevance budget (A4), potentially causing the system to be ignored (success criterion 7).
  [Fix]: Add section 6.5 "Trigger Overlap Handling" specifying deduplication by note path and union of top-N results across triggers.

- [F3]
  [Severity]: SIGNIFICANT
  [Finding]: FTS5 evaluation gate's 40% cross-domain miss rate threshold is arbitrary and unjustified; test dimensions (cross-domain, within-domain, noise) are sufficient but lack quantifiable scoring rubric (e.g., how to score "relevant" per query?).
  [Why]: Poor gate design risks premature v2 acceleration (false positive misses) or prolonged v1 inadequacy (false negatives), especially post-300 book influx when cross-domain gaps amplify (U4). Threshold feels pulled from thin air, undermining decision credibility.
  [Fix]: Justify threshold via literature (e.g., cite retrieval eval benchmarks like BEIR with similar rates) or pilot 3-5 queries now; define relevance rubric (e.g., "operator confirms >=1 actionable item").

- [F4]
  [Severity]: CRITICAL
  [Finding]: "Zero new maintenance rituals" claim (sections 6, 9.6, 10) is contradicted by introducing new scripts (AKM-004), skill modifications (AKM-005/006), vault-check rules (AKM-003), and an evaluation checkpoint (AKM-EVL) requiring manual test execution.
  [Why]: This violates core "Ceremony Budget Principle" (section 4.3) and "Maintenance gravity" (section 10); hidden ceremony (debugging scripts, re-testing post-vault changes, running evals) scales with KB growth, turning automatic surfacing into another "thing to maintain."
  [Fix]: Revise claim to "Minimize new rituals; automate eval via script" and add AKM-013 for self-monitoring (e.g., log hit rates, alert on <50%).

- [F5]
  [Severity]: SIGNIFICANT
  [Finding]: Personal writing boost (ranking priority, A5, AKM-003) is forward-looking with no current content ("doesn't exist yet"), yet baked into v1 retrieval core (AKM-004 ranking) and success criteria (#2).
  [Why]: Premature prioritization risks v1 irrelevance/noise if boost dominates mediocre future content; defers real value until content arrives, undermining early milestones' validation.
  [Fix]: Defer boost to post-AKM-003 content creation; make it configurable toggle in retrieval script with empirical calibration in AKM-012.

- [F6]
  [Severity]: SIGNIFICANT
  [Finding]: Cross-agent Tess advisory (AKM-010/011) underestimates risks like coordination failures (e.g., Tess ignores stale briefs), boundary violations (Tess tempted to suggest KB edits despite "flags only"), or bridge protocol overload if extended.
  [Why]: Highest-risk milestone (section 7); vague options (a/b/c) without pros/cons/tradeoffs invite implementation drift, potentially breaking "Curation boundary" (section 4.3) and causing inter-agent friction.
  [Fix]: Flesh out AKM-010 with decision matrix (e.g., option b: file-based least risky); add acceptance criteria for boundary tests (e.g., "Tess output contains no edit suggestions").

- [F7]
  [Severity]: SIGNIFICANT
  [Finding]: Active focus signal format (AKM-001) lacks mechanical definition of sources/fields, e.g., how to weight "session history" vs. "operator priorities," or handle multi-project states.
  [Why]: Foundational (risk: medium); ambiguity propagates to all retrieval quality, invalidating assumptions A1/A6 and success criterion #5 (cross-domain). U5 explicitly flags this as unknown.
  [Fix]: Provide YAML schema example in section 8 (e.g., `{projects: [...], keywords: [...], weight: {history: 0.4}}`); prototype 2 signals in spec.

- [F8]
  [Severity]: MINOR
  [Finding]: Knowledge brief format (AKM-002) targets "<=500 tokens for 5 items" but doesn't specify tokenization method or enforcement (e.g., truncate summaries?).
  [Why]: Minor context pressure risk (section 4.5); inconsistent with "compact" goal if LLM tokenizers vary.
  [Fix]: Specify "gpt-4o-mini tokenizer" and add truncation rule (e.g., "summary <=50 tokens").

- [F9]
  [Severity]: SIGNIFICANT
  [Finding]: Retrieval engine v1 ranking lacks specifics beyond high-level signals (tag match, MOC proximity); no algorithm pseudocode or weights, despite BM25 gap acknowledgment (U4).
  [Why]: Core logic (AKM-004, medium risk); vagueness invites poor empirical results in AKM-EVL, especially cross-domain where lexical overlap fails.
  [Fix]: Add section 4.1.2 "v1 Ranking Formula" (e.g., score = 2*personal_boost + 1.5*tag_overlap + MOC_depth).

- [F10]
  [Severity]: MINOR
  [Finding]: Dependency graph omits arrow from AKM-EVL to potential v2 impl; parallel embedding design (AKM-008/009) noted but not gated explicitly.
  [Why]: Minor clarity issue; readers might assume v2 auto-follows, confusing phased delivery (section 7).
  [Fix]: Update graph with dashed "if miss>40%" arrow to new AKM-Impl tasks.

- [F11]
  [Severity]: STRENGTH
  [Finding]: Phased delivery (section 7) with sequential milestones and FTS5 gate effectively bounds risk, validating layers incrementally.
  [Why]: Holds up under scrutiny -- Milestone 1 tests core engine without integrations; gate uses real corpus timing smartly. Edge case (books delayed) handled implicitly by parallel design.
  [Fix]: N/A

- [F12]
  [Severity]: STRENGTH
  [Finding]: System map (section 4.1) and levers (section 4.4) clearly leverage existing vault signals (MOCs, tags) without new infra for v1, aligning with constraints.
  [Why]: Verified against facts/assumptions -- exploits hub-and-spoke structure (3.1), scales per A2. Assumption of low wikilink density doesn't break it (tag/FTS5 primary).
  [Fix]: N/A

- [F13]
  [Severity]: MINOR
  [Finding]: Section 11 research notes are comprehensive but buried; key insights (e.g., RRF for hybrid) could influence PLAN earlier.
  [Why]: Minor discoverability; risks overlooking during task decomp.
  [Fix]: Promote top 3 to section 4.4 Levers or section 7.

---

## Synthesis

### Consensus Findings

**CF-1: "Zero ceremony" claim is overstated** (All 4 reviewers: OAI-F4 CRITICAL, GEM-F4 SIGNIFICANT, DS-F3 SIGNIFICANT, GRK-F4 CRITICAL)

The spec promises "zero new maintenance rituals" but introduces scripts, skill modifications, vault-check rules, and an evaluation checkpoint that are new maintenance surfaces. All four reviewers flagged this — the two rating it CRITICAL are correct. The claim as written sets an expectation the implementation cannot meet. The fix is precise language: "no recurring manual actions required to operate AKM during normal sessions." One-time setup, automated evaluation, and occasional tuning triggered by measured failure are acceptable maintenance — but they exist.

**CF-2: Cross-agent Tess advisory is under-specified** (All 4: OAI-F11, GEM-F6, DS-F5, GRK-F6)

All reviewers flagged that AKM-010/011 needs more specificity: Tess's context signal derivation (DS-F5), visible surface area and redaction rules (OAI-F11), synchronization of Crumb's working context to Tess (GEM-F6), and boundary enforcement tests (GRK-F6). This is Milestone 3 — the highest-risk phase. The spec should strengthen AKM-010's acceptance criteria with boundary tests and a decision matrix for delivery mechanism options.

**CF-3: Unverifiable claims need citations or language downgrade** (All 4: OAI-F18/19/20/21, GEM-F1/2/3, DS-F8, GRK-F1)

LoCoMo 74%, qmd 96% token reduction, Anthropic contextual retrieval 49-67% — all cited without sources. The vault corpus stats ("verified") are self-reported measurements that should be labeled as such. These claims inform architectural confidence but aren't decision-critical — the phased approach validates empirically regardless. Add citations where available, downgrade language where not.

**CF-4: FTS5 40% threshold needs justification** (3 of 4: OAI-F9, DS-F2, GRK-F3)

The threshold is flagged as arbitrary. OpenAI proposes a tiered approach (>40% implement, 25-40% pilot, <25% defer). DeepSeek wants it grounded in cost-of-miss. Grok wants a relevance rubric. Gemini dissents — calls it "reasonable, perhaps even optimistic" and expects FTS5 to fail cross-domain. The tiered approach (OAI-F9) is the strongest fix: it replaces a binary gate with a graduated decision.

**CF-5: Active focus signal needs mechanical specificity** (3 of 4: OAI-F1, GEM-F8, GRK-F7)

The context signal is the linchpin but under-specified: no field precedence, no multi-project handling, no example schema. This is correct — but it's AKM-001's job (a design task). The spec should clarify that this is deliberately deferred to PLAN, not overlooked.

**CF-6: Feedback loop for noise/ignored is missing** (2 of 4: OAI-F14, DS-F1)

The spec identifies "ignored if noisy" as the primary risk but defines no feedback mechanism. A lightweight signal — even just logging whether surfaced notes were subsequently read — would enable ranking calibration. Zero-ceremony constraint means this must be automatic, not a manual rating step.

### Unique Findings

**OAI-F6: Deduplication/diversity constraints** — Genuine insight. Without diversity rules, the top 5 could be 5 digests from the same book. Max 1 per source, max 2 per tag cluster, prefer MOC+leaf mix. Worth adding to AKM-004 acceptance criteria.

**OAI-F7: Knowledge brief summary production method** — Genuine insight. The brief needs one-line summaries but the spec doesn't say how they're generated without LLM calls (which violates "no external services for v1"). Frontmatter fields → first paragraph heuristic → title+matched terms is the right fallback chain.

**OAI-F10: Per-trigger performance SLOs** — Genuine insight. <5s is too generous for ambient (skill activation). Session start <3s, ambient <1s typical, batched <5s. Worth adding.

**GEM-F5: "Ambient" modality is mechanically proactive in CLI context** — Genuine insight, different from CF-5. In a GUI, "ambient" means a sidebar. In a CLI/agent, "available" means injected into context. If the brief is injected, it consumes tokens regardless. The spec should acknowledge this — "ambient" in this context means "loaded during context gathering, used at agent discretion, not displayed to operator."

**GEM-F4: MOC maintenance as hidden ceremony** — Genuine insight, extends CF-1. If retrieval relies on current MOCs but MOC updates are manual (knowledge-navigation Phase 4 deferred), retrieval quality degrades as MOCs go stale. The retrieval engine should have fallback behavior when MOCs are stale (tag/FTS5 queries that bypass MOC traversal).

**DS-F9: Category-aware decay implementation details** — Valid. The constraint says "no uniform decay" but the ranking spec only mentions "personal writing boost." AKM-004 should explicitly state: do not use creation/modification date as a ranking factor unless the note category is operational/news-derived.

### Contradictions

**Personal writing boost timing:** OAI-F12 and GRK-F5 recommend deferring the ranking boost until content exists. DS-F4 and GEM call it correct and proactive to establish now. On closer read, all four agree that establishing the convention (AKM-003) is right. The disagreement is whether the ranking weight should be active in v1 with no test data. OAI's resolution is best: "off by default until >=N notes exist." This satisfies both positions.

**FTS5 threshold expectation:** Gemini expects FTS5 to clearly fail at cross-domain ("perhaps even optimistic"). The other three think the threshold needs justification but don't predict the outcome. This isn't a contradiction — it's a prediction difference. The tiered approach resolves it: design the evaluation to produce a gradient, not a binary.

### Action Items

**Must-fix:**

- **A1** (CF-1, sources: OAI-F4, GEM-F4, DS-F3, GRK-F4): Redefine the "zero ceremony" claim. Replace "Zero new maintenance rituals" in §9 success criteria and §10 constraints with "No recurring manual actions required to operate AKM during normal sessions." Explicitly acknowledge: one-time setup, automated evaluation, and occasional tuning triggered by measured failure are acceptable maintenance.

- **A2** (CF-3, sources: OAI-F18/19/20, GEM-F1/2/3, DS-F8, GRK-F1): Add citations for LoCoMo benchmark, qmd user report, and Anthropic contextual retrieval. Where citations unavailable, downgrade language (e.g., "reported" → "anecdotal"). Label vault corpus stats as "measured [date]" rather than "verified."

**Should-fix:**

- **A3** (CF-2, sources: OAI-F11, GEM-F6, DS-F5, GRK-F6): Strengthen AKM-010 acceptance criteria with: (a) explicit Tess-visible surface area definition, (b) curation boundary enforcement test ("Tess output contains no edit/tag/create suggestions"), (c) decision matrix for delivery mechanism options (a/b/c) with pros/cons.

- **A4** (CF-6, sources: OAI-F14, DS-F1): Add a lightweight, automatic feedback mechanism to AKM-005/006 design. Minimum viable: log which surfaced notes were subsequently read in the same session. No manual rating step.

- **A5** (CF-4, sources: OAI-F9, DS-F2, GRK-F3): Replace the binary 40% threshold with a tiered decision: >40% = implement v2 now, 25-40% = semantic pilot (subset embeddings), <25% = defer and re-evaluate at 500+ notes. Add a relevance rubric to AKM-EVL (relevant / somewhat / irrelevant per query result).

- **A6** (unique: OAI-F6): Add result diversity constraints to AKM-004 acceptance criteria: max 1 item per source (book/video), max 2 per tag cluster, prefer overview+specific mix.

- **A7** (unique: OAI-F7): Add summary production method to AKM-002/004: frontmatter `summary` field → first non-heading paragraph → title + matched terms. No LLM calls in v1.

- **A8** (unique: GEM-F5): Clarify "ambient" modality mechanism in §6: in CLI/agent context, "ambient" means loaded during skill context gathering at agent discretion, not displayed to operator, not pushed. Acknowledge token cost — the brief is injected and consumed regardless.

- **A9** (unique: GRK-F2): Add trigger overlap handling to §6: deduplication by note path across triggers within a session; union of top-N when multiple triggers fire in sequence.

**Defer:**

- **D1** (CF-5, sources: OAI-F1, GEM-F8, GRK-F7): Active focus signal schema and field precedence — deliberately deferred to PLAN (AKM-001). Not a spec gap; it's a design task correctly scoped.

- **D2** (unique: OAI-F10): Per-trigger performance SLOs — appropriate for PLAN. Note the recommendation: session start <3s, ambient <1s, batched <5s.

- **D3** (unique: GRK-F9): v1 ranking formula pseudocode — appropriate for PLAN (AKM-004 design).

- **D4** (unique: DS-F9): Category-aware decay implementation — appropriate for PLAN. Note: AKM-004 should explicitly exclude date-based ranking for non-operational content.

- **D5** (unique: GEM-F4): MOC staleness fallback — appropriate for PLAN. The retrieval engine should have fallback paths when MOC traversal yields low results.

### Considered and Declined

- **OAI-F3** (grep bypasses index-backed performance): `incorrect` — In the spec's architecture, Obsidian CLI FTS5 IS the keyword search. "Keyword grep" in AKM-004 refers to the same index-backed query mechanism, not a separate file-scanning grep. The wording could be clearer but the architecture is sound.

- **GRK-F8** (specify tokenizer for 500-token budget): `overkill` — The 500-token target is approximate design guidance for AKM-002, not a hard enforcement spec. Specifying a tokenizer at spec level is premature; the PLAN phase will operationalize this.

- **GRK-F10** (dependency graph missing dashed arrow): `incorrect` — The note immediately below the graph already states: "Embedding *implementation* is gated by AKM-EVL results." The information is present.

- **GRK-F13** (promote research notes from §11 to §4.4): `constraint` — §11 is deliberately separated from the system map. Research notes are PLAN inputs; Levers are spec-level architectural decisions. Mixing them conflates the spec/design boundary.

- **DS-F6** (AKM-007 run-log hidden dependency): `out-of-scope` — The run-log is a well-established vault convention documented in CLAUDE.md and used by every project. It's not an "external system detail" — it's core infrastructure. Integration point will be refined during PLAN.

- **GRK-F5** (defer personal writing boost entirely): `constraint` — Establishing the convention now (AKM-003) is cheap and prevents future migration. The compromise (A1's resolution of the contradiction) is the right call: convention now, ranking boost off by default until >=N notes exist.
