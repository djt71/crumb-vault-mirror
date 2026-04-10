---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/notebooklm-pipeline/design/specification.md
artifact_type: spec
artifact_hash: 3393a4ee
prompt_hash: f313d6f5
base_ref: null
project: notebooklm-pipeline
domain: learning
skill_origin: peer-review
created: 2026-02-18
updated: 2026-02-18
reviewers:
  - openai/gpt-5.2
  - google/gemini-3-pro-preview
  - perplexity/sonar-reasoning-pro
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192 (openai, google), 65536 (perplexity)
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 42020
    attempts: 1
    raw_json: _system/reviews/raw/2026-02-18-specification-openai.json
  google:
    http_status: 200
    latency_ms: 66401
    attempts: 2
    raw_json: _system/reviews/raw/2026-02-18-specification-google.json
  perplexity:
    http_status: 200
    latency_ms: 30140
    attempts: 1
    raw_json: _system/reviews/raw/2026-02-18-specification-perplexity.json
tags:
  - review
  - peer-review
---

# Peer Review: NotebookLM-to-Crumb Knowledge Pipeline Specification

**Artifact:** Projects/notebooklm-pipeline/design/specification.md
**Mode:** full
**Reviewed:** 2026-02-18
**Reviewers:** OpenAI GPT-5.2, Google Gemini 3 Pro Preview, Perplexity Sonar Reasoning Pro
**Review prompt:** Structured review of specification — context on Crumb vault system, frontmatter conventions, inbox-processor, and #kb/ tag hierarchy provided. Perplexity received additional prompt addendum for dependency verification.

---

## OpenAI (GPT-5.2)

- [F1]
  - [Severity]: CRITICAL
  - [Finding]: The pipeline's core dependency (Chrome extension export) is not treated as a first-class, failure-prone interface contract. Output shape, stability, and metadata fidelity are "unknowns," yet the downstream design assumes consistent, template-aware markdown that can be parsed reliably.
  - [Why]: If export formats shift (extension update, NotebookLM UI change, user settings), the inbox-processor will misclassify, misroute, or silently produce malformed knowledge-notes—poisoning the vault graph at scale for a heavy user.
  - [Fix]: Define an explicit "NLM Export Interface Spec" with versioning: (a) supported exporters + versions, (b) canonical export format(s) you will accept (e.g., "MD v1"), (c) golden sample fixtures committed to the repo, (d) parser contract tests that must pass in CI (or vault-check). Include a fallback "raw import" mode when parsing confidence is low.

- [F2]
  - [Severity]: CRITICAL
  - [Finding]: Source identity and deduplication strategy is missing (no stable IDs, no canonical source record). The schema embeds source metadata inside each knowledge-note, but doesn't prevent duplicates across multiple exports/templates for the same notebook/source.
  - [Why]: Heavy usage will produce multiple digests/extracts per same book/article; without stable IDs you'll get fragmented connections, repeated notes, and unreliable search/MOC generation.
  - [Fix]: Introduce a separate `source` entity type (or a "source index note") with a stable key, e.g. `source_id` (hash of ISBN/URL/title+author+year), and have `knowledge-note` reference it: `source_id`, `source_ref: [[Sources/_index/<id>]]`. Inbox-processor should: (a) look up existing source, (b) link or create it, (c) enforce one canonical title/author/year.

- [F3]
  - [Severity]: SIGNIFICANT
  - [Finding]: The proposed `domain` field as "primary domain" conflicts with the spec's own expectation of cross-domain notes and reliance on `#kb/` tags; this will create inconsistent routing/search semantics.
  - [Why]: In a graph system, inconsistent classification fields degrade retrieval and automation. A single `domain` becomes a misleading constraint once most high-value knowledge is cross-domain.
  - [Fix]: Either (a) change to `domains: []` and define rules for when to include multiple, or (b) make `domain` optional and formally declare `#kb/` tags as the primary classifier.

- [F4]
  - [Severity]: SIGNIFICANT
  - [Finding]: "NLM export characteristics" detection heuristics are unspecified; false positives could cause unrelated markdown to be re-written/routed.
  - [Why]: Inbox processors that mutate files must be conservative; mis-detection is high-impact because it changes metadata, filename, and location.
  - [Fix]: Require a positive marker. Options: (1) user-inserted sentinel line in the template output like `<!-- crumb:nlm-export v1 template:book-digest -->`; (2) exporter-specific header detection; (3) inbox prompt. Prefer (1) because it's deterministic.

- [F5]
  - [Severity]: SIGNIFICANT
  - [Finding]: Frontmatter fields mix "process metadata" and "knowledge metadata" without clear lifecycle rules.
  - [Why]: Over time, process fields drift, become stale, or are inconsistently maintained, which breaks automation and makes notes noisy.
  - [Fix]: Define two blocks: `provenance:` (how this note was produced) and `source:` (what it's about). Define which fields are immutable vs editable.

- [F6]
  - [Severity]: SIGNIFICANT
  - [Finding]: No explicit handling of multi-note outputs (e.g., one export containing multiple sections, tables, or per-chapter summaries) and no "chunking" rules.
  - [Why]: Large sources (books/courses) often exceed a single note's usability. Without chunking, you get unwieldy notes; with ad-hoc chunking, you get inconsistent structure.
  - [Fix]: Add a rule: "one knowledge-note per (source_id, note_type, scope)." Introduce `scope: whole | chapter:<n/name> | timestamp-range | section:<id>`.

- [F7]
  - [Severity]: SIGNIFICANT
  - [Finding]: The spec assumes NotebookLM outputs "don't need heavy post-processing," but it doesn't specify minimum quality gates (factuality, quote fidelity, hallucination risk), especially for podcasts/videos.
  - [Why]: Ingesting synthesized content without quality gates can introduce false claims into a "trusted" second brain.
  - [Fix]: Add an optional "Verification" section and a lightweight gate: flag notes with `needs_review: true` unless they include citations/quotes/timecodes.

- [F8]
  - [Severity]: MINOR
  - [Finding]: Sources/ directory design is good, but subfolder taxonomy is incomplete/inconsistent with schema values (`source_type` includes `other`, folder list adds `papers/` but schema says `paper`).
  - [Fix]: Normalize enumerations: define canonical source_type values and exact folder mapping.

- [F9]
  - [Severity]: SIGNIFICANT
  - [Finding]: Data Tables path mentioned but not integrated into the pipeline design.
  - [Fix]: Make `note_type: data-table` concrete: define accepted formats, companion file strategy, and table_schema metadata.

- [F10]
  - [Severity]: SIGNIFICANT
  - [Finding]: Template library is planned, but there's no versioning or backward compatibility strategy.
  - [Fix]: Add template IDs and semantic versions embedded in output and frontmatter: `query_template: book-digest@1.2`.

- [F11]
  - [Severity]: MINOR
  - [Finding]: Filename rules don't specify collision handling, long titles, or author disambiguation.
  - [Fix]: Define a deterministic filename pattern with truncation rules and collision suffix.

- [F12]
  - [Severity]: SIGNIFICANT
  - [Finding]: "Suggests Obsidian links to related existing notes" is underspecified.
  - [Fix]: Specify a conservative approach: generate suggestions but require confirmation; rank via tag overlap.

- [F13]
  - [Severity]: MINOR
  - [Finding]: Security/privacy implications of Chrome extensions not addressed.
  - [Fix]: Add a "tooling security checklist."

- [F14]
  - [Severity]: STRENGTH
  - [Finding]: Correctly identifies "query templates" as the highest-leverage component and aligns template section headers with vault schema.

- [F15]
  - [Severity]: STRENGTH
  - [Finding]: Extending the existing inbox-processor rather than creating a parallel pipeline is a sound integration choice.

- [F16]
  - [Severity]: SIGNIFICANT
  - [Finding]: Acceptance criteria for tasks are mostly "exists/updated," not behaviorally testable.
  - [Fix]: Add measurable criteria with fixture-based testing.

- [F17]
  - [Severity]: MINOR
  - [Finding]: The design doesn't mention attachments (cover images, PDFs, audio files, transcripts) alongside knowledge-notes.
  - [Fix]: Add `source_uri` / `local_artifact:` fields.

---

## Google Gemini (gemini-3-pro-preview)

- [F1]
  - [Severity]: SIGNIFICANT
  - [Finding]: Missing strategy for "Source Asset" management (original PDFs, EPUBs, MP3s). The pipeline focuses on derived knowledge but ignores the source artifact.
  - [Why]: If the user uploads a PDF to NLM, where does that PDF live in Crumb? Risk of "link rot" if NLM deletes the file or subscription ends.
  - [Fix]: Add to D2 and NLM-004: If a local source file exists, move to `Sources/_assets/` and include `local_source: [[filename.pdf]]` in frontmatter.

- [F2]
  - [Severity]: SIGNIFICANT
  - [Finding]: Ambiguity regarding Chrome Extension selection creates parser risk. D4 relies on parsing markdown exports but lists multiple extensions with likely different output structures.
  - [Fix]: Explicitly select one supported extension as the standard for this pipeline.

- [F3]
  - [Severity]: MINOR
  - [Finding]: Vague detection heuristics for the inbox-processor.
  - [Fix]: Include a standardized "Magic String" or invisible comment in template output (e.g., `<!-- generator: crumb-nlm-pipeline -->`) for deterministic detection.

- [F4]
  - [Severity]: SIGNIFICANT
  - [Finding]: Lack of strategy for "Atomic" vs. "Monolithic" exports. A user may export a chat history containing multiple different queries.
  - [Fix]: Clarify in D4: enforce "One Query = One Note" to match the note_type taxonomy.

- [F5]
  - [Severity]: STRENGTH
  - [Finding]: Decision D1 (Sources/ directory) correctly decouples reference material from active domains.

- [F6]
  - [Severity]: MINOR
  - [Finding]: `query_template` metadata field lacks versioning.
  - [Fix]: Treat as versioned string (e.g., `book-digest-v1`).

---

## Perplexity (sonar-reasoning-pro)

- [F1]
  - [Severity]: STRENGTH
  - [Finding]: Specification correctly states NotebookLM has no official content extraction API. Verified against documentation.

- [F2]
  - [Severity]: STRENGTH
  - [Finding]: NotebookLM feature references (Data Tables, source types) verified as accurate.

- [F3]
  - [Severity]: SIGNIFICANT
  - [Finding]: NLM free tier supports only 50 daily chat queries. The spec assumes "heavy usage" but doesn't quantify load against these limits.
  - [Fix]: Add rate-limit modeling as an assumption to validate.

- [F4]
  - [Severity]: CRITICAL
  - [Finding]: Chrome extension "NotebookLM Ultra Exporter" cannot be verified from current sources.
  - [Fix]: Verify extension availability and test with real export before building parser.

- [F5]
  - [Severity]: CRITICAL
  - [Finding]: Chrome extension "NotebookLM to LaTeX & MD" cannot be verified from current sources.
  - [Fix]: Same as F4. Consider alternative workflows: copy-paste, Data Tables → Sheets, etc.

- [F6]
  - [Severity]: SIGNIFICANT
  - [Finding]: Extension compatibility with consumer-tier NLM is undocumented. Extensions may rely on undocumented UI scraping.
  - [Fix]: Test extension behavior and document fallback workflows.

- [F7]
  - [Severity]: STRENGTH
  - [Finding]: System Map explicitly identifies constraints and dependencies clearly.

- [F8]
  - [Severity]: STRENGTH
  - [Finding]: Query templates correctly identified as highest-leverage intervention point.

- [F9]
  - [Severity]: MINOR
  - [Finding]: Cross-domain knowledge notes may conflict with single-domain frontmatter convention.
  - [Fix]: Explicitly document whether `domain:` is "primary" or "narrowest," confirm #kb/ tags mandatory for cross-domain.

- [F10]
  - [Severity]: MINOR
  - [Finding]: Sources/ directory may become unwieldy with heavy usage.
  - [Fix]: Document future migration path in NLM-006.

- [F11]
  - [Severity]: MINOR
  - [Finding]: Inbox-processor extension vs separate skill composition question.
  - [Fix]: Document rationale; extract to separate skill if NLM logic exceeds ~200 lines.

- [F12]
  - [Severity]: SIGNIFICANT
  - [Finding]: Circular dependency in task decomposition — NLM-004 requires template outputs validated in NLM-003/005, but dependencies flow wrong.
  - [Fix]: Reorder: NLM-003 should include "test templates and document output structure" before NLM-004 begins.

---

## Synthesis

### Consensus Findings

**1. Chrome extension brittleness / verification needed** (OAI-F1, GEM-F2, PPLX-F4, PPLX-F5, PPLX-F6)
All three reviewers flagged the pipeline's dependency on unverified, third-party Chrome extensions as the primary risk. OpenAI wants an explicit interface contract with golden fixtures. Gemini wants one canonical extension selected. Perplexity couldn't even verify the extensions exist and wants fallback workflows.

**2. Detection heuristics need a deterministic marker** (OAI-F4, GEM-F3)
Both OpenAI and Gemini independently proposed the same solution: embed a sentinel comment in query template output (e.g., `<!-- crumb:nlm-export v1 template:book-digest -->`) so the inbox-processor has a reliable signal rather than guessing.

**3. Template versioning** (OAI-F10, GEM-F6)
Both flagged that templates will evolve and old exports need to remain parseable. Version strings in template IDs and output markers.

**4. Source asset management / original files** (OAI-F17, GEM-F1)
Where do the original PDFs, EPUBs, audio files live? The spec covers derived knowledge but not the source artifacts. Both suggest linking knowledge-notes back to locally stored originals.

**5. Multi-note / chunking strategy** (OAI-F6, GEM-F4)
What happens when a single NLM export contains multiple queries, or a book needs chapter-by-chapter extracts? Both want explicit rules: one query = one note, with a scope mechanism for sub-source granularity.

**6. Cross-domain frontmatter tension** (OAI-F3, PPLX-F9)
Single `domain:` field vs. cross-domain reality. Both suggest either making it optional, allowing a list, or formally declaring #kb/ tags as the primary cross-domain mechanism.

**7. Task dependency ordering** (OAI-F16, PPLX-F12)
The task decomposition has NLM-004 depending on NLM-003, but NLM-003's acceptance criteria (template output structure) are actually needed to *design* the parser in NLM-004. Need to ensure NLM-003 includes sample output documentation before NLM-004 begins.

### Unique Findings

**OAI-F2: Source deduplication / stable IDs** — Genuine insight. Heavy usage will produce multiple notes per source (a digest, then extracts, then a data table from the same book). Without a stable source identifier, these won't be reliably linked. Worth addressing.

**OAI-F7: Quality gates for ingested content** — Genuine insight. NLM-synthesized content can hallucinate, especially from podcasts/videos. A `needs_review` tag for notes lacking citations is a low-friction guard.

**PPLX-F3: NLM daily query rate limits** — Practical concern. 50 daily chat queries on AI Pro could constrain heavy template usage. Worth noting as a constraint, though unlikely to be blocking for a "run a couple templates per session" workflow.

**OAI-F5: Provenance vs source metadata separation** — Reasonable conceptually but may be over-engineering for v1. The current `source:` block is clean enough.

**OAI-F9: Data Tables path not designed** — Valid. The spec mentions it as a possibility but doesn't design for it. Worth deferring to v2 rather than blocking v1.

### Contradictions

None significant. All three reviewers are aligned on the major risks (extension dependency, detection heuristics, template versioning). Minor disagreements on severity levels but not on substance.

### Action Items

**Must-fix (blocking for PLAN phase):**

- **A1** — Add Chrome extension verification step to NLM-003 (before parser design). Test actual exports from real NLM notebooks. Commit golden sample fixtures to the repo. Define a fallback path (copy-paste) if extensions break. (Source: OAI-F1, GEM-F2, PPLX-F4, PPLX-F5)

- **A2** — Add sentinel marker to query template design. Templates must embed `<!-- crumb:nlm-export v1 template:{name} -->` in their output so the inbox-processor has a deterministic detection signal. (Source: OAI-F4, GEM-F3)

- **A3** — Add source deduplication strategy. At minimum: define a `source_id` convention (e.g., slug from title+author) and have knowledge-notes that reference the same source link to each other. Full source-index-note can be v2 if needed. (Source: OAI-F2)

- **A4** — Fix task dependency ordering. NLM-003 must include "export sample outputs from NLM, document exact markdown structure" as a deliverable. NLM-004's parser work is blocked until those samples exist. (Source: OAI-F16, PPLX-F12)

**Should-fix (before implementation):**

- **A5** — Add chunking/scope rule: one query = one note. For multi-chapter or multi-section needs, user runs template per scope unit and exports individually. Add `scope` field to schema if needed. (Source: OAI-F6, GEM-F4)

- **A6** — Add template versioning. Template names include version: `book-digest-v1`. Sentinel marker includes version. Parser maintains compatibility with known versions. (Source: OAI-F10, GEM-F6)

- **A7** — Clarify cross-domain handling. Document that `domain:` is the primary domain, #kb/ tags are mandatory for cross-domain discovery. Defer `domains: [list]` unless vault-check changes are warranted. (Source: OAI-F3, PPLX-F9)

- **A8** — Add `needs_review` tag convention for notes from low-citation sources (podcasts, videos). Templates for these source types should include a "Claims without evidence" section. (Source: OAI-F7)

- **A9** — Strengthen acceptance criteria for NLM-004 and NLM-005 with fixture-based testing: "Given exports A/B/C, parser produces valid frontmatter, correct routing, vault-check passes." (Source: OAI-F16)

**Defer (v2 or later):**

- **A10** — Source asset management (storing original PDFs/EPUBs alongside knowledge-notes). Useful but not essential for v1 — the inbox-processor already handles binary intake. Can compose later. (Source: OAI-F17, GEM-F1)

- **A11** — Data Tables pipeline path (Sheets → CSV → markdown). Mentioned in spec but can remain a v2 feature. (Source: OAI-F9)

- **A12** — Source index notes (full bibliographic entity separate from knowledge-notes). Useful at scale but not needed until Sources/ has significant volume. (Source: OAI-F2, deferred portion)

- **A13** — Filename collision handling and long-title truncation rules. Good hygiene but unlikely to bite in early usage. (Source: OAI-F11)

- **A14** — NLM rate limit modeling. Note the 50-query daily limit as a known constraint. Unlikely to be blocking for typical workflow. (Source: PPLX-F3)

### Considered and Declined

- **OAI-F5** (provenance/source metadata separation): `constraint` — The current `source:` block is consistent with Crumb's existing frontmatter patterns (e.g., `attachment:` block in companion notes). Adding a separate `provenance:` block diverges from established convention for marginal benefit at this stage.

- **OAI-F13** (Chrome extension security checklist): `overkill` — Both extensions claim local-only processing. A formal security checklist adds overhead without proportional benefit for a personal vault.

- **OAI-F12** (connection suggestion ranking algorithm): `out-of-scope` — The spec is at SPECIFY phase. Connection suggestion implementation details belong in PLAN/IMPLEMENT, not in the problem specification.

- **PPLX-F10** (Sources/ scalability / dated subdirs): `overkill` — Flat directories work well into the hundreds of files in Obsidian. Premature to design a partitioning scheme before the directory exists.

- **PPLX-F11** (separate skill extraction threshold): `out-of-scope` — Implementation-level decision. If NLM logic grows large during IMPLEMENT, extract then. Not a spec concern.
