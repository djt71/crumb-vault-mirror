---
type: research-brief
project: obsidian-applenotes-import
domain: software
purpose: Verified Obsidian community-plugin development guidance, used as input to SPECIFY phase
sources_consulted:
  - github.com/obsidianmd/obsidian-developer-docs (official, via Context7)
  - github.com/obsidianmd/obsidian-sample-plugin (official, fetched at HEAD via gh)
sources_pinned:
  developer_docs_head: 2ed97bd04e82773d81eac967382819431da3b098  # 2026-03-16
  sample_plugin_head: dc2fa22c4d279199fb07a205a0c11eb155641f3d   # 2025-12-30
  manifest_doc_blob: eeac634ac771a85e5c22ee3b35754c5d5614b076   # en/Reference/Manifest.md
  submission_doc_blob: ce93a442f4b6edf0c3aef10958c785ed1722ba9c # en/Plugins/Releasing/Submission requirements for plugins.md
created: 2026-04-25
updated: 2026-04-25
---

# Research Brief — Obsidian Plugin Platform (Verified)

Compiled from `obsidianmd/obsidian-developer-docs` and the current `obsidianmd/obsidian-sample-plugin` template. All facts here are direct quotes/observations from official sources, not from training data.

## 1. Build & Project Layout (current sample-plugin)

- **Entry point:** `src/main.ts` (moved from root in newer template)
- **Bundle output:** `main.js` at repo root, **gitignored — must not be committed**
- **Build chain:** `tsc -noEmit -skipLibCheck && node esbuild.config.mjs production`
- **TypeScript:** `^5.8.3`, target `ES6`, `module: ESNext`, `noUncheckedIndexedAccess: true`, `strictNullChecks: true`
- **esbuild:** `0.25.5`, format `cjs`, target `es2018`, `treeShaking: true`, `minify` only in production, sourcemap inline in dev
- **Externals:** `obsidian`, `electron`, all `@codemirror/*`, all `@lezer/*`, plus Node `builtinModules`
- **Lint:** `eslint-plugin-obsidianmd` `0.1.9` pinned in current sample template's `package.json` devDependencies (per [pinned sample-plugin HEAD](https://github.com/obsidianmd/obsidian-sample-plugin/blob/dc2fa22c4d279199fb07a205a0c11eb155641f3d/package.json), 2025-12-30). Latest published on npm is `0.2.4` (verified 2026-04-25). PLAN decides whether to track the template's pin or take latest.
- **package.json:** `"type": "module"` (build scripts are ESM; the shipped plugin is CJS)
- **Scripts:** `dev` (watch), `build` (production), `version` (bumps `manifest.json` + `versions.json` in one commit), `lint`

## 2. manifest.json — Required Fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes | Must NOT contain "obsidian" |
| `name` | string | yes | Display name; avoid the word "Obsidian" unless necessary |
| `version` | string | yes | Semver `x.y.z` |
| `minAppVersion` | string | yes | Minimum Obsidian app version |
| `description` | string | yes | |
| `author` | string | yes | |
| `isDesktopOnly` | boolean | yes | **Set `true` for our plugin** — we use NodeJS `child_process` (osascript) |
| `authorUrl` | string | no | |
| `fundingUrl` | string \| object | no | **Omit if not accepting donations** (per submission rules) |

## 3. Plugin API Patterns We Will Use

- **Lifecycle:** `Plugin` class with `async onload()` / `onunload()`
- **Settings:** `addSettingTab(new MySettingTab(app, this))`, persist via `loadData()` / `saveData()` (JSON-serialized to plugin's `data.json`)
- **Commands:** `addCommand({ id, name, callback })`. **Do not include plugin name/ID in command names — Obsidian prefixes automatically.**
- **UI:** `Modal` subclass with `onOpen` / `onClose` (always `contentEl.empty()` in `onClose`); `Notice` for transient feedback
- **DOM construction:** `containerEl.createEl('div', { text, cls })` — **never** `innerHTML` / `outerHTML` / `insertAdjacentHTML` with user input (XSS rule)
- **Auto-cleanup wrappers:** `registerEvent`, `registerDomEvent`, `registerInterval` — required to avoid leaks on unload
- **Vault writes:**
  - `app.vault.create(path, content)` — markdown
  - `app.vault.createBinary(path, ArrayBuffer)` — attachments
  - `app.vault.createFolder(path)` — **throws if folder already exists**; wrap in try/catch or check via `app.vault.getAbstractFileByPath`
- **Path safety:** `normalizePath(userPath)` on every user-supplied path
- **Adapter checks:** `if (this.app.vault.adapter instanceof FileSystemAdapter) { ... }` — never cast

## 4. Submission Requirements (relevant subset)

From `Plugins/Releasing/Submission requirements for plugins.md` and the plugin self-critique checklist:

- ✗ Don't ship `main.js` in repo (release artifact only)
- ✗ Don't put placeholder names in `manifest.json`
- ✗ Don't include "Obsidian" or your plugin's name/ID in command names
- ✗ Don't use `innerHTML` with user input
- ✗ Don't cast adapters — use `instanceof`
- ✗ Don't use `fetch` for network — use Obsidian's `requestUrl` (N/A for us; no network)
- ✓ Use `normalizePath` on user-defined paths
- ✓ Use `registerEvent` / `registerDomEvent` / `registerInterval` for cleanup
- ✓ Provide `fundingUrl` only if you actually accept donations
- ✓ For mobile support: gate Node usage. **We are explicitly desktop-only** (`isDesktopOnly: true`), so this is satisfied by the manifest, but we should still:
  - Add a runtime `Platform.isMacOS` check on plugin load
  - Show a clear `Notice` and disable commands on non-macOS desktops (Linux/Windows)

## 5. Apple Notes Surface (AppleScript) — Open Questions for SPECIFY

These are **not yet verified** against current macOS — systems-analyst should flag them as assumptions to validate during the spec phase, ideally with small osascript probes:

- **Listing:** `tell application "Notes" to get every note` — what's the latency for ~1000 notes? Are folder/account queries available?
- **Identity:** Each note has a stable id (CoreData URI). Confirm it survives across app restarts and is suitable as our round-trip key.
- **Body format:** `body` returns HTML. Need a sanitizing HTML→markdown converter (turndown is conventional). Confirm whether AppleScript exposes plain text alongside HTML.
- **Attachments:** Listing exists; extracting requires either AppleScript export or reading from the Notes filesystem cache. Spec should pick one and document.
- **Soft delete:** `tell application "Notes" to delete theNote` — confirm this hits Recently Deleted (30-day) rather than hard-deleting.
- **TCC permissions:** First osascript invocation triggers Automation prompt. UX: how does the plugin handle first-run denial? Recovery path?
- **Locked notes / iCloud-shared notes:** Confirm exclusion behavior or surface as "skipped" in the import receipt.

## 6. Locked Decisions (carried into SPECIFY)

1. AppleScript via `osascript` (NodeJS `child_process.execFile`) — no SQLite/protobuf approach.
2. Soft delete only — `tell application "Notes" to delete` (Recently Deleted, 30-day retention). No hard delete in v1.
3. Desktop-only, macOS-only. `isDesktopOnly: true` + runtime `Platform.isMacOS` gate.
4. Community-distributable: follows all submission requirements above.

## 7. References (resolved)

- Sample plugin: `github.com/obsidianmd/obsidian-sample-plugin` (manifest, esbuild.config.mjs, tsconfig.json, src/main.ts pulled at HEAD `dc2fa22c4d279199fb07a205a0c11eb155641f3d`, last commit 2025-12-30)
- Developer docs: `github.com/obsidianmd/obsidian-developer-docs` at HEAD `2ed97bd04e82773d81eac967382819431da3b098` (last commit 2026-03-16)
- Lint rules: `eslint-plugin-obsidianmd` (`0.1.9` pinned in template; latest published `0.2.4`)

## 8. Citations (pinned per Pre-PLAN Gate G4)

All factual claims in this brief originate from the following pinned sources. Re-verify at PLAN start by re-fetching at the pinned SHAs.

| Claim | Source | Pinned SHA / blob |
|---|---|---|
| `manifest.json` schema and required fields (id, name, version, minAppVersion, description, author, isDesktopOnly) | `obsidianmd/obsidian-developer-docs` `en/Reference/Manifest.md` | blob `eeac634ac771a85e5c22ee3b35754c5d5614b076` |
| Plugin id "cannot contain 'obsidian'" submission rule | `obsidianmd/obsidian-developer-docs` `en/Reference/Manifest.md` | blob `eeac634ac771a85e5c22ee3b35754c5d5614b076` |
| Submission requirements (no committed `main.js`, no `innerHTML` with user input, etc.) | `obsidianmd/obsidian-developer-docs` `en/Plugins/Releasing/Submission requirements for plugins.md` | blob `ce93a442f4b6edf0c3aef10958c785ed1722ba9c` |
| Sample plugin scaffold structure (src/main.ts, esbuild.config.mjs, tsconfig.json, package.json scripts and deps) | `obsidianmd/obsidian-sample-plugin` HEAD | tree `dc2fa22c4d279199fb07a205a0c11eb155641f3d` |
| `eslint-plugin-obsidianmd` exists and is in current sample template at version `0.1.9` | sample-plugin `package.json` at HEAD | tree `dc2fa22c4d279199fb07a205a0c11eb155641f3d` |
| `eslint-plugin-obsidianmd` latest published version `0.2.4` | npm registry | verified 2026-04-25 |
