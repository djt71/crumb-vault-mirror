---
type: design
status: active
domain: software
project: semuta
created: 2026-03-15
updated: 2026-03-15
---

# Semuta — Design Specification v0.1

**Status:** Draft  
**Created:** 2026-03-15  
**Author:** Danny (architecture/product), Claude (technical design)

---

## 1. What Semuta Is

Semuta is a generative audiovisual meditation platform. It produces coupled sound and light — ambient soundscapes entangled with GPU-driven visual environments — designed to dissolve the user's sense of time and reward sustained, passive attention.

The name references the fictional drug-music pairing from Frank Herbert's *Dune Messiah*, where atonal vibrations produce a state of timeless ecstasy. Semuta pursues that same quality through technology rather than pharmacology: sound and image that operate below conscious musical and visual grammar, creating an experience that is felt rather than watched or listened to.

Semuta is not a visualizer. It does not react to external audio. It is not an instrument. It is a self-composing environment that accepts gentle influence from optional inputs.

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

**Input Layer** — Normalizes external signals into a common format. A MIDI note-on, a microphone amplitude spike, and a time-of-day transition all become the same thing: a parameter influence event with a source, a target, and a magnitude. Inputs are optional. The system generates a complete experience with zero external input.

**Parameter Bus** — The shared nervous system. A set of named, continuously-evolving parameters (e.g., `energy`, `density`, `warmth`, `turbulence`) that drive both audio and visual engines simultaneously. Parameters evolve autonomously via mode-defined rules and are perturbed by input events. This is where entanglement lives — audio and visual are coupled because they read from the same state, not because one drives the other.

**Visual Engine** — WebGPU-based. Manages compute pipelines (simulation), render pipelines (presentation), and the GPU resource lifecycle. Modes provide shader code and configuration; the engine provides the execution environment.

**Audio Engine** — Web Audio API-based. Manages oscillator banks, audio graph routing, effects (reverb, delay, filtering), and output. Modes provide synthesis configurations and parameter-to-audio mappings; the engine provides the runtime.

**Modes** — Self-contained generative definitions. Each mode specifies:
- A visual program (shaders, simulation rules, rendering approach)
- An audio program (synthesis graph, tonal material, temporal behavior)
- A parameter mapping (how the shared parameter bus drives both programs)
- Input mappings (how external inputs influence parameters, if at all)
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
  input_mappings  → how input events perturb parameters (optional)
  vr_config       → VR-specific overrides (camera placement, stereoscopic rendering, spatial audio) (optional)
```

This separation means:
- New modes can be added without touching engine code.
- The same mode runs on flat screen and VR with minimal adaptation.
- Modes can be developed and tested independently.
- Community-contributed modes become possible in the future.

---

## 3. Technology Stack

### 3.1 Rendering — WebGPU

**Why WebGPU over WebGL:** Compute shaders. The visual simulations Semuta requires (reaction-diffusion, fluid dynamics, particle systems with complex interactions) need GPU-side computation, not just vertex/fragment rendering. WebGL cannot do this. WebGPU's compute pipeline allows the simulation to run entirely on the GPU, with the render pipeline consuming the simulation output directly — no CPU round-trip per frame.

**Browser support:** Chrome/Edge (stable since 2023), Firefox (stable since mid-2025), Safari (stable since Safari 26). ~70% global coverage. Sufficient for a v1 targeting modern browsers.

**Shader language:** WGSL (WebGPU Shading Language). Text-based, statically validated, portable across backends (Vulkan, Metal, D3D12).

**Key patterns:**
- Double-buffer (ping-pong) for simulation state
- Compute pass → render pass pipeline per frame
- Storage textures for simulation grids
- Instanced rendering for particle-like elements
- Workgroup size of 64 as default (GPU-optimal for most hardware)

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

### 3.3 Input — Web MIDI API + Others

**Web MIDI:** Supported in Chrome/Edge/Firefox. Not supported in Safari (Apple declined due to fingerprinting concerns). Acceptable limitation — Safari users get the passive experience; Chrome/Firefox users can optionally connect MIDI controllers.

**MIDI's role in Semuta:** An influence channel, not a performance interface. A MIDI note-on event does not trigger a discrete sound or visual. It perturbs the parameter bus — increasing energy, shifting warmth, introducing a new harmonic partial — and the system integrates that perturbation over time. The result should feel like dropping dye into water, not pressing a button.

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
**Audio character:** Sub-bass drones with slow harmonic evolution. Long reverb tails. Occasional high, crystalline partials that appear and dissolve. No perceptible rhythm.  
**Technical approach:** Reaction-diffusion simulation on a 2D grid (compute shader), rendered as emissive color field. Audio: 3-5 detuned oscillators with just-intonation relationships, convolution reverb with 8-12 second tail.  
**Parameter emphasis:** Very low energy, high density, high warmth, minimal turbulence.

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
- Parameter bus implementation
- Deep Still mode: visual simulation + audio synthesis + parameter mapping
- Simulated MIDI input (on-screen controls or auto-generated events)
- Basic UI shell (mode selection placeholder, fullscreen toggle)

**Success criteria:** A person can open a URL, see luminous forms drifting through darkness, hear entangled ambient sound, and lose track of time for at least a few minutes.

### Phase 1 — Mode Expansion + Input

**Goal:** Validate the mode abstraction by building a second mode that is aesthetically distinct from the first. Add real MIDI input.

**Deliverables:**
- Lucid Drift mode (distinct simulation type, distinct audio character)
- Web MIDI integration (real hardware input)
- Input mapping system (MIDI events → parameter perturbations)
- Mode switching (smooth crossfade between modes)
- Refined UI

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
- **WebGPU coverage is ~70%.** Users on older browsers or unsupported platforms get nothing. A WebGL fallback could be built but adds significant complexity for diminishing returns. Decision: no fallback at v1. Graceful error message directing users to a supported browser.
- **VR performance budget is tight.** Quest browser + WebGPU + stereoscopic rendering means the simulation resolution and complexity may need to be reduced for VR. Mode VR configs handle this by specifying VR-appropriate parameters.
- **Audio quality ceiling.** Web Audio API synthesis will not match dedicated audio software or hardware synthesizers. This is acceptable — Semuta's audio needs to be *good enough* to produce the meditative effect, not audiophile-grade.

### 6.2 Open Questions

- **Persistence:** Should Semuta remember user preferences across sessions? (Mode preferences, MIDI device mappings, parameter tuning.) If so, where? (localStorage, account system, URL parameters.)
- **Sharing:** Can a user share a "moment" — a snapshot of the generative state that another person can open and see/hear the same thing? This is technically feasible (serialize parameter state + timestamp seed) but adds UX complexity.
- **Accessibility:** What does accessibility mean for a primarily visual+audio meditation experience? Captions for audio? High-contrast mode for visuals? This needs thought.
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

*This document is the constitutional reference for the Semuta project. Implementation details, mode specifications, and API designs are separate documents that must remain consistent with the principles and architecture defined here.*
