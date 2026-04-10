---
type: analysis
project: mission-control
status: complete
domain: software
created: 2026-03-07
updated: 2026-03-07
skill_origin: researcher
tags:
  - dashboard
  - web
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Mission Control — Design Rationale Analysis

Cross-referencing Phase 0 design decisions against data visualization and visual perception source material in the vault.

## 1. Summary

The Phase 0 design decisions are broadly well-aligned with the source material. Of the ten decisions analyzed, seven receive direct or strongly extrapolated support from the digested sources. One decision (SVG arc gauges) faces a direct, well-documented contradiction from Few, who invented a specific alternative to replace circular gauges. Two decisions (dark background, text size floor) have partial support with important nuances the sources raise.

The most significant finding is that the single most directly relevant source -- Few's *Information Dashboard Design* -- explicitly addresses nearly every decision in the Mission Control design. It is the only book in the vault written specifically about the artifact type being built. The Ware and Tufte sources provide strong perceptual science foundations that validate the color and encoding choices. Cairo and Knaflic offer supporting frameworks for the functional-first philosophy already embedded in the aesthetic brief.

The AKM surfaced five relevant items during Phase 0 sessions, none of which were read. All five would have contributed materially to at least one decision, and two (Ware's *Information Visualization* chapter digest and Few's chapter digest) would have informed nearly every decision under review.

## 2. Per-Decision Analysis

### Decision 1: Status Palette — 4 Semantic Colors (ok/warn/error/stale)

**The decision as made:** Four status colors with strict semantic mapping: green (#4aba7a) for healthy, amber (#e0a830) for degraded, red (#e05545) for critical, gray (#706860) for stale. "Every hue carries meaning. No decorative color." (design-system.md 1.5)

**Source citations:**

Ware (*Information Visualization*, Ch. 4): "Color is highly effective as a nominal code (labeling categories), but designers should limit themselves to around 12 distinct colors." The four-color status palette is well within this limit.

Ware (*Information Visualization*, Ch. 5): "If we want a symbol to pop out, it should be distinct on at least one of these feature channels... for example, it might be the only item that is colored in a display where everything else is black and white." The Mission Control approach of reserving color exclusively for status creates exactly this pop-out condition.

Few (*Information Dashboard Design*, Ch. 4): "There is a practical limit to perceptual distinctness; for example, humans can only easily distinguish about five distinct color intensities." Four semantic colors sits safely within this limit.

Few (*Information Dashboard Design*, Ch. 5): "Muted, natural colors should form the baseline of the dashboard, reserving bright, saturated colors exclusively for alerts and important data." The design system follows this precisely -- the background tones and text colors are muted, with saturated hues reserved for the status palette.

Knaflic (*Storytelling with Data*, Ch. 4): "Color must be used sparingly. A 'rainbow' chart highlights nothing because everything is competing for attention." The functional-only color discipline avoids this trap.

Ware (*Visual Thinking for Design*, Ch. 4): "Large background areas should use low-saturation, subdued colors, while small target symbols should use high-saturation, bold colors to stand out." The design system's background tokens (desaturated charcoals) versus status tokens (saturated green/amber/red) follow this rule.

**Assessment:** SUPPORTED (direct). Multiple sources converge on this decision from different angles -- perceptual limits, preattentive processing, and functional color discipline. The four-color count is conservative relative to the ~5-12 distinguishable hues the science supports, which is appropriate since the status dots are small (8px) and must be discriminated rapidly.

**Confidence:** Direct.

**AKM cross-reference:** Ware chapter digest was surfaced 3 times during Phase 0 but never read. It contains the most relevant preattentive processing and color channel science for this decision.

---

### Decision 2: SVG Arc Gauges for Resource Metrics (CPU/Memory/Disk/GPU)

**The decision as made:** Four custom SVG arc gauges with needle-style fill, threshold coloring (ok/warn/error), centered percentage value. Budget capped at 4 gauges across the entire dashboard. (widget-inventory.md, ops-mockup.html)

**Source citations:**

Few (*Information Dashboard Design*, Ch. 6): "The Bullet Graph: Designed to replace the circular gauge, it linearly displays a key measure alongside comparative measures (like a target) and qualitative ranges (good, satisfactory, poor) while taking up a fraction of the space." Few explicitly invented the bullet graph as a direct replacement for circular gauges, calling vendor gauges a symptom of "what's wrong with the industry."

Few (*Information Dashboard Design*, Ch. 1): "Most dashboard software emphasizes superficial glitz (e.g., photo-realistic gauges and meters) that subverts clear communication."

Few (*Information Dashboard Design*, Ch. 3): Circular gauges are listed under the "meaningless variety" and "useless decoration" anti-patterns. "Introducing meaningless variety (changing chart types just to avoid looking 'boring'), using 3D effects on 2D data, and cluttering the screen with useless decoration (like real-world metaphors) all distract the viewer from the actual data."

Cairo (*The Functional Art*, Ch. 6): The Cleveland-McGill scale ranks visual encodings. "Position on a common scale > Position on nonaligned scales > Length/Direction/Angle > Area." Arc fill position falls into the "Angle" tier, which is less accurate than position on a common scale (what a bar or bullet graph provides).

Tufte (*Visual Display*, Ch. 4): "Maximize the data-ink ratio." A 120x80px SVG gauge dedicates significant ink to the track arc, needle hub, and empty arc space that carries no data. A bullet graph of equivalent height would present the same information with higher data-ink density.

**Assessment:** CONTRADICTED (direct). Few devotes substantial argument to replacing circular gauges with bullet graphs, and his reasoning is well-grounded in the perceptual science from Ware and the data-ink principles from Tufte. The arc fill encodes percentage via angle, which Cleveland-McGill ranks below linear position.

**Mitigating factors the sources do not address:** The aesthetic brief explicitly acknowledges a "library vs observatory tension" and chooses analog-feeling readouts as a deliberate character decision: "Analog-feeling readouts -- gauges, meters, dials styled as vintage scientific instruments, not flat digital counters." The design also limits gauges to exactly 4 instances, budgets them explicitly, and pairs each gauge with a redundant KPI card showing the same percentage as a direct number. The redundancy means the gauge is never the sole encoding -- it is a character element reinforced by a more perceptually accurate KPI readout.

**Phase 1 recommendation:** The contradiction is real but intentionally absorbed. The gauge budget cap, redundant KPI encoding, and threshold coloring all mitigate Few's concerns. During implementation, consider whether the gauge value text (24px, centered) provides sufficient precision that the arc position becomes supplementary rather than primary. If so, the gauges function as ambient status indicators (green/amber/red arc at a glance) rather than precise readouts, which is a defensible use.

**Confidence:** Direct (the contradiction is explicit and well-documented).

**AKM cross-reference:** Few's chapter digest was surfaced implicitly through the dataviz companion overlay but the full source was not read. The bullet graph argument would have been encountered directly.

---

### Decision 3: Urgency-Colored Left Borders on Attention Cards

**The decision as made:** Attention cards use a 3px left border colored by urgency level: now=error red, soon=warn amber, ongoing=accent teal, awareness=stale gray. (widget-vocabulary.css `.attention-card.urgency-*`)

**Source citations:**

Ware (*Information Visualization*, Ch. 5): Preattentive features that produce pop-out include "color, orientation, size, or motion." Color applied to a border edge leverages both the color channel and the spatial-position channel (left edge is consistent, predictable).

Few (*Information Dashboard Design*, Ch. 5): Among the visual attributes useful for highlighting, "Hue: Any hue that is distinct from the norm will stand out." The left-border encoding places the status hue at a consistent spatial anchor point, supporting rapid scanning of a vertical card list.

Ware (*Visual Thinking for Design*, Ch. 3): Spatial ordering patterns -- "Spatially ordered graphical objects" convey "Related information or a sequence." The vertical card list with left-border colors creates a scannable sequence where urgency status is readable without examining card content.

Knaflic (*Storytelling with Data*, Ch. 3): Gestalt principle of continuity -- elements arranged on a line are perceived as related. The left borders create a continuous vertical color stripe that groups cards by urgency level when sorted.

**Assessment:** SUPPORTED (extrapolated). No source directly addresses "left border as urgency encoding," but the combination of preattentive color, spatial consistency, and Gestalt continuity principles all support this pattern. The left position is particularly strong because Western readers' eyes begin scanning at the left edge.

**Confidence:** Extrapolated (from general preattentive and Gestalt principles).

**AKM cross-reference:** Ware chapter digest surfaced 3 times, never read. The preattentive features discussion in Ch. 5 would have directly informed this decision.

---

### Decision 4: KPI Strip as Primary Scannability Mechanism

**The decision as made:** Horizontal strip of compact KPI cards (auto-fit grid, 140px min) as the first section on every page. Each card shows: chrome label (13px uppercase), value (22px monospace), and sub-label (13px). (design-system.md 3.4, ops-mockup.html)

**Source citations:**

Few (*Information Dashboard Design*, Ch. 1): "A dashboard is a visual display of the most important information needed to achieve one or more objectives; consolidated and arranged on a single screen so the information can be monitored at a glance." The KPI strip serves exactly this "at a glance" function.

Few (*Information Dashboard Design*, Ch. 6): "Sparklines: Invented by Edward Tufte, these are 'word-sized' line graphs without axes, used to provide a quick historical context or trend directly inline with text." The design incorporates sparklines within KPI cards (CPU Load card in ops-mockup.html), following this recommendation.

Tufte (*Visual Display*, Ch. 8): "Small Multiples: These are series of graphics showing the same combination of variables, indexed by changes in another variable. They are inevitably comparative, efficiently interpreted, and often narrative in content." A KPI strip is structurally a small-multiples array -- same card format, different variable per card.

Ware (*Visual Thinking for Design*, Ch. 1): "Visual Working Memory Limits: We can hold only about three 'objects' in our visual working memory at a time." The KPI strip's design -- compact, uniform cards with a single value each -- makes each card a single "chunk" that can be processed rapidly. The 9-card Ops strip exceeds the 3-object limit but leverages the auto-fit grid to create a scannable visual array that doesn't require holding all values in memory simultaneously.

Cairo (*The Functional Art*, Ch. 9): "Overview first, zoom and filter, then details on demand" (Shneiderman's mantra, cited by Cairo). The KPI strip serves as the overview layer, with service cards and panels below serving as the detail layer.

**Assessment:** SUPPORTED (direct). The KPI strip pattern is one of the most strongly supported decisions in the design. It maps directly to Few's dashboard definition, Shneiderman's overview-first principle, and Tufte's small multiples concept.

**Confidence:** Direct.

**AKM cross-reference:** Tufte's index was surfaced once but never read. The small multiples concept from Ch. 8 would have provided direct terminology for the KPI strip.

---

### Decision 5: Dark Background for Operational Dashboard

**The decision as made:** Dark Observatory direction selected. Charcoal background (#1c1f26), bright status colors, teal-green accent. Rationale cited in aesthetic-brief.md D6: "status colors pop dramatically, reduced eye strain, aligns with observatory-at-night metaphor."

**Source citations:**

Knaflic (*Storytelling with Data*, Ch. 9): "Dark backgrounds: They make graphs feel heavy and require reversing the standard rules of contrast (white stands out, grey fades back)." Knaflic does not endorse dark backgrounds -- she presents them as a constraint requiring special handling, not a recommendation.

Ware (*Information Visualization*, Ch. 3): "The visual system uses center-surround receptive fields to calculate local contrast rather than absolute luminance." This is neutral on light-vs-dark but emphasizes that contrast is what matters. The dark theme's light-on-dark text (#e8e4dc on #1c1f26) provides high luminance contrast.

Ware (*Visual Thinking for Design*, Ch. 4): "The most important single principle in the use of color is that whenever detailed information is to be shown, luminance contrast is necessary." The design system maintains high luminance contrast for all text tiers -- the 13px chrome text uses warm off-white against dark charcoal.

Few (*Information Dashboard Design*, Ch. 5): "Muted, natural colors should form the baseline of the dashboard." Few's examples universally use light backgrounds with muted tones, but his principle is about relative saturation, not absolute lightness. The dark theme's muted charcoal backgrounds satisfy the "muted baseline" principle if interpreted as saturation rather than lightness.

Cairo (*The Functional Art*, Ch. 8): "Limit aesthetic variables: Stick to two or three colors and one or two fonts to maintain visual unity." The dark theme's color discipline (four status colors, one accent, three font families) aligns well with this constraint.

**Assessment:** PARTIALLY SUPPORTED with caveats. The perceptual science is neutral on dark vs. light -- it cares about contrast, not polarity. The design system maintains adequate contrast ratios. However, no source in the vault explicitly recommends dark backgrounds for dashboards, and Knaflic specifically flags dark backgrounds as requiring careful handling. The decision is better supported by industry convention (Grafana, Linear, every ops dashboard) and the aesthetic brief's observatory metaphor than by the visualization literature.

**Phase 1 consideration:** Ware's Ch. 3 warns that "simultaneous contrast illusions can cause substantial errors (up to 20%) when reading quantitative data maps encoded in grayscale." On a dark background, the gray/stale status color (#706860) could be affected by surrounding panel backgrounds (#242830). The stale state may need a slightly higher luminance than currently specified to ensure adequate discrimination from the dark background.

**Confidence:** Extrapolated.

**AKM cross-reference:** Ware chapter digest surfaced 3 times, never read. The luminance contrast and simultaneous contrast content would have been directly applicable.

---

### Decision 6: Timeline with Color-Coded Dots

**The decision as made:** 24-hour horizontal timeline track with positioned, color-coded dots (heartbeat=green, alert=red, mode=amber, maintenance=gray). Grid lines every 4 hours, time labels below. (ops-mockup.html, design-system.md 1.6)

**Source citations:**

Tufte (*Visual Display*, Ch. 1): "Time-series displays are most effective for large, complex data sets with real variability; they should not be wasted on simple linear changes." The 24h timeline shows discrete events with real variability (different types, irregular spacing), making a time-series display appropriate.

Tufte (*Visual Display*, Ch. 4): "Maximize the data-ink ratio." The timeline is lean -- dots carry data (position=time, color=type), grid lines provide orientation, and the track background is minimal. No excessive decoration.

Tufte (*Visual Display*, Ch. 5): "Grids should be muted, gray, or completely suppressed so that their presence is only implicit." The timeline grid lines use `--timeline-grid` (#363b48), a subtle dark-gray tone that does not compete with the data dots. This follows Tufte's recommendation precisely.

Ware (*Information Visualization*, Ch. 5): "Visual search is driven by 'preattentive processing': targets distinct in color, orientation, size, or motion can be found rapidly." The four dot colors encode four event types via the color preattentive channel. However, the dots are all the same size (10px) and shape (circle), meaning color is the sole differentiator.

Cairo (*The Functional Art*, Ch. 6): Cleveland-McGill scale: "Position on a common scale" is the most accurate encoding. The timeline uses position on a common horizontal scale (time axis) as the primary encoding, with color as secondary categorization. This is the optimal ordering.

**Assessment:** SUPPORTED (direct). The timeline follows visualization best practices closely -- position for temporal data, color for categorization, muted grid, and high data-ink ratio.

**Minor gap:** Ware (Ch. 5) notes that conjunction searches (finding a specific color among multiple colors) are slower than single-feature searches. With four dot colors of identical size and shape, finding "all alerts" requires a conjunction-like scan. However, the alert color (red) against a predominantly green (heartbeat) field should still produce adequate pop-out due to the red-green opponent channel contrast. The "now" indicator uses size differentiation (12px + glow) to distinguish it, which adds a second preattentive channel -- this is well-supported.

**Confidence:** Direct.

**AKM cross-reference:** Ware chapter digest surfaced 3 times, never read. Tufte index surfaced once, never read.

---

### Decision 7: Cards-Within-Panel Containment (Digest Panel)

**The decision as made:** Signal cards nested within a digest panel that provides a header, border, and filter controls. Individual cards inside lose their own border/shadow -- the panel provides containment. (intelligence-mockup.css `.digest-body .signal-card` overrides)

**Source citations:**

Ware (*Information Visualization*, Ch. 6): "Gestalt laws dictate visual grouping: elements that are close together, look similar, or are bounded by a common region are perceived as related." The digest panel uses common-region grouping (enclosure) to bind signal cards into a unified set.

Ware (*Information Visualization*, Ch. 6): "Connectedness (lines) and common region (enclosure) are the most powerful methods for showing relationships." The panel border creates a common region, which is the strongest non-connection grouping principle.

Few (*Information Dashboard Design*, Ch. 7): "What is the least visible means to visually delineate groups of data? The answer is white space... Use white space to delineate groups of data whenever possible." Few prefers whitespace over borders for grouping. The digest panel uses a border rather than whitespace, which is more visible but justified given the dark background where whitespace (just more dark space) would not create adequate visual separation.

Knaflic (*Storytelling with Data*, Ch. 3): Gestalt principles of enclosure and proximity. "Humans inherently try to create order out of visual stimuli."

Tufte (*Visual Display*, Ch. 4): "Erase non-data-ink." The design's decision to strip individual card borders/shadows when nested (`.digest-body .signal-card { border: none; box-shadow: none; }`) follows this principle -- the panel provides containment, so individual card borders become redundant non-data ink.

**Assessment:** SUPPORTED (direct). The containment pattern is a textbook application of Gestalt common-region grouping, and the removal of redundant individual card styling follows data-ink maximization. The border-over-whitespace choice is a reasonable adaptation to the dark background context.

**Confidence:** Direct.

**AKM cross-reference:** Ware chapter digest surfaced 3 times, never read. Ch. 6 on Gestalt grouping is directly relevant.

---

### Decision 8: 13px/14px Text Floor on Dark Backgrounds

**The decision as made:** Universal 13px minimum (chrome labels, timestamps, nav labels). 14px minimum for data values (service meta, LLM stats, cost values). "Dark backgrounds require slightly larger text for equivalent readability vs light backgrounds." (aesthetic-brief.md D2, D3)

**Source citations:**

Ware (*Visual Thinking for Design*, Ch. 4): "The most important single principle in the use of color is that whenever detailed information is to be shown, luminance contrast is necessary." The text floor decision is motivated by the same concern -- ensuring adequate readability -- but expressed as a size constraint rather than a contrast constraint.

Ware (*Information Visualization*, Ch. 2): "The human eye's acuity is highest in the fovea and drops off sharply in the periphery, meaning visualizations should group critical information centrally (within a 6-degree parafoveal region)." This speaks to spatial positioning rather than text size, but implies that text at the periphery of a large display needs adequate size to be resolved during peripheral-to-foveal saccades.

Ware (*Information Visualization*, Ch. 4): "Because chromatic channels cannot resolve fine detail, text and small symbols must always have a high luminance contrast against their background." The 13px floor combined with high-contrast text colors (#e8e4dc on #1c1f26) addresses this requirement.

Few (*Information Dashboard Design*, Ch. 6): Sparklines and bullet graphs are described as "word-sized" display mechanisms, implying they function at body-text scale. The design's sparklines (80x24px, rendered inline with 22px KPI values) are sized proportionally.

**Assessment:** PARTIALLY SUPPORTED. The sources strongly support the need for high luminance contrast for text readability, which the design system provides. However, no source in the vault provides a specific pixel-size floor recommendation for light-on-dark text. The D2 assertion that "dark backgrounds require slightly larger text for equivalent readability" is a widely accepted typographic convention but is not explicitly stated in any of the six digested sources. The WCAG accessibility standard (referenced in Yablonski's Fitts's Law chapter at 44x44 CSS px for touch targets) does not directly address minimum text size.

**Phase 1 consideration:** The 13px floor appears adequate for the three font families in use (Inter has a large x-height for its nominal size, JetBrains Mono is inherently wider than proportional fonts, Source Serif 4 at 13px may be the tightest case). Consider verifying the Source Serif 4 chrome-tier usage -- the design system currently uses Inter for all 13px chrome, which is the stronger choice.

**Confidence:** Extrapolated (general typographic principles, not specific source citations).

**AKM cross-reference:** Yablonski chapter digest surfaced once, never read. While it does not contain specific text-size guidance, its Fitts's Law and accessibility content would have been useful for the mobile viewport analysis.

---

### Decision 9: Four-State Visual Pattern System (blocked/empty/error/stale)

**The decision as made:** Four visual states derived from the adapter `{data, error, stale}` contract, plus "blocked" for upstream dependencies. Each state has distinct visual treatment at three scales: full panel, KPI card, and card-within-list. (design-system.md 3.8, widget-vocabulary.html/css)

**Source citations:**

Ware (*Information Visualization*, Ch. 5): "Visual search is driven by 'preattentive processing': targets distinct in color, orientation, size, or motion can be found rapidly, regardless of the number of distractors." The four states use multiple differentiating channels:
- **Blocked:** dashed border + 50% opacity (form change + luminance)
- **Empty:** centered layout + muted icon (spatial layout change)
- **Error:** red banner + red border (color + spatial addition)
- **Stale:** amber banner + amber accent (color + spatial addition)

This multi-channel differentiation follows Ware's recommendation that targets should be "distinct on at least one of these feature channels."

Few (*Information Dashboard Design*, Ch. 2): "Operational dashboards monitor dynamic, real-time activities requiring immediate response. They need alerts that grab attention instantly." The error and stale states use color-coded banners that provide this instant-attention function.

Few (*Information Dashboard Design*, Ch. 3): "Displaying measures without context (e.g., a number without a target or historical comparison) renders the data meaningless." The stale state addresses this by showing both the age and the freshness threshold ("Data is 45 minutes old (threshold: 3 minutes)"), providing the context that makes the staleness judgment meaningful.

Yablonski (*Laws of UX*, Ch. 8 — Von Restorff Effect): "When multiple similar objects are present, the one that differs from the rest is most likely to be remembered." The four states are designed to be visually distinct from the normal (data-present, healthy) state, leveraging the Von Restorff effect.

**Assessment:** SUPPORTED (direct). The four-state system is well-grounded in preattentive processing principles, and the multi-channel differentiation (not just color) ensures states remain distinguishable even for users with color vision deficiencies. The three-scale approach (panel, KPI, card) demonstrates thoughtful adaptation of the same semantic pattern across widget types.

**Sufficiency question:** Four states appears adequate. The adapter contract produces three data conditions (data, error, stale), and "blocked" covers the upstream-dependency case. There is no obvious fifth state missing from the sources' perspective. Empty vs. blocked is the closest pair perceptually, but the dashed-border treatment for blocked provides adequate differentiation from the centered-icon empty state.

**Confidence:** Direct.

**AKM cross-reference:** Yablonski chapter digest surfaced once, never read. The Von Restorff Effect (Ch. 8) is directly relevant to the distinctiveness of error/stale states.

---

### Decision 10: Progress Bar vs. Gauge Assignment

**The decision as made:** Five candidates were evaluated for gauge vs. bar treatment. Four resource metrics (CPU/Memory/Disk/GPU) were assigned to gauges. Five other candidates (FIF cost ceiling, YT API quota, dossier completeness, budget vs actual, MOC coverage) were assigned to bars/KPIs. (widget-inventory.md "Analog Readout Budget")

**Source citations:**

Few (*Information Dashboard Design*, Ch. 6): "Use bars for discrete comparisons across nominal or ordinal scales (e.g., regions). Use lines exclusively for interval scales (e.g., time series)." The cost burn panel uses bars correctly for discrete categorical comparison (cost per service).

Cairo (*The Functional Art*, Ch. 2): "The Bubble Plague: Circles are frequently misused in infographics because the human brain struggles to accurately compare 2D areas." This supports the decision to avoid gauges for dossier completeness (N accounts) -- area comparison across multiple gauges would be even harder than bubble comparison.

Cairo (*The Functional Art*, Ch. 6): Cleveland-McGill scale: bars (position on common scale) outperform angles (gauge arcs) for precision. The candidates rejected from gauge treatment -- FIF cost ceiling, dossier completeness, budget vs actual -- all require precise comparison or tracking against a target, where bars are perceptually superior.

Few (*Information Dashboard Design*, Ch. 6): "The linear design of the bullet graph... allows several to be placed next to one another in a relatively small space." The "Candidates not selected" table in widget-inventory.md cites rationale consistent with Few's thinking: "Additive fill toward ceiling -- bar is more natural than arc" (FIF cost), "Many instances -- gauge doesn't scale to N accounts" (dossier completeness).

**Assessment:** SUPPORTED (direct) for the rejection decisions. The five candidates correctly assigned to bars/KPIs all have characteristics (multiple instances, target tracking, precise comparison) that bars handle better than gauges. The gauge assignment for the four resource metrics is the weaker part -- per Decision 2 above, bullet graphs would be perceptually superior even for these -- but the explicit budget cap and redundant KPI encoding mitigate the concern.

**Confidence:** Direct (for the bar/KPI assignments); see Decision 2 for the gauge assignments.

**AKM cross-reference:** Few's chapter digest was not surfaced by AKM but is the single most relevant source for this decision.

---

### Additional Decision: Three-Font Typography System (Serif/Mono/Sans)

**The decision as made:** Source Serif 4 for page titles and panel headers, JetBrains Mono for data values and timestamps, Inter for chrome labels and metadata. (design-system.md 2.1)

**Source citations:**

Tufte (*Visual Display*, Ch. 9): "Friendly graphics avoid mysterious encodings, spell words out, and ensure typography is clear (upper-and-lower case with serifs)." Tufte endorses serif typography for data graphics.

Few (*Information Dashboard Design*, Ch. 5): Advocates for clear, consistent typography with "de-emphasized" non-data elements and "enhanced" data elements. The three-font system creates a clear typographic hierarchy: serif for structural headings (human-oriented), monospace for data (machine-readable precision), sans-serif for chrome (compact, functional).

Cairo (*The Functional Art*, Ch. 8): "Limit aesthetic variables: Stick to two or three colors and one or two fonts to maintain visual unity." Three fonts is at the upper limit of Cairo's recommendation. However, each font serves a distinct semantic purpose (heading/data/chrome), so they function as a typographic system rather than arbitrary variety.

**Assessment:** SUPPORTED (direct). The three-font system is semantically motivated and follows the general principle of using typography to create hierarchy. The serif/mono/sans split maps naturally to the content/data/chrome distinction.

**Confidence:** Direct.

---

### Additional Decision: Focus Ring via `:focus-visible` (not `:focus`)

**The decision as made:** All interactive elements show a 2px accent ring with panel-color gap on keyboard navigation, but not on mouse clicks. (design-system.md 1.9)

**Source citations:**

Yablonski (*Laws of UX*, Ch. 2 — Fitts's Law): Touch/click targets need appropriate sizing and spacing. The focus ring design addresses keyboard users specifically, complementing the mouse-oriented hover states.

Yablonski (*Laws of UX*, Ch. 5 — Postel's Law): "Be empathetic to, flexible about, and tolerant of any actions the user could take." Supporting both mouse and keyboard interaction with appropriate visual feedback follows this principle.

**Assessment:** SUPPORTED (extrapolated). The sources address accessibility and input tolerance generally but do not specifically discuss `:focus-visible` vs. `:focus`. The decision follows modern web accessibility best practices.

**Confidence:** Extrapolated.

## 3. Contradictions and Gaps

### Contradiction: Circular Gauges vs. Bullet Graphs (Decision 2)

**Severity:** Moderate. Few's argument against circular gauges is the strongest direct contradiction in the analysis. His bullet graph was specifically invented to solve the problems he identifies with circular gauges: space inefficiency, perceptual inaccuracy of angle-based encoding, and lack of comparative context (no target lines, no qualitative ranges).

**Recommendation:** Do not redesign -- the gauge budget cap, redundant KPI encoding, and aesthetic rationale are sound mitigations. However, Phase 1 implementation should:
1. Ensure gauge value text (24px center number) is the primary readout, with the arc serving as ambient status indication
2. Consider adding threshold tick marks on the gauge arc to provide the "qualitative range" context that Few's bullet graphs include
3. If the gauge rendering proves problematic on mobile (2-column at 480px), prefer the KPI card rendering over scaling down the gauge SVG

### Gap: No Source Addresses Dark Background Specifically (Decision 5)

The visualization literature in the vault consistently uses light-background examples. Few's dashboards are all light. Tufte's work predates dark-mode conventions. Knaflic treats dark backgrounds as a constraint to work around, not a recommendation. The dark background decision is better supported by operational dashboard convention than by the academic sources.

**Recommendation:** No change needed. The perceptual science is polarity-neutral (contrast matters, not absolute lightness), and the design system maintains adequate contrast ratios. But note that the stale-state gray (#706860) on dark panel backgrounds (#242830) has the narrowest contrast ratio in the system and should be verified during implementation.

### Gap: No Source Addresses Minimum Text Size for Dark Mode (Decision 8)

The 13px floor is stated as a "hard constraint" but the rationale ("dark backgrounds require slightly larger text") is a practitioner convention without citation in the digested sources. This is a gap in the source material, not a gap in the design.

**Recommendation:** The 13px floor is reasonable and likely adequate. No change needed.

### Gap: Sparkline Area Fill

The ops-mockup uses sparklines with both a stroke line and an area fill (`.sparkline-area` with 10% opacity). Tufte's sparkline concept is a "word-sized" line graph -- pure stroke, no fill. The area fill adds non-data ink that could be considered chartjunk by strict Tufte standards. However, on a dark background, the subtle area fill improves the visual weight of the sparkline without introducing distortion.

**Recommendation:** Keep the area fill at low opacity. If it obscures underlying content or creates visual noise, reduce or remove it in Phase 1.

## 4. Discoveries

### Discovery 1: Few's Bullet Graph as a Future Widget Type

Few's bullet graph is directly described in the vault source material and would be a natural addition to the widget vocabulary for cases where the design currently uses progress bars with targets (e.g., FIF cost today vs. ceiling, dossier completeness). A bullet graph would add qualitative ranges (good/satisfactory/poor backgrounds) that progress bars lack.

**Applicability:** Intelligence page "Cost Today" KPI card, Customer page dossier completeness, Agent Activity cost dashboard.

### Discovery 2: Ware's Integral vs. Separable Dimensions for Badge Design

Ware (*Information Visualization*, Ch. 5) discusses integral vs. separable visual dimensions. The badge system uses color (background tint + text color) for category encoding. Color is a separable dimension from spatial position and shape, which means badges can be read independently without interfering with the card's primary content. This validates the badge design but suggests that using both background color AND text color for the same semantic (e.g., `.badge-now` uses error-bg background + error text) creates an integral encoding that strengthens the urgency signal. This is working well and should be preserved.

### Discovery 3: Shneiderman's Mantra as Navigation Architecture

Cairo cites Shneiderman's "Overview first, zoom and filter, then details on demand" as a core interaction principle. The Mission Control page architecture follows this: KPI strip (overview) > section panels (filter/context) > interactive cards (detail on demand). This three-tier architecture is not explicitly documented in the design artifacts as following Shneiderman's mantra, but it maps precisely. Documenting this mapping would strengthen Phase 1 implementation decisions about drill-down interaction patterns.

### Discovery 4: Few on Single-Screen Constraint

Few is emphatic that dashboards must fit on a single screen: "One of the great benefits of a dashboard as a medium of communication is the simultaneity of vision that it offers: the ability to see everything that you need at once." The Ops page in ops-mockup.html, with its KPI strip + gauges + service grid + timeline + LLM status + cost burn + blocked panels, likely exceeds a single viewport at 1440px. This is documented in the spec as acceptable ("scrolling is expected for detail sections below the fold") but conflicts with Few's definition.

**Phase 1 consideration:** Ensure the KPI strip -- the primary "at a glance" layer -- is fully visible without scrolling on the target viewport. Below-the-fold content is acceptable if the above-the-fold KPI strip provides the "is the house on fire?" answer within Few's single-screen ideal.

### Discovery 5: Ware on Simultaneous Contrast and the Stale State

Ware (*Information Visualization*, Ch. 3): "Simultaneous contrast illusions can cause substantial errors (up to 20%) when reading quantitative data maps encoded in grayscale." The stale state uses gray (#706860) -- the lowest-contrast status color -- on dark backgrounds. In contexts where a stale KPI card sits adjacent to an ok KPI card (green), the gray may appear shifted in hue due to simultaneous contrast effects. This is worth monitoring in implementation.

## 5. AKM Utilization Summary

| Source | Times Surfaced | Read? | Decisions Relevant To | Value Assessment |
|--------|---------------|-------|----------------------|-----------------|
| `ware-information-visualization-chapter-digest.md` | 3 | No | 1, 2, 3, 5, 6, 7, 8, 9 (8 of 10) | **Critical** -- preattentive processing, color channels, Gestalt grouping, and contrast science apply to nearly every design decision |
| `yablonski-laws-of-ux-chapter-digest.md` | 1 | No | 9, focus ring, mobile viewport | **Moderate** -- Von Restorff and Fitts's Law are relevant but the decisions they inform were made correctly regardless |
| `tufte-visual-display-index.md` | 1 | No | 2, 4, 6, 7, sparklines | **High** -- data-ink ratio, small multiples, and chartjunk principles undergird the design philosophy |
| `knaflic-storytelling-with-data-digest.md` | 1 | No | 1, 3, 5 | **Moderate** -- preattentive attributes and decluttering principles are relevant but largely redundant with Ware and Tufte |
| `ware-information-visualization-index.md` | 1 | No | (index file -- would have led to chapter digest) | **High** -- gateway to the most relevant single source |

**Aggregate assessment:** The AKM surfaced 7 items across 5 unique sources. Zero were read, representing a 0% utilization rate. Of the 5 unique sources, 2 were critical (Ware chapter digest, Tufte index), 1 was high-value (Knaflic), and 2 were moderate (Yablonski, Ware index as gateway).

Had the Ware chapter digest been read during any of its 3 surfacings, it would have provided direct perceptual science grounding for Decisions 1, 3, 5, 6, 7, and 9 -- potentially catching the simultaneous contrast concern (Discovery 5) and the integral/separable dimension insight (Discovery 2) during design rather than post-hoc analysis.

Had the Few chapter digest been available through AKM (it was not surfaced), it would have been the single most impactful source -- the only book in the vault written specifically about dashboard design.

**Recommendation for AKM tuning:** The Ware chapter digest being surfaced 3 times and ignored 3 times suggests either surfacing fatigue or context mismatch. Consider whether AKM surfacing includes a brief relevance note ("contains preattentive processing principles relevant to your status color decisions") rather than just the file name.

## References

**Design artifacts analyzed:**
- `Projects/mission-control/design/design-system.md`
- `Projects/mission-control/design/aesthetic-brief.md`
- `Projects/mission-control/design/widget-inventory.md`
- `Projects/mission-control/design/mockups/ops-mockup.html`
- `Projects/mission-control/design/mockups/ops-mockup.css`
- `Projects/mission-control/design/mockups/attention-mockup.html`
- `Projects/mission-control/design/mockups/attention-mockup.css`
- `Projects/mission-control/design/mockups/intelligence-mockup.html`
- `Projects/mission-control/design/mockups/intelligence-mockup.css`
- `Projects/mission-control/design/mockups/widget-vocabulary.html`
- `Projects/mission-control/design/mockups/widget-vocabulary.css`

**Source material cited:**
- `Sources/books/tufte-visual-display-chapter-digest.md` (Tufte, *The Visual Display of Quantitative Information*)
- `Sources/books/ware-information-visualization-chapter-digest.md` (Ware, *Information Visualization: Perception for Design*)
- `Sources/books/ware-visual-thinking-for-design-chapter-digest.md` (Ware, *Visual Thinking for Design*)
- `Sources/books/cairo-functional-art-chapter-digest.md` (Cairo, *The Functional Art*)
- `Sources/books/knaflic-storytelling-with-data-chapter-digest.md` (Knaflic, *Storytelling with Data*)
- `Sources/books/yablonski-laws-of-ux-chapter-digest.md` (Yablonski, *Laws of UX*)
- `Sources/books/few-information-dashboard-design-chapter-digest.md` (Few, *Information Dashboard Design*)
