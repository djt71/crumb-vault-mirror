---
type: solution
track: pattern
domain: software
status: active
created: 2026-08-14
updated: 2026-08-14
confidence: high
tags:
  - compound
  - teardown
  - configuration
  - kb/software-dev
topics:
  - moc-crumb-operations
source_projects:
  - agentic-sunset
source_artifacts:
  - _system/logs/session-log.md
---

# Decommission Residue in Live Configs

## Claim

When infrastructure is decommissioned, configs and scripts that *survive* the teardown keep carrying values and rationale from the dead system — stale binary paths, dead identities, obsolete purpose comments. The residue is dangerous in both directions: it can make live operations inert (config points at a removed install) and it can make dead rationale drive wrong decisions (stale comments justify removing something still needed). Teardown sweeps enumerate the dead system's own artifacts; they systematically miss the *references to it* inside surviving artifacts.

## Evidence

Three confirmed instances, all post-agentic-sunset:

1. **2026-07-07 (stale path):** `.mcp.json` pointed workspace-mcp at the decommissioned tess-user install — a package-manager upgrade of the danny-side install would have been inert. Caught only because the upgrade session verified which binary the config actually runs.
2. **2026-07-07 (stale value):** the same `.mcp.json` carried a foreign-domain identity as `USER_GOOGLE_EMAIL` — a Tess-era config value (likely model fabrication) carried verbatim through migration and repoint. Lesson sharpened: verify every carried-over config *value*, not just paths.
3. **2026-07-13 (stale rationale):** `drive-sync.sh`'s comments still framed Target 2 as the "Perplexity Computer feed" a month after that subscription was cancelled — and since greps read the script, the stale rationale nearly drove removal of a live backup (operator catch). The keep-set manifest had the correct rationale; the artifact-local copy was the one consulted.

## How to Apply

- **At teardown/migration time:** after removing the dead system's own artifacts, run a residue sweep over *surviving* configs and scripts — grep live config surfaces (`.mcp.json`, plists, shell env, script headers/comments) for the dead system's names, paths, identities, and product references.
- **At repoint time:** verify every carried-over value against ground truth (which binary runs, which identity authenticates), not just whether the service starts.
- **At removal-proposal time:** before deleting anything justified by an in-artifact comment, check the comment's rationale against an authoritative source (manifest, service inventory) — artifact-local rationale rots fastest.

## Related

- [[infrastructure-teardown-discipline]] — the teardown disciplines this pattern extends (residue lives in survivors, not the dead system's own registry).
- [[registry-enumeration-at-retirement]] — same class error: enumerating known instances instead of the class.
