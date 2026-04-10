---
type: specification
status: draft
domain: software
skill_origin: systems-analyst
project: semuta
created: 2026-03-17
updated: 2026-03-18
---

# Semuta — Project Specification

## 1. Problem Statement

No browser-native application we've found produces coupled generative audio and visuals designed for sustained meditative attention. Existing browser-based tools are either audio-only (Endel, Brain.fm), visually reactive to external audio, or require installation. The browser is the right delivery surface — zero-install, shareable via URL, and capable of GPU compute (WebGPU) and real-time synthesis (Web Audio). The opportunity is to build a self-composing audiovisual environment that dissolves temporal perception through entangled sound and light.

## 2. Design Reference

The creative vision, architectural philosophy, mode concepts, and aesthetic targets are defined in `semuta-design-spec-v0.2.md` (this directory). That document is the constitutional reference for what Semuta is and is not. This specification adds engineering structure: concrete decisions, acceptance criteria, risks, and task decomposition.

Audio reference points for the quality of attention Semuta targets: Éliane Radigue, Stars of the Lid, the quieter passages of Tim Hecker. The goal is not to match their production quality but to match the quality of attention their music produces.

## 3. Facts, Assumptions, and Unknowns

### Facts
- WebGPU: Chrome/Edge full support (113+, primary target). Safari partial support (26.0+, macOS Tahoe, secondary target). Firefox disabled by default on current stable (not a Phase 0 target). iOS Safari 26+ supported but not Phase 0 optimization target. Global coverage ~82.7% (caniuse.com, March 2026).
- Web Audio API provides oscillators, filters, convolution reverb, and AudioParam automation — sufficient for drone synthesis
- WebXR Device API is expected to support stereoscopic rendering on Meta Quest via Chromium (verify on target Quest browser version before Phase 3)
- Safari does not support Web MIDI as of current stable releases (Web MIDI is not relevant to Phase 0)
- AudioContext requires a user gesture to start (browser autoplay policy)
- WGSL is the shader language for WebGPU — text-based, statically validated
- Vite explicitly documents `?raw` imports — WGSL import is a known tooling pattern, not a hypothesis
- Claude implements, Danny directs — Danny will not write WGSL or compute shaders directly

### Assumptions (to validate)
- **A1:** Reaction-diffusion simulation at 512×512 fixed grid runs at 60fps on Apple Silicon integrated GPU via WebGPU (simulation resolution is decoupled from display resolution) — *validate in SEM-005b*
- **A2:** 3-5 detuned Web Audio oscillators with convolution reverb produce drone quality sufficient for the meditative effect — *validate in SEM-006*
- **A3:** Parameter bus coupling (shared state driving both engines) produces perceptible entanglement rather than arbitrary co-occurrence — *validate in SEM-007*
- **A5:** Free-tier Vercel hosting is sufficient for a static WebGPU app (no server-side compute needed) — *validate in SEM-008*
- **A6:** Publicly licensed impulse response files exist at sufficient quality for long-tail convolution reverb (8-12s) — *validate in SEM-006*

### Unknowns
- **U1:** What simulation resolution + workgroup size hits the performance sweet spot across hardware? (Empirical — needs profiling)
- **U2:** How to crossfade between modes without audible/visible discontinuity? (Phase 1 problem — not Phase 0)
- **U3:** Whether the parameter bus abstraction holds when modes have fundamentally different simulation types (reaction-diffusion vs. particle fluid) — Phase 1 validation
- **U4:** VR performance budget on Quest — stereoscopic + compute may require significant resolution reduction (Phase 3)

## 4. System Map

### Components
- **Visual Engine** — WebGPU device management, compute/render pipeline abstraction, double-buffer state management
- **Audio Engine** — Web Audio context management, oscillator bank, filter/reverb chain, AudioParam automation
- **Parameter Bus** — Named parameter store, autonomous evolution rules, smooth interpolation
- **Mode System** — TypeScript interface for mode plugins, mode loading, mode-specific shader/audio/parameter configs
- **Input Layer** — Normalized input events → parameter perturbations (deferred to Phase 1; no input perturbation in Phase 0 beyond autonomous evolution)
- **UI Shell** — Start button (gesture gate), fullscreen toggle, minimal info display
- **Platform Layer** — Canvas management, resize handling, frame loop orchestration

### Dependencies
- WebGPU browser API (no polyfill — graceful error if unsupported)
- Web Audio browser API
- Vite (build tooling)
- Vercel (deployment)
- Impulse response audio files (public domain / CC-licensed)

### External Code Repo
`~/openclaw/semuta/` — initialized. `project_class: system` — standalone web application.

### Constraints
- **No framework.** Vanilla TypeScript + browser APIs. React/Vue/Svelte add weight with no value for this kind of application. DOM interaction is minimal (one canvas, a few buttons).
- **No WebGL fallback at v1.** Unsupported browsers get a clear error message.
- **No backend.** Fully static — all generation happens client-side.
- **Phase 0 scope is one mode.** Deep Still only. Resist expanding until the architecture proves out.

### Levers (high-impact intervention points)
- **Parameter bus design** — if this is right, modes compose naturally; if wrong, every mode becomes a special case
- **Shader architecture** — compute/render separation pattern determines how easy new visual modes are to build
- **Audio graph construction** — whether synthesis configs are declarative (mode describes what it wants) vs. imperative (mode builds its own graph) affects mode portability

### Second-Order Effects
- A well-designed mode interface enables community contributions (future)
- Live URL from Phase 0 enables early aesthetic feedback loops with Danny
- Browser-native approach means VR (Phase 3) shares the same codebase — no port required

## 5. Domain Classification & Workflow

- **Domain:** Software (creative application)
- **Workflow:** Full four-phase (SPECIFY → PLAN → TASK → IMPLEMENT)
- **Rationale:** Substantial standalone application with GPU programming, real-time audio, and a novel architecture. Needs full rigor despite being a passion project — quality over speed.

## 6. Technical Decisions

### 6.1 Build Tooling
- **Vite** — TypeScript compilation, dev server with HMR, production bundling
- **TypeScript** — strict mode, no `any` leakage
- **WGSL imports** — Vite `?raw` suffix for importing .wgsl shader files as strings (validate A4; fallback: small Vite plugin)
- **Package manager:** npm
- **Linting:** ESLint with TypeScript rules
- **Testing:** Vitest for unit tests (parameter bus, audio graph construction). Aesthetic evaluation is manual — deploy and review.

### 6.2 Deployment
- **Vercel** — free tier, automatic preview deployments from git branches, zero config for static sites
- **CI:** Vercel's built-in (runs `vite build` on push)
- Phase 0 ships on a Vercel subdomain (e.g., `semuta.vercel.app`). Custom domain is a future decision.

### 6.3 Project Structure
```
src/
  main.ts                    — entry point, frame loop, orchestration
  engine/
    gpu.ts                   — WebGPU device init, pipeline management
    audio.ts                 — Web Audio context, synthesis graph
    parameter-bus.ts         — shared parameter state + evolution
    types.ts                 — shared engine types
  modes/
    types.ts                 — Mode interface definition
    deep-still/
      index.ts               — mode registration, metadata
      visual.ts              — shader config, buffer definitions
      audio.ts               — synthesis config, tonal palette
      params.ts              — parameter schema + evolution rules
      shaders/
        compute.wgsl         — reaction-diffusion simulation
        render.wgsl          — emissive color field rendering
  ui/
    shell.ts                 — start button, fullscreen, info display
public/
  assets/
    impulse-responses/       — convolution reverb IR files
index.html
vite.config.ts
tsconfig.json
package.json
```

### 6.4 Audio Architecture (Phase 0)

Deep Still drone synthesis using standard Web Audio nodes:
- **Oscillator bank:** 3-5 OscillatorNodes with custom PeriodicWave, frequencies in just-intonation ratios relative to a root (e.g., root ~55 Hz / A1)
- **Detuning:** Microtonal offsets between oscillators to produce slow beating (1-3 Hz difference tones)
- **Filtering:** BiquadFilterNode (lowpass) with slowly modulated cutoff frequency driven by parameter bus
- **Reverb:** ConvolverNode with long-tail impulse response (8-12 second decay). Source: CC0/CC-BY licensed IR files (verify per-file license before bundling). Prefer stereo IR if available under size budget (~4MB stereo vs ~2MB mono) for improved spatial quality on headphones. IR is fetched at runtime (not bundled into JS). **Start gating:** `isReady` means "can produce sound" (dry signal path functional), NOT "has loaded all assets." Allow entry once WebGPU device is acquired and a minimal dry audio graph can be created on user gesture. Fade in the convolver path when the IR finishes loading — nobody will notice reverb arriving 2-3 seconds late, everyone will notice a stuck start button. Fallback: dry signal if IR load fails entirely.
- **Gain envelope:** Master GainNode with long attack (fade in over ~5 seconds on start)
- **Parameter automation:** AudioParam.setTargetAtTime for all smooth transitions — designed for continuous approach to moving targets without discontinuities when interrupted by autonomous parameter drift. **Update throttling:** Parameter-to-audio updates should NOT run in lockstep with the render loop (60Hz). setTargetAtTime replaces previous automation on each call — 60fps of overlapping schedules wastes CPU and gains nothing for the slow drift Semuta produces. Throttle audio parameter pushes to ~10-15Hz (every 4-6 frames) via a separate timer or frame counter. Visual uniforms can update every frame (GPU uniform writes are cheap); audio parameter writes are the ones to throttle. **Time constant:** Use `setTargetAtTime` with time constant of ~0.2s at the ~15Hz update rate. The time constant should be roughly 2-3x the update interval for smooth approach without audible stepping.
- **Visibility handling:** Listen for `visibilitychange` events. On page hidden: suspend AudioContext gracefully (fade out over ~500ms, then `audioContext.suspend()`), pause `requestAnimationFrame` loop and parameter bus evolution (prevents GPU/battery waste and state drift — user returns to familiar state, not one that has drifted significantly). On page visible: resume AudioContext (`audioContext.resume()`, fade in), resume frame loop and parameter evolution.

### 6.5 Visual Architecture (Phase 0)

Deep Still uses reaction-diffusion simulation (Gray-Scott model or similar):
- **Compute pass:** Simulation step — reads from buffer A, writes to buffer B (ping-pong)
- **Render pass:** Fullscreen quad sampling the simulation buffer, mapped to emissive color field
- **Color mapping:** Simulation values → color via a palette function in the fragment shader (deep blue, soft amber, phosphorescent green per v0.1)
- **Simulation state storage:** Two storage textures, ping-ponged each frame. Compute shader reads current-state texture, writes next-state texture. Render shader samples current-state texture. Bind group layout: group 0 for simulation textures + uniforms, group 1 for mode-specific resources. **Format fallback chain:** `rgba16float` (preferred — half-float precision sufficient for reaction-diffusion) → `rgba32float` (widely supported for `STORAGE_BINDING`, larger memory footprint) → graceful error with user message. Check supported formats after device acquisition in SEM-002. Note: this is the *storage texture format* for the simulation, distinct from the canvas presentation format (use `GPU.getPreferredCanvasFormat()`) and from the `float32-filterable` feature (which controls texture filtering, not storage binding). These are three different concerns.
- **Resolution independence (first-class design decision):** Simulation grid runs at a fixed resolution (512×512 default), independent from display resolution. Render pass upscales to canvas via the fragment shader's bilinear interpolation. DPR (device pixel ratio) for the presentation canvas capped at 1x by default (configurable). This is both a performance win (avoids 4x+ compute on high-DPI) and an aesthetic win (natural smoothing from upscaling produces the soft, luminous quality Deep Still wants). Canvas resolution is for presentation only; simulation resolution is for compute. Do not conflate them.
- **Workgroup size:** 64 (8×8) as default, adjust per profiling (U1)
- **Parameter coupling:** Parameter bus values passed as uniforms to compute shader (feed rate, kill rate, diffusion rates → control simulation character)

## 7. Acceptance Criteria

### Phase 0 — Foundation (Engine + Deep Still)

**Must have:**
- [ ] WebGPU initializes successfully; graceful error message on unsupported browsers
- [ ] Reaction-diffusion simulation runs on GPU at ≥30fps on Apple Silicon (target 60fps)
- [ ] Luminous, drifting forms visible — organic, bioluminescent quality per v0.1 §4.1
- [ ] Audio drone plays: multiple detuned oscillators with convolution reverb
- [ ] Audio starts only after user gesture (button click) — no autoplay policy violations
- [ ] Parameter bus drives both visual uniforms and audio params from shared state
- [ ] Perceptible entanglement: parameter sweeps produce correlated visual + audio shifts per evaluation protocol (SEM-007)
- [ ] Fullscreen mode works (Fullscreen API)
- [ ] Audio suspends/resumes gracefully on page visibility change (no clicks, no orphaned audio)
- [ ] Deployed to a live URL (Vercel) — shareable, opens in a tab
- [ ] Runs without errors on Chrome latest stable (must-have)
- [ ] Runs on Safari latest stable (macOS Tahoe+) with documented caveats (should-have)

**Should have:**
- [ ] Smooth fade-in on start (both audio and visual)
- [ ] Canvas resizes correctly on window resize
- [ ] Minimal UI: start/stop button, fullscreen toggle
- [ ] Parameter evolution is autonomous — experience changes over time without input
- [ ] Clean resource lifecycle: stop releases GPU resources and audio nodes; restart works without page reload

**Nice to have:**
- [ ] On-screen parameter display (debug overlay, togglable) for tuning
- [ ] Basic responsive layout (works on mobile viewport, even if experience is desktop-optimized)

### Phase 1 — Mode Expansion + Input (acceptance criteria to be detailed in Phase 1 spec)
- Second mode (Lucid Drift) running with distinct visual/audio character
- Mode switching with smooth crossfade (no pops, no visual discontinuity)
- Real MIDI input → parameter perturbation (Chrome/Firefox)
- Mode abstraction validated: adding Lucid Drift required zero engine changes

### Phase 2 — Full Mode Set + Polish
- Focus Sustain and Freeform modes complete
- PWA installable, offline-capable for loaded modes
- Performance profiled and optimized (frame budget, memory)
- Responsive across desktop, tablet, mobile viewports

### Phase 3 — Immersive
- WebXR session on Meta Quest browser
- Stereoscopic rendering at ≥72fps per eye
- Spatial audio positioning (HRTF panning)
- VR comfort: no forced camera movement, slow transitions only

## 8. Risk Register

| ID | Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|---|
| R1 | WGSL shader debugging is opaque — no breakpoints, cryptic errors | Medium | High | Start from known-good shader patterns. Build small test harnesses. Budget extra time for shader iteration. |
| R2 | Reaction-diffusion at target resolution underperforms on integrated GPUs | High | Medium | Simulation resolution decoupled from display (512×512 default). Measure frame times during SEM-005b; if avg frame time >33ms, halve simulation resolution and re-measure. If performance is unacceptable at any resolution, surface a user-facing performance warning. |
| R3 | Web Audio drone sounds thin or mechanical vs. reference artists | Medium | Medium | Layer oscillators with rich PeriodicWave shapes. Long convolution reverb adds space. AudioWorklet is escape hatch if standard nodes are insufficient. |
| R4 | Parameter coupling feels arbitrary rather than entangled | High | Medium | Careful mapping design — parameters should affect semantically related aspects of both audio and visual. Tuning session with Danny once integrated. |
| R5 | Impulse response sourcing — need CC0/CC-BY long-tail IRs <2MB | Low | Low | Verify per-file licenses from candidate sources (OpenAIR, etc.). Fallback: algorithmic reverb or dry signal. Validate in SEM-006. |
| R6 | Cross-browser WebGPU differences produce inconsistent visuals | Medium | Medium | Test on Chrome (Vulkan/D3D12) and Safari (Metal) as primary targets. Keep shaders simple in Phase 0. |
| R7 | Scope creep via mode ambition — each mode is a creative rabbit hole | High | High | Phase 0 is one mode only. Definition of done is explicit. Don't start Phase 1 until Phase 0 acceptance criteria are met. **Timebox:** Set a check-in point at 6 weeks of active work. Not a deadline — a forcing function. If Phase 0 isn't at acceptance after 6 weeks, stop and evaluate whether the architecture needs to change rather than pushing forward. Prevents the infinite-polish trap while respecting the passion-project pace. |
| R8 | Vite WGSL import needs custom plugin | Low | Low | Small Vite plugin (~20 lines) to handle .wgsl → raw string. Well-documented pattern. (Note: Vite `?raw` imports are documented — this is a known tooling pattern, not a meaningful risk.) |

## 9. Phase 0 Task Decomposition

| Task | Description | Depends On | Risk | Files |
|---|---|---|---|---|
| SEM-001 | Project scaffolding: Vite + TypeScript + WebGPU types + deployment pipeline | — | Low | package.json, tsconfig.json, vite.config.ts, index.html, src/main.ts |
| SEM-002 | WebGPU engine: device init, compute/render pipeline framework, double-buffer | SEM-001 | Medium | src/engine/gpu.ts, src/engine/types.ts |
| SEM-003 | Parameter bus: named parameter store, autonomous evolution, interpolation | SEM-001 | Low | src/engine/parameter-bus.ts, src/engine/types.ts |
| SEM-004 | Web Audio engine: AudioContext, oscillator bank, filter/reverb chain, param automation | SEM-001 | Medium | src/engine/audio.ts, src/engine/types.ts |
| SEM-005 | Mode interface + Deep Still visual: mode types, reaction-diffusion compute shader, render shader | SEM-002 | High | src/modes/types.ts, src/modes/deep-still/visual.ts, shaders/compute.wgsl, shaders/render.wgsl |
| SEM-006 | Deep Still audio: drone synthesis config, just-intonation palette, reverb IR sourcing | SEM-004 | Medium | src/modes/deep-still/audio.ts, public/assets/impulse-responses/ |
| SEM-007 | Deep Still integration: parameter mapping, coupling visual + audio, frame loop orchestration | SEM-003, SEM-005, SEM-006 | High | src/modes/deep-still/params.ts, src/modes/deep-still/index.ts, src/main.ts |
| SEM-008 | UI shell + deployment: start button, fullscreen, deploy to Vercel | SEM-007 | Low | src/ui/shell.ts, src/main.ts, vercel.json |

### Task Details

**SEM-001 — Project Scaffolding**
*Set up the development environment and deployment pipeline.*
- Initialize Vite with TypeScript template
- Configure tsconfig for strict mode + WebGPU types (`@webgpu/types`)
- Validate WGSL raw import pattern (A4)
- Configure Vercel project + connect to git repo
- Acceptance: `npm run dev` serves blank canvas; `npm run build` succeeds; Vercel deploys on push

**SEM-002 — WebGPU Engine**
*Establish GPU device and pipeline abstractions that modes will build on.*
- Request adapter + device with graceful fallback
- Log `GPUAdapter.info` (vendor, architecture, description), `GPUDevice.limits`, and `GPUDevice.features` at init for cross-device debugging
- Check supported storage texture formats after device acquisition — implement fallback chain: rgba16float → rgba32float → graceful error
- Abstract compute pipeline creation (shader module, bind group layout, pipeline layout). Wrap `createComputePipeline`/`createRenderPipeline` in try/catch; propagate `GPUPipelineError` to global error handler
- Use `pushErrorScope('validation')` / `popErrorScope()` around GPU command recording for validation error reporting
- Abstract render pipeline creation (vertex shader for fullscreen quad, fragment shader slot)
- Double-buffer management (ping-pong texture pair for simulation state)
- `_deviceLost` flag: on `GPUDevice.lost`, halt frame loop immediately, log event, show user reload message. In `stop()`: call `destroy()` on all GPU resources (textures, buffers, pipelines) and null references. Restart re-creates everything from scratch.
- Acceptance: compute shader writes to texture, render shader displays it — visible colored quad on screen; GPU adapter info logged; storage format fallback chain functional; device loss halts cleanly

**SEM-003 — Parameter Bus**
*Build the coupling mechanism that makes Semuta more than a visualizer bolted to a synth.*
- TypeScript parameter registry: name, current value, range (min/max), default
- Evolution engine: per-parameter drift rate, noise injection, attractor points
- Smooth interpolation: all value changes use exponential smoothing (no discontinuities)
- Observable: audio and visual engines subscribe to parameter changes
- Acceptance: parameter values evolve autonomously over time; changes are smooth; unit tests pass for evolution logic

**SEM-004 — Web Audio Engine**
*Synthesis framework that modes configure declaratively.*
- AudioContext creation with user-gesture gating
- Oscillator bank: create N oscillators from a frequency list, each with custom PeriodicWave
- Filter chain: configurable BiquadFilterNode(s) with parameter-driven cutoff/resonance
- Convolution reverb: ConvolverNode with loaded impulse response buffer (async decode). `isReady` state means "dry signal path functional" — does not gate on IR decode. Convolver fades in when IR finishes loading.
- Master gain with fade-in envelope. Start oscillators ~100-200ms before beginning gain fade-in to avoid transient pop.
- Parameter binding: map named parameters to AudioParam targets via `setTargetAtTime` (time constant ~0.2s) with scaling functions
- Visibility handling: `visibilitychange` → suspend/resume AudioContext with fade ramps
- Resource cleanup: `stop()` method tears down oscillators, disconnects nodes, closes or suspends context
- Acceptance: calling `start()` after user gesture produces a sustained drone (dry path immediately, convolver fades in when ready); parameter changes audibly shift the sound character; tab-switching suspends/resumes without clicks; test at low volume (~10-15% system volume) — no exposed quantization noise, aliasing, or convolver artifacts

**SEM-005a — Mode Interface**
*Define the mode contract that all modes implement.*
- TypeScript `Mode` interface: metadata, visual config (shaders + pipeline layout), audio config (synthesis graph description), parameter schema + evolution rules
- Optional lifecycle hooks: `onInit()`, `onResize(width, height)`, `onFrame(dt)`, `onDestroy()`. Modes that don't need them can omit them. Engines own device/context; hooks are for mode-specific setup and state management.
- No `vr_config` in Phase 0 — document as future consideration.
- Acceptance: interface importable by both visual and audio mode implementations; no runtime dependencies on engine internals

**SEM-005b — Deep Still Visual**
*Implement the first visual mode against the Mode interface.*
- Deep Still compute shader: Gray-Scott reaction-diffusion in WGSL. Simulation at fixed 512×512 grid resolution, decoupled from display. Render pass upscales via bilinear interpolation.
- Recommended internal staging: (1) toy simulation first — simple diffusion blur or threshold at 512×512 to validate the entire compute→render pipeline (ping-pong, format, performance), (2) Gray-Scott implementation on the validated pipeline. The toy sim derisks the plumbing; Gray-Scott is the aesthetic target. If Gray-Scott proves unworkable, the validated pipeline supports alternative simulations (layered noise fields, advection, simplified CA).
- Deep Still render shader: simulation state → emissive color field (blue/amber/green palette). Consider blue-noise dithering (~5 lines WGSL) to avoid color banding on 8-bit displays with dark palette.
- Seed initial simulation noise with `crypto.getRandomValues()` — no fixed seed, so repeat visitors see different opening sequences.
- Visual config: buffer sizes, uniform bindings, workgroup dispatch dimensions
- Acceptance: reaction-diffusion simulation visible on screen — non-uniform pattern formation within 10s; frame times profiled at 512×512; ≥30fps on Apple Silicon (target 60fps)

**SEM-006 — Deep Still Audio**
*Implement the drone synthesis for Deep Still.*
- Frequency palette: just-intonation ratios relative to root (~55 Hz). Candidates: 1:1, 3:2, 5:4, 7:4, 9:8 — producing a harmonic drone with slow beating from near-unison partials
- PeriodicWave design: rich harmonics for warmth (not pure sine — closer to soft sawtooth or triangle with rolloff)
- Convolution reverb: source and load a long-tail IR (8-12s). Validate A6. Prefer stereo IR for headphone spatial quality (~4MB budget); mono fallback (~2MB). 44.1kHz. Verify per-file CC0/CC-BY license before bundling in `public/assets/`. Fallback: dry signal path if IR fetch/decode fails. Consider algorithmic reverb fallback (simple feedback delay network) if dry signal is aesthetically insufficient.
- Synthesis config object conforming to Mode audio interface
- Acceptance: drone plays continuously; warm, enveloping character; long reverb tail; no clicks or artifacts; IR file size verified within budget; test at low volume (~10-15% system volume) — no exposed artifacts. Consider adding subtle filtered noise bed beneath oscillator bank for textural "air."

**SEM-007 — Deep Still Integration**
*Wire everything together — this is where entanglement lives or dies.*
- Deep Still parameter schema: `energy` (0-1), `density` (0-1), `warmth` (0-1), `turbulence` (0-1)
- Parameter → visual mapping: `energy` → feed rate, `density` → kill rate offset, `warmth` → color palette bias, `turbulence` → diffusion rate perturbation
- Parameter → audio mapping: `energy` → oscillator gain envelope, `density` → number of active partials, `warmth` → filter cutoff, `turbulence` → detuning spread
- Evolution rules: Deep Still targets very low energy, high density, high warmth, minimal turbulence — parameters drift toward these attractors with slow noise perturbation. Primary cycle ~45 minutes. Per-parameter cycle lengths staggered across a 35-55 minute range, explicitly designed so no two parameters share a period — prevents exact repetition, produces emergent variation over long sessions through continuously shifting phase relationships
- Frame loop: evolve parameters → push uniforms + audio params (audio throttled to ~15Hz) → compute pass → render pass (parameter evolution before compute ensures visual and audio reflect the same state each frame). Use Page Visibility API to pause rAF loop and parameter evolution when page is hidden — prevents GPU/battery waste and state drift.
- Parameter scene recorder (should-have): log timestamped parameter values to array, support replay mode that drives bus from recorded data. Supports structured evaluation and A/B comparison across revisions.
- Phase transitions (should-have): parameter evolution supports occasional attractor shifts — moments where the target attractor basin changes rather than parameters just drifting within one. Infrequent (every 10-20 minutes), gradual (transition over 2-3 minutes). Adds non-linear quality that makes generative systems feel alive.
- Acceptance: A3 validated via structured evaluation protocol:
  1. Define 3-4 parameter sweeps (e.g., energy 0→1, warmth 0→1) with expected co-changes documented
  2. Execute each sweep via debug overlay controls
  3. Verify: visual form character shifts perceptibly AND audio character shifts perceptibly AND the shifts feel coupled (not coincidental). Document expected visual and audio behavior for each sweep *before* executing it.
  4. Capture screen recordings of sweep tests for comparison across revisions. Use parameter scene recorder (SF-7) for replay-based A/B comparison.
  5. **Negative test:** Deliberately break the coupling — freeze audio parameters while sweeping visual ones (and vice versa). Confirm the experience feels noticeably worse / less coherent. If breaking the coupling doesn't feel different, the coupling isn't working — it's just two things happening at the same time.
  6. Danny evaluation as final aesthetic arbiter — confirms the experience quality, not just measurable correlation. Operates on structured evidence from steps 1-5, not impressionistic reaction.

**SEM-008 — UI Shell + Deployment**
*Minimal interface and live URL.*
- Start button: prominent, centered. Disabled until WebGPU device acquired + audio engine `isReady` resolved (`isReady` = dry signal path functional, not IR decoded). Starts AudioContext + begins rendering. Convolver fades in when IR finishes loading.
- **Start experience transition:** This is a meditative app — the first three seconds set the tone. The button should fade out (not snap-disappear). The canvas should fade in from black over ~2 seconds. Audio fades in per the gain envelope (~5s). If the simulation needs warm-up frames, show a minimal loading state (subtle, not a spinner). The transition from "click" to "immersed" should feel like entering a space, not loading a page.
- Loading state: show IR fetch + decode progress — but do not gate entry on it. Keep minimal and consistent with the meditative aesthetic
- Fullscreen button: toggles Fullscreen API
- Stop/pause: tears down resources cleanly, returns to start state (restart without page reload)
- Canvas fills viewport (no scrollbars, no margins)
- Deploy to Vercel: verify live URL works on Chrome and Safari; verify total public/ bundle size and audio asset delivery
- Acceptance: shareable URL opens to a clean start screen; start transition feels intentional (fade, not snap); one click enters the experience; fullscreen works; start/stop/restart cycle works cleanly; no console errors

## 10. Business Context (Business Advisor Overlay)

### Lifecycle Stage: Ideation
Pre-revenue, pre-user, pre-product. Stage-appropriate action is validation: build a minimal proof-of-concept, share it, evaluate response. Stage-inappropriate actions: business plans, entity formation, pricing analysis, go-to-market strategy. The spec's deferral of all monetization questions past Phase 0 is correct for this stage.

### Jobs-to-be-Done Analysis
Three candidate "jobs" a user might hire Semuta for:

| Job | Competitive Density | Defensibility |
|---|---|---|
| "Help me relax without active effort" | High — Endel, Calm, Brain.fm | Low — well-funded incumbents |
| "Give me an immersive focus environment" | High — Brain.fm, lo-fi beats, Coffitivity | Low — same crowded space |
| "Show me something beautiful I can surrender to" | Low — art installations, niche generative art | High — requires creative vision, hard to copy |

The most defensible position is Job 3. Audio+visual entanglement is the differentiator — nobody else is doing browser-native coupled generation.

### Competitive Landscape

| Competitor | Model | Gap Semuta Fills |
|---|---|---|
| Endel | Audio-only, subscription, native apps | No visual dimension. Not shareable via URL. |
| Brain.fm | Audio-only, subscription | Same gaps. |
| Calm / Headspace | Guided content, subscription | Not generative — library model, not emergent. |
| Electric Sheep / screensavers | Generative visual, no audio coupling | No meditative intent. No audio entanglement. |
| YouTube ambient | Pre-recorded, ad-supported | Not generative. Loops. Finite. |

Switching cost in both directions is near-zero (Semuta is a URL). Distribution and experience quality are the only moats.

### Cost Structure
Near-zero marginal cost. Static site (Vercel free tier), no backend compute, no content licensing (self-generating). Danny's time is the only real cost, framed as enjoyment, not labor. Claude API is sunk cost. Cost floor is effectively $0/month — one of the cheapest possible software projects to operate.

### Risk/Reward
- **Downside:** Personal time on something that stays a personal toy. No financial exposure.
- **Upside floor:** Portfolio piece demonstrating cutting-edge web tech (WebGPU compute shaders). Creative differentiation from the SE career track.
- **Upside ceiling:** Niche audience willing to pay for a genuinely meditative generative experience — especially in VR (Phase 3). The wellness/meditation app market is large and growing (dominated by content-library models, not generative ones) — validate market size with current data if monetization becomes relevant.

### Architectural Constraint with Business Implications
Do not build an account system or backend until there is evidence someone besides Danny wants to use it. The static-site, no-backend constraint is good engineering *and* good business — it keeps the cost floor at zero and avoids premature infrastructure investment. If monetization becomes relevant later, gating modes client-side (encrypted mode bundles, license key validation) is simpler and cheaper than running auth infrastructure.

## 11. Open Questions (Deferred)

Per v0.1 §6.2 — all deferred past Phase 0:
- Persistence (localStorage, accounts, URL params)
- Sharing (state serialization for shareable moments)
- Accessibility (what does a11y mean for meditative audiovisual art?)
- Monetization (free/paid/donation model)
- Name (Semuta references a fictional narcotic — evaluate branding fit)

## 12. Non-Goals for Phase 0

- No WebXR / VR support
- No MIDI input (real or simulated — simulated input was in v0.1 but adds complexity without validating the core)
- No mode switching (only one mode exists)
- No PWA / offline support
- No WebGL fallback
- No mobile optimization (should work but not tuned)
- No analytics or telemetry
