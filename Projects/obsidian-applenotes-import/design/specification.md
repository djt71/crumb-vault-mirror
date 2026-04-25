---
project: obsidian-applenotes-import
domain: software
type: specification
skill_origin: systems-analyst
created: 2026-04-25
updated: 2026-04-25
revision: 2
revision_history:
  - rev: 1
    date: 2026-04-25
    note: Initial SPECIFY output
  - rev: 2
    date: 2026-04-25
    note: Round-1 peer-review revision pass — applied 10 must-fix and 18 should-fix actions; A4 probe validated
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

| Gate | Status | Evidence |
|---|---|---|
| **G1 / A4** — AppleScript `delete` on Notes is soft-delete (Recently Deleted), not hard-delete | ✅ **VALIDATED 2026-04-25** | osascript probe + raw output archived at [`design/probes/a4-soft-delete.applescript`](probes/a4-soft-delete.applescript) and [`design/probes/a4-probe-result.md`](probes/a4-probe-result.md). Re-validate at IMPLEMENT if macOS major version changes (baseline: 26.3.1). |
| **G2 / A2** — Note `id` is stable across Notes app restart, edit-after-restart, and folder move | ⏳ Pending | Probe to be authored and run before PLAN. Must cover: restart, post-restart edit, move between folders, iCloud↔On-My-Mac account where available. |
| **G3 / A7** — Attachment extraction approach decision (AppleScript export vs. Group Container filesystem cache) | ⏳ Pending | OAI-008a runs the dual probe + decision; criteria in §Task Decomposition. Filesystem-cache approach may require Full Disk Access — flag if so. |
| **G4** — Citations pinned in [`design/research-brief-plugin-platform.md`](research-brief-plugin-platform.md) | ⏳ Pending | Add source URLs + commit SHAs for: (a) "no-obsidian-in-id" submission rule, (b) `eslint-plugin-obsidianmd` version, (c) sample-plugin template HEAD. |

PLAN does not begin until **G2, G3, G4 resolve**. If G2 or G3 fail, return to SPECIFY for revision (e.g., G3 failure may require dropping attachments from v1 or adding Full Disk Access permission flow).

## Facts

Sourced from [`design/research-brief-plugin-platform.md`](research-brief-plugin-platform.md) (verified against `obsidianmd/obsidian-developer-docs` and `obsidianmd/obsidian-sample-plugin` template on 2026-04-25; citations pending pin per G4):

- Plugin id in `manifest.json` cannot contain the substring "obsidian" → proposed id `applenotes-import`.
- `isDesktopOnly: true` is required; we use NodeJS `child_process` to invoke `osascript`.
- `main.js` is a build artifact; must not be committed (release-only).
- `app.vault.create`, `app.vault.createBinary`, `app.vault.createFolder` (errors if folder exists), `normalizePath` are the relevant vault APIs.
- DOM construction must use `containerEl.createEl` etc.; `innerHTML`/`outerHTML` with user input is a submission reject.
- Adapter type checks must use `instanceof FileSystemAdapter` (no casting).
- `registerEvent` / `registerDomEvent` / `registerInterval` are required for cleanup.
- `eslint-plugin-obsidianmd` is the official lint plugin and is in the current sample template (version pinning pending G4).
- `styles.css` is a first-class plugin asset: committed in repo, included in release zip alongside `main.js` and `manifest.json`.
- AppleScript `delete` against an Apple Notes note moves it to Apple Notes' Recently Deleted folder — **empirically validated G1 on 2026-04-25**. The user has confirmed that this soft-delete behavior (not hard-delete) is the desired semantics for v1; the probe confirms the behavior matches.

## Assumptions (Pre-PLAN gating + PLAN spike)

Each assumption is paired with the cheapest validation we can perform. **Pre-PLAN gating** assumptions block PLAN entry; **PLAN spike** assumptions can be validated during PLAN's spike phase.

### Pre-PLAN gating (block PLAN entry)

- **A2** (Pre-PLAN, see G2) — `id of note` is stable across Notes app restart, post-restart edit, and folder move.
- **A4** ✅ **VALIDATED 2026-04-25** — AppleScript `delete` lands in Recently Deleted, not hard-delete.
- **A7** (Pre-PLAN, see G3) — Attachment extraction is feasible with acceptable reliability via AppleScript export OR filesystem cache (decision in OAI-008a).

### PLAN spike (validate during PLAN, before TASK lock)

- **A1** — `tell application "Notes" to get every note` returns within ≤10s for ~1k notes. Validate: time the probe; if >10s, design must include async streaming/paginated list rather than block-on-all.
- **A3** — `body of note` returns HTML reliably; attachments are referenced as inline objects extractable separately. Validate: probe one note with image and one with sketch; inspect HTML structure.
- **A5** — TCC Automation permission denial returns recognizable error codes (e.g., `-1743`, `-10000`) or characteristic stderr text (`Not authorized to send Apple events`). Validate: trigger denial path on a test machine via `tccutil reset AppleEvents`; capture exact stderr/exit code.
- **A6** — Locked notes appear in `every note` but `body` raises an AppleScript error. Validate: probe a locked note; confirm error pattern.

## Unknowns (carried into PLAN)

- AppleScript performance ceiling for "list 1000+ notes" → drives whether the modal needs virtualized scrolling and pagination. If A1 spike shows >5s for 1k, OAI-013 MUST use paginated/streamed loading.
- Behavior of the Notes id under iCloud account-switching → mitigated by content-hash secondary key in import index (see OAI-012 revision).
- Whether `eslint-plugin-obsidianmd` rules conflict with our preferred TypeScript style; resolve in PLAN.

## System Map

### Components

- **Apple Notes** (external macOS app) — the source-of-truth for unmigrated notes; accessed only via AppleScript.
- **AppleScript bridge** — small `.applescript` files plus a TS runner (`child_process.execFile osascript`) that returns JSON-shaped strings parsed in TS.
- **Conversion layer** — Apple-Notes-specific HTML pre-processor → `turndown` (with custom node-filters that *catch* unknown tags rather than silently drop) → markdown. Pre-processor handles checklist objects, attachment object placeholders, and Apple-specific spans/divs. Tested with fixtures from real captured Apple Notes HTML, not synthetic input.
- **Attachment extractor** — pulls binary attachments to `_attachments/apple-notes/` (or configured folder) and rewrites `<img>` / link references in the converted markdown. Handles per-attachment-type (image, PDF, audio, drawing/sketch, scanned doc, web bookmark) per the support matrix in §Task Decomposition.
- **Import index** — per-vault JSON in plugin `data.json` keyed by `apple_notes_id` AND content-hash (secondary key for collision/account-switch tolerance). Drives idempotency UX. **Corruption recovery: safe-degraded mode + frontmatter rebuild** — on parse error, plugin disables delete-capable imports until index is repaired or user explicitly chooses re-index, which scans vault frontmatter for `apple_notes_id` and reconstructs the index. Never silently treat corruption as empty.
- **Vault writer** — calls `app.vault.create` / `createBinary` / `createFolder`; assembles YAML frontmatter. Settings paths normalized + validated on save (reject empty/invalid; auto-create on first import).
- **Composite verify-before-delete gate** — before any AppleScript `delete` fires, ALL of the following must succeed: (1) markdown file exists, (2) markdown content matches the **expected pre-write hash** (not a self-hash), (3) all expected attachment files exist with non-zero size, (4) all rewritten markdown attachment references resolve to existing files, (5) import index has been persisted and read-back succeeds. Failure of any step aborts delete and marks the note errored in the receipt; the source remains in Apple Notes.
- **Batch transaction model** — multi-select imports use **per-note independence**: each note proceeds through its own pipeline (fetch→convert→write→verify→index→delete); a single note's failure aborts only *that* note's delete, never propagates to the batch. After all notes complete, a final summary dialog reports imported / imported-not-deleted / skipped / errored counts. The modal exposes a **cancel-after-current** control during execution.
- **Modal UI** — table of notes with checkboxes, search, account/folder filter, target-folder picker, dry-run toggle, "show already-imported" toggle. If A1 probe shows >5s for 1k notes, modal MUST use paginated/streamed loading.
- **Confirm dialog** — final approval listing N notes about to import + soft-delete, with explicit "Notes will be moved to Recently Deleted in Apple Notes" copy.
- **Receipt log** — per-batch markdown file in a configurable receipts folder summarizing what was imported, skipped, deleted, errored, and any conversion warnings. Imported note paths emitted as wikilinks for clickability. Receipt filename collisions handled with timestamp suffix.
- **Settings tab** — defaults for target folder, attachments folder, receipts folder, "show already-imported" default, dry-run default, debug-mode toggle (controls inline warning verbosity).
- **TCC handler** — probes on **first user-initiated command invocation** (NOT plugin load); on denial captured by stderr-pattern match or timeout, surfaces in-app guidance + settings-tab guidance. Denial-detection contract: parse stderr for known patterns (`Not authorized to send Apple events`, error codes -1743/-10000); timeout fallback for hang case; generic-error fallback for unmatched.
- **Platform gate** — runtime `Platform.isMacOS` check at plugin load. On non-macOS desktop OR mobile, plugin **does not register commands at all** (cleaner than registering inert commands); a single Notice "macOS only" emits at load.

### Conversion warning tiers (composite verify input)

| Tier | Trigger | Behavior |
|---|---|---|
| **Severe** | Required attachment failed to extract; markdown reference would be broken | **Blocks delete.** Note marked errored in receipt; source remains in Apple Notes. |
| **Moderate** | Unsupported HTML element encountered (e.g., complex sketch); content best-effort converted | Logged in receipt + frontmatter `import_warnings: [...]`. Delete still proceeds. |
| **Debug-only** | Detailed conversion telemetry, including raw source HTML for unsupported elements | Inline in note body **only when debug mode setting is on** (off by default, to keep imported notes clean). |

### Dependencies

- **Inbound:** macOS, Apple Notes app, TCC Automation grant, Electron-bundled Node, Obsidian ≥ minAppVersion (researched in OAI-002 against API surface: `Platform`, `vault.createBinary`, `normalizePath`, `FileSystemAdapter`, `containerEl.createEl`).
- **External libs:** `turndown` (HTML→MD; small, MIT). Custom node-filters required to capture unknown tags. Possibly `sanitize-html` if turndown's input handling proves insufficient (decide in PLAN).
- **Outbound (eventual):** `obsidianmd/obsidian-releases` PR for community-plugin directory submission.

### External code repo

YES — already initialized at `~/code/obsidian-applenotes-import/` (commit `4bd59d9`). `repo_path` and `build_command` recorded in `project-state.yaml`. Decision-doc location for OAI-008a is **repo-local** (`design/decisions/` inside the plugin repo), NOT `_system/docs/solutions/`.

### Constraints

- Hard: macOS-only; `isDesktopOnly: true`; AppleScript performance ceiling; no `innerHTML` with user input; no committed `main.js`; plugin id can't contain "obsidian"; no command name prefixed with plugin name (Obsidian prefixes automatically); `styles.css` committed and shipped.
- Soft: AppleScript latency degrades the UX above ~1k notes; rich-content fidelity in turndown is best-effort even with custom node-filters.
- Regulatory: none.

### Levers (high-leverage intervention points)

1. **Composite verify-before-delete contract.** Single point determining data-loss risk. Now covers md + attachments + index, not just md.
2. **Sequencing as primary safety control.** Even if the verify gate has bugs, the strict order (write → verify → persist index → delete) constrains the blast radius.
3. **Import index integrity + rebuild path.** Single point determining whether re-import is correctly gated. Loss/corruption now triggers safe-degraded mode + frontmatter-scan rebuild instead of silent reset.
4. **Body-conversion fidelity tier (with severe→delete-block).** Single point determining "does this feel like a useful migration tool or like a lossy copy"? Severe omissions block delete; moderate are logged.
5. **TCC failure UX.** First-command probe (not load probe) avoids unexpected prompts; structured denial detection avoids silent lockout.
6. **Submission compliance.** Single point determining whether v1 ships to the community directory or has to be revised post-review.

### Second-Order Effects

- If composite verify is loose, users lose source data — single highest-impact failure mode.
- Recently Deleted in Apple Notes auto-purges per Apple's standard retention; soft delete is a bounded recovery window, not permanent.
- AppleScript Notes queries can stall the UI on first-run for huge libraries; A1 spike result drives whether modal uses pagination/streaming.
- Frontmatter `apple_notes_id` exposes a CoreData URI; users sharing vaults will leak their machine's identifier. Documented prominently in README. Hashed-id alternative deferred to v1.1.
- Building a turndown pipeline creates maintenance gravity if Apple Notes' HTML evolves; pin turndown version, write golden-output tests using captured real-world fixtures.
- Index lives in plugin `data.json` (per-vault, not synced across Obsidian installs). Vault sync across machines + plugin reinstall on second machine → empty index → safe-degraded mode kicks in until rebuild from frontmatter scan.

## Domain Classification & Workflow Depth

- **Domain:** software
- **project_class:** system (TS plugin, external repo, build artifact)
- **Workflow:** four-phase (SPECIFY → PLAN → TASK → IMPLEMENT)
- **Rationale:** Code project with destructive operations against a third-party app, ≥3 vault/repo files, community-distribution gate. PLAN earns its keep particularly because A1/A3/A5/A6 spikes burn down assumption risk before TASK locks scope; A2/A4/A7 are gated pre-PLAN because their failure forces spec revision, not design adjustment.

## Locked Decisions (carried in from pre-SPECIFY)

| ID | Decision | Source |
|---|---|---|
| LD-01 | AppleScript via `osascript` (no SQLite/protobuf) | User, 2026-04-25 |
| LD-02 | Soft delete only — Recently Deleted (validated G1, 2026-04-25) | User, 2026-04-25 |
| LD-03 | macOS-only; `isDesktopOnly: true` | Inherited from LD-01 |
| LD-04 | Community-distributable from v1 | User, 2026-04-25 |
| LD-05 | Re-import gate: show disabled w/ "already imported" badge; toggle to override | User, 2026-04-25 (Q1) |
| LD-06 | Target folder: settings default + per-import override | User, 2026-04-25 (Q2) |
| LD-07 | Attachments included in v1, extracted to configurable folder | User, 2026-04-25 (Q3) |
| LD-08 | HTML→MD via turndown, best-effort with tiered warnings (severe blocks delete; moderate logs; debug-only inline) | User, 2026-04-25 (Q4 + round-1 review) |
| LD-09 | Frontmatter set: `source`, `apple_notes_id`, `apple_notes_account`, `apple_notes_folder`, `apple_notes_created`, `apple_notes_modified`, `imported_at`, `imported_attachments`, `import_warnings` | User, 2026-04-25 (Q5 + round-1 review added `import_warnings`) |

## Plugin Manifest (proposed for PLAN/IMPLEMENT)

```json
{
  "id": "applenotes-import",
  "name": "Apple Notes Import",
  "version": "0.1.0",
  "minAppVersion": "TBD — researched in OAI-002 against API surface",
  "description": "Browse Apple Notes from inside Obsidian, selectively import notes (with attachments) as markdown, and soft-delete the originals.",
  "author": "Dan Turner",
  "authorUrl": "TBD",
  "isDesktopOnly": true
}
```

`fundingUrl` deliberately omitted (per submission rules: only include if accepting donations). `styles.css` shipped alongside `main.js` and `manifest.json` in release assets.

## Acceptance Criteria (project level)

A v1 release is accepted when **all** of the following hold:

- **AC1** — Modal lists Apple Notes responsively: first results / loading indicator within 2 seconds; complete listing for ~1k notes within 5–10s under typical conditions; locked / iCloud-shared / unreadable notes counted and explicitly labeled. If A1 spike shows >5s for 1k, modal uses paginated/streamed loading.
- **AC2** — A selected note is imported as a markdown file in the configured target folder with frontmatter exactly matching LD-09.
- **AC3** — Attachments are extracted and linked from the markdown; rendered note in Obsidian shows attachments inline where Apple Notes did, for the support-matrix-defined types (image, PDF, audio, drawing/sketch, scanned doc, web bookmark). Severe omissions block delete (AC5).
- **AC4** — A scripted integration test confirms: after a successful import, the source note is no longer in its original folder and appears in Apple Notes' Recently Deleted folder. Probe-based, not inferred from behavior.
- **AC5** — Composite verify-before-delete: (a) markdown exists and content matches expected pre-write hash; (b) all expected attachment files exist with non-zero size; (c) all rewritten markdown attachment references resolve; (d) import index persisted and read-back succeeds. Any failure aborts delete; source note remains in Apple Notes; receipt marks it errored. Adversarial tests injecting partial-write, attachment-failure, and index-failure scenarios prove the gate holds.
- **AC6** — Re-opening the modal after an import shows imported notes as disabled with "already imported on YYYY-MM-DD" badge by default. Index corruption triggers safe-degraded mode (delete-capable imports disabled until repaired).
- **AC7** — On a non-macOS desktop OR mobile, plugin loads without registering commands; emits a single Notice "macOS only".
- **AC8** — On TCC denial (probed on first user-initiated command, NOT on plugin load), plugin surfaces in-app guidance and disables import/delete commands until permission is granted. Denial detection works for known stderr patterns (-1743 / -10000 / `Not authorized to send Apple events`), with timeout fallback for hangs and generic-error fallback for unmatched.
- **AC9** — Submission requirements pass: `isDesktopOnly: true`, no committed `main.js`, no `innerHTML` with user input, `instanceof` adapter checks, `normalizePath` on user paths, `registerEvent`/`registerDomEvent`/`registerInterval` for all listeners, `styles.css` committed and shipped, no plugin-name prefix in command names. `eslint-plugin-obsidianmd` runs clean.
- **AC10** — Per-batch receipt markdown is written, listing imported / imported-not-deleted / skipped / errored notes with reasons; imported paths emitted as wikilinks. Receipt filename collisions resolved with timestamp suffix.
- **AC11** — Batch transaction: per-note independence — a note-level failure aborts only that note's delete, never the batch. Cancel-after-current control available during execution. Final summary dialog presents imported / imported-not-deleted / skipped / errored counts. If md writes but attachments fail, md is left in vault and marked errored; incomplete attachment temp directories are cleaned up.

## Task Decomposition

Tasks scoped ≤5 file changes each except where noted. Risk: low | medium | high. Each task ID prefixed `OAI-`. Dependencies expressed in **Depends** column. Critical-path tasks (data-safety) bolded.

### M1 — Foundation

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| OAI-001 | Repo build scaffold | 4 (`package.json`, `tsconfig.json`, `esbuild.config.mjs`, `eslint.config.mjs`) | low | #code | — | `npm install && npm run build` produces `main.js`; `npm run lint` exits 0 |
| OAI-002 | Plugin skeleton + minAppVersion research | 3 (`manifest.json`, `versions.json`, `src/main.ts`) | low | #code, #research | OAI-001 | Plugin loads in test vault; ribbon icon visible; `onunload` clean (no leaked listeners). minAppVersion researched against API surface (`Platform`, `vault.createBinary`, `normalizePath`, `FileSystemAdapter`, `containerEl.createEl`) and set to a concrete version (not "TBD") |
| OAI-003 | Settings tab + path validation | 2 (`src/settings.ts`, `src/main.ts` wiring) | low | #code | OAI-002 | All v1 settings present (target folder, attachments folder, receipts folder, show-already-imported default, dry-run default, debug-mode toggle); paths normalized + validated on save (reject empty/invalid; auto-create on first import); persist across reload |

### M2 — AppleScript bridge (validate Assumptions)

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| OAI-004 | osascript runner | 2 (`src/applescript/runner.ts`, test) | medium | #code | OAI-001 | Wraps `child_process.execFile`; surfaces stderr, timeout, exit code; unit-tested with a fixture script |
| OAI-005 | List notes script + parser | 2 (`src/applescript/list-notes.applescript`, `src/applescript/list-notes.ts`) | medium | #code | OAI-004 | Returns `[{id, name, account, folder, created, modified, attachmentCount, isLocked}]` for visible notes; locked notes listed with `isLocked: true` flag; import pipeline skips locked notes with explicit reason unless body fetch later succeeds |
| OAI-006 | Fetch note body script + parser | 2 | medium | #code | OAI-004 | Returns `{id, name, account, folder, created, modified, bodyHtml}`; locked notes return `{skipped: 'locked'}` instead of raising |
| **OAI-007** | **Soft-delete script + wrapper** | 2 | **high** | #code | OAI-004 | Already-validated G1 (2026-04-25); task implements the production-quality wrapper. Acceptance: deleted note appears in Recently Deleted within 2s; integration test re-runs the G1 probe pattern |
| **OAI-008a** | **Attachment extraction probe + decision (Pre-PLAN G3)** | 3 (`design/decisions/attachments.md`, dual-approach probe scripts) | **high** | #research, #decision | OAI-004 | Run dual probe: (i) AppleScript export, (ii) Group Container filesystem cache (`~/Library/Group Containers/group.com.apple.notes/Media/`). Evaluate against criteria: ≥95% reliability across image/PDF/audio/drawing/scan/bookmark types; no permission prompts beyond TCC Automation (or document Full Disk Access requirement); <2s/attachment; no stale temp files. Decision-doc archived **at repo-local `design/decisions/attachments.md`** (NOT `_system/docs/solutions/`). |
| **OAI-008b** | **Attachment extractor (implement winner)** | 3 (`list-attachments.applescript` or filesystem reader, `extract-attachment.ts`, tests) | **high** | #code | OAI-008a | Implements the chosen approach; extracts ≥95% of attachments by configured type matrix; binary written to vault attachments folder with correct extension; markdown reference uses relative path that resolves when rendered |

### M3 — Conversion & vault writes

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| OAI-009 | HTML→Markdown converter (Apple-Notes-aware) | 3 (`src/convert/preprocess.ts`, `src/convert/html-to-md.ts`, golden-output tests) | medium | #code | OAI-008a (HTML object shape) | Pre-processing layer normalizes Apple-Notes-specific HTML (checklist objects, attachment object placeholders, Apple-specific spans/divs) BEFORE turndown. Turndown is configured with custom node-filters that **catch** unknown tags (turndown silently drops them by default) and emit them as `> [!warning]` (moderate tier) or escalate to severe per the warning-tier matrix. Headings, lists, links, bold/italic, GFM tables, code blocks, GFM checklists round-trip. Golden tests use ≥10 representative inputs **captured from real Apple Notes**, not synthetic |
| OAI-010 | Filename sanitizer + collision policy | 1 + tests | low | #code | — | `normalizePath`; sanitizer strips macOS+Obsidian-illegal characters; collision policy: title→sanitized name; suffix `-2`, `-3`, … on collision; index stores canonical chosen path; re-import override creates new unique file (never overwrite silently) |
| OAI-011 | Vault writer | 2 (`src/vault/writer.ts`, frontmatter helper) | medium | #code | OAI-009, OAI-010 | Creates target/attachments folders idempotently; writes md and binary attachments; frontmatter matches LD-09 exactly. Captures **expected pre-write content hash** (used by OAI-016b verify gate). On md-written-but-attachments-failed: md left in vault, incomplete attachment temp dirs cleaned up |

### M4 — Import index

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| **OAI-012** | **Import index store (corruption-resilient)** | 2 (`src/index/import-index.ts`, tests) | **high** | #code | OAI-002 | Persists `{appleNotesId → {vaultPath, contentHash, importedAt}}` via plugin `data.json`; **secondary key**: content hash, used to detect collisions (e.g., iCloud account-switch yielding different ids for same content) — flag, do not silently re-import. Survives plugin reload. **Corruption recovery: safe-degraded mode** — on parse error, plugin disables delete-capable imports, surfaces Notice with "Repair" action. Repair scans vault frontmatter for `apple_notes_id` and reconstructs the index. Never silently treats corruption as empty |

### M5 — Modal UI

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| OAI-013 | Notes modal | 2 (`src/ui/NotesModal.ts`, `styles.css`) | medium | #code | OAI-005, OAI-006, OAI-012, OAI-019 | Lists notes (account/folder columns, search, filter); checkbox multi-select; preview snippet from body fetch; target-folder picker; dry-run toggle; "show already-imported" toggle; already-imported notes disabled by default with badge; constructed via `createEl`, no `innerHTML`. **`styles.css` committed in repo and included in release zip.** **If A1 probe shows >5s for 1k notes, modal uses paginated/streamed loading.** Cancel-after-current control available during execution |
| OAI-014 | Confirm-delete modal | 1 | medium | #code | OAI-013 | Lists N notes about to import + soft-delete, explicit "moved to Recently Deleted in Apple Notes" copy, requires confirm click |
| OAI-015 | Command + ribbon wiring | 1 (`src/main.ts`) | low | #code | OAI-013, OAI-014 | "Browse Apple Notes" command palette entry; ribbon icon launches modal. Commands registered ONLY when `Platform.isMacOS === true` (cleaner than registering inert commands on other platforms) |

### M6 — Import orchestrator (safety-critical, split per round-1 review)

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| **OAI-016a** | **Import transaction model + sequencing** | 2 (`src/import/transaction.ts`, tests) | **high** | #code | OAI-006, OAI-008b, OAI-011, OAI-012 | Defines and implements the strict pipeline order per note: fetch → convert → write attachments → write markdown → composite verify → persist index → verify index readback → soft-delete → append receipt. Receipt append is **NOT** a delete gate. Sequencing is the primary safety control — never call delete unless every prior step succeeded |
| **OAI-016b** | **Composite verify-before-delete contract** | 2 (`src/import/verify.ts`, adversarial tests) | **high** | #code | OAI-011, OAI-012, OAI-016a | Verify gate covers: (1) md exists, (2) md content matches expected pre-write hash (NOT a self-hash), (3) all expected attachment files exist with non-zero size, (4) all rewritten markdown attachment refs resolve, (5) index persisted + readback succeeds. Adversarial tests inject mocked partial-write, attachment-failure, and index-failure to prove the gate aborts delete and leaves source intact |
| **OAI-016c** | **Soft-delete gate execution** | 1 (`src/import/delete-gate.ts`) | **high** | #code | OAI-007, OAI-016b | Gates the actual `osascript` delete call behind verify success; on verify failure, returns abort-with-reason without ever invoking delete. Integration test: contrived verify-failure → confirms delete-not-called via spy |
| **OAI-016d** | **Batch execution + cancellation + progress** | 2 (`src/import/batch.ts`, UI wiring) | high | #code | OAI-016a..c, OAI-013 | Per-note independence: failure aborts only that note's pipeline, never propagates. Cancel-after-current honored. Progress updates streamed to modal. Final summary dialog: imported / imported-not-deleted / skipped / errored counts |
| OAI-016e | Receipt log writer | 1 (`src/import/receipt.ts`) | low | #code | OAI-016d | Per-batch markdown written to receipts folder with imported / imported-not-deleted / skipped / errored sections. Imported paths use `[[wikilinks]]`; skipped/errored entries have plain-text reason. Receipt filename collision → timestamp suffix |

### M7 — Permission & platform UX

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| OAI-019 | TCC permission probe + handler | 2 (`src/permissions/tcc.ts`, README guidance) | medium | #code | OAI-004, OAI-015 | Probe runs **on first user-initiated command invocation** (NOT plugin load). Denial detection: parse stderr for `Not authorized to send Apple events`, error codes -1743 / -10000; timeout fallback for hangs (treat as probable denial with manual-recheck affordance); generic-error fallback for unmatched (don't auto-disable). On confirmed denial: in-app Notice + settings-tab guidance directs user to System Settings → Privacy → Automation → Obsidian → Notes; commands disabled until granted; manual "Re-check permission" button in settings |
| OAI-020 | Platform gate (no command registration off-platform) | 1 (`src/main.ts`) | low | #code | OAI-002 | `Platform.isMacOS === false` (or mobile) → plugin loads but does NOT register commands; emits one Notice "macOS only" at load |

### M8 — Distribution

| ID | Title | Files | Risk | Tags | Depends | Acceptance |
|---|---|---|---|---|---|---|
| OAI-021 | README, LICENSE, screenshots | 3 | low | #writing | M6 + M7 complete | README documents: permission flow, soft-delete semantics + Recently Deleted retention, frontmatter fields (incl. `apple_notes_id` privacy notice prominent), known limitations, manual install steps, TCC troubleshooting section, macOS-only banner. LICENSE chosen (MIT or 0-BSD). ≥2 screenshots reflecting current UI |
| OAI-022 | Release workflow | 1 (`.github/workflows/release.yml`) | medium | #code | OAI-021 | Tag push → builds → attaches `main.js`, `manifest.json`, `styles.css` to GitHub release. Manifest fields match release tag/version. `.gitignore` excludes `main.js` + dev artifacts. Submission self-critique checklist (per research-brief §4) runs clean |
| OAI-023 | Community submission PR | 1 (community-plugins.json entry, separate fork) | low | #writing | OAI-022 | Submission PR drafted against `obsidianmd/obsidian-releases`; submission self-critique checklist run clean |

### Task Dependency Summary

```
M1 (OAI-001 → 002 → 003)
                   ↓
M2 (OAI-004 → 005, 006, 007, 008a → 008b)
                   ↓
M3 (009 [needs 008a HTML shape], 010 → 011)
                   ↓
M4 (OAI-012)
                   ↓
M7-OAI-019 ← (OAI-004)        M5 (013 needs 005, 006, 012, 019 → 014 → 015)
                   ↓
M6 (016a → 016b → 016c → 016d → 016e)  [needs 007, 008b, 011, 012, 013]
                   ↓
M7 (020 [needs 002])
                   ↓
M8 (021 [needs M6+M7] → 022 → 023)
```

### Attachment support matrix (for OAI-008a/b)

| Type | Source format examples | v1 expectation | Notes |
|---|---|---|---|
| Image | JPEG, PNG, HEIC | Required | Inline rendering in Obsidian |
| PDF | application/pdf | Required | Linked, not embedded |
| Audio | m4a | Required | Linked |
| Drawing/sketch | Apple Notes proprietary canvas | Best-effort PNG fallback | Interactive ink lost; warn moderate-tier |
| Scanned document | PDF | Required | OCR layer preserved if present in source |
| Web bookmark | HTML preview card | Best-effort link extraction | Card render lost; warn moderate-tier |

## Risk Register (project level)

| Risk | Severity | Mitigation |
|---|---|---|
| ~~AppleScript hard-delete instead of soft-delete~~ | ✅ **Cleared** | G1 validated 2026-04-25 |
| Composite verify-before-delete gate weakly enforced | **Critical** | OAI-016b dedicated task with adversarial tests for partial-write / attachment-failure / index-failure |
| Index corruption causes silent re-import / data confusion | **Critical** | OAI-012 safe-degraded mode + frontmatter rebuild |
| Mid-batch failure cascades / partial source loss | High | OAI-016d per-note independence + final summary |
| TCC denial silently locks users out | High | OAI-019 first-command probe + structured denial detection + manual re-check |
| AppleScript performance kills modal UX on large libraries | Medium | A1 probe in PLAN; if confirmed, OAI-013 pagination contingency triggers |
| turndown drops formatting users care about | Medium | Apple-Notes-aware pre-processor + custom node-filters; golden tests on real captured HTML; tiered warnings (severe blocks delete) |
| Note id instability across iCloud account switch | Medium | Content-hash secondary key in OAI-012 |
| Submission rejected on first community-plugin review | Low | Distribution checklist (gitignore, release-asset hygiene, README, screenshots, manifest/tag consistency) in OAI-022; lint with `eslint-plugin-obsidianmd` from day 1 |
| Apple Notes HTML changes break converter post-release | Low | Pin turndown; golden tests on real fixtures; docs link for users to file repro issues |

## Spec Scope Classification

**MAJOR.** New system, new external repo, destructive operations against a third-party app, community-distribution gate. Round-1 peer review applied (10 must-fix, 18 should-fix, 4 declined). Round-2 diff review pending against this revision.
