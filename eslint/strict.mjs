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
