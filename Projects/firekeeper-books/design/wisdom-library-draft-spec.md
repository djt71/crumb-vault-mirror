---
type: design
status: active
domain: creative
project: firekeeper-books
created: 2026-03-17
updated: 2026-03-17
---

# Wisdom Library — Phase 1 Capability Spec

**Project:** Wisdom Library
**Phase:** 1 — Premium Illustrated Ebook Editions
**Classification:** Internal • Danny + Crumb/Tess
**Date:** March 2026
**Status:** DRAFT  
**Parent doc:** side-hustle-research-brief-v0.2.md

---

## 1. Mission

Make foundational human wisdom beautiful and accessible again through premium illustrated digital editions of public domain texts. Monetization is the sustainability model, not the mission. Revenue validates that the work is reaching people.

---

## 2. Phase 1 Scope

Produce and publish beautifully designed, illustrated digital editions of public domain wisdom texts. Ebook only — audiobook and multilingual editions are deferred to Phase 2 and Phase 3 respectively.

### In Scope

- Source text acquisition and preparation (Project Gutenberg, Internet Archive)
- Series design system (typography, color palette, layout templates, illustration style guide)
- AI-generated original illustrations (10+ per title, KDP requirement)
- Cover design (series-consistent, AI-generated with human art direction)
- Ebook formatting and production (epub/mobi)
- Publishing to KDP (Amazon), Kobo, Google Play, Apple Books (via aggregator)
- Marketplace optimization (metadata, categories, keywords, description)
- Sales tracking and validation metrics

### Out of Scope (Deferred)

- Audiobook narration and production (Phase 2)
- Multilingual editions (Phase 3)
- Physical print editions
- Companion content (reading guides, annotations beyond what's in the edition)
- Marketing beyond marketplace presence (no paid ads, no social campaigns in Phase 1)

---

## 3. Validation Hypothesis

**Hypothesis:** A premium illustrated edition of a high-demand public domain wisdom text, priced at $4.99–$9.99, can generate meaningful sales despite the availability of free alternatives — differentiated by original illustrations, series design identity, and production quality.

**Validation criteria (measured over 60–90 days per title):**

| Metric | Minimum Viable | Strong Signal |
|--------|---------------|---------------|
| Unit sales (KDP) | 75+ (break-even at $4.99) | 200+ |
| Average rating | 3.5+ stars | 4.0+ stars |
| Organic rank in category | Top 100 in Philosophy > Stoicism | Top 50 |
| Reviews mentioning design/illustrations | Any | 3+ |
| Cross-platform sales (Kobo/Google/Apple) | Any | 20%+ of total |

**Go/no-go gate:** After 2–3 titles published and 60–90 days of data per title, evaluate whether to continue catalog expansion, adjust pricing/positioning, or pivot.

**Kill criteria:** If the first title generates <20 sales in 90 days with no review traction, the market hypothesis is invalidated at the current positioning. Reassess before investing in additional titles.

---

## 4. First Title: Meditations — Marcus Aurelius

### Why This Title

- Highest demand of any public domain philosophy text (265,280 Goodreads ratings)
- ~871 daily Project Gutenberg downloads
- 12-book structure provides natural illustration breakpoints
- Clear visual themes per book (nature, duty, mortality, impermanence, leadership)
- Stoic philosophy boom (Ryan Holiday's 10M+ books sold) creates sustained demand
- Competitive field is large but quality floor is low — most Kindle editions are minimal-effort

### Source Text

**Translation:** George Long (1862). Public domain in the US (pre-1928). Available via Project Gutenberg.

**Note:** The Long translation is serviceable but dated in style. This is acceptable for Phase 1 validation. If the market responds well, later editions could use other public domain translations or commission original translations (separate investment).

### Edition Structure (Preliminary)

- Series title page with brand identity
- Brief contextual introduction (original content — who was Marcus Aurelius, why this matters, how to read it)
- 12 books, each with:
  - Book title page with original illustration
  - Full text with clean typography
  - Optional: 1–2 interior illustrations at thematic moments
- Minimal footnotes (only where archaic language genuinely obscures meaning)
- About the series / catalog page at end

**Target illustration count:** 14–18 (12 book openers + cover + 2–4 interior pieces). Exceeds KDP's 10-illustration minimum.

---

## 5. Design System

### Series Identity

**Series name:** TBD. Needs to convey: wisdom, permanence, beauty, curation. Not "Classics" (overused). Not cute or clever. Should work across philosophy, literature, and spiritual texts.

**Design aesthetic:** "Scholarly warmth meets functional precision" — Danny's established design language.

- Serif-first typography (transitional or old-style serifs)
- Warm color palette (golds, deep blues, warm grays, cream backgrounds)
- Information density without clutter
- Consistent structural elements across titles (title page layout, chapter openers, margins, ornaments)

### Illustration Style Guide

**Style direction:** Needs to be defined through prototyping. Key considerations:

- Must be visually coherent across an entire title and across multiple titles in the series
- Should feel timeless, not trend-chasing (avoid hyperrealistic AI art aesthetic)
- Should complement rather than compete with the text
- Line art, woodcut-inspired, or watercolor styles may be more achievable at consistent quality than photorealistic imagery
- Each book's illustration should reflect its thematic content

**AI illustration tooling:** Midjourney (recommended by research for quality and consistency). Budget: $10–30/month.

**Critical open question:** Can Midjourney or similar tools produce a visually coherent series identity across 10+ illustrations within a single title, and across multiple titles? This must be validated through prototyping before committing to full production.

### Design Prototype Milestone

Before full production of the first title, produce:

1. Cover design concept (3 variations)
2. Title page layout
3. Chapter opener layout with illustration (for 2–3 of the 12 books)
4. Interior page spread showing text typography

**Purpose:** Validate that the design system works, that AI illustration can achieve the required consistency, and that the overall aesthetic justifies a premium price. This is a design gate — if the prototype doesn't look meaningfully better than existing editions, pause and reassess.

---

## 6. Production Pipeline

### Per-Title Workflow

| Step | Owner | Estimated Effort | Notes |
|------|-------|-----------------|-------|
| 1. Source text acquisition | Tess | <1 hour | Project Gutenberg download, clean text extraction |
| 2. Text preparation | Tess + Danny review | 2–4 hours | Formatting cleanup, structure verification, footnote decisions |
| 3. Introduction writing | Danny | 2–3 hours | Brief contextual intro (original content) |
| 4. Illustration generation | Tess + Danny art direction | 6–10 hours | AI generation with iterative prompting for consistency |
| 5. Cover design | Tess + Danny art direction | 2–4 hours | Series-consistent cover from template + title-specific art |
| 6. Ebook formatting | Tess | 2–4 hours | Epub generation using Calibre/Sigil or Atticus |
| 7. Quality assurance | Danny | 2–3 hours | Full read-through on Kindle app, formatting check, illustration review |
| 8. Marketplace listing | Tess + Danny review | 1–2 hours | Metadata, description, categories, keywords, pricing |
| 9. Publishing | Tess | <1 hour | Upload to KDP, Kobo, Google Play, Apple (via aggregator) |

**Estimated total per title:** 20–30 hours (first title higher due to design system setup; subsequent titles lower as templates and workflows stabilize)

**Estimated marginal cost per title:** $50–150 (AI illustration tooling + formatting tools)

### Pipeline Automation Targets

After the first title is produced manually with Tess assistance, identify which steps can be further automated for subsequent titles:

- Text acquisition and cleanup: highly automatable
- Illustration generation: semi-automatable (Tess generates, Danny approves)
- Cover design from template: highly automatable once template exists
- Ebook formatting: highly automatable once template exists
- Marketplace listing: semi-automatable (Tess drafts, Danny reviews)

**Target steady-state for titles 4+:** 10–15 hours per title, primarily illustration art direction and QA.

---

## 7. Distribution Strategy

### Platform Priority

| Platform | Priority | Royalty | Notes |
|----------|----------|---------|-------|
| KDP (Amazon) | Primary | 70% ($2.99–$9.99) | Largest ebook market. Direct upload. KDP Select (90-day exclusive) considered but not recommended — limits multi-platform strategy. |
| Kobo Writing Life | Secondary | 70% | Strong international presence (190+ countries). Direct upload. |
| Google Play Books | Secondary | 52% | Direct upload. Smaller market but growing. |
| Apple Books | Tertiary | 70% | Via aggregator (Draft2Digital). Worth having presence but lower priority. |

### Pricing Strategy

**Phase 1 starting price:** $4.99

**Rationale:** Low enough to be an impulse buy when compared to free alternatives, high enough to signal quality. At 70% KDP royalty minus delivery, nets ~$3.34 per sale. Break-even at ~45–75 sales depending on production cost.

**Pricing experiments (after first title data):** Test $6.99 and $9.99 on subsequent titles to measure price sensitivity. Penguin Classics editions price at $9.99 — that's the ceiling for public domain philosophy ebooks on Amazon.

### Marketplace Optimization

- **Categories:** Philosophy > Stoicism, Philosophy > Greek & Roman, Self-Help > Personal Growth (if applicable)
- **Keywords:** Research top-performing keywords for Meditations editions on KDP
- **Description:** Emphasize original illustrations, design quality, and series identity. Differentiate from the "another free Meditations" perception.
- **A+ Content (KDP):** If eligible, use enhanced product page with illustration samples

---

## 8. Conflict Safety Assessment

**Risk level:** Very Low (9/10 on evaluation framework)

Per Vector 5 research findings:

- Public domain content — no IP overlap with any employer
- No customer overlap with Infoblox
- No use of employer-confidential information
- No competitive threat to employer's business
- Passes the Strategic Independence Test cleanly
- Passes the plain-language test: "I publish illustrated editions of Marcus Aurelius in my spare time" raises zero eyebrows

**Recommended action:** Review Infoblox employment agreement to confirm no broad moonlighting restrictions. Consider informal disclosure if agreement requires it. Based on Vector 5 findings, this activity type (content creation in unrelated domain) represents the lowest-risk category across all case studies examined.

---

## 9. Entity & Legal Considerations

Per Vector 5 research:

- **LLC formation:** Recommended for liability protection and business credibility. Does not create IP separation but establishes clean business identity. Can be formed in Michigan or another state.
- **Tax:** Self-employment income. Consult accountant for quarterly estimated tax obligations once revenue starts.
- **AI art copyright:** Legally ambiguous. AI-generated illustrations may not be copyrightable, which means limited IP protection for the visual identity. Competitors could reuse illustration styles. This is a known risk, not a blocker — the brand and series consistency are the moat, not individual image copyrights.
- **KDP AI disclosure:** Required during title setup. Confidential — not shown to customers. Not a friction point.

---

## 10. Milestones

### M0: Design Prototype (Gate)

**Deliverables:**
- 3 cover design concepts for Meditations
- Title page and chapter opener layouts
- 2–3 sample AI illustrations in the chosen style
- Interior page typography sample

**Gate criteria:** Danny evaluates whether the design system produces something meaningfully better than existing Meditations editions on Amazon. If yes, proceed to M1. If no, iterate on design direction or reassess.

### M1: First Title Production

**Deliverables:**
- Complete Meditations edition (text, 14–18 illustrations, cover, formatted epub)
- Marketplace listings prepared (KDP, Kobo, Google Play, Apple)

### M2: First Title Published

**Deliverables:**
- Live on all four platforms
- Tracking dashboard set up (sales, rank, reviews)
- 60-day timer starts for validation measurement

### M3: Validation Assessment

**Deliverables:**
- 60–90 day sales and engagement data compiled
- Scored against validation criteria from Section 3
- Go/no-go decision on titles 2–3
- If go: select next titles from Tier 1 candidates (Enchiridion, Art of War, Tao Te Ching, Bhagavad Gita)
- If no-go: post-mortem analysis — what failed, is the hypothesis wrong or the execution?

### M4: Catalog Expansion (Conditional)

**Deliverables:**
- Titles 2–3 produced and published using refined pipeline
- Per-title production time and cost tracked for pipeline optimization
- Updated validation data across multiple titles

---

## 11. Candidate Title Pipeline

Based on Vector 7 research, ranked by composite strength:

### Tier 1 — First Candidates

| Title | Author | Translation | Structure | Visual Potential |
|-------|--------|-------------|-----------|-----------------|
| Meditations | Marcus Aurelius | George Long (1862) | 12 books | High — nature, duty, mortality themes |
| The Enchiridion | Epictetus | T.W. Higginson (1865) | Compact, 53 chapters | Medium — pairs with Meditations |
| The Art of War | Sun Tzu | Lionel Giles (1910) | 13 chapters | High — strategy, terrain, conflict |
| Tao Te Ching | Lao Tzu | James Legge (1891) | 81 short chapters | Very High — nature, water, emptiness |
| Bhagavad Gita | — | Edwin Arnold (1885) | 18 chapters | Very High — rich visual tradition |

### Tier 2 — After Validation

| Title | Author | Translation | Notes |
|-------|--------|-------------|-------|
| Letters from a Stoic | Seneca | Multiple pre-1928 | 124 letters, series-within-series potential |
| Discourses | Epictetus | George Long | Longer work, pairs with Enchiridion |
| The Republic | Plato | Benjamin Jowett (1871) | Foundational. 10 books. |

### Tier 3 — Expansion

| Title | Author | Translation | Notes |
|-------|--------|-------------|-------|
| The Analects | Confucius | James Legge (1861) | East Asian market potential |
| Thus Spoke Zarathustra | Nietzsche | Thomas Common (1909) | Highly visual, narrative structure |

---

## 12. Open Questions

1. **Series name.** What's the brand? This needs to be decided before M0 prototyping.
2. **AI illustration consistency.** Can we achieve it? M0 prototype will answer this.
3. **Infoblox employment agreement.** Danny needs to review specific IP and moonlighting clauses.
4. **Michigan invention statutes.** Is Michigan among the states with employee invention protection? (Not in the nine identified in Vector 5.)
5. **KDP Select vs. wide distribution.** KDP Select offers promotional tools (Kindle Unlimited, countdown deals) in exchange for 90-day Amazon exclusivity. Worth testing on the first title? Or go wide from day one?
6. **Aggregator selection.** Draft2Digital is the most commonly recommended for Apple Books access. Confirm terms and setup.
7. **Competitive purchase.** Buy and review 3–5 existing illustrated philosophy ebook collections on Amazon to calibrate quality expectations. (Recommended by Vector 7 research.)

---

## 13. Market Intelligence

- [[Sources/signals/erhardt-amazon-pod-enshittification|Amazon POD Enshittification]] — Amazon is replacing stock paperback editions with lower-quality print-on-demand copies at 50-80% price premiums. Affects Penguin Classics, Mariner, and bestselling philosophy titles. Creates differentiation opportunity: customers experiencing degraded physical quality are more receptive to premium digital alternatives with visible quality investment. Directly relevant to the Meditations market positioning and the "meaningfully better than existing editions" validation gate (M0).

## 14. Relationship to Other Projects

**Opportunity Scout (Project 1):** Wisdom Library Phase 1 operational data feeds the Scout's scoring model. Time spent, production friction, revenue data, and marketplace learnings all become calibration inputs for evaluating future opportunities.

**Remaining research vectors (V1–V4, V6):** Independent of Wisdom Library execution. Can be dispatched to the researcher skill in parallel. Their findings feed the Scout Mode project, not this one.

**Crumb infrastructure:** Production pipeline components (AI illustration orchestration, marketplace publishing workflows, sales tracking) may become reusable Crumb capabilities that serve other Execute Mode streams.
