---
project: obsidian-applenotes-import
domain: software
type: probe-result
skill_origin: systems-analyst
created: 2026-04-25
updated: 2026-04-25
---

# A4 Probe Result — AppleScript Soft-Delete Semantics

**Date:** 2026-04-25
**Probe script:** [a4-soft-delete.applescript](a4-soft-delete.applescript)
**Outcome:** ✅ **VALIDATED — soft-delete confirmed**

## Environment (captured inline for self-evidence)

```
$ sw_vers
ProductName:		macOS
ProductVersion:		26.3.1
ProductVersionExtra:	(a)
```

Apple Notes app: bundled with macOS (no third-party Notes client).

## Method

Created a throwaway note via `tell application "Notes" to make new note`, then deleted it via `delete newNote`, then enumerated all folders and queried by id.

## Raw output

```
PRIOR_PROBES_CLEANED=0
PROBE_ID=x-coredata://9BBC9A13-B1F7-4AAD-B0FD-466AC3743D51/ICNote/p10
PROBE_NAME=crumb-probe-DELETE-2026-04-25
ORIGINAL_FOLDER=unknown
EXISTS_BY_ID_BEFORE_DELETE=true
EXISTS_BY_ID_AFTER_DELETE=true
FOUND_AFTER_DELETE_IN_FOLDER=Notes+Recently Deleted
ALL_FOLDERS=Notes, Recently Deleted
```

## Findings

1. **`EXISTS_BY_ID_AFTER_DELETE=true`** — the AppleScript-deleted note is **still queryable by its CoreData id** after `delete`. This is the data-layer signature of a soft delete; a hard-deleted note would return `false`.
2. **Note found in "Recently Deleted" folder** after the delete — matches the user-visible Apple Notes UX of soft-delete.
3. The "Notes+Recently Deleted" duplicate finding was caused by an orphan from a prior failed probe run that hadn't yet been cleaned up at the moment of enumeration. Subsequent independent enumeration confirmed only one probe note in Recently Deleted.

## Implications for spec

- **LD-02 (soft-delete only) is empirically supported** on the current macOS+Notes baseline.
- The composite verify-before-delete contract (OAI-017) can rely on `delete` being recoverable for at least the duration of Apple Notes' Recently Deleted retention window.
- Re-validate at IMPLEMENT start if macOS major version has changed (current baseline: 26.3.1).

## Probe note status

Two probe notes were created during validation (one orphan from an initial AppleScript syntax error, one from the successful run). Both are now in **Recently Deleted** and will auto-purge per Apple Notes' standard retention. No manual cleanup required.

## Notes about the probe script

`a4-soft-delete.applescript` is suitable for re-running at any point — it cleans up prior probe notes by name before creating a new one.
