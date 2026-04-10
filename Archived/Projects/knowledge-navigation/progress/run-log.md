---
project: knowledge-navigation
domain: learning
type: log
status: active
created: 2026-02-24
updated: 2026-02-24
---

# Run Log — knowledge-navigation

## 2026-02-24 — Session 1: Project Creation + SPECIFY

### Project Genesis
Spun off from notebooklm-pipeline v2 deferrals. Two features:
1. **Source index notes** — per-source landing pages linking all digests for that source
2. **MOC notes per #kb/ topic** — navigable browsing layer on top of Sources/

### Routing Assessment
- New project (not maintenance) — new artifact types, first MOC implementation, 3+ files
- Domain: learning | Class: knowledge | Workflow: three-phase (SPECIFY → PLAN → ACT)
- MOC schema already designed in spec §5.6 — implementation is ahead of design for once
- Source index notes need specification (only mentioned as "future" in NLM spec)
- Dependency: existing #kb/-tagged notes will need `topics` field backfill once MOCs exist

### Scope Reframe
Renamed from `sources-navigation` → `knowledge-navigation`. This is vault-wide knowledge infrastructure, not Sources/-only. The MOC system touches all 114 kb-tagged files across Projects/, Sources/, _system/docs/, and _attachments/.

### Plan Approved
Four-phase implementation:
- **Phase 1:** Foundation — MOC skeletons, source index schema, bug fixes
- **Phase 2:** vault-check additions (checks 17-19, 21)
- **Phase 3:** Backfill — topics field on all kb-tagged files, MOC Core population, Rawls source index POC
- **Phase 4:** Automation integration (deferred — can be separate project)

Key design decisions:
- Check 19 (topics requirement) starts as WARNING, promoted to ERROR after clean backfill
- MOC Core gets one-liners for source index notes, not individual knowledge notes per source
- `moc-crumb-architecture` and `moc-crumb-operations` in Domains/Learning/ (no Domains/Software/ exists)

## 2026-02-24 — Session 2: Implementation (Phases 1-3)

### Context Inventory
- Spec §5.6 (MOC system), §5.5 (KB protocol)
- file-conventions.md (type taxonomy, frontmatter schemas)
- vault-check.sh (12 existing checks)
- learning-overview.md (MOC placeholder)
- Sample profile (albert-einstein.md — frontmatter pattern for 45 profiles)
- Rawls digest (Sources/books/rawls-theory-justice-digest.md)

### Phase 1: Foundation

**1A — MOC Skeletons (4 files created):**
- `Domains/Learning/moc-history.md` (orientation, kb/history)
- `Domains/Learning/moc-philosophy.md` (orientation, kb/philosophy)
- `Domains/Learning/moc-crumb-architecture.md` (orientation, kb/software-dev)
- `Domains/Learning/moc-crumb-operations.md` (operational, kb/software-dev)

**1B — Source Index Schema:**
- Added `source-index` type to file-conventions.md type taxonomy
- Documented full schema (frontmatter + body sections) parallel to knowledge-note section

**1C — Bug Fixes:**
- Added `philosophy` to vault-check.sh canonical kb tag list (was missing)
- Fixed CLAUDE.md: `spirituality` → `religion` (matching spec), added missing `dns`
- Added `Sources/` to vault-check scan directories (checks 1, 9)
- Updated learning-overview.md: replaced MOC placeholder with actual wikilinks

### Phase 2: vault-check Additions

Added 4 new checks (script now has 16 total):
- **Check 17:** MOC schema validation — required fields, review_basis values, filename uniqueness
- **Check 18:** Topics resolution — each entry resolves to a valid MOC file in Domains/*/
- **Check 19:** Topics requirement (WARNING) — kb-tagged non-MOC notes must have topics
- **Check 21:** MOC synthesis density — orientation MOCs with >5 Core + empty Synthesis

Bash 3.2 compatibility: replaced `declare -A` (bash 4+) with string-based lookup for MOC uniqueness.

### Phase 3: Backfill

**3A — Think Different profiles (48 files):**
- Added `topics: [moc-history]` to 45 profiles + campaign-history + roster + synthesis
- Populated moc-history Core with 48 one-liners organized by domain (science, music, civil rights, film, arts, business, sports, spirituality, cross-cutting)

**3B — Other kb-tagged files (16 files):**
- Architecture → moc-crumb-architecture (8 files): feed-intel spec+summaries, vault-mirror spec, crumb-tess-bridge spec, boundary reference, comparison, architecture diagram, restructure analysis/discussion
- Operations → moc-crumb-operations (5 files): claude-print-automation, html-rendering-bookmark, write-read-path-verification, reasoning-token-budget, claude-code-ssh-setup
- Philosophy → moc-philosophy (1 file): rawls-theory-justice-digest
- **Deferred (3 files):** ai-telltale-anti-patterns (kb/writing), security-verification-circularity (kb/security), lucidchart-policy-compliance (kb/business) — each topic has only 1 file, no MOC created

**3C — Rawls Source Index (POC):**
- Created `Sources/books/rawls-theory-justice-index.md` using source-index schema
- Links existing digest, populated Overview from digest's Core Thesis

**3D — Check 19 promotion:**
- NOT promoted to error. 3 deferred files remain as warnings (topics < 3 notes each, MOCs would be premature)
- Promote when these topics accumulate 3+ notes

### Wikilink Fix
Obsidian uses shortest-path resolution (default, no `newLinkFormat` override in app.json). MOC one-liners initially used path-prefixed wikilinks (`[[profiles/albert-einstein|...]]`) which would be dead links — Obsidian interprets those as vault-relative paths. Fixed:
- moc-history: stripped `profiles/` prefix from all 45 entries → `[[albert-einstein|...]]`
- moc-crumb-architecture: 3 `[[specification|...]]` links were ambiguous (10 files named specification.md) → replaced with full vault paths `[[Projects/feed-intel-framework/design/specification|...]]`
- All other links verified unique — shortest-path resolves correctly

### Verification
- vault-check: 0 errors, 3 warnings (all expected — deferred topics)
- All 4 MOC files pass schema validation (check 17)
- 67 topic entries resolve correctly (check 18)
- 70 kb-tagged notes checked, 67 have topics (check 19)
- All MOC wikilinks verified: unique filenames resolve under shortest-path, ambiguous names use full vault paths

**Actions Taken:**
- Renamed project sources-navigation → knowledge-navigation
- Created 4 MOC skeletons, 1 source index note
- Added source-index type to file-conventions
- Added 4 vault-check checks (17, 18, 19, 21)
- Backfilled topics on 65 files, populated MOC Core sections
- Fixed kb tag discrepancies across CLAUDE.md, vault-check.sh

**Current State:**
- Phase 1-3 complete. Navigable knowledge browsing layer operational.
- Phase 4 (automation integration) deferred — can be a separate project.
- 3 kb-tagged files without topics (deferred — single-note topics with no MOC)

**Files Modified:**
- `_system/scripts/vault-check.sh` — 4 new checks, canonical tag fix, Sources/ scan dirs
- `_system/docs/file-conventions.md` — source-index schema, type taxonomy
- `CLAUDE.md` — canonical kb tag list sync
- `Domains/Learning/learning-overview.md` — MOC links
- `Domains/Learning/moc-*.md` (4 new files) — MOC skeletons with Core populated
- `Sources/books/rawls-theory-justice-index.md` (new) — source index POC
- `Sources/books/rawls-theory-justice-digest.md` — topics added
- 48 think-different files — topics added
- 16 _system/docs/ and Projects/ files — topics added
- Project scaffold files — renamed from sources-navigation

**Compound:**
- **Convention reinforced:** Obsidian shortest-path wikilink resolution means MOC one-liners must use bare filenames for unique files and full vault paths for ambiguous names (e.g., `specification.md`). Caught during review — add to file-conventions or MOC authoring guidance if this recurs.
- **Pattern confirmed:** sed-based frontmatter patching breaks when the target line isn't the last in a YAML array — Python-based insertion before closing `---` is more robust for multi-tag files. Already documented in MEMORY.md via the Write tool frontmatter loss vector note; this is the array-splitting variant.
- **Routing:** 3 deferred kb topics (writing, security, business) each have 1 file — monitor during compound steps and create MOCs when any reaches 3+ notes.
- **bash 3.2 compat:** macOS default bash lacks `declare -A` (associative arrays). vault-check must use string-based lookups. This joins the macOS openrsync note in MEMORY.md as a platform constraint.

## 2026-02-24 — Session 3: Peer Review + Remediation

### Context Inventory
- Review note from Session 2 (run-log)
- vault-check.sh (16 checks from Session 2)
- 4 MOC files, source index POC, file-conventions.md, learning-overview.md
- peer-review-config.md, peer-review-dispatch agent

### Peer Review
Full 5-reviewer peer review (first review cycle for this project):
- **Automated (4):** GPT-5.2, Gemini 3 Pro Preview, DeepSeek V3.2-Thinking, Grok 4.1 Fast Reasoning
- **Manual (1):** Perplexity Sonar Reasoning Pro (submitted by operator)
- **Consensus verdict:** Needs significant revision (5/5 unanimous)
- **Finding totals:** ~68 findings across 5 reviewers — 7 CRITICAL, 24 SIGNIFICANT, 14 MINOR, 10 STRENGTH, 4 UNVERIFIABLE

Key consensus themes:
1. Check 21 synthesis heuristic fragile (5/5)
2. YAML parsing fragility (4/5)
3. Wikilink style inconsistency undocumented (4/5)
4. Check 17 grep pattern bugs (4/5)
5. Non-MOC filename uniqueness not enforced (3/5)
6. Missing source-index validation (2/5)

Unique valuable findings: Grok caught MOC body structure validation gap (GRK-F1/F2) and bidirectional topics/Core drift risk (GRK-F4). Perplexity caught §5.6.6 one-liner lint omission (PPLX-F6, operator-verified).

### Remediation (10 items)

**Must-fix (3):**
- A1: Check 17 grep → awk exact string matching (prevents regex dot and prefix bugs)
- A2: Wikilink convention documented in file-conventions.md (bare vs path-prefixed)
- A5: MOC body structure validation (CORE/SYNTHESIS/DELTAS markers in Check 17)

**Should-fix (7):**
- A3: Check 21 → word count (>30 words) instead of sentence counting
- A4: Check 20 added — source-index schema validation (fills numbering gap)
- A6: moc-philosophy "2 notes" → "1 note"
- A7: Check 18 uses pre-built Domains/ file cache (eliminates per-iteration find)
- A8: extract_field strips surrounding quotes
- A14: Checks 18/19 scan Archived/ directory (promoted from defer per operator)
- A15: One-liner quality lint per §5.6.6 (merged into Check 21)

**Bonus bug found during testing:**
- `[ test ] || return` under `set -euo pipefail` — bare `return` inherits non-zero exit from failed `[`, killing the script silently. Fixed 3 instances to `return 0`. This was not caught by any reviewer — discovered through runtime debugging when Check 21 silently aborted on the first moc-operational file.

**Deferred (6):** A9 (non-MOC uniqueness), A10 (sub-MOC convention), A11 (bidirectional validation — flagged high-priority for Phase 4), A12 (wikilink resolution), A13 (Check 19 upgrade timeline), A15-original (§5.6.6 — implemented, no longer deferred)

**Declined (7):** OAI-F2 (bash arrays — incorrect), DS-F2 (mindepth — overkill), DS-F12 (rename MOC — constraint), GRK-F11 (dates — incorrect), DS-F6 (path — incorrect), DS-F4 (typeless — incorrect), PPLX-F3 (type exemptions — overkill)

### Verification
- vault-check: 0 errors, 7 warnings (all expected)
  - 1 review note frontmatter (review schema, not standard)
  - 3 deferred topics (pre-existing)
  - 1 archived project topic (notebooklm-pipeline — new Archived/ scan catch)
  - 2 synthesis density (architecture + historical-figures — empty Synthesis by design)

**Actions Taken:**
- Ran 5-reviewer peer review with synthesis
- Implemented 10 remediation items (3 must-fix, 7 should-fix)
- Fixed 3 instances of `return` vs `return 0` under `set -e` (silent abort bug)
- vault-check now has 17 checks (added Check 20: source-index validation)

**Current State:**
- Phases 1-3 complete + peer review remediation complete
- Phase 4 (automation integration) remains deferred
- A11 (bidirectional topics/Core validation) flagged high-priority for Phase 4 planning
- 4 deferred topics warnings (3 original + 1 from Archived/ scope expansion)

**Files Modified:**
- `_system/scripts/vault-check.sh` — Check 20 added, Checks 17/18/21 improved, extract_field hardened, 3 `return 0` fixes, file cache, Archived/ scan scope
- `_system/docs/file-conventions.md` — wikilink convention section added
- `Domains/Learning/moc-philosophy.md` — "2 notes" → "1 note"
- `Projects/knowledge-navigation/reviews/` — review note + raw JSON responses (5 reviewers)

**Compound:**
- **Pattern confirmed:** `[ test ] || return` under `set -euo pipefail` is a silent-abort trap. Bare `return` inherits the non-zero exit code from the failed `[` test, which `set -e` treats as a fatal error. Always use `return 0` explicitly. This should be added to vault-check authoring guidance and MEMORY.md.
- **Convention codified:** Wikilink convention (bare for unique, path-prefixed for ambiguous) was documented in file-conventions.md — previously an implicit rule from Session 2's run-log.
- **Peer review signal:** Grok produced the most valuable unique findings this round (body structure validation, bidirectional drift). Consistent with the calibration note in peer-review-config.md — Grok is earning its place at $0.02-0.04/review.
- **Routing:** A11 (bidirectional validation) → Phase 4 planning backlog. When automated placement pass is built, evaluate whether bidirectional enforcement is still needed.

## 2026-03-07 — Archival

Phase 4 (automation integration) evaluated and declined as a standalone project:
- A11 (bidirectional validation) is ~20 lines of vault-check bash — ad hoc addition if needed
- Automated MOC placement is convention-level, not project-level
- Deferred topic monitoring (3 single-note topics) is a compound-step check

Phases 1-3 delivered the full navigable knowledge layer: 4 MOCs, source index schema + POC, 5 new vault-check rules (17-21), 65-file topics backfill, peer review + 10-item remediation. Infrastructure is operational.

**Compound:** No new patterns. Phase 4 scope confirms the "ceremony budget" principle — the remaining automation is lower leverage than just doing it manually when creating notes.
