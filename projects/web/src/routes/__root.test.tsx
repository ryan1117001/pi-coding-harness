import { screen } from '@testing-library/react';
import { renderApp } from '../../tests/render-app';

describe('RootLayout', () => {
  it('renders the navbar with the app name', async () => {
    await renderApp();
    expect(await screen.findByText('web')).toBeTruthy();
  });

  it('renders the outlet content for the index route', async () => {
    await renderApp();
    expect(await screen.findByText('Welcome to web')).toBeTruthy();
  });
});
