---
type: run-log
project: firekeeper-books
domain: creative
status: active
created: 2026-03-17
updated: 2026-04-02
---

# firekeeper-books — Run Log

## 2026-03-17 — Project creation + CLARIFY

**Context:** Draft spec dropped in `_inbox/` from prior research (V7 side-hustle research brief). Danny requested new project creation and CLARIFY phase review.

**Actions:**
- Created project scaffold (project-state, run-log, progress-log, design/)
- Moved draft spec from inbox to `design/wisdom-library-draft-spec.md`
- Ran CLARIFY as structured review — surfaced 6 questions against draft
- Danny resolved all 6; formalized into `design/specification.md`

**CLARIFY Resolutions:**
1. Series name: TBD, brainstorm together
2. Distribution: wide from day one (no KDP Select exclusivity)
3. Translation: modernized adaptations of PD translations (new production step)
4. Danny's time: acknowledged, highly motivated — no gating needed
5. Pre-M0 spike: added as M-1 milestone for tool/process familiarization
6. Marketing: included in Phase 1 scope (Goodreads, Reddit, landing page)

**Note:** Danny initially thought Meditations had been deferred due to art concept incompatibility — no prior record found in vault. Disregarded; Meditations stays as first title.

**Artifacts:**
- `design/specification.md` — formal spec with CLARIFY resolutions incorporated
- `design/specification-summary.md`
- `design/wisdom-library-draft-spec.md` — original draft (preserved as reference)

**Next:** Danny confirms spec → transition to ACT phase. Series name brainstorm needed before M0.

### Phase Transition: CLARIFY → ACT
- Date: 2026-03-17
- CLARIFY phase outputs: `design/specification.md`, `design/specification-summary.md`
- Goal progress: all met — mission, scope, constraints, success criteria, risk assessment formalized. PIIA and Michigan law questions resolved. Business Advisor overlay applied (3 flags + catalog-compounding framing incorporated).
- Compound: Business Advisor insight — validation thresholds must account for distribution capacity to avoid false negatives. Applied in-spec (threshold lowered to 30–40). General principle, no new primitive needed.
- Context usage before checkpoint: moderate
- Action taken: none
- Key artifacts for ACT phase: `design/specification-summary.md`, `design/specification.md`

## 2026-03-17 — ACT phase: action plan

**Context:** Transitioned from CLARIFY. Spec finalized with all CLARIFY resolutions, Business Advisor flags, and PIIA confirmations.

**Actions:**
- Created `design/action-plan.md` — 6 milestones (M-1 through M4) broken into 33 concrete actions with owners and done-whens

**Immediate next actions:**
1. Danny buys 3–5 illustrated philosophy ebooks (M-1.1)
2. Danny + Crumb review competitive purchases (M-1.2)
3. Set up Midjourney and run test prompts (M-1.3, M-1.4)

## 2026-03-17 — Spec restoration: fiction/drama scope

**Context:** Danny discovered that a prior Crumb session (claude.ai/chat/8491fbaa) had broadened the project scope beyond philosophy to include fiction, drama, and poetry. That correction was made in a v0.2 spec but was lost when the current draft was assembled. The philosophy-only pipeline was a regression, not a deliberate scoping decision.

**Restored:**
- Mission statement — now references fiction, drama, poetry alongside philosophy
- §2 scope — explicit that catalog spans all genres; design system must accommodate from day one
- §3 validation hypothesis — generalized from "wisdom text" to "public domain text"
- §5 design system — series name must be genre-agnostic; illustration style must work for abstract themes (philosophy) AND concrete scenes (fiction)
- §11 title pipeline — restructured into 4 tiers: Philosophy & Wisdom (Tier 1), Fiction & Drama (Tier 2), Drama & Poetry (Tier 3), Philosophy Expansion (Tier 4). Fiction candidates: Frankenstein, Divine Comedy, Odyssey, Siddhartha, Metamorphosis, Heart of Darkness, Greek tragedies, Crime and Punishment.

**Key insight from prior session:** Fiction is arguably *more* suited to illustrated editions because of stronger visual anchor points (scenes, characters, settings vs. abstract philosophical themes). Starting with philosophy is a market validation choice, not a scope limitation.

## 2026-03-17 — v0.2 spec merge (major)

**Context:** Danny discovered the v0.2 spec (from a prior claude.ai session) in his files and uploaded it. The initial draft we'd been working from was v0.1 — missing significant content from v0.2 including: translation change, AI tool evaluation framework, pricing revision, series name decision, fiction pipeline, hard gate language, and legal analysis.

**Merged from v0.2 (net new content):**
- **Translation:** Switched from George Long (1862) to C.R. Haines (1916, Loeb Classical Library) with detailed rationale and comparison action item
- **AI tool evaluation:** Comparative framework across Midjourney, Nano Banana 2, DALL-E with 5 specific evaluation criteria
- **Pricing:** Revised from $4.99 to $5.99 (bimodal market — need distance from free tier)
- **Series name:** "Hearthlight Editions" decided (pending trademark/domain), with backup candidates
- **M0 hard gate:** Explicit hard gate language with human-illustrator fallback ($500-1500) if AI tools fail
- **KDP Select rationale:** Detailed reasoning about contaminating validation data
- **D2D aggregator:** Cost analysis and decision documented
- **Michigan legal analysis:** Full section on invention/moonlighting law
- **Pipeline additions:** Iliad, Dhammapada, Tale of Two Cities, Jekyll & Hyde, and selection criteria framework
- **Resolved questions table:** Formal resolved/remaining format replacing ad-hoc strikethrough

**Preserved from our session's work (not in v0.2):**
- Business Advisor analysis (catalog-compounding framing, validation threshold, critical path)
- Lowered validation threshold (30-40 sales)
- LLC deferral to post-M3
- PIIA-specific §8 references (Exhibit B, Section 13)
- Launch marketing in scope
- M-1 spike milestone
- Time tracking mechanism
- Action plan with gates and done-whens
- Reddit caution note

**Artifacts:** v0.2 draft preserved at `design/wisdom-library-spec-v0.2.md` for reference.

## 2026-03-17 — Danny spec review + final fixes

**Context:** Danny reviewed revised spec and action plan, flagged 4 inconsistencies.

**Fixes applied:**
1. §11 pipeline table: Meditations translation now shows "C.R. Haines (1916); Long (1862) fallback" (was still showing George Long)
2. §6 pipeline: Translation work estimate now conditional — "4–8 hours (Haines) or 15–25 hours (Long fallback)" (was hardcoded 15–25)
3. M3 go decision: Now references Tier 1 pipeline + selection criteria instead of hardcoded philosophy-only titles
4. M4.1 action plan: Same fix — references spec §11 + selection criteria

**Additional work:**
- Added §7a Print-on-Demand (Phase 1.5) — evaluate after ebook validation per M3 data. KDP Print vs IngramSpark considerations. Key decision: generate all illustrations at 300 DPI from M-1 onward to keep POD path open.
- Finalized competitive purchase list — 5 must-buy + 2 conditional, covering philosophy (Standard Ebooks, Duke, Bennett/Long), fiction (Frankenstein/Coulthart, Inferno/Doré, Odyssey illustrated), and series identity (Dracula/Timeless Gothic)
- Created `design/competitive-review.md` with purchase list, evaluation framework (visual quality, reading experience, product quality, series identity, price/value, competitive gap), and review template

**Compound:** No new system-level patterns. The spec is now comprehensive — merging v0.1 + v0.2 + CLARIFY resolutions + Business Advisor flags + Danny's review corrections. No drift between spec, summary, and action plan.

**Model routing:** All work done on Opus (main session). No delegation — this was interactive spec refinement with frequent operator input, not suitable for Sonnet delegation.

**Session artifacts (final state):**
- `design/specification.md` — authoritative spec (v0.1 + v0.2 merge + all corrections)
- `design/specification-summary.md` — current summary
- `design/action-plan.md` — 35 actions across 6 milestones
- `design/competitive-review.md` — purchase list + evaluation framework
- `design/wisdom-library-draft-spec.md` — v0.1 draft (reference)
- `design/wisdom-library-spec-v0.2.md` — v0.2 draft (reference)
- `progress/time-log.md` — ready for Danny's first entries
- `progress/progress-log.md` — milestone tracker
- `project-state.yaml` — phase: ACT

**Next actions:**
1. Danny buys competitive ebooks per `design/competitive-review.md` purchase list
2. Danny reviews on Kindle device using evaluation framework
3. Danny + Crumb complete competitive review (M-1.2)
4. Set up Midjourney/Nano Banana 2/DALL-E accounts (M-1.3)

## 2026-03-18 — Series name: Firekeeper Books

**Context:** Resumed session for series name brainstorm (Hearthlight Editions had trademark conflicts — two existing publishing entities found).

**Brainstorm arc:**
- Hearthlight Editions → conflict (Hearthlight Publishing + Hearthlight Books/Maple Shores Press)
- Lighthouse Editions → heavily saturated (6+ publishers)
- Explored ember/fire/light/keeper themes
- Danny's campfire connection: spreading embers at end of night, light and heat together, consumed for benefit of all
- Landed on **Firekeeper Books** — the person who tends the fire so it stays alive for everyone

**Verification:**
- No competing publisher/imprint uses the name
- `firekeeperbooks.com` WHOIS confirmed available → **registered by Danny**
- No USPTO trademark conflict found in publishing classes (web scraping couldn't confirm directly — manual verification at tmsearch.uspto.gov recommended as final step)

**Updated:** spec §5, spec §13 resolved questions, spec remaining items, summary, action plan M0.1, competitive review template. All Hearthlight references replaced in live files; v0.2 draft retains history.

**Compound:** The naming process surfaced a useful pattern — always check for existing publishers (BookScouter, Open Library) before falling in love with a name. "Hearthlight" sounded original but had two conflicts in the exact same industry. Web search + BookScouter + targeted domain/trademark check should be standard for any brand name validation.

**Model routing:** All Opus (interactive brainstorm with operator). Not delegable.

## 2026-03-18 — Trademark verified, legal sequence clarified

**Actions:**
- Danny ran USPTO TESS search: 6 results for "firekeeper," zero live marks in Class 016 (books) or Class 041 (publishing). One dead/abandoned Class 016 mark ("printed gift books featuring poetry"). Two live marks in unrelated classes (011: fire pits, 045: spiritual services). **Clear.**
- `firekeeperbooks.com` registered by Danny
- Clarified legal sequence:
  1. Now: domain (done), ™ on materials
  2. Before M2: DBA filing with county clerk (~$15, Michigan assumed name certificate)
  3. Post-M3: LLC formation (~$50), replaces DBA

**Updated spec:** Remaining open item A now reads "Register domain + verify USPTO" — both complete.

**Next actions (unchanged):**
1. Buy competitive ebooks per purchase list
2. Review on Kindle using evaluation framework
3. Set up Midjourney/Nano Banana 2/DALL-E accounts

## 2026-03-19 — Title #1 production plan

**Context:** Danny prompted a complete production plan for Firekeeper Books Title #1. Shifts project from planning to execution mode.

**Actions:**
- Created `title-01/production-plan.md` — comprehensive plan covering:
  1. Title selection: Meditations confirmed via evaluation against Odyssey, Frankenstein, Inferno
  2. Production plan: manuscript structure, cover brief, layout, 16-illustration strategy with visual concepts
  3. Go-to-market: categories, keywords, $5.99 pricing with per-platform economics, marketing description, launch sequence
  4. Tess task breakdown: 30 tasks across 6 phases (A–F), ~18–22 sessions over 30–35 days
  5. Cost estimate: $90 budget / $238 with Atticus. Break-even at 28–72 sales
- Research subagents: KDP landscape + Haines translation availability
- Integrated research: competitive summary, Haines source URLs, readability caveat, category arbitrage

**Key competitive insights:**
- **No truly illustrated Kindle Meditations edition exists** — stock images only. Original illustrations = genuine market gap.
- Translation trust broken in market — honest attribution is a differentiator
- Structure is #1 reader complaint → added thematic subtitles to book openers
- KDP delivery cost on illustrated ebooks is a margin factor → compression critical
- Biographies of Philosophers category has thinner competition

**Compound:** "No illustrated edition exists" finding elevates illustration from differentiator to sole competitive moat. Strengthens M0 hard gate.

**Model routing:** Opus main + 2 research subagents. Delegation effective.

**Artifacts:** `title-01/production-plan.md` (new)

**Next:** Danny reviews production plan → Phase A (source text) + Phase B (competitive intel) in parallel.

### Mid-session correction: KDP 35% royalty on public domain

**Critical finding:** KDP restricts public domain content to 35% royalty. The original spec and initial production plan assumed 70%. This was caught when Danny surfaced a reference to the restriction.

**Policy (from kdp.amazon.com):** *"The 70% royalty option is for in-copyright works only. Works in the public domain or consisting primarily of public domain content are only eligible for the 35% royalty option."*

**Impact:**
- Per-sale KDP revenue drops from ~$3.29 to ~$2.80 (at revised $7.99 price)
- Price recommendation revised from $5.99 to $7.99 (higher price compensates partially)
- Non-Amazon platforms (Kobo, Google Play, Apple) are unaffected — wide distribution becomes even more critical
- POD royalties are also unaffected — strengthens case for accelerating print alongside ebook

**Escape hatch:** "If you add substantial original content or publish an original translation" → 70% eligible. Firekeeper's case: 16 original illustrations + modernized translation adaptation + original intro. Plausible but uncertain — Amazon reviewers decide.

**Plan adjustment:** Plan for 35%, pursue 70% as upside. Price at $7.99. Prioritize non-Amazon distribution. Flag POD acceleration for Danny's consideration.

**Compound insight:** The 35% PD royalty restriction is a structural constraint that should have been caught during CLARIFY. It changes the economics of every PD ebook title. This needs to be added to the spec as a known constraint, and the pricing strategy across all future titles needs to account for it. The "digital only" constraint set before understanding this restriction should be revisited — POD at $6.50/sale vs ebook at $2.80/sale is a 2.3x difference that changes the production priority.

### Continued: app-readiness, wide-first, 70% campaign, Perplexity research

**App-readiness (§6 added to plan):** Passage-level structuring (task D-1b) breaks Meditations into ~480 addressable passages with thematic tags. Reflection prompts (task D-5) at two levels. 2–3 extra Tess sessions, zero infrastructure. Content structured for future daily reading / subscription product. Ebook ships with Reader's Guide appendix.

**Wide-first distribution (§3.4 rewritten):** 35% restriction makes Amazon the worst-paying channel. Direct sales via firekeeperbooks.com (Payhip, ~$7.59 net) worth 2.7x KDP. Revenue mix target: 50% KDP / 15% direct / 15% Kobo / 10% Apple / 10% Google. Blended per-sale: $4.02 (35% KDP) or $5.30 (70% KDP).

**D2D prohibition:** Draft2Digital prohibits PD content. Apple Books switched to Apple Books for Authors (direct). Net improves $5.03 → $5.59 (no aggregator cut).

**70% royalty campaign (8 research actions):** Upload mechanism confirmed — "I own the copyright" at title setup is the only 70% path. USCO registration ($65) is the evidentiary response to Amazon's proof-of-ownership request. Processing 3–11 months. **Decision: Title #1 launches at 35%. 70% is a Title #2 play.** Research (R-1 through R-8) runs in parallel.

**Perplexity research report:** One confirmed practitioner success (r/KDP Feb 2025). Daniel Hall YouTube teaches the method. USCO certificate accepted by KDP. KDP image recommendation 600×800px (not 1600px). Saved at `title-01/research/70-pct-findings-perplexity.md`. Improved research prompt saved at `title-01/research/70-pct-research-prompt.md`.

**Image sizing revised:** Two-tier — generate at 2400px (POD/web/app), export at 600×800 (ebook). File size ~2–3MB.

**Compound insights from this session:**
1. **Channel mix IS the business model for PD publishing.** The 35% KDP restriction inverts conventional self-publishing wisdom. Direct + wide distribution isn't a nice-to-have — it's the economic foundation. This applies to every Firekeeper title, not just Meditations.
2. **Content structured for app-readiness at production time costs almost nothing.** 2–3 extra Tess sessions to passage-tag and write prompts. If the subscription path validates, the content is ready. If not, the Reader's Guide still ships in the ebook and strengthens the derivative work argument.
3. **The "I own the copyright" upload election is a one-way door.** Selecting "PD work" locks to 35% with no appeal. Selecting "I own copyright" requires documentation but opens 70%. This procedural fact — not the policy language — is what makes copyright registration mechanically essential.

**Model routing:** Opus main session throughout. 2 research subagents (Sonnet, web search) early in session — effective for KDP landscape + Haines translation. No further delegation — session was heavily interactive with Danny driving successive refinements.

**Session artifacts:**
- `title-01/production-plan.md` — comprehensive, iterated through 5 major revision cycles
- `title-01/research/70-pct-research-prompt.md` — external LLM research prompt
- `title-01/research/70-pct-findings-perplexity.md` — Perplexity findings

**Next:**
1. Danny reviews final production plan
2. Phase A: source text acquisition (Haines from Internet Archive + Long from Gutenberg)
3. Phase B: competitive intelligence + 70% royalty research (R-1, R-3, R-4, R-8)
4. Danny: competitive ebook purchases + translation comparison read + Midjourney setup

## 2026-03-31 — Fiction-first pivot: Frankenstein + Odyssey

**Context:** Danny submitted updated action plan via inbox (`firekeeper-updated-action-plan.md`). Major strategic pivot from Meditations-first to fiction-first strategy, plus addition of The Odyssey as Title #2 with a hard external deadline (Nolan film July 17, 2026).

**Strategic changes:**
- **Title #1: Frankenstein** (was Meditations). Fiction-first rationale: illustrations are the moat, fiction maximizes the moat through concrete visual anchor points.
- **Title #2: The Odyssey** on staggered schedule overlapping with Frankenstein production. Nolan film creates a time-limited demand wave.
- **Meditations deferred indefinitely.** Stoicism shelf saturated (Ryan Holiday). May revisit as later catalog title.
- **Brothers Karamazov queued** as post-validation candidate (Danny's personal favorite, Garnett 1912 translation is PD).
- **Pricing confirmed at $7.99** per the March 19 session's 35% KDP PD royalty finding.

**Actions taken:**
1. Fixed M2.1 royalty election instruction — was "select public domain work" which contradicts the March 19 compound insight about the one-way door. Now correctly instructs: elect 70% if USCO registration is in place, otherwise 35%.
2. Moved updated action plan from `_inbox/` to `design/action-plan.md` (replaces 2026-03-17 version).
3. Renamed `title-01/` → `title-01-frankenstein/`. Old Meditations production plan preserved as historical reference.
4. Created `title-02-odyssey/` directory.
5. Updated `design/specification.md` — major revision:
   - §2: Fiction-first framing, Frankenstein + Odyssey as first two titles
   - §3: $7.99 pricing, updated economics, added direct sales metric
   - §4: Complete rewrite — Frankenstein replaces Meditations (1818 text, edition structure, illustration targets). Added §4a for Odyssey.
   - §5: Added per-title accent color system (gothic blues/grays for Frankenstein, Mediterranean reds/blues/gold for Odyssey)
   - §6: Updated pipeline for fiction editorial (removed Haines/Long specifics)
   - §7: Major rewrite — 35% KDP reality, D2D prohibition on PD, Apple direct, direct sales as highest-margin channel, wide-first revenue mix targets
   - §10: Two-title milestone structure (M-1, M0, M1, OD-Pre, M2, OD-M1, OD-M2, M3)
   - §11: Pipeline reordered — Active Production table + Next Candidates. Meditations and Enchiridion moved to Deferred.
   - §13: Updated resolved questions (pricing, first title, scope). Added open items F (USCO registration) and G (70% royalty for Title #2).
6. Rewrote `design/specification-summary.md` to reflect all changes.
7. Updated `project-state.yaml` — next_action reflects M-1 spike start.
8. **Renamed project: `wisdom-library` → `firekeeper-books`.** Directory moved, all frontmatter `project:` fields updated (12 files), project-state name updated. External references updated: `Projects/index.md`, `claude-ai-context.md`, `tess-context.md`, `operator_priorities.md`. Historical references in logs, deliberation data, and daily notes left as-is (they record what the project was called at that time).

**Review findings surfaced to Danny (before proceeding):**
- M2.1 royalty election contradiction (fixed)
- Schedule aggressiveness flagged (Danny acknowledged — "don't sacrifice quality for deadline" is in the plan)
- Odyssey scope (28–32 illustrations, 3–4 weeks) is the tightest constraint
- Dropped items from old plan: 70% research (R-1 through R-8) and app-readiness features — status TBD
- Brothers Karamazov translation needs specifying (Garnett 1912 is PD — noted in pipeline)
- Danny's parallel workload during M1 + OD-Pre overlap flagged

**Compound:** The fiction-first pivot validates an insight from the very first session (March 17): "Fiction is arguably more suited to illustrated editions because of stronger visual anchor points." That was noted as a future consideration — Danny has now made it the strategy. The Nolan Odyssey timing adds an external catalyst that didn't exist when the project was conceived. Together, these create a stronger value proposition than philosophy-first: the product's competitive moat (illustrations) is maximized, and the second title rides a marketing wave. No new system-level patterns — this is a strategic refinement within the existing project framework.

**Model routing:** Opus main session. No delegation — interactive review + high-volume spec editing with operator-provided strategic direction.

**Next:**
1. Danny buys competitive ebooks per M-1.1 (Coulthart Frankenstein, illustrated Odyssey, 1–2 gothic/fiction classics)
2. Danny sets up Midjourney / Nano Banana 2 / DALL-E accounts
3. Danny + Crumb review competitive purchases on Kindle (M-1.2)
4. Generate test illustrations for Frankenstein + Odyssey scenes across all tools (M-1.4)
5. Spike assessment — go/iterate/stop (M-1.5)

## 2026-04-02 — AI art & book design learning plan

**Context:** Danny requested a structured training program for becoming proficient at AI art with Midjourney, post-processing with Pixelmator Pro, and book design (typography + layout) for Firekeeper Books. Learning-plan skill applied with Life Coach overlay consideration.

**Actions:**
1. Gathered context: spec-summary, Ericsson *Peak* digest (deliberate practice), Young *Ultralearning* digest (directness principle). Assessed Danny's current level through 5 questions.
2. Created `ai-art-learning-plan.md` — 6-phase plan (1: Tool Fluency, 2: Style Development, 3: Ebook Production, 3b: Print Design, 4: Odyssey, 5: Ongoing) aligned with production milestones M-1 through OD-M2.
3. Expanded typography section based on Danny's emphasis that text/page design is decisive for book success.
4. Revised typography sections after Danny shared a thread analyzing ebook format constraints — reflowable EPUB gives very limited font control (readers override). Restructured: ebook typography (Phase 3) scoped to what actually renders consistently (relative spacing, chapter opener styling, image-based front matter); deep typography craft (type selection, page architecture, designed spreads) moved to new Phase 3b for print-on-demand where full control exists.
5. Tool recommendation shifted from Affinity Publisher to Atticus ($147) for ebook production (dual-format export), with Affinity Publisher positioned as the graduation tool for print when design needs outgrow Atticus.

**Key decisions:**
- Skill type: composite (creative dominant + applied-technical secondary)
- Production-integrated learning (no separate ramp-up period — every practice session produces candidate material)
- Ebook = discovery product with constrained typography; print = margin product with full design craft
- Core thesis: the antidote to "AI art" stigma is intentionality, not concealment

**Compound:** The ebook/print typography split is a reusable insight for any digital-first illustrated publishing: invest design energy where the format rewards it. In ebook, illustrations carry the premium; in print, typography and illustration compound together. This is specific to Firekeeper Books production strategy, not a system-level pattern.

**Model routing:** All Opus (main session). Interactive plan design with multiple revision cycles based on operator input — not delegable.

**Artifacts:**
- `ai-art-learning-plan.md` — committed and pushed (ca5ef8b)

**Next:**
1. Danny begins Phase 1 (M-1 tool spike, Apr 2–8): Midjourney parameter experimentation, anti-pattern study, benchmark edition analysis
2. Buy competitive ebooks if not already purchased
3. Set up Midjourney account and run first Frankenstein/Odyssey test illustrations

---
