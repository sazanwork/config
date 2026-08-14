# План A — собрать и опубликовать `@mikitasazan/config` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Собрать публичный npm-пакет `@mikitasazan/config` (Biome + ESLint + tsconfig в форме «база + пресеты») и опубликовать `v1.0.0` через GitHub Actions по тегу.

**Architecture:** Один репозиторий-пакет с конфигами-файлами, отдаваемыми через `exports`. Самопроверка — дымовой тест: запускаем Biome/ESLint/tsc на фикстурах и проверяем, что нужное правило срабатывает (а в чистой фикстуре — молчит). Публикация автоматическая по git-тегу.

**Tech Stack:** Node 22, Biome 2.4.x, ESLint 9 (flat config), TypeScript 5.9, GitHub Actions.

**Спека:** `docs/specs/2026-06-13-shared-config-package.md`

**Объём:** Это План A. Миграция потребителей — отдельный План B, он зависит от первой публикации из этого плана.

---

### Task 1: Каркас репозитория пакета

**Files:**
- Create: `package.json`
- Create: `.gitignore`
- Create: `README.md`

- [ ] **Step 1: Инициализировать git и каркас**

Папка `~/Development/Projects/config` уже существует (в ней лежит `docs/`). Выполнить в корне пакета:

```bash
cd ~/Development/Projects/config
git init
```

- [ ] **Step 2: Создать `package.json`**

```json
{
  "name": "@mikitasazan/config",
  "version": "0.0.0",
  "description": "Shared Biome, ESLint and tsconfig presets for all projects",
  "type": "module",
  "license": "MIT",
  "publishConfig": {
    "access": "public"
  },
  "engines": {
    "node": ">=20"
  },
  "files": [
    "biome",
    "eslint",
    "tsconfig"
  ],
  "exports": {
    "./biome": "./biome/base.json",
    "./biome-react": "./biome/react.json",
    "./biome-astro": "./biome/astro.json",
    "./eslint": "./eslint/base.mjs",
    "./eslint-strict": "./eslint/strict.mjs",
    "./tsconfig.json": "./tsconfig/base.json"
  },
  "scripts": {
    "test": "bash test/smoke.sh"
  },
  "devDependencies": {
    "@biomejs/biome": "2.4.15",
    "eslint": "^9.0.0",
    "typescript": "^5.9.0"
  }
}
```

Версия `0.0.0` намеренно: реальная версия `1.0.0` проставляется в Task 9 перед публикацией.

- [ ] **Step 3: Создать `.gitignore`**

```gitignore
node_modules/
*.log
test/.tmp/
```

- [ ] **Step 4: Создать `README.md`**

````markdown
# @mikitasazan/config

Общие конфиги Biome, ESLint и TypeScript для всех проектов. Форма «база + пресеты».

## Установка

```bash
npm install -D @mikitasazan/config
```

## Использование

Biome (`biome.json`):

```jsonc
// бэкенд / любой не-фронтовый проект
{ "extends": ["@mikitasazan/config/biome"] }

// React / React Native / Next
{ "extends": ["@mikitasazan/config/biome", "@mikitasazan/config/biome-react"] }

// Astro
{ "extends": ["@mikitasazan/config/biome", "@mikitasazan/config/biome-astro"] }
```

ESLint (`eslint.config.mjs`):

```js
import { basePaddingRules } from '@mikitasazan/config/eslint';
// или строгий супер-набор:
import { strictPaddingRules } from '@mikitasazan/config/eslint-strict';

export default [{ rules: basePaddingRules }];
```

TypeScript (`tsconfig.json`):

```jsonc
{ "extends": "@mikitasazan/config/tsconfig.json" }
```

База строгая (`strict: true`); проект, не готовый к строгости, ослабляет нужные
флаги у себя.
````

- [ ] **Step 5: Установить зависимости и закоммитить каркас**

```bash
cd ~/Development/Projects/config
npm install
git add package.json package-lock.json .gitignore README.md docs/
git commit -m "chore: scaffold @mikitasazan/config package"
```

Ожидание: `npm install` создаёт `node_modules/` и `package-lock.json` без ошибок.

---

### Task 2: Biome база (`biome/base.json`)

База — это `biome.shared.json` без правил React/JSX. Правила, уезжающие в react-пресет: `useExhaustiveDependencies`, `useHookAtTopLevel`, `useJsxKeyInIterable`, `noArrayIndexKey`, `useSelfClosingElements`, `useFragmentSyntax`.

**Files:**
- Create: `biome/base.json`
- Create: `test/fixtures/biome-base/biome.json`
- Create: `test/fixtures/biome-base/bad.ts`
- Create: `test/fixtures/biome-base/good.ts`

- [ ] **Step 1: Написать падающий тест (фикстуры + ручной прогон)**

Создать `test/fixtures/biome-base/biome.json` (расширяет базу относительным путём — мы внутри пакета):

```json
{
  "extends": ["../../../biome/base.json"]
}
```

Создать `test/fixtures/biome-base/bad.ts` (нарушает базовое правило `noVar`):

```ts
var x = 1;
export const y = x;
```

Создать `test/fixtures/biome-base/good.ts` (чисто):

```ts
export const y = 1;
```

- [ ] **Step 2: Прогнать и убедиться, что тест падает (база ещё не создана)**

Run:
```bash
cd ~/Development/Projects/config
./node_modules/.bin/biome check test/fixtures/biome-base/bad.ts
```
Expected: ошибка вида «Cannot find the file `../../../biome/base.json`» — базы ещё нет.

- [ ] **Step 3: Создать `biome/base.json`**

```json
{
  "$schema": "https://biomejs.dev/schemas/2.4.15/schema.json",
  "files": {
    "includes": [
      "**/*.{astro,js,jsx,ts,tsx,json,jsonc,css,md,mdx,yaml,yml}",
      "!**/node_modules",
      "!**/dist",
      "!**/build",
      "!**/coverage",
      "!**/.reassure",
      "!**/.next",
      "!**/.turbo",
      "!**/.worktrees"
    ],
    "ignoreUnknown": false
  },
  "vcs": {
    "enabled": true,
    "clientKind": "git",
    "useIgnoreFile": true
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100,
    "lineEnding": "lf",
    "bracketSpacing": true
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "single",
      "jsxQuoteStyle": "single",
      "trailingCommas": "none",
      "semicolons": "always",
      "arrowParentheses": "always",
      "bracketSpacing": true
    },
    "globals": [
      "__DEV__",
      "jest",
      "describe",
      "it",
      "test",
      "expect",
      "beforeEach",
      "afterEach",
      "beforeAll",
      "afterAll"
    ]
  },
  "json": {
    "formatter": {
      "enabled": true,
      "expand": "auto",
      "bracketSpacing": true,
      "lineEnding": "lf",
      "trailingCommas": "none",
      "indentStyle": "space",
      "indentWidth": 2,
      "lineWidth": 100
    }
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "correctness": {
        "noUnusedVariables": "error",
        "noUnusedImports": "error",
        "noUndeclaredVariables": "error",
        "noUnreachable": "error"
      },
      "suspicious": {
        "noConsole": {
          "level": "warn",
          "options": { "allow": ["error", "warn"] }
        },
        "noExplicitAny": "error",
        "noRedundantUseStrict": "error",
        "noShadowRestrictedNames": "error",
        "noDebugger": "error",
        "noVar": "error"
      },
      "style": {
        "useConst": "error",
        "useTemplate": "error",
        "noParameterAssign": "error",
        "useAsConstAssertion": "error",
        "useDefaultParameterLast": "error",
        "useEnumInitializers": "error",
        "useSingleVarDeclarator": "error",
        "noUnusedTemplateLiteral": "error",
        "useNumberNamespace": "error",
        "noInferrableTypes": "error",
        "noUselessElse": "error",
        "useLiteralEnumMembers": "error",
        "useShorthandAssign": "error",
        "useBlockStatements": "error"
      },
      "performance": { "noDelete": "error" }
    }
  }
}
```

- [ ] **Step 4: Прогнать и убедиться, что правило срабатывает на bad, молчит на good**

Run:
```bash
cd ~/Development/Projects/config
./node_modules/.bin/biome check test/fixtures/biome-base/bad.ts; echo "exit=$?"
./node_modules/.bin/biome check test/fixtures/biome-base/good.ts; echo "exit=$?"
```
Expected: на `bad.ts` — ненулевой exit и упоминание `noVar`; на `good.ts` — `exit=0`.

- [ ] **Step 5: Коммит**

```bash
git add biome/base.json test/fixtures/biome-base/
git commit -m "feat: add framework-agnostic Biome base config"
```

---

### Task 3: Biome react-пресет (`biome/react.json`)

**Files:**
- Create: `biome/react.json`
- Create: `test/fixtures/biome-react/biome.json`
- Create: `test/fixtures/biome-react/Comp.tsx`

- [ ] **Step 1: Написать падающий тест**

Создать `test/fixtures/biome-react/biome.json` (база + react):

```json
{
  "extends": ["../../../biome/base.json", "../../../biome/react.json"]
}
```

Создать `test/fixtures/biome-react/Comp.tsx` (нарушает `useFragmentSyntax` — длинная форма фрагмента вместо `<>`):

```tsx
export const Comp = () => {
  return <React.Fragment>hi</React.Fragment>;
};
```

- [ ] **Step 2: Убедиться, что БАЗА одна это правило НЕ ловит**

Run:
```bash
cd ~/Development/Projects/config
./node_modules/.bin/biome check --config-path test/fixtures/biome-base test/fixtures/biome-react/Comp.tsx; echo "exit=$?"
```
Expected: правило `useFragmentSyntax` НЕ упомянуто (база его не включает; это и доказывает, что оно действительно живёт только в пресете).

- [ ] **Step 3: Создать `biome/react.json`**

Пресет НЕ переобъявляет `recommended` — только добавляет правила React/JSX.

```json
{
  "$schema": "https://biomejs.dev/schemas/2.4.15/schema.json",
  "linter": {
    "rules": {
      "correctness": {
        "useExhaustiveDependencies": "error",
        "useHookAtTopLevel": "error",
        "useJsxKeyInIterable": "error"
      },
      "suspicious": {
        "noArrayIndexKey": "warn"
      },
      "style": {
        "useSelfClosingElements": "error",
        "useFragmentSyntax": "error"
      }
    }
  }
}
```

- [ ] **Step 4: Прогнать и убедиться, что база+react ловит правило**

Run:
```bash
cd ~/Development/Projects/config
./node_modules/.bin/biome check test/fixtures/biome-react/Comp.tsx; echo "exit=$?"
```
Expected: ненулевой exit и упоминание `useFragmentSyntax` — пресет добавил правило поверх базы.

- [ ] **Step 5: Коммит**

```bash
git add biome/react.json test/fixtures/biome-react/
git commit -m "feat: add Biome react preset"
```

---

### Task 4: Biome astro-пресет (`biome/astro.json`)

Пресет = только `overrides`-блок: для `.astro` отключаем `noUnusedVariables`/`noUnusedImports` (в Astro frontmatter импорты, используемые в шаблоне, выглядят неиспользуемыми, потому что Biome шаблон не видит).

**Files:**
- Create: `biome/astro.json`
- Create: `test/fixtures/biome-astro/biome.json`
- Create: `test/fixtures/biome-astro/Page.astro`

- [ ] **Step 1: Написать тест**

Создать `test/fixtures/biome-astro/biome.json`:

```json
{
  "extends": ["../../../biome/base.json", "../../../biome/astro.json"]
}
```

Создать `test/fixtures/biome-astro/Page.astro` (импорт «используется» только в шаблоне):

```astro
---
import Button from './Button.astro';
---
<Button />
```

- [ ] **Step 2: Убедиться, что БАЗА одна ругается на «неиспользуемый» импорт**

Run:
```bash
cd ~/Development/Projects/config
./node_modules/.bin/biome check --config-path test/fixtures/biome-base test/fixtures/biome-astro/Page.astro; echo "exit=$?"
```
Expected: упоминание `noUnusedImports` (база видит только frontmatter и считает импорт лишним) — это и есть проблема, которую чинит пресет.

- [ ] **Step 3: Создать `biome/astro.json`**

```json
{
  "$schema": "https://biomejs.dev/schemas/2.4.15/schema.json",
  "overrides": [
    {
      "includes": ["**/*.astro"],
      "linter": {
        "rules": {
          "correctness": {
            "noUnusedVariables": "off",
            "noUnusedImports": "off"
          }
        }
      }
    }
  ]
}
```

- [ ] **Step 4: Прогнать и убедиться, что база+astro молчит на `.astro`**

Run:
```bash
cd ~/Development/Projects/config
./node_modules/.bin/biome check test/fixtures/biome-astro/Page.astro; echo "exit=$?"
```
Expected: `noUnusedImports` больше НЕ упомянут для `.astro` (override отключил его).

- [ ] **Step 5: Коммит**

```bash
git add biome/astro.json test/fixtures/biome-astro/
git commit -m "feat: add Biome astro preset"
```

---

### Task 5: ESLint base + strict (`eslint/base.mjs`, `eslint/strict.mjs`)

Содержимое переносится 1-в-1 из текущих `~/Development/Projects/eslint.base.mjs` и `eslint.strict.mjs` (это рабочие, проверенные правила отступов).

**Files:**
- Create: `eslint/base.mjs`
- Create: `eslint/strict.mjs`
- Create: `test/fixtures/eslint/eslint.config.mjs`
- Create: `test/fixtures/eslint/bad.js`

- [ ] **Step 1: Написать падающий тест**

Создать `test/fixtures/eslint/eslint.config.mjs` (использует базовые правила из пакета):

```js
import { basePaddingRules } from '../../../eslint/base.mjs';

export default [
  {
    files: ['**/*.js'],
    rules: basePaddingRules
  }
];
```

Создать `test/fixtures/eslint/bad.js` (нет пустой строки перед `return` — нарушает `padding-line-between-statements`):

```js
export function f() {
  const a = 1;
  return a;
}
```

- [ ] **Step 2: Прогнать — падает, потому что `eslint/base.mjs` ещё нет**

Run:
```bash
cd ~/Development/Projects/config
./node_modules/.bin/eslint -c test/fixtures/eslint/eslint.config.mjs test/fixtures/eslint/bad.js; echo "exit=$?"
```
Expected: ошибка резолва модуля `../../../eslint/base.mjs` (файла ещё нет).

- [ ] **Step 3: Создать `eslint/base.mjs`**

```js
// Shared ESLint padding-line rules for all unified projects.

export const basePaddingRules = {
  'padding-line-between-statements': [
    'error',
    { blankLine: 'always', prev: '*', next: 'return' },
    { blankLine: 'always', prev: '*', next: 'continue' },
    { blankLine: 'always', prev: '*', next: 'break' },
    { blankLine: 'always', prev: ['const', 'let', 'var'], next: '*' },
    { blankLine: 'any', prev: ['const', 'let', 'var'], next: ['const', 'let', 'var'] },
    { blankLine: 'always', prev: 'if', next: '*' }
  ]
};

export default basePaddingRules;
```

- [ ] **Step 4: Создать `eslint/strict.mjs`**

```js
// Shared ESLint strict padding-line rules + brace-style.
// Superset of eslint/base.mjs.

import { basePaddingRules } from './base.mjs';

const basePadding = basePaddingRules['padding-line-between-statements'];

export const strictPaddingRules = {
  'padding-line-between-statements': [
    ...basePadding,
    { blankLine: 'always', prev: '*', next: 'if' },
    { blankLine: 'always', prev: '*', next: 'for' },
    { blankLine: 'always', prev: 'for', next: '*' }
  ],
  'brace-style': ['error', '1tbs', { allowSingleLine: false }]
};

export default strictPaddingRules;
```

- [ ] **Step 5: Прогнать — правило срабатывает**

Run:
```bash
cd ~/Development/Projects/config
./node_modules/.bin/eslint -c test/fixtures/eslint/eslint.config.mjs test/fixtures/eslint/bad.js; echo "exit=$?"
```
Expected: ненулевой exit и `padding-line-between-statements` в выводе.

- [ ] **Step 6: Коммит**

```bash
git add eslint/ test/fixtures/eslint/
git commit -m "feat: add shared ESLint base and strict padding rules"
```

---

### Task 6: tsconfig строгая база (`tsconfig/base.json`)

База — только флаги строгости проверки типов, без `module`/`target`/`lib` (их задаёт проект).

**Files:**
- Create: `tsconfig/base.json`
- Create: `test/fixtures/tsconfig/tsconfig.json`
- Create: `test/fixtures/tsconfig/bad.ts`

- [ ] **Step 1: Написать падающий тест**

Создать `test/fixtures/tsconfig/tsconfig.json` (наследует базу, добавляет module/target, чтобы tsc запустился):

```json
{
  "extends": "../../../tsconfig/base.json",
  "compilerOptions": {
    "module": "esnext",
    "target": "es2022",
    "moduleResolution": "bundler",
    "noEmit": true
  },
  "include": ["bad.ts"]
}
```

Создать `test/fixtures/tsconfig/bad.ts` (ошибка, которую ловит строгий режим — неявный `any` параметра):

```ts
export function f(x) {
  return x + 1;
}
```

- [ ] **Step 2: Прогнать — падает, базы ещё нет**

Run:
```bash
cd ~/Development/Projects/config
./node_modules/.bin/tsc -p test/fixtures/tsconfig/tsconfig.json; echo "exit=$?"
```
Expected: ошибка про отсутствующий `../../../tsconfig/base.json`.

- [ ] **Step 3: Создать `tsconfig/base.json`**

```json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true,
    "esModuleInterop": true,
    "resolveJsonModule": true,
    "skipLibCheck": true
  }
}
```

- [ ] **Step 4: Прогнать — строгая база ловит неявный any**

Run:
```bash
cd ~/Development/Projects/config
./node_modules/.bin/tsc -p test/fixtures/tsconfig/tsconfig.json; echo "exit=$?"
```
Expected: ненулевой exit и ошибка `TS7006` (Parameter 'x' implicitly has an 'any' type) — `strict` базы работает.

- [ ] **Step 5: Коммит**

```bash
git add tsconfig/base.json test/fixtures/tsconfig/
git commit -m "feat: add strict TypeScript base config"
```

---

### Task 7: Собрать дымовой тест в один скрипт (`test/smoke.sh`)

Объединяем все проверки в `npm test`, чтобы CI прогонял их перед публикацией.

**Files:**
- Create: `test/smoke.sh`

- [ ] **Step 1: Создать `test/smoke.sh`**

```bash
#!/usr/bin/env bash
# Дымовой тест: каждый конфиг грузится и нужное правило срабатывает.
set -uo pipefail
cd "$(dirname "$0")/.."

BIOME=./node_modules/.bin/biome
ESLINT=./node_modules/.bin/eslint
TSC=./node_modules/.bin/tsc
fail=0

check_contains() { # desc, expected_substr, output
  if echo "$3" | grep -q "$2"; then
    echo "  OK: $1"
  else
    echo "  FAIL: $1 (ожидалось '$2')"; fail=1
  fi
}
check_clean() { # desc, exit_code
  if [ "$2" -eq 0 ]; then echo "  OK: $1"; else echo "  FAIL: $1 (exit=$2)"; fail=1; fi
}

echo "[biome base] bad.ts должен ловить noVar"
out=$($BIOME check test/fixtures/biome-base/bad.ts 2>&1); check_contains "noVar fires" "noVar" "$out"

echo "[biome base] good.ts должен быть чист"
$BIOME check test/fixtures/biome-base/good.ts >/dev/null 2>&1; check_clean "good.ts clean" $?

echo "[biome react] база+react ловит useFragmentSyntax"
out=$($BIOME check test/fixtures/biome-react/Comp.tsx 2>&1); check_contains "react preset adds rule" "useFragmentSyntax" "$out"

echo "[biome astro] база+astro молчит на .astro импорте"
$BIOME check test/fixtures/biome-astro/Page.astro >/dev/null 2>&1; check_clean "astro override silences unused import" $?

echo "[eslint base] bad.js ловит padding-line"
out=$($ESLINT -c test/fixtures/eslint/eslint.config.mjs test/fixtures/eslint/bad.js 2>&1); check_contains "padding rule fires" "padding-line-between-statements" "$out"

echo "[tsconfig] строгая база ловит implicit any"
out=$($TSC -p test/fixtures/tsconfig/tsconfig.json 2>&1); check_contains "strict catches implicit any" "TS7006" "$out"

if [ "$fail" -ne 0 ]; then echo "SMOKE TEST FAILED"; exit 1; fi
echo "SMOKE TEST PASSED"
```

- [ ] **Step 2: Сделать исполняемым и прогнать**

Run:
```bash
cd ~/Development/Projects/config
chmod +x test/smoke.sh
npm test
```
Expected: вывод заканчивается `SMOKE TEST PASSED`, exit 0.

- [ ] **Step 3: Коммит**

```bash
git add test/smoke.sh package.json
git commit -m "test: add smoke test runner for all configs"
```

---

### Task 8: GitHub Actions — публикация по тегу

**Files:**
- Create: `.github/workflows/publish.yml`

- [ ] **Step 1: Создать `.github/workflows/publish.yml`**

```yaml
name: Publish

on:
  push:
    tags:
      - 'v*'

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          registry-url: 'https://registry.npmjs.org'
      - run: npm ci
      - run: npm test
      - run: npm publish
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

`--access public` не нужен в команде — он задан через `publishConfig.access` в `package.json`. Провенанс (`--provenance`) намеренно НЕ включаем в первой версии, чтобы избежать настройки прав `id-token` на первой публикации; добавим позже при желании.

- [ ] **Step 2: Коммит**

```bash
git add .github/workflows/publish.yml
git commit -m "ci: publish to npm on version tag"
```

---

### Task 9: Первая публикация `v1.0.0` (Шаг 0 для Плана B)

Здесь есть ручные действия пользователя — они помечены **[ПОЛЬЗОВАТЕЛЬ]**.

- [ ] **Step 1: [ПОЛЬЗОВАТЕЛЬ] Аккаунт npm**

Завести/войти в аккаунт на npmjs.com под именем `mikitasazan`:
```bash
npm adduser
```
Затем создать **Automation**-токен (Access Tokens → Generate New Token → Automation) — он не требует одноразового кода при публикации из CI.

- [ ] **Step 2: [ПОЛЬЗОВАТЕЛЬ] Создать GitHub-репозиторий и положить секрет**

Создать публичный репозиторий `github.com/sazanwork/config`, затем:
```bash
cd ~/Development/Projects/config
git remote add origin https://github.com/sazanwork/config.git
git push -u origin master
```
В настройках репозитория: Settings → Secrets and variables → Actions → New secret → имя `NPM_TOKEN`, значение — Automation-токен из Step 1.

- [ ] **Step 3: Проставить версию 1.0.0 и закоммитить**

```bash
cd ~/Development/Projects/config
npm version 1.0.0 --no-git-tag-version
git add package.json package-lock.json
git commit -m "chore: release v1.0.0"
git push
```

- [ ] **Step 4: Поставить тег и запушить — это запускает публикацию**

```bash
cd ~/Development/Projects/config
git tag v1.0.0
git push origin v1.0.0
```
Expected: во вкладке Actions репозитория проходит workflow `Publish`, шаг `npm test` зелёный, `npm publish` успешен.

- [ ] **Step 5: Проверить, что пакет реально опубликован (гейт для Плана B)**

Run:
```bash
npm view @mikitasazan/config version
```
Expected: выводит `1.0.0`. С этого момента потребители могут ставить пакет — План B разблокирован.

---

## Self-Review

**Spec coverage:**
- Структура пакета (спека §3) → Task 1 (package.json/exports) + Task 2–6 (файлы).
- Разделение base/react (§4) → Task 2 (база без react-правил) + Task 3 (react-пресет, не трогает `recommended`).
- Astro-пресет = overrides-блок (§4) → Task 4.
- ESLint base/strict (§3) → Task 5.
- tsconfig строгая база (§2, §4а) → Task 6.
- Дымовой тест (§8) → Task 7.
- Публикация по тегу, Automation-токен, `publishConfig.access` (§7) → Task 8.
- Шаг 0: опубликовать v1.0.0 и проверить резолв (§9) → Task 9.
- Деление на План A / План B (§10) → этот документ = План A; миграция вынесена.

**Placeholder scan:** все шаги содержат реальный код/команды/ожидаемый вывод; заглушек нет.

**Type/имя consistency:** экспорты в `package.json` (`./biome`, `./biome-react`, `./biome-astro`, `./eslint`, `./eslint-strict`, `./tsconfig.json`) совпадают с создаваемыми файлами (`biome/base.json`, `biome/react.json`, `biome/astro.json`, `eslint/base.mjs`, `eslint/strict.mjs`, `tsconfig/base.json`). Имена экспортов `basePaddingRules` / `strictPaddingRules` совпадают между `eslint/base.mjs`, `eslint/strict.mjs` и тестом.

**Не входит в План A (осознанно):** проверка резолва через `npm pack` + установку в потребителя и pnpm-симлинки относится к Плану B (миграция), где это проверяется на реальных проектах; в Плане A резолв конфигов проверяется относительными путями внутри пакета + реальной публикацией в Task 9.
