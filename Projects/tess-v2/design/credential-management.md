---
type: design
domain: software
status: draft
created: 2026-04-01
updated: 2026-04-01
project: tess-v2
skill_origin: null
task: TV2-024
---

# Tess v2 — Credential Management Design

Comprehensive credential architecture for Tess v2: macOS Keychain as the single secret store, env var injection per Ralph loop session, OAuth refresh automation, mid-contract expiry handling, audit logging, never-in-vault enforcement, and privileged operation escalation via AD-009.

**Sources:** specification.md (§10b.3, §2.4), escalation-design.md (TV2-018, Gate 3 §5), contract-schema.md (TV2-019), service-interfaces.md (TV2-021b), state-machine-design.md (TV2-017, §13), migration-inventory.md (TV2-001), ralph-loop-spec.md (TV2-020).

---

## 1. Credential Store Architecture

### 1.1 Design Principle

macOS Keychain is the single credential store. No secrets in vault files, plist `EnvironmentVariables`, env files, or JSON configs. The vault stores credential *metadata* (which services need which credentials, expiry dates) but never the secrets themselves (spec §10b.3).

### 1.2 Keychain Service Naming Convention

All Tess v2 credentials use a structured `service` field in Keychain:

```
tess.v2.{service}.{credential-type}
```

Examples:
- `tess.v2.anthropic.api-key`
- `tess.v2.gmail.oauth-refresh-token`
- `tess.v2.gmail.oauth-access-token`
- `tess.v2.telegram.tess-bot-token`
- `tess.v2.telegram.fif-bot-token`
- `tess.v2.telegram.scout-bot-token`
- `tess.v2.discord.tess-bot-token`
- `tess.v2.discord.mechanic-bot-token`
- `tess.v2.x-oauth.client-secret`
- `tess.v2.x-oauth.refresh-token`
- `tess.v2.brave-search.api-key`

The `account` field in Keychain is always `tess-orchestrator` (the retrieving principal). This scopes Keychain Access prompts and ACL entries to the `tess` user context.

### 1.3 What Goes in Keychain

| Category | Examples | Keychain? |
|----------|----------|-----------|
| API keys | Anthropic, OpenAI, Perplexity, Brave, Gemini, DeepSeek, XAI, Mistral, Lucid, Healthchecks, TwitterAPI.io, YouTube, Book Scout | Yes |
| OAuth tokens | Google refresh token, Google access token, X OAuth client secret, X OAuth refresh token | Yes |
| Bot tokens | Telegram (Tess, FIF, Scout), Discord (Tess, Mechanic) | Yes |
| Webhook URLs | Discord webhooks (5) | No -- not secrets. Store in service config YAML |
| HC ping URL | Dead man's switch endpoint | No -- not a secret. Store in service config YAML |
| Vault paths | Read paths, staging paths | No -- contract fields, not credentials |
| Config values | Schedules, thresholds, cadences | No -- service config YAML or contract fields |

### 1.4 Keychain Access Control

- **Keychain location:** Default login keychain for `tess` user (`/Users/tess/Library/Keychains/login.keychain-db`)
- **ACL:** Each entry allows access only from the runner process (no global "Always Allow")
- **No inter-user access:** Danny's Keychain is not accessed. Credentials that Danny provisions are added to the tess user's Keychain via `security add-generic-password` (one-time setup or rotation)

### 1.5 Migration Path from Current Credentials

Current state: 22+ credentials scattered across plists, `~/.config/fif/env.sh`, OpenClaw JSON configs, and `_openclaw/state/` (migration-inventory.md §Credential Inventory).

Migration sequence per credential:

1. Read current value from source location
2. Store in Keychain: `security add-generic-password -a tess-orchestrator -s "tess.v2.{service}.{type}" -w "{value}" -T "" login.keychain-db`
3. Verify retrieval: `security find-generic-password -a tess-orchestrator -s "tess.v2.{service}.{type}" -w`
4. Update service config to reference Keychain name instead of inline value
5. Remove credential from original source location
6. Test service with Keychain-sourced credential

Migration is per-service during M5 service migration tasks (TV2-032 through TV2-037). Each service migration task includes a credential migration subtask. No big-bang cutover.

---

## 2. Credential Inventory — Keychain Migration Table

Complete mapping from current credential locations to Keychain entries. Derived from migration-inventory.md credential inventory.

| # | Credential | Current Location | Keychain Service Name | Env Var Name | Used By Services |
|---|-----------|-----------------|----------------------|-------------|-----------------|
| 1 | Anthropic API key | Gateway config, FIF env.sh, Scout env | `tess.v2.anthropic.api-key` | `TESS_ANTHROPIC_API_KEY` | fif-attention, overnight-research, morning-briefing, scout-daily, connections-brainstorm |
| 2 | OpenAI API key | env var | `tess.v2.openai.api-key` | `TESS_OPENAI_API_KEY` | memory-search embeddings |
| 3 | Tess Telegram bot token | Gateway config, plist env | `tess.v2.telegram.tess-bot-token` | `TESS_TELEGRAM_BOT_TOKEN` | awareness-check, email-triage, vault-health, morning-briefing, daily-attention |
| 4 | FIF Telegram bot token | FIF env.sh | `tess.v2.telegram.fif-bot-token` | `TESS_TELEGRAM_FIF_BOT_TOKEN` | fif-feedback |
| 5 | Scout Telegram bot token | Scout env | `tess.v2.telegram.scout-bot-token` | `TESS_TELEGRAM_SCOUT_BOT_TOKEN` | scout-daily, scout-feedback, scout-heartbeat |
| 6 | Discord bot token (Tess) | Gateway config | `tess.v2.discord.tess-bot-token` | `TESS_DISCORD_TESS_BOT_TOKEN` | morning-briefing (delivery) |
| 7 | Discord bot token (Mechanic) | Gateway config | `tess.v2.discord.mechanic-bot-token` | `TESS_DISCORD_MECHANIC_BOT_TOKEN` | awareness-check (delivery) |
| 8 | Perplexity API key | env var | `tess.v2.perplexity.api-key` | `TESS_PERPLEXITY_API_KEY` | overnight-research |
| 9 | Brave Search API key | Scout env | `tess.v2.brave-search.api-key` | `TESS_BRAVE_SEARCH_API_KEY` | scout-daily |
| 10 | TwitterAPI.io key | FIF env.sh | `tess.v2.twitterapi.api-key` | `TESS_TWITTERAPI_API_KEY` | fif-capture |
| 11 | X OAuth client secret | FIF env.sh | `tess.v2.x-oauth.client-secret` | `TESS_X_OAUTH_CLIENT_SECRET` | fif-capture |
| 12 | X OAuth refresh token | Keychain (already) | `tess.v2.x-oauth.refresh-token` | `TESS_X_OAUTH_REFRESH_TOKEN` | fif-capture |
| 13 | YouTube API key | FIF env.sh | `tess.v2.youtube.api-key` | `TESS_YOUTUBE_API_KEY` | fif-capture |
| 14 | Google OAuth refresh token | gws tooling | `tess.v2.gmail.oauth-refresh-token` | `TESS_GMAIL_OAUTH_REFRESH_TOKEN` | email-triage, morning-briefing, daily-attention |
| 15 | Google OAuth access token | gws tooling (dynamic) | `tess.v2.gmail.oauth-access-token` | `TESS_GMAIL_OAUTH_ACCESS_TOKEN` | email-triage, morning-briefing, daily-attention |
| 16 | Gemini API key | env var | `tess.v2.gemini.api-key` | `TESS_GEMINI_API_KEY` | peer-review, multi-model eval |
| 17 | DeepSeek API key | env var | `tess.v2.deepseek.api-key` | `TESS_DEEPSEEK_API_KEY` | peer-review, multi-model eval |
| 18 | XAI API key | env var | `tess.v2.xai.api-key` | `TESS_XAI_API_KEY` | peer-review, multi-model eval |
| 19 | Mistral API key | env var | `tess.v2.mistral.api-key` | `TESS_MISTRAL_API_KEY` | peer-review, multi-model eval |
| 20 | Lucid API key | env var | `tess.v2.lucid.api-key` | `TESS_LUCID_API_KEY` | diagram generation |
| 21 | Healthchecks API key | env var | `tess.v2.healthchecks.api-key` | `TESS_HEALTHCHECKS_API_KEY` | dashboard health panel |
| 22 | HC ping UUID | plist env | N/A (not a secret) | `HC_PING_UUID` | health-ping |
| 23 | Book Scout API key | Gateway plugin config | `tess.v2.book-scout.api-key` | `TESS_BOOK_SCOUT_API_KEY` | book-scout |

**Dropped credentials (no migration):**
- Gateway auth password -- drops with OpenClaw gateway replacement
- Bridge secret -- drops with bridge replacement (Tess v2 dispatch)
- `/Users/openclaw/.openclaw/credentials/` (3 items) -- investigate; likely OpenClaw internal

**Notes:**
- X OAuth refresh token (#12) is already in Keychain. Rename service field to `tess.v2.*` convention during migration.
- Google OAuth access token (#15) is ephemeral -- refreshed automatically (see §4). Stored in Keychain for retrieval between refresh cycles, not for persistence.
- Discord webhook URLs (5) are NOT in this table -- they are configuration values, not secrets.

---

## 3. Retrieval Mechanism

### 3.1 Retrieval Architecture

```
                    ┌───────────────────────┐
                    │   macOS Keychain       │
                    │   (tess login keychain)│
                    └───────────┬────────────┘
                                │ security find-generic-password
                                │
                    ┌───────────▼────────────┐
                    │   Runner               │
                    │   (Ralph loop owner)   │
                    │                        │
                    │   1. Read contract     │
                    │   2. Resolve cred      │
                    │      manifest          │
                    │   3. Retrieve from     │
                    │      Keychain          │
                    │   4. Build env var set │
                    │   5. Inject into       │
                    │      executor process  │
                    └───────────┬────────────┘
                                │ env vars in process
                                │
                    ┌───────────▼────────────┐
                    │   Executor             │
                    │   (Claude --print,     │
                    │    Hermes, Nemotron)   │
                    │                        │
                    │   Reads $TESS_*        │
                    │   env vars only.       │
                    │   No Keychain access.  │
                    └────────────────────────┘
```

### 3.2 Retrieval Rules

1. **Runner retrieves, executor consumes.** The runner is the only process that calls `security find-generic-password`. Executors receive credentials as environment variables. An executor never accesses Keychain directly.
2. **Retrieval at DISPATCHED, not QUEUED.** Credentials are fetched when the dispatch envelope is being built (ROUTING -> DISPATCHED transition), not at contract creation. This ensures credentials are fresh at execution time.
3. **Session-scoped.** Credentials exist only as env vars in the executor process. When the process terminates, the env vars cease to exist. No credential persistence between Ralph loop iterations.
4. **Fail-fast on missing credential.** If `security find-generic-password` returns non-zero (credential not found), the runner classifies this as a `tool`-class failure and transitions to ESCALATED. No execution with missing credentials.

### 3.3 Credential Manifest per Service

Each service definition (service-interfaces.md) includes a `credentials` field listing required Keychain service names. The runner resolves this manifest at dispatch time.

```yaml
# Example: service-interfaces.md entry
service: fif-capture
credentials:
  - keychain_service: "tess.v2.twitterapi.api-key"
    env_var: "TESS_TWITTERAPI_API_KEY"
    required: true
  - keychain_service: "tess.v2.x-oauth.refresh-token"
    env_var: "TESS_X_OAUTH_REFRESH_TOKEN"
    required: true
  - keychain_service: "tess.v2.youtube.api-key"
    env_var: "TESS_YOUTUBE_API_KEY"
    required: true
```

Runner resolves all `required: true` credentials before dispatch. If any are missing or expired, the contract does not enter DISPATCHED.

---

## 4. Env Var Injection Per Session

### 4.1 Injection Mechanism

The runner constructs the env var set from the contract's credential manifest and passes them to the executor process. Credentials are never written to files.

**For `claude --print` dispatch (Tier 3 Claude Code):**

```bash
# Runner builds env, invokes executor
TESS_ANTHROPIC_API_KEY="$(security find-generic-password -a tess-orchestrator -s tess.v2.anthropic.api-key -w)" \
TESS_GMAIL_OAUTH_ACCESS_TOKEN="$(security find-generic-password -a tess-orchestrator -s tess.v2.gmail.oauth-access-token -w)" \
claude --print --model claude-sonnet-4-6 --tools "Read,Write,Edit,Bash,Glob,Grep" \
  --permission-mode dontAsk \
  < dispatch-envelope.txt
```

Env vars are inline in the process invocation. They exist only in the subprocess environment.

**For Hermes dispatch (Tier 1 local / Kimi cloud):**

```bash
# Runner sets env before Hermes API call
export TESS_TWITTERAPI_API_KEY="$(security find-generic-password ...)"
export TESS_X_OAUTH_REFRESH_TOKEN="$(security find-generic-password ...)"
# Hermes receives via its config or API parameters
hermes-agent execute --contract "$CONTRACT_PATH" --env-pass "TESS_*"
```

The exact Hermes integration depends on Hermes Agent's env injection mechanism (validate during Phase 1 A1 confirmation). If Hermes cannot pass env vars to tool execution, the runner writes a temporary env wrapper that is deleted after execution.

### 4.2 Naming Convention

```
TESS_{SERVICE}_{CREDENTIAL_TYPE}
```

All uppercase, underscores for separators. The `TESS_` prefix avoids collision with system or application env vars.

| Pattern | Example |
|---------|---------|
| API key | `TESS_ANTHROPIC_API_KEY` |
| OAuth token | `TESS_GMAIL_OAUTH_ACCESS_TOKEN` |
| Bot token | `TESS_TELEGRAM_TESS_BOT_TOKEN` |
| Client secret | `TESS_X_OAUTH_CLIENT_SECRET` |

### 4.3 Cleanup

Env vars exist only in the executor process's environment. When the process terminates (successful completion, failure, or timeout), the env vars are gone. No explicit cleanup step is needed for process-scoped env vars.

The runner's own process retains retrieved values in memory for the duration of the dispatch. After the executor returns and the runner logs the result, the runner clears its in-memory credential cache for that contract.

---

## 5. Google OAuth Automated Refresh

### 5.1 The Problem

Google OAuth access tokens expire after 1 hour. Refresh tokens have longer validity but can be revoked. Email triage, morning briefing, and daily attention all depend on Google OAuth. The current email-triage service already has an auth failure flag set (migration-inventory.md), confirming this is an active pain point.

### 5.2 Refresh Architecture

A dedicated background service (`tess.v2.credential-refresh`) runs as a LaunchAgent, separate from the contract execution pipeline:

```
┌────────────────────────────────────┐
│  tess.v2.credential-refresh        │
│  (LaunchAgent, every 900s)         │
│                                    │
│  For each OAuth credential:        │
│    1. Read access token from       │
│       Keychain                     │
│    2. Decode JWT, check exp claim  │
│    3. If <600s remaining:          │
│       a. Read refresh token        │
│       b. Call token endpoint       │
│       c. Store new access token    │
│       d. Log refresh event         │
│    4. If refresh fails:            │
│       a. Log failure               │
│       b. Mark credential expired   │
│       c. Trigger circuit breaker   │
└────────────────────────────────────┘
```

### 5.3 Refresh Parameters

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Check interval | 900s (15 min) | Catches tokens with 1-hour lifetime well before expiry |
| Refresh threshold | 600s (10 min remaining) | Buffer for check interval jitter and transient network failures |
| Max refresh retries | 3 (30s backoff) | Distinguishes transient failure from revoked token |
| Refresh token validity check | Daily | Detects revoked refresh tokens before access token expiry |

### 5.4 Supported OAuth Credentials

| Credential | Token Endpoint | Refresh Token Location |
|-----------|---------------|----------------------|
| Google OAuth | `https://oauth2.googleapis.com/token` | `tess.v2.gmail.oauth-refresh-token` |
| X OAuth | `https://api.twitter.com/2/oauth2/token` | `tess.v2.x-oauth.refresh-token` |

### 5.5 Refresh Token Expiry

Refresh tokens themselves can expire or be revoked. When a refresh attempt returns `invalid_grant`:

1. Mark credential as `expired` in credential state file (`~/.tess/state/credential-status.yaml`)
2. Trigger credential cascade circuit breaker (state-machine-design.md §13)
3. Alert Danny: "Google OAuth refresh token expired. Manual reauthorization required. Services paused: email-triage, daily-attention, morning-briefing."
4. No automated recovery possible -- Danny must complete the browser-based OAuth flow

---

## 6. Mid-Contract Expiry Handling

### 6.1 Scenario

A credential expires while a contract is in EXECUTING state. The executor makes an API call, receives a 401/403 error, and reports failure.

### 6.2 Detection and Classification

The runner classifies credential-related API errors as `tool`-class failures (transient infrastructure, not reasoning errors):

| Error Signal | Detection | Classification |
|-------------|-----------|---------------|
| HTTP 401 Unauthorized | Status code in executor error output | `tool` (credential) |
| HTTP 403 Forbidden | Status code in executor error output | `tool` (credential) |
| `invalid_token` in API response | Pattern match on executor output | `tool` (credential) |
| `token_expired` in API response | Pattern match on executor output | `tool` (credential) |

### 6.3 Recovery Sequence

```
Executor returns with API auth error
    │
    ▼
Runner classifies: tool-class failure (credential)
    │
    ▼
Runner attempts credential refresh
    │
    ├── Refresh succeeds
    │   │
    │   ▼
    │   Re-inject fresh credential
    │   Retry iteration (does NOT decrement retry_budget —
    │   infrastructure retry, per spec §9.4)
    │
    └── Refresh fails
        │
        ▼
        Contract → DEAD_LETTER
        reason: credential_expired
        Trigger circuit breaker (§6.4)
```

**Key design decision:** Infrastructure-class credential failures do NOT consume the contract's retry budget. The executor's logic was correct; the infrastructure was broken. Decrementing the budget would penalize the executor for an infrastructure problem. This aligns with spec §9.4 retry failure classes where `tool` failures use "defer/requeue with backoff."

### 6.4 Circuit Breaker Integration

When credential refresh fails during mid-contract recovery, the credential cascade circuit breaker (state-machine-design.md §13) activates:

1. Contract transitions to DEAD_LETTER with `reason: credential_expired`
2. All action classes depending on the failed credential are marked as `deferred` in the scheduler
3. Danny receives ONE consolidated alert (not per-service alerts)
4. Deferred contracts resume when the credential is restored
5. If unresolved after 24 hours, escalate to `urgent_blocking` in daily attention

**Threshold:** If 3+ contracts fail on the same credential within 1 hour (even across different services), the circuit breaker fires preemptively -- the runner does not wait for the refresh service to confirm the credential is expired.

---

## 7. Audit Logging

### 7.1 What Is Logged

Every credential access event is logged with metadata only. Credential values are never logged.

| Event | Fields Logged |
|-------|---------------|
| **Retrieve** | timestamp, contract_id, service, credential_type (Keychain service name), result (success/not_found/error) |
| **Refresh** | timestamp, credential_type, result (success/failed), new_expiry (if success) |
| **Expire** | timestamp, credential_type, detected_by (refresh_service/executor_error), dependent_services |
| **Inject** | timestamp, contract_id, env_var_names (list of env var names, NOT values), executor_type |
| **Circuit breaker** | timestamp, credential_type, trigger (threshold/refresh_failure), deferred_services |

### 7.2 Log Format

```yaml
# ~/.tess/logs/credential-audit.log (YAML stream)
---
timestamp: "2026-04-01T08:15:00Z"
event: retrieve
contract_id: "TV2-034-C1"
service: fif-capture
credential_type: "tess.v2.twitterapi.api-key"
result: success
---
timestamp: "2026-04-01T08:15:01Z"
event: inject
contract_id: "TV2-034-C1"
env_vars: ["TESS_TWITTERAPI_API_KEY", "TESS_X_OAUTH_REFRESH_TOKEN", "TESS_YOUTUBE_API_KEY"]
executor_type: tier1-nemotron
---
timestamp: "2026-04-01T08:30:00Z"
event: refresh
credential_type: "tess.v2.gmail.oauth-access-token"
result: success
new_expiry: "2026-04-01T09:30:00Z"
```

### 7.3 Log Destination and Retention

- **Path:** `~/.tess/logs/credential-audit.log`
- **NOT in vault:** Credential audit logs live outside the vault (`~/.tess/`) to avoid the observability feedback loop (spec §2.4). vault-check does not scan `~/.tess/`.
- **Retention:** 30 days rolling. Log rotation via the runner: when the file exceeds 10MB or at the start of each day, rotate to `credential-audit.{date}.log` and delete files older than 30 days.
- **Access:** Readable by `tess` user only. No group or other permissions.

### 7.4 Health Digest Integration

The daily health digest (TV2-025 observability) includes a credential health summary:

```yaml
credential_health:
  total: 22
  valid: 20
  expiring_soon: 1      # <24h until expiry
  expired: 1
  details:
    - credential: "tess.v2.gmail.oauth-access-token"
      status: valid
      expires: "2026-04-01T09:30:00Z"
    - credential: "tess.v2.x-oauth.refresh-token"
      status: expiring_soon
      expires: "2026-04-02T00:00:00Z"
```

---

## 8. Never-in-Vault Enforcement

### 8.1 Enforcement Layers

Never-in-vault is enforced mechanically at three layers. No layer relies on behavioral instruction alone (per F11: behavioral triggers fail silently under task momentum).

| Layer | Mechanism | When | Scope |
|-------|-----------|------|-------|
| **Pre-promotion scan** | Runner scans staged artifacts before PROMOTION_PENDING | Every contract promotion | Staged artifacts only |
| **vault-check rule** | Pattern scan on all vault files | vault-check runs (daily + pre-commit) | Entire vault |
| **git pre-commit hook** | Pattern scan on staged git files | Every `git commit` | Changed files |

### 8.2 Detection Patterns

```yaml
credential_patterns:
  # API key formats
  - name: anthropic_key
    pattern: "sk-ant-[a-zA-Z0-9_-]{20,}"
    description: "Anthropic API key"
  - name: openai_key
    pattern: "sk-[a-zA-Z0-9]{20,}"
    description: "OpenAI API key"
  - name: aws_key
    pattern: "AKIA[A-Z0-9]{16}"
    description: "AWS access key ID"
  - name: slack_token
    pattern: "xox[bpras]-[a-zA-Z0-9-]+"
    description: "Slack token"

  # OAuth / bearer tokens
  - name: bearer_token
    pattern: "Bearer [a-zA-Z0-9._~+/=-]{20,}"
    description: "Bearer authorization token"
  - name: google_oauth
    pattern: "ya29\\.[a-zA-Z0-9._-]{20,}"
    description: "Google OAuth access token"

  # Bot tokens
  - name: telegram_bot
    pattern: "[0-9]{8,}:[a-zA-Z0-9_-]{35}"
    description: "Telegram bot token"
  - name: discord_bot
    pattern: "[MN][a-zA-Z0-9]{23,}\\.[a-zA-Z0-9_-]{6}\\.[a-zA-Z0-9_-]{27,}"
    description: "Discord bot token"

  # Generic high-entropy strings (supplementary, higher false positive rate)
  - name: base64_secret
    pattern: "['\"][A-Za-z0-9+/]{40,}={0,2}['\"]"
    description: "Possible base64-encoded secret in quotes"

  # Env var assignments with values (catch credential leaks in scripts)
  - name: env_assignment
    pattern: "(TESS_[A-Z_]+_KEY|TESS_[A-Z_]+_TOKEN|TESS_[A-Z_]+_SECRET)=['\"]?[^ '\"]{10,}"
    description: "Env var assignment with credential value"
```

### 8.3 Pre-Promotion Credential Scan

When a contract reaches STAGED and the runner prepares for QUALITY_EVAL:

1. Scan all files in `_staging/{contract_id}/` against the credential patterns
2. If any pattern matches:
   - Block promotion: contract transitions to DEAD_LETTER with `reason: credential_leak_detected`
   - Alert: Telegram notification to Danny with file path and pattern name (NOT the matched value)
   - Executor output is quarantined in staging (not promoted, not deleted)
3. If no patterns match: proceed to QUALITY_EVAL normally

### 8.4 Allowlist for Known Non-Secret Patterns

Some legitimate vault content matches credential patterns (e.g., documenting key formats in this design document, example YAML showing env var names). The allowlist prevents false positives:

```yaml
credential_scan_allowlist:
  # Files that document credential patterns (meta-documentation)
  - path: "Projects/tess-v2/design/credential-management.md"
    reason: "Design document contains credential pattern examples"
  - path: "_system/scripts/vault-check.sh"
    reason: "Contains credential detection regex patterns"

  # Patterns that match but are not secrets
  - pattern: "TESS_[A-Z_]+=\\$\\("
    reason: "Shell variable expansion (retrieving from Keychain, not literal value)"
  - pattern: "sk-ant-.*\\.\\.\\..*"
    reason: "Truncated/redacted key examples"
```

---

## 9. Privileged Operations and AD-009

### 9.1 Operation Classification

Credential operations are classified into two categories with different authorization requirements:

| Operation | Examples | Privileged? | Gate 3 Behavior |
|-----------|----------|-------------|-----------------|
| **Read (retrieve)** | Fetch API key for dispatch, read token for injection | No | Normal dispatch flow |
| **Refresh (automated)** | OAuth access token refresh, rotating token update | No | Background service, no contract |
| **Create** | Add new API key, provision new bot token | Yes | Gate 3 `credential_access` rule fires -> Tier 3 + `review_within_24h` |
| **Rotate** | Replace existing key with new value | Yes | Gate 3 `credential_access` rule fires -> Tier 3 + `review_within_24h` |
| **Delete** | Remove credential from Keychain | Yes | Gate 3 `destructive_operation` rule fires -> Tier 3 + `requires_human_approval` + PENDING_APPROVAL |
| **Scope change** | Modify credential ACL, change associated services | Yes | Gate 3 `credential_access` + `system_modification` rules fire -> Tier 3 + `requires_human_approval` |

### 9.2 Gate 3 Enforcement

From escalation-design.md §5, the `credential_access` rule:

```yaml
- name: credential_access
  condition:
    tools_required_contains: ["keychain_read", "env_inject", "oauth_refresh"]
    OR target_paths_match: ["*credential*", "*.env", "*secret*"]
  action: escalate_tier3
  requires_human_approval: false
  human_escalation_class: review_within_24h
```

This rule escalates to Tier 3 but does NOT require human approval for routine credential access. The escalation ensures a cloud model (Kimi) handles credential-touching operations rather than the local model.

**Privileged operations additionally match** `destructive_operation` or `system_modification` rules, which DO require human approval. This means:

- Reading a credential for dispatch: escalated to Tier 3, no approval needed (automated flow)
- Creating a new credential: escalated to Tier 3, Danny reviews within 24h
- Deleting a credential: escalated to Tier 3, execution blocked until Danny approves

### 9.3 Mechanical Enforcement

No executor can modify Keychain entries. The runner mediates all credential operations:

1. **Retrieval:** Runner calls `security find-generic-password`. Executor receives env vars.
2. **Refresh:** Background service (`tess.v2.credential-refresh`) calls `security add-generic-password` to update tokens. Not part of the contract execution pipeline.
3. **Creation/rotation/deletion:** Requires a specific contract with action_class that triggers Gate 3. The runner executes the Keychain command only after the contract passes all gates. The executor proposes the operation; the runner executes it.

This separation ensures that even if an executor's prompt is adversarially crafted or the model hallucinates a `security` command, the executor cannot execute it -- the executor has no Keychain access, and the runner only executes Keychain mutations through the privileged operation contract path.

---

## 10. Credential State Management

### 10.1 Credential Status File

The runner maintains a credential status file at `~/.tess/state/credential-status.yaml`:

```yaml
credentials:
  tess.v2.anthropic.api-key:
    status: valid          # valid | expiring_soon | expired | not_found
    last_retrieved: "2026-04-01T08:15:00Z"
    last_verified: "2026-04-01T08:00:00Z"
    expires: null          # null for non-expiring keys
    dependent_services: [fif-attention, overnight-research, morning-briefing, scout-daily, connections-brainstorm]

  tess.v2.gmail.oauth-access-token:
    status: valid
    last_retrieved: "2026-04-01T08:15:00Z"
    last_verified: "2026-04-01T08:30:00Z"
    expires: "2026-04-01T09:30:00Z"
    dependent_services: [email-triage, morning-briefing, daily-attention]

  tess.v2.gmail.oauth-refresh-token:
    status: valid
    last_retrieved: "2026-04-01T08:30:00Z"
    last_verified: "2026-04-01T08:00:00Z"
    expires: null          # refresh tokens have no fixed expiry
    dependent_services: [email-triage, morning-briefing, daily-attention]
```

### 10.2 Status Transitions

```
                   ┌─────────┐
              ┌────│  valid  │◄──── refresh succeeds
              │    └────┬────┘
              │         │ <600s remaining (OAuth)
              │         │ OR retrieval fails
              │         ▼
              │    ┌──────────────┐
              │    │expiring_soon │
              │    └──────┬───────┘
              │           │ refresh fails
              │           │ OR expiry reached
              │           ▼
              │    ┌──────────┐
              └────│ expired  │───── circuit breaker fires
                   └──────────┘
                        │
                        │ Danny re-provisions
                        ▼
                   ┌──────────┐
                   │  valid   │
                   └──────────┘
```

### 10.3 Proactive Expiry Monitoring

For non-OAuth credentials (API keys, bot tokens) that have no programmatic expiry:

- **Daily verification:** The refresh service attempts a lightweight API call (e.g., account info endpoint) for each credential to verify it is still valid. Does not consume quota-counted API calls where possible.
- **Provider notification:** Some providers (Anthropic, OpenAI) send email before key expiry. Danny forwards these to Tess via the email-triage pipeline, which creates a credential rotation contract.
- **Manual tracking:** For credentials without programmatic expiry detection, Danny records expected rotation dates in `~/.tess/state/credential-status.yaml` as `manual_expiry` fields.

---

## 11. Cross-Reference Index

| Section | Related Design Doc | Section |
|---------|-------------------|---------|
| Circuit breaker | state-machine-design.md | §13 |
| Gate 3 credential rule | escalation-design.md | §5 |
| Retry failure classes | specification.md | §9.4 |
| Staging/promotion | staging-promotion-design.md | §3 |
| Service credential manifests | service-interfaces.md | Cross-Cutting Concerns |
| Env injection layers | ralph-loop-spec.md | §1.2 |
| Observability integration | TV2-025 (pending) | Credential health in digest |
| Credential expiry cascade | specification.md | §2.4 |
| Contract `side_effects` | contract-schema.md | §1.1 |

---

## 12. Open Questions

1. **Hermes env var passthrough.** The exact mechanism for passing env vars through Hermes Agent to tool execution is unvalidated (Phase 1 A1). If Hermes sandboxes env vars, the runner may need a wrapper script or Hermes config modification.
2. **Keychain unlock on boot.** After a reboot, the tess user's login keychain may be locked. The runner must handle this gracefully: detect locked keychain, alert Danny, defer credential-dependent contracts. Not an issue during normal operation (keychain unlocked at login).
3. **Credential rotation automation.** This design handles OAuth refresh but not API key rotation. Some providers support programmatic key rotation (Anthropic via API). Future work: credential rotation contracts that cycle keys without Danny's intervention.
4. **Multi-credential atomic operations.** Some services need multiple credentials (FIF capture needs 3). If one retrieval fails, should the runner fail the entire dispatch or inject partial credentials? Current design: fail-fast on any missing required credential. This may need relaxation for services with optional credentials.
5. **`/Users/openclaw/.openclaw/credentials/` contents.** Three items in the OpenClaw credentials directory are unexamined (permission denied). Investigate before migration to determine if any are needed for Tess v2 services.
