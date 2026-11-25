# Gotchas

## Index

| Gotcha | Summary |
|---|---|
| [biome-export-without-json](#biome-export-without-json) | Biome can interpret the specifier as a relative path. |
| [Consumers choose JSX](#jsx-задаёт-потребитель) | JSX modes vary by environment. | <!-- verbatim -->

### biome-export-without-json

The public Biome exports are `biome`, `biome-react`, and `biome-astro`. Leave out
the `.json` suffix. Biome can treat a specifier ending in `.json` as a relative
file and fail to resolve it through `node_modules`.

### «jsx-задаёт-потребитель»

React Native, Next.js, and plain React use different JSX modes. TypeScript
presets deliberately leave `jsx` for each consumer to set in its own `tsconfig`.
