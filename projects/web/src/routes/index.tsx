import { createFileRoute } from '@tanstack/react-router';
import { Button } from '../components/atoms/Button';

/* v8 ignore start -- route registration glue rewritten by autoCodeSplitting */
export const Route = createFileRoute('/')({
  component: HomePage,
});
/* v8 ignore stop */

function HomePage() {
  return (
    <div className="card max-w-md bg-base-200 shadow-md">
      <div className="card-body">
        <h1 className="card-title">Welcome to web</h1>
        <p>
          React 19 · Vite 8 · Tailwind v4 · daisyUI v5 · TanStack Router ·
          TanStack Query
        </p>
        <div className="card-actions justify-end">
          <Button className="btn-primary">Get started</Button>
        </div>
      </div>
    </div>
  );
}
