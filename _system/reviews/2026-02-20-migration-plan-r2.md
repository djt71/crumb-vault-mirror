---
type: review
review_mode: full
review_round: 2
prior_review: _system/reviews/2026-02-20-migration-plan.md
artifact: Projects/vault-restructure/design/migration-plan.md
artifact_type: plan
artifact_hash: ae5dc24a
prompt_hash: 79f1469a
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
  soft_heuristic_triggered: false
  user_override: false
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 37494
    attempts: 1
    raw_json: _system/reviews/raw/2026-02-20-migration-plan-r2-openai.json
  deepseek:
    http_status: 200
    latency_ms: 100057
    attempts: 1
    raw_json: _system/reviews/raw/2026-02-20-migration-plan-r2-deepseek.json
  google:
    http_status: 200
    latency_ms: 66690
    attempts: 2
    raw_json: _system/reviews/raw/2026-02-20-migration-plan-r2-google.json
tags:
  - review
  - peer-review
---

# Peer Review Round 2: Migration Plan (vault-restructure)

**Artifact:** Projects/vault-restructure/design/migration-plan.md
**Mode:** full (346-line diff, but touches foundational sections)
**Reviewed:** 2026-02-20
**Reviewers:** GPT-5.2, DeepSeek V3.2-Thinking, Gemini 3 Pro Preview
**Prior review:** [[2026-02-20-migration-plan]]
**Review prompt:** Round 2 — verify round 1 fixes applied correctly, catch regressions, evaluate coherence

---

## OpenAI (GPT-5.2)

- **[OAI-F1–F11]** — **[Severity]: STRENGTH** — All 11 round 1 action items verified as correctly applied.

- **[OAI-F12]**
  - **[Severity]: CRITICAL**
  - **[Finding]: Phase 2 copy-then-move sequence will collide. Step 1 copies to `_system/scripts/session-startup.sh` (creating the directory). Step 6 runs `git mv scripts/ _system/scripts/` — but `_system/scripts/` already exists, so git either nests (`_system/scripts/scripts/`) or errors.**
  - **[Why]:** High blast radius — this is the SessionStart hook migration. Collision mid-flight could lock out Claude Code.
  - **[Fix]:** Option A (recommended): No copy step. Patch script in-place at `scripts/`, then `git mv scripts/ _system/scripts/`, then update hook. Option B: True shim stub at old path.

- **[OAI-F13]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Phase 2 has two "Step 0"s — "Close Obsidian" and "Fix VAULT_ROOT depth" (numbered 0 in the migration sequence). Ambiguous execution order.**
  - **[Fix]:** Renumber migration sequence steps to start at 1, or label them 2A/2B/2C.

- **[OAI-F14]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Grep exclusion patterns for historical logs are inconsistent and ad-hoc across phases.**
  - **[Fix]:** Define immutable log patterns once and reuse.

- **[OAI-F15]** — **[Severity]: MINOR** — Phase 0 lettering: 0G appears before 0F in the document.

- **[OAI-F16]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Phase 3 only audits `settings.local.json` for `reviews/` patterns, not `settings.json`. A11 was applied in Phase 1 but not consistently carried to Phase 3.**
  - **[Fix]:** Mirror Phase 1 language: audit both settings files.

- **[OAI-F17]** — **[Severity]: MINOR** — `setup-vault-structure.sh` "if not removed in Phase 0" has no removal step in Phase 0.

- **[OAI-F18]** — **[Severity]: STRENGTH** — Overall coherence remains good. Plan is executable.

---

## DeepSeek (V3.2-Thinking)

- **[DSK-F1]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Phase 0G appears before 0F — lettering out of order.**
  - **[Fix]:** Swap order or reletter.

- **[DSK-F2]**
  - **[Severity]: CRITICAL**
  - **[Finding]: Phase 2 copy-before-move creates `_system/scripts/` directory, then `git mv scripts/ _system/scripts/` will nest or fail.**
  - **[Fix]:** Remove copy step. Edit script in-place, then git mv, then update hook.

- **[DSK-F3]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Phase 1B says "Update all references to the old spec filename" but doesn't list which files, unlike other phases' detailed file lists.**
  - **[Fix]:** Add a file list or a grep command to Phase 1B.

- **[DSK-F4]** — **[Severity]: MINOR** — Sort order note could be in a global section.

- **[DSK-F5]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Phase 1 `bash scripts/session-startup.sh` verification may succeed even if overlay loading fails, depending on error handling.**
  - **[Fix]:** Also verify overlay index was actually found/loaded.

- **[DSK-F6]** — **[Severity]: STRENGTH** — Overall additions excellent; verification and rollback significantly improved.

- **[DSK-F7]** — **[Severity]: MINOR** — Phase 0G "document findings" doesn't specify where.

---

## Google Gemini (3 Pro Preview)

- **Round 1 verification:** All A1-A11 items confirmed correctly applied.

- **[GEM-F1]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Phase 2 `git mv scripts/ _system/scripts/` will collide with the pre-created `_system/scripts/` from the copy step.**
  - **[Fix]:** Simplify: edit script in-place → `git mv` → update hook → verify. No pre-copy.

- **[GEM-F2]**
  - **[Severity]: MINOR**
  - **[Finding]: Bulk replace `docs/` → `_system/docs/` could corrupt `../docs/` relative patterns into `../_system/docs/`, creating double-nesting from the new location.**
  - **[Fix]:** Exclude `../docs/` patterns from bulk replace unless specifically verified.

- **[GEM-F3]** — **[Severity]: STRENGTH** — Verification rigor (secondary checks, unrestricted grep) is exceptionally robust.

---

## Synthesis

### Round 1 Fix Verification

All 11 action items (A1-A5 must-fix, A6-A11 should-fix) confirmed correctly applied by all three reviewers. No regressions from the fixes themselves.

### Consensus Findings

**1. Phase 2 copy-then-move collision** (OAI-F12, DSK-F2, GEM-F1)
All three reviewers independently identified this. Creating `_system/scripts/` via copy, then running `git mv scripts/ _system/scripts/`, causes a directory nesting or failure. Unanimous recommendation: remove the copy step, edit the script in-place, then `git mv`.

**2. Phase 0 lettering out of order** (OAI-F15, DSK-F1)
0G (external tooling inventory) was inserted before 0F (fix breakable links). Two reviewers flagged it.

### Unique Findings

**OAI-F16 (SIGNIFICANT): Phase 3 settings.json audit gap** — A11 was applied to Phase 1 but not consistently carried forward. Phase 3 only audits `settings.local.json`. Genuine oversight — the fix pattern should be applied uniformly across all move phases.

**DSK-F3 (SIGNIFICANT): Phase 1B missing file list for spec rename** — Other phases have detailed file lists; Phase 1B just says "update all references." Should include at least a grep command or bullet list for consistency.

**GEM-F2 (MINOR): `../docs/` bulk replace risk** — Bulk replacing `docs/` could corrupt `../docs/` relative patterns into `../_system/docs/`. This is already addressed by the manual review pass (item 17), but worth noting as a specific pattern to watch for during that pass.

**DSK-F5 (SIGNIFICANT): Phase 1 verification may false-positive** — `bash scripts/session-startup.sh` may succeed even if overlay loading silently fails. The secondary verification (`test -f _system/docs/overlays/overlay-index.md`) partially addresses this, but the startup script's own error handling should be checked.

### Contradictions

None. All three reviewers agree on the core issue (Phase 2 collision) and the overall quality of the plan.

### Action Items

**Must-fix:**

- **B1** (OAI-F12, DSK-F2, GEM-F1): Rewrite Phase 2 sequence — remove copy step, edit script in-place, then `git mv`, then update hook. Eliminates directory collision risk.

**Should-fix:**

- **B2** (OAI-F15, DSK-F1): Fix Phase 0 lettering — swap 0G and 0F, or reletter sequentially.
- **B3** (OAI-F16): Add settings.json audit to Phase 3 pre-move updates (mirror Phase 1 pattern).
- **B4** (DSK-F3): Add file list or grep command to Phase 1B for spec filename references.
- **B5** (OAI-F13): Disambiguate Phase 2 "Step 0" numbering (Close Obsidian vs VAULT_ROOT fix).

**Defer:**

- **B6** (GEM-F2): `../docs/` pattern risk — already covered by manual review pass; add as a specific callout in item 17 decision rule.
- **B7** (OAI-F14): Grep exclusion standardization — functional as-is; one-time migration doesn't warrant a reusable pattern definition.
- **B8** (OAI-F17): setup-vault-structure.sh ambiguity — clarify in Phase 0 whether it's being deleted.
- **B9** (DSK-F7): Phase 0G documentation location — minor.

### Considered and Declined

- **DSK-F4** (move sort order note to global section): `overkill` — the note is in Phase 1 where it matters most and is only a few lines. Moving it to a global section adds structural complexity for no operational benefit.
- **DSK-F5** (startup script false-positive): `constraint` — the secondary verification (`test -f`) already validates the key file exists. The startup script's error handling is a separate concern from the migration plan's verification checklist.
