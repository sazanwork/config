// Shared ESLint padding-line rules for all unified projects.

export const basePaddingRules = {
  'padding-line-between-statements': [
    'error',
    { blankLine: 'always', prev: '*', next: 'return' },
    { blankLine: 'always', prev: '*', next: 'continue' },
    { blankLine: 'always', prev: '*', next: 'break' },
    { blankLine: 'always', prev: ['const', 'let', 'var'], next: '*' },
    { blankLine: 'any', prev: ['const', 'let', 'var'], next: ['const', 'let', 'var'] },
    { blankLine: 'always', prev: 'if', next: '*' }
  ]
};

export default basePaddingRules;
