---
type: action-plan
project: documentation-overhaul
domain: software
status: active
created: 2026-03-14
updated: 2026-03-14
skill_origin: action-architect
tags:
  - system/docs
  - system/architecture
topics:
  - moc-crumb-architecture
---

# Documentation Overhaul — Action Plan

## Context Inventory

- `design/specification-summary.md` — approved spec summary (1 doc)
- No overlays loaded (no matching activation signals)
- No estimation calibration history exists
- No relevant solution patterns in `_system/docs/solutions/`

---

## M1: Infrastructure Prerequisites

**Success criteria:** New tags pass vault-check. Directory structure exists for all three tracks.

### M1.1: Tag Taxonomy + Directory Setup

Update `file-conventions.md` and `vault-check.sh` to accept `system/architecture`, `system/operator`, and `system/llm-orientation` tags. Create the directory structure under `_system/docs/` for architecture, operator (with Diátaxis subdirectories), and llm-orientation.

**Tasks:** DOH-001, DOH-002

**Session estimate:** Combined with first Phase 1 session (lightweight).

---

## M2: Architecture Foundation

**Success criteria:** Five architecture docs + overview exist in `_system/docs/architecture/`, each with Mermaid diagrams and prose fallbacks, passing vault-check. All absorbed docs have stub-and-archive redirects. Danny has reviewed each doc pass/fail.

### M2.1: Context and Scope (Session 1)

Create the overview stub, then draft the broadest-view doc: system boundary, actors, external interfaces. Absorb `system-architecture-diagram.md`, `attachments/tess-crumb-architecture.md`, and actor definitions from `tess-crumb-comparison.md`.

**Source material:** Design spec, version history, CLAUDE.md, SOUL.md, OpenClaw infrastructure notes.

**Tasks:** DOH-003, DOH-004, DOH-005

### M2.2: Building Blocks (Session 2)

Subsystem decomposition, ownership map, dependency diagram. Absorb `tess-crumb-boundary-reference.md` and ownership/routing content from `tess-crumb-comparison.md`.

**Source material:** Design spec, version history, SKILL.md files, vault structure, dashboard repo notes.

**Tasks:** DOH-006, DOH-007

### M2.3: Deployment (Session 3)

Physical topology, process model, network, storage, credentials, DNS. No docs to absorb — this is net-new content.

**Source material:** Design spec, version history, OpenClaw infrastructure notes, health-check config, Cloudflare setup.

**Tasks:** DOH-008

### M2.4: Runtime Views (Session 4)

Behavioral flows as sequence diagrams: session lifecycle, Tess dispatch, feed pipeline, Mission Control, bridge handoff, AKM surfacing. Absorb `feed-intel-processing-chain.md` + diagram.

**Source material:** Design spec, version history, SKILL.md files, bridge architecture docs, dashboard source code.

**Tasks:** DOH-009, DOH-010

### M2.5: Cross-Cutting Concepts + Overview (Session 5)

Observable conventions and enforced patterns (not restated principles). Then complete the overview with navigation links and terminology index.

**Source material:** `file-conventions.md`, `vault-check.sh`, CLAUDE.md, `skill-authoring-conventions.md`, `code-review-config.md`.

**Tasks:** DOH-011, DOH-012

---

## M3: Operator Documentation

**Success criteria:** All minimum-set operator docs exist in `_system/docs/operator/`, each classified to exactly one Diátaxis quadrant, passing vault-check. Legacy docs migrated and retagged. Ops/ directory retired. Danny has reviewed each batch pass/fail.

### M3.1: Migration Batch (Session 6, or parallel with M2)

Move and retag 6 "keep as-is" docs. Check each against its Diátaxis quadrant — flag any that need normalization. Then expand the deployment runbook to cover OpenClaw upgrade scope.

**Tasks:** DOH-013, DOH-013b

### M3.2: Core Reference (Session 7)

Draft the three highest-value reference docs by scanning vault and code for structured entries.

**Tasks:** DOH-014, DOH-015, DOH-016

### M3.3: Subsystem Operations (Session 8-9)

Draft feed pipeline how-to, triage how-to, SQLite schema reference, and Mission Control tutorial. Stability gate applies — stub any unstable-interface docs.

**Tasks:** DOH-017, DOH-018, DOH-019, DOH-020

### M3.4: Onboarding + Explanation (Session 10-11)

Draft tutorials and explanation docs. Absorb personality model from `tess-crumb-comparison.md` into `why-two-agents.md`.

**Tasks:** DOH-021, DOH-022, DOH-023, DOH-024, DOH-025, DOH-026

### M3.5: Remaining Reference + How-To (Session 12-13)

Draft remaining operator docs: update-a-skill, rotate-credentials, add-knowledge-to-vault (absorb NLM import process), tag-taxonomy-reference, overlays-reference.

**Tasks:** DOH-027, DOH-028, DOH-029, DOH-030, DOH-031

---

## M4: LLM Orientation Map

**Success criteria:** `orientation-map.md` exists in `_system/docs/llm-orientation/`, lists all LLM-consumed docs with location, budget, update trigger, and architecture source. Gap analysis documented. Danny has reviewed pass/fail.

### M4.1: Build Map + Gap Analysis (Session 14)

Scan vault for all SKILL.md files, overlays, CLAUDE.md, SOUL.md, IDENTITY.md. Build the map, link to architecture sources, identify gaps.

**Tasks:** DOH-032, DOH-033

---

## Dependency Graph

```
M1 (prerequisites) → M2 (architecture) → M3 (operator docs)
                                        → M4 (orientation map)
```

M3 drafting and M4 can run in parallel after M2 completes, but M3 is higher priority.

**M3 parallelism exception:** DOH-013 (migration batch) depends only on M1 (DOH-001 + DOH-002), not on M2. It may begin as soon as tag taxonomy and directories are in place, even while architecture docs are being drafted. This is the sole M3 task that can run in parallel with M2. All M3 *drafting* tasks (DOH-014+) require both M2 completion (DOH-012) and migration completion (DOH-013).

Within M2, sessions are strictly sequential including absorb tasks: draft 01 → absorb 01 → draft 02 → absorb 02 → draft 04 → absorb 04 → draft 03 → absorb 03 → draft 05 → complete 00. Each draft depends on the prior session's absorb completing first.

Within M3, the migration batch (M3.1) must complete before AI drafting batches (M3.2-M3.5) begin. Drafting batches are sequential by priority but individual docs within a batch are independent.

---

## Risk Assessment

| Milestone | Risk | Rationale |
|---|---|---|
| M1 | Low | Mechanical tag/directory changes, fully reversible |
| M2 | Medium | Architecture docs become the authoritative source — factual errors compound downstream. Pass/fail review is the primary gate. |
| M3 | Low | Additive docs with no system impact. Migration is reversible. |
| M4 | Low | Single tracking artifact, no system impact |

---

## Session Estimate

| Milestone | Sessions | Notes |
|---|---|---|
| M1 | 0.5 | Combined with M2.1 |
| M2 | 5 | One doc per session, 01 and overview stub share session 1 |
| M3 | 7-8 | Migration + 4 drafting batches |
| M4 | 1 | Single session |
| **Total** | **13-14** | Upper range of spec estimate, accounting for consolidation work. 35 tasks (DOH-001 through DOH-034 + DOH-013b) |
