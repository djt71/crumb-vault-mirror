---
type: design
project: vault-optimization
domain: software
status: active
created: 2026-06-10
updated: 2026-06-10
source: design/optimization-design.md
tags:
  - design
  - storage-policy
topics:
  - moc-crumb-operations
---

# VO-022 — Storage Policy

Governs B1 (Archived/) and B2 (attachments/logs, 3 sub-batches per VO-029).
Data sources: VO-021 enumeration (`archived-enumeration.md`), VO-020 system
survey, this session's audits (commands inline).

## Three-outcome distinction (spec, stated up front)

Deleting content affects three different things; this policy treats them
separately and claims only what each action actually delivers:

- **(a) Working tree** — what `find` sees and Obsidian indexes. B1+B2 shrink
  this directly: ~147 MB disk / ~880 tracked files (Archived/) + attachment
  orphans + dead logs.
- **(b) Navigation surface** — MOC rows, category taxonomy, orientation
  tables that mention dead content. Deleting files does NOT fix these;
  they are remediated as consumers in the owning batch (the A11
  Archived/-as-category list is VO-024/B3 scope; ~14 category-level
  referencing files counted at VO-021 D3).
- **(c) Repo/clone size** — `.git` (47 MB) does not shrink by deleting
  files; only history rewrite would do that. See decision below.

## (a) Working tree

### B1 — Archived/ (147 MB)

Per `archived-enumeration.md`: ~133 MB is two **untracked** `.venv` trees
(disk-only weight; never entered git). Tracked content is 14 MB / 880 files.
Procedure: extract exceptions E1–E3 → remediate consumers (D1–D4) →
`rm -rf Archived/` → vault-check → commit. Disk recovers 147 MB; the git
commit removes 880 files.

### B2 sub-batch (i) — `_attachments/` orphan sweep (low risk)

Audit (2026-06-10): `_attachments/` = 4.7 MB, **9 files** (7 tracked; the
untracked 2 are gitignored binaries, e.g. `wyner-fluent-forever.pdf` whose
companion note exists beside it). Scope is trivial. Plan: run
inbox-processor's orphan detection (companion-note check per file +
inbound-embed grep); delete only files with neither companion nor embed.
Expected yield: ≈0 — record the result either way.

### B2 sub-batch (ii) — non-md heavyweights (medium risk)

Audit command + results (2026-06-10, excludes .git/Archived/.obsidian):

```
find . -not -path "./.git/*" -not -path "./Archived/*" -not -path "./.obsidian/*" \
  -type f -size +1M -exec du -h {} + | sort -rh | head -20
```

| File | Size | Tracked | Disposition |
|---|---|---|---|
| `Projects/think-different/attachments/james-watson.jpg` | 9.1 MB | yes | keep — active project embed (companion pair pattern, 45 tracked pairs in that dir) |
| `Projects/tess-v2/scripts/.venv/.../_pydantic_core...so` | 4.0 MB | no | disk-only venv; delete rides with AS-030 tess-v2 closure (flagged to AS run-log) — not VO scope |
| `_attachments/learning/wyner-fluent-forever.pdf` | 3.9 MB | no | keep on disk — live companion (learning-plan source material); gitignored by design |

No tracked heavyweight is unowned → sub-batch (ii) expected yield: the
tess-v2 venv flag only. Re-run the audit at batch open (drift rule).

### B2 sub-batch (iii) — dead logs (producer-alive rule, low risk)

Rule: a log whose producer is decommissioned dies with the producer; a log
with a live producer is kept and rotated. `_system/logs/` audit (2026-06-10,
total ≈1 MB — weight is trivial; this is hygiene, not storage):

| Log | Size | Producer | Alive? | Disposition |
|---|---|---|---|---|
| `session-log.md` (+ `-2026-02`) | 187K + 55K | session-end protocol | yes | keep; monthly rotation per startup hook |
| `akm-feedback.jsonl` | 103K | `knowledge-retrieve.sh` (invoked by live skill-preflight hook) | yes | keep; add to rotation watch (rotate/truncate at 1 MB) |
| `mirror-sync.log`, `vault-gc.log`, `vault-check-output.log` | 76K/36K/3K | live plists/hooks | yes | keep — already gitignored hot-churn set |
| `health-check.log` | 42K | `tess-health-check.sh` (delete-listed B4; dead since 2026-06-01) | no | **delete** (already flagged in manifest) |
| `health-check-launchd.err` / `.log` | 3.6K / 0B | retired tess plist | no | **delete** |
| runtime JSONs (`ops-metrics`, `system-stats`, `llm-health`, `backup-status`) | <1K each | live plists | yes | keep — gitignored |
| `vault-audit-status.json` | <1K | audit skill step 17 (MC dashboard feed) | producer alive, consumer = stripped-dashboard question | disposition decided at VO-025 ceremony classification (zombie-producer flag already standing) |

### Log rotation policy (steady state)

- `session-log.md` / run-logs: existing monthly-rotation convention
  (startup hook detects; Claude rotates) — unchanged, reaffirmed.
- Machine-written logs (`akm-feedback.jsonl`, `mirror-sync.log`,
  `vault-gc.log`): size-triggered — truncate or rotate when >1 MB, checked
  opportunistically at audit time (audit skill), not by a new scheduled job
  (no new automation per v3 ADR).
- Dead-producer logs: deleted with their producers — standing rule going
  forward, not just this batch.

## (b) Navigation surface

Counted, then removed in B3 (VO-024 A11 list): category-level `Archived/`
references in AGENTS.md, file-conventions, archive-conventions,
spec v2-4, operator docs, architecture/02+04+05, vault-structure-reference,
Learning MOCs; plus dead MOC rows found by the VO-019 survey
(orientation-map and skills-reference rows for merged/deleted skills —
B5 remediation). Deleting files without this pass would leave the
navigation layer lying about the tree; every batch therefore carries its
consumer remediation in the same commit (D4 batch discipline).

## (c) Repo/clone size — git-history-rewrite decision

**Decision: NO history rewrite. Recorded explicitly (U4).**

Rationale: `.git` is 47 MB — healthy for a 3,200-file vault; the heaviest
artifacts (venvs) never entered history; tracked-Archived is only 14 MB
spread across history. A rewrite (filter-repo/BFG) would invalidate every
clone, break the "git history is the archive" premise that B1–B6 deletions
rely on for retrieval, and buy ~tens of MB. The aggressive-deletion strategy
*depends on* history remaining intact — rewriting it would be
self-defeating. Revisit only if `.git` exceeds ~500 MB or a secret-removal
need arises (those are new decisions, new ADR).

*(Operator confirmed 2026-06-10, in-conversation question gate — decision is
final. Per design U4 the policy records the decision either way — the
recorded decision is "no rewrite".)*

## AC check (VO-022)

1. Three-outcome distinction stated separately ✓ (a)/(b)/(c) sections
2. `_attachments` orphan-sweep plan ✓ (sub-batch i)
3. Non-md top-N audit ✓ (sub-batch ii, command + table)
4. Log rotation policy ✓ (sub-batch iii + steady state)
5. History-rewrite decision recorded explicitly ✓ (no rewrite, rationale,
   revisit conditions)
