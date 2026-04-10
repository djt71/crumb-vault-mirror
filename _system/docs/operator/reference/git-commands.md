---
type: reference
status: active
domain: software
created: 2026-02-14
updated: 2026-03-14
tags:
  - system/operator
---

git add docs/crumb-design-spec-v1-7-1.md docs/separate-version-history.md docs/peer-review-skill-spec.md
git rm docs/peer-review-skill-spec-v2.md
git commit -m "v1.7.1: add new spec files and peer-review skill spec
git push

example flow:

cp ~/Downloads/vault-check.sh scripts/vault-check.sh
chmod +x scripts/vault-check.sh
git add scripts/vault-check.sh
git commit -m "fix: broken pipe in has_frontmatter under pipefail"
git push