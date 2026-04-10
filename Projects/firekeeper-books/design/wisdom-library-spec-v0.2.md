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
**Status:** DRAFT v0.2  
**Parent doc:** side-hustle-research-brief-v0.2.md  
**Changelog:**
- v0.3 — Broadened scope beyond philosophy to include fiction, drama, poetry, and narrative nonfiction. Restructured title pipeline with genre diversity. Updated mission, scope, and series identity language. Replaced single-tool Midjourney recommendation with comparative evaluation framework (Midjourney, Nano Banana 2, DALL-E) at M0.
- v0.2 — Resolved open questions (translation, series name, distribution, legal, competitive), elevated illustration gate, refined pricing strategy, added pre-M0 competitive audit task.

---

## 1. Mission

Make foundational works of human thought and imagination beautiful and accessible again through premium illustrated digital editions of public domain texts — philosophy, fiction, drama, poetry, and narrative nonfiction. The catalog spans from the Greek tragedies to early 20th-century literature. Monetization is the sustainability model, not the mission. Revenue validates that the work is reaching people.

---

## 2. Phase 1 Scope

Produce and publish beautifully designed, illustrated digital editions of public domain texts across genres — philosophy, fiction, drama, poetry, and narrative nonfiction. The unifying thread is not genre but quality and endurance: these are texts that have shaped how people think, feel, and see the world. Ebook only — audiobook and multilingual editions are deferred to Phase 2 and Phase 3 respectively.

### In Scope

- Source text acquisition and preparation (Project Gutenberg, Internet Archive, Standard Ebooks, Wikisource)
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

**Hypothesis:** A premium illustrated edition of a high-demand public domain text, priced at $4.99–$9.99, can generate meaningful sales despite the availability of free alternatives — differentiated by original illustrations, series design identity, and production quality.

**Validation criteria (measured over 60–90 days per title):**

| Metric | Minimum Viable | Strong Signal |
|--------|---------------|---------------|
| Unit sales (KDP) | 75+ (break-even at $4.99) | 200+ |
| Average rating | 3.5+ stars | 4.0+ stars |
| Organic rank in category | Top 100 in relevant subcategory | Top 50 |
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

**Primary translation:** C.R. Haines (1916), from the Loeb Classical Library edition. Public domain in the US (published pre-1928). Available via Wikisource and Internet Archive.

**Rationale:** The spec previously defaulted to George Long (1862), which is the most widely available public domain translation. However, Long's Victorian prose style is a genuine liability for a product positioned as "premium and accessible." Readers accustomed to the Hays translation (2002, under copyright) will find Long's language stiff and archaic. The Haines translation reads more naturally while remaining scholarly, and carries the credibility of the Loeb Classical Library. It is also less commonly used in the flood of low-effort Kindle editions that default to Long, providing a small but real differentiation point.

**Alternates considered:**

- **George Long (1862):** Most widely available. Faithful but dated Victorian English. Used by the vast majority of free and low-cost Kindle editions — using it puts us in direct visual-quality competition with a hundred near-identical products. Retained as fallback.
- **G.W. Chrystal (1902):** Somewhat more readable than Long, but less well-known and harder to source cleanly.
- **A.S.L. Farquharson (1944):** Excellent scholarly translation with commentary. Public domain status depends on jurisdiction — published in the UK, author died 1942, so public domain in life+70 jurisdictions. In the US, the 1944 publication date means it entered public domain on January 1, 2040 under current law. **Not available for Phase 1.**
- **Gerald H. Rendall (1898):** Available but less fluid than Haines.

**Action item:** Before committing, obtain the Haines text from Wikisource/Internet Archive, do a side-by-side read of 2–3 books against Long, and confirm the readability improvement justifies the switch. If Haines proves too academic in tone, fall back to Long with a stronger editorial introduction that frames the archaic language.

### Edition Structure

- Series title page with brand identity
- Brief contextual introduction (original content — who was Marcus Aurelius, why this matters, how to read it)
- A note on the translation (brief — which translation, why, how to read 1900s-era English)
- 12 books, each with:
  - Book title page with original illustration
  - Full text with clean typography
  - Optional: 1–2 interior illustrations at thematic moments
- Minimal footnotes (only where archaic language genuinely obscures meaning)
- About the series / catalog page at end

**Target illustration count:** 14–18 (12 book openers + cover + 2–4 interior pieces). Exceeds KDP's 10-illustration minimum.

---

## 5. Series Identity

### Series Name: Hearthlight Editions

**Rationale:** Conveys warmth (hearth) and illumination (light) without being precious or overused. Works equally well across philosophy, fiction, drama, poetry, and nonfiction — it doesn't pigeonhole into any single genre. Avoids "Classics" (saturated), "Library" (institutional), and "Press" (implies a larger operation). The compound word has a handcrafted feel that aligns with the "scholarly warmth" aesthetic. Domain availability and trademark clearance should be verified before committing — this is a working name pending that check.

**Backup candidates (if Hearthlight has conflicts):**
- Hearthstone Editions (gaming connotation risk — Blizzard's card game)
- Lanternlight Editions
- Cornerstone Editions

**Action item:** Check trademark databases (USPTO TESS) and domain availability for "Hearthlight Editions" before M0.

### Design Aesthetic

"Scholarly warmth meets functional precision" — Danny's established design language.

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

**AI illustration tooling:** To be determined through M0 comparative evaluation. The spec does not lock into a single tool. The leading candidates as of March 2026:

- **Midjourney (V7):** The strongest option for stylized, artistic illustration. Style Reference feature enables locking an aesthetic across a series with minimal drift. Mature prompt ecosystem. Weakness: Discord-based workflow can be clunky; character consistency across scenes requires workarounds. $10–30/month subscription.
- **Google Nano Banana 2 (Gemini 3.1 Flash Image):** Launched February 2026. Strong character consistency (up to 5 characters maintained across a workflow), fast iteration, and free through the Gemini app. Particularly compelling for fiction titles where the same characters appear across multiple illustrations (e.g., Odysseus across 12 scenes). Weakness: optimized more for photorealism and social content than for the timeless artistic styles (woodcut, watercolor, line art) this project requires. Less mature for tight art direction compared to Midjourney.
- **DALL-E (via ChatGPT):** Conversational editing loop is low-friction. Good for iterative refinement. Weakness: character identity can drift across longer sequences; less stylistic range than Midjourney.

**M0 will include a comparative evaluation:** Run the same 3–4 illustration prompts (covering both philosophical/abstract and narrative/scenic subjects) through all three tools. Evaluate against these criteria specific to this project:

1. **Timeless aesthetic** — Does it look like book illustration, or does it look like "AI art"? The hyperrealistic, oversaturated AI look is disqualifying.
2. **Cross-illustration coherence** — Can the tool produce 4+ images that feel like they belong in the same book?
3. **Style-lock capability** — Can you establish a visual language and reproduce it reliably across prompts?
4. **Character consistency** (for fiction titles) — Can the same character be recognizably maintained across different scenes?
5. **Prompt fidelity** — Does the tool follow specific compositional and stylistic instructions, or does it "create boldly" in ways that fight your art direction?

A combined workflow is also possible — e.g., Midjourney for establishing the visual style and generating initial concepts, Nano Banana 2 for maintaining character consistency across a fiction title's illustration series. The M0 evaluation should test both single-tool and combined approaches.

**Budget:** $10–30/month (Midjourney subscription) + $0 (Nano Banana 2 via Gemini free tier) + $0 (DALL-E via existing ChatGPT). Total tooling cost remains minimal regardless of which tool wins.

### Design Prototype Milestone (Hard Gate)

Before full production of the first title, produce:

1. Cover design concept (3 variations)
2. Title page layout
3. Chapter opener layout with illustration (for 2–3 of the 12 books)
4. Interior page spread showing text typography

**This is a hard gate, not a soft checkpoint.** If the prototype does not demonstrate:
- Visual coherence across 3+ illustrations in a consistent style
- A design system that is meaningfully and obviously superior to the top 5 existing Meditations editions on Amazon
- Illustration quality that justifies a premium price to a skeptical buyer

...then production does NOT proceed. The illustration consistency question is the single highest technical risk in Phase 1. If none of the evaluated tools can produce a coherent visual series from a style guide and structured prompts, the entire value proposition collapses. Better to discover this before investing 20+ hours in a full title.

**Fallback if gate fails:** Consider commissioning a human illustrator for key pieces (cover + 12 book openers) and using AI only for interior spots. This changes the cost model significantly (~$500–1500 vs. ~$30) but may be the only path to the required quality bar.

---

## 6. Production Pipeline

### Per-Title Workflow

| Step | Owner | Estimated Effort | Notes |
|------|-------|-----------------|-------|
| 1. Source text acquisition | Tess | <1 hour | Project Gutenberg / Wikisource download, clean text extraction |
| 2. Text preparation | Tess + Danny review | 2–4 hours | Formatting cleanup, structure verification, footnote decisions |
| 3. Introduction writing | Danny | 2–3 hours | Brief contextual intro (original content) |
| 4. Illustration generation | Tess + Danny art direction | 6–10 hours | AI generation (tool per M0 evaluation) with iterative prompting for consistency |
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

### Platform Priority & Approach

**Decision: Go wide from day one. Do not use KDP Select.**

**Rationale:** The validation hypothesis tests whether a premium illustrated edition can generate organic sales. KDP Select's promotional tools (Kindle Unlimited reads, countdown deals, free promotion days) would juice numbers in ways that contaminate the signal. Kindle Unlimited reads in particular count as "sales" but represent a fundamentally different buyer behavior — KU subscribers browse and sample freely, which inflates volume without validating willingness to pay. Going wide from day one produces cleaner data, avoids 90-day exclusivity lock-in, and tests multi-platform viability immediately.

| Platform | Priority | Royalty | Approach |
|----------|----------|---------|----------|
| KDP (Amazon) | Primary | 70% ($2.99–$9.99) | Direct upload. No KDP Select. |
| Google Play Books | Secondary | 52% | Direct upload. Smaller market but growing. |
| Kobo Writing Life | Secondary | 70% | Direct upload. Strong international (190+ countries). |
| Apple Books | Tertiary | 70% | Via Draft2Digital (see aggregator decision below). |

### Aggregator Decision: Draft2Digital

**Decision:** Use Draft2Digital for Apple Books distribution. Direct-upload to KDP, Google Play, and Kobo.

**Rationale:** At Phase 1 volumes (1–3 titles, low initial sales), Draft2Digital's commission model (10% of list price from royalties) costs less than PublishDrive's subscription model ($14–17/month minimum). D2D's commission only costs money when books sell, which is the right risk profile for validation. D2D does not distribute to Google Play — that's handled via direct upload. If the catalog grows beyond 5–10 titles with consistent sales, revisit PublishDrive for its higher per-book royalties and broader distribution network.

**D2D cost at $4.99 price point:** ~$0.50 per sale via D2D channels. Acceptable for validation phase.

### Pricing Strategy

**Phase 1 starting price:** $5.99

**Rationale (revised from $4.99):** The competitive audit (see Section 12) reveals that the Kindle Meditations landscape is bimodal: free/$0.99 minimal-effort editions, and $9.99+ premium editions (Penguin, Modern Library). $4.99 sits uncomfortably close to the low end and may signal "slightly better free" rather than "premium." $5.99 creates more distance from the free tier while remaining an impulse buy. At 70% KDP royalty minus delivery, nets ~$3.84 per sale. Break-even at ~40–60 sales depending on production cost.

**Pricing experiments (after first title data):** Test $7.99 and $9.99 on subsequent titles to measure price sensitivity. $9.99 is the ceiling — that's Penguin Classics territory and requires brand credibility the series hasn't earned yet.

### Marketplace Optimization

- **Categories:** Philosophy > Stoicism, Philosophy > Greek & Roman, Self-Help > Personal Growth (if applicable)
- **Keywords:** Research top-performing keywords for Meditations editions on KDP (use Publisher Rocket or manual research)
- **Description:** Emphasize original illustrations, design quality, and series identity. Differentiate from the "another free Meditations" perception. Lead with the visual experience, not the text.
- **A+ Content (KDP):** If eligible, use enhanced product page with illustration samples. This is a significant differentiator — most competitors don't use A+ Content.

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

### Michigan Invention & Moonlighting Law

**Finding:** Michigan does not have an employee invention protection statute. The nine states with explicit statutory protections for employee inventions developed on personal time are: California, Delaware, Illinois, Kansas, Minnesota, New Jersey, North Carolina, Washington, and (as of recently) New York. Michigan is not among them.

**What this means practically:** In Michigan, employee IP rights default to common law principles and whatever the employment agreement says. The key common law doctrines are:

- **Shop right doctrine:** An employer gets a non-exclusive license to use an invention if the employee used employer resources to develop it.
- **Hired to invent:** If an employee was specifically hired to invent, the employer owns the invention.
- **Scope of employment:** Inventions related to the employer's business, developed during work hours or with employer resources, are at risk of employer claims.

**Assessment for Wisdom Library:** None of these doctrines apply. Publishing illustrated ebooks of ancient philosophy is entirely unrelated to DDI/DNS security. No Infoblox resources, time, equipment, or trade secrets are involved. The risk is effectively zero from an IP-claim perspective. The remaining risk is contractual — if the Infoblox employment agreement contains a broad moonlighting disclosure or approval requirement, that's a procedural obligation to fulfill, not a substantive risk.

**Action item (unchanged):** Danny needs to review the specific IP assignment and moonlighting clauses in the Infoblox employment agreement. This is a 15-minute task. Do it before M0.

### LLC Formation

Recommended for liability protection and business credibility. Does not create IP separation but establishes clean business identity. Michigan LLC formation is straightforward and inexpensive (~$50 filing fee). Can be done any time before first revenue, but ideally before publishing the first title so the publisher name on KDP matches the LLC.

### Tax

Self-employment income. Consult accountant for quarterly estimated tax obligations once revenue starts. At Phase 1 volumes, this is likely negligible, but the structure should be set up correctly from the start.

### AI Art Copyright

Legally ambiguous. AI-generated illustrations may not be copyrightable under current US Copyright Office guidance, which means limited IP protection for the visual identity. Competitors could potentially reuse illustration styles. This is a known risk, not a blocker — the brand, series consistency, and curation are the moat, not individual image copyrights.

### KDP AI Disclosure

Required during title setup. Confidential — not shown to customers. Not a friction point.

---

## 10. Milestones

### Pre-M0: Competitive Audit

**Deliverables:**
- Purchase and review 3–5 existing illustrated philosophy ebooks on Amazon (budget: ~$25–40)
- Purchase and review 2–3 existing illustrated fiction/drama ebooks (e.g., illustrated Frankenstein, Odyssey, or Dante editions) to calibrate cross-genre quality expectations
- Document: price point, illustration count and quality, typography, formatting, review themes
- Identify specific quality gaps the Hearthlight edition can exploit
- Calibrate the "meaningfully better" bar for the M0 design gate

**This is not optional.** You cannot evaluate whether your design prototype is "meaningfully better than existing editions" if you haven't looked at the existing editions carefully. The competitive purchase should happen before any illustration prototyping begins.

### M0: Design Prototype (Hard Gate)

**Deliverables:**
- AI illustration tool comparison: same 3–4 prompts run through Midjourney, Nano Banana 2, and DALL-E, evaluated against the five criteria in §5 (timeless aesthetic, cross-illustration coherence, style-lock, character consistency, prompt fidelity)
- Tool selection decision documented with rationale
- 3 cover design concepts for Meditations (using selected tool/workflow)
- Title page and chapter opener layouts
- 2–3 sample illustrations in the chosen style
- Interior page typography sample
- Side-by-side comparison against competitive audit findings

**Gate criteria:** Danny evaluates against the competitive audit baseline. The prototype must be visually superior in a way that would be immediately obvious to a casual browser on the Amazon product page. If the illustration consistency is not achievable, the project pauses for reassessment (see fallback in Section 5).

### M1: First Title Production

**Deliverables:**
- Complete Meditations edition (text, 14–18 illustrations, cover, formatted epub)
- Marketplace listings prepared (KDP, Kobo, Google Play, Apple via D2D)

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

Ranked by composite strength: demand (Goodreads ratings, Gutenberg downloads), visual potential for illustrated edition, structural suitability (natural illustration breakpoints), and competitive gap (how much room exists above the current quality floor on Kindle).

The pipeline spans philosophy, fiction, drama, poetry, and narrative nonfiction. The first title is philosophy (Meditations) because the research vectors that initiated this project were Stoicism-focused and the competitive analysis is furthest along there. But fiction and drama titles are not secondary — many are *more* suited to illustrated editions than philosophy, because they offer richer visual material (scenes, characters, landscapes, dramatic moments) and broader audience appeal.

### Tier 1 — First Candidates (Titles 1–5)

| Title | Author/Source | Genre | Translation/Edition | Visual Potential | Notes |
|-------|--------------|-------|-------------------|-----------------|-------|
| Meditations | Marcus Aurelius | Philosophy | C.R. Haines (1916) | High — nature, duty, mortality themes | First title. Research furthest along. |
| The Odyssey | Homer | Epic Poetry/Fiction | Samuel Butler (1900) prose or A.T. Murray (1919) | Very High — monsters, gods, sea voyages, homecoming | Enormous demand. Naturally episodic. Each book is a set piece. |
| Frankenstein | Mary Shelley | Fiction | 1818 text (public domain) | Very High — creation, isolation, arctic landscapes, the creature | #1 on Gutenberg downloads. Gothic visual aesthetic. |
| Divine Comedy: Inferno | Dante Alighieri | Epic Poetry/Fiction | Henry Wadsworth Longfellow (1867) | Extraordinary — every canto is a distinct visual scene | Rich illustration tradition (Doré, Blake, Botticelli). 34 cantos = 34 illustration opportunities. |
| The Enchiridion | Epictetus | Philosophy | T.W. Higginson (1865) | Medium — pairs with Meditations | Compact. Natural Stoic companion piece. |

### Tier 2 — After Validation (Titles 6–12)

| Title | Author/Source | Genre | Translation/Edition | Visual Potential | Notes |
|-------|--------------|-------|-------------------|-----------------|-------|
| The Art of War | Sun Tzu | Philosophy/Strategy | Lionel Giles (1910) | High — strategy, terrain, conflict | Crossover appeal beyond philosophy readers. |
| Tao Te Ching | Lao Tzu | Philosophy/Spiritual | James Legge (1891) | Very High — nature, water, emptiness | 81 short chapters. Minimalist illustration style opportunity. |
| Bhagavad Gita | — | Philosophy/Spiritual | Edwin Arnold (1885) | Very High — rich visual tradition | "The Song of God." Established illustration precedent in Hindu art. |
| Dracula | Bram Stoker | Fiction | Original (1897) | Very High — Gothic horror, Transylvania, Victorian London | Massive demand. Epistolary structure offers unique design opportunities. |
| The Picture of Dorian Gray | Oscar Wilde | Fiction | Original (1890/1891) | High — decadence, portraits, Victorian aesthetics | Shorter novel. Strong thematic visual hooks. |
| Greek Tragedies (collected) | Sophocles, Euripides, Aeschylus | Drama | Various pre-1928 | Very High — Oedipus, Antigone, Medea, the chorus | Could be a collected volume or individual plays. Extraordinary visual drama. |
| Heart of Darkness | Joseph Conrad | Fiction | Original (1899) | High — river journey, jungle, colonial horror | Short. Intense. Visually atmospheric. |

### Tier 3 — Catalog Expansion

| Title | Author/Source | Genre | Translation/Edition | Visual Potential | Notes |
|-------|--------------|-------|-------------------|-----------------|-------|
| Moby-Dick | Herman Melville | Fiction | Original (1851) | Extraordinary — whaling, ocean, the white whale | Long but visually rich. Chapter structure provides many breakpoints. |
| Les Misérables | Victor Hugo | Fiction | Isabel Hapgood (1887) | Very High — revolutionary Paris, redemption, characters | Massive work. Could be multi-volume. |
| The Iliad | Homer | Epic Poetry/Fiction | Samuel Butler (1898) prose | Very High — war, gods, heroes, Troy | Pairs with Odyssey. |
| Letters from a Stoic | Seneca | Philosophy | Multiple pre-1928 | Medium | 124 letters, series-within-series potential. |
| The Republic | Plato | Philosophy | Benjamin Jowett (1871) | Medium | Foundational. 10 books. Allegory of the Cave is strong visual moment. |
| The Analects | Confucius | Philosophy | James Legge (1861) | Medium | East Asian market potential. |
| Thus Spoke Zarathustra | Nietzsche | Philosophy/Fiction | Thomas Common (1909) | High — narrative structure, mountain imagery | More fiction than philosophy in form. |
| The Dhammapada | — | Philosophy/Spiritual | Multiple pre-1928 | Medium-High | Buddhist wisdom tradition. Danny's personal connection. |
| Crime and Punishment | Dostoevsky | Fiction | Constance Garnett (1914) | High — psychological intensity, St. Petersburg | Classic psychological fiction. |
| A Tale of Two Cities | Dickens | Fiction | Original (1859) | Very High — French Revolution, London/Paris duality | Strong dramatic scenes. |
| Metamorphoses | Ovid | Poetry/Mythology | Various pre-1928 | Extraordinary — every myth is a visual scene | Nearly inexhaustible illustration material. |
| The Strange Case of Dr Jekyll and Mr Hyde | Stevenson | Fiction | Original (1886) | High — duality, Victorian London, transformation | Short novella. Strong visual concept. |
| Beowulf | — | Epic Poetry | Multiple pre-1928 | Very High — monsters, warriors, mead halls | Anglo-Saxon visual aesthetic opportunity. |
| Paradise Lost | John Milton | Epic Poetry | Original (1667) | Extraordinary — Heaven, Hell, Eden, angels, Satan | Rich illustration tradition (Doré, Blake). |

### Selection Criteria for Pipeline Prioritization

When choosing the next title to produce, weight these factors:

1. **Visual potential** — Does the text offer rich, concrete illustration opportunities? Fiction and narrative poetry generally score higher than abstract philosophy.
2. **Demand signal** — Goodreads ratings, Gutenberg downloads, Amazon search volume. Proxy for how many people are actively looking for this text.
3. **Competitive gap** — How bad are the existing Kindle editions? A crowded field of low-quality editions is actually *good* — it means demand exists and quality differentiation is possible.
4. **Structural fit** — Does the text have natural breakpoints for illustrations (chapters, cantos, books, acts)?
5. **Genre balance** — The catalog should not be monotonically philosophical. Alternating between philosophy and fiction/drama keeps the series identity broad and the audience growing.
6. **Production effort** — Shorter texts are faster to produce. Prioritize compact, high-impact titles early to build momentum before tackling 500-page novels.
| The Dhammapada | — | Multiple pre-1928 | Buddhist wisdom tradition. Danny's personal connection to Buddhist texts adds authentic curation. |

---

## 12. Resolved Questions

Questions from v0.1 that have been resolved in this version:

| # | Question | Resolution | Section |
|---|----------|------------|---------|
| 1 | Series name | "Hearthlight Editions" (pending trademark/domain check) | §5 |
| 2 | AI illustration consistency | Elevated to hard gate at M0 with defined fallback. M0 now includes comparative evaluation across Midjourney, Nano Banana 2, and DALL-E. | §5 |
| 3 | Infoblox employment agreement | Michigan has no invention protection statute; risk is contractual only. Danny must review agreement. | §9 |
| 4 | Michigan invention statutes | Michigan is NOT among the 9 states with employee invention protection. Default to common law + contract. | §9 |
| 5 | KDP Select vs. wide | Go wide from day one. KDP Select contaminates validation data. | §7 |
| 6 | Aggregator selection | Draft2Digital for Apple Books. Direct to KDP, Google Play, Kobo. | §7 |
| 7 | Competitive purchase | Elevated to formal pre-M0 milestone. Not optional. | §10 |

### Remaining Open Items

| # | Item | Status | Owner |
|---|------|--------|-------|
| A | Trademark/domain check for "Hearthlight Editions" | To do | Danny |
| B | Infoblox employment agreement review | To do (15 min) | Danny |
| C | Translation comparison: Haines vs. Long side-by-side read | To do before M1 | Danny |
| D | Michigan LLC formation timing | Decide before M2 | Danny |
| E | AI illustration tool evaluation: Midjourney, Nano Banana 2, DALL-E comparative test | M0 | Danny + Tess |

---

## 13. Relationship to Other Projects

**Opportunity Scout (Project 1):** Wisdom Library Phase 1 operational data feeds the Scout's scoring model. Time spent, production friction, revenue data, and marketplace learnings all become calibration inputs for evaluating future opportunities.

**Remaining research vectors (V1–V4, V6):** Independent of Wisdom Library execution. Can be dispatched to the researcher skill in parallel. Their findings feed the Scout Mode project, not this one.

**Crumb infrastructure:** Production pipeline components (AI illustration orchestration, marketplace publishing workflows, sales tracking) may become reusable Crumb capabilities that serve other Execute Mode streams.
