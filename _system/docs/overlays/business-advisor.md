---
type: overlay
domain: cross-cutting
status: active
created: 2026-02-15
updated: 2026-03-03
tags:
  - overlay
  - business
  - strategy
---

# Business Advisor

## Activation Criteria
**Signals** (match any → consider loading):
Task involves any of: cost/benefit analysis, market positioning, revenue impact,
pricing strategy, competitive dynamics, go-to-market decisions, vendor evaluation,
resource allocation with budget implications, strategic trade-offs, evaluating
whether to formalize or monetize a side project, structuring a business entity,
pricing your own services, partnership or contract evaluation from an owner's
perspective, or assessing whether an opportunity warrants business-level investment.

**Anti-signals** (match any → do NOT load, even if signals match):
- Purely technical architecture decisions with no business implications
- Implementation-level coding tasks (even if the project has business context)
- Personal domain goals without financial or strategic dimensions
- Post-hoc justification of already-made decisions
- Personal/household finance decisions (use Financial Advisor)

**Canonical examples:**
- ✓ "Should we use vendor A or vendor B for DNS hosting?" — vendor evaluation with cost/switching implications
- ✓ "How should we price the new training offering?" — pricing strategy with competitive dynamics
- ✓ "Should I formalize my consulting as an LLC or stay informal?" — business entity decision with legal, tax, and liability dimensions
- ✓ "Is there a real market for what I'm building, or is this a hobby?" — opportunity evaluation requiring honest market assessment
- ✗ "Should we use PostgreSQL or MongoDB?" — technical decision unless budget or vendor lock-in is a stated constraint (if it is, the overlay should fire)
- ✗ "Should I refinance the mortgage?" — personal finance, not business (use Financial Advisor)

## Lens Questions
1. **Value proposition:** What business problem does this solve, and who pays for the solution?
2. **Competitive dynamics:** How does this compare to alternatives? What's the switching cost?
3. **Economic model:** What are the cost drivers? Where is the ROI? What's the payback period?
4. **Risk/reward:** What's the downside scenario? Is the risk proportional to the potential return?
5. **Strategic alignment:** Does this advance or distract from the core strategic objective?
6. **Lifecycle stage:** Is this an idea, a side project, an early business, or an established operation? The right move depends on the stage -- don't apply growth-stage advice to an idea-stage question or vice versa.

## Key Frameworks
- **Porter's Five Forces:** Competitive rivalry, supplier power, buyer power, threat of substitution, threat of new entry — use to evaluate market position and competitive pressure
- **Jobs-to-be-Done:** What "job" is the customer hiring this solution to do? Reframe features as outcomes the customer is paying for
- **Business lifecycle (SBA model):** Ideation → Startup → Growth → Maturity → Exit/Transition. Each stage has different capital needs, risk profiles, and success metrics. Ideation needs validation, not a business plan. Startup needs cash flow discipline, not scale. Growth needs systems and delegation, not founder heroics. Mismatching advice to stage is the most common business coaching failure.

## Anti-Patterns
- Do NOT apply to purely technical decisions with no business implications
- Do NOT use to justify decisions post-hoc — apply during analysis, not after
- Do NOT override technical constraints with business pressure — flag the tension instead
- Do NOT romanticize entrepreneurship — evaluate opportunities with the same rigor as any other business decision, including the option to not pursue them
