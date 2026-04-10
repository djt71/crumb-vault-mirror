---
type: overlay
domain: career
status: active
created: 2026-03-03
updated: 2026-03-05
tags:
  - overlay
  - networking
  - dns
  - security
---

# Network Skills

Domain expertise lens for enterprise networking, DNS infrastructure, and
network security. Ensures technical recommendations and customer-facing
work draw on authoritative sources rather than general knowledge. Oriented
toward Infoblox SE work but also applicable to personal learning and
architecture exploration.

Companion reference: `_system/docs/network-skills-sources.md` carries the
curated source catalog. Load it when this overlay fires.

## Activation Criteria

**Signals** (match any → consider loading):
Task involves any of: DNS architecture or resolution design, DHCP/IPAM
planning, network security architecture (RPZ, DoH/DoT, DNS filtering),
SASE or SSE evaluation, CDN behavior or integration, hyperscaler
networking (AWS VPC, GCP networking, Azure VNet), load balancer design
or selection, SD-WAN architecture, zero trust network access, customer
network migration planning, RFC interpretation or compliance, BGP/routing
design, firewall policy architecture, network protocol analysis.

**Anti-signals** (match any → do NOT load, even if signals match):
- Application-level coding or software architecture with no network dimension
- Crumb system infrastructure (launchd, Obsidian, local tooling) unless network-specific
- Generic security topics not related to network infrastructure
- Business or pricing decisions about network vendors (use Business Advisor)
- Career development questions about networking skills (use Career Coach)

**Canonical examples:**
- ✓ "Design a split-horizon DNS architecture for this customer's hybrid cloud migration" — DNS architecture, likely involves hyperscaler integration
- ✓ "How does Zscaler's ZIA handle DNS resolution vs. Netskope's approach?" — competitive analysis requiring vendor-specific technical knowledge
- ✓ "What RFC governs DNS-over-HTTPS and what are the deployment implications?" — standards interpretation with operational impact
- ✗ "Help me write a proposal for the DNS migration project" — persuasion/writing task, not a networking knowledge task
- ✗ "Should I get my CCNP or focus on cloud certifications?" — career development (Career Coach)

## Lens Questions

1. **Standards compliance:** Is this design consistent with the relevant RFCs and IETF standards? If it deviates, is the deviation deliberate and documented?
2. **Authoritative source check:** Am I drawing this recommendation from vendor documentation, RFC text, or verified operational knowledge — or am I guessing? Check the source catalog before asserting.
3. **Integration surface:** Where does this component touch other vendors' infrastructure? What are the protocol handoff points, and what can go wrong at each boundary?
4. **Scale and failure mode:** How does this behave at the customer's scale? What happens when it fails — graceful degradation or hard outage?
5. **Infoblox positioning (customer-facing work):** Where does this design create or reduce dependency on Infoblox products? Be honest about competitive strengths and gaps. (Skip for pure learning/exploration contexts.)
6. **Source catalog feedback:** Did this session surface a new authoritative source or reveal a stale one? If so, propose an update to `_system/docs/network-skills-sources.md`.

## Key Frameworks

- **DNS resolution chain:** Stub resolver → recursive resolver → authoritative server → root/TLD. Every DNS architecture question should be grounded in where in this chain the change occurs and what it affects upstream and downstream. Most misarchitectures come from confusing which layer owns the decision.
- **Defense in depth for DNS:** RPZ (policy), DoH/DoT (transport encryption), DNSSEC (data integrity), DNS filtering (threat prevention) — these are complementary layers, not alternatives. Evaluate customer architectures against which layers are present and which are missing.

## Anti-Patterns

- Do NOT rely on general LLM knowledge for protocol specifics — check RFCs and vendor docs via the source catalog
- Do NOT present Infoblox as the answer to every networking question — credibility comes from honest technical assessment
- Do NOT conflate marketing terminology with technical architecture — vendors use "zero trust" and "SASE" differently; e.g., Zscaler's "zero trust" (proxy-based internet access via ZIA) vs. NIST 800-207 (per-request policy evaluation). Ground claims in actual product behavior.
- Do NOT assume hyperscaler defaults are best practice — cloud provider networking has opinionated defaults that may conflict with enterprise DNS/security requirements
