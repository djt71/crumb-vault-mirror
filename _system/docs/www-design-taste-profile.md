---
type: reference
domain: creative
status: active
created: 2026-02-21
updated: 2026-03-06
tags:
  - design
  - web
  - personal
---

# Design Taste Profile — Danny's Personal Sites

*Generated February 21, 2026 — based on a structured review of 11 websites*

---

## Core Aesthetic Identity

Your design taste sits at a distinctive intersection: **scholarly warmth meets functional precision**. You're drawn to design that feels like it was made by someone who reads old books, builds real things, and respects your intelligence. The closest historical analog is the visual culture of the Enlightenment — detailed illustrations, elegant serif typography, warm paper tones, and data presented as craft rather than commodity.

You want design **in service of content**, never design as the main event.

---

## Foundational Principles

These apply across all site types:

### Typography
- **Serif fonts are non-negotiable.** You respond strongly to literary, bookish typefaces — the kind used on Gwern.net (Charter/Source Serif) and in the Tufte CSS framework (ET Book). These evoke printed books and academic papers.
- **Italic serif for quotations and emphasis** — the XXIIVV quotation font triggered an immediate positive response.
- **Monospace for code blocks and technical content** — the font switchup between prose and code on Tufte CSS appealed to you. This creates clear visual separation between narrative and technical material.
- **Sans-serif is generally a negative signal.** GOV.UK, Nomad List, and 100r.co all used sans-serif and all drew flat or negative reactions. The exception is *functional UI chrome* (nav labels, button text, metadata tags) where sans-serif can serve as a supporting player.

### Color Philosophy
- **Restrained base palette.** Warm off-whites, creams, parchment tones for backgrounds. Black or near-black for body text. Think aged paper, not sterile white or dark mode.
- **Color as spotlight, not wallpaper.** You want one or two accent colors that *mean something* and pop against the quiet background. Obsidian's purple was the positive example — it has impact precisely because everything around it is restrained.
- **Functional color only.** Every color should carry meaning: status indicators, link states, category markers, alert levels. Grafana's green-for-healthy, red-for-alert approach resonated. Decorative color (Nomad List's rainbow emoji bullets, Luma's gradient pastels) is a hard no.
- **No dark mode as default.** You acknowledged Linear's dark UI was "too dark." Warm, light backgrounds are your canvas.

### Layout & Space
- **Use the full screen width.** Narrow centered columns with dead margins are a consistent complaint (Gwern, XXIIVV, 100r.co). You want your monitor's real estate respected.
- **Tufte-style margin notes** are the ideal solution: maintain a readable main column (~65-75 characters) while putting the margins to work for sidenotes, annotations, figures, and metadata.
- **Information density is welcome** — as long as it's well-structured. You don't want minimalism for its own sake. Dense, readable, and well-organized beats sparse and pretty.

### Graphic Style
- **"Age of Enlightenment" illustration aesthetic.** Detailed, craft-heavy, almost engraving-like artwork. Botanical illustrations, scientific diagrams, cartographic elements, woodcuts. The XXIIVV hermetic/alchemical emblem and Tufte's historical charts (Minard's Napoleon campaign, Playfair's trade balance) both triggered strong positive reactions.
- **Analog over digital.** When displaying data, you prefer readouts that feel like vintage instruments, gauges, or hand-drawn charts rather than flat digital stat cards. Think observatory equipment, not SaaS dashboard.
- **Small, purposeful graphic touches.** Linear's yellow star, Obsidian's purple accent dots — tiny details that reward attention. Not decorative illustration, but meaningful visual punctuation.

### Mood & Character
- **Serious but warm.** Not sterile (GOV.UK), not playful (Poolsuite), not showy (Rauno). Somewhere between a private library and a well-equipped workshop.
- **Personal and opinionated.** Your sites should feel like *yours* — with character, specificity, and taste. Government-grade neutrality is boring. Design-school showmanship is hollow.
- **Content-first always.** Design serves the material. If something is beautiful but doesn't help you find, read, or understand information better, it doesn't belong.

---

## Interaction Principles

These principles govern how interfaces *behave*, complementing the aesthetic
principles above. The Web Design Preference overlay prompts the questions;
this section provides mode-specific rationale.

### Jakob's Law Tension
The Enlightenment aesthetic deliberately breaks mainstream visual conventions.
This creates a design contract: interaction patterns (navigation, search,
filtering, link behavior, scroll behavior) must be *more* predictable than
usual to compensate for the unfamiliar visual language. Novel aesthetics +
novel interactions = user confusion. Novel aesthetics + familiar interactions
= user delight. Every interaction pattern should pass the test: "would a
first-time visitor know what to do here without thinking?"

### Hick's Law — Navigation Structure
Each site mode has different navigation complexity needs:
- **Library:** Deep content, many pages. Use hierarchical navigation with progressive disclosure — table of contents, tag filtering, search. Don't present the full site map at once.
- **Observatory:** Many widgets, but navigation is spatial (scroll the grid). Keep panel groupings to 4-6 sections maximum. Within each section, 3-7 widgets.
- **Cartographer's Table:** Navigation is zoom/pan. Provide clear entry points (named regions, a legend) — don't drop the user on an unlabeled infinite canvas.

### Fitts's Law — Mode-Specific Target Sizing
- **Library:** Primary interactions are links and TOC entries. Links should have generous click targets (padding, not just text underline). TOC entries should be easy to hit, especially on mobile.
- **Observatory:** Widget controls (filters, time range selectors, drill-down buttons) are high-frequency targets — size them generously. Status indicators are read-only and can be smaller.
- **Cartographer's Table:** Canvas nodes are the primary targets. Minimum node size must account for zoom level — nodes that are easy to click at 100% zoom may be impossible at 50%.

### Tesler's Law — Complexity Allocation
- **Library:** Content complexity is the reader's job — dense, referenced, interlinked content is welcome. But *finding* content should be simple. The system absorbs navigation complexity (search, cross-linking, metadata filtering).
- **Observatory:** The viewer should never have to configure the dashboard to see useful information. Default views should be immediately legible. Complexity lives in the data pipeline, not the display layer.
- **Cartographer's Table:** The system manages layout, connection routing, and zoom semantics. The user's job is interpretation, not arrangement.

### Doherty Threshold — Response Budget
- **Library:** Static content — page loads and navigation transitions are the main interaction. Target <400ms for page-to-page navigation. Margin note expansion and TOC scroll should be instant (<100ms).
- **Observatory:** Live data means continuous updates. Widget refresh should be invisible (no full-page reload). Data staleness indicator preferred over loading spinners. Target <400ms for any user-initiated action (filter change, time range adjustment).
- **Cartographer's Table:** Zoom and pan must be <16ms per frame (60fps) to feel responsive. Node expansion on click <200ms. This is the most performance-sensitive mode.

---

## Site Modes

Your projects fork into distinct design modes that share the DNA above but serve different structural purposes.

### Mode 1 — "The Library"
**Use cases:** Blog/writing, reference wiki, NotebookLM output, Crumb knowledge base pages

**Primary references:** Gwern.net (structure, metadata, typography), Tufte CSS (margin notes, illustrations, reading experience), The Marginalian (content architecture, cross-linking)

**Key characteristics:**
- Single-column centered layout with active Tufte-style margins for sidenotes, figures, and annotations
- Serif body text, justified with hyphenation (Gwern-style) or left-aligned with generous leading
- Structured metadata at page level: date, status, certainty, importance, tags — visible but not dominant (Gwern's metadata bar)
- Rich cross-linking: backlinks, related pages, bibliography sections, inline references
- Table of contents for long-form pieces, either inline or floating in the margin
- Full-width breakout for large figures, charts, and illustrations
- Historical/Enlightenment-style illustrations where appropriate
- Code blocks in monospace with clear visual distinction from prose
- Warm off-white background, black text, one or two functional accent colors for links and tags

### Mode 2 — "The Observatory"
**Use cases:** Operational dashboards, system monitoring, metric displays, status panels

**Primary references:** Grafana (widget grid, panel architecture, functional color), Linear (information density, clean structure, purposeful accents)

**Key characteristics:**
- Widget grid layout using full screen width — panels arranged in a responsive grid, each a self-contained information unit
- Warm light background (not dark mode), with panels having subtle borders or card-style containment
- Analog-feeling readouts: gauges, meters, dials, and charts styled to evoke vintage scientific instruments rather than flat digital counters
- Serif labels and headers on panels; small sans-serif for secondary metadata within widgets
- Sparklines, trend indicators, and small multiples — data that's alive and moving
- Functional color for status: a deliberate, limited palette where green/amber/red (or equivalent) map to system states
- One strong accent color for interactive elements and highlights
- Structured sections or groupings of related panels (e.g., "System Health," "Active Projects," "Recent Activity")

### Mode 3 — "The Cartographer's Table"
**Use cases:** Mission control canvas, knowledge graphs, project maps, Crumb/Tess system visualization

**Primary references:** Obsidian Canvas/Graph View, network visualizations, historical cartography

**Key characteristics:**
- Spatial canvas layout — zoomable, pannable infinite surface
- Nodes representing knowledge domains, projects, tasks, or system components, connected by visible relationship lines
- Rich node previews: clicking/hovering reveals content, metadata, status
- Graph aesthetics: warm tones, serif labels on nodes, connection lines styled more like hand-drawn cartographic routes than sterile digital edges
- Ability to zoom out for the big picture (high-level topology) and zoom in for detail (individual node content)
- Subtle animation: nodes that pulse gently for active/recent items, connections that highlight on interaction
- This mode is the most experimental and distinctive — essentially "what if an 18th century cartographer designed a system monitoring canvas"

---

## Anti-Patterns (What to Avoid)

| Pattern | Why it fails for you |
|---|---|
| Dark mode as default | Too heavy; you prefer warm, light canvases |
| Sans-serif body text | Feels clinical, generic, personality-free |
| Narrow centered content | Wastes screen width; feels like mobile-first on desktop |
| Video backgrounds | Distracting, competes with content |
| Cartoon/emoji icons | Too playful, lacks seriousness |
| Decorative color | Color without meaning is noise |
| Marketing-heavy layouts | Hero images, CTA buttons, testimonial carousels — all irrelevant for personal tools |
| "Design as art gallery" | Horizontal scroll, oversized poster typography, style over substance |
| Flat digital stat cards | Prefer analog-feeling, characterful readouts |
| Pure minimalism without structure | Austerity needs to be paired with organizational richness |

---

## Reference Palette

### Positive References (Ranked)
1. **Gwern.net** — Strongest overall match. Typography, structure, metadata, monochrome discipline, information density.
2. **Tufte CSS** — Best reading experience. Margin notes solve the width problem. Historical illustrations. Warm tones.
3. **Grafana dashboards** — Best structural reference for Mode 2. Widget grid, functional color, live data.
4. **Obsidian Canvas/Graph View** — Best reference for Mode 3. Spatial layout, connected nodes, interactive exploration.
5. **Linear.app** — Selective inspiration. Purposeful accent color, clean information hierarchy, functional graphic touches.

### Negative References
- **Rauno.me** — Design as main event, not content
- **Poolsuite** — Right principle (historical aesthetic + functional UI) but wrong era and tone
- **GOV.UK** — Excellent but soulless
- **Nomad List / Nomads.com** — Generic SaaS marketing aesthetic
- **Luma** — Playful consumer product, nothing relevant

---

## Concrete Next Steps

1. **Pick a type stack.** Start with ET Book (the Tufte font) or Source Serif Pro for body, paired with a monospace like JetBrains Mono or IBM Plex Mono for code. Test both against your content.

2. **Define the accent color.** Pick one strong color that will serve as your primary interactive/highlight accent across all modes. Deep teal, burgundy, or a rich amber would all fit the warm Enlightenment palette. Test it against cream/off-white backgrounds.

3. **Prototype Mode 1 first.** A single wiki/reference page using Tufte CSS as the foundation. Add Gwern-style metadata (status, certainty, tags). This is the lowest-risk, highest-learning starting point.

4. **Collect illustration assets.** Start building a library of public-domain Enlightenment-era graphics: scientific diagrams, botanical plates, cartographic elements, instrument drawings. Sources: Biodiversity Heritage Library, Internet Archive, Wellcome Collection, David Rumsey Map Collection.

5. **Sketch the dashboard widget vocabulary.** Before building Mode 2, define what widgets you need (status indicator, trend chart, activity feed, gauge, counter, etc.) and sketch how each would look in the "analog observatory" style.

6. **Canvas exploration.** For Mode 3, experiment with libraries like D3.js force-directed graphs or Cytoscape.js, styled with your warm palette and serif labels. This is the most technically ambitious mode.

---

*This document should be updated as design decisions are made and refined through prototyping.*
