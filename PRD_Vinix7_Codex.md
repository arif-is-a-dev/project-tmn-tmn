# PRD — Sistem Data Terintegrasi Desa Cangkringan

## 1. Informasi Proyek

**Judul:** PENGEMBANGAN SISTEM DATA TERINTEGRASI UNTUK OPTIMALISASI POTENSI BAHAN ORGANIK, PRODUKSI, DAN PEMASARAN PRODUK DESA CANGKRINGAN BERBASIS DATA.

**Tujuan:** Membangun website dengan dashboard dan katalog digital untuk mengintegrasikan data pertanian, bahan organik, produksi, stok, dan penjualan; memberi peringkat potensi bahan organik untuk bahan baku pupuk; menampilkan prediksi permintaan/penjualan pupuk; serta mendukung informasi dan pemasaran produk desa.

**Pengguna utama:** pengelola/mitra desa dan tim proyek. Untuk MVP, buat dashboard informatif yang mudah digunakan. Jangan menambahkan sistem akun kompleks kecuali memang diperlukan oleh struktur proyek yang sudah ada.

## 2. Rumusan Masalah yang Harus Dijawab

1. Bagaimana mengintegrasikan data produksi, penjualan, stok, dan bahan baku pupuk organik serta probiotik?
2. Bagaimana menentukan bahan organik paling potensial berdasarkan ketersediaan, kontinuitas, jarak, dan kemudahan memperoleh bahan?
3. Bagaimana memprediksi kebutuhan atau permintaan pupuk organik berdasarkan data historis produksi dan penjualan?
4. Bagaimana menyajikan integrasi data, analisis potensi bahan organik, prediksi, dan informasi produk dalam website untuk mendukung perencanaan produksi dan pemasaran Desa Cangkringan?

## 3. Kondisi Awal dan Aset yang Sudah Ada

Ada notebook `Projek_vinix.ipynb` yang berisi proses data profiling, data cleaning, standardisasi, ETL ke PostgreSQL, EDA, AHP-SAW untuk potensi bahan organik, model Extra Trees untuk prediksi penjualan, evaluasi model, prediksi 2026, dan penyimpanan hasil ke PostgreSQL/CSV/PKL.

Notebook mengacu pada PostgreSQL lokal dengan database `vinix7`. Tabel inti yang digunakan:

- `kalurahan`
- `padukuhan`
- `data_pertanian`
- `bahan_organik`
- `ketersediaan_bahan`
- `produk`
- `produksi`
- `penjualan`

Notebook juga membuat/menyimpan hasil analisis seperti `hasil_scoring` dan `hasil_prediksi`. **Nama kolom dan skema final harus diperiksa langsung dari database/SQL yang tersedia; jangan mengarang kolom atau mengasumsikan semua tabel sudah sama persis dengan contoh notebook.**

### Temuan yang harus diperhatikan

- AHP-SAW untuk bahan organik sudah mulai diimplementasikan dalam notebook. Empat kriterianya: ketersediaan, kontinuitas, jarak ke lokasi produksi, dan kemudahan pengumpulan.
- Notebook menyebut bobot matriks AHP sebagai **asumsi simulasi**, bukan hasil penilaian mitra/ahli. Tampilkan label/peringatan ini di UI sampai bobot divalidasi oleh mitra. Jangan menyatakan bobot tersebut sebagai keputusan resmi mitra.
- Notebook juga memiliki peringkat produk berdasarkan total prediksi penjualan. Itu **berbeda** dari peringkat potensi bahan organik. Pisahkan kedua konsep dan labelnya dengan jelas.
- Model prediksi yang dibuat adalah Extra Trees untuk `Jumlah_Terjual`, dengan fitur seperti produk, bulan kalender, dan lag historis. Hasil prediksi 2026 di notebook adalah proyeksi penjualan, bukan kepastian permintaan aktual.
- Notebook memiliki path lokal/Google Drive dan kredensial database yang ditulis langsung pada sel kode. Jangan menyalin kredensial/path tersebut ke aplikasi. Gunakan environment variables dan file `.env` yang tidak masuk Git.
- Beberapa bagian notebook menggunakan `to_sql(if_exists="replace")`. Jangan membuat aplikasi web menimpa tabel sumber atau tabel hasil secara destruktif saat aplikasi berjalan.

## 4. Stack Teknologi yang Disarankan

Gunakan stack berikut kecuali repository yang sudah ada menunjukkan pilihan yang harus dipertahankan:

- **Frontend:** React + Vite + TypeScript (jika konfigurasi TypeScript terlalu mengganggu struktur yang ada, pertahankan pola proyek yang ditemukan), Tailwind CSS, shadcn/ui atau komponen accessible setara.
- **Visualisasi:** Recharts atau library chart yang sudah ada di repository.
- **Backend API:** Python + FastAPI.
- **Database:** PostgreSQL. Pertahankan skema yang sudah ada; target deployment dapat memakai PostgreSQL cloud gratis seperti Neon Free.
- **ORM/DB access:** SQLAlchemy + psycopg.
- **Model:** gunakan pipeline/model Extra Trees yang sudah disimpan bila file model tersedia dan kompatibel. Jangan melatih ulang tanpa alasan yang jelas.
- **Deployment sasaran:** frontend Vercel, API Render, database PostgreSQL cloud (misalnya Neon). Konfigurasi harus dapat diganti melalui environment variables.

## 5. Prinsip Implementasi untuk Codex

1. **Mulai dengan audit repository.** Periksa struktur folder, README, notebook, file SQL, file model `.pkl`, CSV hasil, dependency, dan status Git sebelum mengubah apa pun.
2. Berikan ringkasan singkat tentang apa yang sudah tersedia, apa yang kurang, dan rencana implementasi sebelum melakukan perubahan besar.
3. Jangan menghapus, menimpa, memindahkan, atau menulis ulang notebook/database/model yang sudah ada tanpa kebutuhan yang jelas.
4. Jangan menginisialisasi Git, melakukan commit, push, force push, atau mengubah remote.
5. Jangan menampilkan atau menyalin password, token, atau URL database dengan kredensial ke log, dokumentasi, screenshot, atau frontend. Jika menemukan kredensial hardcoded, tandai untuk diganti dan gunakan environment variables di aplikasi baru.
6. Jangan mengarang data, nama produk, bobot kriteria, metrik model, atau hasil prediksi. Jika data tidak tersedia, tampilkan empty state yang jelas.
7. Pertahankan logika analisis yang sudah ada setelah diverifikasi. Pisahkan kode aplikasi dari notebook agar API tidak perlu mengeksekusi seluruh notebook setiap kali menerima request.
8. Jangan menggunakan data dummy sebagai hasil produksi secara diam-diam. Data demo harus diberi label `Demo` dan mudah dimatikan.
9. Setelah implementasi, jalankan test/build yang tersedia dan laporkan hasil aktual serta hal yang belum dapat diuji.
10. Utamakan langkah sederhana dan kode yang mudah dirawat. Jangan menambah arsitektur kompleks yang tidak dibutuhkan untuk mini project.

## 6. Fitur MVP

### 6.1 Dashboard

Tampilkan ringkasan yang bersumber dari API/database:

- total jenis bahan organik;
- total produk katalog;
- ringkasan produksi dan stok jika kolomnya tersedia;
- ringkasan penjualan historis;
- ringkasan proyeksi penjualan 2026 bila hasil tersedia;
- grafik penjualan aktual dari waktu ke waktu;
- grafik proyeksi bulanan dan/atau per produk;
- daftar bahan organik berperingkat tertinggi dari AHP-SAW.

Semua angka KPI harus berasal dari database/API. Tampilkan skeleton/loading, error state, dan empty state jika data belum tersedia.

### 6.2 Potensi Bahan Organik

Buat halaman tabel dan detail analisis bahan organik. Kriteria yang ditampilkan:

1. Ketersediaan bahan — benefit.
2. Kontinuitas — benefit.
3. Jarak ke lokasi produksi — cost.
4. Kemudahan pengumpulan — benefit.

Tampilkan nilai sumber, nilai normalisasi SAW, bobot AHP, skor akhir, dan peringkat bila tersedia. Tambahkan filter pencarian dan pengurutan.

Aturan:

- Ikuti kategori dan konversi yang sudah ada di notebook setelah memverifikasi implementasinya.
- Validasi input kosong, kategori tak dikenal, jarak nol/negatif, nilai numerik tidak valid, dan pembagian nol.
- Tampilkan bahwa bobot AHP saat ini merupakan asumsi simulasi jika belum dikonfirmasi mitra.
- Jangan menyamakan ranking potensi bahan organik dengan ranking produk berdasarkan prediksi penjualan.
- Jika perlu mengubah bobot, jangan simpan perubahan resmi tanpa mekanisme yang jelas. Untuk MVP boleh hanya menampilkan bobot yang sedang dipakai.

### 6.3 Produksi dan Stok

Tampilkan data produksi dan stok berdasarkan tabel yang ada. Fitur minimal:

- tabel dengan pencarian, filter produk/periode, dan pagination jika jumlah baris besar;
- ringkasan jumlah produksi dan stok dengan satuan yang benar;
- grafik tren jika tersedia kolom tanggal/periode yang valid.

Jangan menyimpulkan stok aman/kritis tanpa ambang batas yang disepakati. Jika ambang belum ada, tampilkan nilai stok mentah.

### 6.4 Penjualan dan Prediksi

Tampilkan:

- data historis penjualan;
- prediksi penjualan bulanan per produk;
- total prediksi per produk dan per bulan;
- informasi model: Extra Trees dan fitur utama yang digunakan, jika dapat dikonfirmasi dari pipeline model;
- metrik evaluasi yang benar-benar tersedia dari notebook (misalnya MAE/RMSE/WAPE), tanpa mengarang nilai.

Beri label jelas bahwa prediksi 2026 merupakan estimasi model. Jangan mengklaim sebagai penjualan aktual. Jangan melatih ulang model setiap kali halaman dibuka.

### 6.5 Katalog Digital

Buat halaman katalog produk yang mengambil data dari tabel `produk` dan menggabungkan data relevan yang memang tersedia. Minimal:

- nama produk;
- kategori/deskripsi jika kolom tersedia;
- harga jika tersedia;
- informasi produk lain hanya jika ada di database.

Sediakan pencarian dan filter kategori bila datanya mendukung. Jika gambar produk tidak tersedia, gunakan placeholder yang rapi; jangan mengarang foto atau informasi. MVP cukup katalog informatif; checkout/payment tidak termasuk scope.

### 6.6 Halaman Data Terintegrasi

Sediakan halaman ringkas untuk melihat data bahan organik, produksi, penjualan, stok, wilayah, dan pertanian. Baca saja pada MVP kecuali operasi tambah/edit/hapus memang diminta dan memiliki aturan validasi/otorisasi.

## 7. Rancangan API Awal

Rute berikut adalah usulan; sesuaikan dengan skema yang benar setelah audit:

- `GET /api/health` — status API dan koneksi database (tanpa membocorkan detail rahasia).
- `GET /api/dashboard/summary` — KPI ringkasan.
- `GET /api/dashboard/sales-trend` — penjualan historis per periode.
- `GET /api/organic-materials` — daftar bahan organik dan ringkasan ketersediaan.
- `GET /api/organic-materials/ranking` — hasil AHP-SAW bahan organik.
- `GET /api/organic-materials/{bahan_id}` — detail bahan dan kriteria.
- `GET /api/production` — data produksi dan stok.
- `GET /api/sales` — penjualan historis dengan filter periode/produk.
- `GET /api/forecasts` — hasil prediksi yang sudah tersimpan.
- `GET /api/forecasts/summary` — rekap prediksi per produk/periode.
- `GET /api/products` — katalog produk dengan pencarian/filter.
- `GET /api/products/{produk_id}` — detail produk.

Ketentuan API:

- Gunakan Pydantic schemas dan response yang konsisten.
- Tambahkan pagination/filter untuk endpoint tabel bila diperlukan.
- Tangani error database dengan aman; jangan mengirim stack trace atau kredensial ke client.
- Batasi CORS ke domain frontend lewat environment variable; jangan gunakan wildcard untuk konfigurasi production bila tidak diperlukan.
- Gunakan query parameter yang tervalidasi dan query SQL parameterized/ORM.
- Untuk MVP, endpoint bersifat read-only kecuali ada kebutuhan yang terkonfirmasi.

## 8. Database dan Environment

- Pertahankan tabel inti dan relasi yang ada. Jangan membuat duplikasi tabel sumber tanpa alasan.
- Sebelum migrasi cloud, periksa primary key, foreign key, tipe data, jumlah record, dan query yang digunakan notebook.
- Gunakan `DATABASE_URL` untuk koneksi deployment. Jangan hardcode host/user/password.
- Siapkan `.env.example` berisi nama variabel dan contoh placeholder saja, tanpa rahasia.
- Pastikan `.env`, credential, file backup sensitif, dan data privat tidak masuk Git.
- Buat skrip migrasi/DDL tambahan hanya jika dibutuhkan dan tidak destruktif. Dokumentasikan cara backup dan restore.
- Jangan menjalankan `DROP TABLE`, `TRUNCATE`, atau replace table secara otomatis dari aplikasi web.

## 9. UI/UX dan Arah Visual

Buat antarmuka dashboard data yang modern, profesional, bersih, dan responsif; cocok untuk presentasi proyek akademik dan mitra desa.

- Layout desktop: sidebar kiri, topbar, area konten utama.
- Palet: hijau/teal sebagai aksen yang berkaitan dengan pertanian, latar netral terang, teks kontras.
- KPI cards sederhana, grafik jelas, tabel mudah dibaca, status loading/error/empty state.
- Navigasi: Dashboard, Potensi Bahan Organik, Produksi & Stok, Penjualan & Prediksi, Katalog Produk, Data Wilayah (bila relevan).
- Desain responsif untuk laptop, tablet, dan ponsel.
- Gunakan format angka Indonesia yang konsisten dan jangan mengasumsikan satuan jika tidak tersedia.
- Aksesibilitas dasar: label input, keyboard navigation, fokus terlihat, kontras memadai, semantik heading, dan teks alternatif untuk gambar.
- Hindari animasi berlebihan, grafik dekoratif tanpa data, serta angka dummy yang tampak nyata.

## 10. Keamanan dan Keandalan

- Tidak ada kredensial database di source code frontend atau repository.
- Frontend hanya mengakses database melalui API; tidak ada koneksi PostgreSQL langsung dari browser.
- CORS dibatasi ke domain yang diizinkan.
- Validasi parameter, penanganan error, timeout, dan logging tanpa rahasia.
- Tidak perlu login kompleks untuk MVP jika belum diminta, tetapi jangan mengklaim data terlindungi dari perubahan jika semua endpoint terbuka. Endpoint tulis/admin harus ditunda sampai autentikasi ditentukan.
- Jangan mengubah data sumber ketika hanya menampilkan dashboard.

## 11. Deployment Target

Target awal untuk demo gratis:

- Frontend: Vercel.
- Backend FastAPI: Render atau penyedia yang sesuai dengan batasan gratis saat deployment dilakukan.
- PostgreSQL: Neon Free atau PostgreSQL cloud gratis setara.

Buat konfigurasi deploy dan dokumentasi untuk:

1. variabel environment frontend (misalnya `VITE_API_BASE_URL`);
2. variabel environment backend (`DATABASE_URL`, `CORS_ORIGINS`);
3. perintah build/start yang benar;
4. migrasi database dari PostgreSQL lokal ke cloud;
5. health check API;
6. catatan bahwa layanan gratis dapat sleep/terbatas dan first request mungkin lambat.

Jangan mengklaim deployment berhasil sebelum benar-benar diuji. Jangan memigrasikan data ke layanan cloud tanpa persetujuan pengguna.

## 12. Testing dan Acceptance Criteria

Implementasi dianggap memenuhi MVP jika:

1. Frontend dapat dijalankan secara lokal dengan instruksi README yang jelas.
2. Backend FastAPI dapat dijalankan secara lokal dan memiliki endpoint health.
3. Backend membaca PostgreSQL melalui `DATABASE_URL`, bukan kredensial hardcoded.
4. Dashboard mengambil data nyata dari API; bila database belum tersedia, UI menunjukkan error/empty state yang jelas.
5. Halaman potensi bahan organik menunjukkan empat kriteria yang benar dan ranking AHP-SAW terpisah dari ranking penjualan.
6. Label asumsi bobot AHP ditampilkan sampai bobot dikonfirmasi mitra.
7. Halaman prediksi menampilkan hasil Extra Trees yang sudah tersimpan, dengan label estimasi, bukan aktual.
8. Katalog membaca tabel produk dan tidak menampilkan atribut yang tidak tersedia.
9. Tidak ada aksi otomatis yang menimpa/menghapus tabel sumber atau melatih ulang model saat halaman dibuka.
10. UI berfungsi pada ukuran mobile dan desktop, dengan loading/error/empty state.
11. Build frontend berhasil; tes backend yang tersedia berjalan. Jika tidak ada test suite, buat test dasar untuk health, query/API utama, dan fungsi scoring yang bisa diuji tanpa merusak database.
12. Tidak ada secret dalam frontend, file contoh environment, atau output log.
13. README menjelaskan setup lokal, variabel environment, pengujian, dan deployment.
14. Codex memberikan ringkasan file yang dibuat/diubah, perintah yang dijalankan, hasil test/build aktual, serta pekerjaan yang belum selesai.

## 13. Di Luar Scope MVP

- Checkout dan pembayaran online.
- Sistem marketplace penuh.
- Prediksi real-time yang melatih ulang model otomatis.
- Penggantian algoritma model yang sudah ada tanpa bukti kebutuhan.
- Penghapusan atau rekonstruksi database yang sudah ada.
- Autentikasi/role kompleks sebelum kebutuhan akses ditentukan.
- Integrasi IoT, sensor, atau API eksternal yang tidak disebutkan dalam kebutuhan.

## 14. Rencana Kerja yang Harus Diikuti Codex

### Tahap 1 — Audit

- Temukan root project, struktur folder, notebook, file SQL, file model, CSV, README, requirements/package files, dan konfigurasi Git.
- Identifikasi skema tabel dan kolom sebenarnya dari file SQL/notebook; tandai yang tidak bisa diverifikasi tanpa koneksi database.
- Tentukan apakah frontend/backend sudah ada sebelum membuat proyek baru.
- Jangan mengubah file selama audit.

### Tahap 2 — Fondasi backend

- Siapkan struktur FastAPI modular, konfigurasi environment, koneksi SQLAlchemy, schemas, error handling, CORS, dan health endpoint.
- Tambahkan endpoint read-only berdasarkan skema aktual.
- Pisahkan fungsi perhitungan AHP-SAW dari notebook hanya setelah logika dan skema diverifikasi. Pertahankan hasil dan rumus notebook, serta buat test unit.
- Muat model `.pkl` hanya jika file tersedia dan kompatibilitas dependency dapat dipastikan. Jangan menganggap file model otomatis tersedia hanya karena path Google Drive ada di notebook.

### Tahap 3 — Frontend

- Bangun layout dashboard responsif dan navigasi.
- Hubungkan halaman ke endpoint API; hindari hardcoded mock data untuk mode production.
- Buat visualisasi dari data API dan format nilai secara konsisten.

### Tahap 4 — Validasi

- Jalankan tes backend, build frontend, dan lint jika script tersedia.
- Verifikasi hasil ranking bahan dan prediksi tidak tercampur.
- Periksa responsive layout, loading/error/empty state, CORS, dan kebocoran secret.

### Tahap 5 — Dokumentasi deployment

- Buat README setup lokal dan deployment.
- Sertakan `.env.example` tanpa rahasia.
- Berikan langkah migrasi database manual yang aman, termasuk backup/restore. Tunggu persetujuan sebelum melakukan migrasi atau tindakan cloud.

## 15. Instruksi Awal untuk Codex

Mulai dari **Tahap 1 — Audit**. Jangan langsung menulis ulang proyek. Setelah audit, sampaikan temuan dan rencana singkat, lalu implementasikan MVP bertahap dengan perubahan kecil yang mudah diperiksa. Prioritas utama: mempertahankan database/model yang ada, menyediakan API aman, dan membuat dashboard/katalog yang benar-benar menggunakan data proyek.
