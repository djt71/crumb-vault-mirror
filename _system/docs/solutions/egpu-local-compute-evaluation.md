---
type: solution
domain: software
status: active
created: 2026-04-01
updated: 2026-04-01
skill_origin: research
confidence: medium
track: pattern
linkage: discovery-only
tags:
  - kb/software-dev
  - hardware
  - local-inference
  - fine-tuning
  - tess-v2
topics:
  - moc-crumb-architecture
---

# eGPU for Local Compute: TinyGPU Evaluation

Research note evaluating TinyGPU (by TinyCorp/tinygrad) as a path to AMD/NVIDIA
eGPU compute on the Mac Studio M3 Ultra. Triggered by TinyCorp announcement
(2026-04-01) that Apple approved their macOS driver extension for USB4/Thunderbolt
eGPUs.

## What TinyGPU Is

TinyCorp's TinyGPU is a macOS driver extension (DEXT) that enables AMD (RDNA 2/3/4)
and NVIDIA (Ampere/Ada/Blackwell) GPUs connected via USB4 or Thunderbolt to be used
as compute devices on Apple Silicon Macs. The driver is compute-only — no display
output, no general macOS GPU acceleration. It routes AI/ML workloads through
tinygrad's runtime.

**Timeline:**
- May 2025: First AMD eGPU on Apple Silicon via USB3 (libusb, hacky)
- Oct 2025: NVIDIA RTX support via USB4/Thunderbolt (required SIP disable)
- Apr 2026: Apple-approved DEXT path (no SIP disable required for install)

## Two Install Paths (Conflicting)

1. **DEXT path** (docs.tinygrad.org/tinygpu/): `curl | sh` installs TinyGPU.app,
   macOS prompts to approve driver extension in System Settings. No SIP disable.
   Requires macOS 12.1+.

2. **SIP-disabled path** (geohot's stated preference): Disable SIP, install driver
   from source. geohot's rationale: the Apple entitlement path forces signed
   distribution (users can't modify), and requires a shim process for Python to
   talk to the GPU. He considers both unacceptable for open source.

The DEXT path is what's relevant for production use. The SIP path is for
contributors/hackers.

## Hardware Requirements

- USB4 or Thunderbolt 4 port (Mac Studio M3 Ultra: confirmed, has Thunderbolt 4)
- ADT-UT3G dock (~$50-80) or similar USB4/TB eGPU enclosure
- Supported GPU: RTX 30/40/50 series (NVIDIA) or RDNA 2/3/4 (AMD)
- Note: RTX 50 series (Blackwell) has open initialization issues as of Jan 2026

## Relevance to Crumb/Tess Stack

### Current local compute profile
- Nemotron Cascade 2 30B-A3B Q4_K_M via llama.cpp on Metal
- ~31.4 GB memory under load on 96 GB unified memory
- AD-012: Nemotron GO as local executor (2026-03-31)
- Kimi K2.5 orchestrates via OpenRouter (cloud)

### What eGPU could add

| Capability | Current (Metal) | With eGPU | Delta |
|---|---|---|---|
| Nemotron inference | ~6.4s p50 | Unchanged (stays on Metal) | None |
| Larger model support | Limited by 96GB shared budget | Dedicated VRAM (24GB on 4090) | Enables running a second large model |
| Fine-tuning | Not practical on Metal | CUDA-class fine-tuning on RTX | Major unlock for vault-as-training-data |
| Parallel inference | Single model at a time | Two models on separate compute | Enables local two-model routing |

### Key constraint: tinygrad lock-in

The eGPU is currently accessible **only through tinygrad's runtime**. It does not
appear as a standard CUDA or ROCm device to other software. This means:

- llama.cpp cannot use it directly (llama.cpp uses Metal, CUDA, or Vulkan backends)
- You'd need to use tinygrad's own inference path (`tinygrad/apps/llm.py`)
- Or wait for broader driver support that exposes the GPU as a standard compute device

This is the primary blocker. The eGPU is useful only if your inference/training
stack can address it. As of 2026-04-01, that means tinygrad or nothing.

**Exception:** If tinygrad's ONNX support (added in v0.11.0) is mature enough,
you could potentially export models to ONNX and run them through tinygrad on the
eGPU. Untested for production inference workloads.

## Cost Estimate

| Item | Cost |
|---|---|
| ADT-UT3G dock | ~$60 |
| RTX 4090 (used) | ~$700-900 |
| RTX 3090 (used) | ~$400-500 |
| Total (budget) | ~$460-560 |
| Total (performance) | ~$760-960 |

## Known Issues

1. **RTX 5060 Ti initialization failures** — open GitHub issues (#14334, #14338)
   with Blackwell GPUs failing GSP init over Thunderbolt. Ampere and Ada are stable.
2. **Bandwidth ceiling** — USB4/TB4 at ~40 Gbps. Model loading is slow. Inference
   is fine if the model fits entirely in GPU VRAM (no host-GPU streaming).
3. **DEXT vs SIP story unresolved** — geohot publicly opposes the Apple-approved
   path. The docs describe it. Unclear which path gets maintained long-term.
4. **Tinygrad is not 1.0** — still pre-release. API stability improving but not
   guaranteed.

## Decision: WATCH (30 days)

**Not acting now.** Reasons:

1. Tess v2 critical path is Phase 1-2 evaluation (Kimi soak through Apr 6). Adding
   a third compute tier is scope creep.
2. Liberation Directive immediate priority is Firekeeper Books Title #1 — hardware
   investment doesn't advance the 30-day target.
3. The tinygrad lock-in question needs resolution. If llama.cpp or vLLM can't
   address the eGPU, it's an isolated compute island.
4. DEXT vs SIP install path needs to settle before committing to production use
   on the Studio.

**Revisit trigger:** When fine-tuning a local model on vault data becomes the
critical path (likely Phase 4 of tess-v2, or a dedicated fine-tuning project).
At that point, an RTX 4090 eGPU at ~$800 total would be a compelling investment.

**Also revisit if:** llama.cpp or Ollama add tinygrad/TinyGPU backend support,
which would eliminate the lock-in concern entirely.

## Also Evaluated: Icarus Memory Protocol (2026-04-01)

Separate X post claimed "Icarus now works inside Obsidian" with Hermes agent
memory as editable vault notes and vault-as-training-data. Investigation found:

- **Repo:** `esaradev/icarus-daedalus` (7 stars, 6 commits, 1 human contributor)
- **No Obsidian plugin exists.** Fabric entries are markdown files in `~/fabric/`,
  not integrated with Obsidian's plugin API.
- **README describes features beyond what the code implements.** File tree shows
  the original agent-to-agent dialogue prototype, not the fabric/plugin system.
- **Fine-tuning pipeline** operates on narrow fabric entry format, not on
  general vault content. Would not handle design specs, run logs, or knowledge notes.
- **Graph view claim false.** Fabric refs use YAML frontmatter arrays, not
  wikilinks. Obsidian graph view wouldn't render connections.

**Verdict: No action.** Crumb's existing architecture (AKM + QMD, A2A protocol,
contract-based execution, structured run logs) is more rigorous on every axis.
The Ceremony Budget Principle applies — this would add dependency for capabilities
already present or insufficiently developed.

**Track if:** Nous Research integrates structured memory natively into Hermes
core (not as a community plugin). That would change the calculus for the
Hermes platform evaluation already underway in tess-v2.
