-- Vinix7 schema. Run through scripts/init_db.py; this file is intentionally
-- not idempotent so an existing/partial schema cannot be mistaken for a fresh one.

CREATE TABLE kalurahan (
    kalurahan_id TEXT PRIMARY KEY,
    kalurahan TEXT NOT NULL,
    luas_kalurahan_ha NUMERIC(12, 4) CHECK (luas_kalurahan_ha IS NULL OR luas_kalurahan_ha >= 0),
    jumlah_padukuhan INTEGER CHECK (jumlah_padukuhan IS NULL OR jumlah_padukuhan >= 0),
    jumlah_rw INTEGER CHECK (jumlah_rw IS NULL OR jumlah_rw >= 0),
    jumlah_rt INTEGER CHECK (jumlah_rt IS NULL OR jumlah_rt >= 0),
    batas_utara TEXT,
    batas_selatan TEXT,
    batas_barat TEXT,
    batas_timur TEXT,
    jarak_kecamatan_km NUMERIC(8, 2) CHECK (jarak_kecamatan_km IS NULL OR jarak_kecamatan_km >= 0),
    jarak_kabupaten_km NUMERIC(8, 2) CHECK (jarak_kabupaten_km IS NULL OR jarak_kabupaten_km >= 0),
    jarak_provinsi_km NUMERIC(8, 2) CHECK (jarak_provinsi_km IS NULL OR jarak_provinsi_km >= 0),
    jarak_nasional_km NUMERIC(8, 2) CHECK (jarak_nasional_km IS NULL OR jarak_nasional_km >= 0),
    latitude NUMERIC(10, 7) CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
    longitude NUMERIC(10, 7) CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180)
);

CREATE TABLE padukuhan (
    padukuhan_id TEXT PRIMARY KEY,
    kalurahan_id TEXT NOT NULL REFERENCES kalurahan(kalurahan_id),
    kalurahan TEXT NOT NULL,
    padukuhan TEXT NOT NULL,
    jumlah_rt INTEGER CHECK (jumlah_rt IS NULL OR jumlah_rt >= 0),
    jumlah_rw INTEGER CHECK (jumlah_rw IS NULL OR jumlah_rw >= 0),
    latitude NUMERIC(10, 7) CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
    longitude NUMERIC(10, 7) CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180),
    UNIQUE (kalurahan_id, padukuhan)
);

CREATE TABLE data_pertanian (
    agri_id TEXT PRIMARY KEY,
    kalurahan TEXT NOT NULL,
    padukuhan_id TEXT NOT NULL REFERENCES padukuhan(padukuhan_id),
    padukuhan TEXT NOT NULL,
    komoditas TEXT NOT NULL,
    kelompok_komoditas TEXT NOT NULL,
    tahun INTEGER NOT NULL CHECK (tahun BETWEEN 1900 AND 2100),
    luas_panen_ha NUMERIC(12, 4) NOT NULL CHECK (luas_panen_ha >= 0),
    luas_lahan_ha NUMERIC(12, 4) NOT NULL CHECK (luas_lahan_ha >= 0),
    jumlah_petani INTEGER NOT NULL CHECK (jumlah_petani >= 0),
    jumlah_utp INTEGER NOT NULL CHECK (jumlah_utp >= 0),
    jumlah_kelompok_tani INTEGER NOT NULL CHECK (jumlah_kelompok_tani >= 0),
    produksi NUMERIC(18, 4) NOT NULL CHECK (produksi >= 0),
    satuan_produksi_q TEXT NOT NULL,
    UNIQUE (padukuhan_id, komoditas, tahun)
);

CREATE TABLE bahan_organik (
    bahan_id TEXT PRIMARY KEY,
    jenis_bahan_organik TEXT NOT NULL,
    kategori_bahan TEXT NOT NULL
);

CREATE TABLE ketersediaan_bahan (
    ketersediaan_id TEXT PRIMARY KEY,
    bahan_id TEXT NOT NULL REFERENCES bahan_organik(bahan_id),
    padukuhan_id TEXT NOT NULL REFERENCES padukuhan(padukuhan_id),
    periode DATE NOT NULL,
    jumlah_ketersediaan NUMERIC(18, 2) NOT NULL CHECK (jumlah_ketersediaan >= 0),
    satuan TEXT NOT NULL,
    kontinuitas TEXT NOT NULL,
    jarak_ke_produksi_km NUMERIC(8, 2) CHECK (jarak_ke_produksi_km IS NULL OR jarak_ke_produksi_km >= 0),
    kemudahan_pengumpulan TEXT NOT NULL,
    status_pemanfaatan TEXT NOT NULL,
    frekuensi TEXT NOT NULL,
    musim TEXT NOT NULL,
    jumlah_sumber INTEGER NOT NULL CHECK (jumlah_sumber >= 0),
    status_data TEXT NOT NULL,
    UNIQUE (bahan_id, padukuhan_id, periode)
);

CREATE TABLE produk (
    produk_id TEXT PRIMARY KEY,
    nama_produk TEXT NOT NULL,
    jenis_produk TEXT NOT NULL,
    deskripsi TEXT,
    manfaat TEXT,
    harga NUMERIC(14, 2) CHECK (harga IS NULL OR harga >= 0),
    ukuran_kemasan TEXT,
    produsen TEXT,
    lokasi_produsen TEXT,
    kontak TEXT,
    stok_ketersediaan TEXT,
    foto_produk TEXT
);

CREATE TABLE produksi (
    produksi_id TEXT PRIMARY KEY,
    produk_id TEXT NOT NULL REFERENCES produk(produk_id),
    nama_produk TEXT NOT NULL,
    jenis_produk TEXT NOT NULL,
    jumlah_produksi_varian NUMERIC(18, 2) NOT NULL CHECK (jumlah_produksi_varian >= 0),
    jumlah_produksi_total NUMERIC(18, 2) NOT NULL CHECK (jumlah_produksi_total >= jumlah_produksi_varian),
    satuan TEXT NOT NULL,
    kapasitas_produk NUMERIC(18, 2) CHECK (kapasitas_produk IS NULL OR kapasitas_produk >= 0),
    bahan_baku_aktif TEXT,
    bahan_baku TEXT,
    jumlah_bahan_baku NUMERIC(18, 3) CHECK (jumlah_bahan_baku IS NULL OR jumlah_bahan_baku >= 0),
    periode_produksi INTEGER NOT NULL CHECK (periode_produksi BETWEEN 1900 AND 2100),
    status_data TEXT NOT NULL,
    satuan_bahan_baku TEXT,
    satuan_stok TEXT,
    stok NUMERIC(18, 3) CHECK (stok IS NULL OR stok >= 0),
    UNIQUE (produk_id, periode_produksi)
);

CREATE TABLE penjualan (
    penjualan_id TEXT PRIMARY KEY,
    produk_id TEXT NOT NULL REFERENCES produk(produk_id),
    bulan DATE NOT NULL CHECK (EXTRACT(DAY FROM bulan) = 1),
    produk TEXT NOT NULL,
    jumlah_terjual NUMERIC(18, 2) NOT NULL CHECK (jumlah_terjual >= 0),
    harga_satuan NUMERIC(14, 2) NOT NULL CHECK (harga_satuan >= 0),
    total_penjualan NUMERIC(18, 2) NOT NULL CHECK (total_penjualan >= 0),
    satuan TEXT,
    kanal TEXT,
    status_data TEXT,
    CHECK (total_penjualan = jumlah_terjual * harga_satuan),
    UNIQUE (produk_id, bulan)
);

-- Second catalog is kept only for audit; it is never merged into produk.
CREATE TABLE produk_katalog_audit (
    produk_id TEXT PRIMARY KEY,
    nama_produk TEXT NOT NULL,
    jenis_produk TEXT NOT NULL,
    deskripsi TEXT,
    manfaat TEXT,
    harga NUMERIC(14, 2) CHECK (harga IS NULL OR harga >= 0),
    ukuran_kemasan TEXT,
    produsen TEXT,
    lokasi_produsen TEXT,
    kontak TEXT,
    stok_ketersediaan TEXT,
    foto_produk TEXT
);

-- Kecamatan-level real agriculture. It cannot be joined to padukuhan.
CREATE TABLE data_pertanian_real (
    agri_id TEXT PRIMARY KEY,
    wilayah TEXT NOT NULL,
    komoditas TEXT NOT NULL,
    luas_panen_ha NUMERIC(12, 4) CHECK (luas_panen_ha IS NULL OR luas_panen_ha >= 0),
    luas_lahan_ha NUMERIC(12, 4) CHECK (luas_lahan_ha IS NULL OR luas_lahan_ha >= 0),
    jumlah_utp INTEGER CHECK (jumlah_utp IS NULL OR jumlah_utp >= 0),
    produksi NUMERIC(18, 4) CHECK (produksi IS NULL OR produksi >= 0),
    satuan_produksi TEXT NOT NULL,
    tahun_produksi INTEGER NOT NULL CHECK (tahun_produksi BETWEEN 1900 AND 2100),
    tahun_utp INTEGER CHECK (tahun_utp IS NULL OR tahun_utp BETWEEN 1900 AND 2100),
    sumber_produksi TEXT NOT NULL,
    sumber_utp TEXT,
    status_data TEXT NOT NULL,
    catatan TEXT,
    UNIQUE (wilayah, komoditas, tahun_produksi)
);

-- One row per validated import run. This is the durable staging/audit artifact;
-- row payloads are not stored here, so PII from the catalog is not duplicated.
CREATE TABLE staging_import_run (
    run_id TEXT PRIMARY KEY,
    started_at TIMESTAMPTZ NOT NULL,
    finished_at TIMESTAMPTZ,
    source_sha256 TEXT NOT NULL,
    mode TEXT NOT NULL CHECK (mode IN ('dry-run', 'apply')),
    status TEXT NOT NULL CHECK (status IN ('validated', 'applied', 'failed')),
    report JSONB NOT NULL
);

CREATE INDEX idx_padukuhan_kalurahan ON padukuhan(kalurahan_id);
CREATE INDEX idx_data_pertanian_padukuhan ON data_pertanian(padukuhan_id);
CREATE INDEX idx_ketersediaan_bahan_bahan ON ketersediaan_bahan(bahan_id);
CREATE INDEX idx_ketersediaan_bahan_padukuhan ON ketersediaan_bahan(padukuhan_id);
CREATE INDEX idx_produksi_produk ON produksi(produk_id);
CREATE INDEX idx_penjualan_produk ON penjualan(produk_id);
CREATE INDEX idx_penjualan_bulan ON penjualan(bulan);

COMMENT ON TABLE data_pertanian IS 'Synthetic padukuhan-level agriculture (sheet Data_Pertanian).';
COMMENT ON TABLE data_pertanian_real IS 'Real kecamatan-level agriculture (sheet Data Pertanian_real); not joinable to padukuhan.';
COMMENT ON TABLE produk_katalog_audit IS 'Audit copy of sheet Produk_Katalog; never merged into produk.';
COMMENT ON TABLE ketersediaan_bahan IS 'jarak_ke_produksi_km is NULL until a verified distance source exists.';
COMMENT ON TABLE produksi IS 'Use jumlah_produksi_varian for aggregation. jumlah_produksi_total is a repeated group total and must not be summed.';
COMMENT ON TABLE staging_import_run IS 'Validation/import run log. Dry-run reports are written to reports/*.json and are not inserted here.';
