---
type: solution
status: active
track: bug
created: 2026-03-09
updated: 2026-04-04
domain: software
topics:
  - moc-crumb-operations
tags:
  - kb/software-dev
  - tess
  - openclaw
  - haiku
  - prompt-engineering
---

# Haiku SOUL.md Behavior Injection Ceiling

## Problem

New behavioral sections added to Tess's SOUL.md (~15KB) fail to reliably trigger on Haiku. Three iterations of increasing directness all produced conversational responses instead of procedure execution:

1. **50-line embedded procedure** — Haiku recognized intent but responded conversationally
2. **Imperative steps + "Do NOT answer conversationally" guard** — Haiku asked for clarification
3. **4-line thin trigger ("run this script")** — still conversational

## Root Cause

Haiku can't reliably override its conversational defaults to execute a command from within an active Telegram session. General behavioral instructions earlier in SOUL.md ("Assess, decide, move", "Default: Read, Route, Proof, Next") have higher attention weight and override procedure-specific instructions added later.

This is fundamentally different from **dedicated cron prompts** (morning briefing) where the entire session context IS the procedure — no competing behavioral instructions.

## Pattern

| Approach | Haiku Reliability | Use When |
|----------|------------------|----------|
| Dedicated session prompt (cron/exec) | High | Procedure must fire reliably (morning briefing, meeting prep) |
| SOUL.md behavior section | Low | Nice-to-have convenience, not critical path |
| SOUL.md thin trigger to script | Low | Same problem — Haiku still defaults to conversation |

## Mitigation

- **Deterministic work → bash scripts.** File reads, data assembly, file writes — anything that doesn't need LLM judgment.
- **LLM synthesis → dedicated session invocation.** Use `openclaw exec` with a focused prompt, not SOUL.md injection.
- **SOUL.md → routing hints only.** Keep SOUL.md sections for behavioral context (voice, boundaries, security), not procedural execution.

## Affected Tasks

- **TOP-047 fn1 (session prep):** Resolved via terminal-triggered script. SOUL.md trigger left as aspirational for Sonnet upgrade.
- **TOP-047 fn2 (meeting prep):** Must use dedicated session invocation — Telegram trigger is non-negotiable (brief delivered to phone before meetings).

## Related

- Haiku date hallucination (MEMORY.md)
- Haiku quality on FIF triage (47% T1 rate — overnight-research-design.md §Model Selection)
- `_system/docs/solutions/` pattern catalog
