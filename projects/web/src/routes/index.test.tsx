import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import {
  createMemoryHistory,
  createRouter,
  RouterProvider,
} from '@tanstack/react-router';
import { render, screen } from '@testing-library/react';
import { routeTree } from '../routeTree.gen';

function renderApp() {
  const router = createRouter({
    routeTree,
    history: createMemoryHistory({ initialEntries: ['/'] }),
  });
  const queryClient = new QueryClient();

  render(
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} />
    </QueryClientProvider>,
  );
}

describe('index route', () => {
  it('renders the welcome card with a daisyUI button', async () => {
    renderApp();

    expect(await screen.findByText('Welcome to web')).toBeTruthy();
    const button = await screen.findByRole('button', { name: 'Get started' });
    expect(button.className).toContain('btn');
  });
});
