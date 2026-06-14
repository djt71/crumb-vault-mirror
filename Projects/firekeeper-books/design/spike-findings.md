---
project: firekeeper-books
domain: creative
type: design
skill_origin: null
created: 2026-06-13
updated: 2026-06-13
---

# M-1B Local Pipeline Spike — Findings

Running log of the local-AI illustration spike (spec §10). Accumulates per session; the **go/iterate/stop gate decision** is written at the bottom after session 3 (or earlier if a verdict is clear). Benchmark for every session: the Coulthart and Wrightson illustrated Frankenstein editions — not other AI output.

**Setup:** Draw Things on Mac Studio (M3 Ultra, 96GB). Models pulled: SDXL Base v1.0, Juggernaut XL Ragnarok (full precision), Z-Image Turbo, Qwen Image 2512. Prompts: [[03d-local-pipeline-prompts]]. Scene 1 = the Workshop (frontispiece).

---

## Session 1 — 2026-06-12

**Run:** Scene 1 (Workshop) on **Z-Image Turbo only**, 896×1152, low CFG, monochrome-direct prompt. 4 candidates surfaced for review (`~/Pictures/firekeeper-mb1/session-1/`). Juggernaut + Qwen deferred to session 2.

**Headline finding — Z-Image Turbo is a contender, not just the fast calibration lane.** The distilled turbo model produced near-plate-quality wood-engraving texture from positive prompt language alone — no negative prompt, minimal guidance. This was unexpected: the spike plan cast Z-Image as the high-volume panel engine and SDXL/Juggernaut as the quality lane. Session 1 inverts that assumption pending the other two models' runs.

**Per-candidate verdict (all Z-Image):**
- **Candidate 3 — session keeper.** Bent low, hands engaged, stone room receding to dark, dense hatching, candle as true single source. Only one where "airless and obsessive" lands. *(seed: TBD — capture in session 2 record)*
- **Candidate 1 — texture benchmark, wrong scene.** Finest line-engraving of the four, genuine 19th-c plate quality in places. But reads as a man writing a letter; candle has a decorative glow-halo; cluttered background violates "absolute darkness behind him." Retain for the style-LoRA seed pool. *(seed: TBD)*
- **Candidate 4 — right mood, crushed blacks.** Darkest/grittiest, face properly lost in shadow, but tonal zones merge — fails the 03c "3 separated zones" greyscale check; would go muddy on e-ink. Coarser woodcut texture noted as a variant direction.
- **Candidate 2 — cull.** Ink-wash smoothness not carved line; ambient theatrical lighting; most "helpfully lit" face. Competent, wrong book.

**Systematic finding (the real session-1 result):** all four outputs missed the *same* two composition instructions — none gave "seen from slightly above and behind," and every one lit the face more than the brief allows. At Z-Image's CFG 1–2 this is expected (the model barely steers). **Conclusion: the printmaking style is solved; composition obedience is now the open test.** That is the right kind of remaining problem — art direction, not image quality. Texture is already past every sub-$1 competitor and within sight of real plate work.

**Action carried into session 2:**
1. Revised "face-hidden" prompt drafted (front-loads viewpoint, makes hidden face a hard constraint, forbids glow-halo and background clutter). SDXL/Juggernaut lane adds negatives: `face visible, portrait, frontal view, bright ambient light, cluttered shelves, glowing halo`.
2. **Run the revised prompt on all three models including a Z-Image rerun** — apples-to-apples panel, same brief.
3. 16 images/model, equal sample. Record hit rate (keepers/16) per model — that's gate evidence.
4. Capture seeds + settings for every keeper (missing from session 1 — fix).
5. Per-model subfolders, seeds in filenames.

**Open question for session 2:** does Juggernaut's engraving texture survive its photoreal training bias (negative prompt fighting it), and does Qwen's staging-adherence reputation deliver the behind-view/hidden-face composition the others missed? Possible production shape emerging: **Qwen for composition + Z-Image for texture volume.**

---

## Session 2 — (pending)

## Session 3 — (pending)

---

## Gate Decision — (pending session 3)

*Go = ≥3 images across ≥2 scenes that feel like one book AND Danny would put his name on at $7.99 → proceed to M0. Iterate = clear trajectory, ≤2 more sessions then final go/stop. Stop = bar not reachable at acceptable effort → strategic rethink (human-illustrator pivot or archive with editorial banked).*
