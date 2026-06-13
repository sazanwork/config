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
// нейтральная строгая база
{ "extends": "@mikitasazan/config/tsconfig.json" }

// Node-сервис (резолв модулей NodeNext, цель ES2023)
{ "extends": "@mikitasazan/config/tsconfig-node" }

// сборка через bundler — React / React Native / Next / Vite
// (резолв Bundler, isolatedModules, noEmit)
{ "extends": "@mikitasazan/config/tsconfig-bundler" }
```

База строгая (`strict: true`); проект, не готовый к строгости, ослабляет нужные
флаги у себя. Пресеты `tsconfig-node` и `tsconfig-bundler` наследуют базу и лишь
добавляют флаги среды. `jsx` намеренно не задан (он различается: `react-native`
/ `preserve` / `react-jsx`) — его выставляет проект.
