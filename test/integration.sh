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
if [ "$fail" -ne 0 ]; then echo "INTEGRATION TEST FAILED"; exit 1; fi
echo "INTEGRATION TEST PASSED"
