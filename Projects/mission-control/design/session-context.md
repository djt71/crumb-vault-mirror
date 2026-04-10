---
type: session-context
project: mission-control
domain: software
created: 2026-03-07
source: claude-ai-session
status: active
updated: 2026-03-07
---

# Mission Control Dashboard — Session Context

## What happened

A claude.ai exploration session (2026-03-07) produced the full SPECIFY-phase
deliverables for a new project: mission-control. The session included:

1. **Landscape survey** of dashboard tools (Homepage, Grafana, NASA Open MCT,
   builderz-labs/mission-control, self-hosted dashboards)
2. **Deep exploration** of the vault mirror — reading tess-operations specs
   (chief-of-staff, Google, Apple, comms, memory search, frontier ideas,
   beyond-current-roadmap), A2A spec, AKM audit, FIF action plan, design
   taste profile, web design preference overlay, inbox-processor skill,
   vault-query skill, and multiple other design docs
3. **Draft specification** — 566-line spec covering 7-page architecture,
   attention-item vault primitive, technical stack, build order, design system
4. **Peer review** by 4 models (Gemini 3, DeepSeek V3.2, GPT-5.2, Perplexity)
5. **Review synthesis** — 20 amendments (10 must-fix, 10 should-fix), 5 declines
6. **Amended spec v2** — all 20 amendments applied, 664 lines

## Files to ingest

All files should be placed under `Projects/mission-control/`:

| File | Destination | Content |
|------|-------------|---------|
| `mission-control-spec-v2.md` | `design/specification.md` | Amended specification (v2, post-review) |
| `mission-control-review-synthesis.md` | `reviews/2026-03-07-peer-review-synthesis.md` | Review synthesis with 20 amendments |
| `mission-control-review-context.md` | `design/review-context.md` | Context briefing sent to reviewers |

The review prompt (`mission-control-review-prompt.md`) and original draft
(`mission-control-spec-draft.md`) are superseded by v2 and the synthesis.
Keep for reference if desired, discard if not.

## Current phase

**SPECIFY — complete.** The spec has been written and peer reviewed. Next
phase is PLAN (action-architect produces task decomposition).

## Cross-project impacts

This project touches six existing projects. Key implications:

**feed-intel-framework** — M-Web (FIF-W01–W12) is absorbed. The Intelligence
page Pipeline section replaces M-Web. Kill-switch: if Pipeline can't reach
M-Web parity by end of Phase 1 M3, M-Web reverts to standalone. FIF action
plan needs amendment to reflect this absorption or the kill-switch decision.

**agent-to-agent-communication** — Dashboard implements A2A-015.1/015.2/015.3
(mission control scaffolding, read UI, feedback adapter) and later A2A-019
(approval) and A2A-024 (control plane). Phase 4+ write endpoints are
explicitly A2A facades. A2A tasks should cross-reference this project's
milestones. No A2A changes needed now — the dashboard is designed to be
A2A-independent through Phase 3.

**tess-operations** — Dashboard consumes tess-ops data (heartbeat, briefings,
dispatch state, ops metrics, intelligence outputs). New mechanic check needed:
dashboard health endpoint monitoring (extends TOP-011). Two new scripts needed
for Ops page: `system-stats.sh` and `service-status.sh`. These can be created
as part of this project's Phase 1 or as tess-ops tasks — decide in PLAN.

**active-knowledge-memory** — Dashboard closes the AKM feedback loop (audit
finding F3) by consuming `akm-feedback.jsonl` and surfacing hit rates, dead
knowledge candidates, and an actionable "review stale sources" path on the
Knowledge page. No AKM code changes required — the dashboard reads existing
data.

**customer-intelligence** — Dashboard displays account dossier data with
privacy constraints (C7: no public routes expose customer data, PII omitted
by default). Customer/Career page comes in Phase 3, so plenty of time to
align data access patterns.

**crumb-tess-bridge** — Dashboard reads dispatch state files for the Agent
Activity page dispatch log. Read-only, no bridge changes needed.

## Attention-item primitive

The spec introduces a new vault note type (`type: attention-item`) that needs
to be registered in file-conventions.md and vault-check.sh. This is a PLAN
task, not a SPECIFY task. Key schema fields: `attention_id`, `kind` (system /
relational / personal), `source_ref`, `created_by`, `status`, `urgency`,
`action_type`. Full schema in spec §7.1.

## Design phase (Phase 0)

The spec mandates a visual design gate before any React code. Observatory mode
(from the taste profile) is a hypothesis to be validated via mockups. The
design gate has a 10-item checklist (spec §9.1). Design tooling is TBD
(operator choosing between Figma and alternatives). Phase 0 can start
immediately — it has no upstream dependencies.

## What to do first

1. Create the project directory structure (`Projects/mission-control/`)
2. Place the spec and review files per the table above
3. Create `project-state.yaml` (phase: SPECIFY, status: reviewed)
4. Run the action-architect skill to produce the PLAN phase deliverables
   (action plan + task decomposition) from the reviewed spec
5. The action plan should account for cross-project impacts listed above

## Key decisions already made

- 6 pages (Intelligence + Feed Intelligence merged), with Phase 0 checkpoint to split back to 7 if needed
- React + Vite + Tailwind + Express BFF (justified in spec A1)
- Attention-lite in Phase 1 (not deferred to Phase 2)
- Mandatory Phase 1 retrospective before Phase 2
- Phase 4+ writes are A2A facades, not independent logic
- Vault-native attention items (markdown + frontmatter), not SQLite-native
- Desktop-first, mobile triage-capable for Attention + Ops only
- M-Web absorption with kill-switch at Phase 1 M3
