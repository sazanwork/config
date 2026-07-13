#!/usr/bin/env bash
# Интеграционный тест: ставим пакет в НАСТОЯЩЕГО потребителя (через npm pack +
# install, как в жизни) и проверяем два несущих свойства:
#   1) резолв конфига по ИМЕНИ пакета (@mikitasazan/config/biome)
#   2) распространение форматтера базы через extends (двойные -> одинарные + ;)
# Именно это нельзя проверить внутри репо (там фикстуры с root:false).
set -uo pipefail
cd "$(dirname "$0")/.."
ROOT=$(pwd)
fail=0

echo "[integration] собираю tarball и ставлю в учебного потребителя..."
TGZ=$(npm pack --silent | tail -1)
CONS=$(mktemp -d)
mv "$TGZ" "$CONS/pkg.tgz"
cd "$CONS"
git init -q; printf 'node_modules/\n' > .gitignore
echo '{"name":"consumer","version":"1.0.0","private":true}' > package.json
echo '{ "extends": ["@mikitasazan/config/biome"] }' > biome.json
printf 'var greeting = "hello"\nexport const out = greeting\n' > f.ts

if ! npm install -D ./pkg.tgz @biomejs/biome@2.4.15 --silent --no-audit --no-fund >/dev/null 2>&1; then
  echo "  FAIL: npm install потребителя упал"; cd "$ROOT"; rm -rf "$CONS"; exit 1
fi

echo "[integration] резолв по имени пакета + линтер базы (noVar)"
out=$(./node_modules/.bin/biome check f.ts 2>&1 || true)
if echo "$out" | grep -q noVar; then echo "  OK: '@mikitasazan/config/biome' резолвится, noVar сработал"; else echo "  FAIL: резолв/линтер"; echo "$out"; fail=1; fi

echo "[integration] форматтер базы передаётся через extends"
fmt=$(./node_modules/.bin/biome format f.ts 2>&1 || true)
if echo "$fmt" | grep -q "'hello';"; then echo "  OK: двойные кавычки -> одинарные + ; (форматтер пришёл из базы)"; else echo "  FAIL: форматтер не передался"; echo "$fmt"; fail=1; fi

cd "$ROOT"; rm -rf "$CONS"

# 3) bin/init-hooks: пишет хук туда, откуда git РЕАЛЬНО их читает (core.hooksPath).
# Регрессия: раньше бин жёстко писал в .husky/. В репозитории с core.hooksPath=.githooks
# (git-guards: защита master + commit-msg) husky перебивал hooksPath, и эти хуки
# молча переставали работать — линтер при этом продолжал жить, поэтому поломку не видно.
echo "[integration] bin уважает core.hooksPath (не навязывает husky)"
H=$(mktemp -d); cd "$H"
git init -q; git config core.hooksPath .githooks; mkdir -p .githooks
printf '#!/bin/sh\nexit 0\n' > .githooks/pre-push; chmod +x .githooks/pre-push
echo '{"name":"h","private":true}' > package.json
node "$ROOT/bin/init-hooks.mjs" >/dev/null 2>&1
if [ -f .githooks/pre-commit ] && [ ! -d .husky ] && [ -f .githooks/pre-push ]; then
  echo "  OK: хук лёг в .githooks, .husky не создан, защита pre-push цела"
else
  echo "  FAIL: бин не уважает core.hooksPath"; fail=1
fi

echo "[integration] bin без core.hooksPath ведёт себя как раньше (.husky)"
H2=$(mktemp -d); cd "$H2"
git init -q; echo '{"name":"h2","private":true}' > package.json
node "$ROOT/bin/init-hooks.mjs" >/dev/null 2>&1
if [ -f .husky/pre-commit ]; then
  echo "  OK: поведение по умолчанию не изменилось"
else
  echo "  FAIL: сломано поведение по умолчанию"; fail=1
fi

cd "$ROOT"; rm -rf "$H" "$H2"
if [ "$fail" -ne 0 ]; then echo "INTEGRATION TEST FAILED"; exit 1; fi
echo "INTEGRATION TEST PASSED"
