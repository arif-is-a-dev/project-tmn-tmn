import React, { useState, useEffect, useRef } from 'react';
import { Menu, Wifi, WifiOff } from 'lucide-react';
import { probeApi } from '../../services/api.js';

const HEALTH_POLL_MS = 30_000;

export default function TopBar({ onMenuToggle }) {
  const [apiStatus, setApiStatus] = useState('checking');
  const ctrlRef = useRef(null);

  useEffect(() => {
    let timer;
    async function check() {
      if (ctrlRef.current) ctrlRef.current.abort();
      const ctrl = new AbortController();
      ctrlRef.current = ctrl;
      const timeout = setTimeout(() => ctrl.abort(), 8_000);
      try {
        const result = await probeApi();
        clearTimeout(timeout);
        if (ctrlRef.current !== ctrl) return;
        setApiStatus(result ? 'ok' : 'error');
      } catch {
        clearTimeout(timeout);
        if (ctrlRef.current !== ctrl) return;
        setApiStatus('error');
      }
    }
    check();
    timer = setInterval(check, HEALTH_POLL_MS);
    return () => { clearInterval(timer); if (ctrlRef.current) ctrlRef.current.abort(); };
  }, []);

  return (
    <header className="h-12 flex-shrink-0 flex items-center justify-between px-6 border-b border-border bg-bg z-10">
      <div className="flex items-center gap-3">
        <button
          onClick={onMenuToggle}
          className="lg:hidden p-1.5 -ml-1.5 text-secondary hover:text-primary rounded transition-colors"
          aria-label="Buka navigasi"
        >
          <Menu size={18} />
        </button>
      </div>

      <div className="flex items-center gap-3">
        {apiStatus === 'checking' && (
          <span className="flex items-center gap-1.5 text-2xs text-muted">
            <span className="w-1.5 h-1.5 rounded-full bg-muted animate-pulse" />
          </span>
        )}
        {apiStatus === 'ok' && (
          <span className="flex items-center gap-1.5 text-2xs font-medium text-success">
            <Wifi size={10} />
            <span className="hidden sm:inline">API connected</span>
          </span>
        )}
        {apiStatus === 'error' && (
          <span className="flex items-center gap-1.5 text-2xs font-medium text-danger">
            <WifiOff size={10} />
            <span className="hidden sm:inline">Offline</span>
          </span>
        )}
      </div>
    </header>
  );
}
