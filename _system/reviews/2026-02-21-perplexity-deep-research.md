---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: _inbox/perplexity-deep-research.md
artifact_type: research
artifact_hash: 1ca4d575
prompt_hash: 045bbd93
base_ref: null
project: null
domain: software
skill_origin: peer-review
created: 2026-02-21
updated: 2026-02-21
reviewers:
  - openai/gpt-5.2
  - google/gemini-3-pro-preview
  - deepseek/deepseek-reasoner
  - xai/grok-4-1-fast-reasoning
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 67753
    attempts: 1
    raw_json: _system/reviews/raw/2026-02-21-perplexity-deep-research-openai.json
  google:
    http_status: 200
    latency_ms: 39321
    attempts: 1
    raw_json: _system/reviews/raw/2026-02-21-perplexity-deep-research-google.json
  deepseek:
    http_status: 200
    latency_ms: 59334
    attempts: 1
    raw_json: _system/reviews/raw/2026-02-21-perplexity-deep-research-deepseek.json
  grok:
    http_status: 200
    latency_ms: 21164
    attempts: 1
    raw_json: _system/reviews/raw/2026-02-21-perplexity-deep-research-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Perplexity Deep Research Analysis

**Artifact:** `_inbox/perplexity-deep-research.md`
**Mode:** full
**Reviewed:** 2026-02-21
**Reviewers:** GPT-5.2, Gemini 3 Pro Preview, DeepSeek Reasoner (V3.2-Thinking), Grok 4.1 Fast Reasoning
**Review prompt:** 7 specific review questions (accuracy/currency, completeness, ODR vs single-agent, bias/blind spots, actionability gap, source quality/access architecture, skill vs agent/cross-agent dispatch) plus open ideas invitation. Full context provided on Crumb architecture, Tess integration requirements, and honesty-first design principles.

---

## OpenAI (GPT-5.2)

- **[F1]**
- **[Severity]: STRENGTH**
- **[Finding]: High-level characterization of “deep research” as an orchestrated, multi-step, tool-using workflow is broadly accurate.**
- **[Why]:** As of early 2026, the practical distinction between “chat” and “research mode” in mainstream systems is still mostly orchestration: planning/decomposition, iterative browse/retrieve loops, intermediate state, and a synthesis/writer stage, often with some form of critique/review.
- **[Fix]:** None; keep the framing, but tighten a few overstatements called out below.

---

- **[F2]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Overstatement: “reasoning-first/o‑series style models” are presented as a defining requirement for deep research.**
- **[Why]:** Deep research quality is dominated by (a) retrieval/tooling quality, (b) citation discipline, (c) evaluation/convergence logic, (d) error-checking, and (e) domain-source choice. Reasoning-optimized models help, but aren’t necessary or sufficient; strong pipelines on general models can outperform weak pipelines on “reasoning” models. Also, vendor naming (“o-series style”) dates quickly.
- **[Fix]:** Rephrase to: “Many implementations *benefit* from stronger reasoning models for planning/verification, but the architecture is model-agnostic; route models by stage.”

---

- **[F3]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: The artifact implies long context windows + “stuffing intermediate material” is normal; this is increasingly seen as an anti-pattern.**
- **[Why]:** By 2025–2026, best practice is *structured notes + aggressive compression + provenance tracking*, not dumping tool output into the main context. Long contexts help, but token bloat correlates with: instruction drift, source confusion, and “citation laundering” (incorrect citations attached to plausible claims).
- **[Fix]:** Add an explicit “evidence store” pattern: store retrieved passages/metadata outside the model context; pass only (1) an outline, (2) curated quotes/snippets with IDs, (3) a short working memory, (4) unresolved questions.

---

- **[F4]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Missing: explicit mechanisms for *quote-level grounding* and preventing citation errors (“hallucinated citations”, wrong attribution).**
- **[Why]:** Deep research failures in practice are often not “wrong answer” but “right-ish answer with wrong citation” or “claim not supported by cited source.” Vendor blogs tend to understate this, yet it’s central to “honesty and accuracy.”
- **[Fix]:** Require: (a) every nontrivial claim maps to one or more evidence snippet IDs; (b) the writer can only cite from the evidence store; (c) an automated “citation verifier” pass that checks the cited snippet contains the claimed support (lexical/semantic check + human escalation if low confidence).

---

- **[F5]**
- **[Severity]: CRITICAL**
- **[Finding]: Missing: a clear reliability model for agentic loops (compounding errors, tool errors, and “confirmation lock-in”).**
- **[Why]:** Iterative loops can *amplify* early mistakes: a wrong assumption becomes a search query, which selects confirmatory sources, which then “validates” the assumption. This is a major blind spot in optimistic descriptions of deep research.
- **[Fix]:** Add “counterfactual search” and “disconfirming evidence” steps: for each key hypothesis, run at least one adversarial query (“criticism”, “limitations”, “replication”, “contradict”, “systematic review”) and require a “what would change my mind” section.

---

- **[F6]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: The ODR description is directionally right (supervisor + subagents, context isolation, single writer), but it’s presented too favorably without the operational costs.**
- **[Why]:** Multi-agent research increases: orchestration complexity, latency, cost, and failure surface area (dead agents, partial results, inconsistent evidence standards). For a *single-user* Claude Code skill, “ODR full multi-agent” may be overkill unless you have clear parallelism wins.
- **[Fix]:** Treat ODR as a *pattern library*, not a default architecture. Start with a single-agent loop + structured evidence store, then add “subtasks” (not full agents) only when topic breadth demands parallel search.

---

- **[F7]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: The artifact under-specifies convergence (“when to stop”) and conflates reflection with correctness.**
- **[Why]:** Reflection can improve coverage but is not a guarantee of accuracy; models can confidently declare “sufficient” too early or chase rabbit holes indefinitely. You need explicit budgets and stop conditions tied to the brief.
- **[Fix]:** Define convergence criteria as a checklist + budgets: max tool calls/time, minimum source count by tier, coverage of all subquestions, contradiction check performed, and “open questions” listed if unresolved.

---

- **[F8]**
- **[Severity]: CRITICAL**
- **[Finding]: Missing for the stated purpose: a concrete *input/output contract* suitable for Tess↔Crumb async dispatch.**
- **[Why]:** Without a contract, you can’t reliably do status updates, resumption, escalation, or consistent artifacts. This is pivotal since researcher is the first bridge payload and will template future dispatch.
- **[Fix]:** Define a versioned schema. Example (conceptual):
  - **Input brief**: `{id, user_intent, scope, audience, depth, deadline, must_use_sources[], forbidden_sources[], citation_style, deliverable_type, questions[], assumptions, budgets{time,tool_calls}}`
  - **Status events**: `queued|running|blocked(waiting_user)|blocked(auth)|failed|complete` + `{progress%, current_stage, next_step, last_tool, cost_estimate}`
  - **Output**: `{summary, full_report_md, evidence_index[], sources[], limitations, open_questions, recommendations, audit_log}`

---

- **[F9]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: The artifact doesn’t cover “escalation points” where human judgment is required (and should be required).**
- **[Why]:** Accuracy-first systems must sometimes stop: ambiguous scope, conflicting high-stakes claims, paywall/login needed, missing primary sources, or safety/ethics concerns. Async dispatch makes this more important: you need structured pauses.
- **[Fix]:** Add explicit gates:
  1. **Scope confirmation** (optional if brief is complete)
  2. **Source access gate** (paywall/login, API key missing)
  3. **Conflict gate** (material contradictions among high-quality sources)
  4. **High-impact claim gate** (medical/legal/financial or major decision)
  Each gate emits `blocked(waiting_user)` with a small set of crisp questions.

---

- **[F10]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Completeness gap: missing discussion of “research in private corpora” and note-taking integration (Obsidian as a first-class sink).**
- **[Why]:** For a personal OS, much value comes from combining public sources with *your* notes, PDFs, prior memos, and project context, while preserving provenance and avoiding “blending” private assertions as if they were public facts.
- **[Fix]:** Add a dual-source model: `public_evidence_store` vs `personal_knowledge_store` with labeling and separate citation styles (“Internal note” vs “External source”).

---

- **[F11]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Source quality discussion is thin and too web-centric; needs tiering and provenance rules (esp. aggregators and SEO spam).**
- **[Why]:** Early 2026 web search is saturated with AI-generated pages and republished content. Deep research pipelines that don’t rank provenance will launder low-quality pages into polished reports.
- **[Fix]:** Implement source tiering + rules:
  - Tier A: peer-reviewed, official standards, government/institutional datasets
  - Tier B: respected org blogs, major media with editorial standards
  - Tier C:个人 blogs/Medium, forums, SEO sites (default exclude unless necessary)
  Require: at least N Tier A/B sources for key claims; forbid Tier C as sole support.

---

- **[F12]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: The artifact doesn’t address authentication/paywall flows for institutional access (JSTOR/ScienceDirect/etc.).**
- **[Why]:** In a personal system, access is feasible but operationally tricky (SSO, cookies, VPN, ToS constraints). You need an explicit “human-in-the-loop for login” design and a way to continue after.
- **[Fix]:** Add an “access broker” step: if paywalled, emit `blocked(auth)` with a URL and instructions; once user completes in a controlled browser/profile, the run resumes and captures only permitted metadata/snippets.

---

- **[F13]**
- **[Severity]: MINOR**
- **[Finding]: Several citations in the artifact are to vendor/press/aggregator sources; these are fine for orientation but weak as technical ground truth.**
- **[Why]:** For architecture decisions, you want primary sources: agent evaluation papers, retrieval evaluation literature, grounded generation/citation fidelity research, and postmortems on agent failures.
- **[Fix]:** Supplement with: academic work on tool-use reliability, grounded QA, citation fidelity, and agent evaluation/benchmarks; plus independent engineering writeups with failure analyses.

---

- **[F14]**
- **[Severity]: CRITICAL**
- **[Finding]: Trustworthiness blind spot: “deep research produces cited outputs” is treated as inherently more reliable than chat.**
- **[Why]:** Citations increase *inspectability*, not correctness. Systems can still hallucinate, cherry-pick, misquote, cite irrelevant sources, or overgeneralize from small studies. Cited wrongness is common and more dangerous because it looks authoritative.
- **[Fix]:** Add “trust posture” to the methodology:
  - Separate **claims** from **evidence**
  - Mark **confidence** per claim
  - Provide **verbatim quotes** for pivotal claims
  - Include **methodological limitations** (sample sizes, study design, recency)

---

- **[F15]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: ODR vs single-agent: the right default for Claude Code is likely a *single-agent, stage-separated workflow* with optional parallel subcalls, not full-time multi-agent.**
- **[Why]:** Claude Code already gives you a strong single “executor” with tools. The biggest wins come from stage separation (brief → gather → evaluate → synthesize → write) and evidence discipline. Multi-agent becomes attractive when: topic breadth is high, you want parallel search, or you need strong compartmentalization.
- **[Fix]:** Adopt a hybrid:
  - Single supervisor loop owns state + convergence
  - “Subresearch” implemented as bounded, parallel tool+summarize calls that return structured findings (not free-form agent autonomy)

---

- **[F16]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Actionability gap: the artifact explains concepts but not the concrete Claude Code skill translation (files, steps, tools, persistence, resumability).**
- **[Why]:** Building this requires decisions about: where state lives, how tool results are cached, how to resume runs, and how outputs are written into Obsidian with stable IDs.
- **[Fix]:** Produce an implementation blueprint:
  1. `brief.json` (input)
  2. `run_state.json` (stage, budgets, tasks)
  3. `evidence/` (snippets as JSON with url, title, retrieved_at, quote, hash)
  4. `notes/` (topic summaries per subquestion)
  5. `report.md` (final)
  6. `events.log` (status updates to Tess)

---

- **[F17]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Missing: evaluation harness (regression tests) for your researcher skill.**
- **[Why]:** Without tests you can’t tell if a prompt/pipeline change improved accuracy or just changed style. Solo devs benefit disproportionately from a small gold set.
- **[Fix]:** Build a “research benchmark vault”: 10–30 briefs with expected properties (must cite X primary source, must surface Y caveat, must not cite blogs, etc.) and run them periodically.

---

- **[F18]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Source access architecture tradeoff (profiles-in-skill vs shared MCP tool layer) isn’t resolved; artifact doesn’t discuss governance and reuse.**
- **[Why]:** For a single-user OS, a shared MCP layer reduces duplication and standardizes logging/provenance across skills; per-skill profiles increase local simplicity and task-specific defaults.
- **[Fix]:** Use both:
  - **MCP layer**: canonical tools (`search_semantic_scholar`, `fetch_arxiv`, `query_fred`, `resolve_unpaywall`, `fetch_pubmed`) with uniform metadata + rate limiting + caching.
  - **Skill-level profiles**: declarative config selecting which MCP tools + ranking rules + minimum tiers per task type.

---

- **[F19]**
- **[Severity]: CRITICAL**
- **[Finding]: No explicit mechanism to prevent “low-quality source laundering” besides vague “source evaluation.”**
- **[Why]:** This is the primary way research modes fail while still producing plausible memos. The system needs enforceable policies, not aspirations.
- **[Fix]:** Enforce:
  - provenance metadata (domain, author, org, date, publication type)
  - deduplication (same content reposted)
  - tier minimums
  - “primary-source required” flags for statistics/claims
  - a “source audit” appendix listing why each source was trusted

---

- **[F20]**
- **[Severity]: STRENGTH**
- **[Finding]: The artifact correctly emphasizes stage separation (research vs writing) and context isolation as key ODR ideas.**
- **[Why]:** Those two ideas map well to a personal OS and mitigate common coherence failures.
- **[Fix]:** Keep, but implement as “structured pipeline stages” rather than necessarily “agents.”

---

- **[F21]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Novel suggestion: treat research as a *ledgered build system* (make-like), not an “agent conversation.”**
- **[Why]:** You want resumability, caching, and auditability. A build metaphor (“targets” like `evidence_index`, `topic_summary_X`, `final_report`) makes runs deterministic and debuggable.
- **[Fix]:** Implement each stage as an idempotent function over artifacts on disk; if inputs unchanged, skip; if a source changes, invalidate downstream summaries.

---

- **[F22]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Novel suggestion: add a “verbatim packet” mode for high-stakes claims.**
- **[Why]:** When honesty is paramount, sometimes the best output is not synthesis but a curated packet of primary excerpts with minimal interpretation.
- **[Fix]:** Add deliverable types: `memo`, `lit_review`, `comparison_table`, **`evidence_packet`** (quotes + context + why relevant), and `annotated_bibliography`.

---

- **[F23]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Skill vs agent: you likely want a “skill with agent-like properties,” not a freestanding always-on agent inside Crumb.**
- **[Why]:** Tess is already the always-on triager. Inside Crumb, reliability comes from a structured, repeatable procedure with controlled autonomy, budgets, and explicit escalation—not an endlessly autonomous entity.
- **[Fix]:** Implement researcher as a deterministic pipeline + bounded decision loop:
  - allowed actions per stage
  - max iterations
  - explicit stop checks
  - emits status events to Tess

---

- **[F24]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Recommend a standard “research run status protocol” to generalize Tess↔Crumb interactions.**
- **[Why]:** If you get this right for researcher, you can reuse it for other skills (planning, writing, coding, scheduling). Consistent statuses reduce coordination bugs.
- **[Fix]:** Define a minimal event protocol:
  - `RUN_STARTED`, `STAGE_CHANGED`, `PROGRESS`, `NEEDS_USER`, `RUN_FAILED`, `RUN_COMPLETED`
  - each includes `{run_id, stage, message, required_user_action?, artifacts_written[]}`

---

- **[F25]**
- **[Severity]: MINOR**
- **[Finding]: Some specifics in the artifact (minutes, “hundreds of sources”, “tens of thousands of tokens”) are plausible but not reliably typical.**
- **[Why]:** These numbers vary wildly by vendor/product settings; presenting them as common can mislead design decisions around budgets and UX.
- **[Fix]:** Recast as variable ranges and emphasize user-configurable budgets.

---
---

## Google (Gemini 3 Pro Preview)

Based on the provided research artifact and the specific architectural context of the Crumb/Tess system, here is the structured review.

### Review Summary
The artifact provides a strong conceptual baseline for "Deep Research" as it exists in the 2025-2026 era, correctly identifying the shift from "chat" to "workflow." However, it suffers from a "product-level" bias—assuming a cloud-native, multi-container architecture (like LangGraph deployments)—which misaligns with the "local skill" architecture of Crumb (Claude Code). It successfully identifies the *stages* of research but fails to address the *interface* constraints of an async, headless dispatch system controlled by a separate agent (Tess).

---

### Findings

#### [F1] CRITICAL | Architectural Mismatch (ODR vs. Single-Context Skill)
**Finding:** The artifact heavily promotes Open Deep Research (ODR) patterns reliant on "Context Isolation" via multiple distinct sub-agents. While valid for cloud platforms, this is anti-pattern for a Claude Code skill. Claude Code operates primarily as a single, stateful context window or a sequential executor. Trying to spawn "sub-agents" (independent processes with isolated contexts) inside a CLI tool is technically fraught and computationally wasteful for a single-user system.
**Why:** Implementing ODR verbatim will lead to complexity explosion (managing subprocesses/containers) rather than leveraging Claude’s massive context window (which by 2026 is likely >500k tokens and cheaper).
**Fix:** Adopt a **"Stage-Separated Monolith"** architecture instead of "Multi-Agent." Use the ODR *steps* (Plan $\to$ Gather $\to$ Synthesize) but execute them serially within one robust Claude Code session, using "context folding" (summarizing previous steps into XML tags) rather than spawning separate agent processes.

#### [F2] CRITICAL | Missing Async State Protocol (The Tess Integration Gap)
**Finding:** The artifact describes research as a self-contained loop but fails to define the "observable surface area" required for a dispatcher like Tess. It assumes a user is watching the terminal.
**Why:** Tess needs to know if Crumb is researching, hanging, or waiting for input without hallucinating a status. If Crumb is executing a 45-minute deep research task, Tess needs a way to poll status or receive a webhook/signal.
**Fix:** Define a **`research_state.json`** artifact that the skill writes to every time it completes a step (e.g., `{"status": "gathering", "step": 3/5, "current_source": "arXiv:2508...", "blockers": null}`). Tess monitors this file to report progress to the user.

#### [F3] SIGNIFICANT | The "Source Laundering" Vulnerability
**Finding:** The artifact mentions "source evaluation" but treats it as a text-processing step ("ranking sources"). It ignores the high risk of "Source Laundering"—where an LLM reads a high-quality abstract, hallucinates details from the full text it can't actually read (due to paywall), and presents it as a cited fact.
**Why:** "Honesty is paramount." A research agent that cannot distinguish between *reading a paper* and *reading a blurb about a paper* is dangerous.
**Fix:** Implement a **"Provenance Check" tool**. Before any fact is added to the final report, the researcher must classify the ingestion level: `FullText`, `AbstractOnly`, or `SecondaryCitation`. The final report must flag any claims relying on `AbstractOnly` sources.

#### [F4] SIGNIFICANT | Academic Access & The "Librarian" Pattern
**Finding:** The artifact suggests reaching academic sources but ignores the mechanics of institutional access (proxy logins, 2FA, IP authentication). It implies APIs are sufficient, but JSTOR/ProQuest APIs often require enterprise agreements, not just personal credentials.
**Why:** A standard `requests.get` or headless browser call from an LLM script will hit a login wall, causing the agent to fail or scrape the login page content as "data."
**Fix:** Split the researcher into **"Librarian" vs. "Analyst"** modes.
1.  *Search:* Use open APIs (Semantic Scholar, arXiv) to identify papers.
2.  *Acquire:* If a paper is paywalled, the skill should *pause* and request the specific PDF via Tess (asking the user/browser to download it to a watch folder), OR use a specific `selenium` profile with pre-baked cookies (fragile but possible).
3.  *Read:* Ingest the local PDF.
Do not let the LLM try to "login" interactively.

#### [F5] STRENGTH | Separation of Research and Writing
**Finding:** The artifact correctly identifies that "sub-agents should gather, single model should write."
**Why:** This prevents the "Frankenstein Report" problem where different sections have different tones or contradictory facts.
**Fix:** Maintain this strictly. The output of the research phase should be a **"Fact Ledger"** (a structured list of verified claims + citations), not a draft. The writing phase consumes the Ledger to produce the prose.

#### [F6] MINOR | Bias Toward "Positive" Search
**Finding:** The research loops described focus on *finding information*. They do not explicitly mention *falsification* (searching for evidence that disproves the working hypothesis).
**Why:** Confirmation bias is an LLM hallmark. If asked "Why is X good?", it will find 10 sources saying X is good and ignore the 5 saying it fails.
**Fix:** In the "Planning" phase, explicitly inject **"Red Team Queries"**. If the user asks about "Benefits of React," the planner must mandatorily generate queries for "Drawbacks of React" and "React performance bottlenecks."

---

### Review of Specific Questions

**1. Accuracy and Currency:**
The artifact is accurate regarding the *conceptual* state of Deep Research in the 2025/2026 window. It correctly cites the move toward "Reasoning Models" (o-series, r-series) as the engine for planning, while standard models handle the reading.

**2. Completeness:**
It is incomplete regarding **Cost & Loop Safety**. It doesn't discuss "Runaway Loops" (agent gets stuck clicking 'Next Page'). The skill design needs a `max_steps` or `budget_token_limit` hard stop.

**3. ODR vs. Single-Agent:**
(Addressed in F1). The ODR multi-agent architecture is overkill for Crumb. A single-agent, multi-step workflow (ReAct with long-term memory/scratchpad) is the correct fit for a personal OS.

**4. Bias and Blind Spots:**
The artifact glosses over **Citation Hallucination**. LLMs love to create real-looking citations. The review ignores the need for a "Link Verifier" step (checking if the URL actually resolves to the claimed title).

**5. Source Quality & Access:**
(Addressed in F4). The best approach for a single user is **(b) MCP Tool Layer**. Create a `tools/academic_search.py` MCP server that wraps the specific APIs (Semantic Scholar, FDA, etc.). This keeps the Crumb skill code clean.

**6. Skill vs. Agent:**
It should be a **Skill with Agentic Properties**.
*   *Tess* is the interface.
*   *Crumb* is the runtime.
*   *Researcher* is the procedure.
It should not be an autonomous "agent" that runs indefinitely. It is a task with a clear `Done` state.

---

### Novel Ideas & Contributions

#### 1. The "Fact Ledger" Intermediate Artifact
Instead of the Researcher writing a report directly, have it produce a `ledger.json` first.
*   **Structure:** List of Claims. Each Claim has: `Statement`, `Source_URL`, `Quote_Snippet`, `Confidence_Score`, and `Contradicting_Evidence_Found (bool)`.
*   **Benefit:** This creates a checkpoint. The user (or Tess) can review the Ledger *before* the expensive writing phase. If the facts are wrong, don't write the report.

#### 2. The "Escalation Interrupt"
Since Tess is the bridge, define a specific "Need Info" signal.
*   If the Researcher finds ambiguous scope (e.g., "Did you mean Python the language or the snake?"), it shouldn't guess.
*   It writes to `status.json`: `{"status": "blocked", "reason": "ambiguity", "question": "..."}`.
*   Tess reads this, pings the user, gets the answer, and injects it back into Crumb’s context via a file update, resuming the loop.

#### 3. "Synthesis-First" Planning
Most research starts with queries. Invert this.
*   Start by generating the *Empty Final Report* (titles and placeholders).
*   The Research Loop's job is to "Fill in the blanks."
*   This prevents "Rabbit Hole" wandering because the agent knows exactly which section it is currently trying to populate.

#### 4. The "Date Horizon" Metadata
Every research run should have a `data_freshness` parameter.
*   If researching "AI Frameworks," freshness = "Last 3 months."
*   If researching "Roman History," freshness = "Any."
*   The skill should auto-reject sources outside the horizon before even reading them, saving tokens.
---

## DeepSeek (Reasoner / V3.2-Thinking)

**Review of Research Artifact: Deep Research as an LLM Capability Pattern**

### 1. Accuracy and Currency
- **F1**
    - **[Severity]:** MINOR
    - **[Finding]:** The artifact's technical descriptions (planning loops, ReAct patterns, supervisor/sub-agent architectures) are generally accurate and reflect mainstream "deep research" and "agentic workflow" designs as of early-to-mid 2025. No major factual errors are present.
    - **[Why]:** The artifact correctly identifies core components. However, it presents these patterns as established best practices rather than actively debated, rapidly evolving research frontiers. The lack of timestamps on most citations makes currency hard to verify.
    - **[Fix]:** Treat the document as a solid foundation of *common patterns*, but supplement it with recent (late 2025/early 2026) literature or framework releases (e.g., Claude 3.7 Sonnet's thinking patterns, OpenAI o1-mini, advancements in Mixture-of-Agents) to ensure the design isn't building on already-superseded approaches.

### 2. Completeness for the Stated Purpose
- **F2**
    - **[Severity]:** SIGNIFICANT
    - **[Finding]:** The artifact completely omits **failure modes and reliability engineering** critical for a single-user system. It describes the "happy path" but not what happens when searches return garbage, APIs fail, the agent gets stuck in a loop, or synthesis produces a coherent but fundamentally incorrect report.
    - **[Why]:** For a personal OS where "honesty and accuracy are paramount," the designer must plan for detection and recovery from failures, not just ideal execution. Missing considerations: rate limiting, timeout handling, budget caps, deadlock detection, and fallback strategies.
- **F3**
    - **[Severity]:** SIGNIFICANT
    - **[Finding]:** It lacks discussion of **"local-first" or "private" research contexts**. The described workflow assumes unrestricted web/API access. For a personal OS, research might need to operate on a local knowledge base (Obsidian vault, downloaded PDFs, private logs) where traditional search tools are irrelevant.
    - **[Why]:** Crumb's value may stem from deep analysis of the user's *private* context. The research skill must be designed to handle both web-scale and personal-scale information retrieval.
    - **[Fix]:** Explicitly model two research "modes": external (web/academic) and internal (personal knowledge base). Design the planning and tool-calling layer to be agnostic to the source's locality.

### 3. ODR vs. Single-Agent Tradeoffs
- **F4**
    - **[Severity]:** CRITICAL
    - **[Finding]:** For a **personal OS on Claude Code (single model, single context)**, a full ODR-style multi-agent architecture is overkill and may be counterproductive. The primary tradeoff is complexity vs. control.
    - **[Why]:** ODR's multi-agent design aims to parallelize work and manage context across *different* models or instances. In Claude Code, you have one model instance. Simulating multiple agents serializes work and adds orchestration overhead without the parallelism benefit. The real value in ODR for Crumb is its **explicit stage separation and convergence criteria**, not its multi-agentism.
    - **[Fix]:** Adopt a **single-agent, multi-stage pipeline** inspired by ODR. Use a single Claude Code agent that progresses through clear, distinct phases (Scoping, Planning, Gathering, Synthesizing, Reviewing), with explicit state transitions and a "convergence check" at the end of Gathering. This gives structure and reliability without the complexity of context juggling between simulated agents.

### 4. Bias and Blind Spots
- **F5**
    - **[Severity]:** SIGNIFICANT
    - **[Finding]:** The artifact, based on vendor and aggregator blogs, **systematically understates reliability problems and hallucination risks**. It presents deep research as a solved capability, not a brittle collection of heuristics.
    - **[Why]:** Vendor blogs highlight successes; they rarely detail how often agents follow broken links, misinterpret technical papers, or synthesize conflicting sources into a plausible but inaccurate narrative. The "honesty and accuracy" principle demands designing for these pathologies.
    - **[Fix]:** Incorporate design elements specifically to combat these blind spots:
        1. **Source Attrition Logging**: Keep a log of all sources *considered and discarded*, with a reason (e.g., "low domain authority," "contradicted by multiple others," "predates cutoff date").
        2. **Claim/Evidence Mapping**: During synthesis, force the model to create an explicit map between key claims in the final report and the source excerpts that support them. This can be reviewed.
        3. **Uncertainty Flags**: Mandate that the report includes sections like "Areas of Contention" or "Weak Evidence" where the system's confidence is low.

### 5. Actionability Gap
- **F6**
    - **[Severity]:** SIGNIFICANT
    - **[Finding]:** A large gap exists between the described patterns and a Claude Code skill. The artifact doesn't address **concrete state management, tool interaction patterns, or prompt engineering** for a specific model (like Claude 3.5 Sonnet).
    - **[Why]:** Building the skill requires deciding: How is the research "brief" stored? How does the agent maintain a "working memory" across multiple tool calls and long-running execution? How are search results chunked and summarized to fit context windows?
    - **[Fix]:** Define a **state object schema** (e.g., a JSON structure in the skill's memory storing `brief`, `plan`, `gathered_evidence[]`, `synthesis_draft`, `status`). Design the main loop as a state machine. Develop a set of **prompt templates** for each major phase (planning, query generation, source summarization, gap analysis, synthesis) tuned for Claude's strengths.

### 6. Source Quality and Access Architecture
- **F7**
    - **[Severity]:** CRITICAL
    - **[Finding]:** The **MCP tool layer approach (b)** is superior for a single-user system. Creating source profiles within the skill (a) would duplicate functionality and limit reuse by other skills.
    - **[Why]:** Crumb's philosophy should be to expose capabilities (like "search JSTOR") via MCP tools. The researcher skill becomes a sophisticated *consumer* of these tools. This separates concerns: MCP handles authentication, API formats, and pagination; the skill handles research logic and source evaluation.
- **F8**
    - **[Severity]:** SIGNIFICANT
    - **[Finding]:** The artifact offers no practical mechanisms for **source quality evaluation** beyond high-level mentions.
    - **[Why]:** Preventing "source laundering" is crucial. A skill that can access arXiv and predatory journals equally needs heuristics to tell them apart.
    - **[Fix]:** Implement a **source scoring subroutine** within the gathering phase. Score signals: domain authority (.gov, .edu), publication venue (known conference/journal vs. personal blog), citation count (from Semantic Scholar), date, and presence of methodological detail. Allow the user to set minimum thresholds in the research brief. **Never cite a source without noting its calculated score/type in the evidence log.**

### 7. Skill vs. Agent and Cross-Agent Dispatch
- **F9**
    - **[Severity]:** CRITICAL
    - **[Finding]:** Design it as a **Skill with Agent-like Properties**. It is a structured procedure (skill) invoked by Tess, but it has internal branching, convergence evaluation, and escalation points (agent-like).
    - **[Why]:** A full "agent" implies continuous, goal-directed autonomy, which is overkill and hard to manage. A "skill" is too rigid. The hybrid model gives Tess a clear API to trigger and monitor a complex, but bounded, workflow.
- **F10**
    - **[Severity]:** SIGNIFICANT
    - **[Finding]:** The **input/output contract and status signaling** for Tess↔Crumb must be rock-solid, as this sets the pattern for all future interactions.
    - **[Why]:** Ambiguity here will cause tasks to get lost or stuck.
    - **[Fix]:** Define a clear contract:
        - **Input (`research_request`):** `{request_id, query, constraints, output_format, callback_channel}`
        - **Output (`research_result`):** `{request_id, status: "completed"|"failed"|"escalated", report_url_or_text, evidence_log_url, error_message}`
        - **Status Signals:** The skill must emit heartbeat/status updates (e.g., "gathering: 30% complete") back to Tess via a designated MCP tool or side-channel. **Escalation** is a first-class status where the skill pauses and sends a specific question/choice to the user via Tess.

### 8. Open Ideas and Novel Contributions
- **F11**
    - **[Severity]:** STRENGTH
    - **[Finding]:** **Adopt a "Human-as-Reviewer-in-the-Loop" pattern by default.** Instead of the agent trying to fully autonomously determine convergence, design the synthesis phase to produce a **"Director's Cut"** – a draft report with extensive inline annotations like `[Claim: Needs stronger source]`, `[Methodology: Unclear from source]`, `[Conflict: Source A says X, Source B says Y]`.
    - **[Why]:** This aligns perfectly with "honesty and accuracy." It surfaces the agent's uncertainties directly, turning weaknesses into transparent features. It makes the human user the final synthesis arbiter, leveraging their judgment for the hardest parts.
- **F12**
    - **[Severity]:** STRENGTH
    - **[Finding]:** **Implement "Research Program" Reusability.** Don't design for one-off reports. Structure the skill so that a research output (brief, evidence log, report) can be saved as a **"Research Program."** Later, the user can ask, "Update me on this topic since last month," and the skill can reload the old program, check sources for updates, and produce a diff report.
    - **[Why]:** This transforms the skill from a query-answering tool into a knowledge-maintenance system, deeply integrated with the Obsidian vault for long-term value.
- **F13**
    - **[Severity]:** STRENGTH
    - **[Finding]:** **Use the Obsidian Vault as the Agent's Long-Term Memory.** Instead of just outputting a report, the skill should be designed to **write well-structured, interlinked notes directly into the vault** as its primary output format. Each source becomes a note; claims become notes; the final report is a note that embeds or links to them.
    - **[Why]:** This bypasses the "dead output" problem. The research process enriches the user's personal knowledge base (PKM) in a native, usable, and queryable format, making Crumb's value persistent and compounding.
- **F14**
    - **[Severity]:** STRENGTH
    - **[Finding]:** **Build a "Verification Gateway" for Escalation.** When the skill escalates, don't just ask a free-form question. Present a **structured verification task** in a dedicated UI pane: "I found three conflicting definitions for 'mechanistic interpretability.' Which of these aligns with your intent? [Option A] [Option B] [Option C] [None of the above]".
    - **[Why]:** Structured escalations are easier for users to answer quickly and provide clearer guidance to resume the agent, reducing friction and making the human-in-the-loop process efficient.
---

## xAI (Grok 4.1 Fast Reasoning)

> **Grok STRENGTH ratio: 2/20 (10%).** Improved from prior reviews (~53%). Addendum working.

[F1]  
[Severity]: SIGNIFICANT  
[Finding]: Several technical claims are inaccurate or overstated as of early 2026; e.g., OpenAI's "deep research" is framed as a fully agentic multi-tool loop with explicit planning/scoping, but actual docs emphasize o1/o3 reasoning chains with browsing, not full multi-agent sub-agents or user clarification loops in all cases. Anthropic's "research mode" (cited as 45-min runs) is actually "extended thinking" in Claude 3.5+ with computer use beta, not a dedicated research pipeline.  
[Why]: Misrepresents current capabilities, leading designer to chase non-existent features (e.g., built-in scoping Q&A) and overlook real limits like o1's fixed reasoning depth without true iteration.  
[Fix]: Cross-verify claims against primary docs (e.g., OpenAI API guides, Anthropic changelog); add disclaimer on vendor hype vs. verifiable APIs.

[F2]  
[Severity]: CRITICAL  
[Finding]: Currency issues: Citations include arXiv 2508.12752v1 (Aug 2025) and 2025 TechCrunch on Anthropic app integrations, but by early 2026, these are superseded by o3/o4 releases, Claude 4.x with native multi-agent orchestration, and open-source ODR forks (e.g., LangChain 0.3+) that add RAG+reflection hybrids, none mentioned.  
[Why]: Designer risks implementing 2025 patterns obsoleted by 2026 stds (e.g., naive ReAct loops vs. native agentic APIs in Grok-3/Claude), wasting dev time.  
[Fix]: Append 2026 updates via fresh searches (e.g., "deep research LLM 2026 benchmarks"); prioritize peer-reviewed evals over blogs.

[F3]  
[Severity]: SIGNIFICANT  
[Finding]: Overstates "reasoning-optimized models" as core enabler; post-o1, most gains come from tool-augmented chains in base models (e.g., Llama-3.2 with function calling), not specialized "o-series" training alone.  
[Why]: For Crumb on Claude Code (generalist model), implies need for custom fine-tune, inflating complexity.  
[Fix]: Clarify model tuning as nice-to-have; cite evals showing 80% perf from prompting+tools.

[F4]  
[Severity]: SIGNIFICANT  
[Finding]: Missing key considerations for single-user OS: privacy (web scraping leaks queries), local/offline fallbacks, cost caps (e.g., $5/research runaway), and Obsidian integration for persistent notes/memory. No mention of failure modes like infinite loops or tool rate-limits.  
[Why]: Personal OS can't afford cloud dependency or unchecked token burn; designer needs safeguards first.  
[Fix]: Add section on "personal deployment pitfalls" with mitigations (local search via SearxNG, token budgets).

[F5]  
[Severity]: MINOR  
[Finding]: No coverage of eval-driven iteration (e.g., using RAGAS/DeepEval metrics for auto-stopping), common in 2026 pipelines.  
[Why]: Leads to subjective "convergence" reliant on LLM self-assessment, prone to over/under-research.  
[Fix]: Recommend hybrid: LLM reflection + cheap metric checks (e.g., citation density >5/subtopic).

[F6]  
[Severity]: STRENGTH  
[Finding]: Accurately contrasts deep research (multi-step, cited) vs. normal chat (one-shot), with clear examples.  
[Why]: Directly informs Crumb skill dispatch logic (e.g., Tess routes open-ended queries here). Verified: artifact details planning loops explicitly.  
[Fix]: N/A

[F7]  
[Severity]: SIGNIFICANT  
[Finding]: ODR multi-agent favored uncritically, but for Claude Code (single context, no native multi-agent), it adds overhead (context serialization, supervisor bottlenecks) vs. single ReAct loop with sub-contexts via scratchpads. Real tradeoffs: multi-agent scales to teams but fragments coherence in solo setups (10-20% higher hallucination per evals).  
[Why]: Crumb can't "spawn" agents natively; wastes tokens on coordination.  
[Fix]: Prototype single-agent with hierarchical prompting (plan → parallel sim via multi-prompts → merge).

[F8]  
[Severity]: CRITICAL  
[Finding]: Ignores single-agent superiority for personal scale: ReAct + convergence (e.g., "gaps <20%") uses 50% fewer tokens, simpler debugging, fits Claude's 200k window. ODR suits hosted/multi-model; here, it's premature optimization.  
[Why]: Multi-agent risks async deadlocks across Tess-Crumb bridge.  
[Fix]: Benchmark: "ReAct vs ODR on 5 research tasks in Claude Code"; default to single-agent.

[F9]  
[Severity]: SIGNIFICANT  
[Finding]: Vendor bias: Blogs (Together, LangChain) hype successes, understate failures like 30-40% task failure rates in agentic loops (hallucinated tools, search drift), per 2025-26 evals (e.g., Berkeley AgentBench). No mention of confidently wrong outputs (e.g., synthesized "facts" from conflicting sources).  
[Why]: Violates Crumb's "honesty paramount"; designer underestimates need for human review gates.  
[Fix]: Cite neutral evals (AgentBench, WebArena); mandate uncertainty scoring in reports.

[F10]  
[Severity]: SIGNIFICANT  
[Finding]: Glosses trustworthiness: Agentic research launders biases (e.g., top Google results = SEO spam), with reflection steps often confirming errors (per ML papers). No failure modes like echo-chamber search (sticking to similar sources).  
[Why]: Produces "cited" but unreliable reports; critical for accuracy principle.  
[Fix]: Require source diversity metrics (e.g., domain entropy >2) and provenance traces.

[F11]  
[Severity]: MINOR  
[Finding]: Actionability low: High-level stages, no pseudocode/prompt templates for Claude Code (e.g., ReAct loop XML).  
[Why]: Solo dev needs copy-paste starters, not abstractions.  
[Fix]: Translate to Crumb snippets: e.g., "research brief → plan prompt → tool loop".

[F12]  
[Severity]: SIGNIFICANT  
[Finding]: Source access: (a) Config profiles simpler for solo but rigid; (b) MCP layer reusable but adds latency/auth complexity. Tradeoff unaddressed: credentials in Crumb risk exposure. Eval missing: no Bayesian source scoring (recency + citations + domain).  
[Why]: Paywalled access key, but poor eval = garbage-in reports.  
[Fix]: Hybrid: MCP for APIs, profile selectors; eval via "score = 0.4*peer_cites + 0.3*recency + 0.3*venue_rank".

[F13]  
[Severity]: CRITICAL  
[Finding]: No async/bridge design: Needs I/O contracts (JSON brief {query, constraints, format}, status {in-progress: {stage, eta}, blocked: {reason}, complete: {report_id}, escalate: {human_query}}), escalation (e.g., "conflicting sources?"). Skill vs agent: Structured skill with loops, not full agent (avoids non-determinism).  
[Why]: First Tess-Crumb payload; poor signaling breaks dispatch template.  
[Fix]: Define schema: input via Obsidian note, output vault file + webhook to Tess.

[F14]  
[Severity]: SIGNIFICANT  
[Finding]: Researcher as "skill with agent properties": Fixed stages + LLM-decided branches/escalations, status via file polling or MCP events. Generalize: Envelope pattern (brief → exec → artifact + metadata).  
[Why]: Ensures reliability; pure agent too autonomous for bridge.  
[Fix]: Spec: "POST /_openclaw/research {brief}; GET /status/{id}".

[F15]  
[Severity]: MINOR  
[Finding]: Novel idea missing: "Uncertainty-first" dispatch—Tess scores query ambiguity, only sends deep research if >threshold, else quick chat.  
[Why]: Saves cost; challenges "always deep" assumption.  
[Fix]: Add pre-filter agent in Tess.

[F16]  
[Severity]: STRENGTH  
[Finding]: Clear stage separation (scoping → planning → loops → synthesis) maps well to Crumb overlays. Verified: Artifact details each with examples.  
[Why]: Provides blueprint for procedural skill. Edge: Loops verifiable via citations.  
[Fix]: N/A

[F17]  
[Severity]: SIGNIFICANT  
[Finding]: Unexplored: Obsidian-native memory (use vaults as vector store for prior research, auto-cite user notes).  
[Why]: Personal OS strength; prevents re-research.  
[Fix]: Integrate Dataview queries as cheap RAG.

[F18]  
[Severity]: MINOR  
[Finding]: Challenge assumption: "Multi-tool heavy" bad for personal—prioritize 3 tools (web, arXiv, PubMed) + local files.  
[Why]: Reduces failure surface.  
[Fix]: Configurable tool whitelist.

[F19]  
[Severity]: SIGNIFICANT  
[Finding]: Creative: "Human-in-loop via Tess escalation"—e.g., pause at synthesis, ping Tess for approval on key claims, using bridge for judgment.  
[Why]: Boosts honesty without full human babysit.  
[Fix]: Build into convergence: if uncertainty>0.5, escalate.

[F20]  
[Severity]: MINOR  
[Finding]: Novel: Connection to scientific workflows—adapt Jupyter agents (nbdev) for traceable research in Obsidian (markdown notebooks).  
[Why]: Makes outputs executable/reproducible.  
[Fix]: Output as Obsidian canvas with linked evals.
---


## Synthesis

### Consensus Findings

**C1. ODR multi-agent architecture is overkill for Claude Code — adopt single-agent, stage-separated pipeline.**
All 4 reviewers independently reached this conclusion. Claude Code provides a single model in a single context window; simulating multi-agent orchestration adds complexity without parallelism benefits. The valuable ODR ideas (stage separation, context isolation, convergence criteria) should be borrowed as patterns, not as an architecture.
Sources: OAI-F6, OAI-F15, GEM-F1, GEM-F4, DS-F4, GRK-F7, GRK-F8.

**C2. Missing async state protocol and I/O contracts for Tess↔Crumb bridge.**
All 4 reviewers flagged the absence of a concrete input/output contract and status signaling protocol — the single most critical gap given the researcher is the first bridge payload and will template future cross-agent dispatch. Need: versioned brief schema, status events (queued/running/blocked/failed/complete), structured escalation, and artifact output contract.
Sources: OAI-F8, OAI-F24, GEM-F2, GEM-F10, DS-F9, GRK-F13, GRK-F14.

**C3. Source laundering / provenance vulnerability is unaddressed.**
All 4 reviewers identified that "source evaluation" is mentioned aspirationally but lacks enforceable mechanisms. Need: source tiering, provenance metadata, deduplication, primary-source requirements, and a source audit appendix. GPT-5.2 additionally flagged the web's saturation with AI-generated content as an aggravating factor.
Sources: OAI-F11, OAI-F19, GEM-F3, DS-F5, DS-F8, GRK-F10, GRK-F12.

**C4. Citation hallucination and grounding problems systematically understated.**
All 4 reviewers noted that vendor blogs understate reliability problems. Citations increase inspectability, not correctness. Systems can misquote, cite irrelevant sources, or attach plausible citations to hallucinated claims. Need: quote-level grounding, claim-evidence mapping, citation verification, and confidence scoring.
Sources: OAI-F4, OAI-F14, GEM-F6, DS-F5, GRK-F9.

**C5. Researcher should be a "skill with agent-like properties" — not a full agent.**
All 4 reviewers converged on this hybrid model: structured procedure with internal branching, convergence evaluation, explicit escalation points, and bounded autonomy. Tess is the always-on agent; the researcher is a bounded pipeline invoked by Tess.
Sources: OAI-F23, GEM-F9, DS-F9, GRK-F14.

**C6. Failure modes and reliability engineering are missing.**
3 of 4 reviewers flagged the absence of: loop detection, budget caps, timeout handling, rate limiting, deadlock detection, and fallback strategies. The artifact describes only the happy path.
Sources: OAI-F5, OAI-F7, DS-F2, GRK-F4, GRK-F9.

**C7. Confirmation bias / adversarial search step needed.**
3 of 4 reviewers identified that research loops can amplify early mistakes by selecting confirmatory sources. Need: counterfactual queries, disconfirming evidence steps, and source diversity metrics.
Sources: OAI-F5, GEM-F6, GRK-F10.

**C8. MCP tool layer preferred for source access, with skill-level profiles for selection.**
3 of 4 reviewers recommended shared MCP tools for API access (Semantic Scholar, arXiv, PubMed, FRED, etc.) with skill-level config selecting which tools + ranking rules per task type. This separates access concerns from research logic.
Sources: OAI-F18, DS-F7, GRK-F12.

**C9. Private/local knowledge integration missing.**
3 of 4 reviewers noted the artifact ignores research on private corpora — vault notes, prior research, downloaded PDFs. Need: dual-source model (public vs personal) with separate provenance labeling.
Sources: OAI-F10, DS-F3, GRK-F17.

**C10. Actionability gap — needs concrete state schemas and implementation blueprint.**
3 of 4 reviewers flagged the gap between conceptual descriptions and what you'd actually build. Need: state object schema, file-based persistence, prompt templates per phase, and a resumability model.
Sources: OAI-F16, DS-F6, GRK-F11.

### Unique Findings

**OAI-F21: "Ledgered build system" metaphor — treat research as a make-like build.** Genuine insight. Each stage produces idempotent artifacts on disk; if inputs unchanged, skip; if a source changes, invalidate downstream. Makes runs resumable, cacheable, and auditable. This maps well to Crumb's file-based architecture.

**OAI-F22: "Verbatim packet" mode for high-stakes claims.** Genuine insight. When honesty is paramount, sometimes the best output is curated primary excerpts with minimal interpretation rather than synthesis. Add `evidence_packet` as a deliverable type alongside `memo`, `lit_review`, etc.

**OAI-F17: Evaluation harness / research benchmark vault.** Genuine insight. A gold set of 10-30 briefs with expected properties enables regression testing of pipeline changes. Solo devs benefit disproportionately.

**GEM-F11: "Director's Cut" annotated report.** Genuine insight. Produce a draft with inline annotations like `[Needs stronger source]`, `[Conflict: A says X, B says Y]`. Surfaces uncertainty transparently as a feature.

**GEM-F12: "Research Program" reusability.** Genuine insight. Save research outputs as reloadable programs for update queries ("What's changed since last month?"). Transforms from query-answering to knowledge-maintenance.

**GEM-F13: Obsidian vault as primary output format.** Genuine insight, and well-aligned with Crumb's existing patterns. Each source becomes a note, claims become notes, final report links to them. Research enriches the vault natively.

**GEM-F14: Structured verification gateway for escalation.** Genuine insight. Present structured multiple-choice decisions at escalation points rather than free-form questions. Reduces friction and provides clearer guidance for resumption.

**GRK-F15: "Uncertainty-first" dispatch from Tess.** Genuine insight. Tess pre-scores query ambiguity and only routes to deep research above a threshold, saving cost on simple lookups. Challenges the "always deep" assumption.

**GRK-F20: Connection to Jupyter/nbdev for traceable research.** Noise for Crumb's context. Obsidian markdown is the native format; Jupyter adds toolchain complexity without clear benefit for a personal OS.

**GRK-F2: Currency claim — 2025 sources "superseded" by o3/o4/Claude 4.x.** Partially genuine. The research does lean on mid-2025 sources, and rapid model evolution means some specifics may date. But the structural patterns (stage separation, convergence criteria, evidence discipline) are model-agnostic and remain valid. The recommendation to supplement with late-2025/early-2026 sources is sound.

**GEM-F4 (academic access / "Librarian" pattern):** Genuine insight on separating search, acquire, and read phases for paywalled content. The `blocked(auth)` escalation pattern aligns with the bridge status protocol.

### Contradictions

**Source access architecture granularity.** OAI recommends "use both MCP + skill-level profiles." DS says "MCP layer is clearly superior." GRK says "hybrid with formula-based scoring." The direction is unanimous (MCP), but the degree of skill-level customization varies. **Flag for human judgment:** how much per-task source customization is needed vs. a simpler MCP-only approach?

**How much of ODR to borrow.** All agree multi-agent is wrong for Crumb, but emphasis varies: OAI says "pattern library, start minimal," GEM says "stage-separated monolith," DS says "single-agent multi-stage with structured phases," GRK says "prototype single-agent, benchmark vs ODR." These are consistent in direction but different in how aggressively to adopt ODR ideas. **Low-stakes disagreement** — start minimal and adopt more as needed.

**Grok's accuracy claims (GRK-F1, GRK-F2).** Grok asserts several specific technical claims as inaccurate (e.g., "Anthropic's research mode is actually extended thinking, not a dedicated pipeline"). GPT-5.2 and DeepSeek do not flag these same claims as incorrect. GRK-F2's assertion that "o3/o4 releases" and "Claude 4.x with native multi-agent orchestration" exist by early 2026 is itself unverifiable here. **Flag for verification** — cross-check Grok's accuracy claims against primary docs before acting on them.

### Action Items

**A1 (Must-fix) — Define Tess↔Crumb I/O contract and status protocol.**
Sources: OAI-F8, OAI-F24, GEM-F2, GEM-F10, DS-F9, GRK-F13, GRK-F14.
What to do: Define a versioned schema covering: input brief (id, query, constraints, audience, depth, deadline, source requirements, budget caps, deliverable type), status events (queued, running, blocked with reason, failed, complete), escalation format (structured questions, not free-form), and output contract (report, evidence index, source list, limitations, open questions, audit log). This becomes the template for all future Tess↔Crumb dispatch.

**A2 (Must-fix) — Design single-agent, stage-separated pipeline architecture.**
Sources: OAI-F6, OAI-F15, GEM-F1, GEM-F4, DS-F4, GRK-F7, GRK-F8.
What to do: Adopt a single supervisor loop with explicit stages: Brief → Plan → Gather → Evaluate → Synthesize → Write. Each stage produces artifacts on disk (brief.json, plan.json, evidence/, topic summaries, report.md). Implement as a skill with agent-like properties — structured procedure with branching, convergence evaluation, and escalation points. No multi-agent orchestration.

**A3 (Must-fix) — Implement source provenance and anti-laundering mechanisms.**
Sources: OAI-F11, OAI-F19, GEM-F3, DS-F5, GRK-F10, GRK-F12.
What to do: Implement source tiering (Tier A: peer-reviewed, official; Tier B: major editorial; Tier C: blogs, forums, SEO — excluded as sole support). Require provenance metadata per source (domain, author, org, date, publication type, ingestion level: FullText/AbstractOnly/SecondaryCitation). Enforce minimum Tier A/B sources for key claims. Include source audit appendix in every report.

**A4 (Must-fix) — Add citation grounding and verification.**
Sources: OAI-F4, OAI-F14, GEM-F6, DS-F5, GRK-F9.
What to do: Every nontrivial claim maps to evidence snippet IDs. Writer can only cite from the evidence store. Add a citation verification pass (lexical/semantic check that cited snippet supports the claim). Mark confidence per claim. Escalate to human when confidence is low.

**A5 (Should-fix) — Add failure mode protections: budgets, loop detection, adversarial search.**
Sources: OAI-F5, OAI-F7, DS-F2, GRK-F4, GRK-F9.
What to do: Define hard budgets (max tool calls, max tokens, max wall-clock time). Add loop detection (repeated similar queries). Implement counterfactual/adversarial queries for key hypotheses. Add "what would change my mind" section requirement.

**A6 (Should-fix) — Build evidence store pattern with structured intermediate artifacts.**
Sources: OAI-F3, OAI-F21, GEM-F5, DS-F6.
What to do: Store retrieved evidence outside the model context as structured snippets (url, title, retrieved_at, quote, hash, tier, confidence). Pass only curated summaries + snippet IDs into the synthesis context. Make each stage idempotent over artifacts on disk (build-system metaphor). Add "Fact Ledger" as the bridge between gather and write phases.

**A7 (Should-fix) — Design escalation points with structured questions.**
Sources: OAI-F9, GEM-F2, GEM-F14, GRK-F19.
What to do: Define explicit gates: scope confirmation, source access (paywall/auth), conflict (material contradictions), high-impact claims. Each gate emits `blocked(waiting_user)` with structured multiple-choice questions, not free-form. Tess relays to user, injects answer, resumes run.

**A8 (Should-fix) — Design MCP tool layer for academic/institutional source access.**
Sources: OAI-F18, DS-F7, GRK-F12.
What to do: Create MCP tools wrapping key APIs (Semantic Scholar, arXiv, PubMed, FRED, Unpaywall) with uniform metadata, rate limiting, and caching. Skill-level profiles select which tools + ranking rules per task type. For paywalled content: separate search → acquire → read phases with auth escalation to user.

**A9 (Should-fix) — Integrate private/vault knowledge alongside public sources.**
Sources: OAI-F10, DS-F3, GRK-F17.
What to do: Dual-source model: public_evidence_store vs personal_knowledge_store. Separate provenance labeling ("Internal note" vs "External source"). Query vault via Obsidian CLI or Dataview as a first-class research source.

**A10 (Defer) — Build evaluation harness / research benchmark vault.**
Sources: OAI-F17.
What to do: Create 10-30 research briefs with expected properties (must cite X, must surface Y caveat, must not rely solely on blogs) for regression testing pipeline changes. Valuable but not blocking initial build.

**A11 (Defer) — Add "Research Program" reusability for update queries.**
Sources: GEM-F12.
What to do: Save research outputs as reloadable programs. On "update" request, reload prior program, check for new sources, produce diff report. High value but second-phase feature.

**A12 (Defer) — Supplement with late-2025/early-2026 sources before spec phase.**
Sources: GRK-F2, OAI-F13.
What to do: Run targeted searches for recent framework releases, agent evaluation benchmarks (AgentBench, WebArena), and updated model capabilities before locking the researcher skill spec. The structural patterns in the artifact are sound; specific model/tool references may need updating.

### Considered and Declined

**GRK-F1 (accuracy claims about vendor capabilities).** Grok asserts specific inaccuracies (e.g., "Anthropic's research mode is extended thinking, not a dedicated pipeline") but doesn't provide primary source evidence. Other reviewers didn't flag these same claims. The artifact's descriptions are at the pattern level, not vendor-specific implementation level, and remain valid at that abstraction. **Reason: incorrect** — the artifact describes patterns, not vendor internals.

**GRK-F3 ("reasoning-optimized models" as nice-to-have).** Grok claims post-o1, "most gains come from tool-augmented chains in base models." This is debatable — reasoning models do provide genuine planning advantages. However, the artifact's point is directionally correct that reasoning models help. The fix (clarify as "nice-to-have") is already captured in the artifact's model-agnostic framing. **Reason: constraint** — the research skill will use whatever model Claude Code provides; model selection isn't a skill-level decision.

**GRK-F18 ("prioritize 3 tools + local files").** Limiting to 3 external tools is premature; the MCP layer (A8) should support a broader set with per-task selection. **Reason: overkill** — the tool whitelist idea is handled by skill-level profiles in A8.

**GRK-F20 (Jupyter/nbdev connection).** Adding Jupyter as an output format adds toolchain complexity without clear benefit for an Obsidian-native vault. **Reason: out-of-scope** — Obsidian markdown is the native format.

**OAI-F25 (variable ranges for numbers like "minutes" and "hundreds of sources").** The artifact uses these as illustrative, not prescriptive. The real budget controls are in A5. **Reason: constraint** — the artifact is a research overview, not a spec; budget specifics belong in the skill design.

**GEM-F3 (ingestion level classification — FullText/AbstractOnly/SecondaryCitation).** While the concept is sound, it's already captured within A3's provenance metadata requirements. The specific three-tier ingestion classification is a good implementation detail to carry forward but doesn't need a separate action item. **Reason: already covered** — subsumed by A3.
