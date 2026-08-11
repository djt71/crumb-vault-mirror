---
type: reference
project: agentic-sunset
domain: software
status: archived
created: 2026-02-23
updated: 2026-07-03
skill_origin: null
tags:
  - feed-intel
  - operator-config
---

# Operator Priorities

Edit this file to steer feed-intel triage toward or away from specific topics.
The triage engine reads this as part of the vault snapshot (§5.5.0).

## Active (April 2026)

- **tess-v2 (IMPLEMENT):** Scheduled launchd services execution only — Amendment AC narrowed scope away from orchestrator role. Operator-facing planning moved upstream (claude.ai / Cowork / Remote Control). In-flight: TV2-038, TV2-040, TV2-057d/e/f scheduled-services work.
- **mission-control (TASK):** Dashboard Phase 3 — M3.1 intel feed density redesign (Surface-inspired dense list, multi-axis filters, shared tier config) blocks M8. Start: MC-080 + MC-082.
- **opportunity-scout (TASK):** M2 behavioral validation gate passed. 4-gate triage scoring (actionability gate) + Sonnet upgrade in production.
- **semuta (PLAN→TASK):** Scaffolding next (SEM-001).
- **firekeeper-books (ACT):** Phase 2 — Style Development, currently creating Frankenstein illustrations via Midjourney.
- **customer-intelligence (ACT):** Scaling validated pipeline to remaining accounts.
- **feed-intel-framework (DONE):** Phase 1 shipped. Reddit adapter code done, pending Reddit API approval. M6/M7 deferred as Phase 2.

## Ongoing interests

- Agent security, endpoint hardening, MCP security patterns
- Multi-agent orchestration patterns, subagent architectures
- Claude model updates (Opus/Sonnet/Haiku) and Claude Code / Agent SDK feature releases
- Local/open-weight model deployment and evaluation (Kimi K2.x family, Nemotron, Hermes runtime)
- DDI/DNS security — customer conversation positioning (Infoblox domain)
- Build-in-public, creator economy for technical builders
- Cloud-hosted agent surfaces (Anthropic Routines, Channels, Remote Control)
