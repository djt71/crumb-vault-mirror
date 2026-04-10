---
type: reference
status: active
domain: software
created: 2026-03-14
updated: 2026-03-14
tags:
  - system/operator
topics:
  - moc-crumb-architecture
---

# Overlays Reference

Complete index of Crumb's 8 expert lens overlays with activation signals, lens questions, and companion files.

**Architecture source:** [[02-building-blocks]] §Overlays, [[skills-reference]] §Overlay Integration

**Index source:** `_system/docs/overlays/overlay-index.md` (loaded at session start)

---

## Overlays Index

| Overlay | Purpose | Activation Signals | Companion Files |
|---------|---------|-------------------|-----------------|
| **Business Advisor** | Business strategy, pricing, market analysis | Cost/benefit, market positioning, revenue impact, pricing, competitive dynamics, vendor evaluation | None |
| **Career Coach** | Professional development, career trajectory | Skill gap analysis, career positioning, organizational dynamics, stakeholder strategy, role transition | None |
| **Design Advisor** | Visual design, UI/UX, data visualization | Visual design, color palette, typography, wireframes, charts, dashboards, infographics | `_system/docs/design-advisor-dataviz.md` |
| **Financial Advisor** | Household finances, investment, budgeting | Budgeting, cash flow, investment decisions, debt strategy, tax planning, insurance, retirement | None |
| **Glean Prompt Engineer** | Enterprise knowledge search (Infoblox) | Querying Glean, internal data lookup, customer intelligence gathering | None |
| **Life Coach** | Personal direction, values, priorities | Personal goals, values clarification, motivation, domain prioritization, habit change, "should I" decisions | `Domains/Spiritual/personal-philosophy.md` |
| **Network Skills** | DNS, DHCP/IPAM, network security | DNS architecture, SASE/SSE, CDN, hyperscaler networking, SD-WAN, zero trust, RFC interpretation | `_system/docs/network-skills-sources.md` |
| **Web Design Preference** | Danny's personal web properties | Personal site design, digest templates, dashboard panels, Enlightenment aesthetic | `_system/docs/www-design-taste-profile.md` |

---

## Lens Questions by Overlay

### Business Advisor
1. Value proposition — who pays and why?
2. Competitive dynamics and switching costs?
3. Cost drivers and ROI?
4. Risk/reward proportional?
5. Strategic alignment?
6. Business lifecycle stage (idea → startup → growth → maturity)?

### Career Coach
1. Skill leverage — compounds across roles?
2. Reputation signal?
3. Relationship capital?
4. Opportunity cost of time?
5. Next-role test — relevant beyond current role?

### Design Advisor
1. Visual hierarchy (first → second → third)?
2. Design system / brand consistency?
3. Medium and viewport constraints?
4. Typography serves readability and tone?
5. Color emotional register and contrast?
6. Negative space sufficiency?
7. Interaction path support?
8. Hick's Law check?
9. Fitts's Law check?
10. Tesler's Law check?

### Financial Advisor
1. Time horizon (<1yr, 1-10yr, 10+yr)?
2. Tax implications and after-tax number?
3. Opportunity cost — name the tradeoff?
4. Assumptions check and sensitivity?
5. Reversibility (one-way vs. two-way door)?
6. Household impact and agreement?
7. Cash flow impact and sustainability?

### Glean Prompt Engineer
1. What specific info needed and downstream use?
2. Search query vs. assistant query distinction?
3. Which data sources likely contain the answer?
4. Temporal scoping needed?
5. What structured output format for Crumb?

### Life Coach
1. Values alignment with personal philosophy?
2. Whole-person impact (domains other than primary)?
3. Energy and sustainability path?
4. What does your library say?
5. The "enough" test (satisfice vs. optimize)?
6. Philosophy feedback loop — update personal-philosophy.md?

### Network Skills
1. Standards compliance (RFC consistency)?
2. Authoritative source check?
3. Integration surface and protocol handoffs?
4. Scale and failure mode behavior?
5. Infoblox positioning (customer-facing contexts)?
6. Source catalog feedback?

### Web Design Preference
1. Mode selection (Library / Observatory / Cartographer's Table)?
2. Typography — serif foundation intact?
3. Color discipline — warm palette, functional only?
4. Layout and density — active margins?
5. Jakob's Law tension — predictable interactions with novel aesthetics?
6. Character and graphic style — Enlightenment aesthetic?

---

## How Overlays Work

- **Loaded by skills:** Skills with overlay check steps (systems-analyst, action-architect, writing-coach, learning-plan, attention-manager) match the current task against the overlay index and load matching overlays
- **Operator override:** Any overlay can be loaded explicitly by the operator
- **Additive only:** Overlays add lens questions to the active skill — they don't replace the skill procedure
- **Budget exception:** Overlays and `personal-context.md` don't count against the source document budget

### Skills with Overlay Checks

| Skill | Overlay Behavior |
|-------|-----------------|
| systems-analyst | Matches task against index (Step 2) |
| action-architect | Matches task against index (Step 2) |
| writing-coach | Matches audience against index (Step 2) |
| learning-plan | Matches skill domain against index (Step 2) |
| attention-manager | **Always** loads Life Coach + Career Coach |

---

## Overlay File Locations

```
_system/docs/overlays/
├── overlay-index.md           # Activation signal index (loaded at session start)
├── business-advisor.md
├── career-coach.md
├── design-advisor.md
├── financial-advisor.md
├── glean-prompt-engineer.md
├── life-coach.md
├── network-skills.md
└── web-design-preference.md
```

**Reconciliation:** 8 overlay files on disk match the 8 entries in `overlay-index.md`.
