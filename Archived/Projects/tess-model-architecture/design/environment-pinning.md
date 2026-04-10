---
type: design
project: tess-model-architecture
domain: software
created: 2026-02-22
updated: 2026-02-23
tags:
  - environment
  - rollback
  - operations
---

# Environment Pinning & Rollback Plan

## 1. Purpose

Record the exact software versions, configuration hashes, and service definitions
for the Tess model architecture deployment. Provides a step-by-step rollback
procedure to revert to the pre-implementation state if the tiered architecture fails.

## 2. Current Environment (Pre-Implementation Baseline)

### 2.1 Software Versions

| Component | Version | Source | Notes |
|-----------|---------|--------|-------|
| **OpenClaw** | `2026.2.17` | `/Users/openclaw/.local/lib/node_modules/openclaw/package.json` | Installed under `openclaw` user. Latest available: `2026.2.21-2` (upgrade blocked on bundler corruption #22841) |
| **Node.js** | `v25.6.1` | System install | |
| **npm** | `11.9.0` | System install | |
| **Ollama** | `0.16.3` | Homebrew (`brew install ollama`) | Installed 2026-02-22. Running as Homebrew service. |
| **qwen3-coder:30b** | `06c1097efce0` | `ollama pull qwen3-coder:30b` | 18 GB, Q4_K_M default quantization. Blob: `sha256-1194192cf2a1` |
| **Modelfile** | `d99f6d12...bfbbc4` | `design/Modelfile.tess-mechanic` | Custom Modelfile: `FROM qwen3-coder:30b` + `PARAMETER num_ctx 65536`. Model: `tess-mechanic:30b` (digest: `3d92bf9a9a66`) |
| **macOS** | Darwin 25.3.0 | System | Mac Studio M3 Ultra 96GB |

### 2.2 OpenClaw Configuration

| Property | Value |
|----------|-------|
| Config location | `/Users/openclaw/.openclaw/openclaw.json` |
| Config hash | `6fd1afa3068fc34e59b416eaeb3eaa15defdd9666a7b5dd395d2603c7c864f25` (SHA-256 of live config) |
| Config snapshot | `design/openclaw-config-baseline.json` — captured 2026-02-22, credentials redacted. Hash is of the live unredacted config at `/Users/openclaw/.openclaw/openclaw.json`. |

**Action required:** Before beginning TMA-002, snapshot the current config:
```bash
sudo -u openclaw cat /Users/openclaw/.openclaw/openclaw.json > \
  /Users/tess/crumb-vault/Projects/tess-model-architecture/design/openclaw-config-baseline.json
shasum -a 256 /Users/tess/crumb-vault/Projects/tess-model-architecture/design/openclaw-config-baseline.json
```

### 2.3 LaunchDaemon Configuration

| Property | Value |
|----------|-------|
| Plist path | `/Library/LaunchDaemons/ai.openclaw.gateway.plist` |
| Label | `ai.openclaw.gateway` |
| User | `openclaw` |
| Entry point | `/Users/openclaw/launch-openclaw.sh` |
| Port | `18789` |
| KeepAlive | `true` |
| RunAtLoad | `true` |
| Log (stdout) | `/Users/openclaw/.openclaw/logs/gateway.log` |
| Log (stderr) | `/Users/openclaw/.openclaw/logs/gateway.err.log` |
| Service version env | `OPENCLAW_SERVICE_VERSION=2026.2.17` |

### 2.4 Ollama (Post-Installation — Fill During TMA-002)

| Property | Value |
|----------|-------|
| Ollama version | `0.16.3` |
| Install method | Homebrew (`brew install ollama`), running as `brew services` |
| Model | `qwen3-coder:30b` |
| Model digest | `06c1097efce0` (blob: `sha256-1194192cf2a1`) |
| Quantization | Q4_K_M (baseline), Q5_K (preferred if benchmarks confirm) |
| Modelfile hash | `d99f6d12...bfbbc4` (SHA-256 of `design/Modelfile.tess-mechanic`) |
| Modelfile location | `design/Modelfile.tess-mechanic` |
| Custom model name | `tess-mechanic:30b` |
| Custom model digest | `3d92bf9a9a66` |
| Ollama data dir | `~/.ollama/` (default) |
| API endpoint | `http://127.0.0.1:11434` |
| `OLLAMA_KEEP_ALIVE` | `-1` (permanent model loading) |
| `OLLAMA_KV_CACHE_TYPE` | `q4_0` (aggressive — structured output only) |

## 3. Configuration Artifacts to Track

Every configuration change during implementation must be tracked. Hash each artifact
before and after modification.

| Artifact | Location | Pre-Hash | Post-Hash |
|----------|----------|----------|-----------|
| `openclaw.json` | `/Users/openclaw/.openclaw/openclaw.json` | `6fd1afa3…c864f25` | `bc490149…b821f6c` |
| Modelfile | `design/Modelfile.tess-mechanic` | N/A (new) | `d99f6d12…bfbbc4` |
| LaunchDaemon plist | `/Library/LaunchDaemons/ai.openclaw.gateway.plist` | _snapshot_ | _fill if modified_ |
| Ollama service config | _TBD (launchd or manual)_ | N/A (new) | _fill after setup_ |
| tess-voice SOUL.md | _external (Tess repo)_ | N/A (not modified) | N/A |
| Limited Mode prompt | _TBD_ | N/A (new) | _fill after TMA-004 implementation_ |
| tess-mechanic identity | _TBD_ | N/A (new) | _fill after TMA-011_ |

## 4. Rollback Procedure

### 4.1 Scope

Revert to the pre-implementation state: single-agent OpenClaw with cloud model only,
no Ollama, no two-agent split, no Limited Mode.

### 4.2 Prerequisites

- Access to `openclaw` user (sudo required)
- Baseline `openclaw.json` snapshot (§2.2 — MUST be captured before implementation begins)
- Current `openclaw.json` backup (post-implementation, for forensics)

### 4.3 Steps

**Step 1: Stop the gateway**
```bash
sudo launchctl bootout system/ai.openclaw.gateway
# Verify process is gone:
sudo lsof -iTCP:18789 -sTCP:LISTEN
# If still running:
sudo pkill -f "openclaw/dist/index.js"
```

**Step 2: Restore baseline OpenClaw config**
```bash
sudo -u openclaw cp /Users/tess/crumb-vault/Projects/tess-model-architecture/design/openclaw-config-baseline.json \
  /Users/openclaw/.openclaw/openclaw.json
# Verify hash matches baseline:
sudo -u openclaw shasum -a 256 /Users/openclaw/.openclaw/openclaw.json
```

**Step 3: Remove Ollama provider from config (if Step 2 baseline doesn't exist)**

If the baseline snapshot was not captured, manually remove the tiered architecture
additions from `openclaw.json`:
- Remove the `providers.ollama` block
- Remove the second agent from `agents.list`
- Remove `bindings` array
- Remove fallback chains
- Restore single-agent config

**Step 4: Stop Ollama (if running)**
```bash
# If installed as Homebrew service:
brew services stop ollama
# If running manually:
pkill -f ollama
# Verify:
lsof -iTCP:11434 -sTCP:LISTEN
```

**Step 5: Restart gateway with baseline config**
```bash
sudo launchctl bootstrap system /Library/LaunchDaemons/ai.openclaw.gateway.plist
# Verify:
sleep 5
sudo lsof -iTCP:18789 -sTCP:LISTEN
```

**Step 6: Verify baseline operation**
- Send a Telegram message → should get a response from the cloud model
- Check gateway logs for errors:
  ```bash
  sudo -u openclaw tail -20 /Users/openclaw/.openclaw/logs/gateway.log
  ```

**Step 7: (Optional) Uninstall Ollama**
```bash
brew uninstall ollama
rm -rf ~/.ollama/  # Remove model data
```
Only do this if Ollama is not needed for other purposes. The local model data
(~19GB+ for qwen3-coder:30b) is the largest artifact.

### 4.4 Rollback Verification Checklist

| Check | Expected Result |
|-------|-----------------|
| Gateway listening on 18789 | Yes |
| Telegram message gets response | Yes |
| Response comes from cloud model | Yes (check gateway logs) |
| No Ollama process running | Yes (unless kept for other use) |
| No second agent in config | Yes |
| Config hash matches baseline | Yes |
| Gateway logs show no errors | Yes |

## 5. Implementation Checkpoints

At each milestone boundary, capture a snapshot of the environment state:

### Milestone 1 Gate (Validation & Design)
- [x] Baseline `openclaw.json` snapshot captured and hashed
- [x] Ollama installed, version recorded
- [x] qwen3-coder:30b pulled, digest recorded
- [ ] Modelfile created, hashed
- [ ] Environment table (§2.4) fully populated

### Milestone 2 Gate (Build & Benchmark)
- [ ] All benchmark results recorded with environment versions
- [ ] Production `openclaw.json` draft hashed
- [ ] Any Modelfile changes documented

### Milestone 3 Gate (Integration & Measurement)
- [ ] Production `openclaw.json` finalized and hashed
- [ ] All environment artifacts in §3 table have post-hashes
- [ ] Rollback procedure tested (dry run on non-production config)

## 6. Operational Notes

- **OpenClaw lives under the `openclaw` user** — all config reads/writes require
  `sudo -u openclaw` with explicit `HOME=/Users/openclaw` (see MEMORY.md macOS
  multi-user operations)
- **Ollama will be installed under the primary user** (tess or system-level via Homebrew)
  — the `openclaw` user accesses it via HTTP API at `127.0.0.1:11434`, not via CLI
- **LaunchDaemon plist changes require sudo** — modifications to
  `/Library/LaunchDaemons/ai.openclaw.gateway.plist` need root access
- **npm operations under openclaw user** need explicit prefix and cache paths
  (see MEMORY.md macOS multi-user operations)
- **Gateway restart sequence:** `launchctl bootout` → verify process killed →
  `launchctl bootstrap` (not `openclaw daemon start`)
