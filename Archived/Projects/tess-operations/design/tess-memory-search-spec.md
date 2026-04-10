---
project: tess-operations
type: specification
domain: software
skill_origin: systems-analyst
status: active
created: 2026-02-27
updated: 2026-02-27
deployed: 2026-02-27
tags:
  - tess
  - openclaw
  - memory
  - memory-search
  - configuration
---

# Tess Memory Search Enablement — Specification

## 1. Problem Statement

Tess currently operates with `memorySearch.enabled: false` in `openclaw.json`. This means:

- No retrieval from daily memory files (`memory/YYYY-MM-DD.md`) or curated long-term memory (`MEMORY.md`)
- No embedding index maintained over workspace content
- No pre-compaction memory flush (`compaction.memoryFlush` not configured)
- No session transcript indexing

The practical consequence is that Tess is **stateless across sessions** — she retains no conversational context, learned preferences, or accumulated operational knowledge beyond what is hardcoded in bootstrap files (`SOUL.md`, `AGENTS.md`) and what arrives through the crumb-tess-bridge filesystem exchange. Within a session, compaction can erase context without any mechanism to write durable notes first.

This is a severe handicap for the chief-of-staff role defined in the parent spec. Morning briefings lack conversational context. Session prep cannot recall prior discussions about a customer or project. Tess cannot accumulate observations about Danny's preferences, meeting patterns, or recurring topics. Every session starts from zero.

**Relationship to other specs:** This is a foundational infrastructure spec that improves Tess's operational capability across all sibling specs (chief-of-staff, Google services, Apple services, communications channel). Memory search is not a feature — it is a prerequisite for the continuity that makes a chief-of-staff useful.

## 1b. Existing Infrastructure

This spec builds on:

- **tess-model-architecture** (DONE) — Haiku 4.5 voice agent, qwen3-coder:30b mechanic agent, production config
- **openclaw-colocation** (DONE) — Dedicated `openclaw` user, `workspaceOnly: true`, LaunchDaemon supervisor, Tier 1 hardening
- **tess-operations** (TASK, M0+M1 deployed) — Cron jobs, heartbeats, kill-switch, ops metrics harness, awareness-check
- **OpenClaw v2026.2.25** — Memory search, hybrid BM25+vector, MMR, temporal decay, embedding cache, memoryFlush all available in this version
- **Anthropic API key** — Already configured for Haiku 4.5 voice agent; satisfies embedding provider auto-selection (OpenAI key not required — Anthropic key resolves via auth profiles)

**What already works without memory search:** The crumb-tess-bridge filesystem exchange (`_openclaw/inbox/outbox/`) provides structured persistence for dispatched tasks. Bash scripts (awareness-check, vault-health, health-ping) provide monitoring. Cron jobs provide scheduled operations. None of these depend on memory search — they will continue to function unchanged.

---

## 2. What Memory Search Provides

OpenClaw's memory system has three components relevant to this spec:

### 2.1 Memory Files (Persistence Layer)

- `MEMORY.md` — curated long-term facts. Injected into system prompt on every session start (main/private sessions only). Acts as durable reference memory.
- `memory/YYYY-MM-DD.md` — daily append-only logs. Today + yesterday read at session start. Older entries available via `memory_search`.

These files already exist in Tess's workspace layout but are currently unpopulated and unindexed.

### 2.2 Memory Tools (Retrieval Layer)

- `memory_search` — semantic recall over indexed snippets (~400-token chunks, 80-token overlap). Returns snippet text, file path, line range, and score.
- `memory_get` — targeted read of a specific memory file/line range. Paths outside `MEMORY.md`/`memory/` are rejected. Degrades gracefully on missing files (returns `{ text: "", path }` instead of ENOENT).

Both tools are agent-facing — Tess uses them during conversations to recall relevant context.

### 2.3 Memory Flush (Compaction Safety Net)

When a session approaches compaction, OpenClaw can trigger a silent agentic turn that prompts the model to write durable notes to `memory/YYYY-MM-DD.md` before the lossy summarization runs. This is controlled by `compaction.memoryFlush` and is currently not configured.

**Scope:** Memory flush fires on auto-compaction within any session where the workspace is writable. Isolated cron sessions mint fresh session IDs per run and are typically short-lived — they are unlikely to hit compaction thresholds. The primary beneficiary of memoryFlush is the voice agent's main Telegram session, which accumulates context over extended conversations. This is the correct scope: the voice session is where conversational context lives and where compaction loss is most damaging. Mechanic sessions and cron jobs are stateless by design.

### 2.4 Retrieval Pipeline

The full retrieval pipeline when hybrid search is enabled:

```
Vector + BM25 → Weighted Merge → Temporal Decay → Sort → MMR → Top-K Results
```

- **Vector similarity:** Semantic match — finds related content even when wording differs
- **BM25 keyword relevance:** Exact token match — finds IDs, config keys, error strings, names
- **Temporal decay:** Exponential score multiplier based on age. Evergreen files (`MEMORY.md`, non-dated files in `memory/`) are exempt. Dated daily files use the date extracted from filename.
- **MMR (Maximal Marginal Relevance):** Diversity filter — prevents near-duplicate snippets from dominating results

---

## 3. Configuration Design

### 3.1 Target Configuration

The following block is added to `agents.defaults` in `openclaw.json`:

```json
{
  "agents": {
    "defaults": {
      "memorySearch": {
        "enabled": true,
        "cache": {
          "enabled": true,
          "maxEntries": 50000
        },
        "query": {
          "hybrid": {
            "enabled": true,
            "vectorWeight": 0.7,
            "textWeight": 0.3,
            "candidateMultiplier": 4,
            "mmr": {
              "enabled": true,
              "lambda": 0.7
            },
            "temporalDecay": {
              "enabled": true,
              "halfLifeDays": 30
            }
          }
        }
      },
      "compaction": {
        "mode": "safeguard",
        "memoryFlush": {
          "enabled": true
        }
      }
    }
  }
}
```

### 3.2 Configuration Rationale

| Setting | Value | Rationale |
|---------|-------|-----------|
| `compaction.mode` | `"safeguard"` | Already set in Tess's live config. Safeguard mode uses chunked summarization for long histories, vs. `"default"` which can silently fail at ~180k tokens producing "Summary unavailable" truncation (GitHub issue #7477). `openclaw doctor --fix` also sets safeguard. Retained here for explicitness — not a change. |
| `memorySearch.enabled` | `true` | Core change. Enables `memory_search` and `memory_get` tools, starts embedding index. |
| `cache.enabled` | `true` | Caches chunk embeddings in SQLite. Prevents re-embedding unchanged text during frequent updates. Free optimization. |
| `cache.maxEntries` | `50000` | OpenClaw documented default. Tess's corpus will be far smaller than this for the foreseeable future. |
| `hybrid.enabled` | `true` | Combines vector + BM25. Vector alone is weak at exact tokens (config keys, error strings, names). BM25 alone is weak at paraphrases. Both together cover the query space. |
| `vectorWeight` / `textWeight` | `0.7` / `0.3` | OpenClaw documented default. Favors semantic match but gives meaningful weight to keyword hits. Adjust only if empirical results warrant it. |
| `candidateMultiplier` | `4` | OpenClaw documented default. Retrieves 4× the final result count from each backend before merging. Ensures the merge has enough candidates. |
| `mmr.enabled` | `true` | Prevents near-duplicate daily note snippets from dominating results. Tess will accumulate daily notes with overlapping content (e.g., repeated references to the same customer or project). |
| `mmr.lambda` | `0.7` | OpenClaw documented default. Balanced: slight relevance bias over diversity. `1.0` = pure relevance (no diversity), `0.0` = max diversity. |
| `temporalDecay.enabled` | `true` | Ensures recent context outranks stale notes. Without decay, a well-worded note from 6 months ago can outrank yesterday's update on the same topic. |
| `temporalDecay.halfLifeDays` | `30` | OpenClaw recommended default for daily-note-heavy workflows. Score halves every 30 days: 7 days = ~84%, 30 days = 50%, 90 days = 12.5%, 180 days = ~1.6%. Evergreen files (`MEMORY.md`, non-dated `memory/*.md`) are exempt — always score at full value. Start here; increase to 60-90 if useful older context is getting buried. |
| `compaction.memoryFlush.enabled` | `true` | Triggers a silent agentic turn before compaction, prompting Tess to write durable notes. Without this, anything not yet written to disk is lost when compaction summarizes older conversation history. This is the single highest-impact change in this spec. |

### 3.3 Embedding Provider

No explicit `memorySearch.provider` is set. OpenClaw auto-selects based on available API keys:

1. ~~`local`~~ — no local model path configured
2. **`openai`** — if an OpenAI key can be resolved → not configured
3. **`gemini`** — if a Gemini key can be resolved → not configured
4. **`voyage`** — if a Voyage key can be resolved → not configured
5. **`mistral`** — if a Mistral key can be resolved → not configured

**Resolution:** Tess's Anthropic API key is configured via `auth.profiles.anthropic:default`. OpenClaw's auto-selection logic needs to be verified against v2026.2.25 — it is unclear from the docs whether the Anthropic auth profile satisfies embedding provider resolution, since the auto-selection list names OpenAI/Gemini/Voyage/Mistral but does not mention Anthropic.

**If auto-selection does not resolve to a working provider**, explicitly set:

```json
"memorySearch": {
  "provider": "openai",
  "model": "text-embedding-3-small",
  "remote": {
    "apiKey": "${OPENAI_API_KEY}"
  }
}
```

This requires obtaining an OpenAI API key and storing it in the openclaw user's environment. `text-embedding-3-small` is the cheapest option (~$0.02 per 1M tokens) and is widely used for memory search.

**Alternative:** Use Gemini embeddings (`gemini-embedding-001`) if a Gemini API key is already available or cheaper to obtain. Or set `provider: "local"` with a GGUF model path if zero-cost/zero-network is preferred — at the expense of first-run model download and slightly lower embedding quality.

**Open question:** Does v2026.2.25 support Anthropic embeddings natively for memory search? This needs verification during Phase 0 before committing to a provider choice.

### 3.4 Per-Agent Override: Mechanic Memory Search Disabled

Mechanic runs heartbeat checks (60-min cycle) and cron jobs in isolated sessions. It doesn't need conversational memory recall — its checks are stateless binary health assessments. Enabling memory search for mechanic wastes tokens on embedding injection and retrieval overhead every 60 minutes, 24/7, on a local model that doesn't benefit from it.

Add per-agent override to `openclaw.json`:

```json
{
  "agents": {
    "list": [
      {
        "id": "mechanic",
        "memorySearch": {
          "enabled": false
        }
      }
    ]
  }
}
```

This is part of the baseline config, not deferred. Only the voice agent (Haiku 4.5, primary Telegram sessions) benefits from memory search.

### 3.5 What Is NOT Changed

| Setting | Current Value | Rationale for No Change |
|---------|--------------|------------------------|
| `memory.backend` | (default: builtin SQLite) | QMD is deferred per design spec §9. Builtin is sufficient at current corpus scale. |
| `memorySearch.extraPaths` | (not set) | Vault content outside the workspace is not indexed. Tess reads vault files via the bridge, not memory search. Adding vault paths would expand the data accessible through Telegram prompt injection (colocation spec T1). |
| `memorySearch.experimental.sessionMemory` | (not set) | Session transcript indexing adds token overhead and complexity. Defer until daily memory files prove insufficient for cross-session recall. |
| `contextPruning` | (not set) | Context pruning removes old tool results from the prompt. Useful for long sessions with heavy tool use, but adds a configuration surface. Defer until compaction frequency data from memoryFlush reveals whether pruning adds value. |
| `compaction.memoryFlush.softThresholdTokens` | (default) | Use OpenClaw's default threshold (4000 tokens before compaction triggers). Tune only if flush fires too early or too late. |
| `compaction.memoryFlush.prompt` / `systemPrompt` | (default) | Use OpenClaw's default prompts. Custom prompts are an optimization — the defaults are designed for this use case. |
| `tools.fs.workspaceOnly` | `true` | Unchanged. Memory files live inside the workspace. No filesystem access expansion needed. |

---

## 4. Security Assessment

### 4.1 Colocation Threat Model Impact

| Threat | Impact of Memory Search Enablement |
|--------|-----------------------------------|
| T1 (Prompt injection via messaging) | **No change.** Memory search indexes files already inside the workspace (`MEMORY.md`, `memory/*.md`). The workspace is already accessible to the agent. No new data surfaces are exposed. `extraPaths` is explicitly not set — vault content outside the workspace remains unindexed. |
| T4 (Lateral movement to Crumb creds) | **No change.** `workspaceOnly: true` is preserved. Memory tools (`memory_search`, `memory_get`) reject paths outside `MEMORY.md`/`memory/`. |
| All other threats | **No change.** Memory search is a retrieval capability over existing workspace files, not a new I/O surface. |

### 4.2 Cost Surface

| Component | Cost Impact |
|-----------|------------|
| Embedding API calls | Depends on provider. OpenAI `text-embedding-3-small`: ~$0.02/1M tokens. At Tess's estimated daily conversation volume (~30-50 Telegram messages/day based on chief-of-staff spec §11 projected usage — no operational data yet as M1 is in gate eval), embedding cost is negligible — likely <$0.10/month. |
| Token overhead from injected memory snippets | `memory_search` returns snippets capped at ~700 chars each. With top-K defaults (typically 3-5 results), this adds 2,000-3,500 tokens per search. This is context window budget consumed per query, not API cost per se — but it can accelerate compaction if searches are frequent. |
| memoryFlush turns | One additional agentic turn per compaction cycle. Uses the voice agent's model (Haiku 4.5). At ~500 tokens per flush, cost is negligible. |
| Embedding cache storage | SQLite file in workspace. Disk cost is zero at any realistic corpus size. |

**Estimated monthly cost increase:** $0.10-0.50, depending on embedding provider and conversation volume. Well within the cost envelope defined in the chief-of-staff spec §11.

---

## 5. MEMORY.md Curation Strategy

`MEMORY.md` is injected into the system prompt on every main/private session start. It must remain concise to avoid bootstrap truncation and compaction acceleration.

### 5.1 Content Guidelines

**Include in MEMORY.md (curated, durable facts):**

- Danny's communication preferences and working style
- Key account names and relationship context (top 5-10 accounts)
- Recurring meeting schedule and prep patterns
- Active project names and current phases (refreshed weekly)
- Known operational patterns (e.g., "Danny prefers bullet summaries for briefings")
- Tess's operational learnings (e.g., "awareness-check bash migration was needed because isolated sessions can't exec tools")

**Exclude from MEMORY.md (goes in daily logs instead):**

- Transient conversational context ("Danny asked about X today")
- Specific task details or one-time instructions
- Detailed project state (this lives in vault specs, not memory)
- Anything that changes more than weekly

### 5.2 Size Budget

Target: **≤2,000 tokens** for MEMORY.md. This is approximately 1,500 words or ~60 curated facts.

At 2,000 tokens, MEMORY.md adds ~2% to Haiku 4.5's 200K context window — negligible impact on compaction frequency. If MEMORY.md grows beyond 3,000 tokens, review and prune.

### 5.3 Maintenance Cadence

- **Weekly:** Review MEMORY.md during weekly ops review. Remove stale entries, update project phases.
- **Monthly:** Review half-life effectiveness. If useful older context is consistently buried in daily logs, increase `halfLifeDays`. If stale noise is prominent, decrease it.
- **On prompt revision:** Any change to `SOUL.md` should trigger a review of MEMORY.md for consistency.

---

## 6. Operational Procedures

### 6.1 Verification After Enablement

**CLI flag verification required:** Per the CLI hallucination pattern (2 confirmed occurrences in vault — Apple services spec, comms channel spec), the following commands must be verified against `openclaw memory --help` and `openclaw memory status --help` before they appear in any runbook:

- `openclaw memory status --deep --index` (used in verification step 2 below)
- `openclaw memory index --verbose` (used in §7 failure modes)

If these flags don't exist, substitute with the correct equivalent from `--help` output.

After applying the config change and restarting the gateway:

1. **Embedding provider resolved:** Check gateway logs for embedding provider selection. If "memory search stays disabled until configured" appears, provider needs explicit configuration (see §3.3).

2. **Index built:** Run `sudo -u openclaw env HOME=/Users/openclaw /opt/homebrew/bin/openclaw memory status --deep --index`. Verify: store exists, file count > 0, store is not dirty.

3. **Write test:** Send Tess a message via Telegram: "Remember that my preferred briefing format is bullet summaries." Verify `memory/YYYY-MM-DD.md` is created/updated in the workspace.

4. **Recall test:** In a new session, ask Tess: "What's my preferred briefing format?" Verify she retrieves the previously stored fact via `memory_search`.

5. **Hybrid test:** Store a fact containing an exact token (e.g., "Project FIF-029 CLI runner passed code review"). Later query with a paraphrase ("What happened with the feed-intel CLI runner?") and with exact terms ("FIF-029 code review"). Both should return the relevant snippet.

6. **Memory flush test:** Have a long enough conversation to approach compaction. Verify in gateway logs that a memory flush turn fires before compaction. Verify that `memory/YYYY-MM-DD.md` was written to during the flush.

7. **Token pressure check:** After several conversations, use `/context list` (if available via Telegram) or check gateway logs for context window utilization. Verify that memory injection is not causing abnormally frequent compaction.

### 6.2 Monitoring

Add the following bash health check to the mechanic's operational checks (consistent with the awareness-check and vault-health bash migration pattern):

**Memory index health check** (add to mechanic HEARTBEAT.md or as a standalone bash check):

- **Check:** Verify `memory/` directory contains at least one `.md` file with mtime within the last 48 hours during periods where Tess has active conversations. If no recent memory files exist after 48 hours of active Telegram sessions, emit a warning to `_openclaw/state/vault-health-notes.md`.
- **Check:** Verify the embedding index SQLite file exists at `~/.openclaw/memory/<agentId>.sqlite` and is non-empty. If missing or zero-size, alert via Telegram.
- **Threshold:** These checks are meaningful only after Phase 0 is complete and memory search has been active for 24+ hours.

If embedding provider failures are observed in gateway logs, add a `grep`-based log scan to the mechanic heartbeat (pattern: "embedding" + "error\|fail\|unavailable").

**Note on v2026.2.26:** The spec references v2026.2.25 throughout. If the upgrade to v2026.2.26 happens before or during enablement, embedding provider support may change — re-verify Step 0 after any upgrade.

### 6.3 Rollback

If memory search causes issues (token pressure, compaction storms, embedding API failures, unexpected cost):

```json
"memorySearch": {
  "enabled": false
}
```

One config change + gateway restart. Memory files remain on disk and are unaffected. The embedding index (SQLite) can be deleted if needed but does not cause harm if left in place. `memoryFlush` can be disabled independently if it's the flush turn specifically that's causing problems.

---

## 7. Failure Modes

| Failure | Impact | Mitigation |
|---------|--------|------------|
| Embedding provider not resolved | Memory search silently disabled — tools unavailable | Verify provider during Phase 0 (§6.1 step 1). If auto-selection fails, configure explicitly (§3.3). |
| Embedding API key invalid/expired | Memory search disabled until key is refreshed | Gateway logs will show embedding errors. Mechanic health check detects via `memory status`. |
| Index dirty after upgrade | `memory_search` returns stale or empty results | Run `openclaw memory index --verbose` to reindex. Add post-upgrade reindex to upgrade runbook. |
| MEMORY.md grows too large | Bootstrap truncation; increased compaction frequency | Size budget (§5.2) limits to ≤2,000 tokens. Weekly review cadence (§5.3) enforces pruning. |
| Memory flush fires during sensitive conversation | Tess writes a flush turn that disrupts conversation flow | Default prompts use `NO_REPLY` — flush is silent. If disruption occurs, tune `softThresholdTokens` higher. |
| Over-injection token pressure | Frequent compaction from injected memory snippets | Monitor via `/context list` or gateway logs. Reduce `maxResults` in hybrid config if needed. |
| Silent persistence failure (memory-core stops writing) | Daily logs not updated despite active conversations | Mechanic health check verifies `memory/YYYY-MM-DD.md` timestamps move during active conversation windows. |
| Stale daily notes outrank recent updates | Retrieval returns irrelevant old context | Temporal decay (30-day half-life) mitigates. If insufficient, reduce half-life or increase `vectorWeight`. |

---

## 8. Implementation Phasing

This is a single-phase change — no multi-milestone rollout required. The entire scope is a config update + verification.

### Phase 0 — Enablement (estimated: 1-2 hours)

**Step 0 — Embedding provider verification (BLOCKING GATE):**

Nothing else in this spec matters if there is no working embedding provider. This step must pass before any config changes are applied.

- [ ] Check whether Anthropic auth profile satisfies embedding provider auto-selection: start gateway with `memorySearch.enabled: true` only (no other changes), check gateway logs for provider selection
- [ ] If auto-selection resolves to a working provider → proceed to Step 1
- [ ] If "memory search stays disabled until configured" appears → obtain API key for chosen provider:
  - **Preferred:** OpenAI `text-embedding-3-small` (~$0.02/1M tokens) — set `OPENAI_API_KEY` in openclaw user environment
  - **Alternative:** Gemini `gemini-embedding-001` (free tier available) — set `GEMINI_API_KEY`
  - **Zero-cost alternative:** `provider: "local"` with GGUF model path — requires first-run model download, slightly lower quality
- [ ] Re-verify: restart gateway, confirm embedding provider resolves, confirm index creation begins
- [ ] **Gate:** `openclaw memory status` shows a valid provider and store. If this fails, STOP. Do not proceed.

**Step 1 — Configuration and seeding:**

- [ ] Seed initial `MEMORY.md` with 10-15 curated facts (owner: Crumb — has vault context to write this; see §5.1 for content guidelines)
- [ ] Apply remaining `openclaw.json` config changes (§3.1): hybrid search, MMR, temporal decay, cache, memoryFlush, mechanic override
- [ ] Restart gateway: `sudo launchctl kickstart -k system/ai.openclaw.gateway`

**Step 2 — Verification:**

- [ ] Run verification suite (§6.1 steps 1-7)
- [ ] If all verifications pass: memory search is operational
- [ ] If any verification fails: diagnose, fix, re-verify

### Post-Enablement Observation (3-5 days)

- [ ] Monitor compaction frequency — does it increase noticeably?
- [ ] Monitor embedding costs on provider dashboard
- [ ] Monitor retrieval quality — does Tess surface relevant memories?
- [ ] Review MEMORY.md size — is it growing beyond budget?
- [ ] Evaluate temporal decay setting — is 30 days appropriate?
- [ ] Decision: keep current settings, tune, or rollback

---

## 9. Relationship to QMD

QMD (`memory.backend = "qmd"`) replaces the builtin SQLite indexer with a local-first hybrid search sidecar (BM25 + vectors + reranking + query expansion). It is documented as experimental in OpenClaw and deferred in the Crumb design spec §9.

**This spec does not enable QMD.** The builtin provider is sufficient at Tess's current corpus scale (likely <100 memory files in the first months of operation). QMD adds operational complexity (Bun dependency, SQLite extension requirements, XDG directory management, first-query model downloads, concurrency sensitivity documented in v2026.2.21 release notes).

**Trigger for QMD adoption:** When keyword + tag search starts failing at vault scale, or when Tess's memory corpus grows large enough that builtin retrieval quality degrades. This is the same trigger defined in the Crumb design spec. The memory search enablement in this spec provides the empirical baseline data to evaluate whether QMD is needed.

---

## 10. Open Questions

1. ~~**Anthropic embeddings support.**~~ **RESOLVED (2026-02-27).** OpenClaw v2026.2.25 does NOT support Anthropic as an embedding provider. Auto-selection with only an Anthropic auth profile resolves to `Provider: none`. An explicit OpenAI API key (`text-embedding-3-small`, 1536 dims) was configured in the openclaw user's Keychain, and `provider: "openai"` + `model: "text-embedding-3-small"` added explicitly to `memorySearch` config. Auto-selection (`requested: auto`) finds the provider but does not fully activate memory search — explicit provider declaration is required. The `openclaw memory status` CLI reports "Memory search disabled" even when the gateway runtime has memory search active and functional — this is a misleading diagnostic; verify via Telegram test + runtime logs, not CLI status.

2. **Session transcript indexing.** OpenClaw supports indexing session transcripts (`memorySearch.experimental.sessionMemory: true`) so `memory_search` can recall past conversations without relying on daily memory file writes. This is deferred in this spec but may be the natural next step if daily memory files prove insufficient for cross-session recall.

3. **Interaction with awareness-check bash script.** The awareness-check currently runs as a standalone bash script with direct Telegram Bot API delivery. It does not use OpenClaw's memory tools. If memory search is enabled, should awareness-check be reconsidered as an OpenClaw cron job that can leverage memory for richer context? Probably not — the bash-for-checks pattern is validated and zero-cost. But worth revisiting if awareness-check's scope expands beyond binary health checks.

4. **memoryFlush bug (GitHub #4836).** A January 2026 bug report documented memoryFlush being enabled in config but not executing during compaction events. The issue was closed (linked to #5343, presumably fixed). Verify during post-enablement observation that flush turns actually fire — check gateway logs for "memory flush" activity around compaction events. If the bug persists in v2026.2.25, the fix is to upgrade or work around with explicit memory-writing prompts in SOUL.md.

---

## 11. Cost Analysis

| Component | Monthly Estimate | Notes |
|-----------|-----------------|-------|
| Embedding API | $0.05-0.20 | text-embedding-3-small at estimated ~30-50 msgs/day + daily file updates. No operational data yet — refine after Week 1 gate. |
| Memory flush turns | $0.02-0.05 | ~1 flush/day on Haiku 4.5 at ~500 tokens |
| Token overhead (indirect) | $0.10-0.30 | Increased context from injected snippets → marginal increase in per-message cost |
| **Total incremental** | **$0.17-0.55/month** | Well within chief-of-staff §11 cost envelope |

---

## 12. Rollback Plan

**Selective rollback (memory search only):**

1. Set `memorySearch.enabled: false` in `openclaw.json`
2. Restart gateway
3. Memory files remain on disk — no data loss
4. Embedding index (SQLite) can be left in place or deleted

**Selective rollback (memory flush only):**

1. Remove `compaction.memoryFlush` block from `openclaw.json`
2. Restart gateway
3. Compaction reverts to default behavior (lossy summarization without pre-flush)

**Full rollback (both):**

1. Revert `openclaw.json` to pre-enablement state (restore from `.bak`)
2. Restart gateway
3. System returns to stateless-across-sessions behavior

No data loss in any rollback scenario. Memory files written during the enablement period persist and remain human-readable markdown.
