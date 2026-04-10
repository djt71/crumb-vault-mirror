---
type: overlay
domain: null
status: active
created: 2026-02-17
updated: 2026-03-06
tags:
  - overlay
  - design
---

# Design Advisor

Expert lens for graphic design, web/app UI design, digital aesthetics, and data visualization.

Companion reference: `_system/docs/design-advisor-dataviz.md` carries the
data visualization lens questions, frameworks, and anti-patterns. Load it
when this overlay fires and the task involves dataviz.

## Activation Criteria

Task involves any of: visual design, graphic design, UI/UX layout, web or app interface work, color palette selection, typography choices, brand identity, wireframes or mockups, design system decisions, responsive design, visual hierarchy, charts, graphs, dashboards, data visualization, infographics, presenting quantitative information visually.

## Lens Questions

1. What is the visual hierarchy — what should the eye hit first, second, third?
2. Is there a design system or brand identity this must be consistent with? If not, should one be established?
3. What is the intended medium and viewport? (print, web desktop, mobile, app, social) — constraints differ dramatically.
4. Is the typography serving readability and tone, or fighting them?
5. Does color usage communicate the right emotional register and maintain sufficient contrast/accessibility?
6. Is there enough negative space, or is the design trying to say too much at once?
7. What is the actual interaction path — does the visual flow support it or fight it?
8. **Hick's Law check:** How many choices is the user facing at each decision point? Can options be staged, defaulted, or progressive-disclosed to reduce decision complexity?
9. **Fitts's Law check:** Are interactive targets (buttons, links, form fields) sized and positioned proportional to their importance and frequency of use? Are primary actions large and close to the user's likely cursor/finger position?
10. **Tesler's Law check:** Where does the irreducible complexity live — with the user or with the system? If the user is managing complexity the system could absorb (configuration, error recovery, state management), the design has a problem.

## Key Frameworks

- Visual hierarchy: size, contrast, proximity, alignment
- Gestalt principles (Laws of Proximity, Similarity, Common Region, Prägnanz, Uniform Connectedness): elements perceived as grouped by spatial proximity, visual similarity, shared boundaries, simplicity of form, and visual connection. Apply to information architecture, not just visual layout.
- **Doherty Threshold:** Interactions must respond within 400ms or provide feedback. Above this threshold, users perceive the system as unresponsive. Budget applies to page loads, transitions, and any user-initiated action.
- **Jakob's Law:** Users bring expectations from other interfaces. Novel interaction patterns carry a learning cost. Deviate from conventions only when the benefit exceeds the friction of learning something new.
- Responsive design breakpoints and fluid layouts
- WCAG accessibility: contrast ratios, touch targets, semantic structure
- Design system thinking: tokens, components, patterns — when to formalize vs. ad-hoc
- Mobile-first vs. desktop-first based on primary audience

## Vault Source Material

- [[yablonski-laws-of-ux-digest]] — Hick's Law, Fitts's Law, Tesler's Law, Jakob's Law, Doherty Threshold, Gestalt principles, cognitive load, and other UX heuristics informing the general lens questions above

## Anti-Patterns

- Designing for aesthetics without considering the task flow
- Treating accessibility as optional — it is structural
- Cargo-culting design trends without understanding the problem they solve
- Treating responsive as "make it smaller" rather than redesigning for the medium
- Zero whitespace — cramming because "everything needs to be above the fold"
