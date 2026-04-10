---
type: change-spec
domain: software
project: x-feed-intel
status: integrated
created: 2026-02-25
updated: 2026-02-25
---

# Amendment: Backlog Research Command

**Scope:** Add a standalone Telegram command `research {url}` that dispatches any post in the database for enriched research, independent of the current digest.

**Motivation:** Item IDs (A01, B03, etc.) are ephemeral — they reset with each digest delivery. Once a new digest arrives, there is no way to reference items from previous digests via Telegram. The underlying data persists in SQLite (every captured post is in the `items` table with its canonical ID), but the Telegram-based feedback loop has no handle to reach it.

This is particularly acute during the initial deployment phase: the first capture pulled hundreds of historical bookmarks, many of which are research-worthy but have since been displaced from the active digest.

**Relationship to existing spec:**
- §5.8 (Reply-Based Control Protocol): Reply-based `{ID} research` remains the primary path for current-digest items. This amendment adds a parallel entry point that bypasses the digest entirely.
- §5.8.1 (Research Command: Context Enrichment): The enrichment pipeline (thread expansion, reply mining, context file generation, bridge dispatch) is reused wholesale. Only the input resolution changes — canonical ID from URL instead of item ID from digest.
- §5.8 standalone commands: Follows the same pattern as `refresh` (XFI-022b) — non-reply messages routed before the reply-to-message check.

---

## Design

### Command Format

Standalone (non-reply) message to the bot:

```
research https://x.com/{author}/status/{id}
```

Also accepted:
- `research https://twitter.com/{author}/status/{id}` (legacy domain)
- `research {canonical_id}` (raw tweet ID, for power-user/scripted use)

Case-insensitive command word. Whitespace-trimmed.

### Resolution Flow

1. **Parse URL → canonical ID.** Extract the numeric tweet ID from the URL path. For raw numeric input, use directly. Reject anything that doesn't resolve to a numeric ID — reply with: "Couldn't parse that URL. Format: `research https://x.com/.../status/123`"

2. **DB lookup.** Query the `items` table by canonical ID.
   - **Found:** Load normalized post data (author, text, conversation_id, created_at, engagement). Proceed to step 3.
   - **Not found:** The post was never captured by the pipeline. Reply with: "Post {id} isn't in the database. It may not have been captured yet." Do NOT fetch from the API — the post should have gone through capture → triage first. (Future: a `fetch + research` variant could be added if needed.)

3. **Dedup check.** Same as reply-based research — query `feedback` table for `canonical_id + command = 'research'`. If already dispatched, reply: "Already researched — see `_openclaw/feeds/research/{filename}.md`". Include the actual filename so the user can find the output.

4. **Dispatch.** Feed into the existing `handleResearch()` flow starting after item resolution. The remainder of the pipeline is identical:
   - Generate stem (human-readable filename)
   - Initial Telegram ack
   - Enrichment (thread + replies)
   - Context file write
   - Bridge dispatch
   - Investigate file write
   - Pending research tracking
   - Completion polling

### Feedback Storage

Log to the `feedback` table with:
- `digest_date`: the date the post was *originally captured* (from `items.captured_at`), not today's date. This preserves the semantic meaning of `digest_date` as "when the pipeline saw this post."
- `item_id`: the canonical ID (no ephemeral code available). This is a divergence from reply-based research where `item_id` is `A01` etc., but the field is only used for logging/display — dedup uses `canonical_id`.
- `command`: `research` (same as reply-based)

### Telegram UX

Initial ack for backlog research includes the post context since the user doesn't have a digest in front of them:

```
🔍 Researching @{author}: "{first_60_chars}..." — expanding thread...
```

Second ack (conditional on >2s enrichment) same as existing:

```
Context expanded — dispatching to Crumb...
```

Completion notification same as existing, with the human-readable filename.

### Error Handling

- **Malformed URL:** Reply with parse error message (step 1). No action taken.
- **Post not in DB:** Reply with "not captured" message (step 2). No action taken.
- **Already researched:** Reply with dedup message and existing filename (step 3). No action taken.
- **Enrichment/dispatch failures:** Same as §5.8.1 — non-blocking, proceed with available context.

---

## Spec Integration Points

1. **§5.8 command table:** Add row: `research {url}` (standalone) — "Dispatch any captured post for enriched research by URL, independent of current digest"
2. **§5.8 standalone commands paragraph** (line 529): Update "the feedback listener ignores it" to note that `refresh` and `research {url}` are standalone commands handled before the reply-to-message check.
3. **§5.8.1:** No changes needed — enrichment pipeline is reused as-is. The amendment note can reference this section for the shared flow.
4. **§5.9 cost telemetry:** No impact — backlog research uses the same enrichment calls, already tracked under the `enrichment` cost component.

## Implementation Notes

- Slot into the existing standalone command router at `feedback-listener.ts:1071-1077`, alongside `refresh`
- Extract URL parsing into a helper (`parseResearchTarget(text: string): string | null`) — returns canonical ID or null
- The `handleResearch()` function currently takes `(db, token, chatId, messageId, itemId, digestDate, canonicalId)`. The backlog path provides all of these except `itemId` (use canonical ID) and `digestDate` (from `items.captured_at`)
- No new API calls, no new dependencies, no schema changes

## Cost Impact

Zero incremental API cost vs reply-based research — same enrichment calls, same bridge dispatch. The only difference is input resolution (URL → canonical ID → DB lookup), which is a local SQLite query.
