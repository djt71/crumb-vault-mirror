---
type: summary
project: x-feed-intel
domain: software
skill_origin: null
created: 2026-02-23
updated: 2026-02-25
source_updated: 2026-02-25
tags:
  - openclaw
  - tess
  - automation
---

# X Feed Intelligence Pipeline — Specification Summary

## Core Content

X Feed Intel is an automated pipeline that extracts Danny's X bookmarks (via X API v2, OAuth 2.0) and discovers relevant public content (via TwitterAPI.io search), then triages both streams using Tess's LLM-based triage engine. Results are delivered as a structured daily Telegram digest with inline feedback controls, and high-signal items are routed into the vault for Crumb or Tess to act on.

The architecture uses two decoupled clocks: a **capture clock** (bookmark puller + topic scanner + normalizer + global dedup) that runs opportunistically and accumulates items in a durable SQLite queue, and an **attention clock** (triage + vault router + cost telemetry + digest) that runs once daily at a fixed time. This separation lets capture retry freely without spamming delivery.

Triage uses Haiku 4.5 in batch mode (10-20 posts per call) with a vault snapshot providing current project context. Each post receives a structured decision: priority, tags, why-now assessment, recommended action, confidence, and vault routing target. Only posts tagged `crumb-architecture` with medium+ confidence auto-route to `_openclaw/inbox/`. Danny can manually stage items to the KB review queue via a `save` command in Telegram replies.

Monthly cost target is ~$2-4 (X API bookmarks $1.50-3, TwitterAPI.io search $0.30-0.45, LLM triage ~$0.36), with a $6/month combined soft ceiling and automatic search volume reduction at 90% of budget.

## Key Decisions

- **State storage:** SQLite (unanimous peer review consensus). DB lives outside the vault alongside pipeline code.
- **Boundary compliance:** Crumb owns spec/architecture; Tess owns runtime operation and topic config management (operator-initiated CRUD with validation-before-commit). Pipeline code is outside the vault. Only config, routed items, and KB review queue are vault-resident under `_openclaw/`.
- **Feedback protocol:** Six commands (promote, save, ignore, add-topic, expand, research). Promote has conditional confirmation via triage engine's own routing bar. Save stages to `_openclaw/feeds/kb-review/` for Crumb review. Research triggers context enrichment before bridge dispatch (§5.8.1).
- **KB tag separation:** Triage tags (`crumb-architecture`, `tool-discovery`, etc.) are pipeline-internal routing labels. `#kb/` tags are assigned by Crumb during KB review — Tess never assigns them.
- **Thread handling:** Phase 1 uses heuristic detection (`needs_context` flag) for capture/triage — no additional API calls. On-demand thread expansion is implemented for the `research` command (§5.8.1) via TwitterAPI.io `thread_context` and `tweet/replies` endpoints. Full automatic expansion for all flagged items remains Phase 2.
- **Topic config:** Pinned to `config/topics.yaml` in pipeline repo. Tess manages via Telegram commands (list/add/remove/modify) with validation-before-commit.
- **Triage prompt:** v0 skeleton in Appendix A. Prompt engineering is an explicit Phase 1 deliverable with 2-3 iteration cycles. 20-post labeled benchmark set available for validation.

## Interfaces & Dependencies

- **X API v2** — OAuth 2.0 (user context), $0.005/post, 180 req/15min, 800-bookmark ceiling
- **TwitterAPI.io** — API key, $0.15/1000 tweets, advanced search operators (verify in Phase 0)
- **OpenClaw** — Required for Tess's triage and Telegram delivery. Pipeline queues items if offline.
- **Telegram bot** — Existing Tess channel for digest delivery and reply-based feedback
- **macOS Keychain** — Credential storage for all API tokens
- **Vault directories:** `_openclaw/feeds/` (items/, digests/, kb-review/), `_openclaw/config/operator_priorities.md`, `_openclaw/inbox/feed-intel-*.md`

## Next Actions

- **Resolve in PLAN:** Implementation language (Node.js per OpenClaw stack), register `type: x-feed-intel` in vault taxonomy, track new `_openclaw/` subdirectories
- **Phase 0 (pre-implementation):** API account setup, operator verification of search queries, TwitterAPI.io advanced search operator validation, thread heuristic field verification
- **Phase 1:** Core pipeline (all components), triage prompt engineering, reply-based control protocol with `save` and `research` commands (research includes context enrichment via TwitterAPI.io), cost telemetry with guardrails, runtime ops guide
- **Phase 2:** Account monitoring, full automatic thread expansion (for all flagged items, not just research), historical trend analysis, backpressure router
- **Phase 3:** Automated topic suggestion, per-topic weight adjustment from feedback, auto-save rule proposals
