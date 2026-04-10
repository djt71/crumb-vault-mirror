---
type: reference
status: active
created: 2026-03-12
updated: 2026-03-12
domain: null
---

# Attention Manager

Overview: Curates a daily attention plan or monthly review by reading across vault sources and applying Life Coach + Career Coach lenses. Produces an opinionated short list of what deserves focus — not a task manager.

## /attention-manager

**Invoke:** "plan my day", "daily attention", "what should I focus on", "monthly review"
**Inputs:** goal-tracker.yaml, SE inventory, personal-context.md, life-coach overlay, personal-philosophy.md, career-coach overlay; most recent daily artifact (daily mode only)
**Outputs:** `_system/daily/YYYY-MM-DD.md` (daily) or `_system/daily/review-YYYY-MM.md` (monthly)

**What happens (daily):**
- Loads context and scans all active project `next_action` fields
- Infers SE obligation due dates from cadence annotations + recent completion history
- Carries forward unchecked Focus items with day counts; escalates items deferred 5+ days
- Applies Life Coach (values, whole-person, "enough" test) and Career Coach (skill leverage, opportunity cost) lenses
- Writes 5-8 Focus items with Why now / Domain / Source; includes Domain Balance, Carry-Forward, Deferred, and Goal Alignment sections

**What happens (monthly):**
- Pre-processes all daily artifacts for the month into a structured digest (domain counts, carry patterns, completion rate, SE coverage)
- Analyzes patterns against goals, SE cadence, and both overlay lenses
- Writes monthly review artifact and proposes goal-tracker updates — does not modify goal-tracker.yaml without explicit operator confirmation

## Modes

**Daily** — on-demand curation for today. Budget: standard (5 docs). Cost ~$0.60 / 2 min.
**Monthly** — retrospective synthesis over all daily artifacts. Budget: extended (7-8 docs). Cost ~$0.90 / 3 min. Invoke at month-end to review patterns and update goals.
