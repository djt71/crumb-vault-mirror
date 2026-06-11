---
type: design
project: agentic-sunset
domain: software
status: active
created: 2026-06-11
updated: 2026-06-11
topics:
  - moc-crumb-operations
tags:
  - decommission
  - verification
---

# Scheduler Product Verification — Cowork vs. Routines (AS-023 input)

Re-verification of April 2026 product claims against current primary docs (2026-06-11),
per the verification list in `_system/docs/work-surfaces.md`. Input to the AS-023
substrate choice. Method: two parallel research agents against primary Anthropic
documentation (code.claude.com, support.claude.com, GitHub issue tracker); citations in
source notes below.

## Verdict for AS-023

**The pass strengthens the Cowork-scheduled tilt, with one new design obligation.**

- Cowork scheduled tasks: local execution with live filesystem access **confirmed**;
  machine-awake + app-open requirement confirmed, with 7-day catch-up auto-rerun on
  wake (moot on the always-on Studio). Sub-hour intervals available via `/schedule` or
  natural language (UI picker floor is 1 hour). Cowork went GA (all paid plans).
- **Cowork does NOT read a folder's CLAUDE.md** (issue #30530 closed *as not planned*)
  **and does NOT fire Claude Code lifecycle hooks** (issue #63360 open). New design
  obligation: the AS-023 scheduled-task prompt must be self-contained — carry its own
  frontmatter template and conventions; nothing can be inherited from CLAUDE.md.
- **The mechanical guard holds for Cowork:** git pre-commit hooks (vault-check) DO fire
  when Cowork runs `git commit` — hooks live in `.git/hooks`, not the harness. The
  write-boundary ADR's Class 1 rule (writer commits immediately) is therefore
  enforceable as designed.
- **The mechanical guard does NOT hold for Routines:** cloud runs work on a fresh clone
  — local `.git/hooks` don't exist there, so vault-check cannot fire cloud-side.
  Routines' default write path (`claude/`-prefixed branch + PR) compensates via operator
  review; the opt-in "Allow unrestricted branch pushes" would permit direct pushes
  **without any vault-check** — do not enable it for crumb-vault.
- Routines otherwise stable since April: cloud execution, Pro+, research preview,
  1-hour cron floor, API + GitHub triggers, connectors-only MCP, autonomous runs.
  One new note: GitHub-trigger events have per-routine/per-account hourly caps during
  preview.

Net: for a daily artifact in `_system/daily/` (Class 1 drop zone), Cowork-scheduled
offers direct live-vault write with vault-check enforcement at commit; Routines offers
either daily PR ceremony (adoption-suppressing) or unguarded direct push (rejected).
Routines remains the right surface for machine-independent or repo-read-only cadence
work where PR-mediated output is natural.

## Findings vs. April claims

### Cowork

| Claim (April) | Status (June) |
|---|---|
| Scheduled tasks local; Mac awake + app open; skip + auto-rerun on wake with notification | Confirmed (7-day catch-up window) |
| 1-minute minimum interval | Confirmed with caveat: UI picker floor 1 hour; 1-minute via `/schedule`/natural language |
| Single-device lock (issue #43698) | Confirmed; still open, no Anthropic response — the Studio is the Cowork device |
| All paid plans | Confirmed; GA (reported 2026-04-09) |
| Live local filesystem access in scheduled tasks | Confirmed |
| Honors folder CLAUDE.md | **No** — Desktop project-level CLAUDE.md request closed *not planned* (#30530) |
| Fires Claude Code hooks (settings.json lifecycle) | **No** (#63360 open); git `.git/hooks` DO fire on Cowork-run git commands |
| Memory mechanism | Same Agent SDK as Claude Code; persistent project memory exists; whether it shares `~/.claude/projects/<project>/memory/` not explicitly documented — observe in pilot |
| Built on Claude Code harness | Confirmed (Agent SDK) |

### Routines

| Claim (April) | Status (June) |
|---|---|
| Anthropic cloud; runs with machine off | Confirmed |
| Pro/Max/Team/Enterprise; research preview | Confirmed (still preview, no GA timeline) |
| Triggers: cron (1h floor), API `/fire` + bearer token, GitHub PR/release | Confirmed; no new trigger types; GitHub events capped hourly during preview |
| Fresh git clone per run; no local filesystem | Confirmed |
| Writes via `claude/` branches + PR | Confirmed default; "Allow unrestricted branch pushes" opt-in exists (rejected for crumb-vault — bypasses vault-check) |
| Connectors-only MCP | Confirmed |
| Autonomous, no approval prompts | Confirmed |

## Source notes

Primary: code.claude.com/docs/en/routines · code.claude.com/docs/en/desktop-scheduled-tasks ·
support.claude.com/en/articles/13854387 · support.claude.com/en/articles/13345190 ·
code.claude.com/docs/en/memory · code.claude.com/docs/en/agent-sdk/overview ·
github.com/anthropics/claude-code issues #43698 (open), #30530 (closed not planned),
#63360 (open).

Confidence: high on scheduling mechanics and write models (direct doc quotes); medium on
Cowork memory internals (not explicitly documented — pilot observation item); the
CLAUDE.md finding is inferred from the closed feature request plus absence of any
primary-doc support claim.
