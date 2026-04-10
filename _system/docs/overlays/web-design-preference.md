---
type: overlay
domain: null
status: active
created: 2026-02-23
updated: 2026-03-06
tags:
  - overlay
  - design
  - web
---

# Web Design Preference

Personal aesthetic lens for Danny's web properties. Companion to the generic
Design Advisor — that overlay asks "is this good design?", this one asks
"is this Danny's design?" Full source: `_system/docs/www-design-taste-profile.md`.

Core identity: **scholarly warmth meets functional precision.** Enlightenment
visual culture — serif typography, warm paper tones, detailed craft, data
presented as instrument readouts not SaaS dashboards. Design in service of
content, never design as the main event.

## Activation Criteria

**Signals** (match any → consider loading):
Personal site design, Danny's web projects, digest templates, vault-facing UI,
dashboard or status panel design for personal systems, Enlightenment aesthetic
application, site mode selection (Library/Observatory/Cartographer).

**Anti-signals** (match any → do NOT load, even if signals match):
- Work for external stakeholders or clients with their own brand guidelines
- Purely backend/logic tasks with no visual output
- Functional-only UI where aesthetic judgment isn't needed (CLI tools, scripts)

**Canonical examples:**
- ✓ x-feed-intel digest HTML template — Library mode, needs taste alignment
- ✓ Personal blog or wiki design — Library mode, core use case
- ✓ Crumb system dashboard — Observatory mode, analog readout aesthetic
- ✗ Client deliverable following their brand guide — their taste, not Danny's
- ✗ Internal CLI tool or shell script — no visual design surface

## Lens Questions

1. **Mode selection:** Which structural mode applies — Library (reading/reference), Observatory (dashboards/metrics), or Cartographer's Table (spatial graphs/canvas)? Each has distinct layout patterns; pick before designing.
2. **Typography:** Is the serif foundation intact? Body text in ET Book, Source Serif, or equivalent bookish serif. Monospace for code with clear visual separation. Sans-serif permitted only for functional chrome (nav labels, button text, metadata tags) — never for body or headings.
3. **Color discipline:** Warm off-white/cream/parchment background, black body text. One or two accent colors that carry meaning (link states, status, categories). No decorative color. Functional only — every hue must justify its presence. No dark mode as default.
4. **Layout and density:** Is the screen width being used? Narrow centered columns with dead margins are a consistent negative. Library mode uses Tufte-style active margins (sidenotes, figures, annotations). Observatory uses full-width widget grids. Information density is welcome if well-structured.
5. **Jakob's Law tension:** The Enlightenment aesthetic deliberately breaks from mainstream web conventions. This means interaction patterns (navigation, search, filtering, link behavior) must be *more* predictable than usual to compensate for the unfamiliar visual language. Novel aesthetics + novel interactions = user confusion. Novel aesthetics + familiar interactions = user delight.
6. **Character and graphic style:** Does this feel like a private library crossed with a well-equipped workshop? Serious but warm, personal and opinionated, content-first. Not sterile (GOV.UK), not playful (Poolsuite), not showy (Rauno). If data is displayed, does it feel like vintage instruments and observatory equipment, or flat SaaS stat cards? If illustrations or graphic elements are present, do they follow the Enlightenment aesthetic — botanical plates, scientific diagrams, engraving-style artwork, cartographic elements — rather than stock icons or decorative filler? Small, purposeful graphic touches (a meaningful accent, a visual punctuation mark) over ornament.

## Key Frameworks

- **Library mode** (Gwern.net, Tufte CSS, The Marginalian): Single-column with active Tufte margins, serif body, page-level metadata bar, rich cross-linking, historical illustrations, warm background with 1-2 functional accent colors.
- **Observatory mode** (Grafana, Linear): Widget grid at full width, warm light background, analog-feeling readouts (gauges, dials, meters), serif panel headers, functional status color (green/amber/red), sparklines and trend indicators.
- **Cartographer's Table mode** (Obsidian Canvas, historical cartography): Zoomable spatial canvas, nodes with serif labels connected by hand-drawn-style routes, warm tones, subtle pulse animation for active items. Most experimental — "what if an 18th century cartographer designed a system monitoring canvas."

## Anti-Patterns

- Dark mode as default — warm, light canvases are the foundation (including dashboards — the most tempting dark-mode use case)
- Sans-serif body text — clinical, generic, personality-free
- Narrow centered content with wasted margins — respect the screen
- Decorative color, emoji icons, cartoon illustrations — color without meaning is noise
- Flat digital stat cards — prefer analog, characterful readouts
- Design as the main event — if the design draws attention to itself over the content, it's wrong
- Marketing patterns (hero images, CTA buttons, testimonial carousels) — irrelevant for personal tools
