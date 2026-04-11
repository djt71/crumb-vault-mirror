---
type: reference
status: active
domain: software
created: 2026-03-14
updated: 2026-04-11
tags:
  - system/llm-orientation
topics:
  - moc-crumb-architecture
---

# LLM Orientation Map

Index of every LLM-consumed document in the Crumb/Tess system — location, token budget, loading trigger, and architecture source. Enables gap detection and staleness tracking.

**Architecture source:** [[00-architecture-overview]]

---

## Core Context (Loaded Every Session)

| Document | Location | Est. Tokens | Load Trigger | Update Trigger | Architecture Source |
|----------|----------|-------------|-------------|----------------|-------------------|
| CLAUDE.md | `/CLAUDE.md` | ~2,860 | Session start (system-reminder) | Operational procedure changes, new primitives, schema changes | [[01-context-and-scope]] §Constraints |
| AGENTS.md | `/AGENTS.md` | ~973 | Session start (system-reminder) | New subagent creation, routing changes | [[02-building-blocks]] §Subagents |
| MEMORY.md | `~/.claude/projects/.../memory/MEMORY.md` | ~2,080+ | Session start (auto-memory) | Discoveries during sessions | N/A (per-machine) |
| overlay-index.md | `_system/docs/overlays/overlay-index.md` | ~983 | Session start (startup hook) | New overlay creation, signal changes | [[02-building-blocks]] §Overlays |

**Session start total:** ~6,900 tokens (before any skill or project context)

---

## Skill Definitions (Loaded on Invocation)

| Skill | Location | Est. Tokens | Load Trigger | Update Trigger | Architecture Source |
|-------|----------|-------------|-------------|----------------|-------------------|
| action-architect | `.claude/skills/action-architect/SKILL.md` | ~1,500 | Skill trigger phrase | Workflow decomposition changes | [[02-building-blocks]] §Skills |
| attention-manager | `.claude/skills/attention-manager/SKILL.md` | ~2,400 | "plan my day", "daily attention" | Goal-tracker schema, attention planning | [[03-runtime-views]] §AKM |
| audit | `.claude/skills/audit/SKILL.md` | ~1,800 | "audit vault", "check for drift" | Vault-check rule changes | [[05-cross-cutting-concepts]] §vault-check |
| checkpoint | `.claude/skills/checkpoint/SKILL.md` | ~550 | Phase transitions | Context management changes | [[05-cross-cutting-concepts]] §Context Budget |
| code-review | `.claude/skills/code-review/SKILL.md` | ~3,000 | "review this code" | Review panel model changes | [[02-building-blocks]] §Code Review |
| critic | `.claude/skills/critic/SKILL.md` | ~1,800 | "critique this", "find problems", "adversarial review" | Critic framework changes | [[02-building-blocks]] §Skills |
| deck-intel | `.claude/skills/deck-intel/SKILL.md` | ~2,600 | "process this deck" | Extraction format changes | [[02-building-blocks]] §Skills |
| deliberation | `.claude/skills/deliberation/SKILL.md` | ~3,500 | "deliberate on", "panel review" | Evaluator panel, overlay routing | [[02-building-blocks]] §Skills |
| diagram-capture | `.claude/skills/diagram-capture/SKILL.md` | ~2,350 | "capture this diagram" | Image classification changes | [[02-building-blocks]] §Skills |
| feed-pipeline | `.claude/skills/feed-pipeline/SKILL.md` | ~3,400 | "process feed items" | FIF schema changes, tier logic | [[03-runtime-views]] §Feed Pipeline |
| inbox-processor | `.claude/skills/inbox-processor/SKILL.md` | ~6,700 | "process inbox" | Sentinel format, routing rules | [[02-building-blocks]] §Skills |
| learning-plan | `.claude/skills/learning-plan/SKILL.md` | ~2,900 | "learn", "training plan" | Pedagogy framework changes | [[02-building-blocks]] §Skills |
| mermaid | `.claude/skills/mermaid/SKILL.md` | ~4,000 | "diagram this", "chart", "excalidraw", "sketch" | Mermaid or Excalidraw syntax changes | [[02-building-blocks]] §Skills |
| peer-review | `.claude/skills/peer-review/SKILL.md` | ~2,650 | "peer review", "get review" | Review panel model changes | [[02-building-blocks]] §Skills |
| researcher | `.claude/skills/researcher/SKILL.md` | ~4,150 | "research", "investigate" | Pipeline stage changes | [[02-building-blocks]] §Skills |
| startup | `.claude/skills/startup/SKILL.md` | ~400 | Session start | Startup sequence changes | [[03-runtime-views]] §Session Lifecycle |
| sync | `.claude/skills/sync/SKILL.md` | ~500 | Session end, milestones | Commit/push logic changes | [[05-cross-cutting-concepts]] §Git Patterns |
| systems-analyst | `.claude/skills/systems-analyst/SKILL.md` | ~1,650 | "analyze this", "write a spec" | Spec schema changes | [[02-building-blocks]] §Skills |
| vault-query | `.claude/skills/vault-query/SKILL.md` | ~700 | "query the vault" | Query format changes | [[02-building-blocks]] §Skills |
| writing-coach | `.claude/skills/writing-coach/SKILL.md` | ~1,000 | "improve this", "review my writing" | Writing evaluation changes | [[02-building-blocks]] §Skills |

**Skill layer total:** ~47,550 tokens (all 20 skills; only 1-3 loaded per session). Removed since 2026-03-14: excalidraw, lucidchart, meme-creator, obsidian-cli. Added: critic, deliberation.

---

## Overlays (Loaded on Demand)

| Overlay | Location | Est. Tokens | Load Trigger | Update Trigger | Architecture Source |
|---------|----------|-------------|-------------|----------------|-------------------|
| business-advisor | `_system/docs/overlays/business-advisor.md` | ~716 | Business/market context | Framework updates | [[02-building-blocks]] §Overlays |
| career-coach | `_system/docs/overlays/career-coach.md` | ~858 | Career/professional context | Career framework updates | [[02-building-blocks]] §Overlays |
| design-advisor | `_system/docs/overlays/design-advisor.md` | ~707 (+companion) | Visual design tasks | Design principles updates | [[02-building-blocks]] §Overlays |
| financial-advisor | `_system/docs/overlays/financial-advisor.md` | ~922 | Financial decisions | Financial framework updates | [[02-building-blocks]] §Overlays |
| glean-prompt-engineer | `_system/docs/overlays/glean-prompt-engineer.md` | ~538 | Glean queries (Infoblox) | Glean capability changes | [[02-building-blocks]] §Overlays |
| life-coach | `_system/docs/overlays/life-coach.md` | ~975 (+companion) | Personal direction, values | Philosophy updates | [[02-building-blocks]] §Overlays |
| network-skills | `_system/docs/overlays/network-skills.md` | ~844 (+companion) | DNS/network tasks | Vendor doc updates | [[02-building-blocks]] §Overlays |
| web-design-preference | `_system/docs/overlays/web-design-preference.md` | ~943 (+companion) | Web design for Danny | Taste profile changes | [[02-building-blocks]] §Overlays |

**Overlay layer total:** ~6,503 tokens (overlays only; companions add ~2,000-5,000 each)

---

## Tess Context (OpenClaw Agent)

| Document | Location | Est. Tokens | Load Trigger | Update Trigger | Architecture Source |
|----------|----------|-------------|-------------|----------------|-------------------|
| SOUL.md | `_openclaw/staging/SOUL.md` | ~4,044 | OpenClaw session start | Personality/behavioral changes | [[01-context-and-scope]] §Actors |
| IDENTITY.md | `_openclaw/staging/IDENTITY.md` | ~33 | OpenClaw session start | Agent role changes | [[01-context-and-scope]] §Actors |

---

## Protocols (Loaded at Phase Transitions)

| Document | Location | Est. Tokens | Load Trigger | Update Trigger | Architecture Source |
|----------|----------|-------------|-------------|----------------|-------------------|
| context-checkpoint-protocol.md | `_system/docs/context-checkpoint-protocol.md` | ~1,394 | Phase transitions | Phase gate workflow changes | [[05-cross-cutting-concepts]] §Compound |
| session-end-protocol.md | `_system/docs/protocols/session-end-protocol.md` | ~1,073 | Session end (autonomous) | Session-end process changes | [[03-runtime-views]] §Session Lifecycle |
| bridge-dispatch-protocol.md | `_system/docs/protocols/bridge-dispatch-protocol.md` | ~178 | Bridge dispatch stage | Dispatch format changes | [[03-runtime-views]] §Bridge Handoff |
| convergence-rubrics.md | `_system/docs/convergence-rubrics.md` | ~438 | Quality evaluations | Convergence criteria updates | [[05-cross-cutting-concepts]] §Convergence |
| file-conventions.md | `_system/docs/file-conventions.md` | ~4,505 | Before creating new files | Schema/tag/type changes | [[05-cross-cutting-concepts]] §Frontmatter |
| personal-context.md | `_system/docs/personal-context.md` | ~416 | Session-wide (budget-exempt) | Personal preferences change | N/A (personal) |

---

## Subagent Definitions (Loaded on Dispatch)

| Agent | Location | Est. Tokens | Load Trigger | Update Trigger | Architecture Source |
|-------|----------|-------------|-------------|----------------|-------------------|
| code-review-dispatch | `.claude/agents/code-review-dispatch.md` | ~2,100 | code-review skill dispatch | Model/reviewer changes | [[02-building-blocks]] §Subagents |
| peer-review-dispatch | `.claude/agents/peer-review-dispatch.md` | ~2,650 | peer-review skill dispatch | Model/reviewer changes | [[02-building-blocks]] §Subagents |
| deliberation-dispatch | `.claude/agents/deliberation-dispatch.md` | ~2,800 | deliberation skill dispatch | Panel config, overlay binding | [[02-building-blocks]] §Subagents |
| test-runner | `.claude/agents/test-runner.md` | ~1,100 | Test execution | Test framework changes | [[02-building-blocks]] §Subagents |

---

## System Configuration (Loaded by Hooks/Skills)

| Document | Location | Est. Tokens | Load Trigger | Update Trigger | Architecture Source |
|----------|----------|-------------|-------------|----------------|-------------------|
| skill-preflight-map.yaml | `_system/docs/skill-preflight-map.yaml` | ~515 | PreToolUse hook (every skill) | Skill KB eligibility changes | [[02-building-blocks]] §Skills |
| code-review-config.md | `_system/docs/code-review-config.md` | ~852 | code-review-dispatch agent | Review model/policy changes | [[02-building-blocks]] §Code Review |
| review-safety-denylist.md | `_system/docs/review-safety-denylist.md` | ~623 | Review dispatch | Safety pattern updates | [[02-building-blocks]] §Code Review |
| claude-ai-context.md | `_system/docs/claude-ai-context.md` | ~2,653 | claude.ai sessions (manual) | Project state changes | N/A (orientation checkpoint) |

---

## Token Budget Summary

| Category | Documents | Est. Tokens | Loading Pattern |
|----------|-----------|-------------|-----------------|
| Core context | 4 | ~6,900 | Every session |
| Skills (all 20) | 20 | ~47,550 | 1-3 per session |
| Overlays (all 8) | 8 (+4 companions) | ~6,503 (+companions) | 0-2 per session |
| Tess context | 2 | ~4,077 | OpenClaw only |
| Protocols | 6 | ~8,004 | Per phase/event |
| Subagents | 4 | ~8,650 | On dispatch |
| System config | 4 | ~4,643 | Per hook/skill |
| **Total inventory** | **48** | **~86,327** | — |

**Typical session budget:** Core (~7k) + 1-2 skills (~4-10k) + 0-1 overlay (~1k) + protocol (~2k) = **~14-20k tokens** for orientation docs before project-specific context.

---

## Gap Analysis

### Subsystems With Orientation Coverage

| Subsystem | Coverage | Documents |
|-----------|----------|-----------|
| Session lifecycle | Full | CLAUDE.md, startup SKILL.md, session-end-protocol, checkpoint SKILL.md |
| Skill system | Full | 22 SKILL.md files, skill-preflight-map.yaml |
| Overlay system | Full | overlay-index.md, 8 overlay files |
| Feed pipeline | Full | feed-pipeline SKILL.md, file-conventions.md |
| Bridge protocol | Full | bridge-dispatch-protocol.md, CLAUDE.md §Bridge |
| AKM/Knowledge | Full | file-conventions.md, kb-to-topic.yaml |
| Code review | Full | code-review SKILL.md, code-review-config.md, code-review-dispatch agent |
| Peer review | Full | peer-review SKILL.md, peer-review-dispatch agent |
| vault-check | Full | CLAUDE.md §File Access, file-conventions.md |
| Tess personality | Full | SOUL.md, IDENTITY.md |

### Subsystems With Gaps

| Subsystem | Gap | Recommendation |
|-----------|-----|----------------|
| Mission Control dashboard | No LLM orientation doc for dashboard API/structure | **Defer** — dashboard is consumed by humans via browser, not LLMs. No LLM needs to understand its internal structure. |
| OpenClaw gateway config | No LLM-facing doc for openclaw.json structure | **Defer** — gateway config is managed manually. Tess operates through the gateway, not on it. |
| LaunchAgent/daemon management | No LLM-facing reference for service management | **Defer** — service management is human-operated (sudo required). Covered in operator how-to docs. |
| Vault-check rule details | vault-check.sh is consumed directly, not via summary | **Not needed** — vault-check output is machine-readable. Crumb reads error messages, not the script. |
| Design spec | No LLM-optimized summary of the 46k-token spec | **Fill candidate** — a spec-summary for LLM context loading would reduce unnecessary full-spec reads. Exists as `crumb-design-spec-v2-4-summary.md` but may be stale. Check staleness. |
| Automation hooks | No doc explaining the hook chain (PreToolUse, PostToolUse, SessionStart) | **Fill candidate** — hooks are invisible infrastructure that affect every session. A brief orientation doc would help debugging. |

### Recommendations

1. **Check staleness** of `crumb-design-spec-v2-4-summary.md` — if current, the spec gap is already filled
2. **Consider** a lightweight hooks orientation doc (~50 lines) for the automation chain
3. **No action needed** on Mission Control, OpenClaw config, LaunchAgent, or vault-check gaps — these are human-operated subsystems
