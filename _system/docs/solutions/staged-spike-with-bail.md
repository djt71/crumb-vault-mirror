---
type: solution
track: pattern
domain: software
status: active
created: 2026-04-21
updated: 2026-04-21
confidence: high
tags:
  - compound
  - research-methodology
  - evaluation-spike
source_projects:
  - tess-v2
source_artifacts:
  - Projects/tess-v2/design/paperclip-spike-decision-2026-04-12.md
  - Projects/tess-v2/progress/run-log.md
---

# Staged Spike With Bail Checkpoints

## Claim

Research and integration spikes should be structured in explicit stages, with
a **bail checkpoint after Stage 0** that can kill the spike before most of its
budget is spent. A well-framed Stage 0 question concentrates the load-bearing
assumption of the spike into a binary — and when it fails, the remaining stages
are moot, regardless of how well-planned they are.

## Evidence

- **TV2-045 Paperclip integration spike (2026-04-12):** Time budget 4.5 hours.
  Spike structured with Stage 0 = "does a generic Bash/HTTP adapter exist that
  our contract runner can target?" Answer found in ~45 minutes via direct
  `packages/adapters/` inspection: no, all adapters are runtime-specific.
  Result: spike bailed at Stage 0. Effective cost: 45 min vs. 4.5 hr budget.
  ~90% time saved.
- **Peer review of the spike plan** (4 models, all succeeded) validated the
  downstream-stage design. All 4 reviewers accepted the "Bash adapter exists"
  premise because it appeared in secondary-source memos and web search results.
  Only direct package inspection disproved it. Downstream design quality was
  irrelevant once Stage 0 failed — ground truth beat secondhand claims.

## Pattern

1. **Identify the load-bearing assumption.** What single fact, if false, makes
   the remaining spike work pointless? Name it explicitly.
2. **Stage 0 is the verification of that assumption.** Use primary sources —
   direct package inspection, running the tool, reading the code. Not
   secondary sources (memos, blogs, summaries) that may be wrong.
3. **Set a hard bail rule.** If Stage 0 fails, stop. Do not proceed to
   Stages 1+ out of sunk-cost momentum. Write a decision document noting
   what was learned.
4. **Budget Stage 0 at ≤10% of total spike budget.** The cheaper Stage 0 is,
   the higher the expected value of the bail option.

## When to Apply

- Integration spikes against third-party tools/libraries where documentation
  quality is unknown.
- Research evaluating whether a new capability is worth adopting.
- Any task where the worth of doing depends on a specific upstream fact you
  haven't personally verified.
- Paper/blog-driven recommendations where the cited behavior hasn't been
  observed directly.

## When Not to Apply

- Work where the value is in the process, not the outcome (learning exercises,
  deliberate exploration).
- Spikes where the downstream stages have independent value regardless of
  Stage 0's answer.

## Corollary

Peer review of spike *plans* is not a substitute for verifying the spike's
load-bearing assumption. Peer reviewers will often accept premises they haven't
personally checked. Stage 0 is the check that peer review doesn't provide.

## Related

- `_system/docs/solutions/foreign-tool-reveals-native-blind-spots.md` — adjacent
  pattern on using external tools as verification probes
- `_system/docs/solutions/behavioral-vs-automated-triggers.md` — adjacent
  pattern on mechanical verification over memory
