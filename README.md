# VINIX7 — Sistem Pendukung Keputusan Bahan Organik

VINIX7 adalah aplikasi sistem pendukung keputusan untuk membantu menentukan prioritas bahan organik menggunakan metode **Analytical Hierarchy Process (AHP)** dan pemeringkatan alternatif berdasarkan kriteria yang digunakan.

## 🔗 Demo Aplikasi

- **Frontend:** https://project-tmn-tmn.vercel.app/
- **Backend API:** https://project-tmn-tmn.onrender.com/
- **API Ranking:** https://project-tmn-tmn.onrender.com/api/organic-materials/ranking

## 🛠️ Teknologi

- **Frontend:** Vite
- **Backend:** Python FastAPI
- **Database:** PostgreSQL
- **Database Hosting:** Neon PostgreSQL
- **Deployment:** Vercel dan Render
- **Metode pengambilan keputusan:** Analytical Hierarchy Process (AHP) dan pemeringkatan alternatif

## 📁 Struktur Proyek

```text
project-ebil/
├── backend/              # API dan logika backend
├── frontend/             # Aplikasi frontend
├── database/
│   └── vinix7.sql        # Ekspor struktur dan data PostgreSQL
├── scripts/              # Script pendukung
├── README.md
└── ...
```

## 🚀 Menjalankan Proyek Secara Lokal

### 1. Clone repository

```bash
git clone https://github.com/arif-is-a-dev/project-tmn-tmn.git
cd project-tmn-tmn
```

### 2. Siapkan database PostgreSQL

Pastikan PostgreSQL sudah terpasang dan database kosong bernama `vinix7` sudah dibuat.

Impor file database yang tersedia di repository:

```bash
psql -U postgres -d vinix7 -v ON_ERROR_STOP=1 -f database/vinix7.sql
```

Sesuaikan username PostgreSQL dengan konfigurasi di komputer masing-masing.

> **Catatan:** File SQL merupakan snapshot database pada saat ekspor. Perubahan yang dilakukan setelah ekspor tidak otomatis masuk ke file tersebut.

### 3. Konfigurasi backend

Siapkan virtual environment Python, aktifkan, lalu instal dependensi sesuai file dependensi yang tersedia di folder backend.

Contoh di Windows PowerShell:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

Jika repository menyediakan `requirements.txt` di root:

```powershell
pip install -r requirements.txt
```

Buat atau sesuaikan file `.env` berdasarkan konfigurasi yang dibaca backend. Isi koneksi database menggunakan PostgreSQL lokal milik masing-masing.

Jangan mengunggah `.env`, password, atau connection string database ke GitHub.

Jalankan backend menggunakan perintah yang sesuai dengan struktur modul proyek. Untuk konfigurasi deployment yang menggunakan Uvicorn:

```bash
uvicorn backend.app.main:app --reload
```

Dokumentasi API FastAPI biasanya tersedia di `/docs` pada alamat backend lokal.

### 4. Konfigurasi frontend

Masuk ke folder frontend:

```bash
cd frontend
npm install
```

Atur `VITE_API_BASE_URL` melalui file `.env` frontend sesuai alamat backend yang digunakan. Untuk pengembangan lokal, gunakan alamat backend lokal beserta prefix API yang sesuai.

Jalankan frontend:

```bash
npm run dev
```

Buka alamat lokal yang ditampilkan oleh Vite di terminal.

## 📊 Database

Repository menyediakan `database/vinix7.sql` yang berisi ekspor struktur dan data PostgreSQL untuk membantu anggota tim menyiapkan lingkungan pengembangan yang sama.

Untuk memeriksa data K3 setelah impor, jalankan:

```sql
SELECT
    COUNT(*) AS total_baris,
    COUNT(jarak_ke_produksi_km) AS k3_terisi,
    COUNT(*) - COUNT(jarak_ke_produksi_km) AS k3_null
FROM ketersediaan_bahan;
```

Pada database lokal yang diperiksa saat ekspor, terdapat 88 baris data K3 dan seluruhnya sudah terisi. Hasil dapat berbeda jika database telah diperbarui atau menggunakan snapshot lain.

## 🧮 Metode AHP dan K3

Endpoint ranking menyediakan bobot kriteria AHP, consistency ratio, dan hasil pemeringkatan alternatif.

**Catatan metodologi:** nilai jarak K3 yang digunakan pada simulasi dihitung menggunakan rumus Haversine dari titik referensi sintetis, yaitu centroid aritmetik 73 padukuhan sumber bahan organik. Titik tersebut bukan lokasi aktual fasilitas produksi. Bobot AHP juga merupakan asumsi simulasi, bukan hasil validasi pakar.

Karena itu, hasil ranking harus dipahami sebagai hasil simulasi dan belum dapat dianggap sebagai rekomendasi operasional yang tervalidasi.

## 🔐 Keamanan

- Jangan commit file `.env` atau kredensial database.
- Jangan membagikan password PostgreSQL atau connection string Neon.
- Pastikan data dalam dump SQL aman untuk dibagikan sebelum repository dipublikasikan.
- Gunakan kredensial dan database masing-masing untuk pengembangan lokal.