# Спека: общий пакет конфигов `@mikitasazan/config`

Дата: 2026-06-13
Статус: согласование дизайна (до реализации); обновлено после адверсариального ревью

## 1. Контекст и проблема

Общие настройки линтеров и форматтера (`biome.shared.json`, `eslint.base.mjs`,
`eslint.strict.mjs`) лежали в `~/Development/Projects/` — на уровень выше любого
проекта, и эта папка не под git. Проекты ссылались на них относительным путём
(`extends: ["../biome.shared.json"]`, `import ... from '../../eslint.base.mjs'`).

Последствие: локально/в облаке файл «над» репозиторием не выгружается, поэтому
Biome/ESLint падают на загрузке конфига ещё до проверки кода. НО где именно это
бьёт — зависит от того, где реально запускается линт (см. раздел 1а, уточнено
по итогам ревью).

Дополнительно: общий Biome тащил правила под React даже в бэкенд `2r-backend`
(NestJS/Fastify), что давало ложные срабатывания.

### 1а. Где линт реально исполняется (уточнено ревью — это основа приоритетов)

| Проект | Где сейчас ломается | Что гоняет линт | Тип |
|---|---|---|---|
| 2r-mobile | **облачный CI** | job `lint`: `biome check . && eslint .` (через `../../`) | настоящий CI-сбой |
| 2r-backend | локально / pre-commit | CI = `buf lint` + тесты, `npm run lint` НЕ запускается | локальный сбой |
| games-distribution | локально | CI-воркфлоу нет вообще | локальный сбой |
| iney-mvp | нигде (дремлет) | CI `pnpm lint` = только `biome check .`; biome свой; ESLint не вызывается | наведение порядка |
| one-q | нигде (дремлет) | то же; pnpm-монорепо с `catalog:` | наведение порядка |
| playhub | — (уже автономный) | CI гоняет lint; конфиг своя копия | единообразие |
| slow | несовместим | Biome **2.0.0-beta.6** (схема 2.4.x не подойдёт) | сначала апгрейд Biome |
| Alitools / alitools | не использует общий конфиг | — | вне объёма (опц. в будущем) |

Вывод: приоритет миграции — `2r-mobile` (единственный настоящий облачный сбой),
затем локальные/pre-commit (`2r-backend`, `games-distribution`), затем
дремлющие cleanup (`iney-mvp`, `one-q`, `playhub`). `slow` — отдельно, после
апгрейда его Biome. `Alitools` — вне объёма.

## 2. Решение (кратко)

Один публичный npm-пакет `@mikitasazan/config` в новом репозитории
`github.com/sazanwork/config`. Внутри — Biome, ESLint и tsconfig в форме
**база + пресеты**. Проекты ставят пакет как обычную зависимость; конфиг
попадает в `node_modules` внутри выгруженного репозитория, поэтому он виден.
Причина сбоев устраняется в корне.

Ключевые решения (согласованы с пользователем):

- Реестр: **публичный npm** (npmjs.com), scope `@mikitasazan`. Установка без
  токена — `mikitasazan` и `sazanwork` ставят одинаково. (Имя `@mikitasazan/config`
  на npm свободно — проверено: `npm view` → E404.)
- Форма: **база + пресеты** — нейтральная база плюс пресеты `react`, `astro`.
- Содержимое: Biome + ESLint + tsconfig-база.
- tsconfig-база: **строгая** (`strict: true` + современные флаги). Проект, не
  готовый к строгости, ослабляет её у себя явными override (бэкенд `2r-backend`
  сейчас работает мягко: `noImplicitAny: false`, неполный `strict` — при миграции
  оставит эти послабления у себя, чтобы сборка не покраснела). Базовая строгость
  даёт «единый стандарт», а отставание каждого проекта становится видимым.
- Публикация: **GitHub Actions по git-тегу** (`vX.Y.Z`).

## 3. Структура пакета

```
@mikitasazan/config/
  package.json          # name, version, exports, files, publishConfig
  biome/
    base.json           # формат + правила без привязки к фреймворку
    react.json          # пресет: React/RN/Next (хуки, JSX)
    astro.json          # пресет: только overrides-блок под .astro
  eslint/
    base.mjs            # basePaddingRules
    strict.mjs          # строгий супер-набор + brace-style (импортирует base)
  tsconfig/
    base.json           # строгая TS-база
    node.json           # пресет: Node-сервис (NodeNext, ES2023)
    bundler.json        # пресет: сборка bundler'ом (React/RN/Next/Vite)
  README.md
  docs/specs/2026-06-13-shared-config-package.md
```

`package.json` (ключевое):

```jsonc
{
  "name": "@mikitasazan/config",
  "version": "1.0.0",
  "type": "module",
  "publishConfig": { "access": "public" },
  "files": ["biome", "eslint", "tsconfig"],
  "exports": {
    "./biome": "./biome/base.json",
    "./biome-react": "./biome/react.json",
    "./biome-astro": "./biome/astro.json",
    "./eslint": "./eslint/base.mjs",
    "./eslint-strict": "./eslint/strict.mjs",
    "./tsconfig.json": "./tsconfig/base.json",
    "./tsconfig-node": "./tsconfig/node.json",
    "./tsconfig-bundler": "./tsconfig/bundler.json"
  }
}
```

Имена Biome-экспортов — без `.json`: Biome считает специфайр, оканчивающийся на
`.json`/`.jsonc`, относительным путём и не ищет в `node_modules` (подтверждено
эмпирически на Biome 2.4.15).

tsconfig-пресеты `tsconfig-node` (резолв `NodeNext`, цель `ES2023`) и
`tsconfig-bundler` (резолв `Bundler`, `isolatedModules`, `noEmit`) наследуют
строгую базу через относительный `extends: "./base.json"` и добавляют только
флаги среды. `jsx` намеренно НЕ зашит — он различается между потребителями
(`react-native` / `preserve` / `react-jsx`), его задаёт сам проект. Два кластера
выделены по факту: анализ потребителей показал, что Node-сервисы и сборки
React/RN/Next дублировали ровно эти наборы поверх базы. Покрыты дымовым тестом
(наследование `strict` + ожидаемый `moduleResolution`).

Минимальная версия Biome, на которую рассчитан конфиг: **>= 2.4.10**. `slow`
(2.0.0-beta.6) её не удовлетворяет — апгрейд до миграции.

## 4. Разделение правил Biome (база против react-пресета)

В react-пресет уезжает всё, что про React/JSX; остальное остаётся в базе.

| Правило | Куда | Почему |
|---|---|---|
| `useHookAtTopLevel` | react | React-хуки; на бэкенде ложно срабатывает |
| `useExhaustiveDependencies` | react | зависимости React-хуков |
| `useJsxKeyInIterable` | react | только JSX |
| `useFragmentSyntax` | react | только JSX |
| `useSelfClosingElements` | react | про JSX-теги |
| `noArrayIndexKey` | react | про React-ключи |
| формат, `noVar`, `useConst`, `noExplicitAny`, импорты, json-формат, globals и пр. | база | безопасно везде |

Важные оговорки (по итогам ревью):

- База сохраняет `recommended: true`. В рекомендованный набор Biome входят и
  некоторые JSX/a11y-правила. На бэкенде они безвредны не потому, что исключены,
  а потому что в нём **нет JSX-файлов**. Это надо понимать явно.
- Пресеты **не должны** переобъявлять `recommended` (иначе сбросят унаследованное
  состояние) — они только ДОБАВЛЯют свои не-рекомендованные правила.
- `biome-astro` по сути содержит ровно `overrides`-блок под `.astro` (отключение
  `noUnusedVariables`/`noUnusedImports` для frontmatter), потому что Biome видит
  в `.astro` только frontmatter; шаблон линтует ESLint (`eslint-plugin-astro`).
  Пресет тонкий — это нормально, но честно фиксируем его реальное содержимое.

## 5. Как проект подключает

Бэкенд (только база) — `2r-backend`:

```jsonc
// biome.json
{ "extends": ["@mikitasazan/config/biome"] }
```
```ts
// eslint.config.ts
import { basePaddingRules } from '@mikitasazan/config/eslint';
```
```jsonc
// tsconfig.json
{ "extends": "@mikitasazan/config/tsconfig.json" }
```

React-проект (база + react) — `2r-mobile`, `iney-mvp`, `one-q`:

```jsonc
{ "extends": ["@mikitasazan/config/biome", "@mikitasazan/config/biome-react"] }
```

Astro (база + astro, eslint strict) — `playhub`, `games-distribution`:

```jsonc
{ "extends": ["@mikitasazan/config/biome", "@mikitasazan/config/biome-astro"] }
```
```js
// eslint.config.js
import { strictPaddingRules } from '@mikitasazan/config/eslint-strict';
```

Несколько `extends` складываются по порядку — поздние переопределяют ранние
(проверено эмпирически).

## 6. Монорепо / pnpm (iney-mvp, one-q)

`iney-mvp` и `one-q` — pnpm-монорепо (`pnpm-workspace.yaml`, `apps/*`,
`packages/*`; у one-q есть `catalog:` — единый пин версий на весь репозиторий).

Открытые пункты, которые план обязан закрыть проверкой (ревьюер НЕ смог
проверить эмпирически из-за симлинков pnpm):

- Ставить пакет в devDependencies **корня** монорепо (для one-q — вероятно через
  `catalog:`), а не в каждое приложение.
- Убедиться, что Biome/ESLint/TS резолвят `@mikitasazan/config/...` из вложенного
  конфига (`apps/web/biome.json`) через симлинкованный `node_modules` pnpm.
- Прогнать установку с `--frozen-lockfile` (как в CI), чтобы поймать рассинхрон
  лок-файла.

## 7. Публикация (GitHub Actions по тегу)

- Триггер — push git-тега вида `v*` (например `v1.2.0`).
- Шаги: `npm ci` → дымовой тест конфигов → `npm publish`.
- Секрет `NPM_TOKEN` — **Automation / Granular токен** (НЕ classic publish-токен),
  иначе при включённой 2FA `npm publish` потребует одноразовый код и Action
  зависнет/упадёт. Кладёт пользователь.
- `--access public` обеспечен через `publishConfig.access: public`.
- Если включаем provenance (`--provenance`) — добавить в workflow
  `permissions: id-token: write` и публичный репозиторий; иначе publish упадёт.

## 8. Тестирование и критерии приёмки

Дымовой тест в репо пакета: крошечный образец кода + прогон `biome check` и
`eslint` с этими конфигами — убедиться, что они грузятся и не противоречат сами
себе. Запускается в CI до публикации.

Критерий приёмки **по каждому проекту** = «команда, которая реально линтует,
проходит зелёной»:

- `2r-mobile`, `playhub`, `iney-mvp`, `one-q` — зелёный шаг lint в облачном CI.
- `2r-backend` — зелёный локальный `npm run lint` + успешный pre-commit (в его CI
  линта нет).
- `games-distribution` — зелёный локальный `npm run lint` (CI нет).

## 9. План миграции (порядок — по «где линт исполняется»)

**Шаг 0 (жёсткий гейт):** опубликовать `v1.0.0` на npm и проверить, что
`npm view @mikitasazan/config` резолвится. Без этого `npm ci` /
`pnpm install --frozen-lockfile` у потребителей упадёт на неизвестной
зависимости. Вся миграция зависит от Шага 0.

1. `2r-mobile` — единственный настоящий облачный CI-сбой. Чиним первым:
   ставим пакет, `extends` → база + react, ESLint-импорт → пакет.
2. `2r-backend` — локальный/pre-commit сбой. Переключаем `extends`/импорт на
   пакет (только база), tsconfig → пакет. Заодно решаем undeclared `jiti`:
   либо пинуем `jiti` в devDependencies, либо переводим `eslint.config.ts` →
   `.mjs` (как в iney/one-q), чтобы убрать скрытую зависимость.
3. `games-distribution` — локальный сбой (CI нет). База + astro, eslint strict.
4. `iney-mvp`, `one-q` — наведение порядка (мина дремлет). Раздел 6 (pnpm)
   обязателен. ESLint можно либо подключить к пакету, либо оставить выключенным —
   по желанию (это не аварийная починка).
5. `playhub` — единообразие; перевод на пакет и удаление локальной копии.
6. `slow` — сначала апгрейд Biome до >= 2.4.10, затем база (+ нужный пресет).
7. После миграции всех активных потребителей — удалить старые
   `~/Development/Projects/{biome.shared.json,eslint.base.mjs,eslint.strict.mjs}`.

Каждый шаг проверяется своим критерием приёмки (раздел 8) до перехода к следующему.

## 10. Объём планов (рекомендация ревью)

Разбить на **два плана реализации**, потому что у них разный «радиус взрыва» и
разная зависимость:

- **План A — собрать и опубликовать пакет.** Самодостаточен, проверяется своим
  дымовым тестом, заканчивается публикацией `v1.0.0`. Это и есть Шаг 0.
- **План B — мигрировать потребителей.** Один PR на репозиторий, каждый гейтится
  своим зелёным линтом. Строго зависит от первой публикации из плана A.

## 11. Риски и оговорки

- **Имя scope на npm.** `@mikitasazan` должно быть создано на npmjs.com
  (`npm adduser`) — разовый шаг пользователя.
- **pnpm-резолвинг** (раздел 6) — единственное несущее допущение, не
  подтверждённое эмпирически; план обязан проверить его на iney/one-q.
- **`slow` на Biome-бете** — несовместим до апгрейда.
- **Дрейф версий** — пока проект не обновил пакет, живёт на старых правилах;
  осознанный размен ради «никого не ломаем разом».
- **Приёмка ≠ только облачный CI** — у бэкенда и games линт в облаке не гоняется;
  их приёмка локальная (раздел 8).
```