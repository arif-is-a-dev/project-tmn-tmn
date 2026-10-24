/**
 * Formatting utilities — Indonesian locale conventions.
 */

/**
 * Format a number as Indonesian Rupiah.
 * @param {number|null|undefined} value
 * @returns {string}
 */
export function formatRupiah(value) {
  if (value == null || isNaN(value)) return '—';
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(value);
}

/**
 * Format a number with Indonesian thousands separator.
 * @param {number|null|undefined} value
 * @returns {string}
 */
export function formatNumber(value) {
  if (value == null || isNaN(value)) return '—';
  return new Intl.NumberFormat('id-ID').format(value);
}

/**
 * Format a date string as Indonesian readable form (e.g. "11 Sep 2025").
 * @param {string} dateStr  — ISO date string
 * @returns {string}
 */
export function formatDate(dateStr) {
  if (!dateStr) return '—';
  try {
    const d = new Date(dateStr);
    return d.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' });
  } catch {
    return dateStr;
  }
}