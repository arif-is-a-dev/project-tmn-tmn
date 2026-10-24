import React from 'react';
import { cn } from '../../lib/utils.js';

export function Skeleton({ className, ...props }) {
  return <div className={cn('skeleton rounded', className)} {...props} />;
}

export function SkeletonCard() {
  return (
    <div className="surface p-5 space-y-3">
      <div className="flex justify-between items-start">
        <Skeleton className="h-3 w-16" />
        <Skeleton className="h-4 w-20 rounded" />
      </div>
      <Skeleton className="h-5 w-full" />
      <Skeleton className="h-3 w-3/4" />
      <div className="pt-3 border-t border-border-subtle flex justify-between">
        <Skeleton className="h-4 w-16" />
        <Skeleton className="h-3 w-8" />
      </div>
    </div>
  );
}

export function SkeletonTable({ rows = 5, cols = 4 }) {
  return (
    <div className="surface overflow-hidden">
      <div className="h-10 border-b border-border" />
      {Array.from({ length: rows }).map((_, i) => (
        <div key={i} className="h-12 flex items-center gap-4 px-4 border-b border-border-subtle last:border-0">
          {Array.from({ length: cols }).map((_, j) => (
            <Skeleton key={j} className="h-3 flex-1" />
          ))}
        </div>
      ))}
    </div>
  );
}
