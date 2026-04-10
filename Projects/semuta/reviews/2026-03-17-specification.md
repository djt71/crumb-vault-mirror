---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/semuta/design/specification.md
artifact_type: spec
artifact_hash: d9ac3f70
prompt_hash: 0bf167e5
base_ref: null
project: semuta
domain: software
skill_origin: peer-review
created: 2026-03-17
updated: 2026-03-17
reviewers:
  - openai/gpt-5.4
  - google/gemini-3.1-pro-preview
  - deepseek/deepseek-reasoner
  - grok/grok-4-1-fast-reasoning
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
  warnings: []
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 61784
    attempts: 1
    raw_json: Projects/semuta/reviews/raw/2026-03-17-specification-openai.json
  google:
    http_status: 200
    latency_ms: 39471
    attempts: 1
    raw_json: Projects/semuta/reviews/raw/2026-03-17-specification-google.json
  deepseek:
    http_status: 200
    latency_ms: 57777
    attempts: 1
    raw_json: Projects/semuta/reviews/raw/2026-03-17-specification-deepseek.json
  grok:
    http_status: 200
    latency_ms: 26285
    attempts: 1
    raw_json: Projects/semuta/reviews/raw/2026-03-17-specification-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Semuta Specification

**Artifact:** Projects/semuta/design/specification.md
**Mode:** full
**Reviewed:** 2026-03-17
**Reviewers:** OpenAI GPT-5.4, Google Gemini 3.1 Pro Preview, DeepSeek Reasoner (V3.2), Grok 4.1 Fast Reasoning
**Review prompt:** Full specification review — correctness, completeness, internal consistency, feasibility, clarity. Structured findings with severity classification.

---

## OpenAI (gpt-5.4)

Below is a structured review of the specification.

---

## Overall Assessment

This is a strong, unusually coherent draft for a creative technical project. It has:
- a clear Phase 0 scope,
- sensible architecture boundaries,
- explicit assumptions and risks,
- decomposed tasks with acceptance criteria,
- and a healthy anti-scope-creep posture.

The biggest issues are not conceptual but practical/spec-quality issues:
1. a few likely factual claims that need verification,
2. some technical ambiguities in the WebGPU data model and pipeline contract,
3. a couple of internal inconsistencies around input/non-goals and browser support wording,
4. under-specified performance and testing criteria for a real-time GPU/audio system.

---

## Findings

### F1
- [Severity]: SIGNIFICANT
- [Finding]: **UNVERIFIABLE CLAIM:** “WebGPU compute shaders are stable in Chrome, Edge, Firefox, and Safari 26 (~70% global coverage as of 2026)”
- [Why]: This is a foundational platform assumption, but the exact browser/version/support/global-coverage claim is not independently verifiable from the spec alone. “Safari 26” is especially suspicious as versioning terminology may be inaccurate or nonstandard. The coverage percentage also needs a source.
- [Fix]: Replace with a sourced statement, e.g. “WebGPU support is available in current stable versions of X/Y/Z as of [date], per [MDN/Can I Use/vendor docs].” If exact coverage is important, cite the source and date explicitly.

### F2
- [Severity]: SIGNIFICANT
- [Finding]: **UNVERIFIABLE CLAIM:** “WebXR Device API supports stereoscopic rendering on Meta Quest via Chromium”
- [Why]: This may be broadly true, but as written it is a platform compatibility claim without citation. Since Phase 3 depends on it, this should be grounded.
- [Fix]: Add a source reference or soften the wording to “is expected to support” until verified on target Quest browser versions.

### F3
- [Severity]: SIGNIFICANT
- [Finding]: **UNVERIFIABLE CLAIM:** “Safari does not support Web MIDI (Apple policy on fingerprinting)”
- [Why]: The support claim may be true in practice, but the stated reason (“Apple policy on fingerprinting”) is causal attribution and should not be asserted without source support.
- [Fix]: Split into two parts: “Safari lacks Web MIDI support” and cite an official compatibility source; omit or source the policy rationale.

### F4
- [Severity]: SIGNIFICANT
- [Finding]: **UNVERIFIABLE CLAIM:** “OpenAIR project or equivalent CC-licensed library” and “Fokke van Saane collection” as viable IR sources
- [Why]: Asset licensing is operationally important for a public deployment. The spec names possible sources but does not verify licensing compatibility for redistribution in a web app.
- [Fix]: Add a concrete asset acceptance criterion: exact source, license type, attribution requirements, and whether bundling in a public repo/deployment is permitted.

### F5
- [Severity]: CRITICAL
- [Finding]: The visual architecture is under-specified about the actual simulation storage format and binding model for reaction-diffusion.
- [Why]: The spec alternates between “buffer A/buffer B,” “ping-pong texture pair,” “simulation buffer,” and “fullscreen quad sampling the simulation buffer.” In WebGPU, whether the simulation state is stored in storage textures vs storage buffers has major implications for WGSL bindings, formats, filtering, render sampling, compatibility, and performance. This is a core implementation contract, not an incidental detail.
- [Fix]: Explicitly choose one Phase 0 representation, e.g.:
  - “Simulation state is stored in two `rgba16float` storage textures ping-ponged each frame; compute writes next-state texture, render samples current-state texture.”
  - Or “simulation state is stored in storage buffers, then copied/blitted into a render texture.”
  Also define uniform/storage binding layouts at a high level.

### F6
- [Severity]: SIGNIFICANT
- [Finding]: The render-pipeline description says “fragment shader slot” and “vertex shader for fullscreen quad,” but does not define whether there is a shared fullscreen triangle/quad utility, nor the expected shader entry-point contract for modes.
- [Why]: Since extensibility is a stated goal, the engine/mode boundary should specify what a mode provides versus what the engine provides. Otherwise each new mode may require engine changes, undermining the architecture.
- [Fix]: Add an explicit mode visual contract such as:
  - engine-owned fullscreen geometry,
  - required WGSL entry points (`vs_main`, `fs_main`, `cs_main`),
  - expected bind group numbers and resource slots,
  - which resources are mode-defined vs engine-defined.

### F7
- [Severity]: SIGNIFICANT
- [Finding]: There is an internal inconsistency about input scope.
- [Why]: Section 4 lists an “Input Layer — (Phase 0: simulated only),” but the Non-Goals section says “No MIDI input (real or simulated — simulated input was in v0.1 but adds complexity without validating the core).” This creates confusion about whether any input perturbation abstraction exists in Phase 0 beyond UI controls.
- [Fix]: Clarify one of:
  1. Phase 0 has no input layer beyond start/stop/fullscreen, or
  2. Phase 0 includes a dormant input abstraction with no external input sources enabled.
  Rewrite Section 4 to align with Non-Goals.

### F8
- [Severity]: SIGNIFICANT
- [Finding]: The frame-loop ordering in SEM-007 may be suboptimal or at least unjustified: “compute pass → parameter evolution → audio param update → render pass.”
- [Why]: If parameter evolution occurs after the compute pass, then the rendered frame may reflect old visual parameters while audio reflects new parameters, creating a one-frame desynchronization in the very system whose key value is “entanglement.”
- [Fix]: State a consistent update order, likely:
  - evolve parameters,
  - push uniforms/audio params,
  - compute,
  - render.
  If one-frame lag is acceptable, document it explicitly.

### F9
- [Severity]: SIGNIFICANT
- [Finding]: The acceptance criterion “Perceptible entanglement” is important but under-operationalized.
- [Why]: It currently depends on subjective evaluation (“Danny evaluation required”), which is valid artistically, but the spec lacks even a minimal structured validation method. That makes Phase 0 completion harder to assess objectively.
- [Fix]: Add a lightweight evaluation protocol, e.g.:
  - define 3–4 parameter sweeps,
  - document expected visual/audio co-changes,
  - perform a short guided review checklist,
  - optionally capture a tuning matrix mapping semantic intent to both systems.

### F10
- [Severity]: SIGNIFICANT
- [Finding]: Performance criteria are incomplete for a real-time audiovisual app.
- [Why]: The spec sets a frame target, but not memory, thermal, startup, audio glitch tolerance, or adaptive resolution behavior. For browser GPU/audio work, “works” can degrade badly without clear constraints.
- [Fix]: Add Phase 0 nonfunctional criteria such as:
  - first frame within X seconds after Start,
  - audio begins within Y ms of gesture,
  - no sustained crackles/dropouts during 5-minute run on target hardware,
  - adaptive resolution steps and minimum floor,
  - no unbounded resource growth over N minutes.

### F11
- [Severity]: SIGNIFICANT
- [Finding]: Cross-browser support expectations are too broad in one place and too narrow in another.
- [Why]: Facts mention support across Chrome, Edge, Firefox, Safari; acceptance only requires Chrome and Safari latest stable. That is fine, but the target support policy is not stated clearly. Readers may infer four-browser support is in scope for Phase 0.
- [Fix]: Add a concise support matrix:
  - “Phase 0 officially targets latest stable Chrome and Safari on desktop.”
  - “Edge/Firefox are exploratory/non-blocking.”
  This would align facts with acceptance criteria.

### F12
- [Severity]: SIGNIFICANT
- [Finding]: The spec assumes a convolution reverb IR of 8–12 seconds but does not discuss asset size, network loading, or startup strategy.
- [Why]: Long IR files can materially affect initial load time on a static site, especially if the app is intended to be shareable by URL. If IR loading blocks audio start, the UX may feel broken.
- [Fix]: Specify:
  - target file size range,
  - whether IR is preloaded on page load or lazily fetched after gesture,
  - fallback behavior if IR load fails,
  - whether a temporary dry/algorithmic path is used until loaded.

### F13
- [Severity]: MINOR
- [Finding]: The statement “No browser-native application exists…” is overly absolute.
- [Why]: Broad “no application exists” claims are hard to defend and unnecessary. Even if directionally true, absolutes invite challenge.
- [Fix]: Soften to “There is no widely adopted browser-native application we’ve identified…” or “We have not found…”

### F14
- [Severity]: MINOR
- [Finding]: Section numbering is inconsistent: there are two “11” sections.
- [Why]: This creates minor confusion in references and review comments.
- [Fix]: Renumber “Non-Goals for Phase 0” to Section 12.

### F15
- [Severity]: MINOR
- [Finding]: The “Fullscreen mode works (Fullscreen API)” acceptance criterion does not mention iOS/Safari caveats.
- [Why]: Fullscreen behavior can vary across browsers/platforms. Since Safari is a target, implementation expectations should be clearer.
- [Fix]: Define what “works” means on target platforms, e.g. desktop Safari/Chrome only for Phase 0.

### F16
- [Severity]: MINOR
- [Finding]: The spec says “Canvas fills viewport (no scrollbars, no margins)” but does not mention DPR scaling strategy.
- [Why]: For visual fidelity/performance, whether the internal render resolution tracks CSS size × devicePixelRatio matters substantially.
- [Fix]: Add a canvas sizing rule such as:
  - canvas CSS fills viewport,
  - backing resolution = viewport × DPR capped at X,
  - simulation resolution may be decoupled from display resolution.

### F17
- [Severity]: MINOR
- [Finding]: “Strict mode, no `any` leakage” is a good aspiration but not translated into a reviewable standard.
- [Why]: It’s easy for this to become informal rather than enforceable.
- [Fix]: Add a lint/build rule expectation such as “`noImplicitAny`, `strict: true`, ESLint rule against explicit `any` except documented escape hatches.”

### F18
- [Severity]: MINOR
- [Finding]: The audio architecture says “3–5 detuned oscillators” and also “1–3 Hz difference tones,” which may be interpreted imprecisely.
- [Why]: Difference-tone language is musically evocative, but from an engineering perspective the desired detuning relationship and beat rates should be more explicit if they matter for implementation.
- [Fix]: Clarify whether the goal is:
  - slow beat frequencies in the ~0.05–3 Hz range between nearby partials,
  - or detuned fundamentals/partials according to specific cents offsets.

### F19
- [Severity]: MINOR
- [Finding]: The parameter bus evolution model is conceptually good but mathematically unspecified.
- [Why]: Terms like “noise injection,” “attractor points,” and “exponential smoothing” are enough for intent, but if this is central to feel and portability, a little more formalization would help.
- [Fix]: Add a brief implementation sketch, e.g. per-frame update formula or tick cadence, bounded output behavior, and smoothing constants.

### F20
- [Severity]: STRENGTH
- [Finding]: The spec demonstrates excellent scope discipline for Phase 0.
- [Why]: Limiting to one mode, no backend, no framework, no WebGL fallback, no VR, and no premature monetization materially reduces execution risk for a passion project.
- [Fix]: Keep this discipline; it is one of the strongest aspects of the document.

### F21
- [Severity]: STRENGTH
- [Finding]: The assumptions/unknowns/risk structure is strong and appropriately honest.
- [Why]: The spec clearly distinguishes what is known versus what must be validated empirically, especially around performance, sound quality, and coupling quality.
- [Fix]: Preserve this structure into implementation docs and post-task validation notes.

### F22
- [Severity]: STRENGTH
- [Finding]: The architecture separates concerns sensibly: visual engine, audio engine, parameter bus, mode system, platform/UI shell.
- [Why]: This is a good fit for a browser-native real-time system and supports future mode extensibility without framework overhead.
- [Fix]: Reinforce it by tightening the mode contracts as noted in F6.

### F23
- [Severity]: STRENGTH
- [Finding]: Task decomposition is practical and mostly dependency-aware.
- [Why]: SEM-001 through SEM-008 create a plausible build path, with the riskiest integration work placed after foundations.
- [Fix]: Consider adding explicit validation outputs per task (short demo/check artifact) to improve progress visibility.

### F24
- [Severity]: STRENGTH
- [Finding]: The business overlay is appropriately lightweight and stage-aware.
- [Why]: It supports the engineering constraints rather than distorting them, especially the “no backend until evidence exists” principle.
- [Fix]: None needed; this is proportionate and useful.

### F25
- [Severity]: SIGNIFICANT
- [Finding]: Testing strategy is too thin for the GPU and browser-platform dimensions of the project.
- [Why]: Unit tests on parameter bus/audio graph are useful, but the hardest failures here will be integration-level: shader compilation, bind-group mismatches, resource lifecycle, browser permission/startup edge cases, and long-run stability.
- [Fix]: Add lightweight integration validation:
  - smoke test checklist for Chrome/Safari,
  - shader compile/startup sanity check in dev,
  - 5–10 minute soak test,
  - console-error-free criterion after start/stop/restart.

### F26
- [Severity]: SIGNIFICANT
- [Finding]: Resource lifecycle and cleanup behavior are under-specified.
- [Why]: Real-time browser apps often leak GPU resources, animation loops, or audio nodes on restart/stop. Since stop/pause is in scope, cleanup semantics matter.
- [Fix]: Define expected behavior for:
  - start/stop/restart,
  - AudioContext suspend vs close,
  - GPU resource reuse vs rebuild on resize/mode load,
  - event listener teardown.

### F27
- [Severity]: SIGNIFICANT
- [Finding]: The mode system is described as plugin-like, but loading strategy is not specified.
- [Why]: Even for one mode, it matters whether mode assets are eagerly bundled, lazy-loaded via dynamic import, or statically linked. This affects startup, extensibility, and build complexity.
- [Fix]: State a Phase 0 policy such as:
  - “Deep Still is statically bundled; no dynamic mode loading in Phase 0.”
  Future phases can introduce lazy loading if useful.

### F28
- [Severity]: MINOR
- [Finding]: “No mobile optimization (should work but not tuned)” conflicts slightly with acceptance mentioning a mobile-responsive layout as nice-to-have.
- [Why]: This is not a major contradiction, but it could be read as implying mobile support expectations.
- [Fix]: Clarify: “Mobile viewport rendering is non-blocking and unsupported for quality/performance in Phase 0.”

### F29
- [Severity]: SIGNIFICANT
- [Finding]: The phrase “graceful error message on unsupported browsers” is not defined enough.
- [Why]: For unsupported WebGPU browsers or failed adapter/device requests, user experience can vary widely. A “graceful error” should be specific enough to implement consistently.
- [Fix]: Define minimum behavior:
  - detect unsupported state before start,
  - show static fallback screen with explanation,
  - optionally list supported browsers/platforms,
  - no uncaught exceptions or blank canvas.

### F30
- [Severity]: MINOR
- [Finding]: The specification would benefit from a concise glossary for terms like “entanglement,” “warmth,” “density,” and “turbulence.”
- [Why]: These are good creative-control names, but they are also semantic anchors in the parameter bus. A short glossary would improve tuning and team communication.
- [Fix]: Add a mini parameter glossary in `params.ts` or the spec, including intended perceptual effect on both sound and image.

---

## Summary of Key Actions

If you only address a few items before implementation, prioritize these:

1. **Specify the WebGPU simulation data model clearly** — storage textures vs buffers, formats, bind groups.  
2. **Resolve the Phase 0 input inconsistency** — simulated input layer vs no simulated input.  
3. **Define the engine/mode contract more concretely** — especially shader entry points and resource ownership.  
4. **Tighten performance and lifecycle requirements** — startup, stop/restart, soak behavior, adaptive resolution.  
5. **Verify or soften unsupported factual/platform claims** — especially WebGPU support/version/coverage and Safari/Web MIDI rationale.  

---

## Bottom Line

The spec is solid and very buildable. It already has better scope control and architectural self-awareness than many early-stage project specs. The main weaknesses are technical precision at the engine/shader boundary and a handful of unsupported factual claims. Tightening those areas would make this a strong implementation-ready Phase 0 specification.

---

## Google (gemini-3.1-pro-preview)

Here is a structured review of the "Semuta" project specification. 

- [F1]
- [Severity]: CRITICAL
- [Finding]: Direct scope contradiction regarding simulated input in Phase 0.
- [Why]: Section 4 (System Map > Input Layer) states explicitly: "(Phase 0: simulated only) Normalized input events → parameter perturbations". However, the second Section 11 (Non-Goals for Phase 0) states: "No MIDI input (real or simulated — simulated input was in v0.1 but adds complexity without validating the core)". This contradiction prevents finalizing the Phase 0 scope and affects the definition of done.
- [Fix]: Remove the "simulated only" reference in Section 4, as the rationale in Section 11 (reducing complexity to validate the core) represents the sounder engineering decision for Phase 0.

- [F2]
- [Severity]: SIGNIFICANT
- [Finding]: Flawed Web Audio methodology for autonomous parameter drift (Section 6.4). 
- [Why]: The spec mandates `AudioParam.linearRampToValueAtTime` for smooth transitions. However, because the Parameter Bus (Section 9, SEM-003) uses continuous, unpredictable "noise injection" and drift toward attractors, interrupting a `linearRamp` with new ramp values can cause audible clicks or unexpected envelope behaviors. `linearRampToValueAtTime` requires absolute precision of the current scheduled event.
- [Fix]: Change the automation strategy to `AudioParam.setTargetAtTime()`. This method is explicitly designed by the Web Audio API for continuous, exponentially smoothed approach to dynamically changing targets, eliminating the risk of audio artifacts during autonomous parameter perturbation.

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: Missing asynchronous asset loading state for Convolution Reverb.
- [Why]: In Section 6.4 and SEM-006, the spec dictates using an 8-12 second impulse response (IR) file. Long-tail IR files can be multiple megabytes. The app must fetch this file and run `audioContext.decodeAudioData()` before the audio graph can safely start. The UI shell (SEM-008) lacks a "Loading" state, meaning the user could click "Start" before the buffer is ready, causing a crash or silent reverb node.
- [Fix]: Add an async initialization phase to `main.ts` and an "Asset Loading" UI state in SEM-008 that disables the Start button until the WebGPU device is ready and the IR buffer is fully decoded.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Safari 26 and ~70% global WebGPU coverage.
- [Why]: Section 3 (Facts) claims WebGPU is stable in "Safari 26" and has "~70% global coverage as of 2026". Given current real-world software versions and WebGPU adoption metrics, these claims cannot be independently verified. Relying on fictional or future browser metrics may mask actual cross-browser compatibility risks.
- [Fix]: Validate actual current WebGPU support on iOS/macOS via caniuse.com, update the expected Safari version target, and establish a fallback or explicit "not supported" UI strategy for incompatible browsers.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Wellness/meditation app market size is $6B+.
- [Why]: Section 10 (Risk/Reward) cites a specific market size of $6B+. While this may be directionally accurate, the specific statistic lacks attribution.
- [Fix]: Provide a source for the market data or remove the specific dollar figure, focusing instead on the qualitative market dynamics already described.

- [F6]
- [Severity]: MINOR
- [Finding]: Workflow friction between SEM-004 (Audio testing) and SEM-008 (UI).
- [Why]: SEM-004's acceptance criteria state: "calling start() after user gesture produces a sustained drone." However, the actual UI Start button isn't scheduled to be built until SEM-008. While a developer can easily wire a temporary button, missing it in the decomposition creates a tiny blind spot in task sequencing.
- [Fix]: Add a sub-task in SEM-004 to "Implement temporary DOM button for user-gesture audio gating," which is later replaced by the SEM-008 UI Shell.

- [F7]
- [Severity]: MINOR
- [Finding]: Duplicate section numbering.
- [Why]: The document ends with "11. Open Questions" followed immediately by "11. Non-Goals for Phase 0". 
- [Fix]: Renumber "Non-Goals for Phase 0" to Section 12.

- [F8]
- [Severity]: MINOR
- [Finding]: Highly optimistic Quest VR performance target (Phase 3).
- [Why]: Section 7 (Phase 3) targets 72fps stereoscopic rendering combined with GPU compute shaders. Given the strict thermal and power limits of standalone VR headsets (e.g., Quest 2/3), achieving 72fps stereo rendering with real-time reaction-diffusion compute will be extremely challenging without aggressive downscaling.
- [Fix]: Note the severe performance constraint of standalone VR in the Risk Register (Section 8) to keep it visible, even though it is deferred to Phase 3.

- [F9]
- [Severity]: STRENGTH
- [Finding]: The architectural decision to enforce a "No Backend" and "Static Deployment" constraint.
- [Why]: For an audiovisual exploration tool pre-validation, eliminating backend services drastically reduces operational costs, security footprints, and deployment friction. The mapping of this technical constraint to business lifecycle in Section 10 is excellent.

- [F10]
- [Severity]: STRENGTH
- [Finding]: The "Parameter Bus" abstraction (Section 4 & SEM-003).
- [Why]: Tying visual and audio parameters to a centralized, dynamically evolving data store is the correct architectural pattern for this project. It prevents tight coupling between the audio graph and the render pipeline while guaranteeing that the targeted "entanglement" effect remains mathematically grounded and deterministic.

---

## DeepSeek (deepseek-reasoner)

- **F1**
- **Severity**: SIGNIFICANT
- **Finding**: The specification lists "Safari 26" as supporting WebGPU. This version number appears speculative for a 2026 context. Furthermore, the claim of "~70% global coverage as of 2026" for WebGPU is an unverifiable forward-looking statistic without a cited source.
- **Why**: Basing technical feasibility on unverified or future browser support figures is risky. If actual support is lower, the core constraint of "no WebGL fallback" becomes a significant barrier to user access.
- **Fix**: Replace with a verifiable, current source (e.g., "WebGPU is enabled by default in Chrome 113+, Edge 113+, Firefox 121+, Safari 17.4+" from caniuse.com or official browser blogs). For coverage, use a source like StatCounter for current browser version adoption, and note it as an estimate. Acknowledge the evolving landscape.

- **F2**
- **Severity**: SIGNIFICANT
- **Finding**: Assumption A5 states "Free-tier Vercel hosting is sufficient." While likely true for static files, the performance of serving large impulse response (IR) audio files (8-12 seconds) from a free-tier CDN with potential bandwidth limits is unvalidated.
- **Why**: Slow loading of critical audio assets (IR files) could break the user experience with silent audio or long delays. Free tiers often have bandwidth/asset size limitations.
- **Fix**: Validate A5 specifically for audio asset delivery. Calculate total size of IR files, check Vercel's free tier limits for bandwidth and asset size, and consider compression (e.g., Opus for IR files). Add a mitigation step to SEM-008: "Verify audio assets load within acceptable time and do not exceed hosting limits."

- **F3**
- **Severity**: SIGNIFICANT
- **Finding**: The specification contains several forward-looking or unverifiable factual claims without citation: "WebXR Device API supports stereoscopic rendering on Meta Quest via Chromium," "Safari does not support Web MIDI (Apple policy on fingerprinting)," and the $6B+ wellness market figure.
- **Why**: While these may be accurate, presenting them as "Facts" without sources reduces the document's credibility and could lead to incorrect technical decisions if the underlying facts change or are misunderstood.
- **Fix**: Reclassify these as "Assumptions" or "References" and cite sources (e.g., WebXR device API documentation, Apple developer policies, market research reports). Prefix with "UNVERIFIABLE CLAIM:" until sourced.

- **F4**
- **Severity**: MINOR
- **Finding**: There is an inconsistency in the "Acceptance Criteria" for visual performance: the "Must have" states "≥30fps on Apple Silicon," while the description in Section 6.5 and Assumption A1 target 60fps.
- **Why**: This creates ambiguity for validation. Is 30fps acceptable for launch, or is 60fps the real target? The lower bar in "Must have" weakens the performance objective.
- **Fix**: Align the criteria. Recommendation: Change the "Must have" to "≥30fps (target 60fps)" to clearly separate the minimum viable threshold from the design goal referenced elsewhere.

- **F5**
- **Severity**: SIGNIFICANT
- **Finding**: Risk R4 ("Parameter coupling feels arbitrary") has a mitigation that is subjective and non-technical: "Tuning session with Danny once integrated."
- **Why**: This relies entirely on a single person's aesthetic judgment post-integration, which is a scheduling and quality risk. It lacks an objective or testable criterion for "entanglement."
- **Fix**: Define more concrete, testable validation criteria for A3/SEM-007. For example: "A directed change in parameter P produces a statistically significant change in both audio feature X (e.g., spectral centroid) and visual feature Y (e.g., histogram of pixel values) within a defined time window, as measured by a diagnostic tool."

- **F6**
- **Severity**: MINOR
- **Finding**: The `project_class` mentioned in "External Code Repo" (`~/openclaw/semuta/`) is described as `system`. This term is not defined within the specification context.
- **Why**: It creates a minor ambiguity for anyone reading the spec who is not familiar with the internal classification system ("system" vs. perhaps "library" or "tool").
- **Fix**: Either remove the `project_class` mention as internal metadata not needed for the spec, or add a brief footnote explaining its meaning within your project taxonomy.

- **F7**
- **Severity**: STRENGTH
- **Finding**: The document demonstrates excellent internal consistency and project self-awareness. Constraints ("No framework," "No backend," "Phase 0 scope is one mode") are clearly stated and then consistently reflected in the architecture, task decomposition, and non-goals.
- **Why**: This coherence drastically reduces the likelihood of scope creep and ensures all technical decisions align with the project's core philosophy. The business context section correctly ties these technical constraints to the ideation stage and cost structure.

- **F8**
- **Severity**: STRENGTH
- **Finding**: The specification excellently decomposes high-level creative goals into concrete, actionable engineering tasks (SEM-001 through SEM-008). Each task has clear dependencies, identified risks, and file-level deliverables.
- **Why**: This transforms a visionary concept into an executable project plan. The decomposition bridges the gap between design ("bioluminescent quality") and implementation ("compute shader writes to texture, render shader displays it").

- **F9**
- **Severity**: SIGNIFICANT
- **Finding**: The validation of Assumption A2 ("3-5 detuned Web Audio oscillators... produce drone quality sufficient") is assigned to SEM-006. However, SEM-006's acceptance criteria are descriptive ("warm, enveloping character") and subjective.
- **Why**: This makes the validation of a key technical assumption qualitative and dependent on personal judgment, similar to R4. Without a more objective benchmark, it's difficult to know when the assumption is truly "validated" or if more complex audio synthesis (e.g., AudioWorklet) is needed.
- **Fix**: Supplement the subjective acceptance with an objective, comparable reference. E.g., "Generate a 60-second sample. In an A/B blind test with a reference sample from the target aesthetic (e.g., Stars of the Lid), the sample is not consistently identified as 'thin' or 'mechanical' by a small listener panel."

- **F10**
- **Severity**: CRITICAL
- **Finding**: The specification omits a concrete plan for handling `AudioContext` state in response to system events like page backgrounding or device sleep. The Web Audio API will have its context "suspended" automatically by the browser in many of these cases.
- **Why**: If the audio stops when a user switches tabs or locks their phone, the meditative experience is broken. This is a fundamental requirement for a sustained, immersive application. Not addressing it is a critical oversight.
- **Fix**: Add a requirement and task element (likely within SEM-004 or SEM-008) to listen for `pagevisibilitychange` and `blur`/`focus` events. Implement logic to gracefully suspend and resume the `AudioContext` and potentially pause the simulation loop to save power.

- **F11**
- **Severity**: MINOR
- **Finding**: The document numbering has two consecutive "11." sections (Open Questions and Non-Goals).
- **Why**: A minor typographical error that slightly affects document professionalism.
- **Fix**: Renumber "11. Open Questions" to "12. Open Questions" and "11. Non-Goals" to "13. Non-Goals".

---

## Grok (grok-4-1-fast-reasoning)

- [F1]  
  [Severity]: CRITICAL  
  [Finding]: Contradiction between System Map §4 (Input Layer described as "(Phase 0: simulated only)") and Non-Goals §11 ("No MIDI input (real or simulated — simulated input was in v0.1 but adds complexity without validating the core)"). Parameter Bus §4 also references "input perturbation" without clarifying if simulated input is in/out of scope.  
  [Why]: Undermines scope definition for Phase 0, risks scope creep or implementation confusion (e.g., does autonomous evolution suffice, or is perturbation from simulated input required?). Breaks internal consistency.  
  [Fix]: Remove "(Phase 0: simulated only)" from System Map and strike "input perturbation" from Parameter Bus description. Explicitly state in §4 Components: "Input Layer — Deferred to Phase 1 (no perturbations in Phase 0 beyond autonomous evolution)."

- [F2]  
  [Severity]: CRITICAL  
  [Finding]: Acceptance Criteria §7 for SEM-007 requires "Danny evaluation required" for validating perceptible entanglement (A3), but Facts §3 state "Claude implements, Danny directs — Danny will not write WGSL or compute shaders directly." No objective metrics defined for "feels coupled, not coincidental."  
  [Why]: Makes Phase 0 completion dependent on unavailable external validation; subjective criteria halt progress without Danny's involvement, contradicting self-contained passion project workflow.  
  [Fix]: Replace with objective proxies, e.g., "[ ] Parameter changes (manual toggle via debug UI) produce correlated shifts: visual form density varies with audible partial count; spectrum analyzer confirms beating rates track turbulence param."

- [F3]  
  [Severity]: SIGNIFICANT  
  [Finding]: UNVERIFIABLE CLAIM: "WebGPU compute shaders are stable in Chrome, Edge, Firefox, and Safari 26 (~70% global coverage as of 2026)" (Facts §3). No attributed source for coverage stat; Safari 26 is hypothetical (current Safari ~17-18 as of 2024 knowledge).  
  [Why]: Spec relies on ungrounded future browser data for feasibility; if coverage <70% or stability issues persist, Phase 0 deployment value drops (e.g., alienates Safari users).  
  [Fix]: Rephrase to "Target browsers: latest Chrome/Edge/Firefox/Safari with WebGPU enabled (~stable in Chrome/Edge/Firefox as of 2024; monitor caniuse.com for Safari). Remove numeric coverage until sourced (e.g., caniuse or StatCounter 2026 data)."

- [F4]  
  [Severity]: SIGNIFICANT  
  [Finding]: No contingency for impulse response file sizes/bundling in §6.4 Audio Arch or SEM-006; 8-12s IRs at 48kHz (stereo float32) could exceed 10MB/file, bloating static site bundle beyond Vercel free-tier limits or mobile feasibility (A5/A6).  
  [Why]: Risks deployment failure (Vercel bandwidth caps) or poor perf; contradicts "no-backend, static-site" constraint and "zero marginal cost" business claim (§10).  
  [Fix]: Add to Risks R5: "IR bundle >50MB" (Medium impact); Fix: "Prioritize compressed mono 44.1kHz IRs <2MB; fallback to Web Audio reverb alternatives (e.g., IIR if ConvolverNode insufficient). Validate total public/ size <20MB in SEM-006."

- [F5]  
  [Severity]: SIGNIFICANT  
  [Finding]: Unknown U1 ("simulation resolution + workgroup size hits performance sweet spot") lacks budgeted profiling tasks; SEM-002/SEM-005 assume defaults (1080p, workgroup 64) without iterative tuning steps, despite R2 (High impact).  
  [Why]: Phase 0 Must-Have requires ≥30fps on Apple Silicon (A1), but no explicit profiling workflow risks perf regressions across hardware (e.g., Intel iGPU vs. M-series).  
  [Fix]: Add subtask to SEM-002: "Profile 512²/720p/1080p at 60/30fps on target GPUs (Chrome DevTools, Safari Instruments); select defaults + adaptive resizer uniform."

- [F6]  
  [Severity]: SIGNIFICANT  
  [Finding]: Project Structure §6.3 lists `src/modes/deep-still/shaders/compute.wgsl` but Task SEM-005 files list `src/modes/deep-still/shaders/compute.wgsl, shaders/render.wgsl` (relative path ambiguity); Vite import assumes `?raw` works cross-subdirs (A4).  
  [Why]: Build errors if paths mismatch; delays SEM-001 validation and scaffolding.  
  [Fix]: Standardize to `src/modes/deep-still/shaders/*.wgsl`; note in SEM-001: "Test import from 'deep-still/shaders/compute.wgsl?raw'."

- [F7]  
  [Severity]: SIGNIFICANT  
  [Finding]: No handling for AudioContext state across fullscreen/resize/pause (e.g., suspend/resume on visibilitychange); §6.4 mentions fade-in but not runtime interruptions.  
  [Why]: Browser policies (page visibility API) can mute/suspend audio, causing discontinuities; violates "no discontinuities" audio goal and Acceptance "smooth fade-in" extension.  
  [Fix]: Add to SEM-004: "Hook document.visibilitychange → audio.suspend()/resume() with crossfade ramps."

- [F8]  
  [Severity]: MINOR  
  [Finding]: Duplicate section numbers: "11. Open Questions (Deferred)" followed by "11. Non-Goals for Phase 0" (§11).  
  [Why]: Reduces clarity and scanability in a long doc.  
  [Fix]: Renumber Non-Goals to §12.

- [F9]  
  [Severity]: MINOR  
  [Finding]: Acceptance Criteria "Nice to have: Basic responsive layout (works on mobile viewport, even if experience is desktop-optimized)" contradicts Non-Goals "No mobile optimization (should work but not tuned)."  
  [Why]: Minor scope ambiguity; risks over-optimization.  
  [Fix]: Align: Change Nice-to-have to "Canvas scales to viewport (CSS); no mobile-specific shaders/UI."

- [F10]  
  [Severity]: MINOR  
  [Finding]: UNVERIFIABLE CLAIM: "OpenAIR project or equivalent CC-licensed library" for IRs (R5, SEM-006, A6). OpenAIR exists but licensing per-file varies (some non-CC); no specific files cited.  
  [Why]: Risks copyright issues in public/ folder; static site can't gate.  
  [Fix]: Specify "e.g., OpenAIR CC0 files like 'MIT reverberator_8s_stereo.wav'; list 2-3 verified URLs in SEM-006 details."

- [F11]  
  [Severity]: MINOR  
  [Finding]: Task dependencies incomplete: SEM-007 depends on SEM-003/005/006, but frame loop orchestration (main.ts) implicitly needs SEM-002 (GPU) and SEM-004 (audio).  
  [Why]: Risks parallel execution bugs.  
  [Fix]: Update SEM-007 Depends On: "SEM-002, SEM-003, SEM-004, SEM-005, SEM-006."

- [F12]  
  [Severity]: STRENGTH  
  [Finding]: Comprehensive Risk Register §8 with ID/mitigation table, covering shaders (R1), perf (R2), audio quality (R3), coupling (R4), and scope (R7).  
  [Why]: Proactively addresses high-likelihood pitfalls (e.g., WGSL opacity), enabling feasible Phase 0; ties directly to assumptions/tasks. Edge case: R7 prevents passion-project derailment.  
  [Fix]: N/A

- [F13]  
  [Severity]: STRENGTH  
  [Finding]: Task Decomposition §9 with sequential dependencies, per-task files, risks, and detailed substeps (e.g., SEM-001 acceptance: npm run dev/build).  
  [Why]: Provides executable roadmap; verifies against artifact (e.g., SEM-007 maps params explicitly). Handles unknowns like U1 via profiling gates.  
  [Fix]: N/A

- [F14]
  [Severity]: STRENGTH
  [Finding]: Strict constraints (§4: No framework/backend/WebGL fallback, Phase 0 one mode) and Non-Goals §11 align with static-site philosophy and business "cost floor $0" (§10).
  [Why]: Ensures feasibility/minimalism; internal consistency (e.g., Vite only for build, no React weight). Challenges: No backend avoids premature scaling.
  [Fix]: N/A

---

## Synthesis

### Consensus Findings

**1. Input Layer / Non-Goals Contradiction** [CRITICAL] — OAI-F7, GEM-F1, GRK-F1 (3/4 reviewers)
System Map §4 lists "Input Layer — (Phase 0: simulated only)" and Parameter Bus mentions "input perturbation," while Non-Goals §11 explicitly excludes simulated input ("was in v0.1 but adds complexity without validating the core"). Highest-confidence finding — clear internal inconsistency.

**2. Unverifiable WebGPU Browser Coverage** [SIGNIFICANT] — OAI-F1, GEM-F4, DS-F1, GRK-F3 (4/4 reviewers)
"Safari 26" and "~70% global coverage as of 2026" cited as Facts without any source. All reviewers flagged this as ungrounded.

**3. IR File Loading / Size / Hosting Strategy** [SIGNIFICANT] — OAI-F12, GEM-F3, DS-F2, GRK-F4 (4/4 reviewers)
8-12 second impulse responses at 48kHz stereo can be multi-MB. No loading strategy (preload vs lazy), size budget, fallback if load fails, or Vercel bandwidth validation specified. GEM-F3 specifically flags that users could click Start before IR is decoded.

**4. Subjective Entanglement Validation** [SIGNIFICANT] — OAI-F9, DS-F5, GRK-F2 (3/4 reviewers)
"Perceptible entanglement" acceptance depends on "Danny evaluation required" with no objective proxy or structured evaluation protocol. Makes Phase 0 completion assessment ambiguous.

**5. AudioContext Backgrounding/Visibility** [SIGNIFICANT] — DS-F10, GRK-F7 (2/4 reviewers)
No plan for AudioContext suspend/resume when page loses visibility. Browser will suspend audio automatically; spec doesn't address graceful handling. DeepSeek rated CRITICAL.

**6. Duplicate Section Numbering** [MINOR] — OAI-F14, GEM-F7, DS-F11, GRK-F8 (4/4 reviewers)
Two consecutive §11 sections. Trivial fix.

**7. Additional Unverifiable Claims** [SIGNIFICANT] — OAI-F2, OAI-F3, OAI-F4, GEM-F5, DS-F3, GRK-F10 (multiple)
WebXR on Quest, Safari Web MIDI policy rationale, $6B+ wellness market, and OpenAIR licensing all presented as facts without attribution.

**8. Mobile Nice-to-Have vs Non-Goal** [MINOR] — OAI-F28, GRK-F9 (2/4 reviewers)
"Basic responsive layout" as nice-to-have contradicts "No mobile optimization" non-goal.

### Unique Findings

**OAI-F5 [CRITICAL] — WebGPU Storage Format Under-Specified.** The spec alternates between "buffer," "texture," and "simulation buffer" without choosing between storage textures and storage buffers. This affects WGSL bindings, formats, and performance. **Genuine insight** — important for SEM-002 implementation.

**GEM-F2 [SIGNIFICANT] — AudioParam Method: linearRamp → setTargetAtTime.** With continuous autonomous parameter drift interrupting ramps, `linearRampToValueAtTime` can cause clicks. `setTargetAtTime()` is the correct Web Audio pattern for exponentially smoothed approach to moving targets. **Genuine technical insight** — directly applicable.

**OAI-F8 [SIGNIFICANT] — Frame Loop Ordering Desync.** Spec says "compute pass → parameter evolution → audio param update → render pass." If parameters evolve after compute, visual reflects old state while audio reflects new state — one-frame desync in the system whose core value is entanglement. **Genuine insight.**

**OAI-F6 [SIGNIFICANT] — Mode Contract / Shader Entry Points.** Engine/mode boundary doesn't specify what a mode provides (entry points, bind groups) vs. what the engine provides. **Valid architectural concern** for extensibility, though lower priority for single-mode Phase 0.

**OAI-F26 [SIGNIFICANT] — Resource Lifecycle / Cleanup.** Start/stop/restart semantics for GPU resources, audio nodes, animation loops not specified. **Valid** — browser apps leak resources without explicit cleanup design.

**OAI-F25 [SIGNIFICANT] — Testing Strategy Too Thin.** Only unit tests mentioned. GPU/browser integration needs smoke tests, shader compile checks, and soak testing. **Valid.**

**GRK-F5 [SIGNIFICANT] — U1 Profiling Not Budgeted.** SEM-002/005 assume defaults (1080p, workgroup 64) without explicit profiling subtasks despite R2 (High impact). **Valid.**

**DS-F4 [MINOR] — 30fps vs 60fps Inconsistency.** Must-have says ≥30fps, but A1 targets 60fps at 1080p. Should align as "≥30fps (target 60fps)." **Valid.**

**GRK-F11 [MINOR] — SEM-007 Dependencies Incomplete.** Frame loop orchestration implicitly needs SEM-002 (GPU) and SEM-004 (audio), not just SEM-003/005/006. **Valid.**

**GRK-F6 [MINOR] — Shader Path Ambiguity.** Task file lists use inconsistent relative paths for shaders. **Valid but trivial.**

### Contradictions

**Entanglement validation approach.** All three flagging reviewers agree the current approach is insufficient, but disagree on how much human judgment to retain:
- **GRK-F2:** Fully replace Danny evaluation with objective proxies (spectrum analyzer, pixel histogram)
- **OAI-F9:** Add lightweight evaluation protocol (parameter sweeps, checklist) alongside Danny
- **DS-F5/F9:** Statistical/A-B testing with listener panel

**Resolution recommendation:** OAI-F9's middle ground is most appropriate. This is a creative project where aesthetic judgment matters — supplement Danny's evaluation with structured parameter sweeps and observable proxies, don't replace it. A listener panel (DS-F9) is overkill for Phase 0.

### Action Items

#### Must-fix
**A1** [OAI-F7, GEM-F1, GRK-F1] — **Resolve Input Layer / Non-Goals contradiction.** Remove "(Phase 0: simulated only)" from System Map §4 Input Layer. Remove "input perturbation" from Parameter Bus description. State: "Input Layer — Deferred to Phase 1."

**A2** [DS-F10, GRK-F7] — **Add AudioContext visibility handling.** Add requirement to SEM-004/SEM-008: listen for `visibilitychange`, suspend/resume AudioContext gracefully, optionally pause simulation loop.

**A3** [all 4] — **Fix section numbering.** Renumber second §11 (Non-Goals) to §12.

#### Should-fix
**A4** [OAI-F1, GEM-F4, DS-F1, GRK-F3] — **Source or soften WebGPU coverage claim.** Replace with verifiable statement citing caniuse.com or browser release notes. Remove specific percentage until sourced.

**A5** [OAI-F12, GEM-F3, DS-F2, GRK-F4] — **Specify IR loading strategy.** Add: target file size (<2MB mono compressed), async loading with UI "loading" state, fallback behavior if load fails (dry signal or algorithmic reverb), Vercel bandwidth check in SEM-008.

**A6** [OAI-F9, DS-F5, GRK-F2] — **Add entanglement evaluation protocol.** Define 3-4 parameter sweeps with expected visual/audio co-changes. Danny evaluation stays as final arbiter but supplemented with observable proxies (e.g., debug overlay showing parameter→output correlation).

**A7** [OAI-F5] — **Specify WebGPU simulation storage format.** Choose storage textures (rgba16float) vs storage buffers for reaction-diffusion state. Document format and bind group layout expectations for SEM-002.

**A8** [GEM-F2] — **Switch AudioParam strategy to setTargetAtTime.** Replace `linearRampToValueAtTime` recommendation in §6.4 with `setTargetAtTime()` for autonomous parameter drift.

**A9** [OAI-F8] — **Fix frame loop ordering.** Change to: evolve parameters → push uniforms/audio params → compute → render.

**A10** [OAI-F26] — **Add resource lifecycle spec.** Define start/stop/restart semantics: AudioContext suspend vs close, GPU resource reuse vs rebuild, event listener teardown.

**A11** [OAI-F2, OAI-F3, GEM-F5, DS-F3, GRK-F10] — **Source or soften remaining unverifiable claims.** WebXR, Web MIDI rationale, $6B+ market, OpenAIR licensing — either cite sources or move to Assumptions.

#### Defer
**A12** [OAI-F6] — **Mode contract / shader entry points.** Important but acceptable to refine during PLAN phase when implementing SEM-002/005.

**A13** [OAI-F25] — **Expand testing strategy.** Add smoke test checklist and soak test during PLAN/TASK phases.

**A14** [GRK-F5] — **Add profiling subtasks.** Include resolution/workgroup profiling in SEM-002 task refinement during PLAN.

**A15** [DS-F4] — **Align 30fps/60fps wording.** Minor: change Must-have to "≥30fps (target 60fps)."

**A16** [OAI-F28, GRK-F9] — **Align mobile nice-to-have / non-goal.** Clarify: viewport CSS scaling only, no mobile-specific optimization.

**A17** [GRK-F11] — **Update SEM-007 dependency list.** Add SEM-002 and SEM-004 as explicit dependencies.

### Considered and Declined

- **DS-F9** (A/B blind test with listener panel for audio quality) — `overkill`. A listener panel for a Phase 0 passion project is disproportionate. Danny's evaluation is sufficient at this stage.

- **GRK-F2** (fully replace Danny evaluation with objective proxies) — `constraint`. Danny's aesthetic judgment is a stated design constraint ("Danny directs"). Supplement with proxies, don't replace.

- **OAI-F13** ("No browser-native application exists" too absolute) — `out-of-scope`. Problem statement framing is appropriate for an internal spec. Softening adds no engineering value.

- **OAI-F17** (translate strict TS to lint rules in spec) — `overkill`. `strict: true` in tsconfig + standard ESLint is sufficient for Phase 0. Implementation detail, not spec-level.

- **OAI-F16** (DPR scaling strategy) — `out-of-scope`. Implementation detail for SEM-002, not spec-level decision.

- **GEM-F6** (temp button subtask for SEM-004) — `overkill`. Developer trivially adds a test button. No spec change needed.

- **GEM-F8** (Quest VR perf in risk register) — `out-of-scope`. Already captured as U4; risk register covers Phase 0 scope.

- **DS-F6** (project_class undefined) — `out-of-scope`. Internal Crumb taxonomy, not part of spec audience.

- **OAI-F15** (Fullscreen Safari caveats) — `out-of-scope`. Implementation detail for SEM-008.

- **OAI-F18** (detuning precision) — `out-of-scope`. Tuning detail for SEM-006 implementation, not spec-level.

- **OAI-F19** (parameter bus math formalization) — `out-of-scope`. Spec describes intent; implementation detail for SEM-003.

- **OAI-F11** (cross-browser support matrix) — `out-of-scope`. Already implicit — acceptance says Chrome + Safari, Facts describe broader landscape.

- **OAI-F29** ("graceful error" under-defined) — `out-of-scope`. Reasonable implementation guidance for SEM-002, but the spec-level "graceful error message on unsupported browsers" is sufficient intent. Detail goes in task acceptance criteria.

- **OAI-F27** (mode loading strategy) — `out-of-scope`. Phase 0 has one mode; static bundling is obvious. No spec clarification needed.

- **OAI-F30** (parameter glossary) — `out-of-scope`. Belongs in `params.ts` comments during implementation, not the spec.

- **GRK-F6** (shader path ambiguity) — `incorrect`. Paths in the task table are file-level references; the project structure tree is authoritative. No actual ambiguity for implementation.
