import type { Meta, StoryObj } from '@storybook/react-vite';
import { expect, fn, userEvent, within } from 'storybook/test';
import { Button } from './Button';

const meta: Meta<typeof Button> = {
  title: 'Atoms/Button',
  component: Button,
  args: { children: 'Get started' },
};

export default meta;

type Story = StoryObj<typeof Button>;

export const Primary: Story = {
  args: { className: 'btn-primary' },
};

export const Secondary: Story = {
  args: { className: 'btn-secondary' },
};

export const Outline: Story = {
  args: { className: 'btn-outline' },
};

export const Clickable: Story = {
  args: { className: 'btn-primary', children: 'Click me', onClick: fn() },
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    const button = canvas.getByRole('button', { name: 'Click me' });
    await userEvent.click(button);
    expect(args.onClick).toHaveBeenCalledTimes(1);
  },
};
