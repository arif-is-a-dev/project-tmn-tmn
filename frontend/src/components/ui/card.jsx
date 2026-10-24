import React from 'react';
import { cn } from '../../lib/utils.js';

/** Card primitive */
export function Card({ className, ...props }) {
  return (
    <div
      className={cn('bg-white rounded-lg border border-stone-200 shadow-card', className)}
      {...props}
    />
  );
}

export function CardHeader({ className, ...props }) {
  return (
    <div className={cn('px-5 py-4 border-b border-stone-100', className)} {...props} />
  );
}

export function CardContent({ className, ...props }) {
  return <div className={cn('p-5', className)} {...props} />;
}

export function CardFooter({ className, ...props }) {
  return (
    <div className={cn('px-5 py-3 border-t border-stone-100', className)} {...props} />
  );
}