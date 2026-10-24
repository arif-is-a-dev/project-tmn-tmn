import React from 'react';
import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  Leaf,
  Factory,
  ShoppingCart,
  Database,
  Map,
  Layers,
  X,
  Sun,
  Moon,
  Activity,
} from 'lucide-react';
import { useTheme } from '../ThemeProvider.jsx';

const NAV_ITEMS = [
  { to: '/dashboard',         icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/organic-materials', icon: Leaf,             label: 'Bahan Organik' },
  { to: '/production',        icon: Factory,           label: 'Produksi' },
  { to: '/sales',             icon: ShoppingCart,       label: 'Penjualan' },
  { to: '/products',          icon: Database,           label: 'Produk' },
  { to: '/wilayah',           icon: Map,                label: 'Wilayah' },
  { to: '/data',              icon: Layers,             label: 'Data' },
];

function NavItem({ to, icon: Icon, label, onClose }) {
  return (
    <NavLink
      to={to}
      onClick={onClose}
      className={({ isActive }) => `nav-item${isActive ? ' active' : ''}`}
    >
      <Icon size={15} strokeWidth={1.75} />
      <span>{label}</span>
    </NavLink>
  );
}

export default function Sidebar({ onClose }) {
  const { theme, toggle } = useTheme();

  return (
    <div className="flex flex-col h-full">
      {/* ── Zone 1: Brand header ─────────────────────────── */}
      <div className="px-5 py-5 border-b border-white/[0.06] flex-shrink-0">
        <div className="flex items-center gap-2.5">
          <div className="w-7 h-7 rounded bg-accent flex items-center justify-center flex-shrink-0">
            <span className="text-accent-text font-black text-xs leading-none">V7</span>
          </div>
          <div>
            <span className="text-sm font-bold text-[var(--nav-text-active)] tracking-tight leading-none block">
              VINIX7
            </span>
            <span className="text-[9px] text-[var(--nav-text)] mt-0.5 block leading-none tracking-wide uppercase">
              Field Lab
            </span>
          </div>
        </div>
        <button
          onClick={onClose}
          className="lg:hidden absolute top-4 right-4 p-1.5 text-[var(--nav-text)] hover:text-[var(--nav-text-active)] rounded transition-colors"
          aria-label="Tutup navigasi"
        >
          <X size={18} />
        </button>
      </div>

      {/* ── Zone 2: Navigation + Field Status ────────────── */}
      <div className="flex-1 min-h-0 flex flex-col">
        {/* Nav links */}
        <nav className="flex-shrink-0 px-3 py-4 space-y-0.5">
          {NAV_ITEMS.map(item => (
            <NavItem key={item.to} {...item} onClose={onClose} />
          ))}
        </nav>

        {/* Separator */}
        <div className="mx-5 border-t border-white/[0.06]" />

        {/* Field Status panel */}
        <div className="px-5 py-4 flex-shrink-0">
          <div className="flex items-center gap-1.5 mb-2.5">
            <Activity size={10} className="text-[var(--nav-accent)]" />
            <span className="text-[9px] font-semibold uppercase tracking-widest text-[var(--nav-text-active)]">
              Field Status
            </span>
          </div>
          <div className="space-y-1.5">
            <div className="flex items-center justify-between">
              <span className="text-[10px] text-[var(--nav-text)]">Periode data</span>
              <span className="text-[10px] font-mono text-[var(--nav-text-active)]">2020 – 2025</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-[10px] text-[var(--nav-text)]">Sumber</span>
              <span className="text-[10px] font-mono text-[var(--nav-text-active)]">PostgreSQL</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-[10px] text-[var(--nav-text)]">Mode</span>
              <span className="text-[10px] font-mono text-[var(--nav-text-active)]">Read-only</span>
            </div>
          </div>
        </div>
      </div>

      {/* ── Zone 3: Footer / Theme toggle ────────────────── */}
      <div className="px-4 py-4 border-t border-white/[0.06] flex-shrink-0 space-y-2.5">
        <button
          onClick={toggle}
          className="flex items-center gap-2.5 w-full px-3 py-2 rounded-md text-xs font-medium
                     text-[var(--nav-text)] hover:text-[var(--nav-text-active)] hover:bg-white/[0.06]
                     transition-all cursor-pointer"
          aria-label={theme === 'light' ? 'Switch to dark mode' : 'Switch to light mode'}
        >
          {theme === 'light' ? <Moon size={14} /> : <Sun size={14} />}
          <span>{theme === 'light' ? 'Dark mode' : 'Light mode'}</span>
        </button>
        <p className="text-[9px] text-[var(--nav-text)] opacity-70 leading-snug pl-3">
          Desa Cangkringan &copy; 2026
        </p>
      </div>
    </div>
  );
}
