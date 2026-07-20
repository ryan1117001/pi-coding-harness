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
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  render(
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} />
    </QueryClientProvider>,
  );
}

describe('RootLayout', () => {
  it('renders the navbar with the app name', async () => {
    renderApp();
    expect(await screen.findByText('web')).toBeTruthy();
  });

  it('renders the outlet content for the index route', async () => {
    renderApp();
    expect(await screen.findByText('Welcome to web')).toBeTruthy();
  });
});
