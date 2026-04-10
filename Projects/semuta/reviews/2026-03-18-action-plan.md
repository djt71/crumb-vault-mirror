---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/semuta/action-plan.md
artifact_type: action-plan
artifact_hash: 5ef4e7c7
prompt_hash: 3e450e55
base_ref: null
project: semuta
domain: software
skill_origin: peer-review
created: 2026-03-18
updated: 2026-03-18
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
    latency_ms: 76426
    attempts: 1
    raw_json: Projects/semuta/reviews/raw/2026-03-18-action-plan-openai.json
  google:
    http_status: 200
    latency_ms: 53652
    attempts: 1
    raw_json: Projects/semuta/reviews/raw/2026-03-18-action-plan-google.json
  deepseek:
    http_status: 200
    latency_ms: 57955
    attempts: 2
    raw_json: Projects/semuta/reviews/raw/2026-03-18-action-plan-deepseek.json
  grok:
    http_status: 200
    latency_ms: 28506
    attempts: 1
    raw_json: Projects/semuta/reviews/raw/2026-03-18-action-plan-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Semuta Action Plan (Phase 0)

**Artifact:** Projects/semuta/action-plan.md (+ companion Projects/semuta/tasks.md)
**Mode:** full
**Reviewed:** 2026-03-18
**Reviewers:** OpenAI gpt-5.4, Google gemini-3.1-pro-preview, DeepSeek deepseek-reasoner, Grok grok-4-1-fast-reasoning

---

## OpenAI (gpt-5.4)

Below is a structured review of the action plan and companion tasks table for **Semuta Phase 0**.

---

## Overall Assessment

The plan is **strong overall**: it has a clear milestone structure, a sensible critical path, explicit risk awareness, and mostly solid acceptance criteria. It is especially good at separating foundational engines from mode-specific work and identifying the visual pipeline as the highest-risk area.

That said, there are a few **important gaps and dependency ambiguities**, mostly around:
- browser/platform compatibility assumptions,
- asset/licensing handling,
- lifecycle/state management across start/stop/restart,
- observability/profiling/debugging,
- and a few places where “parallel” is overstated or under-specified.

I do **not** see a fatal structural flaw, but I do see several **SIGNIFICANT** issues worth tightening before execution.

---

# Findings

## Coverage

- **F1**
  - **Severity:** SIGNIFICANT
  - **Finding:** The plan does not explicitly include a task for **browser capability detection and fallback UX**, beyond a graceful WebGPU error in SEM-002.
  - **Why:** Phase 0 ships to a live URL on Chrome and Safari. WebGPU support, adapter/device acquisition behavior, and audio gesture constraints vary across browsers/platforms. A polished shipped experience needs a defined user-facing path for unsupported or partially supported environments.
  - **Fix:** Add explicit acceptance criteria in SEM-008 or SEM-002 for:
    - unsupported browser messaging,
    - unsupported GPU/device acquisition failure state,
    - asset load failure state,
    - and recovery/retry behavior.

- **F2**
  - **Severity:** SIGNIFICANT
  - **Finding:** The plan does not explicitly cover **performance measurement/profiling instrumentation**, despite performance being identified as a top risk.
  - **Why:** SEM-005 acceptance mentions ≥30fps on Apple Silicon with 60fps target, but there is no task for measuring frame time, resolution scaling thresholds, shader timings, or a debug overlay/logging mode. Without instrumentation, performance risk may be discovered late and diagnosed slowly.
  - **Fix:** Add minimal profiling work to SEM-002 or SEM-005:
    - frame timing,
    - simulation resolution control,
    - adaptive resolution fallback,
    - optional debug HUD or console telemetry.

- **F3**
  - **Severity:** SIGNIFICANT
  - **Finding:** There is no explicit task for **seed/initial-condition generation and reset behavior** for the reaction-diffusion simulation.
  - **Why:** Deep Still needs visible organic forms and restartability. Gray-Scott systems depend heavily on initialization. Restart behavior is part of SEM-008, but visual reset semantics are not captured.
  - **Fix:** Add acceptance criteria to SEM-005 or SEM-007 for:
    - deterministic or controlled random seeding,
    - visible emergence within defined time,
    - and reset/restart reinitializing simulation state cleanly.

- **F4**
  - **Severity:** SIGNIFICANT
  - **Finding:** The plan does not explicitly cover **asset packaging/versioning/documentation** for the impulse response file.
  - **Why:** SEM-006 mentions IR licensing and size limits, but shipping reliably on Vercel also requires a clear asset location, preload strategy, and attribution documentation if CC-BY is used.
  - **Fix:** Add acceptance criteria to SEM-006/SEM-008 for:
    - IR file checked into repo or otherwise deterministically hosted,
    - attribution file/location if CC-BY,
    - cache/load path verified in production build.

- **F5**
  - **Severity:** MINOR
  - **Finding:** The plan does not explicitly mention **responsive canvas sizing / DPR management** except “canvas fills viewport” in SEM-008.
  - **Why:** On high-DPI displays, WebGPU canvas size and simulation resolution handling affect both visual quality and performance.
  - **Fix:** Add acceptance criteria in SEM-002 or SEM-008 for:
    - devicePixelRatio-aware canvas sizing,
    - resize handling,
    - and decoupled simulation resolution if needed.

- **F6**
  - **Severity:** STRENGTH
  - **Finding:** Coverage of the main Phase 0 product slice is strong: scaffold → engines → Deep Still mode → integration → UI/deploy.
  - **Why:** This decomposition tracks the end-to-end delivery goal well and avoids premature expansion into non-Phase-0 modes or unnecessary architecture.
  - **Fix:** None.

---

## Dependency correctness

- **F7**
  - **Severity:** SIGNIFICANT
  - **Finding:** SEM-008 depends only on SEM-007, but its acceptance criteria include “Start button disabled until WebGPU device + IR buffer ready,” which also depends on lower-level readiness/lifecycle details from SEM-002 and SEM-004/SEM-006.
  - **Why:** It is technically reachable through SEM-007’s transitive dependencies, but the task definition under-specifies that SEM-008 needs concrete readiness/status APIs from both engines.
  - **Fix:** Clarify in SEM-004, SEM-006, and/or SEM-007 that they expose explicit readiness states consumed by SEM-008. Optionally keep dependency as-is but add interface-level acceptance criteria.

- **F8**
  - **Severity:** SIGNIFICANT
  - **Finding:** SEM-005 is listed as depending only on SEM-002, but its acceptance criteria include a `Mode` interface with visual/audio/parameter config slots, which conceptually touches integration concerns also used by SEM-006/SEM-007.
  - **Why:** This is not a hard dependency problem, but it risks defining the mode contract too early or too narrowly inside a visual task, leading to rework when integrating audio.
  - **Fix:** Either:
    - move `Mode` interface definition into SEM-007 or a new small interface task, or
    - keep it in SEM-005 but narrow SEM-005’s scope to a provisional visual mode contract and finalize the shared contract in SEM-007.

- **F9**
  - **Severity:** MINOR
  - **Finding:** The plan states SEM-002, SEM-003, and SEM-004 have “no runtime dependencies on each other,” which is true, but there may still be **interface dependencies** if integration-ready APIs are not lightly coordinated.
  - **Why:** Pure implementation parallelism is possible, but if each subsystem invents its own timing, lifecycle, and update API in isolation, SEM-007 may absorb avoidable integration cost.
  - **Fix:** Add a lightweight shared contract before or during those tasks: update cadence, init/start/stop semantics, error/reporting pattern.

- **F10**
  - **Severity:** STRENGTH
  - **Finding:** The critical path and dependency graph are internally coherent and correctly identify SEM-005 as the principal schedule risk.
  - **Why:** This is the right bottleneck to emphasize given WebGPU shader/debug/performance uncertainty.
  - **Fix:** None.

---

## Risk calibration

- **F11**
  - **Severity:** SIGNIFICANT
  - **Finding:** SEM-004 risk is likely **underestimated** at medium given Safari/Web Audio quirks, gesture-gated startup, async IR loading, visibility suspend/resume, and clean teardown/restart.
  - **Why:** Browser audio lifecycle bugs are common, especially when combining start/stop/restart, convolver loading, and automation. This can easily become integration-heavy and cross-browser finicky.
  - **Fix:** Consider marking SEM-004 as **high** or explicitly splitting engine basics from lifecycle/restart hardening.

- **F12**
  - **Severity:** SIGNIFICANT
  - **Finding:** SEM-008 risk is likely **underestimated** at low because it includes cross-browser verification, fullscreen behavior, lifecycle restart, and production deployment validation.
  - **Why:** “UI shell” sounds small, but cross-browser shipped polish often uncovers issues in all prior layers. This is especially true when start gating depends on both GPU and decoded audio assets.
  - **Fix:** Raise to **medium** or narrow SEM-008 acceptance criteria to pure shell concerns and move cross-browser hardening explicitly into prior tasks.

- **F13**
  - **Severity:** MINOR
  - **Finding:** SEM-003 risk may be slightly **overstated or correctly low depending on ambitions**, but “autonomous evolution” can become subjective if not constrained.
  - **Why:** The implementation itself is straightforward, but if the parameter evolution quality is expected to materially shape the meditation feel, there is product/design risk not captured by “low.”
  - **Fix:** Keep low for engineering risk, but add clearer evolution behavior expectations to prevent hidden design churn.

- **F14**
  - **Severity:** STRENGTH
  - **Finding:** Identifying SEM-005 as high risk and pulling it forward is appropriate.
  - **Why:** Shader correctness, opaque debugging, and performance on target hardware are the most likely blockers.
  - **Fix:** None.

---

## Task sizing

- **F15**
  - **Severity:** SIGNIFICANT
  - **Finding:** SEM-004 is somewhat **too large and heterogeneous** for a single medium-risk task.
  - **Why:** It combines:
    - audio context policy compliance,
    - synthesis graph design,
    - IR loading,
    - visibility lifecycle,
    - and cleanup/restart.
    These are separable concerns and likely to fail independently.
  - **Fix:** Split into two tasks, e.g.:
    - Audio engine core (context, oscillator bank, filters, parameter control)
    - Audio lifecycle/assets (IR loading, visibility handling, cleanup/restart)

- **F16**
  - **Severity:** SIGNIFICANT
  - **Finding:** SEM-005 is also large: interface design, simulation shader, render shader, color mapping, and performance target are bundled together.
  - **Why:** This is the highest-risk task and the biggest on the critical path. If left monolithic, progress tracking and fallback decisions become coarse.
  - **Fix:** Split into:
    - visual engine integration + simulation correctness,
    - render/color mapping,
    - performance tuning/adaptive resolution.
    If not split formally, at least add sub-checkpoints.

- **F17**
  - **Severity:** MINOR
  - **Finding:** SEM-008 may be slightly too broad for a final “UI shell” task because it also absorbs QA and release verification.
  - **Why:** This can conceal production hardening work.
  - **Fix:** Optionally separate “UI shell” from “release verification,” or add a release checklist subsection.

- **F18**
  - **Severity:** STRENGTH
  - **Finding:** SEM-001, SEM-003, and SEM-006 are well-sized for atomic execution.
  - **Why:** They are specific enough to be actionable without being fragmented.
  - **Fix:** None.

---

## Acceptance criteria quality

- **F19**
  - **Severity:** SIGNIFICANT
  - **Finding:** Several acceptance criteria are not fully binary because they rely on subjective terms such as “warm,” “enveloping,” “organic,” “bioluminescent,” and “feel coupled.”
  - **Why:** These may be valid product goals, but they are hard to test objectively and can create ambiguity about done-ness.
  - **Fix:** Keep the subjective criteria as product review checks, but pair them with objective proxies. Examples:
    - visible non-uniform pattern formation within N seconds,
    - audio spectrum includes harmonic partials at defined ratios,
    - reverb decay exceeds approximate threshold,
    - predefined parameter sweeps visibly and audibly alter named outputs.

- **F20**
  - **Severity:** SIGNIFICANT
  - **Finding:** SEM-005 criterion “≥30fps on Apple Silicon (target 60fps)” is incomplete because it lacks **resolution, device class, browser, and measurement method**.
  - **Why:** Performance claims are meaningless without test conditions and can lead to disputes later.
  - **Fix:** Specify:
    - canvas resolution / simulation grid,
    - browser version family,
    - representative hardware,
    - and how FPS is measured.

- **F21**
  - **Severity:** SIGNIFICANT
  - **Finding:** SEM-007 includes “Danny confirms entanglement quality,” which is useful but not sufficient as acceptance on its own.
  - **Why:** This is a stakeholder signoff, not a reproducible test. It should supplement, not define, completion.
  - **Fix:** Add objective acceptance criteria such as:
    - each of 4 parameters maps to at least 1 visual and 1 audio dimension,
    - scripted sweeps produce consistent expected output changes,
    - no dropped frames or zipper noise during sweeps.

- **F22**
  - **Severity:** MINOR
  - **Finding:** SEM-001 includes ESLint passing with TypeScript strict config, but ESLint is not mentioned in the milestone text.
  - **Why:** Not a problem, just a mismatch between action plan and task table granularity.
  - **Fix:** Either mention linting/strictness in M1 text or remove it from SEM-001 if intentionally out of scope.

- **F23**
  - **Severity:** MINOR
  - **Finding:** SEM-002 acceptance says `requestAdapter()` + `requestDevice()` succeed on Chrome/Safari, which may be too environment-dependent to be a universal binary criterion.
  - **Why:** Availability depends on hardware/browser support, flags, and platform status.
  - **Fix:** Rephrase to “on supported target environments” and specify which environments are in-scope.

- **F24**
  - **Severity:** STRENGTH
  - **Finding:** Most task criteria are concrete and implementation-linked, especially for SEM-001, SEM-002, SEM-003, and SEM-004.
  - **Why:** They make progress legible and reduce ambiguity.
  - **Fix:** None.

---

## Sequencing

- **F25**
  - **Severity:** STRENGTH
  - **Finding:** The recommended order is broadly sound and correctly prioritizes the visual critical path early.
  - **Why:** This minimizes the chance of late discovery of shader/performance blockers.
  - **Fix:** None.

- **F26**
  - **Severity:** SIGNIFICANT
  - **Finding:** There is a reasonable alternative sequencing improvement: start a **thin SEM-004 spike earlier**, before or alongside SEM-005, rather than waiting until after SEM-003.
  - **Why:** Audio engine lifecycle problems can be subtle, and a minimal gesture-gated audio proof early would de-risk Safari/browser behavior without significantly distracting from the visual path.
  - **Fix:** Suggested order:
    1. SEM-001
    2. SEM-002
    3. SEM-005
    4. lightweight SEM-004 spike
    5. SEM-003
    6. finish SEM-004 + SEM-006
    7. SEM-007
    8. SEM-008

- **F27**
  - **Severity:** MINOR
  - **Finding:** SEM-003 could likely proceed in parallel earlier without cost, but current sequencing delays it until after SEM-005.
  - **Why:** This is fine for risk-first work, but if Danny/Claude want momentum from completed tasks, SEM-003 is an easy parallel win.
  - **Fix:** Keep current order or explicitly note SEM-003 as “good filler task while debugging WGSL.”

---

## Feasibility

- **F28**
  - **Severity:** SIGNIFICANT
  - **Finding:** The plan assumes Safari support for the WebGPU + Web Audio + Fullscreen combination without explicitly bounding target Safari versions or platform constraints.
  - **Why:** Browser-native graphics/audio stacks are highly sensitive to version/platform support. “Safari latest stable” may still behave differently across macOS versions/hardware.
  - **Fix:** Explicitly define the support matrix:
    - Chrome latest stable on macOS,
    - Safari latest stable on macOS,
    - maybe whether iOS Safari is excluded for Phase 0.

- **F29**
  - **Severity:** SIGNIFICANT
  - **Finding:** `rgba16float` storage texture use in SEM-005 may have compatibility/performance implications that are not acknowledged in the plan.
  - **Why:** Format support and storage/render usage combinations can vary, and even where supported may affect performance and implementation complexity.
  - **Fix:** Add a fallback or validation criterion:
    - verify required texture format/features at startup,
    - define fallback format/packing strategy if unsupported.

- **F30**
  - **Severity:** SIGNIFICANT
  - **Finding:** The restart requirement may be harder than the plan suggests, especially for complete teardown and recreation of GPU/audio resources without page reload.
  - **Why:** Resource lifecycle bugs are common in WebGPU and Web Audio. Restart often reveals hidden state coupling.
  - **Fix:** Add explicit lifecycle contracts across subsystems:
    - `init`,
    - `ready`,
    - `start`,
    - `stop`,
    - `dispose`,
    - `restart`.
    Include one acceptance criterion per subsystem around idempotent cleanup.

- **F31**
  - **Severity:** MINOR
  - **Finding:** The plan is feasible for a passion-project Phase 0 if scope discipline is maintained.
  - **Why:** Single mode, vanilla APIs, and Vercel deployment keep scope controlled.
  - **Fix:** None.

---

## Unverifiable claims

- **F32**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** “SEM-002 validates assumption A1 (performance on Apple Silicon).”
  - **Why:** The review artifact does not include the actual assumptions document, target hardware definition, or measured performance thresholds, so this claim cannot be independently verified from the provided materials.
  - **Fix:** Link A1 explicitly and define its measurable pass/fail criteria in SEM-002/SEM-005.

- **F33**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** “SEM-006 validates assumptions A2 (drone quality) and A6 (IR sourcing).”
  - **Why:** The underlying assumption definitions are not included, and “drone quality” is not operationalized in a verifiable way.
  - **Fix:** Include assumption text or restate measurable criteria directly in the task.

- **F34**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** “SEM-007 validates A3 (entanglement).”
  - **Why:** No formal definition of A3 is provided, and “entanglement” is partly subjective in the current criteria.
  - **Fix:** Define A3 explicitly with observable coupling behaviors.

- **F35**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** “SEM-008 validates A5 (Vercel free tier).”
  - **Why:** The artifact does not specify expected traffic, asset footprint, build/runtime constraints, or free-tier limits being tested.
  - **Fix:** Define what free-tier viability means for this project: build size, bandwidth assumptions, asset count, etc.

- **F36**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** “GPU engine renders a colored quad from a compute shader” as evidence of Apple Silicon performance validity.
  - **Why:** A colored quad is a correctness smoke test, not sufficient evidence of target simulation performance.
  - **Fix:** Separate correctness validation from performance validation in acceptance criteria.

---

# Summary by evaluation dimension

## 1. Coverage
Strong overall, but missing explicit handling for:
- unsupported-browser/failure UX,
- profiling/instrumentation,
- simulation initialization/reset,
- asset packaging/attribution,
- and clearer resize/DPR handling.

## 2. Dependency correctness
Mostly correct. Main concern is that:
- SEM-005 may be defining too much shared interface too early,
- and “parallel” is true at runtime but needs lightweight API coordination.

## 3. Risk calibration
Best-calibrated risk: SEM-005 = high.  
Likely underestimated:
- SEM-004,
- SEM-008.

## 4. Task sizing
Best-sized:
- SEM-001, SEM-003, SEM-006.  
Too large:
- SEM-004,
- SEM-005.

## 5. Acceptance criteria quality
Generally good, but some criteria are:
- subjective,
- under-specified for performance,
- or environment-dependent.

## 6. Sequencing
Current sequence is good. Best improvement:
- add a small early audio spike to de-risk browser audio lifecycle.

## 7. Feasibility
Feasible if:
- support matrix is bounded,
- performance fallback is planned,
- lifecycle/restart contracts are made explicit.

---

# Bottom line

This is a **well-structured and execution-ready draft** with a few meaningful refinements needed. The most important changes I’d make before implementation are:

1. **Split or checkpoint SEM-005 and SEM-004**
2. **Add explicit profiling/performance fallback criteria**
3. **Define browser/platform support boundaries**
4. **Make restart/lifecycle contracts explicit**
5. **Turn subjective acceptance criteria into mixed subjective + objective criteria**

If you want, I can also turn this review into:
- a **redlined revision** of the action plan/tasks table, or
- a **prioritized top-10 changes list** for Danny/Claude to apply immediately.

---

## Google (gemini-3.1-pro-preview)

Here is the structured review of the Semuta Action Plan and Tasks document. 

- **F1**
- **Severity**: CRITICAL
- **Finding**: There is a circular dependency regarding the "Start" button in the testing phases. SEM-004’s Acceptance Criteria requires that the "start button disabled until decoded." However, the start button is not built until SEM-008.
- **Why**: An atomic task cannot be validated if its acceptance criteria relies on UI elements built four tasks later. SEM-004 cannot pass its current AC without SEM-008.
- **Fix**: Remove the UI requirement from SEM-004. Update SEM-004's AC to: "Audio engine exposes an `isReady` Promise/state that resolves when the IR buffer is decoded." Move the logic for disabling/enabling the start button to SEM-008.

- **F2**
- **Severity**: SIGNIFICANT
- **Finding**: UNVERIFIABLE CLAIM: "requestAdapter() + requestDevice() succeed on Chrome/Safari" and "live Vercel URL works on Safari latest stable" (SEM-002 / SEM-008). 
- **Why**: WebGPU is fully supported in standard stable Chrome, but Safari's WebGPU support has historically been tied to Safari Technology Preview or locked behind developer feature flags on iOS/macOS. Assuming a zero-error "live URL" on Safari latest stable without explicitly handling feature flags may cause immediate failure upon deployment. 
- **Fix**: Update the Safari-specific AC in SEM-008 to verify the "graceful error message" required in SEM-002, or explicitly document the specific Safari version and experimental feature flags required to pass.

- **F3**
- **Severity**: SIGNIFICANT
- **Finding**: Task SEM-004 (Audio Engine) is severely overloaded compared to the rest of the plan.
- **Why**: Combining AudioContext instantiation, lifecycle/visibility management, gesture gating, cleanup, and the complete DSP graph (oscillator bank, filter chain, asynchronous convolution reverb) into a single task increases the risk of PR bloat and debugging complexity.
- **Fix**: Split SEM-004 into two tasks: **SEM-004a** (Core Audio Engine: Context, gesture gating, visibility handling, teardown) and **SEM-004b** (Audio Graph: Oscillator bank, filter chain, convolver setup and async loading).

- **F4**
- **Severity**: SIGNIFICANT
- **Finding**: There is a missing error boundary for the asynchronous Impulse Response (IR) loading between tasks. SEM-006 mandates a "dry-signal fallback works when IR load fails," but SEM-004 lacks requirements for handling a failed fetch/decode.
- **Why**: If the async ConvolverNode loading in SEM-004 throws an unhandled exception or permanently suspends the audio graph, SEM-006's fallback mechanism cannot function.
- **Fix**: Update SEM-004's AC to explicitly catch IR fetch/decode errors and resolve the audio graph gracefully without the ConvolverNode, allowing SEM-006 to handle the dry fallback.

- **F5**
- **Severity**: MINOR
- **Finding**: SEM-004 implements `visibilitychange` to suspend and resume the audio engine.
- **Why**: Semuta is an audiovisual meditation platform. Users commonly listen to meditation drones in a background tab, while working, or when the device is locked. Suspending audio on `visibilitychange` defeats a core product use case.
- **Fix**: Only use `visibilitychange` to suspend the WebGPU compute/render loop (SEM-002/SEM-005) to save battery, but keep the AudioContext running while hidden.

- **F6**
- **Severity**: MINOR
- **Finding**: SEM-002 bakes "double-buffer ping-pong" directly into the generic WebGPU engine abstraction.
- **Why**: Ping-pong buffering is a specific requirement of the Gray-Scott reaction-diffusion simulation (SEM-005). Enforcing it at the core engine level tightly couples the generic engine to Phase 0's specific mode, wasting memory/cycles for any future modes that don't rely on temporal feedback.
- **Fix**: Keep SEM-002 focused strictly on device acquisition and base pipeline abstraction. Move the double-buffer setup and texture swapping logic entirely into the Mode interface implementations (SEM-005).

- **F7**
- **Severity**: STRENGTH
- **Finding**: The risk-informed sequencing logic tackles SEM-005 (the WGSL compute pipeline) immediately after scaffolding and core engine initialization. 
- **Why**: This is excellent architectural planning. WGSL reaction-diffusion performance on mobile/Apple Silicon is the single highest technical risk (R1/R2). Proving this out before writing the UI, parameter bus, and audio integrations ensures the project fails fast or validates its core technical assumption before sinking time into auxiliary systems.

---

## DeepSeek (deepseek-reasoner)

**Structured Review of Semuta Phase 0 Action Plan**

---

### **1. Coverage**

- **F1**
- **Severity:** STRENGTH
- **Finding:** The plan comprehensively covers the technical scope for a functional Phase 0 (Deep Still mode), from foundational engines to final integration and deployment.
- **Why:** All major components (scaffold, GPU, audio, parameters, visual/audio modes, integration, UI) are present with clear ownership. It moves from infrastructure to subsystems to product integration logically.
- **Fix:** N/A

- **F2**
- **Severity:** SIGNIFICANT
- **Finding:** The plan lacks explicit tasks for cross-browser/device compatibility testing, performance profiling/optimization, and error handling/user feedback beyond the basic start button.
- **Why:** While SEM-008 mentions verifying on Chrome and Safari, there is no task for systematic testing on different devices/GPUs or for implementing adaptive resolution (the noted fallback for risk R2). Error states (e.g., WebGPU failure, audio context suspension) are mentioned but not decomposed into UI tasks.
- **Fix:** Add tasks: "SEM-009: Cross-browser/device validation & fallback UI" (depends on SEM-008) and "SEM-010: Performance profiling & adaptive resolution" (depends on SEM-005). Or expand acceptance criteria for SEM-005 and SEM-008 to include these explicitly.

---

### **2. Dependency Correctness**

- **F3**
- **Severity:** MINOR
- **Finding:** The dependency graph and task table are consistent and logically sound. The parallelization of SEM-002, SEM-003, and SEM-004 is correctly noted.
- **Why:** This allows for parallel development after the scaffold is complete, optimizing team throughput.
- **Fix:** N/A

- **F4**
- **Severity:** SIGNIFICANT
- **Finding:** SEM-006 (Deep Still audio) depends only on SEM-004 (audio engine), but its acceptance criteria involve a "warm drone," which implies a dependency on the parameter bus (SEM-003) for dynamic control, conflicting with the stated goal of building mode-specific components independently.
- **Why:** This creates a potential integration cliff. While the audio engine can be built, the *mode-specific* audio implementation likely needs parameter definitions to be testable.
- **Fix:** Clarify that SEM-006 can proceed using a mock parameter interface or hardcoded values, with the final parameter mapping deferred to SEM-007. Update SEM-006's acceptance criteria to "drone plays with static warm character."

---

### **3. Risk Calibration**

- **F5**
- **Severity:** STRENGTH
- **Finding:** Risk levels are appropriately calibrated. SEM-005 (visual mode) is correctly flagged as HIGH due to WGSL debugging and unknown performance.
- **Why:** This accurately identifies the project's technical crux and informs the risk-informed sequencing.
- **Fix:** N/A

- **F6**
- **Severity:** MINOR
- **Finding:** SEM-004 (audio engine) is marked "medium" risk, which may be slightly underestimated given the complexity of gesture gating, cleanup, and convolution reverb with async loading.
- **Why:** Web Audio API state management and glitch-free suspend/resume are non-trivial, though less opaque than WGSL.
- **Fix:** Consider elevating SEM-004 to "medium-high" or ensuring the "medium" rating accounts for the integration complexity with visibility and gesture policies.

---

### **4. Task Sizing**

- **F7**
- **Severity:** SIGNIFICANT
- **Finding:** SEM-007 (Integration) is potentially oversized, combining parameter schema definition, bidirectional engine mappings, *and* frame loop orchestration.
- **Why:** This is a complex task where the "entanglement" magic happens. Bundling it all risks masking subtasks and making progress harder to track.
- **Fix:** Decompose SEM-007 into: SEM-007a (Parameter schema & evolution rules), SEM-007b (Visual & audio parameter mappings), and SEM-007c (Frame loop orchestration & testing).

- **F8**
- **Severity:** STRENGTH
- **Finding:** All other tasks are well-sized and atomic, each focusing on a single subsystem or deliverable.
- **Why:** This allows for clear definition of done and parallel workstreams.
- **Fix:** N/A

---

### **5. Acceptance Criteria Quality**

- **F9**
- **Severity:** STRENGTH
- **Finding:** Most acceptance criteria are excellent: binary, testable, and focused on outcomes (e.g., "organic drifting forms visible," "no console errors").
- **Why:** This minimizes ambiguity for the implementer (Claude) and the reviewer (Danny).
- **Fix:** N/A

- **F10**
- **Severity:** SIGNIFICANT
- **Finding:** **UNVERIFIABLE CLAIM:** SEM-005's acceptance criterion "organic drifting forms visible at ≥30fps on Apple Silicon (target 60fps)" is subjective ("organic drifting") and depends on unspecified hardware (which Apple Silicon? M1? M3?).
- **Why:** This makes the task's success contingent on a qualitative judgment and an unstated performance baseline.
- **Fix:** Replace with more objective criteria: "Gray-Scott simulation is visually anisotropic and non-repeating over a 60-second period. Compute + render passes complete in <16.7ms on a 2021 M1 MacBook Pro in Chrome."

- **F11**
- **Severity:** SIGNIFICANT
- **Finding:** **UNVERIFIABLE CLAIM:** SEM-007's success depends on "Danny confirms entanglement quality." This is a necessary subjective gate but is the *only* criterion for the core experiential goal.
- **Why:** This creates a single point of failure with no objective backup criteria.
- **Fix:** Add objective precursor criteria: "Parameter sweeps produce measurable changes in visual output (e.g., histogram shift) and audio output (e.g., RMS or spectral centroid change) logged to console."

---

### **6. Sequencing**

- **F12**
- **Severity:** STRENGTH
- **Finding:** The recommended risk-informed sequence (SEM-001 → SEM-002 → SEM-005 → SEM-003 → SEM-004 → SEM-006 → SEM-007 → SEM-008) is sound.
- **Why:** It front-loads the highest-risk item (visual pipeline) while respecting dependencies. It also correctly identifies the critical path.
- **Fix:** N/A

- **F13**
- **Severity:** MINOR
- **Finding:** The sequence suggests SEM-004 (audio engine) and SEM-006 (audio mode) can be done "back-to-back." However, SEM-006 depends on SEM-004, so they are sequential, not parallel.
- **Why:** This is a minor clarity issue in the narrative. The dependency graph correctly shows SEM-006 depends on SEM-004.
- **Fix:** Amend the text in "Risk-Informed Sequencing" to "SEM-004 (audio engine) then SEM-006 (audio mode) — can be done back-to-back."

---

### **7. Feasibility**

- **F14**
- **Severity:** SIGNIFICANT
- **Finding:** The plan assumes WebGPU availability on target browsers (Chrome/Safari). While SEM-002 includes a graceful error message, there is no defined fallback experience or degradation path.
- **Why:** A significant portion of users may not have WebGPU enabled/available. The project could be a blank screen for them.
- **Fix:** Add a task or expand SEM-002/008: Implement a static or canvas 2D fallback visual with a message explaining the requirement, ensuring a non-broken page for all users.

- **F15**
- **Severity:** MINOR
- **Finding:** The plan lacks explicit time estimates or velocity tracking, which is fine for a passion project but could make pacing ambiguous.
- **Why:** Not critical, but could help with milestone forecasting.
- **Fix:** Consider adding rough story point estimates or week targets to each task for informal tracking.

---

### **Summary of Unverifiable Claims (Flagged as SIGNIFICANT):**
1.  **(F10)** The definition of "organic drifting forms" and the specific "Apple Silicon" performance baseline in SEM-005.
2.  **(F11)** The sole reliance on "Danny confirms entanglement quality" as the success criterion for SEM-007.

**Overall Assessment:** This is a exceptionally well-structured, clear, and technically coherent action plan. Its primary strengths are its logical decomposition, clear dependencies, and risk-aware sequencing. The main areas for improvement are adding robustness tasks (fallbacks, error states, performance adaptation) and refining a few subjective acceptance criteria.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]  
  [Severity]: SIGNIFICANT  
  [Finding]: No explicit task or criteria for performance profiling or benchmarking, despite R2 (performance risk) being highlighted in SEM-005 and critical path notes.  
  [Why]: Phase 0 success hinges on ≥30fps (target 60fps) on Apple Silicon; without dedicated profiling, risks like shader inefficiency or texture bandwidth issues go unaddressed until late integration, potentially derailing M2.  
  [Fix]: Add sub-task or AC to SEM-005: "Profile frame times via browser dev tools or custom timestamp queries; document avg FPS on M1/M2 Mac at 1080p."

- [F2]  
  [Severity]: SIGNIFICANT  
  [Finding]: IR (impulse response) sourcing and license verification in SEM-006 assumes a suitable CC0/CC-BY file exists with <2MB compressed size; no contingency for sourcing, generating, or fallback beyond "dry-signal fallback."  
  [Why]: Blocks SEM-004/006/008; if no suitable IR found, delays shipping or degrades "long reverb tail" quality central to "Deep Still" immersion.  
  [Fix]: Expand SEM-006 AC: "Document exact IR source URL + license link; if none found, generate synthetic IR via offline tool (e.g., freeverb impulse) and verify specs."

- [F3]  
  [Severity]: CRITICAL  
  [Finding]: Dependency graph and table show SEM-007 depending directly on SEM-003, SEM-005, SEM-006—but SEM-006 depends on SEM-004 (not listed in SEM-007 deps), creating implicit chain SEM-004→SEM-006→SEM-007 without explicit notation.  
  [Why]: Risks overlooking SEM-004 delays propagating to integration; critical path ignores audio chain, falsely suggesting visuals alone block shipping.  
  [Fix]: Update SEM-007 "Depends On" to "SEM-003, SEM-004, SEM-005, SEM-006"; reflect in graph with SEM-004→SEM-006→SEM-007 arrow.

- [F4]  
  [Severity]: SIGNIFICANT  
  [Finding]: No handling for WebGPU adapter/device loss (e.g., tab backgrounding, power save modes) beyond initial acquisition in SEM-002.  
  [Why]: Meditation app runs fullscreen/long sessions; device loss causes black screen/crashes, violating "clean start/stop/restart" in SEM-008. WebGPU requires explicit reconnection.  
  [Fix]: Add to SEM-002 AC: "Handle 'device lost' error by re-requesting adapter/device and restarting pipelines"; test in SEM-008.

- [F5]  
  [Severity]: SIGNIFICANT  
  [Finding]: UNVERIFIABLE CLAIM: Assumptions A1-A6 referenced (e.g., A1 GPU perf, A2 drone quality) but not defined or listed in artifact; validation tasks claim to check them without specifics.  
  [Why]: Obscures if plan truly validates spec; reviewer can't assess completeness without knowing what A1-A6 entail (e.g., exact perf targets?).  
  [Fix]: Inline brief definitions (e.g., "A1: ≥60fps Gray-Scott at 1080p on M1") or link to spec doc.

- [F6]  
  [Severity]: MINOR  
  [Finding]: Recommended order (SEM-001→002→005→003→004→006→007→008) contradicts "parallelism note" allowing interleaving of SEM-002/003/004.  
  [Why]: Minor confusion for implementer (Claude); risks inefficient sequencing if strictly followed.  
  [Fix]: Clarify: "Recommended: Risk-prioritized sequence, but SEM-003/004 interleavable after SEM-001."

- [F7]  
  [Severity]: SIGNIFICANT  
  [Finding]: Task sizing for SEM-005 too large: Mode interface + full Gray-Scott compute shader + emissive render shader + perf validation in one task.  
  [Why]: High-risk (R1/R2); WGSL bugs could stall entire critical path for days; violates atomic task principle for decomposition.  
  [Fix]: Split into SEM-005a (Mode TS interface), SEM-005b (Gray-Scott compute), SEM-005c (render shader + perf AC); update deps/chain.

- [F8]  
  [Severity]: MINOR  
  [Finding]: Acceptance criteria for SEM-007 include "Danny confirms entanglement quality"—subjective, non-binary.  
  [Why]: Hinders solo implementation/testing by Claude; acceptance stalls on unavailable stakeholder.  
  [Fix]: Add objective proxy: "Demo video of 3 sweeps shows correlated shifts (e.g., energy up → brighter forms + brighter harmonics)."

- [F9]  
  [Severity]: SIGNIFICANT  
  [Finding]: No mobile/responsive criteria; canvas "fills viewport no scrollbars" (SEM-008) but no touch gestures or lower-end GPU testing (e.g., iPhone WebGPU perf).  
  [Why]: Browser-native meditation targets mobile; untested perf/resolution adaptation risks broken experience on Vercel-shared URL.  
  [Fix]: Add to SEM-008 AC: "Canvas responsive 320px-4K; verify ≥15fps on iPhone 15 Safari; touch fullscreen toggle."

- [F10]  
  [Severity]: MINOR  
  [Finding]: Risk for SEM-004 (medium) underrates Web Audio complexities: gesture gating + visibility suspend/resume + async IR without clicks is tricky (pop/click artifacts common).  
  [Why]: Could cause autoplay blocks or audio glitches blocking SEM-008 cross-browser.  
  [Fix]: Bump to "high"; add AC: "No audible pops on suspend/resume (verified by recording)."

- [F11]  
  [Severity]: SIGNIFICANT  
  [Finding]: Coverage gap: No error boundaries or user-facing error states beyond "graceful error message" (SEM-002) and loading (SEM-008); e.g., shader compile failures opaque in WGSL.  
  [Why]: WGSL errors crash silently; users see black canvas, harming shareable URL goal.  
  [Fix]: Add SEM-008 AC: "Shader compile errors show friendly message + reload button"; use GPU validation layers where possible.

- [F12]  
  [Severity]: MINOR  
  [Finding]: Dependency table misses SEM-001 as dep for SEM-003/004 explicitly in "Notes" critical path, though implied.  
  [Why]: Minor oversight; could confuse quick scans.  
  [Fix]: Update table "Depends On" for SEM-003/004 to "SEM-001".

- [F13]  
  [Severity]: STRENGTH  
  [Finding]: Dependency graph visually accurate and matches table/critical path.  
  [Why]: Enables quick parallelism spotting (e.g., param bus off-critical); challenges: Graph omits SEM-004→006 explicit arrow, but text compensates.  
  [Fix]: N/A

- [F14]  
  [Severity]: STRENGTH  
  [Finding]: Acceptance criteria generally binary/testable (e.g., "Vitest unit tests pass," "no console errors").  
  [Why]: Supports rapid iteration; challenges: Some visuals subjective, but balanced with tech metrics like FPS/texture formats.  
  [Fix]: N/A

- [F15]  
  [Severity]: SIGNIFICANT  
  [Finding]: Feasibility concern: rgba16float textures for simulation (SEM-005) assumes WebGPU support on Safari; Safari limits formats/precision.  
  [Why]: Reaction-diffusion needs float precision; fallback to rgba8f may degrade "organic drifting" quality, unaddressed.  
  [Fix]: Add SEM-005 AC: "Detect/prefer rgba16float; fallback rgba8f if unsupported, with visual diff doc."

- [F16]  
  [Severity]: MINOR  
  [Finding]: Sequencing sound but defers audio (004/006) late despite "parallel opportunities"; no rationale for post-visual.  
  [Why]: Minor; audio lower risk but still needs Danny confirmation in 007.  
  [Fix]: Note: "Audio deferred to preserve critical path momentum."

- [F17]  
  [Severity]: SIGNIFICANT  
  [Finding]: No task for parameter schema definition timing; SEM-007 assumes it's done there, but evolution rules needed for SEM-003 testing.  
  [Why]: SEM-003 AC requires "declared ranges/evolution rules" but schema only in SEM-007; circular or stubs needed early.  
  [Fix]: Move schema stub to SEM-003; full def in SEM-007.

- [F18]
  [Severity]: MINOR
  [Finding]: Tasks table lacks estimated effort/timings despite atomic decomposition goal.
  [Why]: Harder for Danny/Claude to plan sprints.
  [Fix]: Add column "Est. Days" (e.g., SEM-005: 3-5).

---

## Synthesis

### Consensus Findings

**C1: Performance profiling gap** (OAI-F2, DS-F2, GRK-F1) — 3/4 reviewers
No explicit task or criteria for frame timing, profiling, or adaptive resolution fallback despite R2 being a top risk. Profiling is how we validate the most critical assumption (A1).

**C2: SEM-004 overloaded and risk underestimated** (OAI-F11, OAI-F15, GEM-F3, DS-F6, GRK-F10) — 4/4 reviewers
Combines AudioContext lifecycle, gesture gating, oscillator bank, filter chain, convolution reverb, visibility handling, and cleanup. Unanimous that risk should be higher; multiple suggest splitting.

**C3: Subjective acceptance criteria need objective proxies** (OAI-F19, OAI-F21, DS-F10, DS-F11, GRK-F8) — 3/4 reviewers
"Organic," "warm," "enveloping," "feel coupled" are product goals, not binary tests. Danny's subjective evaluation is necessary but insufficient as sole criterion. Need measurable proxies alongside.

**C4: Safari WebGPU / rgba16float concerns** (OAI-F28, OAI-F29, GEM-F2, GRK-F15) — 3/4 reviewers
Safari WebGPU support status, texture format availability, and feature flags need explicit handling. rgba16float may not be universally available.

**C5: IR sourcing contingency** (OAI-F4, GRK-F2) — 2/4 reviewers
Need explicit contingency beyond "dry fallback" — document exact source, license, synthetic generation plan.

**C6: Restart/lifecycle + device loss complexity** (OAI-F30, GRK-F4) — 2/4 reviewers
Clean teardown + restart is harder than estimated. WebGPU device loss during long meditation sessions is unhandled.

### Unique Findings

**GEM-F1 (CRITICAL): SEM-004 start button circular dependency.** SEM-004 AC says "start button disabled until decoded" but the button is built in SEM-008. Genuine logic error — SEM-004 should expose readiness state, not reference UI. **Insight: valid.**

**GRK-F17 (SIGNIFICANT): Parameter schema timing.** SEM-003 AC requires "declared ranges/evolution rules" for testing, but Deep Still's parameter schema isn't defined until SEM-007. Need stub schema in SEM-003. **Insight: valid — genuine circular dependency.**

**GRK-F4 (SIGNIFICANT): WebGPU device loss handling.** No handling for adapter/device loss during long sessions. Only Grok caught this. **Insight: valid for a meditation app designed for extended use.**

**GEM-F5 (MINOR): Audio should keep playing when tab hidden.** Product concern — meditation users may want background audio. **Insight: valid product question, but conflicts with spec's explicit decision (peer-reviewed A2 action item). Route to spec reconsideration, not action plan change.**

**GEM-F6 (MINOR): Double-buffer belongs in mode, not engine.** Architectural concern that ping-pong is mode-specific. **Insight: reasonable, but spec §6.5 placed this at engine level. Defer to implementation experience.**

### Contradictions

**Audio visibility handling:** GEM-F5 argues audio should continue in background tabs (product concern: meditation users). The spec explicitly decided to suspend AudioContext on `visibilitychange` per peer-reviewed A2 action item. This is a spec-level reconsideration, not an action plan issue. Flagged for human judgment.

### Action Items

**Must-fix:**

- **A1** (GEM-F1) — Fix SEM-004 circular AC: replace "start button disabled until decoded" with "audio engine exposes `isReady` state that resolves when IR buffer is decoded." Move button-disable logic to SEM-008.
- **A2** (GRK-F3) — Make SEM-007 dependency on SEM-004 explicit in the dependency table. Currently SEM-007 lists SEM-003, SEM-005, SEM-006 — but SEM-006→SEM-004 is only implicit. Add SEM-004 to prevent overlooking audio chain delays.

**Should-fix:**

- **A3** (OAI-F2, DS-F2, GRK-F1) — Add profiling criteria to SEM-005 AC: "Profile frame times via browser dev tools; document avg FPS at canvas resolution on target hardware (M1/M2 Mac, Chrome)."
- **A4** (OAI-F11, OAI-F15, GEM-F3, DS-F6, GRK-F10) — Raise SEM-004 risk from medium to high. The audio lifecycle complexity (gesture gating + visibility + async IR + cleanup/restart) warrants it.
- **A5** (OAI-F19, OAI-F21, DS-F10, DS-F11, GRK-F8) — Add objective proxy criteria alongside subjective ACs: SEM-005 "non-uniform pattern formation within 10s of simulation start"; SEM-006 "spectral content includes harmonics at declared ratios"; SEM-007 "each parameter maps to ≥1 visual and ≥1 audio dimension; scripted sweeps produce consistent output changes."
- **A6** (OAI-F29, GRK-F15) — Add rgba16float validation to SEM-005 AC: "Verify rgba16float storage texture support at startup; document fallback strategy if unsupported on target browser."
- **A7** (GRK-F4) — Add device loss handling to SEM-002 AC: "Handle GPUDevice `lost` event by re-requesting adapter/device and notifying caller."
- **A8** (GRK-F17) — Add parameter schema stub requirement to SEM-003 AC: "Include a test parameter schema (stub or example) with ranges and evolution rules for unit testing. Deep Still's full schema defined in SEM-007."
- **A9** (OAI-F32-F36, GRK-F5) — Inline brief assumption definitions in tasks.md notes section so the plan is self-contained.
- **A10** (OAI-F4, GRK-F2) — Expand SEM-006 IR sourcing criteria: "Document exact IR source URL + license; if no suitable CC0/CC-BY IR found, generate synthetic IR via offline tool."
- **A11** (OAI-F1, GRK-F11) — Expand SEM-008 AC for error UX: "Shader compile errors and device loss show user-friendly message with reload option."

**Defer:**

- **A12** (OAI-F16, GRK-F7) — Split SEM-005 into sub-tasks. Task is ≤5 files; splitting risks over-fragmentation. Monitor during implementation — if SEM-005 stalls, split then.
- **A13** (OAI-F28, GEM-F2) — Explicit browser support matrix with version bounds. Spec says "Chrome and Safari latest stable" — sufficient for Phase 0. Revisit if cross-browser issues emerge.
- **A14** (OAI-F5) — DPR-aware canvas sizing. Visual quality concern for high-DPI but within Phase 0 "should work but not tuned" scope.
- **A15** (OAI-F3) — Simulation seeding/reset behavior. Implementation detail for SEM-005, not an action plan gap.

### Considered and Declined

| Finding | Justification | Reason |
|---------|--------------|--------|
| GEM-F5 (audio keep playing when hidden) | Spec explicitly decided to suspend AudioContext per peer-reviewed A2 action item | constraint |
| GEM-F6 (double-buffer in mode not engine) | Spec §6.5 places double-buffer at engine level | constraint |
| GRK-F9 (mobile/responsive testing) | Spec §12 explicitly lists "No mobile optimization" as Phase 0 non-goal | constraint |
| DS-F14 (canvas 2D fallback) | Spec says "No WebGL fallback at v1" — graceful error message is the design decision | constraint |
| DS-F15, GRK-F18 (time estimates) | Not part of Crumb task convention | out-of-scope |
| OAI-F22 (ESLint in milestone text) | Minor text mismatch, not a gap | overkill |
| OAI-F27 (SEM-003 as filler task note) | Recommended order already has this implicit | overkill |
| DS-F13 (back-to-back wording) | Dependency table is clear; narrative is fine | overkill |
| GRK-F12 (SEM-001 explicit dep for 003/004) | Already in the dependency table | overkill |
| GRK-F16 (audio deferral rationale) | Risk-Informed Sequencing section explains this | overkill |
| OAI-F26 (early audio spike) | Current sequencing is sound; optimization not needed | overkill |
| DS-F7 (split SEM-007) | Single reviewer; integration task is inherently bundled | overkill |
| OAI-F9 (lightweight API coordination before M2) | SEM-007 integration task is the coordination point | overkill |
