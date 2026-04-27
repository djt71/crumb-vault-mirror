---
project: obsidian-applenotes-import
domain: software
type: action-plan-summary
skill_origin: action-architect
created: 2026-04-27
updated: 2026-04-27
source_updated: 2026-04-27
---

# Action Plan Summary — Apple Notes Import

## Scope

29 atomic tasks across 9 phases (M0 PLAN spikes + M1–M8 implementation). MAJOR scope. All tasks ≤5 file changes.

## Critical Path

```
M0 spikes (OAI-024..027) → M1 (001→002→003) → M2 (004→{005,006,007}) →
M3 (009→011) → M6 (016a..e) → M8 (021→022→023)
```

12-task longest chain. M4 (012) and M7 (019, 020) parallel to M2/M3/M5.

## Phase Gates (all defined now, evaluated at phase exit)

| Phase | Exit Gate |
|---|---|
| M0 | All 4 spike artifacts present; decisions recorded if any spike changed downstream approach |
| M1 | Plugin loads in test vault on macOS; off-platform smoke passes; lint clean |
| M2 | G1 re-test passes via production wrapper; all 4 scripts return typed parsed results |
| M3 | Golden tests pass; vault write produces correct frontmatter + verifiable pre-write hash |
| M4 | All adversarial tests pass (corruption, repair conflict policy, atomic-rebuild fault injection) |
| M5 | Mock-data end-to-end run succeeds; off-platform smoke confirms no UI registration |
| M6 | All adversarial tests pass + 3-note batch test (1 success, 1 verify-fail, 1 conv-error) produces correct outcomes |
| M7 | TCC reset → first command surfaces correct guidance; off-platform Notice de-duplicates across reloads |
| M8 | Submission PR opened; release asset inspection passes on real tag push; self-critique clean |

## Highest-Stakes Cluster

**M6 (OAI-016a–e)** — composite verify-before-delete is the single point determining data-loss risk for body content. 2–4 rework rounds expected; all other tasks single-pass.

## PLAN Decisions to Lock During Implementation

| Decision | Lock during | Recording artifact |
|---|---|---|
| `minAppVersion` concrete `X.Y.Z` | OAI-002 | `manifest.json` + design/decisions/004 if non-obvious |
| `eslint-plugin-obsidianmd` 0.1.9 vs 0.2.4 | OAI-001 | `design/decisions/002-eslint-plugin-version.md` |
| turndown alone vs turndown + sanitize-html | OAI-009 | `design/decisions/003-conversion-stack.md` |
| Modal loading strategy (simple vs paginated/streamed) | M0 spike OAI-024 | `design/decisions/001-modal-loading-strategy.md` (if contingency triggered) |

## Pattern Reuse

- **Staged spikes with bail** (M0): each spike's Stage 0 ≤30 min; bail-without-proceeding if Stage 0 fails.
- **Atomic rebuild** (OAI-012): index repair builds into staging, validates, atomic-swaps. Live index never overwritten directly.
- **Gate evaluation**: every milestone has a fixed exit gate set at PLAN time, not retroactively.

## Cross-Project Dependencies

None.

## Out of Scope (carried forward from spec)

Attachments (v1.1), hashed `apple_notes_id` (v1.1), two-way sync, hard delete, cross-platform, locked-note unlock, bulk export.

## Iteration Budget

2–4 rework rounds expected on M6 cluster only (composite verify-before-delete). All other tasks single-pass with normal review.
