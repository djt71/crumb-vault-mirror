---
type: review
review_type: project-audit
review_mode: full
scope: project-complete
project: active-knowledge-memory
domain: software
skill_origin: external-review
created: 2026-03-03
updated: 2026-03-03
status: active
reviewer: anthropic/claude-opus-4-6
cross_check: crumb/claude-opus-4-6
tags:
  - review
  - audit
  - akm
---

# Active Knowledge Memory — Project Audit & Peer Review

**Reviewer:** Claude Opus 4.6 (external session, full project materials read)
**Cross-check:** Crumb (main session, verified against implementation artifacts)
**Scope:** Full project lifecycle audit — specification through validation, code, design docs, process adherence
**Materials reviewed:** 18 files (specification, spec summary, action plan, 7 design docs, 2 reviews, run-log, progress-log, project-state, knowledge-retrieve.sh, 3 skill integrations, session-startup.sh integration)

---

## Executive Summary

This is a well-executed project. The problem was correctly identified, the solution is architecturally sound, the implementation is functional, and the process discipline is strong. AKM shipped in ~6 sessions (matching the estimate) and delivered working proactive knowledge surfacing across three integration points with zero noise in validation.

That said, there are genuine weaknesses worth documenting — some in the implementation, some in the evaluation methodology, and some in process choices that traded thoroughness for speed. None are project-threatening, but several should be addressed before this system runs unattended for months.

**Overall grade: Strong.** The project did what it set out to do and did it cleanly. The criticisms below are calibration, not condemnation.

---

## 1. Specification Quality

### Strengths

The spec is unusually thorough for a personal project. The problem statement is crisp, the system map is clear, the task decomposition has real acceptance criteria, and the phased delivery plan is disciplined. The decision to establish personal writing conventions before any personal writing exists is the kind of forward-thinking that prevents migration pain later.

The surfacing modality framework (proactive / ambient / batched) is a genuinely useful abstraction. It's not just scheduling — it determines the delivery contract. This is reusable beyond AKM and the compound evaluation correctly flagged it as a potential solutions doc.

The spec evolution from FTS5-first to QMD-promoted-to-v1 was handled well. The QMD promotion was justified by external production evidence, the operator approved it, and the spec was updated comprehensively rather than patched ad hoc.

### Weaknesses

**The spec's "Facts" section conflates measured, assumed, and cited-without-source.** The peer review caught this (all 4 reviewers flagged unverifiable claims), and the fix was "add citations or downgrade language." Looking at the final spec, the LoCoMo benchmark claim still says "74% with basic operations" without a citation. The Anthropic contextual retrieval claim now says "reduced failed retrievals by 49-67%" with a URL but no caveat about dataset specificity. These aren't decision-critical (the phased approach validates empirically), but the spec reads with more confidence than the evidence warrants. Minor point.

**AKM-010/011 deferral is the right call but the activation signal is vague.** "Post-AKM-012 assessment of whether tess_scratch brief suffices" — suffices for what? There's no defined criteria for when Tess needs more than the lightweight scratch file. This means the deferral is effectively permanent unless someone remembers to revisit it with a specific question. If that's the intent, fine — but it should be stated as such rather than leaving a dangling "activation signal."

### Peer Review Process Assessment

The 4-model peer review was well-structured. The synthesis is the strongest part — the coordinator didn't just aggregate findings, they evaluated them, declined incorrect ones (ANT-F1 on `tr '\n'`), and resolved contradictions (personal writing boost timing). The 9 action items applied to the spec are substantive and traceable.

One observation: all 4 reviewers flagged "zero ceremony" as overstated, but the fix was wordsmithing ("no recurring manual actions during normal sessions"). The deeper issue — that the system adds new failure modes that require monitoring — wasn't fully addressed. The feedback JSONL logging is a step, but there's no defined mechanism for *acting on* that feedback data. This connects to Finding F3 below.

---

## 2. Action Plan & Execution

### Strengths

The action plan is clean. Milestones are well-scoped, dependencies are explicit, the critical path is identified, and work packages group naturally. The 6-session estimate was accurate (a rarity). The pinned decisions (D1–D6) carry forward SPECIFY-phase resolutions without re-litigating them — this is good process discipline.

The decision to skip peer review for mechanical tasks (AKM-005/006/007/008) was correct. The compound evaluations at each session boundary are consistently useful — the "infrastructure script + thin integration" pattern observation is validated three times and genuinely describes the architecture.

### Weaknesses

**The entire PLAN → TASK → IMPLEMENT sequence happened in a single day (2026-03-02).** The run-log shows specification on March 1, then everything else — PLAN, all three milestones, evaluation gate, tuning, and validation — on March 2. This is fast, and speed isn't inherently bad, but it means there was no gap between designing and implementing. No overnight reflection, no chance for the spec to be stress-tested by a day of other work. For a system that's supposed to run continuously and unattended, this is noted but **mitigated by process** — the spec had already been through 4 external reviewers and 52 findings before implementation began. The peer review process served the stress-test function that elapsed time would normally provide.

**The evaluation gate (AKM-EVL) and validation (AKM-012) share a methodological weakness: the same person who designed the system designed the tests.** This is unavoidable in a single-operator system, but it means the test queries are biased toward the designer's mental model of what should work. The EVL noted this partially ("expectation quality caveat") but didn't fully reckon with it. More on this in Finding F4.

---

## 3. Implementation Audit

### knowledge-retrieve.sh (797 lines)

**Architecture:** The script is well-structured. Signal construction → QMD query → post-filter → format → feedback logging is a clean pipeline. The per-trigger mode routing is data-informed (from AKM-EVL). The env-var-based Python data passing (A3 fix from code review) is the right approach.

**Code review was thorough.** The 2-reviewer panel (Opus + Codex) found genuine issues. The dedup file scoping bug (PID-based → date-based) was a real functional defect. The shell-to-Python injection fix via env vars was necessary. The dead code removal (959 → 749 lines, then grew to 797 during AKM-009 mode routing + FTS5 fallback) shows cleanup discipline.

### Findings

**F1 [SIGNIFICANT] — The dedup file is date-scoped, not session-scoped.**

The original code review correctly identified that PID-scoped dedup was broken. The fix changed it to date-based: `/tmp/akm-surfaced-$(date +%Y%m%d).txt`. This means dedup works *within* a day but resets at midnight. It also means that items surfaced in a morning session will be suppressed in an afternoon session — even though those are separate Claude Code sessions with separate context windows. The design doc (brief-format.md) still says "session-scoped" and references `$$` in the dedup explanation, which is now stale.

The real question: what does "session" mean here? A Claude Code session? A calendar day? The current behavior (daily) is arguably better than PID-scoped (per-invocation) but doesn't match the documented intent. If you have two sessions in a day, the second one will never surface items the first one found — even though the second session has no memory of the first.

> **Cross-check (Crumb):** Confirmed. Line 18: `DEDUP_FILE="/tmp/akm-surfaced-$(date +%Y%m%d).txt"`. The comment on line 418 says "session-scoped, date-based key" — the code author was aware of the mismatch and tried to bridge it with a comment, but never updated the design doc (brief-format.md line 145 still says `$$`).

**Recommended action:** Document the current behavior explicitly. If daily scope is intentional, update brief-format.md. If per-session is actually desired, consider an environment variable (e.g., `AKM_SESSION_ID`) that the session-startup script sets.

**F2 [SIGNIFICANT] — The embedded Python block is still not extractable or testable.**

The code review flagged this as D1 (deferred: extract Python to standalone `akm_postfilter.py`). It's 300+ lines of Python embedded in a bash heredoc. The deferral rationale was "do when script needs major changes." The problem is that this block contains all the ranking, diversity, decay, and formatting logic — the core intellectual content of the system. It cannot be unit-tested, linted with mypy, or debugged with a Python debugger. Any future tuning (new decay categories, adjusted boost values, changed diversity rules) requires editing Python inside bash.

This isn't blocking today, but it's the single biggest maintainability risk in the project. The code review correctly identified it; the deferral was reasonable at ship time; but it should be high on the maintenance queue.

> **Cross-check (Crumb):** Confirmed. Lines 444–765 are a single Python heredoc — ~320 lines of ranking, decay, diversity, summary extraction, and formatting logic.

**F3 [SIGNIFICANT] — Feedback logging exists but nothing consumes it.**

`akm-feedback.jsonl` records every surfacing event (timestamp, trigger, paths, cross-domain flag). The brief-format.md describes a session-end diff against read-files to determine hit rate. But looking at the session-end protocol integration, only `qmd update` was added (line 4). There's no step that reads the feedback log, diffs against actually-read files, or computes hit rate.

This means the feedback mechanism is write-only. The validation (AKM-012) measured hit rate manually during the test session, but there's no automated feedback loop for ongoing operations. The spec's success criterion #7 ("After 10 sessions, the operator hasn't disabled or started skipping the knowledge brief") has no instrumented measurement. You'd need to remember to check the JSONL file and manually correlate.

> **Cross-check (Crumb):** Confirmed. Session-end protocol (step 4) only has `qmd update`. No feedback consumption step exists. brief-format.md lines 157-159 describe the read-file diff mechanism that was never implemented.

**Recommended action:** Either implement the read-file diff at session end (as designed), or acknowledge this as deferred and add a ticket/note. The current state is a half-built feedback loop.

**F4 [MINOR] — FTS5 fallback path is untested in practice.**

AKM-009 added an FTS5 fallback via Obsidian CLI. The code path is ~20 lines of Python that converts Obsidian search results to QMD-like JSON. The validation (AKM-012) didn't test this path — all scenarios ran against live QMD. The code constructs `qmd://sources/` and `qmd://domains/` prefixed paths, which the downstream Python post-filter will then try to resolve. If the Obsidian CLI output format doesn't match the expected structure, this fallback fails silently (returns `[]`).

Low risk because QMD is the primary path and should always be available on the Mac Studio. But if you ever need the fallback, discovering it's broken at that moment would be frustrating.

**F5 [MINOR] — Personal writing boost is tested in code but never exercised.**

The `check_personal_writing_boost()` function is implemented, the daily cache works, and the threshold (≥3 notes) is correct. But with zero `type: personal-writing` notes in the vault, this code path has never run with `active` status. The validation explicitly notes this: "logic implemented, activates at ≥3." When personal writing arrives, the first time this activates will be the first real test. This is acceptable — it's forward-looking by design — but worth noting as an unexercised path.

**F6 [MINOR] — Domain-concept mapping is hard-coded and acknowledged as a workaround.**

The `build_session_start_signal()` function maps project domains to concept terms via a static `case` statement. The compound evaluation correctly flags this: "The map is hard-coded and won't adapt to new domains or evolving project focus." The EVL results showed session-start produced 0 items in validation (empty brief). The hypothesis is that hybrid mode's query expansion will help, but session-start *is* hybrid and still produced nothing.

The run-log says this will improve as more signal-notes accumulate and the mapping is tuned. That's plausible, but there's no mechanism to detect when tuning is needed (connects back to F3 — feedback loop is write-only).

### Integration Points

All three integration points are minimal and well-isolated:

- **Session startup** (lines 196-199): 4 lines, failure-isolated with `2>/dev/null || KB_BRIEF=""`. Clean.
- **Systems-analyst / action-architect** (1 line each): Additive sub-step, clearly documented as ambient, counts against context budget. Clean.
- **Feed-pipeline** (step 8): 6 lines, graceful skip on empty. Writes to tess_scratch. Clean.

No concerns with the integrations themselves. The "infrastructure script + thin integration" pattern works as advertised.

---

## 4. Evaluation Methodology

### QMD Mode Evaluation (AKM-EVL)

The test design is reasonable: 12 queries, 3 modes, blinded expectations, 36 total searches. The findings are genuinely useful — "modes are complementary, not interchangeable" is a better conclusion than the spec anticipated.

**Weakness: 4 of 30 expected results were impossible (authors not in corpus).** The evaluation caught this post-hoc and noted it as a caveat, but it means 13% of the test fixtures were invalid. For a 12-query evaluation, that's a non-trivial error rate in test design. The blinded approach is correct (prevents post-hoc rationalization), but the corpus inventory should have been done first.

> **Cross-check (Crumb):** The evaluation self-corrected by catching and accounting for the gap. This is evidence the methodology works, not evidence it's broken. The reviewer acknowledged this: "I was double-penalizing — flagging the error and under-crediting the recovery."

**Weakness: the 32% cross-domain score triggered the "all modes miss >40% → investigate" criterion, but investigation was light.** The decision criteria said to investigate indexing or query construction. The actual investigation was: "digest quality drives recall more than mode choice" (noted) and three items tracked for AKM-009 (chapter-digest indexing, min-score thresholds, manual query expansion). These are hypotheses, not investigations. The fundamental question — "are the book digests rich enough for semantic search to find cross-domain connections?" — wasn't answered.

### End-to-End Validation (AKM-012)

7 scenarios is a small sample. The 71% hit rate (5/7) passes the 60% target, but with N=7, the confidence interval is wide. One more empty result and you're at 57% (fail). The validation acknowledges this implicitly ("extend to 5 sessions if borderline") but didn't extend.

**The SLO soft-fail was accepted by adjusting the SLO rather than fixing the latency.** New-content hybrid averages 7s against a 5s SLO. The justification (batch context, operator already waiting) is reasonable. The original 5s SLO was a pre-implementation hypothesis; adjusting to 10s based on actual measurement and operational context (batch, not interactive) is calibration, not generosity. The tuning decisions doc shows cold-start new-content at 15.35s — that's 3× the original SLO. The "warm" number (1.70s) depends on a prior hybrid call in the same session loading the model.

> **Cross-check (Crumb):** Pre-implementation SLOs are hypotheses. The reviewer agreed: "Adjusting to 10s based on actual measurement and operational context is calibration, not generosity."

**The solutions-linkage assessment is well-reasoned.** AKM and solutions-linkage are correctly identified as complementary. No action needed.

---

## 5. Process & Documentation

### Strengths

The run-log is excellent — detailed, chronological, honest about what worked and what didn't. Compound evaluations at each session boundary are consistently insightful. The progress-log provides a cleaner summary for quick reference. The project-state.yaml is properly updated to DONE with correct metadata.

The design docs form a coherent set: problem statement → companion notes → spec → action plan → focus signal → brief format → QMD reference → collections → mode evaluation → tuning decisions → validation results. Each document has a clear purpose and doesn't duplicate others unnecessarily.

### Weaknesses

**F7 [MINOR] — brief-format.md's dedup description is stale.** It still references `/tmp/akm-surfaced-$$.txt` (PID-scoped), but the implementation now uses `/tmp/akm-surfaced-$(date +%Y%m%d).txt` (date-scoped). Minor documentation drift, but this is a design doc that future implementers would reference.

> **Cross-check (Crumb):** Confirmed. brief-format.md line 145.

**F8 [MINOR] — The spec summary wasn't updated after EVL/tuning.** It still says "QMD mode evaluation gate after Milestone 1 + book pipeline landing (~300 books, ~1 week)" — the evaluation is done and the answer is per-trigger routing. The summary should reflect final state, not planning-time language.

> **Cross-check (Crumb):** Confirmed. Spec summary line 42.

**F9 [OBSERVATION] — All code review findings were self-reviewed.** The code review panel (Opus + Codex) found issues, but the coordinator who synthesized findings, decided severity, applied fixes, and verified results was the same Crumb session that wrote the code. This is the nature of a single-operator system, but it's worth noting that the reviewer and the reviewed are structurally the same agent. The ANT-F1 declination (correctly identifying an incorrect finding) demonstrates value in the coordinator role, but a truly independent code review would have a different operator evaluating the synthesis.

---

## 6. Deferred Items & Open Risks

| Item | Risk | Comment |
|------|------|---------|
| AKM-010/011 (Tess KB advisory) | Low | tess_scratch brief is a reasonable lightweight path. Activation signal is vague but not urgent |
| D1: Extract Python to standalone file | Medium | Single biggest maintainability risk. Every future tuning change requires editing Python in bash |
| Feedback loop completion | Medium | Write-only JSONL with no consumption mechanism. Can't measure whether the system is being ignored |
| Session-start empty brief | Low | Known limitation. Domain-concept mapping is a workaround. Will improve with more content, but no mechanism to detect when tuning is needed |
| Test suite (CDX-F9 deferred) | Low | No automated tests for core ranking/diversity logic. Acceptable for v1 but creates regression risk on any future change |
| EVL regression fixtures at /tmp | Low | Preserved at `/tmp/akm-evl/` — will be lost on reboot. Should be copied to vault if regression testing is planned |

---

## 7. Summary of Findings

| ID | Severity | Finding | Recommendation | Cross-check |
|----|----------|---------|----------------|-------------|
| F1 | SIGNIFICANT | Dedup is date-scoped, not session-scoped; design doc is stale | Document actual behavior; consider `AKM_SESSION_ID` env var | Confirmed |
| F2 | SIGNIFICANT | 300+ lines of embedded Python untestable/unlintable | Extract to `akm_postfilter.py` (high priority for maintenance queue) | Confirmed |
| F3 | SIGNIFICANT | Feedback JSONL is write-only; no consumption mechanism | Implement session-end read-file diff or explicitly defer with tracking | Confirmed |
| F4 | MINOR | FTS5 fallback untested with real Obsidian CLI output | Test manually once; low risk since QMD is primary | Confirmed |
| F5 | MINOR | Personal writing boost never exercised with active status | Acceptable; will self-test when content arrives | Confirmed |
| F6 | MINOR | Session-start empty brief with no detection for when tuning is needed | Connects to F3; feedback loop would surface this | Confirmed |
| F7 | MINOR | brief-format.md dedup description references old `$$` approach | Update doc to match implementation | Confirmed |
| F8 | MINOR | Spec summary uses planning-time language post-completion | Update to reflect final state | Confirmed |
| F9 | OBSERVATION | Self-review structure (author = coordinator = reviewer) | Inherent to single-operator system; noted, not actionable | Confirmed |

### Priority Order (agreed by reviewer and cross-checker)

1. **F3** (feedback loop) — most impactful, enables detection of F6 and system degradation
2. **F7/F8/F1** (doc staleness) — quick cleanup pass, ~15 minutes
3. **F2** (Python extraction) — schedule for next time the script needs changes

---

## 8. Verdict

AKM v1 is a solid piece of work. It identified a real problem (passive KB), chose a pragmatic solution (QMD + thin integrations), executed cleanly (11 tasks, 6 sessions, on estimate), and validated with real data (71% hit rate, zero noise). The process discipline — spec-first, peer review, code review, compound evaluations — is well above the bar for a personal system.

The three significant findings (F1–F3) are all about operational sustainability rather than correctness. The system works today. The question is whether it degrades gracefully over months of operation without anyone actively monitoring it. The feedback loop gap (F3) is the most important item to address — it's the mechanism that would tell you whether the other issues matter.

The embedded Python (F2) is the biggest maintainability debt. It's not urgent, but every future change to ranking or diversity logic will be more painful than it needs to be until it's extracted.

Overall: ship it, address F3 soon, schedule F2 for when the script next needs changes, and update the stale docs (F1/F7/F8) in a quick cleanup pass.

---

## Appendix: Cross-Check Adjustments

The following reviewer assessments were revised after cross-check discussion:

**§2 "Single day" concern** — Revised from "mild concern" to "noted, mitigated by process." The spec had been through 4 external reviewers and 52 findings before implementation began. The peer review process served the stress-test function that elapsed time would normally provide.

**§4 EVL invalid fixtures** — Revised assessment. The evaluation self-corrected by catching and accounting for the gap. Self-correction during evaluation is evidence the methodology works. The original framing double-penalized: flagging the error and under-crediting the recovery.

**§4 SLO adjustment** — Revised from "generous" to "calibration." Pre-implementation SLOs are hypotheses. Adjusting based on actual measurement and operational context is standard engineering practice.

**§3 Line count** — Clarified: 959 → 749 post-code-review, then grew to 797 during AKM-009 (mode routing function, FTS5 fallback path). The reviewer acknowledged this gap should have been noted rather than leaving the inconsistency.
