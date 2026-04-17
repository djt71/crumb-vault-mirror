---
project: tess-v2
type: migration-spec
domain: software
status: draft
created: 2026-04-17
updated: 2026-04-17
task: TV2-057d
phase: 4b
depends_on:
  - TV2-057b
  - TV2-057c
source: tv2-057-promotion-integration-note.md §4.4; src/tess/classifier.py; contracts/daily-attention.yaml; scripts/daily-attention.sh; _openclaw/scripts/daily-attention.sh
tags:
  - migration
  - promotion
  - daily-attention
---

# TV2-057d — `daily-attention` migration to staged-then-promoted

> **Purpose.** Input document for TV2-057d execution. Captures the audit of how `daily-attention` currently produces its canonical artifact, specifies the target post-057d behavior, enumerates the wrapper/script changes, and documents rollback. Written now so the audit doesn't have to be re-derived when TV2-057d starts.
>
> **Scope.** `daily-attention` only. `vault-health` migration is deferred to TV2-040 (ownership transfer from OpenClaw). `connections-brainstorm` reclassified to Class C in TV2-057b (no canonical promotion — no migration needed).

---

## 1. Current state (as of 2026-04-17, TV2-057b landing)

### 1.1 Control flow

1. **LaunchAgent:** `com.tess.v2.daily-attention` (StartInterval 1800s) invokes the contract runner with `contracts/daily-attention.yaml`.
2. **Runner:** executes `scripts/daily-attention.sh` (the Tess v2 wrapper) via `command_exit_zero` test.
3. **Wrapper (`scripts/daily-attention.sh:22`):** shells out to `/Users/tess/crumb-vault/_openclaw/scripts/daily-attention.sh` — the OpenClaw production script.
4. **OpenClaw script (`_openclaw/scripts/daily-attention.sh`):**
   - Idempotency check at `:53` — if `$VAULT_ROOT/_system/daily/{YYYY-MM-DD}.md` exists, exit 0 immediately.
   - Otherwise: gather context (goal-tracker, projects, calendar, Apple snapshots, signals), call Anthropic Opus, generate plan, write atomically:
     - `:516` `mkdir -p "$DAILY_DIR"` (= `$VAULT_ROOT/_system/daily`)
     - `:518` `tmp_artifact=$(mktemp "${DAILY_DIR}/.tmp.XXXXXX")`
     - `:520` `mv "$tmp_artifact" "$OUTPUT_FILE"` (= `$DAILY_DIR/{YYYY-MM-DD}.md`)
5. **Tess v2 wrapper continuation:** captures exit code, writes `attention-log.yaml` (execution log, not the canonical artifact) to `$STAGING_PATH`.
6. **Runner (contract):** verifies `attention-log.yaml` via `file_exists`, parses YAML, checks status — **contract passes or fails on the log, not on the canonical artifact.** The canonical plan is already in place by the time the contract resolves.

### 1.2 The direct-to-canonical landmine

The canonical write (`_system/daily/{date}.md`) happens inside the OpenClaw script invocation, bypassing the Tess v2 staging directory entirely. TV2-057 integration-note §4.4 flagged this pattern explicitly: **turning on promotion for Class A is not merely "add a state transition" — it changes the write path.**

Additional observations from the audit:

- The OpenClaw script already uses **atomic rename** (`mktemp` + `mv`) to land the canonical artifact. So the file-level write is already crash-safe. The problem is only the destination directory.
- Idempotency is enforced by checking canonical-path existence. This is a once-per-day invariant the OpenClaw scheduler relies on across its 48 runs/day (every 1800s).
- Contract-level test assertions (`attention-log.yaml`) are decoupled from canonical-artifact assertions, which means a future change to where the artifact lands does not break the test shape — the log is always in staging.

### 1.3 Why this survives under TV2-057b

The TV2-057b contract schema for `daily-attention` now declares:

```yaml
canonical_outputs:
  - staging_name: "attention-plan.md"
    destination: "_system/daily/{date}.md"
```

The classifier treats it as Class A on that signal. But the runner's Class A terminal path (STAGED) is the same as it was before: no `PromotionEngine` call, no lock acquisition. The wrapper continues to direct-write the artifact to canonical. Operationally, **nothing observable changes today** — 057b is pure schema + declarative setup. The landmine is untriggered.

TV2-057c (lock acquisition at `_cmd_run` entry) wires the `WriteLockTable` but, per its scope, only **acquires** locks — it does not promote. Locks held around a direct-to-canonical write still serialize concurrent writes correctly (the lock uses the destination path), though they are a redundant safety net over the mktemp+mv already performed by the OpenClaw script.

TV2-057d is where the landmine triggers: the moment the Tess v2 promotion engine is expected to move the artifact from `_staging/` to canonical, the wrapper must stop writing directly to canonical.

---

## 2. Target state (post-TV2-057d)

### 2.1 Redirect the canonical write to staging

Introduce an environment variable that overrides `DAILY_DIR` in the OpenClaw script:

```bash
# _openclaw/scripts/daily-attention.sh (:22, modified)
DAILY_DIR="${ATTN_OUT_DIR:-$VAULT_ROOT/_system/daily}"
```

Default behavior is unchanged (OpenClaw continues to write canonical on its cadence). Tess v2 wrapper sets the override:

```bash
# scripts/daily-attention.sh — Tess v2 wrapper, new env export
export ATTN_OUT_DIR="${STAGING_PATH:?STAGING_PATH required}"
```

With `ATTN_OUT_DIR` set to `$STAGING_PATH`, the OpenClaw script's mktemp+mv atomic rename now lands `attention-plan.md` inside the contract's staging directory (same filename — the OpenClaw script uses `${TODAY}.md`, so the naming needs to change OR the staging_name in `canonical_outputs` needs to match `{YYYY-MM-DD}.md`).

**Decision needed during 057d:** filename convention.
- **Option A:** Rename the staging-side artifact to a fixed `attention-plan.md`, promotion engine substitutes `{date}` in destination on promotion.
- **Option B:** Keep the date-stamped filename (`2026-04-17.md`) in staging, promotion engine does a straight rename to canonical (destination already has the date baked in).

Option A matches the schema shape documented in `tv2-057-promotion-integration-note.md` §2.4 (staging filename is stable, destination templates expand). Recommended. Requires a 1-line change to the OpenClaw script's `OUTPUT_FILE` derivation.

### 2.2 Promotion engine invocation

Post-Ralph-loop, the Class A branch in `cli.py _cmd_run` (wired by TV2-057d):

1. Builds a promotion manifest from the contract's `canonical_outputs` (`staging_name` → `staging_path`/`staging_name`, `destination` after placeholder substitution).
2. Calls `PromotionEngine.promote()` — atomically moves `_staging/TV2-035-C1/attention-plan.md` to `_system/daily/2026-04-17.md`.
3. On success, transitions `STAGED → COMPLETED`, releases write-lock, cleans up staging.
4. On `PromotionResult.success=False` with `conflicts[]`, transitions to `QUALITY_FAILED` or aborts per `staging-promotion-design.md` §4.5.

### 2.3 Idempotency — who checks what

The OpenClaw script's line-53 idempotency check (`$VAULT_ROOT/_system/daily/{date}.md` exists → skip) must continue to read from the **canonical** path, not the staging override. Otherwise every Tess v2 run regenerates the plan (staging is empty per-run).

Amendment to OpenClaw script:

```bash
# :53 — idempotency check reads CANONICAL path even when write redirects to staging
CANON_CHECK_FILE="${CANON_CHECK_FILE:-$VAULT_ROOT/_system/daily/${TODAY}.md}"
if [[ -f "$CANON_CHECK_FILE" && "$DRY_RUN" == "false" ]]; then
    echo "Artifact already exists: $CANON_CHECK_FILE — skipping."
    cron_set_cost "0.00"
    cron_finish 0
fi
```

Default (`CANON_CHECK_FILE` unset) behaves as today. Tess v2 wrapper explicitly sets it to the canonical path so idempotency continues to work across both platforms.

### 2.4 Lock path

Write-lock acquired by TV2-057c at `_cmd_run` entry uses the `destination` (after placeholder substitution) from `canonical_outputs`. For `daily-attention`, that's `_system/daily/{date}.md`. Lock granularity is per-file, which prevents a same-day concurrent Tess+OpenClaw run from racing on the canonical artifact. (In practice OpenClaw is decommissioned at TV2-040, but during the transition both platforms may still fire.)

---

## 3. Change inventory

| File | Change | Owner |
|---|---|---|
| `_openclaw/scripts/daily-attention.sh` | Line 22: `DAILY_DIR="${ATTN_OUT_DIR:-$VAULT_ROOT/_system/daily}"`. Line 23: `OUTPUT_FILE="$DAILY_DIR/${OUTPUT_NAME:-${TODAY}.md}"`. Line 53: `CANON_CHECK_FILE="${CANON_CHECK_FILE:-$VAULT_ROOT/_system/daily/${TODAY}.md}"` + replace `$OUTPUT_FILE` with `$CANON_CHECK_FILE` in the idempotency block. | TV2-057d |
| `scripts/daily-attention.sh` (Tess v2 wrapper) | Add `export ATTN_OUT_DIR="$STAGING_PATH"`, `export OUTPUT_NAME="attention-plan.md"`, `export CANON_CHECK_FILE="$VAULT_ROOT/_system/daily/${TODAY}.md"` before the `bash "$SCRIPT"` call. | TV2-057d |
| `src/tess/cli.py _cmd_run` | After Ralph loop terminates STAGED for a Class A contract, call `PromotionEngine.promote()` with a manifest built from `contract.canonical_outputs`. Transition STAGED → COMPLETED on success. | TV2-057d |
| `src/tess/promotion.py` | Ensure `build_manifest()` understands `CanonicalOutput` entries and substitutes `{date}`, `{week}`, `{timestamp}` placeholders. | TV2-057d (likely already supported; verify) |
| Tests | New integration test: run daily-attention contract end-to-end, assert artifact ends up in `_system/daily/{date}.md` via promotion, not via direct OpenClaw-script write. Mock or stub the Anthropic API call. | TV2-057d |

---

## 4. Rollback procedure

### 4.1 Trigger conditions

- Promotion fails with an unrecoverable conflict not covered by partial-promotion logic.
- Canonical artifact appears in the wrong path (e.g., staging leftover that wasn't cleaned up).
- Idempotency breaks (multiple artifacts per day).
- `duration_ms` regressions that suggest the promotion path is slow enough to affect the next cadence tick.

### 4.2 Rollback steps

1. **Immediate** — revert the Tess v2 wrapper to not export `ATTN_OUT_DIR` / `OUTPUT_NAME`:
   ```bash
   # scripts/daily-attention.sh — rollback
   unset ATTN_OUT_DIR OUTPUT_NAME
   bash "$SCRIPT"
   ```
   (Or `git revert` the commit that added the exports.) OpenClaw script's defaults kick in; canonical write resumes as before.

2. **Cli.py rollback** — disable the Class A promotion branch via feature flag or revert the commit. Contract runner falls back to pre-057d behavior (leave STAGED as terminal).

3. **Verify** — `ls -la _system/daily/$(date +%Y-%m-%d).md` confirms canonical artifact is in place. `sqlite3 ~/.tess/state/run-history.db "SELECT outcome FROM run_history WHERE service='daily-attention' ORDER BY started_at DESC LIMIT 3;"` confirms rows resume as `staged`.

### 4.3 Data integrity

No data loss from a rollback. The canonical artifact path (`_system/daily/{date}.md`) is the same before and after 057d — only the write path (direct vs. through-staging) differs. Rolling back restores direct-write; the same-day artifact is unaffected.

---

## 5. Pre-flight checklist for 057d execution

- [ ] TV2-057c (lock acquisition at `_cmd_run` entry) landed and validated in production.
- [ ] Confirm OpenClaw plist `ai.openclaw.daily-attention` is either unloaded (TV2-040 complete) or its cadence does not race with Tess v2's inside a single 1800s window.
- [ ] Snapshot `~/.tess/state/run-history.db` (for pre-change outcome distribution).
- [ ] Verify `PromotionEngine` placeholder substitution covers `{date}` (read `src/tess/promotion.py` `build_manifest` implementation; add if absent).
- [ ] Write the integration test **first** (a failing test before the cli.py change) so the test proves the migration works.
- [ ] Deploy to a single cadence cycle; verify artifact appears in `_system/daily/` via promotion logs, not via OpenClaw-script logs.
- [ ] Soak for ≥24h before considering 057d closed.

---

## 6. Follow-ups owned by other tasks

- **TV2-057c** — R1 vs R2 lock-retry semantics. Every Tess v2 `daily-attention` run will now execute a SQLite `BEGIN IMMEDIATE` transaction. Contention against concurrent LaunchAgents (e.g., `connections-brainstorm` or other same-destination services) is a 057c test concern.
- **TV2-057f** — Class A backfill disposition for daily-attention's 596 legacy staged rows. Separate from TV2-057a's bulk sentinel backfill (Class C only).
- **TV2-040** — Decommission `ai.openclaw.daily-attention` plist entirely. Once done, the OpenClaw-script fork from §3 becomes Tess-v2-owned.
