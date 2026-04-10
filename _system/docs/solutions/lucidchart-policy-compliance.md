---
type: reference
domain: career
status: active
track: convention
linkage: discovery-only
created: 2026-02-20
updated: 2026-04-04
topics:
  - moc-business
tags:
  - policy
  - compliance
  - lucidchart
  - genai
  - kb/business
---

# Lucidchart API & GenAI Policy Compliance

Research conducted 2026-02-20 via claude.ai session + Glean (Infoblox internal AI agent) validation against Infoblox AUP, Information Security, and Generative AI Use policies. Updated 2026-02-20 with direct review of primary source documents (GenAI Use Policy v4.1 and Code of Business Conduct and Ethics).

## Lucidchart API Usage — COMPLIANT

Using Lucidchart's REST API for diagram automation is within Infoblox policy. Confirmed by Glean against internal policy documents.

**Why it's compliant:**
- Lucidchart is an Infoblox-procured SaaS tool (in use across SE enablement, ARB workflows, training docs, templates)
- API access is included with the existing Lucid Suite Enterprise license — no additional cost or procurement
- Using the official REST API against a pre-approved vendor is treated as scripting/automation, not a "new application"
- Personal script running on a company-managed device with a personal API key does not require IT/Security review
- Data going into diagrams is the same data that would be entered manually (network topologies, DDI architectures, customer designs)

**Requirements to stay compliant:**
- Use only the company-managed Infoblox Lucidchart account (not personal accounts)
- Run scripts from company-managed devices only [Code of Conduct: "Use of Company Property" — assets used for legitimate business purposes]
- Store API key in `~/.config/crumb/.env` — never commit to repos, never paste into Slack/Teams/email/tickets
- Treat the API key like a password (unique per user, not shared)
- Only store the same classes of data you would normally put into Lucidchart manually
- Protect proprietary data customers/suppliers provide [Code of Conduct: "Fair Dealing" — protect proprietary data as reflected in agreements]

**When IT/Security review IS required:**
- Turning the script into a shared/always-on integration (service account, scheduled jobs, webhook listener)
- Moving Lucidchart data into new third-party systems
- Automation touching especially sensitive data beyond normal Lucidchart usage
- Any pattern that could be considered a "new application" under the AUP

## GenAI Boundary — CONSTRAINT

Claude Code (Anthropic) is **not** on the Infoblox approved GenAI tools list.

### Policy basis (from primary source documents)

**Generative AI Use Policy v4.1 (updated 2026-02-18):**
- **§2.1.1** — "Infoblox Personnel must adhere to the applicable Infoblox IT and Security policies and use only approved GenAI tools."
- **§2.1.4** — "Do not install any nonapproved Application Programming Interfaces (APIs), web or browser plug-ins, connectors [...] or software related to GenAI systems. Any AI-generated code in approved systems must be reviewed via established code review practices."
- **§2.2.1** — "Infoblox Personnel may not input sensitive information into any GenAI system unless that GenAI system has been approved by the AI Steering Committee and is within Infoblox's IT and Security policies."
- **§2.2.2** — "Do not input intellectual property into nonapproved generative AI applications. Do not enter personal information (PI) of employees, customers, or other third parties into any nonapproved GenAI application."
- **§2.3** — "employees must review for accuracy of the output to avoid false outputs (hallucinations), bias, and copyright infringement."
- **§2.4 (Transparency)** — "when GenAI forms the substantial basis for final materials without significant human alteration OR where otherwise required by applicable law, Infoblox Personnel must identify in that final material that GenAI has been used."
- **§2.5 (Third-Party Risk)** — "Data sent by Infoblox Personnel to third parties may be used in the third party's GenAI tools."
- **§2.7** — Report policy violations to aicommittee@infoblox.com.

**Code of Business Conduct and Ethics (revised 05/01/2023):**
- **Confidentiality** — Employees entrusted with confidential info including: (1) technical info about products/services, (2) business/marketing plans, (3) financial data, (4) personnel info, (5) supply and customer lists, (6) other non-public info that could be useful to competitors or harmful to customers/partners. Must sign agreement to protect proprietary info.
- **Use of Company Property** — "assets of Infoblox should be used for legitimate business purposes and for personal purposes only to the extent allowed by Company policy."
- **Fair Dealing** — "Protect all proprietary data our customers or suppliers provide to us as reflected in our agreements with them."
- **Corporate Opportunities** — "shall not use Company property or information [...] for personal gain other than actions taken for the overall advancement of the interests of the Company."

### What this means for Crumb

**Hard constraints:**
- Do NOT input non-public Infoblox data into Claude Code sessions: no real customer names, internal IPs, customer topologies, employee data, or intellectual property [GenAI §2.2.1, §2.2.2]
- Use synthetic/redacted data for anything customer-facing
- This applies to ALL Crumb sessions, not just Lucidchart — it's a system-wide constraint
- Must review all GenAI output for accuracy before use [GenAI §2.3]
- Must disclose GenAI usage when it forms the substantial basis for final customer-facing materials without significant human alteration [GenAI §2.4]
- Data sent to Anthropic (Claude Code) could theoretically be used in their models [GenAI §2.5] — reinforces the prohibition on sending sensitive data

**What this does NOT block:**
- Using Claude Code to generate diagram JSON from generic descriptions ("create a DNS hierarchy with three tiers")
- Using Claude Code with synthetic/example data ("create a topology for ExampleCorp with 10.0.0.0/8 addressing")
- The Lucidchart API call itself (that's Crumb → Lucidchart, no GenAI involved)
- Any Crumb work that doesn't involve non-public Infoblox data
- Using company device for SE productivity tooling [Code of Conduct: Use of Company Property — legitimate business purposes]

**The boundary is upstream of the Lucidchart skill.** The skill itself is policy-safe regardless. The constraint is on what data enters Claude Code sessions.

**Uncertainty contact:** aicommittee@infoblox.com [GenAI §2.2.2, §2.7]

## Practical Operating Model

1. **Lucidchart skill with synthetic data:** Fully compliant. Claude Code generates JSON, pushes to Lucidchart API. No policy issues.
2. **Lucidchart skill with real customer data:** Non-compliant IF the customer data passes through Claude Code. Compliant IF you manually prepare the diagram spec and only use Claude Code for the API push mechanics (no customer data in the prompt).
3. **Customer-intelligence project:** Must use redacted/synthetic data in Claude Code sessions. Real customer names and details should be redacted before entering any Crumb workflow.
4. **Transparency disclosure [GenAI §2.4]:** If a Crumb-generated diagram is delivered to a customer as a final material without significant human modification (e.g., auto-generated and sent directly), it must include a disclosure that GenAI was used. If you substantially rearrange/edit the diagram in Lucidchart after generation, no disclosure is required. **Safe default:** add "Generated with AI assistance" to the diagram description or delivery notes.
5. **Output review [GenAI §2.3]:** Always visually verify generated diagrams in Lucidchart before sharing externally. Check for hallucinated components, incorrect connections, and missing elements.

## Source

**Primary documents (reviewed directly):**
- Infoblox Generative AI Use Policy, v4.1, updated 2026-02-18 (Owner: Chris Herbst, Governing: Legal & IT, Approvers: Wei Chen, Amy Farrow). Classified: Highly Confidential.
- Infoblox Code of Business Conduct and Ethics, revised 05/01/2023. Classified: Infoblox Confidential.

**Secondary sources (via Glean):**
- Infoblox Acceptable Use Policy (6.2025) — cited by Glean, not reviewed directly
- Infoblox Mobile Device Policy (1.26) — cited by Glean
- Infoblox User Access Control Policy (6.2025) — cited by Glean
- Infoblox Email and Messaging Policy (6.2025) — cited by Glean

**Other:**
- Lucid developer documentation — via web research, 2026-02-20
- Glean validation of claude.ai compliance analysis — 2026-02-20

---

## Appendix: Glean Conversation Transcript (2026-02-20)

Verbatim transcript of Glean (Infoblox internal AI agent) policy validation session. Retained as evidence in case of future challenge.

### Query 1: Lucidchart API access and use

**Glean response:**

You're allowed to automate Lucidchart via its API, as long as you stay within the general IT/Security and Acceptable Use policies. There is no Infoblox policy that specifically forbids Lucidchart API use; it's treated like any other already-approved SaaS tool.

**What policy says that's relevant:**

1. **Use only company-approved apps for company data**
   - The Acceptable Use Policy (AUP) says the IT team publishes a list of approved applications; if something isn't on that list, you're supposed to open a ServiceNow ticket to get it reviewed/approved.
   - It also says you may only put non-public company data into platforms that have been procured directly by Infoblox and have the right contractual protections.
   - Lucidchart is already in use across SE enablement and ARB workflows (training docs, templates, customer designs), which strongly implies it is an approved/procured tool for that data.

2. **Acceptable use of devices and systems**
   - AUP and related policies require that you:
     - Use company-managed devices and security tooling.
     - Don't bypass security controls, share credentials, or mishandle confidential data.

3. **New tools / integrations vs. scripting**
   - Policies require review and approval for new applications or services that process Infoblox data (via the Applications Hub / New Application Request, or ServiceNow).
   - That is aimed at new SaaS or 3rd-party services, not at writing scripts against an already-approved vendor like Lucidchart.

4. **GenAI-specific rules (only if your automation uses AI)**
   - The Generative AI Use Policy says you must not install non-approved APIs, browser plugins, or connectors related to GenAI systems and must only use approved GenAI tools.
   - This becomes relevant only if your Lucidchart automation is calling GenAI services or using AI plugins; plain Lucidchart REST API automation is not covered by this restriction.

**What's OK in practice:**

For an SE automating within our existing Infoblox Lucidchart tenant, you are within policy to:
- Use Lucidchart's official API/SDKs to generate or update diagrams, sync data from internal spreadsheets/CPQ/etc. into Lucidchart, automate template population and housekeeping
- Run those scripts from your company-managed laptop or approved internal environment
- Store only the same classes of data you would normally put into Lucidchart manually (designs, BOM linkage, customer diagrams), since that's already approved usage

**Things you must not do:**
- Use personal Lucidchart accounts with Infoblox customer/prospect data
- Hard-code or share API tokens in GitHub, Teams, email, etc. (treat them like passwords)
- Stand up a new external service (e.g., some third-party integration platform) to broker data between Infoblox and Lucidchart without going through the Applications Hub / ServiceNow "New Application Request" review
- Pipe confidential data into any unapproved GenAI layer wrapped around Lucidchart

**When to involve IT / Security:**

You should loop in IT/Security (via ServiceNow or security-compliance@infoblox.com) if:
- You want a shared, always-on integration (service account, scheduled jobs, webhook listener, etc.) rather than a personal script
- Your automation will touch especially sensitive data, or move Lucidchart data into new third-party systems
- You're unsure whether a particular pattern counts as a "new application" under the AUP

### Query 2: Validation of compliance summary

**Glean response:**

Your writeup is mostly correct, with two important caveats around GenAI approval and "personal script vs shared integration". Here's a line-by-line validation with minimal edits.

**Where Crumb fits cleanly within policy:**
- You're using Lucidchart's official REST API (not a third-party broker)
- You're using your company-managed Infoblox Lucidchart account (not personal)
- You're running scripts from your company-managed machine (the work Mac / Studio)
- The data going into diagrams is the same stuff you'd put there manually (network topologies, DDI architectures, customer designs)
- The API key will be stored in ~/.config/crumb/.env on your machine (not in GitHub, Teams, or email)

All of this is aligned with policy, assuming:
- Lucidchart is indeed provisioned under Infoblox's SaaS stack (it clearly is, given the SE training and templates in SharePoint). That satisfies the AUP requirement that non-public data only go into procured systems with proper contracts.
- Your laptop is a company-managed device with the standard endpoint controls, as required by the Endpoint Management and AUP policies.
- You never check the .env into any repo or share its contents; API tokens must be treated like passwords (this is consistent with User Access Control and AUP expectations).

**Where you need to be careful:**

1. **.env file and vault mirror** — Your caution here is spot-on: double-check that ~/.config/crumb/.env is never committed anywhere and that the vault mirror's .gitignore excludes it. The policy is clear: treat API tokens like passwords. Explicitly say "never paste keys into Slack/Teams/email or tickets" (which matches Email & Messaging + AUP posture).

2. **The GenAI boundary / Claude Code** — This is the main area that needs tightening.
   - The Generative AI Use Policy applies to any GenAI use for Infoblox work, not only "automation." It simply says: you must use only approved GenAI tools and follow IT/Security policies. You may not input sensitive info (customer/employee data, IP, etc.) into any GenAI system unless that system is approved by the AI Steering Committee and within Infoblox IT/Security policy. It also says: "Do not install any nonapproved APIs, web or browser plug-ins, connectors ... related to GenAI systems."
   - If Claude Code is not on the Infoblox-approved GenAI list, using it on real Infoblox customer or internal data would be out of policy, regardless of the Lucidchart API piece.

3. **"Personal script" vs "shared integration"** — Directionally correct but slightly overstated.
   - The AI policy says: any new application, subscription, or service that processes Infoblox data (public or confidential) must go through the New Application Request review.
   - Your script itself is not a "new application/service" in that sense; it's just automation against a pre-approved SaaS (Lucidchart).
   - For a personal script running on your company-managed machine, with your own Lucidchart account and no new external service, you're within policy. If you turn this into a shared/always-on integration or introduce a new SaaS component, that's the point where IT/Security review is required.

**Works cited:**
1. Acceptable Use Policy (6.2025) — infoblox.sharepoint.com
2. Mobile Device Policy (1.26) — infoblox.sharepoint.com
3. User Access Control Policy (6.2025) — infoblox.sharepoint.com
4. Email and Messaging Policy (6.2025) — infoblox.sharepoint.com
5. Infoblox Generative AI Use Policy — infoblox.sharepoint.com
