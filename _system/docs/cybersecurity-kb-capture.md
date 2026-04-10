---
project: null
domain: career
type: reference
skill_origin: null
status: active
created: 2026-03-03
updated: 2026-03-06
tags:
  - kb/security
  - kb/customer-engagement
  - guidance
topics:
  - moc-security
---

# Cybersecurity KB Capture Guide

Guidance for incrementally building cybersecurity reference material in the vault. Not a project — capture as you go, using this as a value filter and structural reference.

## What to Capture

**High value — write it down:**

- Explanations you've given to customers more than once. If you've said it twice, you'll say it a third time — capture the cleanest version.
- Vertical-specific threat context that took real effort to learn. The connection between an industry's operational reality and its security exposure (e.g., manufacturing OT/IT convergence creating DNS visibility gaps) is hard-won knowledge that decays if not recorded.
- Compliance-to-product mappings. The bridge between "NIST/CIS/CMMC/HIPAA/PCI-DSS says X" and "here's how DDI addresses that" is your SE differentiator. These mappings are durable and directly reusable.
- Attack patterns and incident narratives that work in customer conversations. A good story about a real DNS tunneling exfiltration or a DGA-based C2 channel lands harder than a feature list.
- Competitive positioning intel. Where Infoblox's DNS security approach differs from alternatives, and in which scenarios those differences matter.
- Vertical threat landscape summaries. What a financial services CISO worries about vs. a manufacturing OT director vs. a government agency — the framing differs even when the technology overlaps.

**Low value — skip these:**

- Generic security concepts you carry in your head (CIA triad, defense in depth, etc.)
- News-cycle items that'll be stale in a month unless they produced a durable lesson
- Deep technical detail that lives better in vendor docs you can reference by link
- Anything you can reconstruct from first principles in under 60 seconds

## Note Structure

Use standard KB note conventions. Each note is a standalone artifact in `Domains/Career/` (or `Sources/signals/` if captured via the feed pipeline).

```yaml
---
project: null
domain: career
type: reference
skill_origin: null
status: active
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - kb/security
  - kb/security/[subtopic]   # only if the parent tag gets crowded
  - kb/customer-engagement   # if it's customer-facing material
topics:
  - moc-security             # see MOC mapping note below
---
```

Keep the body short and opinionated. A good cybersecurity KB note answers "so what?" — not just what the threat or framework is, but why it matters in a customer conversation and how it connects to the product story.

## Tagging

Primary tag: `#kb/security`

Level 3 subtopics (create when `#kb/security` accumulates enough notes that finer filtering helps):
- `#kb/security/dns-threats` — DNS-layer attack vectors, tunneling, DGA, cache poisoning
- `#kb/security/compliance` — framework mappings (NIST, CIS, CMMC, HIPAA, PCI-DSS)
- `#kb/security/verticals` — industry-specific threat landscapes

Don't pre-create subtopics. Let them emerge from actual content per the compound engineering convention.

## MOC Mapping

`#kb/security` maps to `moc-security` in `kb-to-topic.yaml` (remapped 2026-03-06 from `moc-business`). Security KB now has a dedicated MOC in `Domains/Career/`. Rare system-security notes (e.g., agent sandboxing, prompt injection defense) can override with `topics: [moc-crumb-architecture]` explicitly.

## Overlay Coverage

The Network Skills overlay (`_system/docs/overlays/network-skills.md`) covers the security dimension for DNS/network infrastructure — its source catalog includes MITRE ATT&CK, NIST SP 800-81-2/800-207, CIS Benchmarks, and its defense-in-depth framework addresses RPZ, DoH/DoT, DNSSEC, and DNS filtering. A standalone cybersecurity overlay is not needed; security lens questions live in Network Skills.
