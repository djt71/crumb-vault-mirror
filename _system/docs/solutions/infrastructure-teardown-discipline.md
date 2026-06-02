---
type: solution
track: pattern
domain: software
status: active
created: 2026-06-01
updated: 2026-06-01
confidence: high
topics:
  - moc-crumb-operations
tags:
  - compound
  - infrastructure
  - decommission
  - operations
  - kb/software-dev
source_projects:
  - feed-intel-framework
  - opportunity-scout
  - mission-control
  - tess-v2
source_artifacts:
  - _system/logs/session-log.md
  - Projects/mission-control/progress/run-log.md
---

# Infrastructure Teardown Discipline

## Claim

Standing infrastructure — cron jobs, launchd agents, log writers, monitors —
accumulates faster than it is removed, because **building has a trigger
(a need) and teardown has none**. The cost is not the idle process; it is the
*false signal*: an orphaned monitor turns silence into noise, a stale freshness
check turns a deliberate shutdown into a recurring alert, and a tracked
churn-file turns a clean working tree into permanent drift. Three disciplines,
applied at teardown time, prevent the recurring class: declare an end-condition,
sweep consumers when removing a producer, and never version-control what your
own toolchain rewrites.

## Evidence

This pattern reached its promotion threshold after a third independent
recurrence (the 2026-04-25 session-log entry set the trigger explicitly:
"promote if a third instance surfaces").

- **Namespace-migration zombies (2026-04-24):** orphaned artifacts left in
  `_openclaw/` after a namespace migration — infrastructure that outlived its
  migration with no teardown step.
- **Soak monitors outliving the test (2026-04-25):** `soak-heartbeat` (15m),
  `soak-vault-check` (1h), `soak-deep-check` Hermes cron jobs plus 7 stale
  `once` jobs and a `com.tess.soak-monitor` launchd agent kept firing Telegram
  noise ~3 weeks after the tess-v2 soak test ended. 2.8 MB of orphaned load-test
  data also recovered. The test had a start trigger; nothing owned its teardown.
- **Monitoring-stack cascade (2026-06-01)** — four instances in one session:
  - `awareness-check` Check 2 fired "feed digest may be stale" every 30m because
    FIF capture was decommissioned (2026-05-28) but the *monitor watching FIF's
    output* was not. A disabled producer made its freshness check a permanent
    false alarm.
  - `com.crumb.service-status` (60s sensor) + `com.tess.v2.awareness-check`
    (LLM heartbeat) outlived the Mission Control dashboard they fed; the sensor
    became an orphan writing data nobody read.
  - `com.tess.health-check` (TMA-004 Limited Mode failover) had been broken and
    `idle_error`-ing for *months* while still loaded — nobody noticed because
    nothing swept for chronically-failing agents.
  - Six hot-churn logs were tracked in git — notably `vault-check-output.log`,
    written by the pre-commit hook *itself* — so the working tree never reached
    clean. This hid ~6 weeks of real drift (≈300 files) behind expected noise.
- **Stale-output pipelines + dual-generation cruft (2026-06-01):**
  `overnight-research` and `connections-brainstorm` decommissioned after review
  found the research pipeline had emitted a byte-identical (frozen) brief every
  Sun/Wed for ~26 days while the cron, stream rotation, and "complete" Telegram
  all read green (see failure-log 2026-06-01) — a producer broken for a month
  with nothing sweeping for stale *content*. Teardown also surfaced the
  namespace-zombie shape: **four** launchd agents across two generations
  (`ai.openclaw.*`/`com.tess.*` legacy bash + `com.tess.v2.*` dispatch-contract)
  for two services, two copies of each script, plus contracts — the migration
  to v2 never removed the legacy plists. Consumer-graph trace was clean: the only
  freshness watcher (`check_feed_freshness`) was already disabled and read a
  different dir, so no false-alarm was created. Confirms discipline 1 (no
  end-condition on a generative pipeline → frozen output goes unnoticed) and the
  migration-zombie corollary of discipline 2.

## Pattern

Apply all three at the moment infrastructure is *created* (cheapest) and
re-check them at the moment anything is *decommissioned* (highest-leverage):

1. **Declare an end-condition or teardown owner.** Any infrastructure built for
   a bounded purpose — a soak test, a migration, a spike, a dashboard feeder —
   carries in its definition either an explicit end-date, a marker file, or a
   named owner responsible for removal. A periodic sweep (audit skill /
   service-status review) flags infrastructure past its end-condition or
   chronically failing (`idle_error` for N consecutive runs). "Permanent until
   someone remembers" is the default that produces zombies.

2. **Decommissioning a producer sweeps its consumers and watchers in the same
   pass.** Before disabling a pipeline, trace its output's consumer graph. Every
   freshness check, health monitor, and dashboard widget reading that output
   becomes a false signal the instant the producer stops — a stale-data alert
   that can never clear, or a "service down" that was intentional. Disable the
   watchers *with* the producer, not when their alerts annoy someone weeks later.

3. **Never version-control artifacts your own toolchain rewrites.** A file
   written by a commit hook, a cron job, or a build step churns the working tree
   on its own schedule. Tracked, it guarantees the tree is never clean and
   provides perfect camouflage for real uncommitted work. Gitignore it (keep on
   disk) the moment you notice it dirtying the tree without a manual edit.

## When to Apply

- Standing up any cron job, launchd agent, monitor, or recurring writer —
  especially for a bounded purpose (test, migration, spike, demo).
- Decommissioning, disabling, or archiving any pipeline, service, or project —
  trace the consumer graph as a required step.
- Investigating recurring alert noise or a working tree that won't reach clean —
  these are the symptoms this discipline prevents.

## When Not to Apply

- Genuinely permanent core infrastructure (gateway, vault backup, the
  dead-man's switch) — these have no end-condition by design. Discipline 1 still
  applies as a *named owner*, but not an end-date.
- One-shot scripts that exit and leave nothing standing — no teardown surface.
- State files intentionally tracked for cross-machine continuity (e.g. cron
  cursors under a deliberately un-ignored path) — discipline 3 exempts anything
  whose tracked history is the point, not a side effect.

## Corollary

The three disciplines share a root cause: **asymmetry between creation and
removal**. Creation is pulled by a need; removal must be *pushed* by discipline
because nothing pulls it. The fix in every case is to attach the teardown
obligation to the thing at creation time — an end-date, a consumer-graph note, a
gitignore line — so removal is mechanical rather than remembered. When in doubt,
the diagnostic question is: *"If the thing this serves disappeared tomorrow,
what would notice and turn this off?"* If the answer is "nothing," it is a future
zombie.

## Related

- [[behavioral-vs-automated-triggers]] — when a discipline should be enforced by
  a hook/sweep rather than left to memory; the audit sweep in discipline 1 is a
  candidate for automation.
- [[atomic-rebuild-pattern]] — the build-side counterpart: disciplined creation
  of derived artifacts; this doc is the disciplined *removal* counterpart.
- `macos-system-notes.md` (memory) — the launchd↔login-keychain isolation that
  kept `com.tess.health-check` silently broken, an example of discipline 1's
  "chronically failing, unnoticed" failure mode.
