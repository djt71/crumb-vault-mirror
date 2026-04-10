---
type: plan
project: firekeeper-books
domain: creative
skill_origin: learning-plan
status: active
created: 2026-04-02
updated: 2026-04-02
skill_type: composite
skill_type_secondary:
  - applied-technical
target_level: "Produce original, stylistically consistent book illustrations and page designs using AI tools that transcend generic AI aesthetic — publishable at premium quality across ebook and print-on-demand formats"
weekly_hours: 15-20 (integrated with production)
tags:
  - learning-plan
  - ai-art
  - midjourney
  - kb/writing
---

# AI Art & Book Design — Learning Plan

## Goal

Develop the skills to produce original, stylistically distinctive AI-generated illustrations and page designs for Firekeeper Books — starting with Frankenstein (16-20 illustrations) and The Odyssey (28-32 illustrations). The quality bar: even people who know it's AI-generated respect the craft and originality. The anti-target: the glossy, soulless, "obviously Midjourney" default aesthetic that the public rightly dislikes.

This is learning by doing. Every practice session produces candidate material for the books. The plan is production-integrated, not academic.

## Skill Classification

**Composite** — Creative dominant + Applied-technical secondary.

- **Creative (dominant):** Aesthetic judgment, art direction, developing a personal visual voice, compositional thinking, color and mood. This is the moat. Danny has the eye and imagination — the plan builds the vocabulary and workflow to externalize that vision.
- **Applied-technical (secondary):** Midjourney prompt engineering, Pixelmator Pro post-processing, ebook layout and typography. These are the instruments. Fluency here removes friction between vision and output.

**Practice shape:** Study exemplars → imitate with intention → vary and diverge → develop signature style. Interleaved with direct-then-drill cycles: produce real illustrations, identify the bottleneck (prompt? composition? post-processing? style consistency?), drill that component, reintegrate.

## Current Assessment

- **Midjourney:** Beginner. Some experimentation, no systematic prompt knowledge.
- **Visual art:** Strong aesthetic eye and imagination. Cannot draw or paint manually — AI tools are the production medium, not a supplement to traditional skills.
- **Page design/typography:** Minimal. Some Adobe PageMaker experience (dated). New to modern ebook layout.
- **Post-processing:** New to Pixelmator Pro workflows for illustration refinement.
- **Strengths to leverage:** Taste, imagination, willingness to iterate, clear vision of what "good" looks like even without the tools to produce it yet.

---

## Phase 1: Tool Fluency & Anti-Pattern Recognition (Apr 2–8)

*Aligns with M-1 tool spike.*

**Phase goal:** Understand what makes AI art look bad, learn Midjourney's core parameters, and produce 10-15 experimental illustrations across both title worlds that demonstrate style direction.

### Core Activities

**1. Learn what to avoid (Day 1-2)**
Study AI art that triggers the "ugh, AI" reaction. Identify the specific anti-patterns:
- The "Midjourney glow" — oversaturated lighting, plastic skin, HDR-everything
- Overcrowded compositions with no negative space
- Anatomical uncanny valley (hands, eyes, teeth, fingers)
- Generic "fantasy art" defaults (every woman looks the same, every castle is the same castle)
- Lack of artistic intentionality — images that look like they happened to the prompt, not on purpose
- Perfect symmetry and unnatural cleanliness
- Text-like artifacts and nonsense symbols

Build a mental catalog. For each anti-pattern, note what the *opposite* looks like in real illustration.

**2. Study benchmark illustrated editions (Day 1-3)**
With the competitive ebooks (Coulthart Frankenstein, illustrated Odyssey, gothic/fiction editions):
- Analyze 3-5 illustrations per book: composition, palette, mood, level of detail, relationship to text
- Note what makes them feel *authored* — consistent style, deliberate choices, restraint
- Identify the gap between these and generic AI output
- Save notes and reference images in `Projects/firekeeper-books/design/references/`

**3. Midjourney fundamentals (Day 2-5)**
Learn through structured experimentation, not reading docs cover-to-cover:

| Parameter | What it controls | Practice exercise |
|-----------|-----------------|-------------------|
| `--ar` | Aspect ratio | Generate same scene at 2:3, 3:4, 16:9 — observe how composition shifts |
| `--s` (stylize) | How much MJ applies its own aesthetic | Same prompt at `--s 0`, `--s 250`, `--s 750` — find where *your* taste lives |
| `--c` (chaos) | Variation in results | Same prompt at `--c 0`, `--c 50`, `--c 100` — understand the exploration dial |
| `--no` | Negative prompts | Use to suppress specific anti-patterns (e.g., `--no photorealistic, HDR, lens flare`) |
| `--sref` | Style reference (image URL) | Feed it reference illustrations you admire — this is a key originality lever |
| `--cref` | Character reference | For character consistency across illustrations |
| `--w` (weird) | Unconventional outputs | Low values for subtle divergence from defaults |
| `/describe` | Reverse-engineer prompts from images | Feed it illustrations you admire, study the language it generates |
| `--v 6.1` / `--v 7` | Model version | Test both — different strengths |
| Vary (Region) | Inpainting | Regenerate specific areas (fix hands, faces, backgrounds) |
| Pan/Zoom | Extend canvas | Expand compositions beyond initial frame |

**4. First Frankenstein experiments (Day 3-7)**
Pick 3 iconic scenes (the creation, the creature in moonlight, the Arctic frame). Generate 20-30 variations each. Resist the urge to settle — volume builds your mental representations of what's possible.

**5. First Odyssey experiments (Day 5-7)**
Pick 2-3 scenes (Cyclops, Sirens, Penelope weaving). Different genre, different palette. Test whether your emerging style vocabulary transfers across worlds.

### Feedback Loop
- **Self-assessment:** For each batch, separate outputs into three piles: "this works," "close but something's off," and "generic AI." Articulate *why* for each.
- **External:** Share 5-10 best outputs with 2-3 people whose taste you trust. Ask specifically: "Does this look like AI art to you? What's working? What feels off?"

### Plateau Markers
- If every output looks the same: you're stuck on a prompt formula. Change 3+ variables at once.
- If outputs are wild but nothing is usable: reduce chaos, add more specific compositional language to prompts.

### Resources (Phase 1)
- Midjourney documentation (in-app `/help` and docs.midjourney.com)
- `/describe` on 10-15 illustrations you admire from the benchmark books
- YouTube: search "Midjourney style reference workflow" — watch 2-3 tutorials, no more (diminishing returns fast)
- The competitive ebooks themselves as visual benchmarks

---

## Phase 2: Style Development & Art Direction (Apr 8–14)

*Aligns with M0 design prototype. Hard gate: output must be meaningfully better than existing editions.*

**Phase goal:** Establish a coherent Frankenstein visual language — palette, texture, composition style, level of abstraction — and produce 5-8 prototype illustrations that clear the M0 gate.

### Core Activities

**1. Art direction document (Day 1-2)**
Write a style guide for Frankenstein. Not just "gothic" — specific decisions:
- **Palette:** Which specific colors and ranges? (e.g., desaturated blues and ambers, not full-spectrum)
- **Texture:** What surface quality? (e.g., matte, painterly, visible brushstroke vs. etching vs. woodcut)
- **Composition:** Preferred framing? (e.g., off-center subjects, generous negative space, no "centered hero shot")
- **Mood vocabulary:** 5-10 descriptive words that define the emotional register
- **Reference artists:** 3-5 real artists/illustrators whose work resonates with your vision (Gustave Doré, Francisco Goya, Bernie Wrightson, Zdzisław Beksiński, Edward Gosse — or whoever speaks to you)
- **Anti-patterns specific to this title:** What Frankenstein illustrations usually get wrong

This document becomes your prompt compass. When outputs drift, return to it.

**2. Style reference library**
Curate 10-20 reference images (mix of real art and your best Phase 1 outputs) that define the target aesthetic. Use `--sref` with these consistently. This is how you build visual consistency across illustrations — the style reference is your "artistic DNA."

**3. Prompt architecture**
Move from ad-hoc prompts to structured prompt templates:
```
[scene description], [compositional direction], [mood/atmosphere],
[medium/technique reference], [lighting], --sref [your style refs]
--ar [ratio] --s [your sweet spot] --no [anti-patterns]
```
Build 2-3 template variants. Test each on the same scene to see which produces the most consistently *you* results.

**4. The "human touch" post-processing pipeline**
This is where Pixelmator Pro becomes essential. Start building the workflow:
- **Tonal adjustment:** Shift away from the "AI color profile" (typically too saturated, too even). Add contrast variation, mute some colors, let others breathe.
- **Texture overlay:** Add subtle paper texture, grain, or canvas effect. This single step does enormous work against the "digital perfection" problem.
- **Detail refinement:** Inpaint or paint over AI artifacts. Fix hands, eyes, architectural impossibilities.
- **Vignetting and atmosphere:** Subtle edge darkening, atmospheric haze — techniques traditional illustrators use that AI rarely generates naturally.
- **Cropping and reframing:** AI-generated compositions are often "too much." Aggressive cropping can transform a generic image into a purposeful one.

**5. Typography seed: study exemplar book interiors (parallel track)**
While developing illustration style, start training your eye for page design:
- Pull 5-8 premium illustrated ebooks and physical books. Study the *text pages*, not just the illustrations:
  - How does the typeface feel? Heavy, light, modern, classical?
  - How much whitespace surrounds the text block? How does it breathe?
  - Where do illustrations sit relative to the text they reference — before, after, facing page?
  - What happens at chapter openings? Drop caps? Decorative elements? Extra vertical space?
  - Is there a visual system for section breaks, epigraphs, or quoted text?
- Screenshot or photograph 10-15 text pages and chapter openers you admire. Save to `Projects/firekeeper-books/design/references/typography/`. These become your layout benchmarks the way illustration references became your style benchmarks.
- **Key insight to internalize early:** In an illustrated book, the text pages are not "the boring parts between illustrations." They're the rhythm section. Bad typography makes even great illustrations feel cheap. Good typography makes the whole book feel *made*.

**6. Produce M0 prototype set**
Generate and post-process 5-8 illustrations for the M0 gate. These should be near-publishable quality. Select scenes that test range: intimate (Victor's study), dramatic (creation scene), landscape (Alpine), and emotional (creature's solitude).

### Feedback Loop
- **M0 gate review:** Does this set clear the bar? Is it meaningfully better than existing Kindle Frankenstein editions? Would you buy this book based on these illustrations?
- **The "scroll test":** Put illustrations in a social media feed context. Do they stop the scroll? Or do they blend in with the AI art noise?
- **Style consistency check:** Lay all 5-8 next to each other. Do they look like they came from the same artist? Same palette? Same textural quality? Same compositional philosophy?

### Plateau Markers
- If outputs are technically clean but emotionally flat: your prompts are too descriptive, not evocative enough. Use emotional and atmospheric language, not just visual description.
- If style references are dominating too heavily: reduce `--sref` weight or blend multiple references.

### Resources (Phase 2)
- Pixelmator Pro documentation (focus on: color adjustment, layers, brushes, texture overlays)
- Study 2-3 post-processing workflows: search "digital painting over AI art" or "AI art post-processing photoshop" (Photoshop techniques translate to Pixelmator Pro)
- Color theory basics — a single resource like Josef Albers' *Interaction of Color* (concepts, not the full book) or a 20-minute YouTube primer
- Your own art direction document (created in this phase)

---

## Phase 3: Ebook Production & Illustration Completion (Apr 15–May 5)

*Aligns with M1 Frankenstein production. Learning is now fully embedded in real output.*

**Phase goal:** Complete all 16-20 Frankenstein illustrations at publish quality. Build the ebook edition with clean, professional formatting that works within EPUB's real constraints. Establish a production pipeline that repeats for Odyssey.

### Core Activities

**1. Production pipeline optimization**
You now have a working process. Make it efficient:
- **Batch generation:** Generate 4-6 scenes per session, 20-30 variations each. Resist premature selection — let options accumulate before choosing.
- **Selection discipline:** Develop a two-pass selection process. First pass: gut reaction, pull anything that catches your eye. Second pass (next day): evaluate against art direction document. Fresh eyes catch "AI drift" that in-the-moment excitement misses.
- **Post-processing template:** Build a Pixelmator Pro action/workflow for your standard adjustments (texture overlay, tonal curve, grain). Apply as baseline, then customize per illustration.
- **Time tracking:** Log actual hours per illustration (generation, selection, post-processing). This data tells you where the bottleneck is.

**2. Ebook typography — what you actually control**

Here's the reality of ebook formatting: the reader controls the font. Kindle offers Bookerly, Amazon Ember, Palatino, Baskerville, Georgia, and a few others — and the reader picks. Your CSS font-family declaration is a *suggestion* that most readers will never see. Apple Books respects embedded fonts better. Kobo is somewhere in between.

This doesn't mean typography doesn't matter in the ebook — it means you invest in the things that *do* render consistently and save the full craft for print (Phase 3b).

**What you control and should invest in:**

- **Relative sizing and spacing:** Font size ratios between headings and body, line spacing (leading), margins, indentation. These are set via CSS and generally respected across devices. Design these carefully — they establish hierarchy and rhythm even when the reader's chosen font overrides yours.

- **Chapter opener styling:** This is where ebook design can express itself. Drop caps render well across most devices and signal craft. Small caps for the first few words of a chapter. Letterspacing on chapter titles. These CSS treatments survive font overrides because they're *structural*, not font-dependent.

- **Image-based front matter (the workaround for full brand control):**
  Design the title page, series page, half-title, and "About Firekeeper Books" page as images — full typographic control, your exact layout, your brand elements, exported as high-res PNG. Many premium ebook editions do exactly this. These pages are the Firekeeper Books brand identity and should look identical on every device.
  - Design in Pixelmator Pro or Affinity Designer at 1600x2400px (standard ebook cover dimensions work for interior full-page images too)
  - Include: series logo/wordmark, book title in your chosen display typeface, author name, "illustrated edition" or similar
  - Copyright page can go either way — image for full control, or styled text for accessibility

- **Illustration placement:** You control where illustrations appear relative to text, whether they're full-width, and their aspect ratio. For reflowable EPUB:
  - Full-page illustrations work best as their own "page" — a full-width image between text sections
  - Half-page and inline images are less predictable across devices — keep to full-width for consistency
  - Place illustrations at natural text breaks (paragraph or scene boundaries), never mid-paragraph
  - Chapter opener pattern: illustration → chapter heading → body text. This flow renders consistently.

- **Section breaks and ornaments:** Centered ornaments (asterisms, fleurons, or a small custom graphic) between scenes. These render reliably and add craft.

- **Embedded fonts (best-effort):** Embed your chosen typefaces in the EPUB. Readers who haven't overridden fonts will see them — this includes most first-time openers and readers on Apple Books. Design and test against both your chosen font *and* Bookerly/Georgia (the most common Kindle defaults), so the book looks intentional either way.

**What to accept and not fight:**

- You can't guarantee your typeface. Design so it looks good in any quality serif.
- You can't precisely control line breaks or page breaks. Reflowable means the text reflows.
- You can't do designed spreads (left/right page pairings). That's a print-only feature.
- Text wrap around images is unreliable across devices. Don't attempt it.

**3. Ebook production tools**

| Tool | Strengths | Limitations | Cost |
|------|-----------|-------------|------|
| **Atticus** | Visual editor, chapter themes, custom font embedding, ebook AND print-ready PDF from same project. Fastest path to professional output. | Less granular control than hand-edited EPUB. Relatively new tool. | $147 one-time |
| **Vellum** | Purpose-built for ebook. Beautiful defaults. Clean EPUB and KDP export. Mac-native. | Limited customization — can't fine-tune spacing precisely. Reflowable only. | $250 one-time |
| **Sigil** | Direct EPUB editing — unlimited control via HTML/CSS. Free. | Steep learning curve. You're writing code, not designing visually. | Free |
| **Calibre** | EPUB validation, format conversion, device testing. Essential utility regardless of primary tool. | Not a design tool — conversion and QA only. | Free |

**Recommendation for ebook production:**
- **Atticus** as the primary layout tool — visual workflow, handles both ebook and print export, fast learning curve given timeline pressure. The $147 is trivial relative to the value, and dual-format export means your Frankenstein ebook and POD files come from one project.
- **Calibre** for EPUB validation after every export — test on multiple device simulators.
- **Sigil** as surgical fallback — if Atticus's EPUB has quirks on specific devices, open in Sigil for targeted CSS fixes.

**4. Deliberate practice: direct-then-drill**
As you produce real illustrations, you'll hit specific bottlenecks. Drill them:

| Bottleneck | Drill |
|-----------|-------|
| Faces look generic | Generate 50 faces with specific character descriptions. Study what prompt language controls facial individuality. |
| Composition is always centered | Study off-center compositions in real art. Add explicit compositional language: "figure in lower third," "viewed from above," "extreme close-up." |
| Consistency across illustrations | Generate the same character in 10 different scenes using `--cref`. Evaluate which variations maintain identity. |
| Post-processing takes too long | Build reusable Pixelmator Pro templates. Time yourself — if >30 min per illustration on post-processing, your generation step needs more precision. |
| Gothic atmosphere feels cliché | Study actual Gothic art beyond the obvious. Look at Caspar David Friedrich, Odilon Redon, Francisco Goya's Black Paintings — feed these to `/describe`, learn the vocabulary. |

**5. Complete Frankenstein ebook**
Ship all 16-20 illustrations + ebook layout. This is the capstone. Every illustration should pass: "Would I hang this on a wall?" If the answer is no, regenerate or rework. Test the complete EPUB on Kindle Previewer, Apple Books, and at least one Kobo/phone simulator.

### Feedback Loop
- **Per-illustration quality gate:** Each finished illustration gets a 60-second cold assessment the morning after completion. "Still good? Or was I just fatigued and settled?"
- **Beta reader/viewer:** Show the complete edition to 2-3 people before publish. Ask: "What's the weakest illustration?" (Not "do you like it" — that gets polite answers.)
- **Production metrics:** Track time-per-illustration across the run. The learning curve should show: early illustrations take 3-4x longer than later ones.
- **Device testing:** View the complete ebook on 3+ devices/apps. Check: illustration rendering at different screen sizes, chapter opener flow, front matter image quality, section break spacing.

### Plateau Markers
- If all illustrations look good individually but the set feels disjointed: your style reference drifted. Return to art direction doc, regenerate outliers.
- If you're spending more time on post-processing than generation: your prompts need work, not your Pixelmator skills. The generation step should get you 80% there.

### Resources (Phase 3)
- **Atticus** ($147) — start with their built-in tutorials. Focus on: chapter formatting, image insertion, font embedding, export settings for both EPUB and KDP
- **Kindle Previewer** (free from Amazon) — essential for testing how your ebook actually renders on Kindle devices
- **Calibre** (free) — install immediately. Use for EPUB validation and cross-format testing
- **Butterick's Practical Typography** (free online) — still the best crash course. For ebook purposes, focus on the "body text" and "line spacing" chapters — the page layout chapters are more relevant to print (Phase 3b)
- Your Phase 2 typography reference screenshots — compare your ebook's chapter openers and text flow against the exemplars

---

## Phase 3b: Print Edition — Typography & Page Design (parallel with Phase 3, production in Phase 4+)

*This is where the full typographic craft lives. The ebook is constrained by format; print-on-demand gives you total control. Everything you design here is exactly what the reader holds.*

**Phase goal:** Learn book typography and page design at a level that produces a print edition worth owning as a physical object. Develop a design system that works across the Firekeeper Books series.

**Why this matters strategically:** KDP Print pays 60% royalty on paperback — no public domain penalty. At $18.99 paperback, you're looking at ~$4-6 per sale after printing costs, significantly better than $2.80 on the ebook. The print edition is the margin product. And it's where typography, illustration, and physical design compound into something people gift, display, and photograph for bookstagram.

### Core Activities

**1. Typography foundations**

Core concepts to internalize through study, not memorization. These matter in print where you control every variable:

| Concept | What it means | Why it matters for illustrated books |
|---------|--------------|--------------------------------------|
| **Serif vs. sans-serif** | Serifs guide the eye along lines of text. Sans-serif is cleaner but can feel clinical in long-form reading. | Literary illustrated editions almost always use serif body text. Sans-serif may work for display/headers as contrast. |
| **Leading (line spacing)** | Vertical space between baselines. Too tight = claustrophobic. Too loose = disconnected. | Illustrated books need generous leading — the text should feel spacious, echoing the breathing room around illustrations. |
| **Tracking & kerning** | Tracking = uniform letter spacing across a block. Kerning = spacing between specific letter pairs. | Display type (chapter titles, cover) needs manual kerning attention. Body text tracking should be left at default. |
| **Measure (line length)** | Characters per line. 45-75 is the readability sweet spot. 66 is often cited as ideal. | Your trim size and margins lock this in. A 6x9" book with proper margins lands naturally in this range. |
| **Vertical rhythm** | Consistent spacing relationships: line height, paragraph spacing, heading spacing, margins all relate mathematically. | Creates the invisible structure that makes a page feel "right." When rhythm breaks around illustrations, the whole page feels amateur. |
| **Hierarchy** | Visual weight differences that signal structure: title > chapter heading > subheading > body > caption. | Must be established with no more than 2-3 typefaces. More than that = visual noise. |
| **Typographic color** | Not ink color — the overall gray value of a text block. Determined by typeface weight, size, leading, and tracking together. | Pages should have a consistent "color" when you squint at them. Light, even gray = readable. Patchy or dark = something's wrong. |

**2. Type selection for the Firekeeper Books series**

You need a type palette — a small, deliberate set of typefaces that work together across the series. Choose these once, use them for every title:

- **Body text (1 typeface):** The workhorse. Must be supremely readable at 10-12pt in print. Should have personality without calling attention to itself. Qualities to look for: generous x-height, open counters (the holes in letters like 'e' and 'a'), functional italics (you'll use them for emphasis and epigraphs).
  - *Candidates to evaluate:* Crimson Pro, Cormorant Garamond, EB Garamond, Libre Baskerville, Spectral (all libre-licensed via Google Fonts). For a more distinctive choice: Alegreya (designed specifically for literature).
  - *Anti-candidates:* Times New Roman (generic), Palatino (overused), Georgia (screen-optimized, not ideal in print).

- **Display text (1 typeface):** For chapter titles, section headers, cover text. Can have more character than the body face. Should contrast with body text — if body is a transitional serif (Baskerville-style), display could be a high-contrast didone (Bodoni-style) or a humanist serif.
  - *Candidates:* Playfair Display, Cinzel (classical/architectural), Cormorant (works as both body and display in different weights).
  - For Frankenstein specifically: consider faces with a slightly irregular or engraved quality — something that whispers "19th century letterpress" without being a novelty font.

- **Decorative (optional, 0-1):** Only if you use drop caps or ornamental initials. These are high-risk — bad decorative type ruins pages faster than anything else. If in doubt, skip it and use the display face at a larger size for drop caps.

**Type pairing principle:** Contrast, not conflict. Body and display should differ in *classification* (e.g., old-style body + neoclassical display) but share a mood. Test pairings by setting a full chapter opener: title in display, first paragraph in body, with a drop cap if applicable. Print a test page and evaluate on paper — screens lie about type at body sizes.

**3. Page architecture**

In print, you control every spatial relationship. This is where "someone made this with care" lives:

- **Trim size:** Standard trade paperback options: 5.5x8.5", 6x9", or 5x8". For an illustrated edition, 6x9" gives the most room for illustrations while remaining standard enough for POD. KDP Print supports all of these.

- **Text block position:** Traditional book design places the text block slightly high and toward the spine (inner margin < outer margin, top margin < bottom margin). This asymmetry feels natural. For 6x9": inner margin ~0.75", outer ~0.9", top ~0.75", bottom ~1.0" is a reasonable starting point. Adjust based on the typeface and page count (thicker books need more inner margin for the gutter).

- **Margins as design element:** Generous margins signal quality. Cramped margins = cheap paperback energy. For illustrated editions, the margins frame both text and illustrations — they should feel spacious enough that a full-page illustration has breathing room from the page edge (or intentionally bleeds to the edge — but bleed adds $0.15/copy in POD printing).

- **Chapter openers — the most designed page in any book:**
  - *Vertical start position:* How far down the page does the chapter title sit? Starting at 1/3 or even 1/2 down the page creates drama and white space. This vertical drop is one of the strongest "premium edition" signals.
  - *Title treatment:* Display typeface, possibly all-caps with wide tracking, possibly with a decorative rule or ornament above or below.
  - *Drop cap:* The enlarged first letter of the first paragraph. 2-3 lines deep is standard. Must be optically aligned (the top of the drop cap aligns with the cap height of the first line, the bottom aligns with the baseline of the 2nd or 3rd line). Misaligned drop caps are one of the most common amateur tells.
  - *Opening paragraph:* Often set in small caps (first few words or first line) to transition from the display-scale title to body text. This bridge prevents the jarring jump from big → small.
  - *Illustration integration:* Does every chapter open with an illustration? A vignette? A decorative border? The decision should be consistent within a title.

- **Running headers/footers:** Page numbers (folios) at minimum. Optional: chapter title on verso (left), book title on recto (right). Keep these subtle — small size, light weight. They're wayfinding, not decoration. Some illustrated editions omit running headers entirely for a cleaner page — a valid choice.

- **Section breaks:** Options: extra vertical space (1-2 blank lines), a centered ornament (asterism ⁂, fleuron ❧, or a custom small graphic from your illustration work), or a simple horizontal rule. Pick one, use it everywhere.

**4. Text-image integration in print — designed spreads**

Print unlocks what ebook can't do: you control how left and right pages relate to each other.

- **Illustration placement patterns (print-specific):**

  | Pattern | When to use | Print-specific consideration |
  |---------|------------|----------------------------|
  | **Full-page illustration** | Key dramatic moments | Can face the relevant text page as a designed *spread*. No text on the illustration page. Consider whether the illustration bleeds to the edge or has a frame/border within the margins. |
  | **Frontispiece** | The signature illustration | Faces the title page. This pairing (frontispiece + title page spread) is a centuries-old convention that signals "illustrated edition." |
  | **Chapter opener illustration** | Every chapter or selected chapters | Sits above the chapter title on the same page, or on the facing page. In print, you control this exactly. |
  | **Half-page illustration** | Supplementary scenes | Text flows around or stops below. In print, wrapping works reliably — but simpler placement (text stops, illustration sits between paragraphs) often looks cleaner. |
  | **Vignette / spot illustration** | Decorative, transitional | Can serve as chapter-ending ornaments, section breaks, or page-bottom decorations. In print, these small touches accumulate into a "lovingly made" feeling. |

- **The spread as design unit:**
  In print, readers see two pages at once. Every spread is a composition. An illustration on the right (recto) page creates a visual anchor; text on the left (verso) provides the narrative context. When you place illustrations, think in spreads, not single pages. A full-page illustration on a verso facing a chapter opener on the recto is a powerful combination.

- **Paper-aware color:**
  POD paperback typically uses cream/ivory paper (KDP's default for fiction/literary). Your illustrations, designed on a white screen, will look slightly warmer and lower-contrast on cream paper. This can actually *help* — the warm paper softens the digital precision of AI art. But test: export a few illustrations, order a proof copy, and see how they actually look on paper. Adjust brightness/contrast in post-processing if needed.

- **Bleed decisions:**
  Full-bleed illustrations (running to the page edge) look dramatic but cost more in POD ($0.15/copy premium on KDP Print) and require 0.125" extra image area on all bleed edges. Framed illustrations within the margins are cheaper, faster to produce, and arguably more classical. Decide once for the series.

**5. Non-body-text page design**

Pages that aren't body text or illustrations still need design — and in print, you have full control:

- **Title page:** Series name, book title, author, "illustrated edition," Firekeeper Books imprint. Design this as a composed page with your display typeface, generous whitespace, possibly a small ornament or vignette. This and the frontispiece form the first spread the reader sees after the cover.
- **Copyright page:** Functional but not ugly. Smaller type, consistent with body face. Include colophon information (typefaces used, illustration process, paper stock). This is a subtle signal of craft — premium editions include it, mass-market doesn't.
- **Table of contents:** Same typeface hierarchy as the interior. In print with fixed page numbers, the TOC can include page numbers with dot leaders — a small classical touch.
- **Epigraph pages:** Quote + attribution. Generous whitespace. Italic body text or display face. Centered or right-aligned on the page, not left-aligned like body text. In print, an epigraph page can be a designed object — almost a poem of whitespace and type.
- **Part/section dividers:** Frankenstein has three volumes in the 1818 text. These are mini title pages. Design once, reuse. Consider a small vignette illustration for each.
- **Dedication page:** Simple, central, lots of air.

**6. Design system documentation**

Codify all decisions into a living design system document (`Projects/firekeeper-books/design/design-system.md`). This becomes the single reference for both formats and all future titles:

- Trim size, margins, and text block dimensions (print) + spacing values (ebook)
- Type palette: typefaces, sizes, leading, paragraph spacing, tracking for display type
- Drop cap specifications: face, size, line depth, optical alignment rules
- Chapter opener template: spatial layout, title treatment, illustration integration — both print and ebook versions
- Illustration placement rules: full-page, half-page, vignette — spacing values for each format
- Section break treatment
- Running header/footer specs (print) + navigation specs (ebook)
- Paper and color notes (cream stock color profile for print illustration adjustment)
- Bleed/no-bleed decision and rationale
- Front matter page sequence (both formats)
- Colophon template
- File naming and organization conventions

**7. Print production tools**

If you're using Atticus (from Phase 3) for the ebook, it also exports print-ready PDF — so your print layout can come from the same project file. This is the fastest path.

For deeper print design control (if you outgrow Atticus):

| Tool | What it adds for print | When to move to it |
|------|----------------------|-------------------|
| **Affinity Publisher 2** ($70) | Full typographic control, baseline grids, master pages, bleed marks, professional PDF export. The real page design tool. | If Atticus's print output doesn't meet your quality bar, or if you want pixel-level spread design |
| **Adobe InDesign** ($23/mo) | Industry standard. Total control over everything. | Only if you're producing 10+ titles and want maximum efficiency at scale |

**Recommendation:** Start with Atticus for both formats. Order a KDP Print proof copy of Frankenstein early — before the ebook even ships. Hold the physical book. If it meets your bar, Atticus is the production tool. If you see things you want to control more precisely (and you will, eventually), that's when Affinity Publisher enters the workflow — likely for the Odyssey print edition or a second-edition Frankenstein.

### Feedback Loop
- **The physical proof test:** Order a proof copy from KDP Print as soon as the layout is ready. Hold it. Read a chapter. Look at the illustrations on paper. This single act will teach you more about print typography than any tutorial. Note everything that feels off — margin tightness, type size, illustration contrast on cream paper.
- **The bookshelf test:** Place the proof next to the Coulthart Frankenstein and other benchmark illustrated editions on your shelf. Does it belong? What's the gap?

### Plateau Markers
- If pages feel "right" on screen but wrong in the proof: screen and print are different media. Adjust type size, leading, and illustration contrast for paper. This is normal — every designer iterates between screen and proof.
- If the design system feels constraining: you may be ready for Affinity Publisher's granularity. That's growth, not failure.

### Resources (Phase 3b)
- **Butterick's Practical Typography** — now read the page layout chapters (margins, page proportions) with print context
- **The Elements of Typographic Style** by Robert Bringhurst — the canonical reference. Ch. 2 (Rhythm & Proportion) and Ch. 8 (Choosing & Combining Type) are highest-value for this phase
- **Google Fonts** — final type palette selection. Print a specimen sheet (actual paper) for each candidate at body text sizes before committing
- **KDP Print proof ordering** — submit a draft, order a single proof copy ($3-5 + shipping). The physical object is irreplaceable feedback
- **Your Phase 2 typography reference screenshots and physical books** — compare your proof against the exemplars, now on the same medium

---

## Phase 4: Genre Adaptation — The Odyssey (Apr 29–Jun 8)

*Aligns with OD-Pre and OD-M1. Your Frankenstein skills must transfer to a completely different visual world.*

**Phase goal:** Adapt your established workflow and style sensibility to epic/classical/Mediterranean aesthetics. Produce 28-32 Odyssey illustrations at or above Frankenstein quality. Refine the design system for genre flexibility.

### Core Activities

**1. Odyssey art direction document**
New genre, new style guide. The Odyssey demands different choices:
- **Palette shift:** Mediterranean light vs. Gothic darkness. Warm earth tones, azure seas, bronze and marble vs. Frankenstein's desaturated blues and ambers.
- **Scale:** The Odyssey is about vast landscapes, divine intervention, massive creatures. Compositions need to feel expansive. Frankenstein was intimate; Odyssey is epic.
- **Figural style:** Greek/classical influence without being kitschy. Study how to reference classical art without producing "Greek mythology clipart."
- **Reference artists:** Shift your reference pool. Consider: John Flaxman (line illustrations of Homer), Maxfield Parrish (color and light), N.C. Wyeth (epic narrative illustration), or contemporary artists who do classical subjects with originality.

**2. Style transfer exercises**
Before committing to production:
- Take 3 Frankenstein-style prompts and adapt them for Odyssey. Observe what changes and what stays constant. The *constant* part is your emerging personal style.
- Generate the same Odyssey scene in 5 different style directions. Which one feels most "Firekeeper Books" while being authentically Odyssey?

**3. Character consistency at scale**
28-32 illustrations means Odysseus appears in many of them. Penelope, Telemachus, Athena, Poseidon — recurring characters need to be recognizable. This is a harder problem than Frankenstein (fewer recurring characters).
- Build robust `--cref` references for each major character
- Test consistency across scene types (action, dialogue, solitude, divine encounter)
- Accept that 100% consistency is impossible with current tools — aim for "same character" recognition, not "same face every time"

**4. Expanded illustration count management**
28-32 illustrations is nearly double Frankenstein. Efficiency matters:
- Plan illustration map before generating: which scenes, what composition type, what mood
- Batch by mood/setting (all sea scenes together, all Ithaca scenes together) — your prompts and style references stay in a groove
- Set a per-illustration time budget based on Frankenstein metrics. If you averaged 2 hours, budget 2 hours or less for Odyssey.

**5. Design system stress test (ebook + print)**
Your Frankenstein layout decisions now face a fundamentally different text — and for the Odyssey, you're producing *both* formats, informed by the Frankenstein proof copy feedback:

- **Verse vs. prose:** If you choose a verse translation (Pope, Cowper), line breaks are semantic, not just visual — the typography must respect them. Verse needs more vertical space per page, different indentation rules, and possibly a slightly larger type size to compensate for shorter lines. If prose (Butler, Lawrence), your Frankenstein system transfers more directly. This affects both formats but matters more in print where you control line breaks precisely.
- **24 books vs. chapters:** The Odyssey's structure (24 "books," each with an established title) creates more section breaks, more chapter openers, more text-image transition points. Your chapter opener template gets 24 repetitions — any weakness will become glaring. In the ebook, 24 chapter openers means 24 navigation points in the TOC. In print, it means 24 designed pages.
- **Illustration density:** 28-32 illustrations across 24 books means roughly 1.2 per book, but distribution is uneven (some books are action-heavy, some are dialogue). The page rhythm shifts more frequently — your spacing rules need to handle both illustration-dense and illustration-sparse stretches. In print, this affects spread composition; in ebook, it affects scroll rhythm.
- **Epigraphs and invocations:** The Odyssey opens with "Sing in me, Muse" — this demands typographic treatment (epigraph page, possibly with illustration). Many books have natural epigraph moments. In print, these are designed pages with generous whitespace. In ebook, use image-based rendering for the invocation page if it needs precise typographic treatment.
- **Names and epithets:** Homer's repeated epithets ("rosy-fingered Dawn," "wine-dark sea") are a design opportunity — consider whether any get special typographic treatment or if they're purely body text.
- **Print-specific Odyssey concerns:** Longer text = more pages = thicker book = more gutter margin needed. Illustration-heavy books need higher paper quality (or heavier stock) to prevent bleed-through. Order a proof early in Odyssey production, not just at the end.

### Feedback Loop
- **Side-by-side test:** Place a Frankenstein illustration and an Odyssey illustration next to each other. They should feel like they come from the same *publisher* but not the same *book*. Shared DNA, different expression.
- **The Nolan timing pressure test:** Is the quality holding up under schedule pressure, or are you settling? If quality is slipping, cut illustration count before cutting quality.

### Plateau Markers
- If Odyssey illustrations look like "Frankenstein but in daylight": you're not adapting enough. Return to Odyssey-specific reference artists.
- If they look nothing like Frankenstein editions: you've lost your thread. Return to what's constant in your style.

---

## Phase 5: Signature Style & Expanding Craft (Ongoing, post-Odyssey)

**Phase goal:** Evolve from "good at using AI art tools" to "recognizable Firekeeper Books aesthetic." Build skills that compound across future titles.

### Core Activities

1. **After-action review on first two titles:** What worked? What would you do differently? Where did post-processing save bad generation vs. where did great generation need no post-processing? Write this up — it's your most valuable learning artifact.

2. **Expand tool repertoire as needed:**
   - **Affinity Publisher 2** — if Atticus's print output doesn't satisfy your growing design eye, this is the graduation tool. Full typographic control, baseline grids, master pages, professional PDF output. The Odyssey or third title is the natural point to evaluate.
   - **ComfyUI / Stable Diffusion** — more control over generation pipeline (advanced, only if Midjourney's constraints frustrate you)
   - **Affinity Photo / Photoshop** — deeper compositing than Pixelmator Pro allows (only if you hit Pixelmator's ceiling)

3. **Study real art more, not more AI tools.** At this point, your bottleneck is taste and art direction, not tool fluency. Spend time with:
   - Illustrated book history (Arthur Rackham, Aubrey Beardsley, William Morris/Kelmscott Press, Edward Gosse)
   - Contemporary narrative illustration (Jon Klassen, Carson Ellis, Shaun Tan)
   - Art movements relevant to your titles (Romanticism, Pre-Raphaelites, Art Nouveau)
   - Museum visits, physical art books — screen-based references have their own aesthetic bias

4. **Build community and get feedback loops beyond personal circle:**
   - Ebook design communities
   - AI art communities that focus on craft (not just prompt sharing)
   - Book reviewer/bookstagram feedback on published editions

5. **Genre expansion:** Each new title is a style adaptation exercise. The skill is not "Midjourney for gothic horror" — it's "art direction for illustrated books using AI tools, across any genre."

---

## Additional Tools Worth Evaluating

| Tool | What it adds | When to evaluate |
|------|-------------|-----------------|
| **Magnific AI** | AI upscaling + enhancement. Can add detail and increase resolution beyond Midjourney's native output. | Phase 3, if resolution is a bottleneck for print |
| **Topaz Gigapixel AI** | Dedicated upscaler. Good for print-ready output at 300dpi. | Phase 3b, when preparing print illustrations |
| **Krea AI** | Real-time AI generation with more compositional control (canvas-based). | Phase 2, as a compositional sketching tool |
| **ComfyUI** | Node-based Stable Diffusion interface. Maximum control over generation pipeline. Steep learning curve. | Phase 5 only — don't add complexity during production |
| **Affinity Publisher 2** | Full page layout with professional typographic control. Exports to EPUB and PDF. | Phase 3b or Phase 4, when/if you outgrow Atticus for print design |
| **Atticus** | Visual ebook + print layout from one project. Fast, professional defaults. | Phase 3 — recommended primary production tool |
| **Calibre** | EPUB validation and format conversion. Essential utility. | Phase 3 — install immediately |
| **Kindle Previewer** | Amazon's official tool for testing how your ebook renders on Kindle devices. | Phase 3 — install immediately |

## Progress Tracking

| Phase | Target Date | Status | Hours Logged | Notes |
|-------|------------|--------|-------------|-------|
| Phase 1: Tool Fluency | Apr 8 | | | |
| Phase 2: Style Development | Apr 14 | | | |
| Phase 3: Ebook Production | May 5 | | | |
| Phase 3b: Print Design | Parallel / May 12 | | | |
| Phase 4: Odyssey | Jun 8 | | | |
| Phase 5: Ongoing | — | | | |

### Per-Illustration Log Template

```
| # | Scene | Generation time | Selection time | Post-processing time | Total | Quality (1-5) | Notes |
|---|-------|----------------|---------------|---------------------|-------|--------------|-------|
```

Track this in `Projects/firekeeper-books/progress/time-log.md`.

## The Core Principle: Intentionality Is the Moat

The reason AI art triggers negative reactions isn't that it's AI-generated — it's that most AI art is *unintentional*. Someone typed a prompt, got a pretty result, and shipped it. There's no authorial voice, no compositional philosophy, no consistent aesthetic, no restraint.

The antidote isn't hiding that it's AI. It's making every choice *on purpose*:
- Why this palette and not another
- Why this composition and not centered
- Why this level of detail and not more
- Why this mood and not the obvious one
- Why this post-processing treatment

When every choice has a reason, the result has authorship. That's what separates illustration from generation. You're not learning to use Midjourney — you're learning to be an art director whose primary production tool happens to be Midjourney.
