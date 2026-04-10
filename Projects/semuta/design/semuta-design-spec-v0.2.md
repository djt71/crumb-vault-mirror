---
type: design
status: active
domain: software
project: semuta
created: 2026-03-15
updated: 2026-03-18
---

# Semuta — Design Specification v0.2

**Status:** Revised
**Created:** 2026-03-15
**Revised:** 2026-03-18
**Author:** Danny (architecture/product), Claude (technical design)

**Precedence:** This is the constitutional reference for what Semuta is and is not.
When execution details conflict between this document and the engineering specification
(`specification.md`), the engineering spec governs for Phase 0 implementation decisions.
This document governs creative vision, architectural philosophy, and multi-phase scope.

**Changes from v0.1:** Removed simulated MIDI from Phase 0 deliverables (deferred to
Phase 1 per engineering spec). Added lifecycle hooks to Mode interface. Reflected
SEM-005a/005b split. Corrected browser support claims. Softened absolute novelty claim.
Added design notes from peer review synthesis. Reframed accessibility open question.
Added headphone recommendation.

---

## 1. What Semuta Is

Semuta is a generative audiovisual meditation platform. It produces coupled sound and light — ambient soundscapes entangled with GPU-driven visual environments — designed to dissolve the user's sense of time and reward sustained, passive attention.

The name references the fictional drug-music pairing from Frank Herbert's *Dune Messiah*, where atonal vibrations produce a state of timeless ecstasy. Semuta pursues that same quality through technology rather than pharmacology: sound and image that operate below conscious musical and visual grammar, creating an experience that is felt rather than watched or listened to.

Semuta is not a visualizer. It does not react to external audio. It is not an instrument. It is a self-composing environment that accepts gentle influence from optional inputs.

No browser-native application we've found produces coupled generative audio and visuals designed for sustained meditative attention. Existing browser-based tools are either audio-only (Endel, Brain.fm), visually reactive to external audio (music visualizers), or require installation (native apps). Semuta fills the gap between these categories.

### 1.1 Design References

- **Endel** — Generative audio app with purpose-driven modes (Focus, Relax, Sleep, Move). Semuta extends this model by adding a tightly coupled visual dimension.
- **Semuta music** (*Dune Messiah*) — Atonal vibrations that dissolve temporal perception. Design target: sound that rewards surrender rather than attention.
- **Squid Lake** (*Star Wars: Revenge of the Sith*) — Mon Calamari ballet performed inside anti-gravity water spheres. Luminous, semitransparent forms moving through a fluid medium, abstract enough to sit between creature and physics. Design target: visuals that inhabit the ambiguous space between organic movement and procedural simulation.
- **Cirque du Soleil "O"** — The real-world inspiration for Squid Lake. Performers in water, gravity suspended, movement slowed and made strange by the medium.

### 1.2 Core Principles

1. **Passivity first.** The default experience requires zero interaction. Open it, let it run. Inputs are influence channels, not controls.
2. **Temporal dissolution.** No beats, no loops, no visual rhythms that anchor the viewer in clock time. State changes are gradual enough to be imperceptible in the moment but unmistakable over minutes.
3. **Entanglement over reaction.** Audio and visual are not cause-and-effect. They are co-expressions of a shared generative state. A tone does not "trigger" a visual event — both arise from the same underlying process.
4. **Organic ambiguity.** Visuals should resist classification. Not particles, not fluid, not creatures — something that borrows qualities from all three. The viewer should be uncertain whether they are watching biology, physics, or mathematics.
5. **Modes with purpose.** Each mode exists for a reason — a cognitive or emotional state it supports. A freeform/random mode exists for pure exploration, but purpose-driven modes are the primary offering.

---

## 2. Architecture Overview

### 2.1 System Layers

```
┌─────────────────────────────────────────────────┐
│                   Semuta App                     │
│                                                  │
│  ┌─────────────┐  ┌──────────┐  ┌────────────┐  │
│  │   Modes     │  │  Modes   │  │   Modes    │  │
│  │  (visual)   │  │ (audio)  │  │ (mapping)  │  │
│  └──────┬──────┘  └────┬─────┘  └─────┬──────┘  │
│         │              │              │          │
│  ┌──────┴──────────────┴──────────────┴──────┐   │
│  │           Parameter Bus                   │   │
│  │     (shared generative state)             │   │
│  └──────┬──────────────┬─────────────────────┘   │
│         │              │                         │
│  ┌──────┴──────┐ ┌─────┴──────┐                  │
│  │ Visual      │ │ Audio      │                  │
│  │ Engine      │ │ Engine     │                  │
│  │ (WebGPU)    │ │ (Web Audio)│                  │
│  └─────────────┘ └────────────┘                  │
│                                                  │
│  ┌──────────────────────────────────────────┐    │
│  │           Input Layer                    │    │
│  │  MIDI · Microphone · Sensors · Clock     │    │
│  └──────────────────────────────────────────┘    │
│                                                  │
│  ┌──────────────────────────────────────────┐    │
│  │           Platform Layer                 │    │
│  │  Browser (2D) · WebXR (VR) · PWA        │    │
│  └──────────────────────────────────────────┘    │
└─────────────────────────────────────────────────┘
```

### 2.2 Layer Responsibilities

**Platform Layer** — Manages surface creation (canvas, XR session), device capabilities, and presentation. The rest of the system is platform-agnostic; it produces frames and audio without knowing whether it's rendering to a flat screen or a VR headset.

**Input Layer** — Normalizes external signals into a common format. A MIDI note-on, a microphone amplitude spike, and a time-of-day transition all become the same thing: a parameter influence event with a source, a target, and a magnitude. Inputs are optional. The system generates a complete experience with zero external input. Input layer is deferred to Phase 1; Phase 0 runs on autonomous evolution only.

**Parameter Bus** — The shared nervous system. A set of named, continuously-evolving parameters (e.g., `energy`, `density`, `warmth`, `turbulence`) that drive both audio and visual engines simultaneously. Parameters evolve autonomously via mode-defined rules and are perturbed by input events. This is where entanglement lives — audio and visual are coupled because they read from the same state, not because one drives the other.

**Visual Engine** — WebGPU-based. Manages compute pipelines (simulation), render pipelines (presentation), and the GPU resource lifecycle. Modes provide shader code and configuration; the engine provides the execution environment.

**Audio Engine** — Web Audio API-based. Manages oscillator banks, audio graph routing, effects (reverb, delay, filtering), and output. Modes provide synthesis configurations and parameter-to-audio mappings; the engine provides the runtime. Audio is designed for headphone listening — the 55Hz root fundamental won't reproduce on small speakers.

**Modes** — Self-contained generative definitions. Each mode specifies:
- A visual program (shaders, simulation rules, rendering approach)
- An audio program (synthesis graph, tonal material, temporal behavior)
- A parameter mapping (how the shared parameter bus drives both programs)
- Input mappings (how external inputs influence parameters, if at all — Phase 1+)
- Metadata (name, description, purpose, recommended duration)

### 2.3 Mode Abstraction

A mode is a plugin. It does not manage its own GPU device, audio context, or input listeners. It receives a parameter state and produces instructions for the engines.

```
Mode Interface (conceptual):
  metadata        → name, description, purpose, tags
  visual_config   → shaders (WGSL), pipeline layout, buffer definitions, render settings
  audio_config    → synthesis graph definition, tonal palette, envelope shapes
  param_schema    → declares which parameters this mode uses and their ranges
  param_rules     → autonomous evolution rules (drift rates, attractor points, noise functions)
  input_mappings  → how input events perturb parameters (optional, Phase 1+)
  lifecycle hooks → onInit(), onResize(w, h), onFrame(dt), onDestroy() (all optional)
```

VR config (camera placement, stereoscopic rendering, spatial audio) is a future consideration for Phase 3. Not part of the Phase 0 interface.

Lifecycle hooks are optional — modes that don't need init, resize, per-frame state packing, or teardown logic can omit them. Engines own device/context; hooks are for mode-specific setup and state management.

This separation means:
- New modes can be added without touching engine code.
- The same mode runs on flat screen and VR with minimal adaptation.
- Modes can be developed and tested independently.
- Community-contributed modes become possible in the future.

---

## 3. Technology Stack

### 3.1 Rendering — WebGPU

**Why WebGPU over WebGL:** Compute shaders. The visual simulations Semuta requires (reaction-diffusion, fluid dynamics, particle systems with complex interactions) need GPU-side computation, not just vertex/fragment rendering. WebGL cannot do this. WebGPU's compute pipeline allows the simulation to run entirely on the GPU, with the render pipeline consuming the simulation output directly — no CPU round-trip per frame.

**Browser support (as of March 2026):**
- Chrome/Edge: full support (stable since 113+). Primary Phase 0 target.
- Safari: partial support (26.0+, macOS Tahoe). Secondary validation target — note caveats around storage texture formats and feature availability.
- Firefox: disabled by default on all current stable versions. Not a Phase 0 target.
- iOS Safari (26+): supported but not a Phase 0 optimization target.
- Global coverage: ~82.7% (caniuse.com, March 2026).

**Shader language:** WGSL (WebGPU Shading Language). Text-based, statically validated, portable across backends (Vulkan, Metal, D3D12).

**Key patterns:**
- Double-buffer (ping-pong) for simulation state
- Compute pass → render pass pipeline per frame
- Storage textures for simulation grids
- Instanced rendering for particle-like elements
- Workgroup size of 64 as default (GPU-optimal for most hardware)
- Simulation resolution decoupled from display resolution (see §4.1 DN-2)

### 3.2 Audio — Web Audio API

**Why Web Audio API:** It is the only browser-native option for real-time audio synthesis. It provides oscillators, gain nodes, filters (biquad), convolution reverb, delay lines, wave shapers, and analyser nodes. The audio graph model maps naturally to generative synthesis architectures.

**Capabilities relevant to Semuta:**
- OscillatorNode with custom PeriodicWave for rich timbres
- Multiple oscillators with microtonal detuning for beating/shimmering effects
- ConvolverNode for long-tail reverb (impulse response-based)
- BiquadFilterNode for spectral shaping that evolves over time
- AudioParam automation for smooth, scheduled parameter changes
- Offline rendering for pre-computing textures or audio segments

**Tonal approach:** Just intonation ratios rather than equal temperament. Harmonic series relationships produce the slow beating and shimmering characteristic of drone music. Mode definitions specify a pitch palette (a set of ratios relative to a root frequency) rather than note names.

**Listening context:** Designed for headphone listening. The 55Hz root fundamental won't reproduce on small speakers; the harmonics will carry, but the full experience requires headphones or full-range speakers. This should be noted in UI/onboarding.

### 3.3 Input — Web MIDI API + Others

**Web MIDI:** Supported in Chrome/Edge. Not supported in Safari or Firefox (Safari declined due to fingerprinting concerns; Firefox support varies). Acceptable limitation — non-Chrome users get the passive experience; Chrome/Edge users can optionally connect MIDI controllers.

**MIDI's role in Semuta:** An influence channel, not a performance interface. A MIDI note-on event does not trigger a discrete sound or visual. It perturbs the parameter bus — increasing energy, shifting warmth, introducing a new harmonic partial — and the system integrates that perturbation over time. The result should feel like dropping dye into water, not pressing a button.

**Input layer is deferred to Phase 1.** Phase 0 runs on autonomous evolution only.

**Other inputs (future):**
- Microphone (Web Audio API `MediaStreamSource`) — ambient sound analysis as input signal
- Device sensors (DeviceOrientation API) — tilt/rotation as slow parameter drift (especially relevant for mobile/tablet)
- Time of day (JS `Date`) — circadian-aware parameter defaults
- Biometric (future, requires hardware) — heart rate, breathing rate as input signals

### 3.4 Immersive — WebXR

**VR target:** Meta Quest (runs Chromium-based Meta Quest Browser with WebGPU support). WebXR Device API provides stereoscopic rendering, head tracking, and spatial audio positioning.

**Why design for VR from the start:** The experience of being *inside* a generative luminous environment is categorically different from watching one on a screen. For a meditative application, immersion is not a luxury feature — it may be the optimal delivery format. Designing the engine to be surface-agnostic (flat canvas or XR session) from the beginning avoids a painful retrofit later.

**VR-specific considerations:**
- Stereoscopic rendering (two viewpoints per frame)
- Performance budget is tighter (Quest targets 72Hz, ideally 90Hz, per eye)
- Spatial audio (Web Audio API supports HRTF panning via `PannerNode`)
- Comfort: no forced camera movement, no sudden visual changes, slow transitions only
- Mode VR configs can specify environment geometry (surrounding sphere, infinite plane, volumetric cloud, etc.)

**Frame loop design note:** The frame loop should accept an external timing source rather than hardcoding `requestAnimationFrame`. WebXR uses its own rAF equivalent. Render pass should not hardcode single-viewport assumptions. This is a Phase 0 design consideration even though XR is Phase 3.

### 3.5 Deployment

**Primary:** Hosted web app (e.g., `semuta.app` or similar). Single URL, zero install, works on desktop and mobile browsers with WebGPU support.

**Secondary:** PWA (Progressive Web App). Installable to home screen, offline-capable for pre-loaded modes. Service worker caches mode assets (shaders, impulse responses, configuration).

**Tertiary:** VR via WebXR in Meta Quest Browser. Same codebase, same URL, detected and adapted at runtime.

**Future consideration:** Native app wrappers (Electron, Capacitor, or direct native builds using wgpu/Dawn) if performance or distribution requirements outgrow the browser. The architecture should not preclude this, but it is not a v1 target.

---

## 4. Modes — Initial Set

The following modes are design targets. Each is described by purpose, aesthetic character, and technical approach. Detailed mode specifications will be separate documents.

### 4.1 Deep Still (working name)

**Purpose:** Deep relaxation, pre-sleep wind-down.
**Visual character:** Slow, luminous masses drifting through a dark medium. Bioluminescent quality. Forms merge and separate like oil in water. Very low turbulence. Dominant colors: deep blue, soft amber, occasional phosphorescent green.
**Audio character:** Sub-bass drones with slow harmonic evolution. Long reverb tails. Occasional high, crystalline partials that appear and dissolve. No perceptible rhythm. Designed for headphone listening — recommend headphones in UI.
**Technical approach:** Reaction-diffusion simulation on a 2D grid (compute shader), rendered as emissive color field. Simulation runs at a fixed grid resolution (default 512×512), decoupled from display resolution — the natural smoothing from upscaling via bilinear interpolation in the fragment shader produces the soft, luminous quality the mode wants. Audio: 3-5 detuned oscillators with just-intonation relationships, convolution reverb with 8-12 second tail.
**Parameter emphasis:** Very low energy, high density, high warmth, minimal turbulence.
**Evolution timescale:** Primary cycle ~45 minutes. Per-parameter cycles staggered across 35-55 minute range, no shared periods. Target session ~20-30 minutes — the cycle is deliberately longer than a session so the user never experiences the full arc.

**Design notes:**
- Reaction-diffusion is the Phase 0 validation vehicle for the architecture, not the definitive Semuta visual language. RD naturally produces "bioluminescent field" but not "fluid creature ambiguity" (Squid Lake reference). Later modes will need advection-distorted fields, particle trails, or volumetric impostors.
- Alternative visual approach in reserve: layered smooth noise fields advected over time could achieve the "oil-in-water" quality with simpler shader code and easier art-direction than Gray-Scott. Keep as Plan B if Gray-Scott proves too finicky.
- If audio technically passes but aesthetically underwhelms, first enhancement targets: noise bed, stereo decorrelation, gentle saturation/waveshaping, algorithmic reverb.

### 4.2 Lucid Drift (working name)

**Purpose:** Open-ended contemplation, creative ideation, flow state support.
**Visual character:** More active than Deep Still. Filamentary structures that grow, branch, and dissolve. Interference patterns where fields overlap. Moderate color range with shifting hue cycles. The "Squid Lake" reference is strongest here — translucent forms moving with apparent intention through a fluid medium.
**Audio character:** Richer harmonic palette. Slow arpeggiation of microtonal intervals (not rhythmic — think wind chimes in unpredictable breeze). Granular texture layers. Medium reverb.
**Technical approach:** Particle-based fluid simulation (SPH or simplified Navier-Stokes via compute shader) with emissive trail rendering. Audio: granular synthesis engine with pitch material drawn from mode-defined scale, randomized grain timing.
**Parameter emphasis:** Medium energy, medium density, moderate warmth, moderate turbulence.

### 4.3 Focus Sustain (working name)

**Purpose:** Sustained concentration support. Gentle enough to remain peripheral, structured enough to prevent mind-wandering.
**Visual character:** Geometric but soft. Slow mandala-like patterns that form and dissolve at the edges of symmetry — never quite achieving perfect regularity. Subtle. Muted palette: warm grays, desaturated golds, quiet whites.
**Audio character:** Steady-state drone with very slow spectral evolution. Almost static. The audio equivalent of a warm room — present but not demanding attention. Binaural beating in the alpha/low-beta range (8-15 Hz difference tones) as an optional layer.
**Technical approach:** Layered Perlin/simplex noise fields with rotational symmetry constraints (compute shader). Rendering as subtle luminance variations on a neutral field. Audio: 2-3 oscillators with extremely slow frequency modulation, optional binaural layer using two `OscillatorNode` instances with precise frequency offset.
**Parameter emphasis:** Low-medium energy, low density, neutral warmth, minimal turbulence. Stability is the defining quality.

### 4.4 Freeform (working name)

**Purpose:** Exploration, experimentation, pure aesthetic enjoyment. No prescribed cognitive target.
**Visual character:** User-influenced. Draws from the visual vocabularies of all other modes. Higher responsiveness to input. More vivid color. The "playground" mode.
**Audio character:** Similarly eclectic. More responsive to MIDI input — this is the mode where playing with a controller is most rewarding. Harmonic material shifts based on input.
**Technical approach:** Composite — selects and blends techniques from other modes based on parameter state. This mode is architecturally the most complex because it must be flexible rather than optimized for a single simulation type.
**Parameter emphasis:** Full range. Parameters are more volatile and more responsive to input than in purpose-driven modes.

---

## 5. Development Roadmap

### Phase 0 — Foundation (Engine + One Mode)

**Goal:** Prove the architecture. One working mode (Deep Still) running in a browser with coupled audio and visuals driven by a shared parameter bus.

**Deliverables:**
- WebGPU initialization and compute/render pipeline framework
- Web Audio synthesis framework
- Parameter bus implementation with autonomous evolution
- Mode interface definition (SEM-005a) with optional lifecycle hooks
- Deep Still mode: visual simulation (SEM-005b) + audio synthesis (SEM-006) + parameter mapping (SEM-007)
- Basic UI shell (start experience transition, fullscreen toggle)
- Live URL on Vercel

Input layer (MIDI, simulated or real) is deferred to Phase 1 per engineering spec.

**Success criteria:** A person can open a URL, see luminous forms drifting through darkness, hear entangled ambient sound, and lose track of time for at least a few minutes. Danny confirms meditative quality for at least 3 minutes of sustained use.

### Phase 1 — Mode Expansion + Input

**Goal:** Validate the mode abstraction by building a second mode that is aesthetically distinct from the first. Add real MIDI input.

**Deliverables:**
- Lucid Drift mode (distinct simulation type, distinct audio character)
- Web MIDI integration (real hardware input)
- Input mapping system (MIDI events → parameter perturbations)
- Mode switching (smooth crossfade between modes)
- Refined UI
- Full device loss recovery (re-create pipelines, re-sync state)

### Phase 2 — Full Mode Set + Polish

**Goal:** Complete the initial mode set. Polish the experience.

**Deliverables:**
- Focus Sustain mode
- Freeform mode
- PWA support (installable, offline-capable)
- Performance optimization (frame budget, memory management)
- Responsive design (desktop, tablet, mobile)

### Phase 3 — Immersive

**Goal:** VR experience on Meta Quest.

**Deliverables:**
- WebXR integration
- Stereoscopic rendering pipeline
- Spatial audio positioning
- VR-specific mode configurations (environment geometry, comfort settings)
- Performance optimization for Quest hardware budget

### Future Possibilities (Not Committed)

- Additional input channels (microphone, biometric, ambient light)
- Community mode SDK / mode editor
- Social presence (shared VR meditation spaces)
- Native app wrappers for app store distribution
- AI-driven parameter evolution (LLM or smaller model guiding generative state)

---

## 6. Constraints and Decisions

### 6.1 Accepted Constraints

- **Safari has no Web MIDI support.** Safari users get the passive experience only. This is acceptable because the passive experience is the primary experience.
- **WebGPU browser support varies.** Chrome/Edge: full support (primary target). Safari: partial (secondary, macOS Tahoe+). Firefox: disabled by default (not a Phase 0 target). Users on unsupported browsers get a graceful error message. No WebGL fallback at v1.
- **VR performance budget is tight.** Quest browser + WebGPU + stereoscopic rendering means the simulation resolution and complexity may need to be reduced for VR. Mode VR configs handle this by specifying VR-appropriate parameters.
- **Audio quality ceiling.** Web Audio API synthesis will not match dedicated audio software or hardware synthesizers. This is acceptable — Semuta's audio needs to be *good enough* to produce the meditative effect, not audiophile-grade.
- **Headphone-optimized.** The 55Hz root fundamental won't reproduce on small speakers. The experience is designed for headphone or full-range speaker listening. Note this in UI.

### 6.2 Open Questions

- **Persistence:** Should Semuta remember user preferences across sessions? (Mode preferences, MIDI device mappings, parameter tuning.) If so, where? (localStorage, account system, URL parameters.)
- **Sharing:** Can a user share a "moment" — a snapshot of the generative state that another person can open and see/hear the same thing? This is technically feasible (serialize parameter state + timestamp seed) but adds UX complexity.
- **Accessibility:** Specific concerns for this experience: luminance intensity (seizure safety, dark-adapted eye comfort), motion sensitivity (rate of visual change), volume-safe defaults (prevent accidental loud start), graceful entry/exit from fullscreen (escape routes for disorientation). The generic question of "captions/high contrast" is less relevant than these experience-specific safety considerations.
- **Monetization:** If this is eventually public, what's the model? Free with limited modes, paid for full set? Donation-based? Subscription? Not a v1 concern but worth keeping in mind architecturally (e.g., mode loading should support gating).
- **Name:** "Semuta" is evocative and the Herbert reference is intentional, but it does reference a fictional narcotic. Is that the right signal for a meditation/wellness product? Worth discussing.

---

## 7. What Semuta Is Not

- **Not a music player or visualizer.** It does not consume external audio. It generates both audio and visual internally.
- **Not an instrument.** MIDI input is an influence channel, not a performance interface. The goal is not to "play" Semuta but to "be in" it.
- **Not a game.** There are no goals, scores, levels, or progression mechanics.
- **Not a screensaver.** It is designed for active (if passive) human presence. The experience is calibrated for a person who is paying soft attention, not for an empty room.
- **Not a clinical tool.** While it may produce relaxation, focus, or other cognitive effects, Semuta makes no medical or therapeutic claims. It is an aesthetic experience.

---

## 8. Design Notes (from peer review synthesis, 2026-03-18)

### DN-1: Latent parameter layer (Phase 1 escape hatch)
Four flat named parameters mapped linearly to audio and visual may produce coarse correlation ("brighter = louder") rather than emergent entanglement. A latent state vector with coupled dynamics, from which named parameters are derived as projections, would produce richer coupling. Too much architecture for Phase 0, but should be the first intervention if A3 validation reveals the coupling feels thin.

### DN-2: Simulation resolution independence
Simulation grid runs at a fixed resolution (512×512 default), independent from display resolution. Render pass upscales to canvas via the fragment shader's bilinear interpolation. DPR (device pixel ratio) for the presentation canvas capped at 1x by default (configurable). This is both a performance win and an aesthetic win — the natural smoothing from upscaling produces the soft, luminous quality Deep Still wants. This is a first-class design decision, not a fallback.

---

*This document is the constitutional reference for the Semuta project. Implementation details, mode specifications, and API designs are separate documents that must remain consistent with the principles and architecture defined here. When execution details conflict, the engineering specification (`specification.md`) governs for Phase 0.*
