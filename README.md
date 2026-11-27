# @mikitasazan/config

[Project overview](_docs/README.md).

Shared Biome, ESLint, and TypeScript configurations for all projects.
Use a common base and add the preset for your environment.

## Install

```bash
npm install -D @mikitasazan/config
```

## Usage

Biome (`biome.json`)

```jsonc
// Backend or another non-frontend project
{ "extends": ["@mikitasazan/config/biome"] }

// React / React Native / Next
{ "extends": ["@mikitasazan/config/biome", "@mikitasazan/config/biome-react"] }

// Astro
{ "extends": ["@mikitasazan/config/biome", "@mikitasazan/config/biome-astro"] }
```

ESLint (`eslint.config.mjs`)

```js
import { basePaddingRules } from '@mikitasazan/config/eslint';
// Or use the strict superset:
import { strictPaddingRules } from '@mikitasazan/config/eslint-strict';

export default [{ rules: basePaddingRules }];
```

TypeScript (`tsconfig.json`)

```jsonc
// Neutral strict base
{ "extends": "@mikitasazan/config/tsconfig.json" }

// Node service (NodeNext module resolution, ES2023 target)
{ "extends": "@mikitasazan/config/tsconfig-node" }

// Bundler build — React / React Native / Next / Vite
// (Bundler resolution, isolatedModules, noEmit)
{ "extends": "@mikitasazan/config/tsconfig-bundler" }
```

The base enables strict mode (`strict: true`). Projects can relax individual
options in their own config. The `tsconfig-node` and `tsconfig-bundler` presets
extend the base and add only options for their environments. The shared config
deliberately leaves `jsx` to each consumer because the mode varies by project
(`react-native`, `preserve`, or `react-jsx`).

## Release

Follow the same release procedure for every shared package. The
`package-ops` skill describes it.

Bump the version in a PR. After the PR merges, push the `vX.Y.Z` tag from master.
GitHub Actions (`.github/workflows/publish.yml`) publishes through npm Trusted
Publishing without a token or one-time code. Leave `npm publish` to that workflow.

```bash
npm version patch --no-git-tag-version   # In the PR, then on master after merging:
git checkout master && git pull
git tag vX.Y.Z && git push origin vX.Y.Z   # The tag must match the version in package.json
```

Consumers pin the exact version. After publishing, open a separate upgrade PR
in each consumer repository.
