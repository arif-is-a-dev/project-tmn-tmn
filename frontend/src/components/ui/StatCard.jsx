import React from 'react';

/**
 * Compact stat card — analytics dashboard style.
 * Tight padding, clear hierarchy, minimal whitespace.
 * Uses CSS variables for full theme support.
 */
export function StatCard({ label, value, sub, loading, large, className }) {
  return (
    <div className={`surface px-4 py-3.5 ${className || ''}`}>
      <span className="text-[10px] font-semibold uppercase tracking-wider text-muted leading-none block mb-1.5">
        {label}
      </span>

      {loading ? (
        <>
          <div className="skeleton h-7 w-20 mb-1" />
          {sub && <div className="skeleton h-3 w-28" />}
        </>
      ) : (
        <>
          <p className={`${large ? 'text-3xl font-extrabold tracking-tight' : 'text-xl font-bold tracking-tight'} text-primary leading-none`}>
            {value ?? '—'}
          </p>
          {sub && <p className="text-[11px] text-secondary mt-1.5 leading-snug">{sub}</p>}
        </>
      )}
    </div>
  );
}
