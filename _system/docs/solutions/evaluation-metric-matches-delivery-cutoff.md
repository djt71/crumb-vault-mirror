---
type: solution
track: pattern
domain: software
status: active
created: 2026-08-14
updated: 2026-08-14
confidence: medium
tags:
  - compound
  - evaluation-design
  - retrieval
  - kb/software-dev
topics:
  - moc-crumb-operations
source_projects:
  - akm-refresh
source_artifacts:
  - Projects/akm-refresh/specification.md
  - Projects/akm-refresh/progress/run-log.md
---

# Evaluation Metric Must Match the Delivery Cutoff

## Claim

When a system evaluates retrieval (or any ranked selection) with a top-k metric, k must equal the cutoff the delivery path actually applies. If the eval measures recall@k_eval but the consumer only ever sees the top k_delivery < k_eval, the eval systematically overstates quality: items ranked between k_delivery+1 and k_eval count as hits that no user ever receives.

## Evidence

- **GEM-F2 (akm-refresh SPECIFY, 2026-07-07):** the AKM bench fixture measured recall@5 while the surfacing budget delivers only 3 items. The metric passed; the brief actually missed — the relevant chunk sat at rank 4–5, counted as recall success, and was cut before delivery. Single confirmed instance (hence `confidence: medium`); promoted to solutions/ by operator approval 2026-08-14.

## How to Apply

- At eval design time, trace the delivery path and read the cutoff out of the consuming code/config — don't default to a conventional k (5, 10) from benchmark habit.
- If multiple consumers apply different cutoffs, evaluate at the smallest one (or report per-cutoff).
- When a delivery budget changes, treat every eval keyed to the old budget as invalidated — re-run, don't extrapolate.
- Cheap audit: grep eval configs for `@k` / `top_k` values and diff against the delivery-side budget constants. Any mismatch is this pattern.

## Related

- [[live-soak-beats-benchmark]] — sibling failure mode: even a correctly-cut metric can diverge from live behavior.
