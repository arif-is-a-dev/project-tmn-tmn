import React from 'react';
import { cn } from '../../lib/utils.js';

export function EmptyState({ icon: Icon, title, description, className }) {
  return (
    <div className={cn('flex flex-col items-center justify-center py-20 px-6 text-center', className)}>
      {Icon && (
        <div className="w-12 h-12 rounded-lg bg-surface-alt border border-border flex items-center justify-center mb-4">
          <Icon size={22} className="text-muted" />
        </div>
      )}
      <h3 className="text-base font-semibold text-primary mb-1">{title}</h3>
      {description && (
        <p className="text-sm text-secondary max-w-xs leading-relaxed">{description}</p>
      )}
    </div>
  );
}
