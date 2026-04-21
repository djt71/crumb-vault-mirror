---
project: null
domain: cross-cutting
type: pattern
skill_origin: writing-coach
status: active
track: convention
confidence: high
created: 2026-02-15
updated: 2026-04-04
topics:
  - moc-writing
tags:
  - writing-pattern
  - quality
  - kb/writing
---

# AI Telltale Anti-Patterns

**Reference document for the writing-coach skill.**
Load when reviewing text intended for external audiences, formal deliverables, or any context where sounding machine-generated undermines credibility.

**Source:** Curated from Wikipedia's "Signs of AI writing" guide (maintained by WikiProject AI Cleanup), based on observations of thousands of instances of AI-generated text. Patterns selected for relevance across Crumb's domain spread — SE work, learning artifacts, creative writing, personal documents, specs, and proposals.

**Core insight:** LLMs optimize for the statistically most likely next token. The result converges on phrasing that is technically correct but generically applicable — it sounds like everyone and no one. These patterns are the fingerprints of that convergence.

---

## Content Patterns

### 1. Significance Inflation

**Problem:** Arbitrary details get inflated into grand statements about evolution, transformation, or pivotal moments.

**Watch for:** "marking a pivotal moment in," "the evolution of," "a testament to," "underscores the importance of," "setting the stage for," "represents a shift," "indelible mark."

**Fix:** State the fact. If something is important, the reader will see it from the fact itself. If they can't, the inflation was papering over a weak point.

**Before:** "This workflow marks a pivotal moment in the evolution of personal knowledge management."
**After:** "This workflow consolidates session notes into reusable patterns."

### 2. Vague Attributions

**Problem:** Sources are gestured at without specifics. "Experts believe," "studies show," "research suggests" — with no names, dates, or citations.

**Fix:** Name the source, or drop the claim. If you can't attribute it, present it as your own reasoning and own the uncertainty.

**Before:** "Research suggests that spaced repetition significantly improves retention."
**After:** "Spaced repetition improves retention (Ebbinghaus's forgetting curve; Piotr Wozniak's SuperMemo work in the late 1980s)."

### 3. Promotional Language

**Problem:** Writing reads like marketing copy. Breathtaking, groundbreaking, cutting-edge, seamless, nestled, rich tapestry — words that sell rather than describe.

**Fix:** Replace with concrete descriptors. What specifically makes it good? Say that instead.

**Before:** "A seamless, intuitive, and powerful experience for managing your vault."
**After:** "The vault syncs in under 2 seconds and search covers frontmatter properties."

### 4. Superficial -ing Analyses

**Problem:** Strings of present participles used to imply depth without providing it. "Symbolizing the community's resilience, reflecting broader trends, showcasing the interplay between..."

**Fix:** Either expand with actual evidence/reasoning, or cut. Each -ing clause is a claim that needs support.

**Before:** "The design spec, reflecting the system's maturity while showcasing its flexibility, symbolizing a new approach to personal tooling."
**After:** "The design spec covers seven domains and four workflow depths. It's been through two external reviews."

### 5. Formulaic Resilience Narratives

**Problem:** "Despite challenges... continues to thrive/evolve/grow." A content-free sentence shape that sounds like a conclusion but says nothing.

**Fix:** Name the specific challenge. State the specific outcome. If you can't, the sentence doesn't belong.

**Before:** "Despite challenges inherent in multi-agent architectures, the system continues to evolve."
**After:** "Context window limits forced a summary-based architecture. The tradeoff is that summaries can drift from source docs — the staleness protocol (§5.3) addresses this."

---

## Language Patterns

### 6. AI Vocabulary

**Problem:** Certain words appear at dramatically higher rates in LLM output than in human writing. They're not wrong — they're just statistically overrepresented.

**Words to watch:** additionally, furthermore, moreover, crucial, vital, pivotal, foster, leverage, landscape, delve, intricate, multifaceted, testament, underscore, highlight, showcase, noteworthy, comprehensive, nuanced, robust, streamline, facilitate, paradigm.

**Fix:** Use the simpler word. "Additionally" → "also." "Crucial" → "important" (or just cut it — if it's crucial, the reader knows). "Leverage" → "use." "Facilitate" → "help." "Landscape" → name the actual domain.

### 7. Copula Avoidance

**Problem:** LLMs systematically avoid "is" and "has" in favor of fancier verbs. "Serves as," "functions as," "stands as," "features," "boasts."

**Fix:** Use "is" and "has." They're not boring — they're clear.

**Before:** "The vault serves as a single source of truth."
**After:** "The vault is the single source of truth."

### 8. Negative Parallelisms

**Problem:** "It's not just X, it's Y." A rhetorical structure LLMs overuse because it sounds emphatic without requiring actual reasoning.

**Fix:** State the point directly. If Y is the real claim, just say Y.

**Before:** "It's not just a note-taking system, it's a personal operating system."
**After:** "It's a personal operating system."

### 9. Synonym Cycling

**Problem:** LLMs avoid repeating words by cycling through synonyms: "the protagonist... the main character... the central figure... the hero." This reads as evasive rather than varied.

**Fix:** Repeat the clearest term. Readers track referents better when you're consistent. Technical writing especially benefits from terminological consistency.

**Before:** "The orchestrator routes work to skills. The coordinator then manages workflow phases. The dispatcher spawns subagents as needed."
**After:** "The orchestrator routes work to skills, manages workflow phases, and spawns subagents as needed."

### 10. Rule of Three

**Problem:** LLMs default to three-item lists ("innovation, inspiration, and insights") even when the natural count is two, four, or one. The cadence is a rhetorical tell.

**Fix:** Use the natural number of items. If there are two things, list two. If there's one, just say it.

---

## Style Patterns

### 11. Em Dash Overuse

**Problem:** LLMs use em dashes at a much higher rate than human writers, often stacking multiples in one sentence — mimicking punchy editorial writing — without the editorial judgment about when dashes help — and when they don't.

**Fix:** Use commas or periods. Reserve em dashes for genuine parenthetical asides where commas would be ambiguous.

### 12. Boldface and Formatting Overuse

**Problem:** Mechanical emphasis on terms that don't need it. Every noun gets bolded, every list item gets a bold header followed by a colon.

**Fix:** Bold sparingly. If everything is emphasized, nothing is. Use bold only for terms the reader needs to scan for.

### 13. Inline-Header Lists

**Problem:** Lists where each item starts with a bolded phrase followed by a colon, then a sentence that often restates the bold header. "**Performance:** Performance has improved significantly."

**Fix:** Convert to prose, or keep the list but cut the redundancy. If the bold header says it, the sentence shouldn't repeat it.

---

## Communication Patterns

### 14. Chatbot Artifacts

**Problem:** Residual conversational framing that doesn't belong in a deliverable. "I hope this helps!" "Let me know if you'd like me to expand on any section!" "Great question!"

**Fix:** Remove entirely. Deliverables aren't conversations.

### 15. Sycophantic Framing

**Problem:** Opening with validation of the reader or the question. "That's an excellent point." "You're absolutely right that..." "This is a really thoughtful approach."

**Fix:** Respond to the substance. If you agree, show agreement through the content of your response, not through a preamble.

### 16. Hedging Stacks

**Problem:** Multiple uncertainty markers piled onto one claim. "It could potentially possibly have some positive effect." Each hedge individually is fine; stacked, they signal that the LLM has no actual position.

**Fix:** Pick one level of uncertainty and commit. "This may improve retention" — not "this could potentially possibly help to perhaps improve retention somewhat."

---

## Filler Patterns

### 17. Throat-Clearing Phrases

**Problem:** Phrases that add words without adding meaning. "In order to" (just "to"), "due to the fact that" (just "because"), "it is important to note that" (just state it), "at the end of the day" (cut entirely).

**Fix:** Delete the filler. Read the sentence without it. If it still works, it was filler.

### 18. Generic Conclusions

**Problem:** "The future looks bright." "Exciting times lie ahead." "This journey toward excellence continues." Content-free wrap-ups that say nothing.

**Fix:** End with a specific next step, an open question, or just stop. If there's nothing specific to conclude with, the piece is done — you don't need a bow on it.

---

## When to Load This Document

This reference is most valuable for:

- Customer-facing deliverables (proposals, training materials, executive summaries)
- Published or shared writing (blog posts, documentation, reports)
- Formal specifications and design documents
- Creative writing where voice matters
- Any text where sounding machine-generated would undermine trust

This reference is less relevant for:

- Internal working notes and session logs
- Draft-stage brainstorming and rough outlines
- Personal journal entries and reflections
- Task lists and progress updates

**Loading heuristic:** If the audience extends beyond yourself and the purpose is to inform, persuade, or represent your thinking — load this doc. If the text is scaffolding for your own use — skip it.

---

## Maintenance

Patterns may be added, removed, or refined through the compound step when writing-coach sessions reveal recurring AI tells not covered here, or when patterns listed here prove irrelevant in practice. Follow standard confidence tagging: new patterns enter as observations in the run-log and promote here after a second occurrence.
