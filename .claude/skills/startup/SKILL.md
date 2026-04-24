---
name: startup
description: Run session startup checks — vault health, Obsidian CLI, rotation, overlay index, audit status, stale summaries
disable-model-invocation: true
user-invocable: true
allowed-tools: Bash, Read
model_tier: execution
---

Run the session startup script and display the results:

1. Execute `bash _system/scripts/session-startup.sh` from the vault root
2. Find the pre-formatted block after `=== DISPLAY THIS BLOCK VERBATIM AS YOUR FIRST OUTPUT ===`
3. Display that **Startup Summary** block exactly as emitted — do not reformat or summarize
4. Act on the structured context data:
   - Check monthly rotation for `_system/logs/session-log.md` and active project run-log.md; rotate if needed (hook provides `session_log_month` and `active_run_logs` with their current months)
   - Load overlay index (`_system/docs/overlays/overlay-index.md`) for skill routing (hook reports whether the index exists)
   - If `last_full_audit` is 7+ days ago or unknown, suggest running one
   - If `stale_summaries` ≥ 3, recommend full audit regardless of cadence
   - If `compound_insights_pending` > 0, run compound insight routing using the file list from `compound_insights_pending_files`:
     a. Read each listed file's `compound_insight` frontmatter block
     b. Present each insight to the operator: pattern, scope, target, confidence, durability
     c. Prompt for decision per insight: **route** / **defer** / **dismiss**
     d. If **route**: create the target artifact (ADR, pattern doc, convention update, or project design doc) using the research output as source material. Add `routed_at: YYYY-MM-DD` and `routed_to: <vault-relative-path>` to the research file's `compound_insight` block.
     e. If **dismiss**: add `dismissed: true` to the research file's `compound_insight` block
     f. If **defer**: no action — insight stays pending for next session
   - If `compound_insights_stale` > 0, flag the files from `compound_insights_stale_files` for operator decision: **revalidate** (update `valid_as_of` to today) / **dismiss** / **promote to permanent** (set `durability: permanent`, remove `valid_as_of`, add `promoted_from_perishable: true` and `promoted_at: YYYY-MM-DD`)
