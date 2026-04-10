---
project: tess-v2
type: design-input
domain: software
skill_origin: inbox-processor
created: 2026-04-04
updated: 2026-04-04
tags:
  - orchestration
  - external-systems
  - architecture
---

# Pedro Franceschi Autopilot System — Pattern Extraction

**Source:** Core Memory Podcast, Ashley Vance interview with Pedro Franceschi (CEO/co-founder, Brex). Transcript provided by operator 2026-04-04.
**Purpose:** Structured extraction of adoptable patterns mapped against Amendment Z and tess-v2 architecture.

---

## System Overview

Pedro runs Brex (~1,300 employees) through an OpenClaw-based autopilot system he calls "Lemon Pie." The system operates across Telegram (primary interface), Discord (multi-channel sub-agent coordination), and a custom web UI showing all tasks. Voice-first interaction — sends voice notes to OpenClaw while driving, in transit, etc.

---

## Extracted Patterns

### Pattern 1: Signal Injection Pipeline (People + Programs)

**How Pedro does it:** Screens email, Slack, Google Docs, WhatsApp. Filters through two declarative concepts:
- **Programs:** Named initiatives (financial performance, Capital One integration, AI strategy). Each program declares what Pedro cares about and what he doesn't.
- **People:** ~25 declared people in company and personal life, with what he cares about for each.

The pipeline denormalizes signals through these lenses, then produces clean summaries + action items.

**Tess mapping:** Programs = active projects + liberation directive prompts. People would be a new declarative primitive. The dispatch queue (Z1) is downstream of this — signal injection feeds the planning cycle (Z4), which produces the queue.

**Adoptability:** High for programs (already have project-state + liberation directive). Medium for people (new primitive, most valuable for TV2-036 email triage). Not blocked on Z — could be built independently.

**Key quote:** "The question is like what matters, like what to pay attention to."

### Pattern 2: Auto-Resolver

**How Pedro does it:** Action items from signal injection that can execute themselves. Flow: Granola captures meeting → creates action item → auto-resolver checks context from meeting notes → drafts follow-up message → Pedro clicks one button to approve.

**Tess mapping:** This is exactly `dispatch_type: autonomous` in Z1. The auto-resolver is the planning service (Z4) routing autonomous-eligible items for immediate dispatch. The "one button approval" is the intermediate state — not fully autonomous, but minimal-ceremony human gate.

**Adoptability:** Direct. The Z schema already supports this. The `context_files` field in dispatch queue items serves the same role as Pedro's "go back to the notes for context." Implementation is Z4 + autonomous routing.

### Pattern 3: Skills as Composable Blocks

**How Pedro does it:** Reusable patterns like "review a doc as Pedro" — 3-5 standard questions (What's most important? What's the bottleneck? Why aren't we moving faster?). Skills are Lego blocks that compose into workflows within the pipeline.

**Tess mapping:** Crumb's overlay system + skill procedures. Pedro's skills are our overlays (behavioral lenses) + skill definitions (procedures). Already implemented. Validates the composable approach.

**Adoptability:** Already implemented. No action needed. Confirms architecture.

### Pattern 4: Crab Trap (Policy Proxy)

**How Pedro does it:** HTTP proxy with adversarial LLM intercepting all traffic from OpenClaw instances. Routes through policy LLM that screens: "Is this something a recruiter agent should be doing?" Can block requests at network layer. The monitored agent is unaware.

**Key quote:** "The only technology that we think will be able to monitor agents is actually agents themselves."

**Tess mapping:** Phase 4+ gap item in external systems evaluation. Pedro's architecture is concrete: network-layer interception, policy LLM, adversarial agent monitors working agent. Brex plans to open-source this.

**Adoptability:** Future state. Needed when Tess runs unsupervised on external-facing actions (sending messages, making purchases, interacting with external APIs). Not needed during current soak/migration phase. Watch for Brex open-source release.

### Pattern 5: Virtual Employee Pattern

**How Pedro does it:** Full Slack/email personas. "Jim" the recruiter has his own email, Slack identity, engages with human recruiters. Self-bootstrapping — Jim built his own resume screening capability without anyone coding it. Has a human manager on the recruiting team who signs off on actions, gives feedback, sets budget.

**Key design insight:** Virtual employees need the same oversight mechanisms as human employees — a manager, feedback loops, access controls, budget limits. "Firing" (replacing/reconfiguring) when performance is poor.

**Tess mapping:** Long-term vision. Tess as a named entity with defined authority, a manager (Danny), self-bootstrapping capability, and feedback loops (session reports, run_history). The graduated autonomy model in Z is the path toward this — each proven capability class expands her authority.

**Adoptability:** Future state. The Z amendment lays the foundation (structured oversight, dispatch authority, reporting). Full virtual employee pattern requires Tess operating independently across communication channels — post-migration.

### Pattern 6: Voice-First Interaction

**How Pedro does it:** Sends voice notes to OpenClaw while driving, in meetings, in transit. "Best developer experience because it can be like on the way here I was sending voice notes saying change this, change that."

**Tess mapping:** Telegram is already the interface. OpenClaw supports voice notes. Under-leveraged capability in current architecture — Danny interacts primarily via Claude Code (text). Voice interaction would extend operator input surface beyond keyboard sessions.

**Adoptability:** Low priority. Nice-to-have, not load-bearing. The bottleneck is orchestrator authority (Z), not interaction modality.

---

## Patterns Not Adopted

| Pattern | Reason |
|---------|--------|
| Brex virtual card MCP for agent purchases | Different domain — Brex-specific fintech capability |
| Granola meeting transcription | Danny doesn't have the same meeting volume; signal injection from meetings not a current bottleneck |
| Discord for sub-agent coordination | Tess uses Telegram; adding Discord adds channel complexity without clear benefit |

---

## Sequencing Against Amendment Z

| Priority | Pattern | When |
|----------|---------|------|
| Now | Auto-resolver (Pattern 2) | Built into Z4 autonomous routing |
| Z implementation | Signal injection concepts (Pattern 1) | Programs = projects, inform planning cycle |
| TV2-036 | People primitive (Pattern 1) | Most valuable for email triage signal filtering |
| Phase 4+ | Crab Trap (Pattern 4) | When Tess takes unsupervised external actions |
| Post-migration | Virtual employee (Pattern 5) | After Tess proves autonomous reliability |
| Low priority | Voice interaction (Pattern 6) | When interaction modality becomes a bottleneck |

---

## Related Design Inputs

- **Amendment Z** (`design/spec-amendment-Z-interactive-dispatch.md`): Auto-resolver (Pattern 2) maps directly to Z4 autonomous dispatch. People + Programs (Pattern 1) inform the planning service's input model.
- **External systems evaluation** (`design/external-systems-evaluation-2026-04-04.md`): Pedro's Autopilot was one of 10 systems; this extraction goes deeper on the adoptable patterns.
- **Services vs. roles analysis** (`design/services-vs-roles-analysis.md`): Paperclip's "agents as roles" model is the sub-orchestrator layer that sits below Z's orchestrator authority. Pedro's virtual employee pattern (Pattern 5) is the endpoint of that trajectory.

## Provenance

- **Source:** Core Memory Podcast transcript, Ashley Vance / Pedro Franceschi
- **Extraction date:** 2026-04-04
- **Extracted by:** Crumb, mapped against Amendment Z schema
- **Operator direction:** "I need to study Pedro's system more" + "I intend for Tess to be this as well, the best of both worlds"
