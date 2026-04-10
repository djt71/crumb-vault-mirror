---
type: run-log
project: x-feed-intel
domain: software
created: 2026-02-23
updated: 2026-03-04
---

# X Feed Intel — Run Log

> **Archives:**
> - [[run-log-phase1]] — Project creation through IMPLEMENT deployment (SPECIFY, PLAN, TASK M0-M3, IMPLEMENT live deployment + research dispatch + digest amendment)
> - [[run-log-2026-02]] — Post-deployment operations (refresh command, digest fix, cost overrun, enrichment, bot separation, compound routing)

---

## 2026-03-08 — Decommissioned in Favor of FIF

### Context
Full feature parity evaluation confirmed FIF X adapter has complete coverage of all x-feed-intel
core capabilities plus improvements (thread collapsing, URL collision detection, multi-source
orchestration). Three minor gaps identified (research command, refresh command, enrichment module)
— all low-frequency power-user features, not blockers.

### Actions
1. **LaunchAgents disabled:** `ai.openclaw.xfi.capture` and `ai.openclaw.xfi.attention` bootout'd.
   `ai.openclaw.xfi.feedback` was already disabled (2026-03-04g).
2. **Plist files removed:** All 3 xfi plists deleted from `~/Library/LaunchAgents/`.
3. **Credentials shared:** FIF reuses `x-feed-intel` Keychain service prefix — no credential
   migration needed. Both systems use the same `@xfeed_crumb_bot` token.
4. **Topic config:** `ai-workflows` topic was intentionally removed from FIF (overlaps with
   agent-architecture and claude-code). No gap to restore.
5. **DB state:** 1,397 posts in x-feed-intel DB, 804 overlapping with FIF. Non-overlapping
   593 posts are historical — no migration needed (FIF has its own capture history).
6. **FIF dedup hardened:** `normalizeCanonicalId()` and `bareNativeId()` added to FIF dedup
   engine (commit pending). Handles bare-ID ↔ prefixed-ID format mismatches defensively.
7. **Project state:** Phase set to DONE.

### Soak Evidence
- FIF X adapter operational since 2026-03-05 (soak day 1)
- X and RSS digests delivering daily without legacy pipeline
- Cost within estimates ($0.30 total soak as of day 2)
- Feedback listener handles both legacy and new digest replies via `id_aliases`

### Decom Gaps Accepted
- `research` command (bridge dispatch + enrichment): low usage, can be added to FIF later
- `refresh` command (on-demand pipeline via Telegram): CLI fallback available
- Thread enrichment (context + replies): only used by research command

### Compound
- **Pattern confirmed:** Feature parity evaluation before decom is essential. The 804-tweet
  overlap (58% of x-feed-intel corpus) validated that FIF processes the same content.
  Dedup hardening (normalizeCanonicalId) is defense-in-depth — no runtime issue exists
  since both systems have separate DBs, but migration safety is guaranteed.
- **Convention:** When decommissioning a predecessor system, keep the repo for reference
  but don't archive the vault project if it has active knowledge graph content. x-feed-intel
  has only project mechanics (specs, plans, tasks) — archival candidate per §4.6.

---

## 2026-03-04 — Stale State Cleanup

### Actions
- Checked compound insight routing status: all 6 research outputs already routed (2026-02-25). `next_action` was stale — removed "Route 4 pending compound insights."
- **Stale project-state pattern:** second project found today with outdated `next_action`. Indicates session-end sequences aren't consistently refreshing project-state when work completes mid-session.

---
