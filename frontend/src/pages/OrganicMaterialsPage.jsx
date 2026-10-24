import React, { useState, useEffect, useCallback, useRef } from 'react';
import { motion } from 'framer-motion';
import { Leaf, Lock, AlertTriangle, Trophy, Info } from 'lucide-react';
import { getOrganicMaterials, getOrganicSummary, getOrganicCriteriaStatus, getOrganicRanking } from '../services/api.js';
import { formatNumber } from '../services/formatters.js';
import { SkeletonTable } from '../components/ui/Skeleton.jsx';
import ErrorState from '../components/ui/ErrorState.jsx';
import { EmptyState } from '../components/ui/EmptyState.jsx';
import { Badge } from '../components/ui/Badge.jsx';
import { StatCard } from '../components/ui/StatCard.jsx';
import { Pagination } from '../components/ui/Pagination.jsx';

const PER_PAGE = 10;

/* -- Criteria status table --------------------------------------------------- */
function CriteriaTable({ criteria, loading }) {
  if (loading || !criteria) return null;
  return (
    <div className="surface overflow-hidden">
      <div className="px-5 py-4 border-b border-border-subtle">
        <h3 className="text-sm font-semibold text-primary">Kriteria AHP-SAW</h3>
      </div>
      <div className="overflow-x-auto">
        <table className="data-table w-full text-sm">
          <thead className="bg-surface-alt border-b border-border-subtle">
            <tr>
              <th className="px-5 py-3 text-left text-2xs font-semibold uppercase tracking-wider text-muted">Kode</th>
              <th className="px-5 py-3 text-left text-2xs font-semibold uppercase tracking-wider text-muted">Kriteria</th>
              <th className="px-5 py-3 text-left text-2xs font-semibold uppercase tracking-wider text-muted">Tipe</th>
              <th className="px-5 py-3 text-left text-2xs font-semibold uppercase tracking-wider text-muted">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border-subtle">
            {criteria.map(c => (
              <tr key={c.code} className="hover:bg-surface-alt/50 transition-colors">
                <td className="px-5 py-3 font-mono text-xs text-muted">{c.code}</td>
                <td className="px-5 py-3 text-xs text-primary">{c.name}</td>
                <td className="px-5 py-3">
                  <Badge variant={c.type === 'Benefit' ? 'success' : 'danger'}>{c.type}</Badge>
                </td>
                <td className="px-5 py-3">
                  {c.complete ? (
                    <span className="inline-flex items-center gap-1 text-xs text-success font-medium">
                      <span className="w-1.5 h-1.5 rounded-full bg-success" /> Lengkap
                    </span>
                  ) : (
                    <span className="inline-flex items-center gap-1 text-xs text-danger font-medium" title={c.note || ''}>
                      <span className="w-1.5 h-1.5 rounded-full bg-danger" /> Tidak lengkap
                    </span>
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

/* -- Ranking blocked notice -------------------------------------------------- */
function RankingBlockedNotice({ ranking }) {
  if (!ranking || ranking.status !== 'blocked') return null;
  return (
    <div className="surface p-5 flex gap-4">
      <div className="w-10 h-10 rounded-lg bg-danger-bg flex items-center justify-center flex-shrink-0">
        <Lock size={18} className="text-danger" />
      </div>
      <div className="min-w-0">
        <h3 className="text-sm font-semibold text-primary mb-1.5">
          Ranking AHP-SAW belum tersedia
        </h3>
        <p className="text-sm text-secondary leading-relaxed">
          {ranking.blocked_reason}
        </p>
        {ranking.missing_criteria && ranking.missing_criteria.length > 0 && (
          <div className="mt-3 flex flex-wrap gap-2">
            {ranking.missing_criteria.map(code => (
              <span key={code} className="inline-flex items-center gap-1 text-xs font-medium text-danger bg-danger-bg px-2 py-1 rounded">
                <AlertTriangle size={10} /> {code} belum lengkap
              </span>
            ))}
          </div>
        )}
        <ul className="mt-3 space-y-1.5 text-sm text-secondary list-disc list-inside">
          {ranking.missing_criteria && ranking.missing_criteria.includes('K3') && (
            <li>
              <strong className="font-medium">Jarak ke lokasi produksi (K3)</strong> {'—'}
              seluruh nilai <code className="text-xs bg-surface-alt px-1 py-0.5 rounded text-primary">NULL</code> karena
              sumber jarak belum diverifikasi.
            </li>
          )}
          <li>
            <strong className="font-medium">Bobot AHP</strong> {'—'} saat ini merupakan
            asumsi simulasi dari notebook, bukan hasil penilaian mitra atau ahli.
          </li>
        </ul>
        <p className="mt-4 text-xs text-muted">
          Setelah seluruh kriteria terpenuhi dari sumber yang terverifikasi,
          halaman ini akan menampilkan tabel ranking dengan skor akhir dan peringkat.
        </p>
      </div>
    </div>
  );
}

/* -- Simulation warning banner ----------------------------------------------- */
function SimulationWarning() {
  return (
    <div className="border-l-2 border-warning pl-4 py-2">
      <div className="flex items-start gap-3">
        <Info size={16} className="text-warning flex-shrink-0 mt-0.5" />
        <div className="text-xs text-secondary leading-relaxed space-y-1">
          <p>
            <strong className="font-semibold text-primary">Catatan metodologis:</strong> Seluruh ranking bersifat simulasi.
            Bobot AHP merupakan asumsi dari notebook, <em>bukan</em> hasil validasi pakar.
          </p>
          <p>
            Kriteria K3 (jarak ke lokasi produksi) dihitung menggunakan titik referensi sintetis
            (centroid aritmetik 73 padukuhan sumber) dengan formula Haversine.
            Titik ini <em>bukan</em> lokasi aktual fasilitas produksi manapun.
          </p>
        </div>
      </div>
    </div>
  );
}

/* -- Ranking table ----------------------------------------------------------- */
function RankingTable({ ranking }) {
  if (!ranking || ranking.status !== 'ok' || !ranking.items.length) return null;

  return (
    <div className="space-y-3">
      {/* Header with CR and weights info */}
      <div className="surface p-4 space-y-3">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
          <h3 className="text-sm font-semibold text-primary flex items-center gap-2">
            <Trophy size={14} className="text-accent" />
            Peringkat Bahan Organik (AHP-SAW)
          </h3>
          {ranking.consistency_ratio != null && (
            <span className="text-xs text-muted font-mono">
              CR = {ranking.consistency_ratio.toFixed(4)}
              {ranking.consistency_ratio < 0.10
                ? <span className="text-success ml-1">(konsisten)</span>
                : <span className="text-danger ml-1">(tidak konsisten)</span>
              }
            </span>
          )}
        </div>

        {/* Weights display */}
        {ranking.ahp_weights && (
          <div className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted">
            {Object.entries(ranking.ahp_weights).map(([k, v]) => (
              <span key={k} className="font-mono">{k}: {v.toFixed(4)}</span>
            ))}
          </div>
        )}

        <SimulationWarning />
      </div>

      {/* Table */}
      <div className="surface overflow-hidden">
        <div className="overflow-x-auto">
          <table className="data-table w-full text-sm">
            <thead>
              <tr className="bg-surface-alt border-b border-border">
                <th className="text-center px-3 py-3 w-12 text-2xs font-semibold uppercase tracking-wider text-muted">#</th>
                <th className="text-left px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted">Bahan Organik</th>
                <th className="text-left px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted hidden sm:table-cell">Kategori</th>
                <th className="text-right px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted">Skor Akhir</th>
                <th className="text-right px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted hidden md:table-cell">Ketersediaan</th>
                <th className="text-center px-3 py-3 text-2xs font-semibold uppercase tracking-wider text-muted hidden lg:table-cell">K2</th>
                <th className="text-center px-3 py-3 text-2xs font-semibold uppercase tracking-wider text-muted hidden lg:table-cell">K4</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-subtle">
              {ranking.items.map((item) => {
                const isGold = item.peringkat === 1;
                return (
                  <tr key={item.bahan_id} className={`hover:bg-surface-alt/50 transition-colors ${isGold ? 'bg-accent/5' : ''}`}>
                    <td className="px-3 py-3 text-center">
                      {isGold ? (
                        <span className="inline-flex items-center justify-center w-6 h-6 rounded-full bg-accent text-accent-text text-xs font-bold">
                          {item.peringkat}
                        </span>
                      ) : (
                        <span className="text-xs font-mono text-muted">{item.peringkat}</span>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      <p className="font-medium text-primary text-xs leading-snug">{item.jenis_bahan_organik}</p>
                      <p className="text-2xs text-muted font-mono mt-0.5 sm:hidden">{item.kategori_bahan}</p>
                    </td>
                    <td className="px-4 py-3 text-xs text-secondary hidden sm:table-cell">{item.kategori_bahan}</td>
                    <td className="px-4 py-3 text-right">
                      <span className={`font-mono text-xs font-semibold ${isGold ? 'text-accent' : 'text-primary'}`}>
                        {item.skor_akhir.toFixed(4)}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right text-xs text-secondary hidden md:table-cell">
                      {formatNumber(item.jumlah_ketersediaan)}
                    </td>
                    <td className="px-3 py-3 text-center text-xs text-secondary hidden lg:table-cell">
                      {item.skor_kontinuitas}/4
                    </td>
                    <td className="px-3 py-3 text-center text-xs text-secondary hidden lg:table-cell">
                      {item.skor_kemudahan}/3
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
        {ranking.items.length > 0 && (
          <div className="px-4 py-2 border-t border-border-subtle text-2xs text-muted">
            {ranking.items.length} bahan organik diurutkan berdasarkan skor AHP-SAW.
            Peringkat sama ({'“'}competition ranking{'”'}) diterapkan untuk skor yang identik.
          </div>
        )}
      </div>
    </div>
  );
}

/* -- Materials table --------------------------------------------------------- */
function MaterialsTable({ items }) {
  if (!items.length) return null;
  return (
    <div className="surface overflow-hidden">
      <div className="overflow-x-auto">
        <table className="data-table w-full text-sm">
          <thead>
            <tr className="bg-surface-alt border-b border-border">
              <th className="text-left px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted">Bahan Organik</th>
              <th className="text-left px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted">Kategori</th>
              <th className="text-right px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted">Jumlah</th>
              <th className="text-left px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted">Satuan</th>
              <th className="text-right px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted">Padukuhan</th>
              <th className="text-right px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted">Periode</th>
              <th className="text-center px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted">Kontinuitas</th>
              <th className="text-center px-4 py-3 text-2xs font-semibold uppercase tracking-wider text-muted">Kemudahan</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border-subtle">
            {items.map(item => {
              const b = item.bahan;
              const a = item.availability;
              return (
                <tr key={b.bahan_id} className="hover:bg-surface-alt/50 transition-colors">
                  <td className="px-4 py-3">
                    <p className="font-medium text-primary text-xs leading-snug">{b.jenis_bahan_organik}</p>
                    <p className="text-2xs text-muted font-mono mt-0.5">{b.bahan_id}</p>
                  </td>
                  <td className="px-4 py-3 text-xs text-secondary">{b.kategori_bahan}</td>
                  <td className="px-4 py-3 text-right font-medium text-primary text-xs">{formatNumber(a.total_quantity)}</td>
                  <td className="px-4 py-3 text-xs text-muted">{a.satuan}</td>
                  <td className="px-4 py-3 text-right text-xs text-secondary">{a.distinct_padukuhan}</td>
                  <td className="px-4 py-3 text-right text-xs text-secondary">{a.distinct_periods}</td>
                  <td className="px-4 py-3 text-center">
                    {a.skor_kontinuitas != null ? (
                      <span className="text-xs text-secondary">{a.skor_kontinuitas}/4</span>
                    ) : <span className="text-xs text-muted">{'—'}</span>}
                  </td>
                  <td className="px-4 py-3 text-center">
                    {a.skor_kemudahan != null ? (
                      <span className="text-xs text-secondary">{a.skor_kemudahan}/3</span>
                    ) : <span className="text-xs text-muted">{'—'}</span>}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}

/* -- Page -------------------------------------------------------------------- */
export default function OrganicMaterialsPage() {
  const [items, setItems] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [searchInput, setSearchInput] = useState('');
  const [summary, setSummary] = useState(null);
  const [criteria, setCriteria] = useState(null);
  const [ranking, setRanking] = useState(null);
  const [summaryLoading, setSummaryLoading] = useState(true);
  const abortRef = useRef(null);

  // Debounce search
  useEffect(() => {
    const t = setTimeout(() => setSearch(searchInput), 350);
    return () => clearTimeout(t);
  }, [searchInput]);

  useEffect(() => { setPage(1); }, [search]);

  const fetchData = useCallback(async () => {
    if (abortRef.current) abortRef.current.abort();
    const ctrl = new AbortController();
    abortRef.current = ctrl;
    setLoading(true);
    setError(null);
    try {
      const params = { page, per_page: PER_PAGE, signal: ctrl.signal };
      const data = await getOrganicMaterials(params);
      if (abortRef.current !== ctrl) return;
      let filtered = data.items || [];
      if (search) {
        const q = search.toLowerCase();
        filtered = filtered.filter(i =>
          i.bahan.jenis_bahan_organik.toLowerCase().includes(q) ||
          i.bahan.kategori_bahan.toLowerCase().includes(q)
        );
      }
      setItems(filtered);
      setTotal(search ? filtered.length : (data.total || 0));
    } catch (err) {
      if (err.name === 'AbortError' || err.name === 'CanceledError') return;
      if (abortRef.current !== ctrl) return;
      setError(err.message);
    } finally {
      if (abortRef.current === ctrl) setLoading(false);
    }
  }, [page, search]);

  useEffect(() => { fetchData(); }, [fetchData]);

  // Load summary + criteria + ranking on mount
  useEffect(() => {
    let cancelled = false;
    setSummaryLoading(true);
    Promise.all([
      getOrganicSummary().catch(() => null),
      getOrganicCriteriaStatus().catch(() => null),
      getOrganicRanking().catch(() => null),
    ]).then(([s, c, r]) => {
      if (!cancelled) {
        setSummary(s);
        setCriteria(c?.criteria || null);
        setRanking(r);
        setSummaryLoading(false);
      }
    });
    return () => { cancelled = true; };
  }, []);

  const totalLabel = total > 0
    ? `${total} bahan organik${search ? ' — disaring' : ''}`
    : loading ? 'Memuat…' : 'Tidak ada data';

  return (
    <motion.div
      className="max-w-6xl mx-auto space-y-5"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1, transition: { duration: 0.22, ease: 'easeOut' } }}
    >
      {/* Header */}
      <div>
        <h1 className="text-xl font-bold text-primary">Potensi Bahan Organik</h1>
        <p className="text-sm text-muted mt-0.5">{totalLabel}</p>
      </div>

      {/* Summary cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <StatCard label="Jenis Bahan" value={formatNumber(summary?.total_materials)} loading={summaryLoading} />
        <StatCard label="Record Ketersediaan" value={formatNumber(summary?.total_availability_records)} loading={summaryLoading} />
        <StatCard label="Bahan dengan Data" value={formatNumber(summary?.materials_with_availability)} loading={summaryLoading} />
        <StatCard
          label="Kriteria Lengkap"
          value={summary?.criteria_complete ? 'Ya' : 'Tidak'}
          sub={summary && !summary.criteria_complete ? `${summary.missing_criteria.length} kriteria belum lengkap` : undefined}
          loading={summaryLoading}
        />
      </div>

      {/* Ranking section: either blocked notice or ranking table */}
      {summaryLoading ? (
        <div className="surface p-8 flex items-center justify-center">
          <div className="text-sm text-muted">Memuat data ranking...</div>
        </div>
      ) : ranking ? (
        ranking.status === 'blocked' ? (
          <RankingBlockedNotice ranking={ranking} />
        ) : (
          <RankingTable ranking={ranking} />
        )
      ) : null}

      {/* Criteria table */}
      <CriteriaTable criteria={criteria} loading={summaryLoading} />

      {/* Search */}
      <div className="relative max-w-md">
        <input
          type="text"
          value={searchInput}
          onChange={e => setSearchInput(e.target.value)}
          placeholder="Cari bahan organik…"
          className="w-full pl-8 pr-3 py-2 text-sm bg-surface border border-border rounded-md text-primary focus:outline-none focus:border-accent placeholder:text-muted"
        />
        <svg className="absolute left-2.5 top-1/2 -translate-y-1/2 text-muted" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
        </svg>
      </div>

      {/* Content */}
      {loading ? (
        <SkeletonTable rows={8} cols={8} />
      ) : error ? (
        <ErrorState message={error} onRetry={fetchData} />
      ) : items.length === 0 ? (
        <EmptyState
          icon={Leaf}
          title="Tidak ada bahan organik ditemukan"
          description={search ? 'Coba ubah kata kunci pencarian.' : 'Belum ada data bahan organik di database.'}
        />
      ) : (
        <>
          <MaterialsTable items={items} />
          {!search && <Pagination page={page} total={total} perPage={PER_PAGE} onPage={setPage} />}
        </>
      )}
    </motion.div>
  );
}
