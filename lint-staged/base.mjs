// Shared lint-staged config for all projects.
// Biome formats + lints, then ESLint applies the padding rules Biome lacks.
// Use in a project: lint-staged.config.mjs -> export { default } from '@mikitasazan/config/lint-staged'
export default {
  '*.{ts,tsx,js,jsx,mjs,cjs}': [
    'biome check --write --no-errors-on-unmatched',
    'eslint --fix',
  ],
  '*.{json,jsonc}': ['biome format --write --no-errors-on-unmatched'],
};
