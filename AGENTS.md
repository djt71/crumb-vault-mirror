# Crumb — Personal Multi-Agent Operating System

## What This Is
Crumb is a personal operating system for knowledge work across all life domains. It uses an Obsidian vault as a single source of truth for context, decisions, patterns, and deliverables. AI agents (currently Claude Code) orchestrate workflows, but this file is tool-agnostic — any AI system can use it for context.

## System Architecture
The system uses specialized AI capabilities orchestrated through a shared Obsidian vault:
- **Skills** — Repeatable procedures loaded on-demand (analysis, planning, writing, auditing)
- **Subagents** — Independent workers with isolated context for heavy design/analysis work
- **Overlays** — Domain expert lenses applied to active skills (business, technical, etc.)
- **Protocols** — Cross-cutting workflow patterns (convergence, compound engineering, hallucination detection)

## Domains
All work is classified into domains that determine workflow depth:
- **Software** — Full four-phase workflow (specify → plan → task → implement)
- **Knowledge work** (career, learning, financial) — Three-phase (specify → plan → act)
- **Personal** (health, relationships, creative, spiritual) — Two-phase (clarify → act)

## Core Principles
1. One system for everything — all domains share the same architecture
2. Plan → Design → Task → Implement — never jump straight to output; review at every gate, compound at every transition
3. Specs are the source of truth — change specs first, regenerate downstream
4. Every unit of work compounds — each task makes future tasks easier
5. Teach the system, don't do the work — prefer building skills over manual effort
6. Risk-tiered human-in-the-loop — auto-approve low-risk, require approval for high-risk
7. Grounded self-improvement — use external checks, never pure self-critique
8. Start simple, add complexity when empirically needed

## Vault Structure Overview
- `AGENTS.md` / `CLAUDE.md` — System configuration
- `_system/logs/session-log.md` — Non-project interaction history
- `_system/docs/` — Global references (spec, rubrics, overlays, patterns, calibration data)
- `Domains/` — Domain overviews and knowledge base notes (career, health, learning, etc.)
- `Projects/` — Active project workspaces with specs, designs, tasks, logs
- `Archived/` — Completed project archives
- `_attachments/` — Global binary storage with companion notes
- `_inbox/` — Drop zone for unprocessed files (transient)
- `_openclaw/` — OpenClaw gateway integration directory
- `_system/reviews/` — Peer review artifacts (consolidated notes + raw API responses)
- `.claude/` — AI-specific skills and agent definitions
- `_system/scripts/` — External validation and bootstrap tools

## Skills
- **systems-analyst** — Structured specification from ambiguous problems
- **action-architect** — Decompose specs into milestones and tasks
- **writing-coach** — Improve clarity, structure, tone, and brevity
- **audit** — Vault health checks, drift detection, staleness scans
- **checkpoint** — Log progress, compact context, verify vault files
- **sync** — Git commit, cloud backup at session end or milestones
- **inbox-processor** — Classify and route files dropped into `_inbox/`
- **peer-review** — Send artifacts to external LLMs for structured review
- **code-review** — Two-reviewer panel: Claude Opus (architectural reasoning via API) and Codex (tool-grounded review via CLI). Runs at milestone boundaries and on manual request.
- **mermaid** — Mermaid/Excalidraw diagrams (inline markdown or `.excalidraw` JSON)
- **startup** — Session initialization and startup summary

## File Conventions
Every substantive document uses YAML frontmatter. Project docs (under `Projects/`) require: project, domain, type, created, updated. Non-project docs additionally require: status. Binary files require colocated companion notes (`type: attachment-companion`). Summaries carry a `source_updated` field tracking their parent document's last modification. File naming is kebab-case and descriptive. See `_system/docs/file-conventions.md` for full details.

## Key Behaviors Any AI Tool Should Follow
- Read summary files before full documents
- Write YAML frontmatter on every new document
- Scope queries by project/domain — never search the entire vault unbounded
- Log decisions with rationale, not just outcomes
- When modifying a document with a summary, regenerate the summary
- Don't skip workflow phases — if the spec is wrong, update it first
