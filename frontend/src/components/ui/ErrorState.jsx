import React from 'react';
import { AlertTriangle, RefreshCw } from 'lucide-react';

export default function ErrorState({ message, onRetry }) {
  return (
    <div className="flex flex-col items-center justify-center py-20 px-6 text-center">
      <div className="w-12 h-12 rounded-lg bg-danger-bg flex items-center justify-center mb-4">
        <AlertTriangle size={22} className="text-danger" />
      </div>
      <h3 className="text-base font-semibold text-primary mb-1">Gagal memuat data</h3>
      <p className="text-sm text-secondary max-w-sm mb-5 leading-relaxed">
        {message ? String(message).slice(0, 160) : 'Tidak dapat terhubung ke server.'}
      </p>
      {onRetry && (
        <button
          onClick={onRetry}
          className="inline-flex items-center gap-2 px-4 py-2 bg-accent text-accent-text text-xs font-bold rounded hover:bg-accent-dim transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent focus-visible:ring-offset-2"
        >
          <RefreshCw size={13} />
          Coba lagi
        </button>
      )}
    </div>
  );
}
