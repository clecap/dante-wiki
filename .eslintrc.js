module.exports = {
  env: {
    browser: true,
    es2021: true,
    node: true,
  },
  extends: [
    'eslint:recommended'
  ],
  parserOptions: {
    ecmaFeatures: {
      jsx: true,
    },
    ecmaVersion: 12,
    sourceType: 'module',
  },
  plugins: [
  ],
  rules: {
    'react/prop-types':  'off',
    'no-console':        'warn',
    'no-debugger':       'error',
    'no-unused-vars':    ['warn'],
    'eqeqeq':            ['error', 'always'],
    'curly':             ['error', 'all'],
    'semi':              ['error', 'always'],
    'quotes':            ['error', 'single'],
  },
  settings: {
    react: {
      version: 'detect',
    },
  },
};
