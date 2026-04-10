---
project: null
domain: career
type: reference
skill_origin: null
status: active
created: 2026-03-03
updated: 2026-03-03
tags:
  - networking
  - dns
  - security
  - reference-catalog
---

# Network Skills -- Source Catalog

This catalog guides what authoritative sources SHOULD be represented in the
vault as knowledge notes. It is not a runtime reference — the overlay accesses
vault knowledge via AKM at activation time. Use this catalog for:
- Quarterly gap analysis (what's in the catalog but not in the vault?)
- Researcher skill scoping (prioritize these sources when fetching live)
- Maintenance review (are URLs still valid? have sources been superseded?)

Maintenance: add sources as you encounter them in SE work. Remove sources
that go stale or get superseded. Review quarterly alongside overlay.

---

## Standards and RFCs

Primary authority for protocol behavior. When in doubt, the RFC wins.

| Topic | RFC / Standard | Key Content |
|-------|---------------|-------------|
| DNS core | RFC 1034, 1035 | Domain name concepts, message format, resolution |
| DNS extensions (EDNS) | RFC 6891 | Extension mechanisms, larger UDP payloads |
| DNSSEC | RFC 4033, 4034, 4035 | DNS Security Extensions -- signing, validation, key management |
| DNS-over-HTTPS (DoH) | RFC 8484 | HTTPS transport for DNS queries |
| DNS-over-TLS (DoT) | RFC 7858 | TLS transport for DNS queries |
| DNS Response Policy Zones | ISC RPZ spec (draft-vixie-dnsop-dns-rpz) | RPZ rewriting behavior, trigger types, policy actions |
| DHCP v4 | RFC 2131 | Dynamic Host Configuration Protocol |
| DHCPv6 | RFC 8415 | DHCP for IPv6 (consolidated spec) |
| BGP | RFC 4271 | Border Gateway Protocol core |
| HTTP/2 | RFC 7540 | Relevant to DoH transport behavior |
| TLS 1.3 | RFC 8446 | Relevant to DoT and modern secure transport |
| IPv6 addressing | RFC 4291 | IP Version 6 addressing architecture |

**IETF document index:** https://www.rfc-editor.org/
**IANA DNS parameters:** https://www.iana.org/assignments/dns-parameters/

---

## Hyperscaler Networking Documentation

### Amazon Web Services (AWS)

| Service | Documentation | SE Relevance |
|---------|--------------|--------------|
| Route 53 | https://docs.aws.amazon.com/Route53/ | DNS hosting, health checks, routing policies, resolver endpoints |
| VPC | https://docs.aws.amazon.com/vpc/ | Subnets, route tables, NACLs, peering, Transit Gateway |
| Direct Connect | https://docs.aws.amazon.com/directconnect/ | Dedicated network connections to AWS |
| ELB (ALB/NLB/CLB) | https://docs.aws.amazon.com/elasticloadbalancing/ | Load balancer types, listener rules, target groups |
| Network Firewall | https://docs.aws.amazon.com/network-firewall/ | Managed firewall service, Suricata-compatible rules |
| Route 53 Resolver | https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resolver.html | Hybrid DNS -- forwarding between VPC and on-premises |
| AWS Well-Architected (Networking) | https://docs.aws.amazon.com/wellarchitected/ | Design principles, networking pillar |

### Google Cloud Platform (GCP)

| Service | Documentation | SE Relevance |
|---------|--------------|--------------|
| Cloud DNS | https://cloud.google.com/dns/docs | Managed authoritative DNS, DNSSEC support |
| VPC | https://cloud.google.com/vpc/docs | Subnets, routes, firewall rules, Shared VPC |
| Cloud Load Balancing | https://cloud.google.com/load-balancing/docs | Global/regional LB, HTTP(S), TCP/UDP, SSL proxy |
| Cloud Interconnect | https://cloud.google.com/network-connectivity/docs/interconnect | Dedicated/partner interconnect to GCP |
| Cloud Armor | https://cloud.google.com/armor/docs | DDoS protection, WAF policies |
| Network Intelligence Center | https://cloud.google.com/network-intelligence-center/docs | Network topology, connectivity tests, performance dashboard |

### Microsoft Azure

| Service | Documentation | SE Relevance |
|---------|--------------|--------------|
| Azure DNS | https://learn.microsoft.com/en-us/azure/dns/ | DNS hosting, private DNS zones |
| Virtual Network (VNet) | https://learn.microsoft.com/en-us/azure/virtual-network/ | Subnets, NSGs, peering, service endpoints |
| Azure Load Balancer | https://learn.microsoft.com/en-us/azure/load-balancer/ | L4 load balancing, health probes |
| Application Gateway | https://learn.microsoft.com/en-us/azure/application-gateway/ | L7 load balancing, WAF, SSL termination |
| ExpressRoute | https://learn.microsoft.com/en-us/azure/expressroute/ | Private connectivity to Azure |
| Azure Firewall | https://learn.microsoft.com/en-us/azure/firewall/ | Managed cloud firewall, threat intelligence |
| Azure Private DNS Resolver | https://learn.microsoft.com/en-us/azure/dns/dns-private-resolver-overview | Hybrid DNS resolution (on-prem to Azure and back) |

---

## CDN Providers

| Provider | Documentation | SE Relevance |
|----------|--------------|--------------|
| Cloudflare | https://developers.cloudflare.com/ | CDN, DNS (1.1.1.1), DDoS, Workers, Zero Trust (Cloudflare One) |
| Akamai | https://techdocs.akamai.com/ | CDN, edge compute, DNS (Edge DNS), DDoS (Prolexic) |
| Fastly | https://docs.fastly.com/ | CDN, edge compute (Compute@Edge), real-time logging |
| AWS CloudFront | https://docs.aws.amazon.com/cloudfront/ | CDN integrated with AWS ecosystem, Lambda@Edge |
| Azure CDN / Front Door | https://learn.microsoft.com/en-us/azure/frontdoor/ | Global LB + CDN + WAF, Azure-native |
| GCP Cloud CDN | https://cloud.google.com/cdn/docs | CDN tied to GCP load balancing |

---

## SASE / SSE Providers

| Provider | Documentation | Key Products |
|----------|--------------|-------------|
| Zscaler | https://help.zscaler.com/ | ZIA (internet security), ZPA (private access), ZDX (digital experience) |
| Netskope | https://docs.netskope.com/ | SSE platform, CASB, SWG, ZTNA (Netskope Private Access) |
| Palo Alto Networks (Prisma) | https://docs.paloaltonetworks.com/prisma-access | Prisma Access (SASE), Prisma SD-WAN, GlobalProtect |
| Cisco (Secure Access) | https://docs.umbrella.com/ | Umbrella (DNS security/SWG), Secure Access (ZTNA), Meraki SD-WAN |
| Fortinet (FortiSASE) | https://docs.fortinet.com/product/fortisase/ | FortiSASE, FortiGate SD-WAN integration |

---

## Load Balancers and ADCs

| Provider | Documentation | SE Relevance |
|----------|--------------|--------------|
| F5 (BIG-IP / NGINX) | https://techdocs.f5.com/ , https://docs.nginx.com/ | GSLB, LTM, DNS-integrated load balancing, iRules (note: my.f5.com requires auth) |
| Citrix (NetScaler) | https://docs.netscaler.com/ | ADC, GSLB, SSL offload |
| HAProxy | https://docs.haproxy.org/ | Open-source L4/L7 load balancer, widely deployed |
| AWS ALB/NLB | (see AWS section above) | Cloud-native L4/L7 |
| Kemp (Progress) | https://support.kemptechnologies.com/ | LoadMaster, GEO (GSLB) |

---

## DNS-Specific Vendors and Tools

| Vendor / Tool | Documentation | SE Relevance |
|---------------|--------------|--------------|
| Infoblox | https://docs.infoblox.com/ | NIOS, BloxOne DDI, BloxOne Threat Defense, Grid architecture |
| ISC BIND | https://bind9.readthedocs.io/ | Reference DNS implementation, RPZ support |
| Unbound | https://unbound.docs.nlnetlabs.nl/ | Validating recursive resolver |
| PowerDNS | https://doc.powerdns.com/ | Authoritative + recursor, Lua scripting |
| Knot DNS / Knot Resolver | https://www.knot-dns.cz/docs/ | High-performance authoritative + resolver |
| dig / drill / kdig | man pages / CLI tools | DNS query troubleshooting |
| DNSViz | https://dnsviz.net/ | DNSSEC chain visualization and validation |

---

## Network Security

| Topic / Vendor | Documentation | SE Relevance |
|----------------|--------------|--------------|
| MITRE ATT&CK (Network) | https://attack.mitre.org/ | Threat framework, network-layer TTPs |
| CIS Benchmarks | https://www.cisecurity.org/cis-benchmarks | Hardening baselines for network devices |
| NIST SP 800-81-2 | https://csrc.nist.gov/pubs/sp/800/81/2/final | Secure DNS Deployment Guide |
| NIST SP 800-207 | https://csrc.nist.gov/pubs/sp/800/207/final | Zero Trust Architecture |
| OWASP | https://owasp.org/ | Web application security (relevant to WAF/CDN config) |
| Krebs on Security | https://krebsonsecurity.com/ | Threat intelligence, breach reporting |
| The Cloudflare Blog | https://blog.cloudflare.com/ | Deep technical posts on DNS, DDoS, network protocols |

---

## Industry Analysts and Frameworks

| Source | URL | SE Relevance |
|--------|-----|--------------|
| Gartner (SASE/SSE MQ) | https://www.gartner.com/ (paywalled) | Market positioning, vendor comparisons |
| Forrester (Zero Trust) | https://www.forrester.com/ (paywalled) | Zero Trust Wave, network security evaluations |
| EMA Research | https://www.enterprisemanagement.com/ | DDI and network management research |
| NSS Labs / SE Labs | various | Independent security product testing |

---

*This catalog is not exhaustive. Add sources as they prove useful in SE
work. Prefer official vendor documentation over blog posts or third-party
summaries. When vendor docs conflict with RFCs, the RFC is authoritative
for protocol behavior; the vendor doc is authoritative for product behavior.*
