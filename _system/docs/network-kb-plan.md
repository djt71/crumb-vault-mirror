---
project: null
domain: career
type: reference
skill_origin: null
status: active
created: 2026-03-06
updated: 2026-03-06
tags:
  - kb/networking
  - kb/networking/dns
topics:
  - moc-networking
---

# Network Knowledge Base — Ingestion Plan

## Problem

The Network Skills overlay instructs Claude to "check the source catalog before
asserting" — but the vault contains zero `#kb/networking/dns` or `#kb/networking` knowledge
notes. The source catalog is 54 URLs the LLM cannot access at runtime. The overlay
operates entirely on training knowledge.

## Three-Layer Architecture

| Layer | Content | Access Pattern |
|-------|---------|----------------|
| **Vault knowledge** (primary) | Digested, tagged knowledge notes in `Sources/`. Stable foundational knowledge — RFCs, architecture patterns, protocol behavior, competitive analysis. | AKM surfaces at overlay activation. Always available, no network dependency. |
| **Source catalog** (maintenance) | Curated URL list (`_system/docs/network-skills-sources.md`). Gap analysis and maintenance guide. | Loaded as overlay companion doc. Used to identify ingestion priorities. |
| **Live fetch** (fallback) | Current vendor docs, release notes, CVE advisories. Too volatile to digest. | WebSearch/WebFetch on demand during sessions. |

### Runtime Flow — How the Layers Work Together

Example: designing hybrid DNS for a customer on AWS.

1. **Network Skills overlay activates** → AKM surfaces vault knowledge (RFC 1034/1035 for resolution mechanics, Infoblox UDDI architecture for hybrid deployment patterns, RPZ spec for threat defense enforcement). These are the stable mental models.
2. **Source catalog loads** as overlay companion doc → curated URL for Route 53 Resolver docs, Azure Private DNS Resolver, etc. identified as available fetch targets.
3. **WebFetch on demand** → pull the current Route 53 page to get latest pricing, endpoint limits, or integration specifics for this customer's design.

The vault knowledge provides the durable framework (how DNS resolution works, how RPZ enforcement works, how UDDI's cloud DNS management integrates with Route 53). Live fetch provides current specifics that change quarterly. You don't digest that Route 53 costs $0.40/million queries — you digest that Route 53 Resolver exists and how it fits architecturally, then fetch the current numbers when you need them.

## Knowledge Note Granularity

| Source Type | Granularity | Example |
|-------------|-------------|---------|
| RFC (core protocol) | One note per RFC or tightly coupled group | `rfc-1034-1035-dns-concepts.md` |
| RFC (extension) | Standalone if substantial; fold into parent if minor | EDNS (6891) warranted standalone (138 lines) |
| Architecture pattern | One note per pattern | `split-horizon-dns-architecture.md` |
| Vendor product | One note per product family (technical behavior) | `infoblox-nios-uddi-architecture.md` |
| Competitive comparison | One note per comparison pair/category | `dns-security-vendor-comparison.md` |
| Security framework | One note per framework | `nist-800-207-zero-trust-architecture.md` |

## Priority Sources

**Vault knowledge (digest once, stable):**
1. ~~RFC 1034/1035 — DNS concepts and resolution~~ DONE 2026-03-06
2. ~~RFC 8484 — DNS-over-HTTPS~~ DONE 2026-03-06
3. ~~NIST SP 800-207 — Zero Trust Architecture~~ DONE 2026-03-06
4. ~~DNS & BIND 5th Edition~~ DONE 2026-03-06 (NLM digest, bypassed OCR block)
5. ~~RPZ specification (ISC draft-vixie-dnsop-dns-rpz)~~ DONE 2026-03-06
6. ~~DNSSEC (RFC 4033-4035)~~ DONE 2026-03-06
7. ~~DNS-over-TLS (RFC 7858)~~ DONE 2026-03-06
8. ~~EDNS (RFC 6891)~~ DONE 2026-03-06

**Vault knowledge (digest, refresh annually):**
9. ~~Infoblox NIOS + Universal DDI (UDDI) architecture~~ DONE 2026-03-06 (from training knowledge, user-reviewed)

**Live fetch only (do NOT digest — too volatile):**
- AWS Route 53 / Route 53 Resolver
- Azure DNS / Azure Private DNS Resolver
- GCP Cloud DNS
- Zscaler ZIA DNS handling
- Cloudflare Zero Trust / 1.1.1.1
- All hyperscaler networking docs
- SASE/SSE vendor comparisons
- Competitive positioning

These stay in the source catalog as WebFetch targets for session-time retrieval.
The overlay's companion doc already serves this purpose.

## Tagging

- `#kb/networking/dns` for DNS-specific, `#kb/networking` for broader networking, `#kb/security` for network security
- Topics: `moc-networking` (Domains/Career/)
- Dual-tag when appropriate (e.g., DNSSEC gets both `kb/networking/dns` and `kb/security`)
