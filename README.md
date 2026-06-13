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
