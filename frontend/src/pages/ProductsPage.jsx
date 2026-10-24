import React, { useState, useEffect, useCallback, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Search, SlidersHorizontal, Package } from 'lucide-react';
import { getProducts, getProductJenis } from '../services/api.js';
import ProductCard from '../components/products/ProductCard.jsx';
import ProductModal from '../components/products/ProductModal.jsx';
import ErrorState from '../components/ui/ErrorState.jsx';
import { EmptyState } from '../components/ui/EmptyState.jsx';
import { SkeletonCard } from '../components/ui/Skeleton.jsx';
import { Pagination } from '../components/ui/Pagination.jsx';

const PER_PAGE = 12;

const listContainer = {
  hidden: {},
  show: { transition: { staggerChildren: 0.05 } },
};

export default function ProductsPage() {
  const [items,        setItems]        = useState([]);
  const [total,        setTotal]        = useState(0);
  const [loading,      setLoading]      = useState(true);
  const [error,        setError]        = useState(null);
  const [page,         setPage]         = useState(1);
  const [search,       setSearch]       = useState('');
  const [jenisList,     setJenisList]    = useState([]);
  const [selectedJenis, setSelectedJenis] = useState('');
  const [modalProduct, setModalProduct] = useState(null);
  const abortRef = useRef(null);

  const [searchInput, setSearchInput] = useState('');
  useEffect(() => {
    const t = setTimeout(() => setSearch(searchInput), 350);
    return () => clearTimeout(t);
  }, [searchInput]);

  useEffect(() => { setPage(1); }, [search, selectedJenis]);

  const fetchProducts = useCallback(async () => {
    if (abortRef.current) abortRef.current.abort();
    const ctrl = new AbortController();
    abortRef.current = ctrl;

    setLoading(true);
    setError(null);
    try {
      const data = await getProducts({
        page, per_page: PER_PAGE,
        nama_produk:  search || undefined,
        jenis_produk: selectedJenis || undefined,
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
  }, [page, search, selectedJenis]);

  useEffect(() => { fetchProducts(); }, [fetchProducts]);

  useEffect(() => {
    getProductJenis().then(d => setJenisList(d)).catch(() => {});
  }, []);

  const totalLabel = total > 0
    ? `${total} produk${selectedJenis ? ` — ${selectedJenis}` : ''}`
    : loading ? 'Memuat…' : 'Tidak ada produk';

  return (
    <div className="max-w-7xl mx-auto space-y-5">
      {/* Header */}
      <div>
        <h1 className="text-xl font-bold text-primary tracking-tight">Katalog Produk</h1>
        <p className="text-sm text-secondary mt-0.5">{totalLabel}</p>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3">
        {/* Search */}
        <div className="relative flex-1">
          <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted pointer-events-none" />
          <input
            type="text"
            value={searchInput}
            onChange={e => setSearchInput(e.target.value)}
            placeholder="Cari nama produk…"
            className="w-full pl-9 pr-4 py-2.5 text-sm border border-border rounded-md
                       bg-surface focus:outline-none focus:ring-1 focus:ring-accent focus:border-accent
                       placeholder:text-muted text-primary"
          />
        </div>

        {/* Jenis filter */}
        <div className="relative">
          <SlidersHorizontal size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted pointer-events-none" />
          <select
            value={selectedJenis}
            onChange={e => { setSelectedJenis(e.target.value); setPage(1); }}
            className="pl-9 pr-8 py-2.5 text-sm border border-border rounded-md bg-surface
                       focus:outline-none focus:ring-1 focus:ring-accent focus:border-accent
                       appearance-none cursor-pointer text-primary min-w-[180px]"
          >
            <option value="">Semua jenis</option>
            {jenisList.map(j => (
              <option key={j} value={j}>{j}</option>
            ))}
          </select>
          <div className="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none text-muted">
            <svg width="10" height="6" viewBox="0 0 10 6" fill="none">
              <path d="M1 1l4 4 4-4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
        </div>
      </div>

      {/* Content grid */}
      {loading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3">
          {Array.from({ length: 8 }).map((_, i) => <SkeletonCard key={i} />)}
        </div>
      ) : error ? (
        <ErrorState message={error} onRetry={fetchProducts} />
      ) : items.length === 0 ? (
        <EmptyState
          icon={Package}
          title="Tidak ada produk ditemukan"
          description={
            search || selectedJenis
              ? 'Coba ubah kata kunci pencarian atau filter jenis.'
              : 'Belum ada data produk di katalog.'
          }
        />
      ) : (
        <>
          <AnimatePresence mode="wait">
            <motion.div
              key={`${page}-${search}-${selectedJenis}`}
              className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3 items-stretch"
              variants={listContainer}
              initial="hidden"
              animate="show"
            >
              {items.map(p => (
                <motion.div key={p.produk_id} className="h-full">
                  <ProductCard
                    product={p}
                    onClick={() => setModalProduct(p)}
                  />
                </motion.div>
              ))}
            </motion.div>
          </AnimatePresence>
          <Pagination page={page} total={total} perPage={PER_PAGE} onPage={setPage} />
        </>
      )}

      {/* Modal */}
      <AnimatePresence>
        {modalProduct && (
          <ProductModal
            product={modalProduct}
            onClose={() => setModalProduct(null)}
          />
        )}
      </AnimatePresence>
    </div>
  );
}
