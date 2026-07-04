---
name: startup
description: Display the formatted session-startup summary from the SessionStart hook output (vault health, Obsidian CLI, rotation, overlay index, audit status, stale summaries). Trigger — /startup invocation only; the hook runs automatically, this skill is the display contract.
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
