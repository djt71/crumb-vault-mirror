---
project: crumb
domain: software
type: log
skill_origin: null
status: active
created: 2026-02-12
updated: 2026-03-06
tags:
  - design-spec
  - crumb
  - version-history
---

## 10. Version History

> Pre-v2.0 versions (v0.1–v1.9.1): [[separate-version-history-archive]]

**v2.4** (2026-03-06)
- **Active Knowledge Memory, researcher skill, overlay expansion**
  - New system capability: Active Knowledge Memory (AKM) — QMD-backed semantic retrieval engine integrated into session startup as Knowledge Brief. Three trigger modes: session-start (5 items, cross-domain), skill-activation (3 items, project-scoped), new-content (5 items, cross-pollination). Decay-based relevance scoring: fast half-life (90 days) for technical topics, slow (365 days) for humanities, no decay for timeless. Daily deduplication prevents resurfacing. Feedback logging at `_system/logs/akm-feedback.jsonl`. Script: `_system/scripts/knowledge-retrieve.sh`. Project: `Projects/active-knowledge-memory/` (phase: DONE).
  - §9 "Semantic search via qmd" deferred item struck through — now operational via AKM (path 2: direct QMD in Crumb)
  - New skill: researcher (§3.3) — stage-separated evidence pipeline with 6 stages (Scoping, Planning, Research Loop, Synthesis, Citation Verification, Writing) orchestrated via Agent tool dispatch. Write-only-from-ledger citation integrity. Three rigor levels (`light`, `standard`, `deep`). YouTube adapter for video source ingestion. Skill directory: `stages/` (6 stage procedures + validation rules), `schemas/` (handoff, fact-ledger, telemetry templates). `model_tier: reasoning`. Project: `Projects/researcher-skill/`.
  - §9 "Web search tool integration" deferred item struck through — researcher skill uses Claude Code's built-in WebSearch/WebFetch
  - New solution doc: `_system/docs/solutions/write-only-from-ledger.md` — compound pattern from researcher skill (high confidence)
  - Three new overlays (§3.4.2): Career Coach (professional trajectory, stakeholder strategy), Life Coach (values clarification, life direction, habit change), Network Skills (DNS, DHCP/IPAM, SASE/SSE, hyperscaler networking, CDN, zero trust)
  - Companion Document pattern added to overlay-index.md — standing reference docs that auto-load alongside overlays. Three companions: Design Advisor dataviz (Tufte, Cleveland-McGill, Cairo, Ware), Life Coach personal philosophy, Network Skills vendor catalog
  - Design Advisor expanded: dataviz activation signals added (charts, dashboards, infographics); dataviz companion doc split from overlay body
  - Business Advisor expanded: formalizing/monetizing side projects, partnership evaluation, opportunity assessment added to activation signals; Financial Advisor cross-reference in anti-signals
  - 8 active overlays total (was 5). §9 overlay composition deferred item updated to reflect 8 overlays
  - §3.4.2 Active Overlays table synced with live `overlay-index.md` (authoritative)
  - MOC roster updated (§5.6.12): 15 built MOCs (was 14) — `moc-signals` added for feed-pipeline signal-notes
  - Feed-pipeline hardened: noise reduction, tighter classification thresholds, TTL cleanup script (`_system/scripts/feed-inbox-ttl.sh`)
  - §2.1 directory tree updated: researcher skill subdirectories, `knowledge-retrieve.sh`, `feed-inbox-ttl.sh`, `poetry-collection-v1.md` NLM template
  - Session startup (§6, §7.1): Knowledge Brief added as step 10 — runs `knowledge-retrieve.sh --trigger session-start`
  - §3.2 agent roster label updated from "v2.1" to "v2.4"
  - **Spec restructuring (294KB → 261KB):** inline version history replaced with pointer to `separate-version-history.md`; §3.3 struck-through skills compacted to "Built skills" table; §4.9 collapsed to tombstone; §9 struck-through items compacted; §4.1.4 Context Checkpoint Protocol replaced with summary + pointer (standalone doc already existed); §4.8 Hallucination Detection Protocol extracted to `_system/docs/protocols/hallucination-detection-protocol.md` with inline summary. Spec now fits within the 256KB single-read limit.
- Source: AKM project (full lifecycle), researcher-skill M4-M5 sessions, overlay creation sessions, feed-pipeline overhaul session, spec restructuring session

**v2.3** (2026-03-01)
- **Knowledge pipeline expansion — spec-reality sync**
  - New skill: feed-pipeline (§3.3) — 3-tier feed intel routing from `_openclaw/inbox/`. Tier 1: permanence evaluation → auto-promote to `Sources/signals/` as signal-notes (1a) or route to operator review queue (1b). Tier 2: action extraction → project run-logs. Tier 3: skip (TTL cron, Phase 2). Tags derived via `kb-to-topic.yaml`. MOC Core placement for promoted signal-notes. `model_tier: reasoning`.
  - New document type: signal-note (§2.2.5) — lightweight pointer-style KB capture from feed intel pipeline. Lives in `Sources/signals/`. Full frontmatter schema with `provenance` block for triage traceability. Promotion path to full knowledge-note preserves `source_id`.
  - New document type: source-index (§2.2.6) — per-source landing page aggregating all child knowledge notes. Named `[source_id]-index.md`, colocated with children. Canonical MOC entry point: one source = one MOC one-liner.
  - Five new canonical `#kb/` tags (§5.5): `fiction`, `biography`, `politics`, `psychology`, `lifestyle` — with corresponding MOC files in `Domains/Learning/`
  - MOC roster updated (§5.6.12): 14 built MOCs (was 0 built / 9 planned). Split into "Built" and "Planned starters" tables. New built MOCs: `moc-philosophy`, `moc-history`, `moc-writing`, `moc-business`, `moc-biography`, `moc-fiction`, `moc-gardening`, `moc-poetry`, `moc-politics`, `moc-psychology`, `moc-religion`, `moc-lifestyle` (plus existing `moc-crumb-architecture`, `moc-crumb-operations`)
  - New shared artifact: `_system/docs/kb-to-topic.yaml` — canonical `#kb/` tag → MOC slug mapping. Single source of truth used by inbox-processor, feed-pipeline, and batch scripts
  - inbox-processor upgraded: Step 3 (topics derivation via `kb-to-topic.yaml`), Step 4j (source-index note creation/update), Step 4k (MOC Core placement with operator confirmation). Acceptance criteria expanded.
  - Vault-check expanded from 23 to 25 checks (§7.8): check 24 (run-log size warning, 1000-line threshold), check 25 (signal-note schema validation — location, schema_version, source subfields, provenance subfields, topics, kb tag)
  - New `--pre-commit` mode for vault-check: `--pre-commit` flag scopes all checks to staged files only (~0.3s vs ~90s full scan). Pre-commit hook updated; `--full` for audits.
  - Session startup now reports feed-intel inbox count with tier breakdown (T1/T2/T3 classification)
  - Ceremony Budget Principle added to CLAUDE.md Workflow Routing — evaluate friction reduction before proposing new capabilities. Provenance: `_system/docs/crumb-v2-system-health-assessment.md`
  - Batch automation scripts added to §2.1: `_system/scripts/batch-moc-placement.py` (MOC Core placement for source-index notes), `_system/scripts/batch-book-pipeline/generate-source-index.py` (source-index generation from knowledge notes)
  - `Sources/signals/` directory added to §2.1
  - `feed-pipeline/SKILL.md` added to §2.1 skills tree
  - Type taxonomy updated: `signal-note` and `source-index` added to type comment in §2.2 frontmatter examples
- Source: feed-pipeline build, BBP-005/006 batch processing, inbox-processor MOC alignment, MOC pre-staging sessions

**v2.2** (2026-03-01)
- **Process simplification — session rating and signal capture removed**
  - Interactive 1-3 session rating removed from session-end sequence (zero entropy: 0 rating-1 entries out of ~120 sessions)
  - `signals.jsonl` archived to `signals-archive-2026.jsonl`, no longer appended
  - §4.9 deprecated (Signal Capture Protocol)
  - Failure logging now autonomous — Crumb assesses session quality from context (repeated errors, dead ends, rework, user frustration) rather than prompting the user
  - Audit skill step 7 switched from signal trend analysis to failure-log pattern analysis
  - Session-end protocol rewritten (5 steps instead of 6): `_system/docs/protocols/session-end-protocol.md`
  - CLAUDE.md session-end section updated to match
- **Vault-check `--pre-commit` mode (§7.8)**
  - New `--pre-commit` flag scopes all checks to staged files only (~0.3s vs ~90s full scan)
  - Pre-commit hook now invokes `vault-check.sh --pre-commit`; weekly audits use `--full`
- Provenance: Ceremony Budget Principle application
- Source: session-end rework session (2026-03-01)

**v2.1** (2026-02-25)
- **Spec–reality sync (drift analysis + today's commits)**
  - Code-review skill registered in spec: §2.1 directory tree (skill + config files), §3.3 backlog table struck through with full architectural description (two-tier: Sonnet inline Tier 1 + cloud panel Tier 2), §3.2 updated to reflect actual agents
  - Agent roster corrected: §2.1 `.claude/agents/` tree and §3.2 updated from theoretical frontend/backend designers (never built) to actual agents — `code-review-dispatch.md`, `peer-review-dispatch.md`, `test-runner.md`. Frontend/backend designers moved to Phase 2+ backlog table.
  - Vault-check §7.8 updated: "Twenty" label → "Twenty-three"; check 20 corrected from "Reserved" to "Source-Index Schema Validation" (added during knowledge-navigation project); check 22 renumbering note and script alignment clarified; check 23 added (Code Review Gate — enforces code review entries for post-2026-02-26 tasks in projects with `repo_path`, amnesty for earlier work, warning level). Phase 1b extension note updated.
  - `repo_path` field added to project-state.yaml schema in §4.1.5 (used by crumb-tess-bridge, feed-intel-framework, x-feed-intel; enforced by check 23)
  - Model routing amendment folded in as new §3.5 (skill `model_tier` field, execution vs reasoning tiers, Task tool delegation, phased rollout). Former §3.5 Primitive Creation Protocol renumbered to §3.6.
  - Web Design Preference overlay added to §3.4.2 Active Overlays table
  - `protocols/` directory added to §2.1 `_system/docs/` tree (`session-end-protocol.md`, `bridge-dispatch-protocol.md`, `inline-attachment-protocol.md`)
  - `code-review-config.md` and `review-safety-denylist.md` added to §2.1 `_system/docs/` tree
  - `reviews/` added to §2.1 project scaffold (optional, created on-demand; dual-location pattern: project-scoped under `Projects/[project]/reviews/`, system-level under `_system/reviews/`)
  - Peer-review model roster updated in §3.3: reflects 4-reviewer standard panel (GPT-5.2, Gemini 3 Pro Preview, DeepSeek V3.2-Thinking, Grok 4.1 Fast Reasoning); notes `peer-review-config.md` as authoritative
  - AGENTS.md skill list completed: added excalidraw, mermaid, lucidchart, code-review (4 missing skills)
  - Version history gap for v2.0.4 closed (this file)
- Source: spec-reality-drift-analysis-20260225.md, vault mirror commits 507334d and d4f8032

**v2.0.4** (2026-02-22)
- **Project lifecycle: DONE phase + completed-project guard**
  - New `phase: DONE` lifecycle state (§4.1.6) — lightweight alternative to full archival for completed projects that stay in `Projects/`
  - New `related_projects` optional field in project-state.yaml (§4.1.5) for cross-project linking
  - CLAUDE.md Completed Project Guard section: prevents scope creep into DONE/ARCHIVED projects, directs new work to create linked projects with `related_projects` back-reference
  - Vault-check #22 warns on design files created after a project is marked DONE
  - §4.6 updated to describe three lifecycle states (active/done/archived)
- Source: crumb-tess-bridge final sessions

**v2.0.3** (2026-02-22)
- **Compound retrieval loop closed (§3.1.1, §3.1.2, §4.4)**
  - Systems Analyst Step 1 now includes "Search for prior art" — globs `_system/docs/solutions/*.md` and scans filenames + frontmatter tags for relevance to the problem domain
  - Action Architect Step 1 now includes "Search for implementation patterns" — same glob, scoped to tech stack and architecture being planned
  - §4.4 routing table already specified the write path (compound → solutions); these changes close the read path
  - Both skill §3.1 summaries updated: key behavior includes solutions search, context contract adds MAY-request for solutions
- **Agent architecture documentation**
  - New `_system/docs/tess-crumb-comparison.md`: roles, boundaries, handoff model, design philosophy for the Tess-Crumb two-agent architecture
  - New `_system/docs/tess-crumb-boundary-reference.md`: operational routing guide (who owns what, handoff triggers, bridge protocol summary)
  - Architecture diagram at `_system/docs/attachments/tess-crumb-architecture.png` with companion note
  - Tess persona files (IDENTITY.md + SOUL.md) deployed to OpenClaw workspace as bootstrap files
- **CLAUDE.md Bridge Dispatch Stage Output (§6)**
  - Schema requirements for `claude --print` dispatch stage output added to CLAUDE.md
  - Field names, required structure, governance computation instructions — the durable instruction surface for model-generated structured output
  - Complements prompt-level task-specific context (Pattern 2 from automation patterns)
- **New solution docs**
  - `_system/docs/solutions/claude-print-automation-patterns.md`: 4 high-confidence patterns for `--print` orchestration — runner owns deterministic fields, CLAUDE.md as durable instruction surface, hash-verify/canary-stamp governance, budget for live deployment iteration
  - `_system/docs/solutions/write-read-path-verification.md`: compound infrastructure meta-pattern — verify read paths exist when building knowledge persistence infrastructure
- **OpenClaw operational updates**
  - `_system/docs/openclaw-skill-integration.md` pitfalls 7-8: Python module caching requires watcher restart, Tess polling timeout vs dispatch duration
- **Phase 2 dispatch live deployment**
  - First successful end-to-end dispatch (invoke-skill audit) through Telegram → Tess → OpenClaw → Watcher → Dispatch Engine → `claude --print` → Stage Runner → Response → Outbox
  - 867 tests total across all suites (416 Node.js + 451 Python)
- Source: crumb-tess-bridge Sessions 20-31 (Phase 2 IMPLEMENT), compound scan session

**v2.0.2** (2026-02-22)
- **Stale path fixes** — fixed 20 stale `session-log.md` path references across spec (pre-vault-restructure paths still pointing to `docs/` instead of `_system/logs/`)
- **Conditional session-end commit protocol (§6)**
  - Git diff drives commit behavior at session end: log-only delta → lightweight `chore:` commit, substantial delta → flag to user + descriptive commit, no changes → skip commit entirely
  - Applied to both CLAUDE.md session-end sequence and spec §6
- Source: crumb-tess-bridge Session 22

**v2.0.1** (2026-02-22)
- **Markdown rendering fix** — bridge echo-formatter outputs Markdown instead of raw HTML so OpenClaw's pipeline converts naturally to Telegram-safe HTML
- All 5 Phase 1 operations verified live with correct formatting (bold, code blocks, italic)
- Display-only patch, no protocol or schema changes
- Source: crumb-tess-bridge Session 18

**v2.0** (2026-02-22)
- **Crumb-Tess bridge — bidirectional Telegram communication**
  - Crumb is no longer CLI-only: the Tess bridge enables governed vault operations from any Telegram client
  - Architecture: Telegram → OpenClaw (Tess) → `_openclaw/inbox/` → kqueue file watcher → bridge processor → governance verification → `_openclaw/outbox/` → Tess → Telegram
  - 5 Phase 1 operations: approve-gate, reject-gate, query-status, query-vault, list-projects
  - Security: 4-layer defense (schema validation, payload hashing with canonical JSON, confirmation echo for write ops, post-processing governance verification), 15-payload injection test suite
  - 325 tests across all suites
  - Phase 2 dispatch protocol designed and peer-reviewed for long-running multi-stage task execution
  - §9 OpenClaw integration entry updated: Phases 1+3 operational, Phase 2/4 deferred
  - Project: `Projects/crumb-tess-bridge/` (16 tasks, 6 peer review rounds across lifecycle)
  - Full bridge specification at `Projects/crumb-tess-bridge/design/specification.md`
- Source: crumb-tess-bridge Sessions 1-19 (SPECIFY through Phase 1 IMPLEMENT)
