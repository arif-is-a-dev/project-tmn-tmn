# Vinix7 - Audit Data dan ETL PostgreSQL

Repositori ini berisi audit sumber Excel, skema PostgreSQL, importer dua mode,
dan validasi untuk proyek Sistem Data Terintegrasi Desa Cangkringan.

Status saat ini:

- Audit sumber dan dry-run selesai.
- Database PostgreSQL telah diinisialisasi dan diisi melalui mode `apply`.
- Backend FastAPI dan frontend React sudah berjalan.
- Ranking AHP-SAW aktif sebagai **simulasi** (lihat catatan metodologis di bawah).
- Model forecasting ExtraTreesRegressor terintegrasi (WAPE test 2025 = 58,25%).
- Nilai jarak bahan organik (K3) telah diisi menggunakan Haversine ke titik referensi sintetis.

## Struktur Folder

```text
.
|-- Data Projek Vinix (1).xlsx   # sumber, tidak diubah
|-- Projek_vinix.ipynb           # referensi analisis, tidak dijalankan
|-- PRD_Vinix7_Codex.md
|-- db/schema.sql                # DDL terkontrol, bukan idempotent
|-- scripts/vinix_etl.py         # baca Excel, transformasi, validasi, laporan
|-- scripts/db_utils.py          # guard target, cek skema, upsert, redaksi error
|-- scripts/init_db.py           # inisialisasi skema; default dry-run
|-- scripts/import_vinix.py      # importer; default dry-run
|-- scripts/validate_vinix.py    # validasi sumber dan database (read-only)
|-- tests/test_vinix_etl.py      # 15 unit test tanpa database
|-- reports/                     # laporan JSON hasil dry-run/validasi
|-- requirements.txt
|-- .env.example                 # contoh kredensial, tanpa secret nyata
`-- .gitignore                   # mengabaikan .env dan cache
```

Tidak ditemukan folder CSV hasil standardisasi di workspace ini. File model
`.pkl` tersedia di `backend/models/`. Frontend dan backend sudah
diimplementasikan.

## Sumber dan Pemetaan Sheet

Extent baris/kolom di bawah adalah extent pandas tanpa header. Baris berformat
kosong tidak dihitung. Detail kolom dan tipe pandas setiap sheet tersedia di
`reports/dry_run.json` pada bagian `sheet_audit`.

| Sheet | Baris x kolom | Peran | Tabel target |
|---|---:|---|---|
| `Data_produksi_pupuk` | 66 x 14 | ETL | `produksi` |
| `Data_Bahan_Organik` | 88 x 16 | ETL | `bahan_organik` + `ketersediaan_bahan` |
| `Produk_Katalog` | 11 x 12 | ETL audit | `produk_katalog_audit` |
| `Data_Produk_Katalog` | 11 x 12 | ETL utama | `produk` |
| `Data_Penjualan` | 792 x 10 | ETL | `penjualan` |
| `Data Wilayah_Kalurahan` | 5 x 16 | ETL | `kalurahan` |
| `Data_Wilayah_Padukuhan` | 73 x 8 | ETL | `padukuhan` |
| `Data_Pertanian` | 511 x 14 | ETL sintetis | `data_pertanian` |
| `Data Pertanian_real` | 14 x 14 | ETL riil | `data_pertanian_real` |
| `Copy of Data_Penjualan` | 792 x 19 | Arsip | tidak dimuat |
| `Copy of Data Pertanian_Dummy` | 522 x 17 | Arsip | tidak dimuat |
| `Copy of Data Wilayah_Kalurahan` | 13 x 18 | Arsip | tidak dimuat |
| `Copy of Data Wilayah_Padukuhan` | 87 x 19 | Arsip | tidak dimuat |

Notebook hanya membaca tujuh sheet: `Data_produksi_pupuk`,
`Data_Bahan_Organik`, `Data_Produk_Katalog`, `Data_Penjualan`,
`Data Wilayah_Kalurahan`, `Data_Wilayah_Padukuhan`, dan `Data_Pertanian`.
Kedua katalog dan data pertanian riil tetap diimpor ke tabel audit terpisah.

## Skema Database

DDL ada di `db/schema.sql`. File ini sengaja tidak memakai
`CREATE TABLE IF NOT EXISTS`, `DROP`, `TRUNCATE`, atau `DELETE`. Inisialisasi
akan berhenti jika salah satu tabel target sudah ada.

Tabel inti:

| Tabel | Primary key | Foreign key | Sumber |
|---|---|---|---|
| `kalurahan` | `kalurahan_id` | - | `Data Wilayah_Kalurahan` |
| `padukuhan` | `padukuhan_id` | `kalurahan_id` | `Data_Wilayah_Padukuhan` |
| `data_pertanian` | `agri_id` | `padukuhan_id` | `Data_Pertanian` (sintetis) |
| `bahan_organik` | `bahan_id` | - | `Data_Bahan_Organik` (unik) |
| `ketersediaan_bahan` | `ketersediaan_id` | `bahan_id`, `padukuhan_id` | `Data_Bahan_Organik` |
| `produk` | `produk_id` | - | `Data_Produk_Katalog` |
| `produksi` | `produksi_id` | `produk_id` | `Data_produksi_pupuk` |
| `penjualan` | `penjualan_id` | `produk_id` | `Data_Penjualan` |

Tabel tambahan:

| Tabel | Primary key | Fungsi |
|---|---|---|
| `produk_katalog_audit` | `produk_id` | Salinan audit `Produk_Katalog`, tidak digabung ke `produk` |
| `data_pertanian_real` | `agri_id` | Data riil tingkat kecamatan, tidak dapat di-join ke `padukuhan` |
| `staging_import_run` | `run_id` | Log satu run validasi/apply dalam bentuk JSONB |

`staging_import_run` tidak menyimpan payload baris, sehingga kontak katalog
tidak terduplikasi di log. Semua tabel memakai batasan nilai dan indeks yang
relevan. `penjualan.bulan` bertipe `DATE` dengan hari selalu 1.

Tabel hasil analisis berikut tidak dibuat oleh importer dan belum divalidasi
terhadap database: `hasil_prediksi`, `hasil_scoring`,
`hasil_peringkat_potensi_organik`, dan `perbandingan_ranking_organik`.

## Aturan Data yang Diterapkan

- `Data_Produk_Katalog` menjadi katalog utama; `Produk_Katalog` hanya audit.
- `Data_Pertanian` adalah data sintetis tingkat padukuhan; `Data Pertanian_real`
  adalah data riil tingkat kecamatan dan disimpan terpisah.
- Agregasi produksi memakai `jumlah_produksi_varian`.
  `jumlah_produksi_total` adalah total kelompok berulang dan tidak boleh
  dijumlahkan.
- `jarak_ke_produksi_km` telah diisi menggunakan fungsi Haversine dengan titik
  referensi sintetis (centroid aritmetik 73 padukuhan sumber). Nilai ini
  merupakan **simulasi garis lurus**, bukan jarak perjalanan atau lokasi aktual
  fasilitas produksi. Lihat catatan metodologis AHP-SAW di bawah.
- Semua sheet `Copy of ...` hanya arsip dan tidak dimuat.
- Baris penjualan dengan jumlah 0 dipertahankan; bukan data rusak.
- `Total_Penjualan = Jumlah_Terjual x Harga_Satuan` divalidasi untuk semua baris.
- Nilai `status_data = 'Sintestis'` dipertahankan apa adanya sampai ada
  keputusan normalisasi.
- Kontak produsen adalah PII; nilainya tidak ditulis ke laporan atau log.

## Instalasi

Gunakan Python 3.13 dari PowerShell:

```powershell
py -3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
py -3.13 -m pip install -r requirements.txt
```

Dependensi: pandas, openpyxl, SQLAlchemy, psycopg2-binary, dan python-dotenv.
Test memakai `unittest`; `pytest` tidak diperlukan.

## Konfigurasi Koneksi

Salin contoh environment, lalu isi kredensial PostgreSQL lokal:

```powershell
Copy-Item .env.example .env
notepad .env
```

Isi `VINIX7_DATABASE_URL` dengan format:

```text
postgresql+psycopg2://USER:PASSWORD@localhost:5432/vinix7
```

Jangan commit `.env`. File itu sudah diabaikan oleh `.gitignore`. Script
`apply` hanya menerima host `localhost`, `127.0.0.1`, atau `::1` dengan nama
database tepat `vinix7`; target lain ditolak.

## Dry-Run (Default, Tanpa Database)

```powershell
py -3.13 scripts/init_db.py --dry-run
py -3.13 scripts/import_vinix.py --dry-run --report reports/dry_run.json
py -3.13 scripts/validate_vinix.py --report reports/validate_source.json
py -3.13 -m unittest discover -s tests -v
```

`import_vinix.py` tanpa argumen juga berjalan sebagai dry-run. Mode ini hanya
membaca Excel, melakukan transformasi dan validasi, lalu menulis laporan JSON.
Mode ini tidak membuka koneksi PostgreSQL.

## Apply Setelah Persetujuan Eksplisit

Jangan jalankan perintah berikut sebelum pengguna menyetujui perubahan database.

```powershell
py -3.13 scripts/init_db.py --apply
py -3.13 scripts/import_vinix.py --apply
py -3.13 scripts/validate_vinix.py --database
```

Konfirmasi interaktif:

- `init_db.py --apply`: ketik `INISIALISASI VINIX7`.
- `import_vinix.py --apply`: ketik `IMPOR VINIX7`.

`init_db.py` tidak melakukan reset dan menolak jika tabel target sudah ada.
Importer memakai transaksi tunggal dan upsert berdasarkan primary key. Tidak
ada `if_exists="replace"`, `DROP`, `TRUNCATE`, atau penghapusan data otomatis.

## Validasi

Validasi sumber memeriksa fatal error, jumlah baris target, aturan
`jumlah_produksi_varian`, dan konsistensi total penjualan. Validasi `--database`
menambahkan pemeriksaan:

- jumlah baris database terhadap hasil transformasi;
- keunikan primary key dan foreign key yatim;
- rentang bulan penjualan;
- rumus total penjualan;
- pemisahan data pertanian sintetis dan riil;
- kolom wajib skema.

Laporan validasi ditulis ke `reports/validate.json` secara default.

## Integrasi Notebook

Notebook asli memakai DDL yang berbeda dari skema final: tanggal disimpan
sebagai `TEXT`, `kapasitas_produk` sebagai `TEXT`, dan beberapa tabel memakai
`CREATE TABLE IF NOT EXISTS`. Skema final memakai tipe yang lebih ketat.

Notebook juga membuat tabel hasil dengan `to_sql(if_exists="replace")`.
Importer tidak meniru perilaku destruktif tersebut. Sebelum menjalankan
forecasting, AHP, atau SAW, tentukan strategi tabel hasil dan pastikan data
sumber lolos validasi.

AHP-SAW membutuhkan `jarak_ke_produksi_km`. Nilai jarak telah diisi menggunakan
Haversine ke titik referensi sintetis (centroid aritmetik 73 padukuhan sumber),
bukan lokasi aktual fasilitas produksi. Ranking AHP-SAW sekarang aktif sebagai
**simulasi** — bobot AHP berasal dari notebook dan belum divalidasi pakar.
`hasil_scoring` adalah ranking produk berdasarkan prediksi penjualan, bukan
ranking potensi bahan organik. Jangan menggabungkan keduanya.

### Catatan Metodologis AHP-SAW

- **K3 (Jarak ke lokasi produksi)** dihitung dengan formula Haversine (great-circle
  distance) menggunakan titik referensi sintetis: latitude = -7.6458732,
  longitude = 110.4530850. Titik ini adalah centroid aritmetik dari 73 padukuhan
  sumber bahan organik, **bukan** lokasi aktual CV. Pendawa Kencana Multi Farm
  atau fasilitas produksi manapun.
- Jarak yang dihasilkan adalah **garis lurus** (straight-line), bukan jarak
  perjalanan jalan raya. Rentang nilai: 0,48 – 8,10 km.
- **Bobot AHP** (K1=0,395, K2=0,239, K3=0,198, K4=0,168) merupakan asumsi
  simulasi dari Projek_vinix.ipynb Cell 308, **bukan** hasil validasi pakar atau
  mitra lapangan. Consistency Ratio (CR) = 0,022 (< 0,10 threshold).
- Seluruh hasil ranking harus dilabeli sebagai **simulasi** dalam tampilan
  pengguna. Field `methodological_note` pada respons API `/api/organic-materials/ranking`
  berisi penjelasan ini secara otomatis.
- Script pengisian jarak: `scripts/compute_k3_distances.py` (mode preview dan
  write terpisah, transaksi database dengan rollback on failure).

### Catatan Metodologis Forecasting

- Model: **ExtraTreesRegressor** (scikit-learn 1.9.1) dengan 500 estimator,
  max_depth=15, fitur lag (1, 2, 3, 12 bulan) + OneHotEncoder produk.
- Data latih: 792 baris penjualan historis 2020–2025 dari PostgreSQL (bukan Excel asli).
- Metrik validasi: WAPE test 2025 = **58,25%**, MAE = 5,23, RMSE = 11,29.
- Prediksi bersifat **recursive**: hasil prediksi bulan sebelumnya menjadi input
  lag untuk bulan berikutnya, sehingga error dapat terakumulasi.
- Prediksi negatif di-clamp ke 0. Transaksi bernilai 0 dipertahankan (bukan data rusak).
- File model: `backend/models/sales_forecast_pipeline.pkl` + metadata JSON.
- Hasil prediksi hanya cocok untuk **perencanaan kasar**, bukan akurasi yang dijamin.

## Batasan dan Keputusan yang Masih Terbuka

- Perlu keputusan apakah `Sintestis` dinormalisasi menjadi `Sintetis`.
- Perlu keputusan apakah `data_pertanian_real` dan `produk_katalog_audit`
  ditampilkan di aplikasi atau hanya menjadi arsip audit.
- Perlu keputusan strategi tabel hasil analisis tanpa `if_exists="replace"`.
- Kontak produsen memerlukan kontrol akses jika katalog diekspos.
- Upsert tidak menghapus baris lama yang sudah tidak ada di Excel. Database
  harus dalam keadaan bersih atau konsisten sebelum apply.
- Pemeriksaan skema memvalidasi keberadaan kolom wajib, belum membandingkan
  tipe dan constraint secara menyeluruh.
- **Data stok memiliki satuan berbeda** (kg, zak, L) — agregat `total_stok`
  dari `/api/production/summary` menjumlahkan lintas satuan dan **tidak boleh**
  ditafsirkan sebagai satu angka bermakna. Stok per-record tetap valid dengan
  satuan masing-masing.
- Ranking AHP-SAW dan jarak K3 bersifat simulasi; validasi pakar diperlukan
  sebelum digunakan untuk pengambilan keputusan operasional.

## Integritas Sumber

SHA256 `Data Projek Vinix (1).xlsx`:

```text
0f352dec5dc71410294196678590f9702a20732210aa89f09309473b33cfcc13
```

File Excel, notebook, dan PRD tidak diubah oleh proses audit/ETL ini.

## Backend FastAPI (MVP Fondasi)

### Struktur

```text
backend/
|-- __init__.py
|-- app/
|   |-- __init__.py
|   |-- config.py      # DatabaseSettings (VINIX7_DATABASE_URL, local-only guard)
|   |-- database.py    # SQLAlchemy engine, get_db_session (read-only)
|   |-- geo.py         # Haversine distance function (pure, no DB dependency)
|   |-- models.py      # ORM models mirroring db/schema.sql
|   |-- schemas.py     # Pydantic request/response schemas
|   |-- main.py        # FastAPI app, CORS, route registration
|   `-- routes/
|       |-- __init__.py
|       |-- health.py       # GET /api/health
|       |-- products.py     # GET /api/products, /{id}, /jenis/list
|       |-- organic.py      # GET /api/organic-materials, /summary, /criteria-status, /ranking
|       |-- production.py   # GET /api/production, /summary
|       |-- sales.py        # GET /api/sales, /summary
|       |-- forecasts.py    # GET /api/forecasts, /summary
|       `-- wilayah.py      # GET /api/wilayah/kalurahan, /padukuhan, /summary
|-- models/
|   |-- sales_forecast_pipeline.pkl   # ExtraTreesRegressor model
|   `-- sales_forecast_metadata.json  # Training metadata & metrics
`-- tests/
    |-- __init__.py
    |-- conftest.py           # TestClient fixture, env loading
    |-- test_health.py
    |-- test_products.py
    |-- test_organic.py       # 26 tests (ranking, blocked scenario via mock)
    |-- test_organic_saw_math.py  # Independent AHP-SAW math verification
    |-- test_geo.py           # 35 Haversine unit tests
    |-- test_compute_k3.py    # 21 K3 distance script tests
    |-- test_production.py
    |-- test_sales.py
    |-- test_forecasts.py
    `-- test_wilayah.py
```

### Endpoint

| Method | Path | Deskripsi |
|--------|------|-----------|
| GET | `/api/health` | Status API dan koneksi database |
| GET | `/api/products` | Daftar produk (paginated, filterable) |
| GET | `/api/products/{produk_id}` | Detail satu produk |
| GET | `/api/products/jenis/list` | Jenis produk unik |
| GET | `/api/organic-materials` | Daftar bahan organik + agregat ketersediaan |
| GET | `/api/organic-materials/summary` | Ringkasan jumlah bahan dan kelengkapan kriteria |
| GET | `/api/organic-materials/criteria-status` | Status K1–K4 (complete/incomplete) |
| GET | `/api/organic-materials/ranking` | Ranking AHP-SAW atau status blocked + methodological_note |
| GET | `/api/production` | Daftar record produksi (paginated, filterable) |
| GET | `/api/production/summary` | Agregat produksi: records, produk, periode, varian, stok |
| GET | `/api/sales` | Daftar penjualan historis (paginated, filterable) |
| GET | `/api/sales/summary` | Agregat penjualan: revenue, volume, kanal |
| GET | `/api/forecasts` | Daftar prediksi penjualan 2026 (paginated) |
| GET | `/api/forecasts/summary` | Ringkasan prediksi + metadata model + metrik validasi |
| GET | `/api/wilayah/kalurahan` | Daftar kalurahan (paginated) |
| GET | `/api/wilayah/padukuhan` | Daftar padukuhan (paginated, filter by kalurahan) |
| GET | `/api/wilayah/summary` | Ringkasan wilayah: total kalurahan, padukuhan |

### Cara Menjalankan (Lokal)

Pastikan `.env` sudah dikonfigurasi dengan kredensial PostgreSQL lokal, lalu:

```powershell
# Install dependencies
py -3.13 -m venv .venv_backend
. .venv_backend/Scripts/activate
py -3.13 -m pip install -r requirements.txt

# Jalankan server
py -3.13 -m uvicorn backend.app.main:app --reload --host 127.0.0.1 --port 8000
```

API dokumentasi interaktif: `http://127.0.0.1:8000/docs`

### Menguji Endpoint

```powershell
# Health check
Invoke-RestMethod http://127.0.0.1:8000/api/health | ConvertTo-Json

# Daftar produk
Invoke-RestMethod "http://127.0.0.1:8000/api/products?per_page=3" | ConvertTo-Json

# Detail produk
Invoke-RestMethod http://127.0.0.1:8000/api/products/PROD-001 | ConvertTo-Json
```

### Menjalankan Unit Test

```powershell
. .venv_backend/Scripts/activate
py -3.13 -m pytest backend/tests/ -v
```

### Catatan Keamanan

- Koneksi hanya mendukung PostgreSQL lokal (`localhost/127.0.0.1`).
- Tidak ada kredensial yang ditulis ke log atau response.
- Kolom `kontak` (PII) tidak pernah disertakan dalam respons API.
- Semua endpoint read-only; tidak ada operasi tulis ke database.
- CORS dibatasi ke `http://localhost:5173` dan `http://localhost:3000` (override via `CORS_ORIGINS` env var).

## Frontend React (Tahap 3)

### Struktur

```text
frontend/
|-- index.html
|-- package.json
|-- vite.config.js          # proxy /api → http://localhost:8000
|-- tailwind.config.js      # custom palette (primary=green, accent=teal, surface=stone)
|-- postcss.config.js
`-- src/
    |-- main.jsx            # React 18 mount
    |-- App.jsx             # BrowserRouter, sidebar layout, 7 routes
    |-- index.css           # Tailwind directives, scrollbar, animations
    |-- services/
    |   |-- api.js          # apiGet(), semua endpoint wrapper (products, organic, production, sales, forecasts, wilayah)
    |   `-- formatters.js   # formatRupiah(), formatNumber(), formatDate() (id-ID locale)
    |-- components/
    |   |-- layout/
    |   |   |-- Sidebar.jsx  # 7 NavLink items, mobile overlay
    |   |   `-- TopBar.jsx   # mobile menu toggle, API status pill (polls /api/health every 30s)
    │   |-- products/
    │   │   |-- ProductCard.jsx  # card with formatted price, badge
    │   │   `-- ProductModal.jsx  # full detail panel, PII notice
    │   └── ui/
    │       |-- Badge.jsx        # green/blue/amber/gray variants
    │       |-- Skeleton.jsx     # Skeleton, SkeletonCard, SkeletonTable
    │       |-- EmptyState.jsx   # icon + title + description
    │       `-- ErrorState.jsx  # alert + message + optional retry
    `-- pages/
        |-- Dashboard.jsx            # KPI cards (4 data-driven), methodological note, product preview
        |-- ProductsPage.jsx         # search, jenis filter, paginated grid, ProductModal
        |-- OrganicMaterialsPage.jsx # AHP-SAW ranking table, simulation warning, blocked notice
        |-- ProductionPage.jsx       # production records table, summary stats
        |-- SalesPage.jsx            # sales history + forecast predictions chart
        |-- WilayahPage.jsx          # kalurahan/padukuhan tables with coordinates
        `-- DataPage.jsx             # link cards to all data sections
```

### Cara Menjalankan (Lokal)

```powershell
cd frontend
npm install

# Development (memerlukan backend berjalan di port 8000)
npm run dev

# Vite proxy otomatis meneruskan /api → http://localhost:8000
# Buka http://localhost:5173
```

### Build Produksi

```powershell
npm run build
# Output: dist/
```

### Catatan Implementasi

- **Tidak ada data palsu** — semua data berasal dari PostgreSQL via FastAPI.
- **Loading/error/empty states** — setiap halaman menampilkan SkeletonCard saat memuat,
  ErrorState saat gagal, dan EmptyState saat tidak ada hasil.
- **Kontak tidak pernah ditampilkan** — kolom `kontak` di-redact di backend (schema + route)
  dan tidak pernah di-render di UI.
- **AHP-SAW (OrganicMaterialsPage)** — ranking aktif sebagai simulasi. K3 dihitung dengan
  Haversine ke centroid sintetis 73 padukuhan (bukan lokasi aktual). Bobot AHP belum
  divalidasi pakar. SimulationWarning banner selalu tampil di atas tabel ranking.
  Jika kriteria tidak lengkap, RankingBlockedNotice tampil sebagai pengganti tabel.
- **Prediksi penjualan (SalesPage)** — model ExtraTreesRegressor terintegrasi
  (`backend/models/sales_forecast_pipeline.pkl`). WAPE test 2025 = 58,25%. Prediksi
  bersifat recursive dan hanya cocok untuk perencanaan kasar. Quality warning
  selalu tampil di halaman prediksi.
- **Produksi & Stok (ProductionPage)** — endpoint `GET /api/production` dan
  `/api/production/summary` tersedia. Data stok memiliki satuan berbeda (kg, zak, L);
  agregat total_stok tidak boleh ditafsirkan sebagai satu angka bermakna.
- **Dashboard** — 4 KPI card data-driven (Produk, Bahan Organik, Produksi, Penjualan),
  catatan metodologis tentang simulasi AHP-SAW dan keterbatasan agregat stok.