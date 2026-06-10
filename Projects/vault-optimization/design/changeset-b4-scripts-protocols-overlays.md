---
type: changeset-pack
project: vault-optimization
domain: software
status: active
created: 2026-06-10
updated: 2026-06-10
source: keep-set-manifest.md
tags:
  - changeset
  - b4
topics:
  - moc-crumb-operations
---

# B4 Scripts/Protocols/Overlays Changeset Pack (VO-023)

**Batch:** B4 — executes at VO-031. **Preconditions:** B0 green, Appendix A
frozen (VO-016), AS M6 sign-off verified in AS run-log.
**Drafted:** 2026-06-10 against manifest baseline 2026-06-10 (HEAD b58a3e4e).
**Batch-open staleness check (A1):** re-validate dispositions + inventory
drift diff; evidence-status changes return to operator (A2).

## Approval record

| Field | Value |
|---|---|
| Pack status | **APPROVED** |
| Approved by | operator (in-conversation question gate) |
| Date | 2026-06-10 |
| Conditions/exceptions | none — approved as drafted incl. #F5 (A3-extension keeps confirmed) |

Flagged for explicit operator attention: #F5 (qmd-index + vault-rebuild
plists resolved as A3-extension keeps — extends a prior operator decision).

## Disposition list — deletes (6 scripts + 1 plist file + 3 protocols)

Sign-off status per D1: no-evidence rows carry wholesale operator sign-off
2026-06-10; superseded rows need no per-item sign-off but sunset-tied ones
carry AS-concurrence flags (verify AS run-log concurrence at batch open).

| Item | Class | Remediation (same B4 commit) |
|---|---|---|
| batch-moc-placement.py | no-evidence (signed) | none — architecture/02:201 "Plus:" list line covered by B3 arch-cluster edit (verify applied) |
| bridge-watcher.py | superseded (AS concurrence) | vault-intake-map.md — **deleted at B3 (R9), no edit needed; verify at batch open**. architecture/02:194,201 + 03:300-310 + 04:88,94,147 — verify B3 refresh applied. crumb-deployment-runbook.md:43,469-516 — strip watcher install/ops sections |
| com.crumb.bridge-watcher.plist (parked file) | superseded | architecture/04:147 + runbook:469-516 — same edits as above (confirmed parked-only, not in LaunchAgents) |
| clear-claude-cache.sh | no-evidence (signed) | crumb-deployment-runbook.md:901 — drop reference |
| openclaw-isolation-test.sh | superseded (AS concurrence) | none |
| tess-health-check.sh | superseded (AS concurrence) | architecture/04:142 "preserved for possible repair" line removed (B3 refresh — verify); health-check*.log deletion rides B2-iii (already in storage policy) |
| vault-search.sh | superseded (AS concurrence) | none (tess-v2 design/review docs historical) |
| bridge-dispatch-protocol.md | superseded | **Order gate: CLAUDE.md:219 "Bridge Dispatch Stage Output" § must be removed first (AS-025)** — verify in AS run-log at batch open. architecture/02:143 + 03:17 — verify B3 refresh. orientation-map.md:95,151 — drop rows |
| dispatch-triage-protocol.md | superseded | architecture/02:146 — verify B3 refresh applied |
| research-brief-review-protocol.md | superseded (AS concurrence) | none |

**Cross-batch note:** several B4 consumers are edited at B3 (architecture
cluster, vault-intake-map deletion). The B4 batch-open check must verify those
B3 edits landed; if B3 has not executed, the listed edits move into this batch
(forward-fix rule).

## Disposition list — keeps (confirmations recorded at VO-023)

| Item | Status |
|---|---|
| dns-recon.sh | keep — operator decision 2026-06-10 (A2 re-review); customer-intelligence consumer stands |
| setup-crumb.sh | keep confirmed — **VO-023 verification done 2026-06-10: zero references to any delete-listed script** (grep over all 7 names, exit 1); disaster-recovery path intact |
| hallucination-detection-protocol.md | keep — resolved at VO-024 (B3 pack R13): authoritative expansion of spec §4.8 |
| inline-attachment-protocol, session-end-protocol | keep (structural) |
| All 12 remaining keep scripts (backup-status, drive-sync(+filter), knowledge-retrieve, mirror-sync, session-startup, skill-preflight, system-stats, vault-backup, vault-check, vault-gc) | keep per manifest — no pack action |

### Overlays (8) — all keep; VO-023 re-check recorded

glean-prompt-engineer re-check (manifest flag): **keep confirmed** — operator
career work surface (Infoblox enterprise-search lens); cost = one index row +
one overlay file; consistent with financial-advisor keep rationale (light
personal/work-domain lenses are cheap). No overlay deletions → no overlay
remediations. Overlay-index.md untouched at B4.

### Plists — pending rows resolved (#F5)

| Item | Resolution | Rationale |
|---|---|---|
| com.crumb.qmd-index | **keep (A3 extension)** | produces the qmd search index consumed by interactive vault search + session-report step (used today); viewing-stack adjacency — same knowledge-work-surface rationale as the A3 dashboard decision |
| com.crumb.vault-rebuild | **keep (A3 extension)** | produces the static site that A3-kept vault-web serves — deleting it dark-ends an operator-kept surface |

Both extend the operator's A3 dashboard-stack decision rather than create new
keeps — flagged #F5 for confirmation at pack approval. Manifest rows
pending→keep on approval.

## Reassignment in

`schemas/briefs/` (4 files) deletion was reassigned from B3/B4 to **B5**
(single-changeset coordination with kept-skill `brief_schema:` frontmatter
strips — A2 #3). No briefs action in this batch.

## AC check (VO-023, B4 half)

- B4 pack separately named, carries disposition list + remediation map +
  approval record ✓ (approval pending operator)
- Every delete/merge row for scripts/protocols/overlays covered ✓ (10 deletes
  remediated; 0 overlay deletes; keeps + pending resolutions recorded)
- Trigger-condition rewrites + gotchas: B5 pack scope (skills/agents) — see
  changeset-b5-skills-agents.md
