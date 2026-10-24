/**
 * API service layer — thin wrapper around fetch().
 * All calls go through /api/* which is proxied to the FastAPI backend.
 * No credentials are stored in this file.
 *
 * Every request uses AbortSignal.timeout(10_000) to prevent indefinite hangs.
 * This guards against:
 *   - Slow database queries blocking the connection pool
 *   - Vite proxy stalling
 *   - Backend process being overwhelmed
 */

const BASE = '/api';

/** Default timeout for all API requests (milliseconds). */
export const REQUEST_TIMEOUT_MS = 10_000;

/**
 * Make a JSON request to the Vinix7 API.
 * @param {string}   path   — e.g. '/products?per_page=10'
 * @param {AbortSignal} [signal] — optional external signal (e.g. from AbortController)
 * @returns {Promise<any>} parsed JSON
 * @throws {Error} with message on non-2xx or timeout/network failure
 */
/** Timeout for forecast endpoints — model loading can take >10s on first request. */
export const FORECAST_TIMEOUT_MS = 60_000;

async function apiGet(path, signal, timeoutMs = REQUEST_TIMEOUT_MS) {
  const timeoutSignal = AbortSignal.timeout(timeoutMs);
  // If caller passed a signal, compose both so either cancels the request
  const controller = new AbortController();
  const onAbort = () => controller.abort();
  timeoutSignal.addEventListener('abort', onAbort);
  if (signal) signal.addEventListener('abort', onAbort);

  try {
    const res = await fetch(`${BASE}${path}`, {
      method: 'GET',
      headers: { Accept: 'application/json' },
      signal: controller.signal,
    });

    if (!res.ok) {
      let message = `HTTP ${res.status}`;
      try {
        const body = await res.json();
        if (body?.detail?.error) message = body.detail.error;
        else if (body?.detail) message = typeof body.detail === 'string' ? body.detail : message;
      } catch {
        // ignore parse errors
      }
      throw new Error(message);
    }

    return res.json();
  } finally {
    timeoutSignal.removeEventListener('abort', onAbort);
    if (signal) signal.removeEventListener('abort', onAbort);
  }
}

// ── Health ────────────────────────────────────────────────────────────────

export async function getHealth(signal) {
  return apiGet('/health', signal);
}

// ── Products ───────────────────────────────────────────────────────────────

/**
 * @param {object} params
 * @param {number} [params.page=1]
 * @param {number} [params.per_page=10]
 * @param {string} [params.jenis_produk]
 * @param {string} [params.nama_produk]
 * @param {AbortSignal} [params.signal]
 */
export async function getProducts({ page = 1, per_page = 10, jenis_produk, nama_produk, signal } = {}) {
  const qs = new URLSearchParams({ page, per_page });
  if (jenis_produk) qs.set('jenis_produk', jenis_produk);
  if (nama_produk)  qs.set('nama_produk', nama_produk);
  return apiGet(`/products?${qs}`, signal);
}

export async function getProduct(produk_id, signal) {
  return apiGet(`/products/${encodeURIComponent(produk_id)}`, signal);
}

export async function getProductJenis(signal) {
  return apiGet('/products/jenis/list', signal);
}

// ── Health-check only (for dashboard) ─────────────────────────────────────

/** Probe the API; returns null if unreachable or timed out. */
export async function probeApi() {
  try {
    return await getHealth();
  } catch {
    return null;
  }
}

// ── Production ───────────────────────────────────────────────────────────────

/**
 * @param {object} params
 * @param {number} [params.page=1]
 * @param {number} [params.per_page=10]
 * @param {string} [params.nama_produk]   — partial name search (case-insensitive)
 * @param {string} [params.jenis_produk]  — exact filter
 * @param {number} [params.periode]        — production year (e.g. 2024)
 * @param {AbortSignal} [params.signal]
 */
export async function getProduction({ page = 1, per_page = 10, nama_produk, jenis_produk, periode, signal } = {}) {
  const qs = new URLSearchParams({ page, per_page });
  if (nama_produk)  qs.set('nama_produk', nama_produk);
  if (jenis_produk) qs.set('jenis_produk', jenis_produk);
  if (periode)      qs.set('periode', String(periode));
  return apiGet(`/production?${qs}`, signal);
}

/**
 * @param {AbortSignal} [signal]
 */
export async function getProductionSummary(signal) {
  return apiGet('/production/summary', signal);
}

// ── Organic Materials ────────────────────────────────────────────────────────

/**
 * @param {object} params
 * @param {number} [params.page=1]
 * @param {number} [params.per_page=10]
 * @param {string} [params.jenis_bahan]
 * @param {string} [params.kategori_bahan]
 * @param {AbortSignal} [params.signal]
 */
export async function getOrganicMaterials({ page = 1, per_page = 10, jenis_bahan, kategori_bahan, signal } = {}) {
  const qs = new URLSearchParams({ page, per_page });
  if (jenis_bahan)    qs.set('jenis_bahan', jenis_bahan);
  if (kategori_bahan) qs.set('kategori_bahan', kategori_bahan);
  return apiGet(`/organic-materials?${qs}`, signal);
}

export async function getOrganicSummary(signal) {
  return apiGet('/organic-materials/summary', signal);
}

export async function getOrganicCriteriaStatus(signal) {
  return apiGet('/organic-materials/criteria-status', signal);
}

export async function getOrganicRanking(signal) {
  return apiGet('/organic-materials/ranking', signal);
}

// ── Wilayah ───────────────────────────────────────────────────────────────────

/**
 * @param {object} params
 * @param {number} [params.page=1]
 * @param {number} [params.per_page=10]
 * @param {AbortSignal} [params.signal]
 */
export async function getKalurahanList({ page = 1, per_page = 10, signal } = {}) {
  const qs = new URLSearchParams({ page, per_page });
  return apiGet(`/wilayah/kalurahan?${qs}`, signal);
}

/**
 * @param {object} params
 * @param {number} [params.page=1]
 * @param {number} [params.per_page=20]
 * @param {string} [params.kalurahan_id] — filter by parent kalurahan
 * @param {AbortSignal} [params.signal]
 */
export async function getPadukuhanList({ page = 1, per_page = 20, kalurahan_id, signal } = {}) {
  const qs = new URLSearchParams({ page, per_page });
  if (kalurahan_id) qs.set('kalurahan_id', kalurahan_id);
  return apiGet(`/wilayah/padukuhan?${qs}`, signal);
}

export async function getWilayahSummary(signal) {
  return apiGet('/wilayah/summary', signal);
}

// ── Sales / Penjualan ─────────────────────────────────────────────────────────

/**
 * @param {object} params
 * @param {number} [params.page=1]
 * @param {number} [params.per_page=20]
 * @param {string} [params.produk_id] — filter by product ID
 * @param {string} [params.periode_start] — YYYY-MM-DD, bulan >= this date
 * @param {string} [params.periode_end] — YYYY-MM-DD, bulan <= this date
 * @param {AbortSignal} [params.signal]
 */
export async function getSales({ page = 1, per_page = 20, produk_id, periode_start, periode_end, signal } = {}) {
  const qs = new URLSearchParams({ page, per_page });
  if (produk_id)      qs.set('produk_id', produk_id);
  if (periode_start)  qs.set('periode_start', periode_start);
  if (periode_end)    qs.set('periode_end', periode_end);
  return apiGet(`/sales?${qs}`, signal);
}

export async function getSalesSummary(signal) {
  return apiGet('/sales/summary', signal);
}

// ── Forecasts / Prediksi Penjualan ────────────────────────────────────────────

/**
 * @param {AbortSignal} [signal]
 */
export async function getForecastSummary(signal) {
  return apiGet('/forecasts/summary', signal, FORECAST_TIMEOUT_MS);
}

/**
 * @param {object} params
 * @param {number} [params.page=1]
 * @param {number} [params.per_page=20]
 * @param {string} [params.produk] — partial product name filter (case-insensitive)
 * @param {string} [params.bulan] — exact month filter (YYYY-MM-DD)
 * @param {AbortSignal} [params.signal]
 */
export async function getForecasts({ page = 1, per_page = 20, produk, bulan, signal } = {}) {
  const qs = new URLSearchParams({ page, per_page });
  if (produk) qs.set('produk', produk);
  if (bulan)  qs.set('bulan', bulan);
  return apiGet(`/forecasts?${qs}`, signal, FORECAST_TIMEOUT_MS);
}

/**
 * Generate a custom date range forecast via POST.
 * @param {object} params
 * @param {string} params.start_date — YYYY-MM-DD (only year-month used)
 * @param {string} params.end_date — YYYY-MM-DD (only year-month used)
 * @param {string} [params.produk] — optional product name filter (partial match)
 * @param {AbortSignal} [params.signal]
 * @returns {Promise<any>} ForecastCustomResponse
 */
export async function postCustomForecast({ start_date, end_date, produk, signal } = {}) {
  const timeoutSignal = AbortSignal.timeout(FORECAST_TIMEOUT_MS);
  const controller = new AbortController();
  const onAbort = () => controller.abort();
  timeoutSignal.addEventListener('abort', onAbort);
  if (signal) signal.addEventListener('abort', onAbort);

  try {
    const body = { start_date, end_date };
    if (produk) body.produk = produk;

    const res = await fetch(`${BASE}/forecasts/custom`, {
      method: 'POST',
      headers: { Accept: 'application/json', 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      signal: controller.signal,
    });

    if (!res.ok) {
      let message = `HTTP ${res.status}`;
      try {
        const errBody = await res.json();
        if (errBody?.detail?.message) message = errBody.detail.message;
        else if (errBody?.detail?.error) message = errBody.detail.error;
        else if (errBody?.detail) message = typeof errBody.detail === 'string' ? errBody.detail : message;
      } catch { /* ignore parse errors */ }
      throw new Error(message);
    }

    return res.json();
  } finally {
    timeoutSignal.removeEventListener('abort', onAbort);
    if (signal) signal.removeEventListener('abort', onAbort);
  }
}
