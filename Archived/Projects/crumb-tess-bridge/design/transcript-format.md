---
type: design-doc
domain: software
status: draft
created: 2026-02-21
updated: 2026-02-21
project: crumb-tess-bridge
task: CTB-006
tags:
  - openclaw
  - integration
---

# Bridge Transcript Format

## Overview

Every bridge request that reaches Crumb execution (past schema validation and hash
verification) produces a transcript file in `_openclaw/transcripts/`. Transcripts are
the audit trail for bridge operations — they record what was requested, what Crumb did,
and what was returned.

**Normative references:**
- `bridge-schema.md` §7 — file naming conventions, atomic write protocol
- `bridge-schema.md` §4.1–4.2 — response schemas (transcript_hash, transcript_path)
- `specification.md` §Protocol Design — confirmation echo flow

## Directory Structure

```
_openclaw/
├── inbox/                  # Incoming requests from Tess
│   └── .processed/         # Completed requests (moved here after processing)
├── outbox/                 # Responses from Crumb to Tess
├── transcripts/            # Audit trail (this document)
├── .processed-ids          # Append-only duplicate detection log
└── spec/                   # Schema artifacts (git-tracked)
```

**Ownership:** All directories share the `crumbvault` group with `775` permissions —
group membership is the access control boundary, not file ownership. `openclaw` owns
`inbox/` and `outbox/` (created during colocation setup). `tess` owns `transcripts/`
and `inbox/.processed/` (created by Crumb). Both users have full read/write via group.

## File Naming

Per `bridge-schema.md` §7:

```
_openclaw/transcripts/{request_id}-transcript.md
```

Example: `transcripts/01953e8a-7b2c-7d4f-8a1e-3f5b6c8d9e0a-transcript.md`

The `request_id` is the UUIDv7 from the originating request, linking each transcript
to exactly one request/response pair.

## Transcript Structure

```markdown
# Bridge Transcript

## Request

- **ID:** {request_id}
- **Timestamp:** {request.timestamp}
- **Operation:** {request.operation}
- **Schema Version:** {request.schema_version}
- **Confirmed:** {request.confirmed}

### Parameters

{request.params as YAML block — human-readable, not canonical JSON}

### Payload Hash

`{request.payload_hash}` — verified ✓ | mismatch ✗

## Execution

- **Started:** {ISO 8601 UTC}
- **Completed:** {ISO 8601 UTC}
- **Duration:** {seconds}s
- **Status:** success | error
- **Risk Tier:** {low | medium | high}

### Actions Taken

{Numbered list of what Crumb did — files read, files written, commands run.
Brief, factual, auditable. Not a full Claude session transcript — just the
observable actions and their outcomes.}

### Governance Check

- **CLAUDE.md loaded:** {yes | no}
- **Governance hash:** `{sha256(CLAUDE.md)[:12]}`
- **Governance canary:** `{last 64 bytes of CLAUDE.md}`
- **Project state read:** {yes | no}

## Response

- **Response ID:** {response.id}
- **Status:** {success | error}
- **Error code:** {if error — code from bridge-schema.md §4.4}

### Result

{Operation-specific result summary. For success: what changed. For error:
what went wrong and whether it's retryable.}

## Integrity

- **Transcript hash:** `{sha256(transcript_content)[:12]}`
```

## Field Notes

**Actions Taken** is the critical audit section. It records observable side effects,
not internal reasoning. Examples:

- `1. Read Projects/crumb-tess-bridge/project-state.yaml`
- `2. Read Projects/crumb-tess-bridge/progress/run-log.md (lines 1-50)`
- `3. Wrote _openclaw/outbox/01953e8a-...-response.json (atomic rename)`

**Payload Hash verification** happens before execution. If it fails, the transcript
records the mismatch and execution does not proceed — the error response references
the transcript for the hash comparison details.

**Governance Check** fields are copied verbatim into the response JSON
(`governance_check` object in bridge-schema.md §4.1). The transcript preserves them
for audit even after the response file is consumed and deleted by Tess.

## Transcript Hash Computation

The `transcript_hash` in the response JSON is computed as:

```
sha256(transcript_file_contents)[:12]
```

This is computed **after** the transcript is fully written (including the Integrity
section placeholder), then the hash is:
1. Written into the transcript's own Integrity section
2. Included in the response JSON `transcript_hash` field

Both values must match. This enables tamper detection: if the transcript file is
modified after the response is sent, the hash in the response won't match a
re-computation of the file contents.

**Threat model scope:** The 12-hex-char truncation (48 bits) is sufficient for tamper
*detection* — inconsistency between transcript and response is evidence of modification.
It is **not** a tamper *prevention* primitive. An attacker who controls both the
transcript file and the response JSON could forge a consistent pair. CTB-005 and CTB-012
must not treat a matching transcript hash as proof of non-tampering in any automated
decision path.

**Bootstrap note:** The transcript hash covers the file contents *without* the hash
line itself. Compute the hash over the file with the placeholder
`- **Transcript hash:** \`{pending}\`` , then replace `{pending}` with the actual
hash. The hash does not cover itself.

## Retention

Transcripts are retained indefinitely in `_openclaw/transcripts/`. They are gitignored
(under the `_openclaw/*` rule) but persist on disk as local audit history.

Future consideration: archive transcripts older than 90 days to a compressed bundle
if disk usage becomes a concern. Not needed for Phase 1 volume.

## Error Transcripts

Failed requests (schema validation failure, hash mismatch, governance failure,
operation error) still produce transcripts. The transcript records:
- How far execution got before the error
- The specific failure point and error code
- Whether any side effects occurred before the failure

This ensures the audit trail is complete even for failures — especially important
for governance failures (BT3) where you want to know what a potentially compromised
session attempted.
