---
type: reference
domain: software
status: active
created: 2026-03-14
updated: 2026-04-11
tags:
  - system/architecture
topics:
  - moc-crumb-architecture
---

# 03 — Runtime Views

This section documents six key runtime flows through the system as sequence diagrams with prose summaries. Each flow covers the happy path and notes failure handling where relevant.

**Source attribution:** Synthesized from the design spec ([[crumb-design-spec-v2-4]] §4.1, §6, §7.1), [[context-checkpoint-protocol]], [[session-end-protocol]], [[bridge-dispatch-protocol]], the feed-intel processing chain (formerly [[feed-intel-processing-chain]] and [[feed-intel-processing-chain-diagram]]), [[fif-triage-and-signals]], and the AKM design in spec §5 and `knowledge-retrieve.sh`.

---

## 1. Session Lifecycle

A Crumb session from startup through work to session end. This is the most common runtime flow.

```mermaid
%%{init: {'theme': 'default'}}%%
sequenceDiagram
    actor Danny
    participant CC as Claude Code
    participant Hook as SessionStart Hook
    participant VC as vault-check.sh
    participant AKM as knowledge-retrieve.sh
    participant Vault

    Danny->>CC: Start session
    CC->>Hook: SessionStart fires
    Hook->>Hook: git pull
    Hook->>VC: vault-check (deferred to pre-commit)
    Hook->>Hook: Obsidian CLI probe
    Hook->>Hook: Rotation checks
    Hook->>AKM: --trigger session-start
    AKM->>AKM: QMD semantic search (5 items)
    AKM-->>CC: Knowledge Brief
    Hook-->>CC: Startup summary

    Danny->>CC: "Resume project X"
    CC->>Vault: Read project-state.yaml
    CC->>Vault: Read run-log.md (last entry)
    CC->>Vault: Read tasks.md
    CC-->>Danny: State summary + next steps

    loop Work Phase
        Danny->>CC: Task instruction
        CC->>Vault: Read source files
        CC->>Vault: Write deliverables
        CC-->>Danny: Results
    end

    Note over CC,Vault: Phase Transition (if applicable)
    CC->>CC: Verify summaries exist
    CC->>CC: Goal progress check
    CC->>CC: Compound reflection
    CC->>CC: Check /context
    CC->>Vault: Log phase transition to run-log

    Note over CC,Vault: Session End (autonomous)
    CC->>Vault: Log to run-log + compound eval
    CC->>Vault: Update project-state.yaml
    CC->>CC: Failure log (if session went poorly)
    CC->>CC: Code review sweep (if code tasks)
    CC->>CC: Build verification (if repo_path + build_command)
    CC->>AKM: QMD index update
    CC->>CC: AKM feedback measurement
    CC->>CC: git add + commit (conditional)
    CC->>CC: git push
```

### Prose Summary

**Startup:** The SessionStart hook runs automatically — git pull, vault-check (deferred to pre-commit), Obsidian CLI availability check, rotation checks, and the AKM Knowledge Brief (5 cross-domain items via QMD semantic search with decay-based relevance scoring).

**Resume:** Claude reads `project-state.yaml` for phase/task state, the last run-log entry for narrative context, and `tasks.md` for remaining work. Presents a state summary and waits for confirmation.

**Work:** Tasks execute within the current phase. Claude reads source files, writes deliverables, and reports results. Context management is autonomous (compact at >70%, clear+reconstruct at >85%).

**Phase transition:** Context Checkpoint Protocol runs: verify summaries → goal progress check → compound reflection → context check → log transition. Compound reflection is structurally enforced at every phase boundary.

**Session end (autonomous, 9 steps):** Log with compound eval → project state refresh → failure log (conditional) → code review sweep (conditional) → build verification (conditional) → AKM feedback + QMD update → inbox sweep → conditional commit → git push.

**Failure handling:** If context exhausts mid-work: `/compact` or `/clear` + vault reconstruction. If a skill fails to load: retry once, degrade, then escalate. If the session crashes: Session Interruption Recovery (spec §7.4) reconciles filesystem state against run-log on next resume.

---

## 2. Tess Dispatch (Telegram Interaction)

How a Telegram message from Danny reaches Tess and gets a response.

```mermaid
%%{init: {'theme': 'default'}}%%
sequenceDiagram
    actor Danny
    participant TG as Telegram
    participant GW as OpenClaw Gateway
    participant TV as Tess Voice (Kimi K2.5)
    participant Vault

    Danny->>TG: Send message
    TG->>GW: Webhook delivery
    GW->>GW: Route to tess-voice agent
    GW->>TV: Process message

    alt Quick Lookup
        TV->>Vault: Read relevant files
        TV-->>GW: Response
    else Status Check
        TV->>Vault: Read project-state, run-log
        TV-->>GW: Status summary
    else Needs Crumb
        TV-->>GW: "This needs a Crumb session"
        Note over TV,Vault: Stages context in _openclaw/inbox/
        TV->>Vault: Write to _openclaw/inbox/
    end

    GW->>TG: Send response
    TG-->>Danny: Display response
```

### Prose Summary

Danny sends a Telegram message. The Telegram API delivers it to the OpenClaw gateway via webhook. The gateway routes it to the tess-voice agent (Kimi K2.5 via OpenRouter, with Qwen 3.6 failover).

**Interactive dispatch (Amendment Z, tess-v2 Phase IMPLEMENT as of 2026-04-11):** The dispatch flow is evolving toward an orchestrator-driven interactive model where Tess Voice can request multi-turn clarification via the bridge before committing a governed operation. Amendment Z peer-reviewed (two rounds). Phase A end-to-end loop completed 2026-04-06. Current sequence diagram reflects the stabilized quick-lookup / status-check / needs-Crumb paths — interactive-dispatch refinements are in active soak and may adjust the diagram in a later refresh.

**Quick lookups:** Tess reads vault files directly and responds. **Status checks:** Tess reads project-state.yaml and recent run-log entries, formats a summary. **Governed work:** Tess recognizes the request exceeds her scope (architecture decisions, governed file modifications, convergence/peer review), stages context in `_openclaw/inbox/`, and responds "This needs a Crumb session."

Tess reads the full vault but writes only to `_openclaw/` directories. No governed vault modifications happen through this flow.

**Failure handling:** OpenRouter handles primary→failover routing at the gateway layer (Kimi K2.5 → Qwen 3.6). If both cloud endpoints are unavailable, tess-voice falls back to limited mode (local Nemotron via `com.tess.llama-server` with reduced scope). If the OpenClaw gateway is down, Telegram messages queue in Telegram's infrastructure until the gateway recovers.

---

## 3. Feed Pipeline

Content capture through triage to vault promotion. Three stages, two clocks, two agents.

```mermaid
%%{init: {'theme': 'default'}}%%
sequenceDiagram
    participant Src as Content Sources<br/>(X API, RSS)
    participant Cap as Capture Clock<br/>(launchd)
    participant DB as SQLite<br/>(pipeline.db)
    participant Att as Attention Clock<br/>(launchd, daily)
    participant Triage as Triage Engine<br/>(Kimi K2.5 via OpenRouter)
    participant TG as Telegram
    participant Inbox as _openclaw/inbox/
    participant Crumb as Crumb<br/>(/feed-pipeline)
    participant Vault

    Note over Src,Cap: Stage 1: Capture
    Src->>Cap: Fetch content
    Cap->>Cap: Normalize + dedup
    Cap->>DB: Store in pending queue

    Note over DB,TG: Stage 2: Attention
    DB->>Att: Read pending items
    Att->>Triage: Batch triage (10-20 items)
    Note right of Triage: Vault snapshot provides<br/>project context + priorities
    Triage-->>Att: Scored items (priority, tags, why_now, action)

    alt Meets routing bar
        Att->>Inbox: Write feed-intel-*.md
    end
    Att->>TG: Daily digest (grouped by priority)

    Note over Inbox,Vault: Stage 3: Crumb Processing
    Crumb->>Inbox: Glob feed-intel-*.md
    Crumb->>Crumb: Classify into tiers

    alt Tier 1 (high priority + high confidence)
        Crumb->>Crumb: Permanence evaluation
        alt Auto-promote (1a)
            Crumb->>Vault: Create signal-note in Sources/signals/
        else Review queue (1b)
            Crumb-->>Crumb: Queue for operator review
        end
    else Tier 2 (actionable)
        Crumb->>Vault: Extract action → project run-log
        Crumb->>Inbox: Delete source file
    else Tier 3 (no action)
        Note right of Crumb: TTL cron purges after 14 days
    end
```

### Prose Summary

**Stage 1 (Capture Clock):** LaunchAgent jobs fetch content from configured sources (X API v2 bookmarks, TwitterAPI.io search, RSS). Content is normalized to a unified format, deduped against SQLite, and queued. Runs on per-adapter schedules, decoupled from delivery.

**Stage 2 (Attention Clock):** Runs daily. Batches pending items (10–20 per LLM call) through the cloud triage engine (Kimi K2.5 via OpenRouter; Qwen 3.6 failover). Each item gets: priority, tags, `why_now` rationale, recommended action, confidence. A vault snapshot (project frontmatter, operator priorities, recent session summaries) provides triage context. Items meeting the routing bar land in `_openclaw/inbox/`. All items go to a Telegram digest.

**Stage 3 (Crumb Processing):** The `/feed-pipeline` skill processes the inbox. Tier 1 (high priority + high confidence + capture action) gets permanence evaluation — auto-promote to `Sources/signals/` as signal-notes (1a) or route to operator review queue (1b). Circuit breaker: >10 Tier 1 items routes all to review queue (classifier drift signal). Tier 2 (actionable items) gets one-line action extracted and routed to project run-logs. Tier 3 gets no action; TTL cron purges after 14 days.

**Feedback loop:** Telegram digest supports inline commands (promote, save, research, ignore). `save` routes to `_openclaw/feeds/kb-review/` for Crumb review. `research` dispatches a bridge research job.

**Failure handling:** Capture and attention clocks are decoupled — capture failures don't block delivery. Triage failures leave items in pending queue for next run. Crumb processing failures leave items in inbox (idempotent — reprocessing is safe due to filename-based dedup).

---

## 4. Mission Control Dashboard

The web dashboard for feed triage and pipeline visibility.

```mermaid
%%{init: {'theme': 'default'}}%%
sequenceDiagram
    actor Danny
    participant MC as Mission Control<br/>(Web Dashboard)
    participant DB as SQLite<br/>(pipeline.db)
    participant Crumb as Crumb<br/>(/feed-pipeline)
    participant Vault

    Danny->>MC: Open Intelligence page
    MC->>DB: Query pending items
    DB-->>MC: Display pipeline section

    alt Skip
        Danny->>MC: Click Skip
        MC->>DB: Mark skipped (immediate)
    else Delete
        Danny->>MC: Click Delete
        MC->>DB: Remove from queue (immediate)
    else Promote
        Danny->>MC: Click Promote (optional kb_tag)
        MC->>DB: Write to dashboard_actions<br/>(action: promote, consumed_at: null)
    end

    Note over Crumb,Vault: During Crumb session
    Crumb->>DB: Query dashboard_actions<br/>(consumed_at IS NULL)
    loop Each promotion
        Crumb->>Vault: Create signal-note<br/>(skip permanence eval —<br/>human judgment applied)
        Crumb->>DB: Set consumed_at
    end
```

### Prose Summary

The Mission Control Intelligence page surfaces the FIF pipeline section. Danny can **skip** (immediate, no vault write), **delete** (immediate, removes from queue), or **promote** (queues a row in `dashboard_actions` with optional `kb_tag` override).

During a Crumb session, the `/feed-pipeline` skill's Step 0 queries `dashboard_actions` for unconsumed promotions. Because human judgment was already applied at the dashboard, these skip the permanence evaluation and go straight to signal-note creation. Each consumed promotion gets its `consumed_at` timestamp set.

The dashboard is served from `~/openclaw/crumb-dashboard` via Cloudflare Tunnel + Access. Telegram digest is transitioning to notification-only as the dashboard matures.

**Failure handling:** Dashboard actions are durable in SQLite — if a Crumb session fails mid-processing, unconsumed promotions remain in the queue for the next session.

---

## 5. Bridge Handoff (Tess → Crumb → Tess)

How a governed request flows from Telegram through the bridge to Crumb and back.

```mermaid
%%{init: {'theme': 'default'}}%%
sequenceDiagram
    actor Danny
    participant TG as Telegram
    participant TV as Tess Voice
    participant Inbox as _openclaw/inbox/
    participant BW as ai.openclaw.bridge.watcher<br/>(kqueue, Python)
    participant CC as claude --print<br/>(Bridge Crumb)
    participant Outbox as _openclaw/outbox/
    participant Vault

    Danny->>TG: Request (needs governance)
    TG->>TV: Webhook
    TV->>TV: Recognize: exceeds scope
    TV-->>TG: Confirmation echo<br/>(exact payload + hash)
    Danny->>TG: CONFIRM

    TV->>Inbox: Write request file
    BW->>BW: kqueue detects new file (sub-ms)
    BW->>CC: Spawn claude --print<br/>(full CLAUDE.md governance)

    CC->>Vault: Read governed files
    CC->>CC: Execute under governance
    CC->>Vault: Write deliverables
    CC->>CC: Compute governance check<br/>(sha256 hash + canary)
    CC->>Outbox: Write stage output JSON

    BW->>Outbox: Read response
    BW->>TV: Forward to Tess
    TV->>TG: Deliver result
    TG-->>Danny: Display result
```

### Prose Summary

Danny sends a request via Telegram that requires governed vault operations (architecture decisions, project file modifications, etc.). Tess Voice recognizes it exceeds her scope.

**Confirmation echo:** Before acting, Tess displays the exact payload she's about to relay plus a hash, and waits for explicit CONFIRM from Danny. This prevents unintended bridge writes.

**Bridge transport:** Tess writes the request to `_openclaw/inbox/`. The bridge-watcher (persistent Python process using kqueue) detects the new file in sub-milliseconds and spawns `claude --print` with full CLAUDE.md governance loaded.

**Governed execution:** The bridge Crumb session reads vault files, executes the requested operation under identical governance rules as an interactive session, computes a governance check (SHA-256 hash of CLAUDE.md + canary stamp), and writes structured JSON output to `_openclaw/outbox/`.

**Response delivery:** The bridge-watcher reads the response, forwards it to Tess Voice, which delivers the result to Danny via Telegram.

**Security (4-layer):** Schema validation (request structure), payload hashing (canonical JSON), confirmation echo (write operations), post-processing governance verification (hash + canary in output).

**Kill switch:** Touching `_openclaw/.bridge-disabled` disables all bridge processing.

**Failure handling:** If `claude --print` fails, the bridge-watcher logs the error. The request file remains in inbox for manual review. If governance verification fails (hash mismatch), the output is rejected. `bestEffort` mode on delivery means Tess reports success even if Telegram delivery fails — a known triple-silent-failure pattern (documented in MEMORY.md).

---

## 6. AKM Surfacing (Knowledge Brief)

How the Active Knowledge Memory retrieves and surfaces relevant vault knowledge.

```mermaid
%%{init: {'theme': 'default'}}%%
sequenceDiagram
    participant Hook as SessionStart Hook
    participant AKM as knowledge-retrieve.sh
    participant QMD as QMD Index
    participant Vault
    participant CC as Claude Code

    Note over Hook,AKM: Trigger: skill-activation
    Hook->>AKM: --trigger skill-activation
    AKM->>QMD: Semantic search<br/>(3 items, project-scoped)
    QMD-->>AKM: Matches
    AKM-->>CC: Injected as additionalContext

    Note over CC,Vault: Session End
    Note over AKM: Consumption tracking removed<br/>(retrieval logging continues)
```

### Prose Summary

**Skill-activation retrieval:** Fires before every skill invocation for KB-eligible skills (automated via PreToolUse hook and `skill-preflight.sh`). Retrieves 3 project-scoped items and injects them as `additionalContext`. This is the primary AKM retrieval path — it has real context (project, task, skill) to target against.

**New-content trigger:** When new knowledge enters the vault (source ingestion, signal-note promotion), AKM surfaces 5 cross-pollination candidates — items from other domains that might relate to the new content.

**Feedback loop:** Removed. The Read-tool-based hit-rate metric was structurally flawed — briefs are consumed in context without triggering a Read on the source file, so all sessions showed 0% hit rate. Retrieval logging (what was surfaced and when) continues in `akm-feedback.jsonl` for QMD tuning.

**Failure handling:** AKM failures are non-blocking. If QMD is unavailable or returns no results, the session proceeds without a Knowledge Brief. The feedback script skips if no AKM entries exist for the day.
