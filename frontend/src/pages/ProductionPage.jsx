import React, { useState, useEffect, useCallback, useRef } from 'react';
import { motion } from 'framer-motion';
import { Factory } from 'lucide-react';
import { getProduction, getProductionSummary } from '../services/api.js';
import { formatNumber } from '../services/formatters.js';
import { SkeletonTable } from '../components/ui/Skeleton.jsx';
import ErrorState from '../components/ui/ErrorState.jsx';
import { EmptyState } from '../components/ui/EmptyState.jsx';
import { StatCard } from '../components/ui/StatCard.jsx';
import { Pagination } from '../components/ui/Pagination.jsx';
import { Badge } from '../components/ui/Badge.jsx';

const PER_PAGE = 10;

/* ── Filter bar ────────────────────────────────────────────── */
function FilterBar({ search, setSearch, selectedJenis, setSelectedJenis, selectedPeriode, setSelectedPeriode, jenisOptions, periodeOptions, onReset }) {
  return (
    <div className="flex flex-wrap gap-2">
      {/* Name search */}
      <div className="relative flex-1 min-w-[160px]">
        <input
          type="text"
          value={search}
          onChange={e => setSearch(e.target.value)}
          placeholder="Cari produk…"
          className="w-full pl-8 pr-3 py-2 text-sm bg-surface border border-border rounded-md text-primary placeholder:text-muted focus:outline-none focus:border-accent"
        />
        <svg className="absolute left-2.5 top-1/2 -translate-y-1/2 text-muted" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
        </svg>
      </div>

      {/* Jenis filter */}
      <select
        value={selectedJenis}
        onChange={e => setSelectedJenis(e.target.value)}
        className="pl-3 pr-7 py-2 text-sm bg-surface border border-border rounded-md text-primary focus:outline-none focus:border-accent appearance-none cursor-pointer min-w-[140px]"
      >
        <option value="">Semua jenis</option>
        {jenisOptions.map(j => <option key={j} value={j}>{j}</option>)}
      </select>

      {/* Tahun filter */}
      <select
        value={selectedPeriode}
        onChange={e => setSelectedPeriode(e.target.value)}
        className="pl-3 pr-7 py-2 text-sm bg-surface border border-border rounded-md text-primary focus:outline-none focus:border-accent appearance-none cursor-pointer min-w-[120px]"
      >
        <option value="">Semua tahun</option>
        {periodeOptions.map(p => <option key={p} value={p}>{p}</option>)}
      </select>

      {(search || selectedJenis || selectedPeriode) && (
        <button
          onClick={onReset}
          className="px-3 py-2 text-sm text-secondary hover:text-accent-text border border-border rounded-md hover:border-accent transition-colors"
        >
          Reset
        </button>
      )}
    </div>
  );
}

/* ── Production table ──────────────────────────────────────── */
function ProductionTable({ items }) {
  if (!items.length) return null;
  return (
    <div className="surface overflow-hidden">
      <div className="overflow-x-auto">
        <table className="data-table w-full text-sm">
          <thead>
            <tr>
              <th className="text-left px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted">Produk</th>
              <th className="text-left px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted">Jenis</th>
              <th className="text-right px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted">Prod. Varian</th>
              <th className="text-left px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted">Satuan</th>
              <th className="text-right px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted">Tahun</th>
              <th className="text-right px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted">Stok</th>
              <th className="text-left px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted">Status</th>
            </tr>
          </thead>
          <tbody>
            {items.map(item => (
              <tr key={item.produksi_id}>
                <td className="px-4 py-3">
                  <p className="font-medium text-primary text-xs leading-snug">{item.nama_produk}</p>
                  <p className="text-2xs text-muted font-mono mt-0.5">{item.produk_id}</p>
                </td>
                <td className="px-4 py-3">
                  <span className="text-xs text-secondary">{item.jenis_produk}</span>
                </td>
                <td className="px-4 py-3 text-right font-medium text-primary text-xs">
                  {formatNumber(item.jumlah_produksi_varian)}
                </td>
                <td className="px-4 py-3 text-xs text-secondary">{item.satuan}</td>
                <td className="px-4 py-3 text-right text-xs text-secondary font-medium">
                  {item.periode_produksi}
                </td>
                <td className="px-4 py-3 text-right">
                  {item.stok != null ? (
                    <span className="text-xs text-primary">
                      {formatNumber(item.stok)}{item.satuan_stok ? ` ${item.satuan_stok}` : ''}
                    </span>
                  ) : (
                    <span className="text-xs text-muted">—</span>
                  )}
                </td>
                <td className="px-4 py-3">
                  <Badge variant={item.status_data === 'valid' ? 'success' : 'neutral'}>
                    {item.status_data}
                  </Badge>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

/* ── Page ──────────────────────────────────────────────────── */
export default function ProductionPage() {
  const [items,           setItems]           = useState([]);
  const [total,           setTotal]           = useState(0);
  const [loading,         setLoading]         = useState(true);
  const [error,           setError]           = useState(null);
  const [page,            setPage]            = useState(1);
  const [search,          setSearch]          = useState('');
  const [searchInput,     setSearchInput]      = useState('');
  const [selectedJenis,   setSelectedJenis]    = useState('');
  const [selectedPeriode, setSelectedPeriode]  = useState('');
  const [summary,         setSummary]         = useState(null);
  const [summaryLoading,  setSummaryLoading]  = useState(true);
  const [jenisOptions,     setJenisOptions]    = useState([]);
  const [periodeOptions,  setPeriodeOptions]  = useState([]);
  const abortRef = useRef(null);

  // Debounce search
  useEffect(() => {
    const t = setTimeout(() => setSearch(searchInput), 350);
    return () => clearTimeout(t);
  }, [searchInput]);

  useEffect(() => { setPage(1); }, [search, selectedJenis, selectedPeriode]);

  const fetchData = useCallback(async () => {
    if (abortRef.current) abortRef.current.abort();
    const ctrl = new AbortController();
    abortRef.current = ctrl;

    setLoading(true);
    setError(null);
    try {
      const data = await getProduction({
        page, per_page: PER_PAGE,
        nama_produk:  search || undefined,
        jenis_produk: selectedJenis || undefined,
        periode:      selectedPeriode || undefined,
        signal: ctrl.signal,
      });
      if (abortRef.current !== ctrl) return;
      setItems(data.items ?? []);
      setTotal(data.total ?? 0);
    } catch (err) {
      if (err.name === 'AbortError' || err.name === 'CanceledError') return;
      if (abortRef.current !== ctrl) return;
      setError(err.message);
    } finally {
      if (abortRef.current === ctrl) setLoading(false);
    }
  }, [page, search, selectedJenis, selectedPeriode]);

  useEffect(() => { fetchData(); }, [fetchData]);

  // Load summary (once on mount)
  useEffect(() => {
    let cancelled = false;
    setSummaryLoading(true);
    getProductionSummary()
      .then(d => { if (!cancelled) { setSummary(d); setSummaryLoading(false); } })
      .catch(() => { if (!cancelled) setSummaryLoading(false); });
    return () => { cancelled = true; };
  }, []);

  // Collect filter options from current data for convenience
  useEffect(() => {
    if (!items.length) return;
    const newJenis   = [...new Set(items.map(i => i.jenis_produk))].sort();
    const newPeriode = [...new Set(items.map(i => i.periode_produksi))].sort((a, b) => b - a);
    setJenisOptions(prev => {
      const merged = [...new Set([...prev, ...newJenis])].sort();
      return merged.length > prev.length ? merged : prev;
    });
    setPeriodeOptions(prev => {
      const merged = [...new Set([...prev, ...newPeriode])].sort((a, b) => b - a);
      return merged.length > prev.length ? merged : prev;
    });
  }, [items]);

  const totalLabel = total > 0
    ? `${total} record${selectedJenis || selectedPeriode ? ' — disaring' : ''}`
    : loading ? 'Memuat…' : 'Tidak ada data';

  const summarySection = (
    <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
      <StatCard
        label="Total Record"
        value={formatNumber(summary?.total_records)}
        sub={summary ? `${formatNumber(summary.distinct_products)} produk, ${formatNumber(summary.distinct_periods)} tahun` : undefined}
        loading={summaryLoading}
      />
      <StatCard
        label="Periode"
        value={summary?.latest_period ? String(summary.latest_period) : '—'}
        sub={summary?.earliest_period !== summary?.latest_period
          ? `dari ${summary.earliest_period}`
          : summary?.earliest_period ? String(summary.earliest_period) : undefined}
        loading={summaryLoading}
      />
      <StatCard
        label="Total Produksi"
        value={summary?.total_production_varian != null ? formatNumber(summary.total_production_varian) : '—'}
        sub="jumlah_produksi_varian"
        loading={summaryLoading}
      />
      <StatCard
        label="Total Stok"
        value={summary?.total_stok != null ? formatNumber(summary.total_stok) : '—'}
        sub={summary?.total_stok == null ? 'tidak ada data stok' : 'dari semua record'}
        loading={summaryLoading}
      />
    </div>
  );

  return (
    <motion.div
      className="max-w-6xl mx-auto space-y-5"
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0, transition: { duration: 0.22, ease: 'easeOut' } }}
    >
      {/* Header */}
      <div>
        <h1 className="text-xl font-bold text-primary">Produksi & Stok</h1>
        <p className="text-sm text-secondary mt-0.5">{totalLabel}</p>
      </div>

      {/* Summary cards */}
      {summarySection}

      {/* Pending data note — shown when no production data loaded yet */}
      {!summaryLoading && summary && summary.total_records === 0 && (
        <div className="border-l-2 border-accent pl-4 py-2">
          <p className="text-xs text-secondary leading-relaxed">
            Tabel <code className="text-2xs bg-surface-alt px-1 py-0.5 rounded text-primary font-mono">produksi</code>{' '}
            belum memiliki data yang terisi. Halaman ini akan menampilkan ringkasan dan tabel produksi
            begitu data tersedia.
          </p>
        </div>
      )}

      {/* Filter bar */}
      <FilterBar
        search={searchInput}
        setSearch={setSearchInput}
        selectedJenis={selectedJenis}
        setSelectedJenis={setSelectedJenis}
        selectedPeriode={selectedPeriode}
        setSelectedPeriode={setSelectedPeriode}
        jenisOptions={jenisOptions}
        periodeOptions={periodeOptions}
        onReset={() => { setSearchInput(''); setSelectedJenis(''); setSelectedPeriode(''); }}
      />

      {/* Content */}
      {loading ? (
        <SkeletonTable rows={8} cols={7} />
      ) : error ? (
        <ErrorState message={error} onRetry={fetchData} />
      ) : items.length === 0 ? (
        <EmptyState
          icon={Factory}
          title="Tidak ada data produksi ditemukan"
          description={
            search || selectedJenis || selectedPeriode
              ? 'Coba ubah kata kunci pencarian atau filter.'
              : 'Belum ada data produksi di database.'
          }
        />
      ) : (
        <>
          <ProductionTable items={items} />
          <Pagination page={page} total={total} perPage={PER_PAGE} onPage={setPage} />
        </>
      )}
    </motion.div>
  );
}
