---
type: action-plan
project: active-knowledge-memory
domain: software
skill_origin: action-architect
status: draft
created: 2026-03-02
updated: 2026-03-02
tags:
  - akm
  - knowledge-retrieval
  - qmd
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Active Knowledge Memory — Action Plan

## Overview

This action plan decomposes the AKM specification (v1, QMD-based) into implementation
milestones covering 11 active tasks (AKM-001 through AKM-009, AKM-EVL, AKM-012).
AKM-010 (Tess KB design) and AKM-011 (Tess implementation) are deferred to a future
milestone. AKM-007 writes a brief to `_openclaw/tess_scratch/` as a lightweight
pre-answer — revisit after AKM-012.

The core problem: the vault's KB (43 sources, 45 profiles, 13 MOCs, ~300 books landing)
is passive — content only surfaces when you already know to look. AKM adds three
retrieval triggers (session start, skill activation, new content) using QMD as the
search engine.

**Spec reference:** `Projects/active-knowledge-memory/design/specification.md`

---

## Pinned Decisions

Decisions resolved during SPECIFY, carried forward as constraints.

**D1. Personal writing threshold: N = 3.** Three notes triggers the ranking boost.
Low enough to activate quickly, high enough to be meaningful. Trivial to adjust later.

**D2. Active focus signal schema:**

```yaml
focus:
  projects:                        # from project-state.yaml (all active)
    - name: <project>
      phase: <phase>
      domain: <domain>
      next_action: "<text>"
  priorities: ["<from operator_priorities.md>"]
  keywords: ["<derived from projects + priorities>"]
  tags: ["kb/<relevant>"]
  trigger: session-start|skill-activation|new-content
  trigger_context: null            # skill/new-content populates this
```

**D3. Per-trigger SLOs:** Session start < 3s, skill activation < 2s, new content < 5s.

**D4. Category-aware decay (post-QMD ranking multiplier):**

| Category | kb/ tags | Half-life |
|----------|----------|-----------|
| Timeless | philosophy, religion, biography, poetry, writing, creative, fiction, inspiration, history, psychology | none |
| Reference | software-dev, dns, networking, security | 2 years |
| Slow | politics, business, lifestyle | 1 year |
| Fast | customer-engagement, training-delivery | 3 months |
| Signal-notes | (type: signal-note) | 1 month |

Formula: `weight = 0.5 ^ (age_days / half_life_days)`. Multi-tag notes use slowest decay.

**D5. Ranking post-filter order:** (1) decay weight, (2) personal writing boost (+0.3
normalized, when ≥ 3 notes), (3) diversity (max 1 per source, max 2 per L2 tag cluster),
(4) budget truncation (5 items session-start, 3 skill-activation, 5 new-content).

**D6. MOC staleness fallback:** Informational flag when MOC `last_reviewed` > 6 months.
No automated action.

---

## M1: Foundation + Session Start

**Spec reference:** §4 (system map), §5 (focus signal), §6 (ranking), §8.1–8.5, §8.8
**Task range:** AKM-001 through AKM-005, AKM-008
**Goal:** Prove retrieval works end-to-end. Operator sees a knowledge brief at session startup.

### Success Criteria

1. QMD installed, 4 collections indexed, `knowledge-retrieve.sh` returns relevant results
2. Session startup includes knowledge brief (0–5 items)
3. Retrieval < 3s, graceful degradation if QMD unavailable
4. Feedback logging automatic (zero ceremony)
5. Focus signal schema implemented with 3+ worked examples validated against real vault state
6. Brief format produces ≤ 500 tokens for 5 items
7. `type: personal-writing` convention documented in file-conventions.md

### Key Risks

| Risk | Level | Mitigation |
|---|---|---|
| QMD CLI flags differ from assumptions | Medium | Verify all flags against `qmd --help` before scripting (CLI hallucination protocol) |
| Ranking quality poor on first pass | Medium | Request 15–20 results, post-filter to budget — tuning in M3 |
| Startup path regression | Medium | KB section isolated — errors don't break existing startup |
| QMD unavailable (not installed, broken) | Low | Graceful skip with log message |

### Work Packages

**WP-1: Design foundations** (AKM-001, AKM-002, AKM-003 — parallel)

Three independent design documents, executable in parallel:

- **AKM-001: Define active-focus signal format**
  - File: `design/focus-signal-format.md`
  - Document schema (D2), write 3 worked examples from real vault state
  - Risk: Medium (foundational — downstream tasks consume this)

- **AKM-002: Define knowledge brief format**
  - File: `design/brief-format.md`
  - Structured text (not YAML). Entry: `[rank] path -- summary (tag-cluster)`
  - Summary chain: frontmatter `summary` → first non-heading paragraph (120 chars) → title + matched terms
  - Sample from 5 real KB notes, verify ≤ 500 tokens for 5 items
  - Risk: Low

- **AKM-003: Establish personal writing convention**
  - Files: `_system/docs/file-conventions.md` (update type taxonomy), `Domains/Creative/writing/` (create directory)
  - `type: personal-writing` in frontmatter. Auto-activation: `knowledge-retrieve.sh` counts notes with this type, activates boost at ≥ 3
  - Risk: Low

**WP-2: Retrieval engine** (AKM-004 — depends on WP-1)

- **AKM-004: Build retrieval engine on QMD**
  - Files: `_system/scripts/knowledge-retrieve.sh` (new), session-end hook addition
  - Approach: (1) Install QMD — verify flags against `qmd --help` per CLI hallucination warning. (2) Create 4 collections: sources, projects, domains, system. (3) Build wrapper: parse focus signal → construct QMD queries → apply post-filter (D4/D5) → format brief. `--json` QMD output for parsing. (4) Add `qmd update` to session-end sequence
  - Risk: Medium (core logic — ranking quality is everything)

**WP-3: Integration + collection config** (AKM-005, AKM-008 — depends on WP-2)

- **AKM-005: Integrate at session start**
  - File: `_system/scripts/session-startup.sh` (new section after existing inbox scans, before display block ~line 283)
  - Build focus signal from active project-state.yaml + operator_priorities.md → call `knowledge-retrieve.sh` → include brief in startup summary
  - Failure isolated (KB section error doesn't break startup)
  - Feedback: session-end diffs read-files against surfaced paths → `_system/logs/akm-feedback.jsonl`
  - Risk: Medium (critical startup path — but additive, not modifying existing sections)

- **AKM-008: Configure QMD collections and indexing**
  - File: `design/qmd-collections.md`
  - Evaluate collection granularity (answer: 4 coarse collections for v1). Test scoped vs cross-collection queries. Configure incremental re-indexing. Document strategy
  - Risk: Low

---

## M2: Skill Activation (Ambient Delivery)

**Spec reference:** §5 (focus signal), §8.6
**Task range:** AKM-006
**Goal:** KB brief loaded silently during systems-analyst and action-architect context gathering.
**Depends on:** M1 complete (AKM-004 operational)

### Success Criteria

1. Both skills include KB brief in context inventory
2. Brief counts as 1 doc against context budget
3. Retrieval < 2s
4. No regression in skill output quality
5. Skill modifications are additive sub-steps (no existing steps removed or reordered)

### Key Risks

| Risk | Level | Mitigation |
|---|---|---|
| Skill procedure regression | Medium | Additive sub-step only; test with 2–3 real invocations |
| Brief noise degrades skill output | Low | Budget of 3 items limits exposure; diversity filter prevents clustering |

### Work Package

**WP-4: Skill integration** (AKM-006)

- **AKM-006: Integrate at skill activation**
  - Files: `.claude/skills/systems-analyst/SKILL.md`, `.claude/skills/action-architect/SKILL.md`
  - After existing KB tag search (systems-analyst line 35, action-architect line 33), add sub-step: derive focus signal from project context + task → call `knowledge-retrieve.sh --trigger skill-activation` → include in context inventory as 1 doc against budget. Ambient: loaded, not displayed
  - Risk: Medium (modifies skill procedures — but additive sub-step)

---

## Evaluation Gate: QMD Mode Comparison (AKM-EVL)

**Spec reference:** §4.3 (QMD modes), §8.10
**Depends on:** AKM-004 (engine operational), book pipeline (~300 books — 296 already in Sources/books/)
**External dependency:** Book pipeline landing. 296 books already present; may be unblocked.

### Test Query Design (during TASK phase)

- 5–7 cross-domain concept queries (e.g., "software resilience" → expect Stoic philosophy)
- 3–5 within-domain queries (baseline)
- 2–3 noise baseline queries (common terms, measure irrelevant results)
- Blinded fixtures: expected results documented before running retrieval

### Decision Criteria

- BM25 > 75% cross-domain recall → BM25 default
- BM25 misses > 25% cross-domain → hybrid default
- All modes miss > 40% → investigate indexing or query construction

### Work Package

**WP-5: Mode evaluation** (AKM-EVL)

- **AKM-EVL: QMD mode evaluation**
  - File: `design/qmd-mode-evaluation.md`
  - Design 10–15 blinded test queries during TASK. Execute all 3 modes post-books. Score: relevant/somewhat/irrelevant. Apply decision criteria
  - Risk: Medium (wrong test design → wrong config)

---

## M3: New Content + Tuning + Validation

**Spec reference:** §8.7, §8.9, §8.12
**Task range:** AKM-007, AKM-009, AKM-012
**Goal:** Complete third trigger, apply empirical tuning, validate the whole system.
**Depends on:** M1 + M2 complete, AKM-EVL complete

### Success Criteria

1. Feed-pipeline logs "Related knowledge" on promotion, cross-domain matches flagged
2. Default QMD mode per trigger documented with empirical data
3. FTS5 fallback operational when QMD unavailable
4. 3+ real sessions: hit rate ≥ 60%, performance < 5s, brief ≤ 500 tokens
5. Trigger deduplication working (same item not surfaced by multiple triggers in one session)
6. Noise level acceptable (< 2 irrelevant items per brief)
7. Assessment: does AKM-006 subsume solutions-linkage proposal?

### Key Risks

| Risk | Level | Mitigation |
|---|---|---|
| EVL data inconclusive | Medium | Default to hybrid if unclear; revisit with more data |
| Validation sessions too few | Low | Extend to 5 sessions if borderline |
| Feed-pipeline integration disrupts existing flow | Low | Additive step after existing promotion |

### Work Packages

**WP-6: New content trigger** (AKM-007 — depends on AKM-004)

- **AKM-007: Integrate on new content arrival**
  - File: `.claude/skills/feed-pipeline/SKILL.md`
  - After Step 5.7 (delete source from inbox): build focus signal from promoted note's tags/content → call `knowledge-retrieve.sh --trigger new-content` → if results, append "Related knowledge" to run-log entry. Cross-domain flagged for compound. Write brief to `_openclaw/tess_scratch/kb-brief-latest.md` (lightweight Tess path)
  - Risk: Low (additive)

**WP-7: Tuning** (AKM-009 — depends on AKM-EVL, AKM-008)

- **AKM-009: Tune mode selection and ranking**
  - Files: `_system/scripts/knowledge-retrieve.sh` (config update), `design/qmd-tuning-decisions.md`
  - Set default mode per trigger from EVL data. Calibrate result count (request 15–20, post-filter to budget). Test decay weights. Define fallback to Obsidian CLI FTS5 when QMD unavailable
  - Risk: Low (data-informed)

**WP-8: Validation** (AKM-012 — depends on AKM-005, AKM-006, AKM-007, AKM-009)

- **AKM-012: End-to-end validation**
  - File: `design/validation-results.md`
  - 3+ real sessions, all triggers active. Measure: hit rate (≥ 60%), performance (< 5s), token budget (≤ 500), trigger deduplication, noise level
  - Evaluate whether AKM-006 subsumes solutions-linkage proposal
  - Risk: Low

---

## Dependency Graph

```
AKM-001 ─┐
AKM-002 ─┼─→ AKM-004 ─┬─→ AKM-005 ──────────────────────┐
AKM-003 ─┘      │      ├─→ AKM-008 ──┐                    │
                 │      ├─→ AKM-006   │                    │
                 │      └─→ AKM-007   │                    │
                 │                    │                    │
                 └─→ AKM-EVL ────→ AKM-009 ──→ AKM-012 ←─┘
                       ↑                         ↑
                  book pipeline            AKM-006, AKM-007
```

**Critical path:** AKM-001/002/003 → AKM-004 → AKM-EVL (books) → AKM-009 → AKM-012

---

## Deferred Tasks (tracked)

| Task | Description | Activation Signal |
|---|---|---|
| AKM-010 | Tess KB design — design what Tess needs from AKM | After AKM-012 validates system; assess whether AKM-007 tess_scratch brief suffices |
| AKM-011 | Tess implementation — OpenClaw integration | After AKM-010 design approved |

---

## Session Estimate

1. AKM-001 + AKM-002 + AKM-003 (parallel foundation)
2. AKM-004 (QMD install + wrapper — largest task)
3. AKM-005 + AKM-008 (session start + collection config)
4. AKM-006 + AKM-007 (skill activation + new content)
5. AKM-EVL (if books landed)
6. AKM-009 + AKM-012 (tuning + validation)

~6 sessions for core system.

---

## Critical Notes

- **CLI hallucination warning applies:** Verify all `qmd` command flags against `qmd --help` during AKM-004. Do not commit CLI commands to scripts without verification
- **Session-end protocol update:** Document `qmd update` addition in `_system/docs/protocols/session-end-protocol.md`, not just the script
- **Solutions-linkage evaluation:** During AKM-012, assess whether skill-activation retrieval (AKM-006) subsumes the `required_context`/`consumed_by` proposal
- **AKM-007 as lightweight Tess path:** Writing to `tess_scratch` during new-content may satisfy AKM-010/011 requirements. Evaluate during AKM-012
