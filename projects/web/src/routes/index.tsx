import { createFileRoute } from '@tanstack/react-router';
import { Button } from '../components/atoms/Button';
import { m } from '../paraglide/messages.js';

/* v8 ignore start -- route registration glue rewritten by autoCodeSplitting */
export const Route = createFileRoute('/')({
  component: HomePage,
});
/* v8 ignore stop */

function HomePage() {
  return (
    <div className="card max-w-md bg-base-200 shadow-md">
      <div className="card-body">
        <h1 className="card-title">{m.welcome_title()}</h1>
        <p>{m.stack_description()}</p>
        <div className="card-actions justify-end">
          <Button className="btn-primary">{m.get_started()}</Button>
        </div>
      </div>
    </div>
  );
}
