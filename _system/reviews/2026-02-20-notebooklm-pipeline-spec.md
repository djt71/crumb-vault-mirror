---
type: review
review_mode: full
review_round: 3
prior_review: null
artifact: Projects/notebooklm-pipeline/design/specification.md
artifact_type: spec
artifact_hash: cfc0eec0
prompt_hash: a01ee73e
base_ref: null
project: notebooklm-pipeline
domain: learning
skill_origin: peer-review
created: 2026-02-20
updated: 2026-02-20
reviewers:
  - deepseek/deepseek-reasoner
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
reviewer_meta:
  deepseek:
    http_status: 200
    latency_ms: 71144
    attempts: 1
    raw_json: _system/reviews/raw/2026-02-20-notebooklm-pipeline-spec-deepseek.json
tags:
  - review
  - peer-review
  - notebooklm-pipeline
---

# Peer Review: NotebookLM Pipeline Specification

**Artifact:** `Projects/notebooklm-pipeline/design/specification.md`
**Mode:** full
**Reviewed:** 2026-02-20
**Reviewers:** DeepSeek V3.2-Thinking (via deepseek-reasoner)
**Context:** Round 3 — DeepSeek's first review of this spec. Rounds 1-2 were GPT-5.2, Gemini 3 Pro, Perplexity. User requested DeepSeek-only review before PLAN phase.

---

## DeepSeek (deepseek-reasoner)

### [F1]
- **[Severity]:** SIGNIFICANT
- **[Finding]:** Chrome extension dependency creates single point of failure without documented mitigation plan
- **[Why]:** The entire pipeline depends on third-party Chrome extensions (especially "NotebookLM Ultra Exporter") that could break with any NotebookLM UI update, become unsupported, or require permissions that change. The spec acknowledges fragility but lacks a contingency plan beyond manual copy-paste, which doesn't scale for heavy usage.
- **[Fix]:** Add explicit contingency task: If extensions become unusable, implement a local Bookmarklet/JavaScript snippet that users can run in NotebookLM's DevTools console to extract structured markdown. Document this as backup path in NLM-003.

### [F2]
- **[Severity]:** SIGNIFICANT
- **[Finding]:** `source_id` collision risk from simple slug generation
- **[Why]:** The `source_id` generation method (`kebab(author-surname + short-title)`) will collide for:
  1. Multiple authors with same surname writing on similar topics (e.g., "smith-thinking" could match multiple Smiths)
  2. Different editions/translations of same work
  3. Sources where author attribution is unclear (corporate authors, anonymous works)
  Collisions would incorrectly merge unrelated sources during deduplication.
- **[Fix]:** Enhance `source_id` with disambiguation tuple: `kebab(author-surname + short-title + year-first-4-chars-of-title-hash)`. Include collision detection in inbox-processor that alerts when two sources share same base slug but have different canonical URLs/ISBNs.

### [F3]
- **[Severity]:** MINOR
- **[Finding]:** `scope` field ambiguity for non-linear media
- **[Why]:** The `scope` field assumes chapter/section/timestamp segmentation, but podcasts and interviews often have overlapping topics rather than linear progression. "timestamp:<range>" may not capture conceptual boundaries. This could lead to either too-fine or too-coarse scoping.
- **[Fix]:** For `source_type: podcast|video`, allow `scope: topic:<name>` alongside timestamp ranges. Update query templates to support topic-based extraction prompts.

### [F4]
- **[Severity]:** STRENGTH
- **[Finding]:** Dual sentinel marker design is robust against export transformations
- **[Why]:** Using both HTML comment and plain-text markers anticipates Chrome extensions that strip HTML comments, ensuring detection works across export variations. This shows good defensive design thinking.

### [F5]
- **[Severity]:** SIGNIFICANT
- **[Finding]:** Missing backlink strategy from domain summaries to knowledge notes
- **[Why]:** The spec focuses on forward-linking (knowledge notes → projects/domains via tags) but doesn't specify how domain summary notes should reference relevant Sources/. Without backlinks, domain summaries become disconnected from the knowledge base they should synthesize.
- **[Fix]:** Add convention: Domain overview notes should include `## Source Notes` section with `[[wikilinks]]` to key knowledge-notes from that domain. Consider auto-generating this during NLM processing for high-relevance sources.

### [F6]
- **[Severity]:** MINOR
- **[Finding]:** Template promotion creates symlink dependency that may break across systems
- **[Why]:** Symlinking from `Projects/notebooklm-pipeline/templates/` to `docs/templates/notebooklm/` assumes all environments support symlinks. Some cloud sync services don't preserve symlinks properly.
- **[Fix]:** Instead of symlinks, maintain master templates in `docs/templates/notebooklm/` and have project reference them directly. Or use a template registry file that points to the canonical location.

### [F7]
- **[Severity]:** SIGNIFICANT
- **[Finding]:** Daily query limit constraint not addressed in workflow design
- **[Why]:** NotebookLM AI Pro's ~50 queries/day limit directly impacts template-heavy workflows. The spec mentions batching but doesn't provide concrete guidance on which templates to prioritize or how to structure session batches.
- **[Fix]:** Add to workflow guide: "Batch Strategy" section recommending prioritization and monitoring.

### [F8]
- **[Severity]:** STRENGTH
- **[Finding]:** Quality gate for low-citation sources shows good content integrity thinking
- **[Why]:** Auto-tagging `needs_review` for podcasts/videos and including "Uncertain / Needs Verification" sections acknowledges NotebookLM's hallucination risk with audio/video sources.

### [F9]
- **[Severity]:** MINOR
- **[Finding]:** Missing validation for `canonical_url` field format
- **[Why]:** Inconsistent URL formats (with/without protocol, trailing slashes) could break future indexing or deduplication that uses URL matching.
- **[Fix]:** Add normalization rule in inbox-processor: ensure URLs start with `http(s)://`, strip trailing slashes, and use lowercase for domain portion.

### [F10]
- **[Severity]:** SIGNIFICANT
- **[Finding]:** No versioning strategy for `knowledge-note` schema itself
- **[Why]:** The schema (frontmatter structure, field semantics) will likely evolve. Without versioning, older notes become incompatible with new processing logic. The spec versions templates but not the document schema.
- **[Fix]:** Add `schema_version: 1` field to frontmatter. Inbox-processor should handle migration paths or at least warn when processing notes with older schema versions.

### [F11]
- **[Severity]:** STRENGTH
- **[Finding]:** Cross-domain discovery via mandatory `#kb/` tags is elegant and practical
- **[Why]:** Avoiding `domains: [list]` simplifies processing while still enabling full cross-domain searchability through the existing tag graph.

### [F12]
- **[Severity]:** MINOR
- **[Finding]:** Task dependency chain has potential blocking point
- **[Why]:** NLM-004 depends on NLM-003 Phase 1 golden fixtures. If Chrome extensions are completely broken during testing, NLM-003 could stall, blocking the entire pipeline.
- **[Fix]:** Make NLM-003 Phase 1 failure non-blocking: If extensions fail, immediately validate manual copy-paste path with sentinel markers and proceed with those fixtures.

---

## Synthesis

### Consensus Findings

Cross-referencing with rounds 1-2 findings:

- **Chrome extension fragility** (DS-F1) — echoes round 1 findings. All reviewers have flagged this as the biggest risk. The spec acknowledges it but the contingency (copy-paste fallback) needs explicit documentation.
- **Template promotion symlinks** (DS-F6) — aligns with round 1 ChatGPT feedback and the vault-wide symlink prohibition established in vault-restructure peer review (A4). Must use reference notes or direct move, not symlinks.

### Unique Findings

- **DS-F2 (source_id collision):** Genuine insight. The simple slug scheme is fine for a personal vault with moderate volume, but the collision scenario is real for authors with common surnames. Worth a lightweight fix.
- **DS-F5 (domain summary backlinks):** Good observation about the forward-linking gap. This is a v2 concern — the MOC system (already planned) will handle this naturally. Not blocking for v1.
- **DS-F10 (schema versioning):** Valid for long-term evolution. Lightweight `schema_version: 1` field is cheap insurance.
- **DS-F3 (scope for non-linear media):** Useful refinement. `topic:<name>` scope is a clean addition.
- **DS-F7 (query limit batching):** Practical workflow concern. Better addressed in the workflow guide (NLM-006) than in the spec.

### Contradictions

None — single reviewer, no cross-reviewer contradictions.

### Action Items

| ID | Classification | Source | Action |
|---|---|---|---|
| A1 | Should-fix | DS-F2 | Add collision detection to `source_id`: when a slug already exists, check `canonical_url`/`title` match. If different source, append year or short hash for disambiguation. |
| A2 | Should-fix | DS-F10 | Add `schema_version: 1` to knowledge-note frontmatter schema. |
| A3 | Should-fix | DS-F3 | Add `topic:<name>` as valid scope value for podcast/video sources. |
| A4 | Must-fix | DS-F6 | Replace symlink approach in NLM-007 with direct move (no project copies). Aligns with vault-wide symlink prohibition. |
| A5 | Defer | DS-F5 | Domain summary backlinks — address when MOC system is built, not in v1. |
| A6 | Defer | DS-F7 | Batch strategy guidance — add to workflow guide (NLM-006), not spec. |
| A7 | Defer | DS-F9 | URL normalization — add during NLM-004 implementation, minor detail. |

### Considered and Declined

- **DS-F1 (DevTools/bookmarklet contingency):** `incorrect` — the copy-paste fallback already exists and scales adequately for personal use. Building a custom bookmarklet adds maintenance burden for a hypothetical failure. The spec's approach (validate copy-paste path in NLM-003) is sufficient.
- **DS-F12 (make extension failure non-blocking):** `constraint` — NLM-003 already specifies "If extensions are broken/unavailable, validate the manual copy-paste fallback path with the same fixture diversity." This is already addressed.
