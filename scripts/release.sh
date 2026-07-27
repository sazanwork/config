#!/usr/bin/env bash
# Release ritual (npm-registry mechanism): test → bump+tag → push → publish →
# show consumer drift. Publish token comes from `npm login` / vault, never the repo.
set -euo pipefail
cd "$(dirname "$0")/.."

BUMP="${1:?usage: release.sh patch|minor|major}"
[ -z "$(git status --porcelain)" ] || { echo "X dirty working tree — commit or stash first" >&2; exit 1; }

npm test
npm version "$BUMP"
git push
git push --tags
npm publish

node scripts/consumers-check.mjs || true
echo "Consumers update with: npm update @mikitasazan/config  (pnpm update in one-q)"
