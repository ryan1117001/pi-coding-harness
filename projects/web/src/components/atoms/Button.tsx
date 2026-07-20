import type { ButtonHTMLAttributes } from 'react';

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  className?: string;
}

export function Button({ className, type, ...props }: ButtonProps) {
  return (
    <button
      type={type ?? 'button'}
      className={['btn', className].filter(Boolean).join(' ')}
      {...props}
    />
  );
}
