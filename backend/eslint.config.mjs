import tseslint from 'typescript-eslint';
import prettierConfig from 'eslint-config-prettier';

export default tseslint.config(
  { ignores: ['dist/**', 'node_modules/**', 'jest.config.js'] },
  ...tseslint.configs.recommended,
  prettierConfig,
  {
    rules: {
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_', caughtErrorsIgnorePattern: '^_', varsIgnorePattern: '^_' }],
      '@typescript-eslint/explicit-function-return-type': 'off',
      // {} as Express route params type is a valid pattern
      '@typescript-eslint/no-empty-object-type': 'off',
      'no-console': 'warn',
    },
  },
  // Test files: allow require() imports (Jest mock pattern) and any types
  {
    files: ['**/*.test.ts'],
    rules: {
      '@typescript-eslint/no-require-imports': 'off',
      '@typescript-eslint/no-explicit-any': 'off',
    },
  },
  // Logger and migration scripts: console is expected
  {
    files: ['src/shared/logger.ts', 'src/db/migrate.ts'],
    rules: {
      'no-console': 'off',
    },
  },
);
