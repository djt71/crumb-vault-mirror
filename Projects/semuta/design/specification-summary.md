---
type: specification-summary
status: draft
domain: software
project: semuta
created: 2026-03-17
updated: 2026-03-18
source_updated: 2026-03-18
---

# Semuta — Specification Summary

## What
Generative audiovisual meditation platform. Browser-native (WebGPU + Web Audio). Coupled sound and light driven by a shared parameter bus — not a visualizer, not an instrument, a self-composing environment.

## Why
No browser-native tool produces entangled generative audio and visuals for meditative attention. The browser is the right surface: zero-install, shareable via URL, GPU compute capable.

## How (Phase 0)
- **Visual:** Reaction-diffusion at 512×512 fixed grid (decoupled from display) via WebGPU compute shaders → emissive color field upscaled via bilinear interpolation. Format fallback: rgba16float → rgba32float → error. Staged: toy sim validates pipeline, then Gray-Scott.
- **Audio:** Drone synthesis via Web Audio oscillator bank + convolution reverb (just intonation, long decay). `setTargetAtTime` with ~0.2s time constant, throttled to ~10-15Hz. `isReady` = dry path (convolver fades in later). Headphone-optimized (55Hz root). Visibility-aware suspend/resume + simulation pause.
- **Coupling:** Parameter bus (energy, density, warmth, turbulence) drives both engines. Per-param cycles 35-55 min, no shared periods. Frame loop: evolve → push → compute → render. Validated via structured sweeps, negative test, screen recordings, scene recorder replay + Danny as final arbiter.
- **Stack:** Vite + TypeScript + vanilla browser APIs. No framework. Deployed to Vercel.
- **Scope:** One mode (Deep Still) end-to-end. Live URL. Input layer deferred to Phase 1.
- **Browser targets:** Chrome (must-have), Safari Tahoe+ (should-have), Firefox (not Phase 0).

## Key Risks
- WGSL shader debugging is opaque — mitigated by staged approach: toy sim → Gray-Scott (R1)
- Performance: simulation decoupled from display at 512×512 default (R2)
- Parameter coupling must feel entangled — structured evaluation with negative test (R4)
- Scope creep — 6-week timebox check-in (R7)

## Tasks (Phase 0)
8 tasks: SEM-001 through SEM-008. Critical path: SEM-001 → SEM-002 → SEM-005 → SEM-007 → SEM-008. Integration task SEM-007 is highest risk (where entanglement succeeds or fails).

## Reviews
- **Spec peer review (2026-03-17):** 4 reviewers, 11 action items. See `reviews/2026-03-17-specification.md`.
- **External synthesis (2026-03-18):** 5 reviewers across all docs. 5 MF + 14 SF applied. Design spec bumped to v0.2. Key changes: resolution independence (512×512), format fallback chain, start gating decoupled from IR, staged visual approach, Mode lifecycle hooks, browser matrix corrected, entanglement evaluation strengthened.

## Builder Model
Claude implements, Danny directs. Danny does not write WGSL or compute shaders. Quality over speed — passion project.

## Full Spec
See `specification.md` in this directory. Design reference: `semuta-design-spec-v0.2.md`.
