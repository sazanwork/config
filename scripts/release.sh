#!/usr/bin/env bash
# Release ritual (npm-registry mechanism): test → bump+tag → push → publish →
# show consumer drift.
#
# Auth: a granular access token with "bypass 2FA", kept in vault as
# npm.NPM_TOKEN. An interactive `npm login` is NOT enough — npmjs requires 2FA
# or such a token to publish, and the web session expires within the hour.
# The token is written to a temp userconfig (mode 600, removed on exit) so it
# never reaches the process list, the repo, or ~/.npmrc.
set -euo pipefail
cd "$(dirname "$0")/.."

BUMP="${1:?usage: release.sh patch|minor|major}"
[ -z "$(git status --porcelain)" ] || { echo "X dirty working tree — commit or stash first" >&2; exit 1; }

npm test
npm version "$BUMP"
git push
git push --tags

NPMRC=$(mktemp "${TMPDIR:-/tmp}/npmrc.XXXXXX")
chmod 600 "$NPMRC"
trap 'rm -f "$NPMRC"' EXIT
printf '//registry.npmjs.org/:_authToken=%s\n' "$(vault get npm.NPM_TOKEN)" > "$NPMRC"
NPM_CONFIG_USERCONFIG="$NPMRC" npm publish

node scripts/consumers-check.mjs || true
echo "Consumers update with: npm update @mikitasazan/config  (pnpm update in one-q)"
