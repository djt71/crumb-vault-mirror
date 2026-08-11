---
project: vault-optimization
domain: software
type: design
skill_origin: null
created: 2026-08-10
updated: 2026-08-10
---

# VO-037 — CLAUDE.md Fire-Rate Review

Section-by-section review of CLAUDE.md (220 lines at review time, commit
`07d2d15b`) against the keep-inline test: **keep only if it changes behavior
in most sessions AND CLAUDE.md is its sole source; either "no" → one line +
pointer.** Pointer mechanism per moved section is textual load-on-demand in
every case — all pointerized content is rare-fire procedure, where `@import`
would inline at session load and save nothing (context-cost rationale per
task acceptance).

## Fire-Rate Table (all 24 sections)

| # | Section | Lines | Fires in most sessions? | Sole source? | Decision |
|---|---|---|---|---|---|
| 1 | Title + tagline | 3 | yes (identity) | yes | KEEP |
| 2 | Project Overview | 3 | yes (orientation) | no (v3 ADR, operating note) | KEEP — already minimal; the 3 lines are the orientation function itself |
| 3 | Domains | 2 | yes (routing input) | no (file-conventions domain enum) | KEEP — 1-line list, routing-critical; cheaper inline than a pointer round-trip |
| 4 | Workflow Routing (bullets + triage) | ~15 | yes | yes | KEEP |
| 5 | — Ceremony Budget Principle | 18 | no (fires at proposal-time only) | no (operating-note rubric now FINAL is the canonical decision surface; provenance doc exists) | **E1 POINTERIZE** → 3 lines + pointer to operating note §4 |
| 6 | — Phase Transition Gate | 3 | per-phase | already a pointer | KEEP |
| 7 | — Project Creation | 21 | no (~monthly) | no (spec §4.1.5 full flow; 3b/3c repo-gate steps CLAUDE.md-only → move to spec first) | **E2 POINTERIZE** → 4 lines + pointer; spec §4.1.5 absorbs 3b/3c (companion edit S1) |
| 8 | Risk-Tiered Approval | 5 | yes | yes | KEEP |
| 9 | Context Rules | 10 | yes (every skill invocation) | mostly | KEEP |
| 10 | File Access | 14 | yes (CLI-vs-native routing) | kb tag list duplicated verbatim in file-conventions §Defined-Level-2 | **E3 TRIM** — replace tag list + level rules with pointer to file-conventions; keep CLI/native routing + query patterns |
| 11 | Subagent Configuration | 3 | no | overlaps Model Routing precedence line | **E4 MERGE** into Model Routing |
| 12 | Model Routing (tier map + delegation) | ~11 | yes (every skill load) | YES — spec §3.5 explicitly defers concrete strings here | KEEP |
| 13 | — Cost Observation + rollout | 13 | no (session-end note-taking detail; rollout is reference) | rollout duplicated in spec §3.5; cost-observation prose CLAUDE.md-only → move to spec | **E5 POINTERIZE** → 2 lines; spec §3.5 absorbs cost-observation (companion edit S2) |
| 14 | Plan Mode | 4 | no (occasional) | yes | KEEP — 4 lines, below pointer overhead |
| 15 | Behavioral Boundaries (System/Always/Exception/Ask-First/Never) | 38 | yes (constitutional) | yes | KEEP — behavior-loss check protects every rule; no pointerization |
| 16 | Project Archival | 15 | no (rare, operator-initiated) | no (spec §4.6 owns the procedure; section already cites it) | **E6 POINTERIZE** → 4 lines (never-autonomous rule + KB exception + pointer) |
| 17 | Completed Project Guard | 6 | no (occasional) | yes (spec has no equivalent guard section) | KEEP — sole-sourced; 6 lines |
| 18 | Compound Engineering | 3 | per-phase | pointer already | KEEP |
| 19 | Skills & Agents | 8 | yes (loading semantics) | creation-protocol sentences duplicate spec §3.6 | **E7 TRIM** creation sentences → pointer; keep loading semantics |
| 20 | Overlay Routing | 8 | when overlays fire | overlay-index owns signals | **E8 TRIM** to 4 lines (index location + skills-check + lens semantics) |
| 21 | Subagent Validation | 3 | per subagent | pointer already | KEEP |
| 22 | Convergence | 3 | per-phase | pointer | KEEP |
| 23 | Hallucination Detection | 3 | audit-time | pointer | KEEP |
| 24 | Session Startup / Session Management / Session-End | 17 | yes | pointers already | KEEP |
| 25 | External Tools (MarkItDown) | 3 | no (inbox sessions only) | no (spec §7.9; inbox-processor skill is the consumer) | **E9 DELETE** — spec §7.9 + consuming skill carry it |

## Duplicated-Fact List (single-source resolutions)

| Fact | Copies | Resolution |
|---|---|---|
| Canonical #kb/ Level 2 tag list (18 tags) | CLAUDE.md §File-Access + file-conventions §Defined-Level-2 | file-conventions = source (E3) |
| Project creation flow | CLAUDE.md §Project-Creation + spec §4.1.5 | spec = source; 3b/3c moved there (E2 + S1) |
| Archival procedure | CLAUDE.md §Project-Archival + spec §4.6 | spec = source (E6) |
| Model-routing phased rollout | CLAUDE.md §Cost-Observation + spec §3.5 | spec = source (E5 + S2) |
| Sonnet pin `claude-sonnet-4-6` (stale) in spec §3.5 vs CLAUDE.md "pin tier, not version" | spec §3.5 tier table | spec corrected to tier-not-version (S2) |
| Primitive-creation approval flow | CLAUDE.md §Skills-&-Agents + spec §3.6 | spec = source (E7) |
| Domains list | CLAUDE.md §Domains + file-conventions enum | Accepted duplication — 1 line, routing-critical, both stable (recorded, not resolved) |

## Companion Spec Edits (not CLAUDE.md; medium-risk proceed+flag)

- **S1:** spec §4.1.5 absorbs CLAUDE.md steps 3b (external repo gate) + 3c
  (service registration) verbatim-adapted.
- **S2:** spec §3.5 absorbs Cost Observation prose; stale
  `claude-sonnet-4-6` pin → "Sonnet (current release — pin tier, not
  version)".
- **S3 (bundled deferred item):** §3.1/§3.3 structural reorg
  (build-plan framing → as-built registry), spec version bump v2.4 → v2.5.
  Executed as its own tranche after the CLAUDE.md pass.

## Approval & Metrics

Each CLAUDE.md edit (E1–E9) individually operator-approved before apply
(Ask-First class). Before/after line count, token estimate, and the
behavior-loss check (every Always/Ask-First/Never rule still reachable)
recorded in the run-log at apply time.
