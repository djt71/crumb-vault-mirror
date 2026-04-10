---
type: protocol
domain: software
status: active
created: 2026-03-14
updated: 2026-03-14
---

# Dispatch Triage Protocol

Before processing queued dispatches, evaluate each for actual relevance and signal quality.
The cron that generates dispatches does mechanical keyword matching — Crumb provides the
judgement layer.

## Triage Criteria

For each dispatch in `_openclaw/dispatch/queue/`:

1. **Source verification** — Does the source exist and say what the digest claimed?
2. **Signal strength** — Official announcement vs. Show HN vs. speculation. Weight accordingly.
3. **Project relevance** — Does this genuinely affect the referenced project's architecture
   or decisions, or did it just match keywords?
4. **Actionability** — Would this insight change how we build something, or is it just
   "interesting"?
5. **Timing** — Is this relevant during the current gate/phase, or is it background noise?

## Triage Outcomes

- **PROCESS** — Signal is strong, relevant, and timely. Write the insight note.
- **SKIP** — Signal is weak, irrelevant, or keyword noise. Move to `processed/` with
  `triage_outcome: skipped` and a one-line reason in the file header.

## Procedure

1. Read all queued dispatches
2. For each, quickly check the source and assess against the criteria above
3. Present triage recommendations to the user (1-2 sentences per item)
4. User approves or overrides
5. Process approved items, move skipped items to `_openclaw/dispatch/processed/`
