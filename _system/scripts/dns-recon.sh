#!/usr/bin/env bash
# PASSIVE ONLY — this script performs standard recursive DNS queries.
# No zone transfers, port scans, subdomain enumeration, or active probing.
#
# Usage: dns-recon.sh [-r resolver] <domain>
# Output: structured markdown to stdout (caller redirects to file)

set -eu

RESOLVER="8.8.8.8"

usage() {
  echo "Usage: $0 [-r resolver] <domain>" >&2
  echo "  -r  DNS resolver to use (default: 8.8.8.8)" >&2
  exit 1
}

while getopts "r:" opt; do
  case "$opt" in
    r) RESOLVER="$OPTARG" ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

if [ $# -lt 1 ]; then
  usage
fi

DOMAIN="$1"
DATE=$(date +%Y-%m-%d)

# Check for dig
if ! command -v dig &>/dev/null; then
  echo "ERROR: dig not found. Install bind/dnsutils." >&2
  exit 1
fi

# Helper: run dig and return answer section, empty string on failure/NXDOMAIN
dig_query() {
  local qtype="$1"
  local qname="$2"
  dig +noall +answer +nocmd +tries=2 +time=5 "@${RESOLVER}" "$qname" "$qtype" 2>/dev/null || true
}

# ── Collect raw DNS data ──

RAW_MX=$(dig_query MX "$DOMAIN")
RAW_NS=$(dig_query NS "$DOMAIN")
RAW_TXT=$(dig +noall +answer +nocmd +tries=2 +time=5 "@${RESOLVER}" "$DOMAIN" TXT 2>/dev/null || true)
RAW_DMARC=$(dig +noall +answer +nocmd +tries=2 +time=5 "@${RESOLVER}" "_dmarc.${DOMAIN}" TXT 2>/dev/null || true)
RAW_WWW_CNAME=$(dig_query CNAME "www.${DOMAIN}")
RAW_WWW_A=$(dig_query A "www.${DOMAIN}")
RAW_SOA=$(dig_query SOA "$DOMAIN")

# ── Vendor detection arrays ──
# Each entry: "pattern|vendor_name"

declare -a VENDORS_FOUND=()

add_vendor() {
  local vendor="$1"
  local method="$2"
  local category="$3"
  local entry="${vendor}|${method}|${category}"
  # Deduplicate
  for v in "${VENDORS_FOUND[@]+"${VENDORS_FOUND[@]}"}"; do
    if [ "$v" = "$entry" ]; then
      return
    fi
  done
  VENDORS_FOUND+=("$entry")
}

# ── MX vendor detection ──

detect_mx_vendor() {
  local record="$1"
  local lower
  lower=$(echo "$record" | tr '[:upper:]' '[:lower:]')
  if echo "$lower" | grep -qE '(google\.com|aspmx\.l\.google\.com)'; then
    echo "Google Workspace"
  elif echo "$lower" | grep -q 'mail\.protection\.outlook\.com'; then
    echo "Microsoft 365"
  elif echo "$lower" | grep -q 'pphosted\.com'; then
    echo "Proofpoint"
  elif echo "$lower" | grep -q 'mimecast\.com'; then
    echo "Mimecast"
  elif echo "$lower" | grep -q 'barracudanetworks\.com'; then
    echo "Barracuda Email Security"
  elif echo "$lower" | grep -q 'messagelabs\.com'; then
    echo "Broadcom/Symantec Email Security"
  elif echo "$lower" | grep -q 'iphmx\.com'; then
    echo "Cisco IronPort / Cisco Secure Email"
  else
    echo ""
  fi
}

# ── NS vendor detection ──

detect_ns_vendor() {
  local record="$1"
  local lower
  lower=$(echo "$record" | tr '[:upper:]' '[:lower:]')
  if echo "$lower" | grep -q 'awsdns-'; then
    echo "AWS Route 53"
  elif echo "$lower" | grep -q 'cloudflare\.com'; then
    echo "Cloudflare"
  elif echo "$lower" | grep -q 'azure-dns\.'; then
    echo "Microsoft Azure DNS"
  elif echo "$lower" | grep -qE '(akam\.net|akamai)'; then
    echo "Akamai"
  elif echo "$lower" | grep -qE '(googledomains\.com|google\.com)'; then
    echo "Google Cloud DNS"
  elif echo "$lower" | grep -q 'ultradns\.'; then
    echo "Neustar/UltraDNS"
  elif echo "$lower" | grep -q 'domaincontrol\.com'; then
    echo "GoDaddy"
  else
    echo ""
  fi
}

# ── WWW CNAME/A vendor detection ──

detect_www_vendor() {
  local record="$1"
  local lower
  lower=$(echo "$record" | tr '[:upper:]' '[:lower:]')
  if echo "$lower" | grep -q 'cloudfront\.net'; then
    echo "AWS CloudFront CDN"
  elif echo "$lower" | grep -qE '(akamai|edgesuite\.net|edgekey\.net)'; then
    echo "Akamai CDN"
  elif echo "$lower" | grep -q 'cloudflare'; then
    echo "Cloudflare CDN/WAF"
  elif echo "$lower" | grep -q 'fastly'; then
    echo "Fastly CDN"
  elif echo "$lower" | grep -qE '(azurewebsites\.net|azureedge\.net)'; then
    echo "Microsoft Azure"
  elif echo "$lower" | grep -qE '(googleapis\.com|google\.com)'; then
    echo "Google Cloud"
  elif echo "$lower" | grep -q 'wpengine\.com'; then
    echo "WP Engine (WordPress)"
  elif echo "$lower" | grep -q 'squarespace\.com'; then
    echo "Squarespace"
  elif echo "$lower" | grep -qE '(impervadns\.net|incapsula\.com|imperva)'; then
    echo "Imperva WAF/CDN"
  elif echo "$lower" | grep -q 'sucuri'; then
    echo "Sucuri WAF/CDN"
  else
    echo ""
  fi
}

# ── TXT / SPF vendor detection ──

detect_spf_vendors() {
  local txt="$1"
  local lower
  lower=$(echo "$txt" | tr '[:upper:]' '[:lower:]')
  if echo "$lower" | grep -q 'include:_spf\.google\.com'; then
    add_vendor "Google Workspace" "SPF include" "Email"
  fi
  if echo "$lower" | grep -q 'include:spf\.protection\.outlook\.com'; then
    add_vendor "Microsoft 365" "SPF include" "Email"
  fi
  if echo "$lower" | grep -qE 'include:.*salesforce\.com'; then
    add_vendor "Salesforce" "SPF include" "SaaS"
  fi
  if echo "$lower" | grep -qE 'include:(.*mcsv\.net|servers\.mcsv\.net)'; then
    add_vendor "Mailchimp" "SPF include" "SaaS"
  fi
  if echo "$lower" | grep -qE 'include:.*hubspot'; then
    add_vendor "HubSpot" "SPF include" "SaaS"
  fi
  if echo "$lower" | grep -qE 'include:.*zendesk\.com'; then
    add_vendor "Zendesk" "SPF include" "SaaS"
  fi
  if echo "$lower" | grep -qE 'include:.*freshdesk\.com'; then
    add_vendor "Freshdesk" "SPF include" "SaaS"
  fi
  if echo "$lower" | grep -q 'include:amazonses\.com'; then
    add_vendor "AWS SES" "SPF include" "Cloud"
  fi
  if echo "$lower" | grep -q 'include:sendgrid\.net'; then
    add_vendor "Twilio SendGrid" "SPF include" "SaaS"
  fi
  if echo "$lower" | grep -qE 'include:.*pphosted\.com'; then
    add_vendor "Proofpoint" "SPF include" "Security"
  fi
  if echo "$lower" | grep -qE 'include:.*mimecast'; then
    add_vendor "Mimecast" "SPF include" "Security"
  fi
}

detect_txt_verification() {
  local txt="$1"
  if echo "$txt" | grep -q 'MS=ms'; then
    add_vendor "Microsoft 365" "TXT verification token" "SaaS"
  fi
  if echo "$txt" | grep -q 'google-site-verification='; then
    add_vendor "Google" "TXT verification token" "SaaS"
  fi
  if echo "$txt" | grep -q 'docusign='; then
    add_vendor "DocuSign" "TXT verification token" "SaaS"
  fi
  if echo "$txt" | grep -q 'facebook-domain-verification='; then
    add_vendor "Meta/Facebook" "TXT verification token" "SaaS"
  fi
  if echo "$txt" | grep -q 'atlassian-domain-verification='; then
    add_vendor "Atlassian (Jira/Confluence)" "TXT verification token" "SaaS"
  fi
  if echo "$txt" | grep -qE '(adobe-idp-site-verification=|adobe-sign-verification=)'; then
    add_vendor "Adobe" "TXT verification token" "SaaS"
  fi
  if echo "$txt" | grep -q 'hubspot-developer-verification='; then
    add_vendor "HubSpot" "TXT verification token" "SaaS"
  fi
  if echo "$txt" | grep -q '_github-challenge-'; then
    add_vendor "GitHub" "TXT verification token" "SaaS"
  fi
  if echo "$txt" | grep -q 'stripe-verification='; then
    add_vendor "Stripe" "TXT verification token" "SaaS"
  fi
  if echo "$txt" | grep -q 'zoom-domain-verification='; then
    add_vendor "Zoom" "TXT verification token" "SaaS"
  fi
  if echo "$txt" | grep -q 'cisco-ci-domain-verification='; then
    add_vendor "Cisco Webex" "TXT verification token" "SaaS"
  fi
  if echo "$txt" | grep -q 'apple-domain-verification='; then
    add_vendor "Apple" "TXT verification token" "SaaS"
  fi
  if echo "$txt" | grep -q 'amazonses:'; then
    add_vendor "AWS SES" "TXT verification token" "Cloud"
  fi
  if echo "$txt" | grep -q 'v=DKIM1'; then
    add_vendor "DKIM" "TXT DKIM record" "Email"
  fi
  if echo "$txt" | grep -qi 'zscaler-verification'; then
    add_vendor "Zscaler" "TXT verification token" "Security"
  fi
  if echo "$txt" | grep -qi 'globalsign-domain-verification='; then
    add_vendor "GlobalSign (PKI)" "TXT verification token" "Security"
  fi
  if echo "$txt" | grep -qi 'digicert\.com'; then
    add_vendor "DigiCert (PKI)" "TXT verification token" "Security"
  fi
  if echo "$txt" | grep -qi 'Probely='; then
    add_vendor "Probely (Vuln Scanner)" "TXT verification token" "Security"
  fi
  if echo "$txt" | grep -qi 'sectigo'; then
    add_vendor "Sectigo (PKI)" "TXT verification token" "Security"
  fi
}

# ── Infoblox integration mapping ──
# Returns integration story for a vendor, or empty if no known integration

infoblox_integration() {
  local vendor="$1"
  case "$vendor" in
    "CrowdStrike")
      echo "DNS detection + endpoint investigation, bidirectional threat intel (Falcon IOCs <-> TIDE)|BloxOne TD detects DNS-layer threats, CrowdStrike Falcon correlates to endpoint — full kill chain visibility" ;;
    "Splunk")
      echo "Official Add-on + BloxOne plugin dashboards, IPAM enrichment|DNS security events flow into Splunk for unified SOC visibility; IPAM context enriches any IP-based alert" ;;
    "Microsoft Sentinel"|"Microsoft Azure"|"Microsoft Azure DNS"|"Microsoft 365")
      echo "Cloud-to-cloud HTTP destination, dedicated threat dashboards; Universal DDI for Azure|BloxOne TD events stream directly to Sentinel for cloud-native SIEM correlation; unified DDI across Azure and on-prem" ;;
    "Palo Alto Networks")
      echo "TIDE -> PAN EDLs, BloxOne -> Cortex XSOAR automation|DNS threat intelligence feeds directly into PAN firewalls; Cortex XSOAR automates incident response" ;;
    "Fortinet")
      echo "TIDE -> FortiGate, NIOS -> FortiSIEM|DNS threat feeds enhance FortiGate blocking; DNS events correlate in FortiSIEM" ;;
    "Zscaler")
      echo "DNS forwarding architecture (Infoblox recursive + RPZ, Zscaler web inspection)|Infoblox handles DNS resolution + security policy, Zscaler handles web traffic — clean separation" ;;
    "Cisco IronPort / Cisco Secure Email"|"Cisco Webex"|"Cisco")
      echo "ISE/IPAM via pxGrid, Umbrella coexistence|IPAM context enriches ISE access decisions; on-prem Infoblox + roaming Umbrella for complete coverage" ;;
    "Tenable")
      echo "DHCP asset discovery -> Tenable inventory, new device -> auto VA scans|Every new device on the network gets automatically scanned — DHCP-triggered vulnerability assessment" ;;
    "Google Cloud DNS"|"Google Cloud"|"Google Workspace"|"Google")
      echo "Universal DDI for GCP, DNS Armor|Extend enterprise DDI policy into Google Cloud workloads with Universal DDI" ;;
    "AWS Route 53"|"AWS CloudFront CDN"|"AWS SES")
      echo "Universal DDI for AWS, hybrid DNS management|Centralized DDI across on-prem and AWS with consistent policy and visibility" ;;
    "ServiceNow")
      echo "IPAM integration, CMDB enrichment|IPAM data enriches ServiceNow CMDB for accurate asset tracking" ;;
    "Proofpoint")
      echo "Complementary email + DNS security layers|Proofpoint handles email-layer threats, BloxOne TD handles DNS-layer — defense in depth" ;;
    "Mimecast")
      echo "Complementary email + DNS security layers|Mimecast for email gateway security, BloxOne TD for DNS-layer protection" ;;
    "Cloudflare"|"Cloudflare CDN/WAF")
      echo "Complementary DNS security — Infoblox TIDE threat intel + BloxOne recursive alongside Cloudflare authoritative/CDN|Infoblox provides on-prem DNS security and IPAM while Cloudflare handles authoritative DNS and CDN — no overlap" ;;
    "Imperva WAF/CDN")
      echo "Complementary layers — Imperva WAF protects web apps, BloxOne TD protects DNS layer|Imperva handles web application security, BloxOne TD adds DNS-layer threat detection — defense in depth at different stack layers" ;;
    *)
      echo "" ;;
  esac
}

# ── Build output ──

echo "# DNS Reconnaissance — ${DOMAIN}"
echo "> Generated: ${DATE} | Method: passive DNS queries only (dig @${RESOLVER}) | No active probing performed"
echo ""

# ── MX Records ──

echo "## Raw Findings"
echo ""
echo "### MX Records (Email)"
echo ""

if [ -n "$RAW_MX" ]; then
  echo "| Priority | Mail Server | Vendor |"
  echo "|---|---|---|"
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    priority=$(echo "$line" | awk '{print $(NF-1)}')
    server=$(echo "$line" | awk '{print $NF}')
    vendor=$(detect_mx_vendor "$server")
    echo "| ${priority} | ${server} | ${vendor:-Unknown} |"
    if [ -n "$vendor" ]; then
      add_vendor "$vendor" "MX record" "Email"
    fi
  done <<< "$RAW_MX"
else
  echo "*No MX records found.*"
fi
echo ""

# ── NS Records ──

echo "### NS Records (DNS Hosting)"
echo ""

if [ -n "$RAW_NS" ]; then
  echo "| Nameserver | Vendor |"
  echo "|---|---|"
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    server=$(echo "$line" | awk '{print $NF}')
    vendor=$(detect_ns_vendor "$server")
    echo "| ${server} | ${vendor:-Unknown} |"
    if [ -n "$vendor" ]; then
      add_vendor "$vendor" "NS record" "DNS"
    fi
  done <<< "$RAW_NS"
else
  echo "*No NS records found.*"
fi
echo ""

# ── TXT Records ──

echo "### TXT Records (SPF, Verifications)"
echo ""

if [ -n "$RAW_TXT" ]; then
  echo "| Record | Vendor Signal |"
  echo "|---|---|"
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    # Extract the TXT data (everything in quotes)
    txt_data=$(echo "$line" | sed 's/.*TXT[[:space:]]*//' | tr -d '"')
    vendor_signal=""

    # SPF detection
    if echo "$txt_data" | grep -qi '^v=spf1'; then
      detect_spf_vendors "$txt_data"
      # Assess SPF strictness
      if echo "$txt_data" | grep -q '\-all'; then
        vendor_signal="SPF (strict -all)"
      elif echo "$txt_data" | grep -q '~all'; then
        vendor_signal="SPF (softfail ~all)"
      elif echo "$txt_data" | grep -q '?all'; then
        vendor_signal="SPF (neutral ?all)"
      elif echo "$txt_data" | grep -q '+all'; then
        vendor_signal="SPF (permissive +all — WARNING)"
      else
        vendor_signal="SPF"
      fi
    else
      # Verification token detection
      detect_txt_verification "$txt_data"
      if echo "$txt_data" | grep -q 'MS=ms'; then
        vendor_signal="Microsoft 365 verification"
      elif echo "$txt_data" | grep -q 'google-site-verification='; then
        vendor_signal="Google verification"
      elif echo "$txt_data" | grep -q 'docusign='; then
        vendor_signal="DocuSign verification"
      elif echo "$txt_data" | grep -q 'facebook-domain-verification='; then
        vendor_signal="Meta/Facebook verification"
      elif echo "$txt_data" | grep -q 'atlassian-domain-verification='; then
        vendor_signal="Atlassian verification"
      elif echo "$txt_data" | grep -qE '(adobe-idp-site-verification=|adobe-sign-verification=)'; then
        vendor_signal="Adobe verification"
      elif echo "$txt_data" | grep -q 'hubspot-developer-verification='; then
        vendor_signal="HubSpot verification"
      elif echo "$txt_data" | grep -q '_github-challenge-'; then
        vendor_signal="GitHub verification"
      elif echo "$txt_data" | grep -q 'stripe-verification='; then
        vendor_signal="Stripe verification"
      elif echo "$txt_data" | grep -q 'zoom-domain-verification='; then
        vendor_signal="Zoom verification"
      elif echo "$txt_data" | grep -q 'cisco-ci-domain-verification='; then
        vendor_signal="Cisco Webex verification"
      elif echo "$txt_data" | grep -q 'apple-domain-verification='; then
        vendor_signal="Apple verification"
      elif echo "$txt_data" | grep -q 'amazonses:'; then
        vendor_signal="AWS SES verification"
      elif echo "$txt_data" | grep -q 'v=DKIM1'; then
        vendor_signal="DKIM key"
      elif echo "$txt_data" | grep -qi 'zscaler-verification'; then
        vendor_signal="Zscaler verification"
      elif echo "$txt_data" | grep -qi 'globalsign-domain-verification='; then
        vendor_signal="GlobalSign (PKI) verification"
      elif echo "$txt_data" | grep -qi 'digicert\.com'; then
        vendor_signal="DigiCert (PKI) verification"
      elif echo "$txt_data" | grep -qi 'Probely='; then
        vendor_signal="Probely (vuln scanner) verification"
      elif echo "$txt_data" | grep -qi 'sectigo'; then
        vendor_signal="Sectigo (PKI) verification"
      fi
    fi

    # Truncate long TXT records for table display
    display_txt="$txt_data"
    if [ ${#display_txt} -gt 120 ]; then
      display_txt="${display_txt:0:117}..."
    fi
    echo "| \`${display_txt}\` | ${vendor_signal:-—} |"
  done <<< "$RAW_TXT"
else
  echo "*No TXT records found.*"
fi
echo ""

# ── DMARC ──

echo "### DMARC Policy"
echo ""

if [ -n "$RAW_DMARC" ]; then
  dmarc_data=$(echo "$RAW_DMARC" | sed 's/.*TXT[[:space:]]*//' | tr -d '"')
  echo "\`${dmarc_data}\`"
  echo ""

  # Parse DMARC fields
  dmarc_policy=""
  dmarc_rua=""
  dmarc_ruf=""
  dmarc_pct=""

  if echo "$dmarc_data" | grep -qoE 'p=(none|quarantine|reject)'; then
    dmarc_policy=$(echo "$dmarc_data" | grep -oE 'p=(none|quarantine|reject)' | head -1 | cut -d= -f2)
  fi
  if echo "$dmarc_data" | grep -q 'rua='; then
    dmarc_rua=$(echo "$dmarc_data" | grep -oE 'rua=[^;]+' | head -1 | cut -d= -f2)
  fi
  if echo "$dmarc_data" | grep -q 'ruf='; then
    dmarc_ruf=$(echo "$dmarc_data" | grep -oE 'ruf=[^;]+' | head -1 | cut -d= -f2)
  fi
  # Detect vendor from DMARC report addresses
  if echo "$dmarc_data" | grep -qi 'proofpoint\.com'; then
    add_vendor "Proofpoint" "DMARC report destination" "Security"
  fi
  if echo "$dmarc_data" | grep -qi 'agari\.com'; then
    add_vendor "Agari (Fortra)" "DMARC report destination" "Security"
  fi
  if echo "$dmarc_data" | grep -qi 'dmarcian\.com'; then
    add_vendor "Dmarcian" "DMARC report destination" "Security"
  fi
  if echo "$dmarc_data" | grep -qi 'valimail\.com'; then
    add_vendor "Valimail" "DMARC report destination" "Security"
  fi
  if echo "$dmarc_data" | grep -q 'pct='; then
    dmarc_pct=$(echo "$dmarc_data" | grep -oE 'pct=[0-9]+' | head -1 | cut -d= -f2)
  fi

  echo "| Field | Value | Assessment |"
  echo "|---|---|---|"
  case "$dmarc_policy" in
    reject)    echo "| Policy | \`reject\` | Strong — unauthorized mail is rejected |" ;;
    quarantine) echo "| Policy | \`quarantine\` | Moderate — unauthorized mail is quarantined |" ;;
    none)      echo "| Policy | \`none\` | Monitoring only — no enforcement |" ;;
    *)         echo "| Policy | Unknown | Could not parse policy |" ;;
  esac
  if [ -n "$dmarc_pct" ]; then
    echo "| Percentage | \`${dmarc_pct}%\` | Policy applies to ${dmarc_pct}% of mail |"
  fi
  if [ -n "$dmarc_rua" ]; then
    echo "| Aggregate Reports (rua) | \`${dmarc_rua}\` | Configured |"
  else
    echo "| Aggregate Reports (rua) | — | Not configured |"
  fi
  if [ -n "$dmarc_ruf" ]; then
    echo "| Forensic Reports (ruf) | \`${dmarc_ruf}\` | Configured |"
  else
    echo "| Forensic Reports (ruf) | — | Not configured |"
  fi
else
  echo "*No DMARC record found at \`_dmarc.${DOMAIN}\`.*"
fi
echo ""

# ── WWW Resolution ──

echo "### WWW Resolution (CDN/Hosting)"
echo ""

www_vendor=""
if [ -n "$RAW_WWW_CNAME" ]; then
  cname_target=$(echo "$RAW_WWW_CNAME" | awk '{print $NF}')
  echo "**CNAME:** \`www.${DOMAIN}\` → \`${cname_target}\`"
  www_vendor=$(detect_www_vendor "$cname_target")
  if [ -n "$www_vendor" ]; then
    echo "**Vendor:** ${www_vendor}"
    add_vendor "$www_vendor" "WWW CNAME" "CDN"
  fi
  echo ""
fi

if [ -n "$RAW_WWW_A" ]; then
  echo "**A Records:**"
  echo ""
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    ip=$(echo "$line" | awk '{print $NF}')
    echo "- \`${ip}\`"
    # Check A record target for vendor patterns too
    if [ -z "$www_vendor" ]; then
      a_vendor=$(detect_www_vendor "$line")
      if [ -n "$a_vendor" ]; then
        add_vendor "$a_vendor" "WWW A record" "CDN"
      fi
    fi
  done <<< "$RAW_WWW_A"
elif [ -z "$RAW_WWW_CNAME" ]; then
  echo "*No WWW record found for \`www.${DOMAIN}\`.*"
fi
echo ""

# ── SOA Record ──

echo "### SOA Record"
echo ""

if [ -n "$RAW_SOA" ]; then
  soa_primary=$(echo "$RAW_SOA" | awk '{print $5}')
  soa_admin=$(echo "$RAW_SOA" | awk '{print $6}')
  soa_serial=$(echo "$RAW_SOA" | awk '{print $7}')
  echo "| Field | Value |"
  echo "|---|---|"
  echo "| Primary NS | \`${soa_primary}\` |"
  echo "| Admin Contact | \`${soa_admin}\` |"
  echo "| Serial | \`${soa_serial}\` |"
else
  echo "*No SOA record found.*"
fi
echo ""

# ── Vendor Summary ──

echo "## Vendor Summary"
echo ""

if [ ${#VENDORS_FOUND[@]} -gt 0 ]; then
  echo "| Vendor | Detection Method | Category |"
  echo "|---|---|---|"

  # Track vendors already printed to deduplicate by vendor name
  declare -a printed_vendors=()
  for entry in "${VENDORS_FOUND[@]}"; do
    vendor=$(echo "$entry" | cut -d'|' -f1)
    method=$(echo "$entry" | cut -d'|' -f2)
    category=$(echo "$entry" | cut -d'|' -f3)

    already_printed=false
    for pv in "${printed_vendors[@]+"${printed_vendors[@]}"}"; do
      if [ "$pv" = "$vendor" ]; then
        already_printed=true
        break
      fi
    done
    if [ "$already_printed" = false ]; then
      # Collect all methods for this vendor
      all_methods=""
      for e2 in "${VENDORS_FOUND[@]}"; do
        v2=$(echo "$e2" | cut -d'|' -f1)
        m2=$(echo "$e2" | cut -d'|' -f2)
        if [ "$v2" = "$vendor" ]; then
          if [ -n "$all_methods" ]; then
            all_methods="${all_methods}, ${m2}"
          else
            all_methods="$m2"
          fi
        fi
      done
      echo "| ${vendor} | ${all_methods} | ${category} |"
      printed_vendors+=("$vendor")
    fi
  done
else
  echo "*No vendors detected.*"
fi
echo ""

# ── Infoblox Integration Opportunities ──

echo "## Infoblox Integration Opportunities"
echo ""

infoblox_rows=""
if [ ${#VENDORS_FOUND[@]} -gt 0 ]; then
  declare -a infoblox_printed=()
  for entry in "${VENDORS_FOUND[@]}"; do
    vendor=$(echo "$entry" | cut -d'|' -f1)

    # Deduplicate
    already=false
    for iv in "${infoblox_printed[@]+"${infoblox_printed[@]}"}"; do
      if [ "$iv" = "$vendor" ]; then
        already=true
        break
      fi
    done
    if [ "$already" = true ]; then
      continue
    fi
    infoblox_printed+=("$vendor")

    integration_data=$(infoblox_integration "$vendor")
    if [ -n "$integration_data" ]; then
      integration=$(echo "$integration_data" | cut -d'|' -f1)
      story=$(echo "$integration_data" | cut -d'|' -f2)
      infoblox_rows="${infoblox_rows}| ${vendor} | ${integration} | ${story} |
"
    fi
  done
fi

if [ -n "$infoblox_rows" ]; then
  echo "| Detected Vendor | Integration | Better Together Story |"
  echo "|---|---|---|"
  printf '%s' "$infoblox_rows"
else
  echo "*No detected vendors have documented Infoblox integrations.*"
fi
echo ""

# ── Security Posture Indicators ──

echo "## Security Posture Indicators"
echo ""

# Email security summary
email_provider="Unknown"
# Prefer Email-category vendors; fall back to Security-category email tools
for entry in "${VENDORS_FOUND[@]+"${VENDORS_FOUND[@]}"}"; do
  v=$(echo "$entry" | cut -d'|' -f1)
  m=$(echo "$entry" | cut -d'|' -f2)
  c=$(echo "$entry" | cut -d'|' -f3)
  if [ "$c" = "Email" ]; then
    email_provider="$v"
    break
  fi
done
if [ "$email_provider" = "Unknown" ]; then
  for entry in "${VENDORS_FOUND[@]+"${VENDORS_FOUND[@]}"}"; do
    v=$(echo "$entry" | cut -d'|' -f1)
    m=$(echo "$entry" | cut -d'|' -f2)
    if echo "$m" | grep -qiE '(MX|SPF|DMARC)'; then
      email_provider="$v"
      break
    fi
  done
fi

# SPF assessment
spf_assessment="missing"
if [ -n "$RAW_TXT" ]; then
  spf_line=$(echo "$RAW_TXT" | grep -i 'v=spf1' || true)
  if [ -n "$spf_line" ]; then
    if echo "$spf_line" | grep -q '\-all'; then
      spf_assessment="strict (-all)"
    elif echo "$spf_line" | grep -q '~all'; then
      spf_assessment="softfail (~all)"
    elif echo "$spf_line" | grep -q '?all'; then
      spf_assessment="neutral (?all)"
    elif echo "$spf_line" | grep -q '+all'; then
      spf_assessment="permissive (+all — INSECURE)"
    else
      spf_assessment="present (no explicit all mechanism)"
    fi
  fi
fi

# DMARC assessment
dmarc_assessment="missing"
dmarc_reporting="not configured"
if [ -n "${dmarc_policy:-}" ]; then
  dmarc_assessment="$dmarc_policy"
fi
if [ -n "${dmarc_rua:-}" ] || [ -n "${dmarc_ruf:-}" ]; then
  dmarc_reporting="configured"
fi

# DNS hosting assessment
dns_hosting="unknown"
for entry in "${VENDORS_FOUND[@]+"${VENDORS_FOUND[@]}"}"; do
  c=$(echo "$entry" | cut -d'|' -f3)
  if [ "$c" = "DNS" ]; then
    v=$(echo "$entry" | cut -d'|' -f1)
    dns_hosting="cloud-managed (${v})"
    break
  fi
done
if [ "$dns_hosting" = "unknown" ] && [ -n "$RAW_NS" ]; then
  dns_hosting="self-managed or unrecognized provider"
fi

echo "- **Email security:** ${email_provider} + SPF ${spf_assessment} + DMARC ${dmarc_assessment}"
echo "- **DNS hosting:** ${dns_hosting}"
echo "- **DMARC reporting:** ${dmarc_reporting}"
echo ""

# ── Dossier Enrichment Suggestions ──

echo "## Dossier Enrichment Suggestions"
echo ""

echo "- Update Technology Environment (section 4) with detected email platform (${email_provider}), DNS provider, and any SaaS vendors identified through verification tokens"
if [ -n "$infoblox_rows" ]; then
  echo "- Add Infoblox integration stories to the competitive positioning section — DNS recon revealed concrete \"better together\" angles"
fi
if [ "$dmarc_assessment" = "none" ] || [ "$dmarc_assessment" = "missing" ]; then
  echo "- Flag email security posture: DMARC is ${dmarc_assessment} — potential conversation opener around DNS-layer email security"
fi
if [ "$spf_assessment" = "missing" ] || echo "$spf_assessment" | grep -q 'permissive'; then
  echo "- Note weak SPF configuration — opportunity to discuss protective DNS and email authentication"
fi
echo "- Cross-reference detected SaaS vendors against known customer pain points and renewal cycles for timing intelligence"
