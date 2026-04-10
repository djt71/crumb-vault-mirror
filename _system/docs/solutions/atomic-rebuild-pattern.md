---
type: pattern
domain: software
status: active
track: pattern
created: 2026-04-07
updated: 2026-04-07
tags:
  - system-design
  - reliability
  - deployment
  - compound-insight
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Atomic Rebuild Pattern

## Pattern

When regenerating a live artifact (static site, config file, search index, derived dataset), never overwrite the live copy directly. Build into a staging location, validate the staged artifact, then atomically swap staging and live. On validation failure, discard the staging artifact — the live copy is untouched.

```
Build → staging/         (live/ remains untouched)
Validate staging/        (smoke tests, schema, file count, integrity)
  ✓ Atomic rename:       staging/ ↔ live/
  ✗ Discard staging/, leave live/ as-is
```

The live artifact has a known-good state at all times. Failed builds are detectable and recoverable without heroics.

## Evidence

**vault-mobile-access `rebuild.sh` (2026-04-04):**

The Quartz static site rebuild for the iPhone-accessible vault:
1. Builds Quartz output into `public-next/`
2. Validates the build (file count, key paths exist, smoke checks)
3. Atomically renames: `public/` → `public.bak/`, `public-next/` → `public/`
4. On validation failure, discards `public-next/` and leaves `public/` serving the previous good build
5. LaunchAgent runs every 15 minutes — failed rebuilds never blank out the live site

The result: the operator never sees a half-rendered or broken vault on their phone, even if the source vault is in an inconsistent state mid-rebuild.

**Vault mirror sync (`mirror-sync.log`):**

The vault → cloud mirror uses a similar staging pattern (rsync to a temp location, then promote). Without it, an interrupted sync would leave the mirror in an unknown state.

## Anatomy

Five required components:

1. **Staging location** — distinct from the live location, on the same filesystem (so atomic rename is possible without copy-across-filesystem fallback)
2. **Build process** — writes only to staging, never touches live
3. **Validation gate** — runs against staging only. Must be deterministic and fast enough that the build's "valid?" question has a clear answer before promotion. See [[gate-evaluation-pattern]].
4. **Atomic swap** — `mv` (POSIX rename) is atomic on the same filesystem. Two-step swap with backup: `mv live live.bak && mv staging live`. Optionally `rm -rf live.bak` after a delay or once a new build succeeds.
5. **Failure path** — explicit. On any failure (build error, validation failure), the staging artifact is discarded and the live artifact remains the previous good build. No partial state, no manual recovery.

## Where This Applies in Crumb

| Instance | Live artifact | Staging location | Validation |
|---|---|---|---|
| vault-mobile-access | `quartz-vault/public/` | `public-next/` | File count + smoke check |
| Vault cloud mirror | Cloud mirror dir | rsync temp dir | rsync exit code |
| Compound insight pipeline (potential) | `_system/docs/solutions/<file>.md` | Tempfile via `mktemp` | vault-check on staged file |
| Knowledge brief regeneration (potential) | `_system/docs/knowledge-briefs/<topic>.md` | `.tmp` sibling | Schema check |
| Daily artifact rewrites (potential) | `_system/daily/YYYY-MM-DD.md` | `.draft` sibling | Frontmatter validation |
| Goal-tracker bulk updates (potential) | `_system/docs/goal-tracker.yaml` | `.new` sibling | YAML parse check |
| Generated indexes (signal-notes, MOCs) | The index file | `.next` sibling | Vault-check |

The pattern is dramatically underused inside Crumb relative to where it could help. Most Crumb writes are direct overwrites. Adopting atomic rebuild for any file that is *generated from other files* (as opposed to operator-edited) would eliminate a class of half-write failure modes.

## Failure Modes

- **Cross-filesystem rename fallback.** `mv` is only atomic when source and destination are on the same filesystem. If staging is on a different mount (e.g., tempdir on tmpfs, live on disk), `mv` falls back to copy-then-delete and the atomicity is lost. **Always stage on the same filesystem as the live artifact.**
- **Symlink races.** If consumers follow a symlink to the live artifact, swapping the symlink atomically (`ln -sfn`) is fine. But if consumers cache the resolved path, the swap is invisible to them. Prefer renaming directories over swapping symlinks when consumers are long-lived.
- **Staging dir not cleaned up on failure.** The discard step is easy to forget. Stale staging dirs accumulate and confuse debugging. Always clean up in a `trap` handler or equivalent.
- **Validation that takes longer than the rebuild interval.** If validation is slow and the rebuild runs on a tight cadence, validations can pile up or overlap. Either speed up validation or rate-limit rebuilds.
- **Validation that's weaker than the failure modes.** A file-count check catches "build wrote nothing" but misses "build wrote garbage." Match validation strength to the failure modes you actually see, not to a theoretical ideal.
- **No backup retention.** If you `rm -rf live.bak` immediately after the swap, you have no fast rollback. Keep at least one previous build until the next successful build.

## Why This Pattern Exists

The naive approach — overwrite live in place — has three failure modes the atomic pattern eliminates:

1. **Half-written state during build.** Consumers reading mid-write see inconsistent data. Atomic rebuild keeps consumers on the previous good copy until the new copy is fully ready.
2. **Failed builds blank out live.** A build that errors halfway through can leave the live artifact in a broken state. Atomic rebuild treats broken builds as "do nothing."
3. **No rollback path.** Once you've overwritten live, the previous good state is gone. Atomic rebuild keeps the previous version available (at least transiently) for fast rollback.

The cost is one extra disk's worth of staging space and one extra rename operation. The benefit is eliminating an entire category of bugs. Almost always worth it for any artifact that's generated from inputs and consumed by readers.

## Related Patterns

- **[[gate-evaluation-pattern]]** — atomic rebuild's validation step is an instance of the gate evaluation pattern. The criteria are defined when the rebuild script is written; the evaluation runs on every rebuild.
- **[[validation-is-convention-source]]** — the rebuild's validation rules become the de facto definition of "what counts as a valid build." Don't weaken them silently when builds start failing.
- **[[behavioral-vs-automated-triggers]]** — atomic rebuild is the rare pattern that can be fully automated *because* the validation is mechanical. When validation needs human judgment, this pattern doesn't apply — manual gate-keeping is required instead.

## Origin

Surfaced 2026-04-07 from a retrospective re-read of `Projects/vault-mobile-access/progress/run-log.md`. The original 2026-04-04 session marked the project as having "no compoundable insights — standard infrastructure project." Re-reading, the `rebuild.sh` design is a textbook implementation of a reusable pattern that applies broadly across Crumb's generated-artifact surface. The original assessment was wrong; the work was more compoundable than it looked at the time. See also: [[foreign-tool-reveals-native-blind-spots]], surfaced from the same re-read.
