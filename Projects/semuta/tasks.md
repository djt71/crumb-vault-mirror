---
type: tasks
status: active
domain: software
project: semuta
skill_origin: action-architect
created: 2026-03-18
updated: 2026-03-18
---

# Semuta — Tasks (Phase 0)

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|---|---|---|---|---|---|---|
| SEM-001 | Project scaffolding: Vite + TypeScript + WebGPU types + WGSL import + Vercel deployment | todo | — | low | infra | `npm run dev` serves page with canvas; `npm run build` succeeds with zero errors; `.wgsl` file imports as string in TypeScript (Vite `?raw`); Vercel deploys on git push; ESLint passes with TypeScript strict config |
| SEM-002 | WebGPU engine: device init, pipeline abstraction, double-buffer, format fallback, error scopes, device loss, GPU info logging | todo | SEM-001 | medium | engine | `requestAdapter()` + `requestDevice()` succeed on Chrome; graceful error message when WebGPU unavailable; `GPUAdapter.info`, `GPUDevice.limits`, `GPUDevice.features` logged at init; storage texture format fallback chain (rgba16float → rgba32float → error) functional; compute/render pipeline creation wrapped in try/catch with `GPUPipelineError` propagated to global error handler; `pushErrorScope('validation')` / `popErrorScope()` around command recording; compute shader writes to storage texture; render shader displays texture as visible colored quad; GPUDevice `lost` event sets `_deviceLost` flag, halts frame loop, logs event, shows user reload message; `stop()` destroys all GPU resources and nulls references |
| SEM-003 | Parameter bus: named parameter store, autonomous evolution, exponential smoothing, observable subscriptions, scene recorder | todo | SEM-001 | low | engine | Parameters registered with name/range/default; `evolve(dt)` produces values that change over time within declared ranges; exponential smoothing eliminates discontinuities; subscriber callback fires on value change; Vitest unit tests pass for evolution logic; includes test parameter schema stub with ranges and evolution rules (Deep Still full schema in SEM-007); should-have: scene recorder — log timestamped values to array, replay mode drives bus from recorded data; should-have: phase transitions — occasional attractor shifts (every 10-20 min), gradual transition (2-3 min) |
| SEM-004 | Web Audio engine: AudioContext with gesture gate, oscillator bank, filter chain, convolution reverb, visibility handling, cleanup | todo | SEM-001 | high | engine | AudioContext created only after user gesture (no autoplay violation); oscillator bank produces sound from frequency list; oscillators started ~100-200ms before gain fade-in ramp (avoid transient pop); filter cutoff is parameter-driven; ConvolverNode loads IR buffer asynchronously; `isReady` = dry signal path functional (does NOT gate on IR decode); convolver fades in when IR decoded; IR fetch/decode errors handled gracefully (audio graph resolves without ConvolverNode); `setTargetAtTime` with time constant ~0.2s for parameter automation; `visibilitychange` suspends/resumes without audible clicks; `stop()` tears down all nodes cleanly; test at low volume (~10-15% system) — no exposed quantization noise, aliasing, or convolver artifacts |
| SEM-005a | Mode interface: TypeScript Mode type definition with visual/audio/parameter config slots + lifecycle hooks | todo | SEM-001 | low | architecture | `Mode` interface defined with visual config (shaders + pipeline layout), audio config (synthesis graph description), parameter schema + evolution rules; optional lifecycle hooks: `onInit()`, `onResize(w,h)`, `onFrame(dt)`, `onDestroy()`; no `vr_config` in Phase 0; interface importable by both visual and audio mode implementations; no runtime dependencies on engine internals |
| SEM-005b | Deep Still visual: Gray-Scott compute shader, emissive color field render shader (staged: toy sim first) | todo | SEM-002, SEM-005a | high | visual | Internal staging: (1) toy simulation (diffusion blur/threshold at 512×512) validates compute→render pipeline, then (2) Gray-Scott on validated pipeline; compute shader runs reaction-diffusion step per frame at 512×512 fixed grid (decoupled from display); render shader upscales to canvas via bilinear interpolation, maps simulation to blue/amber/green emissive palette; seed with `crypto.getRandomValues()` (no fixed seed); non-uniform pattern formation visible within 10s; frame times profiled — document avg FPS at 512×512 on M1/M2 Mac Chrome; ≥30fps on Apple Silicon (target 60fps); if avg frame time >33ms, halve grid and re-measure; storage texture format validated per SEM-002 fallback chain; nice-to-have: blue-noise dithering in render shader to avoid color banding on 8-bit displays |
| SEM-006 | Deep Still audio: just-intonation frequency palette, PeriodicWave design, IR sourcing + license verification | todo | SEM-004, SEM-005a | medium | audio | Frequency palette uses just-intonation ratios from ~55 Hz root; PeriodicWave shapes produce warm harmonics (not pure sine); spectral content includes harmonics at declared ratios; IR file is CC0 or CC-BY licensed — exact source URL + license link documented; prefer stereo IR under ~4MB budget for headphone spatial quality, mono fallback under ~2MB; if no suitable IR found, synthetic IR generated via offline tool; IR fetched at runtime (not bundled into JS); drone plays continuously with long reverb tail; dry-signal fallback works when IR load fails; nice-to-have: algorithmic reverb fallback (simple FDN) if dry signal aesthetically insufficient; nice-to-have: subtle filtered noise bed beneath oscillator bank for textural "air"; test at low volume (~10-15% system) — no exposed artifacts |
| SEM-007 | Deep Still integration: parameter schema, parameter→visual/audio mapping, frame loop, entanglement evaluation | todo | SEM-003, SEM-005b, SEM-006 | high | integration | Parameter schema has 4 named params (energy, density, warmth, turbulence) with ranges and evolution rules; per-parameter cycles staggered 35-55 min (no shared periods); should-have: phase transitions (attractor shifts every 10-20 min); each parameter maps to ≥1 visual and ≥1 audio dimension; visual uniforms update from parameter bus each frame; audio params update via `setTargetAtTime` (time constant ~0.2s) throttled to ~10-15Hz; frame loop: evolve→push→compute→render; Page Visibility API pauses rAF loop + parameter evolution when hidden; structured evaluation: (1) document expected behavior before each sweep, (2) execute 3-4 sweeps, (3) capture screen recordings, (4) replay via scene recorder for A/B comparison, (5) negative test: freeze one side while sweeping other — confirm degradation, (6) Danny confirms entanglement quality on structured evidence |
| SEM-008 | UI shell + deployment: start transition, loading state, fullscreen, stop/restart, error UX, cross-browser | todo | SEM-007 | low | ui | Start button disabled until WebGPU device acquired + audio `isReady` (dry path — NOT IR decode); loading state shows IR fetch+decode progress but does not gate entry; start transition: button fades out, canvas fades in from black (~2s), audio fades in per gain envelope; fullscreen toggle via Fullscreen API; stop tears down cleanly, restart works without page reload; shader compile errors and device loss show user-friendly message with reload option; canvas fills viewport (no scrollbars); must-have: Chrome latest stable works without errors; should-have: Safari latest stable (macOS Tahoe+) works — visual output subjectively similar (same aesthetic character, not pixel-identical), audio correct, document caveats; nice-to-have: mobile tap-test on iOS Safari (graceful error, readable message, nothing catastrophically broken) |

## Phase 0 Definition of Done

Phase 0 is complete when:
1. All SEM-001 through SEM-008 acceptance criteria are met
2. Live URL has been shared with at least one person besides Danny
3. Danny has confirmed the experience produces the intended meditative quality for at least 3 minutes of sustained use

Items 1-2 are mechanical. Item 3 is the real acceptance test.

## Notes

- **Critical path:** SEM-001 → SEM-002 → SEM-005b → SEM-007 → SEM-008
- **Parallel opportunities:** SEM-002/003/004/005a after SEM-001; SEM-005b/006 after their respective engines + Mode interface
- **Dependency clarification:** SEM-007 depends on SEM-006 for audio mode config (SEM-004 flows through SEM-006). SEM-008 depends on SEM-004's `isReady` for start-button gating (flows through SEM-007 transitively).
- **Asset management:** IR files in `public/assets/impulse-responses/` are fetched at runtime, not bundled into JS. Vite copies `public/` to build output. SEM-008 loading state reflects IR fetch + decode progress but does not gate entry.
- **Recommended implementation order:** SEM-001 → SEM-005a + SEM-002 (parallel) → SEM-005b (highest risk, staged: toy sim first) → SEM-003 → SEM-004 + SEM-006 (back-to-back) → SEM-007 → SEM-008
- **Headphones recommended:** Document in UI that headphone listening is the design target (55 Hz root won't reproduce on small speakers).

## Design Decisions

- **Evolution timescale:** Primary cycle ~45 minutes. Per-parameter cycle lengths staggered across a 35-55 minute range, no shared periods. Target session ~20-30 minutes — cycle deliberately longer than a session so user never experiences the full arc. Use filtered noise (Perlin/simplex) for parameter evolution, not sinusoidal LFOs (avoids detectable periodicity).
- **Resolution independence:** Simulation grid 512×512 default, decoupled from display resolution. Render pass upscales via bilinear interpolation. DPR capped at 1x by default. Both a performance and aesthetic decision.
- **Start gating:** `isReady` = dry signal path functional. Does not gate on IR decode. Convolver fades in when ready.
- **Browser targets:** Chrome (must-have), Safari macOS Tahoe+ (should-have with caveats), Firefox (not Phase 0).

## Design Notes (from peer review synthesis)

- **DN-1: Latent parameter layer.** If A3 validation reveals coupling feels thin, first intervention: latent state vector with coupled dynamics, named parameters derived as projections. Phase 1 escape hatch.
- **DN-2: RD is a validation vehicle.** Reaction-diffusion validates the architecture but is not the definitive visual language. Later modes will need advection, particles, volumetric impostors.
- **DN-3: Alternative visual approach.** Layered smooth noise fields advected over time — simpler shader code, easier art-direction. Plan B if Gray-Scott proves too finicky.
- **DN-4: Audio enhancement bucket.** If SEM-006 technically passes but aesthetically underwhelms: noise bed, stereo decorrelation, gentle saturation, algorithmic reverb.
- **DN-5: Frame loop XR compatibility.** Frame loop should accept external timing source (not hardcode rAF). Render pass should not hardcode single-viewport assumptions. Phase 0 design consideration for Phase 3 compatibility.

## Assumption Definitions

- **A1:** Reaction-diffusion at 512×512 fixed grid runs at 60fps on Apple Silicon integrated GPU via WebGPU — validated in SEM-005b
- **A2:** 3-5 detuned Web Audio oscillators with convolution reverb produce drone quality sufficient for the meditative effect — validated in SEM-006
- **A3:** Parameter bus coupling produces perceptible entanglement rather than arbitrary co-occurrence — validated in SEM-007
- **A5:** Free-tier Vercel hosting is sufficient for a static WebGPU app — validated in SEM-008
- **A6:** Publicly licensed impulse response files exist at sufficient quality for long-tail convolution reverb (8-12s) — validated in SEM-006

(A4 retired — Vite `?raw` imports are documented tooling, not a hypothesis.)
