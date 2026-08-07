import { screen } from '@testing-library/react';
import { renderApp } from '../../tests/render-app';

describe('index route', () => {
  it('renders the welcome card with a daisyUI button', async () => {
    await renderApp();

    expect(await screen.findByText('Welcome to web')).toBeTruthy();
    const button = await screen.findByRole('button', { name: 'Get started' });
    expect(button.className).toContain('btn');
  });
});
