#!/usr/bin/env bash
# Дымовой тест: каждый конфиг грузится, нужное правило срабатывает,
# и база НЕ протекает React-правилами (страж разделения).
set -uo pipefail
cd "$(dirname "$0")/.."

BIOME=./node_modules/.bin/biome
ESLINT=./node_modules/.bin/eslint
TSC=./node_modules/.bin/tsc
fail=0

contains() { # desc, substr, output
  if echo "$3" | grep -q "$2"; then echo "  OK: $1"; else echo "  FAIL: $1 (ждали '$2')"; fail=1; fi
}
absent() { # desc, substr, output
  if echo "$3" | grep -q "$2"; then echo "  FAIL: $1 ('$2' не должно быть)"; fail=1; else echo "  OK: $1"; fi
}
clean() { # desc, exit
  if [ "$2" -eq 0 ]; then echo "  OK: $1"; else echo "  FAIL: $1 (exit=$2)"; fail=1; fi
}

echo "[biome base] bad.ts ловит noVar"
out=$($BIOME check test/fixtures/biome-base/bad.ts 2>&1); contains "noVar fires" "noVar" "$out"

echo "[biome base] good.ts чист"
$BIOME check test/fixtures/biome-base/good.ts >/dev/null 2>&1; clean "good.ts clean" $?

echo "[split guard] база ОДНА не включает React-правила"
out=$($BIOME check test/fixtures/biome-base-only/frag.tsx 2>&1); absent "base lacks useFragmentSyntax" "useFragmentSyntax" "$out"

echo "[biome react] база+react ловит useFragmentSyntax"
out=$($BIOME check test/fixtures/biome-react/Comp.tsx 2>&1); contains "react preset adds rule" "useFragmentSyntax" "$out"

echo "[biome astro] база+astro молчит на .astro импорте"
$BIOME check test/fixtures/biome-astro/Page.astro >/dev/null 2>&1; clean "astro override silences unused import" $?

echo "[eslint base] bad.js ловит padding-line"
out=$($ESLINT -c test/fixtures/eslint/eslint.config.mjs test/fixtures/eslint/bad.js 2>&1); contains "padding rule fires" "padding-line-between-statements" "$out"

echo "[tsconfig] строгая база ловит implicit any"
out=$($TSC -p test/fixtures/tsconfig/tsconfig.json 2>&1); contains "strict catches implicit any" "TS7006" "$out"

if [ "$fail" -ne 0 ]; then echo "SMOKE TEST FAILED"; exit 1; fi
echo "SMOKE TEST PASSED"
