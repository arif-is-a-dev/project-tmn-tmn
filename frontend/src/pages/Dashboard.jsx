import React, { useEffect, useState, useRef } from 'react';
import { Link } from 'react-router-dom';
import {
  ArrowRight, AlertTriangle, CheckCircle2,
} from 'lucide-react';
import {
  getProducts, getHealth, getSalesSummary,
  getOrganicSummary, getOrganicRanking, getProductionSummary,
} from '../services/api.js';
import { SkeletonCard } from '../components/ui/Skeleton.jsx';
import ErrorState from '../components/ui/ErrorState.jsx';
import { Badge } from '../components/ui/Badge.jsx';
import { formatNumber, formatRupiah } from '../services/formatters.js';

export default function Dashboard() {
  const [apiStatus, setApiStatus] = useState('checking');
  const [products, setProducts] = useState({ loading: true, data: null, error: null });
  const [salesSummary, setSalesSummary] = useState({ loading: true, data: null });
  const [organicSummary, setOrganicSummary] = useState({ loading: true, data: null });
  const [organicRankingStatus, setOrganicRankingStatus] = useState({ loading: true, status: null });
  const [prodSummary, setProdSummary] = useState({ loading: true, data: null });
  const healthCtrlRef = useRef(null);
  const productsCtrlRef = useRef(null);

  useEffect(() => {
    const healthCtrl = new AbortController();
    healthCtrlRef.current = healthCtrl;
    getHealth(healthCtrl.signal)
      .then(d => { if (healthCtrlRef.current !== healthCtrl) return; setApiStatus(d?.status === 'ok' ? 'ok' : 'error'); })
      .catch(() => { if (healthCtrlRef.current !== healthCtrl) return; setApiStatus('error'); });

    const productsCtrl = new AbortController();
    productsCtrlRef.current = productsCtrl;
    getProducts({ per_page: 3, signal: productsCtrl.signal })
      .then(d => { if (productsCtrlRef.current !== productsCtrl) return; setProducts({ loading: false, data: d && Array.isArray(d.items) ? d : { ...d, items: [] }, error: null }); })
      .catch(err => { if (productsCtrlRef.current !== productsCtrl) return; setProducts({ loading: false, data: null, error: err.message || 'Gagal memuat' }); });

    getSalesSummary().then(d => setSalesSummary({ loading: false, data: d })).catch(() => setSalesSummary({ loading: false, data: null }));
    getOrganicSummary().then(d => setOrganicSummary({ loading: false, data: d })).catch(() => setOrganicSummary({ loading: false, data: null }));
    getOrganicRanking().then(d => setOrganicRankingStatus({ loading: false, status: d?.status ?? null })).catch(() => setOrganicRankingStatus({ loading: false, status: null }));
    getProductionSummary().then(d => setProdSummary({ loading: false, data: d })).catch(() => setProdSummary({ loading: false, data: null }));

    return () => { healthCtrl.abort(); productsCtrl.abort(); };
  }, []);

  const isDbOk = apiStatus === 'ok';
  const preview = products.data?.items ?? [];

  return (
    <div className="max-w-6xl mx-auto space-y-4">
      {/* ── Header row ─────────────────────────────────────────────── */}
      <div className="flex items-center justify-between pb-2 border-b border-border-subtle mb-2">
        <div>
          <h1 className="text-xl font-bold text-primary tracking-tight leading-none">
            Field Intelligence
          </h1>
          <p className="text-xs text-secondary mt-1">
            Desa Cangkringan &mdash; Yogyakarta
          </p>
        </div>

        {/* Status badge */}
        <div className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-md text-[10px] font-medium border ${
          isDbOk
            ? 'bg-success-bg text-success border-success/20'
            : 'bg-danger-bg text-danger border-danger/20'
        }`}>
          {isDbOk ? <CheckCircle2 size={12} /> : <AlertTriangle size={12} />}
          {isDbOk ? 'PostgreSQL connected' : 'Backend offline'}
          {isDbOk && <span className="text-muted ml-1 font-mono">{new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })}</span>}
        </div>
      </div>

      {/* ── KPI cards — 4 equal-width, no decorative icons ─────────── */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
        {/* Revenue */}
        <div className="surface px-4 py-3.5">
          <span className="text-[10px] font-semibold uppercase tracking-wider text-muted leading-none block mb-1.5">
            Pendapatan Penjualan
          </span>
          {salesSummary.loading ? (
            <div className="skeleton h-7 w-32 mb-1" />
          ) : (
            <p className="text-xl font-bold tracking-tight text-primary leading-none">
              {salesSummary.data ? formatRupiah(salesSummary.data.total_revenue) : '—'}
            </p>
          )}
          {!salesSummary.loading && salesSummary.data && (
            <p className="text-[11px] text-secondary mt-1.5 leading-snug">
              {formatNumber(salesSummary.data.total_records)} transaksi · {formatNumber(salesSummary.data.distinct_products)} produk
            </p>
          )}
          <Link to="/sales" className="text-[10px] font-semibold text-accent-dim hover:text-accent mt-2 inline-flex items-center gap-1 transition-colors">
            Lihat detail <ArrowRight size={10} />
          </Link>
        </div>

        {/* Products */}
        <div className="surface px-4 py-3.5">
          <span className="text-[10px] font-semibold uppercase tracking-wider text-muted leading-none block mb-1.5">
            Produk
          </span>
          {products.loading ? (
            <div className="skeleton h-7 w-16" />
          ) : (
            <p className="text-xl font-bold tracking-tight text-primary leading-none">
              {formatNumber(products.data?.total)}
            </p>
          )}
        </div>

        {/* Organic Materials */}
        <div className="surface px-4 py-3.5">
          <span className="text-[10px] font-semibold uppercase tracking-wider text-muted leading-none block mb-1.5">
            Bahan Organik
          </span>
          {organicSummary.loading ? (
            <div className="skeleton h-7 w-16" />
          ) : (
            <p className="text-xl font-bold tracking-tight text-primary leading-none">
              {formatNumber(organicSummary.data?.total_materials)}
            </p>
          )}
          {!organicSummary.loading && organicRankingStatus.status === 'ok' && (
            <p className="text-[11px] text-secondary mt-1.5 leading-snug">ranking aktif</p>
          )}
        </div>

        {/* Production */}
        <div className="surface px-4 py-3.5">
          <span className="text-[10px] font-semibold uppercase tracking-wider text-muted leading-none block mb-1.5">
            Produksi
          </span>
          {prodSummary.loading ? (
            <div className="skeleton h-7 w-16" />
          ) : (
            <p className="text-xl font-bold tracking-tight text-primary leading-none">
              {formatNumber(prodSummary.data?.total_records)}
            </p>
          )}
          {!prodSummary.loading && prodSummary.data && (
            <p className="text-[11px] text-secondary mt-1.5 leading-snug">
              {prodSummary.data.earliest_period}–{prodSummary.data.latest_period}
            </p>
          )}
        </div>
      </div>

      {/* ── Methodological note ──────────────────────────────────── */}
      <div className="border-l-2 border-accent pl-3 py-0.5 my-0">
        <p className="text-[11px] text-secondary leading-relaxed max-w-3xl">
          <strong className="text-primary font-semibold">Catatan metodologis:</strong>{' '}
          Ranking AHP-SAW bersifat simulasi. K3 dihitung via Haversine ke centroid sintetis 73 padukuhan, bukan lokasi produksi aktual. Bobot AHP belum divalidasi pakar. Agregat stok tidak dijumlahkan lintas satuan.
        </p>
      </div>

      {/* ── Product preview ─────────────────────────────────────── */}
      <section>
        <div className="flex items-baseline justify-between mb-2">
          <h2 className="text-sm font-bold text-primary tracking-tight">Katalog Produk</h2>
          <Link to="/products" className="text-[10px] font-semibold text-accent-dim hover:text-accent transition-colors">
            Lihat semua
          </Link>
        </div>

        {products.loading ? (
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            {[1,2,3].map(i => <SkeletonCard key={i} />)}
          </div>
        ) : products.error ? (
          <ErrorState message={products.error} onRetry={() => {
            setProducts({ loading: true, data: null, error: null });
            const ctrl = new AbortController();
            productsCtrlRef.current = ctrl;
            getProducts({ per_page: 3, signal: ctrl.signal })
              .then(d => { if (productsCtrlRef.current !== ctrl) return; setProducts({ loading: false, data: d, error: null }); })
              .catch(err => { if (productsCtrlRef.current !== ctrl) return; setProducts({ loading: false, data: null, error: err.message }); });
          }} />
        ) : preview.length === 0 ? (
          <p className="text-xs text-muted py-6">Belum ada produk.</p>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            {preview.map(p => (
              <Link key={p.produk_id} to="/products" className="product-card surface-hover block">
                <div className="flex items-start justify-between gap-2 mb-1.5">
                  <Badge variant="neutral">{p.jenis_produk}</Badge>
                  <span className="text-[10px] font-mono text-muted">{p.produk_id}</span>
                </div>
                <p className="text-[13px] font-semibold text-primary leading-snug mb-0.5">{p.nama_produk}</p>
                {p.deskripsi && <p className="text-[11px] text-secondary line-clamp-2 leading-relaxed">{p.deskripsi}</p>}
                <div className="mt-2 pt-2 border-t border-border-subtle">
                  {p.harga != null ? (
                    <p className="text-[13px] font-bold text-primary">{formatRupiah(p.harga)}</p>
                  ) : (
                    <p className="text-[11px] text-muted italic">Harga belum tersedia</p>
                  )}
                </div>
              </Link>
            ))}
          </div>
        )}
      </section>

      {/* Footer */}
      <p className="text-[10px] text-muted text-center pt-1 pb-1">
        Data bersumber dari PostgreSQL via FastAPI
      </p>
    </div>
  );
}
