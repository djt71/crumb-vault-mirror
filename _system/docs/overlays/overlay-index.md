---
type: reference
domain: null
status: active
created: 2026-02-15
updated: 2026-02-23
tags:
  - overlay
  - routing
---

# Overlay Index

Routing table for overlays. Loaded at session start. When a task matches
an overlay's activation signals, load the overlay file alongside the active skill.

## Active Overlays

| Overlay | File | Activation Signals | Anti-Signals |
|---|---|---|---|
| Business Advisor | `_system/docs/overlays/business-advisor.md` | Cost/benefit analysis, market positioning, revenue impact, pricing strategy, competitive dynamics, go-to-market, vendor evaluation, resource allocation with budget implications, strategic trade-offs, formalizing or monetizing side projects, structuring business entities, pricing your own services, partnership/contract evaluation, opportunity assessment | Purely technical decisions with no business implications; implementation-level coding tasks; personal domain goals without financial dimensions; personal/household finance (use Financial Advisor) |
| Career Coach | `_system/docs/overlays/career-coach.md` | Professional skill gap analysis, career positioning or trajectory planning, navigating organizational dynamics, stakeholder relationship strategy, professional reputation or visibility, role transition planning, performance self-assessment, mentoring, professional development prioritization, conference/community engagement strategy, negotiating role scope, salary negotiation strategy | Business strategy where you represent the company (use Business Advisor); customer engagement tactics; life direction questions spanning beyond career (use Life Coach; may co-fire); technical skill implementation vs. strategic skill investment; financial analysis of comp packages (use Financial Advisor) |
| Design Advisor | `_system/docs/overlays/design-advisor.md` | Visual design, graphic design, UI/UX layout, web or app interface work, color palette, typography, brand identity, wireframes, mockups, design system decisions, responsive design, visual hierarchy, charts, graphs, dashboards, data visualization, infographics, presenting quantitative information visually | Purely backend/logic tasks with no visual component; data modeling; infrastructure work |
| Financial Advisor | `_system/docs/overlays/financial-advisor.md` | Household budgeting, cash flow analysis, investment decisions, debt payoff strategy, tax planning, insurance evaluation, retirement planning, major purchase analysis, net worth tracking, savings goals, risk tolerance, financial product comparison | Business revenue/pricing/go-to-market (use Business Advisor); vendor evaluation for company purposes; purely informational research with no decision; expense tracking without analysis |
| Glean Prompt Engineer | `_system/docs/overlays/glean-prompt-engineer.md` | Querying Glean, enterprise knowledge search, internal data lookup at Infoblox, populating vault artifacts from enterprise sources, customer intelligence gathering via Glean, Glean-to-Crumb data pipeline | Tasks using only public/external data; work entirely within the vault with no enterprise source needed |
| Network Skills | `_system/docs/overlays/network-skills.md` | DNS architecture or resolution design, DHCP/IPAM planning, network security architecture (RPZ, DoH/DoT, DNS filtering), SASE/SSE evaluation, CDN behavior or integration, hyperscaler networking (AWS VPC, GCP networking, Azure VNet), load balancer design, SD-WAN architecture, zero trust network access, customer network migration planning, RFC interpretation, BGP/routing design, firewall policy architecture, network protocol analysis | Application-level coding with no network dimension; Crumb system infrastructure unless network-specific; generic security not related to network infrastructure; business/pricing decisions about vendors (use Business Advisor); career development about networking skills (use Career Coach) |
| Life Coach | `_system/docs/overlays/life-coach.md` | Personal goal-setting, life direction decisions, values clarification, motivation or momentum problems, prioritization across life domains, habit formation or change, work-life tension, "should I" decisions spanning multiple domains, quarterly/annual review, meaning-making, identity questions | Purely technical/implementation tasks; financial analysis (use Financial Advisor); purely strategic business/career decisions (use Business Advisor); generic motivational content disconnected from user context; mental health concerns needing professional support (flag and step back — see anti-patterns) |
| Web Design Preference | `_system/docs/overlays/web-design-preference.md` | Personal site design, Danny's web projects, digest templates, vault-facing UI, dashboard/panel design for personal systems, Enlightenment aesthetic application, site mode selection | Work for external stakeholders/client brand guidelines; purely backend tasks; functional-only UI with no aesthetic dimension |

## Companion Documents

Some overlays declare a **companion doc** — a standing reference document that auto-loads alongside the overlay. Use this pattern when an overlay's value depends on persistent, evolving context rather than lens questions alone.

| Overlay | Companion Doc | Purpose |
|---|---|---|
| Design Advisor | `_system/docs/design-advisor-dataviz.md` | Data visualization lens questions, frameworks, and anti-patterns (Tufte, Cleveland-McGill, Cairo, Ware) |
| Life Coach | `Domains/Spiritual/personal-philosophy.md` | Personal values and philosophical commitments grounding life direction advice |
| Network Skills | `_system/docs/network-skills-sources.md` | Curated vendor documentation catalog (RFC, hyperscaler, CDN, SASE, DNS) |

**When to use:** Companion docs are for overlays grounded in accumulated personal or domain knowledge. Generic advisory overlays (Business Advisor, Financial Advisor, etc.) don't need companions — their value is in the lens questions. Companion docs don't count against the source document budget (overlays are exempt).

**Feedback loop:** Overlays with companions should include a lens question that evaluates whether the companion doc needs updating based on the current session's insights.

## Retired Overlays

<!-- Overlays removed from active routing. Keep for reference. -->
