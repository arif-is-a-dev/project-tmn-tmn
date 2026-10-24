import React from 'react';
import { cn } from '../../lib/utils.js';

/** Lightweight separator used in layout compositions */
export function Separator({ className, ...props }) {
  return (
    <div
      role="separator"
      className={cn('shrink-0 bg-stone-200 h-px w-full', className)}
      {...props}
    />
  );
}
