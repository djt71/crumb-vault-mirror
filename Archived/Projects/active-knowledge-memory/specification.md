---
type: specification
status: active
domain: software
project: active-knowledge-memory
skill_origin: systems-analyst
created: 2026-03-01
updated: 2026-03-02
tags:
  - kb/software-dev
  - agent-memory
  - retrieval
  - knowledge-graph
topics:
  - moc-crumb-architecture
  - moc-crumb-operations
---

# Active Knowledge Memory — Specification

## 1. Problem Statement

The vault's knowledge base is passive — content is organized, tagged, and linked but only retrievable when you already know what to look for. As the KB scales (400+ book digests, feed-intel signal-notes, research artifacts, personal writing), relevant knowledge goes unused during active work because nothing connects what's stored to what's happening now. The system needs active surfacing that brings relevant KB content to the point of work — at session start, during task execution, and when new content arrives.

## 2. Why This Matters

Knowledge that doesn't participate in work is inventory, not capability. The vault is accumulating high-quality curated knowledge (biographical profiles, book digests, compound patterns, research output), but the investment only pays off if that knowledge influences decisions, enriches analysis, and prevents re-derivation of known ideas. Without active surfacing, the KB's value plateaus while its maintenance cost grows linearly — the worst possible scaling curve.

## 3. Facts, Assumptions, Unknowns

### 3.1 Facts

- **KB infrastructure is live:** 13 MOCs (4 populated: history/50, philosophy/12, crumb-architecture/8, crumb-operations/5; 9 empty skeletons), `#kb/` tag taxonomy with canonical L2 tags, `topics` field enforced by vault-check
- **KB corpus composition (measured 2026-03-01):** 43 notes in Sources/ (30 book notes across 10 books, 10 video notes across 5 sources, 2 article notes, 1 reference). 45 biographical profiles in Projects/think-different/. Tag distribution: `kb/philosophy` (26), `kb/history` (25), `kb/religion` (12), `kb/writing` (8), `kb/business` (8) — heavily weighted toward classical texts and history
- **Corpus scaling imminent:** Batch-book-pipeline is about to land ~300 book digests within ~1 week. This grows the KB from ~88 to ~350+ notes spanning history, philosophy, biography, business, spirituality, fiction, and software. The cross-domain connection problem becomes immediately testable against a real multi-domain corpus
- **Wikilink density is low:** Hub-and-spoke structure. MOCs link to source-indexes, source-indexes link to sibling digests, digests link nowhere. No cross-source wikilinks. Cross-domain connections exist only via shared `#kb/` tags and `topics` field — not wikilinks. This limits wikilink proximity as a v1 retrieval signal
- **No personal creative/reflective writing exists yet.** Domains/Creative/ contains only the overview stub. No `type: personal-writing`, journal entries, essays, or original reflective pieces in the vault. AKM-003 establishes the convention for when this content arrives
- **Vault-native query mechanisms exist:** Obsidian CLI supports tag queries, backlink queries, property queries, full-text search — all backed by Obsidian's SQLite FTS5 index. Measured performance (2026-03-01, ~375 indexed notes, M1 Mac): ~190ms per query. Compound queries supported via Obsidian search syntax (`tag:#kb/history "civil rights"`)
- **Feed-pipeline writes to KB, nothing reads back out:** The compound step, feed-pipeline skill, and inbox-processor all route content INTO the KB. No mechanism surfaces existing KB content during active work. No retrieval scripts exist in `_system/scripts/` — only write-path scripts (ingest, index generation, MOC placement)
- **Solutions-linkage proposal documents the same gap** at the solutions-doc level: patterns are captured but not consumed (see `_system/docs/solutions/solutions-linkage-proposal.md`)
- **Memory stratification pattern is established:** Markdown for knowledge, SQLite for operational state. LoCoMo benchmark (Maharana et al., 2024 — "Evaluating Very Long-Term Conversational Memory of LLM Agents"): file-system agents achieved 74% with basic operations, outperforming specialized memory tools
- **Vault snapshot exists but is KB-blind:** Captures project names, statuses, operator priorities — no KB content awareness
- **Bridge protocol is operational but governance-only:** No KB query or advisory channel exists for Tess
- **Tess has vault read access** (filesystem-level), but no structured mechanism to query or surface KB content
- **qmd is the v1 retrieval engine (decision 2026-03-02):** BM25 + vector embedding + neural reranker over markdown files (github.com/tobi/qmd, 11k+ stars). MCP server included. ~2GB model footprint (query expansion 1.7B + reranker 0.6B + embedding 300M). Production-validated by Artem Zhutov (5,700+ docs, 700 sessions, sub-second queries on Obsidian vault). CLI installation, collection-per-folder mapping, session-end hook for index freshness. See `design/qmd-v1-reference.md` for full analysis. Originally deferred as v2 candidate — promoted to v1 after production evidence and operator approval
- **sqlite-vec confirmed viable:** SQLite extension for ANN vector search, SIMD-accelerated on Apple Silicon, dependency-free. Right scale for this vault. Full-corpus embedding at current scale costs <$0.01 with text-embedding-3-small

### 3.2 Assumptions (to validate)

- A1: Vault-native queries (tag proximity, MOC membership, keyword matching) provide sufficient retrieval signal for useful surfacing at current KB scale (~150 notes). **Research note:** Wikilink proximity is a weak signal given current hub-and-spoke density — tag overlap and FTS5 keyword matching are the primary v1 retrieval mechanisms. Wikilink signal strengthens as the vault densifies. **Evaluation note:** With ~300 books landing within a week, A1 will be empirically testable against a real multi-domain corpus within 1-2 weeks. See FTS5 evaluation gate (§7) and `design/fts5-evaluation-note.md`
- A2: ~~Obsidian CLI query performance scales acceptably to 500+ notes (queries are index-backed, not file-scanning)~~ **Validated:** ~190ms per query at current scale, index-backed. No performance concern through 1000+ notes
- A3: Event-driven surfacing (specific trigger moments) is better than continuous background retrieval — bounds compute cost and attention load
- A4: A relevance budget (≤N items surfaced per trigger) prevents noise and keeps the system's signal-to-noise ratio high enough to avoid being ignored. **Research note:** Noise/ignored is confirmed as the primary risk across all studied systems (Smart Connections, Mem.ai, PKM literature). Asymmetric error preference — better to surface 2 highly relevant items than 5 mediocre ones. Empty results are acceptable and signal honesty
- A5: Creative/reflective writing can be reliably identified by vault convention (type field, tag, or directory location) without requiring manual per-note marking
- A6: MOCs serve as an effective compression layer for machine retrieval — 1 MOC provides the context of ~15 notes at 1 note's token cost

### 3.3 Unknowns

- ~~U1: Where does personal creative/reflective writing currently live in the vault?~~ **Resolved:** It doesn't exist yet. Convention needed for when it arrives (AKM-003). The personal writing boost is forward-looking, not retroactive
- U2: What's the right surfacing budget per trigger? (Likely 3-5 items — validate empirically)
- U3: ~~What embedding provider/model to use when v2 arrives?~~ **Narrowed:** OpenAI `text-embedding-3-small` (already configured, <$0.01 full-corpus cost) or `nomic-embed-text-v1.5` via Ollama (local-only, 8192-token context window — critical for long book digests). `bge-micro-v2` (Smart Connections default) is inadequate — 512-token window truncates most vault notes. Final selection deferred to AKM-008
- U4: Whether the vault's existing relationship graph (tags, MOCs, wikilinks, topics) provides enough signal for cross-domain concept matching, or if semantic similarity is needed even at current scale. **Research note:** BM25 misses concept-to-concept connections without lexical overlap (e.g., "Stoic negative visualization" → "software resilience mechanisms"). This is the primary gap v2 addresses
- U5: How to define "active focus" mechanically — which combination of project state, session history, and explicit priorities constitutes the context signal

## 4. System Map

### 4.1 Components

```
┌─────────────────────────────────────────────────────────────┐
│                    TRIGGER LAYER                            │
│  Session Start ─┐                                          │
│  Task Change   ─┼─→ Context Signal → Retrieval → Brief     │
│  New Content   ─┘         ↑              ↑          │      │
│                           │              │          ↓      │
│                    Active Focus    KB Index    Consumer     │
│                    Extractor     (v1: vault   (Crumb skill │
│                                  v2: +embed)  or Tess)     │
└─────────────────────────────────────────────────────────────┘
```

**Context Signal Extractor** — Determines what's relevant right now. Inputs: active project states, current task description, operator priorities, session history. Output: a structured context signal (keywords, tags, concepts).

**Retrieval Engine** — Takes a context signal, queries the KB, returns ranked matches. v1: QMD (BM25 + semantic + hybrid search over vault collections, CLI mode). BM25 as primary mode for structured notes; semantic/hybrid for cross-domain concept matching. Interface is stable; configuration evolves (mode selection, collection scoping, ranking weights).

**Knowledge Brief** — Compact, budgeted output format. Contains: note paths, relevance scores, one-line summaries, source category (personal writing flagged). Sized for context injection without blowing token budgets.

**Trigger Integrations** — Modifications to existing skills, hooks, and pipelines that call the retrieval engine at the right moments. Not new skills or workflows — composable augmentation.

### 4.2 Dependencies

**Depends on:**
- knowledge-navigation — MOC structure, `topics` field, vault-check enforcement
- feed-intel-framework — new content flow (signal-notes arriving via feed-pipeline)
- Obsidian CLI — indexed queries (tag, backlink, property, search)
- vault-check — schema enforcement for any new conventions

**Depended on by (future):**
- Any skill that would benefit from KB context at activation
- Tess awareness functions (advisory KB surfacing)
- Solutions-linkage mechanism (may be subsumed by this system)

### 4.3 Constraints

- **Ceremony Budget Principle:** Must reduce friction, not add it. No recurring manual actions required to operate AKM during normal sessions. Acceptable maintenance: one-time setup, automated evaluation, and occasional tuning triggered only by measured failure (noise/ignored). Surfacing itself is fully automatic.
- **Context budget:** Surfaced content must fit within existing skill context budgets (≤5 source docs). The brief format must be compact — point to notes, don't reproduce them.
- **Curation boundary:** Crumb curates, Tess advises. Tess may receive and flag KB connections. Tess does not create, tag, or modify KB content.
- **Scale range:** Must work at ~150 notes (today) and remain viable at 1000+ notes. Architecture must accommodate embedding-based retrieval without rewrite.
- **Infrastructure separation:** Index artifacts (embedding vectors, retrieval caches) live outside the vault content tree. The vault remains human-meaningful content. `_system/data/` or similar — not `_system/docs/`.
- **Fully local retrieval:** QMD runs locally with local models (~2GB). No external API calls for retrieval. Embedding is handled by QMD's built-in models, not external services.

### 4.4 Levers (High-Impact Intervention Points)

1. **MOCs as compression layer** — Querying MOC Core sections gives concept-level context at a fraction of the token cost of querying individual notes. A single MOC read can inform whether its member notes are relevant.
2. **Existing vault relationships** — Tags, wikilinks, `topics` field, and MOC membership are all free signal. No new indexing infrastructure needed to start getting value.
3. **Event-driven triggers** — Bounding when surfacing runs (3 specific moments, not continuous) keeps compute cost proportional to user actions, not KB size.
4. **Relevance budget** — Capping surfaced items (e.g., top 5) prevents noise accumulation as KB grows.
5. **Personal writing boost** — Type-based relevance weighting lets the system prioritize the highest-value material without complex ranking.

### 4.5 Second-Order Effects

- **Solutions-linkage becomes less critical:** If the retrieval engine surfaces relevant solutions docs during skill activation, the `required_context` / `consumed_by` mechanism from the solutions-linkage proposal is partially subsumed. Evaluate during PLAN whether to pursue both or let this system handle the read-back path.
- **MOC maintenance incentivized:** If MOCs are retrieval targets, keeping them current has direct operational value — strengthens the case for knowledge-navigation Phase 4 automation.
- **Feed-pipeline gains downstream value:** Signal-notes promoted into the KB immediately participate in surfacing, closing the loop from content capture → curation → active use.
- **Risk: ignored if noisy:** If surfacing produces irrelevant results, it becomes another thing to scroll past. The budget cap and relevance threshold are critical safeguards. A "relevance miss" feedback mechanism may be needed.
- **Risk: context pressure:** Surfaced content competes with task-specific context for the limited context window. The brief format must be genuinely compact.

## 5. Domain Classification & Workflow

- **Domain:** software
- **Project class:** system (vault infrastructure, no external code repo needed — scripts live in `_system/scripts/`)
- **Workflow:** SPECIFY → PLAN → TASK → IMPLEMENT (full four-phase)
- **Rationale:** Cross-cutting system capability affecting session startup, skill activation, and content pipeline. Multiple components, architectural decisions, and integration points. Needs careful design before implementation to avoid adding ceremony.

## 6. Surfacing Modality

Each trigger has a distinct interaction pattern. This is a design principle, not just a scheduling detail — it determines how the retrieval output is delivered to the consumer.

| Trigger | Modality | Behavior | Analogy |
|---------|----------|----------|---------|
| Session start | **Proactive** | Knowledge brief is pushed — included in startup output, displayed to the operator | Morning briefing |
| Task context change | **Ambient** | Knowledge brief is loaded during skill context gathering, used at agent discretion, not displayed to operator. In CLI/agent context, "ambient" means injected into the context-gathering step — it consumes tokens but is not pushed as a visible output. Agent uses it if relevant, ignores if not | Obsidian backlinks panel |
| New content arrival | **Batched** | Connections are logged, not surfaced immediately. Tess aggregates and delivers at natural breakpoints (daily digest, next Telegram conversation) | Chief of staff batching observations |

**Design implication:** The retrieval engine is the same for all three. The trigger integrations differ in how they deliver the output. Proactive = display. Ambient = load silently. Batched = write to a log/scratch file for Tess to pick up.

**Trigger overlap handling:** When multiple triggers fire in the same session (e.g., session start followed by skill activation, or new content arriving mid-session), deduplicate surfaced notes by path. A note surfaced at session start is not re-surfaced at skill activation unless the context signal has changed. Across triggers within a session, maintain a union of surfaced paths and suppress duplicates.

## 7. Phased Delivery

The three triggers ship sequentially. Each validates a different layer of the system before the next adds complexity.

**Milestone 1: Session Start** — Proves the retrieval engine works. Validates context signal extraction, vault-native query quality, knowledge brief format, and relevance filtering. Low risk — session start is a natural context-loading moment.

**Milestone 2: Skill Activation** — Proves mid-session integration works. Validates ambient delivery (available but not pushed), context budget interaction, and skill procedure modification. Medium risk — modifies existing skill procedures.

**Milestone 3: New Content** — Proves the Tess advisory path works. Validates batched delivery, cross-agent knowledge flow, and the feed-pipeline → KB → surfacing loop. Highest risk — involves cross-agent coordination.

**QMD Mode Evaluation Gate** — After Milestone 1 ships and the book pipeline lands (~300 books, ~1 week), execute a structured evaluation of QMD's three search modes (BM25, semantic, hybrid) against the real corpus. 10-15 pre-designed test queries covering cross-domain concept matching, within-domain relevance, and noise rate. Determines default mode selection per trigger type. See `design/fts5-evaluation-note.md` for protocol structure (to be updated for QMD modes). The evaluation plan is designed during PLAN; execution happens post-book-landing.

**QMD configuration (AKM-008)** proceeds immediately after AKM-004 installation. **Mode tuning (AKM-009)** is informed by evaluation gate results.

## 8. Task Decomposition

### Foundation

**AKM-001: Define active-focus signal format** `#decision` `#research`
- Define the mechanical structure of "active focus" — what fields, what sources, what format
- Sources to evaluate: project-state.yaml (phase, next_action), operator_priorities.md, current task description, recent run-log entries, session-startup output
- Output: a YAML or structured format that the retrieval engine consumes
- Risk: **medium** — foundational decision; wrong abstraction here propagates
- Acceptance criteria: Format documented, at least 2 example signals generated from real vault state, format supports all 3 trigger types
- File changes: 1 design doc

**AKM-002: Define knowledge brief output format** `#decision`
- Define the compact output format for surfaced KB content
- Must include: note path, relevance signal summary, one-line description, content category (personal writing flag)
- Must fit within context injection budget (target: ≤500 tokens for 5 items)
- Define summary production method for one-line descriptions: frontmatter `summary` → first non-heading paragraph → title + matched terms (no LLM calls in v1)
- Risk: **low** — output format, easily iterable
- Acceptance criteria: Format documented, sample brief generated from real KB content using the summary production chain, token count verified
- File changes: 1 design doc

**AKM-003: Establish personal writing convention** `#decision` `#writing`
- Determine how creative/reflective writing is identified in the vault
- Options: `type: personal-writing` in frontmatter, `#kb/writing` tag with personal subtag, dedicated directory
- Must be discoverable by retrieval queries without scanning every file
- Convention established now; ranking boost activates automatically when corpus reaches threshold (PLAN pins N to a concrete number — e.g., 5 or 10 — so the boost activates without someone remembering to flip a switch)
- Risk: **low** — convention choice, backward-compatible
- Acceptance criteria: Convention documented in file-conventions.md, vault-check rule added if needed, auto-activation threshold defined, existing personal writing (if any) tagged
- File changes: 2-3 (convention doc, vault-check, existing files)

### Vault-Native Retrieval (v1)

**AKM-004: Build retrieval engine on QMD** `#code`
- Install QMD, create vault collections (Sources/, Projects/, Domains/, _system/docs/), initial index build
- Script: `_system/scripts/knowledge-retrieve.sh` — wrapper that translates context signals into QMD queries
- Input: context signal (from AKM-001 format)
- Query methods: `qmd search` (BM25) as primary, `qmd vsearch` (semantic) for cross-domain, `qmd query` (hybrid) for ranked results. Collection scoping per query
- Ranking: QMD's native relevance scoring + post-filter for personal writing boost (off by default, activates automatically when ≥N personal-writing notes exist — PLAN pins N), category-aware relevance (no uniform temporal decay)
- Result diversity: max 1 item per source (book/video), max 2 per tag cluster. Prefer overview+specific mix when available
- Summary production for brief entries: (1) frontmatter `summary` field if present, (2) first non-heading paragraph heuristic, (3) fallback: note title + matched terms. No LLM calls
- Output: knowledge brief (from AKM-002 format), budgeted to N items
- Index freshness: session-end hook to re-index changed files (pattern from Artem's setup)
- Risk: **medium** — core logic, quality determines system usefulness. QMD installation is low-risk (brew/cargo, local models)
- Acceptance criteria: QMD installed and indexing vault, returns relevant results for 3+ test context signals, respects budget cap, results are diverse (no 5-of-same-source), personal writing ranks higher when boost is active, completes in <5s at current KB scale
- Depends on: AKM-001, AKM-002, AKM-003
- File changes: 2-3 (QMD config, retrieval wrapper script, session-end hook update)

**AKM-005: Integrate at session start** `#code`
- Modify session-startup hook or add a post-startup step
- Generate context signal from active projects + operator priorities
- Call retrieval engine, include knowledge brief in startup output
- Brief appears in startup summary as "Relevant knowledge: [items]"
- Include automatic feedback capture: log which surfaced notes were subsequently read during the session (no manual rating step — implicit signal only)
- Risk: **medium** — touches critical startup path
- Acceptance criteria: Knowledge brief appears in session startup output, does not slow startup by more than 3s, gracefully degrades if Obsidian CLI unavailable, feedback logging is automatic and zero-ceremony
- Depends on: AKM-004
- File changes: 1-2 (startup script/hook)

**AKM-006: Integrate at skill activation** `#code`
- Modify systems-analyst and action-architect skill procedures to call retrieval engine during context gathering (step 1)
- Context signal derived from task/project context
- Brief injected as "KB context" alongside existing context inventory
- Include automatic feedback capture: log which surfaced notes were subsequently read during the skill invocation
- Risk: **medium** — modifies skill procedures
- Acceptance criteria: Relevant KB notes surfaced during SPECIFY and PLAN phases, context budget respected (brief counts against doc budget), no regression in skill output quality, feedback logging is automatic
- Depends on: AKM-004
- File changes: 2-4 (skill definitions)

**AKM-007: Integrate on new content arrival** `#code`
- Modify feed-pipeline skill to call retrieval engine after promoting a signal-note
- Context signal = the newly promoted note's content/tags/topics
- If relevant existing KB content found, append a "Related knowledge" section to the run-log entry
- Optionally: flag cross-domain connections for compound evaluation
- Risk: **low** — additive behavior on existing pipeline
- Acceptance criteria: When a signal-note is promoted that relates to existing KB content, the connection is logged. False positive rate acceptable (≤1 irrelevant connection per 5 promotions)
- Depends on: AKM-004
- File changes: 1-2 (feed-pipeline skill)

### QMD Mode Evaluation Gate

**AKM-EVL: Evaluate QMD search modes against real corpus** `#research` `#decision`
- Design 10-15 test queries before book pipeline lands, covering: cross-domain concept matching (critical), within-domain relevance (baseline), noise rate
- Execute evaluation after ~300 books land in the KB
- Run each query in all three QMD modes: `qmd search` (BM25), `qmd vsearch` (semantic), `qmd query` (hybrid)
- Relevance rubric per result: relevant (directly useful) / somewhat (tangentially related) / irrelevant. "Miss" = no relevant result in top 5
- Score each query per mode: relevant results found, relevant results missed, irrelevant results returned
- Tiered decision criteria (per-mode):
  - BM25-only sufficient (>75% cross-domain hit rate) → use BM25 as default, semantic on-demand
  - BM25 misses >25% cross-domain → hybrid as default mode
  - All modes miss >40% → investigate collection mapping, indexing config, or query translation
- Test queries designed as blinded fixtures: expected relevant notes documented before running retrieval
- The evaluation plan is designed during PLAN phase; execution is a TASK-phase checkpoint
- Risk: **medium** — informs default mode selection; bad test design leads to wrong config
- Acceptance criteria: Test queries documented pre-landing with expected results, evaluation executed post-landing, default mode selected with data within 1-2 weeks of books arriving
- Depends on: AKM-004 (QMD must be installed and indexed), book pipeline completion (external dependency)
- File changes: 1 evaluation results doc

### QMD Configuration & Tuning

**AKM-008: Configure QMD collections and indexing** `#code`
- Map vault directories to QMD collections (see `design/qmd-v1-reference.md` for proposed mapping)
- Configure embedding model selection (QMD bundles query expansion 1.7B + reranker 0.6B + embedding 300M)
- Set up incremental re-indexing strategy (session-end hook + scheduled full rebuild)
- Evaluate collection granularity: coarse (4 collections) vs fine (per-project, per-domain)
- Risk: **low** — configuration, not architecture. QMD handles storage/indexing natively
- Acceptance criteria: All vault content indexed, re-indexing hook functional, collection scoping tested with sample queries
- Depends on: AKM-004 (QMD installation)
- File changes: 1-2 (QMD config, indexing script)

**AKM-009: Tune QMD mode selection and ranking** `#decision`
- Determine default search mode per trigger type (BM25 for structured queries, hybrid for cross-domain)
- Calibrate result count and relevance threshold per mode
- Design post-QMD ranking adjustments: personal writing boost, category-aware weighting
- Fallback behavior when QMD is unavailable (graceful degradation to Obsidian CLI FTS5)
- Risk: **low** — tuning informed by AKM-EVL empirical results
- Acceptance criteria: Default mode per trigger documented, ranking adjustments specified, fallback tested
- Depends on: AKM-EVL (mode evaluation data), AKM-008
- File changes: 1 design doc

### Cross-Agent (Tess Advisory)

**AKM-010: Design Tess KB advisory mechanism** `#decision`
- How Tess receives KB context for advisory surfacing
- Options to evaluate with decision matrix (pros/cons/risk):
  - (a) Tess calls retrieval engine directly via vault read access
  - (b) Retrieval engine writes a "KB brief" file to `_openclaw/tess_scratch/` that Tess reads (simplest, no protocol extension)
  - (c) Bridge protocol extension for KB queries
- Must respect curation boundary — Tess flags, Crumb acts
- Define Tess-visible surface area: which directories, tags, and note types Tess can access for KB advisory (exclude any future private/journal content)
- Define Tess context signal derivation: how Tess determines what to query (her current advisory task vs. Crumb's current working context)
- Risk: **medium** — cross-agent architecture, boundary enforcement
- Acceptance criteria: Mechanism documented with decision matrix, curation boundary preserved, delivery path specified, **boundary enforcement test defined** (e.g., "Tess output contains no create/edit/tag suggestions"), no new bridge protocol message types unless necessary
- Depends on: AKM-004
- File changes: 1-2 (design doc, potentially bridge protocol doc)

**AKM-011: Implement Tess-facing surfacing** `#code`
- Implement the mechanism designed in AKM-010
- Risk: **medium** — cross-agent integration
- Acceptance criteria: Tess can access KB context relevant to her current work, curation boundary verified (Tess reads only, does not modify KB), mechanism works with existing Tess session flow
- Depends on: AKM-010, AKM-004
- File changes: 2-3

### Validation

**AKM-012: End-to-end validation** `#research` `#code`
- Test all three trigger points with real vault state
- Measure: relevance hit rate (target: ≥1 useful item per surfacing event, ≥60% of the time), performance (target: <5s per retrieval), context pressure (target: brief ≤500 tokens)
- Evaluate: does this reduce re-derivation? Does it surface connections the operator wouldn't have found manually?
- Collect feedback on noise level — if surfacing is being ignored, recalibrate
- Risk: **low** — validation, not implementation
- Acceptance criteria: 3+ real sessions with surfacing active, hit rate measured, performance measured, operator feedback collected
- File changes: 1 (validation results doc)

### Dependency Graph

```
AKM-001 ─┐
AKM-002 ─┼─→ AKM-004 ─┬─→ AKM-005 (session start) ─→ AKM-EVL (FTS5 gate)
AKM-003 ─┘             ├─→ AKM-006 (skill activation)     ↓
                        ├─→ AKM-007 (new content)    gates v2 timeline
                        ├─→ AKM-010 → AKM-011 (Tess advisory)
                        └─→ AKM-012 (validation)

AKM-008 (QMD config, after AKM-004) → AKM-009 (tuning, after AKM-EVL)
```

**Note:** AKM-EVL depends on AKM-004 + book pipeline landing (external). AKM-008 (QMD config) proceeds immediately after AKM-004. AKM-009 (tuning) is informed by AKM-EVL mode comparison results.

## 9. Success Criteria

Drawn from the problem statement's desired outcomes, made testable:

1. **Relevant knowledge surfaces without being asked for.** At least 1 of N surfaced items is relevant in ≥60% of surfacing events across 10+ sessions.
2. **Personal writing is treated as highest-value.** When a personal writing note is relevant to the current context, it ranks in the top 3 of surfaced items.
3. **Both agents benefit.** Crumb receives KB briefs during skill activation. Tess can access KB context for advisory purposes.
4. **Scales with the KB.** Retrieval completes in <5s at 150 notes. Architecture supports embedding-based retrieval for 1000+ notes without rewrite.
5. **Cross-domain connections are recognized.** System surfaces notes from domains other than the active project's domain when conceptually relevant (e.g., a philosophy note surfaced during a software design session).
6. **No operational ceremony added.** No recurring manual actions required during normal sessions. Surfacing is fully automatic. One-time setup and occasional tuning triggered by measured failure are acceptable.
7. **Not ignored.** After 10 sessions, the operator hasn't disabled or started skipping the knowledge brief.

## 10. Design Constraints Adopted

**Maintenance gravity (from companion notes analysis):** Adopted as a first-class design requirement. Every mechanism must pass: "does this make the system more pleasant to use, or does it add another thing to maintain?" If the answer is the latter, redesign or cut it.

**Category-aware relevance (from companion notes):** No uniform temporal decay. Personal writing, philosophical insights, and conceptual frameworks don't lose relevance with age. Operational notes and news-derived content may decay. The ranking model must distinguish content categories.

**Composability (from companion notes):** This augments existing skills and phases — it does not introduce new workflows, skills, or approval gates. The retrieval engine is infrastructure; the trigger integrations are modifications to existing procedures.

## 11. Research-Informed Design Notes

These findings from research should inform PLAN-phase decisions.

**Existing Obsidian plugins don't solve this problem.** Smart Connections, Omnisearch, Smart Second Brain — all are passive (show connections for the open note) or interactive (type a query). None support event-driven, context-derived retrieval called from outside Obsidian's plugin boundary. The Obsidian CLI's SQLite backend is the right layer to target directly.

**QMD is the v1 retrieval engine (updated 2026-03-02).** Originally deferred as v2 due to 2GB model footprint. Promoted to v1 after production evidence (Artem Zhutov: 5,700+ docs, 700 sessions, sub-second queries on Obsidian vault at comparable scale). The 2GB footprint is negligible on Apple Silicon. QMD ships BM25 + semantic + hybrid — eliminates the need to build a custom FTS5→embedding progression. BM25 handles ~80% of structured-note searches; semantic/hybrid adds cross-domain concept matching that FTS5 cannot provide. CLI mode via Bash tool; MCP server deferred to post-AKM-012 evaluation. See `design/qmd-v1-reference.md` for full analysis. Obsidian CLI FTS5 retained as fallback when QMD is unavailable.

**Hybrid retrieval (v2) should use RRF, not linear combination.** Reciprocal Rank Fusion avoids the score normalization problem between BM25 and vector similarity scores. No training data required. Anthropic's contextual retrieval technique (prepend context to chunks before embedding) reduced failed retrievals by 49-67% in their published evaluation (anthropic.com/news/contextual-retrieval, September 2024; results on specific benchmark datasets — actual improvement at vault scale may differ). Worth implementing when building the embedding index.

**Chunking strategy for embedding:** Strip YAML frontmatter. Embed short notes whole (<512 tokens). Embed long notes (book digests) by H2 section with title prepended. Apply contextual retrieval at embedding time (~50-100 token context per chunk, negligible cost at this scale).

**The solutions-linkage proposal may be subsumed.** If the retrieval engine surfaces relevant solutions docs during skill activation (AKM-006), the `required_context` / `consumed_by` mechanism becomes unnecessary. Evaluate during Milestone 2 empirical results.

## 12. Out of Scope

- Custom embedding infrastructure (QMD handles embeddings natively)
- Replacing manual MOC maintenance (knowledge-navigation Phase 4)
- Modifying the curation boundary (Crumb curates, Tess advises — unchanged)
- Building a standalone graph database (the vault IS the graph)
- Continuous/background knowledge monitoring (event-driven triggers only)
- User-facing UI or dashboard (output is context injection into existing interfaces)
