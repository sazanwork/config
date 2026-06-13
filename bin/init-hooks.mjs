#!/usr/bin/env node
// @mikitasazan/config — install the canonical pre-commit hook into a project.
// Idempotent, no-clobber. Meant to run from the project root via the `prepare`
// script, AFTER husky (e.g. "prepare": "husky && mikitasazan-config-init").
//
// - Writes .husky/pre-commit (npx lint-staged) only if there isn't already a
//   hook that lints (never clobbers a foreign or existing-linting hook).
// - Creates lint-staged.config.mjs re-exporting the shared preset, if the
//   project has no lint-staged config at all.

import { execSync } from 'node:child_process';
import { copyFileSync, chmodSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const pkgDir = dirname(dirname(fileURLToPath(import.meta.url))); // package root

let root;
try {
  root = execSync('git rev-parse --show-toplevel', { stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim();
} catch {
  root = process.cwd();
}

const log = (m) => console.log(`[mikitasazan-config] ${m}`);

// --- pre-commit hook (no-clobber) ---
const huskyDir = join(root, '.husky');
const preCommit = join(huskyDir, 'pre-commit');
if (existsSync(preCommit)) {
  const cur = readFileSync(preCommit, 'utf8');
  if (/lint-staged|npm run lint|biome|eslint/.test(cur)) {
    log('pre-commit already lints — left as is');
  } else {
    log('existing pre-commit found (no lint) — not modified; add `npx lint-staged` if you want it');
  }
} else {
  mkdirSync(huskyDir, { recursive: true });
  copyFileSync(join(pkgDir, 'husky', 'pre-commit'), preCommit);
  chmodSync(preCommit, 0o755);
  log('installed .husky/pre-commit (npx lint-staged)');
}

// --- lint-staged config (only if the project has none) ---
const pkgJsonPath = join(root, 'package.json');
let hasLsInPkg = false;
if (existsSync(pkgJsonPath)) {
  try { hasLsInPkg = !!JSON.parse(readFileSync(pkgJsonPath, 'utf8'))['lint-staged']; } catch { /* ignore */ }
}
const lsConfigExists = ['lint-staged.config.mjs', 'lint-staged.config.js', 'lint-staged.config.cjs', '.lintstagedrc.json', '.lintstagedrc.mjs']
  .some((f) => existsSync(join(root, f)));

if (!hasLsInPkg && !lsConfigExists) {
  writeFileSync(join(root, 'lint-staged.config.mjs'), "export { default } from '@mikitasazan/config/lint-staged';\n");
  log('created lint-staged.config.mjs (re-exports the shared preset)');
} else {
  log('lint-staged config already present — left as is');
}
