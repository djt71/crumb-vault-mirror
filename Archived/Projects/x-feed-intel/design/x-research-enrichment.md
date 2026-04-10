---
type: change-spec
domain: software
project: x-feed-intel
status: integrated
created: 2026-02-25
updated: 2026-02-25
---

# Amendment: Context Enrichment on Research Dispatch

**Scope:** When a digest item is promoted for research (`{ID} research`), Tess enriches the item with full thread context and notable replies before dispatching to Crumb via the bridge.

**Motivation:** Currently, Crumb receives a single post's text (truncated to ~2000 chars) in the dispatch context field. If the post is part of a thread or has high-quality replies, Crumb researches against incomplete information. The operator has no way to surface that surrounding context. Thread expansion was deferred to Phase 2 (§7.5); this amendment pulls it forward, scoped to promoted items only — not all captured content.

**Relationship to existing spec:**
- §5.3 (Normalizer): `needs_context` flag and thread heuristic remain unchanged for triage
- §7.5 (Thread Handling): Phase 1 heuristic-only approach remains for *capture and triage*. This amendment adds on-demand expansion at *research dispatch time* only
- §5.8 (Reply-Based Control Protocol): `research` command gains an enrichment step between command receipt and bridge dispatch
- Web UI proposal "investigate" action: This amendment implements the data-gathering half of that flow within the existing Telegram-based research command. The web UI can consume the same enrichment when built

---

## Design

### Trigger

Enrichment runs when the feedback listener processes a `{ID} research` command. It does NOT run for `promote`, `save`, or other commands — those don't dispatch to Crumb and don't need expanded context.

### Enrichment Steps

After the feedback listener identifies the target item from the digest and before building the bridge dispatch request:

**1. Thread expansion**

If the post has `conversation_id` (available from the X API response, stored in the items table during capture):

- Fetch the conversation chain via TwitterAPI.io `GET /twitter/tweet/thread_context?tweetId={id}` — this returns the full lineage (parent tweets above, replies below) for any tweet in a thread
- Order chronologically (earliest first)
- Include all posts in the direct reply chain regardless of author — this captures genuine multi-author back-and-forth where the best signal often lives. Specifically: include any post where `inReplyToId` points to another post in the chain (direct conversation participants), exclude bystander top-level replies that are not part of the direct chain (those go to step 2)
- Build a `thread_context` array: `[{ position: 1, author: "...", text: "...", created_at: "..." }, ...]`
- Include the original post in its correct thread position
- Note: `thread_context` response may report `has_next_page: true` even when no additional data exists (documented TwitterAPI.io limitation) — paginate only if cursor returns results

If the post has no `conversation_id` or is a standalone post, skip this step. `thread_context` is null.

**2. Reply mining**

Fetch top-level replies to the original post (or to the thread root if it's a thread). These are bystander reactions — not part of the direct conversation chain captured in step 1:

- Use TwitterAPI.io `GET /twitter/tweet/replies?tweetId={root_id}` — returns direct replies, up to 20 per page
- Exclude any authors already present in `thread_context` (their substantive contributions are captured in step 1)
- Sort by engagement (likes + retweets) descending
- Take top N replies (suggest N=10 as default, configurable in pipeline config)
- Filter out obvious noise: replies with no text, pure emoji replies, replies shorter than 20 chars
- Build a `notable_replies` array: `[{ author: "...", text: "...", likes: N, retweets: N }, ...]`

If no replies exist or the API call fails, `notable_replies` is an empty array. Enrichment failure is non-blocking — dispatch proceeds with whatever context was gathered.

**3. Package enriched context**

Replace the current approach of embedding truncated post text in the dispatch `context` field. Instead, write an enriched context file to the investigate directory:

```
_openclaw/feeds/investigate/research-{canonical_id}-context.md
```

Contents:

```markdown
# Research Context: {title or first 80 chars of post}

## Original Post
- **Author:** @{username}
- **Posted:** {created_at}
- **Engagement:** {likes} likes, {retweets} retweets, {replies} replies
- **URL:** https://x.com/{username}/status/{id}

{full post text — no truncation, no ASCII sanitization, UTF-8 encoded}

## Thread Context
<!-- Present only if thread_context is non-null -->
**Conversation thread ({thread_context.length} posts):**

### Post 1 of N — @{author}
{text}

### Post 2 of N — @{author}
{text}

...

## Notable Replies
<!-- Present only if notable_replies is non-empty -->
**Top {N} replies by engagement:**

**@{author}** ({likes} likes)
> {text}

**@{author}** ({likes} likes)
> {text}

...

## Triage Decision
- **Priority:** {priority}
- **Tags:** {tags}
- **Rationale:** {triage rationale}
- **Confidence:** {confidence}
```

**4. Update dispatch request**

The bridge dispatch `description` field references the enriched context file by path instead of embedding post text inline. This addresses the peer review findings about context truncation (OAI-F7), ASCII sanitization data loss (OAI-F6, GEM-F2, DS-F3, GRK-F3), and prompt injection from untrusted content (OAI-F20) — the agent reads full UTF-8 content from a file with clear structural boundaries rather than from an inline string.

The `files` array in the dispatch request includes the enriched context file path (this file exists at dispatch time, unlike the output file — addressing GEM-F1).

---

## Cost Impact

Enrichment adds API calls only on `research` commands — operator-initiated, low volume (estimated 2-5 per day max).

Per enrichment (TwitterAPI.io uniform credit pricing: $0.15/1000 tweets returned):
- Thread expansion: 1 `thread_context` call. Typical self-thread of 5-10 posts: ~$0.00075-0.0015
- Reply mining: 1 `tweet/replies` call. 10 replies: ~$0.0015
- Total per enrichment: ~$0.002-0.003

Estimated monthly cost at 5 researches/day: ~$0.30-0.45. Well within the existing $6 budget ceiling.

---

## Error Handling

- **API failure on thread expansion:** Log warning, proceed with original post only. Set `thread_context: null` and note in context file: "Thread expansion failed — original post only."
- **API failure on reply mining:** Log warning, proceed with empty replies. Set `notable_replies: []` and note: "Reply fetch failed."
- **Rate limiting:** If TwitterAPI.io rate limit is hit during enrichment, dispatch immediately with whatever context was gathered (partial or none). Log the gap. Do NOT retry enrichment after dispatch — the research command is a one-shot operator action and retrying enrichment after dispatch has already gone serves no purpose. The context file notes any missing sections.
- **Both fail:** Dispatch proceeds with the original post text only (current behavior). Enrichment is additive, not blocking.

---

## Schema Changes

### Items table (SQLite)

Verify `conversation_id` is captured during normalization. The normalizer already extracts thread-related fields (§5.3), but confirm `conversation_id` is persisted in the items table, not just used transiently for the `needs_context` heuristic.

### Investigate file frontmatter

Add optional fields:

```yaml
enrichment:
  thread_expanded: true | false
  thread_posts: 8          # number of posts in thread (including non-author direct-chain participants)
  replies_fetched: 10      # number of bystander replies retrieved
  api_calls: 2             # number of TwitterAPI.io calls made (cost derivable from call count)
  enriched_at: "2026-02-25T07:30:00Z"
```

### Pipeline config (config/pipeline.yaml or equivalent)

Add enrichment defaults:

```yaml
enrichment:
  max_replies: 10
  min_reply_length: 20
  enabled: true            # kill switch
```

---

## Implementation Notes

- This runs in the feedback listener process, which is a persistent daemon. Enrichment is async — the listener sends an initial ack to Telegram ("🔍 Researching A01 — expanding thread..."), performs enrichment, then sends a second ack ("Context expanded — dispatching to Crumb...") before dispatch. The second ack confirms enrichment completed and dispatch is underway; omit it if enrichment took <2s (not worth the noise).
- The enrichment step slots between command parsing and bridge dispatch in the existing `handleResearch` flow (or equivalent). No new process or service needed.
- **File naming convention in `_openclaw/feeds/investigate/`:**
  - `research-{canonical_id}-context.md` — enriched context file (written by Tess during enrichment, read by Crumb during research). This is the input to the research task.
  - `research-{canonical_id}.md` — research output file (written by Crumb after research completes). This is the deliverable.
  - The context file persists for auditability — operator can review exactly what Crumb received. Not cleaned up automatically.
- The enriched context file is UTF-8 encoded. The existing pipeline's ASCII sanitization (applied to the dispatch `context` field) does NOT apply to this file — the whole point is preserving full Unicode content for the agent to read from disk.

---

## Files Touched

| File | Action |
|------|--------|
| `src/feedback/feedback-listener.ts` | Add enrichment step in research command handler |
| `src/shared/api-client.ts` | Add `fetchThreadContext()` (wraps `/tweet/thread_context`) and `fetchReplies()` (wraps `/tweet/replies`) |
| `src/shared/normalizer.ts` | Verify `conversation_id` persistence (may already be complete) |
| `config/pipeline.yaml` (or equivalent) | Add enrichment config section |
| Spec §5.8 | Document enrichment step in research command flow |
| Spec §7.5 | Note that thread expansion is implemented for research dispatch (Phase 2 partial) |
| Spec changelog | New version entry |

---

## Resolved Questions

1. **Reply depth:** Top-level replies only for v1. Nested reply-to-reply conversations are noisy and the signal-to-noise ratio drops fast. Revisit if research quality suffers.

2. **Thread filtering:** Direct-chain replies regardless of author (any post where `inReplyToId` points to another post in the chain). This captures genuine multi-author back-and-forth — where the best signal often lives — without pulling in bystander noise. Bystander top-level replies go to the reply mining step (step 2) and are ranked by engagement.

3. **Enrichment for `promote` command:** Deferred. Scoped to `research` only. Promote routes to `_openclaw/inbox/` for triage — a lighter action where single-post context is adequate.

4. **API choice:** TwitterAPI.io. The topic scanner already uses it, the auth pattern (`X-API-Key` header) and HTTP client are already integrated in `api-client.ts`. Two relevant endpoints:
   - `GET /twitter/tweet/thread_context?tweetId={id}` — returns full conversation chain (parents + replies) for any tweet in a thread
   - `GET /twitter/tweet/replies?tweetId={id}` — returns direct replies to a specific tweet, up to 20/page
   - Pricing: uniform $0.15/1000 tweets returned (same as search). No per-endpoint surcharge.
   - `conversation_id:` as a search operator is NOT documented for TwitterAPI.io's search endpoint, but the dedicated `thread_context` endpoint is purpose-built and more reliable.
