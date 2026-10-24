import React from 'react';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import {
  Leaf, Package, ShoppingCart, Factory,
  MapPin, ArrowRight, Sprout,
} from 'lucide-react';

const DATA_ITEMS = [
  {
    icon: MapPin,
    to: '/wilayah',
    label: 'Wilayah',
    desc: '5 kalurahan, 73 padukuhan',
  },
  {
    icon: Leaf,
    to: '/organic-materials',
    label: 'Bahan Organik',
    desc: '17 jenis bahan organik, 88 data ketersediaan',
  },
  {
    icon: Factory,
    to: '/production',
    label: 'Produksi',
    desc: '66 record produksi dari Data_produksi_pupuk',
  },
  {
    icon: ShoppingCart,
    to: '/sales',
    label: 'Penjualan',
    desc: '792 baris data historis 2020–2025',
  },
  {
    icon: Package,
    to: '/products',
    label: 'Katalog Produk',
    desc: '11 produk lengkap — deskripsi, harga, produsen',
  },
];

export default function DataPage() {
  return (
    <div className="max-w-3xl mx-auto space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-xl font-bold text-primary tracking-tight">Data Terintegrasi</h1>
        <p className="text-sm text-secondary mt-1">
          Semua data sumber yang telah diimpor ke PostgreSQL.
        </p>
      </div>

      {/* Data cards */}
      <div className="space-y-2">
        {DATA_ITEMS.map((item, i) => {
          const Icon = item.icon;
          return (
            <motion.div
              key={item.to}
              initial={{ opacity: 0, y: 6 }}
              animate={{ opacity: 1, y: 0, transition: { duration: 0.2, delay: i * 0.04 } }}
            >
              <Link
                to={item.to}
                className="surface surface-hover flex items-center gap-4 rounded-lg border border-border border-l-[3px] border-l-accent p-4 group"
              >
                <div className="w-9 h-9 rounded-md bg-surface-alt flex items-center justify-center flex-shrink-0">
                  <Icon size={16} className="text-secondary" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold text-primary">{item.label}</p>
                  <p className="text-[11px] text-muted mt-0.5">{item.desc}</p>
                </div>
                <ArrowRight size={14} className="text-muted flex-shrink-0 group-hover:text-accent-text transition-colors" />
              </Link>
            </motion.div>
          );
        })}
      </div>

      {/* Note */}
      <div className="border-l-2 border-accent pl-4 py-3">
        <div className="flex items-start gap-2.5">
          <Sprout size={14} className="text-accent-text flex-shrink-0 mt-0.5" />
          <p className="text-[11px] text-secondary leading-relaxed">
            <strong>Catatan:</strong> Semua data di atas tersedia melalui API read-only dan berasal
            langsung dari PostgreSQL. Ranking AHP-SAW pada Bahan Organik bersifat simulasi —
            lihat catatan metodologis di halaman terkait.
          </p>
        </div>
      </div>
    </div>
  );
}
