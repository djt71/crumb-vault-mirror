---
type: action-plan
status: draft
domain: software
project: semuta
skill_origin: action-architect
created: 2026-03-18
updated: 2026-03-18
---

# Semuta — Action Plan (Phase 0)

## Phase 0 Definition of Done

Phase 0 is complete when:
1. All SEM-001 through SEM-008 acceptance criteria are met
2. Live URL has been shared with at least one person besides Danny
3. Danny has confirmed the experience produces the intended meditative quality for at
   least 3 minutes of sustained use

Items 1-2 are mechanical. Item 3 is the real acceptance test.

## M1: Development Environment + Core Engines

Stand up the project scaffold, acquire a WebGPU device, build the three independent
engine subsystems (GPU, audio, parameter bus), and define the Mode interface that
downstream tasks build against.

### Phase 1a: Scaffolding + Mode Interface (SEM-001, SEM-005a)

Initialize the Vite + TypeScript project, configure WebGPU types, validate the WGSL
import pattern, connect Vercel deployment, and define the Mode TypeScript interface with
optional lifecycle hooks (`onInit`, `onResize`, `onFrame`, `onDestroy`).

SEM-005a (Mode interface) is split out from the visual shader work — it's an
architectural decision (low risk, fast) that unblocks SEM-006 (audio mode) early,
even while the visual shaders are still being iterated in SEM-005b.

**Success criteria:** `npm run dev` serves a page with a canvas element; `npm run build`
produces a clean production bundle; Vercel deploys on push; WGSL files import as raw
strings. Mode interface defined with visual/audio/parameter config slots and lifecycle
hooks.

### Phase 1b: Core Engines (SEM-002, SEM-003, SEM-004)

Build the three foundational subsystems in parallel — they share only `types.ts` and
have no runtime dependencies on each other at this stage.

- **SEM-002 (WebGPU engine):** Device acquisition, compute/render pipeline abstraction,
  double-buffer ping-pong, storage texture format fallback chain (rgba16float →
  rgba32float → error), WebGPU error scopes, GPU info logging. Device loss is logged
  with a user-facing reload suggestion and frame loop halt — full device recovery is
  a Phase 1 concern.
- **SEM-003 (Parameter bus):** Named parameter store, autonomous evolution with
  exponential smoothing, observable subscriptions. Should-have: scene recorder for
  evaluation replay, phase transitions (attractor shifts).
- **SEM-004 (Audio engine — high risk):** AudioContext with gesture gating, oscillator
  bank (pre-warm before gain ramp), filter chain, convolution reverb with async IR
  loading, visibility-aware suspend/resume, resource cleanup. `isReady` = dry signal
  path functional (does NOT gate on IR decode). Convolver fades in when IR finishes
  loading. `setTargetAtTime` with ~0.2s time constant. Risk elevated due to audio
  lifecycle complexity.

**Success criteria:** GPU engine renders a colored quad from a compute shader; GPU info
logged; format fallback tested; device loss halts cleanly with user message. Parameter
bus evolves values autonomously with unit tests passing (using stub schema). Audio engine
produces a sustained drone; convolver fades in after IR loads; `isReady` resolves on dry
path.

**Parallelism note:** SEM-002, SEM-003, and SEM-004 can be implemented in any order or
interleaved. All depend only on SEM-001. SEM-005a can run in parallel with SEM-002.

## M2: Deep Still Mode

Implement the first (and only Phase 0) mode — visual reaction-diffusion, drone
synthesis, and the parameter coupling that makes them feel entangled.

### Phase 2a: Visual + Audio Modes (SEM-005b, SEM-006)

Build mode-specific implementations on top of the core engines. These are parallel —
visual doesn't need audio and vice versa. Both build against the Mode interface
(SEM-005a).

- **SEM-005b (Deep Still visual — high risk):** Staged internally: (1) toy simulation
  (diffusion blur at 512×512) validates compute→render pipeline, (2) Gray-Scott on the
  validated pipeline. Simulation runs at fixed 512×512 grid, decoupled from display —
  render pass upscales via bilinear interpolation (both a performance and aesthetic
  win). If Gray-Scott proves unworkable, the validated pipeline supports alternative
  simulations (layered noise, advection, CA).
- **SEM-006 (Deep Still audio):** Just-intonation frequency palette, PeriodicWave design,
  IR sourcing and license verification. IR files fetched at runtime, not bundled. Prefer
  stereo IR for headphone quality. Test at low volume. Validates A2 + A6.

**Success criteria:** Reaction-diffusion simulation visible on screen — non-uniform
pattern formation within 10s of start at 512×512; frame times profiled. Drone plays
with spectral content at declared harmonic ratios and long reverb tail; IR source URL +
license documented.

### Phase 2b: Integration (SEM-007)

Wire visual + audio + parameter bus into a single frame loop. Define the Deep Still
parameter schema (energy, density, warmth, turbulence) and map parameters to both
engines. This is where entanglement succeeds or fails.

**Evolution timescale:** Primary cycle ~45 minutes. Per-parameter cycle lengths staggered
across a 35-55 minute range, no shared periods. Target session ~20-30 minutes — cycle
deliberately longer than a session so user never experiences the full arc.

**Success criteria:** Each parameter maps to ≥1 visual and ≥1 audio dimension. Audio
parameter pushes throttled to ~10-15Hz with ~0.2s time constant. Page Visibility API
pauses rAF + parameter evolution when hidden. Structured evaluation with documented
expectations, screen recordings, scene recorder replay, negative test (break coupling →
confirm degradation). Danny confirms entanglement quality on structured evidence.

## M3: Ship

### Phase 3a: UI Shell + Deployment (SEM-008)

Minimal interface: start button (gated on WebGPU device + audio `isReady` — dry path,
NOT IR decode), fullscreen toggle, loading state (shows IR progress but does not gate
entry). Deploy to Vercel.

**Browser targets:** Chrome latest stable (must-have), Safari latest stable macOS Tahoe+
(should-have — document caveats, visual similarity not pixel-identity).

**Success criteria:** Shareable URL opens to a clean start screen; start transition feels
intentional — button fades, canvas fades in from black, audio fades in; convolver joins
when ready (nobody notices reverb arriving late). Fullscreen works; start/stop/restart
clean. Error UX for shader compile failures and device loss. No console errors on
Chrome.

## Dependency Graph

```
SEM-001 (scaffold)
  ├─→ SEM-005a (Mode interface)  ─→ SEM-005b (Deep Still visual)  ─┐
  ├─→ SEM-002 (GPU engine)       ─→ SEM-005b                       │
  ├─→ SEM-003 (parameter bus)    ──────────────────────────────────→├─→ SEM-007 (integration) → SEM-008 (UI + deploy)
  ├─→ SEM-004 (audio engine)     ─→ SEM-006 (Deep Still audio)    ─┘
  └─→ SEM-005a                   ─→ SEM-006
```

Dependency clarification: SEM-007 depends on SEM-006 for audio mode config (SEM-004
flows through SEM-006). SEM-008 depends on SEM-004's `isReady` for start-button gating
(flows through SEM-007 transitively).

## Critical Path

SEM-001 → SEM-002 → SEM-005b → SEM-007 → SEM-008

The visual pipeline (GPU engine → reaction-diffusion shader) is the longest and
highest-risk chain. SEM-005b carries both R1 (WGSL debugging) and R2 (performance)
risks — mitigated by staged approach (toy sim first, Gray-Scott second). SEM-005a
(Mode interface) is off the critical path — it's fast and depends only on SEM-001.
Parameter bus and audio engine are off the critical path and can absorb delays.

## Risk-Informed Sequencing

Start SEM-005b (visual shaders) as early as possible — it's the highest-risk,
hardest-to-debug task. Get SEM-005a (Mode interface) done first so SEM-006 can start
even while visual shaders are being iterated. The toy-sim staging within SEM-005b
derisks the pipeline plumbing before tackling Gray-Scott.

Recommended implementation order within milestones:
1. SEM-001 (scaffolding)
2. SEM-005a (Mode interface) + SEM-002 (GPU engine) — parallel; interface unblocks
   SEM-006, GPU unblocks critical path
3. SEM-005b (Deep Still visual — staged: toy sim → Gray-Scott)
4. SEM-003 (parameter bus) — needed before integration
5. SEM-004 (audio engine) + SEM-006 (audio mode) — back-to-back; Mode interface
   already available from step 2
6. SEM-007 (integration) — all dependencies met
7. SEM-008 (UI + deploy)
