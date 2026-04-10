---
type: reference
domain: software
status: active
created: 2026-02-20
updated: 2026-02-20
tags:
  - kb/software-dev
related:
  - docs/vault-restructure-discussion-20260220.md
topics:
  - moc-crumb-architecture
---

# Vault Restructure — Open Question Analysis

Analysis of the five open questions from the [vault restructure discussion](vault-restructure-discussion-20260220.md). Research-only — no changes implemented.

---

## Q1: Does `_system/` consolidation conflict with vault-check or skill context contracts?

**Answer: Yes — significant conflicts. All fixable, but the surface area is large.**

### Critical dependencies (hard breaks if moved without updates)

| Component | Issue | Severity |
|-----------|-------|----------|
| `.claude/settings.json` SessionStart hook | Hardcoded `bash scripts/session-startup.sh` | CRITICAL — all session startups fail |
| `.claude/settings.json` permission rules | `Bash(bash scripts/vault-check.sh*)` and `Bash(bash scripts/*)` won't match new paths | CRITICAL — permission denials |
| `scripts/vault-check.sh` line 175 | Enumerates `Projects Domains docs` — won't find `_system/docs` | CRITICAL — docs skip validation |
| `scripts/session-startup.sh` lines 70, 137 | Hardcoded check for `docs/overlays/overlay-index.md` | CRITICAL — overlay loading fails silently |

### Skill contract breaks (6 of 11 skills affected)

| Skill | Refs to update | Impact |
|-------|---------------|--------|
| **peer-review** | 9 refs (config, denylist, output dirs) | Non-functional — can't load config or write reviews |
| **audit** | 10 refs (solutions, failure-log, signals, overlays) | Silent failure — vault health checks don't run |
| **inbox-processor** | 4 refs (file-conventions, spec schema) | Broken — companion notes miss schema, naming violates conventions |
| **action-architect** | 6 refs (overlays, estimation, patterns) | Degraded — no overlays, no estimation history |
| **systems-analyst** | 5 refs (overlays, patterns, personal-context) | Degraded — no overlay routing, patterns not saved |
| **writing-coach** | 6 refs (overlays, patterns, rubrics) | Degraded — no writing patterns, no rubrics |

Skills unaffected: checkpoint, obsidian-cli, sync, meme-creator, startup (also breaks but it's the hook wrapper).

### Overlay index — cascading dependency

`docs/overlays/overlay-index.md` is referenced by every skill with an overlay-check step. The overlay files themselves are referenced by the index using `docs/overlays/*.md` paths. The entire `docs/overlays/` subtree must move together, and the index's internal references must update.

### Conclusion for Q1

No *architectural* conflicts — the consolidation is structurally sound. But the *operational* surface area is:
- **2 critical config files** (settings.json, both scripts)
- **6 skill definitions** (50+ path references total)
- **CLAUDE.md** (~25 path references)
- **AGENTS.md** (7 path references)
- **Design spec** (180+ internal references — bulk find-replace)

The settings.json hook is the hard sequencing constraint: it must update *before* the move, or the first session post-move will fail with no startup hook.

---

## Q2: Full scope of path references needing updates

### Summary table

| File | Count | Priority | Type |
|------|-------|----------|------|
| `CLAUDE.md` | ~25 | CRITICAL | Policy/routing |
| `.claude/settings.json` | 3 | CRITICAL | Config (hook + perms) |
| `scripts/vault-check.sh` | 10+ | CRITICAL | Validation logic |
| `scripts/session-startup.sh` | 4 | CRITICAL | Startup logic |
| `docs/crumb-design-spec-v1-7-1.md` | 180+ | CRITICAL | Master spec |
| `AGENTS.md` | 7 | HIGH | Directory guide |
| `.claude/skills/peer-review/SKILL.md` | 9 | HIGH | Skill procedure |
| `.claude/skills/audit/SKILL.md` | 10 | HIGH | Skill procedure |
| `.claude/skills/action-architect/SKILL.md` | 6 | HIGH | Skill procedure |
| `.claude/skills/systems-analyst/SKILL.md` | 5 | HIGH | Skill procedure |
| `.claude/skills/writing-coach/SKILL.md` | 6 | HIGH | Skill procedure |
| `.claude/skills/inbox-processor/SKILL.md` | 4 | HIGH | Skill procedure |
| `.claude/skills/startup/SKILL.md` | 2 | HIGH | Skill procedure |
| `docs/file-conventions.md` | Multiple | HIGH | Conventions |
| `docs/peer-review-skill-spec.md` | 10 | MEDIUM | Skill spec |
| `docs/separate-version-history.md` | 40+ | MEDIUM | History |
| `Projects/*/progress/run-log.md` | 5+ | LOW | Historical (no functional impact) |

### Internal cross-references (move together, safe as-is)

Files within `docs/` referencing other `docs/` files move together — relative references survive. But absolute-from-root references (`docs/solutions/`, `docs/overlays/`) within docs files *do* need updating to `_system/docs/...`.

### Log files (session-log.md, failure-log.md, signals.jsonl)

If logs move to `_system/logs/`:
- `session-log.md` is referenced in CLAUDE.md (~5 refs), 3 skills, session-startup.sh, vault-check.sh
- `failure-log.md` is referenced in CLAUDE.md (2 refs), audit skill, design spec (~15 refs)
- `signals.jsonl` is referenced in CLAUDE.md (1 ref), audit skill, design spec (~10 refs)

### Estimated migration effort

Mechanical find-replace covers most changes. The design spec (180+ refs) is the largest single file but is amenable to bulk `docs/` → `_system/docs/` replacement. Total unique files requiring edits: **~15–18 files**, with **~300+ individual path references**.

---

## Q3: Project classification — directory, metadata, or both?

### Current state

6 projects, all flat under `Projects/`:

| Project | Domain | Proposed class |
|---------|--------|---------------|
| crumb-tess-bridge | software | system |
| inbox-processor | software | system |
| openclaw-colocation | software | system |
| notebooklm-pipeline | learning | knowledge |
| think-different | learning | knowledge |
| customer-intelligence | career | knowledge |

No `project_class` field exists in any `project-state.yaml` today.

### Option analysis

**Subdirectories (`Projects/system/`, `Projects/knowledge/`):**
- Solves Obsidian browsing friction visually
- Breaks vault-check.sh (enumerates `Projects/*/`), inbox-processor (globs `Projects/*/attachments/`), CLAUDE.md scaffold protocol, archive protocol, and 54+ spec references
- High migration burden (40+ files), ongoing maintenance cost for every new project

**Metadata-only (`project_class: system | knowledge` in YAML):**
- Zero path changes, zero script/skill breakage
- Filterable via Obsidian search or Dataview (plugin not currently installed)
- Doesn't solve the browsing experience without a complementary discovery mechanism
- Consistent with spec §5.5 philosophy ("knowledge base is a view, not a location")

**Hybrid (metadata + MOC index note):**
- All benefits of metadata (zero breakage)
- A `Projects/index.md` or similar provides curated grouping visible in Obsidian
- Can be auto-generated by a future skill
- Dataview installation is optional enhancement, not prerequisite

### Recommendation: metadata + MOC index

The subdirectory approach costs 40+ file edits for modest visual gain. Metadata is zero-cost to add and future-proofs for Dataview. A lightweight index note bridges the Obsidian UX gap today. This can be implemented in a single session:

1. Add `project_class: system | knowledge` to 6 `project-state.yaml` files
2. Create `Projects/index.md` listing projects by class
3. Optionally add vault-check validation for the field

---

## Q4: Which docs/ files should migrate to project directories?

### Inventory results

**System-wide (stay in docs/, move to `_system/docs/` under Proposal A):**
- `crumb-design-spec-v1-7-1.md` — master system spec
- `context-checkpoint-protocol.md` — workflow protocol
- `convergence-rubrics.md` — quality rubrics
- `file-conventions.md` — schema/naming rules
- `peer-review-config.md` — reviewer config
- `peer-review-skill-spec.md` — skill design spec
- `personal-context.md` — user strategic context
- `skill-authoring-conventions.md` — skill writing guide (mislabeled `project: crumb`, should be null)
- `claude-code-ssh-setup.md` — infrastructure reference
- `separate-version-history.md` — spec appendix
- `overlays/*` — all overlay files (system routing)
- `solutions/*` — all reusable patterns
- `protocols/inline-attachment-protocol.md` — cross-project protocol (mislabeled `project: crumb`, should be null)

**Project-affiliated (candidates for symlink into project dirs):**

| File | Project | Action |
|------|---------|--------|
| `openclaw-colocation-spec.md` | openclaw-colocation | Symlink to `Projects/openclaw-colocation/design/specification.md` |
| `openclaw-colocation-spec-summary.md` | openclaw-colocation | Symlink to `Projects/openclaw-colocation/design/specification-summary.md` |
| `openclaw-crumb-reference.md` | openclaw-colocation | Symlink to `Projects/openclaw-colocation/design/integration-reference.md` |
| `crumb-studio-migration.md` | openclaw-colocation | Move or symlink — runbook created during that project |

Per MEMORY.md guidance: symlink pre-existing artifacts rather than moving, to preserve commit-message and cross-reference stability.

**Logs/operational (move to `_system/logs/` under Proposal A):**
- `failure-log.md`
- `signals.jsonl`

**Frontmatter corrections needed (independent of restructure):**
- `skill-authoring-conventions.md`: change `project: crumb` → `project: null`
- `protocols/inline-attachment-protocol.md`: change `project: crumb` → `project: null`

---

## Q5: Stale/scratch files at vault root

| File | Size | Last modified | Status | Recommendation |
|------|------|---------------|--------|---------------|
| `print-mode-results.txt` | 3.3 KB | 2026-02-19 | Gitignored, not tracked | **Remove** — CTB-001 test artifact, findings already documented |
| `print-mode-test7-results.txt` | 2.8 KB | 2026-02-19 | Gitignored, not tracked | **Remove** — CTB-001 test artifact, findings already documented |
| `setup-vault-structure.sh` | 1.5 KB | 2026-02-18 | Tracked in git | **Move to `_system/migration/`** — bootstrap script with doc value |
| `.zprofile` | 118 B | 2026-02-19 | Gitignored, not tracked | **Verify with user** — keychain unlock script, may belong in `~/.zprofile` |

The two print-mode files are safe to `rm` immediately — they're gitignored and contain no data not already captured in CTB-001 docs. The `.zprofile` needs user input on whether it's vault-specific or misplaced home-dir config.

---

## Cross-Cutting Observations

### Migration sequencing matters

If both Proposal A (`_system/` consolidation) and the project classification work proceed:
1. Clean up stale root files first (independent, low risk)
2. Add `project_class` metadata + create project index (independent, low risk)
3. Create symlinks for project-affiliated docs (independent, low risk)
4. Fix frontmatter misclassifications (independent, low risk)
5. Execute `_system/` consolidation last (high surface area, requires atomic commit)

Steps 1–4 can happen in any order and provide immediate value regardless of whether step 5 proceeds.

### The spec update question

The design spec (v1.7.1) has 180+ path references. If `_system/` consolidation proceeds, a spec revision (v1.8 or v2.0) should accompany it. Bulk find-replace handles most changes, but the directory structure diagram in §2.1 needs manual redrawing and the changelog needs a new entry.

### Cost-benefit summary

| Action | Effort | Value | Risk |
|--------|--------|-------|------|
| Remove stale root files | 5 min | Low clutter | None |
| Add project_class metadata | 15 min | Moderate (future filtering) | None |
| Symlink project-affiliated docs | 10 min | Moderate (project discoverability) | Low (symlink management) |
| Fix frontmatter misclassifications | 5 min | Low (correctness) | None |
| `_system/` consolidation | 2–3 hours | High (Obsidian UX) | Medium (300+ path updates, silent failures if missed) |
