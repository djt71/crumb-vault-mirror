---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/vault-restructure/design/migration-plan.md
artifact_type: plan
artifact_hash: 7f8056f5
prompt_hash: 11213329
base_ref: null
project: vault-restructure
domain: software
skill_origin: peer-review
created: 2026-02-20
updated: 2026-02-20
status: active
reviewers:
  - openai/gpt-5.2
  - deepseek/deepseek-reasoner (V3.2-Thinking)
  - google/gemini-3-pro-preview
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: true
  soft_trigger_detail: "customer-intelligence project name — false positive"
  user_override: false
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 69385
    attempts: 1
    raw_json: _system/reviews/raw/2026-02-20-migration-plan-openai.json
  deepseek:
    http_status: 200
    latency_ms: 89849
    attempts: 1
    raw_json: _system/reviews/raw/2026-02-20-migration-plan-deepseek.json
  google:
    http_status: 200
    latency_ms: 57231
    attempts: 2
    raw_json: _system/reviews/raw/2026-02-20-migration-plan-google.json
tags:
  - review
  - peer-review
---

# Peer Review: Migration Plan (vault-restructure)

**Artifact:** Projects/vault-restructure/design/migration-plan.md
**Mode:** full
**Reviewed:** 2026-02-20
**Reviewers:** GPT-5.2, DeepSeek V3.2-Thinking, Gemini 3 Pro Preview
**Review prompt:** Structured review of 5-phase migration plan — phasing correctness, verification sufficiency, rollback gaps, effort realism, missing integrations

---

## OpenAI (GPT-5.2)

- **[OAI-F1]**
  - **[Severity]: CRITICAL**
  - **[Finding]: Phase 1 verification checklist references `_system/scripts/session-startup.sh`, but scripts don't move until Phase 2**
  - **[Why]:** That path doesn't exist after Phase 1. Following the checklist literally would "fail" even though the vault is fine.
  - **[Fix]:** Change Phase 1 checklist to `bash scripts/session-startup.sh` (old path, still valid). Keep `_system/scripts/` references only in Phase 2+ checklists.

- **[OAI-F2]**
  - **[Severity]: CRITICAL**
  - **[Finding]: Phase 2 copy-before-move can leave settings pointing to non-existent file if reverted mid-phase**
  - **[Why]:** If `.claude/settings.json` is updated to point to `_system/scripts/` but the commit is never made, revert won't clean up untracked files.
  - **[Fix]:** Document explicit Phase 2 execution order: create dir + copy → update settings → test from terminal → git mv → re-test → commit. Add "do not close Claude Code until commit succeeds."

- **[OAI-F3]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Phase 2 hardcodes spec filename `crumb-design-spec-v1-7-1.md` but Phase 1B renames it to v1.8**
  - **[Why]:** If 1B is done, the Phase 2 path is wrong. Violates "no dependencies between phases."
  - **[Fix]:** Reference spec generically: `_system/docs/crumb-design-spec-*.md` in all phases after Phase 1.

- **[OAI-F4]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Phase 1 updates `.claude/settings.local.json` but not `.claude/settings.json` permission patterns**
  - **[Why]:** If `settings.json` gates permissions, `docs/` patterns may block reads from `_system/docs/`.
  - **[Fix]:** Add Phase 1 checklist: "audit both settings files for `docs/` patterns; update whichever gates permissions."

- **[OAI-F5]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Grep exclusion patterns for historical logs are ad-hoc**
  - **[Why]:** Risk of false negatives from overly broad excludes or false positives drowning real misses.
  - **[Fix]:** Use a committed `.rgignore` or a dedicated verify script with deterministic exclusions.

- **[OAI-F6]**
  - **[Severity]: CRITICAL**
  - **[Finding]: vault-check.sh is the single point of trust for verification; if Phase 1 introduces a bug, later phases lose reliable checking**
  - **[Why]:** You're modifying the verification tool and then using it to verify the modification.
  - **[Fix]:** Add secondary verification independent of vault-check.sh: `test -d _system/docs`, `test -f _system/docs/overlays/overlay-index.md`, `bash -n` on modified scripts.

- **[OAI-F7]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: `.obsidian/workspace.json` may embed `docs/` paths for open panes**
  - **[Why]:** Not a data loss risk, but broken panes/tabs on next Obsidian open.
  - **[Fix]:** Add note: after move, reopen vault; if panes break, close/reopen or let Obsidian regenerate.

- **[OAI-F8]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: No systematic rule for distinguishing "live path" vs "historical prose" in spec manual pass**
  - **[Why]:** 30-minute manual pass without a decision rule risks inconsistency.
  - **[Fix]:** Define rule: "how-to-run/current-structure/must-exist → update; explicitly-historical/examples → keep old, label section."

- **[OAI-F9]**
  - **[Severity]: MINOR**
  - **[Finding]: Phase 0A `rm` without checking git-tracked status**
  - **[Why]:** If untracked, `rm` works but doesn't clean repo history.
  - **[Fix]:** Add `git status` check; use `git rm` if tracked.

- **[OAI-F10]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Phase 2/3 grep checks are broader than Phase 1 (no file-type scoping)**
  - **[Why]:** Noisy output increases chance of overlooking true positives.
  - **[Fix]:** Standardize on scoped grep across all phases, mirroring Phase 1 approach.

- **[OAI-F11]**
  - **[Severity]: CRITICAL**
  - **[Finding]: External tooling (cron, launchd, shell aliases, Raycast/Alfred) referencing vault `scripts/` paths not inventoried**
  - **[Why]:** Breakage outside the vault won't be caught by in-vault verification.
  - **[Fix]:** Add Phase 0 or Phase 2 preflight: search dotfiles, launch agents, global aliases for vault path references.

- **[OAI-F12]** — **[Severity]: STRENGTH** — Plan correctly isolates high-risk changes and defers low-ROI work.

- **[OAI-F13]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Rollback doesn't cover untracked files created mid-phase**
  - **[Why]:** `git revert HEAD` won't remove newly created `_system/` directories from a failed mid-phase.
  - **[Fix]:** Add to rollback: "if mid-phase, also `git clean -fd _system/` to remove untracked artifacts."

- **[OAI-F14]** — **[Severity]: MINOR** — Phase 1 effort slightly optimistic. Suggest +30-60 min contingency.

- **[OAI-F15]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: "No dependencies between phases" slightly violated by Phase 1B being optional but affecting spec filename**
  - **[Why]:** Phase 2-4 instructions change based on whether 1B happened.
  - **[Fix]:** Remove filename specificity; reference "current spec file" generically.

- **[OAI-F16]** — **[Severity]: STRENGTH** — Immutable historical logs well-reasoned.

- **[OAI-F17]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Plan may miss non-.md/.sh/.json/.yaml references (.txt, .py, .config, etc.)**
  - **[Why]:** Silent failures from missed file types.
  - **[Fix]:** Add a one-time "wide scan" preflight without file-type restrictions.

- **[OAI-F18]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Standard markdown image paths (`![](relative/path.png)`) may break when docs move**
  - **[Why]:** Relative image paths resolve from the file's directory; moving the file changes resolution.
  - **[Fix]:** Pre-check: `rg '!\[[^\]]*\]\((?!http)' _system/docs` after move to find broken image refs.

---

## DeepSeek (V3.2-Thinking)

- **[DSK-F1]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Hidden dependency — session-startup.sh updated in Phase 1 (refs to `_system/docs/`) but remains in `scripts/`. Creates maintenance trap if Phase 2 never executed.**
  - **[Why]:** Orphaned script at old location with updated internal refs is confusing.
  - **[Fix]:** Move session-startup.sh in Phase 1, updating hook at the same time.

- **[DSK-F2]**
  - **[Severity]: CRITICAL**
  - **[Finding]: Grep verification only covers md/sh/json/yaml; misses other file types**
  - **[Why]:** Path references could exist in data files or configs not covered.
  - **[Fix]:** Use unrestricted grep with exclusions instead of restrictive includes.

- **[DSK-F3]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Obsidian URI links (`app://obsidian.md/...`) may exist and would break after moves**
  - **[Why]:** These are absolute paths generated by Obsidian's "copy link" feature.
  - **[Fix]:** Pre-flight check: `grep -r 'app://obsidian.md' .`

- **[DSK-F4]** — **[Severity]: MINOR** — Phase 0 removes files without checking references.

- **[DSK-F5]** — **[Severity]: STRENGTH** — Two-pass spec approach excellent risk mitigation.

- **[DSK-F6]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Plan doesn't check for existing symbolic links pointing to moved directories**
  - **[Why]:** Symlinks would break if targets move.
  - **[Fix]:** Pre-flight: `find . -type l -exec ls -la {} \; | grep -E "(docs|scripts|reviews)/"`

- **[DSK-F7]** — **[Severity]: MINOR** — Effort estimate may be optimistic for Phase 1.

- **[DSK-F8]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Rollback assumes `.claude/settings.json` accessible via Claude Code**
  - **[Why]:** If hook breaks, Claude Code can't start.
  - **[Fix]:** Document terminal-based recovery.

- **[DSK-F9]** — **[Severity]: STRENGTH** — Cross-phase state documentation excellent.

- **[DSK-F10]** — **[Severity]: MINOR** — workspace.json open-tab issues after move.

- **[DSK-F11]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Spot-checking only one skill is thin coverage**
  - **[Why]:** Edge cases in skills with complex conditional logic may be missed.
  - **[Fix]:** Create lightweight skill test script exercising each skill's primary function.

- **[DSK-F12]** — **[Severity]: MINOR** — Case-sensitivity in path references.

---

## Google Gemini (3 Pro Preview)

- **[GEM-F1]**
  - **[Severity]: CRITICAL**
  - **[Finding]: Moving scripts from depth 1 (`scripts/`) to depth 2 (`_system/scripts/`) may break relative path resolution in shell scripts**
  - **[Why]:** If scripts use `$(dirname "$0")/..` or `..` to find vault root, the new depth resolves wrong (`../` from `_system/scripts/` → `_system/` not vault root).
  - **[Fix]:** Phase 2 pre-move audit: check `session-startup.sh` and `vault-check.sh` for relative path usage. Update `..` to `../..` or define a `VAULT_ROOT` variable.

- **[GEM-F2]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: `_system` sorts to the TOP of Obsidian explorer (underscore before letters in ASCII), not below user content as stated**
  - **[Why]:** The plan says "sinks below" but `_system/` will appear above `Domains/` and `Projects/`.
  - **[Fix]:** Either rename to `z_system` for bottom sorting, or update the plan language to reflect that `_system` groups at top (standard Obsidian convention for meta-folders).

- **[GEM-F3]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Obsidian's file watcher may trigger automatic link updates during `git mv` operations, creating a race condition**
  - **[Why]:** Obsidian open + git mv + manual replacements = three-way edit conflict risk.
  - **[Fix]:** Add "Close Obsidian" as first step of each phase; "Open Obsidian" as verification step.

- **[GEM-F4]** — **[Severity]: MINOR** — Phase 2 has a transitional state between ref updates and file move. Add warning not to verify mid-step.

- **[GEM-F5]** — **[Severity]: STRENGTH** — Phase 1B separation is excellent engineering hygiene.

- **[GEM-F6]** — **[Severity]: STRENGTH** — SessionStart hook shim strategy well-designed.

- **[GEM-F7]**
  - **[Severity]: MINOR**
  - **[Finding]: Inter-script calls within scripts/ (e.g., `bash scripts/script-B.sh`) not explicitly audited**
  - **[Why]:** Both scripts move together but internal references using root-absolute paths would break.
  - **[Fix]:** Phase 2 pre-move: grep scripts for `scripts/` string references.

---

## Synthesis

### Consensus Findings

**1. Grep verification too restrictive on file types** (OAI-F17, DSK-F2, OAI-F10)
All three reviewers raised this. Phase 1's grep is scoped to md/sh/json/yaml; Phases 2-3 are unscoped but still may miss unusual file types. A one-time unrestricted scan is the cheapest insurance.

**2. Phase 1 effort estimate slightly optimistic** (OAI-F14, DSK-F7)
Two reviewers flag 2.5 hours as tight for 162-ref manual review plus verification. Suggest buffering to 3-3.5 hours.

**3. Spec filename coupling across phases** (OAI-F3, OAI-F15)
Phase 1B is optional but later phases hardcode the v1.7.1 filename. If 1B runs, those paths are wrong. Generic references fix this cleanly.

**4. Obsidian workspace/UX during migration** (OAI-F7, DSK-F10, GEM-F3)
Three reviewers independently flag Obsidian interaction risks. GEM-F3 is the strongest: close Obsidian during git mv to prevent race conditions from the file watcher.

**5. Phase 0A rm without reference check** (OAI-F9, DSK-F4)
Minor but both flagged it. Quick `grep` before deleting is cheap insurance.

### Unique Findings

**GEM-F1 (CRITICAL): Script relative path depth** — Genuine insight. If `session-startup.sh` or `vault-check.sh` use `$(dirname "$0")/..` or `..` to find vault root, moving from depth 1 to depth 2 breaks resolution. Must audit before Phase 2.

**GEM-F2 (SIGNIFICANT): `_system` sorts to TOP** — Correct observation. Underscore (0x5F) sorts before uppercase A (0x41) in ASCII. The plan's language about "sinking below" is inaccurate. The user should confirm whether top-grouping (standard Obsidian convention for `_templates`, `_attachments`) is acceptable, or whether a rename is needed.

**OAI-F1 (CRITICAL): Phase 1 checklist bug** — The Phase 1 verification step references `bash _system/scripts/session-startup.sh` but scripts don't move until Phase 2. This is a concrete bug in the plan text.

**OAI-F6 (CRITICAL): vault-check.sh as single point of trust** — Valid. You're modifying the verification tool and then using it to verify your modification. Adding independent secondary checks (`test -f`, `bash -n`) costs nothing.

**OAI-F11 (CRITICAL): External tooling not inventoried** — If launchd agents, shell aliases, or Alfred workflows reference `crumb-vault/scripts/...`, they'll break silently. Worth a quick search.

**DSK-F3 (SIGNIFICANT): Obsidian URI links** — Plausible but likely low occurrence in this vault. Worth a 10-second grep to confirm.

### Contradictions

**DSK-F1 vs plan's phasing strategy:** DeepSeek suggests merging the session-startup.sh move into Phase 1 to avoid the "orphaned updated script" problem. This contradicts the plan's core design of isolating the high-risk hook migration in its own phase (Phase 2). OpenAI's F2 and Gemini's F6 both validate the shim strategy as sound. **Resolution: reject DSK-F1** — the orphaned state is documented and functional; merging increases Phase 1's blast radius.

### Action Items

**Must-fix:**

- **A1** (OAI-F1): Fix Phase 1 checklist path bug — change `_system/scripts/session-startup.sh` to `scripts/session-startup.sh` (scripts haven't moved yet in Phase 1)
- **A2** (GEM-F3, OAI-F7, DSK-F10): Add "Close Obsidian" as first step of each phase; "Open Obsidian" in verification
- **A3** (GEM-F1): Add Phase 2 pre-move audit for relative path depth in scripts (`..`, `dirname`, `BASH_SOURCE`)
- **A4** (GEM-F2): Correct plan language about `_system` sorting — it groups at TOP (underscore before letters), not bottom. Confirm with user whether this is acceptable or needs a rename.
- **A5** (OAI-F3, OAI-F15): Remove spec filename specificity in Phases 2-4. Use generic `crumb-design-spec-*.md` or "current spec file."

**Should-fix:**

- **A6** (OAI-F17, DSK-F2, OAI-F10): Add one-time unrestricted grep preflight per phase; standardize scoped grep across all phases
- **A7** (OAI-F6): Add secondary verification independent of vault-check.sh (`test -f` key paths, `bash -n` on modified scripts)
- **A8** (OAI-F13): Add mid-phase rollback note: `git clean -fd _system/` to remove untracked artifacts
- **A9** (OAI-F11): Add external tooling inventory to Phase 0: search dotfiles, launchd plists, shell aliases for vault path references
- **A10** (OAI-F8): Define systematic rule for spec manual pass: "current-structure/how-to-run → update; explicitly-historical → keep + label"
- **A11** (OAI-F4): Audit both `settings.json` and `settings.local.json` in Phase 1 for `docs/` permission patterns

**Defer:**

- **A12** (DSK-F3): Obsidian URI link scan — quick grep, low expected occurrence. Run during Phase 0 if time permits.
- **A13** (DSK-F6): Symlink pre-flight check — design already chose reference notes over symlinks; existing symlinks unlikely but worth a 10-second check.
- **A14** (DSK-F11): Comprehensive skill test script — one spot-check per phase is proportionate for a one-time migration. Full skill testing is overkill.
- **A15** (DSK-F12): Case-sensitivity grep — macOS default filesystem (APFS) is case-insensitive; path references will resolve regardless of case.

### Considered and Declined

- **DSK-F1** (merge session-startup.sh move into Phase 1): `incorrect` — increases Phase 1 blast radius and contradicts the plan's core phasing strategy. The "orphaned updated script" state is documented, functional, and temporary.
- **OAI-F5** (committed verification script): `overkill` — this is a one-time migration, not a recurring operation. A checked-in `.rgignore` or dedicated script adds permanent maintenance for a single-use tool.
- **DSK-F8** (rollback assumes settings accessible): `constraint` — already addressed in the plan's rollback section: "edit `.claude/settings.json` from a regular terminal."
- **OAI-F18** (markdown image path breakage): `incorrect` — the vault uses `![[wikilink]]` format for all embeds (confirmed in the plan's own link audit: "All embeds use basename-only `![[file]]` format"). Standard markdown image paths are not used.
