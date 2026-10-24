import React, { useState, useEffect, useRef } from 'react';
import { motion } from 'framer-motion';
import { ShoppingCart, TrendingUp, Package, Calendar, Filter, AlertTriangle, BrainCircuit, BarChart3, Table2, Play, X as XIcon } from 'lucide-react';
import { getSales, getSalesSummary, getForecastSummary, getForecasts, postCustomForecast } from '../services/api.js';
import { formatNumber, formatRupiah } from '../services/formatters.js';
import { SkeletonTable } from '../components/ui/Skeleton.jsx';
import ErrorState from '../components/ui/ErrorState.jsx';
import { EmptyState } from '../components/ui/EmptyState.jsx';
import { Badge } from '../components/ui/Badge.jsx';
import { StatCard } from '../components/ui/StatCard.jsx';
import { Pagination } from '../components/ui/Pagination.jsx';

const PER_PAGE = 20;
const FORECAST_PER_PAGE = 24;

/* -- Channel breakdown ------------------------------------------------------- */
function ChannelBreakdown({ channels }) {
  if (!channels || !channels.length) return null;
  const maxRevenue = Math.max(...channels.map(c => c.total_revenue), 1);
  return (
    <div className="surface overflow-hidden">
      <div className="px-4 py-3 border-b border-border-subtle">
        <h3 className="text-[13px] font-semibold text-primary">Penjualan per Kanal</h3>
      </div>
      <div className="p-3 space-y-2.5">
        {channels.map((ch, i) => (
          <div key={ch.kanal || `channel-${i}`}>
            <div className="flex items-center justify-between text-[11px] mb-0.5">
              <span className="font-medium text-primary">{ch.kanal || 'Tidak dikategorikan'}</span>
              <span className="text-secondary">{formatRupiah(ch.total_revenue)} ({formatNumber(ch.count)} transaksi)</span>
            </div>
            <div className="h-1.5 bg-surface-alt rounded-full overflow-hidden">
              <div
                className="h-full bg-accent rounded-full transition-all duration-500"
                style={{ width: `${Math.min((ch.total_revenue / maxRevenue) * 100, 100)}%` }}
              />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

/* -- Sales table ------------------------------------------------------------- */
function SalesTable({ items }) {
  if (!items.length) return null;
  return (
    <div className="surface overflow-hidden">
      <div className="overflow-x-auto">
        <table className="data-table w-full text-sm">
          <thead>
            <tr className="bg-surface-alt border-b border-border">
              <th className="text-left px-4 py-2.5 text-[10px] font-semibold uppercase tracking-wider text-muted">Produk</th>
              <th className="text-left px-4 py-2.5 text-[10px] font-semibold uppercase tracking-wider text-muted hidden sm:table-cell">Bulan</th>
              <th className="text-right px-4 py-2.5 text-[10px] font-semibold uppercase tracking-wider text-muted">Terjual</th>
              <th className="text-right px-4 py-2.5 text-[10px] font-semibold uppercase tracking-wider text-muted hidden md:table-cell">Harga Satuan</th>
              <th className="text-right px-4 py-2.5 text-[10px] font-semibold uppercase tracking-wider text-muted">Total</th>
              <th className="text-left px-4 py-2.5 text-[10px] font-semibold uppercase tracking-wider text-muted hidden lg:table-cell">Kanal</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border-subtle">
            {items.map(s => (
              <tr key={s.penjualan_id} className="hover:bg-surface-alt/50 transition-colors">
                <td className="px-4 py-2.5">
                  <p className="font-medium text-primary text-[13px] leading-snug break-words">{s.produk}</p>
                  <p className="text-[11px] text-muted font-mono mt-0.5 sm:hidden">
                    {new Date(s.bulan).toLocaleDateString('id-ID', { month: 'short', year: 'numeric' })}
                  </p>
                </td>
                <td className="px-4 py-2.5 text-xs text-secondary hidden sm:table-cell whitespace-nowrap">
                  {new Date(s.bulan).toLocaleDateString('id-ID', { month: 'long', year: 'numeric' })}
                </td>
                <td className="px-4 py-2.5 text-right">
                  <span className="text-xs text-secondary">{formatNumber(s.jumlah_terjual)}</span>
                  {s.satuan && <span className="text-[10px] text-muted ml-1">{s.satuan}</span>}
                </td>
                <td className="px-4 py-2.5 text-right text-xs text-secondary hidden md:table-cell">
                  {formatRupiah(s.harga_satuan)}
                </td>
                <td className="px-4 py-2.5 text-right font-medium text-primary text-xs">
                  {formatRupiah(s.total_penjualan)}
                </td>
                <td className="px-4 py-2.5 hidden lg:table-cell">
                  {s.kanal ? (
                    <Badge variant="accent">{s.kanal}</Badge>
                  ) : (
                    <span className="text-[11px] text-muted">{'—'}</span>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

/* -- Forecast Section -------------------------------------------------------- */

/** Monthly bar chart for forecast totals — fills container width */
function ForecastMonthlyChart({ byMonth, title }) {
  if (!byMonth || !byMonth.length) return null;
  const maxVal = Math.max(...byMonth.map(m => m.total), 1);
  // For >24 months: horizontal scroll with fixed bar width.
  // For ≤24 months: bars flex to fill container width proportionally.
  const needsScroll = byMonth.length > 24;

  return (
    <div className="surface overflow-hidden">
      <div className="px-4 py-3 border-b border-border-subtle flex items-center gap-2">
        <BarChart3 size={14} className="text-accent" />
        <h3 className="text-[13px] font-semibold text-primary">{title || 'Prediksi Bulanan'}</h3>
      </div>
      <div className="p-4">
        <div className="w-full overflow-x-auto">
          <div
            className="flex items-end gap-1 h-48"
            style={{
              /* For >24 months: set exact width so bars maintain readable size and scroll.
                 For ≤24 months: no width constraint, flex-1 bars fill container proportionally. */
              width: needsScroll ? `${byMonth.length * 32}px` : undefined,
              minWidth: needsScroll ? `${byMonth.length * 32}px` : undefined,
            }}
          >
            {byMonth.map((m) => {
              const pct = Math.max((m.total / maxVal) * 100, 2);
              const date = new Date(m.bulan);
              const label = date.toLocaleDateString('id-ID', { month: 'short', year: '2-digit' });
              return (
                <div
                  key={m.bulan}
                  className={`${needsScroll ? 'w-7 flex-shrink-0' : 'flex-1 min-w-0'} h-full flex flex-col justify-end items-center group relative`}
                >
                  {/* Tooltip */}
                  <div className="absolute bottom-full mb-2 left-1/2 -translate-x-1/2 bg-primary text-surface text-[10px] px-2 py-1 rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap pointer-events-none z-10">
                    {label}: {formatNumber(m.total)}
                  </div>
                  <div
                    className="w-full bg-accent rounded-t-sm transition-all duration-500 hover:bg-accent/90"
                    style={{ height: `${pct}%` }}
                  />
                  <span className={`text-[9px] text-muted mt-1.5 w-full text-center flex-shrink-0 leading-none ${needsScroll ? '' : 'truncate'}`}>{label}</span>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}

/** Per-product forecast summary table */
function ForecastProductTable({ byProduct, title }) {
  if (!byProduct || !byProduct.length) return null;
  return (
    <div className="surface overflow-hidden">
      <div className="px-4 py-3 border-b border-border-subtle flex items-center gap-2">
        <Table2 size={14} className="text-accent" />
        <h3 className="text-[13px] font-semibold text-primary">{title || 'Prediksi per Produk'}</h3>
      </div>
      <div className="overflow-x-auto">
        <table className="data-table w-full text-sm">
          <thead>
            <tr className="bg-surface-alt border-b border-border">
              <th className="text-left px-4 py-2.5 text-[10px] font-semibold uppercase tracking-wider text-muted">Produk</th>
              <th className="text-right px-4 py-2.5 text-[10px] font-semibold uppercase tracking-wider text-muted">Total Prediksi</th>
              <th className="text-right px-4 py-2.5 text-[10px] font-semibold uppercase tracking-wider text-muted">Rata-rata/Bulan</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border-subtle">
            {byProduct.map((p, i) => (
              <tr key={p.produk || i} className="hover:bg-surface-alt/50 transition-colors">
                <td className="px-4 py-2.5 font-medium text-primary text-[13px]">{p.produk}</td>
                <td className="px-4 py-2.5 text-right text-xs text-secondary">{formatNumber(p.total)}</td>
                <td className="px-4 py-2.5 text-right text-xs text-secondary">{formatNumber(p.rata_rata)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

/** Quality warning banner for forecasts */
function ForecastQualityWarning({ warning, metadata }) {
  const wape = metadata?.metrics?.test_2025?.wape;
  return (
    <div className="border-l-2 border-warning pl-3 py-1.5">
      <div className="flex gap-2.5">
        <AlertTriangle size={14} className="text-warning flex-shrink-0 mt-0.5" />
        <div className="min-w-0">
          <h4 className="text-[11px] font-semibold text-warning mb-0.5">Peringatan Kualitas Model</h4>
          <p className="text-[11px] text-secondary leading-relaxed">{warning}</p>
          {wape != null && (
            <p className="text-[10px] text-muted mt-1.5 font-mono">
              WAPE test (2025): {wape.toFixed(2)}% | MAE: {metadata?.metrics?.test_2025?.mae?.toFixed(2)} | RMSE: {metadata?.metrics?.test_2025?.rmse?.toFixed(2)}
            </p>
          )}
        </div>
      </div>
    </div>
  );
}

/** Paginated forecast detail table */
function ForecastDetailTable({ items, loading, error, onRetry }) {
  if (loading) return <SkeletonTable rows={6} cols={4} />;
  if (error) return <ErrorState message={error} onRetry={onRetry} />;
  if (!items || !items.length) return <EmptyState icon={BrainCircuit} title="Tidak ada prediksi" description="Model tidak menghasilkan prediksi." />;

  return (
    <div className="surface overflow-hidden">
      <div className="overflow-x-auto">
        <table className="data-table w-full text-sm">
          <thead>
            <tr className="bg-surface-alt border-b border-border">
              <th className="text-left px-4 py-2.5 text-[10px] font-semibold uppercase tracking-wider text-muted">Bulan</th>
              <th className="text-left px-4 py-2.5 text-[10px] font-semibold uppercase tracking-wider text-muted">Produk</th>
              <th className="text-right px-4 py-2.5 text-[10px] font-semibold uppercase tracking-wider text-muted">Prediksi Volume</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border-subtle">
            {items.map((item, i) => (
              <tr key={`${item.bulan}-${item.produk}-${i}`} className="hover:bg-surface-alt/50 transition-colors">
                <td className="px-4 py-2.5 text-xs text-secondary whitespace-nowrap">
                  {new Date(item.bulan).toLocaleDateString('id-ID', { month: 'long', year: 'numeric' })}
                </td>
                <td className="px-4 py-2.5 font-medium text-primary text-[13px]">{item.produk}</td>
                <td className="px-4 py-2.5 text-right">
                  <span className="inline-flex items-center gap-1.5">
                    <span className="text-xs text-secondary">{formatNumber(item.prediksi_penjualan)}</span>
                    <Badge variant="accent">prediksi</Badge>
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

/** Full forecast section with tabs and custom date range support */
function ForecastSection() {
  // Default (2026) forecast state
  const [summary, setSummary] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [tab, setTab] = useState('overview'); // 'overview' | 'detail' | 'custom'

  // Detail list state (for default 2026 detail tab)
  const [detailItems, setDetailItems] = useState([]);
  const [detailTotal, setDetailTotal] = useState(0);
  const [detailPage, setDetailPage] = useState(1);
  const [detailLoading, setDetailLoading] = useState(false);
  const [detailError, setDetailError] = useState(null);
  const [filterProduk, setFilterProduk] = useState('');
  const abortRef = useRef(null);

  // Custom forecast state
  const [customStart, setCustomStart] = useState('2026-03-15');
  const [customEnd, setCustomEnd] = useState('2027-08-20');
  const [customProduk, setCustomProduk] = useState('');
  const [customResult, setCustomResult] = useState(null);
  const [customLoading, setCustomLoading] = useState(false);
  const [customError, setCustomError] = useState(null);
  const [customValidation, setCustomValidation] = useState(null);
  const customAbortRef = useRef(null);

  // Load default summary on mount
  const summaryAbortRef = useRef(null);
  useEffect(() => {
    if (summaryAbortRef.current) summaryAbortRef.current.abort();
    const ctrl = new AbortController();
    summaryAbortRef.current = ctrl;
    setLoading(true);
    setError(null);
    getForecastSummary(ctrl.signal)
      .then(data => {
        if (summaryAbortRef.current !== ctrl) return;
        if (data.status === 'ok') {
          setSummary(data);
        } else {
          setError(data.error_message || 'Model tidak tersedia.');
        }
        setLoading(false);
      })
      .catch(err => {
        if (err.name === 'AbortError' || err.name === 'CanceledError') return;
        if (summaryAbortRef.current !== ctrl) return;
        setError(err.message);
        setLoading(false);
      });
    return () => { ctrl.abort(); };
  }, []);

  // Load detail list when tab switches or filters change
  useEffect(() => {
    if (tab !== 'detail') return;
    if (abortRef.current) abortRef.current.abort();
    const ctrl = new AbortController();
    abortRef.current = ctrl;
    setDetailLoading(true);
    setDetailError(null);

    const params = { page: detailPage, per_page: FORECAST_PER_PAGE, signal: ctrl.signal };
    if (filterProduk) params.produk = filterProduk;

    getForecasts(params)
      .then(data => {
        if (abortRef.current !== ctrl) return;
        setDetailItems(data.items || []);
        setDetailTotal(data.total || 0);
      })
      .catch(err => {
        if (err.name === 'AbortError' || err.name === 'CanceledError') return;
        if (abortRef.current !== ctrl) return;
        setDetailError(err.message);
      })
      .finally(() => {
        if (abortRef.current === ctrl) setDetailLoading(false);
      });
  }, [tab, detailPage, filterProduk]);

  // Reset page on filter change
  useEffect(() => { setDetailPage(1); }, [filterProduk]);

  // Run custom forecast
  const runCustomForecast = () => {
    // Client-side validation before sending
    if (!customStart || !customEnd) {
      setCustomValidation('Kedua tanggal wajib diisi.');
      return;
    }
    const startDate = new Date(customStart);
    const endDate = new Date(customEnd);
    if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
      setCustomValidation('Format tanggal tidak valid.');
      return;
    }
    // Compare year-month only
    const startYM = startDate.getFullYear() * 12 + startDate.getMonth();
    const endYM = endDate.getFullYear() * 12 + endDate.getMonth();
    if (endYM < startYM) {
      setCustomValidation('Tanggal akhir tidak boleh sebelum tanggal mulai.');
      return;
    }
    const monthCount = endYM - startYM + 1;
    if (monthCount > 36) {
      setCustomValidation(`Rentang ${monthCount} bulan melampaui batas maksimum 36 bulan.`);
      return;
    }

    setCustomValidation(null);
    setCustomError(null);
    setCustomResult(null);

    if (customAbortRef.current) customAbortRef.current.abort();
    const ctrl = new AbortController();
    customAbortRef.current = ctrl;
    setCustomLoading(true);

    const params = { start_date: customStart, end_date: customEnd, signal: ctrl.signal };
    if (customProduk.trim()) params.produk = customProduk.trim();

    postCustomForecast(params)
      .then(data => {
        if (customAbortRef.current !== ctrl) return;
        if (data.status === 'ok') {
          setCustomResult(data);
        } else {
          setCustomError(data.error_message || 'Gagal menghasilkan prediksi.');
        }
      })
      .catch(err => {
        if (err.name === 'AbortError' || err.name === 'CanceledError') return;
        if (customAbortRef.current !== ctrl) return;
        setCustomError(err.message);
      })
      .finally(() => {
        if (customAbortRef.current === ctrl) setCustomLoading(false);
      });
  };

  // Clear custom results when switching away from custom tab
  useEffect(() => {
    if (tab !== 'custom') {
      // Don't clear results — user may want to come back
    }
  }, [tab]);

  if (loading) {
    return (
      <div className="space-y-3">
        <div className="flex items-center gap-2 mb-1">
          <BrainCircuit size={14} className="text-accent" />
          <h2 className="text-sm font-bold text-primary">Prediksi Penjualan</h2>
        </div>
        <SkeletonTable rows={4} cols={3} />
      </div>
    );
  }

  if (error) {
    return (
      <div className="surface p-4 flex gap-3">
        <div className="w-8 h-8 rounded bg-surface-alt flex items-center justify-center flex-shrink-0">
          <BrainCircuit size={16} className="text-muted" />
        </div>
        <div className="min-w-0">
          <h3 className="text-[13px] font-semibold text-primary mb-0.5">Prediksi Tidak Tersedia</h3>
          <p className="text-xs text-secondary">{error}</p>
          <button
            onClick={() => {
              if (summaryAbortRef.current) summaryAbortRef.current.abort();
              const ctrl = new AbortController();
              summaryAbortRef.current = ctrl;
              setLoading(true);
              setError(null);
              getForecastSummary(ctrl.signal)
                .then(data => {
                  if (summaryAbortRef.current !== ctrl) return;
                  if (data.status === 'ok') setSummary(data);
                  else setError(data.error_message || 'Model tidak tersedia.');
                })
                .catch(err => {
                  if (err.name === 'AbortError' || err.name === 'CanceledError') return;
                  if (summaryAbortRef.current !== ctrl) return;
                  setError(err.message);
                })
                .finally(() => {
                  if (summaryAbortRef.current === ctrl) setLoading(false);
                });
            }}
            className="mt-3 text-xs text-accent hover:underline"
          >
            Coba lagi
          </button>
        </div>
      </div>
    );
  }

  if (!summary) return null;

  const metrics = summary.model_metadata?.metrics?.test_2025;

  return (
    <div className="space-y-3">
      {/* Section header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded bg-accent/10 flex items-center justify-center flex-shrink-0">
            <BrainCircuit size={16} className="text-accent" />
          </div>
          <div>
            <h2 className="text-sm font-bold text-primary tracking-tight">Prediksi Penjualan</h2>
            <p className="text-[10px] text-muted">ExtraTreesRegressor · Recursive multi-step forecast</p>
          </div>
        </div>
        {metrics && (
          <div className="hidden sm:flex items-center gap-3 text-[10px] font-mono text-muted">
            <span>WAPE {metrics.wape?.toFixed(1)}%</span>
            <span className="w-px h-3 bg-border" />
            <span>MAE {metrics.mae?.toFixed(2)}</span>
            <span className="w-px h-3 bg-border" />
            <span>RMSE {metrics.rmse?.toFixed(2)}</span>
          </div>
        )}
      </div>

      {/* Quality warning */}
      <ForecastQualityWarning warning={summary.quality_warning} metadata={summary.model_metadata} />

      {/* Tab switcher */}
      <div className="bg-surface-alt p-1 rounded border border-border w-fit">
        <div className="flex gap-1">
          <button
            onClick={() => setTab('overview')}
            className={`px-4 py-1.5 text-xs font-medium rounded-md transition-colors ${
              tab === 'overview' ? 'bg-surface text-primary shadow-xs' : 'text-muted hover:text-secondary'
            }`}
          >
            Ringkasan 2026
          </button>
          <button
            onClick={() => setTab('detail')}
            className={`px-4 py-1.5 text-xs font-medium rounded-md transition-colors ${
              tab === 'detail' ? 'bg-surface text-primary shadow-xs' : 'text-muted hover:text-secondary'
            }`}
          >
            Detail 2026
          </button>
          <button
            onClick={() => setTab('custom')}
            className={`px-4 py-1.5 text-xs font-medium rounded-md transition-colors ${
              tab === 'custom' ? 'bg-surface text-primary shadow-xs' : 'text-muted hover:text-secondary'
            }`}
          >
            Custom Range
          </button>
        </div>
      </div>

      {/* ── Overview tab (default 2026) ─────────────────────────────────── */}
      {tab === 'overview' && (
        <motion.div
          initial={{ opacity: 0, y: 4 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.15 }}
          className="space-y-3"
        >
          {/* Summary stat cards */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
            <StatCard
              label="Total Volume Prediksi"
              value={formatNumber(summary.total_predicted_volume)}
              sub={`${summary.products_count} produk × 12 bulan`}
            />
            <StatCard
              label="Produk Diprediksi"
              value={formatNumber(summary.products_count)}
            />
            <StatCard
              label="Total Prediksi"
              value={formatNumber(summary.total_predictions)}
              sub="baris prediksi"
            />
            <StatCard
              label="WAPE Test (2025)"
              value={metrics ? `${metrics.wape?.toFixed(1)}%` : '—'}
              sub={metrics ? `MAE ${metrics.mae?.toFixed(2)}` : undefined}
            />
          </div>

          {/* Chart full-width, product table below in separate panel (per user instruction) */}
          <ForecastMonthlyChart byMonth={summary.by_month} title="Prediksi Bulanan 2026" />
          <ForecastProductTable byProduct={summary.by_product} title="Prediksi per Produk 2026" />
        </motion.div>
      )}

      {/* ── Detail tab (default 2026) ───────────────────────────────────── */}
      {tab === 'detail' && (
        <motion.div
          initial={{ opacity: 0, y: 4 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.15 }}
          className="space-y-3"
        >
          {/* Filter */}
          <div className="relative max-w-xs">
            <input
              type="text"
              value={filterProduk}
              onChange={e => setFilterProduk(e.target.value)}
              placeholder="Filter nama produk…"
              className="w-full pl-8 pr-3 py-2 text-sm bg-surface border border-border rounded-md text-primary focus:outline-none focus:border-accent placeholder:text-muted"
            />
            <Filter size={13} className="absolute left-2.5 top-1/2 -translate-y-1/2 text-muted" />
          </div>

          <p className="text-xs text-muted">
            {detailTotal > 0
              ? `${detailTotal} prediksi${filterProduk ? ' — difilter' : ''}`
              : detailLoading ? 'Memuat…' : 'Tidak ada data'}
          </p>

          <ForecastDetailTable
            items={detailItems}
            loading={detailLoading}
            error={detailError}
            onRetry={() => setDetailPage(p => p)}
          />
          <Pagination page={detailPage} total={detailTotal} perPage={FORECAST_PER_PAGE} onPage={setDetailPage} />
        </motion.div>
      )}

      {/* ── Custom Range tab ────────────────────────────────────────────── */}
      {tab === 'custom' && (
        <motion.div
          initial={{ opacity: 0, y: 4 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.15 }}
          className="space-y-3"
        >
          {/* Input panel — prominent feature */}
          <div className="surface p-5 space-y-4">
            <div className="flex items-center gap-2.5 mb-1">
              <div className="w-7 h-7 rounded bg-accent/10 flex items-center justify-center flex-shrink-0">
                <Calendar size={14} className="text-accent" />
              </div>
              <div>
                <h3 className="text-[13px] font-semibold text-primary">Custom Date Range Forecast</h3>
                <p className="text-[10px] text-muted">Recursive forecasting — setiap prediksi menjadi input lag bulan berikutnya</p>
              </div>
            </div>

            <div className="flex flex-col sm:flex-row gap-3 items-end">
              <div className="flex-1 min-w-0">
                <label className="block text-[10px] font-semibold uppercase tracking-wider text-muted mb-1.5">Tanggal Mulai</label>
                <input
                  type="date"
                  value={customStart}
                  onChange={e => setCustomStart(e.target.value)}
                  className="w-full px-3 py-2 text-sm bg-surface border border-border rounded-md text-primary focus:outline-none focus:border-accent"
                />
              </div>
              <div className="flex-1 min-w-0">
                <label className="block text-[10px] font-semibold uppercase tracking-wider text-muted mb-1.5">Tanggal Akhir</label>
                <input
                  type="date"
                  value={customEnd}
                  onChange={e => setCustomEnd(e.target.value)}
                  className="w-full px-3 py-2 text-sm bg-surface border border-border rounded-md text-primary focus:outline-none focus:border-accent"
                />
              </div>
              <div className="flex-1 min-w-0">
                <label className="block text-[10px] font-semibold uppercase tracking-wider text-muted mb-1.5">Filter Produk (opsional)</label>
                <input
                  type="text"
                  value={customProduk}
                  onChange={e => setCustomProduk(e.target.value)}
                  placeholder="Semua produk"
                  className="w-full px-3 py-2 text-sm bg-surface border border-border rounded-md text-primary focus:outline-none focus:border-accent placeholder:text-muted"
                />
              </div>
              <button
                onClick={runCustomForecast}
                disabled={customLoading}
                className="flex items-center gap-2 px-5 py-2 bg-accent text-accent-text text-sm font-semibold rounded-md
                           hover:bg-accent-dim transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex-shrink-0"
              >
                {customLoading ? (
                  <>
                    <span className="w-3.5 h-3.5 border-2 border-accent-text/30 border-t-accent-text rounded-full animate-spin" />
                    <span>Memproses…</span>
                  </>
                ) : (
                  <>
                    <Play size={14} />
                    <span>Jalankan</span>
                  </>
                )}
              </button>
            </div>

            {/* Validation error */}
            {customValidation && (
              <div className="border-l-2 border-danger pl-3 py-1.5">
                <p className="text-xs text-danger">{customValidation}</p>
              </div>
            )}

            {/* Period info */}
            {customStart && customEnd && !customValidation && (() => {
              const s = new Date(customStart);
              const e = new Date(customEnd);
              const months = (e.getFullYear() - s.getFullYear()) * 12 + (e.getMonth() - s.getMonth()) + 1;
              if (months > 0 && months <= 36) {
                return (
                  <p className="text-[11px] text-muted font-mono">
                    {months} periode bulanan · {s.toLocaleDateString('id-ID', { month: 'short', year: 'numeric' })} – {e.toLocaleDateString('id-ID', { month: 'short', year: 'numeric' })}
                    {customProduk.trim() ? ` · filter: "${customProduk.trim()}"` : ' · semua produk'}
                  </p>
                );
              }
              return null;
            })()}
          </div>

          {/* Custom forecast error */}
          {customError && (
            <div className="surface p-4 flex gap-3">
              <div className="w-8 h-8 rounded bg-danger-bg flex items-center justify-center flex-shrink-0">
                <AlertTriangle size={16} className="text-danger" />
              </div>
              <div className="min-w-0">
                <h3 className="text-[13px] font-semibold text-primary mb-0.5">Forecast Gagal</h3>
                <p className="text-xs text-secondary">{customError}</p>
              </div>
            </div>
          )}

          {/* Custom forecast results */}
          {customResult && (
            <div className="space-y-3">
              {/* Result stat cards */}
              <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
                <StatCard
                  label="Periode"
                  value={`${customResult.total_months} bulan`}
                  sub={`${new Date(customResult.start_period).toLocaleDateString('id-ID', { month: 'short', year: 'numeric' })} – ${new Date(customResult.end_period).toLocaleDateString('id-ID', { month: 'short', year: 'numeric' })}`}
                />
                <StatCard
                  label="Total Volume"
                  value={formatNumber(customResult.total_predicted_volume)}
                />
                <StatCard
                  label="Produk"
                  value={formatNumber(customResult.products_count)}
                  sub={`${customResult.total_predictions} prediksi`}
                />
                <StatCard
                  label="Rata-rata/Bulan"
                  value={formatNumber(Math.round(customResult.total_predicted_volume / customResult.total_months))}
                />
              </div>

              {/* Custom quality warning */}
              <ForecastQualityWarning warning={customResult.quality_warning} metadata={customResult.model_metadata} />

              {/* Chart full-width, product table below in separate panel (per user instruction) */}
              <ForecastMonthlyChart
                byMonth={customResult.by_month}
                title={`Prediksi Bulanan: ${new Date(customResult.start_period).toLocaleDateString('id-ID', { month: 'short', year: 'numeric' })} – ${new Date(customResult.end_period).toLocaleDateString('id-ID', { month: 'short', year: 'numeric' })}`}
              />
              <ForecastProductTable
                byProduct={customResult.by_product}
                title="Prediksi per Produk (Custom Range)"
              />

              {/* Detail items table */}
              <div className="surface overflow-hidden">
                <div className="px-4 py-3 border-b border-border-subtle flex items-center gap-2">
                  <Table2 size={14} className="text-accent" />
                  <h3 className="text-[13px] font-semibold text-primary">Detail Prediksi ({customResult.total_predictions} baris)</h3>
                </div>
                <div className="overflow-x-auto max-h-[500px] overflow-y-auto">
                  <table className="data-table w-full text-sm">
                    <thead className="sticky top-0 bg-surface-alt z-10">
                      <tr className="border-b border-border">
                        <th className="text-left px-4 py-2.5 text-[10px] font-semibold uppercase tracking-wider text-muted">Bulan</th>
                        <th className="text-left px-4 py-2.5 text-[10px] font-semibold uppercase tracking-wider text-muted">Produk</th>
                        <th className="text-right px-4 py-2.5 text-[10px] font-semibold uppercase tracking-wider text-muted">Prediksi Volume</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-border-subtle">
                      {customResult.items.map((item, i) => (
                        <tr key={`${item.bulan}-${item.produk}-${i}`} className="hover:bg-surface-alt/50 transition-colors">
                          <td className="px-4 py-2.5 text-xs text-secondary whitespace-nowrap">
                            {new Date(item.bulan).toLocaleDateString('id-ID', { month: 'long', year: 'numeric' })}
                          </td>
                          <td className="px-4 py-2.5 font-medium text-primary text-[13px]">{item.produk}</td>
                          <td className="px-4 py-2.5 text-right">
                            <span className="inline-flex items-center gap-1.5">
                              <span className="text-xs text-secondary">{formatNumber(item.prediksi_penjualan)}</span>
                              <Badge variant="accent">prediksi</Badge>
                            </span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

          {/* Empty state when no custom result yet */}
          {!customResult && !customLoading && !customError && !customValidation && (
            <div className="surface p-6 text-center">
              <Calendar size={20} className="text-muted mx-auto mb-2" />
              <p className="text-xs text-secondary">Atur rentang tanggal dan klik "Jalankan" untuk menghasilkan prediksi.</p>
            </div>
          )}
        </motion.div>
      )}
    </div>
  );
}

/* -- Page -------------------------------------------------------------------- */
export default function SalesPage() {
  // Summary state
  const [summary, setSummary] = useState(null);
  const [summaryLoading, setSummaryLoading] = useState(true);

  // List state
  const [items, setItems] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [page, setPage] = useState(1);
  const [filterProduk, setFilterProduk] = useState('');
  const [filterStart, setFilterStart] = useState('');
  const [filterEnd, setFilterEnd] = useState('');
  const abortRef = useRef(null);

  // Load summary on mount
  useEffect(() => {
    let cancelled = false;
    setSummaryLoading(true);
    getSalesSummary().then(s => {
      if (!cancelled) { setSummary(s); setSummaryLoading(false); }
    }).catch(() => {
      if (!cancelled) setSummaryLoading(false);
    });
    return () => { cancelled = true; };
  }, []);

  // Fetch sales list
  useEffect(() => {
    if (abortRef.current) abortRef.current.abort();
    const ctrl = new AbortController();
    abortRef.current = ctrl;
    setLoading(true);
    setError(null);
    const params = { page, per_page: PER_PAGE, signal: ctrl.signal };
    if (filterProduk) params.produk_id = filterProduk;
    if (filterStart)  params.periode_start = filterStart;
    if (filterEnd)    params.periode_end = filterEnd;
    getSales(params)
      .then(data => {
        if (abortRef.current !== ctrl) return;
        setItems(data.items || []);
        setTotal(data.total || 0);
      })
      .catch(err => {
        if (err.name === 'AbortError' || err.name === 'CanceledError') return;
        if (abortRef.current !== ctrl) return;
        setError(err.message);
      })
      .finally(() => {
        if (abortRef.current === ctrl) setLoading(false);
      });
  }, [page, filterProduk, filterStart, filterEnd]);

  // Reset page when filters change
  useEffect(() => { setPage(1); }, [filterProduk, filterStart, filterEnd]);

  // Format period display
  const periodDisplay = summary && summary.period_start && summary.period_end
    ? `${new Date(summary.period_start).toLocaleDateString('id-ID', { month: 'short', year: 'numeric' })} – ${new Date(summary.period_end).toLocaleDateString('id-ID', { month: 'short', year: 'numeric' })}`
    : undefined;

  return (
    <motion.div
      className="max-w-6xl mx-auto space-y-6"
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0, transition: { duration: 0.22, ease: 'easeOut' } }}
    >
      {/* ── Historical Sales Section ─────────────────────────────────────── */}
      <div className="space-y-4">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-xl font-bold text-primary tracking-tight">Data Penjualan</h1>
            <p className="text-xs text-secondary mt-0.5">
              Historis penjualan produk Desa Cangkringan{periodDisplay ? ` (${periodDisplay})` : ''}
            </p>
          </div>
          {summary && !summaryLoading && (
            <span className="text-[10px] text-muted font-mono hidden sm:inline">
              {formatNumber(summary.total_records)} record
            </span>
          )}
        </div>

        {/* Summary + Channel breakdown side by side (SwiftLog-inspired) */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-3">
          <div className="lg:col-span-2">
            <div className="grid grid-cols-2 gap-3">
              <StatCard
                label="Total Pendapatan"
                value={summaryLoading ? undefined : formatRupiah(summary?.total_revenue)}
                sub={!summaryLoading && (filterProduk || filterStart || filterEnd) ? 'Seluruh data (tidak terfilter)' : undefined}
                loading={summaryLoading}
              />
              <StatCard
                label="Volume Terjual"
                value={summaryLoading ? undefined : formatNumber(summary?.total_volume)}
                loading={summaryLoading}
              />
              <StatCard
                label="Record Penjualan"
                value={summaryLoading ? undefined : formatNumber(summary?.total_records)}
                sub={periodDisplay}
                loading={summaryLoading}
              />
              <StatCard
                label="Produk Aktif"
                value={summaryLoading ? undefined : formatNumber(summary?.distinct_products)}
                loading={summaryLoading}
              />
            </div>
          </div>
          <div className="lg:col-span-1">
            {!summaryLoading && summary?.by_channel && summary.by_channel.length > 0 ? (
              <ChannelBreakdown channels={summary.by_channel} />
            ) : (
              <div className="surface h-full flex items-center justify-center p-6">
                <p className="text-xs text-muted">Data kanal tidak tersedia</p>
              </div>
            )}
          </div>
        </div>

        {/* Filters */}
        <div className="flex flex-col sm:flex-row gap-2 items-start sm:items-end">
          <div className="relative flex-1 max-w-xs">
            <input
              type="text"
              value={filterProduk}
              onChange={e => setFilterProduk(e.target.value)}
              placeholder="Filter produk ID…"
              className="w-full pl-8 pr-3 py-2 text-sm bg-surface border border-border rounded-md text-primary focus:outline-none focus:border-accent placeholder:text-muted"
            />
            <Filter size={13} className="absolute left-2.5 top-1/2 -translate-y-1/2 text-muted" />
          </div>
          <div className="flex gap-2">
            <input
              type="date"
              value={filterStart}
              onChange={e => setFilterStart(e.target.value)}
              className="px-3 py-2 text-sm bg-surface border border-border rounded-md text-primary focus:outline-none focus:border-accent"
              title="Periode mulai"
            />
            <input
              type="date"
              value={filterEnd}
              onChange={e => setFilterEnd(e.target.value)}
              className="px-3 py-2 text-sm bg-surface border border-border rounded-md text-primary focus:outline-none focus:border-accent"
              title="Periode akhir"
            />
          </div>
        </div>

        {/* Content */}
        <div className="space-y-3">
          <p className="text-xs text-muted">
            {total > 0
              ? `${total} record penjualan${filterProduk || filterStart || filterEnd ? ' — difilter' : ''}`
              : loading ? 'Memuat…' : 'Tidak ada data'}
          </p>

          {loading ? (
            <SkeletonTable rows={10} cols={6} />
          ) : error ? (
            <ErrorState message={error} onRetry={() => setPage(p => p)} />
          ) : items.length === 0 ? (
            <EmptyState
              icon={ShoppingCart}
              title="Tidak ada data penjualan ditemukan"
              description={filterProduk || filterStart || filterEnd ? 'Coba ubah filter pencarian.' : 'Belum ada data penjualan di database.'}
            />
          ) : (
            <>
              <SalesTable items={items} />
              <Pagination page={page} total={total} perPage={PER_PAGE} onPage={setPage} />
            </>
          )}
        </div>
      </div>

      {/* Divider */}
      <hr className="border-border" />

      {/* ── Forecast Section ─────────────────────────────────────────────── */}
      <ForecastSection />
    </motion.div>
  );
}
