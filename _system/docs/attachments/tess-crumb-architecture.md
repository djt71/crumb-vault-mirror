---
type: attachment-companion
domain: software
status: archived
created: 2026-02-21
updated: 2026-03-14
tags:
  - system
  - openclaw
  - kb/software-dev
attachment:
  source_file: _system/docs/attachments/tess-crumb-architecture.png
  filetype: png
  source: external
  size_bytes: 187086
related:
  docs:
    - 01-context-and-scope.md
description: >
  Agent architecture diagram showing Danny (operator), Tess (primary agent,
  always-on via OpenClaw/Telegram), Crumb (deep work engine, session-bound
  via Claude Code), the _openclaw/ bridge boundary, and the Obsidian vault
  as source of truth. Includes handoff rules and capability mapping.
topics:
  - moc-crumb-architecture
---

# Agent Architecture Diagram

![[tess-crumb-architecture.png]]

For non-rendering environments: [[tess-crumb-architecture.png]]

> **Absorbed into [[01-context-and-scope]]** as part of the documentation overhaul (DOH-005).
> The context diagram, actor definitions, and system boundary now live in `_system/docs/architecture/01-context-and-scope.md`.
> This companion note is retained for the binary file reference.
