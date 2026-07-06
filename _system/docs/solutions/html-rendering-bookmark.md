---
type: reference
domain: software
status: resolved
track: convention
linkage: discovery-only
created: 2026-02-20
updated: 2026-07-05
tags:
  - diagramming
  - data-viz
  - kb/software-dev
topics:
  - moc-crumb-operations
---

# HTML Rendering Skill — Bookmark

## Status: Resolved 2026-07-05 (see Resolution section below) — originally deferred, no active use case

## Trigger

Build this when a real use case surfaces where you need to share a visual artifact with someone who doesn't have Obsidian or a Lucidchart account — and the content doesn't warrant a full Lucidchart deliverable.

Examples: quick visual summary for a customer, internal team update, metrics dashboard, data comparison chart.

## Reference Material

**visual-explainer** — https://github.com/nicobailon/visual-explainer (MIT license)

Relevant patterns to borrow:
- **Self-contained HTML** — single .html file, no external dependencies, opens in browser
- **Chart.js integration** — real data visualization (bar, line, pie) embedded in HTML
- **Mermaid with zoom/pan** — interactive diagram controls in browser context

Not relevant (already covered by Crumb skills):
- Diagram creation (Mermaid/Excalidraw/Lucidchart)
- Themed aesthetics (Crumb has a shared semantic palette)
- Skill structure (Crumb's skill architecture is different)

## Gap Analysis

| Capability | Current Crumb state | What HTML rendering would add |
|---|---|---|
| Data visualization | Mermaid `xychart-beta` only | Chart.js bar/line/pie with real data |
| Shareable format (no account) | None — Lucidchart requires account | Email/Slack an .html file |
| Browser-viewable output | Not a modality we support | Self-contained HTML pages |

## Decision

Evaluated 2026-02-20. Neither integrate wholesale nor ignore. Bookmark as reference material for a future Crumb-native HTML rendering skill if empirical trigger is met.

## Resolution (2026-07-05)

Resolved. The Claude Code harness now provides this capability natively via the
Artifact tool (self-contained HTML pages, no external dependencies, browser-viewable,
shareable via link) combined with the dataviz skill for chart/graph design guidance.
No custom skill is needed — the gap this bookmark tracked has been closed by the
platform itself.
