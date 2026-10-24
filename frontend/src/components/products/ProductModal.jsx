import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Lock } from 'lucide-react';
import { Badge } from '../ui/Badge.jsx';
import { formatRupiah } from '../../services/formatters.js';

function InfoRow({ label, value }) {
  if (!value || value === '—') return null;
  return (
    <div>
      <p className="text-2xs font-semibold uppercase tracking-wider text-muted mb-0.5">{label}</p>
      <p className="text-sm text-primary font-medium leading-snug">{value}</p>
    </div>
  );
}

function DetailSection({ label, children }) {
  if (!children) return null;
  return (
    <div>
      <p className="text-2xs font-semibold uppercase tracking-wider text-muted mb-1.5">{label}</p>
      <div className="text-sm text-secondary leading-relaxed">{children}</div>
    </div>
  );
}

const backdropVariants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { duration: 0.15 } },
  exit:   { opacity: 0, transition: { duration: 0.1 } },
};

const panelVariants = {
  hidden:  { opacity: 0, scale: 0.98, y: 6 },
  visible: { opacity: 1, scale: 1,    y: 0, transition: { duration: 0.18, ease: 'easeOut' } },
  exit:    { opacity: 0, scale: 0.98, y: 3, transition: { duration: 0.1, ease: 'easeIn' } },
};

export default function ProductModal({ product, onClose }) {
  if (!product) return null;

  return (
    <AnimatePresence>
      <motion.div
        className="fixed inset-0 z-50 flex items-center justify-center p-4"
        variants={backdropVariants}
        initial="hidden"
        animate="visible"
        exit="exit"
      >
        <div className="absolute inset-0 bg-[var(--overlay)] backdrop-blur-sm" onClick={onClose} />

        <motion.div
          className="relative bg-surface border border-border rounded-xl shadow-lg w-full max-w-lg max-h-[88vh] flex flex-col overflow-hidden"
          variants={panelVariants}
          initial="hidden"
          animate="visible"
          exit="exit"
        >
          <div className="flex-shrink-0 px-6 py-5 border-b border-border-subtle">
            <div className="flex items-start justify-between gap-3">
              <div className="min-w-0">
                <div className="flex items-center gap-2 mb-1.5">
                  <span className="text-2xs font-mono text-muted">{product.produk_id}</span>
                  <Badge variant="neutral">{product.jenis_produk}</Badge>
                </div>
                <h2 className="text-lg font-bold text-primary leading-snug">
                  {product.nama_produk}
                </h2>
              </div>
              <button
                onClick={onClose}
                className="flex-shrink-0 p-2 text-muted hover:text-primary hover:bg-surface-alt rounded-lg transition-colors"
                aria-label="Tutup"
              >
                <X size={18} />
              </button>
            </div>
          </div>

          <div className="flex-1 overflow-y-auto px-6 py-5 space-y-5">
            <DetailSection label="Deskripsi">{product.deskripsi}</DetailSection>
            <DetailSection label="Manfaat">{product.manfaat}</DetailSection>

            <div className="grid grid-cols-2 gap-x-6 gap-y-4 pt-1">
              <InfoRow label="Harga" value={product.harga != null ? formatRupiah(product.harga) : '—'} />
              <InfoRow label="Kemasan" value={product.ukuran_kemasan || '—'} />
              <InfoRow label="Produsen" value={product.produsen || '—'} />
              <InfoRow label="Lokasi" value={product.lokasi_produsen || '—'} />
              <InfoRow label="Ketersediaan" value={product.stok_ketersediaan || '—'} />
            </div>

            <div className="border-l-2 border-accent pl-4 py-2">
              <div className="flex items-start gap-2">
                <Lock size={12} className="text-muted flex-shrink-0 mt-0.5" />
                <p className="text-2xs text-secondary leading-relaxed">
                  Informasi kontak produsen tidak ditampilkan demi privasi data.
                </p>
              </div>
            </div>
          </div>
        </motion.div>
      </motion.div>
    </AnimatePresence>
  );
}
