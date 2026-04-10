---
type: reference
status: active
created: 2026-03-12
updated: 2026-03-12
domain: null
---

# Learning Plan

Designs phased training plans for skill and knowledge acquisition, grounded in learning science (spaced repetition, deliberate practice, progressive overload). Tailored to skill type and the learner's real constraints.

## /learning-plan

**Invoke:** User mentions "learn", "training plan", "study plan", "how do I get good at", "practice schedule", or asks to develop competence in a skill or domain.

**Inputs:** Skill/topic, current level, target level (specific — not vague), weekly time budget, constraints (equipment, access, budget), motivation type (intrinsic vs. instrumental).

**Outputs:** A vault-native plan document (`[skill]-learning-plan.md`) with phased structure, placed in `Domains/[domain]/` or `Projects/[name]/` depending on scope.

**What happens:**
- Checks vault for existing knowledge on the topic and loads 1-2 relevant learning science digests (Peak, Make It Stick, Ultralearning, etc.)
- Classifies skill type: motor, language, conceptual, applied-technical, creative, or composite — this drives the plan's pedagogical shape
- Asks ≤5 targeted questions to establish current level, target level, time budget, constraints, and motivation type
- Builds a phased plan (2-8 phases depending on depth); each phase has a concrete goal, duration estimate, core activities, spaced repetition integration, feedback loop, and plateau markers
- Writes the plan document with correct frontmatter (`type: plan`, `skill_type`, `target_level`, `weekly_hours`) and optionally includes a Tess check-in integration spec
