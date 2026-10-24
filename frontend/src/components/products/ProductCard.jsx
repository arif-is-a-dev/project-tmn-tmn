import React from 'react';
import { Badge } from '../ui/Badge.jsx';
import { formatRupiah } from '../../services/formatters.js';

export default function ProductCard({ product, onClick }) {
  return (
    <button
      onClick={onClick}
      className="product-card surface-hover focus:outline-none h-full flex flex-col"
      aria-label={`Lihat detail ${product.nama_produk}`}
    >
      <div className="flex items-start justify-between gap-2 mb-3">
        <span className="text-2xs font-mono text-muted leading-none pt-0.5">
          {product.produk_id}
        </span>
        <Badge variant="neutral">{product.jenis_produk}</Badge>
      </div>

      <h3
        className="text-sm font-semibold text-primary leading-snug mb-2"
        style={{ display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}
      >
        {product.nama_produk}
      </h3>

      <div className="flex-grow">
        {product.deskripsi && (
          <p className="text-2xs text-secondary leading-relaxed mb-4 line-clamp-2">
            {product.deskripsi}
          </p>
        )}
      </div>

      <div className="flex items-baseline justify-between pt-3 border-t border-border-subtle mt-auto">
        {product.harga != null ? (
          <span className="text-sm font-bold text-primary break-all">
            {formatRupiah(product.harga)}
          </span>
        ) : (
          <span className="text-2xs text-muted italic">Harga tidak tersedia</span>
        )}
        {product.ukuran_kemasan && (
          <span className="text-2xs text-muted flex-shrink-0 ml-2">{product.ukuran_kemasan}</span>
        )}
      </div>

      {product.produsen && (
        <p className="text-2xs text-muted mt-2.5 leading-snug">
          {product.produsen}
        </p>
      )}
    </button>
  );
}
