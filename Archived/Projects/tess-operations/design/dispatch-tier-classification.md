---
type: design
domain: software
project: tess-operations
skill_origin: systems-analyst
review_round: 1
created: 2026-03-08
updated: 2026-03-08
tags:
  - tess
  - dispatch
  - classification
  - chief-of-staff
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Dispatch-Tier Classification — Design Document

## 1. Purpose

Tess currently operates as a dispatcher that executes work Danny explicitly assigns. The interaction model is: Danny sees work → Danny decides what Tess can handle → Danny dispatches. This design document specifies a classification capability that inverts the model: Tess sees work → Tess classifies by autonomy level → Tess presents a pre-triaged view → Danny reviews and approves.

**The routing inversion:** Danny stops being the dispatcher and becomes the exception handler. Everything in this document — the tiers, the overrides, the learning — exists to make that inversion safe.

This is a cross-cutting capability. It applies to every intake surface Tess monitors: feed-intel signals, Gong call transcripts, email (when integrated), vault-check failures, health alerts, calendar events, and bridge dispatch results. It is not a standalone project — it is a design document that generates tasks folding into tess-operations' existing milestone structure.

**Architectural connection:** The tier model maps directly to the reads/writes separation validated by OpenAI Symphony (see [[symphony-architecture-reference]]): Green items have write permission. Yellow items stage writes pending approval. Red items are read-only until Danny acts. The tiers also instantiate the gate evaluation pattern ([[gate-evaluation-pattern]]): Green = computable gate (passes mechanically), Yellow = judgment-dependent gate (human evaluates), Red = human-only gate.

## 2. The Four Tiers

Adapted from Jim Prosser's dispatch/prep/yours/skip framework, tuned for Tess's operational context.

### Tier Definitions

**Green (Dispatch)** — Tess handles fully and autonomously. Danny sees results in a periodic digest or summary, not individual items. No approval gate. Tess commits the work and logs it.

Characteristics: well-defined procedure exists, output is mechanically verifiable (vault-check passes, test suite passes, health check green), low consequence if wrong (easily reversible or low-stakes), no client-facing output.

Examples:
- Routine FIF capture clock operations (capture, lightweight triage, digest generation)
- Health check passing — log and continue
- Feed-intel items classified as noise/skip during triage
- Routine vault maintenance (run-log rotation, archive operations)
- Bridge dispatch results — success (log completion, update project state)

**Yellow (Prep)** — Tess gets the work 80% done, then presents to Danny for final judgment or approval before completion. This is the default tier for anything with external visibility or judgment-dependent quality.

Characteristics: procedure exists but output requires human quality review, or the action has external consequences that warrant a confirmation gate, or context-dependent judgment is needed for the final step.

Examples:
- Post-call pipeline outputs (extraction done, vault note drafted, follow-up artifact ready — Danny reviews before send)
- Feed-intel items flagged as research-worthy (Tess assembles context, presents recommendation, Danny confirms dispatch)
- Email drafts (Tess drafts, Danny reviews and sends)
- Calendar conflict resolution proposals (Tess identifies conflict + proposes resolution, Danny confirms)
- Vault note updates that change customer dossier facts (Tess drafts update, Danny confirms before commit)
- vault-check failures (Tess identifies the issue and proposes a fix, Danny confirms before commit)
- Health check — failing (Danny needs to see it, Tess assembles diagnostic context)
- Bridge dispatch results — failure (Danny needs to see what failed and decide next step)

**Red (Yours)** — Requires Danny's brain, judgment, or presence. Tess assembles supporting context but does not attempt the work itself. Tess's value is in reducing prep time, not in doing the task.

Characteristics: relationship-sensitive, strategically consequential, requires domain expertise Tess doesn't have, or involves commitments/promises on Danny's behalf.

Examples:
- Client-sensitive communications (relationship management, difficult conversations, pricing)
- Strategic account planning and engagement decisions
- Infoblox-internal political navigation (who to loop in, when to escalate)
- Crumb architectural decisions (design spec changes, new project approval)
- Any item where the cost of getting it wrong significantly exceeds the cost of Danny doing it himself

**Gray (Skip/Defer)** — Not actionable now. Tess logs the item with a reason and a suggested revisit date or trigger condition. Gray items surface in a weekly review, not the daily flow.

Characteristics: blocked on external dependency, informational with no action required, low-priority relative to current focus, or premature (the right time to act hasn't arrived).

Examples:
- FYI emails with no action required
- Feed-intel items that are interesting but not timely
- Tasks blocked on client responses or external timelines
- Low-priority vault gardening that can wait for a quiet week

### Tier Boundary Principles

1. **Bias toward Yellow.** When classification is ambiguous, default to Yellow (prep + present), not Green (autonomous). The cost of unnecessary human review is minutes. The cost of autonomous action on something that needed judgment is much higher.

2. **Green requires mechanical verifiability.** If the output can't be validated by a test, a vault-check, or a binary success condition, it's not Green. "Looks good" is not a verification mechanism.

3. **Red is about the decision, not the prep.** Tess should still do all the preparatory work for Red items — assembling context, pulling dossier data, summarizing prior interactions. The Red classification means Danny makes the final call, not that Tess does nothing.

4. **Gray is not a trash tier.** Every Gray item gets a logged reason and a revisit condition. Gray items without revisit conditions are deleted, not deferred.

## 3. Classification Logic

### 3.1 Item-Type Defaults

Every intake source has a default tier assignment. The default applies when no context-specific signals override it.

| Intake Source | Default Tier | Rationale |
|---------------|-------------|-----------|
| FIF capture (routine) | Green | Mechanical, reversible, no external visibility |
| FIF signal (research-worthy) | Yellow | Requires judgment on whether to promote to research |
| Gong call transcript | Yellow | Post-call pipeline outputs need review before client send |
| Health check — passing | Green | Log and continue |
| Health check — failing | Yellow | Danny needs to see it, Tess assembles diagnostic context |
| Health check — critical (sustained failure) | Red | Requires Danny's immediate attention and decision |
| vault-check failure | Yellow | Tess proposes fix, Danny confirms — auto-repair not yet built |
| Email — from client (when integrated) | Yellow | Client comms always get human review |
| Email — newsletter/FYI (when integrated) | Gray | Informational, no action |
| Email — action-required internal (when integrated) | Yellow | Prep a response, Danny reviews |
| Calendar conflict | Yellow | Propose resolution, Danny confirms |
| Bridge dispatch result — success | Green | Log completion, update project state |
| Bridge dispatch result — failure | Yellow | Danny needs to see what failed and decide next step |

### 3.2 Context-Aware Overrides

Item-type defaults are adjusted by context signals from the vault and operational state.

| Context Signal | Override Effect |
|----------------|----------------|
| Account flagged high-priority in dossier | Upgrade one tier (Green→Yellow, Yellow→Red) |
| New prospect (thin dossier, <3 prior interactions) | Upgrade one tier for any client-facing output |
| Active implementation with timeline pressure | Upgrade post-call outputs to Red if blockers detected in extraction |
| Danny is in focus mode (explicit signal) | Downgrade Yellow→Gray for non-urgent items; accumulate for batch review |
| Weekend/off-hours | Only Green items proceed autonomously; Yellow items queue for next business morning |
| Item involves financial commitment or pricing | Always Red, regardless of type default |
| Item involves external audience >5 people | Always Yellow minimum (no autonomous action with broad visibility) |

### 3.3 Override Learning

When Danny reclassifies an item (changes its tier assignment during review), the override is logged:

```yaml
- timestamp: "2026-03-10T08:15:00Z"
  item_type: "gong-call-note"
  account: "acme-corp"
  assigned_tier: yellow
  override_tier: green
  reason: "Standard check-in with known contact, no surprises. Auto-process these for Acme going forward."
```

Override logs accumulate. Classification logic consults override history when assigning tiers:
- Override pattern key: `(item_type, account)` — these two fields define the pattern for matching purposes.
- If Danny has overridden the same pattern 3+ times in the same direction, across ≥2 separate days, the default shifts permanently for that pattern. The multi-day requirement prevents single-session bias (reclassifying 3 things during a rush ≠ a durable preference).
- Permanent shifts are logged as classification rule updates and surfaced in the weekly review for Danny's awareness.
- Danny can veto any permanent shift ("no, keep this at Yellow — I was being lazy, not making a policy decision").

Override learning rate: conservative. 3 consistent overrides across ≥2 days minimum before a default shifts. The goal is to learn Danny's actual preferences, not to over-optimize on a few hasty reclassifications.

## 4. Presentation Model

### 4.1 Morning Briefing Integration

The morning briefing becomes the primary surface for classified items. Instead of a flat list of updates, the briefing is organized by tier:

```
🟢 Green (handled overnight — 7 items)
  - FIF: 3 signals captured, 1 skipped as noise
  - Health: all services green, 0 alerts
  - Bridge: 1 dispatch completed successfully

🟡 Yellow (ready for your review — 4 items)
  - Acme Corp call note: extraction complete, follow-up draft ready [review]
  - Feed signal: "Karpathy autoresearch" flagged research-worthy [dispatch / skip]
  - Calendar: Thursday 2pm conflict between Initech sync and Globex demo [pick one]
  - Email: RFP response request from partner team [review draft]

🔴 Red (needs your brain — 1 item)
  - Initech: pricing discussion follow-up. Context assembled. [open dossier]

⬜ Gray (deferred — 3 items, next review Sunday)
  - Newsletter roundup (3 items, no action)
```

Green items are summarized as counts, not listed individually. Yellow items are listed with action prompts, sorted by account priority then time-sensitivity. Red items have context links. Gray items show count and next review date.

**Milestone timing:** The tier-organized briefing format lands after M1 gate closes — either as a post-gate amendment to the existing briefing or folded into M2 scope. It does not retroactively change M1.

### 4.2 Real-Time Classification

Items that arrive during the day (Gong emails, health alerts, urgent feed signals) are classified immediately and delivered to Telegram with their tier prefix. Danny can respond to Yellow items via text reply commands: `approve`, `skip`, `defer`, `red` (reclassify). Interactive inline buttons are a comms-channel dependency (M2) — text commands are sufficient for Phase 1.

### 4.3 Yellow Item Aging

Unreviewed Yellow items re-present in the next morning briefing with an age indicator ("Day 2: still pending"). After 48 hours, Tess escalates the Telegram notification: "This Yellow item is aging — act, delegate, or Gray it."

Yellow items do not auto-downgrade to Gray — that would teach Tess that ignoring things makes them go away, which is the wrong incentive. They also do not escalate to Red — the item didn't become more important, Danny just didn't get to it. The 48-hour nudge is a behavioral prompt, not a tier change.

### 4.4 Weekly Review

A weekly summary surfaces:
- Tier distribution (how many Green/Yellow/Red/Gray items this week)
- Override log (any reclassifications Danny made)
- Proposed default shifts (if override threshold reached)
- Gray item review (anything deferred that should be revisited or deleted)

## 5. Integration Points

### 5.1 Post-Call Pipeline

The post-call pipeline ([[post-call-pipeline-spec]], separate project) consumes dispatch-tier classification at two points:
- **Intake:** The Gong email itself is classified (default Yellow). If the call is with a well-documented account and the Gong summary is routine, Tess may assign Green — meaning the vault note is auto-committed and Danny sees it in the morning digest rather than as a review item.
- **Artifact Generation:** The format recommendation incorporates the tier. Green calls get the default format with no escalation. Yellow calls surface the format recommendation for confirmation.

Cross-project dependency: the post-call pipeline spec (§3.3) references "operator confirmation via bridge escalation for format selection." Dispatch-tier classification determines *whether* that escalation fires (Yellow) or is skipped (Green).

### 5.2 Feed-Intel Framework

FIF already has a two-tier triage system (lightweight + standard). Dispatch-tier classification sits *above* this: after FIF triage produces a signal rating, the classification layer decides what happens next:
- Low-signal items → Gray (logged, no action)
- Medium-signal items → Green (captured to vault, appears in digest)
- High-signal items → Yellow (Tess recommends research promotion, Danny confirms)
- Critical/breaking items → Yellow with immediate Telegram notification

### 5.3 Email Triage (Future)

When email integration is built (post-call pipeline M6 / separate project), dispatch-tier classification provides the organizing framework. Every email gets a tier. The tier determines what Tess does with it: auto-archive (Gray), create task and prep response (Yellow), flag for immediate attention (Red), or handle autonomously (Green — e.g., auto-filing receipts or confirming calendar invites).

### 5.4 Tess-Operations Milestones

This design generates tasks that fold into existing tess-operations milestones:
- **Post-M1 (after gate closes):** Morning briefing format amendment — tier-organized presentation replaces flat list.
- **M2-M4 (Service Integrations):** Each integration's read/write boundaries align with tier logic — Green items can auto-write, Yellow items stage for review, Red items are read-only until Danny acts.
- **M7 (Feed-Intel Ownership):** FIF integration point defined in §5.2.

Specific task creation handled during tess-operations task amendment.

## 6. Implementation Approach

### Phase 1: Static Classification (Rules-Based)

Implement item-type defaults (§3.1) and context-aware overrides (§3.2) as a lookup table. No learning, no override tracking. Tess classifies based on rules and presents the tiered morning briefing. Danny reviews and reclassifies verbally or via text commands in Telegram.

**Measurement for Phase 1:** Danny tells Tess he's done reviewing (explicit text acknowledgment in Telegram). Anything fancier is premature.

This is the minimum viable version. It provides value immediately by organizing the morning briefing and establishing the tier vocabulary in daily use.

### Phase 2: Override Logging

Add the override log (§3.3). When Danny reclassifies, Tess records it with the `(item_type, account)` pattern key. Weekly review surfaces the log. No automatic default shifts yet — just data collection.

### Phase 3: Adaptive Defaults

After sufficient override data (target: 50+ classified items with 10+ overrides), implement the automatic default shift logic. 3 consistent overrides in the same direction across ≥2 days → proposed shift → Danny confirms or vetoes.

### Phasing rationale

Phase 1 delivers 80% of the value (organized triage, clear autonomy boundaries). Phases 2 and 3 are refinements that improve accuracy over time — they are not committed roadmap items. The phasing follows the Ceremony Budget Principle: don't build the learning system until you've validated the classification framework is worth learning from.

## 7. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Over-classification as Green (Tess acts on something Danny should have reviewed) | Low (bias-toward-Yellow principle) | High | Green requires mechanical verifiability; no client-facing output can be Green |
| Under-classification as Red (Danny reviews things Tess could have handled) | Medium | Low (wastes Danny's time, not harmful) | Override learning eventually corrects this; acceptable cost during early phase |
| Classification logic becomes stale as work patterns change | Medium | Medium | Weekly review surfaces distribution shifts; override learning adapts |
| Morning briefing becomes too long with tier organization | Low | Low | Green items are counts. Yellow sorted by priority. If 15+ Yellow items consistently, classification thresholds need adjusting — that's a signal, not a presentation problem. |
| Override learning overfits to a temporary pattern | Low | Medium | 3-override minimum across ≥2 days + Danny veto on permanent shifts prevents premature adaptation |
| Yellow items accumulate without review | Medium | Medium | 48-hour aging nudge. Persistent accumulation signals either threshold miscalibration or genuine workload — weekly review surfaces which. |

## 8. Success Metrics

| Metric | Target | Measurement (Phase 1) |
|--------|--------|-----------------------|
| Morning triage time | <10 minutes (briefing delivery to all Yellow items actioned) | Danny's explicit "done reviewing" acknowledgment in Telegram |
| Misclassification rate (Green→should have been Yellow+) | <5% | Items Danny retroactively flags after discovering autonomous action was wrong |
| Override rate (items Danny reclassifies) | <25% after Phase 1 stabilizes; <15% after Phase 3 | Override count / total classified items per week |
| Green autonomy rate | >40% of all items handled without Danny's involvement | Green items / total items per week |
| Classification accuracy (bias check) | Symmetric — no consistent bias toward over- or under-classification | Override log analysis: upgrades vs. downgrades roughly balanced |

## 9. Prior Art

- **Jim Prosser's chief-of-staff system:** dispatch/prep/yours/skip framework. Direct inspiration for the four-tier model. Prosser's system runs 6 subagents in parallel on classified tasks — the classification layer is what makes parallel dispatch safe.
- **OpenAI Symphony:** Reads from Linear (tracker) and dispatches to agent sessions. Symphony's state machine (Todo → In Progress → Human Review → Done) is a simplified version of dispatch-tier classification applied to code tasks only. The reads/writes separation maps directly to tier permissions: Green = write, Yellow = staged write, Red = read-only. See [[symphony-architecture-reference]].
- **Gate evaluation pattern:** Each tier is a gate type — Green = computable gate, Yellow = judgment-dependent gate, Red = human-only gate. The classification framework is the gate evaluation pattern applied to intake routing. See [[gate-evaluation-pattern]].
- **Crumb's researcher-skill escalation gates:** The 4 gate types (scope/access/conflict/risk) are a domain-specific version of "when does the system need human judgment?" Dispatch-tier classification generalizes this pattern across all domains.
- **FIF triage tiers:** Lightweight and standard triage already classify feed items by processing depth. Dispatch-tier classification sits above this, deciding what happens *after* triage.
