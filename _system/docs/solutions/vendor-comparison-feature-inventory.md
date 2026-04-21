---
type: pattern
domain: software
status: active
track: pattern
linkage: discovery-only
created: 2026-04-21
updated: 2026-04-21
tags:
  - compound-insight
  - evaluation
  - decision-making
  - framing-risk
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Pull the Full Feature Inventory Before Framing the Comparison

## Pattern

When evaluating whether to replace an existing system with a vendor offering, the first frame you adopt silently determines which features you compare. If the frame is "A vs. B," you end up comparing A against B's surface features and never learn that C exists and is the actual relevant substitute.

```
Frame: "Cowork vs. Tess"   →   compare Cowork features against Tess features
                           →   miss Routines entirely
                           →   reach wrong conclusion (sunset Tess)

Frame: "what does this vendor offer for unattended execution?"
                           →   find Cowork, Routines, Remote Control, Channels
                           →   map each to the workloads they fit
                           →   reach correct conclusion (division of labor)
```

The cost of the narrow frame is invisible — you don't know what you didn't look for. Multiple independent passes can make the same mistake because each inherits the frame from the last.

## Evidence

**Anthropic consolidation hypothesis (2026-04-21):**

A claude.ai web conversation with Opus framed the question as "Cowork vs. Tess" from the first turn. The output was a plausible architecture (Mac Studio running Cowork, Tess sunsets) built on Cowork's specific constraints (single-device lock, scheduled-tasks-require-awake).

Crumb's first verification pass kept the same frame — verifying the Cowork claims against primary sources without questioning whether Cowork was the right comparison target.

Only when verification followed a link from the Remote Control docs to a "scheduling options" table did Routines surface. Routines (cloud-hosted scheduled Claude Code sessions, runs without local machine on) is the feature the conversation was implicitly looking for when it argued Cowork replaces Tess. Two independent passes missed it because neither questioned the frame.

The correct conclusion, once Routines was on the table, was not substitution but division of labor: Routines takes schedule-triggered vault-artifact workloads, Cowork handles interactive life-OS work, Channels bridges inbound Telegram, Tess stays for local-MCP and sub-hour scheduling. The strategic call (sunset Tess) flipped to a different call (add Routines/Channels to the surface inventory) once the frame was widened.

## Why It Happens

- **Conversational framing is load-bearing.** Whichever comparison gets named first shapes the entire discussion. "Cowork vs. Tess" filters out features that aren't Cowork.
- **Verification inherits frames.** Checking whether specific claims are true doesn't surface unnamed claims. You verify what was asserted; you don't verify what the comparison missed.
- **Vendor docs are organized by product surface, not by workload.** You find Cowork by searching "Cowork"; you find Routines by searching "scheduled tasks" or "unattended automation." If you start with the product name, you stay in the product page.

## How to Apply

Before accepting a "should I replace A with B?" framing:

1. **List the workloads A actually does.** Not features — workloads. "Schedule a daily digest against vault artifacts," "react to Telegram messages," "run a sub-hour monitoring check."
2. **Ask the vendor-neutral question first:** "What does this vendor (or ecosystem) offer that addresses workload X?" Don't name B yet.
3. **Pull the full feature inventory** from the vendor's documentation — index pages, feature lists, comparison tables. Specifically look for pages titled "choose the right approach" or "how X compares."
4. **Then map workloads to features.** Some workloads will map to B (the named competitor); others may map to C, D, or E (features you didn't know about); others may not map at all.
5. **Only then frame the comparison.** The shape is almost never "A vs. B." It's usually "division of labor across A, C, D, with B not actually the right comparison target."

## Anti-Pattern

- Accepting a conversation's framing without checking whether it surveyed the full landscape.
- Verifying the claims a conversation made (claim-level verification) without verifying the claims it *didn't* make (frame-level verification).
- Treating "I checked the facts" as equivalent to "I checked the comparison shape."

## Related

- `_system/docs/anthropic-consolidation-hypothesis.md` — the artifact where this pattern surfaced
- Memory: `feedback-schema-addition-reflex.md` (related: don't pre-commit against unverified premises)
