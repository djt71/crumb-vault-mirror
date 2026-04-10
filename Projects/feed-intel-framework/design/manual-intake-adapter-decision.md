---
type: decision
project: feed-intel-framework
domain: software
status: active
created: 2026-02-24
updated: 2026-02-24
tags:
  - openclaw
  - tess
---

# Decision: Manual Intake via Tess → Framework Adapter

## Context

Danny wants to forward links, YouTube videos, and other ad-hoc findings from
personal browsing into the Crumb system via Tess. Sources include phone, work
Mac, and Studio — any device with Telegram access.

## Decision

Build manual intake as a **source adapter within feed-intel-framework**, not as
a standalone project. The capture surface is Telegram (paste a URL to Tess,
optionally with inline context). Tess recognizes the intake item and queues it
for framework processing via the bridge dispatch protocol.

## Rationale

- The framework's source adapter pattern, triage engine, vault router, and
  digest pipeline provide all the downstream processing this needs. Building
  a parallel path would duplicate infrastructure and require rewiring later.
- Tess as the capture surface gives cross-device coverage for free (Telegram
  runs everywhere).
- Manual items are human-curated, so they skip or receive minimal triage —
  the operator has already decided they're worth capturing.
- The bridge dispatch protocol (crumb-tess-bridge) already handles
  Tess → Crumb routing for processing that exceeds Tess's local capability.

## Design Sketch

- **Capture:** Tess detects a URL in chat (regex or `/intake <url>` command).
  Optional inline annotation parsed as context (e.g., project tag, note).
- **Normalization:** URL + context mapped to unified content format with
  `source_type: manual`. `canonical_id: manual:sha256[:16]` of canonicalized
  URL.
- **Triage:** Skipped or lightweight-only (operator-curated signals high
  relevance). Enrichment (fetch + summarize) runs as processing, not scoring.
- **Routing:** Standard vault router. File naming: `feed-intel-manual-{id}.md`.
- **Digest:** Manual items included in daily digest or delivered as immediate
  confirmation — TBD based on UX preference.
- **Future enhancements:** iOS Shortcuts / share sheet → Telegram message
  (convenience wrapper, same backend). Browser bookmarklet. Batch URL intake.

## Timing

Deferred until M1 framework core and M2 X migration establish the adapter
pattern concretely. Scope during or after M2 — likely a lightweight addition
once the first two adapters prove the interface.

## Open Questions

- Should manual items get an immediate "received + queued" confirmation from
  Tess, or just appear in the next digest silently?
- Annotation syntax: free-form text after URL, or structured
  (e.g., `#project-tag` / `@priority`)?
- Should manual items bypass the attention clock entirely and process on
  arrival, or batch with the next scheduled cycle?
