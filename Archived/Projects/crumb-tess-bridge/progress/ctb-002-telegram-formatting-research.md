---
type: research-note
domain: software
status: draft
created: 2026-02-19
updated: 2026-02-19
project: crumb-tess-bridge
task: CTB-002
---

# CTB-002: Telegram Message Formatting Research

## 1. Rendering Rules Comparison: MarkdownV2 vs HTML

### MarkdownV2 Syntax Reference

| Format | Syntax | Notes |
|--------|--------|-------|
| Bold | `*bold*` | |
| Italic | `_italic_` | |
| Underline | `__underline__` | |
| Strikethrough | `~strikethrough~` | |
| Spoiler | `\|\|spoiler\|\|` | |
| Inline code | `` `code` `` | |
| Code block | ` ```code``` ` | Language specifier: ` ```python\ncode``` ` |
| Blockquote | `>text` | Prefix each line with `>` |
| Expandable blockquote | `**>text` | Collapsible |
| Link | `[text](url)` | |
| User mention | `[text](tg://user?id=NNN)` | |
| Custom emoji | `![emoji](tg://emoji?id=NNN)` | Restricted to premium/fragment bots |

**Escaping rules (MarkdownV2):**

- **Outside entities:** These 20 characters MUST be escaped with `\`:
  `_` `*` `[` `]` `(` `)` `~` `` ` `` `>` `#` `+` `-` `=` `|` `{` `}` `.` `!`
- **Inside `pre` and `code` entities:** Only `` ` `` and `\` need escaping.
- **Inside `(...)` of inline links:** Only `)` and `\` need escaping.

### HTML Syntax Reference

| Format | Tag | Notes |
|--------|-----|-------|
| Bold | `<b>` or `<strong>` | |
| Italic | `<i>` or `<em>` | |
| Underline | `<u>` or `<ins>` | |
| Strikethrough | `<s>`, `<strike>`, or `<del>` | |
| Spoiler | `<span class="tg-spoiler">` or `<tg-spoiler>` | |
| Inline code | `<code>` | |
| Code block | `<pre>` | |
| Code block with language | `<pre><code class="language-python">` | Nested tags |
| Blockquote | `<blockquote>` | |
| Expandable blockquote | `<blockquote expandable>` | |
| Link | `<a href="url">text</a>` | |
| User mention | `<a href="tg://user?id=NNN">text</a>` | |
| Custom emoji | `<tg-emoji emoji-id="NNN">emoji</tg-emoji>` | |

**Escaping rules (HTML):**

- Only 4 named entities recognized: `&lt;` `&gt;` `&amp;` `&quot;`
- All other `<` and `>` and `&` must use these entities
- No backslash escaping — standard HTML entity escaping only

### Nesting Rules

- Bold, italic, underline, strikethrough, and spoiler can nest with each other.
- `pre` and `code` entities **cannot contain** other formatting entities.
- Blockquote entities cannot be nested inside each other.

## 2. Code Block Behavior

### Rendering

- Triple backtick (MarkdownV2) or `<pre>` (HTML) creates a monospace block with a
  distinct visual frame (gray background on most clients).
- Language specifier supported: ` ```json\n{...}\n``` ` renders with syntax highlighting
  (client-dependent — desktop tends to highlight better than mobile).

### Whitespace Preservation

- Code blocks **preserve whitespace and indentation** — newlines and spaces are rendered
  as-is within the block.
- **Known issue (desktop):** Leading whitespace on the first line may be trimmed in some
  Telegram Desktop versions (see [tdesktop#1521](https://github.com/telegramdesktop/tdesktop/issues/1521)).
  Workaround: start code block content on the line after the opening backticks.
- Line wrapping depends on device screen width, font size, and client. Lines do not
  hard-wrap at a fixed column — they soft-wrap at the display edge.

### Character Limit

- No separate character limit for code blocks. They count against the overall 4096-character
  message limit.
- In practice, code blocks can contain the full 4096 characters (minus any surrounding text).

### Special Characters Inside Code Blocks

- **MarkdownV2:** Inside code/pre entities, only `` ` `` and `\` need escaping. All other
  special characters (`_`, `*`, `[`, etc.) render literally without escaping. This is a
  major simplification for programmatic content like JSON.
- **HTML:** Inside `<pre>` tags, only `<`, `>`, and `&` need entity-escaping (`&lt;`,
  `&gt;`, `&amp;`). All other characters render literally.

### Cross-Platform Behavior

- Code blocks render consistently across iOS, Android, Desktop, and Web.
- Minor visual differences: background color shade, font face, padding.
- Copy-to-clipboard behavior is consistent — code blocks copy as plain text without
  formatting artifacts.

## 3. The 4096-Character Limit

### Exact Limit

The Telegram Bot API `sendMessage` method accepts a `text` parameter described as:
**"Text of the message to be sent, 1-4096 characters after entities parsing."**

This means the 4096 limit applies to the **rendered text content** after all formatting
markup is stripped — NOT to the raw MarkdownV2/HTML source.

### Character Counting

Two different encodings matter in different contexts:

1. **Message text limit (4096):** Measured in **UTF-8 characters** (i.e., Unicode code points).
   A single emoji (even a multi-byte one like a flag) counts as its UTF-8 character count.
   For ASCII-only content (like JSON), 1 character = 1 unit.

2. **Entity offsets and lengths:** The Telegram API uses **UTF-16 code units** for computing
   entity offsets and lengths in the `entities` array. This matters when working with the
   raw API entities (not parse modes), because characters outside the Basic Multilingual
   Plane (emoji, some CJK) are 2 UTF-16 code units but 1 code point.

For our use case (ASCII JSON payloads + English text), these are equivalent. But the
implementation should be aware of the distinction if user input contains non-ASCII characters.

### Error Behavior When Exceeded

The Bot API does **NOT** auto-truncate or auto-split. When a message exceeds 4096 characters:

- **API response:** HTTP 400 Bad Request
- **Error description:** `"Bad Request: message is too long"`
- **Behavior:** The message is **not sent at all**. No partial delivery.

The Tess skill MUST validate message length before calling `sendMessage` and implement
its own splitting strategy if needed. Splitting formatted messages is non-trivial because
a split point could land inside a code block, breaking the markup.

### Formatted vs Plain Text Limit

The limit is the same (4096) regardless of parse mode. However, "after entities parsing"
means:

- **MarkdownV2:** The formatting characters (`*`, `_`, backticks, `\` escapes) are NOT
  counted. Only the visible rendered text counts.
- **HTML:** The tags (`<b>`, `</b>`, `<pre>`, etc.) are NOT counted. Only the text
  content between tags counts.
- **Plain text (no parse_mode):** The raw text IS the rendered text, so they're equal.

This is important for budget calculations: the template's formatting markup is "free" —
only the visible characters count toward 4096.

## 4. Special Character Handling Matrix

| Character / Category | In Regular Text | In Code Block | Security Concern |
|---------------------|-----------------|---------------|------------------|
| Newline (`\n`) | Preserved, creates line break | Preserved | None |
| Tab (`\t`) | Rendered as space (width varies) | Preserved as tab | None |
| Zero-width space (U+200B) | Invisible, present in text | Invisible, present | LOW: can pad payload hash input |
| Zero-width joiner (U+200D) | Used in emoji sequences | Present but invisible | LOW: can pad text |
| Zero-width non-joiner (U+200C) | Invisible, present | Invisible, present | LOW: can pad text |
| RTL override (U+202E) | **Reverses text direction** | Rendered in code block | **HIGH: display spoofing** |
| LTR override (U+202D) | Overrides to LTR | Rendered in code block | MEDIUM: can mask RTL override |
| RTL/LTR mark (U+200F/U+200E) | Affects bidi algorithm | Present | MEDIUM: subtle layout shifts |
| Pop directional (U+202C) | Terminates override | Present | Used with RTL/LTR overrides |
| Backspace (U+0008) | Stripped by Telegram | Stripped | None (Telegram sanitizes) |
| Null byte (U+0000) | Stripped by Telegram | Stripped | None (Telegram sanitizes) |
| Backtick (`` ` ``) | Normal character | **Needs escaping (MdV2)** | **HIGH: can break code blocks** |
| Backslash (`\`) | Normal character | **Needs escaping (MdV2)** | MEDIUM: can affect escaping |
| `<`, `>`, `&` | Normal (MdV2) / Escape (HTML) | Escape in HTML mode | MEDIUM: can break HTML parse |

### Injection-Relevant Findings

1. **Code block breakout (MarkdownV2):** A payload containing ` ``` ` (triple backtick)
   will close the code block prematurely if not escaped. The canonical JSON payload must
   have backticks escaped (`\`\`\``) inside code blocks. Since JSON values cannot contain
   raw backticks (they'd be in strings, which use `"`), this risk is limited to
   user-supplied string values.

2. **RTL override attack:** U+202E in a payload could visually reorder the echo display,
   making a destructive operation look benign. **Mitigation:** Strip or reject Unicode
   bidirectional override characters (U+202A–U+202E, U+2066–U+2069) from all user input
   before echoing. Code blocks partially mitigate this (monospace rendering is less
   affected by bidi) but do not fully prevent it.

3. **Zero-width character injection:** Zero-width characters in the payload would be
   invisible in the echo but would change the `payload_hash`. The user sees the "same"
   text but the hash differs. **Mitigation:** Normalize Unicode (NFC) and strip zero-width
   characters before canonical JSON serialization.

4. **HTML tag injection (HTML mode):** If using HTML parse mode, a payload containing
   `<b>` or `<script>` (even though `<script>` is unsupported) could cause parse errors.
   **Mitigation:** Entity-escape all `<`, `>`, `&` in payload content when using HTML mode.
   Code blocks (`<pre>`) still require this escaping.

## 5. Recommended Parse Mode

**Recommendation: HTML**

### Justification

| Factor | MarkdownV2 | HTML | Winner |
|--------|-----------|------|--------|
| Escaping complexity | 20 special chars outside entities, context-dependent rules | 3 chars (`<`, `>`, `&`) everywhere | **HTML** |
| Code block safety | Only `` ` `` and `\` need escaping inside | Only `<`, `>`, `&` need escaping inside | **Tie** |
| Programmatic construction | Error-prone — must track context to know which chars to escape | Simple — one `escapeHtml()` function works everywhere | **HTML** |
| Feature parity | Slightly more features (expandable blockquote syntax is cleaner) | Same core features for our use case | **Tie** |
| Debugging | Hard to read raw MarkdownV2 with all the backslashes | HTML is readable even in raw form | **HTML** |
| JSON in code blocks | JSON contains no backticks normally, so low risk — but user-supplied strings could | JSON contains no `<>` normally; `&` is rare but possible in strings | **Tie** |
| Library support | Many escaping bugs reported in community libraries | Standard HTML escaping — well-understood | **HTML** |

**Key argument:** The bridge constructs messages programmatically from structured data.
HTML's escaping rules are simpler, context-independent, and less error-prone. MarkdownV2's
context-dependent escaping (different rules inside code blocks, inside link URLs, and
outside entities) is a recurring source of bugs in bot development. For a
security-critical confirmation echo, we want the simplest possible escaping to minimize
the surface for formatting errors that could obscure the payload.

**Fallback consideration:** If a specific feature only available in MarkdownV2 is later
needed, the bridge can switch per-message. The parse mode is set per `sendMessage` call,
not globally.

## 6. Echo Display Template

### Template (HTML parse mode)

```html
<b>Bridge Request — Confirm?</b>

<b>Operation:</b> {operation_display_name}
<b>Project:</b> {project_name}
{additional_params_lines}

<b>Payload:</b>
<pre><code class="language-json">{canonical_json_escaped}</code></pre>

<b>Confirmation code:</b> <code>{payload_hash_12}</code>

Reply: <code>CONFIRM {payload_hash_12}</code>
Or: <code>CANCEL</code>
```

### Example Rendering (approve-gate)

Raw HTML sent to Telegram:

```html
<b>Bridge Request — Confirm?</b>

<b>Operation:</b> Approve Gate
<b>Project:</b> crumb-tess-bridge
<b>Gate:</b> SPECIFY → PLAN

<b>Payload:</b>
<pre><code class="language-json">{
  "operation": "approve-gate",
  "params": {
    "decision": "approved",
    "gate": "SPECIFY-&gt;PLAN",
    "project": "crumb-tess-bridge"
  }
}</code></pre>

<b>Confirmation code:</b> <code>3fa91c2d18a4</code>

Reply: <code>CONFIRM 3fa91c2d18a4</code>
Or: <code>CANCEL</code>
```

Visual rendering in Telegram (approximate):

```
┌─────────────────────────────────────────┐
│ Bridge Request — Confirm?               │
│                                         │
│ Operation: Approve Gate                 │
│ Project: crumb-tess-bridge              │
│ Gate: SPECIFY → PLAN                    │
│                                         │
│ Payload:                                │
│ ┌─────────────────────────────────────┐ │
│ │ {                                   │ │
│ │   "operation": "approve-gate",      │ │
│ │   "params": {                       │ │
│ │     "decision": "approved",         │ │
│ │     "gate": "SPECIFY->PLAN",        │ │
│ │     "project": "crumb-tess-bridge"  │ │
│ │   }                                 │ │
│ │ }                                   │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ Confirmation code: 3fa91c2d18a4         │
│                                         │
│ Reply: CONFIRM 3fa91c2d18a4             │
│ Or: CANCEL                              │
│                                         │
└─────────────────────────────────────────┘
```

### Example Rendering (query-status)

```html
<b>Bridge Request — Confirm?</b>

<b>Operation:</b> Query Status
<b>Project:</b> crumb-tess-bridge

<b>Payload:</b>
<pre><code class="language-json">{
  "operation": "query-status",
  "params": {
    "project": "crumb-tess-bridge",
    "scope": "current-phase"
  }
}</code></pre>

<b>Confirmation code:</b> <code>7b2e4f1a9c03</code>

Reply: <code>CONFIRM 7b2e4f1a9c03</code>
Or: <code>CANCEL</code>
```

### Template Validation Against Both Parse Modes

The template is designed for HTML but can be rendered in MarkdownV2 if needed:

**HTML version** (primary):
```
<b>Bridge Request — Confirm?</b>\n\n<b>Operation:</b> ...
```

**MarkdownV2 equivalent** (fallback):
```
*Bridge Request — Confirm?*\n\n*Operation:* ...
```

The MarkdownV2 version requires escaping `-`, `>`, `.` in the display text (e.g.,
`SPECIFY \-\> PLAN`, `crumb\-tess\-bridge`). This further supports the HTML recommendation.

## 7. Character Budget Breakdown

### Template Chrome (Fixed Overhead)

Counting visible rendered characters only (formatting tags are free):

| Component | Characters |
|-----------|-----------|
| "Bridge Request — Confirm?" + newlines | 32 |
| "Operation: " label + newline | 12 |
| "Project: " label + newline | 10 |
| "Payload:" label + newline | 9 |
| "Confirmation code: " + 12-char hash + newlines | 32 |
| "Reply: CONFIRM " + 12-char hash + newline | 29 |
| "Or: CANCEL" | 10 |
| Structural newlines (blank lines between sections) | ~10 |
| **Total fixed chrome** | **~144** |

### Variable Content

| Component | Typical Size | Maximum Reasonable |
|-----------|-------------|-------------------|
| Operation display name | 15–25 chars | 40 chars |
| Project name | 15–30 chars | 60 chars |
| Additional param lines (0–3 lines) | 0–90 chars | 150 chars |
| **Total variable (non-payload)** | **30–145 chars** | **250 chars** |

### Payload Budget

```
Total available:                        4096 characters
Fixed chrome:                          - 144 characters
Variable content (typical):            - 100 characters
Variable content (maximum):            - 250 characters
                                       ─────────────────
Payload budget (typical):               3852 characters
Payload budget (worst case):            3702 characters
Payload budget (safe design target):    3500 characters
```

### Is 3500 Characters Enough?

Phase 1 operations have small payloads:

| Operation | Typical Payload Size | Notes |
|-----------|---------------------|-------|
| `approve-gate` | 120–180 chars | Small — gate name, project, decision |
| `reject-gate` | 150–250 chars | Slightly larger — includes reason text |
| `query-status` | 80–120 chars | Minimal — project + scope |
| `query-progress` | 80–120 chars | Minimal — project + scope |

Phase 2 operations are larger but still well within budget:

| Operation | Typical Payload Size | Notes |
|-----------|---------------------|-------|
| `start-task` | 200–400 chars | Task ID + acceptance criteria excerpt |
| `invoke-skill` | 150–500 chars | Skill name + arguments |
| `quick-fix` | 200–600 chars | Description of change |

**Conclusion:** The 3500-character payload budget is more than sufficient for all planned
operations. Even the largest Phase 2 payloads (~600 chars) use less than 20% of the budget.
A payload approaching the budget limit would indicate a schema design problem, not a
Telegram limitation.

### Overflow Strategy

If a payload ever exceeds the budget (defensive design):

1. **Truncate the JSON display** in the echo with an explicit marker:
   ```
   { "operation": "...", "params": { ... [truncated at 3500 chars] ... } }
   ```
2. **Always display the full hash** — the hash is computed on the full payload, not the
   truncated display. The user can verify via hash even if the display is truncated.
3. **Add a warning line:** "Payload truncated for display. Full payload will be written to inbox."
4. **Never truncate silently** — the user must know the echo is incomplete.

This is a safety net, not an expected path. If triggered, it should log a warning for
investigation.

## 8. Implementation Recommendations

### For CTB-004 (Bridge Skill)

1. **Use HTML parse mode** for all bridge messages (echo, relay, errors).
2. **Implement `escapeHtml(text)`** — replace `&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`.
   Apply to all dynamic content before insertion into HTML template.
3. **Validate message length** against 4096 visible characters before sending. Count the
   rendered text, not the raw HTML.
4. **Strip Unicode bidi overrides** (U+202A–U+202E, U+2066–U+2069) from all user input
   and payload string values before echoing.
5. **Normalize Unicode** (NFC) before canonical JSON serialization to prevent zero-width
   character injection affecting the hash.
6. **Test backtick sequences** in string values — ensure they don't break code blocks
   (unlikely with HTML mode, but verify).

### For CTB-008 (Injection Test Suite)

Test vectors should include:

- Backtick sequences in string values (` ``` `, single `` ` ``)
- HTML tags in string values (`<b>`, `<script>`, `</pre>`)
- RTL override (U+202E) before operation name
- Zero-width characters between hash characters
- Newline injection in parameter values
- Extremely long string values (near budget limit)
- Mixed LTR/RTL text in project names
- Unicode homoglyphs (Cyrillic "а" vs Latin "a" in operation names)

## 9. Acceptance Criteria Status

| Criterion | Status | Notes |
|-----------|--------|-------|
| Telegram markdown rendering rules documented | DONE | Section 1 — full MarkdownV2 and HTML reference |
| Code block behavior tested | PARTIAL | Section 2 — documented from API docs and community reports. Live rendering test still needed (CTB-004/CTB-015 will test against real Telegram) |
| 4096-char truncation behavior confirmed | DONE | Section 3 — confirmed: no truncation, API returns HTTP 400 error |
| Echo display template validated against real Telegram rendering | PENDING | Section 6 — template designed and budget validated. Requires live send via `@tdusk42_bot` to confirm rendering. Recommend: validate during CTB-015 (Telegram UX task) |

**Remaining validation:** The echo display template in Section 6 needs to be sent through
the actual Telegram Bot API to confirm rendering matches expectations. This should happen
during CTB-015 implementation, not as a separate research step — the template is designed
to spec, and live testing is an implementation concern.

## 10. Sources

- [Telegram Bot API — Official Documentation](https://core.telegram.org/bots/api)
- [Styled text with message entities — Telegram](https://core.telegram.org/api/entities)
- [Telegram HTML Formatting Guide — MisterChatter](https://www.misterchatter.com/docs/telegram-html-formatting-guide-supported-tags/)
- [MarkdownV2 special characters — telegraf#1242](https://github.com/telegraf/telegraf/issues/1242)
- [Leading whitespace trimmed in code blocks — tdesktop#1521](https://github.com/telegramdesktop/tdesktop/issues/1521)
- [sendMessage 4096 limit — node-telegram-bot-api#165](https://github.com/yagop/node-telegram-bot-api/issues/165)
- [Message is too long — telegram-bot-api#374](https://github.com/tdlib/telegram-bot-api/issues/374)
- [Telegram Limits — tginfo](https://limits.tginfo.me/en)
- [telegram-escape — correct MarkdownV2 escaping](https://github.com/utterstep/telegram-escape)
- [RTL override vulnerability — Kaspersky/Telegram](https://wccftech.com/telegram-0-day-malware-mining-scripts/)
- [Invisible Unicode threats — Promptfoo](https://www.promptfoo.dev/blog/invisible-unicode-threats/)
- [Code block inconsistencies — telegram-bot-api#515](https://github.com/tdlib/telegram-bot-api/issues/515)
