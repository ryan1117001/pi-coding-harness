import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
import { createRootRoute, Outlet } from '@tanstack/react-router';
import { TanStackRouterDevtools } from '@tanstack/react-router-devtools';

export const Route = createRootRoute({
  component: RootLayout,
});

function RootLayout() {
  return (
    <div className="min-h-screen bg-base-100 text-base-content">
      <header className="navbar bg-base-200 px-4">
        <span className="font-semibold text-lg">web</span>
      </header>
      <main className="p-6">
        <Outlet />
      </main>
      <Devtools />
    </div>
  );
}

/* v8 ignore start -- dev-only tooling, absent from production builds */
function Devtools() {
  if (!import.meta.env.DEV) {
    return null;
  }
  return (
    <>
      <TanStackRouterDevtools position="bottom-right" />
      <ReactQueryDevtools initialIsOpen={false} />
    </>
  );
}
/* v8 ignore stop */
