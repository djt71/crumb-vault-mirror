---
project: obsidian-applenotes-import
domain: software
type: probe-result
skill_origin: systems-analyst
created: 2026-04-25
updated: 2026-04-25
---

# G2 Probe Result — Note ID Stability

**Date:** 2026-04-25
**macOS:** 26.3.1 (`sw_vers` confirmed; same machine as G1)
**Probe scripts:** [`g2-id-stability.applescript`](g2-id-stability.applescript) (main) + an inline folder-move sub-probe
**Outcome:** ✅ **VALIDATED — note id is byte-stable across all in-spec scenarios**

## Method

Created a probe note via `make new note`, captured `id_0`, then exercised each scenario from the spec's pass criteria, querying the id after each:

1. Quit Notes via AppleScript, re-activate, look up note → id matches
2. Repeat (restart 2)
3. Repeat (restart 3)
4. Edit `name of note` (title), look up → id matches
5. Edit `body of note`, look up → id matches
6. Move note via `move noteHandle to targetFolder` (where `noteHandle` is grabbed via `first note whose id is probeId`, NOT by name) → id matches; folder location updated

## Raw evidence

```
G2 PROBE RESULT (2026-04-25)
==========================
id_0                     = x-coredata://9BBC9A13-B1F7-4AAD-B0FD-466AC3743D51/ICNote/p11
id_after_restart_1       = x-coredata://9BBC9A13-B1F7-4AAD-B0FD-466AC3743D51/ICNote/p11 (count=1)
id_after_restart_2       = x-coredata://9BBC9A13-B1F7-4AAD-B0FD-466AC3743D51/ICNote/p11 (count=1)
id_after_restart_3       = x-coredata://9BBC9A13-B1F7-4AAD-B0FD-466AC3743D51/ICNote/p11 (count=1)
id_after_title_edit      = x-coredata://9BBC9A13-B1F7-4AAD-B0FD-466AC3743D51/ICNote/p11
id_after_body_edit       = x-coredata://9BBC9A13-B1F7-4AAD-B0FD-466AC3743D51/ICNote/p11
```

```
Folder-move sub-probe:
before=Notes | move=ok | after=crumb-G2-target | idStable=true
```

## Findings

1. **Pass:** `id of note` is byte-identical across all in-spec scenarios (3 restarts + title edit + body edit + folder move within same account).
2. **Bonus finding (important for PLAN/IMPLEMENT):** Apple Notes **auto-renames notes from the body's first heading or first non-empty line.** Setting `body of note` to `<h1>G2 probe v1</h1>...` caused the note's `name` to change to "G2 probe v1" without us touching the `name` property. This means **note names are volatile in our pipeline:** we must address notes by id, never by name, in production code. Specifically: when re-fetching a handle to perform follow-up operations (move, delete, set body), use `first note whose id is X`, not by-name lookup.
3. **Bonus finding (AppleScript syntax quirk):** `folder of note` raises error -1728 ("Can't get folder of note id …") in this version of Apple Notes. We cannot query a note's containing folder directly. To determine a note's folder, iterate folders and check membership via `id of (every note of f)`. This is acceptable for our use case — we already know each note's folder from the listing pass (OAI-005); we never need to re-query it.
4. **Cross-account ID behavior** was NOT directly tested (test machine has only one account). Per the spec's pass criteria, cross-account-move ID changes are *allowed* (downgrade dedupe to account-scoped). The risk register entry already mitigates this via the OAI-012 content-hash secondary key.

## Spec implications

- **No spec change required.** The bonus findings are PLAN/IMPLEMENT-level notes. The spec's existing design (id-keyed import index, sequencing-then-verify-then-delete) is unaffected.
- **PLAN/IMPLEMENT note for OAI-005/OAI-006/OAI-007/OAI-008b/OAI-016c:** all AppleScript handle re-fetches must use `whose id is …`, not by-name. This is consistent with the import index already keying on `apple_notes_id`.
- **README note:** users renaming imported notes in Obsidian after import won't break the index (handled by `vault.on('rename')` listener in OAI-012). Apple Notes auto-renaming the *source* note based on body content is irrelevant to the plugin (we read once, write once, soft-delete once).
