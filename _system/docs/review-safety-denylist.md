---
type: config
domain: software
status: active
created: 2026-02-24
updated: 2026-02-24
---

# Review Safety Denylist

Shared secret detection patterns for the code-review and peer-review dispatch agents.
This file is the single source of truth — edits here apply to both review skills.

Both dispatch agents (`code-review-dispatch`, `peer-review-dispatch`) and the Tier 1
inline safety gate (SKILL Step 4A) load this file before scanning artifacts/diffs.
If this file is missing, agents fall back to their built-in pattern copies.

## Hard Denylist (halt if matched)

Matches against these patterns halt dispatch immediately. The operator must clean the
artifact or explicitly OVERRIDE (for confirmed false positives).

### Cloud Provider Keys
- AWS access keys: `\bAKIA[A-Z0-9]{16}\b`
- AWS ARNs with account IDs: `arn:aws:[a-z0-9-]+:\d{12}:`

### Private Keys
- PEM private keys: `-----BEGIN .* PRIVATE KEY-----`

### API Keys
- OpenAI / Anthropic sk- keys: `\bsk-[a-zA-Z0-9]{20,}\b`
- OpenAI project keys: `\bsk-proj-[a-zA-Z0-9]+`
- Anthropic keys: `\bsk-ant-[a-zA-Z0-9]+`

### Platform Tokens
- GitHub PATs: `\bghp_[a-zA-Z0-9]{36}\b`
- GitHub fine-grained PATs: `\bgithub_pat_[a-zA-Z0-9_]+`
- Slack bot tokens: `\bxoxb-[a-zA-Z0-9-]+`
- Stripe live keys: `\b[sr]k_live_[a-zA-Z0-9]+`

### Structured Secrets
- JWTs: `\beyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}`
- Generic secrets: `(password|secret|token)\s*[:=]\s*["']?[^\s"'#]{8,}`
- Connection strings: `(mongodb|postgres|mysql)://[^/\s]*:[^/\s]*@`

### Code-Specific Patterns
- `.env` values in diffs: `^\+.*(?:API_KEY|SECRET|TOKEN|PASSWORD)\s*=\s*[^\s]{8,}`
- Hardcoded credentials: `(?:password|secret|api_key)\s*[:=]\s*["'][^"']{8,}["']`
- Bearer tokens in fixtures: `Bearer\s+[A-Za-z0-9._-]{20,}`
- Firebase config keys: `apiKey\s*:\s*["'][A-Za-z0-9_-]{20,}["']`

## Context-Sensitivity Downgrade

If a hard denylist match occurs, check whether the matched value contains placeholder
markers. If so, **downgrade to soft warning** and proceed with dispatch.

**Placeholder heuristics (any match downgrades):**
- Contains: `your-`, `YOUR_`, `xxx`, `***`, `REPLACE`, `REDACTED`, `example`, `test-`, `dummy`, `fake`, `placeholder`, `changeme`, `TODO`
- Is a regex pattern (contains `\b`, `\s`, unescaped `{`, `[` quantifiers)
- Appears in a comment line (`//`, `#`, `*`) alongside words: `example`, `sample`, `template`

## Soft Heuristics (warn, proceed)

These patterns produce warnings in the return summary but do not halt dispatch:

- IP addresses (RFC 1918 ranges: `10.*`, `172.16-31.*`, `192.168.*`)
- localhost URLs with ports
- File paths containing `/home/` or `/Users/` (sanitize by replacing with `~/...` before dispatch)
- Long hex strings (40+ chars): `\b[0-9a-fA-F]{40,}\b` (high false positive rate)
- Commented-out real-looking keys (`.env` patterns in comment lines)
- Long base64 blobs (>200 characters)
- Frontmatter tags: `confidential`, `proprietary`, `pii`, `customer`
- Known customer domains (from `_system/docs/peer-review-denylist.md` if it exists)

## Entropy-Based Soft Detection

For strings matching `[A-Za-z0-9+/=_-]{20,}` that don't match a known pattern above,
compute Shannon entropy. If >3.5 bits/char over 20+ chars, flag as soft warning
(likely random/secret data rather than natural text).

## Maintenance Notes

- When adding patterns, add to the appropriate section above and test against known
  false positives (regex patterns in docs, placeholder examples in specs)
- Both dispatch agents carry built-in copies of the hard denylist as fallback —
  keep those copies in sync when updating this file
- The peer-review-dispatch agent's inline patterns should be updated to reference
  this file in a future revision (currently it has its own inline copy)
