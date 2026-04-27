---
project: obsidian-applenotes-import
domain: software
type: action-plan
skill_origin: action-architect
created: 2026-04-27
updated: 2026-04-27
tags:
  - obsidian-plugin
  - applescript
  - macos
---

# Apple Notes Import — Action Plan

## Overview

29 atomic tasks across 9 phases (M0 spikes + M1–M8 implementation). Total scope **MAJOR**: new external repo, destructive third-party operations, community-distribution gate. Spec rev 4 frozen; all pre-PLAN gates resolved (G1✅ G2✅ G4✅; G3 removed via v1.1 attachment deferral).

The critical path runs:

```
M0 spikes → OAI-001 → OAI-002 → OAI-004
                                  ├─→ OAI-007                                ─┐
                                  ├─→ OAI-005, OAI-006 ──→ OAI-009 ──→ OAI-011 ┤
OAI-002 ──→ OAI-012 ─────────────────────────────────────────────────────────┤
                              OAI-005,006,012 ──→ OAI-013 ──→ OAI-014        │
                                       OAI-004 ──→ OAI-019 ──┐               │
                                                              OAI-015        │
                                       OAI-002 ──→ OAI-020                   │
                                                                    OAI-007,011,012 ──┤
                                                              OAI-016a..e (M6) ←──────┘
                                                                            ↓
                                                                         M8 (021→022→023)
```

The single longest dependency chain is **M0 → M1 → M2 → M3 → M6 → M8** (12 tasks). M4 (OAI-012) and M7 (OAI-019, OAI-020) run parallel to M2/M3/M5.

**Iteration budget:** 2–4 rework rounds expected on the safety-critical M6 cluster (OAI-016a–c) — composite verify-before-delete is the highest-stakes piece of code and adversarial tests will surface edge cases. All other tasks are single-pass with the usual 1 review round.

## M0: PLAN Spikes (validate assumptions before locking)

**Goal:** Resolve the 4 PLAN-stage assumptions (A1, A3, A5, A6) from spec §"Assumptions (PLAN spike)" before implementation begins. Each spike is a staged-spike-with-bail per `_system/docs/solutions/staged-spike-with-bail.md` — Stage 0 verifies the load-bearing assumption with a primary-source probe; bail without proceeding if the assumption fails.

**Success criteria:**
- A1 perf assumption resolved: either validated (≤5s for ~1k notes — modal stays simple) OR triggers paginated/streamed contingency in OAI-013 (5–10s) OR returns to PLAN risk review (>10s).
- A3 attachment-HTML assumption resolved: confirmed `body of note` returns parseable HTML for an attachment-bearing note; converter's drop-attachments path validated against a real fixture (or assumption documented as deferred-to-implement-with-fallback if no fixture available).
- A5 TCC denial detection assumption resolved: exact stderr text + error code captured for an `osascript` denial under `tccutil reset AppleEvents`. OAI-019's denial-detection regex set from real evidence, not guesses.
- A6 locked-note assumption resolved: error shape captured when `body of note` is queried against a locked note. OAI-006's skip-and-log path keyed to real error text.
- Each spike produces a `design/probes/` artifact (script + result) and (if it changes a decision) a `design/decisions/<NNN>-<topic>.md` record.

**Exit gate:** All 4 spikes resolved. PLAN locks the resulting decisions in spec rev 5 (or in design/decisions/ if scope is small). M1 may not start until M0 is closed.

**Tasks:** OAI-024 (A1 perf), OAI-025 (A3 attachment HTML), OAI-026 (A5 TCC denial detection), OAI-027 (A6 locked-note error shape).

**Stage 0 budget rule:** Each spike's Stage 0 ≤30 min. If Stage 0 is going to take longer (e.g., A1 needs a synthetic 1k-note corpus to exist), bail to "deferred to first-run measurement with fallback path" rather than burning the budget.

## M1: Foundation

**Goal:** Repo builds; plugin loads in a test vault; settings persist across reload; platform-gate code path skeleton exists.

**Success criteria:**
- `npm install && npm run build` produces `main.js`; `npm run lint` exits 0 with `eslint-plugin-obsidianmd` enabled.
- Plugin loads in test vault on macOS; settings tab present; `onunload` leaves no listeners.
- `Platform.isMacOS === false` OR `Platform.isMobile === true` → `onload()` early-returns with a single one-shot Notice. No commands, ribbon, or settings tab registered off-platform.
- minAppVersion locked to a concrete `X.Y.Z` (research output of OAI-002).
- eslint-plugin-obsidianmd version locked (`0.1.9` template default vs `0.2.4` latest — PLAN decision recorded in design/decisions/).

**Exit gate:** Plugin loads cleanly in test vault; off-platform smoke test passes (mobile OS reports the one-shot Notice and no other side effects); lint passes.

**Tasks:** OAI-001, OAI-002, OAI-003.

## M2: AppleScript Bridge

**Goal:** All AppleScript surface-area implemented and unit-testable. G1 soft-delete re-validated via the production wrapper (not just the rev-1 probe).

**Success criteria:**
- `osascript` runner wraps `child_process.execFile` with stderr/timeout/exit-code surfacing.
- List, fetch-body, and soft-delete scripts return the documented JSON shapes.
- All scripts address notes by id (`whose id is X`) per probe-derived note 1; no by-name selectors anywhere.
- Locked notes flagged with `isLocked: true` (list) and return `{skipped: 'locked'}` (body fetch) per OAI-026 evidence.
- Production-quality soft-delete wrapper (OAI-007) replicates G1 behavior: deleted note appears in Recently Deleted within 2s.

**Exit gate:** G1 re-test passes via the production wrapper. Adversarial unit test (script returns malformed JSON) does not crash the runner.

**Tasks:** OAI-004 → OAI-005, OAI-006, OAI-007 (parallel after 004).

## M3: Conversion & Vault Writes

**Goal:** HTML → markdown conversion produces faithful output for the canonical surface; attachments dropped with placeholder + warning; vault writer emits correct frontmatter and captures pre-write content hash for the verify gate.

**Success criteria:**
- Pre-processor normalizes Apple-Notes-specific HTML (checklist objects, Apple-specific spans/divs) before turndown.
- Custom node-filters **catch** unknown tags (do not silently drop) — turndown default is to drop, so the filter must be explicit per spec §System Map.
- Attachment objects (image, file ref, drawing canvas, audio, video, web bookmark) replaced with `<!-- [v1: attachment dropped: <type-or-name>] -->` placeholder; counted into `source_had_attachments` and `import_warnings.attachments_dropped`.
- Severe-tier escalation triggers when substantive body content cannot be represented (golden test for empty-table case).
- Golden output tests cover ≥10 representative inputs (synthesized + any captured Apple Notes HTML available; A3 spike may seed one).
- Vault writer creates target folder idempotently, writes via `app.vault.create`, frontmatter matches LD-09 exactly, captures expected pre-write content hash.
- sanitize-html decision locked (PLAN: turndown alone vs turndown + sanitize-html — design/decisions/ record).

**Exit gate:** Golden tests pass; vault write smoke test produces correct frontmatter + a verifiable pre-write hash.

**Tasks:** OAI-009 (depends on OAI-006), OAI-010 (independent), OAI-011 (depends on 009 + 010).

## M4: Import Index (parallel to M2/M3)

**Goal:** Persistent, corruption-resilient import index with vault-listener sync and frontmatter-rebuild repair path.

**Success criteria:**
- Index keyed by `apple_notes_id` AND content hash (secondary key); collisions flagged not silently re-imported.
- `app.vault.on('rename')` and `app.vault.on('delete')` registered via `registerEvent`; index path-updates and entry-removals on native vault changes.
- Readback contract: `JSON.parse(written)` round-trips losslessly AND structural shape matches expected schema. Corrupt parse → safe-degraded mode (delete-capable imports disabled until repaired).
- Repair scans frontmatter for `apple_notes_id` (default scoped to configured import folder; configurable to whole-vault). Progress indicator if scan exceeds 2s.
- Repair conflict policy enforced per spec §System Map: duplicate id → ambiguous (delete disabled until resolved); missing path → drop entry + log; frontmatter/hash mismatch → rebuild with `untrusted: true`. Repair report appended to receipt.
- Index follows the atomic-rebuild pattern (`_system/docs/solutions/atomic-rebuild-pattern.md`) for repair: build new index in staging, validate (parse + shape), atomic swap. Live index never overwritten directly during rebuild.

**Exit gate:** Adversarial tests pass — corrupt JSON triggers safe-degraded; rename listener updates path; delete listener removes entry; repair correctly handles all 4 conflict cases.

**Tasks:** OAI-012 (depends on OAI-002 only — runs parallel to M2/M3).

## M5: Modal UI

**Goal:** Notes modal lists, filters, and multi-selects notes; confirm-delete modal warns about Recently Deleted + attachment loss; commands wire into Obsidian only on macOS.

**Success criteria:**
- Modal table renders via `createEl` (no `innerHTML` with user data); columns: account, folder, title, modified, badges (already-imported, attachment-count).
- Search + filter + checkbox multi-select work; "show already-imported" toggle controls visibility AND checkbox-enable.
- Notes with attachments shown with informational `(N attachments — body only)` badge; selectable as normal.
- `styles.css` committed with ≥3-4 minimal selectors (table, row-disabled state, badge); included in release zip.
- If A1 spike triggered the >5s contingency, modal MUST use paginated/streamed loading.
- Confirm-delete modal lists N notes about to import + soft-delete with explicit "Recently Deleted in Apple Notes" copy. If any selected note has `attachmentCount > 0`, also displays the post-retention attachment-loss warning.
- "Browse Apple Notes" command + ribbon icon registered ONLY when `Platform.isMacOS === true`. TCC probe runs on first command invocation per OAI-019.

**Exit gate:** Mock-data run-through succeeds end-to-end; off-platform smoke test confirms no command/ribbon registration.

**Tasks:** OAI-013, OAI-014, OAI-015 (depends on OAI-013, OAI-014, OAI-019).

## M6: Import Orchestrator (safety-critical)

**Goal:** The end-to-end import pipeline. Sequential per-note execution, composite verify-before-delete enforced, per-note independence, receipt log written. **This is the highest-stakes milestone — 2–4 rework rounds expected on adversarial tests.**

**Success criteria:**
- **Sequencing as primary safety control:** canonical pipeline `fetch → convert → write md → persist index → composite verify → soft-delete → append receipt` is implemented identically in code and matches spec §System Map / AC5 / OAI-016a / OAI-016b.
- **Composite verify (OAI-016b)** function contract: `verifyImport(expectations) → {ok, failures[]}`. Verify covers (1) md exists, (2) md content matches expected pre-write hash, (3) index entry round-trips losslessly with structural shape match. No side effects beyond reads.
- **Delete gate (OAI-016c)** function contract: `executeDeleteIfVerified(noteId, verifyResult) → {deleted, abortReason?}`. Gates the actual `osascript` delete behind `verifyResult.ok === true`. On `false`, returns abort-with-reason without invoking delete. Integration test with contrived verify-failure → confirms delete-not-called via spy.
- **Adversarial tests (OAI-016b)** inject mocked partial-write and index-failure → verify returns `ok: false` correctly. ≥4 adversarial scenarios per gate-evaluation-pattern.
- Sequential batch execution: await each note's pipeline before starting the next. Per-note independence: a single note's failure aborts only THAT note's delete, never the batch. Cancel-after-current observed only between note transactions.
- Final summary dialog reports imported / imported-not-deleted / skipped / errored counts + aggregate `attachments_dropped`.
- Per-batch receipt markdown written; imported paths emitted as `[[wikilinks]]`; collisions resolved with timestamp suffix; receipt-write failure logs to console + Notice without rolling back the soft-delete.

**Exit gate:** All adversarial tests pass; integration test with a 3-note batch (1 success, 1 verify-fail, 1 conversion-error) produces correct summary + receipt + only the success note is soft-deleted in Apple Notes.

**Tasks:** OAI-016a, OAI-016b, OAI-016c (depends on OAI-007 + 016b), OAI-016d (depends on 016a–c + OAI-013), OAI-016e (depends on 016d).

## M7: Permission & Platform UX (parallel to M5/M6)

**Goal:** TCC denial handled cleanly; off-platform path keeps the plugin invisible.

**Success criteria:**
- TCC probe runs on first user-initiated command invocation (NOT plugin load). Settings-tab "Re-check permission" button is also a user-initiated probe.
- Denial detection works for known stderr patterns (`Not authorized to send Apple events`, error codes -1743 / -10000 — exact patterns from OAI-026 evidence). Timeout fallback treats hangs as probable denial. Generic-error fallback does NOT auto-disable on unmatched (errs on the side of letting the user retry).
- On confirmed denial: in-app Notice + settings-tab guidance directs user to System Settings → Privacy → Automation → Obsidian → Notes; commands disabled until granted.
- `Platform.isMacOS === false` OR `Platform.isMobile === true` → `onload()` early-returns BEFORE any side effects. Single Notice "Apple Notes Import: macOS only" emits once per install/version (de-dup via stored marker).

**Exit gate:** TCC reset → first command invocation surfaces correct guidance; off-platform smoke test confirms no commands/ribbon/settings-tab AND only one Notice across multiple reloads.

**Tasks:** OAI-019 (depends on OAI-004 + OAI-026), OAI-020 (depends on OAI-002).

## M8: Distribution

**Goal:** Plugin shipped to community plugin directory. Submission self-critique passes; release zip contains exactly the right 3 files.

**Success criteria:**
- README documents: permission flow, soft-delete semantics + Recently Deleted retention, frontmatter fields (incl. `apple_notes_id` privacy notice), **prominent v1-attachment-loss warning per AC12**, known limitations, manual install steps, TCC troubleshooting, macOS-only banner.
- LICENSE chosen (MIT or 0-BSD).
- ≥2 screenshots reflecting current UI (modal + confirm dialog).
- Tag push triggers GitHub Actions: builds → attaches `main.js`, `manifest.json`, `styles.css` to release.
- Manifest fields match release tag/version (`version` consistent with git tag).
- `.gitignore` excludes `main.js` + dev artifacts.
- **Release asset inspection step in workflow:** zip contains exactly `manifest.json`, `main.js`, `styles.css`; fails if extra files (source maps, tests, dev files) detected.
- Submission self-critique checklist runs clean: `isDesktopOnly: true`, no committed `main.js`, no `innerHTML` with user input, `instanceof FileSystemAdapter`, `normalizePath` on user paths, `registerEvent` / `registerDomEvent` / `registerInterval` for all listeners, `styles.css` committed and shipped, no plugin-name prefix in command names, `eslint-plugin-obsidianmd` clean.
- Submission PR drafted against `obsidianmd/obsidian-releases`.

**Exit gate:** Submission PR opened; release asset inspection passes on a real tag push; self-critique checklist clean.

**Tasks:** OAI-021 (depends on M6 + M7 complete), OAI-022 (depends on OAI-021), OAI-023 (depends on OAI-022).

## Plan Decisions to Lock During PLAN

These are PLAN-stage product/build decisions that the spec called out for resolution. They land in respective implementation tasks but should be decided BEFORE that task starts so there's no rework:

| Decision | Lock during | Spec reference |
|---|---|---|
| `minAppVersion` concrete `X.Y.Z` | OAI-002 (research against API surface used) | Spec §"Plugin Manifest" + Unknowns |
| `eslint-plugin-obsidianmd` version (0.1.9 vs 0.2.4) | OAI-001 (record in design/decisions/) | Spec §Unknowns |
| turndown alone vs turndown + sanitize-html | OAI-009 (decide after first golden test of malformed input) | Spec §System Map + Dependencies |
| A1 contingency: simple modal vs paginated/streamed | M0 spike OAI-024 outcome | Spec §AC1 + System Map |

## Risk-Adjusted Sequencing Notes

- **M6 lands behind M2/M3/M4** intentionally. The composite verify gate cannot be implemented until the index store (OAI-012), vault writer (OAI-011), and AppleScript wrappers (OAI-007) all exist as real surfaces — mocking them at this stage hides bugs that only appear at the integration boundary.
- **M4 (OAI-012) starts as soon as OAI-002 lands.** It only depends on the plugin skeleton existing. Maximizing parallelism here de-risks the M6 critical path.
- **M7 OAI-019 starts as soon as OAI-004 lands.** TCC handling is small but easy to underestimate; getting it on-screen early surfaces stderr-pattern surprises before they bite the M5/M6 cluster.
- **OAI-013 modal can start with mock data** before OAI-005/006 are fully done — only the JSON shape needs to be locked. Documented in spec §M5 acceptance.
- **Iteration budget 2–4 rounds on M6 only.** All other tasks single-pass.

## Out-of-Scope Explicitly Carried Forward

- Attachments (deferred to v1.1 per LD-07 rev 4). `source_had_attachments` frontmatter field reserved for v1.1 retroactive migration. README + confirm dialog must surface the post-retention loss risk per AC12.
- Hashed-id alternative for `apple_notes_id` (deferred to v1.1; v1 stores raw id with prominent README privacy notice).
- Two-way sync, edit-back-to-Notes, conflict resolution.
- Hard delete, cross-platform support, locked-note unlock, bulk export.

## Cross-Project Dependencies

None. This project doesn't consume from or contribute to any other Crumb project's backlog.

## Compound Notes (PLAN-stage)

- **Pattern reuse:** M0 spikes structured per `staged-spike-with-bail.md` (Stage 0 ≤10% of total budget; bail without proceeding if Stage 0 fails). Spec's pre-PLAN gates (G1, G2, G3) already validated this pattern at the SPECIFY layer; we extend it to PLAN-stage probes.
- **Atomic rebuild pattern applied to OAI-012:** index repair builds into staging, validates (parse + shape), atomic-swaps. Live index never overwritten directly. Adopted from `_system/docs/solutions/atomic-rebuild-pattern.md` — eliminates the "half-rebuilt index" failure mode the spec didn't explicitly call out.
- **Gate evaluation pattern applied throughout:** every milestone has a fixed exit gate set at PLAN time, not retroactively. Composite verify (OAI-016b) is itself an instance of the pattern — fixed criteria evaluated per note.
- **Estimation calibration baseline:** prior project (pydantic-ai-adoption) had a 0.04x estimate ratio because of an early bail. This project has 4 explicit bail checkpoints in M0 — the same dynamic could compress the implementation timeline if any spike forces a rescope. Track at completion.
