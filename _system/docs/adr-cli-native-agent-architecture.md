---
type: reference
domain: software
status: active
created: 2026-02-25
updated: 2026-02-25
skill_origin: compound
confidence: high
tags:
  - kb/software-dev
  - architecture
  - agent-design
topics:
  - moc-crumb-operations
---

# ADR: CLI-Native Agent Architecture

Crumb treats CLI text-in/text-out interfaces as the primary agent integration surface and separates agent reasoning from execution environments using OS-level primitives rather than container sandboxing. This document makes explicit what has been implicit across multiple projects.

## Decision

Agent tools and inter-agent communication use CLI and filesystem interfaces by default. Container sandboxing, MCP servers, and custom protocols are adopted only when CLI+filesystem is demonstrably insufficient.

## Context

Two independent industry signals (Feb 2026) validate this as a convergent pattern:

**Karpathy (CLI-as-agent-interface):** CLIs are agent-native because they are text-in/text-out — the same modality as language models. Unix composability maps directly to agent composability. Concrete data: CLI commands consume ~4,150 tokens vs MCP's ~145,000 for equivalent tasks (35x reduction), with 28% higher task completion rates at equivalent token budgets.

**Chase / LangChain (separation of concerns):** "Sandbox as Tool" (agent runs locally, calls execution environment remotely) is superior to "Agent IN Sandbox" for production. Key advantages: API keys stay outside sandbox, instant logic updates without rebuilds, clean security boundaries.

## Crumb Implementation

This pattern is already operational across the stack:

| Project | CLI-Native Pattern |
|---------|-------------------|
| **Crumb core** | Claude Code CLI session; Bash/Read/Write/Edit/Grep/Glob as tool surface |
| **Crumb-Tess Bridge** | `claude --print` + filesystem exchange (`_openclaw/inbox/outbox/`) |
| **OpenClaw colocation** | OS-level user separation, loopback binding, launchd process boundaries |
| **X Feed Intel** | cron → Node.js scripts → API calls → file writes → `claude --print` triage |

## Boundary: When CLI Isn't Enough

CLIs compose well within a trust boundary. Crossing trust boundaries (cross-user execution, enterprise compliance, multi-tenant permission scoping) needs additional structure — the bridge spec chose filesystem exchange over cross-user CLI invocation for exactly this reason. MCP retains value for services without CLI interfaces and for production security requirements.

## Evidence

- Karpathy post (2026-02-24): [@karpathy/status/2026360908398862478](https://x.com/karpathy/status/2026360908398862478)
- Chase / LangChain blog (2026-02-10): [@hwchase17/status/2021261552222158955](https://x.com/hwchase17/status/2021261552222158955)
- Token efficiency data: Reinhard 2026, benchmark comparison (gist/szymdzum)
- Crumb internal: openclaw-colocation (DONE), crumb-tess-bridge (Phase 2 deployed), x-feed-intel (IMPLEMENT)
