---
type: reference
domain: software
status: active
created: 2026-02-22
updated: 2026-02-22
tags:
  - openclaw
  - infrastructure
  - integration
  - crumb-tess-bridge
---

# OpenClaw Skill Integration — Lessons Learned

Reference for installing custom skills into OpenClaw (v2026.2.17+). Derived from
crumb-tess-bridge IMPLEMENT phase, 2026-02-22.

## Working Configuration

Skill file: `~/.openclaw/workspace/skills/<skill-name>/SKILL.md`

Frontmatter (minimal — matches bundled skill format):

```yaml
---
name: skill-name
description: One-line description used for agent routing.
---
```

Config entry in `~/.openclaw/openclaw.json`:

```json
{
  "skills": {
    "entries": {
      "skill-name": { "enabled": true }
    }
  }
}
```

## Skill Discovery Hierarchy

OpenClaw loads skills from three locations (highest to lowest precedence):

1. `<workspace>/skills/` — per-agent workspace skills
2. `~/.openclaw/skills/` — managed/local skills (shared across agents)
3. Bundled skills — shipped with the npm package

Additionally, `skills.load.extraDirs` in `openclaw.json` adds directories at
lowest precedence. The gateway discovers skills from all four sources, but
**agent visibility requires the skill to be in one of the top three locations.**

## Pitfalls Encountered

### 1. `extraDirs` discovery ≠ agent visibility

The gateway debug log showed the skill discovered and sanitized from `extraDirs`,
but the agent could not see or invoke it. Placing the skill in the workspace
directory (`~/.openclaw/workspace/skills/`) resolved this.

**Recommendation:** Always place skills in the workspace directory. Use
`extraDirs` only as a supplementary scan path, not as the primary location.

### 2. Frontmatter format sensitivity

Crumb's initial SKILL.md included a `metadata` field with inline JSON for
gating (emoji, requires.bins, os). No bundled skill used this pattern in its
frontmatter — all working skills had only `name` and `description`. Removing
the `metadata` line was part of the fix.

The `metadata` field is documented and may work for gating, but for a skill
with no binary dependencies or OS restrictions, omit it entirely.

### 3. Session snapshot freezes skill list

OpenClaw snapshots eligible skills when a Telegram session starts. Skills added
after session start are invisible to the agent until a new session begins.

**Fix:** Send `/new` in the Telegram chat to force a fresh session. Gateway
restarts alone do not reliably create new sessions — the Telegram session can
persist across gateway restarts.

### 4. Gateway restart unreliability

- `launchctl kickstart` did not reliably kill the old process — resulted in two
  concurrent `openclaw-gateway` processes (different PIDs, same port).
- `openclaw gateway stop` reported success but the old PID survived.
- `kill -9 <pid>` was the only reliable termination method. Launchd then
  auto-restarted the gateway with a new PID.

**Recommended restart sequence:**

```bash
# Find PID
ps aux | grep openclaw-gateway | grep -v grep

# Kill directly
kill -9 <pid>

# Verify new process
sleep 5 && ps aux | grep openclaw-gateway | grep -v grep

# Force new Telegram session
# Send /new in Telegram chat
```

### 5. Symlinks blocked by workspaceOnly

`tools.fs.workspaceOnly: true` in the config may prevent the agent from
following symlinks that point outside the workspace. A direct copy into the
workspace directory worked; a symlink to the vault exchange directory did not.

### 6. OpenClaw CLI not on PATH

The `openclaw` binary is at `~/.local/bin/openclaw`, not on the default PATH
for the `openclaw` user. Use the full path or add to shell profile.

Useful commands:

```bash
~/.local/bin/openclaw skills list      # show all skills + status
~/.local/bin/openclaw gateway stop     # stop the gateway (may need kill -9 fallback)
```

### 7. Python module caching requires watcher restart

The bridge watcher (`bridge-watcher.py`) is a long-running LaunchAgent process.
Python caches imported modules in `sys.modules`. Any code change to dispatch
engine modules (`stage_runner.py`, `dispatch_engine.py`, `brief_builder.py`,
`dispatch_state.py`) requires killing the watcher for changes to take effect.

`kill -9 <pid>` triggers launchd auto-restart with fresh imports. There is no
hot-reload path — the watcher must be fully restarted.

**Symptom:** Dispatch runs with old validation logic despite code changes on
disk. The watcher log shows the correct routing but the stage runner behaves
as if the fix wasn't applied.

### 8. Tess polling timeout vs dispatch duration

The Tess-side outbox watcher uses `watch-response --timeout 300000` (5 minutes)
to poll for dispatch results. If the dispatch takes longer — or if the first
attempt fails and requires iteration — the Tess session times out.

Tess handles this gracefully: the user can ask Tess to re-check the outbox
at any time, and she'll find the response. But for multi-stage dispatches or
first-time operation deployments, expect the initial polling window to expire.

**Not a bug:** This is the expected interaction model. The response persists in
the outbox until Tess polls again. No data is lost.

## Cross-User Permissions

The crumb-bridge skill runs under the `openclaw` user but accesses files owned
by `tess` via the `crumbvault` group. Key requirements:

- Exchange directories (`_openclaw/inbox/`, `outbox/`, etc.) must be
  `rwxrwxr-x` with group `crumbvault` and setgid bit set
- Both `tess` and `openclaw` must be members of `crumbvault` group
- Skill files in the workspace are owned by `openclaw` (direct copy, not symlink)

## Future Optimization: command-dispatch

The skills doc supports `command-dispatch: tool` in frontmatter, which bypasses
the agent model entirely for slash commands. This would make bridge operations
free on the Tess side (no agent reasoning cost). Worth exploring for production
use to avoid API costs for routine bridge operations.

```yaml
---
name: crumb-bridge
description: ...
command-dispatch: tool
command-tool: exec
command-arg-mode: raw
---
```

Not yet tested. Would need the skill to handle raw arg parsing.
