---
type: design
domain: software
status: draft
created: 2026-04-01
updated: 2026-04-01
project: tess-v2
skill_origin: null
task: TV2-022
---

# Tess v2 — Staging/Promotion Lifecycle Design

Defines the complete lifecycle of executor-produced artifacts from staging through promotion to canonical vault paths. Covers directory structure, write-lock table, hash-based conflict detection, atomic promotion, crash recovery, retention/cleanup, and rollback. This is the implementation specification for AD-008 (staging-first writes), C9 (write-lock table / no promotion collisions), and the PROMOTING state from the contract lifecycle state machine (TV2-017).

## 1. Design Inputs

- Spec §8 (contract-based execution, AD-008 staging-first writes)
- Spec §2.4 (failure modes: promotion race via stale reads, silent contract drift)
- Spec C9 (write-lock table, hash-based conflict detection, atomic promotion)
- Contract schema (TV2-019): `staging_path`, `partial_promotion`, tests/artifacts referencing staging paths
- State machine (TV2-017): STAGED, QUALITY_EVAL, PROMOTION_PENDING, PROMOTING, COMPLETED states; crash-safe resumable promotion; write-lock protocol; scenario walkthroughs B/C
- Escalation storm policy (TV2-026): storm conditions may freeze promotion queue
- Queue fairness policy (TV2-027): dead-letter queue receives failed promotions; retention policy

## 2. Staging Directory Structure

### 2.1 Layout

Every dispatched contract receives an isolated staging directory:

```
_staging/
  {contract-id}/
    [executor-produced artifacts]
    .promotion-manifest.yaml     # written by promotion engine, not executor
    .rollback/                   # written by promotion engine during promotion
      [backup copies of overwritten canonical files]
```

Example for contract `TV2-033-C1`:

```
_staging/
  TV2-033-C1/
    vault-health-notes.md
    appendix-data.yaml
    .promotion-manifest.yaml
    .rollback/
      Projects/tess-v2/progress/
        vault-health-notes.md    # previous canonical version (full path preserved)
```

### 2.2 What Goes in Staging

**Included** — all executor-produced artifacts:
- Output files specified by the contract (reports, designs, code, data)
- Any intermediate files the executor needs to produce the output
- The execution result envelope (`execution-result.yaml`)

**Excluded** — these live outside the vault entirely:
- Runner logs (`~/.tess/logs/`)
- Contract ledger entries (`~/.tess/ledger/`)
- Cost/token metrics (`~/.tess/metrics/`)
- Dead-letter entries (`~/.tess/dead-letter/`)
- Write-lock table (`~/.tess/state/write-locks.db`)

The division follows the observability exclusion rule (state machine §12): staging directories are contract-scoped working space, not system telemetry.

### 2.3 Directory Lifecycle

| Contract State | Staging Directory Status |
|----------------|--------------------------|
| QUEUED | Does not exist |
| ROUTING | Does not exist |
| DISPATCHED | Created (empty) by contract runner before executor launch |
| EXECUTING | Populated by executor — all writes go here per AD-008 |
| STAGED | Sealed — executor has terminated, no further writes |
| QUALITY_EVAL | Read-only — orchestrator reads artifacts for quality evaluation |
| PROMOTION_PENDING | Read-only — awaiting promotion lock acquisition |
| PROMOTING | Active — promotion engine reads staged artifacts and writes `.promotion-manifest.yaml` and `.rollback/` |
| COMPLETED | Deleted — cleanup runs after promotion verified |
| ABANDONED | Retained or deleted per retention policy (§7) |
| DEAD_LETTER | Retained for operator review per retention policy (§7) |

### 2.4 Access Control

| Role | Permission | Scope |
|------|-----------|-------|
| Executor | Read + Write | Own contract's staging directory only |
| Runner | Read | Staging directory (for test/artifact evaluation during iteration_checking) |
| Orchestrator (Tess) | Read | Staging directory (for quality_checks during QUALITY_EVAL) |
| Promotion engine | Read + Write | Staging directory (for manifest, rollback, cleanup) |
| Other contracts | None | A contract's staging directory is never accessible to other contracts |

Access boundaries are enforced by convention in the dispatch envelope: the executor receives only its own `staging_path` and cannot discover other contracts' staging directories. The `_staging/` root is excluded from vault-context `read_paths` auto-discovery (state machine §12).

## 3. Write-Lock Table

### 3.1 Purpose

The write-lock table prevents two contracts from simultaneously claiming the right to overwrite the same canonical vault path. Write-locks gate **dispatch**, not promotion — they are acquired when a contract enters ROUTING, ensuring that no two active contracts believe they can write to the same file.

This is distinct from the promotion lock (§5.4), which gates the actual file-copy operation during PROMOTING.

### 3.2 Storage

Write-locks are stored in a SQLite database at `~/.tess/state/write-locks.db`. Bare YAML is not concurrency-safe under multi-process updates (state machine §7 design decision). SQLite provides ACID transactions for lock operations.

### 3.3 Schema

```sql
CREATE TABLE write_locks (
    path TEXT NOT NULL,
    contract_id TEXT NOT NULL,
    acquired_at TEXT NOT NULL,       -- ISO 8601 timestamp
    canonical_hash TEXT NOT NULL,    -- SHA-256 of canonical file at lock time
    file_exists INTEGER NOT NULL,    -- 1 if file existed at lock time, 0 if new file
    PRIMARY KEY (path, contract_id)
);

CREATE INDEX idx_write_locks_contract ON write_locks(contract_id);
CREATE INDEX idx_write_locks_path ON write_locks(path);
```

**Design notes:**
- Primary key is `(path, contract_id)` — one lock entry per path per contract. A contract targeting multiple files holds multiple rows.
- `canonical_hash` stores the SHA-256 hash of the canonical file at lock acquisition time. Used for conflict detection at promotion (§4).
- `file_exists` distinguishes between overwriting an existing file and creating a new one. New-file promotions skip hash comparison (there is nothing to conflict with).
- No `expires` column — locks are held until the contract reaches a terminal state (COMPLETED, ABANDONED, DEAD_LETTER). There is no time-based expiry for write-locks. Zombie lock cleanup uses contract state, not timestamps (§3.7).

### 3.4 Lock Acquisition

Lock acquisition occurs at **ROUTING time**, before dispatch. The orchestrator extracts the contract's target canonical paths from the contract definition and attempts to lock all of them.

**Target path derivation:** The contract does not explicitly list target canonical paths (its `staging_path` is staging-scoped). Target paths are derived from the contract's service interface definition, which maps staging artifacts to their canonical vault destinations. This mapping is defined per service in TV2-021a/021b.

**Acquisition procedure:**

All target-path locks are acquired in a single SQLite transaction. Partial lock acquisition is impossible.

```
BEGIN IMMEDIATE
    FOR EACH target_path IN contract.target_canonical_paths:
        -- Check for existing lock on this path
        SELECT contract_id FROM write_locks WHERE path = target_path
        IF row exists:
            ROLLBACK
            RETURN lock_denied(blocking_contract_id)
        
        -- Check for ancestor/descendant overlap (GLOB, not LIKE — see §3.4.1)
        SELECT contract_id FROM write_locks
            WHERE target_path GLOB path || '/*'    -- target is descendant of locked path
               OR path GLOB target_path || '/*'    -- locked path is descendant of target
        IF row exists:
            ROLLBACK
            RETURN lock_denied(blocking_contract_id)
        
        -- Compute canonical hash
        IF file_exists(target_path):
            hash = SHA256(read_file(target_path))
            exists = 1
        ELSE:
            hash = "NEW_FILE"
            exists = 0
        
        -- Collect for batch insert (do not insert yet)
        APPEND TO lock_rows: (target_path, contract.contract_id, NOW(), hash, exists)
    
    -- All checks passed — insert all rows atomically
    FOR EACH row IN lock_rows:
        INSERT INTO write_locks (path, contract_id, acquired_at, canonical_hash, file_exists)
            VALUES row
COMMIT
```

**All-or-nothing acquisition:** The single `BEGIN IMMEDIATE` transaction ensures that if any path cannot be locked, `ROLLBACK` releases all tentative state — no partial locks remain. The contract waits in QUEUED (not rejected) and retries on the next scheduler dispatch cycle. This prevents partial lock acquisition that could cause deadlocks between contracts needing overlapping path sets.

#### 3.4.1 Path Overlap Detection

Ancestor/descendant overlap detection uses SQLite `GLOB` with a `/*` suffix, not `LIKE` with `%`. GLOB with `/*` suffix provides separator-aware ancestor/descendant matching without SQL wildcard interference — `LIKE path || '%'` treats `Projects/foo2` as a descendant of `Projects/foo`, and SQL wildcards (`%`, `_`) in paths cause false matches.

**Path normalization requirement:** All paths are normalized (no trailing slashes, no `..`, no double slashes) before lock acquisition. Normalization is enforced at the entry point to the lock acquisition procedure.

#### 3.4.2 Dispatch modes (added 2026-04-17 — TV2-057b Amendment)

Tess v2 supports two dispatch modes:

- **Routed dispatch** (original design, §3.4): An orchestrator process acquires write-locks, then dispatches the contract to an executor. Lock acquisition transaction sits in the router.
- **Direct dispatch** (current production mode): `tess run <contract.yaml>` is invoked directly by a LaunchAgent. Lock acquisition transaction sits in `_cmd_run`'s entry path, before the Ralph loop executes.

In both modes, lock acquisition uses the same all-or-nothing `BEGIN IMMEDIATE` SQLite transaction with overlap detection (§3.4.1). In direct dispatch, **every `tess run` invocation has SQLite transaction semantics on its hot path.** Concurrent LaunchAgents attempting to acquire overlapping locks contend at the SQLite transaction level — the `BEGIN IMMEDIATE` discipline is sufficient to serialize them, but lock-denied must be handled as a retryable condition, not an error, since LaunchAgents will naturally race on cadence boundaries.

Path-overlap detection (§3.4.1) and lock-acquisition-failure behavior (§3.5) apply identically in both modes. The target-path derivation (§3.4 "Target path derivation") is now closed (§13 Open Question #1) via the `canonical_outputs` field on the contract: each entry's `destination` (after placeholder substitution — see `contract-schema.md` / TV2-057b integration-note §2.4) is the set of paths to lock.

**Open sub-question — lock-denied retry semantics (R1 vs R2).** Deferred to TV2-057c. In-invocation spin-retry (R1) masks contention behind latency; exit-and-wait-for-next-cadence (R2) surfaces it behind exit-code noise. Both are defensible; 057c picks one and implements the test plan for the chosen model. See `tv2-057-promotion-integration-note.md` §3.2.1.

**Why this is called out explicitly.** If lock acquisition silently folded into `_cmd_run` as an implementation detail, the fact that every LaunchAgent invocation now executes a SQLite transaction would get rediscovered later — likely by a contention incident. Naming it in the Amendment front-loads the consequence so the TV2-057c implementation task treats it as a known design property, not an emergent surprise.

### 3.5 Lock Acquisition Failure Behavior

When lock acquisition fails:

1. The contract remains in QUEUED state (it has not yet entered ROUTING successfully).
2. The scheduler records the blocking contract ID and path in the contract's queue metadata.
3. The contract is eligible for dispatch again on the next scheduler cycle.
4. Standard `max_queue_age` timeout applies — if the blocking lock is never released before the contract's queue age expires, the contract transitions to DEAD_LETTER with `reason: queue_timeout`.
5. The age-based priority boost from TV2-027 §4.4 still applies, ensuring lock-blocked contracts gain priority over time.

### 3.6 Lock Release

Locks are released when the owning contract reaches a **terminal state**:

| Terminal State | Lock Release Timing |
|----------------|-------------------|
| COMPLETED | After promotion verified and staging cleaned |
| ABANDONED | Immediately on state transition |
| DEAD_LETTER | Immediately on state transition |

Lock release is a single transaction:

```sql
DELETE FROM write_locks WHERE contract_id = ?;
```

All locks for a contract are released atomically. There is no per-path release.

### 3.7 Zombie Lock Cleanup

A lock becomes a zombie when the owning contract's process crashes without reaching a terminal state. The promotion engine detects zombies during its periodic sweep (§7.4):

1. Query all distinct `contract_id` values from `write_locks`.
2. For each contract ID, check the contract ledger for current state.
3. If the contract is in a terminal state but locks remain, release them (crash during cleanup).
4. If the contract does not exist in the ledger (process died before ledger update), release the locks and log a warning.
5. If the contract is in a non-terminal state, the lock is valid — leave it.

Zombie sweep runs as part of the daily cleanup job (§7.4) and at process startup.

## 4. Hash-Based Conflict Detection

### 4.1 Purpose

Hash-based conflict detection prevents the "promotion race via stale reads" failure mode (spec §2.4). Two contracts could read the same canonical file, both produce valid work, and the later promotion silently overwrites the earlier one. By hashing at lock acquisition and re-hashing at promotion, the system detects when the canonical file changed between dispatch and promotion.

### 4.2 Hash Algorithm

SHA-256. Chosen for:
- Collision resistance (no false negatives from hash collision)
- Standard library availability in both Python and shell (`sha256sum`, `shasum -a 256`)
- No performance concern — files being promoted are vault artifacts, not large binaries

### 4.3 Hash Recording Points

| Event | What Is Hashed | Where Stored |
|-------|---------------|-------------|
| Lock acquisition (ROUTING) | Canonical file at target path | `write_locks.canonical_hash` |
| Promotion start (PROMOTING) | Canonical file at target path (re-computed) | Compared against `write_locks.canonical_hash` |

### 4.4 Conflict Detection Procedure

During the PROMOTING state, **inside the promotion lock critical section** (§5.4), before any file copy begins:

```
FOR EACH operation IN promotion_manifest.operations:
    IF operation.file_exists_at_lock_time:
        current_hash = SHA256(read_file(operation.destination))
        IF current_hash != operation.hash_at_lock_time:
            CONFLICT DETECTED
            ABORT promotion
            RETURN conflict_info(path, expected_hash, actual_hash)
    ELSE:
        -- File was new at lock time. Check that no one created it since.
        IF file_exists(operation.destination):
            CONFLICT DETECTED
            ABORT promotion
            RETURN conflict_info(path, "NEW_FILE", SHA256(read_file(operation.destination)))
```

### 4.5 Conflict Resolution

When a hash conflict is detected:

1. **All promotion operations are aborted** — no partial promotion occurs.
2. The promotion lock (§5.4) is released.
3. Write-locks are NOT released — the contract still intends to write to these paths.
4. The contract transitions PROMOTING → QUALITY_EVAL for re-evaluation against the current canonical state.
5. The write-lock table entries for this contract are updated with the **new** canonical hashes.
6. The promotion attempt counter is incremented.
7. If `promotion_attempts >= max_promotion_attempts` (default: 3), the contract transitions to DEAD_LETTER with `reason: promotion_contention`.

Re-evaluation in QUALITY_EVAL may determine:
- The staged artifacts are still valid against the new canonical state (re-promote).
- The staged artifacts conflict with the new canonical state (QUALITY_FAILED).
- The staged artifacts are subsumed by changes already in the canonical file (ABANDONED with `reason: subsumed`).

## 5. Atomic Promotion Procedure

### 5.1 What "Atomic" Means Here

Filesystem operations are not transactional. "Atomic" in this design means: **all artifacts from a contract promote, or none do, from the perspective of the contract lifecycle.** Readers of the vault may observe intermediate states during the copy sequence. The guarantee is crash-safety with idempotent recovery, not strict isolation.

This is an explicit design decision documented in state machine §15: "Honest about reader-visible partial state; idempotent recovery."

### 5.2 Promotion Sequence

The complete promotion sequence, annotated with crash recovery behavior:

```
1. PROMOTION_PENDING → PROMOTING: Acquire promotion lock (§5.4)
   ↓ lock acquired
2. Verify hashes (§4.4) — MUST occur inside the promotion lock critical section
   to prevent TOCTOU races (another process modifying canonical files between
   hash check and copy).
   ↓ all hashes match (if mismatch → abort, release lock, handle conflict per §4.5)
3. Write promotion manifest (status: pending, phase: pending); fsync manifest
   -- CRASH HERE: recovery sees phase "pending" → restart from step 1
4. Update manifest phase to "backing_up"; fsync manifest
   Back up canonical files to .rollback/ (§6.1), preserving canonical-relative paths
       Mark each operation backed_up: true after its backup completes; fsync manifest
   -- CRASH HERE: recovery sees phase "backing_up" → check per-operation backed_up
   --   flags to determine which backups completed, complete the rest, then proceed
5. Update manifest phase to "copying" (status: "in_progress"); fsync manifest
   -- CRASH HERE: recovery sees phase "copying" → resume from step 6
6. FOR EACH operation in manifest:
       Write staging bytes to temp file in destination directory → fsync temp file
         → atomic rename to destination → fsync destination directory
       Mark operation as promoted: true in manifest; fsync manifest
       -- CRASH HERE: recovery resumes from next unpromoted operation
   Per-file promotion uses write-to-temp + atomic rename for crash safety.
   Manifest is fsynced after each phase transition.
7. Verify all promoted files (re-hash destination against staging source)
   -- CRASH HERE: recovery re-runs verification
8. Update manifest status to "completed"; fsync manifest
   -- CRASH HERE: recovery sees "completed" → proceed to step 9
9. Update contract ledger state to COMPLETED
   -- Ledger MUST be updated to COMPLETED before write-locks are released,
   -- preventing competing contracts from dispatching against stale state.
   -- CRASH HERE: recovery sees ledger COMPLETED → proceed to step 10
10. Release write-locks (§3.6)
11. Release promotion lock (§5.4)
12. Clean staging directory (opportunistic)
    -- CRASH HERE: orphaned staging dir cleaned by periodic sweep
```

### 5.3 Promotion Manifest Schema

```yaml
# File: _staging/{contract-id}/.promotion-manifest.yaml
contract_id: "TV2-033-C1"
status: "pending"              # pending | in_progress | completed | failed
phase: "pending"               # pending | backing_up | copying | verifying | completed | failed
created_at: "2026-04-01T14:30:00Z"
promotion_attempt: 1           # increments on each attempt (max: 3)
operations:
  - source: "_staging/TV2-033-C1/vault-health-notes.md"
    destination: "Projects/tess-v2/progress/vault-health-notes.md"
    hash_at_lock_time: "a1b2c3d4..."
    hash_at_promotion: "a1b2c3d4..."    # re-verified at step 2
    file_existed_at_lock: true
    backup_path: "_staging/TV2-033-C1/.rollback/Projects/tess-v2/progress/vault-health-notes.md"
    backed_up: false            # set to true after backup copy completed
    promoted: false             # set to true after successful copy
  - source: "_staging/TV2-033-C1/appendix.yaml"
    destination: "Projects/tess-v2/progress/appendix.yaml"
    hash_at_lock_time: "NEW_FILE"
    hash_at_promotion: "NEW_FILE"
    file_existed_at_lock: false
    backup_path: null           # no backup for new files
    backed_up: false            # always false for new files (no backup needed)
    promoted: false
```

Per-operation `backed_up` flag enables deterministic crash recovery during the backup phase. The top-level `phase` field tracks which step the promotion is in, allowing recovery to determine precisely where to resume without inspecting individual operation states.

### 5.4 Promotion Lock

The promotion lock is a **separate mechanism** from write-locks. Write-locks gate dispatch (preventing two contracts from targeting the same path). The promotion lock gates the actual file-copy operation (preventing two promotions from interleaving their file operations).

**Implementation:** A global mutex at `~/.tess/state/promotion.lock`, implemented as an `flock`-based advisory lock on a sentinel file. Only one promotion can be in progress at any time across all contracts.

**Why a global lock, not per-path:** Promotions are fast (copy a handful of files). The total promotion duration is measured in milliseconds to low seconds. A global lock is simpler and eliminates the possibility of deadlock between contracts with overlapping path sets. Per-path locking would add complexity without meaningful throughput benefit at expected vault operation volume.

**Timeout:** 60 seconds. If the promotion lock is not acquired within 60 seconds (another promotion is in progress and appears stuck), the contract transitions PROMOTION_PENDING → QUALITY_EVAL for re-evaluation. The stuck promotion will either complete or be recovered by crash recovery.

### 5.5 Partial Promotion (from QUALITY_FAILED)

When a contract enters QUALITY_FAILED with `partial_promotion: promote_passing`:

1. The orchestrator identifies which artifacts individually passed quality checks.
2. A filtered promotion manifest is created containing only the passing artifacts.
3. The filtered manifest follows the same promotion procedure (§5.2): hash verification, backup, copy, verify.
4. Failing artifacts remain in staging with a dead-letter entry describing what failed and why.
5. The contract's convergence record notes `outcome: partial_promotion`.

Partial promotion is still atomic within the passing subset: all passing artifacts promote together, or none do. A crash during partial promotion follows the same recovery path.

## 6. Rollback Mechanism

### 6.1 Rollback Data

Before overwriting any canonical file, the promotion engine copies the current canonical version to `_staging/{contract-id}/.rollback/`, preserving the full canonical-relative directory structure. Rollback paths preserve the full canonical-relative directory structure to prevent basename collisions (e.g., two files `foo/spec.md` and `bar/spec.md` would both map to `.rollback/spec.md` under a basename-only scheme).

```
_staging/TV2-033-C1/.rollback/
  Projects/tess-v2/progress/
    vault-health-notes.md         # canonical version before promotion
  # (no entry for appendix.yaml — it was a new file)
```

For new files (no previous canonical version), rollback means deletion of the promoted file. The manifest records `file_existed_at_lock: false` for these, signaling the rollback procedure to delete rather than restore.

### 6.2 Rollback Window

Rollback data is retained for a configurable window after successful promotion:

| Configuration | Default | Description |
|---------------|---------|-------------|
| `rollback_retention_hours` | 24 | Hours after promotion that `.rollback/` is preserved |

After the rollback window expires, the `.rollback/` directory is cleaned up by the periodic sweep (§7.4). The staging directory root `_staging/{contract-id}/` is deleted at this time (the main artifacts were already cleaned immediately after promotion; only `.rollback/` persisted).

### 6.3 Rollback Procedure

Rollback is **operator-initiated only**. The system never automatically rolls back a successful promotion — reversing a promotion requires understanding why.

**Command:** `tess rollback <contract-id>`

**Procedure:**

```
1. Verify rollback data exists at _staging/{contract-id}/.rollback/
   IF NOT: ABORT — rollback window expired or staging already cleaned
2. Read promotion manifest to get the operation list
3. Acquire promotion lock (§5.4) — rollback is a promotion-level operation
4. FOR EACH operation IN manifest WHERE promoted == true:
       IF operation.file_existed_at_lock:
           Copy .rollback/{canonical-relative-path} → operation.destination
       ELSE:
           Delete operation.destination  # remove newly created file
5. Release promotion lock
6. Update contract state: COMPLETED → ROLLED_BACK (a terminal sub-state of COMPLETED)
7. Log rollback to contract ledger with operator identity and reason
8. Write-locks are NOT re-acquired — the rollback does not re-activate the contract
9. Clean rollback data
```

**ROLLED_BACK** is a ledger annotation, not a state machine state. The contract remains terminal. If the work needs to be redone, a new contract is created.

### 6.4 Rollback Limitations

- Rollback restores the **pre-promotion** canonical state. If the canonical file was modified after promotion (by another contract or by the operator), rollback will overwrite those post-promotion changes. The operator must understand this before proceeding.
- Rollback does not unwind side effects. If the contract triggered Telegram notifications, email labels, or other irreversible operations, those are not reversed.
- Rollback of partial promotions restores only the artifacts that were promoted. Artifacts that remained in staging (quality-failed) are unaffected.

## 7. Retention and Cleanup

### 7.1 Retention Policy

| Contract Terminal State | Staging Artifacts | .rollback/ Data | Retention |
|------------------------|-------------------|-----------------|-----------|
| COMPLETED | Deleted immediately after promotion verified | Retained for `rollback_retention_hours` (default 24h) | Rollback data cleaned after window expires |
| DEAD_LETTER (with staging) | Preserved for operator review | N/A (promotion never happened) | 30 days (aligns with TV2-027 §5.3) |
| DEAD_LETTER (no staging) | N/A | N/A | Entry only — 14 days (TV2-027 §5.3) |
| ABANDONED | Configurable | N/A | 7 days default |
| QUALITY_FAILED → DEAD_LETTER | Preserved for review | N/A | 30 days |

### 7.2 ABANDONED Contract Retention

Abandoned contracts (operator cancellation, superseded by new contract) retain staging for a configurable period to allow the operator to inspect what the executor produced before the contract was cancelled.

| Configuration | Default | Description |
|---------------|---------|-------------|
| `abandoned_staging_retention_days` | 7 | Days to retain staging for abandoned contracts |

### 7.3 Cleanup Mechanism

Staging cleanup is performed by a **periodic sweep**, not inline with contract execution. This keeps the hot path (dispatch → execute → promote) fast and avoids coupling cleanup failures to contract lifecycle.

**Sweep schedule:** Daily at 03:00 local time (low-activity period).

**Sweep procedure:**

```
1. Scan _staging/ for all contract directories
2. FOR EACH directory:
       Look up contract_id in ledger
       IF contract is COMPLETED:
           IF .rollback/ exists AND age > rollback_retention_hours:
               Delete .rollback/
           IF no .rollback/ AND main artifacts still present:
               Delete entire staging directory (cleanup after promotion was interrupted)
       IF contract is DEAD_LETTER:
           IF age > dead_letter_staging_retention (30 days):
               Archive staging to ~/.tess/dead-letter/archive/{contract-id}/
               Delete staging directory
       IF contract is ABANDONED:
           IF age > abandoned_staging_retention_days (7 days):
               Delete staging directory
       IF contract NOT IN ledger:
           Log warning: orphaned staging directory
           IF directory age > 7 days:
               Delete (likely from process crash before ledger write)
3. Report: directories cleaned, space reclaimed, orphans found
```

### 7.4 Startup Sweep

In addition to the daily sweep, a startup sweep runs when the Tess orchestrator process starts:

1. Scan for in-progress promotion manifests (§8.1 crash recovery).
2. Scan for zombie write-locks (§3.7).
3. Scan for orphaned staging directories (no corresponding ledger entry).
4. Report findings to the operator log.

## 8. Crash Recovery

### 8.1 Promotion Crash Recovery

On startup, the promotion engine scans all staging directories for `.promotion-manifest.yaml` files:

| Manifest Phase | Recovery Action |
|----------------|-----------------|
| `pending` | Promotion never started. Delete manifest. Contract re-enters PROMOTION_PENDING (staging artifacts are intact). Re-verify hashes before re-attempting. |
| `backing_up` | Backup phase was interrupted. Check per-operation `backed_up` flags to determine which backups completed. Complete backup for operations where `backed_up: false` and `file_existed_at_lock: true`. Then advance to `copying` phase and resume from step 5 of §5.2. |
| `copying` | Copy phase was interrupted. Check which operations are marked `promoted: true`. For promoted operations: verify destination file hash matches staging source. For unpromoted operations: resume copy (write-to-temp + atomic rename). After all operations verified/completed, advance to `verifying` phase. |
| `verifying` | Verification was interrupted. Re-run verification for all operations. If all pass, advance to `completed`. |
| `completed` | Promotion succeeded but cleanup was interrupted. Update ledger to COMPLETED (if not already), release write-locks, release promotion lock, clean staging. |
| `failed` | Promotion was explicitly aborted (hash conflict). Release locks. Contract is already in QUALITY_EVAL or DEAD_LETTER. Clean up manifest. |

### 8.2 Destination Verification During Recovery

When recovering a `copying` or `verifying` phase promotion, the engine must handle the case where a promoted file's destination was subsequently modified:

1. For each operation marked `promoted: true`: compute SHA-256 of the destination file.
2. Compare against the SHA-256 of the staging source file.
3. If they match: operation is clean, proceed.
4. If they do not match: **external modification detected during crash window**. This violates AD-001 (vault authority — Tess is the sole writer to canonical paths). The promotion is marked `failed`, all locks released, and the contract enters DEAD_LETTER with `reason: external_canonical_modification`.

The system does not attempt automatic recovery from AD-001 violations. These require operator investigation.

### 8.3 Lock Recovery

Write-lock and promotion-lock recovery are handled by the startup sweep (§7.4):

- **Write-locks:** Zombie detection (§3.7) releases locks for contracts in terminal states or missing from the ledger.
- **Promotion lock:** `flock`-based locks are automatically released when the holding process terminates. No manual recovery needed. If the lock file exists but no process holds the lock (stale file), `flock` will acquire it normally.

## 9. Configuration

All configurable parameters in one place:

```yaml
# File: ~/.tess/config/staging-promotion.yaml
staging:
  root_path: "_staging/"                    # Vault-relative path for staging directories
  
write_locks:
  db_path: "~/.tess/state/write-locks.db"   # SQLite database path
  
promotion:
  lock_path: "~/.tess/state/promotion.lock"  # flock sentinel file
  lock_timeout_seconds: 60                   # Max wait for promotion lock
  max_promotion_attempts: 3                  # Hash-conflict retries before dead-letter
  hash_algorithm: "sha256"                   # Hash algorithm for conflict detection
  
rollback:
  retention_hours: 24                        # Hours to retain .rollback/ after promotion
  
retention:
  abandoned_staging_days: 7                  # Days to retain staging for abandoned contracts
  dead_letter_staging_days: 30               # Days to retain staging for dead-lettered contracts
  orphan_threshold_days: 7                   # Age before orphaned staging dirs are cleaned
  
cleanup:
  schedule: "03:00"                          # Daily cleanup sweep time (local)
  
escalation_storm:
  freeze_promotions: false                   # Whether L3 storm freezes pending promotions
  # Note: L1/L2 storm levels do not affect in-flight promotions.
  # L3 (dispatch suspend) freezes new PROMOTION_PENDING entries but
  # allows in-progress promotions to complete.
```

## 10. Scenario Walkthroughs

### 10.1 Scenario A: Two Contracts Targeting Same File

**Setup:** Contract C1 targets `Projects/foo/design/spec.md` for a formatting update. Contract C2 targets the same file for a content addition. C1 arrives first.

**Step-by-step:**

1. **C1 enters ROUTING.** Orchestrator extracts target path: `Projects/foo/design/spec.md`. Write-lock acquisition: no existing lock on this path. Lock acquired. `canonical_hash` = `aaa111` (SHA-256 of current `spec.md`). C1 proceeds to DISPATCHED.

2. **C2 enters ROUTING.** Orchestrator extracts target path: `Projects/foo/design/spec.md`. Write-lock acquisition: path already locked by C1. Lock denied. C2 returns to QUEUED with metadata `blocked_by: C1, blocked_path: Projects/foo/design/spec.md`.

3. **C1 executes.** Ralph loop runs. Executor writes formatted `spec.md` to `_staging/C1/spec.md`. Tests pass. C1 transitions EXECUTING → STAGED → QUALITY_EVAL.

4. **C2 waits in QUEUED.** Scheduler cycles. On each cycle, C2 attempts lock acquisition, fails (C1 still holds lock). C2's queue age advances; priority boost begins after 25% of `max_queue_age`.

5. **C1 quality passes.** QUALITY_EVAL → PROMOTION_PENDING. Promotion lock acquired. Hash re-check (inside lock): current canonical hash = `aaa111` = lock-time hash. No conflict. Manifest written. Backup of current `spec.md` to `.rollback/Projects/foo/design/spec.md`. Staging `spec.md` copied to canonical path (write-to-temp + atomic rename). New canonical hash = `bbb222`. Ledger updated to COMPLETED. Write-locks released. Promotion lock released. Staging cleaned (except `.rollback/` retained for 24h). C1 → COMPLETED.

6. **C2 lock now available.** Next scheduler cycle: C2 attempts lock acquisition. Path `Projects/foo/design/spec.md` has no lock. Lock acquired. `canonical_hash` = `bbb222` (the post-C1 version). C2 proceeds to DISPATCHED.

7. **C2 executes.** Executor receives current canonical content (post-C1 formatting) via `read_paths`. Produces content addition. C2 → STAGED → QUALITY_EVAL → PROMOTION_PENDING. Hash re-check: `bbb222` matches. Promotion proceeds. C2 → COMPLETED.

**Key property:** C2 never executes against stale content. The write-lock forces C2 to wait until C1 completes, then C2 dispatches with the updated canonical file.

### 10.2 Scenario B: Interrupted Promotion Mid-Write

**Setup:** Contract C1 has 3 artifacts to promote: `report.md`, `appendix.md`, `data.yaml`. C1 has passed QUALITY_EVAL.

**Step-by-step:**

1. **PROMOTION_PENDING.** Promotion lock acquired. Hash verification (inside lock): all 3 canonical paths match lock-time hashes.

2. **Manifest written:**
   ```yaml
   status: pending
   phase: pending
   operations:
     - source: _staging/C1/report.md
       destination: Projects/foo/report.md
       backed_up: false
       promoted: false
     - source: _staging/C1/appendix.md
       destination: Projects/foo/appendix.md
       backed_up: false
       promoted: false
     - source: _staging/C1/data.yaml
       destination: Projects/foo/data.yaml
       backed_up: false
       promoted: false
   ```

3. **Backup phase.** Manifest phase → `backing_up`. Current canonical `report.md` copied to `.rollback/Projects/foo/report.md` (marked `backed_up: true`). `appendix.md` copied to `.rollback/Projects/foo/appendix.md` (marked `backed_up: true`). `data.yaml` is a new file (no backup needed, `backed_up` stays false). Manifest phase → `copying`, status → `in_progress`.

4. **Copy phase begins.**
   - `report.md`: write to temp file in `Projects/foo/`, fsync, atomic rename to `Projects/foo/report.md`, fsync directory. Manifest updated: `promoted: true`.
   - `appendix.md`: same procedure. Manifest updated: `promoted: true`.
   - **PROCESS CRASHES** before `data.yaml` copy.

5. **Vault state at crash:**
   - `report.md` — new version (from C1)
   - `appendix.md` — new version (from C1)
   - `data.yaml` — does not exist (was a new file, never copied)
   - Promotion lock released automatically (process died, `flock` released)
   - Write-locks still held (SQLite rows remain)

6. **Process restarts. Startup sweep runs.**
   - Finds `_staging/C1/.promotion-manifest.yaml` with `phase: copying`.
   - Scans operations:
     - `report.md`: `promoted: true`. Verify: SHA-256 of `Projects/foo/report.md` matches SHA-256 of `_staging/C1/report.md`. Match confirmed. Clean.
     - `appendix.md`: `promoted: true`. Same verification. Clean.
     - `data.yaml`: `promoted: false`. Resume: write-to-temp + atomic rename `_staging/C1/data.yaml` → `Projects/foo/data.yaml`. Mark `promoted: true`.
   - All operations verified. Manifest phase → `completed`.
   - Update ledger to COMPLETED.
   - Release write-locks.
   - Release promotion lock.
   - Clean staging directory (except `.rollback/` retained for 24h).
   - Operator notified: "Promotion for C1 recovered after crash. All artifacts verified."

**Key property:** The manifest provides an idempotent resume point. Completed operations are verified (not re-executed), and incomplete operations are finished. No data is lost.

### 10.3 Scenario C: Canonical File Changed Since Dispatch

**Setup:** Contract C1 targets `Projects/foo/design/spec.md`. Danny manually edits the same file while C1 is executing.

**Step-by-step:**

1. **C1 enters ROUTING.** Write-lock acquired. `canonical_hash` = `aaa111`.

2. **C1 dispatched and executing.** Executor reads the lock-time version of `spec.md` (hash `aaa111`) via `read_paths` and produces updated content in staging.

3. **Danny edits `spec.md` directly** (via Obsidian or another editor). The canonical file now has hash `ccc333`. This is a direct edit outside Tess's control — it does not go through the write-lock system.

4. **C1 completes execution.** STAGED → QUALITY_EVAL. Quality checks pass (orchestrator evaluates staged artifacts against contract criteria, not against the now-changed canonical file).

5. **QUALITY_EVAL → PROMOTION_PENDING.** Promotion lock acquired. Hash re-check begins (inside lock):
   - `canonical_hash` from write-lock table: `aaa111`
   - Current SHA-256 of `Projects/foo/design/spec.md`: `ccc333`
   - **HASH MISMATCH DETECTED.**

6. **Conflict resolution.**
   - Promotion aborted. No files copied.
   - Promotion lock released.
   - Write-lock entries updated with new canonical hash `ccc333`.
   - Promotion attempt counter incremented (now 1 of 3).
   - Contract transitions PROMOTING → QUALITY_EVAL for re-evaluation.

7. **Re-evaluation in QUALITY_EVAL.** Orchestrator re-evaluates C1's staged artifacts against the new canonical state. Three possible outcomes:
   - **Still valid:** C1's changes are additive (e.g., adding a section that Danny's edit didn't touch). QUALITY_EVAL passes → PROMOTION_PENDING → hash re-check (now `ccc333` matches) → PROMOTING → COMPLETED.
   - **Conflicting:** C1's changes overlap with Danny's edit (same section modified). QUALITY_EVAL fails → QUALITY_FAILED → routes via `partial_promotion` policy.
   - **Subsumed:** Danny's edit already includes what C1 was going to add. QUALITY_EVAL determines no-op → ABANDONED with `reason: subsumed`.

**Key property:** The hash check prevents C1 from silently overwriting Danny's changes. The re-evaluation gives the orchestrator a chance to assess whether C1's work is still valid in the context of the new canonical state.

## 11. Interaction with Other Designs

| Component | Interface Point | This Design's Responsibility |
|-----------|----------------|------------------------------|
| State machine (TV2-017) | PROMOTION_PENDING, PROMOTING states | Defines the file operations that occur during these states |
| Contract schema (TV2-019) | `staging_path`, `partial_promotion` | Consumes staging_path for directory creation; implements partial_promotion policy |
| Escalation storm (TV2-026) | L3 dispatch suspend | L3 freezes new PROMOTION_PENDING but does not interrupt active PROMOTING |
| Queue fairness (TV2-027) | Dead-letter queue, retention policy | Aligns staging retention with dead-letter retention from TV2-027 §5.3 |
| Contract runner (TV2-031b) | Staging directory creation at DISPATCHED | Runner creates the directory; this design defines the structure |
| Observability (TV2-025) | Vault write log | Every promotion writes to `~/.tess/logs/vault-writes.yaml` |

## 12. Design Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Write-lock granularity | Per-file with ancestor/descendant overlap check | Prevents both file-level and directory-level promotion collisions |
| Write-lock acquisition timing | At ROUTING (before dispatch) | Prevents executor from doing wasted work on a locked path |
| Write-lock storage | SQLite (not YAML) | Concurrency-safe under multi-process updates |
| Write-lock expiry | None (state-based release only) | Time-based expiry could release locks prematurely during long executions |
| Hash algorithm | SHA-256 | Standard, collision-resistant, fast for vault-sized files |
| Promotion lock scope | Global (not per-path) | Promotions are fast; global lock is simpler and deadlock-free |
| Promotion guarantee | Crash-safe resumable (not strictly atomic) | Filesystem has no transactions; manifest provides idempotent recovery |
| Rollback mechanism | Operator-initiated only | Automatic rollback requires understanding context the system doesn't have |
| Rollback window | 24 hours configurable | Balances disk usage against recovery need |
| Cleanup mechanism | Periodic sweep (not inline) | Keeps hot path fast; cleanup failures don't block contract lifecycle |
| Zombie lock detection | Contract-state-based, not time-based | Avoids premature release; respects long-running contracts |
| Staging access | Convention-enforced via dispatch envelope | No filesystem-level ACLs needed for single-user Mac environment |

## 13. Open Questions

1. ~~**Target path derivation mechanism.**~~ **CLOSED 2026-04-17 by Amendment AB (TV2-057b).** Mapping lives on the contract YAML as a `canonical_outputs` list, each entry specifying a `staging_name` (filename in `staging_path/`) and a `destination` (vault-relative canonical path with placeholder substitution for `{date}`, `{week}`, `{timestamp}`). Schema shape, validation rules, and classifier-seam rationale: `spec-amendment-AB-canonical-outputs.md`. Inheritance mechanics: C2 (generation-time bake-in — the field lives directly on each contract, not resolved at runtime from `service-interfaces.md`). Absence means Class C (side-effect only, no promotion); an empty list is rejected at load.

2. **Promotion ordering under queue fairness.** When multiple contracts are in PROMOTION_PENDING simultaneously, should promotion order respect priority classes? Current design: FIFO (first to reach PROMOTION_PENDING promotes first). The global promotion lock serializes all promotions regardless of priority.

3. **Metrics for promotion health.** TV2-025 (observability) should track: promotions per hour, hash conflicts per day, average promotion duration, rollback frequency. These are not defined here — they belong in the observability design.
