---
type: progress-log
project: obsidian-applenotes-import
domain: software
created: 2026-04-25
updated: 2026-04-25
---

# Obsidian Apple Notes Import — Progress Log

## 2026-04-25 — Project creation

- Scaffold created (vault + external repo at `~/code/obsidian-applenotes-import/`)
- Pre-SPECIFY decisions: AppleScript access, soft-delete only, four-phase workflow
- Phase: SPECIFY (pending systems-analyst invocation)

## 2026-04-25 — SPECIFY artifact frozen at rev 3 (later superseded by rev 4)

- Rev 1: initial systems-analyst output (23 tasks, MAJOR scope)
- Rev 2: round-1 peer review (4-model panel) → 10 must-fix + 18 should-fix applied
- Rev 3: round-2 peer review → 15 must-fix + 14 should-fix applied; verdicts split 2 READY / 2 ONE MORE ROUND (calibration, not direction)

## 2026-04-25 — Pre-PLAN probes; spec rev 4 (SPECIFY done)

- G1 (soft-delete) ✅ validated 2026-04-25 / macOS 26.3.1
- G2 (note id stability) ✅ validated 2026-04-25 / macOS 26.3.1; bonus findings: Apple Notes auto-renames from body heading; `folder of note` not queryable
- G3 (attachment extraction): could not validate empirically (user library has 0 attachment-bearing notes; spec's filesystem-cache path hypothesis was wrong for macOS 26.x); operator chose to **drop attachments from v1** (Option C) → attachments deferred to v1.1
- G4 (citation pin) ✅ resolved 2026-04-25
- Rev 4: spec rewrite reflecting v1.1 attachment deferral; LD-07 reversed; AC3/AC5/AC11 simplified; new AC12 (attachment-loss communication); OAI-008a/008b removed; risk register simplified
- 25 tasks across 8 milestones (was 27)
- All pre-PLAN gates resolved
- Phase: SPECIFY (frozen artifact; ready for PLAN)
