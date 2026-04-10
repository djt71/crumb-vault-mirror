---
project: notebooklm-pipeline
domain: learning
type: log
status: active
created: 2026-02-18
updated: 2026-02-18
---

# Run Log — notebooklm-pipeline

## 2026-02-18 — Session 1: SPECIFY

### Context Inventory
- `docs/file-conventions.md` — frontmatter schema, type taxonomy, kb/ tag conventions
- `Domains/Learning/learning-overview.md` — current learning domain state
- `.claude/skills/inbox-processor/SKILL.md` — existing intake pipeline schema
- `docs/overlays/overlay-index.md` — overlay routing (no overlays activated for this task)

### Overlay Check
No overlays activated. "Glean Prompt Engineer" is closest (data pipeline from external source) but anti-signals match — this is a personal/consumer tool, not enterprise Glean.

### Research: NotebookLM Export Landscape
- **Enterprise API** — notebook/source lifecycle only (create, delete, share). No content extraction or query endpoints.
- **Chrome extensions** — practical export path:
  - "NotebookLM to LaTeX & MD" — simple, free, markdown export
  - "NotebookLM Ultra Exporter" — batch export, 10+ formats (markdown, CSV, Word, etc.), free, local processing
- **Data Tables feature** — NLM generates structured tables from sources, exportable to Google Sheets
- **No official API** for querying NLM and getting structured answers back programmatically

### Key Design Decision
Pipeline will be **semi-automated** (structured query templates + Chrome extension export + Crumb processing), not fully automated (no API exists for that).

### Peer Review — Round 1
- 3/3 reviewers responded (OpenAI GPT-5.2, Gemini 3 Pro, Perplexity Sonar Reasoning Pro)
- 4 must-fix: Chrome extension verification, sentinel marker, source dedup, task ordering
- 5 should-fix: chunking rule, template versioning, cross-domain handling, quality gate, fixture acceptance criteria
- 5 deferred to v2: source asset storage, Data Tables path, source index notes, filename collisions, rate limit modeling
- All must-fix + should-fix incorporated into spec

### Peer Review — Round 2
- 1/3 reviewers responded (OpenAI GPT-5.2; Gemini 503/timeout, Perplexity search miss)
- No must-fix items
- 6 should-fix: dual sentinel, restrict v1 note_type, dedup behavior, provenance fields, routing clarification, fixture diversity
- All incorporated into spec

### User Feedback
- Template promotion: templates should live in docs/templates/notebooklm/ after validation (not buried in archivable project). NLM-007 task added.

### Phase Transition: SPECIFY → PLAN
- Date: 2026-02-18
- SPECIFY phase outputs: specification.md, specification-summary.md
- Compound: Peer review pattern — Gemini 3 Pro Preview has reliability issues (503/timeout in 2 of 2 sessions). Perplexity's search quality is hit-or-miss for domain-specific artifact review (search returned irrelevant results in round 2). OpenAI GPT-5.2 produced the most consistently useful reviews. → Route to `docs/solutions/peer-review-patterns/` when created.
- Context usage before checkpoint: high (extended session with 2 review rounds)
- Action taken: proceeding to PLAN in same session
- Key artifacts for PLAN phase: specification-summary.md, specification.md (task decomposition section)

### Session End
- **Duration:** Full session — project creation through SPECIFY phase completion
- **Deliverables:** specification.md (25KB, 2 peer review rounds), specification-summary.md, project scaffold, 2 review notes with raw JSON
- **State:** PLAN phase entered, project-state.yaml updated, all artifacts committed
- **Compound:** Peer review reliability pattern identified (Gemini 503s, Perplexity search misses, OpenAI consistent). Template promotion lifecycle insight from user feedback. Both routed to run-log; will promote to docs/solutions/ when pattern files created.
- **Next session:** Begin PLAN phase — detail implementation approach for NLM-001 through NLM-007. Load specification-summary.md to reconstruct context.

## 2026-02-20 — Session 2: PLAN Phase

### Context Inventory
- `Projects/notebooklm-pipeline/design/specification-summary.md` (summary)
- `Projects/notebooklm-pipeline/design/specification.md` (full spec)
- `Projects/notebooklm-pipeline/progress/run-log.md` (session 1 history)
- `_system/docs/file-conventions.md` (type taxonomy, frontmatter schema)
- `.claude/skills/inbox-processor/SKILL.md` (integration target)
- `_system/docs/peer-review-config.md` (reviewer config)

### Overlay Check
No overlays activated.

### DeepSeek Peer Review (Round 3)
- 1/1 reviewer responded (DeepSeek V3.2-Thinking, 71s latency)
- 12 findings: 5 SIGNIFICANT, 4 MINOR, 3 STRENGTH
- Review note: `_system/reviews/2026-02-20-notebooklm-pipeline-spec.md`

**Action items applied to spec:**
- A1 (should-fix): source_id collision detection — added disambiguation with year/hash
- A2 (should-fix): schema_version field — added `schema_version: 1` to frontmatter
- A3 (should-fix): topic scope — added `topic:<name>` for non-linear media
- A4 (must-fix): symlink prohibition — replaced with direct move + reference note
- A5-A7: deferred (domain backlinks to MOC v2, batch strategy to NLM-006, URL normalization to NLM-004)

**Path corrections applied:** `docs/templates/notebooklm/` → `_system/docs/templates/notebooklm/` throughout

### Implementation Plan
- Created `design/implementation-plan.md` — 5-batch execution plan
- Batch 1 (Claude): schema + Sources/ + template authoring
- Batch 2 (User): export verification + template validation in NLM
- Batch 3 (Claude): inbox-processor extension
- Batch 4 (User + Claude): end-to-end testing
- Batch 5 (Claude): documentation + template promotion

### 4-Model Plan Review (R1)
- All 4 reviewers responded (GPT-5.2, DeepSeek V3.2, Gemini 3 Pro, Grok 4.1)
- Review note: `_system/reviews/2026-02-20-notebooklm-pipeline-plan.md`
- 3 must-fix: sentinel contract, source_id algorithm, fixture requirements
- 7 should-fix: parsing approach, pluralization map, validation threshold, NLM-006 files,
  NLM-007 README, malformed sentinel fallback, fixture directory
- 3 deferred: phase renaming (cosmetic), media fields (v2), Sources/ multi-tier (v2)
- All 10 action items (A1-A10) applied to implementation plan

### ACT Phase — Batch 1

**NLM-001 (schema + sentinel contract):**
- Added `knowledge-note` to type taxonomy in `_system/docs/file-conventions.md`
- Added full Knowledge Notes section: frontmatter schema, source_id algorithm, scope enum,
  source_type→directory mapping, quality gate, sentinel contract reference
- Created `_system/docs/templates/notebooklm/sentinel-contract.md` — formal spec with
  exact syntax, field definitions, detection regex, invariants

**NLM-002 (Sources/ directory):**
- Created `Sources/` with 7 subdirectories (books, articles, podcasts, videos, courses, papers, other)
- Created `Sources/sources-overview.md` with directory structure and workflow description

**NLM-003 Phase 2 (template authoring):**
- Created 5 templates in `Projects/notebooklm-pipeline/templates/`:
  `book-digest-v1.md`, `source-digest-v1.md`, `concept-extract-v1.md`,
  `argument-map-v1.md`, `comparison-v1.md`
- Each includes: NLM prompt with dual sentinel, expected output structure (heading maps),
  post-processing notes, version history
- Created `Projects/notebooklm-pipeline/fixtures/README.md` with diversity matrix,
  naming convention, fixture-meta block template

**Batch 1 complete.** vault-check clean.

### ACT Phase — Batch 2 (partial)

**NLM-003 Phase 1 (first fixture):**
- User exported Rawls "A Theory of Justice" book-digest via copy-paste from NLM
- Fixture: `fixtures/fixture-book-book-digest-v1-2026-02-20.md`
- Finding: NLM wrapped sentinel in code fences (triple backticks) — rendered template
  backtick instructions literally. Parser must strip code-fence markers when scanning.
- Markdown structure correct: headings, bullets, bold, blockquotes all preserved
- Remaining fixtures needed: article, podcast, video, messy, short

**NLM-003 Phase 1 (second fixture — Chrome extension export):**
- User exported Huxley "The Perennial Philosophy" book-digest via NotebookLM LaTeX/MD exporter
- Fixture: `fixtures/fixture-book-book-digest-v1-ext-2026-02-20.md` (renamed from double `.md.md`)
- Extension artifacts discovered:
  - Adds its own YAML frontmatter (`exported`, `source`, `type: chat`, `title`)
  - Adds H1 heading with truncated sentinel text
  - Chinese locale timestamp (`导出时间:`)
  - Citation section (`## 引用来源`) with `[N] source.pdf` references
- Formatting differences vs copy-paste:
  - Bullets: `•` (Unicode) instead of `- ` (markdown)
  - Quotes: bare text instead of `>` blockquotes
  - Inline citations: `\[1\]` escaped brackets throughout body
  - Sentinel still in code fences (same as copy-paste)
- **Impact on NLM-004:** Updated sentinel detection to scan 20 lines (not 10), strip extension
  frontmatter/heading/timestamp. Updated Step 4a stripping to handle extension artifacts,
  normalize bullets, remove inline citations, add blockquote formatting to quotes.

### ACT Phase — Batch 3

**NLM-004 (inbox-processor extension):**
- Extended `.claude/skills/inbox-processor/SKILL.md` with full NLM processing path
- Changes made:
  - **Frontmatter + Identity:** Added NLM detection to skill description and purpose
  - **Step 2 (Scan and Classify):** NLM sentinel detection with code-fence stripping,
    tolerant regex (HTML + plain-text forms), malformed sentinel fallback heuristic
  - **Step 3 (Batch Prompting):** NLM-specific prompting section — source metadata
    extraction, source_id proposal, domain/tags/scope/URL gathering
  - **Step 4 (Process Markdown):** Split into Standard Markdown Processing (unchanged)
    and NLM Export Path (new substeps 4a-4k): parse sentinel → extract metadata →
    gather remaining → dedup check → quality gate → build frontmatter → build filename →
    determine destination → write note → suggest connections → verify
  - **Context Contract:** Added sentinel contract as MUST-have for NLM, template files as MAY-request
  - **Output Constraints:** Added knowledge-note schema reference with key constraints
  - **Quality Checklist:** 7 NLM-specific verification items
  - **Convergence Dimensions:** Updated all 3 dimensions with NLM coverage
- Key design elements: template→defaults mapping table, pluralization map, dedup prompt
  (update/version/skip), quality gate for podcast/video, connection suggestion via #kb/ overlap
- Post-fixture update: tightened tag proposal behavior — constrain to canonical #kb/ list,
  explicitly flag non-canonical proposals

### ACT Phase — Batch 4 (NLM-005 e2e test)

**Test: Rawls "A Theory of Justice" (copy-paste fixture)**
- Sentinel detected: `v=1`, `template=book-digest-v1`, `note_type=digest`, `source_type=book`
- source_id: `rawls-theory-justice` — no collision
- Routed to `Sources/books/rawls-theory-justice-digest.md`
- vault-check: passes, `kb/philosophy` tag validated
- Quality gate: no tag (book — correct)
- Dedup: clean (first note in Sources/)
- **Issue found:** proposed `kb/history` and `kb/business` instead of checking canonical list.
  User corrected to `kb/philosophy` (new canonical tag). Fixed inbox-processor Step 3
  to constrain proposals to canonical list and flag non-canonical explicitly.
- **Result: PASS** — full pipeline works end-to-end

### ACT Phase — Batch 5 (NLM-006 + NLM-007)

**NLM-006 (documentation):**
- Created `Projects/notebooklm-pipeline/workflow-guide.md` — user-facing guide:
  setup, template selection, export paths, batch strategy, troubleshooting
- Updated `Domains/Learning/learning-overview.md` — added Sources & NLM Pipeline section,
  added `kb/philosophy` to knowledge base listing

**NLM-007 (template promotion):**
- Copied 5 templates to `_system/docs/templates/notebooklm/`
- Created `_system/docs/templates/notebooklm/README.md` — template index with
  usage table, workflow summary, versioning policy, new template instructions
- Created `Projects/notebooklm-pipeline/templates/PROMOTED.md` — reference note
  pointing to durable location

**Canonical tag update:**
- Added `kb/philosophy` to canonical list in `_system/docs/file-conventions.md` and `CLAUDE.md`

### Session End

- **Duration:** Full session — ACT phase Batches 1-5, all 7 NLM tasks
- **Deliverables:** inbox-processor NLM extension (SKILL.md +266 lines), 5 promoted templates,
  sentinel contract, workflow guide, Sources/ directory + first knowledge note, 2 fixtures
- **State:** Phase DONE, project-state.yaml updated, all artifacts committed
- **Compound:**
  1. Chrome extension export artifacts (frontmatter, H1 heading, Chinese locale timestamps,
     citation sections, Unicode bullets, escaped bracket citations) — documented in run-log
     and coded into parser. Route to `_system/docs/solutions/` if this pattern recurs with
     other Chrome extension tools.
  2. `#kb/` tag discipline failure — proposed non-canonical tags without checking the
     canonical list. Fixed in inbox-processor and recorded in auto-memory. Pattern:
     when a system has a controlled vocabulary, the skill procedure must explicitly
     reference the authoritative list, not rely on Claude's general knowledge.
  3. Promoted templates need frontmatter adjustment when moving from project scope to
     global scope (`project: null`, add `status: active`). This is a general pattern for
     any artifact promotion — not NLM-specific. Consider adding to compound solutions
     if it recurs.
- **Conscious deferrals:** Fixture diversity (4 of 6 slots), e2e coverage (1 of 3-5 runs),
  domain backlinks to MOC (v2), media-specific frontmatter fields (v2)
- **Next:** Pipeline is operational. Iterate when real non-book exports surface issues.

### Archival

- **Date:** 2026-02-20
- **Reason:** All 7 NLM tasks complete. Pipeline operational. All durable deliverables
  already in their permanent locations outside the project folder:
  - Knowledge notes: `Sources/`
  - Templates: `_system/docs/templates/notebooklm/`
  - Schema: `_system/docs/file-conventions.md` (Knowledge Notes section)
  - Sentinel contract: `_system/docs/templates/notebooklm/sentinel-contract.md`
  - Inbox-processor extension: `.claude/skills/inbox-processor/SKILL.md`
- **What remains in project folder:** design docs (spec, implementation plan), fixtures,
  run-log, progress-log, workflow guide, review notes (in `_system/reviews/`) — all
  reference/historical material, no active knowledge graph content.
- **Not a KB exception:** No standalone KB artifacts in project folder (unlike think-different).
  Standard archive to `Archived/Projects/`.

## 2026-02-24 — Session 3: Enhancement Maintenance Pass

### Reactivation
- Project reactivated from `Archived/Projects/` → `Projects/`
- Phase restored: ACT (from `phase_before_archive`)
- Scope: maintenance enhancement — no architectural changes

### Context Inventory
- `Projects/notebooklm-pipeline/design/nlm-enhancement-spec.md` (enhancement spec, moved from _inbox/)
- `Projects/notebooklm-pipeline/progress/run-log.md` (full project history)
- `Projects/notebooklm-pipeline/templates/book-digest-v1.md` (existing template for v2 reference)
- `Projects/notebooklm-pipeline/templates/source-digest-v1.md` (existing template for v2 reference)
- `_system/docs/templates/notebooklm/sentinel-contract.md` (sentinel format reference)

### Overlay Check
No overlays activated.

### Enhancement Scope (E1-E7)
- **E1:** book-digest-v1 → book-digest-v2 (deeper capture, new sections)
- **E2:** source-digest-v1 → source-digest-v2 (mirrors E1 depth for general sources)
- **E3:** NEW chapter-digest-v1 (per-chapter breakdown)
- **E4:** NEW fiction-digest-v1 (themes/ideas-focused, not plot summary)
- **E5:** Parser passthrough verification (may be non-issue)
- **E6:** Template index + README update
- **E7:** V1 fixture gap closure (article, podcast/video, messy, short)

### Spec Refinements Applied
1. Truncation detection note added to E1, E2, E3 — "If response ends mid-section, re-run with 'Continue from [last complete heading]' and concatenate"
2. E3 chapter-digest: individual `chapter:<n>` queries as PRIMARY (fits one-query-one-note contract), batch as fallback for short books
3. E7 added: V1 fixture gap closure — article, podcast/video, messy export, short output fixtures

### E1: book-digest-v2
- Created `templates/book-digest-v2.md` — paragraph-level arguments, expanded concepts
  with usage + examples, 8-12 quotes, new Checklists & Procedures and Tables & Structured
  Data sections, truncation recovery instructions
- Promoted to `_system/docs/templates/notebooklm/book-digest-v2.md`

### E2: source-digest-v2
- Created `templates/source-digest-v2.md` — mirrors E1 depth for general sources,
  5-8 quotes with timestamps for audio/video, same new sections
- Promoted to `_system/docs/templates/notebooklm/source-digest-v2.md`

### E3: chapter-digest-v1
- Created `templates/chapter-digest-v1.md` — individual chapter queries as PRIMARY
  approach, batch as fallback for short books. Per-chapter: summary, key points, quotes,
  checklists, tables. Synthesis: Argument Arc + Cross-Chapter Connections.
- Promoted to `_system/docs/templates/notebooklm/chapter-digest-v1.md`

### E4: fiction-digest-v1
- Created `templates/fiction-digest-v1.md` — Premise, Themes & Ideas (core), Character
  Study (meaning-focused), Craft & Style (notable only), 8-12 quotes (generous),
  Resonance & Connections, optional Context. Explicitly not: plot summary, character
  lists, spoiler warnings.
- Promoted to `_system/docs/templates/notebooklm/fiction-digest-v1.md`

### E5: Parser passthrough verification
- **Confirmed non-issue.** Inbox-processor NLM Export Path (Step 4i) combines frontmatter
  with body via prepend. Body transformations limited to: sentinel/extension artifact
  stripping (4a) and Chrome extension format normalization (bullets, citations, blockquotes).
  No body reformatting of tables, checkboxes, or content blockquotes.
- No code changes needed — passthrough is the existing behavior.

### E6: Template index + README update
- Updated `_system/docs/templates/notebooklm/README.md` — split templates into Digest
  and Extract sections, added all 4 new templates, added v1 vs v2 guidance
- Updated inbox-processor SKILL.md template→defaults mapping with 4 new entries
- Updated `templates/PROMOTED.md` with enhancement pass entries

### E7: V1 fixture gap closure — validation complete

**Fixtures received (4):**
1. Article — Aeon essay on moral courage, source-digest-v2, copy-paste
2. Video — Pigliucci TEDx on Stoicism, source-digest-v2, copy-paste
3. Messy — Degraded Pigliucci export, source-digest-v2, manufactured degradation
4. Short — Clifford ethics of belief (~1000 words), source-digest-v2, copy-paste

**Parser validation results: 3 PASS, 1 FAIL → fixed**

- Article: clean pass — sentinel on lines 1-2 without code fences (notable: only
  fixture of 4 without code-fenced sentinel)
- Video: pass with finding — no timestamps on quotes despite video source. NLM
  doesn't auto-add timestamps; template asks but NLM doesn't comply. Not a parser bug.
  `needs_review` auto-tag logic confirmed correct for video source_type.
- Messy: FAIL on HTML container tags (`<div class="nlm-response">`, `</div>`). Sentinel
  detected at line 10 (within 20-line scan), code fences stripped, missing `note_type`
  inferred from template defaults, extension preamble stripped, `•` normalized, broken
  table preserved (passthrough correct). **Fix applied:** added HTML block-level tag
  stripping rule to inbox-processor Step 4a.
- Short: clean pass — robust output from thin source, minimum-viable content well above
  threshold concerns.

**Fixture diversity matrix now:**
| Fixture | Source Type | Export Method | Template | Status |
|---|---|---|---|---|
| Rawls (v1) | book | copy-paste | book-digest-v1 | validated |
| Huxley (v1) | book | Chrome extension | book-digest-v1 | validated |
| Aeon essay | article | copy-paste | source-digest-v2 | validated |
| Pigliucci TEDx | video | copy-paste | source-digest-v2 | validated |
| Degraded Pigliucci | video (messy) | manufactured | source-digest-v2 | validated (after fix) |
| Clifford essay | article (short) | copy-paste | source-digest-v2 | validated |

6 of 6 fixture slots filled. Original coverage gap closed.

### Template Validation — Real NLM Runs

**Finding: Sentinel dropout under length pressure.**
Book-digest-v2 run against Wealth of Nations — NLM dropped the sentinel entirely.
Long-source context pressure causes NLM to skip the sentinel instruction and jump
straight to content. fiction-digest-v1 and source-digest-v2 (from fixture runs)
produced sentinels successfully, suggesting the failure mode is length-correlated.

**Fix 1: Sentinel reinforcement in templates.**
Added `IMPORTANT: Your response MUST begin with the two sentinel lines shown below,
before any other content.` to book-digest-v2, source-digest-v2, and chapter-digest-v1
(proactive — chapter digests for long books could hit the same issue). Fiction-digest-v1
left as-is (working correctly).

**Fix 2: Parser fallback — heading-pattern detection.**
Added secondary identification path to inbox-processor: if no sentinel found in scan
window, match heading patterns against known template signatures (e.g., `## Premise` +
`## Themes & Ideas` → fiction-digest-v1). Inferred identifications auto-tagged
`needs_review`. Disambiguates book-digest vs source-digest via content indicators.

**Fix 3: Workflow guide — context contamination warning.**
Added guidance: clear NLM chat history when switching templates in the same notebook.
Discovered via chapter-digest-v1 validation — first run produced book-digest-v2 headings
due to prior query in the same NLM session. Updated workflow guide Step 2, troubleshooting.

**Template validation summary:**
| Template | Source | Verdict |
|---|---|---|
| fiction-digest-v1 | Crime and Punishment | PASS — all sections correct |
| book-digest-v2 | Wealth of Nations | Content PASS, sentinel FAIL → reinforced |
| chapter-digest-v1 | Wealth of Nations Ch.1-3 | PASS after clearing NLM history |
| source-digest-v2 | (3 E7 fixtures) | PASS — already validated |

### Session End

- **Duration:** Full session — project reactivation through template validation
- **Deliverables:** 4 new templates (book-digest-v2, source-digest-v2, chapter-digest-v1,
  fiction-digest-v1), parser enhancements (HTML tag stripping, heading-pattern fallback),
  sentinel reinforcement, workflow guide update, 6 fixtures (coverage gap closed)
- **State:** All enhancements landed. Ready for re-archive.
- **Compound:**
  1. NLM sentinel dropout is length-correlated — very long sources (390k+ words) push
     the instruction out of effective context. Mitigation: reinforced instructions +
     heading-pattern parser fallback. This is an NLM platform limitation, not fixable
     on our side. Pattern: any prompt instruction that relies on LLM compliance for
     machine-readability needs a fallback identification path.
  2. NLM context contamination across queries — prior output patterns leak into subsequent
     queries in the same notebook session. Mitigation: clear chat history between template
     switches. Pattern: stateful LLM sessions require explicit state hygiene between
     structurally different queries.
  3. Promoted template frontmatter pattern confirmed: `project: null`, `status: active`
     required on promotion. vault-check caught missing `status` field. Previously noted
     in session 2 compound — now validated as a recurring pattern worth checking
     automatically.

### Re-Archival

- **Date:** 2026-02-24
- **Reason:** Enhancement pass E1-E7 complete. All templates validated against real NLM runs.
  Parser hardened (HTML tags, heading-pattern fallback). Workflow guide updated.
- **Durable deliverables confirmed outside project folder:**
  - Templates (9): `_system/docs/templates/notebooklm/` (5 v1 + 4 new)
  - README + sentinel contract: same location
  - Inbox-processor NLM path: `.claude/skills/inbox-processor/SKILL.md`
  - Schema: `_system/docs/file-conventions.md`
- **What remains in project folder:** design docs (spec, enhancement spec, implementation
  plan), 11 fixtures (6 E7 + 5 validation), run-log, progress-log, workflow guide,
  project templates (development copies)
- **Not a KB exception** — standard archive to `Archived/Projects/`
- **Fixture inventory:** 11 total (was 2 at first archival)

  | Fixture | Template | Export Method |
  |---|---|---|
  | Rawls Theory of Justice | book-digest-v1 | copy-paste |
  | Huxley Perennial Philosophy | book-digest-v1 | Chrome extension |
  | Aeon moral courage essay | source-digest-v2 | copy-paste |
  | Pigliucci TEDx Stoicism | source-digest-v2 | copy-paste |
  | Degraded Pigliucci (messy) | source-digest-v2 | manufactured |
  | Clifford ethics of belief (short) | source-digest-v2 | copy-paste |
  | Crime and Punishment | fiction-digest-v1 | copy-paste |
  | Wealth of Nations | book-digest-v2 | copy-paste |
  | Wealth of Nations Ch.1 | chapter-digest-v1 | copy-paste |
  | Wealth of Nations Ch.2 | chapter-digest-v1 | copy-paste |
  | Wealth of Nations Ch.3 | chapter-digest-v1 | copy-paste |
  | Wealth of Nations batch (all ch.) | chapter-digest-v1 | copy-paste |

### Post-Archive: Batch Workflow Promotion

**Finding: Batch chapter-digest works without truncation for very long books.**
Wealth of Nations (390k words, 30+ chapters) produced complete batch output. NLM runs
on Gemini's 1M-token context window (~750k words capacity). Truncation is theoretical
for any real book — truncation recovery instructions retained as insurance only.

**Batch vs individual tradeoff:** Batch = shallower per chapter (bullet key points,
2 quotes) but full arc in one doc. Individual = paragraph key points, 3-5 quotes,
fuller analysis. Use batch first, drill into specific chapters with individual queries.

**Heading structure difference:** Batch uses `###` chapters + `**bold**` sub-sections.
Individual uses `##` chapters + `###` sub-sections. Parser handles both.

**Changes:** chapter-digest-v1 template updated — batch promoted to primary, individual
to deep-dive. Promoted copy updated. Fixture inventory: 12 total.

## 2026-02-24 — V2 Deferral Resolution

All 5 outstanding v2 deferrals reviewed with operator. Disposition:

1. **Media-specific frontmatter fields** (duration, timestamps) — **Struck.** No use case.
2. **Sources/ multi-tier structure** (sub-subdirectories) — **Moot.** Batch chapter-digest produces single combined file per book (2-3 files max). MOC system handles navigation.
3. **Source asset storage** (PDFs/audio alongside notes) — **Struck.** NLM is the interface to source material; no need for vault-side trackback.
4. **Data Tables export path** (NLM tables → Sheets → CSV → markdown) — **Parked indefinitely.** Operator has never used NLM Data Tables. Revisit only if analytical/fact-checking workflows emerge.
5. **Rate limit modeling** — **Struck.** No rate limit issues encountered across 12 fixtures and multiple validation runs.

**Result:** No outstanding work items. Project fully closed.
