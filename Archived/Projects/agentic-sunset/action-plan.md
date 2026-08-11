---
type: action-plan
skill_origin: action-architect
project: agentic-sunset
domain: software
status: active
created: 2026-06-10
updated: 2026-06-10
topics:
  - moc-crumb-operations
tags:
  - action-plan
  - decommission
sources:
  - specification-summary.md
  - design/teardown-design.md
  - design/service-inventory.md
---

# agentic-sunset — Action Plan

Milestones map 1:1 to teardown-design phases A–G. Task IDs AS-010+ (spec §Task
Decomposition IDs AS-001–009 were provisional; this register supersedes them).
Global invariants: every step disable+archive (no deletion); vault backup never lapses;
plists retire to git-tracked `_system/archive/launchagents-retired/` (= restore path).

## M1 — Pre-flight (Phase A)

### Snapshot, sweep prep, risk verification
Tasks: AS-010, AS-011, AS-012

**Success criteria:** restore snapshot committed; healthchecks.io check paused with zero
false alerts; drive-sync stale-source question answered with evidence.
**Dependencies:** none — first work. AS-011 is a hard gate for M2.

## M2 — Daemon teardown (Phase B)

### The big switch-off
Tasks: AS-013, AS-014, AS-015, AS-016

**Success criteria:** zero `ai.*`/`com.tess.v2.*` labels loaded; Hermes/llama/Ollama down,
ports 8080/11434 closed; 24h quiet (no Telegram, no alerts, keep-set green).
**Dependencies:** M1 complete (AS-011 especially).

## M3 — Plumbing consolidation (Phase C)

### One clean com.crumb.* generation, no backup gap
Tasks: AS-017, AS-018, AS-019

**Success criteria:** drive-sync runs from danny path, crontab empty, Drive copy fresh;
backup + backup-status relabeled and verified firing; simplified vault-health live with
zero `_openclaw/` dependencies. A 3 AM backup succeeds on the first night after relabel.
**Dependencies:** AS-017 ← AS-012 (can run early — stale-sync fix is urgent);
AS-018/019 ← M2 quiet window.

## M4 — Runtime archive + resurrection test (Phase D)

### Make the disable durable
Tasks: AS-020, AS-021, AS-022

**Success criteria:** README-ARCHIVED breadcrumbs in all 7 runtime locations; post-reboot
`launchctl list` exactly matches the 11-label end state; tess-user residuals enumerated
and inert. AS-021/022 are operator-assisted (reboot, sudo).
**Dependencies:** M2 + M3.

## M5 — Upstream migration (Phase E)

### Replace what's worth replacing, document what's dropped
Tasks: AS-023, AS-024

**Success criteria:** daily-attention replacement live as scheduled Claude agent writing
`_system/daily/{date}.md` (dashboard panel unaffected) — or explicitly declined and
documented; upstream-migration doc covers all 5 functions from design §4.
**Dependencies:** M2 (old producer stopped first).

## M6 — Vault surgery (Phase F)

### Remove the layer from the vault's own structure
Tasks: AS-025, AS-026, AS-027, AS-028, AS-029

**Success criteria:** CLAUDE.md contains no bridge-dispatch/dead-routing references
(diff operator-approved before write — high risk gate); `_openclaw/`, `_staging/TV2-*`,
`_tess/` archived with dashboard-read paths spared and intel page still loading; working
tree reaches clean after one full scheduler cycle; skills and memory no longer describe
live agentic infra.
**Dependencies:** AS-026 ← AS-019 (cron-lib relocated first) + AS-025.

## M7 — Closeouts + soak (Phase G)

### Declare the end-condition and prove it
Tasks: AS-030, AS-031, AS-032

**Success criteria:** tess-v2 and tess-danny-migration → DONE with closeout entries;
XD table swept; 7 consecutive green soak days; compound insights routed; archival
proposals presented to operator (archival itself stays user-initiated).
**Dependencies:** all prior milestones.
