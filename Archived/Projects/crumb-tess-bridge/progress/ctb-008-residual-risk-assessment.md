---
type: assessment
domain: software
status: active
created: 2026-02-21
updated: 2026-02-21
project: crumb-tess-bridge
task: CTB-008
---

# CTB-008 — Residual Risk Assessment

## Test Summary

15 adversarial payloads tested through the full bridge pipeline (40 individual tests).
Each payload documents which defense layer caught it or whether it survived.

## Defense Layer Map

| Layer | Mechanism | Catches |
|-------|-----------|---------|
| L1 | Schema validation (`validateOperation`, `validateParams`) | Unknown ops, unknown params, wrong types, path traversal |
| L2 | ASCII enforcement (`validateAscii`, charCode > 127) | All Unicode attacks: zero-width chars, bidi overrides, RTL/LTR markers, homoglyphs outside ASCII |
| L3 | Payload hash (`payloadHash` recomputed by Crumb) | Any payload tampering after echo confirmation |
| L4 | confirm_code binding (A1 fix) | Confirmation replay, code mismatch |
| L5 | HTML escaping (`escapeHtml` in echo-formatter) | HTML injection, script tags, codeblock breakout |
| L6 | Sender ID allowlist (`CRUMB_BRIDGE_ALLOWED_SENDER`) | Unauthorized senders |

## Payload Results Matrix

| # | Payload | Defense | Severity | Result |
|---|---------|---------|----------|--------|
| P1 | Zero-width characters (U+200B, U+FEFF, U+200C, U+200D) | L2 | HIGH | caught-by-schema |
| P2 | RTL/LTR overrides (U+202E, U+202D, U+2066, U+2069) | L2 | HIGH | caught-by-schema |
| P3 | HTML injection (`<script>`, `<b>`) in reason | L5 | MEDIUM | caught-by-echo |
| P4 | Codeblock breakout (`</code></pre>`) | L5 | MEDIUM | caught-by-echo |
| P5a | Path traversal (`../../../etc/passwd`) | L1 | HIGH | caught-by-schema |
| P5b | Absolute path (`/etc/passwd`) | L1 | HIGH | caught-by-schema |
| P5c | Symlink escape | Crumb realpathSync | HIGH | caught-by-crumb |
| P6 | Long reason pushing hash off-screen | L1 (maxLength 500) | ~~MEDIUM~~ CLOSED | caught-by-schema |
| P7 | Transcript poisoning (markdown injection) | — | LOW | survived (see R2) |
| P8 | JSON-shaped malicious reason | L5 | LOW | caught-by-echo |
| P9 | Payload hash tampering (full, partial, empty) | L3 | HIGH | caught-by-hash |
| P10 | confirm_code mismatch | L4 | HIGH | caught-by-crumb |
| P11 | Newline injection in reason | JSON escaping | LOW | survived (benign) |
| P12 | ASCII control characters (NUL, TAB, CR) | JSON escaping | LOW | survived (see R3) |
| P13 | Unauthorized sender_id | L6 | HIGH | caught-by-sender |
| P14 | Unknown fields / unknown operations | L1 | MEDIUM | caught-by-schema |
| P15 | ASCII homoglyphs (l/1, O/0) | — | LOW | survived (see R4) |

## Residual Risks

### R1 — Long Reason String: Echo Truncation — CLOSED

**Finding:** A `reject-gate` reason of ~2000+ chars causes the echo HTML to exceed
Telegram's 4096-char rendered limit, hiding the hash and CONFIRM instruction.

**Fix applied:** `maxLength: 500` added to the `reason` field validator in `constants.js`.
Schema validation now rejects reasons longer than 500 chars. A 500-char reason produces
an echo well within the 3500-char safe budget (verified by test).

**Status:** CLOSED — enforced at L1 (schema validation). No echo truncation possible
with the length cap in place.

### R2 — Transcript Poisoning: Ambiguous Markdown (LOW)

**Finding:** A reason containing markdown headers (`## Integrity`, `# Fake Section`) is
written into the transcript's Parameters block. The injected headers appear in the
transcript alongside the real structural headers.

**Impact:** A human reviewer could be confused by fake sections in the transcript. However:
- The real `## Integrity` section is always the LAST occurrence in the file
- The transcript hash self-verifies (computed over the full content including injected text)
- The injected content is visibly inside the `### Parameters` section when reading top-to-bottom

**Mitigation (deferred, A11 — transcript sanitization before Phase 2 dispatch):**
- Escape or fence param values in the transcript (e.g., wrap in code blocks)
- This matters more for Phase 2 dispatch where Crumb re-reads transcripts

**Severity classification:** LOW — visual confusion only, no integrity bypass. Human
reviewer can identify injected content from structural position.

### R3 — ASCII Control Characters (LOW)

**Finding:** NUL (0x00), TAB (0x09), CR (0x0D), and other ASCII control characters
(0x01-0x1F) pass `validateAscii` (which only rejects charCode > 127). These are
safely escaped by `JSON.stringify` in canonical JSON, preserving hash integrity.

**Impact:** Control characters in params could cause unexpected display behavior in
Telegram. NUL bytes could truncate strings in some rendering contexts.

**Mitigation (optional, low priority):**
- Extend `validateAscii` to also reject control characters (charCode < 0x20, except
  maybe TAB and newline). Or add a `validatePrintableAscii` check.
- Not urgent: Phase 1 params are highly constrained (kebab-case project names, enum
  values, PHASE->PHASE gates). Only `reason` is free-form text.

**Severity classification:** LOW — JSON escaping preserves hash integrity. Display
impact only, in a field (reason) that's already user-supplied content.

### R4 — ASCII Homoglyphs (LOW)

**Finding:** Characters like 0/O, 1/l, rn/m pass all validation. A project named
`test-pr0ject` (zero instead of 'o') would pass schema validation and produce a
different hash than `test-project`.

**Impact:** The confirmation echo shows the exact characters. The hash is different.
A user must visually compare the project name in the echo to catch this. This is
exactly what the echo is designed for — human verification of the payload before
confirming.

**Mitigation:** None needed beyond the echo flow. The hash-bound confirmation echo
IS the defense against visual confusion attacks. If the user confirms a payload with
a confusing project name, that's an informed decision.

**Severity classification:** LOW — the echo mechanism works as designed for this case.

## Findings: Code Quality

### stripBidiOverrides Not Wired In

`stripBidiOverrides()` in `echo-formatter.js` is defined and exported but never called
in the actual echo formatting pipeline. ASCII validation (L2) catches all bidi overrides
at the schema level, making this function redundant for the current architecture.

**Recommendation:** Either wire it in as defense-in-depth (strip before escaping, in case
ASCII validation is ever loosened) or remove it to avoid dead code confusion.

## Conclusion

**No HIGH or MEDIUM-severity bypasses remain unmitigated.**

All HIGH-severity attacks (zero-width chars, bidi overrides, path traversal, hash
tampering, confirmation binding, sender allowlist) are caught by automated defenses.

R1 (the only MEDIUM finding) is now CLOSED — `maxLength: 500` on the reason field
prevents echo truncation at the schema layer. Remaining residual risks are all LOW
severity (transcript visual ambiguity, control chars, ASCII homoglyphs).

## Telegram Rendering Verification

The AC requires adversarial payloads to be "tested through actual Telegram rendering,
not just local string comparison." The following payloads need live Telegram verification:

1. **P3 (HTML injection)** — verify `&lt;script&gt;` renders as literal text, not tag
2. **P4 (codeblock breakout)** — verify `</code></pre>` inside `<pre>` renders safely
3. **P6 (long reason)** — ~~verify truncation behavior~~ CLOSED (maxLength cap)
4. **P15 (homoglyphs)** — verify 0/O distinction in Telegram's font

**Helper script:** `src/e2e/telegram-rendering-verify.js`
- `--dry-run` prints the echo HTML for each payload
- With `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` env vars, sends to Telegram

**Status:** COMPLETE. All 4 payloads verified via live Telegram rendering (2026-02-22).

| Payload | Telegram Result | Msg ID |
|---------|----------------|--------|
| P3a (`<script>` injection) | Literal text, no execution, no missing content | 59 |
| P3b (`<b>` fake bold) | Literal text, NOT rendered as bold, tags visible | 61 |
| P4 (codeblock breakout) | JSON block intact, "INJECTED" not bold, tags literal | 63 |
| P15 (ASCII homoglyphs 0/O) | Zero visually distinguishable from O in monospace font | 65 |

P3a label message failed (Telegram rejects `<script>` as unsupported HTML tag) —
this confirms our echo escaping works: the echo itself sent successfully because
`formatEchoHtml` escapes `<` to `&lt;`. P6 (long reason) was CLOSED by maxLength
cap and did not need rendering verification.
