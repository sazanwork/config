#!/usr/bin/env node
// @mikitasazan/config — install the canonical pre-commit hook into a project.
// Idempotent, no-clobber. Meant to run from the project root via the `prepare`
// script, AFTER husky (e.g. "prepare": "husky && mikitasazan-config-init").
//
// - Writes the pre-commit hook (npx lint-staged) into the directory git ACTUALLY
//   reads hooks from (core.hooksPath), not a hardcoded .husky — a repo that
//   routes hooks elsewhere (e.g. .githooks from git-guards) keeps its own dir.
//   Never clobbers a foreign or existing-linting hook.
// - Creates lint-staged.config.mjs re-exporting the shared preset, if the
//   project has no lint-staged config at all.

import { execFileSync } from 'node:child_process';
import { copyFileSync, chmodSync, existsSync, mkdirSync, readFileSync, writeFileSync, readdirSync } from 'node:fs';
import { dirname, isAbsolute, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const pkgDir = dirname(dirname(fileURLToPath(import.meta.url))); // package root

// execFile, not exec: no shell, so nothing here can be turned into a command.
const git = (...args) => {
  try {
    return execFileSync('git', args, { stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim();
  } catch {
    return '';
  }
};

const root = git('rev-parse', '--show-toplevel') || process.cwd();

const log = (m) => console.log(`[mikitasazan-config] ${m}`);
const warn = (m) => console.warn(`[mikitasazan-config] ⚠ ${m}`);

// --- hook directory: whatever git really reads, not an assumption ---
// core.hooksPath wins over the default. Husky sets it to .husky/_; git-guards
// sets it to .githooks. Writing to .husky when git reads .githooks (or the other
// way round) installs a hook that never runs — a silent no-op.
const hooksPath = git('config', 'core.hooksPath');
const usesHusky = hooksPath.includes('husky');
const hookDir = hooksPath && !usesHusky
  ? (isAbsolute(hooksPath) ? hooksPath : join(root, hooksPath))
  : join(root, '.husky');

// A repo can end up with hooks in a dir git no longer reads: husky rewrites
// core.hooksPath on every `npm install`, so an earlier .githooks setup (branch
// protection, commit-msg convention) goes quiet without any error. Say so.
const strandedDir = join(root, '.githooks');
if (usesHusky && existsSync(strandedDir) && readdirSync(strandedDir).length > 0) {
  warn(`core.hooksPath points at husky (${hooksPath}), but .githooks/ still holds hooks — those are NOT running.`);
  warn('Husky hijacks core.hooksPath. Drop `husky` from the `prepare` script and run: git config core.hooksPath .githooks');
}

// --- pre-commit hook (no-clobber) ---
const preCommit = join(hookDir, 'pre-commit');
if (existsSync(preCommit)) {
  const cur = readFileSync(preCommit, 'utf8');
  if (/lint-staged|npm run lint|biome|eslint/.test(cur)) {
    log('pre-commit already lints — left as is');
  } else {
    log('existing pre-commit found (no lint) — not modified; add `npx lint-staged` if you want it');
  }
} else {
  mkdirSync(hookDir, { recursive: true });
  copyFileSync(join(pkgDir, 'husky', 'pre-commit'), preCommit);
  chmodSync(preCommit, 0o755);
  log(`installed ${preCommit.replace(`${root}/`, '')} (npx lint-staged)`);
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
