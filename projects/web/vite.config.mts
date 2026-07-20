import path from 'node:path';
import { storybookTest } from '@storybook/addon-vitest/vitest-plugin';
import tailwindcss from '@tailwindcss/vite';
import { tanstackRouter } from '@tanstack/router-plugin/vite';
import react from '@vitejs/plugin-react';
import { playwright } from '@vitest/browser-playwright';
import { defineConfig } from 'vitest/config';

export default defineConfig(() => ({
  root: import.meta.dirname,
  cacheDir: '../../node_modules/.vite/projects/web',
  server: {
    port: 4200,
    host: 'localhost',
  },
  preview: {
    port: 4200,
    host: 'localhost',
  },
  plugins: [
    tanstackRouter({
      target: 'react',
      autoCodeSplitting: true,
      routeFileIgnorePattern: '\\.(test|spec)\\.[tj]sx?$',
    }),
    react(),
    tailwindcss(),
  ],
  // Uncomment this if you are using workers.
  // worker: {
  //  plugins: [],
  // },
  build: {
    outDir: './dist',
    emptyOutDir: true,
    reportCompressedSize: true,
    commonjsOptions: {
      transformMixedEsModules: true,
    },
  },
  test: {
    coverage: {
      enabled: true,
      reportsDirectory: '../../coverage/projects/web',
      provider: 'v8' as const,
      reporter: ['text', 'html', 'cobertura'],
      exclude: [
        'src/main.tsx',
        'src/routeTree.gen.ts',
        '**/*.stories.tsx',
        '**/*.{test,spec}.{ts,tsx}',
      ],
      thresholds: {
        statements: 85,
        branches: 85,
        functions: 85,
        lines: 85,
      },
    },
    // Two Vitest projects share this Vite config: `web` runs unit/Testing Library
    // specs in jsdom; `storybook` runs every story as a browser test via the
    // Storybook Vitest addon (Playwright/Chromium). Both extend the plugins above.
    projects: [
      {
        extends: true as const,
        test: {
          name: 'web',
          watch: false,
          globals: true,
          environment: 'jsdom',
          include: [
            '{src,tests}/**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}',
          ],
          reporters: ['default'],
        },
      },
      {
        extends: true as const,
        plugins: [
          storybookTest({
            configDir: path.join(import.meta.dirname, '.storybook'),
          }),
        ],
        test: {
          name: 'storybook',
          watch: false,
          browser: {
            enabled: true,
            provider: playwright({}),
            headless: true,
            instances: [{ browser: 'chromium' as const }],
          },
        },
      },
    ],
  },
}));
