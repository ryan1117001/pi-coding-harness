import { fireEvent, render, screen } from '@testing-library/react';
import { Button } from './Button';

describe('Button', () => {
  it('renders its children with daisyUI button classes', () => {
    render(<Button>Click me</Button>);
    const button = screen.getByRole('button', { name: 'Click me' });
    expect(button.className).toContain('btn');
  });

  it('merges a custom className', () => {
    render(<Button className="btn-secondary">Save</Button>);
    expect(screen.getByRole('button', { name: 'Save' }).className).toContain(
      'btn-secondary',
    );
  });

  it('forwards click handlers', () => {
    let clicked = false;
    render(<Button onClick={() => (clicked = true)}>Go</Button>);
    fireEvent.click(screen.getByRole('button', { name: 'Go' }));
    expect(clicked).toBe(true);
  });
});
