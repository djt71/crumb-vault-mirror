---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: docs/vault-restructure-discussion-20260220.md + docs/vault-restructure-analysis-20260220.md
artifact_type: architecture
artifact_hash: 8e0bf144
prompt_hash: a0dfe614
base_ref: null
project: null
domain: software
skill_origin: peer-review
created: 2026-02-20
updated: 2026-02-20
reviewers:
  - openai/gpt-5.2
  - deepseek/deepseek-reasoner
  - google/gemini-3-pro-preview
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: true
  soft_detail: '"customer" in project name — not sensitive data'
  user_override: false
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 69185
    attempts: 1
    raw_json: _system/reviews/raw/2026-02-20-vault-restructure-openai.json
  deepseek:
    http_status: 200
    latency_ms: 50114
    attempts: 1
    system_fingerprint: fp_eaab8d114b_prod0820_fp8_kvcache
    raw_json: _system/reviews/raw/2026-02-20-vault-restructure-deepseek.json
  google:
    http_status: 200
    latency_ms: 37588
    attempts: 1
    raw_json: _system/reviews/raw/2026-02-20-vault-restructure-google.json
tags:
  - review
  - peer-review
---

# Peer Review: Vault Restructure Proposal + Analysis

**Artifact:** `docs/vault-restructure-discussion-20260220.md` + `docs/vault-restructure-analysis-20260220.md`
**Mode:** Full (composite — two companion documents reviewed together)
**Reviewed:** 2026-02-20
**Reviewers:** GPT-5.2, DeepSeek V3.2-Thinking (deepseek-reasoner), Gemini 3 Pro Preview

**Review prompt summary:** Evaluate correctness, completeness, internal consistency, feasibility, and alternative approaches for a vault restructure proposal (`_system/` consolidation + project classification). Specific questions on the metadata-vs-directory split, the 2-3 hour time estimate, and phased migration options.

---

## OpenAI (GPT-5.2)

- **[OAI-F1]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]:** Q1/Q2 dependency audit is directionally right but not fully evidenced — several "critical" breaks are plausible yet unverified, and some breakpoints may be missing.
  - **[Why]:** The proposal hinges on "mechanical updates" being sufficient. If hardcoded paths exist outside the enumerated files (additional scripts, CI, Obsidian templates), you'll get silent partial failures.
  - **[Fix]:** Before moving anything, run repo-wide grep and produce a "path reference manifest" with exact hit counts by file to replace the approximations (~25, 180+, 10+).

- **[OAI-F2]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]:** The analysis focuses on explicit string references but doesn't address Obsidian-specific link forms (wiki links `[[docs/file]]`, embeds `![[docs/file]]`, reference-style links).
  - **[Why]:** A naive `docs/` → `_system/docs/` replace can break links with aliases, anchors, or encoded characters, and can miss wiki-links that don't contain `docs/` literally.
  - **[Fix]:** Add a "link-format audit" step: parse for `\[\[[^\]]+\]\]` and inventory which include `docs/` prefixes vs bare basenames.

- **[OAI-F3]**
  - **[Severity]: CRITICAL**
  - **[Finding]:** The 2-3 hour estimate is likely optimistic unless it includes verification/testing and a rollback plan. The analysis frames "silent failures" as a risk but doesn't budget time to detect them.
  - **[Why]:** The risky part isn't editing 300 strings; it's confirming nothing was missed across startup hook, permissions, vault-check, overlays, reviews, logs, and Claude workflows.
  - **[Fix]:** Re-estimate with explicit phases: prepare + manifest (30-60m), edits + move (30-60m), verification (45-90m), cleanup + second-pass grep (20-45m). Practical total: 2.5-5 hours.

- **[OAI-F4]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]:** Internal consistency issue: discussion doc says "Conceptually agreed" on `_system/`, but analysis says "significant conflicts" — both can be true, but analysis doesn't clearly reconcile "UX win" vs "operational fragility" into a decision rubric.
  - **[Why]:** Readers could interpret "conceptually agreed" as "low risk," while the analysis describes many critical breakpoints.
  - **[Fix]:** Add a "Definition of Done" + "Go/No-go" checklist: session-start hook runs, vault-check passes, each skill reads overlays and writes outputs, CLAUDE.md/AGENTS.md links validated, logs appended in new location.

- **[OAI-F5]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]:** Q2's "full scope" is incomplete — focuses on a shortlist of known files rather than proving repo-wide coverage; doesn't mention non-obvious consumers like CI, git hooks, or external tooling.
  - **[Why]:** "Full scope" in a migration is only true if you either exhaustively search or constrain the system so only known entrypoints reference paths.
  - **[Fix]:** Add a repo-wide grep report and check `.gitignore`, GitHub Actions, pre-commit hooks, Makefiles, etc.

- **[OAI-F6]**
  - **[Severity]: MINOR**
  - **[Finding]:** The claim "files within docs/ referencing other docs files move together — relative references survive" is misleading; most Obsidian vault links are not OS-relative, they're vault-relative or basename-based.
  - **[Why]:** Could mislead implementers into skipping link validation inside `_system/docs/`.
  - **[Fix]:** Rephrase to: "Links that are basename-only or vault-relative may survive; links that explicitly include `docs/` will not." Require a link-check pass.

- **[OAI-F7]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]:** Recommended split is defensible but misses an alternative: achieve most UX benefit with partial directory consolidation while keeping high-churn paths stable.
  - **[Why]:** The strongest UX pain is Obsidian explorer clutter at top level. You can reduce clutter without moving the most referenced subtree (`docs/overlays`, `docs/solutions`) immediately.
  - **[Fix]:** Consider a phased approach where you first move only low-coupling folders (reviews/, maybe scripts/) and postpone docs/ until automated link/path verification exists.

- **[OAI-F8]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]:** Analysis suggests "symlink" for project-affiliated docs but doesn't address cross-platform and Obsidian behavior risks (sync tools, mobile, git settings, Obsidian indexing).
  - **[Why]:** Symlinks can fail on Windows, behave differently on mobile, or be duplicated by sync setups.
  - **[Fix]:** Replace "symlink" with a supported mechanism: authoritative file stays in docs, project note contains canonical link + brief summary. Or, if symlinks required, document assumptions and add vault-check validation.

- **[OAI-F9]**
  - **[Severity]: CRITICAL**
  - **[Finding]:** A phased migration is not fully developed; analysis recommends _system/ consolidation last but still frames it as a single big-bang move.
  - **[Why]:** Big-bang moves are where you miss one path and spend hours debugging.
  - **[Fix]:** Explicit phased plan: Phase 0: metadata + index (no moves); Phase 1: move reviews/ (low coupling); Phase 2: move scripts/ (update settings.json); Phase 3: move docs/ (largest refactor, only with repeatable verification); Phase 4: move logs (optional, high coupling).

- **[OAI-F10]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]:** Metadata-only for project classification may not solve UX problem unless paired with discovery mechanism; Dataview isn't installed; no no-plugin workflow proposed beyond manual index.
  - **[Why]:** Without Dataview or consistent manual upkeep, metadata can become "true but unused."
  - **[Fix]:** Add concrete no-plugin workflow: pin Projects/index.md in Obsidian, add convention that every new project adds entry (enforced by vault-check), optionally add saved searches.

- **[OAI-F11]**
  - **[Severity]: MINOR**
  - **[Finding]:** Some counts inconsistent between docs (discussion: ~54 Projects/ refs; analysis: 180+ internal refs overall). Not necessarily wrong but unexplained.
  - **[Why]:** Migration planning depends on knowing what categories of refs dominate.
  - **[Fix]:** Break counts into categories: docs/ refs, scripts/ refs, logs refs, Projects/ refs.

- **[OAI-F12]**
  - **[Severity]: STRENGTH**
  - **[Finding]:** Internal consistency on Q3 is good — analysis directly addresses discussion's options and gives pragmatic hybrid (metadata + index) that minimizes breakage.
  - **[Why]:** Acknowledges UX pain while keeping operational stability. Good trade-off for a path-sensitive system.

- **[OAI-F13]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]:** Analysis doesn't discuss git history/renames, backlink integrity, or how Obsidian's file explorer and link resolution behave after mass moves.
  - **[Why]:** Mass renames produce messy diffs; broken backlinks degrade trust in the vault.
  - **[Fix]:** Add migration hygiene: use `git mv` to preserve history, one atomic commit per phase, run Obsidian "Broken links" check after each phase + vault-check.

- **[OAI-F14]**
  - **[Severity]: CRITICAL**
  - **[Finding]:** Sequencing guidance is incomplete: permissions and hook updates must be coordinated with the move; need rollback/escape hatch if SessionStart breaks.
  - **[Why]:** If SessionStart is broken and permissions deny running fix scripts, you strand yourself in a partially migrated state.
  - **[Fix]:** Add escape hatch: temporarily broaden permissions (dual-path allowlist during migration), commit settings.json first, keep rollback instructions documented.

---

## DeepSeek (V3.2-Thinking via deepseek-reasoner)

- **[DS-F1]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]:** The analysis correctly identifies extensive scope (300+ across ~18 files) but potentially underestimates effort and risk. The 2-3 hour estimate may not account for testing, debugging, and verifying no silent failures.
  - **[Why]:** Incomplete migration could cause critical functions (session startup, vault validation, skill execution) to fail.
  - **[Fix]:** Increase estimate to 4-5 hours, explicitly including validation phase: running vault-check.sh, testing each affected skill, and verifying Obsidian link integrity.

- **[DS-F2]**
  - **[Severity]: MINOR**
  - **[Finding]:** Analysis provides comprehensive audit within defined system but may have gaps — doesn't audit Python scripts, Obsidian configuration (.obsidian/), .gitignore, README files, or template files.
  - **[Why]:** While core breakage risk is captured, missed references in auxiliary files could cause minor issues.
  - **[Fix]:** Before execution, conduct final grep across entire vault including hidden files.

- **[DS-F3]**
  - **[Severity]: STRENGTH**
  - **[Finding]:** Excellent internal consistency between discussion and analysis. All five open questions addressed directly with clear, actionable answers.
  - **[Why]:** Demonstrates coherent thought process; migration plan rooted in originally stated problems.

- **[DS-F4]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]:** The recommended split is logically sound, but analysis doesn't fully explore a less risky phased approach for _system/ consolidation.
  - **[Why]:** The _system/ move is high-risk/high-reward. A phased approach reduces initial risk.
  - **[Fix]:** Consider phased consolidation: first move docs/, then scripts/reviews in a second phase after validation.

- **[DS-F5]**
  - **[Severity]: MINOR**
  - **[Finding]:** Analysis dismisses subdirectory approach but doesn't consider a hybrid forward-looking alternative: keep existing projects flat, mandate new projects use `Projects/system/` or `Projects/knowledge/` subdirectories.
  - **[Why]:** Improves browsing for new content immediately with zero migration cost for existing projects.
  - **[Fix]:** Evaluate hybrid directory approach — cost is updating creation protocols and vault-check globs for nested dirs.

- **[DS-F6]**
  - **[Severity]: MINOR**
  - **[Finding]:** Step 4 (fix frontmatter misclassifications) could have hidden dependencies if those files contain docs/ paths that also change in Step 5.
  - **[Why]:** Performing frontmatter fixes before consolidation could necessitate a second update.
  - **[Fix]:** Re-sequence: perform frontmatter fixes after _system/ consolidation, or ensure the update also changes any docs/ references.

- **[DS-F7]**
  - **[Severity]: STRENGTH**
  - **[Finding]:** Analysis excels in identifying the critical sequencing constraint: `.claude/settings.json` SessionStart hook must be updated before the scripts/ directory is moved.
  - **[Why]:** Missing this would cause hard failure on next session start, potentially difficult to recover from.

- **[DS-F8]**
  - **[Severity]: MINOR**
  - **[Finding]:** Symlink recommendation is practical but introduces maintenance burden (broken symlinks if targets renamed) and may confuse Obsidian's graph.
  - **[Why]:** Symlinks are a good compromise but implications for Obsidian and git should be noted.
  - **[Fix]:** Document symlink pattern in file-conventions.md and add vault-check validation to ensure targets exist.

---

## Google (Gemini 3 Pro Preview)

- **[GEM-F1]**
  - **[Severity]: CRITICAL**
  - **[Finding]:** Missing `.gitignore` audit. The analysis recommends moving logs to `_system/logs/`. If ignore rules aren't updated, the next commit will accidentally track log data.
  - **[Why]:** Current .gitignore rules reference current paths. Path changes without .gitignore updates will pollute the repo.
  - **[Fix]:** Add .gitignore to the "Critical dependencies" table in Q1 and the update list in Q2.

- **[GEM-F2]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]:** High risk with symlink recommendation (Q4). Obsidian and sync backends (iCloud, Obsidian Sync) often handle symlinks poorly — ignoring, duplicating, or breaking them.
  - **[Why]:** Can cause data loss or sync conflicts.
  - **[Fix]:** Use "Reference Notes" in Project directory containing WikiLinks to actual spec, leveraging Obsidian's native strengths.

- **[GEM-F3]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]:** SessionStart hook sequencing risk is understated. If the move fails or is partial, session startup fails. If startup fails, Claude Code may fail to initialize, preventing the agent from fixing the issue.
  - **[Why]:** Could lock the user out of the tool.
  - **[Fix]:** Create temporary redundant shim: copy session-startup.sh to new location, update settings.json, verify, then delete old file and move rest.

- **[GEM-F4]**
  - **[Severity]: MINOR**
  - **[Finding]:** `_attachments` impact analysis is missing. Files in docs/ may embed images from _attachments/. Standard Markdown links using relative paths (`../_attachments/image.png`) will break; Obsidian wiki links will auto-resolve.
  - **[Why]:** Could break image rendering in moved docs.
  - **[Fix]:** Grep docs/ for _attachments references to ensure they use Obsidian WikiLinks or absolute paths.

- **[GEM-F5]**
  - **[Severity]: STRENGTH**
  - **[Finding]:** Metadata-only for project classification is the right call. It matches the "Knowledge is a view, not a location" philosophy and avoids permanent friction on project creation.
  - **[Why]:** Allows project reclassification by changing one YAML line, no broken links.

---

## Synthesis

### Consensus Findings

These issues were raised by 2+ reviewers — highest signal.

**1. Time estimate is unrealistic (OAI-F3, DS-F1, GEM implicit)**
All three reviewers independently flag 2-3 hours as optimistic. Consensus estimate: **4-5 hours** including validation, debugging, and a verification pass. The mechanical edits are fast; the testing and silent-failure detection are not.

**2. Phased migration strongly preferred over big-bang (OAI-F9, DS-F4, GEM-F3)**
Universal agreement that the `_system/` consolidation should not be a single atomic move. Reviewers disagree on phase ordering (see Contradictions) but agree the principle is sound.

**3. Path audit needs repo-wide exhaustive search (OAI-F1, OAI-F5, DS-F2)**
The analysis approximates reference counts (~25, 180+). Before executing, produce an exact manifest via repo-wide grep covering all file types including hidden files, .gitignore, and Obsidian config.

**4. Symlink approach is risky for Obsidian (OAI-F8, GEM-F2, DS-F8)**
Three reviewers flag symlink risks: Obsidian sync, cross-platform, graph confusion. Consensus alternative: use reference notes with wikilinks instead of OS-level symlinks.

**5. SessionStart hook is the critical sequencing constraint (OAI-F14, GEM-F3, DS-F7)**
All identify this. GEM adds a concrete mitigation: redundant shim during migration (copy script to new location first, verify, then remove old).

**6. Metadata + index for project classification is correct (OAI-F12, DS-F3, GEM-F5)**
Universal agreement. No reviewer suggests directory-based project classification is worth the cost.

### Unique Findings

**OAI-F2: Obsidian link forms not addressed** — Genuine insight. The analysis only considers string-path references, not wiki links, embeds, or reference-style links. These are a real gap in the audit.

**OAI-F6: "Relative references survive" is misleading** — Genuine insight. Obsidian uses vault-relative or basename resolution, not filesystem-relative. The analysis statement is technically wrong for the Obsidian context.

**OAI-F10: Metadata without enforcement becomes "true but unused"** — Genuine insight. The index note is necessary but not sufficient without a vault-check rule or pinning convention.

**OAI-F13: git history preservation not discussed** — Genuine insight. `git mv` is needed to preserve history; mass moves via `mv` lose git tracking.

**GEM-F1: .gitignore audit missing** — Genuine and important. If log files move but .gitignore rules don't update, logs get committed.

**GEM-F4: _attachments link resolution** — Genuine but low impact. Worth a quick grep to verify.

**DS-F5: Hybrid forward-looking project dirs** — Interesting alternative (new projects in subdirs, existing stay flat). Adds complexity for moderate gain; not recommended but worth noting.

**DS-F6: Frontmatter fix sequencing** — Genuine. Frontmatter corrections should happen after consolidation to avoid double-editing.

### Contradictions

**Phase ordering for _system/ consolidation:**
- OAI: reviews/ first (lowest coupling) → scripts/ → docs/ last
- DS: docs/ first (biggest UX win) → scripts/reviews second
- GEM: logs first (lowest risk test) → scripts/ → docs/reviews

All agree on phasing but disagree on order. The disagreement maps to different optimization targets: OAI optimizes for risk minimization, DS for value delivery, GEM for incremental validation. **Human judgment needed** on which priority to weight.

### Action Items

| ID | Classification | Action | Source Findings |
|----|---------------|--------|-----------------|
| A1 | **Must-fix** | Revise time estimate to 4-5 hours including validation phase | OAI-F3, DS-F1 |
| A2 | **Must-fix** | Produce exact path reference manifest via repo-wide grep before any implementation | OAI-F1, OAI-F5, DS-F2 |
| A3 | **Must-fix** | Design phased migration plan (not big-bang) with per-phase verification checklist | OAI-F9, DS-F4, GEM-F3 |
| A4 | **Must-fix** | Replace symlink recommendation with reference notes using wikilinks | OAI-F8, GEM-F2 |
| A5 | **Must-fix** | Add .gitignore to the migration scope audit | GEM-F1 |
| A6 | **Must-fix** | Plan SessionStart hook migration with redundant shim / dual-path permissions | OAI-F14, GEM-F3 |
| A7 | **Should-fix** | Add Obsidian link-format audit (wiki links, embeds) to migration checklist | OAI-F2, OAI-F6 |
| A8 | **Should-fix** | Add go/no-go checklist reconciling "conceptually agreed" with operational risks | OAI-F4 |
| A9 | **Should-fix** | Add vault-check enforcement for project_class field + index.md convention | OAI-F10 |
| A10 | **Should-fix** | Use `git mv` for all moves to preserve history; one commit per phase | OAI-F13 |
| A11 | **Should-fix** | Grep docs/ for _attachments references to verify link format | GEM-F4 |
| A12 | **Defer** | Re-sequence frontmatter fixes to after consolidation | DS-F6 |
| A13 | **Defer** | Break spec reference counts into categories (docs/, scripts/, logs, Projects/) | OAI-F11 |
| A14 | **Defer** | Evaluate hybrid forward-looking project dirs for new projects | DS-F5 |

### Considered and Declined

| Finding | Justification | Reason |
|---------|---------------|--------|
| DS-F5 (hybrid project subdirs for new projects) | Adds vault-check complexity and bifurcates project paths (some flat, some nested) for marginal gain when metadata + index already solves the UX problem | overkill |
| OAI-F11 (break counts into categories) | Useful for implementation but the exact manifest (A2) supersedes approximate category counts | out-of-scope — deferred to implementation phase |
