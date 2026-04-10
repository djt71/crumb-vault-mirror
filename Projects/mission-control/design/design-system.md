---
project: mission-control
type: design-system
domain: software
status: active
created: 2026-03-07
updated: 2026-03-30
tags:
  - design
  - dashboard
  - web
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Mission Control — Design System

**Task:** MC-004
**Aesthetic direction:** Dark Observatory (D6)
**Source:** Derived from `design/mockups/ops-mockup.css` (MC-002) and design decisions D1-D6

## 1. Color System

### 1.1 Background Tones

| Token | Value | Usage |
|-------|-------|-------|
| `--bg-page` | `#1c1f26` | Page background — deep charcoal with blue undertone |
| `--bg-nav` | `#151820` | Nav rail background — darkest surface |
| `--bg-panel` | `#242830` | Panel/card background — primary content surface |
| `--bg-panel-header` | `#2a2e38` | Panel header row — subtle lift from panel body |
| `--bg-kpi` | `#242830` | KPI card background — matches panel surface |

### 1.2 Borders

| Token | Value | Usage |
|-------|-------|-------|
| `--border-panel` | `#363b48` | Panel and card borders — visible structure |
| `--border-subtle` | `#2e3340` | Low-contrast separators within panels |

### 1.3 Text Colors

| Token | Value | Usage |
|-------|-------|-------|
| `--text-primary` | `#e8e4dc` | Primary text — warm off-white |
| `--text-secondary` | `#a09888` | Secondary text — muted warm tone |
| `--text-tertiary` | `#706860` | Tertiary/chrome text — low emphasis |
| `--text-inverse` | `#1c1f26` | Text on accent/bright backgrounds |

### 1.4 Accent

| Token | Value | Usage |
|-------|-------|-------|
| `--accent` | `#5cb8a4` | Teal-green — interactive elements, active states, links |
| `--accent-hover` | `#7ccebe` | Lighter teal — hover state |
| `--accent-muted` | `rgba(92, 184, 164, 0.12)` | Subtle background tint — large areas only (section highlights, hover backgrounds) |
| `--accent-selected` | `rgba(92, 184, 164, 0.22)` | Stronger tint — selected filter states, active tab backgrounds, selected cards in lists |

### 1.5 Status Palette (Functional Color)

Every hue carries meaning. No decorative color.

| Token | Value | Meaning |
|-------|-------|---------|
| `--status-ok` | `#4aba7a` | Healthy / passing / normal |
| `--status-ok-bg` | `rgba(74, 186, 122, 0.12)` | OK background tint |
| `--status-warn` | `#e0a830` | Degraded / approaching threshold |
| `--status-warn-bg` | `rgba(224, 168, 48, 0.12)` | Warning background tint |
| `--status-error` | `#e05545` | Failed / critical / down |
| `--status-error-bg` | `rgba(224, 85, 69, 0.12)` | Error background tint |
| `--status-stale` | `#706860` | No recent data / idle / unknown |
| `--status-stale-bg` | `rgba(112, 104, 96, 0.10)` | Stale background tint |

### 1.5a Disabled / Loading State

| Token | Value (Dark) | Usage |
|-------|-------|-------|
| `--bg-skeleton` | `#2e3340` | Skeleton loading placeholder background — gentle lift from panel surface |
| `--text-disabled` | `#504a44` | Text for unavailable/disabled content — dimmer than tertiary |

Applied in four state patterns (see §3.8): blocked, empty, error, stale.

### 1.6 Data Visualization Colors

| Token | Value | Usage |
|-------|-------|-------|
| `--sparkline-stroke` | `#5cb8a4` | Sparkline line (accent) |
| `--sparkline-fill` | `rgba(92, 184, 164, 0.10)` | Sparkline area fill |
| `--gauge-track` | `#363b48` | Gauge background arc |
| `--gauge-fill-ok` | `#4aba7a` | Gauge fill — healthy range |
| `--gauge-fill-warn` | `#e0a830` | Gauge fill — approaching threshold |
| `--gauge-fill-error` | `#e05545` | Gauge fill — critical range |
| `--gauge-label` | `#a09888` | Gauge label text (secondary) |
| `--gauge-value` | `#e8e4dc` | Gauge value text (primary) |
| `--timeline-dot-heartbeat` | `#4aba7a` | Heartbeat events (green) |
| `--timeline-dot-alert` | `#e05545` | Alert events (red) |
| `--timeline-dot-mode` | `#e0a830` | Mode transition events (amber) |
| `--timeline-dot-maintenance` | `#706860` | Maintenance events (gray) |
| `--timeline-bg` | `#2a2e38` | Timeline track background |
| `--timeline-grid` | `#363b48` | Timeline grid lines |

### 1.7 Shadows

| Token | Value | Usage |
|-------|-------|-------|
| `--shadow-panel` | `0 1px 3px rgba(0,0,0,0.25)` | Default panel elevation |
| `--shadow-panel-hover` | `0 2px 10px rgba(0,0,0,0.40)` | Hover/interactive elevation |

### 1.8 Badge & Table

| Token | Value | Usage |
|-------|-------|-------|
| `--badge-personal-bg` | `rgba(160, 152, 136, 0.15)` | Personal kind badge background — brighter than `--status-stale-bg` (0.10) to distinguish "personal" from "stale/idle". Reused across Attention, Knowledge, and Agent Activity pages. |
| `--table-row-alt` | `rgba(42, 46, 56, 0.4)` | Data table alternating row tint — subtle lift from panel background. Used across Ops, Agent Activity, and Knowledge page tables. |

### 1.9 Focus & Keyboard

| Token | Value | Usage |
|-------|-------|-------|
| `--focus-ring` | `0 0 0 2px var(--bg-panel), 0 0 0 4px var(--accent)` | Keyboard focus indicator — 2px accent ring with panel-color gap for contrast against both dark and accent backgrounds |

Applied via `:focus-visible` (not `:focus`) to avoid showing focus rings on mouse clicks. All interactive elements — cards, buttons, form inputs, nav items, filter controls — must show the focus ring on keyboard navigation.

### 1.10 Navigation

| Token | Value | Usage |
|-------|-------|-------|
| `--nav-icon` | `#706860` | Inactive nav icon |
| `--nav-icon-active` | `#5cb8a4` | Active nav icon (accent) |
| `--nav-badge-bg` | `#e05545` | Badge background (error red — urgency) |
| `--nav-badge-text` | `#e8e4dc` | Badge text |

## 2. Typography Scale

### 2.1 Font Families

| Role | Family | Weight | Usage |
|------|--------|--------|-------|
| **Serif** | Source Serif 4 | 400, 600, 700 | Page titles, section content, panel headers |
| **Monospace** | JetBrains Mono | 400, 500 | Data values, KPI numbers, timestamps, code |
| **Sans-serif** | Inter | 400, 500, 600 | Chrome labels, nav labels, metadata, badges, buttons |

### 2.2 Size Scale

**Hard constraints (D2, D3, AP-21):**
- 13px (0.8125rem) — universal minimum. No text renders smaller in any context.
- 14px (0.875rem) — data-tier minimum. Service values, LLM stats, monospace readouts.

| Size | rem | px | Usage |
|------|-----|-----|-------|
| **Page title** | 1.5rem | 24px | Page header (`Source Serif 4`, 700) |
| **KPI value** | 1.35rem | ~22px | KPI card primary number (`JetBrains Mono`, 500) |
| **Gauge value** | 1.5rem | 24px | SVG gauge center number (`JetBrains Mono`, 500) |
| **Cost total** | 1.1rem | ~18px | Cost panel header total (`JetBrains Mono`, 500) |
| **Panel title** | 0.95rem | ~15px | Service card name, timeline title (`Source Serif 4`, 600) |
| **Data value** | 0.875rem | 14px | Service meta, LLM stats, cost bar values (`JetBrains Mono`) |
| **Chrome label** | 0.8125rem | 13px | KPI labels, section titles, gauge labels, nav labels (`Inter`, 500-600) |
| **Timestamp** | 0.8125rem | 13px | Refresh time, timeline hour labels (`JetBrains Mono`) |

### 2.3 Typography Rules

- **Section titles:** Inter sans-serif, 13px, 600 weight, uppercase, letter-spacing 0.08em
- **KPI labels:** Inter sans-serif, 13px, 500 weight, uppercase, letter-spacing 0.06em
- **Nav labels:** Inter sans-serif, 13px, 500 weight, uppercase, letter-spacing 0.03em
- **Body line-height:** 1.5 (base), 1.2 (KPI values, gauge values)
- **Font smoothing:** antialiased on both WebKit and Firefox

## 3. Panel Component

The panel is the primary containment element. All dashboard content lives inside panels.

### 3.1 Panel Variants

**Standard panel** — sections like timeline, cost burn, LLM status:
- Background: `--bg-panel` (`#242830`)
- Border: 1px solid `--border-panel` (`#363b48`)
- Border-radius: 8px
- Padding: 20px
- Shadow: `--shadow-panel`

**KPI card** — compact metric display:
- Background: `--bg-kpi` (`#242830`)
- Border: 1px solid `--border-panel`
- Border-radius: 8px
- Padding: 14px 16px
- Shadow: `--shadow-panel`

**Service card** — interactive clickable card:
- Same as standard panel
- Padding: 16px
- Cursor: pointer
- Hover: shadow transitions to `--shadow-panel-hover`
- Transition: 0.15s

**Gauge container** — analog readout:
- Same as standard panel
- Text-align: center
- SVG centered with 8px bottom margin

### 3.2 Panel Header

When a panel has a header row:
- Background: `--bg-panel-header` (`#2a2e38`)
- Used for distinct header regions within panels (timeline header, cost header)
- Contains: title (Source Serif, 15px, 600) + secondary element (legend, total, etc.)
- Layout: flex, space-between, baseline alignment
- Margin-bottom: 16px from content

### 3.3 Panel Spacing

- **Between sections:** 32px (`.section` margin-bottom)
- **Between cards in a grid:** 12px gap
- **Between gauge containers:** 16px gap
- **Page body padding:** 24px 32px 48px
- **Page header padding:** 20px 32px 16px

### 3.4 Grid Layouts

| Grid | Columns | Min Width | Gap |
|------|---------|-----------|-----|
| KPI strip | `auto-fit` | 140px | 12px |
| Service grid | `auto-fill` | 260px | 12px |
| Gauge row | `auto-fit` | 180px | 16px |

### 3.5 Interactive States

- **Hover (cards):** Shadow deepens from `--shadow-panel` to `--shadow-panel-hover`
- **Focus (keyboard):** `box-shadow: var(--focus-ring)` via `:focus-visible`. Outline set to `none` (ring replaces it).
- **Active nav item:** Left border accent bar (3px, `--accent`, rounded), icon color switches to `--accent`
- **Selected (filters/tabs):** Background switches to `--accent-selected`
- **Status dot:** 8px circle, inline with 6px right margin, color from status palette
- **Nav status dot:** 6px circle, positioned top-right of nav item

### 3.6 Transition Conventions

Default transition: `0.15s ease-out` for all interactive state changes (hover, focus, selection). Applies to: `box-shadow`, `color`, `background-color`, `border-color`, `opacity`. No transitions on layout properties (`width`, `height`, `margin`) — these reflow and should snap. Gauge fill arcs use `0.6s ease` (data update, not interaction).

### 3.7 Status Indicators

**Inline status dot:**
- 8px diameter circle
- Colors: `.ok` / `.warn` / `.error` / `.stale`
- Used in service card headers, KPI cards

**Nav status dot:**
- 6px diameter circle
- Positioned absolute, top-right of nav item
- Shows page-level health derived from adapter error roll-up

**Nav badge:**
- Background: `--nav-badge-bg` (error red)
- Text: `--nav-badge-text`, Inter 13px 600
- Min-width: 20px, height: 20px, pill shape (border-radius: 10px)
- Shows count of items needing attention

### 3.8 State Patterns

The adapter `{data, error, stale}` contract produces four visual states. Each works at three levels: full panel, KPI card, and card-within-list.

**Blocked / Placeholder** — upstream dependency not yet available:
- Dashed border (`1px dashed --border-panel`), 50% opacity
- Stale status dot + italic description text
- Class: `.blocked-panel` (widget-vocabulary.css)

**Empty** — adapter succeeded, zero items returned:
- Centered layout, calm tone (not broken)
- Muted icon (32px, `--text-disabled`, 60% opacity) + descriptive text
- KPI card: value and sub-label in `--text-disabled`
- Class: `.state-empty` (widget-vocabulary.css)

**Error** — adapter failed:
- Error banner with `--status-error-bg` background
- Icon (16px, `--status-error`) + error text + retry/context metadata
- KPI card: border turns `--status-error`, value in error color
- Card-within-list: border and background turn error-tinted
- Classes: `.state-error-banner`, `.state-error`, `.kpi-card.state-error`

**Stale** — data exists but past freshness threshold:
- Amber warning banner (`--status-warn-bg`) with clock icon
- Shows age and threshold: "Data is 45 minutes old (threshold: 3 minutes)"
- Data renders normally below the banner
- KPI card: left border accent turns `--status-warn` (3px)
- Card-within-list: 2px amber top stripe via `::before` pseudo-element
- Classes: `.state-stale-banner`, `.kpi-card.state-stale`, `.signal-card.state-stale`

All state pattern CSS lives in `widget-vocabulary.css` (cross-page concern).

### 3.9 Dense List View Constraints [S-3]

The Intelligence Pipeline section uses a dense list layout (`.signal-row`) instead of card layout. These constraints apply to all dense list views:

- **Text-only source labels.** No favicons, avatars, thumbnails, or source logos in item rows. Images break the scanline rhythm and add visual noise that fights the score-badge pattern. Source identification uses short text labels (e.g., "X", "RSS", "HN").
- **Zero card chrome.** No `border`, `border-radius`, `box-shadow`, or padding containers on individual rows. Rows separated by `--border-subtle` bottom divider only.
- **Single-line rows.** Title + thesis inline on one line (truncated at ~80 chars), not stacked. Score badge left margin, source + timestamp right-aligned. Vertical space per item minimized.
- **Score badge color from tier config.** Background color derived from shared tier configuration boundaries, not hardcoded. See [AP-22].

## 4. Responsive Behavior

**Breakpoint:** 480px (mobile test viewport: 375px)

| Element | Desktop | Mobile (≤480px) |
|---------|---------|-----------------|
| Nav rail width | 64px | 48px |
| Page body padding | 24px 32px | 16px |
| Page title | 1.5rem | 1.15rem |
| KPI strip | auto-fit, 140px min | 2 columns |
| KPI value | 1.35rem | 1.1rem |
| Service grid | auto-fill, 260px min | Single column |
| Gauge row | auto-fit, 180px min | 2 columns |
| Cost bar label | 120px min | 80px min |

Text size floors (13px chrome, 14px data) apply at all viewports.

## 5. Warm/Hybrid Palette Reference

The warm (Direction A) and hybrid (Direction C) palettes are retained in `ops-mockup.css` as CSS custom property sets marked by `/* PALETTE: WARM */` and `/* PALETTE: HYBRID */` comment headers. They are not the production target but serve as reference and potential future toggle capability.

## References

- `design/aesthetic-brief.md` — design decisions D1-D6
- `design/mockups/ops-mockup.css` — source CSS with all three palette variants
- `design/specification.md` §9.1-9.3 — design system requirements
- `_system/docs/www-design-taste-profile.md` — Observatory mode principles
