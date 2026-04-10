---
project: batch-book-pipeline
domain: learning
type: design-doc
status: superseded
created: 2026-02-28
updated: 2026-02-28
---

# MOC Scaffolding & Batch-Import Readiness

> **Status: Superseded.** Reviewed in session 8. Core diagnosis correct (tag gaps, MOC gaps, debt concerns). Batch placement script withdrawn — pipeline already handles `topics` via `KB_TO_TOPIC`. Remaining work (tag expansion, MOC skeletons, Core placement script) executed directly. See run-log session 8 for decisions.

## Context

The batch-book-pipeline (BBP) is about to push ~200 knowledge notes into `Sources/books/` across BBP-005 (10 books → ~20 notes) and BBP-006 (90 books → ~180 notes). The current MOC system has 6 MOCs with 71 total entries. The pipeline writes notes with `#kb/` tags but has **zero awareness of `topics` or MOC placement** — it writes to `Sources/books/` and stops.

This means:
1. ~200 notes will land with `#kb/` tags but no `topics` field → vault-check errors on every one (Check 19)
2. No MOC Core entries will be created → knowledge is unnavigable
3. The debt score system will avalanche if we try to catch up naively

This doc proposes the pre-staging work needed before BBP-005 fires.

## Current State (from mirror, 2026-02-28)

### Existing MOCs (6)

| MOC | Type | Tag | Entries | Last Reviewed |
|-----|------|-----|---------|---------------|
| moc-history | orientation | kb/history | 50 | 2026-02-25 |
| moc-philosophy | orientation | kb/philosophy | 5 (4 in Core) | 2026-02-25 |
| moc-crumb-architecture | orientation | kb/software-dev | 8 | 2026-02-24 |
| moc-crumb-operations | operational | kb/software-dev | 5 | 2026-02-24 |
| moc-business | orientation | kb/business | 1 | 2026-02-25 |
| moc-writing | orientation | kb/writing | 2 | 2026-02-25 |

### Canonical `#kb/` Tags (14)
`religion` · `philosophy` · `gardening` · `history` · `inspiration` · `poetry` · `writing` · `business` · `dns` · `networking` · `security` · `software-dev` · `customer-engagement` · `training-delivery`

### What the Library Looks Like (from catalog session)
Rough domain distribution of the ~390 cataloged books:

| Domain | Approx. Books | Current MOC? | Current Tag? |
|--------|--------------|--------------|--------------|
| Buddhism / Zen / Spirituality | ~75 | ❌ | `kb/religion` |
| Philosophy (Western) | ~50 | ✅ moc-philosophy (5 entries) | `kb/philosophy` |
| History / Military history | ~40 | ✅ moc-history (50 entries) | `kb/history` |
| Fiction (classic + modern) | ~35 | ❌ | ❌ no tag |
| Biography / Memoir | ~15 | ❌ | ❌ no tag |
| Poetry | ~15 | ❌ | `kb/poetry` |
| Politics / Social criticism | ~20 | ❌ | ❌ no tag |
| Self-help / Psychology | ~15 | ❌ | `kb/inspiration`? |
| Nature / Gardening / Homesteading | ~10 | ❌ | `kb/gardening` |
| Technical (DNS, Make, coding) | ~10 | ✅ moc-crumb-* | `kb/software-dev` / `kb/networking/dns` |
| Art / Design / Visualization | ~5 | ❌ | ❌ no tag |
| Reference sets (Harvard Classics, etc.) | ~30 vols | — | multi-domain |

### Gaps Identified

**Tag gaps.** The canonical list doesn't cover several major domains in the library:
- **Fiction** — no tag. `kb/fiction`? Or route fiction through existing tags by theme (a Dostoevsky novel → `kb/philosophy`, Tolkien → ???)?
- **Biography / Memoir** — no tag. Could fold into `kb/history` but that's a stretch for, say, a Gandhi autobiography.
- **Politics / Social criticism** — no tag. `kb/politics`? Some will fit `kb/history`, others don't.
- **Psychology / Self-help** — no tag. `kb/inspiration` is the closest but doesn't capture Berne's *Games People Play* or Jung's *Man and His Symbols*.

**MOC gaps.** Major domains with no MOC:
- Religion/Buddhism (~75 books!) — needs at minimum `moc-religion`, probably sub-MOCs
- Poetry — has a tag but no MOC
- Fiction — has neither tag nor MOC

**Structural issue — MOC granularity for Buddhism.** 75 books is enormous for one MOC. The spec says split when a section exceeds 20 links. Options:
- A: Single `moc-religion` that gets split later when sections grow
- B: Pre-split into `moc-buddhism-zen`, `moc-buddhism-tibetan`, `moc-buddhism-theravada`, `moc-christianity`
- C: Hierarchical — `moc-religion` as parent, with sub-MOCs linked from its Paths section

## Proposal

### 1. Expand the Canonical Tag List

Add these Level 2 tags before BBP-005 runs (they need to be in the prompt's canonical list and in vault-check):

| New Tag | Covers | Rationale |
|---------|--------|-----------|
| `kb/fiction` | Classic and modern fiction | Distinct domain — theme extraction is different from nonfiction analysis |
| `kb/biography` | Biographies, memoirs, autobiographies | Lives as subjects, not events or ideas |
| `kb/politics` | Political theory, social criticism, activism | Overlaps history but distinct enough (Arendt, Ortega y Gasset, Snyder) |
| `kb/psychology` | Psychology, self-help, behavioral science | Berne, Jung, Cialdini, Kahneman-adjacent |

**Tags I'd hold off on:**
- `kb/art` — only ~5 books, under the 5-note MOC threshold. Tag if needed per-book as it comes.
- `kb/military-history` — could be a Level 3 subtopic (`kb/history/military`) rather than a new L2.

This brings the list to **18 canonical tags**. Update needed in: `vault-check.sh`, `CLAUDE.md`, `file-conventions.md`, and the BBP-002 prompt templates.

**Decision needed from you:** Do these 4 new tags feel right? Any I'm missing or any you'd rather fold into existing tags?

### 2. Create MOC Skeletons

**New MOCs to create (7):**

| MOC | Type | Tag | Location | Rationale |
|-----|------|-----|----------|-----------|
| `moc-religion` | orientation | kb/religion | Domains/Learning/ | ~75 books. Start coarse, split later per spec §5.6.7 (propose split when section >20 links). Internal sections for Buddhism/Zen, Tibetan, Christianity, Comparative/Other. |
| `moc-fiction` | orientation | kb/fiction | Domains/Learning/ | ~35 books. Sections by period or tradition (Classic, Modern, Sci-Fi/Fantasy). |
| `moc-biography` | orientation | kb/biography | Domains/Learning/ | ~15 books. Cross-domain figures. |
| `moc-politics` | orientation | kb/politics | Domains/Learning/ | ~20 books. Sections: Political theory, Social criticism, Activism/Resistance. |
| `moc-psychology` | orientation | kb/psychology | Domains/Learning/ | ~15 books. Sections: Behavioral science, Self-understanding, Persuasion/Influence. |
| `moc-poetry` | orientation | kb/poetry | Domains/Learning/ | ~15 books. Tag exists, MOC doesn't. |
| `moc-gardening` | orientation | kb/gardening | Domains/Learning/ | ~10 books. Tag exists, MOC doesn't. |

**Not creating (rationale):**
- `moc-inspiration` — only 1 entry currently, tag is vague. Let it grow organically.
- Sub-MOCs for Buddhism — premature. Let `moc-religion` accumulate entries first; sections within the MOC handle subdivision. Split when any section crosses 20 links (per spec). The synthesis pass will propose it when the time comes.

**Decision needed:** Agree with Option A (single `moc-religion` with internal sections) vs. Option B (pre-split sub-MOCs)?

### 3. Batch-Import Mode for Debt Score

**The problem:** If 200 notes land and we do placement immediately, every affected MOC's debt score spikes past 30 instantly. `moc-religion` alone would hit `75 × 3 = 225 points` — 7.5x the threshold. The system would scream for synthesis on every MOC simultaneously, which is expensive and premature (you haven't even reviewed the outputs yet).

**Proposed solution — `review_basis: bulk-import`**

Add a fourth `review_basis` value with a **0.0x multiplier** (debt = 0 during import):

| review_basis | Multiplier | Meaning |
|--------------|-----------|---------|
| `restructure` | 0.5x | Fresh structural review |
| `full` | 1.0x | Standard synthesis |
| `delta-only` | 1.5x | Quick skim |
| `bulk-import` | 0.0x | **Bulk intake — debt suppressed until manual reset** |

**Workflow:**
1. Before BBP-005: set all new MOC skeletons to `review_basis: bulk-import`
2. Run BBP-005 + BBP-006 → notes land in Sources/books/ with `#kb/` tags
3. Run a **batch placement script** (new) that:
   - Reads each new note's `#kb/` tags
   - Maps tags → MOC (using a simple tag→MOC lookup table)
   - Sets `topics` in the note's frontmatter
   - Inserts a one-liner in the target MOC's Core section
   - Does NOT touch `last_reviewed` or `notes_at_review` (those stay at import-time values)
4. User reviews a sample of outputs (quality, tag accuracy, placement accuracy)
5. When satisfied: manually flip each MOC from `bulk-import` to `full` and set `notes_at_review` to current Core count → debt starts accumulating normally from that baseline
6. Synthesis runs organically as debt crosses 30 on each MOC over time

**Alternative (simpler, no spec change):** Just temporarily raise the threshold from 30 to 999 during import, then lower it back. Avoids adding a new `review_basis` value. Less elegant but zero spec change.

**Decision needed:** New `review_basis` value, or temporary threshold override?

### 4. Batch Placement Script

This is the missing piece between the batch pipeline and the MOC system. A standalone script (or addition to `pipeline.py`) that runs *after* BBP output is written:

**Input:** All `.md` files in `Sources/books/` that have `#kb/` tags but no `topics` field.

**Logic (per file):**
1. Extract `#kb/` tags from frontmatter
2. Look up tag → MOC mapping (hardcoded table, ~18 entries)
3. For multi-tag notes: assign to all matching MOCs (most books will hit 1-2)
4. Add `topics: [moc-X, moc-Y]` to frontmatter
5. Insert one-liner in each target MOC's Core section:
   ```
   - [[source-id-index|Author: Title]] — core thesis summary | domain
   ```
   (One-liner text can be extracted from the digest's `## Core Thesis` section — first sentence, truncated to ~100 chars)
6. Bump MOC's `updated` field

**Tag → MOC mapping table:**

```yaml
kb/religion: moc-religion
kb/philosophy: moc-philosophy
kb/history: moc-history
kb/fiction: moc-fiction
kb/biography: moc-biography
kb/politics: moc-politics
kb/psychology: moc-psychology
kb/poetry: moc-poetry
kb/gardening: moc-gardening
kb/writing: moc-writing
kb/business: moc-business
kb/inspiration: moc-history        # fallback — reassign manually if needed
kb/networking/dns: moc-networking   # work-domain, not book-likely
kb/networking: moc-networking
kb/security: moc-crumb-operations
kb/software-dev: moc-crumb-architecture
kb/customer-engagement: moc-business
kb/training-delivery: moc-business
```

**Edge case — notes with no matching MOC:** Tag as `needs-placement` for manual review (consistent with inbox-processor behavior per §5.6.6).

**Edge case — multi-domain books:** A book like *Star Wars and Philosophy* gets `kb/philosophy` + `kb/fiction` → placed in both `moc-philosophy` and `moc-fiction`. This is fine — the `topics` field is an array, one-liners appear in both MOCs.

**Decision needed:** Build this as a standalone Python script in `_system/scripts/`, or integrate into `pipeline.py` as a `--place` post-processing flag?

### 5. Vault-Check Compliance Sequencing

The batch pipeline currently writes notes **without `topics`**. vault-check Check 19 will flag every one as an error. Two options:

**Option A — Pipeline adds `topics` (integrate placement into BBP-003)**
Modify `pipeline.py` to also set `topics` based on the tag→MOC table and insert MOC one-liners. This means vault-check passes immediately after pipeline runs.

**Option B — Two-step: pipeline writes notes, then placement script runs**
Pipeline stays focused on content generation. A separate placement pass handles MOC integration. vault-check will fail between the two steps, but that's fine if they run in the same session.

**Recommendation:** Option B. Keeps the pipeline script simple (it already does 16 things). The placement step is a distinct concern. The gap between pipeline output and placement is minutes, not days — vault-check failing briefly is acceptable.

## Execution Sequence

```
1. Tag expansion (4 new tags → vault-check, CLAUDE.md, file-conventions, BBP prompts)
2. MOC skeleton creation (7 new MOCs with bulk-import basis)
3. Batch placement script (new: _system/scripts/batch-moc-placement.py)
4. BBP-005 (10-book validation) → placement script → review
5. BBP-006 (90-book full batch) → placement script → review
6. Manual reset: flip MOCs from bulk-import → full, set notes_at_review baseline
7. Normal debt-driven synthesis resumes
```

Steps 1-3 are the pre-staging. Steps 4-7 are the execution flow.

## Open Questions for You

1. **New tags** — are `fiction`, `biography`, `politics`, `psychology` the right additions? Anything missing?
2. **Religion MOC granularity** — single `moc-religion` with sections, or pre-split into sub-MOCs?
3. **Debt suppression** — new `bulk-import` review_basis, or temporary threshold override?
4. **Placement script** — standalone `batch-moc-placement.py`, or `--place` flag in pipeline?
5. **One-liner generation** — extract first sentence of Core Thesis from the digest, or write generic placeholders for manual enrichment later?
6. **Source index notes** — the pipeline doesn't generate these either. Defer to a follow-up pass, or batch-generate alongside placement?
