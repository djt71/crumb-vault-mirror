---
type: reference
domain: null
skill_origin: null
status: active
created: 2026-04-24
updated: 2026-04-24
tags:
  - system
  - capture
  - workflow
---

# Capture Tiers

The capture design Crumb is built around. Five tiers, one promotion path, two sweep rituals. Preserved here so the principle survives future temptation to add capture infrastructure.

## Tiers

| Tier | Surface | Purpose | Lifetime | Sweep |
|---|---|---|---|---|
| 1 | Sticky notes | At-desk fleeting thoughts, quick todos | Hours to a day | End-of-day — most go to trash |
| 2 | Paper notebook | Daily scratchpad, ritual items | Per-session | None — stays as-is |
| 3 | Apple Notes | Fleeting-to-semi-durable, phone or laptop | Days to a week | Weekly — promote / keep / delete |
| 4 | Main vault (Crumb) | Durable knowledge only | Permanent | N/A — high-threshold entry |
| 5 | Work vault (separate Obsidian) | Confidential work content | Permanent | N/A — never merges with main vault |

Apple Notes is deliberately flat. No folders. Adding folders re-introduces classification at capture time, which is the friction this design avoids.

## Promotion Path

Apple Notes → main vault is the only promotion path from ephemeral to durable. Stickies that survive end-of-day either get transcribed into Apple Notes (if semi-durable) or go straight into the vault (if durable). The notebook doesn't promote.

**Criteria for promoting a note from Apple Notes to the vault:**
- Referenced more than once (you reached for it again → durable)
- Connects to an existing vault note or project (has wikilink potential)
- Represents a framework, pattern, or principle — not a specific todo or reminder
- You find yourself wanting to search for it later

The "keep" bucket in the weekly sweep should feel uncomfortable to use. If something has been "keep" for three weeks running, it's probably actually delete or promote.

## Work Vault Separation

Work vault stays separate — architecturally, not by preference. The main vault has multiple egress paths (GitHub mirror, Google Drive sync for Perplexity) that confidential customer content cannot flow through. Any customer-identifiable material, Infoblox internal content, or NDA-covered notes belong in the work vault only.

Promotion from work vault to main vault requires de-identification: customer-specific lesson → role-agnostic pattern or framework → main vault as durable career knowledge.

## Round-Trip Friction Principle

The load-bearing idea behind this design. Apple Notes beats Telegram-to-vault pipes for note-taking because capture ceremony is not measured at the write step alone.

> **Capture tools are evaluated on total round-trip friction — write + revisit + edit — not write-step friction alone. A unified write/read surface beats a separated pipe even when the pipe has lower write-step ceremony.**

A tool that lets you revisit what you captured without switching apps wins the capture contest. Telegram-to-vault was always going to lose this for note-taking — once sent, the thought was gone from Telegram until the next Crumb session, with no intermediate read or edit. That's a difference in kind, not degree.

This is why the quick-capture mechanism was retired (2026-04-24) — see retirement note in `Archived/Projects/crumb-tess-bridge/progress/run-log.md`. It was solving the capture problem one layer too low; the write step was frictionless but the round-trip cost was high.

## What NOT to Build

Before proposing new capture infrastructure, check it against this design:

- Don't add folders to Apple Notes
- Don't rebuild phone-to-vault capture pipes that separate write and read surfaces
- Don't add a unified "one true capture app" — the tiers exist because different contexts need different tools
- Don't automate the Apple Notes sweep away — the sweep is the quality filter; removing it re-admits low-signal notes to durable storage

Ceremony Budget Principle applies: if the existing tiers feel inadequate, the first question is whether friction in the sweep or promotion step can be reduced, not whether a new tier needs to exist.

## Skills (possible future)

If the weekly Apple Notes sweep reveals a pattern worth automating, a `promote-note` skill would take raw pasted text, propose frontmatter / location / tags, and let the operator approve. Same shape as `inbox-processor` but text-in rather than file-in.

Do not build this preemptively. Run 2–3 manual weekly sweeps first. Most notes promote or delete in under a minute each; automation may not earn its keep.
