---
type: design-doc
domain: software
status: draft
created: 2026-02-19
updated: 2026-02-19
project: crumb-tess-bridge
task: CTB-003
tags:
  - openclaw
  - security
  - integration
---

# Crumb–Tess Bridge — JSON Schema Specification

## Overview

This document defines the formal request/response JSON schemas for the Crumb–Tess bridge
protocol. It is the single authoritative source for the operation allowlist, message
structure, error codes, and schema versioning strategy. Both Tess (Node.js) and Crumb
(Python/Shell) implementations import their validation rules from this specification.

**Normative references:**
- `specification.md` §Protocol Design — canonical JSON rules, confirmation echo flow
- `_openclaw/spec/canonical-json-test-vectors.json` — cross-implementation hash validation
- CTB-002 research — Telegram formatting constraints and character budget

## 1. Schema Versioning

### Strategy

The bridge uses **semantic major.minor versioning** on the `schema_version` field.

| Component | Meaning | Example |
|-----------|---------|---------|
| Major | Breaking change — new required fields, removed fields, changed semantics | `1.0` → `2.0` |
| Minor | Additive change — new optional fields, new operations, new error codes | `1.0` → `1.1` |

### Consumer Rules

1. `schema_version` is **required** on every message (request and response).
2. Consumers **MUST reject** messages with an unknown major version (e.g., a `1.x` consumer
   rejects `2.0`).
3. Consumers **MUST accept** messages with a known major version and unknown minor version
   (e.g., a `1.0` consumer accepts `1.3` — unknown fields are ignored).
4. The current schema version is **`1.0`**.

### Version Lifecycle

- Phase 1 ships as `1.0`.
- Phase 2 operation additions (start-task, invoke-skill, quick-fix) are `1.1` — additive,
  no breaking change.
- Breaking changes (restructured params, renamed fields) require `2.0` and a migration path.

## 2. Operation Allowlist

The allowlist is the **single authoritative enum** for permitted bridge operations. Both
Tess and Crumb validate incoming operations against this list. Any operation not in the
active allowlist is rejected with error code `UNKNOWN_OPERATION`.

### Phase 1 Operations

| Operation | Description | Risk | Confirmation Required | Params |
|-----------|-------------|------|-----------------------|--------|
| `approve-gate` | Approve a phase transition gate | Medium | Yes | `project`, `gate`, `decision` |
| `reject-gate` | Reject/defer a phase transition | Low | Yes | `project`, `gate`, `decision`, `reason`? |
| `query-status` | Read project state and current phase | Low | No | `project`, `scope`? |
| `query-vault` | Read a specific vault file or summary | Low | No | `path`, `scope`? |
| `list-projects` | List active projects and their phases | Low | No | `filter`? |

### Phase 2 Operations (additive — schema version 1.1)

| Operation | Description | Risk | Confirmation Required | Params |
|-----------|-------------|------|-----------------------|--------|
| `start-task` | Begin a specific task from the task list | High | Yes | `project`, `task_id`, `context`? |
| `invoke-skill` | Run a named skill with arguments | High | Yes | `skill`, `args`? |
| `quick-fix` | Execute a scoped, low-risk change | Medium | Yes | `project`, `description`, `files`? |

**`?` = optional parameter**

### Allowlist Enforcement

```
Tess:  validate operation ∈ allowlist BEFORE echoing confirmation
Crumb: validate operation ∈ allowlist BEFORE executing
```

Both sides reject independently. Tess rejection prevents the request from reaching the
inbox. Crumb rejection is the backstop for direct inbox writes (BT7 scenario).

## 3. Bridge Request Schema

### File Location

`_openclaw/inbox/{id}.json` — where `{id}` is the UUIDv7 message ID.

### Schema Definition

```json
{
  "schema_version": "string (required) — semver, e.g. '1.0'",
  "id": "string (required) — UUIDv7, globally unique, time-ordered (v7 over v4: enables chronological log compaction without parsing timestamps)",
  "timestamp": "string (required) — ISO 8601 UTC, e.g. '2026-02-19T15:30:00Z'",
  "operation": "string (required) — enum from operation allowlist",
  "params": "object (required) — operation-specific parameters (see §3.1)",
  "payload_hash": "string (required) — sha256(canonical_json(operation+params))[:12]",
  "confirmed": "boolean (required) — true for write ops (user confirmed), false for read-only (§8)",
  "confirmation": "object | null (required) — non-null when confirmed=true, null for read-only ops (§8)",
  "confirmation (when non-null)": {
    "echo_message_id": "integer (required) — Telegram message ID of echo",
    "confirm_message_id": "integer (required) — Telegram message ID of CONFIRM reply",
    "confirm_code": "string (required) — payload_hash echoed back by user"
  },
  "original_message": "string (required) — raw user text or STT transcript",
  "source": {
    "platform": "string (required) — 'telegram'",
    "sender_id": "integer (required) — Telegram user ID (numeric)",
    "message_id": "integer (required) — Telegram message ID (numeric)"
  }
}
```

### Validation Rules

1. `schema_version` must be a recognized major version (see §1).
2. `id` must be valid UUIDv7 format (RFC 9562). Crumb checks against
   `_openclaw/.processed-ids` and rejects duplicates.
3. `operation` must be in the active allowlist (see §2).
4. `payload_hash` must equal `sha256(canonical_json({operation, params}))[:12]`.
   Crumb recomputes and rejects on mismatch.
5. `confirmation.confirm_code` must equal `payload_hash`.
6. `confirmed` must be `true` for write operations. Read-only operations
   (`query-status`, `query-vault`, `list-projects`) may have `confirmed: false`
   with `confirmation` set to `null`.
7. All string values in `params` must be ASCII-only (U+0000–U+007F). Non-ASCII
   codepoints are rejected with `INVALID_SCHEMA` before hashing.
   **Design decision:** This constraint applies to free-text fields (`reason`,
   `context`, `description`) as well as structured fields. Rationale: these fields
   are inside `params` and therefore included in the canonical JSON hash — allowing
   UTF-8 would require Unicode normalization (NFC) before hashing to prevent
   invisible codepoint differences from causing hash mismatches. ASCII-only
   eliminates this class of bug entirely. Acceptable for Phase 1 where the only
   free-text field is `reason` (optional, short English text). Revisit for Phase 2
   if STT transcription produces non-ASCII content in `context`/`description`.
8. `source.sender_id` must match the hardcoded allowed Telegram user ID.

### 3.1 Operation-Specific Params

#### `approve-gate`

```json
{
  "project": "string (required) — project name (kebab-case)",
  "gate": "string (required) — format 'PHASE->PHASE', e.g. 'SPECIFY->PLAN'",
  "decision": "string (required) — must be 'approved'"
}
```

#### `reject-gate`

```json
{
  "project": "string (required) — project name (kebab-case)",
  "gate": "string (required) — format 'PHASE->PHASE'",
  "decision": "string (required) — must be 'rejected'",
  "reason": "string (optional) — why rejected/deferred"
}
```

#### `query-status`

```json
{
  "project": "string (required) — project name",
  "scope": "string (optional) — 'current-phase' (default) | 'full'"
}
```

#### `query-vault`

```json
{
  "path": "string (required) — vault-relative file path",
  "scope": "string (optional) — 'summary' (default) | 'full'"
}
```

**Security constraint:** `path` must not contain `..` segments, must not be absolute,
and must resolve to a file within the vault root after symlink resolution (`realpath`).
A symlink inside the vault pointing outside it must be rejected. Crumb validates this
before reading.

#### `list-projects`

```json
{
  "filter": "string (optional) — 'active' (default) | 'all'"
}
```

#### `start-task` (Phase 2)

```json
{
  "project": "string (required) — project name",
  "task_id": "string (required) — task identifier, e.g. 'CTB-003'",
  "context": "string (optional) — additional context for task execution"
}
```

#### `invoke-skill` (Phase 2)

```json
{
  "skill": "string (required) — skill name from .claude/skills/",
  "args": "string (optional) — skill arguments"
}
```

#### `quick-fix` (Phase 2)

```json
{
  "project": "string (required) — project name",
  "description": "string (required) — what to fix",
  "files": "array of strings (optional) — specific files to modify"
}
```

## 4. Bridge Response Schema

### File Location

`_openclaw/outbox/{request_id}-response.json` — where `{request_id}` is the UUIDv7
from the originating request.

### 4.1 Success Response

```json
{
  "schema_version": "string (required) — matches request schema version",
  "id": "string (required) — UUIDv7 for this response",
  "request_id": "string (required) — UUIDv7 of the originating request",
  "timestamp": "string (required) — ISO 8601 UTC",
  "status": "string (required) — 'completed'",
  "summary": "string (required) — human-readable summary for Telegram relay",
  "details": "object (required) — operation-specific result data (see §4.3)",
  "governance_check": {
    "governance_hash": "string (required) — sha256(CLAUDE.md)[:12]",
    "governance_canary": "string (required) — last 64 bytes of CLAUDE.md",
    "claude_md_loaded": "boolean (required)",
    "project_state_read": "boolean (required)",
    "risk_tier": "string (required) — 'low' | 'medium' | 'high'",
    "approval_method": "string (required) — 'bridge-confirm'"
  },
  "transcript_hash": "string (required) — sha256(transcript_content)[:12]",
  "transcript_path": "string (required) — relative path to transcript file"
}
```

### 4.2 Error Response

```json
{
  "schema_version": "string (required)",
  "id": "string (required) — UUIDv7 for this response",
  "request_id": "string (required) — UUIDv7 of the originating request",
  "timestamp": "string (required) — ISO 8601 UTC",
  "status": "string (required) — 'error'",
  "error": {
    "code": "string (required) — error code from §4.4",
    "message": "string (required) — human-readable explanation",
    "retryable": "boolean (required) — whether resending may succeed"
  },
  "governance_check": "object | null — present if session started, null if pre-session failure",
  "transcript_hash": "string | null — present if transcript was written",
  "transcript_path": "string | null — present if transcript was written"
}
```

### 4.3 Operation-Specific Response Details

#### `approve-gate` / `reject-gate`

```json
{
  "files_modified": ["array of strings — vault-relative paths"],
  "next_action": "string — what happens next in the workflow"
}
```

#### `query-status`

```json
{
  "project": "string",
  "phase": "string — current workflow phase",
  "active_task": "string | null",
  "next_action": "string",
  "last_committed": "string | null — last git commit message"
}
```

#### `query-vault`

```json
{
  "path": "string — requested vault path",
  "exists": "boolean",
  "content": "string | null — file content (or summary if scope=summary)",
  "truncated": "boolean — true if content was truncated for Telegram"
}
```

#### `list-projects`

```json
{
  "projects": [
    {
      "name": "string",
      "phase": "string",
      "domain": "string",
      "active_task": "string | null"
    }
  ]
}
```

### 4.4 Error Codes

| Code | Meaning | Retryable | When |
|------|---------|-----------|------|
| `INVALID_SCHEMA` | Request doesn't match schema structure | No | Malformed JSON, missing required fields, wrong types |
| `UNKNOWN_OPERATION` | Operation not in allowlist | No | Operation string not in §2 enum |
| `HASH_MISMATCH` | `payload_hash` doesn't match recomputed hash | No | Canonical JSON mismatch between Tess and Crumb |
| `DUPLICATE_REQUEST` | Request ID already in `.processed-ids` | No | Replay or duplicate delivery |
| `INVALID_SENDER` | `source.sender_id` doesn't match allowed ID | No | Unauthorized Telegram sender |
| `GOVERNANCE_FAILED` | CLAUDE.md governance check failed | No | Hash mismatch, canary mismatch, or CLAUDE.md not loaded |
| `OPERATION_FAILED` | Operation executed but encountered an error | Maybe | Depends on error — file not found, project not found, etc. |
| `PATH_TRAVERSAL` | `query-vault` path contains traversal attempt | No | `..` segments or absolute path in `path` param |
| `INTERNAL_ERROR` | Unexpected error during processing | Yes | Transient failures, timeouts |

### 4.5 Rejection Response for Unknown Operations

When Tess or Crumb receives an unknown operation, the error response includes:

```json
{
  "status": "error",
  "error": {
    "code": "UNKNOWN_OPERATION",
    "message": "Operation 'delete-project' is not in the bridge allowlist. Allowed operations: approve-gate, reject-gate, query-status, query-vault, list-projects",
    "retryable": false
  },
  "governance_check": null,
  "transcript_hash": null,
  "transcript_path": null
}
```

Unknown operations are rejected **before** the governance boundary, so
`governance_check`, `transcript_hash`, and `transcript_path` are always `null`.

The error message **enumerates the active allowlist** to aid the user in correcting
their request.

## 5. Canonical JSON Specification

Reproduced from `specification.md` §Protocol Design for completeness. This section
is normative.

### Canonical Input

An object containing exactly two keys: `"operation"` and `"params"`. All other request
fields are excluded from the hash.

### Serialization Rules

1. Keys sorted lexicographically at all nesting levels (recursive)
2. No insignificant whitespace (no spaces after `:` or `,`, no newlines)
3. ASCII-only string values — reject any string containing non-ASCII codepoints (U+0080+)
   with a validation error before hashing
4. Strings use minimal escaping per RFC 8259 §7 (only `\"`, `\\`, and control characters
   `\uXXXX`)
5. No trailing commas, no comments, no duplicate keys
6. Integers rendered without leading zeros or decimal points; no floating-point values
7. Encoding: UTF-8 (trivially ASCII given rule 3)

### Hash Computation

`sha256(canonical_bytes)[:12]` — first 12 hex characters (48 bits) of the SHA-256 digest.

### Reference Implementations

**Python:**
```python
import json, hashlib

def canonical_json(operation, params):
    obj = {"operation": operation, "params": params}
    return json.dumps(obj, sort_keys=True, separators=(',', ':'))

def payload_hash(operation, params):
    canonical = canonical_json(operation, params)
    return hashlib.sha256(canonical.encode('utf-8')).hexdigest()[:12]
```

**Node.js:**
```javascript
const crypto = require('crypto');

function canonicalJson(operation, params) {
  const obj = { operation, params };
  return JSON.stringify(obj, (key, value) => {
    if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
      return Object.keys(value).sort().reduce((acc, k) => {
        acc[k] = value[k];
        return acc;
      }, {});
    }
    return value;
  });
}

function payloadHash(operation, params) {
  const canonical = canonicalJson(operation, params);
  return crypto.createHash('sha256').update(canonical).digest('hex').slice(0, 12);
}
```

### Test Vectors

See `_openclaw/spec/canonical-json-test-vectors.json` for 4 cross-implementation test
vectors. Both Python and Node.js implementations have been verified to produce identical
output for all vectors.

| Vector | Operation | payload_hash |
|--------|-----------|-------------|
| V1 | `approve-gate` (baseline) | `3c690c41fcf6` |
| V2 | `query-status` (read-only) | `7edf0ef624c5` |
| V3 | `list-projects` (minimal params) | `920b64bee54d` |
| V4 | `reject-gate` (free-text reason) | `ea57afbbe5fa` |

## 6. Telegram Echo Budget Validation

From CTB-002 research: the Telegram 4096-char limit applies to rendered text after
entity parsing. HTML tags are "free" — only visible characters count.

### Budget Breakdown

| Component | Characters |
|-----------|-----------|
| Fixed template chrome | ~144 |
| Variable content (typical) | ~100 |
| **Available for payload** | **~3850** |
| **Safe design target** | **3500** |

### Phase 1 Operations — Budget Check

| Operation | Typical Payload Size | Budget % | Status |
|-----------|---------------------|----------|--------|
| `approve-gate` | 120–180 chars | 3–5% | PASS |
| `reject-gate` | 150–250 chars | 4–7% | PASS |
| `query-status` | 80–120 chars | 2–3% | PASS |
| `query-vault` | 80–120 chars | 2–3% | PASS |
| `list-projects` | 50–80 chars | 1–2% | PASS |

All Phase 1 operations are well within the 3500-char safe target. The largest
(`reject-gate` with a long reason) uses <10% of the budget.

### Response Relay Budget

Responses relayed to Telegram must also fit within 4096 chars. The relay template
(from CTB-002) uses ~200 chars of chrome. Response summaries should target 1000 chars
maximum, leaving headroom for formatting.

For `query-vault` with `scope: full`, content may exceed the limit. The response
includes `truncated: true` when content is cut, with a note that full content is
in the outbox file.

## 7. File Naming Conventions

| File Type | Pattern | Example |
|-----------|---------|---------|
| Request | `_openclaw/inbox/{id}.json` | `inbox/01953e8a-7b2c-7d4f-8a1e-3f5b6c8d9e0a.json` |
| Response | `_openclaw/outbox/{request_id}-response.json` | `outbox/01953e8a-7b2c-7d4f-8a1e-3f5b6c8d9e0a-response.json` |
| Transcript | `_openclaw/transcripts/{request_id}-transcript.md` | `transcripts/01953e8a-7b2c-7d4f-8a1e-3f5b6c8d9e0a-transcript.md` |
| Processed | `_openclaw/inbox/.processed/{id}.json` | `inbox/.processed/01953e8a-7b2c-7d4f-8a1e-3f5b6c8d9e0a.json` |
| Processed IDs | `_openclaw/.processed-ids` | Append-only log of processed UUIDv7s (see rotation rule below) |

### Atomic Write Protocol

All file creation uses atomic rename to prevent partial-write corruption:

1. Write to `{target_dir}/.tmp-{id}.json`
2. `fsync` the file descriptor
3. Rename `.tmp-{id}.json` → `{id}.json`

This ensures readers never see a partially-written file.

### `.processed-ids` Rotation

The `.processed-ids` file is append-only and grows unbounded. Since UUIDv7 IDs encode
timestamps, entries can be safely compacted by age. **Rotation rule:** retain only entries
from the last 30 days. The bridge runner (CTB-011) compacts on startup — entries whose
UUIDv7 timestamp is older than 30 days are removed. Duplicate detection only matters
within a realistic replay window; 30 days provides ample margin.

## 8. Read-Only Operations — Confirmation Exemption

Operations classified as **read-only** (`query-status`, `query-vault`, `list-projects`)
do not require user confirmation via the echo flow. Tess may process these directly:

1. Parse the user's message into a request.
2. Validate operation is in the read-only subset.
3. Compute `payload_hash` over canonical JSON (same as write ops).
4. Write directly to inbox with `confirmed: false` and `confirmation: null`.
5. Crumb verifies `payload_hash` (integrity check — detects tampering in transit)
   but skips `confirm_code` binding (no confirmation to verify).

**Rationale:** Read-only operations cannot modify vault state. The blast radius of a
misparsed read-only request is a wrong query result, not vault corruption. Requiring
confirmation for "what's the status?" creates unnecessary friction.

**Security note:** If Tess is compromised (BT7), an attacker can issue unlimited read
queries against the vault. This is accepted — the `openclaw` user already has read
access to the vault via the `crumbvault` group. Bridge read queries add no new read
capability beyond what a compromised Tess already has.

## 9. Complete Request Example

```json
{
  "schema_version": "1.0",
  "id": "01953e8a-7b2c-7d4f-8a1e-3f5b6c8d9e0a",
  "timestamp": "2026-02-19T15:30:00Z",
  "operation": "approve-gate",
  "params": {
    "project": "crumb-tess-bridge",
    "gate": "SPECIFY->PLAN",
    "decision": "approved"
  },
  "payload_hash": "3c690c41fcf6",
  "confirmed": true,
  "confirmation": {
    "echo_message_id": 12345,
    "confirm_message_id": 12347,
    "confirm_code": "3c690c41fcf6"
  },
  "original_message": "approve the specify gate for crumb-tess-bridge",
  "source": {
    "platform": "telegram",
    "sender_id": 123456789,
    "message_id": 67890
  }
}
```

## 10. Complete Response Examples

### Success

```json
{
  "schema_version": "1.0",
  "id": "01953e8a-9d1e-7f3a-bc2d-4e6f7a8b9c0d",
  "request_id": "01953e8a-7b2c-7d4f-8a1e-3f5b6c8d9e0a",
  "timestamp": "2026-02-19T15:30:45Z",
  "status": "completed",
  "summary": "Phase gate SPECIFY -> PLAN approved for crumb-tess-bridge. Run-log updated. Project state advanced to PLAN.",
  "details": {
    "files_modified": ["project-state.yaml", "progress/run-log.md"],
    "next_action": "Load action-architect skill for PLAN phase"
  },
  "governance_check": {
    "governance_hash": "a1b2c3d4e5f6",
    "governance_canary": "<last 64 bytes of CLAUDE.md>",
    "claude_md_loaded": true,
    "project_state_read": true,
    "risk_tier": "medium",
    "approval_method": "bridge-confirm"
  },
  "transcript_hash": "f6e5d4c3b2a1",
  "transcript_path": "_openclaw/transcripts/01953e8a-7b2c-7d4f-8a1e-3f5b6c8d9e0a-transcript.md"
}
```

### Error — Unknown Operation

```json
{
  "schema_version": "1.0",
  "id": "01953e8b-1a2b-7c3d-4e5f-6a7b8c9d0e1f",
  "request_id": "01953e8a-ffff-7d4f-8a1e-3f5b6c8d9e0a",
  "timestamp": "2026-02-19T15:31:00Z",
  "status": "error",
  "error": {
    "code": "UNKNOWN_OPERATION",
    "message": "Operation 'delete-project' is not in the bridge allowlist. Allowed operations: approve-gate, reject-gate, query-status, query-vault, list-projects",
    "retryable": false
  },
  "governance_check": null,
  "transcript_hash": null,
  "transcript_path": null
}
```

### Error — Hash Mismatch (Pre-Session)

```json
{
  "schema_version": "1.0",
  "id": "01953e8b-2b3c-7d4e-5f6a-7b8c9d0e1f2a",
  "request_id": "01953e8a-cccc-7d4f-8a1e-3f5b6c8d9e0a",
  "timestamp": "2026-02-19T15:31:15Z",
  "status": "error",
  "error": {
    "code": "HASH_MISMATCH",
    "message": "Payload hash '3c690c41fcf6' does not match recomputed hash 'a7b8c9d0e1f2'. Request integrity compromised.",
    "retryable": false
  },
  "governance_check": null,
  "transcript_hash": null,
  "transcript_path": null
}
```
