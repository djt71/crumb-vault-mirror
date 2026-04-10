---
type: reference
status: active
created: 2026-03-12
updated: 2026-03-12
domain: null
---

# Overlays

Overlays are advisory lenses that load alongside skills to add domain-specific questions and framing. They don't replace the active skill — they augment it. Skills with overlay check steps (systems-analyst, action-architect, learning-plan, attention-manager, writing-coach) match tasks against the overlay index and load relevant overlays automatically. You can also request any overlay explicitly.

## How They Work

- Overlays inject lens questions into the active skill's procedure
- Multiple overlays can co-fire on a single task
- They don't count against the source document budget
- Some overlays have companion docs that auto-load with them (persistent domain context)
- Routing is driven by activation signals in the overlay index (`_system/docs/overlays/overlay-index.md`)

## Active Overlays

### Business Advisor
**When it fires:** Cost/benefit analysis, pricing strategy, competitive dynamics, go-to-market, vendor evaluation, monetizing side projects, partnership/contract evaluation.
**What it adds:** Business impact framing, ROI lens, market positioning questions.

### Career Coach
**When it fires:** Professional skill gaps, career trajectory, organizational dynamics, stakeholder strategy, role transitions, professional visibility, salary negotiation.
**What it adds:** Career positioning lens, professional development prioritization, reputation strategy questions.

### Life Coach
**When it fires:** Personal goal-setting, life direction, values clarification, motivation problems, cross-domain prioritization, habit formation, "should I" decisions.
**What it adds:** Values-grounded framing, domain balance questions, meaning-making lens.
**Companion doc:** `Domains/Spiritual/personal-philosophy.md` (personal values and philosophical commitments).

### Financial Advisor
**When it fires:** Household budgeting, investment decisions, debt strategy, tax planning, insurance, retirement, major purchases.
**What it adds:** Cash flow analysis lens, risk tolerance framing, financial product comparison.

### Network Skills
**When it fires:** DNS architecture, DHCP/IPAM, network security (RPZ, DoH/DoT), SASE/SSE, CDN, hyperscaler networking, SD-WAN, zero trust, RFC interpretation.
**What it adds:** Protocol-level design questions, vendor doc pointers, standards compliance checks.
**Companion doc:** `_system/docs/network-skills-sources.md` (curated vendor documentation catalog).

### Design Advisor
**When it fires:** Visual/UI/UX design, color palette, typography, brand identity, wireframes, data visualization, charts, dashboards.
**What it adds:** Visual hierarchy questions, accessibility checks, aesthetic consistency lens.
**Companion doc:** `_system/docs/design-advisor-dataviz.md` (data visualization frameworks — Tufte, Cleveland-McGill, Cairo, Ware).

### Glean Prompt Engineer
**When it fires:** Querying Glean for enterprise knowledge, internal data lookup at Infoblox, populating vault artifacts from enterprise sources.
**What it adds:** Glean query optimization, enterprise-to-vault data pipeline framing.

### Web Design Preference
**When it fires:** Personal site design, Danny's web projects, digest templates, vault-facing UI, dashboard/panel design.
**What it adds:** Enlightenment aesthetic application, site mode selection, personal design system consistency.

## Overlay vs. Skill

Overlays are not skills — they have no standalone procedure. They only fire when attached to an active skill. If you need a standalone advisory session, invoke the relevant skill (e.g., `/systems-analyst` for strategic analysis) and the overlay loads automatically based on the topic.
