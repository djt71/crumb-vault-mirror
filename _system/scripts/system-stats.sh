#!/usr/bin/env bash
# system-stats.sh — Dumps CPU, memory, disk, and GPU info to JSON.
# Runs via launchd every 60 seconds.
# Output: _system/logs/system-stats.json
set -eu

VAULT_ROOT="${VAULT_ROOT:-/Users/tess/crumb-vault}"
OUTPUT="$VAULT_ROOT/_system/logs/system-stats.json"
TMP_OUTPUT="${OUTPUT}.tmp"

timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# CPU — load averages
read -r load1 load5 load15 <<< "$(sysctl -n vm.loadavg | tr -d '{}')"
cpu_cores=$(sysctl -n hw.ncpu)

# Memory — vm_stat gives pages, multiply by page size
page_size=$(vm_stat | head -1 | grep -oE '[0-9]+')
pages_free=$(vm_stat | awk '/Pages free:/ {gsub(/\./,"",$3); print $3}')
pages_active=$(vm_stat | awk '/Pages active:/ {gsub(/\./,"",$3); print $3}')
pages_inactive=$(vm_stat | awk '/Pages inactive:/ {gsub(/\./,"",$3); print $3}')
pages_speculative=$(vm_stat | awk '/Pages speculative:/ {gsub(/\./,"",$3); print $3}')
pages_wired=$(vm_stat | awk '/Pages wired down:/ {gsub(/\./,"",$4); print $4}')
pages_compressed=$(vm_stat | awk '/Pages stored in compressor:/ {gsub(/\./,"",$5); print $5}')

mem_total_bytes=$(sysctl -n hw.memsize)
mem_used_pages=$((pages_active + pages_wired + pages_compressed))
mem_used_bytes=$((mem_used_pages * page_size))
mem_available_bytes=$(( (pages_free + pages_inactive + pages_speculative) * page_size ))

mem_total_gb=$(echo "scale=1; $mem_total_bytes / 1073741824" | bc)
mem_used_gb=$(echo "scale=1; $mem_used_bytes / 1073741824" | bc)
mem_available_gb=$(echo "scale=1; $mem_available_bytes / 1073741824" | bc)
mem_percent=$(echo "scale=1; $mem_used_bytes * 100 / $mem_total_bytes" | bc)

# Disk — root volume
disk_line=$(df -k / | tail -1)
disk_total_kb=$(echo "$disk_line" | awk '{print $2}')
disk_used_kb=$(echo "$disk_line" | awk '{print $3}')
disk_available_kb=$(echo "$disk_line" | awk '{print $4}')
disk_percent=$(echo "$disk_line" | awk '{gsub(/%/,"",$5); print $5}')

disk_total_gb=$(echo "scale=1; $disk_total_kb / 1048576" | bc)
disk_used_gb=$(echo "scale=1; $disk_used_kb / 1048576" | bc)
disk_available_gb=$(echo "scale=1; $disk_available_kb / 1048576" | bc)

# GPU — Apple Silicon integrated (static info; utilization requires sudo powermetrics)
gpu_cores=60

# Write atomically via temp file
cat > "$TMP_OUTPUT" << ENDJSON
{
  "timestamp": "$timestamp",
  "cpu": {
    "load_1m": $load1,
    "load_5m": $load5,
    "load_15m": $load15,
    "cores": $cpu_cores
  },
  "memory": {
    "total_gb": $mem_total_gb,
    "used_gb": $mem_used_gb,
    "available_gb": $mem_available_gb,
    "percent_used": $mem_percent
  },
  "disk": {
    "total_gb": $disk_total_gb,
    "used_gb": $disk_used_gb,
    "available_gb": $disk_available_gb,
    "percent_used": $disk_percent
  },
  "gpu": {
    "model": "Apple M3 Ultra",
    "cores": $gpu_cores,
    "utilization_percent": null
  }
}
ENDJSON

mv "$TMP_OUTPUT" "$OUTPUT"
