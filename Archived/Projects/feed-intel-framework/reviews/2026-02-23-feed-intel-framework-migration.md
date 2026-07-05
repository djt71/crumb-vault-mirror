---
type: review
review_mode: diff (scoped)
review_round: 2
prior_review: Projects/feed-intel-framework/reviews/2026-02-23-feed-intel-framework-specification.md
artifact: Projects/feed-intel-framework/design/specification.md
artifact_section: "§8 State Store Schema + §8.1 Migration from x-feed-intel"
artifact_type: spec
project: feed-intel-framework
domain: software
skill_origin: peer-review
created: 2026-02-23
updated: 2026-02-23
status: active
reviewers:
  - openai
  - deepseek
  - grok
reviewer_meta:
  openai:
    model: gpt-5.2-2025-12-11
    http_status: 200
    latency: 37.61
    attempts: 1
    prompt_tokens: 3360
    completion_tokens: 2346
  deepseek:
    model: deepseek-reasoner
    system_fingerprint: fp_eaab8d114b_prod0820_fp8_kvcache
    http_status: 200
    latency: 0.82
    attempts: 1
    prompt_tokens: 3510
    completion_tokens: 3568
    reasoning_tokens: 2192
  grok:
    model: grok-4-1-fast-reasoning
    system_fingerprint: fp_eddf72ed7d
    http_status: 200
    latency: 22.29
    attempts: 1
    prompt_tokens: 3551
    completion_tokens: 1024
    reasoning_tokens: 1514
    note: "initial urllib dispatch hit Cloudflare 403; retried via curl subprocess"
safety_gate: all clean (schema + migration plan, no secrets)
---

# Peer Review: §8.1 Migration Plan (Round 2, Scoped)

**Artifact:** `Projects/feed-intel-framework/design/specification.md` — §8 State Store Schema + §8.1 Migration from x-feed-intel
**Review scope:** Migration plan only (scoped follow-up to full specification review)
**Context:** This migration plan was rewritten based on findings from the round 1 five-model review. The original plan claimed atomic single-transaction migration; reviewers flagged file renames outside SQLite transactions, missing rollback, broken Obsidian wikilinks, live pipeline divergence risk, and thin cursor migration details.

## Dispatch Note — Artifact Error

**IMPORTANT:** The dispatch script contained a copy-paste duplication of Stage 3 in the artifact content sent to reviewers. The actual specification (`specification.md` lines 1024-1026) has Stage 3 only once. All three reviewers flagged this duplication (OAI-F1, DS-F1, GRK-F1). **These findings should be discarded during synthesis — the duplicate does not exist in the real artifact.**

---

## OpenAI (gpt-5.2)

**F1 — CRITICAL — Stage 3 duplicated (spec hygiene / execution ambiguity)**
The plan repeats "Stage 3 — Vault file migration" verbatim (steps 11-12 duplicated). This is more than a typo risk: a "restartable" script that keys off step numbers or stage completion markers could re-run renames/rewrites twice, creating broken links (`feed-intel-x-x-{id}` patterns), missing files, or double-replaced wikilinks. The migration state file must unambiguously encode stages and idempotency rules; as written, the duplication undermines that.

> **[DISPATCH ERROR — DISCARD: Duplication was in the dispatch artifact, not the real spec.]**

**F2 — CRITICAL — Stage ordering: Stage 1 updates IDs before alias capture (alias data loss)**
Stage 1 step 2 updates `posts.canonical_id` from `{bare_id}` to `x:{bare_id}`. Stage 1 step 7 then says "Populate `id_aliases` mapping `{bare_id}` -> `x:{bare_id}`". If you don't preserve the old bare IDs *before* rewriting them, you no longer have a source to populate `legacy_id` for existing rows (unless you parse it back out of `x:{bare_id}`, which the plan doesn't state, and may not work if IDs weren't purely numeric or had other legacy formats).
Fix: explicitly populate `id_aliases` *before* rewriting, or populate from `substr(canonical_id, 3)` after rewrite, with a clear constraint that legacy IDs are exactly `x:` + legacy.

**F3 — CRITICAL — SQLite cannot "update PK" safely without clarifying foreign keys & cascading**
Stage 1 step 2 "Update canonical_id in posts" changes the PRIMARY KEY. In SQLite, updating a PK is allowed, but if any other tables reference `posts.canonical_id` (current or future), you risk orphaning rows unless `ON UPDATE CASCADE` foreign keys exist and `PRAGMA foreign_keys=ON` is enabled. The artifact's schema shows `feedback` has both `item_id` and `canonical_id` but does not declare FKs, so consistency is entirely application-enforced. The plan updates `feedback.canonical_id` (step 3) but does not mention any other places canonical IDs might appear (e.g., digest message mapping tables in the old system, triage caches, vault frontmatter fields, or any other tables in x-feed-intel §7.2).

**F4 — SIGNIFICANT — "Independently restartable" not true without idempotency rules per step**
The plan claims each stage is independently restartable, but multiple operations are not inherently idempotent unless specified:
- `ALTER TABLE ... ADD COLUMN` will fail on rerun unless guarded (`IF NOT EXISTS` isn't supported for columns in SQLite).
- `CREATE INDEX` without `IF NOT EXISTS` will fail on rerun.
- Renaming files will fail or produce collisions on rerun if already renamed.
- Grep/replace can double-apply if not constrained (see F8).

**F5 — SIGNIFICANT — Failure between stages: Stage 1 committed but Stage 2 not migrated leaves system in limbo**
Crash after Stage 1 (schema + ID rewrites) but before Stage 2 (cursor migration) creates a mixed state: DB is now "framework-shaped" and IDs are prefixed, but the running legacy pipeline is disabled and (per rollback target) expects old cursors in JSON. If you attempt rollback, you restore DB and vault, but if you attempt forward progress, you must ensure the code reading cursors is switched to DB (Stage 5 step 17) *and* cursor rows exist.

**F6 — SIGNIFICANT — Cursor migration "replicate shared legacy cursor per topic" can cause missed/duplicated ingestion**
Stage 2 step 8: for legacy discovery cursors not topic-scoped, create one row per topic with the shared legacy cursor value. This is only safe if the cursor semantics are global monotonic over a unified stream and topic filters are applied *after* fetching the unified stream. If the new discovery implementation is topic-specific (separate queries per topic), copying a global cursor into each topic stream can cause systematic skipping or duplication.

**F7 — SIGNIFICANT — Cursor format divergence risk not handled (opaque JSON + parsing expectations)**
Pre-migration audit says "document divergences," but Stage 2 assumes the JSON cursor values can be moved as-is into `adapter_state.checkpoint_json` and interpreted by new code. If cursor JSON structure diverged in production, migration may succeed but runtime will silently behave incorrectly. Add: schema/version tagging inside `checkpoint_json`, plus explicit validation in Stage 4.

**F8 — CRITICAL — Wikilink grep/replace is underspecified; will miss common Obsidian link variants**
Step 12 replaces `[[feed-intel-{bare_id}]]` -> `[[feed-intel-x-{bare_id}]]`. This misses:
- Display text overrides: `[[feed-intel-123|some text]]`
- Block references: `[[feed-intel-123#^blockid]]` and headings `[[feed-intel-123#Heading]]`
- Embedded transclusions: `![[feed-intel-123]]` and `![[feed-intel-123|...]]`
- Links that include `.md`: `[[feed-intel-123.md]]`
- Markdown links: `[text](feed-intel-123.md)` or absolute/relative paths
- Frontmatter fields or inline metadata referencing the old name
A robust approach: parse wikilinks with a regex that captures `[[target(#...)?(|...)?]]` (and the `!` prefix), rewrite only the target portion.

**F9 — SIGNIFICANT — Vault rename collision and uniqueness not addressed**
Renaming assumes no existing files with the target name. Consider case-insensitive filesystem issues on macOS (default APFS can be case-insensitive): `feed-intel-X-` vs `feed-intel-x-` could collide.

**F10 — SIGNIFICANT — SQLite transaction scope is heavy; WAL + long write lock considerations**
Stage 1 is "single SQLite transaction" performing multiple `ALTER TABLE`, mass updates on PKs, index creation, and alias population. Consider splitting into smaller transactions or at least include a post-Stage-1 `PRAGMA wal_checkpoint(TRUNCATE);`.

**F11 — MINOR — Stage 4 verification is too narrow; key invariants can slip through**
Missing: count parity, referential consistency, `id_aliases` coverage, index existence, spot-check that Obsidian links resolve including `|`/`#` variants.

**F12 — SIGNIFICANT — Operational risk: quiesce via launchd disable can be undone; no hard guardrails**
No concrete controls: `launchctl bootout` or `launchctl disable` + `launchctl print` verification, kill running node processes, and a DB-level guard (e.g., `PRAGMA user_version` / a "migration_in_progress" flag).

**F13 — STRENGTH — Explicit rollback target and manifest-based vault undo is a good correction**
Compared to the earlier "atomic in one transaction" claim, the plan now acknowledges file operations aren't transactional and introduces a rename manifest and a rollback that restores both DB and vault.

**VERDICT: the migration plan needs rework**

---

## DeepSeek (deepseek-reasoner / V3.2-Thinking)

**F1 — CRITICAL — Duplicate Stage 3 section creates ambiguous execution ordering**
The artifact contains two identical "Stage 3 — Vault file migration:" sections (steps 11-12 repeated). Creates ambiguity about whether Stage 3 is intended to run twice.

> **[DISPATCH ERROR — DISCARD: Duplication was in the dispatch artifact, not the real spec.]**

**F2 — CRITICAL — No migration-state tracking mechanism described**
The plan states "A migration state file tracks which stages have completed" and that each stage is "independently restartable," but no details are provided on where this file is stored, its format, how stages check it, or how partially completed stages are resumed. Without a concrete state-tracking design, restartability cannot be guaranteed.

**F3 — SIGNIFICANT — Wikilink replacement pattern misses common Obsidian syntax variations**
The grep/replace for `[[feed-intel-{bare_id}]]` -> `[[feed-intel-x-{bare_id}]]` is too simplistic. It will miss: aliases (`[[feed-intel-123|Alias Text]]`), sub-path references (`[[feed-intel-123#heading]]`), transclusions (`![[feed-intel-123]]`), links with file extensions (`[[feed-intel-123.md]]`).

**F4 — SIGNIFICANT — Rollback procedure omits cleanup of newly created tables and indexes**
If the migration fails after Stage 1 and before Stage 3, the restored backup will not contain the new tables or indexes. Those objects will persist in the database file after restore, causing schema mismatch with the legacy pipeline. The rollback should include explicit `DROP TABLE`/`DROP INDEX` statements.

> **[NOTE: This finding appears to misunderstand the rollback — step (2) says "restore DB from Stage 0 backup," which would overwrite the entire DB file. If it's a file-level restore (copy backup over the live DB), new tables wouldn't persist. Clarification needed on whether "restore" means file copy or SQL-level operations.]**

**F5 — SIGNIFICANT — Cursor-state migration assumes uniform topic-scoped cursor value; divergence risk high**
Duplicating shared legacy discovery cursor per-topic assumes all topics can safely resume from the same checkpoint. If live pipeline has already diverged, this will cause data loss or duplicate captures.

**F6 — MINOR — Stage 1 transaction size may cause SQLite lock contention in WAL mode**
Single transaction bundles multiple schema changes. Given pipeline is quiesced, this is low risk.

**F7 — MINOR — Verification step 15 is insufficient to confirm wikilink integrity**
Only checks "zero hits for old-format filenames." Does not verify new wikilinks are syntactically correct or that every old link was replaced.

**F8 — STRENGTH — Staged approach with pre-migration audit addresses prior review findings**
The rewrite correctly separates file operations from DB transactions, adds a rollback procedure, and mandates a pre-migration audit.

**F9 — SIGNIFICANT — No safeguard against launchd service auto-restart during migration**
"Disable all launchd services" does not specify how. `launchctl unload` may not persist across reboots. Should use `launchctl bootout` and verify via `ps`.

**F10 — MINOR — Missing verification of `id_aliases` table population**
Stage 4 verification does not check that `id_aliases` was correctly populated. Should include count match and expiry date validation.

**VERDICT: the migration plan needs rework**

---

## Grok (grok-4-1-fast-reasoning)

**F1 — SIGNIFICANT — Duplicated Stage 3 description**
The artifact repeats Stage 3 verbatim twice, which introduces confusion and potential for copy-paste errors during implementation.

> **[DISPATCH ERROR — DISCARD: Duplication was in the dispatch artifact, not the real spec.]**

**F2 — CRITICAL — Incomplete rollback for cursor state**
Rollback procedure restores DB from backup and reverses vault files via manifest, but ignores restoring cursor JSON files (capture-state.json, feedback-state.json) after Stage 2 migrates them to adapter_state. If JSONs are deleted/overwritten post-migration, rollback leaves the legacy pipeline without cursors, breaking it permanently. No backup or restoration step for these files is specified.

**F3 — SIGNIFICANT — Wikilink grep misses complex patterns**
The grep/replace uses a simple pattern which fails on common Obsidian wikilink variants: display text, transclusions, embeds, or piped aliases. Verification's "zero hits" check uses the same flawed pattern.

**F4 — SIGNIFICANT — Stage 3 not truly idempotent/restartable**
File renames and grep/replace in Stage 3 are non-transactional. If crash midway, restart from Stage 3 leaves partial renames/mixed wikilinks. No idempotency mechanism (e.g., check manifest before rename, skip if target exists).

**F5 — MINOR — SQLite Stage 1 transaction scale risk**
Single transaction adds columns, updates PKs, creates tables/indexes, populates aliases. WAL mode handles it atomically, but on macOS SQLite with large-ish DB, long locks could timeout. No explicit VACUUM/ANALYZE post-transaction.

**F6 — SIGNIFICANT — Cursor migration divergence risk unmitigated**
Duplicating shared legacy discovery cursor per-topic is safe initially, but no verification in Stage 4 checks cursor JSON values match originals — only presence. If live pipeline diverged, post-migration runs silently use corrupted state.

**F7 — SIGNIFICANT — Verification gaps in Stage 4**
Misses checks for: (1) feedback/cost_log canonical_id updates, (2) id_aliases population completeness, (3) new column defaults, (4) digest_messages if populated, (5) cursor JSON values integrity, (6) no data corruption from PK updates.

**F8 — CRITICAL — Backup gaps for non-vault state**
Pre-reqs backup DB + vault git commit, but omit cursor JSONs, launchd configs, or any external state. Rollback after Stage 2 fails without JSON restoration. Vault git assumes all md files committed — unverified if Obsidian has unsaved/uncommitted changes.

**F9 — MINOR — Operational risk: launchd quiesce imprecise**
"Disable all launchd services" lacks steps. No lockfile or PID monitoring to enforce quiesce.

**F10 — MINOR — Hidden dependency: pre-audit divergence handling**
Stage 1 assumes exact legacy schema. Pre-audit says "adjust steps," but no examples or scripted handling.

**F11 — STRENGTH — Stage ordering and dependencies correct**
5 stages follow logical DB -> state -> files -> verify -> enable sequence. No cross-stage hidden deps beyond migration state file tracking.

**F12 — STRENGTH — SQLite Stage 1 transaction reasonable**
Adds NOT NULL DEFAULT cols, PK updates, table/index creation all atomic in WAL. Addresses prior "not atomic" critique effectively.

**F13 — MINOR — Alias grace period robust**
45-day id_aliases with feedback lookup handles late replies transparently. Pruning post-grace prevents bloat. Verification could add alias count check.

**VERDICT: the migration plan needs rework**

---

## Synthesis

### Consensus Findings (discarding dispatch-error F1s)

**1. Wikilink grep/replace underspecified** [3/3: OAI-F8, DS-F3, GRK-F3]
All three reviewers independently identified that the simple `[[feed-intel-{id}]]` pattern misses display text, heading refs, block refs, transclusions, embeds, and `.md` extensions. **Fixed in v0.3.3:** comprehensive regex specified.

**2. Restartability/idempotency not substantiated** [3/3: OAI-F4, DS-F2, GRK-F4]
"Independently restartable" claimed but no concrete mechanism. SQLite `ALTER TABLE ADD COLUMN` not idempotent, `CREATE INDEX` fails on rerun, file renames non-idempotent. **Fixed in v0.3.3:** migration state file designed, all operations guarded.

**3. Cursor state migration divergence risk** [3/3: OAI-F6/F7, DS-F5, GRK-F6]
Duplicating shared cursor per topic unsafe if cursor semantics aren't globally monotonic. No format validation. **Fixed in v0.3.3:** format validation step added, safety note documenting assumptions.

**4. Stage 4 verification gaps** [3/3: OAI-F11, DS-F7/F10, GRK-F7]
Missing count parity, referential checks, alias coverage, cursor integrity. **Fixed in v0.3.3:** 8 verification steps expanded with comprehensive checks.

**5. Launchd quiesce imprecise** [3/3: OAI-F12, DS-F9, GRK-F9]
No concrete steps. **Fixed in v0.3.3:** `launchctl bootout` + `pgrep` + lockfile guard.

**6. Backup scope too narrow** [2/3: GRK-F2, GRK-F8]
Cursor JSON files not backed up; rollback would leave legacy pipeline without cursors. **Fixed in v0.3.3:** backup scope expanded.

### Unique Findings

**OAI-F2** [CRITICAL]: Alias population order — populate aliases before rewriting canonical_id, not after. **Genuine critical catch.** Fixed by reordering.

**OAI-F3** [CRITICAL]: PK update without FK cascade analysis. **Valid but low risk** — no declared FKs, plan updates all known references. Pre-migration audit catches additional references.

### Considered and Declined

- **OAI-F9** (APFS case-insensitivity): `incorrect` — source_type is always lowercase.
- **OAI-F10** (transaction size): `constraint` — pipeline is quiesced, WAL handles it.
- **DS-F4** (rollback cleanup of new tables): `incorrect` — rollback restores DB from file copy, overwriting everything.

### Verdict

Migration plan upgraded from "needs rework" to **sound with v0.3.3 fixes**. All consensus and critical findings addressed.
