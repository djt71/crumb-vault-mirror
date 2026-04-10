---
project: null
domain: career
type: reference
skill_origin: null
status: active
created: 2026-03-06
updated: 2026-03-06
tags:
  - kb/security
topics:
  - moc-security
---

# Security Knowledge Base — Ingestion Plan

## Problem

The security KB infrastructure is in place — `moc-security`, `#kb/security` tag,
`cybersecurity-kb-capture.md` value filter, `security-kb-sources.md` source catalog
— but the vault contains exactly one `#kb/security` knowledge note (NIST SP 800-207).
The source catalog identifies 14 priority sources plus integration architectures
that should be digested. The overlay and capture guide operate primarily on training
knowledge until vault knowledge is built out.

## Three-Layer Architecture

| Layer | Content | Access Pattern |
|-------|---------|----------------|
| **Vault knowledge** (primary) | Digested, tagged knowledge notes in `Sources/`. Stable foundational knowledge — security frameworks, compliance mappings, competitive architectures, integration stories, threat detection methodologies. | AKM surfaces at overlay activation. Always available, no network dependency. |
| **Source catalog** (maintenance) | Curated URL list (`_system/docs/security-kb-sources.md`). Gap analysis and maintenance guide. Vault-tier vs. live-fetch decisions already made. | Loaded as reference doc. Used to identify ingestion priorities and fetch targets. |
| **Live fetch** (fallback) | Current vendor docs, threat reports, CVE advisories, analyst research. Too volatile or paywalled to digest. | WebSearch/WebFetch on demand during sessions. |

### Runtime Flow — How the Layers Work Together

Example: customer call about replacing Cisco Umbrella with Infoblox DNS security.

1. **Network Skills overlay activates** (security lens) → AKM surfaces vault
   knowledge: NIST CSF 2.0 mapping (Detect/Respond functions), Cisco Umbrella
   architecture note (Talos threat intel, Investigate, SecureX integration),
   Infoblox+Cisco integration story (ISE/IPAM integration, Umbrella coexistence
   pattern), MITRE ATT&CK DNS techniques (what Infoblox detects that Umbrella
   doesn't).
2. **Source catalog loaded** → identifies Cisco Umbrella docs and CIS Controls
   as available fetch targets for current feature details.
3. **WebFetch on demand** → pull the current Umbrella feature page to confirm
   whether a specific capability the customer mentioned is still accurate, or
   fetch the latest CIS Controls mapping for a specific control the customer
   referenced.

The vault knowledge provides the durable competitive framing (architectural
differences, integration patterns, framework mappings). Live fetch provides
current specifics that change quarterly (feature availability, pricing, version
numbers).

## Knowledge Note Granularity

| Source Type | Granularity | Example |
|-------------|-------------|---------|
| Security framework | One note per framework | `nist-csf-2-0-overview.md` |
| Compliance standard | One note per standard (pair tightly coupled ones) | `cmmc-2-0-dns-mapping.md` |
| Competitive architecture | One note per vendor (architecture focus, not features) | `cisco-umbrella-architecture.md` |
| Integration story | One note per vendor pairing | `infoblox-palo-alto-integration.md` |
| Threat detection method | One synthesized note per detection category | `dns-tunneling-detection-methods.md` |
| Threat intel standard | One note per standard (pair STIX/TAXII) | `stix-taxii-overview.md` |
| Government guidance | One note per guidance document | `cisa-protective-dns-guidance.md` |

## Tagging

Primary tag: `#kb/security`

Level 3 subtopics: none pre-defined. With 1 knowledge note in the vault,
subdivision is premature. Let subtags emerge from actual content — when
`#kb/security` has 15+ notes and AKM queries return too broad a set, that's
the signal to subdivide. The capture guide lists candidates
(`dns-threats`, `compliance`, `verticals`) as examples, not commitments.

Dual-tagging:
- DNS-specific security content (e.g., DNS tunneling detection) gets both
  `#kb/security` and `#kb/networking/dns` — primary home in `moc-security`,
  cross-referenced in `moc-networking`
- Competitive architecture notes get `#kb/security` only (not `#kb/business`)
  — these are technical architecture comparisons, not market analysis
- Integration stories get `#kb/security` + `#kb/customer-engagement` — they're
  both technical architecture and SE pitch material. `kb/customer-engagement`
  maps to `moc-business` in `kb-to-topic.yaml`, so integration notes will
  appear in both `moc-security` (via `kb/security`) and `moc-business`
  (via `kb/customer-engagement`). This is intentional — the Better Together
  pitch is both a security architecture and a sales motion. Primary home
  is `moc-security` (set via `topics` field) so there's one curation point

Topics: `moc-security` (primary). Dual-topic with `moc-networking` only for
DNS-specific security content where the networking MOC needs discovery access.

## Source Accessibility

Most priority sources are publicly accessible standards documents (NIST, MITRE,
CISA, CIS, OASIS). These should be fetchable via WebFetch or available as PDFs.

Exceptions:
- **Vendor docs** (Cisco, Palo Alto, Fortinet, Zscaler): generally fetchable from
  vendor documentation sites
- **Infoblox integration pages**: may have JS-rendering issues (dynamic content not
  accessible via fetch). SE domain knowledge is the primary source for integration
  architectures, supplemented by vendor-side docs
- **CIS Controls v8**: requires free registration to download. May need manual
  ingestion from a downloaded copy
- **Paywalled sources** (Gartner, Forrester): live-fetch only, not candidates for
  digestion

## Priority Batches

Sequenced by frequency of use in SE conversations and dependency relationships.
Each batch is a context checkpoint boundary — compact between batches.

### Batch 1 — Security Frameworks (highest frequency, foundation for everything else) DONE 2026-03-06

| # | Source | Notes |
|---|--------|-------|
| 1 | ~~MITRE ATT&CK DNS techniques~~ | DONE — `mitre-attack-dns-techniques-digest.md`. Consolidated T1071.004, T1568, T1048.003, T1583.001 with cross-technique SE framing. |
| 2 | ~~NIST CSF 2.0~~ | DONE — `nist-csf-2-0-overview-digest.md`. All six functions mapped to DDI capabilities with tier progression. |
| 3 | ~~CIS Controls v8~~ | DONE — `cis-controls-v8-dns-mapping-digest.md`. All 18 controls mapped with DDI relevance rating. Training knowledge primary (registration-gated source). |
| 4 | ~~Cyber Kill Chain~~ | DONE — `cyber-kill-chain-dns-mapping-digest.md`. Seven stages with DNS mapping, "6 of 7" pitch, Kill Chain vs ATT&CK guidance. |

### Batch 2 — Government & Protective DNS DONE 2026-03-06

| # | Source | Notes |
|---|--------|-------|
| 5 | ~~CISA Protective DNS guidance~~ | DONE — `cisa-protective-dns-guidance-digest.md`. FCEB-mandated PDNS resolver, 104+ agencies, 1.6B queries/day, three-component architecture (resolver + web app + data platform). |
| 6 | ~~NSA/CISA Protective DNS selection criteria~~ | DONE — `nsa-cisa-pdns-selection-criteria-digest.md`. v1.3 (March 2025), three evaluation dimensions, criteria structurally favor Infoblox. Source PDF blocked (DoD CDN 403) — digest from web coverage + training knowledge. |
| 7 | ~~NIST SP 800-81r3~~ | DONE — `nist-800-81r3-secure-dns-deployment-digest.md`. April 2025 IPD supersedes 800-81-2 (2013). Co-authored by Cricket Liu and Ross Gibson (Infoblox). Formally recommends Protective DNS, RPZ, encrypted DNS (DoT/DoH/DoQ). |
| 8 | ~~CMMC 2.0 + NIST 800-171~~ | DONE — `cmmc-800-171-dns-compliance-mapping-digest.md`. 21 of 110 controls (~19%) with direct DDI relevance across 7 families. Phase 2 (C3PAO assessment) starts 2026. |

### Batch 3 — Threat Intel Standards DONE 2026-03-06

| # | Source | Notes |
|---|--------|-------|
| 9 | ~~STIX 2.1 + TAXII 2.1~~ | DONE — `stix-taxii-threat-intel-standards-digest.md`. Paired note: 18 SDOs + 18 SCOs + patterning language (STIX) + REST API endpoints (TAXII). TIDE architecture mapping for both import/export. SE conversation framework for "do you support STIX?" |

### Batch 4 — Competitive Architectures DONE 2026-03-06

Primary source: vendor documentation sites (fetchable). Focus on architecture
(where DNS inspection happens, what threat intel they use, deployment model),
not feature matrices.

| # | Vendor | Notes |
|---|--------|-------|
| 10 | ~~Cisco Umbrella~~ | DONE — `cisco-umbrella-architecture-digest.md`. Cloud recursive resolver (30+ DCs, Anycast, 620B queries/day), Talos, Investigate passive DNS, SIG/Advantage/Essentials tiers. Strengths/weaknesses vs Infoblox, SE conversation framework. |
| 11 | ~~Palo Alto DNS Security~~ | DONE — `palo-alto-dns-security-architecture-digest.md`. Inline ML on NGFW, cloud signature lookup, WildFire/passive DNS/honeynet data sources, 9 threat categories + advanced detections. Standard vs Advanced DNS Security breakdown. |
| 12 | ~~Fortinet FortiGuard DNS~~ | DONE — `fortinet-fortiGuard-dns-architecture-digest.md`. Category-based DNS filtering via FortiGuard SDNS, proxy/flow modes, botnet C&C blocking, DNS translation, external IP block lists. Simplest architecture of the four competitors. |
| 13 | ~~Zscaler ZIA~~ | DONE — `zscaler-zia-dns-architecture-digest.md`. DNS proxy through ZTE, ZTR cloud resolver (150+ DCs), request+response inspection, DNS Gateway protocol translation, DoH tunnel blocking, predefined risk-tiered rules. Source: full 28-page reference architecture PDF. |

### Batch 5 — Better Together Integration Stories DONE 2026-03-06

Primary source: SE domain knowledge, supplemented by vendor-side docs.
Infoblox ecosystem/integration pages may have JS-rendering issues — don't
depend on them as primary source.

| # | Integration | Notes |
|---|-------------|-------|
| 14 | ~~Infoblox + Palo Alto~~ | DONE — `infoblox-palo-alto-integration-digest.md`. Three surfaces: TIDE→EDL threat feeds, DNS RPZ→firewall enforcement correlation, BloxOne↔Cortex XSOAR bidirectional automation. Most developed integration story. |
| 15 | ~~Infoblox + Fortinet~~ | DONE — `infoblox-fortinet-integration-digest.md`. TIDE→FortiGate external feeds, NIOS Outbound Notifications→address groups for quarantine, DNS events→FortiSIEM correlation. NIOS 8.2+ / FortiGate v6.0.1+ required. |
| 16 | ~~Infoblox + Cisco~~ | DONE — `infoblox-cisco-integration-digest.md`. Two distinct surfaces: IPAM↔ISE via pxGrid (identity+DDI) AND Umbrella coexistence (on-prem Infoblox / roaming Umbrella). ~50% of Umbrella customers have Infoblox. |
| 17 | ~~Infoblox + Zscaler~~ | DONE — `infoblox-zscaler-integration-digest.md`. DNS forwarding architecture. Cleanest separation-of-concerns story: Infoblox=DNS infrastructure+security, Zscaler=web inspection. No API integration needed — architectural coexistence. |
| 18 | ~~Infoblox + CrowdStrike~~ | DONE — `infoblox-crowdstrike-integration-digest.md`. DNS detection→endpoint investigation, bidirectional TIDE↔Falcon intel sharing, Falcon Fusion SOAR automation. Official CrowdStrike Marketplace content pack. |
| 19 | ~~Infoblox + Splunk/SIEM~~ | DONE — `infoblox-splunk-siem-integration-digest.md`. DNS telemetry→Splunk (two official apps: Add-on + BloxOne plugin), IPAM context enrichment, broader SIEM pattern (QRadar, Sentinel, FortiSIEM, Elastic, Chronicle). |

### Internal Deck-Intel Extraction — DONE 2026-03-06

22 internal Infoblox documents processed via deck-intel skill → 17 extraction notes in `Sources/other/`. Extraction notes then used to enrich all Batch 4 and Batch 5 notes with:
- Independent test results (Tolly #224148 vs Zscaler, Tolly #225100 vs PAN, Miercom DR250116C vs Cisco)
- Infoblox Inspect block rates (multi-vendor)
- ADNSR competitive intelligence (pricing, Unit42 analysis)
- Cisco DNS Defense transition data (displacement campaign)
- SEC2 ecosystem roadmap (certified integrations: CrowdStrike, PAN XSOAR, Fortinet, Cisco ISE)
- SOC Insights → SIEM pipeline architecture
- Forrester TEI data (243% ROI, <6 months payback)
- SWG/Zscaler-specific integration architecture

New competitor notes created: AWS Route 53 DNS Firewall, EfficientIP DDI.
MOC synthesis section populated with competitive testing hierarchy, architectural patterns, integration value hierarchy, and key numbers reference.

### Batch 6 — Synthesis Notes (requires researcher dispatch)

These need a researcher skill dispatch to identify best source material
across multiple academic/vendor sources rather than digesting a single
perspective.

| # | Topic | Notes |
|---|-------|-------|
| 20 | DNS tunneling detection methodologies | Payload analysis, frequency analysis, entropy-based detection. Synthesize across academic and vendor sources. |
| 21 | DGA detection methodologies | Lexical analysis, NXDomain ratios, ML-based classification. Same synthesis approach. |

## MOC Integration

As notes are ingested, register them in `moc-security` under the appropriate
subsection:

- **Frameworks** — NIST CSF, CIS Controls, Cyber Kill Chain, MITRE ATT&CK
- **DNS Security** — cross-reference to `moc-networking` for protocol-level content
- **Threat Intelligence** — STIX/TAXII, detection methodologies, kill chain models
- **Compliance & Frameworks** — CMMC, 800-171, PDNS guidance
- **Competitive Positioning** — vendor architecture comparisons

Add a new subsection when the first note lands:
- **Integration Architectures** — Better Together stories

## Execution Notes

- Batches 1-3 are standard knowledge note digestion from fetchable public sources
- Batch 4 uses vendor docs (fetchable) with competitive positioning principle:
  digest architecture, not feature matrices
- Batch 5 relies primarily on SE domain knowledge — treat as user-reviewed
  training-knowledge digests (same pattern as Infoblox UDDI architecture note
  in the network KB build). These need **heavier operator review** than
  Batches 1-3: framework digests are mostly extraction from public documents,
  but integration stories are "how this actually works in a customer
  deployment" — a mix of vendor marketing, technical reality, and field
  experience. Plan for more review cycles on Batch 5
- Batch 6 requires researcher skill dispatch — defer until Batches 1-5 are complete
- Each batch is a context checkpoint boundary: compact between batches, log
  progress to session run-log
- Notes go in `Sources/` with `type: knowledge-note` frontmatter per file conventions
