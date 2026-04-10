---
project: opportunity-scout
domain: software
type: summary
skill_origin: systems-analyst
created: 2026-03-14
updated: 2026-03-14
source_updated: 2026-03-14
tags:
  - automation
  - tess
  - openclaw
  - opportunity-detection
---

# Opportunity Scout — Specification Summary

## Core Content

Opportunity Scout is an automated scanning system that continuously monitors the opportunity landscape for income-generating, skill-building, or creative side ventures matching Danny's profile. The daily pipeline (scan → score → digest → deliver) runs via dedicated cron jobs with bash coordination. Danny reviews a structured Telegram digest each morning and responds with simple feedback commands. Monthly evaluation cycles assess portfolio decisions.

The system is a sibling to FIF (shared adapter patterns, separate codebase) with its own ingestion layer for heterogeneous sources, a two-stage triage model (item-wise Haiku filter → batch Sonnet rank) calibrated from seven completed research dispatches (v1–v7), and a SQLite candidate registry (WAL mode) with dedup, lifecycle state machine, and digest-to-candidate identity mapping for feedback resolution. Scout stops at "surface, score, recommend, track" — portfolio decisions and stream execution happen elsewhere.

The primary failure mode is a firehose Danny learns to ignore. Every design decision is tested against this risk: threshold-based delivery (suppress empty digests), weekly health heartbeat (distinguish "no items" from "pipeline broken"), review throttles (1 research/day, 5 evaluations/month), abort criterion (M2, 30 days, <20% bookmark/research rate OR <5 digests delivered → stop), and the attention budget constraint (10–15 min/day max).

## Key Decisions

- **AD-1:** Dedicated cron jobs for orchestration, NOT Tess SOUL.md injection — Haiku SOUL.md ceiling is a proven failure mode
- **AD-2:** Sibling to FIF, not extension — source types too heterogeneous for FIF's feed-oriented ingestion
- **AD-3:** Vault data under Projects/opportunity-scout/data/, not _system/ — project data, not system infrastructure
- **AD-4:** SQLite for candidate registry (WAL mode) — follows FIF pattern, needed for dedup and state machine queries
- **AD-5:** Separate cron configs per model tier (Haiku triage, Sonnet digest, Opus monthly) — workaround for OpenClaw --model override bug
- **AD-6:** Direct Telegram Bot API for ALL Telegram interaction (delivery + feedback) — bypasses broken OpenClaw delivery/transport; OpenClaw used for LLM inference only
- **AD-7:** M0 constrained to RSS + HN API sources — prevents source integration complexity from blocking validation
- **AD-8:** Threshold-based delivery from day one — never send empty digests
- **AD-9:** Weekly health heartbeat — prevents silent suppression from masking pipeline failures
- **AD-10:** Two-stage triage (item-wise Haiku filter, then batch Sonnet rank) — separates cheap filtering from expensive ranking/writing

## Data Contracts

Spec defines four schemas inline (not referencing external docs):
- **Normalized Item Schema** — adapter → scoring interface contract (source_id, external_id, title, url, content_hash, etc.)
- **Candidate Record Schema** — full lifecycle record with gates, evidence, feedback_history, digest_appearances
- **Digest Mapping Table** — (digest_id, item_index, candidate_id, telegram_msg_id) for feedback command resolution
- **Source Registry Schema** — source_id, url, source_type, signal_tier, yield_score, parser_config, etc.

## Interfaces / Dependencies

- **FIF:** Pattern reuse (adapter interface, scoring concepts), not code sharing
- **OpenClaw:** Cron scheduling, LLM inference sessions. Transport bypassed (AD-6)
- **Telegram Bot API:** Direct delivery + feedback (AD-6 — unified path)
- **v1–v7 research dispatches:** Calibration data for scoring model, graveyard seed
- **book-scout:** Pattern reuse (Telegram interaction model) only, no functional overlap
- **Wisdom Library (future):** Future feedback loop — design deferred until stream exists (OSC-012)

## Critical Risks

- **A1 (HIGH):** Danny has no existing scanning habit. Creating a new daily behavior is the primary project risk. M1 gate: 5 qualifying digests reviewed within 21-day window, ≥10 scan cycles, bookmark/research rate ≥10%.
- **C7:** No baseline engagement data. The 10–15 min review target is an estimate with zero data points.
- **Cost fallback:** If Haiku fails M0 triage validation and Sonnet is required, pilot cost rises from ~$4–6/month to ~$12–18/month — exceeds $10/month ceiling. Renegotiation or volume reduction required.

## Next Actions

1. Peer review complete (r1, 4 reviewers, 5 must-fix + 10 should-fix applied)
2. Remaining open: U5 (research brief v0.5 location)
3. Ready to advance to PLAN phase — invoke action-architect
