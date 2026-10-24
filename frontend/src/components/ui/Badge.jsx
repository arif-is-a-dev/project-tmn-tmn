import React from 'react';
import { cva } from 'class-variance-authority';
import { cn } from '../../lib/utils.js';

const badgeVariants = cva(
  'inline-flex items-center px-2 py-0.5 rounded text-2xs font-semibold tracking-wide',
  {
    variants: {
      variant: {
        accent:   'bg-accent text-accent-text',
        success:  'bg-success-bg text-success border border-success/20',
        warning:  'bg-warning-bg text-warning border border-warning/20',
        danger:   'bg-danger-bg text-danger border border-danger/20',
        neutral:  'bg-surface-alt text-secondary border border-border',
        outline:  'border border-border text-secondary',
      },
    },
    defaultVariants: { variant: 'neutral' },
  }
);

export function Badge({ className, variant, ...props }) {
  return <span className={cn(badgeVariants({ variant }), className)} {...props} />;
}
