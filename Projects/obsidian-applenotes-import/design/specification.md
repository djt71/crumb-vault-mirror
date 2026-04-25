---
project: obsidian-applenotes-import
domain: software
type: specification
skill_origin: systems-analyst
created: 2026-04-25
updated: 2026-04-25
revision: 3
revision_history:
  - rev: 1
    date: 2026-04-25
    note: Initial SPECIFY output
  - rev: 2
    date: 2026-04-25
    note: Round-1 peer-review revision pass — applied 10 must-fix and 18 should-fix actions; A4 probe validated
  - rev: 3
    date: 2026-04-25
    note: Round-2 peer-review revision pass — applied 15 must-fix and 14 should-fix actions; B4 citations pinned; SPECIFY artifact frozen pending pre-PLAN gates
tags:
  - obsidian-plugin
  - applescript
  - macos
---

# Specification — Obsidian Apple Notes Import

## Problem Statement

Apple Notes accumulates capture-stage thinking that should live in the user's Obsidian vault, but there is no built-in path to selectively migrate notes into Obsidian and remove the originals. Users either manually copy-paste (slow, lossy on attachments and formatting) or rely on bulk one-time exporters that don't fit ongoing capture-then-promote workflows. This plugin closes the gap with a per-note review-and-import flow that soft-deletes the source after a verified vault write.

## Goals & Non-Goals

**Goals (v1):**
1. List Apple Notes inside Obsidian (account/folder/title metadata).
2. Selectively import chosen notes as markdown files into a configured vault folder, preserving body, attachments, and provenance metadata.
3. After verified vault write, soft-delete the original Apple Note (Apple Notes' Recently Deleted folder).
4. Be eligible for the Obsidian community plugin directory (manifest, code style, distribution all conformant).

**Non-goals (v1):**
- Two-way sync; edit-back-to-Notes; conflict resolution.
- Hard delete (would bypass Apple's Recently Deleted retention safety net).
- Cross-platform support (Linux/Windows/iOS/iPadOS).
- Re-importing already-imported notes silently (re-import is gated, not denied).
- Locked-note unlock/decrypt; iCloud-shared note edge handling beyond skip-and-log.
- Bulk export of an entire account (the workflow is selective on purpose).
- Hash-redacted `apple_notes_id` in frontmatter (deferred to v1.1; v1 stores raw id with prominent README privacy notice).

## Pre-PLAN Validation Gate

The following must be confirmed **before SPECIFY closes and PLAN begins**. They are not implementation details — they are product-viability assumptions whose failure forces spec revision rather than design adjustment.

| Gate | Status | Evidence | Pass criteria |
|---|---|---|---|
| **G1 / A4** — AppleScript `delete` on Notes is soft-delete (Recently Deleted), not hard-delete | ✅ **VALIDATED 2026-04-25** | osascript probe ran on macOS 26.3.1 (`sw_vers` captured inline at [`probes/a4-probe-result.md`](probes/a4-probe-result.md)). Created throwaway note, deleted via `tell application "Notes" to delete newNote`, confirmed: (a) `EXISTS_BY_ID_AFTER_DELETE=true` (id remains queryable — soft-delete signature), (b) probe note found in "Recently Deleted" folder. Probe script archived at [`probes/a4-soft-delete.applescript`](probes/a4-soft-delete.applescript). | n/a — passed |
| **G2 / A2** — Note `id` is stable across Notes app restart, edit, and folder move | ⏳ Pending | Probe to be authored and run before PLAN. | **Pass:** `id of note` remains byte-identical across (i) 3 Notes app restarts, (ii) post-restart edit to title and body, (iii) folder move within same account. **Cross-account move changes id allowed** — downgrade dedupe to account-scoped (document, do not block). **Same-account scenario id change** → return to SPECIFY. |
| **G3 / A7** — Attachment extraction approach decision (AppleScript export vs. Group Container filesystem cache) | ⏳ Pending | OAI-008a runs the dual probe. | **Pass:** Required types (image, PDF, audio, scanned doc) ≥95% extraction success each, sample size ≥10 notes per type. Best-effort types (drawing/sketch, web bookmark) probe-determines warning semantics; need not hit 95%. **Fail conditions:** any required type below 95%, OR Full Disk Access requirement with unacceptable UX, OR per-attachment latency >2s. Failure → return to SPECIFY (may require dropping attachments from v1 or adding FDA flow). |
| **G4** — Citations pinned in [`research-brief-plugin-platform.md`](research-brief-plugin-platform.md) | ✅ **RESOLVED 2026-04-25** | Source URLs and commit SHAs added to research-brief §8: `obsidian-developer-docs` HEAD `2ed97bd04e82773d81eac967382819431da3b098`, `obsidian-sample-plugin` HEAD `dc2fa22c4d279199fb07a205a0c11eb155641f3d`, `Manifest.md` blob `eeac634a...`, `Submission requirements...md` blob `ce93a442...`. `eslint-plugin-obsidianmd` confirmed at `0.1.9` in template, `0.2.4` latest on npm. | n/a — resolved |

PLAN does not begin until **G2 and G3 resolve**. If either fails, return to SPECIFY for revision.

## Facts

Sourced from [`research-brief-plugin-platform.md`](research-brief-plugin-platform.md) (citations pinned per G4):

- Plugin id in `manifest.json` cannot contain the substring "obsidian" → proposed id `applenotes-import` (per `obsidian-developer-docs` `en/Reference/Manifest.md` blob `eeac634a`).
- `isDesktopOnly: true` is required; we use NodeJS `child_process` to invoke `osascript`.
- `main.js` is a build artifact; must not be committed (release-only).
- `app.vault.create`, `app.vault.createBinary`, `app.vault.createFolder` (errors if folder exists), `normalizePath` are the relevant vault APIs.
- `app.vault.on('rename')` and `app.vault.on('delete')` are the relevant lifecycle events for keeping the import index in sync with native vault changes.
- DOM construction must use `containerEl.createEl` etc.; `innerHTML`/`outerHTML` with user input is a submission reject.
- Adapter type checks must use `instanceof FileSystemAdapter` (no casting).
- `registerEvent` / `registerDomEvent` / `registerInterval` are required for cleanup.
- `eslint-plugin-obsidianmd` is the official lint plugin, pinned at `0.1.9` in current sample template (latest published on npm: `0.2.4`).
- `styles.css` is a first-class plugin asset: committed in repo, included in release zip alongside `main.js` and `manifest.json`.
- AppleScript `delete` against an Apple Notes note moves it to Apple Notes' Recently Deleted folder — **empirically validated G1 on 2026-04-25 / macOS 26.3.1** (note id remains queryable after delete; note found in "Recently Deleted" folder; probe artifacts in [`probes/`](probes/)). The user has confirmed this soft-delete behavior is the desired semantics for v1.

## Assumptions (Pre-PLAN gating + PLAN spike)

Each assumption is paired with the cheapest validation we can perform. **Pre-PLAN gating** assumptions block PLAN entry; **PLAN spike** assumptions can be validated during PLAN's spike phase.

### Pre-PLAN gating (block PLAN entry)

- **A2** (Pre-PLAN, see G2) — `id of note` is stable across Notes app restart, post-restart edit, and folder move (within same account).
- **A4** ✅ **VALIDATED 2026-04-25** — AppleScript `delete` lands in Recently Deleted, not hard-delete.
- **A7** (Pre-PLAN, see G3) — Attachment extraction is feasible with acceptable reliability via AppleScript export OR filesystem cache (decision in OAI-008a).

### PLAN spike (validate during PLAN, before TASK lock)

- **A1** — `tell application "Notes" to get every note` returns within ≤10s (viability) for ~1k notes; >5s triggers paginated/streamed UI mode (single rule with two thresholds).
- **A3** — `body of note` returns HTML reliably; attachments are referenced as inline objects extractable separately. Validate: probe one note with image and one with sketch; inspect HTML structure.
- **A5** — TCC Automation permission denial returns recognizable error codes (e.g., `-1743`, `-10000`) or characteristic stderr text (`Not authorized to send Apple events`). Validate: trigger denial path on a test machine via `tccutil reset AppleEvents`; capture exact stderr/exit code.
- **A6** — Locked notes appear in `every note` but `body` raises an AppleScript error. Validate: probe a locked note; confirm error pattern.

## Unknowns (carried into PLAN)

- Behavior of the Notes id under iCloud account-switching → mitigated by content-hash secondary key in OAI-012; cross-account id-change is allowed and downgrades dedupe to account-scoped.
- Whether `eslint-plugin-obsidianmd` rules conflict with our preferred TypeScript style; resolve in PLAN. Whether to track template's `0.1.9` or latest `0.2.4` is a PLAN decision.
- Exact `minAppVersion` value (researched in OAI-002 against API surface).

## System Map

### Components

- **Apple Notes** (external macOS app) — the source-of-truth for unmigrated notes; accessed only via AppleScript.
- **AppleScript bridge** — small `.applescript` files plus a TS runner (`child_process.execFile osascript`) that returns JSON-shaped strings parsed in TS.
- **Conversion layer** — Apple-Notes-specific HTML pre-processor → `turndown` (with custom node-filters that *catch* unknown tags rather than silently drop) → markdown. Pre-processor handles checklist objects, attachment object placeholders, and Apple-specific spans/divs. Parser tolerates fragment HTML and malformed input (wraps as needed before preprocessing). Tested with fixtures from real captured Apple Notes HTML.
- **Attachment extractor** — pulls binary attachments to `_attachments/apple-notes/` (or configured folder) and rewrites `<img>` / link references in the converted markdown. Handles per-attachment-type per the support matrix.
- **Import index** — per-vault JSON in plugin `data.json` keyed by `apple_notes_id` AND content-hash (secondary key for collision/account-switch tolerance). Listens for `vault.on('rename')` and `vault.on('delete')` events to keep the index synced with native vault changes (rename → update path; delete → remove entry). **Corruption recovery: safe-degraded mode + frontmatter rebuild** — on parse error, plugin disables delete-capable imports until repaired or user explicitly chooses re-index, which scans vault frontmatter for `apple_notes_id` (default scoped to configured import folder; configurable to whole-vault) and reconstructs the index. Progress indicator shown if scan exceeds 2s. Repair conflict policy: duplicate `apple_notes_id` → mark ambiguous, keep delete disabled for those entries until user resolves; missing file path → drop entry + log; frontmatter/hash mismatch → rebuild with current path but mark `untrusted: true`; repair report appended to receipt log. Never silently treats corruption as empty.
- **Vault writer** — calls `app.vault.create` / `createBinary` / `createFolder`; assembles YAML frontmatter. Captures **expected pre-write content hash** (used by composite verify gate). Settings paths normalized + validated on save (reject empty/invalid; auto-create on first import). Temp file pattern: `.tmp-applenotes-import-<note-id>` adjacent to the attachments folder; cleaned post-note regardless of outcome.
- **Composite verify-before-delete gate** — single integration point that runs AFTER index persistence. Ordered pipeline (canonical, applied identically in System Map, AC5, OAI-016a, OAI-016b):
  1. Fetch body + attachments from Apple Notes
  2. Convert HTML → markdown
  3. Write attachment binaries
  4. Write markdown
  5. **Persist index entry** (mark "pending-verify")
  6. **Composite verify**: (a) markdown file exists, (b) markdown content matches the **expected pre-write hash** (NOT a self-hash), (c) all expected attachment files exist with non-zero size, (d) all rewritten markdown attachment references resolve, (e) index entry persisted and JSON-roundtrip readback succeeds with structural shape match
  7. If verify succeeds: mark index entry "imported" (clear "pending-verify"); soft-delete source note
  8. Append receipt
  
  Failure of any verify step aborts delete and marks the entry "errored" in the receipt; the source remains in Apple Notes. Sequencing (steps 1–6 ordered, delete only after verify) is the **primary safety control**; the verify gate is the secondary check.
- **Batch transaction model** — multi-select imports execute notes **sequentially** (await each note's pipeline completion before starting the next) to respect Apple Events concurrency limits. Per-note independence: a single note's failure aborts only *that* note's delete, never propagates. **Cancel-after-current** is observed only between note transactions; once a note enters the verify→delete phase, its pipeline runs to completion for consistency. After all notes complete, a final summary dialog reports imported / imported-not-deleted / skipped / errored counts.
- **Modal UI** — table of notes with checkboxes, search, account/folder filter, target-folder picker, dry-run toggle, "show already-imported" toggle. Toggling "show already-imported" makes those notes visible AND enables their checkboxes for re-selection (re-import forces a new unique filename per OAI-010 — never overwrites). If A1 spike shows >5s for 1k notes, modal MUST use paginated/streamed loading.
- **Confirm dialog** — final approval listing N notes about to import + soft-delete, with explicit "Notes will be moved to Recently Deleted in Apple Notes" copy.
- **Receipt log** — per-batch markdown file in a configurable receipts folder summarizing imported / imported-not-deleted / skipped / errored counts. Imported note paths emitted as wikilinks. Receipt filename collisions handled with timestamp suffix. Receipt-write failure logs to console + Notice; does NOT roll back the soft-delete (delete already occurred; receipt is post-hoc).
- **Settings tab** — defaults for target folder, attachments folder, receipts folder, "show already-imported" default, dry-run default, debug-mode toggle (controls receipt verbosity; see warning tiers). Manual "Re-check permission" button (counts as user-initiated TCC probe). Settings tab itself does not register on non-macOS (see Platform gate).
- **TCC handler** — probes on **first user-initiated command invocation** (NOT plugin load). The settings-tab "Re-check permission" button is also a user-initiated probe. On denial captured by stderr-pattern match (`Not authorized to send Apple events`, error codes -1743/-10000), timeout fallback (treat hangs as probable denial), or generic-error fallback (don't auto-disable on unmatched), surfaces in-app guidance + settings-tab guidance.
- **Platform gate** — runtime `Platform.isMacOS` check at plugin load. On non-macOS desktop OR mobile (`Platform.isMobile === true` OR `!Platform.isMacOS`), `onload()` performs early-return BEFORE any side effects: no command registration, no ribbon icon registration, no settings-tab registration. A single Notice "Apple Notes Import: macOS only" emits **once per install/version** (de-dup via stored marker), not on every reload.

### Conversion warning tiers (composite verify input)

| Tier | Trigger | Behavior |
|---|---|---|
| **Severe** | (a) Required-matrix attachment type (image, PDF, audio, scanned doc per OAI-008b) failed to extract; OR (b) substantive body content cannot be represented (e.g., checklist or table collapses to near-empty output where user-visible content would be lost) | **Blocks delete.** Note marked errored in receipt; source remains in Apple Notes. |
| **Moderate** | Best-effort attachment type (drawing/sketch, web bookmark) lost; OR formatting degradation only (no user-visible content lost) | Logged in receipt + frontmatter `import_warnings: [...]`. Delete proceeds. |
| **Debug-only** | Detailed conversion telemetry, including raw source HTML for unsupported elements | **Recorded in receipt log only** (NOT inline in the imported note body). If a future opt-in setting is added to embed diagnostics in note bodies, it must sanitize Apple-internal IDs and `data-*` attributes before inclusion. |

### Dependencies

- **Inbound:** macOS, Apple Notes app, TCC Automation grant, Electron-bundled Node, Obsidian ≥ minAppVersion (researched in OAI-002 against API surface: `Platform`, `vault.createBinary`, `normalizePath`, `FileSystemAdapter`, `containerEl.createEl`, `vault.on('rename')`, `vault.on('delete')`).
- **External libs:** `turndown` (HTML→MD; small, MIT). Custom node-filters required to capture unknown tags. Possibly `sanitize-html` if turndown's input handling proves insufficient (decide in PLAN).
- **Outbound (eventual):** `obsidianmd/obsidian-releases` PR for community-plugin directory submission.

### External code repo

YES — already initialized at `~/code/obsidian-applenotes-import/` (commit `4bd59d9`). `repo_path` and `build_command` recorded in `project-state.yaml`. Decision-doc location for OAI-008a is **repo-local** (`design/decisions/` inside the plugin repo), NOT `_system/docs/solutions/`.

### Constraints

- Hard: macOS-only; `isDesktopOnly: true`; AppleScript performance ceiling; sequential batch execution (no parallel osascript→Notes); no `innerHTML` with user input; no committed `main.js`; plugin id can't contain "obsidian"; no command name prefixed with plugin name (Obsidian prefixes automatically); `styles.css` committed and shipped.
- Soft: AppleScript latency degrades the UX above ~1k notes; rich-content fidelity in turndown is best-effort even with custom node-filters.
- Regulatory: none.

### Levers (high-leverage intervention points)

1. **Composite verify-before-delete contract.** Single point determining data-loss risk. Now covers md + attachments + index, and runs AFTER index persistence (single canonical sequence).
2. **Sequencing as primary safety control.** Strict order (write attachments → write md → persist index → verify → delete) constrains blast radius even if verify gate has bugs.
3. **Import index integrity + rebuild path.** Listens to vault rename/delete events; safe-degraded mode + frontmatter-scan rebuild; explicit conflict policy.
4. **Body-conversion fidelity tier (with severe→delete-block).** Severe (required-attachment fail OR substantive content loss) blocks delete; moderate logs.
5. **TCC failure UX.** First-command probe (not load probe); structured denial detection; manual re-check button.
6. **Submission compliance.** Single point determining whether v1 ships to the community directory or has to be revised post-review.

### Second-Order Effects

- If composite verify is loose, users lose source data — single highest-impact failure mode.
- Recently Deleted in Apple Notes auto-purges per Apple's standard retention; soft delete is a bounded recovery window, not permanent.
- AppleScript Notes queries can stall the UI on first-run for huge libraries; A1 spike result drives whether modal uses pagination/streaming.
- Frontmatter `apple_notes_id` exposes a CoreData URI; users sharing vaults will leak their machine's identifier. Documented prominently in README. Hashed-id alternative deferred to v1.1.
- Building a turndown pipeline creates maintenance gravity if Apple Notes' HTML evolves; pin turndown version, write golden-output tests using captured real-world fixtures.
- Index lives in plugin `data.json` (per-vault, not synced across Obsidian installs). Vault sync across machines + plugin reinstall on second machine → empty index → safe-degraded mode kicks in until rebuild from frontmatter scan.
- User natively renames/moves an imported note in Obsidian → vault listener updates index path; user deletes → listener removes index entry. Without the listeners, the index would silently desync.

## Domain Classification & Workflow Depth

- **Domain:** software
- **project_class:** system (TS plugin, external repo, build artifact)
- **Workflow:** four-phase (SPECIFY → PLAN → TASK → IMPLEMENT)
- **Rationale:** Code project with destructive operations against a third-party app, ≥3 vault/repo files, community-distribution gate. PLAN earns its keep particularly because A1/A3/A5/A6 spikes burn down assumption risk before TASK locks scope; A2/A4/A7 are gated pre-PLAN because their failure forces spec revision.

## Locked Decisions

| ID | Decision | Source |
|---|---|---|
| LD-01 | AppleScript via `osascript` (no SQLite/protobuf) | User, 2026-04-25 |
| LD-02 | Soft delete only — Recently Deleted (validated G1, 2026-04-25) | User, 2026-04-25 |
| LD-03 | macOS-only; `isDesktopOnly: true` | Inherited from LD-01 |
| LD-04 | Community-distributable from v1 | User, 2026-04-25 |
| LD-05 | Re-import gate: show disabled w/ "already imported" badge; toggle to override; re-import forces new unique filename | User, 2026-04-25 (Q1 + round-2 review) |
| LD-06 | Target folder: settings default + per-import override | User, 2026-04-25 (Q2) |
| LD-07 | Attachments included in v1, extracted to configurable folder; sequential batch execution | User, 2026-04-25 (Q3 + round-2 review) |
| LD-08 | HTML→MD via turndown with Apple-Notes-aware pre-processor + custom node-filters; tiered warnings (severe blocks delete; moderate logs; debug-only in receipt log not note body) | User, 2026-04-25 (Q4 + round-1 + round-2 reviews) |
| LD-09 | Frontmatter set: `source`, `apple_notes_id`, `apple_notes_account`, `apple_notes_folder`, `apple_notes_created`, `apple_notes_modified`, `imported_at`, `imported_attachments`, `import_warnings` | User, 2026-04-25 (Q5 + round-1 review) |

## Plugin Manifest (proposed for PLAN/IMPLEMENT)

```json
{
  "id": "applenotes-import",
  "name": "Apple Notes Import",
  "version": "0.1.0",
  "minAppVersion": "TBD — must resolve to concrete X.Y.Z before TASK lock (researched in OAI-002 against API surface)",
  "description": "Browse Apple Notes from inside Obsidian, selectively import notes (with attachments) as markdown, and soft-delete the originals.",
  "author": "Dan Turner",
  "authorUrl": "TBD",
  "isDesktopOnly": true
}
```

`fundingUrl` deliberately omitted (per submission rules: only include if accepting donations). `styles.css` shipped alongside `main.js` and `manifest.json` in release assets.

## Acceptance Criteria (project level)

A v1 release is accepted when **all** of the following hold:

- **AC1** — Modal lists Apple Notes responsively: first results / loading indicator within 2 seconds; complete listing for ~1k notes within 5–10s under typical conditions; locked / iCloud-shared / unreadable notes counted and explicitly labeled. **Threshold rule:** if A1 spike measures >5s for 1k, modal MUST use paginated/streamed loading; if >10s, return to PLAN risk review.
- **AC2** — A selected note is imported as a markdown file in the configured target folder with frontmatter exactly matching LD-09.
- **AC3** — Attachments are extracted and linked from the markdown; rendered note in Obsidian shows attachments inline where Apple Notes did, for the support-matrix-defined types (image, PDF, audio, drawing/sketch, scanned doc, web bookmark). Severe omissions block delete (AC5).
- **AC4** — A scripted integration test confirms: after a successful import, the source note is no longer in its original folder and appears in Apple Notes' Recently Deleted folder. Probe-based, not inferred from behavior.
- **AC5** — Composite verify-before-delete (canonical sequence): pipeline runs `… write md → persist index → composite verify → soft-delete → append receipt`. Verify covers (a) md exists, (b) md content matches expected pre-write hash, (c) all expected attachment files exist with non-zero size, (d) rewritten markdown attachment references resolve, (e) index entry persisted and JSON-roundtrip readback succeeds with structural shape match. Any failure aborts delete; source remains in Apple Notes; receipt marks errored. Adversarial tests inject partial-write, attachment-failure, and index-failure to prove the gate holds.
- **AC6** — Re-opening the modal after an import shows imported notes as disabled with "already imported on YYYY-MM-DD" badge by default. Toggling "show already-imported" enables their checkboxes for re-selection. Native vault rename/delete of an imported file updates/removes the index entry via `vault.on('rename')` / `vault.on('delete')` listeners. Index corruption triggers safe-degraded mode (delete-capable imports disabled until repaired). Repair conflict policy enforced (duplicate id → ambiguous, missing path → drop, hash mismatch → untrusted).
- **AC7** — On a non-macOS desktop OR mobile, `onload()` performs early-return BEFORE any side effects: no commands registered, no ribbon icon, no settings tab modal. A single Notice "Apple Notes Import: macOS only" emits once per install/version.
- **AC8** — On TCC denial (probed on first user-initiated command, NOT on plugin load; settings "Re-check permission" button also counts as a probe), plugin surfaces in-app guidance and disables import/delete commands until permission is granted. Denial detection works for known stderr patterns (-1743 / -10000 / `Not authorized to send Apple events`), with timeout fallback for hangs and generic-error fallback for unmatched.
- **AC9** — Submission requirements pass: `isDesktopOnly: true`, no committed `main.js`, no `innerHTML` with user input, `instanceof` adapter checks, `normalizePath` on user paths, `registerEvent`/`registerDomEvent`/`registerInterval` for all listeners, `styles.css` committed and shipped, no plugin-name prefix in command names. `eslint-plugin-obsidianmd` runs clean. **Release asset inspection:** the published zip contains exactly `manifest.json`, `main.js`, `styles.css` and excludes source maps, tests, and dev files.
- **AC10** — Per-batch receipt markdown is written, listing imported / imported-not-deleted / skipped / errored notes with reasons; imported paths emitted as wikilinks. Receipt filename collisions resolved with timestamp suffix. Receipt-write failure post-delete logs to console + Notice; does not roll back the soft-delete.
- **AC11** — Batch transaction: per-note independence — a note-level failure aborts only that note's delete, never the batch. Notes execute **sequentially** (await each pipeline completion). Cancel-after-current observed only between note transactions; once a note enters verify→delete it runs to completion. Final summary dialog presents imported / imported-not-deleted / skipped / errored counts. If md writes but attachments fail, md is left in vault and marked errored; temp directories (pattern `.tmp-applenotes-import-<id>`) are cleaned up post-note regardless of outcome.

## Task Decomposition

Tasks scoped ≤5 file changes each except where noted. Risk: low | medium | high. Each task ID prefixed `OAI-`. Dependencies expressed in **Depends** column. Critical-path tasks (data-safety) bolded.

### M1 — Foundation

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| OAI-001 | Repo build scaffold | 4 (`package.json`, `tsconfig.json`, `esbuild.config.mjs`, `eslint.config.mjs`) | low | #code | — | `npm install && npm run build` produces `main.js`; `npm run lint` exits 0. `eslint-plugin-obsidianmd` pinned (decision in PLAN: `0.1.9` template default or `0.2.4` latest) |
| OAI-002 | Plugin skeleton + minAppVersion research + platform-gate early-return | 3 (`manifest.json`, `versions.json`, `src/main.ts`) | low | #code, #research | OAI-001 | Plugin loads in test vault; `onunload` clean (no leaked listeners). minAppVersion researched against API surface (`Platform`, `vault.createBinary`, `normalizePath`, `FileSystemAdapter`, `containerEl.createEl`, `vault.on('rename')`, `vault.on('delete')`) and **set to a concrete `X.Y.Z` value before TASK lock**. `onload()` early-returns on `Platform.isMobile === true` OR `!Platform.isMacOS` BEFORE any side effects |
| OAI-003 | Settings tab + path validation + Re-check button | 2 (`src/settings.ts`, `src/main.ts` wiring) | low | #code | OAI-002 | All v1 settings present (target folder, attachments folder, receipts folder, show-already-imported default, dry-run default, debug-mode toggle); paths normalized + validated on save (reject empty/invalid; auto-create on first import); persist across reload. "Re-check permission" button wired as user-initiated TCC probe |

### M2 — AppleScript bridge (validate Assumptions)

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| OAI-004 | osascript runner | 2 (`src/applescript/runner.ts`, test) | medium | #code | OAI-001 | Wraps `child_process.execFile`; surfaces stderr, timeout, exit code; unit-tested with a fixture script |
| OAI-005 | List notes script + parser | 2 (`src/applescript/list-notes.applescript`, `src/applescript/list-notes.ts`) | medium | #code | OAI-004 | Returns `[{id, name, account, folder, created, modified, attachmentCount, isLocked}]` for visible notes; locked notes listed with `isLocked: true` flag; import pipeline skips locked notes with explicit reason unless body fetch later succeeds |
| OAI-006 | Fetch note body script + parser | 2 | medium | #code | OAI-004 | Returns `{id, name, account, folder, created, modified, bodyHtml}`; locked notes return `{skipped: 'locked'}` instead of raising. Parser tolerates fragment HTML and malformed input (wraps before downstream conversion) |
| **OAI-007** | **Soft-delete script + wrapper** | 2 | **high** | #code | OAI-004 | Already-validated G1 (2026-04-25); task implements the production-quality wrapper. Acceptance: deleted note appears in Recently Deleted within 2s; integration test re-runs the G1 probe pattern |
| **OAI-008a** | **Attachment extraction probe + decision (Pre-PLAN G3)** | 3 (`design/decisions/attachments.md`, dual-approach probe scripts) | **high** | #research, #decision | OAI-004 | Run dual probe per G3 pass criteria. Decision-doc archived **at repo-local `design/decisions/attachments.md`** (NOT `_system/docs/solutions/`). |
| **OAI-008b** | **Attachment extractor (implement winner)** | 3 | **high** | #code | OAI-008a | Implements the chosen approach; extracts ≥95% of required-matrix types (image, PDF, audio, scanned doc); binary written to vault attachments folder with correct extension; markdown reference uses relative path that resolves when rendered. Drawing/sketch and web-bookmark types follow probe-determined warning semantics |

### M3 — Conversion & vault writes

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| OAI-009 | HTML→Markdown converter (Apple-Notes-aware) | 3 (`src/convert/preprocess.ts`, `src/convert/html-to-md.ts`, golden-output tests) | medium | #code | OAI-006, OAI-008a | Pre-processing layer normalizes Apple-Notes-specific HTML (checklist objects, attachment object placeholders, Apple-specific spans/divs) BEFORE turndown. Turndown is configured with custom node-filters that **catch** unknown tags (turndown silently drops them by default) and emit them per the warning-tier matrix (severe blocks delete; moderate logs). Headings, lists, links, bold/italic, GFM tables, code blocks, GFM checklists round-trip. Golden tests use ≥10 representative inputs **captured from real Apple Notes**, not synthetic |
| OAI-010 | Filename sanitizer + collision policy | 1 + tests | low | #code | — | `normalizePath`; sanitizer strips macOS+Obsidian-illegal characters; collision policy: title→sanitized name; suffix `-2`, `-3`, … on collision; index stores canonical chosen path; re-import override creates new unique file (never overwrite silently) |
| OAI-011 | Vault writer + temp file management | 2 (`src/vault/writer.ts`, frontmatter helper) | medium | #code | OAI-009, OAI-010 | Creates target/attachments folders idempotently; writes md and binary attachments; frontmatter matches LD-09 exactly. Captures **expected pre-write content hash** (used by OAI-016b verify gate). Temp files use pattern `.tmp-applenotes-import-<note-id>` adjacent to attachments folder; cleaned post-note regardless of outcome (success and failure paths). On md-written-but-attachments-failed: md left in vault, temp dirs cleaned up |

### M4 — Import index

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| **OAI-012** | **Import index store (corruption-resilient + vault-sync)** | 2 (`src/index/import-index.ts`, tests) | **high** | #code | OAI-002 | Persists `{appleNotesId → {vaultPath, contentHash, importedAt, untrusted?: bool}}` via plugin `data.json`; **secondary key**: content hash, used to detect collisions (e.g., iCloud account-switch yielding different ids for same content) — flag, do not silently re-import. **Vault listeners**: registers `app.vault.on('rename')` (update path) and `app.vault.on('delete')` (remove entry) via `registerEvent` to keep the index in sync with native vault changes. **Readback contract**: index readback succeeds iff `JSON.parse(written)` round-trips losslessly AND structural shape matches expected schema. Survives plugin reload. **Corruption recovery: safe-degraded mode** — on parse error, plugin disables delete-capable imports, surfaces Notice with "Repair" action. Repair scans vault frontmatter for `apple_notes_id` (default scoped to configured import folder; configurable to whole-vault); progress indicator if scan exceeds 2s. **Repair conflict policy**: duplicate `apple_notes_id` → mark ambiguous, keep delete disabled until user resolves; missing file path → drop entry + log; frontmatter/hash mismatch → rebuild with current path but mark `untrusted: true`; repair report appended to receipt. Never silently treats corruption as empty |

### M5 — Modal UI

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| OAI-013 | Notes modal | 2 (`src/ui/NotesModal.ts`, `styles.css`) | medium | #code | OAI-005, OAI-006, OAI-012 | Lists notes (account/folder columns, search, filter); checkbox multi-select; preview snippet from body fetch; target-folder picker; dry-run toggle; "show already-imported" toggle (visibility AND checkbox-enable). Already-imported notes disabled by default with badge; constructed via `createEl`, no `innerHTML`. **`styles.css` committed in repo with at least 3-4 minimal selectors (modal table, row-disabled state, badge), included in release zip.** **If A1 probe shows >5s for 1k notes, modal uses paginated/streamed loading.** Cancel-after-current control available during execution. May be developed with mock data — does NOT depend on OAI-019 (TCC dep is at command wiring in OAI-015, not modal construction) |
| OAI-014 | Confirm-delete modal | 1 | medium | #code | OAI-013 | Lists N notes about to import + soft-delete, explicit "moved to Recently Deleted in Apple Notes" copy, requires confirm click |
| OAI-015 | Command + ribbon wiring | 1 (`src/main.ts`) | low | #code | OAI-013, OAI-014, OAI-019 | "Browse Apple Notes" command palette entry; ribbon icon launches modal. Commands and ribbon registered ONLY when `Platform.isMacOS === true` (tied to OAI-002/OAI-020 platform gate); TCC probe runs on first command invocation per OAI-019 |

### M6 — Import orchestrator (safety-critical, split per round-1 review; boundaries tightened per round-2)

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| **OAI-016a** | **Import transaction model + sequencing (orchestration only — no verify rules embedded)** | 2 (`src/import/transaction.ts`, tests) | **high** | #code | OAI-006, OAI-008b, OAI-011, OAI-012 | Defines and implements the strict canonical pipeline order per note: `fetch → convert → write attachments → write markdown → persist index → invoke verify (OAI-016b) → invoke delete-gate (OAI-016c) → append receipt`. Receipt append is **NOT** a delete gate. Sequencing is the primary safety control. **Function contract:** `runNoteTransaction(note) → {status, errorReason?}` where `status ∈ {imported, imported-not-deleted, skipped, errored}`. 016a does NOT implement verify rules — those live in 016b. 016a does NOT invoke delete directly — that's gated by 016c |
| **OAI-016b** | **Composite verify implementation (pure verification, returns success/failure schema)** | 2 (`src/import/verify.ts`, adversarial tests) | **high** | #code | OAI-011, OAI-012 | **Function contract:** `verifyImport(expectations) → {ok: boolean, failures: string[]}`. Verify covers: (1) md exists, (2) md content matches expected pre-write hash (NOT a self-hash), (3) all expected attachment files exist with non-zero size, (4) all rewritten markdown attachment refs resolve, (5) index entry JSON-roundtrips losslessly with structural shape match. No side effects beyond reads. Adversarial tests inject mocked partial-write, attachment-failure, and index-failure to prove the function returns `ok: false` correctly |
| **OAI-016c** | **Soft-delete gate execution (only "invoke delete iff verify=success")** | 1 (`src/import/delete-gate.ts`) | **high** | #code | OAI-007, OAI-016b | **Function contract:** `executeDeleteIfVerified(noteId, verifyResult) → {deleted: boolean, abortReason?}`. Gates the actual `osascript` delete call behind `verifyResult.ok === true`. On `verifyResult.ok === false`, returns abort-with-reason without ever invoking delete. Integration test: contrived verify-failure → confirms delete-not-called via spy |
| **OAI-016d** | **Batch execution + cancellation + progress + temp cleanup** | 2 (`src/import/batch.ts`, UI wiring) | high | #code | OAI-016a..c, OAI-013 | **Sequential execution** — await each note's pipeline before starting the next. Per-note independence: failure aborts only that note's pipeline, never propagates. **Cancel-after-current**: observed only between note transactions; once a note enters the verify→delete phase it runs to completion. Progress updates streamed to modal. **Temp cleanup**: all temp dirs/files (pattern `.tmp-applenotes-import-<id>`) cleaned post-note regardless of outcome. Final summary dialog: imported / imported-not-deleted / skipped / errored counts |
| OAI-016e | Receipt log writer | 1 (`src/import/receipt.ts`) | low | #code | OAI-016d | Per-batch markdown written to receipts folder with imported / imported-not-deleted / skipped / errored sections. Imported paths use `[[wikilinks]]`; skipped/errored entries have plain-text reason. Receipt filename collision → timestamp suffix. **Receipt-write failure**: logs to console + Notice; does NOT roll back the soft-delete |

### M7 — Permission & platform UX

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| OAI-019 | TCC permission probe + handler | 2 (`src/permissions/tcc.ts`, README guidance) | medium | #code | OAI-004 | Probe runs **on first user-initiated command invocation** (NOT plugin load). Settings-tab "Re-check permission" button is also a user-initiated probe and triggers the same flow. Denial detection: parse stderr for `Not authorized to send Apple events`, error codes -1743 / -10000; timeout fallback for hangs (treat as probable denial with manual-recheck affordance); generic-error fallback for unmatched (don't auto-disable). On confirmed denial: in-app Notice + settings-tab guidance directs user to System Settings → Privacy → Automation → Obsidian → Notes; commands disabled until granted |
| OAI-020 | Platform gate (no UI registration off-platform) | 1 (`src/main.ts`) | low | #code | OAI-002 | `Platform.isMacOS === false` OR `Platform.isMobile === true` → `onload()` performs early-return BEFORE any side effects: skip command registration, ribbon icon, settings tab modal. Single Notice "Apple Notes Import: macOS only" emits **once per install/version** (de-dup via stored marker), not on every reload |

### M8 — Distribution

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| OAI-021 | README, LICENSE, screenshots | 3 | low | #writing | M6 + M7 complete | README documents: permission flow, soft-delete semantics + Recently Deleted retention, frontmatter fields (incl. `apple_notes_id` privacy notice prominent), known limitations, manual install steps, TCC troubleshooting section, macOS-only banner. LICENSE chosen (MIT or 0-BSD). ≥2 screenshots reflecting current UI |
| OAI-022 | Release workflow + asset inspection | 1 (`.github/workflows/release.yml`) | medium | #code | OAI-021 | Tag push → builds → attaches `main.js`, `manifest.json`, `styles.css` to GitHub release. Manifest fields match release tag/version. `.gitignore` excludes `main.js` + dev artifacts. **Release asset inspection step** (in workflow): zip contains exactly `manifest.json`, `main.js`, `styles.css`; fails if extra files (source maps, tests, dev files) detected. Submission self-critique checklist (per research-brief §4) runs clean |
| OAI-023 | Community submission PR | 1 (community-plugins.json entry, separate fork) | low | #writing | OAI-022 | Submission PR drafted against `obsidianmd/obsidian-releases`; submission self-critique checklist run clean |

### Task Dependency Summary

```
M1: OAI-001 → 002 → 003

M2: OAI-004 ─┬─→ 005
             ├─→ 006
             ├─→ 007
             └─→ 008a → 008b

M3: 006, 008a ──→ 009
        010 (independent)
        009 + 010 ──→ 011

M4: 002 ──→ 012

M5: 005, 006, 012 ──→ 013 → 014
M7-OAI-019: 004 ──→ 019  (parallel to M5)
            015 needs 013, 014, AND 019

M6: 006, 008b, 011, 012 ──→ 016a
    011, 012 ──→ 016b
    007, 016b ──→ 016c
    016a..c, 013 ──→ 016d → 016e

M7-OAI-020: 002 ──→ 020 (parallel to M5/M6)

M8: M6 + M7 complete ──→ 021 → 022 → 023
```

### Attachment support matrix (for OAI-008a/b)

| Type | Source format examples | v1 support class | G3 threshold |
|---|---|---|---|
| Image | JPEG, PNG, HEIC | **Required** | ≥95% extraction success |
| PDF | application/pdf | **Required** | ≥95% extraction success |
| Audio | m4a | **Required** | ≥95% extraction success |
| Scanned document | PDF | **Required** | ≥95% extraction success |
| Drawing/sketch | Apple Notes proprietary canvas | Best-effort | Probe-determined; PNG fallback if available; warn moderate |
| Web bookmark | HTML preview card | Best-effort | Probe-determined; link extraction; warn moderate |

Failure of any **Required** type, OR Full Disk Access requirement with unacceptable UX, OR per-attachment latency >2s, → return to SPECIFY.

## Risk Register (project level)

| Risk | Severity | Mitigation |
|---|---|---|
| ~~AppleScript hard-delete instead of soft-delete~~ | ✅ **Cleared** | G1 validated 2026-04-25 (macOS 26.3.1) |
| Composite verify-before-delete gate weakly enforced | **Critical** | OAI-016b dedicated task with adversarial tests for partial-write / attachment-failure / index-failure; sequencing is primary safety control |
| Index corruption causes silent re-import / data confusion | **Critical** | OAI-012 safe-degraded mode + frontmatter rebuild + repair conflict policy |
| Mid-batch failure cascades / partial source loss | High | OAI-016d per-note independence + sequential execution + final summary |
| TCC denial silently locks users out | High | OAI-019 first-command probe + structured denial detection + manual re-check |
| Index silently desyncs from vault on native rename/delete | High | OAI-012 vault.on('rename') / vault.on('delete') listeners |
| AppleScript performance kills modal UX on large libraries | Medium | A1 probe in PLAN; if >5s for 1k, OAI-013 pagination contingency triggers; >10s → PLAN risk review |
| turndown drops formatting users care about | Medium | Apple-Notes-aware pre-processor + custom node-filters; golden tests on real captured HTML; severe-tier blocks delete |
| Note id instability across iCloud account switch | Medium | Content-hash secondary key in OAI-012; cross-account allowed (downgraded dedupe) |
| Submission rejected on first community-plugin review | Low | Distribution checklist (gitignore, release-asset inspection, README, screenshots, manifest/tag consistency) in OAI-022; lint with `eslint-plugin-obsidianmd` from day 1 |
| Apple Notes HTML changes break converter post-release | Low | Pin turndown; golden tests on real fixtures; docs link for users to file repro issues |

## Spec Scope Classification

**MAJOR.** New system, new external repo, destructive operations against a third-party app, community-distribution gate. Two rounds of peer review applied (round 1: 10 must-fix + 18 should-fix; round 2: 15 must-fix + 14 should-fix). SPECIFY artifact frozen at revision 3 pending pre-PLAN gates G2 and G3.
