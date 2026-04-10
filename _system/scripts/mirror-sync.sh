#!/bin/bash
# mirror-sync.sh — Sync allowlisted vault files to the mirror repo.
# Called by .git/hooks/post-commit. Designed to run in background.
set -eu

VAULT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CONFIG_FILE="$VAULT_ROOT/_system/docs/mirror-config.yaml"

# --- Parse config (simple grep-based, no yq dependency) ---
parse_yaml() {
  local key="$1"
  grep "^${key}:" "$CONFIG_FILE" | sed "s/^${key}: *//" | sed 's/ *$//'
}

MIRROR_PATH="$(eval echo "$(parse_yaml mirror_repo_path)")"
MIRROR_REMOTE="$(parse_yaml mirror_remote)"
MIRROR_BRANCH="$(parse_yaml mirror_branch)"
LOG_FILE="$VAULT_ROOT/$(parse_yaml log_file)"

# --- Guard: mirror repo must exist ---
if [ ! -d "$MIRROR_PATH/.git" ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') SKIP mirror repo not found at $MIRROR_PATH" >> "$LOG_FILE"
  exit 0
fi

# --- Check if any allowlisted paths changed in the last commit ---
CHANGED_FILES="$(git -C "$VAULT_ROOT" diff-tree --no-commit-id --name-only -r HEAD)"

ALLOWLIST_PATTERNS=(
  "^_system/docs/"
  "^_system/scripts/"
  "^_system/schemas/"
  "^_system/reviews/"
  "^_system/logs/"
  "^\.claude/skills/"
  "^CLAUDE\.md$"
  "^AGENTS\.md$"
  "^Projects/[^/]+/[^/]+\.md$"
  "^Projects/[^/]+/design/"
  "^Projects/[^/]+/progress/"
  "^Projects/[^/]+/src/"
  "^Projects/[^/]+/reviews/"
  "^Projects/[^/]+/project-state\.yaml$"
  "^Projects/index\.md$"
  "^Archived/Projects/[^/]+/[^/]+\.md$"
  "^Archived/Projects/[^/]+/design/"
  "^Archived/Projects/[^/]+/progress/"
  "^Archived/Projects/[^/]+/src/"
  "^Archived/Projects/[^/]+/reviews/"
  "^Archived/Projects/[^/]+/project-state\.yaml$"
  "^_openclaw/scripts/"
  "^\.claude/agents/"
  "^_attachments/.*\.md$"
)

DENYLIST_PATTERNS=(
  "^Projects/customer-intelligence/"
  "^_system/reviews/raw/"
  "^_system/docs/personal-context\.md$"
  "^Projects/[^/]+/reviews/raw/"
  "^Archived/Projects/[^/]+/reviews/raw/"
  "^\.claude/settings"
  "\.env"
)

has_allowed_change=false
while IFS= read -r file; do
  [ -z "$file" ] && continue

  # Check denylist first
  denied=false
  for pattern in "${DENYLIST_PATTERNS[@]}"; do
    if echo "$file" | grep -qE "$pattern"; then
      denied=true
      break
    fi
  done
  $denied && continue

  # Check allowlist
  for pattern in "${ALLOWLIST_PATTERNS[@]}"; do
    if echo "$file" | grep -qE "$pattern"; then
      has_allowed_change=true
      break 2
    fi
  done
done <<< "$CHANGED_FILES"

if ! $has_allowed_change; then
  exit 0
fi

# --- Sync: rsync allowlisted paths to mirror ---
COMMIT_MSG="$(git -C "$VAULT_ROOT" log -1 --format='%s')"

# Build rsync include/exclude rules.
# Strategy: include allowlisted dirs, exclude everything else.
# rsync --delete ensures removals propagate.
RSYNC_RULES=(
  # Denylist — must come before allowlist includes
  --exclude='Projects/customer-intelligence/'
  --exclude='_system/reviews/raw/'
  --exclude='Projects/*/reviews/raw/'
  --exclude='.claude/settings.json'
  --exclude='.claude/settings.local.json'
  --exclude='.env*'
  --exclude='session-log*.md'
  --exclude='.DS_Store'
  --exclude='_inbox/'
  --exclude='Domains/'
  --exclude='Sources/'
  --exclude='_system/docs/personal-context.md'
  --exclude='*.pdf'

  # Allowlist includes
  --include='_system/'
  --include='_system/docs/***'
  --include='_system/scripts/***'
  --include='_system/reviews/'
  --include='_system/reviews/*'
  --include='_system/reviews/**'
  --include='_system/schemas/'
  --include='_system/schemas/***'
  --include='_system/logs/***'
  --include='.claude/'
  --include='.claude/skills/'
  --include='.claude/skills/***'
  --include='CLAUDE.md'
  --include='AGENTS.md'
  --include='Projects/'
  --include='Projects/*/'
  --include='Projects/*/*.md'
  --include='Projects/*/design/'
  --include='Projects/*/design/***'
  --include='Projects/*/progress/'
  --include='Projects/*/progress/***'
  --include='Projects/*/src/'
  --include='Projects/*/src/***'
  --include='Projects/*/reviews/'
  --include='Projects/*/reviews/*'
  --include='Projects/*/reviews/**'
  --include='Projects/*/project-state.yaml'
  --include='Projects/index.md'
  --include='Archived/'
  --include='Archived/Projects/'
  --include='Archived/Projects/*/'
  --include='Archived/Projects/*/*.md'
  --include='Archived/Projects/*/design/'
  --include='Archived/Projects/*/design/***'
  --include='Archived/Projects/*/progress/'
  --include='Archived/Projects/*/progress/***'
  --include='Archived/Projects/*/src/'
  --include='Archived/Projects/*/src/***'
  --include='Archived/Projects/*/reviews/'
  --include='Archived/Projects/*/reviews/*'
  --include='Archived/Projects/*/reviews/**'
  --include='Archived/Projects/*/project-state.yaml'
  --include='Archived/Projects/*/templates/'
  --include='Archived/Projects/*/templates/***'
  --include='Archived/Projects/*/fixtures/'
  --include='Archived/Projects/*/fixtures/***'
  --include='_openclaw/'
  --include='_openclaw/scripts/'
  --include='_openclaw/scripts/***'
  --include='.claude/agents/'
  --include='.claude/agents/***'
  --include='_attachments/'
  --include='_attachments/**/'
  --include='_attachments/**/*.md'
  --exclude='_attachments/**'

  # Exclude everything else
  --exclude='*'
)

rsync -a --delete "${RSYNC_RULES[@]}" "$VAULT_ROOT/" "$MIRROR_PATH/"

# Clean up OS artifacts that rsync --delete won't touch (excluded from transfer)
find "$MIRROR_PATH" -name .DS_Store -delete 2>/dev/null || true

# --- Commit and push mirror ---
cd "$MIRROR_PATH"
git add -A
if git diff --cached --quiet; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') NOOP no effective changes after rsync" >> "$LOG_FILE"
  exit 0
fi

git commit -m "sync: $COMMIT_MSG"
git push "$MIRROR_REMOTE" "$MIRROR_BRANCH" 2>/dev/null

echo "$(date '+%Y-%m-%d %H:%M:%S') SYNC $COMMIT_MSG" >> "$LOG_FILE"
