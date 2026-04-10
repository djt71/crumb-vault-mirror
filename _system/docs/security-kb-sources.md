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
  - reference-catalog
topics:
  - moc-security
---

# Security KB — Source Catalog

Curated sources for cybersecurity knowledge that supports SE conversations.
Filtered for relevance: these are sources you'd actually open during a
customer call, competitive analysis, or compliance mapping — not an
exhaustive reference list.

This catalog guides what authoritative sources SHOULD be represented in the
vault as knowledge notes. Use for:
- Quarterly gap analysis (what's in the catalog but not in the vault?)
- Researcher skill scoping (prioritize these sources when fetching live)
- Maintenance review (are URLs still valid? have sources been superseded?)

**Vault-tier** = stable, high-reuse, worth digesting into knowledge notes.
**Live-fetch** = volatile, broad, or vendor-specific — reference by URL, don't digest.

Maintenance: add sources as you encounter them in SE work. Remove sources
that go stale or get superseded. Review quarterly alongside moc-security.

---

## Security Frameworks & Standards

Core reference material for customer conversations. Most customers reference
at least one of these; knowing how DNS/DDI maps to each framework is the
SE differentiator.

| Source | URL | Vault Tier | SE Relevance |
|--------|-----|-----------|--------------|
| MITRE ATT&CK — Enterprise | https://attack.mitre.org/matrices/enterprise/ | Vault | Threat framework customers actually use. DNS-relevant techniques: T1071.004 (DNS C2), T1568 (DGA), T1048.003 (DNS exfiltration), T1583.001 (domain acquisition). Map Infoblox detections to ATT&CK IDs in customer conversations. |
| MITRE ATT&CK — DNS techniques | https://attack.mitre.org/techniques/T1071/004/ | Vault | Deep-link to DNS-specific sub-techniques. The "here's exactly what we detect" reference. |
| NIST Cybersecurity Framework (CSF) 2.0 | https://www.nist.gov/cyberframework | Vault | The umbrella framework. Customers reference CSF functions (Identify, Protect, Detect, Respond, Recover) — map DDI capabilities to each. Updated to 2.0 in Feb 2024 with new Govern function. |
| NIST SP 800-207 | https://csrc.nist.gov/pubs/sp/800/207/final | **In vault** | Zero Trust Architecture. Already digested — [[nist-800-207-zero-trust-index]]. |
| NIST SP 800-81r3 (IPD, April 2025) | https://csrc.nist.gov/pubs/sp/800/81/r3/ipd | **In vault** | Supersedes 800-81-2 (2013). Co-authored by Cricket Liu and Ross Gibson (Infoblox). Formally recommends Protective DNS, RPZ, encrypted DNS (DoT/DoH/DoQ). The single most important government reference for DNS security SE conversations. Digested — [[nist-800-81r3-secure-dns-deployment-digest]]. |
| CIS Controls v8 | https://www.cisecurity.org/controls | Vault | 18 prioritized controls. DNS security maps to Controls 9 (Email/Web), 13 (Network Monitoring), 3 (Data Protection). Customers use CIS as their "what should we do first" framework. |
| CISA Zero Trust Maturity Model | https://www.cisa.gov/zero-trust-maturity-model | Vault | Government-specific ZT guidance. Five pillars — DNS fits in the Network pillar. Federal customers reference this alongside 800-207. Updated to v2.0 in 2023. |

---

## DNS Threat Landscape

The intersection of DNS and security is your home turf. These sources
inform the "why DNS security matters" conversation.

| Source | URL | Vault Tier | SE Relevance |
|--------|-----|-----------|--------------|
| CISA: Protective DNS (PDNS) | https://www.cisa.gov/resources-tools/services/protective-domain-name-system-resolver | **In vault** | Government PDNS resolver service. 104+ agencies, 1.6B queries/day. Validates DNS security as federal priority. Digested — [[cisa-protective-dns-guidance-digest]]. |
| NSA/CISA: Selecting a Protective DNS Service (v1.3) | https://media.defense.gov/2025/Mar/24/2003675043/-1/-1/0/CSI-Selecting-a-Protective-DNS-Service-v1.3.PDF | **In vault** | Joint guidance on evaluating PDNS providers. v1.3 (March 2025) adds Palo Alto, Secure64. Criteria favor Infoblox differentiators. Digested — [[nsa-cisa-pdns-selection-criteria-digest]]. PDF blocked by DoD CDN — digest from web coverage. |
| Infoblox Threat Intel (TIDE) | https://docs.infoblox.com/space/BloxOneThreatDefense | Live-fetch | Own-vendor threat intel documentation. Reference for TIDE feed structure, IOC categories, reputation scoring. Too product-specific to digest — refer by URL. |
| DNS Tunneling: detection approaches | (multiple academic sources — see note) | Vault | Payload analysis, frequency analysis, entropy-based detection. Worth a synthesized note covering detection methodologies rather than individual paper digests. |
| DGA Detection | (multiple sources — see note) | Vault | Domain Generation Algorithm detection: lexical analysis, NXDomain ratios, ML-based classification. Same approach as tunneling — synthesized note. |
| Infoblox DNS Threat Report (annual) | https://www.infoblox.com/resources/research/ | Live-fetch | Annual threat landscape report. Good for customer conversations but content refreshes yearly — reference, don't digest. |
| Unit 42 DNS Threat Research | https://unit42.paloaltonetworks.com/ | Live-fetch | Competitor's threat research. Often has good DNS-specific analysis. Use for competitive awareness, not vault content. |

**Note on academic/research sources:** DNS tunneling and DGA detection are
well-studied. Rather than digesting individual papers, create synthesized
knowledge notes covering detection methodologies. Source selection for those
notes should happen during a researcher skill dispatch.

---

## Competitive DNS Security

Know their architecture well enough to explain the difference. Focus on
how they handle DNS-layer security specifically, not their full product suite.

| Vendor | Documentation | Vault Tier | SE Relevance |
|--------|--------------|-----------|--------------|
| Cisco Umbrella | https://docs.umbrella.com/ | **In vault** | Cloud recursive resolver, Talos threat intel, Investigate passive DNS, SIG/Advantage/Essentials tiers. Digested — [[cisco-umbrella-architecture-digest]]. |
| Zscaler ZIA | https://help.zscaler.com/zia | **In vault** | DNS proxy through ZTE, ZTR cloud resolver (150+ DCs), request+response inspection, DoH tunnel blocking. DNS is a feature, not a product. Digested — [[zscaler-zia-dns-architecture-digest]]. |
| Palo Alto — DNS Security | https://docs.paloaltonetworks.com/dns-security | **In vault** | Inline ML on NGFW, cloud signatures from WildFire/passive DNS/honeynet, Standard vs Advanced DNS Security. Digested — [[palo-alto-dns-security-architecture-digest]]. |
| Palo Alto — Cortex XDR | https://docs.paloaltonetworks.com/cortex/cortex-xdr | Live-fetch | Endpoint + network correlation platform. Consumes DNS telemetry as a detection signal alongside endpoint data. Relevant when customers position XDR as their detection layer — the question becomes "where does DNS telemetry come from?" (Infoblox as the source vs. PAN firewall). |
| Palo Alto — Prisma Access | https://docs.paloaltonetworks.com/prisma/prisma-access | Live-fetch | SASE platform with DNS Security subscription included. Cloud-delivered version of the NGFW DNS filtering. Shows up in SASE-first conversations where the customer is consolidating to Palo Alto's stack. Same DNS Security ML engine, different delivery model. |
| Fortinet — FortiGuard DNS | https://docs.fortinet.com/document/fortigate/latest/administration-guide/ | **In vault** | Category-based DNS filtering via FortiGuard SDNS, proxy/flow modes, botnet C&C blocking. Digested — [[fortinet-fortiGuard-dns-architecture-digest]]. |
| Fortinet — FortiSASE | https://docs.fortinet.com/product/fortisase/ | Live-fetch | Cloud-delivered security with DNS filtering. Extends FortiGuard DNS filtering to remote users. Same competitive dynamics as Prisma Access — SASE consolidation play where DNS filtering comes bundled. |
| Netskope | https://docs.netskope.com/ | Live-fetch | Cloud-native SWG/CASB/ZTNA with DNS filtering as part of Security Service Edge (SSE) stack. Shows up in SSE consolidation deals alongside Zscaler. No DDI play. DNS filtering is feature-level, not product-level. Competitive context: Netskope's DNS filtering is policy-based (allow/block by category/domain) — not threat-detection-focused like Infoblox. |
| BlueCat | https://docs.bluecatnetworks.com/ | Live-fetch | Direct DDI competitor. Edge product adds DNS-layer security (threat protection, query logging, analytics). Most relevant in DDI competitive situations — BlueCat's security story is weaker than Infoblox but they're actively adding capabilities. Shows up in enterprise DDI evaluations alongside EfficientIP. |
| Cloudflare Gateway | https://developers.cloudflare.com/cloudflare-one/policies/gateway/dns-policies/ | Live-fetch | DNS filtering via 1.1.1.1 resolver. Consumer-grade simplicity, limited policy granularity vs. enterprise tools. Strong brand but shallow enterprise features. |
| Akamai Enterprise Threat Protector | https://techdocs.akamai.com/ | Live-fetch | DNS-based threat protection from CDN company. Acquired from Nominum. Less competitive focus in your territory but appears in some enterprise deals. |
| EfficientIP | https://www.efficientip.com/resources/ | Live-fetch | Direct DDI competitor. DNS Guardian product for DNS security. Smaller player but shows up in European deals and Gartner DDI MQ. |

**Competitive positioning principle:** Digest the *architecture* (how they
handle DNS queries, where inspection happens, what threat intel they use),
not the feature matrix. Feature matrices change quarterly; architectural
differences are stable and explain *why* the products behave differently.

---

## Better Together — Integration Architectures

How Infoblox integrates with the major security vendors. These are the
"better together" stories that turn competitive conversations into
partnership conversations. High-reuse in SE engagements — the integration
pitch is often what closes the deal when a customer already has a vendor
relationship.

All integration stories are **vault-tier**: the architectures are stable,
the SE pitch is consistent, and you reference these in nearly every
competitive situation.

**Source note:** Integration architecture documentation lives primarily on
Infoblox's ecosystem/integration pages, which may have the same
JS-rendering problem as the Infoblox docs (dynamic page content not
accessible via fetch). Vendor-side docs (Palo Alto, Fortinet, etc.) should
be fetchable. Where web sources are inaccessible, SE domain knowledge is
the primary source, supplemented by whatever's publicly accessible from the
vendor side.

| Integration | Key Mechanisms | Vault Tier | SE Pitch |
|-------------|---------------|-----------|----------|
| Infoblox + Palo Alto | TIDE→EDLs, DNS RPZ→firewall enforcement, BloxOne↔Cortex XSOAR. | **In vault** | "Two detection surfaces, one policy." Digested — [[infoblox-palo-alto-integration-digest]]. |
| Infoblox + Fortinet | TIDE→FortiGate feeds, NIOS notifications→address groups, DNS→FortiSIEM. | **In vault** | "Keep FortiGate for perimeter, add Infoblox for DNS depth." Digested — [[infoblox-fortinet-integration-digest]]. |
| Infoblox + Cisco | ISE/IPAM via pxGrid + Umbrella coexistence architecture. | **In vault** | "Infoblox owns DDI — ISE and Umbrella get better." Digested — [[infoblox-cisco-integration-digest]]. |
| Infoblox + Zscaler | DNS forwarding architecture, clean separation of concerns. | **In vault** | "DNS infrastructure + security proxy — no overlap." Digested — [[infoblox-zscaler-integration-digest]]. |
| Infoblox + CrowdStrike | DNS detection→endpoint investigation, TIDE↔Falcon intel, SOAR automation. | **In vault** | "DNS sees it first, endpoint tells you what it is." Digested — [[infoblox-crowdstrike-integration-digest]]. |
| Infoblox + Splunk/SIEM | DNS telemetry→Splunk (pre-built apps), IPAM context enrichment. | **In vault** | "Every connection starts with DNS." Digested — [[infoblox-splunk-siem-integration-digest]]. |

---

## Compliance Frameworks by Vertical

These come up in specific customer segments. Know which framework your
customer cares about before the call — the compliance-to-DNS mapping is
the value-add.

| Framework | URL | Verticals | Vault Tier | DNS/DDI Relevance |
|-----------|-----|-----------|-----------|-------------------|
| CMMC 2.0 + NIST SP 800-171 | https://dodcio.defense.gov/CMMC/ | Defense, defense supply chain | **In vault** | Combined digest: CMMC certification + 800-171 technical controls. 21 of 110 controls (~19%) with direct DDI relevance. Digested — [[cmmc-800-171-dns-compliance-mapping-digest]]. |
| HIPAA Security Rule | https://www.hhs.gov/hipaa/for-professionals/security/ | Healthcare | Live-fetch | PHI protection. DNS security maps to Access Controls (§164.312) and Audit Controls. Less prescriptive than CMMC — the mapping is more interpretive. |
| PCI DSS 4.0 | https://www.pcisecuritystandards.org/document_library/ | Financial, retail | Live-fetch | Cardholder data. Requirement 1 (network controls), Requirement 10 (logging), Requirement 11 (security testing). DNS monitoring supports multiple requirements. |
| FedRAMP | https://www.fedramp.gov/program-basics/ | Federal cloud, SaaS vendors | Live-fetch | Cloud security authorization. Relevant when positioning BloxOne (cloud-managed DDI) for government customers. |
| SOC 2 Type II | https://www.aicpa-cima.com/topic/audit-assurance/audit-and-assurance-greater-than-soc-2 | SaaS, technology | Live-fetch | Trust Services Criteria. DNS monitoring supports CC7.2 (monitoring), CC6.6 (boundary protection). Comes up with tech company customers. |
| NIS2 Directive | https://digital-strategy.ec.europa.eu/en/policies/nis2-directive | EU-based customers | Live-fetch | EU cybersecurity directive. DNS infrastructure is explicitly in scope as "essential service." Relevant for European accounts. |

**Vault-tier rationale:** CMMC and 800-171 are vault-tier because defense/federal
is a high-priority vertical and the frameworks are stable + prescriptive enough
to create durable compliance-to-DNS mappings. Other frameworks are live-fetch
because either the mapping is too interpretive (HIPAA) or the framework changes
frequently enough (PCI DSS) that a digest would go stale.

---

## Threat Intelligence Standards

Relevant when customers ask about feed integration, IOC sharing, or
threat intel architecture.

| Source | URL | Vault Tier | SE Relevance |
|--------|-----|-----------|--------------|
| STIX 2.1 (OASIS) | https://oasis-open.github.io/cti-documentation/stix/intro.html | **In vault** | Structured threat information format. 18 SDOs, 18 SCOs, patterning language. TIDE mapping for import/export. Digested — [[stix-taxii-threat-intel-standards-digest]]. |
| TAXII 2.1 (OASIS) | https://oasis-open.github.io/cti-documentation/taxii/intro.html | **In vault** | HTTPS transport for STIX. REST API, collections, filtering, pagination. Paired with STIX in single digest — [[stix-taxii-threat-intel-standards-digest]]. |
| Cyber Kill Chain (Lockheed Martin) | https://www.lockheedmartin.com/en-us/capabilities/cyber/cyber-kill-chain.html | Vault | 7-stage attack model. Simpler than ATT&CK — some customers still use this framing. DNS security maps to multiple stages (Reconnaissance, C2, Actions on Objectives). |

---

## Industry Analysis

Paywalled but referenced in every competitive conversation.

| Source | URL | Vault Tier | SE Relevance |
|--------|-----|-----------|--------------|
| Gartner: SSE Magic Quadrant | https://www.gartner.com/ | Live-fetch | Market positioning for DNS security competitors (Zscaler, Netskope, Palo Alto). Paywalled — reference findings, don't digest. |
| Gartner: DNS Security Market Guide | https://www.gartner.com/ | Live-fetch | Directly relevant market definition. Rare — when published, it shapes customer vocabulary for 2+ years. |
| Forrester: Zero Trust Wave | https://www.forrester.com/ | Live-fetch | ZT vendor evaluations. Customers reference Forrester when evaluating ZT architecture. |
| EMA: DDI Research | https://www.enterprisemanagement.com/ | Live-fetch | DDI-specific analyst. Shiv Agarwal's research directly covers Infoblox competitive positioning. Most relevant analyst for DDI. |

---

## Priority Batch — First Digestion Candidates

Based on frequency of use in customer conversations and stability of content:

1. **MITRE ATT&CK DNS techniques** — the "here's what we detect" conversation
2. **NIST CSF 2.0** — the umbrella framework everyone references
3. **CIS Controls v8** — the "where do I start" framework
4. **CISA PDNS guidance** — validates the market category
5. **NSA/CISA Protective DNS selection criteria** — evaluation framework that favors Infoblox
6. **NIST SP 800-81-2** — Secure DNS Deployment Guide (government customers)
7. **CMMC 2.0 + NIST 800-171** — defense vertical compliance (pair these)
8. **STIX/TAXII** — threat intel interoperability (pair these)
9. **Cisco Umbrella architecture** — primary competitor, stable enough to digest
10. **Palo Alto DNS Security architecture** — most common firewall competitor, inline vs. resolver framing
11. **Fortinet FortiGuard DNS architecture** — second most common firewall competitor, category-based model
12. **Zscaler ZIA architecture** — SSE competitor, DNS-as-feature-not-product framing
13. **Better Together integration stories** — Infoblox + Palo Alto, Fortinet, Cisco, Zscaler, CrowdStrike (high-reuse SE narratives, stable architecture)
14. **Cyber Kill Chain** — simpler alternative to ATT&CK that some customers still use

**DNS tunneling and DGA detection** are also high-priority but need a
researcher dispatch to identify the best source material rather than
digesting a single vendor's perspective.

---

*This catalog is curated for SE conversations, not exhaustive coverage.
Prefer official standards and vendor architecture docs over blog posts.
When competitive docs conflict with standards, the standard is authoritative
for protocol behavior; the vendor doc is authoritative for product behavior
and positioning.*
