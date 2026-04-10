---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/book-scout/specification.md
artifact_type: spec
artifact_hash: 9de16509
prompt_hash: e17ecaa9
base_ref: null
project: book-scout
domain: software
skill_origin: peer-review
created: 2026-02-28
updated: 2026-02-28
status: active
reviewers:
  - openai
  - google
  - deepseek
  - grok
config_snapshot:
  openai: gpt-5.2
  google: gemini-3-pro-preview
  deepseek: deepseek-reasoner
  grok: grok-4-1-fast-reasoning
  retry_max: 3
  curl_timeout: 120
safety_gate:
  hard_denylist: pass
  soft_heuristics: pass
  outcome: clean
reviewer_meta:
  openai:
    model_returned: gpt-5.2-2025-12-11
    system_fingerprint: null
    tokens_in: 6546
    tokens_out: 2643
    status: success
  google:
    model_returned: gemini-3-pro-preview
    system_fingerprint: n/a
    tokens_in: 7026
    tokens_out: 1472
    thoughts_tokens: 1988
    status: success
  deepseek:
    model_returned: deepseek-reasoner
    system_fingerprint: fp_eaab8d114b_prod0820_fp8_kvcache
    tokens_in: 6670
    tokens_out: 4329
    reasoning_tokens: 2827
    status: success
  grok:
    model_returned: grok-4-1-fast-reasoning
    system_fingerprint: fp_8163501e02
    tokens_in: 6604
    tokens_out: 1995
    status: success
    note: "Initial urllib dispatch failed (HTTP 403); succeeded on curl retry"
tags:
  - review
  - peer-review
---

# Peer Review — Book Scout Specification

**Artifact:** `Projects/book-scout/specification.md`
**Mode:** full | **Round:** 1 | **Date:** 2026-02-28
**Reviewers:** 4 dispatched, 4 succeeded, 0 failed

---

## Synthesis

### Convergence Summary

All four reviewers approve with conditions (3 explicit "approve with conditions", 1 "needs rework" from Grok). The reviews converge strongly on several themes:

1. **API existence is the critical unknown** — all 4 reviewers flag the unverified Anna's Archive JSON API as a foundational risk. The spec already gates on M0 validation; reviewers want a fallback/kill criteria.
2. **File-based handoff needs robustness** — 3/4 reviewers (OAI, GEM, GRK) identify race conditions, lack of idempotency, missing acknowledgment, and cleanup protocol gaps in the tess_scratch catalog handoff.
3. **Source-index schema compatibility unverified** — 3/4 reviewers (OAI, DS, GRK) note the spec asserts compatibility with file-conventions.md but doesn't quote or validate the actual schema.
4. **Inline download timeout risk** — 3/4 reviewers (OAI, GEM, GRK) flag that synchronous curl downloads could exceed agent/tool timeouts for large files or bulk batches.
5. **Disk exhaustion not mitigated** — 2/4 reviewers (DS, GRK) note the threat model lacks storage quota controls.

### Cross-Reviewer Finding Matrix

| Theme | OAI | GEM | DS | GRK | Consensus |
|-------|-----|-----|-----|-----|-----------|
| API existence unverified | F10 | F3 | F1 | F1 | 4/4 — unanimous |
| File handoff robustness | F3 | F2 | F8(partial) | F5 | 3/4 — strong |
| Schema compatibility | F2 | — | F3 | F2 | 3/4 — strong |
| Download timeout/async | F4 | F1 | F6(partial) | F6 | 3/4 — strong |
| Disk exhaustion | — | — | F5 | F9 | 2/4 — moderate |
| Subject/tag classification | F7 | — | — | F7 | 2/4 — moderate |
| Duplicate detection | F8 | — | — | F8(partial) | 2/4 — moderate |
| Non-PDF format handling | — | — | — | F10 | 1/4 — unique |
| Crumb processor trigger | — | F4 | — | — | 1/4 — unique |
| API deprecation/change | — | — | F4 | — | 1/4 — unique |

### Classified Findings

#### Must-Fix (block PLAN phase)

**MF-1: File-based handoff protocol needs robustness design** (OAI-F3, GEM-F2, GRK-F5)
Three reviewers independently identify that the tess_scratch catalog handoff lacks atomicity, idempotency, acknowledgment, and cleanup. This is the primary integration seam.
- Atomic writes (tmp + rename)
- Deduplication keys (source_id + aa_id)
- Processing states (inbox → processed/failed)
- Crumb sweep trigger mechanism (GEM-F4 adds: when does Crumb actually process these?)
- Stale file cleanup
**Action:** Add a catalog handoff protocol subsection to spec section 4.4 or 6.

**MF-2: Source-index schema must be validated against file-conventions.md** (OAI-F2, DS-F3, GRK-F2)
The spec asserts compatibility but doesn't quote the actual schema. Field mismatches (e.g., `date_ingested` vs `acquired_at`, `domain: learning` vs project `domain: software`) will cause vault-check failures.
**Action:** Read file-conventions.md, quote the exact source-index schema, and reconcile fields in spec section 6.

#### Should-Fix (address before PLAN completion)

**SF-1: Download timeout and size handling** (OAI-F4, GEM-F1, GRK-F6)
Synchronous curl for bulk downloads or large files risks exceeding agent timeouts. The spec should define:
- Per-file size cap or warning threshold (e.g., >50MB requires confirmation)
- Sequential download with per-item timeout
- Partial file cleanup (download to .partial, rename on success)
- Whether bulk downloads are multi-turn or single-turn
**Action:** Add download constraints to spec section 8.1 tool capabilities.

**SF-2: Catalog JSON schema enrichment** (OAI-F6, GRK-F7, GRK-F10)
Schema is minimal — missing language, edition/translator, ISBN, file size in bytes, download URL provenance. Also hardcodes PDF assumption.
**Action:** Extend schema with optional fields; generalize format field beyond PDF.

**SF-3: Subject-to-tag mapping** (OAI-F7, GRK-F7)
No defined mapping from library subjects (philosophy, history, etc.) to `#kb/` tags and `topics:` values. Risk of taxonomy drift.
**Action:** Add subject → kb tag → topic mapping table to spec section 7.

**SF-4: Disk space management** (DS-F5, GRK-F9)
Threat model doesn't cover storage exhaustion. Add pre-download space check and optional per-batch size limit.
**Action:** Add BST-7 to threat model.

**SF-5: Add kill/pivot criteria to BSC-001** (GEM-F3, GRK-F1)
M0 gates on API validation, but there's no defined outcome if the API doesn't exist or behaves differently than assumed. Define what happens: cancel project, pivot to alternative source, or descope.
**Action:** Add fallback criteria to BSC-001 acceptance.

#### Defer (track for implementation phase)

**DF-1: Duplicate detection design** (OAI-F8, GRK-F8)
BSC-009 mentions it but the mechanism isn't specified. Can be designed during TASK phase.

**DF-2: Telegram UX pagination/truncation** (OAI-F14, GRK-F11)
Result sets exceeding Telegram limits need pagination. Implementation detail for BSC-004.

**DF-3: Non-PDF format support** (GRK-F10)
Valid but the operator's library is predominantly PDF. Generalize the format field now (SF-2), defer multi-format download handling.

**DF-4: Testing and CI** (OAI-F12)
Unit/integration tests, API fixtures, and contract tests are implementation concerns for TASK phase.

**DF-5: API change/deprecation resilience** (DS-F4)
Add to threat model as low-priority. Configurable base URL already partially addresses this.

#### Noise / Not Applicable

**GRK-F13** (dates in 2026): The dates are correct — this is a 2026 project. Reviewer lacks context.
**GRK-F3** (Haiku 4.5 unverifiable): Internal system context; Haiku 4.5 is the actual runtime. Not actionable.
**GRK-F4** (infrastructure unverifiable): Same — these are verified internal facts (F4, F5, F6). Not actionable.

### Unverifiable Claims Assessment

| Claim | Reviewers | Assessment |
|-------|-----------|------------|
| Anna's Archive JSON API exists (F1) | OAI, GEM, DS, GRK | **Valid concern** — already gated on M0 |
| Haiku 4.5 runtime | OAI, GRK | Internal fact — verified, not actionable |
| OpenClaw tool patterns (x-feed-intel) | GRK | Internal fact — verified |
| tess_scratch exists with perms | DS | Internal fact — BSC-002 validates |
| crumb-tess-bridge is DONE | GRK | Internal fact — verified |

### Verdict

**Approve with conditions.** The specification is well-structured with clear architectural decisions, comprehensive task decomposition, and appropriate risk awareness. Two must-fix items (handoff protocol robustness, schema validation) should be addressed before advancing to PLAN phase. The remaining should-fix items can be incorporated during PLAN or early TASK phase.

Grok's "needs rework" verdict is overstated — the individual findings don't support that severity. Per calibration notes, treat Grok's summary verdict as "has significant findings" and evaluate findings on merits (which we have done above).

### Action Items

| ID | Action | Class | Source |
|----|--------|-------|--------|
| A1 | Add catalog handoff protocol subsection (atomic writes, dedup keys, processing states, cleanup, Crumb sweep trigger) to spec §4.4 or §6 | must-fix | OAI-F3, GEM-F2, GEM-F4, GRK-F5 |
| A2 | Quote exact source-index schema from file-conventions.md in spec §6; reconcile field names (date_ingested vs acquired_at, domain values, etc.) | must-fix | OAI-F2, DS-F3, GRK-F2, GEM-F5 |
| A3 | Add download constraints: per-file size cap/warning, per-item timeout, .partial file pattern, bulk download sequencing | should-fix | OAI-F4, GEM-F1, GRK-F6 |
| A4 | Extend catalog JSON schema: add language, edition/translator, file_size_bytes; generalize format beyond PDF | should-fix | OAI-F6, GRK-F10 |
| A5 | Add subject → #kb/ tag → topics mapping table to spec §7 | should-fix | OAI-F7, GRK-F7 |
| A6 | Add BST-7 (disk space exhaustion) to threat model with pre-download space check | should-fix | DS-F5, GRK-F9 |
| A7 | Add kill/pivot criteria to BSC-001 acceptance: define outcomes if API doesn't exist or differs from assumptions | should-fix | GEM-F3, GRK-F1 |
| A8 | Design duplicate detection mechanism (defer to TASK phase, track now) | defer | OAI-F8, GRK-F8 |
| A9 | Telegram pagination for large result sets (implementation detail for BSC-004) | defer | OAI-F14, GRK-F11 |
| A10 | Non-PDF format download handling (generalize format field now per A4, defer multi-format download) | defer | GRK-F10 |

### Considered and Declined

| Finding | Justification | Category |
|---------|---------------|----------|
| OAI-F1 (legal/compliance section, mandatory confirmation for non-PD) | Spec §3 Non-Goals item 1 explicitly states copyright is operator concern. Danny confirmed this in clarifying questions. Adding mandatory gates overrides a deliberate design decision. However, making rights metadata display prominent is good — already in spec. | constraint |
| GRK-F1 (suspend spec until M0) | Specs can and should document unknowns with validation gates. M0 is already a gated milestone — the spec correctly separates "what we need to build" from "what we need to learn first." Suspending the spec adds no value. | incorrect |
| OAI-F5 (bridge-skip governance risk) | tess_scratch has group write perms (crumbvault group) and directory-level access control. Crumb-side schema validation is already specified. The bridge's governance (confirmation echo) is designed for interactive operations; catalog handoff doesn't benefit from it. | constraint |
| OAI-F12 (testing/CI/rollback) | Valid but implementation concerns, not spec scope. Tests are covered implicitly in task acceptance criteria. | out-of-scope |
| DS-F4 (API deprecation resilience) | Configurable base URL already partially addresses this. Adding a formal deprecation response plan is overkill for a donation-based API. | overkill |
| GRK-F8 (missing tasks for bulk parse, subject inference) | Bulk parsing is part of BSC-004 (search result formatting). Subject inference is part of BSC-005 (download tool writes catalog JSON with subject). These aren't missing, they're embedded. | incorrect |

---

## Individual Reviewer Responses

### OpenAI (gpt-5.2)

**F1. CRITICAL: Legal/compliance exposure around Anna's Archive usage and "no gating" on rights**
- **Finding:** The spec explicitly states Tess will not gate downloads on copyright/licensing and will rely on operator judgment, while the system is designed to search/download from Anna's Archive (which aggregates materials from mixed legality sources). This creates a high-risk compliance posture for an automated downloader integrated into a persistent agent.
- **Why:** Even if the operator decides, the system design (automation + integrated cataloging) materially increases the risk of unlawful acquisition, policy violations, or account/API key termination.
- **Fix:** Add a compliance section and guardrails: (1) make rights metadata display mandatory and prominent; (2) add an explicit "confirm rights/compliance" step for non-public-domain/unknown rights; (3) add allowlist filters (e.g., PD/CC only) configurable by operator; (4) document AA API ToS constraints.

**F2. CRITICAL: Source-index schema compatibility is asserted but not validated; likely field mismatches**
- **Finding:** The spec claims compatibility with `_system/docs/file-conventions.md` but provides a YAML frontmatter example that may not match the canonical schema. Mixed fields and naming may cause vault-check failures.
- **Why:** Vault ingestion is a hard dependency for downstream BBP. Schema mismatch will break the handoff and produce silent pipeline failures.
- **Fix:** Pin the exact schema requirements and update both catalog JSON mapping and the example frontmatter. Include a contract test.

**F3. CRITICAL: File-drop handoff (AD-2) lacks idempotency, atomicity, and acknowledgement**
- **Finding:** AD-2 is justified but the design omits essential file-based integration mechanics: atomic writes, processing/done states, deduplication keys, and acks.
- **Why:** Primary integration seam. Without correctness guarantees, duplicated source-index notes, missed ingestion, or corrupted JSON ingestion.
- **Fix:** Define a robust file-drop protocol with atomic rename, unique catalog_id, processing states, and reconcile command.

**F4. SIGNIFICANT: Inline download missing resilience features for large/slow/unstable downloads**
- **Finding:** Inline curl lacks support for resume, partial files cleanup, timeouts tuned by size, and concurrency control. The "single conversation turn" assumption may not hold.
- **Why:** Poor UX (Telegram interaction times out), tool invocation may exceed runtime limits.
- **Fix:** Add explicit curl flags, download to *.partial then rename, optional resume, size caps and user confirmation.

**F5. SIGNIFICANT: Bridge-skip risks of bypassing governance not fully addressed**
- **Finding:** File-drop becomes an ungoverned capability escalation path if any process/user can write into tess_scratch/catalog.
- **Why:** Expands attack surface for catalog injection.
- **Fix:** Tighten access/validation, restrict directory permissions, require Crumb-side strict schema validation.

**F6. SIGNIFICANT: Catalog JSON schema missing fields needed for robust provenance**
- **Finding:** JSON lacks language, edition/translator/publisher, ISBN, download URL, file size, and a stable identifier strategy.
- **Why:** Downstream BBP and long-term library management benefit from stable IDs and provenance.
- **Fix:** Extend schema with catalog_id (UUID), aa_doc_id, downloaded_from, language, filesize_bytes, edition/translator.

**F7. SIGNIFICANT: Subject classification and tagging pipeline is underspecified**
- **Finding:** No mapping table, allowed set, or validation to prevent taxonomy drift.
- **Why:** Knowledge graph quality degrades with inconsistent tags/topics.
- **Fix:** Define an authoritative subject-to-tag/topic mapping (enum) and enforce it.

**F8. SIGNIFICANT: Duplicate detection mentioned but not designed end-to-end**
- **Finding:** Hardening task mentions it but there's no earlier design for how to detect or handle duplicates.
- **Why:** Duplicates waste disk and clutter the vault; collisions on source_id could overwrite catalog entries.
- **Fix:** Make dedupe first-class: check existing source-index by aa_doc_id/MD5 before downloading.

**F9. SIGNIFICANT: Unverifiable claims about API, system components, and versions**
- **Finding:** Multiple factual assertions cannot be independently verified within the document.
- **Why:** Foundational to feasibility.
- **Fix:** Convert to explicit assumptions with validation tasks.

**F10. SIGNIFICANT: UNVERIFIABLE CLAIM: "Anna's Archive offers a JSON API"**
- **Finding:** The document asserts an AA JSON API exists and is intended for programmatic use.
- **Why:** Entire project depends on this.
- **Fix:** In BSC-001, require capturing canonical documentation and example requests.

**F11. SIGNIFICANT: UNVERIFIABLE CLAIM: "Tess (voice agent — Haiku 4.5)" runtime characteristics**
- **Finding:** Version references and cost estimates rely on Haiku 4.5 behavior/limits.
- **Why:** Tool timeouts, conversational turn limits, and cost model depend on runtime.
- **Fix:** Document actual runtime constraints in BSC-002.

**F12. SIGNIFICANT: Task decomposition missing explicit tests, CI, and rollback strategy**
- **Finding:** Tasks omit unit/integration tests, fixture-based schema tests, and rollback/uninstall plan.
- **Why:** External API variability and file-based handoff require robust testing.
- **Fix:** Add test harness, contract tests, end-to-end test, and operational runbook.

**F13. MINOR: Inconsistent terminology around IDs**
- **Finding:** Schema uses `aa_id: "md5:abc123..."` but elsewhere refers to "doc IDs" and separate MD5 field.
- **Why:** Implementation confusion and brittle mapping.
- **Fix:** Normalize fields: aa_doc_id (string), md5 (hex).

**F14. MINOR: Telegram UX needs pagination strategy**
- **Finding:** Large result sets will exceed message constraints; no truncation/pagination defined.
- **Why:** Usability for large result sets.
- **Fix:** Specify pagination: show top 5-10, offer "more".

**F15. MINOR: Storage/permissions details lightly specified**
- **Finding:** Mentions group perms but not exact ownership/mode requirements.
- **Why:** Common source of runtime failures.
- **Fix:** Document exact chown/chmod in BSC-002.

**F16. STRENGTH:** Clear four-phase workflow with realistic gating on API key and M0 research.
**F17. STRENGTH:** AD-2 rationale is pragmatic and respects existing DONE bridge constraints.
**F18. STRENGTH:** Threat model identifies key classes (key exposure, path traversal, injection).

**Verdict:** Approve with conditions (3 critical, 9 significant, 3 minor, 3 strengths)

---

### Google (gemini-3-pro-preview)

**F1. CRITICAL: Synchronous execution of bulk downloads risks agent timeouts**
- **Finding:** AD-1 and the bulk list feature conflict. If a batch of 5-10 items or a large PDF is requested, execution will likely exceed standard LLM agent tool timeouts (60-120 seconds).
- **Why:** Tool timeout causes crash or error state, potentially leaving partial downloads or corrupted files.
- **Fix:** Restrict to single file per invocation with agent loop, spawn async process, or enforce size/count limits.

**F2. SIGNIFICANT: "Fire-and-forget" catalog handoff creates silent failure modes**
- **Finding:** No feedback loop if Crumb fails to process the JSON. User told the book is cataloged but source-index note may never be created.
- **Why:** Data consistency risk. Downstream BBP will never see the book.
- **Fix:** Introduce inbox/success/error directory states. Tess checks error directory periodically.

**F3. SIGNIFICANT: UNVERIFIABLE CLAIM regarding Anna's Archive API**
- **Finding:** API may not exist or function differently. If scraping only, entire architecture invalid.
- **Why:** External dependency cannot be verified without donation key.
- **Fix:** Define fallback plan (Strategy B) now — pivot or cancel criteria for BSC-001.

**F4. SIGNIFICANT: Trigger mechanism for Crumb processing is undefined**
- **Finding:** Unclear if Crumb processing is automated daemon, cron job, or manual command.
- **Why:** If manual, "Automated" goals are compromised. If automated, mechanism is missing from architecture.
- **Fix:** Explicitly define trigger in Section 4.3 and add implementation task in M3.

**F5. MINOR: Schema mapping ambiguity for date fields**
- **Finding:** JSON uses ISO8601 `acquired_at` but YAML uses `date_ingested: YYYY-MM-DD`.
- **Why:** Ambiguity in implementation; may cause schema validation errors.
- **Fix:** Explicitly state transformation logic in BSC-007.

**F6. MINOR: Redundant classification in source-index schema**
- **Finding:** Both `tags: - kb/philosophy` and `topics: - moc-philosophy` may be redundant.
- **Why:** Double-entry creates maintenance debt.
- **Fix:** Clarify if both are required by file-conventions.md.

**F7. STRENGTH:** Robust path security strategy (BST-3 well-mitigated).
**F8. STRENGTH:** Appropriate handling of copyright/licensing as operator concern.

**Verdict:** Approve with conditions (1 critical, 3 significant, 2 minor, 2 strengths)

---

### DeepSeek (deepseek-reasoner)

**F1. SIGNIFICANT: Unverifiable claim about Anna's Archive API existence and capabilities**
- **Finding:** Entire project hinges on API's existence, behavior, and availability. Cannot be independently verified.
- **Why:** Core functionality failure if API doesn't function as assumed.
- **Fix:** Treat as critical unknown; BSC-001 must validate before implementation.

**F2. SIGNIFICANT: Unverifiable claim about existing scratch directory and permissions**
- **Finding:** Assumes `_openclaw/tess_scratch/` exists with correct configuration.
- **Why:** Catalog handoff depends entirely on this directory being accessible.
- **Fix:** BSC-002 should verify existence and permissions, create if absent.

**F3. SIGNIFICANT: Source-index note schema compatibility cannot be verified**
- **Finding:** References file-conventions.md schema but doesn't provide the actual schema. Example may not match live schema.
- **Why:** Integration failure if generated notes don't conform to expected schema.
- **Fix:** BSC-007 should explicitly validate against current file-conventions.md schema.

**F4. SIGNIFICANT: No mechanism for handling API changes or deprecation**
- **Finding:** No plan for future API changes to endpoints, response format, or authentication.
- **Why:** Third-party service may change without notice, breaking the tool.
- **Fix:** Add BST-7 to threat model. Make API base URL configurable, add structured error logging.

**F5. SIGNIFICANT: Disk space exhaustion risk not fully mitigated**
- **Finding:** Threat model addresses API quota but not disk space from unchecked downloads.
- **Why:** Unchecked downloads could consume available storage.
- **Fix:** Add BST-8: disk space exhaustion. Implement pre-download space check.

**F6. MINOR: Missing details on concurrent downloads and timeouts**
- **Finding:** No specification of sequential vs concurrent, no timeout values defined.
- **Why:** Large concurrent downloads could overwhelm network; inappropriate timeouts cause unnecessary failures.
- **Fix:** Specify sequential downloads and define timeout/retry values.

**F7. MINOR: Ambiguity in bulk list parsing rules**
- **Finding:** Titles containing delimiters like `-` or `by` may be misparsed.
- **Why:** Misparsing leads to incorrect searches and user frustration.
- **Fix:** More robust parsing or echo each parsed line for user confirmation.

**F8. MINOR: Missing cleanup mechanism for failed catalog JSONs**
- **Finding:** No specification for handling failed processing of catalog JSONs.
- **Why:** Failed JSONs accumulate, causing clutter and reprocessing issues.
- **Fix:** Specify processed/failed subdirectory with logging.

**F9. STRENGTH:** Clear and well-structured architectural decisions (AD-1, AD-2).
**F10. STRENGTH:** Comprehensive task decomposition with risk awareness.
**F11. STRENGTH:** Effective threat modeling for key attack vectors.
**F12. STRENGTH:** Consistent use of existing system patterns.

**Verdict:** Approve with conditions (0 critical, 5 significant, 3 minor, 4 strengths)

---

### Grok (grok-4-1-fast-reasoning)

**F1. CRITICAL: Blocking dependency on unverified Anna's Archive JSON API**
- **Finding:** Entire project relies on assumed JSON API with specific endpoints, fields, and behaviors. No evidence or documentation provided. M0 gates on this, making the spec premature.
- **Why:** Without verification, spec risks total infeasibility. If API doesn't exist or differs, core goals 1-3 fail.
- **Fix:** Suspend spec approval until M0 completes. Add contingency for web scraping or alternative sources.

**F2. CRITICAL: Source-index schema incompatibility with stated conventions**
- **Finding:** Proposed YAML sets `domain: learning`, `project: null`, `source_type: book`, but project metadata has `domain: software`. Catalog JSON maps to source-index notes with fields that may not match file-conventions.md schema.
- **Why:** Mismatches cause vault-check failures, breaking goal 5 and downstream BBP.
- **Fix:** Quote exact file-conventions.md schema in section 6. Align fields. Add BSC-007 subtask for schema validation PoC.

**F3. SIGNIFICANT: UNVERIFIABLE CLAIM: Haiku 4.5 and OpenClaw tool patterns**
- **Finding:** References Haiku 4.5, OpenClaw tools consistent with x-feed-intel. No links or excerpts provided.
- **Why:** Assumes unverified platform capabilities. If mismatched, BSC-003/005 fail.
- **Fix:** Provide platform docs/links or validate in BSC-002.

**F4. SIGNIFICANT: UNVERIFIABLE CLAIM: Existing infrastructure and project states**
- **Finding:** Claims about tess_scratch, bridge DONE status, file-conventions.md schema, BBP independence, tess user setup.
- **Why:** Spec assumes greenfield integration without verification.
- **Fix:** BSC-002 expand to audit all.

**F5. SIGNIFICANT: File-based handoff (AD-2) risks unaddressed**
- **Finding:** Ignores race conditions (multiple Tess instances writing), no idempotency, no cleanup protocol, Crumb sweep timing unspecified.
- **Why:** Lost/duplicate catalog entries, vault bloat, or processing failures in concurrent use.
- **Fix:** Add unique timestamp/UUID to filenames; check source_id existence before write; document Crumb sweep.

**F6. SIGNIFICANT: Inline download (AD-1) blocks Tess for long operations**
- **Finding:** Large files or slow networks timeout Tess conversation. No async/polling; no status endpoint.
- **Why:** Breaks usability for realistic books; personal library ok for small PDFs, but edge cases hang Telegram flow.
- **Fix:** Hybrid: short curl (<50MB) inline, else queue to launchd watcher. Add BSC-005 subtask.

**F7. SIGNIFICANT: Subject classification and file naming underspecified**
- **Finding:** No logic defined for subject assignment (query-based? API metadata? LLM inference?). Overrides mentioned but no protocol.
- **Why:** Ambiguity leads to misorganization/duplicates; Danny must micromanage.
- **Fix:** Define algorithm: subject from query tags + API lib; name via slugify.

**F8. SIGNIFICANT: Task decomposition misses implementation gaps**
- **Finding:** No task for bulk-list parsing, subject inference, Telegram state management, duplicate detection. BSC-007 assumes vault code changes but no skill_origin spec.
- **Why:** Incomplete MVP; dependency chain breaks.
- **Fix:** Add BSC-004.5 (bulk parse), BSC-009.5 (dedupe via vault query).

**F9. SIGNIFICANT: Threat model inadequate for storage/DoS**
- **Finding:** Misses disk exhaustion (unlimited downloads), no size quotas; no Telegram abuse (spam queries exhaust API).
- **Why:** Personal setup vulnerable to operator error or exploit.
- **Fix:** Add per-batch size limit, directory quota check; rate limit Telegram commands.

**F10. SIGNIFICANT: Non-PDF format handling ignored**
- **Finding:** Examples/UI assume PDF; naming convention `.pdf`; but AA has EPUB/MOBI/DJVU.
- **Why:** Breaks goals 1-4 for non-PDF; incomplete spec.
- **Fix:** Generalize format field, naming extension; add format filter to book_search.

**F11. MINOR:** Telegram UX ambiguities (bulk approval syntax, retry state tracking, char limits).
**F12. MINOR:** Cost model optimistic (unverified Haiku cost, ignores metered ISP).
**F13. MINOR:** Dates in 2026 — reviewer lacks context (these are correct).

**F14. STRENGTH:** Detailed Telegram interaction design with concrete examples.
**F15. STRENGTH:** Comprehensive task decomposition with risks/milestones.
**F16. STRENGTH:** Clear responsibility split and non-goals.

**Verdict:** Needs rework (2 critical, 8 significant, 4 minor [1 noise], 3 strengths)

---

## Raw Response Paths

- `Projects/book-scout/reviews/raw/2026-02-28-specification-openai.json`
- `Projects/book-scout/reviews/raw/2026-02-28-specification-google.json`
- `Projects/book-scout/reviews/raw/2026-02-28-specification-deepseek.json`
- `Projects/book-scout/reviews/raw/2026-02-28-specification-grok.json`
