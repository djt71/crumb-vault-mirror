---
project: mission-control
type: design-brief
domain: software
status: active
created: 2026-03-07
updated: 2026-03-07
tags:
  - design
  - dashboard
  - web
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Mission Control — Aesthetic Brief

**Task:** MC-001
**Overlays consulted:** Design Advisor, Web Design Preference, DataViz companion

## Observatory Mode Foundation

Mission Control is a **Mode 2: Observatory** site per the design taste profile. This means:

- **Full-width widget grid** — panels arranged in a responsive grid, each a self-contained information unit
- **Serif panel headers** (ET Book / Source Serif), small sans-serif for metadata chrome, monospace for data values (JetBrains Mono / IBM Plex Mono)
- **Analog-feeling readouts** — gauges, meters, dials styled as vintage scientific instruments, not flat digital counters
- **Sparklines, trend indicators, small multiples** — data that moves
- **Functional status color** — green/amber/red (or warm equivalents) mapping to system states
- **One strong accent color** for interactive elements (deep teal, burgundy, or rich amber)
- **Structured sections** of related panels (4-6 per page, 3-7 widgets per section)

## The Library vs Observatory Tension

The taste profile establishes a warm, light, scholarly foundation across all modes. But Observatory mode has a genuine tension the other modes don't:

**Arguments for warm light (cream/parchment) background:**
- Consistent with the Enlightenment identity across all Danny's web properties
- Warm backgrounds feel personal, scholarly, lived-in — not corporate
- Typography (serif body, monospace data) reads beautifully against cream
- The analog instrument aesthetic can work against warm backgrounds — think brass-and-wood instruments, orreries, antique barometers mounted on oak panels

**Arguments for dark background:**
- Status colors (green/amber/red) pop dramatically against dark backgrounds — critical for at-a-glance health monitoring
- Reduced eye strain during sustained operational monitoring
- Industry convention: Grafana, Linear, virtually every operations dashboard defaults dark
- Sparklines and trend visualizations have higher contrast against dark fields
- The "observatory" metaphor itself — actual observatories are dark environments with luminous readouts

**The hybrid possibility:**
- Dark panels on a warm background (warm frame, dark instrument readouts)
- Light background with dark-mode KPI strips and status indicators
- Mode-aware toggle (Library pages light, Observatory pages dark)
- Per-panel dark where data density demands it, warm surround for the frame

## Exploration Scope for MC-002

Three aesthetic directions will be explored via a single HTML/CSS file with CSS custom properties enabling palette toggling (per AP-9):

### Direction A: Warm Observatory
Cream/parchment background throughout. Panels as warm-toned cards with subtle borders. Status colors tuned as warm equivalents (forest green, burnt amber, brick red). Analog readouts in brass/copper tones. The "antique barometer mounted on a library wall" feeling.

### Direction B: Dark Observatory
Dark background (not black — charcoal, deep slate, or dark navy). Panels as slightly lighter dark cards. Status colors at full saturation against the dark field. Analog readouts as luminous instruments against dark. Sparklines glow. The "observatory at night with luminous dials" feeling.

### Direction C: Hybrid
Warm frame (nav rail, page header, section headers on cream). Dark panel interiors where data lives. Status colors pop within the dark panels. Serif headers in warm tones, data in bright readouts. The "wooden instrument cabinet with dark face plates" feeling.

**Implementation approach:** One HTML file, one CSS file. Layout and widget structure identical across all three. ~12 CSS custom properties define the palette — toggling between directions is a variable swap, not a layout change. This keeps the exploration focused on color/mood, not structure.

## Design Advisor Lens (applied)

1. **Visual hierarchy:** Eye hits KPI strip first (status at a glance), then service grid/cards (detail), then timeline/trends (context). Three clear tiers.
2. **Design system:** This project establishes one. Phase 0 is the creation moment.
3. **Medium/viewport:** Desktop-primary (1440px+), with mobile viewport tested for Attention/Ops readability at 375px. Not a mobile app — a workstation tool.
4. **Typography:** Serving both readability (serif headers) and data clarity (monospace values). The serif/mono split is the key typography decision.
5. **Color:** Functional only. Every hue carries meaning (status, urgency, interactivity). No decorative color.
6. **Negative space:** Widget grids inherently provide structure. Risk is cramming too many widgets per panel — respect the 3-7 per section guideline.
7. **Interaction path:** Scan KPI strip → identify anomaly → drill into relevant panel → click card for detail. Standard dashboard flow.
8. **Hick's Law:** 4-6 sections per page. Nav rail has 6 pages (expandable to 8). Manageable.
9. **Fitts's Law:** Interactive targets (filter buttons, card click zones, quick-add) sized generously. Read-only indicators (status dots, sparklines) smaller.
10. **Tesler's Law:** Default views immediately useful. No configuration required to see "what needs me?" or "is the house on fire?"

## DataViz Lens (applied)

- **Data-ink ratio:** Maximize. No decorative gridlines, no 3D effects, no gradient fills. The analog aesthetic is about *character*, not *ornament* — a gauge communicates data, it's not decoration.
- **Direct labeling:** Values on widgets, not in detached legends.
- **Cleveland-McGill:** Position on common scale (bar charts, KPI strips) for precise comparisons. Color saturation for status categories only.
- **Small multiples:** 24h timeline events, per-source signal breakdowns, cost-by-job panels.
- **Preattentive features:** Status color for immediate pop-out. Size for importance. Position for temporal ordering.

## Web Design Preference Lens (applied)

1. **Mode:** Observatory confirmed.
2. **Typography:** Serif foundation intact. ET Book or Source Serif body, monospace data, sans chrome.
3. **Color discipline:** Functional color only. Status palette + one accent. Direction A/B/C explore the background question.
4. **Layout:** Full-width widget grid. No narrow columns. Information density welcome.
5. **Jakob's Law tension:** Dashboard interactions (nav, filter, drill-down, card expand) must use standard patterns to compensate for the unconventional aesthetic. No novel interaction mechanics.
6. **Character:** Private library crossed with a well-equipped workshop. Analog instruments, not SaaS stat cards. Serious but warm.

## Key Questions for MC-002 Evaluation

When reviewing the three directions, evaluate:

1. Can you answer "is the house on fire?" in <5 seconds on the Ops mock?
2. Does the status color palette (green/amber/red or equivalents) communicate clearly against the background?
3. Does the typography remain readable at data density? (Monospace numbers in panels, serif headers)
4. Does it feel like *yours* — not like a corporate dashboard, not like a dev tool, not like a SaaS product?
5. Does the analog instrument aesthetic work in this color context, or does it feel forced?
6. At 375px viewport width, is the KPI strip still scannable?

## Mockup Workspace

All Phase 0 design artifacts live in `Projects/mission-control/design/mockups/`:
- `ops-mockup.html` — the primary MC-002 deliverable (Ops page, three palette variants)
- `ops-mockup.css` — shared styles with CSS custom property palette toggle
- Supporting files as needed (fonts, SVG gauge components)

## Design Decisions (MC-003 scope)

### D1: Dark mode selected
Dark Observatory is the chosen direction. Status colors pop, reduced eye strain during monitoring, aligns with observatory-at-night metaphor. The warm/hybrid palettes remain in CSS as reference but dark is the default and production target.

### D2: Minimum text size — 13px universal floor
All text across all contexts renders at 13px (0.8125rem) minimum. This is a hard constraint for the design system — no text smaller than 13px in any theme, viewport, or component. Enforced via the chrome tier (Inter sans-serif) bump, but applies equally to monospace data values and serif body. Rationale: dark backgrounds require slightly larger text for equivalent readability vs light backgrounds.

### D3: Minimum text size — 14px for data values
Service card values and LLM stat text bumped to 14px (0.875rem) to visually balance against uppercase chrome labels. The 13px floor applies to chrome labels; data-tier text sits at 14px. Two-tier minimum: 13px chrome, 14px data.

### D4: LLM Status section added to Ops page
New section at same level as Services and Cost Burn. Cards per provider/model showing: success rate, p95 latency, call count, and degradation notes when issues are detected. Data source: ops metrics harness (TOP-050 structured run logs) aggregated by model/provider. Gray/stale state for models with no recent calls.

### D5: LLM Status section order — above Cost Burn
Section order on Ops page: System Status → Resource Gauges → Services → 24h Timeline → LLM Status → Cost Burn. LLM health is operational priority; cost is informational context.

### D6: Aesthetic direction — Dark Observatory (MC-003 decision)
**Selected:** Direction B (Dark Observatory). Charcoal background (#1c1f26), bright status colors, teal-green accent (#5cb8a4). Rationale: status colors pop dramatically, reduced eye strain, aligns with observatory-at-night metaphor, operator's clear preference after reviewing all three variants side by side. Warm and hybrid palettes retained in CSS as reference/fallback. Gate item 12 (§9.1) satisfied.

## References

- `_system/docs/www-design-taste-profile.md` — full taste profile (Mode 2 Observatory section)
- `_system/docs/overlays/design-advisor.md` + `design-advisor-dataviz.md` — design + dataviz lenses
- `_system/docs/overlays/web-design-preference.md` — personal aesthetic lens
- `design/specification.md` §9.1-9.3 — design system requirements, Observatory principles, interaction principles
- `design/tasks.md` MC-001 through MC-003 — Phase 0 M0a task definitions
