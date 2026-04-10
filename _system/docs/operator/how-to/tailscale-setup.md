---
type: runbook
status: active
domain: software
created: 2026-03-01
updated: 2026-03-14
tags:
  - ops/networking
  - ops/security
  - system/operator
---

# Tailscale Setup for Remote SSH Access

**Priority:** High — needed before Danny's upcoming trip
**Scope:** Mac Studio + personal laptop + phone (optional)
**Project context:** OpenClaw colocation security (extends OC-009/OC-010 hardening)

---

## Objective

Enable SSH access to the Mac Studio from Danny's laptop while traveling,
without exposing any services to the public internet.

## Decision: Tailscale

Tailscale was selected over port forwarding or other VPN solutions because:

- Zero public-facing attack surface (WireGuard mesh, no open ports)
- Free for personal use (up to 100 devices)
- Minimal install footprint (system extension on macOS)
- No router configuration required
- Aligns with Johann's Security 101 recommendation (Step 4)

## What Tailscale Does NOT Change

- **OpenClaw gateway stays loopback-bound.** `tailscale.mode: "off"` remains
  in openclaw.json. Tess is controlled via Telegram, not the Control UI.
- **No firewall changes.** Tailscale uses outbound connections only.
- **No new ports opened.** The Studio remains invisible to the public internet.
- **Existing SSH key setup is preserved.** Tailscale provides the network
  path; SSH auth works exactly as before.

## Install Steps

### 1. Mac Studio (server side)

Install the **Standalone variant** from Tailscale's package server (NOT the
App Store — the standalone version has fewer restrictions and is recommended
by Tailscale's own docs).

```bash
# Download from https://tailscale.com/download/mac/standalone
# Or via brew:
brew install --cask tailscale

# Start and authenticate
# The app will prompt for system extension approval in System Settings
# Sign in with a personal account (Google or GitHub)
```

After sign-in, verify:

```bash
tailscale status
# Should show the Studio with a 100.x.y.z IP
tailscale ip
# Note this IP for SSH config
```

Ensure Remote Login (SSH) is enabled for the `tess` user:
System Settings → General → Sharing → Remote Login → ON → Allow access for: tess

### 2. Personal laptop (client side)

**Use personal laptop only** — work laptop carries MDM/policy risk (corporate
IT can see installed network software, and Tailscale may conflict with
corporate VPN clients).

Install Tailscale (standalone or App Store — either works for client-only use).
Sign in with the **same account** used on the Studio. Both devices appear on
the same tailnet.

**Usage pattern:**
- **At home:** Leave Tailscale off on the laptop. Connect to the Studio over
  LAN as usual.
- **Traveling:** Start Tailscale on the laptop (`tailscale up`) to reach the
  Studio. Stop it when done (`tailscale down`).
- **Studio stays connected 24/7** — it must be reachable when you're away.

Test SSH:

```bash
ssh tess@<studio-tailscale-ip>
# Or if MagicDNS is enabled:
ssh tess@<studio-magicdns-hostname>
```

### 3. Phone (optional)

Install Tailscale from the iOS App Store. Sign in with the same account.
Use Termius or Blink Shell to SSH via the Tailscale IP.

### 4. Harden the tailnet

In the Tailscale admin console (https://login.tailscale.com/admin):

- **Disable key expiry** on the Studio node (it's always-on infrastructure;
  you don't want it falling off the tailnet while you're away because a key
  expired)
- **Enable MagicDNS** for friendly hostnames instead of IPs
- **Review ACLs** — default personal tailnet allows all devices to talk to
  each other, which is fine for a 2-3 device setup. If you add more devices
  later, tighten ACLs to restrict which devices can SSH to the Studio.
- **Consider `--shields-up` on the laptop** if you don't want the laptop
  accepting inbound connections from other tailnet devices (laptop is
  client-only)

## Post-Install Verification

**Do this test at least 24 hours before departure.** Use a genuinely different
network (phone hotspot, coffee shop, neighbor's WiFi) — not the same LAN. If
the Tailscale handshake is misconfigured or the system extension approval didn't
stick, you want to find out while you're still physically in front of the Studio.

```bash
# Verify tailnet connectivity
tailscale ping <studio-hostname>

# Verify SSH
ssh tess@<studio-tailscale-ip>

# Verify you can reach OpenClaw's user context
ssh tess@<studio-tailscale-ip> 'sudo -u openclaw whoami'
```

## Rollback

If anything goes wrong:

```bash
# On the Studio:
sudo tailscale down
# Or fully uninstall:
brew uninstall --cask tailscale
```

Tailscale is additive — removing it returns the machine to its previous
network state with no side effects.

## Security Audit Update

After install, update the daily security audit script (item 3 in the
security additions doc) to include a Tailscale check:

```bash
# Add to openclaw-security-audit.sh:
echo "=== TAILSCALE STATUS ==="
tailscale status 2>/dev/null || echo "Tailscale not running"
```

Also verify that OpenClaw's config still has `tailscale.mode: "off"` —
we want Tailscale for SSH only, not for OpenClaw gateway exposure.
