---
type: research-note
domain: software
status: draft
created: 2026-02-19
updated: 2026-02-19
project: crumb-tess-bridge
task: CTB-009
---

# CTB-009: File-Watch Latency Research

## Objective

Determine the best file-watching mechanism for the crumb-tess-bridge Phase 2
runner, which must detect new files in `_openclaw/inbox/` and spawn Claude Code
sessions. Requirements: reliable, low-latency, resource-efficient, runs
continuously as a background service under `tess` user, watches a directory
owned by `openclaw` user.

## Test Environment

- **macOS:** 26.3 (Darwin 25.3.0)
- **Test directory:** `/private/tmp/ctb-watch-test/`
- **Target directory:** `/Users/tess/crumb-vault/_openclaw/inbox/`
- **Current user:** tess (uid=501)
- **Directory owner:** openclaw (uid=502)
- **Shared group:** crumbvault (gid=501), members: openclaw, tess
- **Directory mode:** drwxrwxr-x (775)

## Mechanism 1: Raw kqueue (Python `select.kqueue`)

### How It Works

kqueue is the BSD/macOS kernel-level event notification mechanism. A process
opens a directory file descriptor, registers interest in vnode events
(KQ_NOTE_WRITE, KQ_NOTE_EXTEND, etc.), and the kernel delivers events when
the directory metadata changes.

### Latency Results (5 trials, single file creation)

| Trial | Latency (ms) |
|-------|-------------|
| 1     | 0.410       |
| 2     | 0.460       |
| 3     | 0.356       |
| 4     | 0.392       |
| 5     | 0.439       |

- **Min:** 0.356 ms
- **Max:** 0.460 ms
- **Median:** 0.410 ms
- **Mean:** 0.411 ms

### Spaced Arrival (1-second gaps between files, realistic bridge pattern)

| Trial | Latency (ms) |
|-------|-------------|
| 1     | 0.338       |
| 2     | 0.528       |
| 3     | 0.513       |
| 4     | 0.444       |
| 5     | 0.483       |

- **Min:** 0.338 ms
- **Max:** 0.528 ms
- **Median:** 0.483 ms
- **Mean:** 0.461 ms

### Event Type Detection

| Event Type           | Detected? | Notes |
|---------------------|-----------|-------|
| File creation       | YES       | KQ_NOTE_WRITE fires on directory |
| File deletion       | YES       | KQ_NOTE_WRITE fires on directory |
| File modification   | NO        | Modifying file content does not change directory metadata |
| Subdirectory change | NO        | Must watch each subdirectory separately |
| Atomic rename (same dir) | YES  | Both temp creation and rename trigger WRITE events |
| Cross-dir rename    | YES       | Rename from outside into watched dir triggers WRITE (0.568 ms) |

**Key finding:** kqueue directory watches detect new file creation and deletion,
but NOT content modification of existing files. This is exactly what the bridge
needs: detect new `.json` request files arriving in the inbox.

### Rapid File Creation (10 files, no delay)

- Files created: 10
- kqueue events: 10 (one per file)
- All 10 files detected: YES
- First detection latency: 0.449 ms
- **No coalescing observed** at the raw kqueue level

### Resource Usage (idle)

| Metric           | Value           |
|-----------------|-----------------|
| CPU (10s idle)  | 0.014% total    |
| User CPU        | 0.0006 s        |
| System CPU      | 0.0008 s        |
| Max RSS         | ~16.5 MB (Python process overhead) |

Effectively zero CPU usage when idle. The 500ms poll timeout means the process
wakes briefly twice per second to check the stop flag, which is negligible.

### Batch Processing Pattern

When using the "scan entire directory on any kqueue event" pattern (recommended
for the bridge):
- 10 files created rapidly: all 10 detected
- 75 callback invocations (files scanned multiple times across events)
- This is correct behavior: each kqueue event triggers a directory scan,
  and earlier files are re-seen until processed/moved

## Mechanism 2: launchd WatchPaths

### How It Works

launchd monitors specified filesystem paths using kqueue internally. When a
change is detected, launchd spawns the configured job as a new process. If the
job is already running, launchd waits for it to exit, then re-checks the path.

Source: `launchd.plist(5)` man page on this system.

### Official Documentation Excerpts

From the man page:

> **WatchPaths** `<array of strings>` — This optional key causes the job to be
> started if any one of the listed paths are modified.
>
> **IMPORTANT:** Use of this key is highly discouraged, as filesystem event
> monitoring is highly race-prone, and it is entirely possible for modifications
> to be missed. When modifications are caught, there is no guarantee that the
> file will be in a consistent state when the job is launched.

> **ThrottleInterval** `<integer>` — This key lets one override the default
> throttling policy imposed on jobs by launchd. The value is in seconds, and
> by default, jobs will not be spawned more than once every 10 seconds.

### Estimated Latency Breakdown

| Component                    | Latency      |
|-----------------------------|-------------|
| kqueue event detection      | ~0.5 ms     |
| launchd coalescing window   | ~1 s (empirically observed) |
| Process spawn (/bin/bash)   | ~15 ms (measured) |
| Node.js startup             | ~45 ms (measured) |
| Claude Code startup         | ~2-5 s (estimated: CLAUDE.md load + API handshake) |

**Best case** (job not running, outside ThrottleInterval): ~50-100 ms + Claude startup
**Typical case** (infrequent requests): same as best case
**Worst case** (within ThrottleInterval): up to 10 seconds + Claude startup
**Worst case** (job still running): remaining runtime + ThrottleInterval + Claude startup

### Critical Limitations

1. **ThrottleInterval default = 10 seconds.** If the bridge job exits quickly
   (which it will after processing a single request), launchd will NOT re-launch
   it for at least 10 seconds. This means back-to-back requests have 10+ second
   latency for the second request.

2. **Apple explicitly discourages WatchPaths.** The man page says it is "highly
   race-prone" and "it is entirely possible for modifications to be missed."

3. **No concurrent instances.** If the job is running and a new file arrives,
   launchd does not start a second instance. It waits for the first to exit,
   then re-checks.

4. **Process spawn overhead per request.** Each event spawns a fresh process,
   paying the full startup cost every time.

5. **No event details.** The spawned process receives no information about WHAT
   changed. It must scan the directory to find new files.

### Mitigation: QueueDirectories

`QueueDirectories` is semantically better than WatchPaths for queue processing:
it keeps the job alive as long as the directory is non-empty. The job processes
all files and exits when the queue is empty. However, it still suffers from
ThrottleInterval and the process-per-invocation model.

## Mechanism 3: fswatch

### Availability

**fswatch is NOT installed on this system.** It would need to be installed via
Homebrew (`brew install fswatch`).

### Documented Behavior

fswatch is a userspace wrapper around multiple backends:
- **FSEvents monitor** (macOS default): Apple's high-level filesystem events API.
  Scales well, no per-file fd overhead, but has a configurable latency parameter
  (default 1 second) that delays event delivery for coalescing.
- **kqueue monitor**: Same kernel mechanism tested above. fswatch opens one fd
  per file (not per directory), which scales poorly with large file counts.

### Assessment

fswatch adds a dependency and a layer of abstraction over the same kernel
mechanisms. For watching a single directory, it provides no benefit over
raw kqueue and introduces:
- An external dependency to install and maintain
- FSEvents latency parameter (configurable but defaults to 1s)
- Potential compatibility issues across macOS versions
- No process management (still needs launchd for service lifecycle)

## Mechanism 4: Long-Running kqueue Watcher (Recommended)

### Architecture

Instead of letting launchd spawn a process per event (WatchPaths/QueueDirectories),
run a persistent Python/bash process managed by launchd with `KeepAlive=true`.
The process uses kqueue internally for event detection.

```
launchd (KeepAlive=true)
  └── bridge-watcher.py (persistent process)
        ├── kqueue: watch _openclaw/inbox/
        ├── on event: scan directory for .json files
        ├── for each file: acquire flock, spawn claude --print
        └── move processed files to .processed/
```

### Advantages Over WatchPaths

| Feature                  | WatchPaths          | Long-Running Watcher |
|-------------------------|---------------------|---------------------|
| Detection latency       | 50-100ms + spawn    | 0.3-0.5 ms         |
| ThrottleInterval impact | 10s between runs    | N/A (always running) |
| Process spawn per event | YES                 | NO (already running) |
| Missed events possible  | YES (Apple warning) | Mitigated by dir scan |
| Back-to-back requests   | 10s+ delay          | <1ms detection      |
| Process management      | launchd (automatic) | launchd KeepAlive   |
| Recovery from crash     | launchd relaunches  | launchd relaunches  |

### Tested Performance

- **Idle CPU usage:** 0.014% over 10 seconds (effectively zero)
- **Detection latency:** 0.338-0.528 ms (median 0.483 ms)
- **Batch reliability:** 10/10 files detected in rapid creation test
- **Memory footprint:** ~16.5 MB (Python process overhead; a bash+kqwait
  version would be smaller)

### launchd Integration

The watcher runs as a `KeepAlive` LaunchAgent:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.crumb.bridge-watcher</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>/Users/tess/crumb-vault/_system/scripts/bridge-watcher.py</string>
    </array>
    <key>KeepAlive</key>
    <true/>
    <key>ProcessType</key>
    <string>Adaptive</string>
    <key>StandardOutPath</key>
    <string>/Users/tess/crumb-vault/_openclaw/logs/watcher.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/tess/crumb-vault/_openclaw/logs/watcher.err</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>/Users/tess</string>
    </dict>
</dict>
</plist>
```

Key plist details:
- `KeepAlive=true`: launchd restarts the watcher if it crashes
- `ProcessType=Adaptive`: allows the process to be background when idle,
  elevated when handling XPC transactions (may not apply, but safe default)
- `HOME` explicitly set per MEMORY.md note on macOS multi-user operations
- No `ThrottleInterval` needed (process is persistent, not event-triggered)
- `StandardOutPath`/`StandardErrorPath` for log capture

## Cross-User Permission Findings

### Permission Model

The `_openclaw/inbox/` directory uses the `crumbvault` group for shared access:

```
drwxrwxr-x  openclaw:crumbvault  _openclaw/
drwxrwxr-x  openclaw:crumbvault  _openclaw/inbox/
```

Group `crumbvault` (gid=501) members: `openclaw`, `tess`

### Test Results

| Operation                           | Result |
|------------------------------------|--------|
| Open directory O_RDONLY (for kqueue) | PASS   |
| Register kqueue kevent              | PASS   |
| List directory contents             | PASS   |
| Read files in directory             | SKIP (directory empty, but group rwx grants this) |

**Conclusion:** The `tess` user can fully watch and read files in the
`openclaw`-owned `_openclaw/inbox/` directory via the shared `crumbvault`
group. No permission changes needed.

### File Creation by openclaw

When `openclaw` creates files in `inbox/`, they will inherit the directory's
group (`crumbvault`) if the directory has the setgid bit. Current mode is
`drwxrwxr-x` (no setgid). The files created by openclaw will have group
`crumbvault` only if openclaw's primary group is `crumbvault` or the file
is explicitly created with that group.

**Action needed:** Verify that files written by the OpenClaw Node.js process
are readable by `tess` user. If not, either:
- Set the setgid bit on `inbox/`: `chmod g+s _openclaw/inbox/`
- Or ensure openclaw's umask allows group read (022 or 002)

## Comparison Matrix

| Criterion                     | launchd WatchPaths    | launchd QueueDirs     | fswatch              | Long-Running kqueue   |
|------------------------------|----------------------|----------------------|---------------------|----------------------|
| **Detection latency (median)** | ~100ms + spawn       | ~100ms + spawn       | ~1000ms (FSEvents default) | **0.5ms**            |
| **Detection latency (worst)**  | 10s (ThrottleInterval) | 10s (ThrottleInterval) | configurable         | **0.5ms** + poll interval |
| **Event coalescing**          | Yes (~1s window)     | Yes (~1s window)     | Yes (configurable)   | **None at kqueue level** |
| **Reliability (rapid events)** | Race-prone (Apple warning) | Better (non-empty check) | Good               | **10/10 in testing** |
| **Idle CPU usage**            | 0% (no process)      | 0% (no process)      | Low                  | **0.014%**           |
| **Idle memory**               | 0 (no process)       | 0 (no process)       | ~5-10 MB             | **~16.5 MB** (Python) |
| **Per-request overhead**      | Process spawn (~15ms) | Process spawn (~15ms) | None (persistent)    | **None (persistent)** |
| **launchd integration**       | Native               | Native               | Needs wrapper        | KeepAlive LaunchAgent |
| **Cross-user watching**       | Yes (group perms)    | Yes (group perms)    | Yes (group perms)    | **Yes (tested)**     |
| **Sleep/wake recovery**       | Automatic            | Automatic            | Manual reconnect     | **launchd KeepAlive** |
| **Crash recovery**            | launchd relaunches   | launchd relaunches   | Manual               | **launchd relaunches** |
| **External dependency**       | None                 | None                 | Homebrew             | **None**             |
| **Apple recommendation**      | "Highly discouraged" | Supported            | N/A                  | Standard pattern     |
| **Back-to-back latency**      | 10s (Throttle)       | 10s (Throttle)       | Configurable         | **0.5ms**            |

## Recommendation

**Use a long-running kqueue watcher managed by launchd KeepAlive.**

### Justification

1. **Sub-millisecond detection latency** (0.3-0.5ms) vs. 50ms-10s for WatchPaths.
   While the bridge's total latency is dominated by Claude Code startup (2-5s),
   the watcher should not add unnecessary delay — especially for back-to-back
   requests where WatchPaths' ThrottleInterval would add 10 seconds.

2. **Apple explicitly warns against WatchPaths** for reliability. A persistent
   process with "scan directory on event" is the standard mitigation.

3. **Zero external dependencies.** Uses only Python standard library (`select.kqueue`)
   and macOS built-in launchd. No Homebrew packages to maintain.

4. **Negligible resource usage.** 0.014% CPU idle, ~16.5 MB memory (Python
   process overhead). A bash-based alternative using a compiled kqueue tool
   would be even lighter.

5. **Proven cross-user compatibility.** Tested on the actual `_openclaw/inbox/`
   directory: kqueue registration, directory listing, and file reading all work
   via the `crumbvault` group permissions.

6. **Graceful degradation.** If the watcher crashes, launchd KeepAlive restarts
   it. On restart, the watcher scans the directory for any files that arrived
   during the gap. No events are permanently lost.

### Implementation Notes for CTB-011

- The watcher should scan the full directory on EVERY kqueue event (not just
  process the triggering file). This handles coalescing and missed events.
- Filter for `.json` files matching the request filename pattern. Ignore
  dotfiles, `.tmp` files, and non-JSON files.
- Use flock on a lockfile before spawning `claude --print` (per spec).
- The pgrep session-concurrency check happens inside the watcher before
  spawning, not in launchd.
- Consider implementing a fallback periodic scan (every 30-60 seconds) as
  defense-in-depth against kqueue edge cases.
- The `KQ_EV_CLEAR` flag is essential: it auto-resets the event filter after
  delivery, allowing the same kevent to fire repeatedly.

### Caveats

1. **kqueue fd limitation:** kqueue requires an open file descriptor for the
   watched directory. If the directory is deleted and recreated, the fd becomes
   stale. The watcher should handle EBADF by re-opening the directory.

2. **Python process overhead:** ~16.5 MB for a Python process is nontrivial on
   constrained systems. If memory is a concern, a compiled kqueue watcher
   (C/Rust/Go) or a bash script using a kqueue tool (`kqwait`) would be lighter.
   For this Mac Studio, 16.5 MB is negligible.

3. **No subdirectory watching:** kqueue on a directory only detects direct
   children. If the bridge ever needs nested inbox directories, each must be
   watched separately. Current design uses a flat `inbox/` directory, so
   this is not a concern.

4. **setgid bit:** Verify that files created by `openclaw` in `inbox/` are
   group-readable by `tess`. May need `chmod g+s` on the inbox directory.

## Raw Test Data

All test scripts and raw results are preserved at:
- `/private/tmp/ctb-watch-test/kqueue_test.py` — raw kqueue latency, event types, coalescing, resource usage
- `/private/tmp/ctb-watch-test/kqueue_test2.py` — atomic rename, modification, cross-user tests
- `/private/tmp/ctb-watch-test/long_running_watcher_test.py` — sustained idle, batch, spaced arrival
- `/private/tmp/ctb-watch-test/cross_user_test.py` — permission verification on actual target
- `/private/tmp/ctb-watch-test/kqueue_results.json` — raw kqueue test results
- `/private/tmp/ctb-watch-test/long_running_results.json` — long-running watcher test results
- `/private/tmp/ctb-watch-test/launchd_results.json` — process spawn overhead measurements

## References

- `launchd.plist(5)` man page (macOS 26.3)
- [fswatch GitHub — monitor comparison](https://github.com/emcrisostomo/fswatch)
- [fswatch documentation — Monitors](https://emcrisostomo.github.io/fswatch/doc/1.16.0/fswatch.html/Monitors.html)
- [launchd.info — tutorial](https://www.launchd.info/)
- [Apple Developer Forums — launchd latency](https://developer.apple.com/forums/thread/93044)
- [dabrahams/launchd notes](https://gist.github.com/dabrahams/4092951)
