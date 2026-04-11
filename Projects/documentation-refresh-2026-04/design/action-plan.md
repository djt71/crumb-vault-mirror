---
type: action-plan
project: documentation-refresh-2026-04
domain: software
status: active
created: 2026-04-11
updated: 2026-04-11
skill_origin: action-architect
tags:
  - system/docs
  - system/architecture
topics:
  - moc-crumb-architecture
---

# Documentation Refresh 2026-04 — Action Plan

12 tasks across 5 milestones, ~5-6 sessions. Knowledge-work refresh — direct execution from this plan, no intermediate TASK phase.

## M1: Staleness Survey Closeout

**Goal:** Resolve the 4 unknowns from the spec before entering substantive edits, so M2+ work against verified state.

**Success criteria:**
- Live `launchctl list` captured and compared against `04-deployment.md` process model
- Tess-v2 current phase and soak state documented
- Bridge-watcher current service shape confirmed
- Either (a) unknowns resolved, or (b) explicit "accept as stated in spec" note with reason

**Dependencies:** None — entry point.

**Estimate:** 0 sessions (runs inline at start of first ACT session).

### Phase 1.1 — Live state capture
One task: DOC-001.

---

## M2: Architecture Refresh

**Goal:** All 6 architecture docs reflect 2026-04-11 system state. Dependency-ordered edits so downstream docs never reference stale claims from upstream ones.

**Success criteria:**
- Every `_system/docs/architecture/*.md` file has `updated: 2026-04-11` (or later) or an explicit "verified still current" run-log entry
- Skill count, subagent count, and overlay count agree across 02, 00, and future-refreshed operator docs
- Process model in 04 matches live `launchctl list`
- No doc cites Haiku 4.5 as Tess Voice or qwen3-coder as Tess Mechanic model
- Mermaid diagrams render without broken syntax

**Dependencies:** M1 complete.

**Estimate:** ~3 sessions.

### Phase 2.1 — Actor layer and interfaces
Doc 01 — context, actors, external interfaces, model routing. Task: DOC-002.

### Phase 2.2 — Subsystem inventories
Doc 02 — building blocks, skill/subagent/overlay/script tables. Task: DOC-003. This phase's output feeds DOC-008 and DOC-011 — if counts are wrong here, they propagate.

### Phase 2.3 — Deployment reality
Doc 04 — process model, LaunchAgents, host, credentials. Task: DOC-004. Must reflect email-triage shutdown and Nemotron model hosting.

### Phase 2.4 — Runtime flows
Doc 03 — sequence diagrams (session lifecycle, Tess dispatch, feed pipeline). Task: DOC-005. Must reflect Amendment Z interactive dispatch if stable.

### Phase 2.5 — Cross-cutting conventions
Doc 05 — conventions, vault-check, compound engineering. Task: DOC-006. Add compound engineering enhancements (track schema, conditional review routing, cluster analysis).

### Phase 2.6 — Overview + terminology
Doc 00 — must be last so terminology index reflects what the other 5 docs actually contain. Task: DOC-007.

---

## M3: Operator Refresh

**Goal:** Operator docs consistent with refreshed architecture. Surgical edits only — no rewrites unless >40% stale.

**Success criteria:**
- Every operator doc touched has `updated:` bumped
- Reference counts match architecture (skills-reference, overlays-reference, vault-structure-reference)
- Runbooks (how-to/) reflect current services and credential practices
- Tutorials would succeed for a new operator on 2026-04-11
- No explanation doc cites superseded models

**Dependencies:** M2 complete. (Technically DOC-008 reference refresh could run after DOC-003 alone, but keeping M3 gated on M2 completion simplifies batching.)

**Estimate:** ~2 sessions.

### Phase 3.1 — Reference batch (8 files)
Task: DOC-008. Surgical edits. skills-reference and tag-taxonomy-reference already have April updates — verify not contradict.

### Phase 3.2 — How-to batch (9 files)
Task: DOC-009. Key focus: crumb-deployment-runbook (email triage removal), rotate-credentials (OAuth redaction practice).

### Phase 3.3 — Tutorials + explanation batch (7 files)
Task: DOC-010. Walk through each tutorial; scan explanation docs for model references.

---

## M4: LLM Orientation Map Refresh

**Goal:** Single authoritative token-budget and doc-inventory reference is internally consistent and matches filesystem state.

**Success criteria:**
- Every table row in `orientation-map.md` maps to an existing file
- Token totals are arithmetic-correct
- Gap analysis reflects post-overhaul-project state (fills completed, gaps remaining)
- Skill/subagent/overlay counts agree with M2 and M3 outputs

**Dependencies:** M2 complete. Can run in parallel with M3.

**Estimate:** ~0.5 session.

### Phase 4.1 — Table refresh + arithmetic
Task: DOC-011.

---

## M5: Close-Out Consistency Check

**Goal:** Cross-reference integrity — no contradictions between architecture, operator, and orientation map.

**Success criteria:**
- Skill count identical across `02-building-blocks.md`, `skills-reference.md`, `orientation-map.md`
- Subagent count identical across same three docs
- Model routing claims identical across 01, 04, and any operator doc that mentions them
- Run-log has final ACT entry; progress-log updated
- Any discovered design-spec drift flagged as follow-on project (not fixed in this scope)

**Dependencies:** M2, M3, M4 complete.

**Estimate:** 0 sessions (close-out runs inline at end of last ACT session).

### Phase 5.1 — Cross-reference audit
Task: DOC-012.

---

## Dependency Graph

```
M1 (DOC-001)
  └─▶ M2.1 (DOC-002)
        └─▶ M2.2 (DOC-003)
              └─▶ M2.3 (DOC-004)
                    └─▶ M2.4 (DOC-005)
                          └─▶ M2.5 (DOC-006)
                                └─▶ M2.6 (DOC-007)
                                      ├─▶ M3 (DOC-008, DOC-009, DOC-010)
                                      └─▶ M4 (DOC-011)
                                            └─▶ M5 (DOC-012)
```

M3 and M4 run in parallel after M2 completes. M5 gates on both.

## Risk Profile

- **Medium risk:** DOC-003 (inventory propagates), DOC-004 (live-state-dependent), DOC-005 (tess-v2 state-dependent), DOC-009 (runbook operational accuracy). 4 tasks.
- **Low risk:** DOC-001, DOC-002, DOC-006, DOC-007, DOC-008, DOC-010, DOC-011, DOC-012. 8 tasks.
- **No high-risk tasks.** Content refresh within validated structure, reversible via git.

## Peer Review

**LOW** — documentation updates, additive-only content changes, no structural modifications. Skipping.

## Out of Scope (reminder from spec)

- New sections or files
- Restructuring Diátaxis quadrants
- Updating the design spec
- Updating NotebookLM notebooks
- Updating CLAUDE.md, skill definitions, or overlays
- Updating `claude-ai-context.md` (session-end protocol handles this)
