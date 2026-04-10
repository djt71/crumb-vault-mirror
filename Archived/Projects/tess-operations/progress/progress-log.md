---
project: tess-operations
type: progress-log
created: 2026-02-26
updated: 2026-02-26
---

# tess-operations — Progress Log

## 2026-02-26 — Project Created

Project scaffolded from inbox intake. Three Tess-authored design documents imported to `design/`. Entering SPECIFY phase for Crumb-side validation.

## 2026-02-26 — SPECIFY Complete → PLAN

Four specs validated through Crumb review + two rounds of peer review (8 external models). Total findings resolved: chief-of-staff (3+4), Google services (1 blocking + 8), Apple services (1 blocking + 8), comms channel (3+6), plus 11 synthesis amendments. Specification summary created for PLAN phase. All specs strengthened with: standardized approval contract, cross-spec MVP matrix, global kill-switch, per-job token budgets, email send technical enforcement, HEARTBEAT scope cap.

## 2026-03-16 — Approval Contract + Reminders Write + Discord Mirroring

Three tasks completed in one session, unblocking Phase 2 gate:

- **TOP-049 (Approval Contract protocol):** 5 scripts, filesystem-based AID-* protocol, dedicated Telegram approval bot (@tess_approvals_bot) with inline buttons, 48h expiry, anti-spam batching, 5-min cooldown, audit trail. 10/10 acceptance tests. Gates TOP-032/036/037/043.
- **TOP-032 (Reminders write):** `reminder-write.sh` with autonomous add (Inbox/Agent) and approval-gated add (other lists) + complete. Generic `approval-executor.sh` dispatches payloads after approval. `approval-check.sh` extended with `--validate-only` (action-before-mark pattern). 8/8 tests.
- **TOP-034 (Discord mirroring):** `discord-post.sh` webhook library (post/edit/graceful-skip). Approval contract mirrors to #approvals with message ID correlation + edits on decision. Audit entries to #audit-log. E2e verified.

43/56 tasks done. TOP-035 (Phase 2 gate eval) now unblocked — all 4 deps satisfied.

## 2026-02-27 — PLAN Complete → TASK

Action plan decomposed into 9 milestones and 52 tasks. Two rounds of peer review (Crumb-dispatched: GPT-5.2, Gemini, DeepSeek, Grok; Tess-dispatched: DeepSeek, Gemini, ChatGPT, Perplexity + independent Opus review). Key additions from review: Approval Contract protocol (TOP-049), Ops Metrics harness (TOP-050), cron guardrails infrastructure (TOP-051), feed-intel parallel verification (TOP-052). Critical path: 8-12 weeks M0→M6. Beginning M0 infrastructure foundation.

## 2026-03-29 — DONE

**Final task resolution:** 59 tasks total — 55 done, 4 dropped. Last three blockers (TOP-057/058/059) cleared in one session.

**Scope delivered (9 milestones):**
- **M0:** Infrastructure foundation — cron-lib, LaunchAgents, monitoring, Telegram delivery
- **M1:** Morning briefing — email triage, calendar (Google+Apple), reminders, daily attention plan, pipeline health, feed signals, Discord mirroring, context refresh
- **M2:** Email triage — Haiku-based classification, Gmail label routing, soak-validated (108 runs, 0 failures, $0.17)
- **M3:** Apple services — Reminders read/write, Calendar read, Notes read (all via snapshot architecture)
- **M4:** Google services — Gmail, Calendar, Drive scope validation
- **M5:** Comms channels — Telegram (primary), Discord (mirror), approval contract protocol
- **M6:** Phase 2 gate + Phase 3 gate — passed with scope adjustments
- **Late additions:** Overnight research (reactive + scheduled streams), daily attention cron, session prep, feed-intel ownership transfer

**Key architectural decisions that held:**
- Snapshot architecture for cross-user Apple data (LaunchAgent in danny's domain → shared files)
- Option A cron model (script orchestrates, agent synthesizes — not the reverse)
- Filesystem-based approval contract (AID-* protocol)
- DB-direct pattern for FIF data access (validated when file-based coupling broke)

**What was dropped:** TOP-038 (Apple Calendar write — TCC complexity), TOP-039 (Apple Notes write — same), TOP-043 (Phase 3 Apple — dropped phase), TOP-052 (FIF parallel verification — unnecessary ceremony)

**Maintenance note:** Overnight research scheduled streams re-enabled today — first live run tonight (Sunday competitive rotation). Monitor tomorrow's briefing for results.
