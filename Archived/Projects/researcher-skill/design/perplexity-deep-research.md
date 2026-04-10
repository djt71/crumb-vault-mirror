---
type: research
domain: software
status: complete
source: perplexity-pro
created: 2026-02-21
updated: 2026-02-21
project: researcher-skill
tags:
  - prior-art
  - deep-research
---

<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# what is special about the "deep research" mode that llm's have today?

Deep research modes are basically “LLM-as-researcher”: instead of answering in one shot, the system runs an internal multi-step research workflow (planning → searching → reading → cross-checking → writing) using tools and sometimes multiple agents.[^1_1][^1_2][^1_3][^1_4]

## What makes “deep research” different

- **Explicit planning before answering.** The system decomposes your broad question into sub-questions or a research plan, deciding what to search for, in what order, and how to use intermediate results, rather than just replying directly to your prompt.[^1_3][^1_5][^1_1]
- **Iterative, agent-like loops.** Instead of a single forward pass, an “agent” loop repeatedly drafts, evaluates, and revises answers, sometimes with a separate evaluator model that checks accuracy and sends it back for another round.[^1_2][^1_6][^1_3]
- **Heavy tool and web use.** Deep research modes aggressively call tools: web search, document retrieval, integrations into apps (email, Drive, Notion, etc.), APIs, and code execution, so the model is constantly pulling in fresh, task-specific evidence rather than relying only on pretraining.[^1_6][^1_7][^1_4][^1_1]
- **Long-running, high-token workflows.** They often run for minutes, traverse hundreds of sources, and use large context windows plus long outputs (tens of thousands of tokens) to hold all the intermediate material and final report.[^1_7][^1_8][^1_1][^1_6]
- **Evidence-grounded, cited reports.** The final output is usually a structured report or memo that explicitly cites sources and, in better systems, surfaces where evidence is weak or conflicting instead of hallucinating away uncertainty.[^1_4][^1_9][^1_1][^1_2]
- **Optimized for reasoning over speed.** Under the hood these systems often use “reasoning-first” models (e.g., o-series style) that are trained to break problems into steps, explore alternative paths, backtrack, and verify their own work, trading latency for depth and reliability.[^1_10][^1_11][^1_8][^1_3]


### How this contrasts with “normal chat”

- Normal chat: one LLM call, maybe a couple of retrieval hits, optimized for responsiveness and conversational quality.
- Deep research: orchestrated multi-call, multi-tool, multi-step pipeline that behaves more like a junior analyst doing a literature review and writing a brief.


### Why this feels like a qualitative shift

- You can hand off ill-specified, open-ended tasks (“map the competitive landscape”, “survey current methods in X”) and get a structured, traceable research artifact rather than just an off-the-cuff answer.[^1_12][^1_1][^1_6][^1_10]
- The system is starting to own the *process* (planning, digging, checking) instead of you having to prompt-engineer each step yourself (CoT, RAG prompts, manual web searches, etc.).[^1_5][^1_2][^1_6][^1_3]

If you want, we can walk through what such a mode would actually do step-by-step on a concrete question you care about (e.g., “state of interpretability research in LLMs post-2024”).
<span style="display:none">[^1_13][^1_14][^1_15]</span>

<div align="center">⁂</div>

[^1_1]: https://openai.com/index/introducing-deep-research/

[^1_2]: https://answerrocket.com/deep-research-what-it-is-how-it-works-and-why-it-matters/

[^1_3]: https://arxiv.org/html/2508.12752v1

[^1_4]: https://techcrunch.com/2025/05/01/anthropic-lets-you-connect-apps-to-claude/

[^1_5]: https://leehanchung.github.io/blogs/2025/02/26/deep-research/

[^1_6]: https://www.emergentmind.com/topics/deep-research-llm-agents

[^1_7]: https://arstechnica.com/ai/2025/05/claudes-ai-research-mode-now-runs-for-up-to-45-minutes-before-delivering-reports/

[^1_8]: https://www.mindstudio.ai/blog/openai-o1

[^1_9]: https://www.llmwatch.com/p/everything-to-know-about-deep-research

[^1_10]: https://theaiconsultinglab.com/deep-research-ai-what-is-it-and-how-do-i-use-it/

[^1_11]: https://blog.promptlayer.com/openai-vs-deepseek-an-analysis-of-r1-and-o1-models/

[^1_12]: https://www.anthropic.com/news/accelerating-scientific-research

[^1_13]: https://www.youtube.com/watch?v=68Odxo4FdiA

[^1_14]: https://www.anthropic.com/research/tracing-thoughts-language-model

[^1_15]: https://community.openai.com/t/deep-research-removed-from-o1-pro/1267091


---

# yes, i'd like the details pls

At a technical level, “deep research” is an agentic pipeline wrapped around an LLM that owns the whole research loop: scoping → planning → searching/reading → evaluating → synthesizing → writing, often with minimal further prompting from you.[^2_1][^2_2][^2_3]

## 1. Scoping and clarifying your request

Before it does any “research”, the system first tries to understand what you actually want.

- It may ask you follow-up questions, gather constraints (audience, length, date cutoffs, domains), and then create an internal “research brief” that defines the task.[^2_4][^2_2][^2_1]
- This brief becomes the spec for the rest of the pipeline: key questions to answer, what counts as in-scope vs out-of-scope, and what the final artifact should look like (memo, lit review, FAQ, comparison table, etc.).[^2_4][^2_1]

Example: You say “Deep dive on modern LLM interpretability.” It might clarify: focus on mechanistic interpretability vs behavioral? code-level techniques? timeframe after 2023? target audience?

## 2. Planning and decomposition

Once scoped, the system generates a research plan instead of jumping straight to prose.

- A “planner” agent takes your query and breaks it into sub-problems or sections that roughly map to the outline of the final report.[^2_5][^2_2][^2_6]
- It plans search trajectories: which sub-question to tackle first, what initial search queries to run, and what kinds of sources to look for (papers, benchmarks, blogs, documentation, news).[^2_2][^2_6]
- Architecturally, this is the “task planning” component that every deep research system has: query processing, intent classification, expansion, and outline creation.[^2_7][^2_1]

You can think of this as the AI doing the “research design” step a human analyst would normally sketch on a whiteboard.

## 3. Multi-step, tool-heavy research loops

Then the system actually goes out and gathers evidence in iterative loops.

- It issues search queries, follows links, scrapes pages or PDFs, and summarizes relevant chunks into its working context.[^2_8][^2_3][^2_2]
- A typical cycle is a ReAct-style loop: Plan → Act (call a tool like web search or document loader) → Observe (read results) → update plan, repeated many times.[^2_6][^2_2]
- Sub-agents may run in parallel on different subtopics, each with its own context window, then send their findings back to a “supervisor” agent that coordinates when enough evidence has been collected.[^2_5][^2_1][^2_4]

Example loop for one sub-question:

1. Plan: “I need recent empirical results on activation patching in transformer models.”
2. Act: search the web, fetch 3–10 likely papers or posts.
3. Observe: extract and summarize key findings, note methods and dates.
4. Decide: if coverage is thin or outdated, adjust queries or search another venue (arXiv, blogs, GitHub) and repeat.

This is the opposite of a one-shot chat completion: it’s a long-running, branching exploration.

## 4. Source evaluation, fact-checking, and memory

Deep research systems usually bake in some quality control and state management.

- They keep a structured memory or state: which sub-questions are resolved, which sources have been read, and what preliminary conclusions exist.[^2_7][^2_1]
- They implement source evaluation: ranking sources, cross-checking claims between them, and sometimes explicitly marking conflicting evidence rather than silently averaging it.[^2_1][^2_7]
- Some pipelines use self-critique or “reflection” steps, where an LLM re-evaluates its own summaries and asks, “What’s missing? Where might I be wrong? What needs verification?” before moving on.[^2_2][^2_6]

This is why deep research can sometimes surface caveats (“evidence is thin after 2024 for X”) where normal chat would bluff.

## 5. Synthesis and report writing

Once the system thinks it has enough raw material, it switches to synthesis.

- A final “writer” pass takes the research brief plus the collected notes/summaries and turns them into a structured document: sections, comparisons, tables, citations, and sometimes recommendations.[^2_6][^2_4][^2_1]
- The outline from the planning phase usually becomes the skeleton of the final report, so the structure is aligned with how evidence was gathered.[^2_5][^2_6]
- Reports often include inline citations or reference lists so you can inspect the underlying material, which is a big part of the value relative to opaque chat outputs.[^2_3][^2_8][^2_2]

In more advanced systems, there may be a “reviewer” agent that critiques the draft and sends it back for revisions before you ever see it.[^2_9][^2_1]

## 6. Under-the-hood model differences

Two important under-the-hood pieces make this work better than you just manually chaining prompts:

- **Reasoning-optimized base models.** Many deep research systems sit on top of models specifically tuned for long-chain reasoning and browsing: they’re rewarded during training for planning, adapting, and backtracking across many tool calls.[^2_9][^2_3][^2_2]
- **Agentic / multi-agent architectures.** Implementations range from monolithic (one model doing everything) to explicit multi-agent (planner, researcher(s), summarizer, reviewer), or pipeline-based systems where each stage is a separate, well-defined step.[^2_7][^2_1][^2_6]

From your perspective as a user, the key difference is: you give one high-level instruction and the system autonomously runs a whole research workflow that a human junior analyst or PhD student would otherwise run manually.

***

If you want to get concrete, we can pick a topic you actually care about (e.g., “mechanistic interpretability progress post-2024”) and I can sketch the exact sub-questions, search loops, and agent roles such a deep research run would implement.
<span style="display:none">[^2_10][^2_11][^2_12][^2_13][^2_14][^2_15]</span>

<div align="center">⁂</div>

[^2_1]: https://www.emergentmind.com/topics/deep-research-workflows

[^2_2]: https://blog.promptlayer.com/how-deep-research-works/

[^2_3]: https://developers.openai.com/api/docs/guides/deep-research/

[^2_4]: https://blog.langchain.com/open-deep-research/

[^2_5]: https://www.reddit.com/r/LLMDevs/comments/1jpfa8f/i_built_open_source_deep_research_heres_how_it/

[^2_6]: https://www.together.ai/blog/open-deep-research

[^2_7]: https://shchegrikovich.substack.com/p/4-architectures-of-deep-research

[^2_8]: https://openai.com/index/introducing-deep-research/

[^2_9]: https://arxiv.org/html/2504.18765v3

[^2_10]: https://www.newline.co/@zaoyang/data-pipelines-for-llms-key-steps--b42fa4f3

[^2_11]: https://www.reddit.com/r/ChatGPTPro/comments/1in87ic/mastering_aipowered_research_my_guide_to_deep/

[^2_12]: https://www.zenml.io/blog/steerable-deep-research-building-production-ready-agentic-workflows-with-controlled-autonomy

[^2_13]: https://aclanthology.org/2025.findings-emnlp.320.pdf

[^2_14]: https://www.alphaxiv.org/overview/2501.04227v1

[^2_15]: https://quansight.com/post/anatomy-of-a-local-pdf-deep-research-pipeline/


---

# How does Open Deep Research differ from other agentic workflows

Open Deep Research (ODR) is basically a *reference* deep-research pipeline, designed to be simple, modular, and configurable, rather than a monolithic “assistant with magic sauce.” It differs from a lot of agentic setups in three main ways: how it uses multi‑agent structure, how it controls context/latency, and how much is made explicit and open.[^3_1][^3_2][^3_3]

## Multi‑agent design: where agents are used

- ODR uses a **supervisor + research sub‑agents** pattern: a top-level agent decomposes the brief into subtopics and spawns focused research agents for each one.[^3_2]
- Crucially, **multi‑agent is only used for research, not writing**: sub‑agents gather and clean evidence, then a single final LLM pass writes the report, avoiding the disjoint, inconsistent section-writing that many naive multi-agent workflows fall into.[^3_2]
- Many generic agentic workflows let multiple agents both research and *write* in parallel, which can lead to contradictory tone, overlapping content, and poor global coherence in the final document.[^3_4][^3_2]


## Context and token management

- ODR is explicit about **context isolation**: each sub‑agent works on its own subtopic and returns a compressed summary, not raw web dumps, to the supervisor.[^3_2]
- This reduces **token bloat and context clash**, where a single agent juggles all topics and gets confused or drops threads as the context window fills with heterogeneous tool call outputs.[^3_3][^3_2]
- Many agentic workflows just stuff all tool results into one running context, which is easy to build but scales poorly as research depth and topic multiplicity grow.[^3_5][^3_4]


## Planning, reflection, and “convergence”

- ODR bakes in a simple but explicit **plan → search → gap-check → iterate** loop: the planner generates queries, runs them, and then asks an LLM whether knowledge gaps remain before deciding to stop.[^3_1]
- It draws directly on **self-reflection** ideas: a reflection step judges if the current sources are sufficient, steering additional search only where needed.[^3_3][^3_1]
- Many agentic workflows either (a) run a fixed number of search/reflect steps, or (b) leave “when to stop” implicit, which can produce over-searching, under-searching, or non-deterministic behavior.[^3_5][^3_4]


## Explicit separation of stages

- ODR’s architecture is intentionally **stage-separated**: compress chat history into a brief → supervisor plans subtopics → sub‑agents research and return cleaned findings → single writer composes final output.[^3_1][^3_2]
- That separation is motivated by real failure cases they describe (parallel section-writing, bloated supervisor context, etc.), and the write-up is unusually candid about what *didn’t* work in earlier iterations.[^3_2]
- Many other agentic systems blur these boundaries (e.g., agents both search and write in the same loop), which makes behavior harder to reason about and tune.[^3_4][^3_3]


## Open, configurable, and framework‑oriented

- ODR is published as **open, framework-level code**: you’re expected to swap in your own models, search tools, and MCP tools; it’s not a closed black-box feature.[^3_2]
- That contrasts with proprietary deep research modes (OpenAI, Anthropic) where the pipeline is hidden and you only see the external behavior.[^3_6][^3_4]
- It’s also more opinionated than many “generic” agent frameworks (CrewAI, SmolAgents, etc.) because it’s tuned specifically for research tasks (multi-hop queries, citation-rich reports), not arbitrary automation.[^3_3][^3_1][^3_2]


## Cost / quality tradeoffs and MoA style

- Together’s Open Deep Research (and similar open implementations) explicitly discuss **model selection and cost tradeoffs**, e.g., using cheaper/faster models for some roles and heavier reasoning models only where necessary.[^3_5][^3_1]
- This is closer to a **mixture-of-agents** mindset than “one giant model does everything,” and the design notes emphasize tuning for quality *and* latency/cost.[^3_1]
- Many hobbyist agentic workflows don’t really optimize this; they just call the same big model for every step, which is simpler but less efficient.[^3_7][^3_4]

If you want, we can map this to something concrete: e.g., compare “ODR-style” vs “single ReAct agent + tools” for a research task you actually run (say, surveying R1 vs o1 vs DeepSeek-R1 reasoning models) and spell out what changes in practice.
<span style="display:none">[^3_10][^3_11][^3_12][^3_13][^3_14][^3_15][^3_16][^3_8][^3_9]</span>

<div align="center">⁂</div>

[^3_1]: https://www.together.ai/blog/open-deep-research

[^3_2]: https://blog.langchain.com/open-deep-research/

[^3_3]: https://www.emergentmind.com/topics/step-deepresearch

[^3_4]: https://www.emergentmind.com/topics/deep-research-workflows

[^3_5]: https://www.emergentmind.com/topics/deepresearch-systems

[^3_6]: https://openai.com/index/introducing-deep-research/

[^3_7]: https://opendatascience.com/when-to-use-agentic-ai-workflows-and-when-simpler-is-better/

[^3_8]: https://www.zenml.io/blog/steerable-deep-research-building-production-ready-agentic-workflows-with-controlled-autonomy

[^3_9]: https://relevanceai.com/blog/the-definitive-guide-understanding-ai-agents-vs-ai-workflows

[^3_10]: https://www.reddit.com/r/ChatGPTPro/comments/1m4yaaj/deep_dive_and_demos_ai_assistants_v_ai_agents/

[^3_11]: https://www.reddit.com/r/ExperiencedDevs/comments/1lz4dmj/ai_skeptic_went_all_in_on_an_agentic_workflow_to/

[^3_12]: https://www.facebook.com/groups/DeepNetGroup/posts/2299985437060992/

[^3_13]: https://www.sciencedirect.com/science/article/pii/S1566253525006712

[^3_14]: https://www.reddit.com/r/LocalLLaMA/comments/1chkl62/langchain_vs_llamaindex_vs_crewai_vs_custom_which/

[^3_15]: https://mitsloan.mit.edu/ideas-made-to-matter/agentic-ai-explained

[^3_16]: https://arxiv.org/html/2508.05668v3

