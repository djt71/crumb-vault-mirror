---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/documentation-overhaul/design/specification.md
artifact_type: spec
artifact_hash: 463101d1
prompt_hash: 04a5f245
base_ref: null
project: documentation-overhaul
domain: software
skill_origin: peer-review
created: 2026-03-14
updated: 2026-03-14
reviewers:
  - openai/gpt-5.4
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
    latency_ms: 59018
    attempts: 1
    raw_json: Projects/documentation-overhaul/reviews/raw/2026-03-14-specification-openai.json
  google:
    http_status: 200
    latency_ms: 38867
    attempts: 1
    raw_json: Projects/documentation-overhaul/reviews/raw/2026-03-14-specification-google.json
  deepseek:
    http_status: 200
    latency_ms: 97802
    attempts: 1
    raw_json: Projects/documentation-overhaul/reviews/raw/2026-03-14-specification-deepseek.json
  grok:
    http_status: 200
    latency_ms: 30684
    attempts: 1
    raw_json: Projects/documentation-overhaul/reviews/raw/2026-03-14-specification-grok.json
status: active
tags:
  - review
  - peer-review
---

# Peer Review: Documentation Overhaul Specification

**Artifact:** Projects/documentation-overhaul/design/specification.md
**Mode:** full
**Reviewed:** 2026-03-14
**Reviewers:** OpenAI GPT-5.4, Google Gemini 3 Pro Preview, DeepSeek Reasoner (V3.2), Grok 4.1 Fast Reasoning
**Review prompt:** Full specification review evaluating correctness, completeness, internal consistency, feasibility, and clarity. Findings classified by severity (CRITICAL/SIGNIFICANT/MINOR/STRENGTH). Unverifiable claims flagged.

---

## OpenAI (gpt-5.4)

- [F1]
- [Severity]: STRENGTH
- [Finding]: The three-track architecture is well-defined, with clear audience separation and a sensible authority model: design spec → architecture docs → version history, while operator and LLM docs derive from but do not overwrite architecture truth.
- [Why]: This is the core structural decision in the overhaul, and it resolves a common failure mode in documentation systems: duplicated content with unclear ownership. The distinction between “intent,” “current state,” and “task-oriented/operator-facing” docs is strong and maintainable.
- [Fix]: None.

- [F2]
- [Severity]: STRENGTH
- [Finding]: The spec is internally coherent about framework usage: Arc42 is intentionally cherry-picked for architecture, Diátaxis is strictly applied for operator docs, and the LLM layer is explicitly treated as a governed exception rather than forced into a framework mismatch.
- [Why]: This avoids overfitting one framework to all needs and keeps each track optimized for its audience and use case.
- [Fix]: None.

- [F3]
- [Severity]: STRENGTH
- [Finding]: The implementation phasing is practical and dependency-aware. Producing architecture first, then operator docs, then the orientation map is a sound order.
- [Why]: The phases align with source-of-truth dependencies and reduce rework. Operator docs built before architecture would likely drift or duplicate source material.
- [Fix]: None.

- [F4]
- [Severity]: STRENGTH
- [Finding]: The consolidation plan is unusually concrete and operationally useful, especially the absorb-and-redirect pattern and table mapping old docs to absorbing destinations.
- [Why]: Many documentation reorganizations fail because they ignore migration mechanics. This plan addresses overlap, redirects, and archive handling explicitly.
- [Fix]: None.

- [F5]
- [Severity]: STRENGTH
- [Finding]: The spec shows strong awareness of the actual operating environment, especially the NotebookLM consumption model and the need for docs to remain self-contained outside Obsidian rendering assumptions.
- [Why]: This grounds the overhaul in real usage rather than idealized vault-only reading behavior, which should improve actual adoption and re-ramping value.
- [Fix]: None.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: There is a direct inconsistency in the stated authoritativeness model. The “Three-Document Hierarchy” says “authoritativeness flows downward” from design spec to architecture docs to version history, but the version history is also described as “not a source of authority.”
- [Why]: This creates conceptual confusion. A changelog cannot simultaneously sit in an authority chain and also be non-authoritative. That ambiguity matters because maintenance rules and AI drafting instructions depend on source precedence.
- [Fix]: Rephrase the hierarchy to distinguish authority from evidentiary input. For example: “Authority flows from design spec to architecture docs; version history is a historical input and audit trail, not an authority layer.”

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: The relationship between architecture docs as “authoritative source of truth” and the design spec as “highest-authority document” is not fully resolved.
- [Why]: The spec uses “authoritative” in two senses: architecture is the authoritative current-state source, while the design spec is the authoritative intent source. Without explicitly naming these as different authority domains, readers may not know which document wins in edge cases where implementation diverges from intent.
- [Fix]: Add a short “authority domains” subsection clarifying: design spec = authority for intent and principles; architecture docs = authority for current implementation state; version history = authority only for chronology of recorded changes.

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: The maintenance trigger “Design principle added/changed → Update cross-cutting concepts” conflicts with the earlier distinction that design principles belong to the design spec, while cross-cutting concepts should document observed current practice rather than restated principles.
- [Why]: This reintroduces duplication between intent and practice and weakens the careful boundary the spec established for Section 05.
- [Fix]: Change the trigger to something like: “If a design principle change alters actual enforced conventions or operating patterns, update 05-cross-cutting-concepts; otherwise update only the design spec.”

- [F9]
- [Severity]: SIGNIFICANT
- [Finding]: The minimum operator doc set and the consolidation plan conflict on document handling. Several “keep as-is” docs are to be reclassified into operator directories, but they are not reflected in the “minimum operator doc set” tables or clearly marked as satisfying that set.
- [Why]: This leaves uncertainty about whether those moved docs count as completed deliverables or require rewriting to conform to Diátaxis and quality standards.
- [Fix]: Add a reconciliation table: for each reclassified existing doc, state whether it (a) fully satisfies a target operator doc, (b) requires normalization only, or (c) requires substantive rewriting before acceptance.

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: “Every document in `operator/` belongs to exactly one Diátaxis quadrant” may be hard to sustain for reclassified legacy docs that likely mix procedure, explanation, and reference content.
- [Why]: Strict enforcement is good in principle, but without a normalization rule, legacy docs moved “as-is” may violate the stated model immediately.
- [Fix]: Add a migration rule: any moved legacy doc must be reviewed against a Diátaxis checklist and either trimmed/split to one quadrant or explicitly marked as transitional until normalized.

- [F11]
- [Severity]: SIGNIFICANT
- [Finding]: The quality standard “Every document must have YAML frontmatter with tags” appears to conflict with the note that some LLM orientation docs stay in their current locations and formats, and the overhaul does not change them.
- [Why]: It is unclear whether “every document” means every new doc produced by this overhaul, or literally all docs referenced in the system including CLAUDE.md/SOUL.md/IDENTITY.md, which may not use vault-style frontmatter.
- [Fix]: Narrow the requirement to “Every new vault documentation artifact created under `_system/docs/` must have YAML frontmatter with tags.”

- [F12]
- [Severity]: SIGNIFICANT
- [Finding]: The staleness detection model based on comparing architecture section modified dates to linked operator/LLM docs is too weak as specified and may generate both false positives and false negatives.
- [Why]: A newer architecture doc does not necessarily mean dependent docs are stale if changes were editorial only; likewise, older timestamps do not prove freshness if relevant sections changed elsewhere. This matters because staleness detection is presented as a governance mechanism.
- [Fix]: Define staleness as a heuristic, not a rule, and add a lightweight change annotation mechanism such as “impact tags” or “docs affected” metadata in architecture updates to indicate whether operator/LLM review is required.

- [F13]
- [Severity]: SIGNIFICANT
- [Finding]: The spec assumes AI can reliably draft authoritative current-state docs by synthesizing design spec, version history, run-logs, source code, and vault notes, but it does not define a conflict-resolution method when those sources disagree.
- [Why]: In a living system, these sources will drift. Without a conflict policy, the AI may produce plausible but wrong synthesis, especially since final human review is pass/fail and not line-by-line.
- [Fix]: Add a source precedence rule for factual conflicts, e.g. runtime/source code > current infrastructure config > architecture notes > version history > design spec for implementation facts, with unresolved conflicts called out in an “Open verification points” section.

- [F14]
- [Severity]: SIGNIFICANT
- [Finding]: The spec says operator docs are only written for stable interfaces, but the minimum operator doc set includes several topics that are explicitly described elsewhere as “active development” areas.
- [Why]: This creates a gating ambiguity: should those docs be written now, stubbed, or deferred? Without criteria, implementation may stall or produce churn-heavy docs.
- [Fix]: For each item in the minimum set, add an initial status column: stable / transitional / deferred. For transitional items, specify whether to produce a stub, a limited-scope reference, or a full doc.

- [F15]
- [Severity]: SIGNIFICANT
- [Finding]: The orientation map scope is inconsistent. The plan says it lists “every LLM-consumed doc,” but the automation candidate only scans a subset of likely locations and assumes overlays live under `_system/docs/overlays/`, while earlier text says overlays stay in their current locations.
- [Why]: If the scan paths do not reflect actual storage locations, the map will be incomplete and governance will fail silently.
- [Fix]: Replace hard-coded example paths with a canonical discovery specification: define exact include paths, exclude paths, and naming conventions for each LLM artifact type, or state that Phase 3 must first inventory actual locations before proposing automation.

- [F16]
- [Severity]: SIGNIFICANT
- [Finding]: The source-material lists sometimes blend authoritative sources with highly contextual or ephemeral sources such as session transcripts and userMemories context without stating their trust level.
- [Why]: This can lead to unstable architecture docs if transient context is treated like a source of record.
- [Fix]: Label source classes explicitly: authoritative, corroborating, anecdotal. Restrict architecture docs to authoritative + corroborated facts, with ephemeral sources used only to infer workflow patterns that are then verified.

- [F17]
- [Severity]: MINOR
- [Finding]: The “00-architecture-overview.md” file is called the “master entry point,” but its expected contents are never defined with the same precision as the other five sections.
- [Why]: This may lead to an inconsistent overview file that becomes either redundant boilerplate or an unsustainably detailed summary.
- [Fix]: Add a brief section definition for `00-architecture-overview.md`: purpose, expected contents, and what it should not duplicate.

- [F18]
- [Severity]: MINOR
- [Finding]: The exclusion rationale for some Arc42 sections is somewhat overstated. For example, “Glossary” is said to be served by tag taxonomy and MOC system, which is not equivalent to a glossary.
- [Why]: The decision may still be valid, but the rationale is weaker than stated and could confuse future maintainers.
- [Fix]: Soften the rationale: “A formal glossary is deferred because current scale does not justify it; terminology is partially covered by tag taxonomy and MOCs.”

- [F19]
- [Severity]: MINOR
- [Finding]: “Another competent dev could rebuild this” and “Someone could run this system without the builder” are excellent framing statements, but acceptance criteria are not tied back to them.
- [Why]: Success is described aspirationally but not operationally, making it harder to judge when the overhaul is “done enough.”
- [Fix]: Add completion criteria per track, e.g. architecture complete when an external dev can identify all subsystems, dependencies, runtime flows, and deployment components without consulting scattered legacy notes.

- [F20]
- [Severity]: MINOR
- [Finding]: The plan uses several specialized terms—AKM, QMD, FIF, MOC, HITL, OpenClaw—without ensuring first-use expansion inside the new docs architecture itself.
- [Why]: This is manageable for insiders but slightly undermines the stated goal that another competent developer or operator could rebuild/run the system.
- [Fix]: Require first-use expansion or a lightweight terminology appendix in `00-architecture-overview.md` or `01-context-and-scope.md`.

- [F21]
- [Severity]: MINOR
- [Finding]: The requirement “AI generates Mermaid diagrams inline” is paired with “must render correctly in Obsidian,” but NotebookLM is also a primary consumption path and may not preserve Mermaid rendering.
- [Why]: A diagram that is readable only in Obsidian reduces value in the declared primary consumption environment.
- [Fix]: Require a short prose summary immediately below each diagram so the document remains usable even when Mermaid is not rendered.

- [F22]
- [Severity]: MINOR
- [Finding]: The estimated effort section is plausible but optimistic given the amount of source synthesis, conflict checking, and migration work implied by the consolidation plan.
- [Why]: Underestimation can affect execution confidence and sequencing decisions.
- [Fix]: Note that estimates exclude source reconciliation and legacy-doc normalization, or add a contingency band for verification and reclassification work.

- [F23]
- [Severity]: MINOR
- [Finding]: The “owner metadata field” is dropped as ceremony debt, but no alternative metadata is suggested for review cadence or maintenance responsibility within the docs themselves.
- [Why]: Single-owner systems do not need organizational ownership metadata, but a lightweight “last reviewed for accuracy” field could still help maintenance.
- [Fix]: Consider optional `reviewed:` or `verified_against:` metadata for architecture and reference docs.

- [F24]
- [Severity]: MINOR
- [Finding]: The consolidation row for `tess-crumb-comparison.md` says it will be absorbed into `02-building-blocks.md` for “actor definitions,” but actor definitions were earlier specified under `01-context-and-scope.md`.
- [Why]: This is a small but concrete mapping inconsistency.
- [Fix]: Either move actor/persona boundary content to `01-context-and-scope.md` consistently, or revise the section definitions to explain why some actor-role material belongs in `02-building-blocks.md`.

- [F25]
- [Severity]: MINOR
- [Finding]: The phrase “single-operator personal OS built on Claude Code” in the context summary is not repeated or grounded inside the spec body’s system purpose sections.
- [Why]: This high-level framing seems central and should probably anchor the architecture context more explicitly.
- [Fix]: Ensure `01-context-and-scope.md` includes this formulation or an equivalent concise system identity statement.

- [F26]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Several concrete infrastructure and environment details are asserted without independently verifiable evidence in the artifact, including “Mac Studio M3 Ultra, 96GB RAM,” “crumbos.dev via Cloudflare Registrar,” “Healthchecks.io dead man's switch,” and the specific process/model split “tess-voice on Haiku, tess-mechanic on Qwen via Ollama.”
- [Why]: These are factual deployment claims that could become incorrect quickly and are presented as current state. Since they cannot be independently confirmed from the artifact alone, they should be grounded before being treated as canonical architecture facts.
- [Fix]: Mark these as requiring source verification from live config, infrastructure notes, or deployment manifests before inclusion in architecture docs.

- [F27]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: The spec references specific source artifacts and conventions as if settled facts—e.g. “CLAUDE.md 200 lines,” “overlays 50 lines,” “SKILL.md nine-section structure,” “four sync points,” “Tier 1 inline Sonnet / Tier 2 cloud panel,” and “PAT-embedded URLs”—but these enforcement details are not independently verifiable from the artifact.
- [Why]: These are exactly the kinds of operational facts that architecture section 05 would need to get right. If they are stale or partially true, the documentation system will encode drift as policy.
- [Fix]: Require direct validation against the cited files/configs before publication, and consider annotating Section 05 drafts with verified source file references or commit hashes.

- [F28]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: The plan states “The 1M context window means the design spec (~2,600 lines) and version history can be loaded together without context pressure.”
- [Why]: This is a model/tool capability claim and an approximate source-size claim that may change over time or vary by environment. It is not necessary to the spec and cannot be confirmed from the artifact.
- [Fix]: Remove the numeric capability assertion or restate more generally: “Current available context capacity is sufficient for loading the principal source docs together in most drafting sessions.”

- [F29]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: The plan states that “a Tess skill handles on-demand sync of vault artifacts to Drive for notebook ingestion” and that “Project manifests are maintained manually in the vault.”
- [Why]: These are implementation-state claims about external sync behavior and operational process that are not independently verifiable here.
- [Fix]: Add “if implemented” qualifiers until validated, or cite the controlling skill/spec as the verification source.

- [F30]
- [Severity]: STRENGTH
- [Finding]: The quality standards are concrete and action-oriented, especially the distinctions by doc type and the insistence on complete, publication-ready AI output.
- [Why]: Given the stated review model of “Danny reviews final artifacts only,” strong templates and quality gates are essential. This section supports that workflow well.
- [Fix]: None.

- [F31]
- [Severity]: STRENGTH
- [Finding]: The spec shows good discipline in scoping what it does not cover, especially ADRs, three-view workflow docs, and retroactive extraction from run-logs.
- [Why]: Clear exclusions reduce scope creep and make the overhaul feel achievable.
- [Fix]: None.

- [F32]
- [Severity]: STRENGTH
- [Finding]: The distinction between self-contained docs for NotebookLM consumption and vault-native conventions like wikilinks/MOCs is thoughtfully handled.
- [Why]: It balances local authoring constraints with external reading constraints, which is often neglected in vault-based documentation systems.
- [Fix]: None.

---

## Google (gemini-3-pro-preview)

Here is a structured review of the Crumb/Tess documentation overhaul specification, evaluated for correctness, completeness, internal consistency, feasibility, and clarity.

- [F1]
- [Severity]: CRITICAL
- [Finding]: Contradiction between Phase 2 drafting instructions and the Consolidation Plan regarding existing operational docs.
- [Why]: Under "Phase 2: Operator Docs," `how-to/vault-gardening.md` is listed in the first batch, and the AI workflow explicitly states "AI drafts the document." However, the Consolidation Plan table states that `vault-gardening.md` and `crumb-deployment-runbook.md` should be kept "as-is" and merely moved/retagged with no content duplication. If the AI executes Phase 2 as written, it will overwrite or redundantly draft a document that was supposed to be preserved. 
- [Fix]: Update the Phase 2 workflow to explicitly skip the "AI drafts" step for documents marked "Keep as-is" in the Consolidation Plan, or remove `vault-gardening.md` from the AI's Phase 2 drafting queue and note it as a manual migration step.

- [F2]
- [Severity]: SIGNIFICANT
- [Finding]: Conflict between NotebookLM consumption constraints and mandated Obsidian-specific rendering/linking.
- [Why]: The "Design constraints" section explicitly states that documents must have "no reliance on Obsidian-specific rendering" because NotebookLM is the primary consumption mechanism. However, the Track 1 section mandates inline Mermaid diagrams (which NotebookLM reads as raw code blocks, not visual diagrams) and the Quality Standards mandate Wikilinks (`[[like this]]`), which break and do not function as hyperlinks when imported into Google Drive/NotebookLM. 
- [Fix]: Clarify the rendering compromise. For example: "Mermaid diagrams are permitted as NotebookLM can parse the text relationships, even if it cannot render the image" and "Use standard Markdown links `[Link Text](file.md)` instead of Obsidian Wikilinks, or accept that Wikilinks will function merely as text-based semantic references in NotebookLM."

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: "Host: Mac Studio M3 Ultra, 96GB RAM"
- [Why]: Apple has not released an M3 Ultra chip (the M-series progressed from M2 Ultra directly to the M4 generation for higher-end desktops, or capped at M3 Max). This hardware specification appears factually incorrect or assumes unreleased hardware.
- [Fix]: Verify the actual host machine hardware (e.g., M2 Ultra, M3 Max, or M4) and update the deployment specs accordingly.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: "The 1M context window means the design spec (~2,600 lines) and version history can be loaded together..."
- [Why]: The specification identifies "Claude Code" as the underlying system. Anthropic's Claude 3 and 3.5 models currently have a standard maximum context window of 200,000 tokens. A 1M context window is typically associated with Google's Gemini 1.5 Pro. Relying on a 1M token budget for Claude sessions may result in severe context truncation errors.
- [Fix]: Confirm the actual context window of the configured LLM. If it is 200k, update the statement to reflect that 200k is still easily sufficient for a ~2,600 line design spec plus history.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: The staleness detection mechanism relies on "last-modified date" without specifying the source of that metadata.
- [Why]: The spec says: "compare the last-modified date of an architecture section against its linked operator...". Relying on file system modification times (`mtime`) is notoriously fragile in Git-backed or Google Drive-synced vaults, as cloning, checking out, or syncing often overwrites the `mtime` with the current timestamp. 
- [Fix]: Explicitly mandate that staleness checks use the `updated: YYYY-MM-DD` YAML frontmatter field rather than the file system `mtime`.

- [F6]
- [Severity]: MINOR
- [Finding]: `crumb-deployment-runbook.md` is omitted from the Phase 2 batch prioritization.
- [Why]: The Consolidation Plan states this file should be reclassified into `operator/how-to/`, but it is not listed anywhere in the First, Second, Third, or Fourth batches of Phase 2.
- [Fix]: Explicitly assign the migration of "Keep as-is" operator docs to a specific batch in Phase 2.

- [F7]
- [Severity]: MINOR
- [Finding]: Lack of a defined trigger for archiving Operator Docs.
- [Why]: The Maintenance Model handles new/updated subsystems well, but doesn't explicitly state what happens to operator docs when a subsystem is completely deprecated. 
- [Fix]: Add a trigger to the Maintenance table: "Subsystem deprecated -> Move linked operator docs to `Archived/KB/` and update orientation map."

- [F8]
- [Severity]: STRENGTH
- [Finding]: The Three-Document Hierarchy (Constitution → Current State → Changelog).
- [Why]: This is an exceptionally robust information architecture pattern. By strictly separating design intent (Why) from structural reality (How/Where) and time-based changes (When), it practically eliminates the risk of an LLM hallucinating "what should be" as "what is."

- [F9]
- [Severity]: STRENGTH
- [Finding]: Strict enforcement of the Diátaxis framework.
- [Why]: Tying specific Diátaxis quadrants directly to structural rules (e.g., "no procedural steps in explanation," "tables only for reference") and defining the AI drafting voices for each ensures that the resulting operator documents will be highly functional and uniform.

- [F10]
- [Severity]: STRENGTH
- [Finding]: The "Absorb-and-Redirect" consolidation strategy.
- [Why]: Retaining old filenames as wikilink stubs that point to the new canonical documents is a brilliant way to respect the "Ceremony Budget" and prevent link rot across the rest of the vault without maintaining duplicate content.

---

## DeepSeek (deepseek-reasoner)

**Structured Review: Crumb/Tess Documentation Overhaul — Implementation Plan**

### **Overall Assessment**
The specification is exceptionally well-structured, internally consistent, and demonstrates a mature understanding of documentation theory (Arc42, Diátaxis) applied to a unique, single-operator, AI-integrated system. The plan is highly feasible, with clear phasing, defined AI roles, and respect for existing constraints. The primary risks are operational (adherence to the strict validation model) and maintenance-related (ensuring the tracking map remains current).

---

### **Findings**

**F1**
- **Severity:** SIGNIFICANT
- **Finding:** UNVERIFIABLE CLAIM: The specification asserts "NotebookLM is the primary consumption mechanism" and that docs will be synced to Google Drive for ingestion. This is a critical design constraint, but its implementation status (e.g., existence and reliability of the "Tess sync skill") is not verifiable from this document.
- **Why:** The entire doc structure is justified by this consumption model. If the sync mechanism is not operational, a core assumption of the plan (self-contained sections, explicit cross-references) may be over-engineered.
- **Fix:** Add a brief note on the current status of the NotebookLM sync capability (e.g., "Active/Planned/Broken") or reference the separate "Project Notebooks project spec" for implementation details.

**F2**
- **Severity:** SIGNIFICANT
- **Finding:** The AI validation model requires "publication-ready" drafts from a single pass, with human review only at the end. This assumes the AI can perfectly synthesize from source materials and adhere to all templates without iterative clarification.
- **Why:** This is a high-risk point of failure. Complex sections (e.g., Runtime Views) may require intermediate validation of diagrams or fact-checking against run-logs. A single "pass/fail" review at the end could lead to wasted AI effort if fundamental misunderstandings exist in the first draft.
- **Fix:** Consider a lighter "checkpoint" model for the most complex documents (03-Runtime Views, 02-Building Blocks), where the AI presents the outline or key decomposed lists for confirmation before drafting full narratives and diagrams.

**F3**
- **Severity:** SIGNIFICANT
- **Finding:** The plan does not address how to document subsystems that are **failed, deprecated, or in a prototype state**. The "stable interface" gate for operator docs hints at this, but the architecture docs aim for a "current-state description."
- **Why:** For a rebuild narrative, understanding what *not* to rebuild (e.g., a deprecated skill, a failed experiment like a previous bridge implementation) is as valuable as knowing what exists. Omitting them creates a misleadingly clean picture.
- **Fix:** In `05-cross-cutting-concepts.md` or `02-building-blocks.md`, add a subsection titled "Historical & Deprecated Elements" that briefly catalogs significant abandoned paths and their artifacts, with links to relevant version history entries.

**F4**
- **Severity:** MINOR
- **Finding:** The `orientation-map.md` is described as enabling "staleness detection" by comparing timestamps. However, the spec also states "AI does not auto-update" LLM docs. The process for *acting* on staleness detection is vague.
- **Why:** This creates a potential gap in the maintenance model. The map identifies stale docs, but the trigger for updating them ("Check the orientation map for stale docs") is a manual Crumb session task, not linked to the update triggers table.
- **Fix:** Add a row to the "When to update" table: "Orientation map staleness check flags a doc" -> "Review flagged doc; update if needed, then update orientation map timestamp."

**F5**
- **Severity:** MINOR
- **Finding:** The "Consolidation Plan" table is comprehensive for named artifacts, but the vault likely contains numerous ad-hoc notes (e.g., `some-thoughts-on-bridge.md`) that also contain architectural knowledge.
- **Why:** Relying solely on the AI to find and absorb relevant content from these during drafting is risky. Key insights might be missed, leading to duplication or an incomplete architecture.
- **Fix:** Augment the AI workflow for Phase 1: Before drafting a section, the AI should run a targeted vault search (via `grep` or semantic query) for untagged/unfiled notes containing relevant keywords and explicitly note which were considered/included.

**F6**
- **Severity:** STRENGTH
- **Finding:** The "Three-Document Hierarchy" (Design Spec, Architecture Docs, Version History) brilliantly clarifies authority and prevents drift. The directive that AI must read *both* the design spec (intent) and version history (evolution) to draft architecture (current state) is a robust methodology.
- **Why:** This formalizes a crucial synthesis step, ensuring the architecture docs are neither aspirational nor a mere changelog, but an accurate representation of the *implemented intent*.

**F7**
- **Severity:** STRENGTH
- **Finding:** The application of the Diátaxis framework is precise and well-justified. The clear mapping of quadrant to directory, voice, structure, and maintenance trigger will force disciplined authoring and make the doc set more navigable.
- **Why:** It eliminates the common pitfall of creating hybrid "how-to/explanation" docs that are harder to use and maintain. The "Stability requirement" gate for operator docs is also a pragmatic guard against documentation churn.

**F8**
- **Severity:** STRENGTH
- **Finding:** The plan explicitly addresses ceremony budget and maintenance cost. Excluding Arc42 sections (Quality Requirements, Technical Risks) and avoiding a formal ADR process initially are sound judgments for a single-operator system.
- **Why:** This focus ensures the documentation structure itself adheres to the system's core design principle. It builds only what is immediately valuable and observable.

**F9**
- **Severity:** SIGNIFICANT
- **Finding:** UNVERIFIABLE CLAIM: References to specific file paths (`~/.openclaw/soul.md`), scripts (`vault-check.sh`), and external service configurations (Healthchecks.io, Cloudflare Tunnel) are factual claims about the system's state that cannot be verified from this spec.
- **Why:** While necessary for the plan's specificity, a reviewer cannot confirm these artifacts exist as described. This is acceptable for an internal plan but should be acknowledged.
- **Fix:** No fix required, as this is an inherent characteristic of reviewing a system specification. The finding serves to highlight these points as requiring validation during the plan's execution.

**F10**
- **Severity:** MINOR
- **Finding:** The estimated effort (9-14 Crumb sessions) may be optimistic for Phase 2 (Operator Docs). Generating high-quality, structured reference tables (e.g., `skills-reference.md`) from scanning the vault and code requires careful, accurate data extraction.
- **Why:** Underestimation could lead to schedule pressure or quality compromise. The phase relies heavily on AI's ability to parse and summarize disparate sources without error.
- **Fix:** Frame the estimate more cautiously: "Phase 2 is the most variable, depending on the AI's proficiency in data extraction and tabulation. Allow for contingency sessions."

**F11**
- **Severity:** CRITICAL
- **Finding:** There is a logical contradiction in the maintenance model. The "Tag taxonomy updates required" note states that new tags (`system/architecture`, etc.) require updates to `file-conventions.md` and `vault-check` **validation rules**. However, the new documentation files **must pass vault-check on commit** during Phase 1.
- **Why:** This creates a chicken-and-egg problem: the first architecture doc cannot be committed because its tags will fail validation until `file-conventions.md` is updated. This will block the very first commit of the overhaul.
- **Fix:** **Reorder the pre-requisite work.** Before drafting any new docs in Phase 1, a single, separate session must be held to: 1. Update `file-conventions.md` with the new canonical Level 2 tags. 2. Update the `vault-check.sh` validation logic to allow these tags. 3. Commit these changes. *Then* begin the phased documentation work.

**F12**
- **Severity:** SIGNIFICANT
- **Finding:** The plan lacks a defined rollback or correction process if an AI-drafted document is found to contain significant factual errors during Danny's "pass/fail" review.
- **Why:** If a 50-line `how-to` fails review, it can be redrafted. If a foundational `architecture` doc (like 02-Building Blocks) fails after significant subsequent work (e.g., operator docs referencing it), the rework cost is high.
- **Fix:** Add a brief "Redline Procedure" to the AI Roles section: "If a document fails review due to factual inaccuracy, the AI will create a 'redline' version highlighting the specific sections in question against the source material. Danny reviews the redline to correct misunderstandings before a full redraft is requested."

---
### **Summary**
The specification is **largely excellent and actionable**. The most critical issue (F11) is a procedural blocker that must be resolved before starting. The most significant risks are operational (F2, F10) and concern the validation model's rigidity and effort estimates. The strengths (F6, F7, F8) are foundational and demonstrate sophisticated systems thinking. The unverifiable claims (F1, F9) are expected for an internal system spec but should be acknowledged.

**Primary Recommendation:** Address the critical tag-validation sequence (F11) first, then proceed with the phased implementation, being prepared to adapt the AI review model (F2) based on early results.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]
- [Severity]: SIGNIFICANT
- [Finding]: Inconsistent referencing of the design spec version: filename listed as `crumb-design-spec-v2-0.md` in vault placement, but referred to as "v2.0.2" multiple times (e.g., source material, consolidation plan, three-document hierarchy).
- [Why]: Creates ambiguity about the authoritative version; could lead to AI drafting from wrong source or maintenance confusion in a system emphasizing hierarchy and no drift.
- [Fix]: Standardize to one reference (e.g., confirm filename matches latest version like `crumb-design-spec-v2-0-2.md` or update text to "v2.0"); add note in hierarchy section clarifying filename vs. content version.

- [F2]
- [Severity]: SIGNIFICANT
- [Finding]: Reliance on Obsidian wikilinks (e.g., "wikilink cross-referencing", "wikilink stub") despite primary consumption via NotebookLM, which does not resolve vault-internal wikilinks.
- [Why]: Violates design constraint for notebook-friendly docs ("explicit cross-references rather than assumed vault navigation, no reliance on Obsidian-specific rendering"); Danny's primary interface breaks links, reducing usability.
- [Fix]: Mandate plain Markdown links with full titles or paths (e.g., `[02-building-blocks](_system/docs/architecture/02-building-blocks.md)`); update quality standards to prohibit unresolved wikilinks in notebook-bound docs.

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: Heavy dependence on Mermaid diagrams (at least one per architecture section except 05; sequence diagrams for every runtime flow) for notebook consumption, but Mermaid rendering is not natively supported in NotebookLM.
- [Why]: Core content (e.g., context diagrams, dependencies, flows) becomes inaccessible or poorly rendered in primary consumption tool, undermining "self-contained" requirement and Ceremony Budget Principle.
- [Fix]: Add fallback ASCII art or textual descriptions alongside Mermaid; test rendering in NotebookLM during Phase 1 and note alternatives in quality standards.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: Source material lists undefined or vague items like "userMemories context", "OpenClaw infrastructure notes", "bridge architecture notes", "dashboard source code" without paths or verification steps.
- [Why]: AI drafting workflow assumes AI can locate these; gaps lead to incomplete drafts, violating "AI must produce complete, publication-ready documents" and Danny's final-review-only model.
- [Fix]: Provide explicit paths or vault locations (e.g., "userMemories context: [[userMemories]]"); add "locate source" step in AI workflow.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Specific token/line budgets (CLAUDE.md "200 lines", overlays "50 lines", SKILL.md "nine-section structure") referenced repeatedly as "enforced" or "conventions" (e.g., cross-cutting, quality standards, orientation map).
- [Why]: Cannot independently confirm if existing docs adhere to these exact budgets or if enforcement (e.g., via vault-check) exists; risks drafting stale or incorrect tracking in orientation map.
- [Fix]: Flag for Danny verification; add "verified as of [date]" in orientation map; reference specific vault-check rules if applicable.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: Operator doc minimum set plans new files (e.g., `deploy-openclaw-update.md`) while consolidation "keeps as-is" similar existing ones (e.g., `crumb-deployment-runbook.md` reclassified); potential duplication.
- [Why]: Violates Ceremony Budget Principle; creates overlapping maintenance debt in `operator/how-to/`.
- [Fix]: Merge into one doc during Phase 2 (e.g., expand `crumb-deployment-runbook.md`); explicitly note merges in consolidation table.

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: Effort estimates lowball complexity (e.g., Phase 1: 3-5 sessions for 5 docs with multiple Mermaid diagrams, cross-referencing large sources like 2,600-line spec); ignores diagram iteration/debugging.
- [Why]: Underestimates feasibility for evening/weekend cadence (claimed 2-4 weeks); risks incomplete phases or burnout under single-operator constraint.
- [Fix]: Revise estimates (e.g., 1-2 sessions/doc); add "diagram validation sub-task" in AI workflow.

- [F8]
- [Severity]: MINOR
- [Finding]: Vault placement tree uses `00-architecture-overview.md` as master entry point, but Arc42 section definitions start at `01-context-and-scope.md` without explicitly defining 00's contents.
- [Why]: Minor gap in completeness; overview risks being vague placeholder.
- [Fix]: Add brief "00 — Architecture Overview" definition (e.g., "Summary + section links + change log").

- [F9]
- [Severity]: MINOR
- [Finding]: Tag taxonomy updates required (new Level 2 tags like `system/architecture`) noted, but no action assigned in implementation plan or maintenance model.
- [Why]: Breaks vault-check enforcement on commit; delays Phase 1.
- [Fix]: Add pre-Phase 1 task: "Update `file-conventions.md` and `vault-check.sh` for new tags."

- [F10]
- [Severity]: MINOR
- [Finding]: Orientation map structure uses tables but example has inconsistent columns (e.g., Session Entry Points lacks "Activation Signal"; Skills lacks it too).
- [Why]: Reduces clarity and automation potential; harder for gap/staleness detection.
- [Fix]: Standardize table columns across sections (e.g., add common ones like "Last Updated").

- [F11]
- [Severity]: STRENGTH
- [Finding]: Clear three-document hierarchy with downward authoritativeness flow (design spec → architecture → version history) and explicit drafting inputs.
- [Why]: Prevents drift/duplication effectively; aligns with single-operator maintenance model.
- [Fix]: N/A

- [F12]
- [Severity]: STRENGTH
- [Finding]: Comprehensive consolidation plan with absorb-and-redirect pattern and `Ops/` retirement; specific table mapping existing docs.
- [Why]: Directly addresses ad-hoc state; minimizes duplication while preserving history via stubs/archives.
- [Fix]: N/A

- [F13]
- [Severity]: STRENGTH
- [Finding]: Phased implementation with intra-phase usability (e.g., architecture usable before operator docs) and sequenced dependencies (e.g., deployment before runtime views).
- [Why]: Enhances feasibility under bandwidth constraints; incremental value.
- [Fix]: N/A

- [F14]
- [Severity]: STRENGTH
- [Finding]: Strict Diátaxis enforcement (one quadrant/doc, voice/structure triggers) with minimum set prioritized by criticality.
- [Why]: Ensures operator docs are task-oriented and maintainable; fits "someone could run this" purpose.
- [Fix]: N/A

---

## Synthesis

### Consensus Findings

**1. Tag taxonomy is a Phase 1 blocker** (DS-F11, GRK-F9)
New tags (`system/architecture`, `system/operator`, `system/llm-orientation`) will fail vault-check on commit. `file-conventions.md` and `vault-check.sh` must be updated *before* any new architecture doc can be committed. Both reviewers independently identified this as a sequencing gap.

**2. Consolidation plan conflicts with Phase 2 AI workflow** (GEM-F1, OAI-F9, OAI-F10, GRK-F6)
The Phase 2 AI workflow says "AI drafts the document" for every item in the batch lists. But the consolidation plan marks several docs (vault-gardening, deployment runbook, Ops/ files) as "keep as-is" — meaning they should be moved and retagged, not redrafted. This creates contradictory instructions. Additionally, `deploy-openclaw-update.md` (new) overlaps with `crumb-deployment-runbook.md` (reclassified). And legacy docs moved "as-is" may violate strict Diátaxis quadrant rules without normalization.

**3. NotebookLM rendering vs. Mermaid/wikilink mandates** (OAI-F21, GEM-F2, GRK-F2, GRK-F3)
The spec mandates Mermaid diagrams inline and wikilinks for cross-referencing, but also says NotebookLM is the primary consumption mechanism where neither renders natively. Three reviewers flagged this tension. The constraint "no reliance on Obsidian-specific rendering" is contradicted by vault conventions that are inherently Obsidian-specific.

**4. Staleness detection too weak** (OAI-F12, GEM-F5)
Timestamp-based staleness comparison is fragile — git operations and syncs overwrite filesystem mtime, and editorial changes don't necessarily make downstream docs stale. GEM-F5 specifically recommends using the `updated:` frontmatter field instead.

**5. Effort estimates optimistic** (OAI-F22, DS-F10, GRK-F7)
Three reviewers flagged 3-5 sessions for Phase 1 as tight given source synthesis complexity, diagram iteration, and consolidation work. Phase 2 reference docs requiring vault/code scanning are also variable.

**6. Architecture overview (00) undefined** (OAI-F17, GRK-F8)
Five section definitions are provided (01-05) but 00-architecture-overview.md has no section definition, expected contents, or scope statement. Risk of it becoming a vague placeholder.

**7. Authority model needs clarity** (OAI-F6, OAI-F7)
Version history is described as being in the "authority chain" (three-document hierarchy table) while also being called "not a source of authority." The word "authoritative" is used in two senses (intent authority vs. current-state authority) without distinguishing them.

### Unique Findings

**OAI-F8 — Maintenance trigger contradicts Section 05 rescoping.** The trigger "Design principle added/changed → Update cross-cutting concepts" reintroduces the duplication the rescoping was meant to avoid. Genuine insight — directly conflicts with Decision #11.

**OAI-F13 — No source conflict resolution method.** When design spec, version history, code, and vault notes disagree, the AI has no precedence rule. Useful insight for Phase 1 execution, though possibly better handled as a drafting instruction than a spec-level rule.

**OAI-F24 — Actor definitions mapped to both 01 and 02.** The consolidation table maps `tess-crumb-comparison.md` to `02-building-blocks.md` for "actor definitions," but actor definitions are specified under `01-context-and-scope.md`. Small but concrete mapping inconsistency.

**DS-F2 — Pass/fail review too rigid for complex sections.** Suggests intermediate checkpoints for complex docs (03-runtime-views, 02-building-blocks). Valid operational concern, but the spec's validation model deliberately optimizes for Danny's bandwidth.

**DS-F3 — No plan for documenting deprecated subsystems.** A rebuild narrative benefits from knowing what *not* to rebuild. Could be a subsection in 02-building-blocks. Interesting perspective but may be premature.

**GEM-F12 — No rollback procedure for failed reviews.** If a foundational architecture doc fails pass/fail review, downstream docs built on it incur rework. Suggests a "redline" procedure. Reasonable but may be over-engineering the review process.

**GRK-F1 — Design spec version inconsistency.** Filename is `crumb-design-spec-v2-4.md` but the spec text references `v2.0.2` and the vault placement tree shows `v2-0`. Three different version references.

### Contradictions

**GEM-F3 claims Apple never released M3 Ultra.** This is a reviewer error — the M3 Ultra was released in 2025. The hardware spec is correct.

**GEM-F4 claims Claude doesn't have a 1M context window.** This is a reviewer error — Claude Opus 4.6 has a 1M token context window. The statement in the spec is factually correct.

**Wikilink handling:** GRK-F2 recommends replacing wikilinks with standard Markdown links. This conflicts with the vault's foundational cross-referencing convention. OAI-F21 takes a more pragmatic approach: keep wikilinks but add prose summaries below diagrams for NotebookLM readability. The correct resolution is to treat wikilinks as semantic references that remain readable as text even when not clickable — which the spec's constraint ("explicit cross-references rather than assumed vault navigation") already contemplates.

### Action Items

**Must-fix:**

- **A1** — Pre-Phase 1: update `file-conventions.md` and `vault-check.sh` for new tags before any architecture doc is committed. (DS-F11, GRK-F9)
- **A2** — Reconcile consolidation plan with Phase 2 workflow: (a) exclude "keep as-is" docs from AI drafting queue, (b) add them to a specific batch as migration tasks, (c) clarify whether each needs Diátaxis normalization or moves verbatim, (d) resolve `deploy-openclaw-update.md` vs. `crumb-deployment-runbook.md` overlap. (GEM-F1, OAI-F9, OAI-F10, GRK-F6)

**Should-fix:**

- **A3** — Add NotebookLM rendering guidance: require prose summary below each Mermaid diagram; acknowledge wikilinks function as text references in notebook context. (OAI-F21, GEM-F2, GRK-F2, GRK-F3)
- **A4** — Clarify authority domains: design spec = authority for intent; architecture docs = authority for current implementation state; version history = authority for chronology only (not in the authority chain). (OAI-F6, OAI-F7)
- **A5** — Fix maintenance trigger: change "Design principle added/changed → Update cross-cutting concepts" to "If a design principle change alters enforced conventions or patterns, update 05; otherwise update only the design spec." (OAI-F8)
- **A6** — Add section definition for `00-architecture-overview.md`: purpose, expected contents, what it should not duplicate. (OAI-F17, GRK-F8)
- **A7** — Specify staleness detection uses `updated:` frontmatter field, not filesystem mtime. (GEM-F5, OAI-F12)
- **A8** — Fix design spec version references: standardize to actual filename (`crumb-design-spec-v2-4.md`) throughout. (GRK-F1)
- **A9** — Fix actor definition placement: consolidation table maps comparison doc to 02, but actor definitions are specified under 01. Pick one location. (OAI-F24)

**Defer:**

- **A10** — Add effort estimate caveats for diagram iteration and consolidation work. Planning note, not a spec flaw. (OAI-F22, DS-F10, GRK-F7)
- **A11** — Source material path specificity. Handle during Phase 1 session prep, not spec-level. (OAI-F16, GRK-F4)
- **A12** — First-use term expansion. Handle during Phase 1 drafting in 01-context-and-scope. (OAI-F20)
- **A13** — Checkpoint model for complex docs. Operational adjustment, not spec change. (DS-F2)
- **A14** — Deprecated subsystems documentation. Can add during Phase 1 drafting if needed. (DS-F3)
- **A15** — Orientation map column standardization. Phase 3 concern. (GRK-F10)

### Considered and Declined

- **GEM-F3** — "M3 Ultra doesn't exist." `incorrect` — Apple released M3 Ultra in 2025.
- **GEM-F4** — "Claude doesn't have 1M context." `incorrect` — Claude Opus 4.6 has 1M context window.
- **OAI-F23** — Add `reviewed:` or `verified_against:` metadata. `overkill` — ceremony debt for single-operator system; the `updated:` field already serves this purpose.
- **GEM-F7** — Add deprecation trigger for operator docs. `constraint` — covered by existing project archival conventions in CLAUDE.md §Project Archival.
- **OAI-F11** — Narrow "every document" scope in quality standards. `constraint` — already clear from context that this refers to new docs produced by the overhaul, not CLAUDE.md/SOUL.md.
- **GRK-F2** — Replace wikilinks with standard Markdown links. `constraint` — wikilinks are a foundational vault convention. Changing link syntax for one doc subset would create inconsistency across the vault. NotebookLM handles them as readable text references.
- **GEM-F12** — Add redline procedure for failed reviews. `overkill` — pass/fail review is deliberately lightweight. If a doc fails, the feedback is specific enough to redraft without a formal procedure.
- **OAI-F15** — Orientation map discovery specification. `out-of-scope` — Phase 3 concern; the spec intentionally defers automation details.
