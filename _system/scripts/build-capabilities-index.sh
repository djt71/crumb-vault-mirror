#!/usr/bin/env bash
# build-capabilities-index.sh — Pre-compute capabilities.json from SKILL.md manifests
#
# Reads all SKILL.md files with `capabilities:` frontmatter and outputs
# a flat JSON index at _openclaw/state/capabilities.json for Tess's
# orchestration layer. Reduces runtime parsing for Haiku.
#
# Output format: array of objects, each with:
#   skill_name, capability_id, brief_schema, produced_artifacts,
#   cost_profile, supported_rigor, required_tools, quality_signals
#
# Usage: ./build-capabilities-index.sh [vault_root]
# Exit 0 = success, exit 1 = error
#
# Project: agent-to-agent-communication (A2A-008)

set -eu

VAULT_ROOT="${1:-$(cd "$(dirname "$0")/../.." && pwd)}"
SKILLS_DIR="$VAULT_ROOT/.claude/skills"
OUTPUT="$VAULT_ROOT/_openclaw/state/capabilities.json"

# Ensure output directory exists
mkdir -p "$(dirname "$OUTPUT")"

# Use python3 to parse YAML frontmatter and emit JSON
python3 -c "
import os, json, sys, re

skills_dir = '$SKILLS_DIR'
capabilities = []

for skill_name in sorted(os.listdir(skills_dir)):
    skill_file = os.path.join(skills_dir, skill_name, 'SKILL.md')
    if not os.path.isfile(skill_file):
        continue

    with open(skill_file) as f:
        content = f.read()

    # Extract frontmatter between --- markers
    parts = content.split('---', 2)
    if len(parts) < 3:
        continue
    frontmatter = parts[1]

    if 'capabilities:' not in frontmatter:
        continue

    # Minimal YAML parser for capabilities block
    # We parse the indented block after 'capabilities:'
    lines = frontmatter.split('\n')
    in_cap = False
    cap_lines = []
    for line in lines:
        if line.strip().startswith('capabilities:'):
            in_cap = True
            continue
        if in_cap:
            # Stop at next top-level key (no leading whitespace)
            if line and not line[0].isspace() and line[0] != '#':
                break
            cap_lines.append(line)

    if not cap_lines:
        continue

    # Parse individual capabilities
    current_cap = None
    current_key = None
    current_list = None

    for line in cap_lines:
        stripped = line.strip()
        if not stripped or stripped.startswith('#'):
            continue

        # New capability entry: '- id: ...'
        m = re.match(r'^  - id:\s*(.+)', line)
        if m:
            if current_cap:
                capabilities.append(current_cap)
            current_cap = {
                'skill_name': skill_name,
                'capability_id': m.group(1).strip().strip('\"').strip(\"'\"),
                'brief_schema': None,
                'produced_artifacts': [],
                'cost_profile': {},
                'supported_rigor': [],
                'required_tools': [],
                'quality_signals': [],
            }
            current_key = None
            current_list = None
            continue

        if current_cap is None:
            continue

        # Top-level capability fields (4-space indent)
        m = re.match(r'^    (\w[\w_]*):\s*(.*)', line)
        if m:
            key = m.group(1)
            val = m.group(2).strip()

            if key == 'brief_schema':
                current_cap['brief_schema'] = val.strip('\"').strip(\"'\") if val and val != 'null' else None
                current_key = None
                current_list = None
            elif key == 'supported_rigor':
                # Inline array: [light, standard, deep]
                if val.startswith('['):
                    items = val.strip('[]').split(',')
                    current_cap['supported_rigor'] = [i.strip().strip('\"').strip(\"'\") for i in items if i.strip()]
                    current_key = None
                    current_list = None
                else:
                    current_key = 'supported_rigor'
                    current_list = []
            elif key == 'required_tools':
                if val.startswith('['):
                    items = val.strip('[]').split(',')
                    current_cap['required_tools'] = [i.strip().strip('\"').strip(\"'\") for i in items if i.strip()]
                    current_key = None
                    current_list = None
                else:
                    current_key = 'required_tools'
                    current_list = []
            elif key == 'quality_signals':
                if val.startswith('['):
                    items = val.strip('[]').split(',')
                    current_cap['quality_signals'] = [i.strip().strip('\"').strip(\"'\") for i in items if i.strip()]
                    current_key = None
                    current_list = None
                else:
                    current_key = 'quality_signals'
                    current_list = []
            elif key == 'produced_artifacts':
                current_key = 'produced_artifacts'
                current_list = []
                if val:
                    current_list.append(val.strip('\"').strip(\"'\"))
            elif key == 'cost_profile':
                current_key = 'cost_profile'
                current_list = None
            else:
                current_key = None
                current_list = None
            continue

        # Cost profile sub-fields (6-space indent)
        m = re.match(r'^      (\w[\w_]*):\s*(.*)', line)
        if m and current_key == 'cost_profile':
            k = m.group(1)
            v = m.group(2).strip().strip('\"').strip(\"'\")
            # Try numeric conversion
            try:
                if '.' in v:
                    v = float(v)
                else:
                    v = int(v)
            except (ValueError, TypeError):
                pass
            current_cap['cost_profile'][k] = v
            continue

        # List items (6-space indent with -)
        m = re.match(r'^      - (.+)', line)
        if m and current_key and current_list is not None:
            val = m.group(1).strip().strip('\"').strip(\"'\")
            current_list.append(val)
            current_cap[current_key] = current_list
            continue

    # Don't forget the last capability
    if current_cap:
        capabilities.append(current_cap)

# Write output
output = {
    'generated_at': __import__('datetime').datetime.now().isoformat(),
    'source': '.claude/skills/*/SKILL.md',
    'capabilities': capabilities,
}
print(json.dumps(output, indent=2))
" > "$OUTPUT"

count=$(python3 -c "import json; d=json.load(open('$OUTPUT')); print(len(d['capabilities']))")
echo "Built capabilities index: $count capabilities → $OUTPUT"
