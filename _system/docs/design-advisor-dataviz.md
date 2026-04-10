---
type: reference
domain: null
status: active
created: 2026-03-05
updated: 2026-03-05
tags:
  - overlay
  - design
  - data-visualization
---

# Design Advisor — Data Visualization Reference

Companion document for the Design Advisor overlay. Loaded automatically
when the overlay fires and the task involves data visualization.

## Lens Questions — Data Visualization

When the task involves presenting data visually (charts, graphs, dashboards, infographics, metric displays), apply these in addition to the general design questions:

1. **Show the data.** Is the visualization actually revealing data, or decorating around it? What is the data-ink ratio — how much of the visual serves data vs. ornamentation? Every non-data element should justify its presence. (Tufte: data-ink maximization)
2. **Graphical integrity.** Does the visual representation match the numerical reality? Are areas, lengths, and positions proportional to the quantities they represent? Watch for: truncated axes, area encodings that exaggerate differences, 3D effects that distort comparison. If the visual effect is larger or smaller than the data effect, the chart is lying. (Tufte: Lie Factor)
3. **Right encoding for the task.** Is this the correct chart type for what the viewer needs to do? Position along a common scale (bar charts) yields the most accurate human perception. Area and color saturation yield the least. Match the encoding to the comparison type: use position for precise comparison, length for ranking, color for categorical grouping, small multiples for change over time. (Cleveland-McGill, Cairo: form constrained by function)
4. **Preattentive processing.** Are you leveraging the visual features the brain processes automatically — color, orientation, size, motion — to make the most important patterns pop without requiring conscious effort? Are you overloading any single channel? (Ware: three-stage perceptual model)
5. **Chartjunk check.** Identify and remove: decorative gridlines, 3D effects on 2D data, gradient fills that add no information, heavy borders, logo clutter, ornamental icons. If removing an element changes nothing about understanding, remove it. (Tufte: chartjunk, Ware: noise vs. signal)
6. **Information density.** Could this graphic show more data without becoming cluttered? Small multiples — repeated small charts showing variation across one variable — are almost always superior to animation or interaction for showing change. Shrink, increase density, trust the viewer. (Tufte: small multiples, data density)
7. **Context and comparison.** Does the visualization provide enough context for interpretation? Numbers without comparison are meaningless. Show baselines, trends, benchmarks, or prior periods. Label directly on the graphic rather than using detached legends. (Cairo: presentation vs. exploration continuum)

## Key Frameworks — Data Visualization

- **Data-ink ratio** (Tufte): proportion of ink devoted to data vs. total ink. Maximize relentlessly. Erase non-data-ink, then erase redundant data-ink.
- **Cleveland-McGill perceptual accuracy scale**: position on common scale > position on non-aligned scales > length > direction/angle > area > volume > curvature > color saturation/density. Choose encodings higher on the scale for the most important comparisons.
- **Visualization wheel** (Cairo): six axes for evaluating graphic balance — abstraction-figuration, functionality-decoration, density-lightness, multidimensionality-unidimensionality, originality-familiarity, novelty-redundancy. Use to diagnose why a graphic feels off.
- **Preattentive features** (Ware): color hue, orientation, size, motion, stereoscopic depth. Each operates in a separate visual channel. Map different data dimensions to different channels for parallel processing. Overloading a single channel defeats preattentive pop-out.
- **Small multiples** (Tufte): series of similar small graphics showing change across one variable. Inevitably comparative, deftly multivariate, efficient. Preferred over animation, interaction, or cluttered single charts.
- **Direct labeling** over legends: labels placed on or adjacent to data elements eliminate the cognitive cost of legend lookup. Every legend forces a visual round-trip.

## Anti-Patterns — Data Visualization

- 3D charts for 2D data — perspective distortion lies about quantities
- Pie charts for precise comparison — humans cannot accurately compare angles or areas; use bar charts for more than 2-3 categories
- Dual-axis charts that imply false correlation — two y-axes with different scales can make any two datasets appear related
- Truncated y-axes that exaggerate change — starting above zero makes small differences look dramatic; acceptable only when the baseline is irrelevant and explicitly labeled
- Decorative infographics that sacrifice accuracy — pictograms where icon sizes do not match data proportions
- Color as the only differentiator — always pair with a secondary signal (shape, label, position, pattern)
- Using interaction or animation to compensate for a confusing static design — if the graphic does not work as a screenshot, the design has a problem

## Vault Source Material

These knowledge notes inform the data visualization principles above. Reference when deeper context is needed:
- [[tufte-visual-display-digest]] — data-ink ratio, Lie Factor, chartjunk, small multiples, data density
- [[ware-information-visualization-digest]] — perceptual processing stages, preattentive features, 2D vs 3D, channel separation
- [[cairo-functional-art-digest]] — visualization wheel, form constrained by function, Cleveland-McGill scale, presentation-exploration continuum
