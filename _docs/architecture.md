# Architecture

| Capability | Code organization |
|---|---|
| Biome | `biome/base.json` defines a neutral base. `react.json` and `astro.json` add presets. |
| ESLint | `eslint/base.mjs` exports the base rules. `strict.mjs` exports the strict superset. |
| TypeScript | `tsconfig/base.json` sets strict options. `node.json` and `bundler.json` set options for their environments. |
| Git hooks | `bin/`, `husky/`, and `lint-staged/` install and run consumer checks. |
| Package contract | `package.json` maps public exports to configuration files. |
| Checks | `test/smoke.sh` and `test/integration.sh` verify rules and package installation. |

Consumers install the package and choose the base and any presets they need.
Their tools load the configurations through `exports`.
