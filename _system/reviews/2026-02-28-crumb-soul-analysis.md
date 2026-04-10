---
type: review
status: complete
created: 2026-02-28
updated: 2026-02-28
artifact: "Crumb's SOUL.md analysis — async analytical output operationalization"
review_mode: full
reviewers: [openai, google, deepseek, grok]
dispatched: 4
succeeded: 4
failed: 0
---

# Peer Review: Crumb SOUL.md Analysis

**Artifact:** Crumb's analysis of Tess's first browser-driven research output failure and proposed SOUL.md fix (Analysis Standards section, ~80-100 tokens)

**Review date:** 2026-02-28

**Safety gate:** PASSED — no sensitive patterns detected

---

## OpenAI (gpt-5.2)

**Model:** gpt-5.2-2025-12-11 | **Tokens:** 1,793 prompt / 2,439 completion

- **[OAI-F1]** [STRENGTH]: The diagnosis that many "missing principles" already exist in SOUL.md is plausibly correct. It reframes the issue from "missing values" to "values not triggering in a new task context," which is often the real prompt failure mode.

- **[OAI-F2]** [SIGNIFICANT]: The "real gap is async analytical output operationalization" is plausible but incomplete: the more central failure may be *tool-mediated evidence handling* (source quality, corroboration, quoting, and separating observation vs inference) rather than "async" per se. A synchronous conversation can still produce the same failures if the agent is browsing and summarizing weak sources. **Fix:** Add explicit evidence handling rules for tool output: cite/quote primary sources, note provenance, corroborate claims, and label confidence.

- **[OAI-F3]** [SIGNIFICANT]: The artifact under-specifies what "Demand evidence before committing" means in research, and also misses *recommendation hygiene* (when to recommend architectural change vs incremental fixes) and *decision framing* (options, tradeoffs, reversibility). **Fix:** Add bullets like: "Provide options (status quo / incremental / redesign) with explicit tradeoffs," "Prefer reversible recommendations," and "State what would change your mind."

- **[OAI-F4]** [STRENGTH]: The proposed "Analysis Standards" section is directionally the right type of fix: a small bridging layer that maps existing principles to the research/report genre.

- **[OAI-F5]** [SIGNIFICANT]: The ~80-100 token fix may be too narrow if Tess produces other non-conversational artifacts (plans, specs, postmortems, emails). **Fix:** Reframe header from "Analysis Standards" to "Non-interactive Deliverables Standards" and enumerate covered deliverable types.

- **[OAI-F6]** [CRITICAL]: The proposed bullets are good principles but not sufficiently *enforceable* — they don't force the model into a verifiable structure (Evidence -> Observations -> Inferences -> Recommendations). Without a required scaffold, models often comply superficially. **Fix:** Add a minimal required template for analytical outputs.

- **[OAI-F7]** [SIGNIFICANT]: The fix doesn't explicitly address citation behavior or "quoting vs paraphrasing," which is central when summarizing social media posts. **Fix:** Add one bullet: "When using web/social sources, quote key lines, link source, and label as 'claim by X' unless independently verified."

- **[OAI-F8]** [SIGNIFICANT]: Adding "take your time" is underspecified operationally; speed pressure comes from reward shaping and token budgeting, not just wording. **Fix:** Encode a lightweight two-pass behavior for research: "(1) list unknowns/assumptions + plan; (2) produce report."

- **[OAI-F9]** [STRENGTH]: The addition "ask clarifying questions / state assumptions explicitly if clarification isn't available" is a strong, high-leverage improvement for async contexts.

- **[OAI-F10]** [SIGNIFICANT]: Failure modes remain: agent may comply cosmetically while still importing bias from a single source, or may "launder" uncertainty with polished prose. **Fix:** Add explicit anti-pattern bans and introduce a "stop condition" ("If evidence is thin, output 'insufficient basis' + next steps").

- **[OAI-F11]** [SIGNIFICANT]: Another likely failure mode: *scope creep* — turning "summarize these posts" into "here's the strategic rewrite of your infrastructure." **Fix:** Add: "Stay within the asked scope; if you think a bigger change is warranted, propose it as an optional appendix with justification."

- **[OAI-F12]** [SIGNIFICANT]: The fix doesn't address evaluation/QA: no mechanism to check whether research output meets the standards. **Fix:** Add a short pre-flight checklist or implement an automated "report linter" step.

- **[OAI-F13]** [SIGNIFICANT]: The claim "Treat third-party output as untrusted… wasn't triggered" may be less about missing text and more about *salience/priority* — in long prompts, critical constraints can be diluted. **Fix:** Place "Analysis Standards" near other high-priority boundaries.

- **[OAI-F14]** [SIGNIFICANT]: UNVERIFIABLE CLAIM: "SOUL.md loads for every voice agent session, including isolated cron sessions (OpenClaw binds the agent identity to all sessions for that agent)."

- **[OAI-F15]** [SIGNIFICANT]: UNVERIFIABLE CLAIM: "crumb-tess-bridge… 37 tasks, 897 tests, and 8 peer review rounds."

- **[OAI-F16]** [SIGNIFICANT]: UNVERIFIABLE CLAIM: "1,090-token compressed prompt budget… 1,910 tokens of headroom from the original 3,000-token baseline."

- **[OAI-F17]** [MINOR]: The table mapping personal preferences to SOUL.md equivalents could overstate equivalence (e.g., "don't volunteer unsolicited opinions" is not the same as "push back on poor thinking"). **Fix:** Reword as "partial coverage" and explicitly note deltas.

- **[OAI-F18]** [SIGNIFICANT]: Blind spot: the analysis assumes prompt text is the main lever; the failure may also be driven by workflow (no explicit request for citations, no acceptance criteria, no review step) and by tool UX. **Fix:** Pair the prompt change with workflow changes.

---

## Google (gemini-3-pro-preview)

**Model:** gemini-3-pro-preview | **Tokens:** 1,924 prompt / 894 completion (1,625 thinking)

- **[GEM-F1]** [STRENGTH]: The distinction between conversational interaction (immediate feedback) and asynchronous research (no feedback loop) is insightful. It accurately explains why principles like "push back on poor thinking" failed to trigger — there was no "thinking" to push back on in real-time. This prevents the bloat of redundant principles.

- **[GEM-F2]** [SIGNIFICANT]: Potential prompt contradiction: "Efficiency is respect" vs. the proposed "take your time" counterweight. LLMs often struggle with nuanced contextual switching between these. The model may prioritize the stronger, earlier instruction. **Fix:** Explicitly qualify the existing "Efficiency" rule: "Efficiency is respect in conversation; thoroughness is respect in analysis."

- **[GEM-F3]** [SIGNIFICANT]: Unclear trigger for "Analysis Mode." The proposed fix relies on the model self-identifying that it is in "Research/Brief/Analysis" mode. If the user prompt is ambiguous (e.g., "Check out this guy"), the agent might default to conversational mode, bypassing the new standards entirely. **Fix:** Ensure the task dispatch prompt explicitly labels the request type as "Research" or "Analysis."

- **[GEM-F4]** [SIGNIFICANT]: UNVERIFIABLE CLAIM: OpenClaw's session architecture claim that SOUL.md loads in isolated cron sessions. If cron sessions use a stripped-down prompt to save tokens/latency, this fix will not deploy. **Fix:** Verify in the OpenClaw codebase before applying.

- **[GEM-F5]** [MINOR]: Missing "Negative Constraint" for sycophancy — the analysis notes that report sycophancy looks like "this validates your bet" but the fix doesn't add a specific negative constraint against assuming the user's hypothesis is true by default. **Fix:** Add: "Treat the user's premise as a hypothesis to be tested, not a conclusion to be proven."

- **[GEM-F6]** [STRENGTH]: Token budget management shows strong operational discipline by calculating costs (~80-100 tokens) against the compressed budget (1,090 tokens).

---

## DeepSeek (deepseek-reasoner / V3.2-Thinking)

**Model:** deepseek-reasoner | **Fingerprint:** fp_eaab8d114b_prod0820_fp8_kvcache | **Tokens:** 1,832 prompt / 1,769 completion (249 reasoning)

- **[DS-F1]** [STRENGTH]: The diagnosis correctly identifies a mode-mismatch failure. Crumb's mapping of the six personal preferences to existing SOUL.md principles is accurate. The insight that SOUL.md is optimized for a conversational feedback loop is sharp and likely correct.

- **[DS-F2]** [SIGNIFICANT]: The diagnosis may be incomplete by focusing solely on "operationalization." It doesn't deeply explore if the failure was also due to **tool naivety** (first use of a browser tool on social media) or **agent over-eagerness** to please with a new capability. The proposed fix addresses the output format but not the root cause of overclaim.

- **[DS-F3]** [SIGNIFICANT]: The fix is too narrow — it covers only "research, briefs, or written analysis" but ignores other async output modes (code, structured data summaries, drafting emails) that could suffer from similar "no real-time feedback" issues with different failure signatures.

- **[DS-F4]** [STRENGTH]: The content of the proposed section is highly targeted and valuable. The examples directly counteract the observed failures (overclaim, cheerleading, poor sourcing). This is a precise intervention.

- **[DS-F5]** [MINOR]: The proposed wording "The same rules apply to written output as to conversation" is somewhat circular. If the rules weren't triggered in writing, simply restating they apply may not help.

- **[DS-F6]** [SIGNIFICANT]: Failure mode: **New tool misapplication.** The fix doesn't address the core challenge of an agent using a new tool for the first time on a complex source. Tess might still perform shallow pattern-matching but now just *label* confidence as low without improving analysis quality.

- **[DS-F7]** [SIGNIFICANT]: Failure mode: **Principle conflict.** The new "take your time" principle conflicts with SOUL.md's existing "Efficiency is respect" energy. The agent might experience internal conflict or inconsistently apply principles.

- **[DS-F8]** [SIGNIFICANT]: Failure mode: **Over-correction into inaction.** Emphasis on evidence and stating assumptions could cause the agent to become overly cautious, refusing to produce synthesized insight without "perfect" evidence.

- **[DS-F9]** [SIGNIFICANT]: UNVERIFIABLE CLAIM: OpenClaw's session architecture — "SOUL.md loads for every voice agent session, including isolated cron sessions." Logic is sound if the claim is true, but cannot be verified without source code access.

- **[DS-F10]** [MINOR]: The token budget claim (1,910 tokens of headroom) is unverifiable without the exact compression algorithm, but the core point that there's room for 100 tokens is logically derived.

- **[DS-F11]** [SIGNIFICANT]: Blind spot: **Assumes prompt addition = behavior change.** Doesn't consider limitations of LLM context windows, prompt positioning, or the possibility that existing principles were loaded but overridden by other factors (base model tendencies, tool-use excitement).

- **[DS-F12]** [SIGNIFICANT]: Blind spot: **Neglects the mechanic agent.** Context states Tess has a mechanic agent (background, local LLM). The fix focuses only on the voice agent. Doesn't consider whether the mechanic agent should enforce quality control on async output.

- **[DS-F13]** [SIGNIFICANT]: Blind spot: **No validation plan.** The analysis proposes a change but doesn't suggest how to validate its efficacy (e.g., a test protocol for the next research request).

- **[DS-F14]** [STRENGTH]: Strong systemic thinking — tracing the failure to a mismatch between system design and a new use case rather than just blaming the agent.

---

## Grok (grok-4-1-fast-reasoning)

**Model:** grok-4-1-fast-reasoning | **Tokens:** 2,007 prompt / 1,258 completion (1,302 reasoning)

- **[GRK-F1]** [SIGNIFICANT]: UNVERIFIABLE CLAIM: Specific SOUL.md quote mappings in the table cannot be independently verified without the full SOUL.md text. If quotes are paraphrased or inaccurate, the diagnosis is overstated. **Fix:** Provide or link full SOUL.md excerpts for verification before deployment.

- **[GRK-F2]** [SIGNIFICANT]: Diagnosis correctly identifies conversational vs. async mode gap but overlooks that SOUL.md's "Second Register" or "Serious Mode" sections might already bridge this implicitly for analytical tasks. **Fix:** Cross-reference proposed standards against full "Serious Mode" and "Second Register" content.

- **[GRK-F3]** [MINOR]: Table omits explicit handling of "Write like a smart colleague" beyond "Efficiency is respect," ignoring verbosity in reports as a separate failure vector.

- **[GRK-F4]** [STRENGTH]: Diagnosis accurately pinpoints sycophancy surface forms differing by mode (e.g., "Great question!" vs. "validates your bet"). Sharp insight.

- **[GRK-F5]** [SIGNIFICANT]: Proposed "Analysis Standards" is too narrow — covers only "research, briefs, or written analysis" but ignores other async outputs like status updates, tool summaries, or crumb-tess-bridge handoffs. **Fix:** Broaden to "any async or written output" or add separate "Async Workflow Standards."

- **[GRK-F6]** [SIGNIFICANT]: Proposed section restates "same rules apply... no cheerleading, no fabrication" without adaptation, contradicting the diagnosis that principles don't operationalize for async. Circular logic weakens fix efficacy. **Fix:** Replace with mode-specific operationalizations.

- **[GRK-F7]** [MINOR]: Adds adapted versions of two preferences but doesn't justify why the other four don't need async tweaks. Inconsistent application.

- **[GRK-F8]** [STRENGTH]: Token estimate (~80-100) and budget check is pragmatic and conservative.

- **[GRK-F9]** [CRITICAL]: Failure mode unaddressed: Mechanic agent (local LLM) likely doesn't load SOUL.md identically, so research tool outputs could bypass fixes. If mechanic handles tools async, core issue persists. **Fix:** Confirm/align mechanic prompt or route analysis through voice agent.

- **[GRK-F10]** [SIGNIFICANT]: Failure modes ignore prompt drift in long sessions or tool chaining; browser tool amplifies untrusted X posts without "gap analysis." **Fix:** Add "Before integrating tool outputs, validate against proven infrastructure."

- **[GRK-F11]** [SIGNIFICANT]: UNVERIFIABLE CLAIM: Isolated cron sessions load full SOUL.md. If cron uses truncated/minimal prompt, fix won't apply. **Fix:** Verify via OpenClaw logs or docs; test staging deployment.

- **[GRK-F12]** [SIGNIFICANT]: Blind spot: No mention of testing the fix, despite context noting 897 tests/8 reviews for crumb-tess-bridge. Production change without validation plan. **Fix:** Propose A/B test or peer review round for updated SOUL.md.

- **[GRK-F13]** [SIGNIFICANT]: Blind spot: Assumes browser tool doesn't need separate guidelines, but Tess amplified untrusted X posts directly. Tool-specific trust calibration missing. **Fix:** Add bullet: "Tool outputs (e.g., social media) are hypotheses, not facts — require primary validation."

- **[GRK-F14]** [MINOR]: UNVERIFIABLE CLAIM: Staging path `_openclaw/staging/SOUL.md` and token stats (1,090 compressed, 1,910 headroom from 3,000 baseline).

- **[GRK-F15]** [STRENGTH]: Identifies exact gap (async operationalization) without bloating prompt verbatim with six preferences. Elegant, targeted reasoning.

---

## Cross-Reviewer Consensus

### Converging Findings (3+ reviewers agree)

1. **Fix scope too narrow** (OAI-F5, DS-F3, GRK-F5): All three note the section targets "research, briefs, or written analysis" but misses other async output modes. Consensus fix: broaden the scope.

2. **"Take your time" conflicts with "Efficiency is respect"** (OAI-F8, GEM-F2, DS-F7): Three reviewers flag the potential contradiction. Consensus fix: qualify the efficiency principle by context (conversation vs. analysis).

3. **No validation plan** (OAI-F12, DS-F13, GRK-F12): Three reviewers note the absence of a testing strategy for the proposed change.

4. **UNVERIFIABLE: SOUL.md loads in cron sessions** (OAI-F14, GEM-F4, DS-F9, GRK-F11): All four flag this architectural claim as unverifiable.

5. **Tool-specific evidence handling missing** (OAI-F2, OAI-F7, DS-F2, DS-F6, GRK-F13): Multiple reviewers note the fix addresses output format but not source evaluation — particularly for browser/social media tool outputs.

6. **Mechanic agent blind spot** (DS-F12, GRK-F9): Two reviewers (one CRITICAL) flag that the mechanic agent may not load SOUL.md and could bypass the fix entirely.

7. **Circular "same rules apply" bullet** (DS-F5, GRK-F6): Two reviewers flag the restating of existing rules as potentially ineffective.

### Critical Findings (require action)

- **OAI-F6**: Proposed bullets lack enforceable structure. Need a required scaffold (Evidence -> Observations -> Inferences -> Recommendations).
- **GRK-F9**: Mechanic agent bypass risk. Must confirm/align mechanic prompt or route analysis through voice agent.

### Unique Valuable Findings

- **GEM-F3**: Unclear trigger mechanism — how does the model know it's in "analysis mode" vs "conversation mode"? Task dispatch labeling needed.
- **GEM-F5**: Missing negative constraint: "Treat the user's premise as a hypothesis to be tested, not a conclusion to be proven."
- **DS-F8**: Over-correction risk — agent becomes too cautious, refuses to synthesize.
- **OAI-F11**: Scope creep failure mode — turning "summarize these posts" into "rewrite your infrastructure."
- **OAI-F13**: Prompt position salience — new section may be diluted in long prompts.

---

---

## Synthesis (Crumb)

### Consensus Findings

**1. Fix scope too narrow** (OAI-F5, DS-F3, GRK-F5)
Three reviewers agree the "Analysis Standards" header is too narrow — it covers only "research, briefs, or written analysis" but other async output modes could have similar failures. The broadening proposals range from "any async output" (GRK-F5) to "non-interactive deliverables" (OAI-F5).

**Assessment:** Valid but needs calibration. Status updates and bridge handoffs have different quality requirements than analytical output. Broadening to "Written Deliverables" captures the right scope without overreaching into mechanical operations. The failure pattern (overclaiming, cheerleading, ungrounded recommendations) is specific to work products that involve judgment and synthesis.

**2. "Take your time" conflicts with "Efficiency is respect"** (OAI-F8, GEM-F2, DS-F7)
Three reviewers flag the potential contradiction. GEM-F2 has the cleanest resolution: "Efficiency is respect in conversation; thoroughness is respect in analysis."

**Assessment:** Valid and must-fix. Without explicit qualification, the model will prioritize the earlier, stronger instruction. Gemini's formulation is the right fix.

**3. No validation plan** (OAI-F12, DS-F13, GRK-F12)
Three reviewers note the absence of a testing strategy. GRK-F12 specifically contrasts this with the 897-test rigor of the crumb-tess-bridge.

**Assessment:** Valid. The next research assignment is the natural test. Should be explicitly planned rather than left implicit.

**4. SOUL.md loads in isolated cron sessions** (OAI-F14, GEM-F4, DS-F9, GRK-F11)
All four reviewers flag this claim as unverifiable. They're correct that they can't verify it. OpenClaw's architecture binds agent identity (including workspace files) to all sessions for that agent — isolated sessions get fresh conversation history but the same system prompt. This is architecturally sound but should be empirically verified before relying on it.

**5. Tool-specific evidence handling missing** (OAI-F2, OAI-F7, DS-F2, DS-F6, GRK-F13)
Multiple reviewers note the fix addresses output formatting but not source evaluation methodology. OAI-F7 is the most concrete: "When using web/social sources, quote key lines, link source, and label as 'claim by X' unless independently verified."

**Assessment:** The strongest finding across all reviewers. The proposed fix tells Tess "don't overclaim" but doesn't tell her "evaluate source quality." This is the gap between output discipline and input discipline. Must-fix.

**6. Circular "same rules apply" bullet** (DS-F5, GRK-F6)
Two reviewers flag the last bullet ("The same rules apply to written output as to conversation: no cheerleading, no fabrication, no ungrounded claims") as restating existing rules that already failed to trigger. If they didn't work implicitly, restating them won't help.

**Assessment:** Valid. Replace with something concrete.

### Unique Findings

**GEM-F3 — No trigger mechanism for "analysis mode."** How does the model know it's producing analysis vs. having a conversation? If the task prompt is ambiguous ("check out this person"), the agent may never activate the new standards. **Genuine insight** — the cron job dispatch prompt should explicitly label the task type.

**GEM-F5 — "Treat the user's premise as a hypothesis to be tested, not a conclusion to be proven."** Directly addresses the "validates your bet" failure mode. **Genuine insight** — this is a high-leverage one-liner.

**OAI-F6 — Need enforceable scaffold, not just principles.** Evidence → Observations → Inferences → Recommendations. **Genuine insight but wrong venue** — a structural template belongs in the research session prompt, not the system prompt. SOUL.md sets behavioral principles; the task prompt sets output structure.

**OAI-F11 — Scope creep failure mode.** Tess turned "research this person's posts" into "here's how to rewrite your infrastructure." **Genuine insight** — add a scope discipline bullet.

**DS-F8 — Over-correction risk.** The fix could make Tess so cautious she refuses to synthesize. **Genuine concern but not addressable in the prompt** — monitor in practice.

**OAI-F13 — Prompt position salience.** In long prompts, later sections get diluted. Place new section near existing high-priority boundaries. **Practical insight** — position matters.

### Contradictions

No significant contradictions between reviewers. All agree the diagnosis is directionally correct. Disagreement is on fix scope (narrow vs. broad) and fix type (principles vs. structural enforcement), not on the underlying problem.

### Action Items

| ID | Classification | Source | Action |
|----|---------------|--------|--------|
| A1 | **Must-fix** | OAI-F5, DS-F3, GRK-F5 | Broaden section scope from "Analysis Standards" to "Written Deliverables" — cover analytical output and research briefs without overreaching into mechanical operations |
| A2 | **Must-fix** | OAI-F2, OAI-F7, GRK-F13 | Add source/tool trust calibration: cite sources, quote key claims, label provenance, treat tool output as hypothesis not fact |
| A3 | **Must-fix** | OAI-F8, GEM-F2, DS-F7 | Qualify "Efficiency is respect" with contextual switch: efficiency in conversation, thoroughness in analysis. Modify the existing SOUL.md line, don't just add a new one |
| A4 | **Should-fix** | DS-F5, GRK-F6 | Replace circular "same rules apply" bullet with concrete operationalization (e.g., scope discipline per OAI-F11) |
| A5 | **Should-fix** | GEM-F5 | Add "Treat the user's premise as a hypothesis to be tested, not a conclusion to be proven" |
| A6 | **Should-fix** | OAI-F12, DS-F13, GRK-F12 | Plan explicit validation: next research assignment evaluated against new standards, results logged |
| A7 | **Should-fix** | GEM-F3 | Ensure research cron job dispatch prompts explicitly label the task type as "Research" or "Analysis" — so the model knows to activate the new standards |
| A8 | **Defer** | OAI-F6 | Enforceable scaffold/template (Evidence → Observations → Recommendations). Belongs in the research session prompt template (TOP-046), not SOUL.md |
| A9 | **Defer** | DS-F8 | Monitor for over-correction (excessive caution). Address in practice if it emerges, not preemptively in the prompt |
| A10 | **Done** | OAI-F14, GEM-F4, DS-F9, GRK-F11 | SOUL.md loads in isolated cron sessions — verified via one-shot cron job. Agent quoted "cargo rots on the dock" from SOUL.md in isolated session. |

### Considered and Declined

| Finding | Justification | Category |
|---------|--------------|----------|
| GRK-F9 (mechanic agent bypass) | Mechanic has browser explicitly denied (TOP-054 completed this session). Research routes exclusively through voice agent. Mechanic never produces analytical output. | `constraint` — already mitigated by architecture |
| OAI-F12 (automated report linter) | One research report exists. Building tooling for a problem observed once is premature. Monitor and build if pattern recurs. | `overkill` |
| GRK-F7 (why only two preferences need async tweaks) | The other four are covered by SOUL.md equivalents, as the analysis mapping table shows. The inconsistency is only apparent if you don't read the mapping. | `incorrect` — based on incomplete reading |
| GRK-F2 (Second Register / Serious Mode already bridges) | Second Register is for reframing problems with precedent. Serious Mode is for high-risk situations. Neither is an analytical output standard. Different purpose. | `incorrect` — conflates escalation triggers with output discipline |
| OAI-F17 (table overstates equivalence) | The mapping is explicitly labeled as coverage, not identity. "Push back on poor thinking" and "don't volunteer unsolicited opinions… but flag patterns" are close enough that the gap doesn't warrant a new SOUL.md addition. The two that ARE gaps (take time, ask questions) are called out separately. | `incorrect` — misreads the analysis intent |

---

## Raw Responses

- OpenAI: `_system/reviews/raw/2026-02-28-crumb-soul-analysis-openai.json`
- Google: `_system/reviews/raw/2026-02-28-crumb-soul-analysis-google.json`
- DeepSeek: `_system/reviews/raw/2026-02-28-crumb-soul-analysis-deepseek.json`
- DeepSeek reasoning: `_system/reviews/raw/2026-02-28-crumb-soul-analysis-deepseek-reasoning.txt`
- Grok: `_system/reviews/raw/2026-02-28-crumb-soul-analysis-grok.json`
