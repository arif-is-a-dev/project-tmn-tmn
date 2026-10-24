import React from 'react';

export function Pagination({ page, total, perPage, onPage }) {
  const totalPages = Math.ceil(total / perPage);
  if (totalPages <= 1) return null;

  const getPageNumbers = () => {
    if (totalPages <= 7) return Array.from({ length: totalPages }, (_, i) => i + 1);
    if (page <= 4) return [1, 2, 3, 4, 5, '…', totalPages];
    if (page >= totalPages - 3) return [1, '…', totalPages - 4, totalPages - 3, totalPages - 2, totalPages - 1, totalPages];
    return [1, '…', page - 1, page, page + 1, '…', totalPages];
  };

  return (
    <div className="flex items-center justify-center gap-1 pt-4 pb-2">
      <button
        onClick={() => onPage(page - 1)}
        disabled={page <= 1}
        className="px-3 py-1.5 text-2xs font-medium border border-border rounded hover:bg-surface-alt disabled:opacity-30 disabled:cursor-not-allowed transition-all text-secondary"
        aria-label="Halaman sebelumnya"
      >
        Prev
      </button>
      {getPageNumbers().map((p, i) =>
        p === '…' ? (
          <span key={`e-${i}`} className="w-7 h-7 flex items-center justify-center text-2xs text-muted">…</span>
        ) : (
          <button
            key={p}
            onClick={() => onPage(p)}
            className={`w-7 h-7 text-2xs font-semibold rounded border transition-all ${
              p === page
                ? 'bg-accent text-accent-text border-accent'
                : 'border-border hover:bg-surface-alt text-secondary'
            }`}
            aria-current={p === page ? 'page' : undefined}
          >
            {p}
          </button>
        )
      )}
      <button
        onClick={() => onPage(page + 1)}
        disabled={page >= totalPages}
        className="px-3 py-1.5 text-2xs font-medium border border-border rounded hover:bg-surface-alt disabled:opacity-30 disabled:cursor-not-allowed transition-all text-secondary"
        aria-label="Halaman berikutnya"
      >
        Next
      </button>
    </div>
  );
}
