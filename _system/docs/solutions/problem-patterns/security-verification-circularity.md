---
type: problem-pattern
domain: software
status: active
track: bug
created: 2026-02-19
updated: 2026-04-04
confidence: high
topics:
  - moc-crumb-architecture
tags:
  - kb/security
  - problem-pattern
---

# Security Verification Circularity

## Pattern

When verifying that an untrusted or semi-trusted component performed an action correctly, the verification mechanism must not depend on self-report from that component.

## Instances

### 1. HMAC Under Compromise Assumptions

**Anti-pattern:** Adding HMAC-SHA256 message authentication between two processes where the threat model assumes one process may be compromised. If the shared secret must be accessible to the potentially compromised party (for signing), a compromise gives the attacker the signing key — the HMAC protects against third parties but not against the compromised signer.

**Test:** "If the party I'm authenticating is the same party I'm defending against, does the auth mechanism still hold?" If no, it's circular.

**Alternative:** Use OS-level isolation (filesystem permissions, user boundaries) as the trust boundary. Message-level auth adds value only when it protects against parties *outside* the trust boundary.

**Source:** crumb-tess-bridge spec R2, A2 declined. Filesystem permissions preventing third-party inbox writes made HMAC redundant; compromised Tess having the signing key made it circular.

### 2. Non-Echoable Verification for LLM Sessions

**Anti-pattern:** Injecting a known value (e.g., a hash) into an LLM session prompt, then checking the response contains that value as "proof" the session loaded a governance file. The LLM can simply echo the injected value without reading the file.

**Test:** "Can the session produce the expected output without actually performing the action I'm verifying?" If yes, the check is echoable and therefore circular.

**Fix:** Require the session to produce a value it can only obtain by performing the action. Example: inject only a nonce; require the session to return the last N bytes of the governance file. The runner independently verifies the returned bytes match the file on disk. The session must read the file to produce this value — it cannot echo something from the prompt.

**Source:** crumb-tess-bridge spec R2, A5. Original BT3 two-tier model had runner inject `expected_governance_hash` and check response matched — circular. Fixed to require `governance_canary` (last 64 bytes of CLAUDE.md).

## General Principle

Verification of untrusted components requires the verifier to hold information the verified component cannot derive from the verification request alone. If the verification protocol leaks enough information for the component to "pass" without performing the verified action, the check is security theater.
