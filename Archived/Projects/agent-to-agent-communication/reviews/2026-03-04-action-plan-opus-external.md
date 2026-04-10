---
type: review
artifact: Projects/agent-to-agent-communication/design/action-plan.md
artifact_type: action-plan
project: agent-to-agent-communication
domain: software
reviewer: claude-opus-4-6-external
review_mode: full
status: active
created: 2026-03-04
updated: 2026-03-04
---

# Peer Review: Action Plan — Claude Opus 4.6 (External, vault access)

**Source:** claude.ai session with vault access (Danny-submitted)

## Assessment

Clean. Milestone decomposition is good. OQ1 resolution sound. Code location map genuinely useful.

## Strengths

- M1 → M2 → M3 → M4 sequencing correct
- A2A-004 split into 3 and A2A-012 into 2 is right granularity
- Live deployment iteration budget (3-6 for W1, 3-4 for W2) honest and matches Pattern 4
- Noise ceiling 3/day during gate vs 5/day post-gate addresses blast radius concern

## Findings

### F1 [SIGNIFICANT]: vault.query.facts manifest on wrong skill
A2A-007 puts the `vault.query.facts` manifest on obsidian-cli. But obsidian-cli is a cross-cutting utility (§3.1.5), not a dispatch target. It doesn't receive briefs via the bridge. The capability manifest belongs on whatever skill Crumb runs in a dispatch session, not on obsidian-cli itself. Needs design decision: dedicated vault-query skill (which doesn't exist yet) or general-purpose "answer from vault data" skill.

### F2 [SIGNIFICANT]: M3 depends on M2 gate — may be unnecessarily strict
Capability infrastructure is not logically dependent on W1 succeeding. It depends on M1 infrastructure being operational and having a reason to build it (W2 is coming). The gate produces Haiku/Sonnet data and compound insight quality data — neither of which M3 consumes. Distinction: operational confidence vs logical data dependency. Worth stating which it is.

### F3 [MINOR]: M5 vs M3 scheduling priority
M5 can start independently of M3/M4 but creates a scheduling question if both are unblocked during M2 gate period. M3 is on critical path to W2; M5 is not. Unless Mission Control has standalone value earlier.

### F4 [MINOR]: No session estimates per milestone
Spec had per-task effort estimates. Action plan doesn't carry these forward. For a solo operator with limited sessions, knowing approximate session counts per milestone aids weekly planning.

### F5 [MINOR]: Glossary missing dispatch_group_id
D1 glossary doesn't include `dispatch_group_id` (deferred to Phase 4). Since the review synthesis flagged disambiguation, a note would help.

## Net Assessment
None are blockers. F1 needs a design answer before M3. Rest are refinements.
