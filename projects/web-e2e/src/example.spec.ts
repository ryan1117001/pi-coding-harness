import { expect, test } from '@playwright/test';

test('renders the welcome page with a daisyUI button', async ({ page }) => {
  await page.goto('/');

  await expect(page.locator('h1')).toContainText('Welcome to web');

  const button = page.getByRole('button', { name: 'Get started' });
  await expect(button).toBeVisible();
  await expect(button).toHaveClass(/btn/);
});
