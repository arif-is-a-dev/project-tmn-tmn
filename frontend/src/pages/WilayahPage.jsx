import React, { useState, useEffect, useRef } from 'react';
import { motion } from 'framer-motion';
import { MapPin, Map } from 'lucide-react';
import { getKalurahanList, getPadukuhanList, getWilayahSummary } from '../services/api.js';
import { formatNumber } from '../services/formatters.js';
import { SkeletonTable } from '../components/ui/Skeleton.jsx';
import ErrorState from '../components/ui/ErrorState.jsx';
import { EmptyState } from '../components/ui/EmptyState.jsx';
import { Badge } from '../components/ui/Badge.jsx';
import { StatCard } from '../components/ui/StatCard.jsx';
import { Pagination } from '../components/ui/Pagination.jsx';

/* -- Kalurahan table --------------------------------------------------------- */
function KalurahanTable({ items }) {
  if (!items.length) return null;
  return (
    <div className="surface overflow-hidden">
      <div className="overflow-x-auto">
        <table className="data-table w-full text-sm">
          <thead>
            <tr>
              <th className="text-left px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted">Kalurahan</th>
              <th className="text-right px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted hidden sm:table-cell">Luas (ha)</th>
              <th className="text-center px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted">Padukuhan</th>
              <th className="text-center px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted hidden md:table-cell">RW</th>
              <th className="text-center px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted hidden md:table-cell">RT</th>
              <th className="text-right px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted hidden lg:table-cell">Kec. (km)</th>
              <th className="text-right px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted hidden lg:table-cell">Kab. (km)</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border-subtle">
            {items.map(k => (
              <tr key={k.kalurahan_id} className="hover:bg-surface-alt transition-colors">
                <td className="px-4 py-3">
                  <p className="font-medium text-primary text-[13px] leading-snug">{k.kalurahan}</p>
                  <p className="text-xs text-muted font-mono mt-0.5">{k.kalurahan_id}</p>
                </td>
                <td className="px-4 py-3 text-right text-xs text-secondary hidden sm:table-cell">
                  {k.luas_kalurahan_ha != null ? formatNumber(k.luas_kalurahan_ha) : '—'}
                </td>
                <td className="px-4 py-3 text-center">
                  <Badge variant="accent">{k.jumlah_padukuhan ?? '—'}</Badge>
                </td>
                <td className="px-4 py-3 text-center text-xs text-secondary hidden md:table-cell">{k.jumlah_rw ?? '—'}</td>
                <td className="px-4 py-3 text-center text-xs text-secondary hidden md:table-cell">{k.jumlah_rt ?? '—'}</td>
                <td className="px-4 py-3 text-right text-xs text-secondary hidden lg:table-cell">
                  {k.jarak_kecamatan_km != null ? k.jarak_kecamatan_km : '—'}
                </td>
                <td className="px-4 py-3 text-right text-xs text-secondary hidden lg:table-cell">
                  {k.jarak_kabupaten_km != null ? k.jarak_kabupaten_km : '—'}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

/* -- Padukuhan table --------------------------------------------------------- */
function PadukuhanTable({ items }) {
  if (!items.length) return null;
  return (
    <div className="surface overflow-hidden">
      <div className="overflow-x-auto">
        <table className="data-table w-full text-sm">
          <thead>
            <tr>
              <th className="text-left px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted">Padukuhan</th>
              <th className="text-left px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted">Kalurahan</th>
              <th className="text-center px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted hidden sm:table-cell">RW</th>
              <th className="text-center px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted hidden sm:table-cell">RT</th>
              <th className="text-right px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted hidden md:table-cell">Latitude</th>
              <th className="text-right px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted hidden md:table-cell">Longitude</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border-subtle">
            {items.map(p => (
              <tr key={p.padukuhan_id} className="hover:bg-surface-alt transition-colors">
                <td className="px-4 py-3">
                  <p className="font-medium text-primary text-[13px] leading-snug">{p.padukuhan}</p>
                  <p className="text-xs text-muted font-mono mt-0.5">{p.padukuhan_id}</p>
                </td>
                <td className="px-4 py-3 text-xs text-secondary">{p.kalurahan}</td>
                <td className="px-4 py-3 text-center text-xs text-secondary hidden sm:table-cell">{p.jumlah_rw ?? '—'}</td>
                <td className="px-4 py-3 text-center text-xs text-secondary hidden sm:table-cell">{p.jumlah_rt ?? '—'}</td>
                <td className="px-4 py-3 text-right text-xs text-muted font-mono hidden md:table-cell">
                  {p.latitude != null ? p.latitude.toFixed(5) : '—'}
                </td>
                <td className="px-4 py-3 text-right text-xs text-muted font-mono hidden md:table-cell">
                  {p.longitude != null ? p.longitude.toFixed(5) : '—'}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

/* -- Page -------------------------------------------------------------------- */
export default function WilayahPage() {
  const [tab, setTab] = useState('kalurahan'); // 'kalurahan' | 'padukuhan'
  const [summary, setSummary] = useState(null);
  const [summaryLoading, setSummaryLoading] = useState(true);

  // Kalurahan state
  const [kItems, setKItems] = useState([]);
  const [kTotal, setKTotal] = useState(0);
  const [kPage, setKPage] = useState(1);
  const [kLoading, setKLoading] = useState(true);
  const [kError, setKError] = useState(null);
  const kAbortRef = useRef(null);

  // Padukuhan state
  const [pItems, setPItems] = useState([]);
  const [pTotal, setPTotal] = useState(0);
  const [pPage, setPPage] = useState(1);
  const [pFilter, setPFilter] = useState('');
  const [pLoading, setPLoading] = useState(true);
  const [pError, setPError] = useState(null);
  const pAbortRef = useRef(null);

  const K_PER_PAGE = 10;
  const P_PER_PAGE = 20;

  // Load summary on mount
  useEffect(() => {
    let cancelled = false;
    setSummaryLoading(true);
    getWilayahSummary().then(s => {
      if (!cancelled) { setSummary(s); setSummaryLoading(false); }
    }).catch(() => {
      if (!cancelled) setSummaryLoading(false);
    });
    return () => { cancelled = true; };
  }, []);

  // Fetch kalurahan
  useEffect(() => {
    if (kAbortRef.current) kAbortRef.current.abort();
    const ctrl = new AbortController();
    kAbortRef.current = ctrl;
    setKLoading(true);
    setKError(null);
    getKalurahanList({ page: kPage, per_page: K_PER_PAGE, signal: ctrl.signal })
      .then(data => {
        if (kAbortRef.current !== ctrl) return;
        setKItems(data.items || []);
        setKTotal(data.total || 0);
      })
      .catch(err => {
        if (err.name === 'AbortError' || err.name === 'CanceledError') return;
        if (kAbortRef.current !== ctrl) return;
        setKError(err.message);
      })
      .finally(() => {
        if (kAbortRef.current === ctrl) setKLoading(false);
      });
  }, [kPage]);

  // Fetch padukuhan
  useEffect(() => {
    if (pAbortRef.current) pAbortRef.current.abort();
    const ctrl = new AbortController();
    pAbortRef.current = ctrl;
    setPLoading(true);
    setPError(null);
    const params = { page: pPage, per_page: P_PER_PAGE, signal: ctrl.signal };
    if (pFilter) params.kalurahan_id = pFilter;
    getPadukuhanList(params)
      .then(data => {
        if (pAbortRef.current !== ctrl) return;
        setPItems(data.items || []);
        setPTotal(data.total || 0);
      })
      .catch(err => {
        if (err.name === 'AbortError' || err.name === 'CanceledError') return;
        if (pAbortRef.current !== ctrl) return;
        setPError(err.message);
      })
      .finally(() => {
        if (pAbortRef.current === ctrl) setPLoading(false);
      });
  }, [pPage, pFilter]);

  // Reset padukuhan page when filter changes
  useEffect(() => { setPPage(1); }, [pFilter]);

  // Kalurahan list from summary for filter dropdown (each item has kalurahan_id + kalurahan name)
  const kalurahanOptions = summary?.kalurahan_list || [];

  return (
    <motion.div
      className="max-w-6xl mx-auto space-y-5"
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0, transition: { duration: 0.22, ease: 'easeOut' } }}
    >
      {/* Header */}
      <div>
        <h1 className="text-xl font-bold text-primary">Data Wilayah</h1>
        <p className="text-sm text-secondary mt-0.5">
          Hierarki wilayah Desa Cangkringan: kalurahan dan padukuhan
        </p>
      </div>

      {/* Summary cards */}
      <div className="grid grid-cols-2 lg:grid-cols-3 gap-3">
        <StatCard label="Kalurahan" value={formatNumber(summary?.total_kalurahan)} loading={summaryLoading} />
        <StatCard label="Padukuhan" value={formatNumber(summary?.total_padukuhan)} loading={summaryLoading} />
        <StatCard label="Hierarki" value={summary ? `${summary.total_kalurahan} → ${summary.total_padukuhan}` : undefined} sub="Kalurahan → Padukuhan" loading={summaryLoading} />
      </div>

      {/* Tab switcher */}
      <div className="bg-surface-alt p-1 rounded border border-border w-fit">
        <button
          onClick={() => setTab('kalurahan')}
          className={`px-4 py-2 text-sm font-medium rounded-md transition-colors ${
            tab === 'kalurahan'
              ? 'bg-surface text-primary shadow-sm border border-border'
              : 'text-muted hover:text-primary'
          }`}
        >
          Kalurahan
        </button>
        <button
          onClick={() => setTab('padukuhan')}
          className={`px-4 py-2 text-sm font-medium rounded-md transition-colors ${
            tab === 'padukuhan'
              ? 'bg-surface text-primary shadow-sm border border-border'
              : 'text-muted hover:text-primary'
          }`}
        >
          Padukuhan
        </button>
      </div>

      {/* Kalurahan tab */}
      {tab === 'kalurahan' && (
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <p className="text-xs text-muted">
              {kTotal > 0 ? `${kTotal} kalurahan` : kLoading ? 'Memuat…' : 'Tidak ada data'}
            </p>
          </div>
          {kLoading ? (
            <SkeletonTable rows={5} cols={7} />
          ) : kError ? (
            <ErrorState message={kError} onRetry={() => setKPage(p => p)} />
          ) : kItems.length === 0 ? (
            <EmptyState icon={Map} title="Tidak ada data kalurahan" description="Tabel kalurahan kosong di database." />
          ) : (
            <>
              <KalurahanTable items={kItems} />
              <Pagination page={kPage} total={kTotal} perPage={K_PER_PAGE} onPage={setKPage} />
            </>
          )}
        </div>
      )}

      {/* Padukuhan tab */}
      {tab === 'padukuhan' && (
        <div className="space-y-3">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
            <p className="text-xs text-muted">
              {pTotal > 0 ? `${pTotal} padukuhan` : pLoading ? 'Memuat…' : 'Tidak ada data'}
            </p>
            {/* Filter by kalurahan — uses kalurahan_id as value, displays name */}
            {kalurahanOptions.length > 0 && (
              <select
                value={pFilter}
                onChange={e => setPFilter(e.target.value)}
                className="text-sm bg-surface border border-border text-primary rounded-md px-3 py-1.5 focus:outline-none focus:border-accent max-w-[200px]"
              >
                <option value="">Semua kalurahan</option>
                {kalurahanOptions.map(k => (
                  <option key={k.kalurahan_id} value={k.kalurahan_id}>{k.kalurahan}</option>
                ))}
              </select>
            )}
          </div>
          {pLoading ? (
            <SkeletonTable rows={8} cols={6} />
          ) : pError ? (
            <ErrorState message={pError} onRetry={() => setPPage(p => p)} />
          ) : pItems.length === 0 ? (
            <EmptyState icon={MapPin} title="Tidak ada padukuhan ditemukan" description={pFilter ? 'Coba ubah filter kalurahan.' : 'Tabel padukuhan kosong di database.'} />
          ) : (
            <>
              <PadukuhanTable items={pItems} />
              <Pagination page={pPage} total={pTotal} perPage={P_PER_PAGE} onPage={setPPage} />
            </>
          )}
        </div>
      )}
    </motion.div>
  );
}
