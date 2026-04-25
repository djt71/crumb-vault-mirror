---
project: obsidian-applenotes-import
domain: software
type: specification
skill_origin: systems-analyst
created: 2026-04-25
updated: 2026-04-25
revision: 4
revision_history:
  - rev: 1
    date: 2026-04-25
    note: Initial SPECIFY output
  - rev: 2
    date: 2026-04-25
    note: Round-1 peer-review revision pass — applied 10 must-fix and 18 should-fix actions; A4 probe validated
  - rev: 3
    date: 2026-04-25
    note: Round-2 peer-review revision pass — applied 15 must-fix and 14 should-fix actions; G4 citations pinned
  - rev: 4
    date: 2026-04-25
    note: Pre-PLAN probe outcomes — G2 validated; G3 removed (attachments deferred to v1.1 per operator decision); spec simplified accordingly
tags:
  - obsidian-plugin
  - applescript
  - macos
---

# Specification — Obsidian Apple Notes Import

## Problem Statement

Apple Notes accumulates capture-stage thinking that should live in the user's Obsidian vault, but there is no built-in path to selectively migrate notes into Obsidian and remove the originals. Users either manually copy-paste (slow, lossy on formatting) or rely on bulk one-time exporters that don't fit ongoing capture-then-promote workflows. This plugin closes the gap with a per-note review-and-import flow that soft-deletes the source after a verified vault write.

## Goals & Non-Goals

**Goals (v1):**
1. List Apple Notes inside Obsidian (account/folder/title metadata).
2. Selectively import chosen notes' **markdown body** into a configured vault folder, with provenance metadata in YAML frontmatter.
3. After verified vault write, soft-delete the original Apple Note (Apple Notes' Recently Deleted folder).
4. Be eligible for the Obsidian community plugin directory (manifest, code style, distribution all conformant).

**Non-goals (v1):**
- Attachments — v1 imports body markdown only. If a source note has attachments (image, PDF, audio, drawing/sketch, scanned doc, web bookmark), they are NOT migrated; the converted markdown contains a comment placeholder noting their presence; soft-delete proceeds uniformly. **This is irreversible after Apple Notes' Recently Deleted retention expires** — README must surface this prominently. Attachment migration deferred to v1.1.
- Two-way sync; edit-back-to-Notes; conflict resolution.
- Hard delete (would bypass Apple's Recently Deleted retention safety net).
- Cross-platform support (Linux/Windows/iOS/iPadOS).
- Re-importing already-imported notes silently (re-import is gated, not denied).
- Locked-note unlock/decrypt; iCloud-shared note edge handling beyond skip-and-log.
- Bulk export of an entire account (the workflow is selective on purpose).
- Hash-redacted `apple_notes_id` in frontmatter (deferred to v1.1; v1 stores raw id with prominent README privacy notice).

## Pre-PLAN Validation Gate

The following must be confirmed **before SPECIFY closes and PLAN begins**.

| Gate | Status | Evidence |
|---|---|---|
| **G1 / A4** — AppleScript `delete` on Notes is soft-delete (Recently Deleted), not hard-delete | ✅ **VALIDATED 2026-04-25** | osascript probe on macOS 26.3.1; raw output and `sw_vers` capture in [`probes/a4-probe-result.md`](probes/a4-probe-result.md). Probe: created throwaway note, deleted via `tell application "Notes" to delete`, confirmed (a) `EXISTS_BY_ID_AFTER_DELETE=true`, (b) note found in "Recently Deleted" folder. |
| **G2 / A2** — Note `id` is stable across Notes app restart, edit, and folder move | ✅ **VALIDATED 2026-04-25** | osascript probe on macOS 26.3.1; full results in [`probes/g2-probe-result.md`](probes/g2-probe-result.md). Id byte-identical across 3 restarts + title edit + body edit + folder move within same account. |
| **G4** — Citations pinned in [`research-brief-plugin-platform.md`](research-brief-plugin-platform.md) | ✅ **RESOLVED 2026-04-25** | `obsidian-developer-docs` HEAD `2ed97bd0...`, `obsidian-sample-plugin` HEAD `dc2fa22c...`, `Manifest.md` blob `eeac634a...`, `Submission requirements...md` blob `ce93a442...`. `eslint-plugin-obsidianmd` confirmed at `0.1.9` in template; `0.2.4` latest on npm. |

~~G3 / A7 — Attachment extraction approach decision~~ **REMOVED in rev 4** — attachments deferred to v1.1; v1 imports body only. No attachment extraction is attempted; no permission-cost or feasibility decisions are required for v1.

**All pre-PLAN gates resolved.** SPECIFY artifact is complete; PLAN may begin.

## Probe-Derived Implementation Notes

These findings emerged from G1 and G2 probes and bind PLAN/IMPLEMENT decisions, but do not require spec changes:

1. **Note name is volatile.** Apple Notes auto-derives `name of note` from the body's first heading or first non-empty line. Production AppleScript code MUST address notes by id (`whose id is X`), never by name. The import pipeline already keys on id, so this is a code-style note, not a design change.
2. **`folder of note` is not queryable.** Direct property access raises error -1728. To determine a note's folder, iterate folders and check membership via `id of (every note of f)`. We already capture each note's folder during the listing pass (OAI-005); we never need to re-query it.
3. **AppleScript `move` works** — used in production via fresh `whose id is X` handle (NOT a stale by-name reference). Not needed by the plugin (we read+delete, never move), but documented for future reference.

## Facts

Sourced from [`research-brief-plugin-platform.md`](research-brief-plugin-platform.md) (citations pinned per G4):

- Plugin id in `manifest.json` cannot contain the substring "obsidian" → proposed id `applenotes-import` (per `obsidian-developer-docs` `en/Reference/Manifest.md` blob `eeac634a`).
- `isDesktopOnly: true` is required; we use NodeJS `child_process` to invoke `osascript`.
- `main.js` is a build artifact; must not be committed (release-only).
- `app.vault.create`, `app.vault.createFolder` (errors if folder exists), `normalizePath` are the relevant vault APIs. (`createBinary` no longer needed in v1 — no attachments.)
- `app.vault.on('rename')` and `app.vault.on('delete')` are the relevant lifecycle events for keeping the import index in sync with native vault changes.
- DOM construction must use `containerEl.createEl` etc.; `innerHTML`/`outerHTML` with user input is a submission reject.
- Adapter type checks must use `instanceof FileSystemAdapter` (no casting).
- `registerEvent` / `registerDomEvent` / `registerInterval` are required for cleanup.
- `eslint-plugin-obsidianmd` is the official lint plugin, pinned at `0.1.9` in current sample template (latest published on npm: `0.2.4`).
- `styles.css` is a first-class plugin asset: committed in repo, included in release zip alongside `main.js` and `manifest.json`.
- AppleScript `delete` against an Apple Notes note moves it to Apple Notes' Recently Deleted folder — **empirically validated G1 on 2026-04-25 / macOS 26.3.1**.
- Apple Notes `id of note` is stable across restart/edit/folder-move within same account — **empirically validated G2 on 2026-04-25 / macOS 26.3.1**.

## Assumptions (PLAN spike)

All pre-PLAN gating assumptions resolved. The remaining assumptions are PLAN-spike-stage:

- **A1** — `tell application "Notes" to get every note` returns within ≤10s (viability) for ~1k notes; >5s triggers paginated/streamed UI mode (single rule with two thresholds). Validate during PLAN.
- **A3** — `body of note` returns HTML reliably; conversion can drop attachment-object placeholders gracefully. Validate during PLAN with at least 1 attachment-bearing note (need not extract content; just observe HTML shape and ensure converter doesn't crash).
- **A5** — TCC Automation permission denial returns recognizable error codes (e.g., `-1743`, `-10000`) or characteristic stderr text (`Not authorized to send Apple events`). Validate via `tccutil reset AppleEvents`.
- **A6** — Locked notes appear in `every note` but `body` raises an AppleScript error. Validate with a locked test note.

## Unknowns (carried into PLAN)

- Behavior of the Notes id under iCloud account-switching → mitigated by content-hash secondary key in OAI-012; cross-account allowed (downgrade dedupe to account-scoped).
- Whether `eslint-plugin-obsidianmd` rules conflict with our preferred TypeScript style; resolve in PLAN. Whether to track template's `0.1.9` or latest `0.2.4` is a PLAN decision.
- Exact `minAppVersion` value (researched in OAI-002 against API surface).

## System Map

### Components

- **Apple Notes** (external macOS app) — the source-of-truth for unmigrated notes; accessed only via AppleScript.
- **AppleScript bridge** — small `.applescript` files plus a TS runner (`child_process.execFile osascript`) that returns JSON-shaped strings parsed in TS. All note handles addressed by id (per probe-derived note 1).
- **Conversion layer** — Apple-Notes-specific HTML pre-processor → `turndown` (with custom node-filters that *catch* unknown tags rather than silently drop) → markdown. Pre-processor handles checklist objects and Apple-specific spans/divs. **Attachment objects (image, PDF, audio, drawing, scan, bookmark) are dropped during conversion**, replaced with a markdown comment placeholder of form `<!-- [v1: attachment dropped: <type-or-name>] -->` and counted toward `source_had_attachments` and `import_warnings.attachments_dropped`. Parser tolerates fragment HTML and malformed input.
- **Import index** — per-vault JSON in plugin `data.json` keyed by `apple_notes_id` AND content-hash (secondary key for collision/account-switch tolerance). Listens for `vault.on('rename')` (update path) and `vault.on('delete')` (remove entry) via `registerEvent`. Readback contract: `JSON.parse(written)` round-trips losslessly AND structural shape matches expected schema. Corruption recovery: safe-degraded mode + frontmatter-scan rebuild (default scoped to configured import folder; configurable to whole-vault); progress indicator if scan exceeds 2s. Repair conflict policy: duplicate id → ambiguous (delete disabled until resolved); missing path → drop entry + log; frontmatter/hash mismatch → rebuild with current path but mark `untrusted: true`; repair report appended to receipt. Never silently treats corruption as empty.
- **Vault writer** — calls `app.vault.create` / `app.vault.createFolder`; assembles YAML frontmatter. Captures **expected pre-write content hash** (used by composite verify gate). Settings paths normalized + validated on save (reject empty/invalid; auto-create on first import). **Markdown only — no binary writes in v1.**
- **Composite verify-before-delete gate** — single integration point that runs AFTER index persistence. Canonical pipeline (applied identically in System Map, AC5, OAI-016a, OAI-016b):
  1. Fetch body from Apple Notes
  2. Convert HTML → markdown (drop attachment objects, log placeholders)
  3. Write markdown
  4. **Persist index entry** (mark "pending-verify")
  5. **Composite verify**: (a) markdown file exists, (b) markdown content matches the **expected pre-write hash** (NOT a self-hash), (c) index entry persisted and JSON-roundtrip readback succeeds with structural shape match
  6. If verify succeeds: mark index entry "imported"; soft-delete source note
  7. Append receipt
  
  Failure of any verify step aborts delete and marks the entry "errored" in the receipt; the source remains in Apple Notes. Sequencing (write → persist → verify → delete) is the **primary safety control**; the verify gate is the secondary check. Note: with attachments removed from v1, the verify gate is materially simpler than rev 3 (3 checks vs. 5).
- **Batch transaction model** — multi-select imports execute notes **sequentially** to respect Apple Events concurrency limits. Per-note independence: a single note's failure aborts only *that* note's delete, never propagates. Cancel-after-current observed only between note transactions; once a note enters verify→delete, its pipeline runs to completion. After all notes complete, a final summary dialog reports imported / imported-not-deleted / skipped / errored counts.
- **Modal UI** — table of notes with checkboxes, search, account/folder filter, target-folder picker, dry-run toggle, "show already-imported" toggle. Notes with attachments shown with **informational** badge `(N attachments — body only)`; selectable as normal. Toggling "show already-imported" makes those notes visible AND enables their checkboxes for re-selection (re-import forces a new unique filename per OAI-010 — never overwrites). If A1 spike shows >5s for 1k notes, modal MUST use paginated/streamed loading.
- **Confirm dialog** — final approval listing N notes about to import + soft-delete, with explicit "Notes will be moved to Recently Deleted in Apple Notes" copy. **If any selected note has attachments, dialog ALSO shows: "X of these notes have attachments which will be lost after Apple's Recently Deleted retention expires."**
- **Receipt log** — per-batch markdown file in a configurable receipts folder summarizing imported / imported-not-deleted / skipped / errored counts AND aggregate `attachments_dropped` count across the batch. Imported note paths emitted as wikilinks. Receipt filename collisions handled with timestamp suffix. Receipt-write failure logs to console + Notice; does NOT roll back the soft-delete.
- **Settings tab** — defaults for target folder, receipts folder, "show already-imported" default, dry-run default, debug-mode toggle (controls receipt verbosity). Manual "Re-check permission" button (counts as user-initiated TCC probe). **No "attachments folder" setting in v1.**
- **TCC handler** — probes on **first user-initiated command invocation** (NOT plugin load). The settings-tab "Re-check permission" button is also a user-initiated probe. On denial captured by stderr-pattern match (`Not authorized to send Apple events`, error codes -1743/-10000), timeout fallback (treat hangs as probable denial), or generic-error fallback (don't auto-disable on unmatched), surfaces in-app guidance + settings-tab guidance.
- **Platform gate** — runtime `Platform.isMacOS` check at plugin load. On non-macOS desktop OR mobile, `onload()` performs early-return BEFORE any side effects: no command registration, no ribbon icon, no settings-tab. A single Notice "Apple Notes Import: macOS only" emits **once per install/version** (de-dup via stored marker), not on every reload.

### Conversion warning tiers (composite verify input)

| Tier | Trigger | Behavior |
|---|---|---|
| **Severe** | Substantive body content cannot be represented (e.g., a checklist or table collapses to near-empty output where user-visible content would be lost). | **Blocks delete.** Note marked errored in receipt; source remains in Apple Notes. |
| **Moderate** | Source note had attachments (dropped during conversion); OR formatting degradation with no user-visible content lost. | Logged in receipt + frontmatter `import_warnings: [...]`. Delete proceeds. |
| **Debug-only** | Detailed conversion telemetry, including raw source HTML for unsupported elements. | Recorded in receipt log only (NOT inline in the imported note body). |

### Dependencies

- **Inbound:** macOS, Apple Notes app, TCC Automation grant, Electron-bundled Node, Obsidian ≥ minAppVersion (researched in OAI-002 against API surface: `Platform`, `vault.create`, `normalizePath`, `FileSystemAdapter`, `containerEl.createEl`, `vault.on('rename')`, `vault.on('delete')`).
- **External libs:** `turndown` (HTML→MD; small, MIT). Custom node-filters required to capture unknown tags. Possibly `sanitize-html` if turndown's input handling proves insufficient (decide in PLAN).
- **Outbound (eventual):** `obsidianmd/obsidian-releases` PR for community-plugin directory submission.

### External code repo

YES — already initialized at `~/code/obsidian-applenotes-import/` (commit `4bd59d9`). `repo_path` and `build_command` recorded in `project-state.yaml`.

### Constraints

- Hard: macOS-only; `isDesktopOnly: true`; AppleScript performance ceiling; sequential batch execution (no parallel osascript→Notes); no `innerHTML` with user input; no committed `main.js`; plugin id can't contain "obsidian"; no command name prefixed with plugin name; `styles.css` committed and shipped.
- Soft: AppleScript latency degrades the UX above ~1k notes; rich-content fidelity in turndown is best-effort even with custom node-filters; **attachment migration is out-of-scope for v1** and source-side attachments are lost after Recently Deleted retention.
- Regulatory: none.

### Levers (high-leverage intervention points)

1. **Composite verify-before-delete contract.** Single point determining data-loss risk for body content. Now covers md + index (simpler than rev 3's md + attachments + index).
2. **Sequencing as primary safety control.** Strict order (write md → persist index → verify → delete) constrains blast radius even if verify gate has bugs.
3. **Import index integrity + rebuild path.** Vault rename/delete listeners; safe-degraded mode + frontmatter rebuild; explicit conflict policy.
4. **Body-conversion fidelity tier (with severe→delete-block).** Severe (substantive body content lost) blocks delete; moderate (attachments dropped, formatting degraded) logs.
5. **TCC failure UX.** First-command probe; structured denial detection; manual re-check button.
6. **Attachment-loss communication.** README + confirm-dialog must surface that v1 imports body only and source attachments are lost after retention. User trust depends on this being clearly disclosed up-front.
7. **Submission compliance.** Single point determining whether v1 ships to the community directory or has to be revised post-review.

### Second-Order Effects

- If composite verify is loose, users lose body source data — single highest-impact failure mode.
- Recently Deleted in Apple Notes auto-purges per Apple's standard retention; soft delete is a bounded recovery window. **For attachment-bearing notes, attachments are lost when retention expires** — this is documented as a known v1 limitation.
- AppleScript Notes queries can stall the UI on first-run for huge libraries; A1 spike result drives whether modal uses pagination/streaming.
- Frontmatter `apple_notes_id` exposes a CoreData URI; users sharing vaults will leak their machine's identifier. Documented prominently in README. Hashed-id alternative deferred to v1.1.
- Building a turndown pipeline creates maintenance gravity if Apple Notes' HTML evolves; pin turndown version, write golden-output tests using captured real-world fixtures (where available).
- Index lives in plugin `data.json` (per-vault, not synced across Obsidian installs). Vault sync across machines + plugin reinstall on second machine → empty index → safe-degraded mode kicks in until rebuild from frontmatter scan.
- User natively renames/moves an imported note in Obsidian → vault listener updates index path; user deletes → listener removes index entry.
- v1.1 will need to *retroactively* migrate attachments for notes whose source is already in Recently Deleted. The `source_had_attachments` frontmatter field gives v1.1 a way to identify which imports need attention. **If v1.1 ships >30 days after a v1 import that had attachments, attachments are unrecoverable.** README must surface this so users understand the urgency.

## Domain Classification & Workflow Depth

- **Domain:** software
- **project_class:** system (TS plugin, external repo, build artifact)
- **Workflow:** four-phase (SPECIFY → PLAN → TASK → IMPLEMENT)

## Locked Decisions

| ID | Decision | Source |
|---|---|---|
| LD-01 | AppleScript via `osascript` (no SQLite/protobuf) | User, 2026-04-25 |
| LD-02 | Soft delete only — Recently Deleted (validated G1, 2026-04-25) | User, 2026-04-25 |
| LD-03 | macOS-only; `isDesktopOnly: true` | Inherited from LD-01 |
| LD-04 | Community-distributable from v1 | User, 2026-04-25 |
| LD-05 | Re-import gate: show disabled w/ "already imported" badge; toggle to override; re-import forces new unique filename | User, 2026-04-25 |
| LD-06 | Target folder: settings default + per-import override | User, 2026-04-25 |
| LD-07 | **Attachments NOT included in v1** — body-only import; attachment objects in source HTML dropped during conversion with markdown comment placeholder; soft-delete proceeds uniformly. README warns prominently about post-retention attachment loss. Attachment migration deferred to v1.1. | User, 2026-04-25 (revised post-G3-probe) |
| LD-08 | HTML→MD via turndown with Apple-Notes-aware pre-processor + custom node-filters; tiered warnings (severe blocks delete; moderate logs; debug-only in receipt log NOT note body) | User, 2026-04-25 |
| LD-09 | Frontmatter set: `source`, `apple_notes_id`, `apple_notes_account`, `apple_notes_folder`, `apple_notes_created`, `apple_notes_modified`, `imported_at`, `source_had_attachments` (count), `import_warnings` | User, 2026-04-25 (revised — `imported_attachments` removed; `source_had_attachments` added for v1.1 forward-compat) |

## Plugin Manifest (proposed for PLAN/IMPLEMENT)

```json
{
  "id": "applenotes-import",
  "name": "Apple Notes Import",
  "version": "0.1.0",
  "minAppVersion": "TBD — must resolve to concrete X.Y.Z before TASK lock (researched in OAI-002 against API surface)",
  "description": "Browse Apple Notes from inside Obsidian, selectively import notes' body markdown, and soft-delete the originals. macOS only. v1 does not migrate attachments.",
  "author": "Dan Turner",
  "authorUrl": "TBD",
  "isDesktopOnly": true
}
```

## Acceptance Criteria (project level)

A v1 release is accepted when **all** of the following hold:

- **AC1** — Modal lists Apple Notes responsively: first results / loading indicator within 2 seconds; complete listing for ~1k notes within 5–10s under typical conditions; locked / iCloud-shared / unreadable notes counted and explicitly labeled. **Threshold rule:** if A1 spike measures >5s for 1k, modal MUST use paginated/streamed loading; if >10s, return to PLAN risk review.
- **AC2** — A selected note is imported as a markdown file in the configured target folder with frontmatter exactly matching LD-09. `source_had_attachments` reflects the count from the source note (0 if none).
- **AC3** — Notes with attachments in the source are imported body-only; attachment objects in the converted HTML are replaced with `<!-- [v1: attachment dropped: <type-or-name>] -->` placeholders; the count is captured in `source_had_attachments` frontmatter and the receipt's `attachments_dropped` aggregate.
- **AC4** — A scripted integration test confirms: after a successful import, the source note is no longer in its original folder and appears in Apple Notes' Recently Deleted folder. Probe-based.
- **AC5** — Composite verify-before-delete (canonical sequence): pipeline runs `… write md → persist index → composite verify → soft-delete → append receipt`. Verify covers (a) md exists, (b) md content matches expected pre-write hash, (c) index entry persisted and JSON-roundtrip readback succeeds with structural shape match. Any failure aborts delete; source remains in Apple Notes; receipt marks errored. Adversarial tests inject partial-write and index-failure to prove the gate holds.
- **AC6** — Re-opening the modal after an import shows imported notes as disabled with "already imported on YYYY-MM-DD" badge by default. Toggling "show already-imported" enables their checkboxes for re-selection. Native vault rename/delete of an imported file updates/removes the index entry via `vault.on('rename')` / `vault.on('delete')` listeners. Index corruption triggers safe-degraded mode (delete-capable imports disabled until repaired). Repair conflict policy enforced.
- **AC7** — On a non-macOS desktop OR mobile, `onload()` performs early-return BEFORE any side effects: no commands registered, no ribbon icon, no settings tab. A single Notice "Apple Notes Import: macOS only" emits once per install/version.
- **AC8** — On TCC denial (probed on first user-initiated command, NOT on plugin load; settings "Re-check permission" button also counts as a probe), plugin surfaces in-app guidance and disables import/delete commands until permission is granted. Denial detection works for known stderr patterns (-1743 / -10000 / `Not authorized to send Apple events`), with timeout fallback for hangs and generic-error fallback for unmatched.
- **AC9** — Submission requirements pass: `isDesktopOnly: true`, no committed `main.js`, no `innerHTML` with user input, `instanceof` adapter checks, `normalizePath` on user paths, `registerEvent`/`registerDomEvent`/`registerInterval` for all listeners, `styles.css` committed and shipped, no plugin-name prefix in command names. `eslint-plugin-obsidianmd` runs clean. **Release asset inspection:** the published zip contains exactly `manifest.json`, `main.js`, `styles.css` and excludes source maps, tests, and dev files.
- **AC10** — Per-batch receipt markdown is written, listing imported / imported-not-deleted / skipped / errored notes with reasons, plus an aggregate `attachments_dropped` count for the batch; imported paths emitted as wikilinks. Receipt filename collisions resolved with timestamp suffix. Receipt-write failure post-delete logs to console + Notice; does not roll back the soft-delete.
- **AC11** — Batch transaction: per-note independence — a note-level failure aborts only that note's delete, never the batch. Notes execute **sequentially**. Cancel-after-current observed only between note transactions; once a note enters verify→delete it runs to completion. Final summary dialog presents imported / imported-not-deleted / skipped / errored counts.
- **AC12** — README documents prominently: (a) v1 imports body markdown only; (b) source attachments are NOT migrated and ARE lost after Apple's Recently Deleted retention expires; (c) `source_had_attachments` frontmatter identifies notes that had attachments, for v1.1 retroactive migration; (d) v1.1 must run before retention expires for any imports of interest. Confirm dialog also warns when any selected note has attachments.

## Task Decomposition

Tasks scoped ≤5 file changes each. Risk: low | medium | high. Each task ID prefixed `OAI-`. Critical-path tasks (data-safety) bolded. Task count: **25** (was 27 in rev 3; OAI-008a/008b removed).

### M1 — Foundation

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| OAI-001 | Repo build scaffold | 4 (`package.json`, `tsconfig.json`, `esbuild.config.mjs`, `eslint.config.mjs`) | low | #code | — | `npm install && npm run build` produces `main.js`; `npm run lint` exits 0. `eslint-plugin-obsidianmd` pinned (PLAN decision: `0.1.9` template default or `0.2.4` latest) |
| OAI-002 | Plugin skeleton + minAppVersion research + platform-gate early-return | 3 (`manifest.json`, `versions.json`, `src/main.ts`) | low | #code, #research | OAI-001 | Plugin loads in test vault; `onunload` clean (no leaked listeners). minAppVersion researched against API surface (`Platform`, `vault.create`, `normalizePath`, `FileSystemAdapter`, `containerEl.createEl`, `vault.on('rename')`, `vault.on('delete')`) and **set to a concrete `X.Y.Z` value before TASK lock**. `onload()` early-returns on `Platform.isMobile === true` OR `!Platform.isMacOS` BEFORE any side effects |
| OAI-003 | Settings tab + path validation + Re-check button | 2 (`src/settings.ts`, `src/main.ts` wiring) | low | #code | OAI-002 | All v1 settings present (target folder, receipts folder, show-already-imported default, dry-run default, debug-mode toggle); paths normalized + validated on save; persist across reload. "Re-check permission" button wired as user-initiated TCC probe |

### M2 — AppleScript bridge

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| OAI-004 | osascript runner | 2 (`src/applescript/runner.ts`, test) | medium | #code | OAI-001 | Wraps `child_process.execFile`; surfaces stderr, timeout, exit code; unit-tested with a fixture script |
| OAI-005 | List notes script + parser | 2 (`src/applescript/list-notes.applescript`, `src/applescript/list-notes.ts`) | medium | #code | OAI-004 | Returns `[{id, name, account, folder, created, modified, attachmentCount, isLocked}]`. `attachmentCount` is informational (drives modal badge); locked notes flagged with `isLocked: true`. Note handles addressed by id (not name) per probe-derived implementation note 1 |
| OAI-006 | Fetch note body script + parser | 2 | medium | #code | OAI-004 | Returns `{id, name, account, folder, created, modified, bodyHtml, attachmentCount}`. Locked notes return `{skipped: 'locked'}`. Parser tolerates fragment HTML and malformed input |
| **OAI-007** | **Soft-delete script + wrapper** | 2 | **high** | #code | OAI-004 | Already-validated G1 (2026-04-25); task implements production-quality wrapper. Acceptance: deleted note appears in Recently Deleted within 2s; integration test re-runs the G1 probe pattern. Note handles by id |

### M3 — Conversion & vault writes

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| OAI-009 | HTML→Markdown converter (Apple-Notes-aware, attachment-dropping) | 3 (`src/convert/preprocess.ts`, `src/convert/html-to-md.ts`, golden-output tests) | medium | #code | OAI-006 | Pre-processing layer normalizes Apple-Notes-specific HTML (checklist objects, Apple-specific spans/divs) BEFORE turndown. Turndown configured with custom node-filters that **catch** unknown tags. **Attachment objects (any element matching attachment shape: image, file ref, drawing canvas, audio, video, web bookmark) are dropped and replaced with `<!-- [v1: attachment dropped: <type-or-name>] -->` markdown comment**; counted toward `source_had_attachments` and `import_warnings.attachments_dropped`. Headings, lists, links, bold/italic, GFM tables, code blocks, GFM checklists round-trip. Severe-tier escalation: substantive body content cannot be represented (e.g., table collapses to empty). Golden tests use ≥10 representative inputs (synthesizable + any captured Apple Notes HTML available) |
| OAI-010 | Filename sanitizer + collision policy | 1 + tests | low | #code | — | `normalizePath`; sanitizer strips macOS+Obsidian-illegal characters; collision policy: title→sanitized name; suffix `-2`, `-3`, … on collision; index stores canonical chosen path; re-import override creates new unique file (never overwrite silently) |
| OAI-011 | Vault writer (markdown only) | 2 (`src/vault/writer.ts`, frontmatter helper) | medium | #code | OAI-009, OAI-010 | Creates target folder idempotently; writes markdown via `app.vault.create`; frontmatter matches LD-09 exactly (incl. `source_had_attachments`). Captures **expected pre-write content hash** (used by OAI-016b verify gate). **No binary writes in v1.** |

### M4 — Import index

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| **OAI-012** | **Import index store (corruption-resilient + vault-sync)** | 2 (`src/index/import-index.ts`, tests) | **high** | #code | OAI-002 | Persists `{appleNotesId → {vaultPath, contentHash, importedAt, untrusted?: bool}}` via plugin `data.json`; **secondary key**: content hash, used to detect collisions — flag, do not silently re-import. **Vault listeners**: registers `app.vault.on('rename')` (update path) and `app.vault.on('delete')` (remove entry) via `registerEvent`. **Readback contract**: `JSON.parse(written)` round-trips losslessly AND structural shape matches expected schema. **Corruption recovery: safe-degraded mode** — on parse error, plugin disables delete-capable imports, surfaces Notice with "Repair" action. Repair scans vault frontmatter for `apple_notes_id` (default scoped to configured import folder; configurable to whole-vault); progress indicator if scan exceeds 2s. **Repair conflict policy**: duplicate `apple_notes_id` → ambiguous (delete disabled until resolved); missing path → drop entry + log; frontmatter/hash mismatch → rebuild with current path but mark `untrusted: true`; repair report appended to receipt. Never silently treats corruption as empty |

### M5 — Modal UI

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| OAI-013 | Notes modal | 2 (`src/ui/NotesModal.ts`, `styles.css`) | medium | #code | OAI-005, OAI-006, OAI-012 | Lists notes (account/folder columns, search, filter); checkbox multi-select; preview snippet from body fetch; target-folder picker; dry-run toggle; "show already-imported" toggle (visibility AND checkbox-enable). Already-imported notes disabled by default with badge. **Notes with attachments shown with informational badge `(N attachments — body only)`; selectable as normal.** Constructed via `createEl`, no `innerHTML`. **`styles.css` committed in repo with at least 3-4 minimal selectors (modal table, row-disabled state, badge), included in release zip.** **If A1 probe shows >5s for 1k notes, modal uses paginated/streamed loading.** Cancel-after-current control during execution. May be developed with mock data |
| OAI-014 | Confirm-delete modal | 1 | medium | #code | OAI-013 | Lists N notes about to import + soft-delete, explicit "moved to Recently Deleted in Apple Notes" copy. **If any selected note has `attachmentCount > 0`, also displays: "X of these notes have attachments which will be lost after Apple's Recently Deleted retention expires."** Requires confirm click |
| OAI-015 | Command + ribbon wiring | 1 (`src/main.ts`) | low | #code | OAI-013, OAI-014, OAI-019 | "Browse Apple Notes" command palette entry; ribbon icon launches modal. Commands and ribbon registered ONLY when `Platform.isMacOS === true`; TCC probe runs on first command invocation per OAI-019 |

### M6 — Import orchestrator (safety-critical, split per round-1; boundaries tightened per round-2; simplified per rev 4)

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| **OAI-016a** | **Import transaction model + sequencing (orchestration only)** | 2 (`src/import/transaction.ts`, tests) | **high** | #code | OAI-006, OAI-011, OAI-012 | Defines and implements the canonical pipeline order per note: `fetch → convert → write markdown → persist index → invoke verify (OAI-016b) → invoke delete-gate (OAI-016c) → append receipt`. Receipt append is **NOT** a delete gate. Sequencing is the primary safety control. **Function contract:** `runNoteTransaction(note) → {status, errorReason?}` where `status ∈ {imported, imported-not-deleted, skipped, errored}`. 016a does NOT implement verify rules — those live in 016b. 016a does NOT invoke delete directly — that's gated by 016c |
| **OAI-016b** | **Composite verify implementation (pure verification)** | 2 (`src/import/verify.ts`, adversarial tests) | **high** | #code | OAI-011, OAI-012 | **Function contract:** `verifyImport(expectations) → {ok: boolean, failures: string[]}`. Verify covers: (1) md exists, (2) md content matches expected pre-write hash (NOT a self-hash), (3) index entry JSON-roundtrips losslessly with structural shape match. No side effects beyond reads. Adversarial tests inject mocked partial-write and index-failure to prove the function returns `ok: false` correctly |
| **OAI-016c** | **Soft-delete gate execution** | 1 (`src/import/delete-gate.ts`) | **high** | #code | OAI-007, OAI-016b | **Function contract:** `executeDeleteIfVerified(noteId, verifyResult) → {deleted: boolean, abortReason?}`. Gates the actual `osascript` delete call behind `verifyResult.ok === true`. On `verifyResult.ok === false`, returns abort-with-reason without ever invoking delete. Integration test: contrived verify-failure → confirms delete-not-called via spy |
| **OAI-016d** | **Batch execution + cancellation + progress** | 2 (`src/import/batch.ts`, UI wiring) | high | #code | OAI-016a..c, OAI-013 | **Sequential execution** — await each note's pipeline before starting the next. Per-note independence. **Cancel-after-current**: observed only between note transactions; once a note enters verify→delete it runs to completion. Progress updates streamed to modal. Final summary dialog: imported / imported-not-deleted / skipped / errored counts + aggregate `attachments_dropped` |
| OAI-016e | Receipt log writer | 1 (`src/import/receipt.ts`) | low | #code | OAI-016d | Per-batch markdown written to receipts folder with imported / imported-not-deleted / skipped / errored sections + aggregate `attachments_dropped` line. Imported paths use `[[wikilinks]]`; skipped/errored entries have plain-text reason. Receipt filename collision → timestamp suffix. **Receipt-write failure**: logs to console + Notice; does NOT roll back the soft-delete |

### M7 — Permission & platform UX

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| OAI-019 | TCC permission probe + handler | 2 (`src/permissions/tcc.ts`, README guidance) | medium | #code | OAI-004 | Probe runs **on first user-initiated command invocation** (NOT plugin load). Settings-tab "Re-check permission" button is also a user-initiated probe. Denial detection: parse stderr for `Not authorized to send Apple events`, error codes -1743 / -10000; timeout fallback (treat as probable denial); generic-error fallback (don't auto-disable on unmatched). On confirmed denial: in-app Notice + settings-tab guidance directs user to System Settings → Privacy → Automation → Obsidian → Notes; commands disabled until granted |
| OAI-020 | Platform gate (no UI registration off-platform) | 1 (`src/main.ts`) | low | #code | OAI-002 | `Platform.isMacOS === false` OR `Platform.isMobile === true` → `onload()` performs early-return BEFORE any side effects. Single Notice "Apple Notes Import: macOS only" emits **once per install/version** (de-dup via stored marker) |

### M8 — Distribution

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| OAI-021 | README, LICENSE, screenshots | 3 | low | #writing | M6 + M7 complete | README documents: permission flow, soft-delete semantics + Recently Deleted retention, frontmatter fields (incl. `apple_notes_id` privacy notice prominent), **prominent v1-attachment-loss warning** per AC12, known limitations, manual install steps, TCC troubleshooting section, macOS-only banner. LICENSE chosen (MIT or 0-BSD). ≥2 screenshots reflecting current UI |
| OAI-022 | Release workflow + asset inspection | 1 (`.github/workflows/release.yml`) | medium | #code | OAI-021 | Tag push → builds → attaches `main.js`, `manifest.json`, `styles.css` to GitHub release. Manifest fields match release tag/version. `.gitignore` excludes `main.js` + dev artifacts. **Release asset inspection step** (in workflow): zip contains exactly `manifest.json`, `main.js`, `styles.css`; fails if extra files detected. Submission self-critique checklist runs clean |
| OAI-023 | Community submission PR | 1 (community-plugins.json entry, separate fork) | low | #writing | OAI-022 | Submission PR drafted against `obsidianmd/obsidian-releases`; submission self-critique checklist run clean |

### Task Dependency Summary

```
M1: OAI-001 → 002 → 003

M2: OAI-004 ─┬─→ 005
             ├─→ 006
             └─→ 007

M3: 006 ──→ 009
    010 (independent)
    009 + 010 ──→ 011

M4: 002 ──→ 012

M5: 005, 006, 012 ──→ 013 → 014
M7-OAI-019: 004 ──→ 019  (parallel to M5)
            015 needs 013, 014, AND 019

M6: 006, 011, 012 ──→ 016a
    011, 012 ──→ 016b
    007, 016b ──→ 016c
    016a..c, 013 ──→ 016d → 016e

M7-OAI-020: 002 ──→ 020 (parallel to M5/M6)

M8: M6 + M7 complete ──→ 021 → 022 → 023
```

## Risk Register (project level)

| Risk | Severity | Mitigation |
|---|---|---|
| ~~AppleScript hard-delete instead of soft-delete~~ | ✅ **Cleared** | G1 validated 2026-04-25 (macOS 26.3.1) |
| ~~Note id instability across restart/edit/move~~ | ✅ **Cleared** | G2 validated 2026-04-25 |
| Composite verify-before-delete gate weakly enforced | **Critical** | OAI-016b dedicated task with adversarial tests for partial-write / index-failure; sequencing is primary safety control. Simpler scope post rev 4 (md + index, no attachments) → smaller failure surface |
| Index corruption causes silent re-import / data confusion | **Critical** | OAI-012 safe-degraded mode + frontmatter rebuild + repair conflict policy |
| Mid-batch failure cascades / partial source loss | High | OAI-016d per-note independence + sequential execution + final summary |
| TCC denial silently locks users out | High | OAI-019 first-command probe + structured denial detection + manual re-check |
| Index silently desyncs from vault on native rename/delete | High | OAI-012 vault.on('rename') / vault.on('delete') listeners |
| User trust erosion from undocumented attachment loss | High | AC12 — README + confirm-dialog explicit warning; `source_had_attachments` frontmatter field for v1.1 retroactive migration |
| AppleScript performance kills modal UX on large libraries | Medium | A1 probe in PLAN; if >5s for 1k, OAI-013 pagination contingency triggers; >10s → PLAN risk review |
| turndown drops formatting users care about | Medium | Apple-Notes-aware pre-processor + custom node-filters; golden tests; severe-tier blocks delete |
| v1.1 attachment migration ships >30d after a v1 import → attachments unrecoverable | Medium | README warns; project-level commitment to ship v1.1 within 30 days of v1 release for attachment-bearing imports OR document that v1 is body-only-permanent for users who can't wait |
| Submission rejected on first community-plugin review | Low | Distribution checklist + release asset inspection in OAI-022; lint with `eslint-plugin-obsidianmd` from day 1 |
| Apple Notes HTML changes break converter post-release | Low | Pin turndown; golden tests; docs link for users to file repro issues |

## Spec Scope Classification

**MAJOR.** New system, new external repo, destructive operations against a third-party app, community-distribution gate. Two rounds of peer review applied (round 1: 10+18 actions; round 2: 15+14 actions). Pre-PLAN probe phase (G1, G2, G3-deferred-to-v1.1) reduced scope by removing attachment migration. **All pre-PLAN gates resolved; SPECIFY artifact frozen at revision 4; ready for PLAN.**
