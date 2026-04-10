---
project: firekeeper-books
domain: creative
type: action-plan
created: 2026-03-17
updated: 2026-04-01
---

# Firekeeper Books — Updated Action Plan

Supersedes the 2026-03-17 action plan. Key changes:

- **Title #1 is now Frankenstein** (was Meditations). Fiction-first strategy — illustrations are the moat, and fiction maximizes that moat.
- **Title #2 is The Odyssey**, on a staggered schedule overlapping with Frankenstein production. Hard external deadline: Christopher Nolan's film releases July 17, 2026.
- **Meditations deferred indefinitely.** Stoicism space is saturated (Ryan Holiday owns the shelf). May revisit as a later catalog title.
- **Brothers Karamazov queued** as a future title (Tier 2/3) — Danny's personal favorite, strong literary brand play, but long and commercially harder. Better after the pipeline is proven and the audience exists.
- **Pricing revised to $7.99** (was $5.99) per the 2026-03-19 session finding on KDP's 35% PD royalty restriction.

---

## Schedule Overview

The Odyssey movie (July 17) creates a hard external constraint. Working backward:

| Window | Frankenstein | Odyssey |
|--------|-------------|---------|
| Apr 1–7 | M-1: Spike (shared) | — |
| Apr 8–14 | M0: Design prototype | OD-Pre: Source text + translation eval |
| Apr 15–28 | M1: Production | OD-Pre: Illustration concepts + chapter mapping |
| Apr 29–May 5 | M1: QA + listings | OD-M1: Production begins (stagger start) |
| May 6–12 | M2: Publish | OD-M1: Production continues |
| May 13–Jun 8 | Validation running | OD-M1: Production + QA |
| Jun 9–22 | Validation running | OD-M2: Publish (target: 3–4 weeks before film) |
| Jul 17 | — | Film releases. Search demand peaks. |

This is aggressive but feasible because: (a) M-1 spike and M0 design system apply to both titles, (b) Frankenstein is short and structurally simple, (c) Odyssey pre-production runs in parallel with Frankenstein's later milestones, (d) pipeline workflows from Frankenstein transfer directly.

**If the schedule slips:** Shipping the Odyssey in July or even early August still catches the wave. The search demand from a Nolan movie sustains for months, not days. Don't sacrifice quality for the deadline.

---

## M-1: Tool & Process Spike (Shared — applies to both titles)

**Goal:** Determine whether the tools can produce what the spec requires, calibrated against what already exists in the market. This spike serves both Frankenstein and the Odyssey — the style system must flex across gothic horror and mythic epic.

| # | Action | Owner | Done When |
|---|--------|-------|-----------|
| M-1.1 | Buy competitive ebooks: (a) Frankenstein Deluxe Edition (Coulthart), (b) an illustrated Odyssey edition (see competitive-review.md #4), (c) 1–2 illustrated fiction classics (Dracula/Gothic series, Inferno/Doré). Budget ~$25–35. | Danny | Purchased and downloaded to Kindle |
| M-1.2 | Review competitive purchases — document quality bar, illustration styles, typography, what works, what's missing, where the gap is. Evaluate on actual Kindle device. Use framework in `design/competitive-review.md`. | Danny + Claude | Written review in `design/competitive-review.md` |
| M-1.3 | Set up accounts for Midjourney, Nano Banana 2 (Gemini), and DALL-E (ChatGPT) | Danny | All three tools accessible, first test prompts run |
| M-1.4 | Generate test illustrations across both title worlds: (a) 3 Frankenstein scenes (the creation, Arctic ice, the creature in the Alps), (b) 3 Odyssey scenes (Cyclops cave, Circe's island, Penelope at the loom). Test styles: woodcut, ink wash, line art, watercolor. All three tools. | Danny + Claude assist | 6+ test illustrations per tool, style notes documented |
| M-1.5 | Evaluate coherence: Do the Frankenstein illustrations feel like one book? Do the Odyssey illustrations feel like one book? Do both feel like they belong to the same *series*? Compare against competitive benchmarks from M-1.2. | Danny | Written assessment in `design/spike-findings.md` — go/iterate/stop per the gate criteria below |

**Gate criteria (unchanged from original):**
- **Go** = at least 3 of 6 illustrations feel like they belong together AND are clearly better than competitive review. Style direction promising enough for full prototype.
- **Iterate** = promising but needs refinement. Budget 1–2 more spike sessions.
- **Stop** = tools can't produce what we need. Reassess approach.

**Estimated time:** 1 week (assumes Danny buys ebooks and sets up accounts in the first 2–3 days).

---

## M0: Design Prototype (Frankenstein-focused, series-portable)

**Goal:** Produce enough design artifacts to answer: "Is this meaningfully better than what's on the market?" Design system must work for Frankenstein now and transfer to the Odyssey without a redesign.

| # | Action | Owner | Done When |
|---|--------|-------|-----------|
| M0.1 | Define typography system — serif typeface(s), heading/body hierarchy, page margins for ebook. Must work for gothic horror (Frankenstein) and epic poetry (Odyssey). | Danny + Claude | Typography spec in `design/design-system.md` |
| M0.2 | Define color palette — warm series palette with per-title accent colors. Frankenstein accent: cold blues, grays, laboratory amber. Odyssey accent: wine-dark reds, Mediterranean blues, bronze/gold. | Danny + Claude | Palette documented in `design/design-system.md` |
| M0.3 | Create 3 cover concepts for Frankenstein using chosen illustration style + typography + palette | Danny + Claude | 3 cover images saved in `design/prototypes/` |
| M0.4 | Design title page layout and chapter opener layout (series-level templates) | Danny + Claude | Layout templates in `design/prototypes/` |
| M0.5 | Produce 3 refined Frankenstein illustrations in the chosen style (beyond M-1 spike quality) | Danny + Claude | Illustrations in `design/prototypes/` |
| M0.6 | Create interior page sample — text spread showing how the reading experience feels | Danny + Claude | Sample epub or PDF in `design/prototypes/` |
| M0.7 | Design gate review — compare prototype against Coulthart Frankenstein and other competitive purchases. Decide go/no-go. | Danny | Gate decision logged in run-log |

**Gate:** Danny evaluates the full prototype package. If meaningfully better than existing editions → proceed to M1. If not → iterate or reassess.

**Estimated time:** ~1 week.

---

## M1: Frankenstein Production

**Goal:** Complete, publish-ready illustrated edition of Frankenstein.

### Source Text

**Edition:** The 1818 text (first edition) is cleanly public domain and available via Project Gutenberg. The 1831 revised edition is also PD. Key decision: 1818 vs 1831.

- **1818** — rawer, more radical, closer to Shelley's original voice. Preferred by scholars and increasingly by general readers.
- **1831** — more polished, Shelley's own revisions, more widely known. The "standard" text for 200 years.

Recommendation: use the 1818 text with a brief note explaining the choice. It differentiates from the majority of editions (which default to 1831), aligns with the scholarly trend, and the rawer voice pairs better with original illustrations. If the 1818 proves too rough in practice, the 1831 is an easy fallback.

### Production Tasks

| # | Action | Owner | Done When |
|---|--------|-------|-----------|
| M1.1 | Acquire source text — download 1818 Frankenstein from Gutenberg/Wikisource. Clean, verify structure (3 volumes, letters + chapters). | Claude | Clean text file, structure verified |
| M1.2 | Text preparation — light editorial pass for any OCR artifacts or formatting issues. Verify chapter breaks, letter structure, frame narrative. | Claude + Danny review | Clean manuscript ready |
| M1.3 | Write introduction — brief contextual piece: who was Mary Shelley, the Villa Diodati origin story, why the 1818 text, how to read it. Original content. | Danny + Claude draft | Introduction complete, Danny approves |
| M1.4 | Chapter-by-chapter illustration mapping — identify the strongest visual moment in each chapter/letter. Prioritize scenes with dramatic tension, atmosphere, or iconic imagery. Target: 16–20 illustrations (cover + chapter openers + key interior scenes). | Danny + Claude | Illustration map in `title-01-frankenstein/illustration-map.md` |
| M1.5 | Generate all illustrations using M0 style guide. Art direction from Danny, iterative prompting for consistency and quality. | Danny art direction + Claude | All illustrations generated, reviewed for coherence, approved |
| M1.6 | Final cover design — production-ready cover from M0 template + final illustration. KDP spec: 2560×1600px minimum. | Danny + Claude | Cover image at spec |
| M1.7 | Ebook formatting — assemble epub using Calibre/Sigil or Atticus. Apply design system. | Claude | epub renders correctly on Kindle, Kobo, Apple Books |
| M1.8 | Quality assurance — Danny full read-through on Kindle app. Check formatting, illustrations, typography, chapter flow. | Danny | QA pass complete, issues resolved |
| M1.9 | Keyword research — identify top-performing keywords for Frankenstein editions on KDP. Categories, search terms, description patterns. | Claude | Keyword analysis documented |
| M1.10 | Prepare marketplace listings — title, subtitle, description, categories, keywords, pricing ($7.99) for all platforms. Lead with visual experience in description. Per KDP PD requirements: include "(Illustrated)" in title field, bullet-point differentiation summary in description. | Claude draft + Danny review | Listings finalized for KDP, Kobo, Google Play, Apple Books |
| M1.11 | Prepare launch marketing — Goodreads author profile, targeted community engagement drafts (r/books, r/horrorlit, r/printSF — NOT hard sell), landing page on firekeeperbooks.com if feasible. | Claude draft + Danny review | Marketing materials ready |

**Gate:** Complete edition + marketplace listings + marketing materials all ready. Danny approves for publishing.

**Estimated time:** ~2 weeks.

---

## OD-Pre: Odyssey Pre-Production (runs parallel with Frankenstein M1)

**Goal:** Get the Odyssey ready to enter full production the moment Frankenstein ships. These tasks have no dependency on Frankenstein being finished — they can run concurrently.

| # | Action | Owner | Done When |
|---|--------|-------|-----------|
| OD-P1 | Source text evaluation — obtain Samuel Butler prose translation (1900) from Gutenberg. Also evaluate: Alexander Pope (verse, 1725, PD), William Cowper (verse, 1791, PD), and T.E. Lawrence prose (1932, PD in US). Side-by-side comparison of 2–3 books. | Danny + Claude | Translation selected with rationale documented |
| OD-P2 | Text preparation — clean and structure the selected translation. Verify 24-book structure, identify any editorial work needed. | Claude | Clean manuscript, editorial scope defined |
| OD-P3 | Chapter-by-chapter illustration mapping — the Odyssey has ~30+ iconic visual moments. Map the strongest scene per book, plus key interior moments. Target: 28–32 illustrations (cover + 24 book openers + 3–7 interior). | Danny + Claude | Illustration map in `title-02-odyssey/illustration-map.md` |
| OD-P4 | Odyssey-specific style exploration — using the series design system from M0, generate 3–5 test illustrations in the Odyssey's visual world (Mediterranean light, mythic scale, monsters and gods). Confirm the style system transfers from gothic to epic. | Danny + Claude | Style tests approved, any design-system amendments documented |
| OD-P5 | Competitive landscape snapshot — check what illustrated Odyssey editions exist on KDP right now, especially any timed to the Nolan film. Note pricing, quality, illustration approach. | Claude | Brief competitive note in `title-02-odyssey/competitive-snapshot.md` |

**Estimated time:** ~2 weeks, overlapping with Frankenstein M1.

---

## M2: Frankenstein Published

**Goal:** Live on all platforms, marketing launched, tracking in place.

| # | Action | Owner | Done When |
|---|--------|-------|-----------|
| M2.1 | Publish to KDP — upload epub, cover, fill metadata, set pricing ($7.99). Royalty election: if USCO copyright registration is in place, select "I own the copyright" for 70%; otherwise select "public domain work" for 35%. Do NOT select "public domain" if registration is pending — that election is a one-way door. | Danny + Claude | Live on Amazon |
| M2.2 | Publish to Kobo Writing Life | Claude | Live on Kobo |
| M2.3 | Publish to Google Play Books | Claude | Live on Google Play |
| M2.4 | Publish to Apple Books for Authors (direct — D2D prohibits PD content) | Danny | Live on Apple Books |
| M2.5 | Set up direct sales via firekeeperbooks.com (Payhip or Gumroad) — highest per-sale margin ($7.59 net vs $2.80 KDP) | Danny | Direct sales channel live |
| M2.6 | Execute launch marketing | Danny + Claude | Marketing deployed |
| M2.7 | Set up tracking — weekly sales/rank/review check across all platforms | Claude | Tracking system active |
| M2.8 | Start 60-day validation timer | — | Timer noted in run-log |

---

## OD-M1: Odyssey Production

**Goal:** Complete, publish-ready illustrated edition of The Odyssey. Begins as Frankenstein enters QA/publish phase.

| # | Action | Owner | Done When |
|---|--------|-------|-----------|
| OD-M1.1 | Editorial pass on selected translation — modernize archaic language where needed while preserving tone. The Odyssey is longer than Frankenstein; this is the highest-effort step. | Danny + Claude assist | Final text complete, Danny approves |
| OD-M1.2 | Write introduction — the Odyssey's place in literature, this translation, how to read it, brief note on the 2026 film adaptation (tasteful, not exploitative). Original content. | Danny + Claude draft | Introduction complete |
| OD-M1.3 | Generate all illustrations per the illustration map from OD-P3. Apply series design system with Odyssey accent palette. Iterative prompting for consistency across 28–32 pieces. | Danny art direction + Claude | All illustrations approved |
| OD-M1.4 | Final cover design | Danny + Claude | Cover at KDP spec |
| OD-M1.5 | Ebook formatting | Claude | epub renders correctly across platforms |
| OD-M1.6 | Quality assurance | Danny | QA complete |
| OD-M1.7 | Marketplace listings — keyword research informed by film-related search terms. Categories should include both Classic Literature and Greek/Roman Mythology. | Claude draft + Danny review | Listings finalized |
| OD-M1.8 | Launch marketing — lean into the cultural moment. "Read the original story before (or after) seeing the film." Goodreads, r/books, r/classics, r/movies crossover potential. | Claude draft + Danny review | Materials ready |

**Estimated time:** ~3–4 weeks.

---

## OD-M2: Odyssey Published

**Goal:** Live on all platforms before or shortly after July 17.

| # | Action | Owner | Done When |
|---|--------|-------|-----------|
| OD-M2.1 | Publish to KDP | Danny + Claude | Live on Amazon |
| OD-M2.2 | Publish to Kobo, Google Play, Apple Books, direct sales | Danny + Claude | Live on all platforms |
| OD-M2.3 | Execute launch marketing — time to film release window | Danny + Claude | Marketing deployed |
| OD-M2.4 | Set up tracking | Claude | Tracking active |
| OD-M2.5 | Start 60-day validation timer | — | Timer noted |

**Target publish date:** Late June 2026 (3 weeks before film). Acceptable: anytime before end of July.

---

## M3: Validation Assessment (60–90 days after each title publishes)

Unchanged from original plan. Evaluate per-title and cross-title:

| # | Action | Owner | Done When |
|---|--------|-------|-----------|
| M3.1 | Compile sales data across all platforms per title | Claude | Data in `progress/validation-data.md` |
| M3.2 | Compile review/rating data — do reviews mention illustrations? | Claude | Review analysis documented |
| M3.3 | Score against validation criteria: 30–40 sales minimum viable, 200+ strong signal (at $7.99) | Danny + Claude | Scored table |
| M3.4 | Marketing retrospective | Danny | Learnings documented |
| M3.5 | Production retrospective — actual hours vs estimates, pipeline efficiency Frankenstein→Odyssey | Danny + Claude | Production learnings documented |
| M3.6 | Go/no-go on Title #3+. If go: Brothers Karamazov or Inferno as next candidate. | Danny | Decision logged |

---

## Future Pipeline (post-validation)

| Priority | Title | Rationale |
|----------|-------|-----------|
| Next | Brothers Karamazov | Danny's personal favorite. Literary prestige title. Long production but defines the brand. |
| Next | Inferno (Divine Comedy) | Rich illustration tradition (Doré, Blake). 34 cantos = 34 natural illustration points. |
| Later | The Iliad | Natural companion to Odyssey. Cross-sell potential. |
| Later | Jekyll & Hyde | Short, gothic. Pairs with Frankenstein aesthetically. Quick production. |
| Later | Dracula | Gothic horror series identity. Epistolary structure is interesting design challenge. |
| Later | Siddhartha | Danny's spiritual interests. Different visual world — river, forest, contemplation. |

---

## Time Tracking

Same as original plan. Danny logs start/stop per session in `progress/time-log.md`.

```
## M-1: Tool & Process Spike
- 2026-04-02 | 1.5h | Competitive ebook purchases + first reviews (M-1.1, M-1.2)
- 2026-04-03 | 2h   | Midjourney setup + test prompts (M-1.3, M-1.4)
```

Track from M-1 onward. Frankenstein's actual hours are the single most important data point for projecting Odyssey production time and per-title economics.

---

## Immediate Next Actions

1. **Today/tomorrow:** Danny buys competitive ebooks per M-1.1 purchase list
2. **This week:** Danny sets up Midjourney / Nano Banana 2 / DALL-E accounts (M-1.3)
3. **This week:** Danny + Claude review competitive purchases on Kindle (M-1.2)
4. **This week:** Generate test illustrations for both Frankenstein and Odyssey scenes (M-1.4)
5. **End of week 1:** Spike assessment — go/iterate/stop (M-1.5)

---

## Key Constraints & Reminders

- **KDP PD rules:** Must include "(Illustrated)" in title field. 10+ original illustrations required. Bullet-point differentiation in description.
- **KDP royalty:** 35% for PD content. Plan for it. Non-Amazon channels and direct sales are where margins live.
- **D2D prohibits PD content.** Apple Books must be published directly via Apple Books for Authors.
- **Image sizing:** Generate at 2400px (POD/web/app future-proofing), export at 600×800 (ebook). ~2–3MB per image.
- **Copyright on original content:** All illustrations, introductions, and editorial adaptations are Firekeeper's IP. Include standard disclaimer in front matter.
- **Don't sacrifice quality for the Odyssey deadline.** The Nolan wave sustains for months. A great edition in August beats a rushed one in June.
