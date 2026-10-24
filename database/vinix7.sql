--
-- PostgreSQL database dump
--

\restrict vy7ucBbk6ayuiBs3bOOkVhfJKHSQHyGr73zRv8Gc12HgPMZIg0zrvy7mzZh6orw

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bahan_organik; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bahan_organik (
    bahan_id text NOT NULL,
    jenis_bahan_organik text NOT NULL,
    kategori_bahan text NOT NULL
);


--
-- Name: data_pertanian; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_pertanian (
    agri_id text NOT NULL,
    kalurahan text NOT NULL,
    padukuhan_id text NOT NULL,
    padukuhan text NOT NULL,
    komoditas text NOT NULL,
    kelompok_komoditas text NOT NULL,
    tahun integer NOT NULL,
    luas_panen_ha numeric(12,4) NOT NULL,
    luas_lahan_ha numeric(12,4) NOT NULL,
    jumlah_petani integer NOT NULL,
    jumlah_utp integer NOT NULL,
    jumlah_kelompok_tani integer NOT NULL,
    produksi numeric(18,4) NOT NULL,
    satuan_produksi_q text NOT NULL,
    CONSTRAINT data_pertanian_jumlah_kelompok_tani_check CHECK ((jumlah_kelompok_tani >= 0)),
    CONSTRAINT data_pertanian_jumlah_petani_check CHECK ((jumlah_petani >= 0)),
    CONSTRAINT data_pertanian_jumlah_utp_check CHECK ((jumlah_utp >= 0)),
    CONSTRAINT data_pertanian_luas_lahan_ha_check CHECK ((luas_lahan_ha >= (0)::numeric)),
    CONSTRAINT data_pertanian_luas_panen_ha_check CHECK ((luas_panen_ha >= (0)::numeric)),
    CONSTRAINT data_pertanian_produksi_check CHECK ((produksi >= (0)::numeric)),
    CONSTRAINT data_pertanian_tahun_check CHECK (((tahun >= 1900) AND (tahun <= 2100)))
);


--
-- Name: TABLE data_pertanian; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.data_pertanian IS 'Synthetic padukuhan-level agriculture (sheet Data_Pertanian).';


--
-- Name: data_pertanian_real; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_pertanian_real (
    agri_id text NOT NULL,
    wilayah text NOT NULL,
    komoditas text NOT NULL,
    luas_panen_ha numeric(12,4),
    luas_lahan_ha numeric(12,4),
    jumlah_utp integer,
    produksi numeric(18,4),
    satuan_produksi text NOT NULL,
    tahun_produksi integer NOT NULL,
    tahun_utp integer,
    sumber_produksi text NOT NULL,
    sumber_utp text,
    status_data text NOT NULL,
    catatan text,
    CONSTRAINT data_pertanian_real_jumlah_utp_check CHECK (((jumlah_utp IS NULL) OR (jumlah_utp >= 0))),
    CONSTRAINT data_pertanian_real_luas_lahan_ha_check CHECK (((luas_lahan_ha IS NULL) OR (luas_lahan_ha >= (0)::numeric))),
    CONSTRAINT data_pertanian_real_luas_panen_ha_check CHECK (((luas_panen_ha IS NULL) OR (luas_panen_ha >= (0)::numeric))),
    CONSTRAINT data_pertanian_real_produksi_check CHECK (((produksi IS NULL) OR (produksi >= (0)::numeric))),
    CONSTRAINT data_pertanian_real_tahun_produksi_check CHECK (((tahun_produksi >= 1900) AND (tahun_produksi <= 2100))),
    CONSTRAINT data_pertanian_real_tahun_utp_check CHECK (((tahun_utp IS NULL) OR ((tahun_utp >= 1900) AND (tahun_utp <= 2100))))
);


--
-- Name: TABLE data_pertanian_real; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.data_pertanian_real IS 'Real kecamatan-level agriculture (sheet Data Pertanian_real); not joinable to padukuhan.';


--
-- Name: kalurahan; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.kalurahan (
    kalurahan_id text NOT NULL,
    kalurahan text NOT NULL,
    luas_kalurahan_ha numeric(12,4),
    jumlah_padukuhan integer,
    jumlah_rw integer,
    jumlah_rt integer,
    batas_utara text,
    batas_selatan text,
    batas_barat text,
    batas_timur text,
    jarak_kecamatan_km numeric(8,2),
    jarak_kabupaten_km numeric(8,2),
    jarak_provinsi_km numeric(8,2),
    jarak_nasional_km numeric(8,2),
    latitude numeric(10,7),
    longitude numeric(10,7),
    CONSTRAINT kalurahan_jarak_kabupaten_km_check CHECK (((jarak_kabupaten_km IS NULL) OR (jarak_kabupaten_km >= (0)::numeric))),
    CONSTRAINT kalurahan_jarak_kecamatan_km_check CHECK (((jarak_kecamatan_km IS NULL) OR (jarak_kecamatan_km >= (0)::numeric))),
    CONSTRAINT kalurahan_jarak_nasional_km_check CHECK (((jarak_nasional_km IS NULL) OR (jarak_nasional_km >= (0)::numeric))),
    CONSTRAINT kalurahan_jarak_provinsi_km_check CHECK (((jarak_provinsi_km IS NULL) OR (jarak_provinsi_km >= (0)::numeric))),
    CONSTRAINT kalurahan_jumlah_padukuhan_check CHECK (((jumlah_padukuhan IS NULL) OR (jumlah_padukuhan >= 0))),
    CONSTRAINT kalurahan_jumlah_rt_check CHECK (((jumlah_rt IS NULL) OR (jumlah_rt >= 0))),
    CONSTRAINT kalurahan_jumlah_rw_check CHECK (((jumlah_rw IS NULL) OR (jumlah_rw >= 0))),
    CONSTRAINT kalurahan_latitude_check CHECK (((latitude IS NULL) OR ((latitude >= ('-90'::integer)::numeric) AND (latitude <= (90)::numeric)))),
    CONSTRAINT kalurahan_longitude_check CHECK (((longitude IS NULL) OR ((longitude >= ('-180'::integer)::numeric) AND (longitude <= (180)::numeric)))),
    CONSTRAINT kalurahan_luas_kalurahan_ha_check CHECK (((luas_kalurahan_ha IS NULL) OR (luas_kalurahan_ha >= (0)::numeric)))
);


--
-- Name: ketersediaan_bahan; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ketersediaan_bahan (
    ketersediaan_id text NOT NULL,
    bahan_id text NOT NULL,
    padukuhan_id text NOT NULL,
    periode date NOT NULL,
    jumlah_ketersediaan numeric(18,2) NOT NULL,
    satuan text NOT NULL,
    kontinuitas text NOT NULL,
    jarak_ke_produksi_km numeric(8,2),
    kemudahan_pengumpulan text NOT NULL,
    status_pemanfaatan text NOT NULL,
    frekuensi text NOT NULL,
    musim text NOT NULL,
    jumlah_sumber integer NOT NULL,
    status_data text NOT NULL,
    CONSTRAINT ketersediaan_bahan_jarak_ke_produksi_km_check CHECK (((jarak_ke_produksi_km IS NULL) OR (jarak_ke_produksi_km >= (0)::numeric))),
    CONSTRAINT ketersediaan_bahan_jumlah_ketersediaan_check CHECK ((jumlah_ketersediaan >= (0)::numeric)),
    CONSTRAINT ketersediaan_bahan_jumlah_sumber_check CHECK ((jumlah_sumber >= 0))
);


--
-- Name: TABLE ketersediaan_bahan; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.ketersediaan_bahan IS 'jarak_ke_produksi_km is NULL until a verified distance source exists.';


--
-- Name: padukuhan; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.padukuhan (
    padukuhan_id text NOT NULL,
    kalurahan_id text NOT NULL,
    kalurahan text NOT NULL,
    padukuhan text NOT NULL,
    jumlah_rt integer,
    jumlah_rw integer,
    latitude numeric(10,7),
    longitude numeric(10,7),
    CONSTRAINT padukuhan_jumlah_rt_check CHECK (((jumlah_rt IS NULL) OR (jumlah_rt >= 0))),
    CONSTRAINT padukuhan_jumlah_rw_check CHECK (((jumlah_rw IS NULL) OR (jumlah_rw >= 0))),
    CONSTRAINT padukuhan_latitude_check CHECK (((latitude IS NULL) OR ((latitude >= ('-90'::integer)::numeric) AND (latitude <= (90)::numeric)))),
    CONSTRAINT padukuhan_longitude_check CHECK (((longitude IS NULL) OR ((longitude >= ('-180'::integer)::numeric) AND (longitude <= (180)::numeric))))
);


--
-- Name: penjualan; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.penjualan (
    penjualan_id text NOT NULL,
    produk_id text NOT NULL,
    bulan date NOT NULL,
    produk text NOT NULL,
    jumlah_terjual numeric(18,2) NOT NULL,
    harga_satuan numeric(14,2) NOT NULL,
    total_penjualan numeric(18,2) NOT NULL,
    satuan text,
    kanal text,
    status_data text,
    CONSTRAINT penjualan_bulan_check CHECK ((EXTRACT(day FROM bulan) = (1)::numeric)),
    CONSTRAINT penjualan_check CHECK ((total_penjualan = (jumlah_terjual * harga_satuan))),
    CONSTRAINT penjualan_harga_satuan_check CHECK ((harga_satuan >= (0)::numeric)),
    CONSTRAINT penjualan_jumlah_terjual_check CHECK ((jumlah_terjual >= (0)::numeric)),
    CONSTRAINT penjualan_total_penjualan_check CHECK ((total_penjualan >= (0)::numeric))
);


--
-- Name: produk; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.produk (
    produk_id text NOT NULL,
    nama_produk text NOT NULL,
    jenis_produk text NOT NULL,
    deskripsi text,
    manfaat text,
    harga numeric(14,2),
    ukuran_kemasan text,
    produsen text,
    lokasi_produsen text,
    kontak text,
    stok_ketersediaan text,
    foto_produk text,
    CONSTRAINT produk_harga_check CHECK (((harga IS NULL) OR (harga >= (0)::numeric)))
);


--
-- Name: produk_katalog_audit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.produk_katalog_audit (
    produk_id text NOT NULL,
    nama_produk text NOT NULL,
    jenis_produk text NOT NULL,
    deskripsi text,
    manfaat text,
    harga numeric(14,2),
    ukuran_kemasan text,
    produsen text,
    lokasi_produsen text,
    kontak text,
    stok_ketersediaan text,
    foto_produk text,
    CONSTRAINT produk_katalog_audit_harga_check CHECK (((harga IS NULL) OR (harga >= (0)::numeric)))
);


--
-- Name: TABLE produk_katalog_audit; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.produk_katalog_audit IS 'Audit copy of sheet Produk_Katalog; never merged into produk.';


--
-- Name: produksi; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.produksi (
    produksi_id text NOT NULL,
    produk_id text NOT NULL,
    nama_produk text NOT NULL,
    jenis_produk text NOT NULL,
    jumlah_produksi_varian numeric(18,2) NOT NULL,
    jumlah_produksi_total numeric(18,2) NOT NULL,
    satuan text NOT NULL,
    kapasitas_produk numeric(18,2),
    bahan_baku_aktif text,
    bahan_baku text,
    jumlah_bahan_baku numeric(18,3),
    periode_produksi integer NOT NULL,
    status_data text NOT NULL,
    satuan_bahan_baku text,
    satuan_stok text,
    stok numeric(18,3),
    CONSTRAINT produksi_check CHECK ((jumlah_produksi_total >= jumlah_produksi_varian)),
    CONSTRAINT produksi_jumlah_bahan_baku_check CHECK (((jumlah_bahan_baku IS NULL) OR (jumlah_bahan_baku >= (0)::numeric))),
    CONSTRAINT produksi_jumlah_produksi_varian_check CHECK ((jumlah_produksi_varian >= (0)::numeric)),
    CONSTRAINT produksi_kapasitas_produk_check CHECK (((kapasitas_produk IS NULL) OR (kapasitas_produk >= (0)::numeric))),
    CONSTRAINT produksi_periode_produksi_check CHECK (((periode_produksi >= 1900) AND (periode_produksi <= 2100))),
    CONSTRAINT produksi_stok_check CHECK (((stok IS NULL) OR (stok >= (0)::numeric)))
);


--
-- Name: TABLE produksi; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.produksi IS 'Use jumlah_produksi_varian for aggregation. jumlah_produksi_total is a repeated group total and must not be summed.';


--
-- Name: staging_import_run; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staging_import_run (
    run_id text NOT NULL,
    started_at timestamp with time zone NOT NULL,
    finished_at timestamp with time zone,
    source_sha256 text NOT NULL,
    mode text NOT NULL,
    status text NOT NULL,
    report jsonb NOT NULL,
    CONSTRAINT staging_import_run_mode_check CHECK ((mode = ANY (ARRAY['dry-run'::text, 'apply'::text]))),
    CONSTRAINT staging_import_run_status_check CHECK ((status = ANY (ARRAY['validated'::text, 'applied'::text, 'failed'::text])))
);


--
-- Name: TABLE staging_import_run; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.staging_import_run IS 'Validation/import run log. Dry-run reports are written to reports/*.json and are not inserted here.';


--
-- Data for Name: bahan_organik; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.bahan_organik (bahan_id, jenis_bahan_organik, kategori_bahan) FROM stdin;
BAH-004	Dedak	Bahan organik pertanian
BAH-011	Kompos organik	Kompos
BAH-001	Limbah sayuran	Limbah pertanian/organik
BAH-008	Sumber karbon organik	Bahan organik
BAH-015	Jerami	Limbah pertanian
BAH-005	Limbah pertanian	Limbah pertanian
BAH-012	Humus tanah	Bahan organik tanah
BAH-002	Sisa tanaman pertanian	Limbah pertanian
BAH-009	Bahan fermentasi organik	Bahan fermentasi
BAH-016	Daun mimba	Bahan nabati
BAH-006	Bahan organik fermentasi	Bahan fermentasi
BAH-013	Bahan tanaman fermentasi	Bahan fermentasi
BAH-003	Bahan organik rumah tangga	Limbah rumah tangga
BAH-010	Kompos tanaman	Kompos
BAH-017	Bahan nabati lokal	Bahan nabati
BAH-007	Molase	Bahan fermentasi
BAH-014	Kotoran ternak	Limbah peternakan
\.


--
-- Data for Name: data_pertanian; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.data_pertanian (agri_id, kalurahan, padukuhan_id, padukuhan, komoditas, kelompok_komoditas, tahun, luas_panen_ha, luas_lahan_ha, jumlah_petani, jumlah_utp, jumlah_kelompok_tani, produksi, satuan_produksi_q) FROM stdin;
AGRI-0001	Wukirsari	PAD-046	Cangcangan	Bawang Merah	Hortikultura	2024	0.0066	0.0085	2	2	1	0.4400	kuintal
AGRI-0002	Glagaharjo	PAD-056	Besalen	Bawang Merah	Hortikultura	2024	0.0083	0.0104	2	1	1	0.6800	kuintal
AGRI-0003	Wukirsari	PAD-044	Bulaksalak	Cabai Keriting	Hortikultura	2024	3.2304	4.0321	37	30	3	270.8100	kuintal
AGRI-0004	Argomulyo	PAD-019	Jiwan	Bawang Merah	Hortikultura	2024	0.0104	0.0112	2	1	1	1.2600	kuintal
AGRI-0005	Glagaharjo	PAD-056	Besalen	Kencur	Tanaman Obat	2023	0.0859	0.0951	4	4	1	0.3485	kuintal
AGRI-0006	Glagaharjo	PAD-052	Glagah Malang	Bawang Merah	Hortikultura	2024	0.0049	0.0056	2	1	1	0.6100	kuintal
AGRI-0007	Wukirsari	PAD-045	Surodadi	Cabai Keriting	Hortikultura	2024	0.7281	0.9315	4	3	1	63.8900	kuintal
AGRI-0008	Wukirsari	PAD-043	Gondang	Kunyit	Tanaman Obat	2023	0.1384	0.1788	2	1	1	0.6753	kuintal
AGRI-0009	Argomulyo	PAD-010	Cangkringan	Kunyit	Tanaman Obat	2023	0.1320	0.1470	2	2	1	1.0075	kuintal
AGRI-0010	Glagaharjo	PAD-049	Srunen	Bawang Merah	Hortikultura	2024	0.0094	0.0105	2	1	1	0.6000	kuintal
AGRI-0011	Argomulyo	PAD-004	Kliwang	Cabai Rawit	Hortikultura	2024	1.4245	1.7938	14	9	2	106.0400	kuintal
AGRI-0012	Kepuharjo	PAD-063	Kepuh	Kencur	Tanaman Obat	2023	0.2004	0.2537	2	1	1	1.3043	kuintal
AGRI-0013	Argomulyo	PAD-018	Kauman	Kunyit	Tanaman Obat	2023	0.0898	0.1090	4	3	1	0.4221	kuintal
AGRI-0014	Wukirsari	PAD-041	Gungan	Jahe	Tanaman Obat	2023	0.1955	0.2367	5	2	1	1.4033	kuintal
AGRI-0015	Umbulharjo	PAD-065	Pelemsari	Cabai Besar/TW/Teropong	Hortikultura	2024	0.3843	0.4924	4	3	1	25.8900	kuintal
AGRI-0016	Umbulharjo	PAD-070	Plosorejo	Jahe	Tanaman Obat	2023	0.3959	0.4476	4	3	1	4.3380	kuintal
AGRI-0017	Wukirsari	PAD-033	Tanjung	Cabai Rawit	Hortikultura	2024	2.0105	2.6983	17	13	2	167.6300	kuintal
AGRI-0018	Wukirsari	PAD-027	Sintokan	Kencur	Tanaman Obat	2023	0.0585	0.0741	2	1	1	0.2598	kuintal
AGRI-0019	Argomulyo	PAD-008	Sewon	Kunyit	Tanaman Obat	2023	0.0672	0.0840	2	1	1	0.3874	kuintal
AGRI-0020	Umbulharjo	PAD-068	Gambretan	Bawang Merah	Hortikultura	2024	0.0088	0.0112	2	1	1	1.0400	kuintal
AGRI-0021	Umbulharjo	PAD-070	Plosorejo	Cabai Keriting	Hortikultura	2024	0.6937	0.8969	6	4	1	45.4300	kuintal
AGRI-0022	Glagaharjo	PAD-054	Ngancar	Bawang Merah	Hortikultura	2024	0.0087	0.0105	3	2	1	0.8400	kuintal
AGRI-0023	Glagaharjo	PAD-054	Ngancar	Kencur	Tanaman Obat	2023	0.0597	0.0721	4	3	1	0.2829	kuintal
AGRI-0024	Kepuharjo	PAD-064	Manggong	Bawang Merah	Hortikultura	2024	0.0102	0.0114	2	2	1	0.6000	kuintal
AGRI-0025	Wukirsari	PAD-035	Selorejo	Kunyit	Tanaman Obat	2023	0.1308	0.1519	2	1	1	0.8377	kuintal
AGRI-0026	Argomulyo	PAD-019	Jiwan	Cabai Rawit	Hortikultura	2024	0.8179	1.0183	10	9	1	71.4100	kuintal
AGRI-0027	Kepuharjo	PAD-064	Manggong	Kencur	Tanaman Obat	2023	0.0424	0.0559	2	1	1	0.2385	kuintal
AGRI-0028	Umbulharjo	PAD-066	Pangukrejo	Kunyit	Tanaman Obat	2023	0.2051	0.2413	3	1	1	0.6466	kuintal
AGRI-0029	Wukirsari	PAD-023	Karangpakis	Kunyit	Tanaman Obat	2023	0.2083	0.2413	2	1	1	0.9874	kuintal
AGRI-0030	Umbulharjo	PAD-071	Karanggeneng	Cabai Besar/TW/Teropong	Hortikultura	2024	0.4742	0.5489	7	3	1	40.1400	kuintal
AGRI-0031	Argomulyo	PAD-007	Kebur Kidul	Cabai Rawit	Hortikultura	2024	0.2459	0.3249	2	2	1	17.8200	kuintal
AGRI-0032	Glagaharjo	PAD-053	Jetis Sumur	Kencur	Tanaman Obat	2023	0.0345	0.0425	2	2	1	0.1818	kuintal
AGRI-0033	Argomulyo	PAD-010	Cangkringan	Jahe	Tanaman Obat	2023	0.2661	0.3483	2	1	1	2.8931	kuintal
AGRI-0034	Wukirsari	PAD-038	Salam Krajan	Jahe	Tanaman Obat	2023	0.1357	0.1708	3	3	1	1.3135	kuintal
AGRI-0035	Wukirsari	PAD-044	Bulaksalak	Kunyit	Tanaman Obat	2023	0.0621	0.0695	3	2	1	0.2545	kuintal
AGRI-0036	Kepuharjo	PAD-063	Kepuh	Cabai Rawit	Hortikultura	2024	0.3567	0.4492	3	2	1	33.7100	kuintal
AGRI-0037	Glagaharjo	PAD-055	Banjarsari	Kencur	Tanaman Obat	2023	0.0857	0.1119	2	1	1	0.4681	kuintal
AGRI-0038	Argomulyo	PAD-006	Kebur Lor	Bawang Merah	Hortikultura	2024	0.0061	0.0068	2	2	1	0.6000	kuintal
AGRI-0039	Umbulharjo	PAD-072	Plosokerep	Jahe	Tanaman Obat	2023	0.1264	0.1655	2	1	1	1.0806	kuintal
AGRI-0040	Argomulyo	PAD-012	Karanglo	Cabai Rawit	Hortikultura	2024	0.6859	0.7804	4	2	1	56.7400	kuintal
AGRI-0041	Wukirsari	PAD-038	Salam Krajan	Cabai Rawit	Hortikultura	2024	0.9144	1.1931	6	5	1	70.8900	kuintal
AGRI-0042	Argomulyo	PAD-015	Bakalan	Cabai Rawit	Hortikultura	2024	1.1914	1.4466	14	7	2	106.6000	kuintal
AGRI-0043	Argomulyo	PAD-017	Banaran	Cabai Besar/TW/Teropong	Hortikultura	2024	0.8724	0.9881	8	7	1	95.6500	kuintal
AGRI-0044	Wukirsari	PAD-038	Salam Krajan	Cabai Keriting	Hortikultura	2024	0.8831	1.0709	9	8	1	61.3100	kuintal
AGRI-0045	Wukirsari	PAD-027	Sintokan	Jahe	Tanaman Obat	2023	0.2146	0.2331	5	4	1	2.3502	kuintal
AGRI-0046	Argomulyo	PAD-003	Panggung	Kunyit	Tanaman Obat	2023	0.2235	0.2856	2	1	1	0.8705	kuintal
AGRI-0047	Wukirsari	PAD-028	Rejosari	Bawang Merah	Hortikultura	2024	0.0197	0.0247	2	1	1	0.5000	kuintal
AGRI-0048	Wukirsari	PAD-042	Ngepringan	Jahe	Tanaman Obat	2023	0.3160	0.3956	2	1	1	3.5327	kuintal
AGRI-0049	Wukirsari	PAD-029	Sempon	Cabai Keriting	Hortikultura	2024	1.8299	2.1452	21	16	2	126.5400	kuintal
AGRI-0050	Glagaharjo	PAD-049	Srunen	Jahe	Tanaman Obat	2023	0.3660	0.4587	6	4	1	5.1566	kuintal
AGRI-0051	Wukirsari	PAD-033	Tanjung	Cabai Keriting	Hortikultura	2024	1.5677	1.9875	14	12	2	110.8000	kuintal
AGRI-0052	Kepuharjo	PAD-063	Kepuh	Cabai Keriting	Hortikultura	2024	0.7343	0.8637	7	5	1	57.8700	kuintal
AGRI-0053	Umbulharjo	PAD-065	Pelemsari	Jahe	Tanaman Obat	2023	0.0901	0.1048	2	1	1	0.8836	kuintal
AGRI-0054	Argomulyo	PAD-008	Sewon	Cabai Keriting	Hortikultura	2024	1.3299	1.6700	14	12	2	113.6900	kuintal
AGRI-0055	Wukirsari	PAD-027	Sintokan	Kunyit	Tanaman Obat	2023	0.0908	0.1175	2	2	1	0.5100	kuintal
AGRI-0056	Wukirsari	PAD-039	Cakran	Cabai Keriting	Hortikultura	2024	0.3669	0.4360	6	4	1	31.5200	kuintal
AGRI-0057	Glagaharjo	PAD-048	Kalitengah Kidul	Cabai Rawit	Hortikultura	2024	0.5100	0.5724	6	5	1	37.7200	kuintal
AGRI-0058	Wukirsari	PAD-032	Sembungan	Cabai Rawit	Hortikultura	2024	0.6259	0.6883	9	8	1	47.0600	kuintal
AGRI-0059	Wukirsari	PAD-023	Karangpakis	Kencur	Tanaman Obat	2023	0.0375	0.0453	2	1	1	0.2103	kuintal
AGRI-0060	Glagaharjo	PAD-050	Singlar	Cabai Rawit	Hortikultura	2024	0.6530	0.7346	5	3	1	73.6700	kuintal
AGRI-0061	Glagaharjo	PAD-055	Banjarsari	Kunyit	Tanaman Obat	2023	0.1387	0.1765	2	1	1	0.8902	kuintal
AGRI-0062	Umbulharjo	PAD-073	Pentingsari	Bawang Merah	Hortikultura	2024	0.0043	0.0049	2	1	1	0.4300	kuintal
AGRI-0063	Kepuharjo	PAD-058	Jambu	Bawang Merah	Hortikultura	2024	0.0047	0.0056	2	1	1	0.3100	kuintal
AGRI-0064	Kepuharjo	PAD-060	Kopeng	Jahe	Tanaman Obat	2023	0.1217	0.1407	2	1	1	1.4841	kuintal
AGRI-0065	Glagaharjo	PAD-050	Singlar	Kunyit	Tanaman Obat	2023	0.1891	0.2133	2	1	1	0.9790	kuintal
AGRI-0066	Argomulyo	PAD-019	Jiwan	Jahe	Tanaman Obat	2023	0.5481	0.7096	4	3	1	4.8669	kuintal
AGRI-0067	Argomulyo	PAD-014	Suruh	Kunyit	Tanaman Obat	2023	0.0390	0.0475	3	2	1	0.1976	kuintal
AGRI-0068	Wukirsari	PAD-040	Duwet	Kunyit	Tanaman Obat	2023	0.0208	0.0248	2	1	1	0.1132	kuintal
AGRI-0069	Kepuharjo	PAD-060	Kopeng	Kunyit	Tanaman Obat	2023	0.1045	0.1238	2	1	1	0.4061	kuintal
AGRI-0070	Umbulharjo	PAD-072	Plosokerep	Cabai Rawit	Hortikultura	2024	0.7858	0.9567	7	4	1	90.3500	kuintal
AGRI-0071	Argomulyo	PAD-018	Kauman	Kencur	Tanaman Obat	2023	0.0595	0.0723	2	2	1	0.2393	kuintal
AGRI-0072	Kepuharjo	PAD-062	Pagerjurang	Cabai Rawit	Hortikultura	2024	0.2155	0.2527	2	1	1	15.8600	kuintal
AGRI-0073	Wukirsari	PAD-026	Sruni	Cabai Rawit	Hortikultura	2024	0.9179	1.1284	9	7	1	75.5600	kuintal
AGRI-0074	Wukirsari	PAD-027	Sintokan	Cabai Rawit	Hortikultura	2024	0.3588	0.4498	2	2	1	33.3800	kuintal
AGRI-0075	Wukirsari	PAD-037	Kregan	Cabai Rawit	Hortikultura	2024	1.2578	1.6554	16	10	1	100.3700	kuintal
AGRI-0076	Argomulyo	PAD-018	Kauman	Jahe	Tanaman Obat	2023	0.5291	0.7103	6	3	1	5.0846	kuintal
AGRI-0077	Argomulyo	PAD-021	Gayam	Cabai Keriting	Hortikultura	2024	0.6825	0.7974	8	5	1	47.6500	kuintal
AGRI-0078	Umbulharjo	PAD-070	Plosorejo	Cabai Rawit	Hortikultura	2024	0.4036	0.5191	6	3	1	34.1900	kuintal
AGRI-0079	Wukirsari	PAD-026	Sruni	Jahe	Tanaman Obat	2023	0.2695	0.3191	2	1	1	2.4869	kuintal
AGRI-0080	Wukirsari	PAD-032	Sembungan	Bawang Merah	Hortikultura	2024	0.0069	0.0080	2	1	1	0.4200	kuintal
AGRI-0081	Wukirsari	PAD-042	Ngepringan	Bawang Merah	Hortikultura	2024	0.0051	0.0066	2	1	1	0.2700	kuintal
AGRI-0082	Argomulyo	PAD-021	Gayam	Jahe	Tanaman Obat	2023	0.2357	0.2748	4	2	1	1.8122	kuintal
AGRI-0083	Umbulharjo	PAD-067	Gondang	Jahe	Tanaman Obat	2023	0.0776	0.0839	2	1	1	0.9345	kuintal
AGRI-0084	Wukirsari	PAD-046	Cangcangan	Cabai Keriting	Hortikultura	2024	0.6077	0.7144	4	2	1	73.1700	kuintal
AGRI-0085	Umbulharjo	PAD-073	Pentingsari	Jahe	Tanaman Obat	2023	0.1154	0.1313	3	2	1	1.3939	kuintal
AGRI-0086	Wukirsari	PAD-027	Sintokan	Bawang Merah	Hortikultura	2024	0.0069	0.0090	2	2	1	0.5600	kuintal
AGRI-0087	Argomulyo	PAD-017	Banaran	Jahe	Tanaman Obat	2023	0.1553	0.1698	4	3	1	1.6806	kuintal
AGRI-0088	Umbulharjo	PAD-068	Gambretan	Kencur	Tanaman Obat	2023	0.0845	0.0930	2	1	1	0.4457	kuintal
AGRI-0089	Argomulyo	PAD-005	Teplok	Cabai Keriting	Hortikultura	2024	0.6111	0.7292	6	4	1	48.3300	kuintal
AGRI-0090	Umbulharjo	PAD-067	Gondang	Cabai Keriting	Hortikultura	2024	3.2862	3.8318	31	21	3	370.0300	kuintal
AGRI-0091	Glagaharjo	PAD-056	Besalen	Cabai Besar/TW/Teropong	Hortikultura	2024	0.3936	0.4384	8	5	1	27.9200	kuintal
AGRI-0092	Wukirsari	PAD-039	Cakran	Bawang Merah	Hortikultura	2024	0.0146	0.0190	2	1	1	1.2200	kuintal
AGRI-0093	Argomulyo	PAD-005	Teplok	Cabai Besar/TW/Teropong	Hortikultura	2024	0.4181	0.4748	5	3	1	41.4200	kuintal
AGRI-0094	Wukirsari	PAD-028	Rejosari	Jahe	Tanaman Obat	2023	0.0493	0.0582	2	2	1	0.5547	kuintal
AGRI-0095	Umbulharjo	PAD-073	Pentingsari	Cabai Keriting	Hortikultura	2024	0.4640	0.6028	3	2	1	41.7500	kuintal
AGRI-0096	Glagaharjo	PAD-055	Banjarsari	Cabai Keriting	Hortikultura	2024	0.8851	0.9618	6	5	1	88.9300	kuintal
AGRI-0097	Wukirsari	PAD-024	Glagahwero	Cabai Besar/TW/Teropong	Hortikultura	2024	0.8212	0.9657	9	6	1	44.0500	kuintal
AGRI-0098	Kepuharjo	PAD-057	Kaliadem	Kunyit	Tanaman Obat	2023	0.1375	0.1845	2	2	1	0.8047	kuintal
AGRI-0099	Umbulharjo	PAD-072	Plosokerep	Kencur	Tanaman Obat	2023	0.0578	0.0636	3	2	1	0.1706	kuintal
AGRI-0100	Glagaharjo	PAD-049	Srunen	Cabai Rawit	Hortikultura	2024	0.1574	0.1820	4	3	1	9.2900	kuintal
AGRI-0101	Wukirsari	PAD-031	Kiyaran	Jahe	Tanaman Obat	2023	0.2259	0.2677	2	1	1	2.8569	kuintal
AGRI-0102	Wukirsari	PAD-025	Pusmalang	Cabai Rawit	Hortikultura	2024	1.0556	1.2872	8	6	1	109.3400	kuintal
AGRI-0103	Argomulyo	PAD-008	Sewon	Cabai Besar/TW/Teropong	Hortikultura	2024	0.6655	0.8965	3	2	1	66.8300	kuintal
AGRI-0104	Argomulyo	PAD-020	Dliring	Cabai Rawit	Hortikultura	2024	0.5741	0.6348	7	4	1	78.1200	kuintal
AGRI-0105	Argomulyo	PAD-002	Kuwang	Kunyit	Tanaman Obat	2023	0.3248	0.3856	3	2	1	1.5025	kuintal
AGRI-0106	Argomulyo	PAD-002	Kuwang	Bawang Merah	Hortikultura	2024	0.0106	0.0121	2	2	1	0.8000	kuintal
AGRI-0107	Wukirsari	PAD-040	Duwet	Jahe	Tanaman Obat	2023	0.1461	0.1659	2	1	1	1.6112	kuintal
AGRI-0108	Kepuharjo	PAD-062	Pagerjurang	Jahe	Tanaman Obat	2023	0.3506	0.4531	2	1	1	3.9749	kuintal
AGRI-0109	Wukirsari	PAD-025	Pusmalang	Cabai Besar/TW/Teropong	Hortikultura	2024	0.8601	0.9420	6	5	1	51.6600	kuintal
AGRI-0110	Wukirsari	PAD-037	Kregan	Cabai Keriting	Hortikultura	2024	1.2930	1.7030	14	7	2	161.9800	kuintal
AGRI-0111	Argomulyo	PAD-005	Teplok	Jahe	Tanaman Obat	2023	0.0828	0.1043	2	1	1	0.9636	kuintal
AGRI-0112	Wukirsari	PAD-029	Sempon	Cabai Besar/TW/Teropong	Hortikultura	2024	0.1463	0.1682	2	1	1	12.5100	kuintal
AGRI-0113	Wukirsari	PAD-044	Bulaksalak	Cabai Besar/TW/Teropong	Hortikultura	2024	1.0100	1.1117	9	7	1	105.1600	kuintal
AGRI-0114	Umbulharjo	PAD-066	Pangukrejo	Cabai Rawit	Hortikultura	2024	1.6601	1.9602	13	8	2	158.3500	kuintal
AGRI-0115	Argomulyo	PAD-015	Bakalan	Kencur	Tanaman Obat	2023	0.0407	0.0448	2	1	1	0.2027	kuintal
AGRI-0116	Argomulyo	PAD-011	Jaranan	Cabai Besar/TW/Teropong	Hortikultura	2024	0.6988	0.8194	4	3	1	40.7400	kuintal
AGRI-0117	Argomulyo	PAD-006	Kebur Lor	Cabai Besar/TW/Teropong	Hortikultura	2024	0.3986	0.4724	6	4	1	23.1200	kuintal
AGRI-0118	Umbulharjo	PAD-072	Plosokerep	Cabai Besar/TW/Teropong	Hortikultura	2024	0.2364	0.2969	2	1	1	14.6400	kuintal
AGRI-0119	Wukirsari	PAD-032	Sembungan	Kencur	Tanaman Obat	2023	0.1116	0.1430	6	5	1	0.4782	kuintal
AGRI-0120	Argomulyo	PAD-016	Gadingan	Cabai Keriting	Hortikultura	2024	0.5688	0.6328	6	4	1	43.0000	kuintal
AGRI-0121	Argomulyo	PAD-009	Brongkol	Cabai Besar/TW/Teropong	Hortikultura	2024	0.2651	0.3462	4	3	1	22.1900	kuintal
AGRI-0122	Argomulyo	PAD-017	Banaran	Bawang Merah	Hortikultura	2024	0.0087	0.0097	2	1	1	0.6500	kuintal
AGRI-0123	Argomulyo	PAD-003	Panggung	Jahe	Tanaman Obat	2023	0.1395	0.1565	3	1	1	1.4351	kuintal
AGRI-0124	Glagaharjo	PAD-048	Kalitengah Kidul	Cabai Keriting	Hortikultura	2024	0.3423	0.4320	6	5	1	23.4700	kuintal
AGRI-0125	Kepuharjo	PAD-064	Manggong	Cabai Besar/TW/Teropong	Hortikultura	2024	0.3491	0.4114	2	1	1	31.0100	kuintal
AGRI-0126	Kepuharjo	PAD-057	Kaliadem	Cabai Keriting	Hortikultura	2024	0.6454	0.7635	7	5	1	56.4400	kuintal
AGRI-0127	Wukirsari	PAD-044	Bulaksalak	Jahe	Tanaman Obat	2023	0.1556	0.1819	2	1	1	1.6718	kuintal
AGRI-0128	Wukirsari	PAD-043	Gondang	Jahe	Tanaman Obat	2023	0.2055	0.2451	2	1	1	1.5351	kuintal
AGRI-0129	Argomulyo	PAD-011	Jaranan	Cabai Rawit	Hortikultura	2024	0.5551	0.6081	5	3	1	52.1900	kuintal
AGRI-0130	Glagaharjo	PAD-047	Kalitengah Lor	Cabai Keriting	Hortikultura	2024	0.6208	0.7772	6	5	1	58.5900	kuintal
AGRI-0131	Kepuharjo	PAD-057	Kaliadem	Cabai Rawit	Hortikultura	2024	0.4519	0.4946	3	2	1	26.7200	kuintal
AGRI-0132	Wukirsari	PAD-045	Surodadi	Bawang Merah	Hortikultura	2024	0.0125	0.0153	2	1	1	1.1000	kuintal
AGRI-0133	Umbulharjo	PAD-065	Pelemsari	Kunyit	Tanaman Obat	2023	0.2252	0.2962	2	1	1	1.1198	kuintal
AGRI-0134	Argomulyo	PAD-006	Kebur Lor	Kencur	Tanaman Obat	2023	0.1253	0.1369	2	1	1	0.7769	kuintal
AGRI-0135	Wukirsari	PAD-025	Pusmalang	Kencur	Tanaman Obat	2023	0.0731	0.0981	4	3	1	0.2939	kuintal
AGRI-0136	Kepuharjo	PAD-058	Jambu	Kencur	Tanaman Obat	2023	0.1056	0.1279	3	1	1	0.5922	kuintal
AGRI-0137	Wukirsari	PAD-041	Gungan	Cabai Besar/TW/Teropong	Hortikultura	2024	0.3104	0.4172	2	1	1	23.5400	kuintal
AGRI-0138	Umbulharjo	PAD-071	Karanggeneng	Cabai Keriting	Hortikultura	2024	1.3473	1.5519	11	9	1	108.8700	kuintal
AGRI-0139	Umbulharjo	PAD-070	Plosorejo	Cabai Besar/TW/Teropong	Hortikultura	2024	0.3219	0.4197	5	4	1	39.5200	kuintal
AGRI-0140	Argomulyo	PAD-020	Dliring	Cabai Keriting	Hortikultura	2024	0.3809	0.4501	9	5	1	33.4700	kuintal
AGRI-0141	Argomulyo	PAD-007	Kebur Kidul	Jahe	Tanaman Obat	2023	0.1174	0.1409	2	2	1	1.7376	kuintal
AGRI-0142	Wukirsari	PAD-042	Ngepringan	Cabai Besar/TW/Teropong	Hortikultura	2024	0.6656	0.7325	6	4	1	53.6100	kuintal
AGRI-0143	Wukirsari	PAD-030	Ngemplak	Cabai Keriting	Hortikultura	2024	0.9237	1.0681	8	5	1	66.9500	kuintal
AGRI-0144	Glagaharjo	PAD-054	Ngancar	Kunyit	Tanaman Obat	2023	0.1786	0.2343	2	1	1	1.1372	kuintal
AGRI-0145	Wukirsari	PAD-034	Bedoyo	Bawang Merah	Hortikultura	2024	0.0054	0.0059	2	1	1	0.4400	kuintal
AGRI-0146	Wukirsari	PAD-030	Ngemplak	Cabai Rawit	Hortikultura	2024	0.3872	0.4187	4	2	1	22.8400	kuintal
AGRI-0147	Umbulharjo	PAD-065	Pelemsari	Cabai Rawit	Hortikultura	2024	0.3031	0.3767	3	2	1	28.8100	kuintal
AGRI-0148	Kepuharjo	PAD-060	Kopeng	Bawang Merah	Hortikultura	2024	0.0178	0.0215	2	1	1	1.3600	kuintal
AGRI-0149	Wukirsari	PAD-045	Surodadi	Cabai Rawit	Hortikultura	2024	2.6037	3.1431	28	17	2	239.3700	kuintal
AGRI-0150	Argomulyo	PAD-016	Gadingan	Jahe	Tanaman Obat	2023	0.2745	0.3150	2	1	1	2.4814	kuintal
AGRI-0151	Wukirsari	PAD-032	Sembungan	Kunyit	Tanaman Obat	2023	0.1685	0.2164	2	1	1	1.1756	kuintal
AGRI-0152	Argomulyo	PAD-009	Brongkol	Kencur	Tanaman Obat	2023	0.0278	0.0310	2	1	1	0.2363	kuintal
AGRI-0153	Glagaharjo	PAD-052	Glagah Malang	Cabai Keriting	Hortikultura	2024	0.5562	0.7370	5	3	1	59.2700	kuintal
AGRI-0154	Argomulyo	PAD-010	Cangkringan	Cabai Besar/TW/Teropong	Hortikultura	2024	1.1549	1.2515	12	7	1	65.3600	kuintal
AGRI-0155	Umbulharjo	PAD-065	Pelemsari	Kencur	Tanaman Obat	2023	0.0680	0.0902	2	1	1	0.4469	kuintal
AGRI-0156	Argomulyo	PAD-015	Bakalan	Kunyit	Tanaman Obat	2023	0.0578	0.0753	2	1	1	0.3287	kuintal
AGRI-0157	Glagaharjo	PAD-052	Glagah Malang	Jahe	Tanaman Obat	2023	0.0624	0.0784	5	3	1	0.8432	kuintal
AGRI-0158	Kepuharjo	PAD-059	Petung	Kencur	Tanaman Obat	2023	0.0562	0.0727	3	1	1	0.2616	kuintal
AGRI-0159	Glagaharjo	PAD-048	Kalitengah Kidul	Cabai Besar/TW/Teropong	Hortikultura	2024	0.2308	0.2709	3	2	1	13.7100	kuintal
AGRI-0160	Argomulyo	PAD-002	Kuwang	Cabai Rawit	Hortikultura	2024	0.2657	0.3547	3	1	1	20.0400	kuintal
AGRI-0161	Argomulyo	PAD-001	Randusari	Bawang Merah	Hortikultura	2024	0.0141	0.0166	2	1	1	1.3000	kuintal
AGRI-0162	Wukirsari	PAD-023	Karangpakis	Jahe	Tanaman Obat	2023	0.1059	0.1182	2	1	1	1.0891	kuintal
AGRI-0163	Glagaharjo	PAD-056	Besalen	Cabai Rawit	Hortikultura	2024	0.9589	1.0402	7	6	1	95.0800	kuintal
AGRI-0164	Umbulharjo	PAD-070	Plosorejo	Kunyit	Tanaman Obat	2023	0.0273	0.0348	2	2	1	0.2171	kuintal
AGRI-0165	Argomulyo	PAD-001	Randusari	Cabai Besar/TW/Teropong	Hortikultura	2024	0.5203	0.5952	2	1	1	45.3100	kuintal
AGRI-0166	Kepuharjo	PAD-063	Kepuh	Bawang Merah	Hortikultura	2024	0.0020	0.0026	3	2	1	0.1700	kuintal
AGRI-0167	Kepuharjo	PAD-064	Manggong	Kunyit	Tanaman Obat	2023	0.0536	0.0672	2	1	1	0.2663	kuintal
AGRI-0168	Argomulyo	PAD-004	Kliwang	Cabai Besar/TW/Teropong	Hortikultura	2024	1.0802	1.1787	10	7	1	75.3400	kuintal
AGRI-0169	Wukirsari	PAD-045	Surodadi	Kunyit	Tanaman Obat	2023	0.0542	0.0713	3	2	1	0.3518	kuintal
AGRI-0170	Wukirsari	PAD-038	Salam Krajan	Kencur	Tanaman Obat	2023	0.0229	0.0261	2	1	1	0.1305	kuintal
AGRI-0171	Wukirsari	PAD-036	Plupuh	Cabai Besar/TW/Teropong	Hortikultura	2024	0.4697	0.5949	4	3	1	25.6000	kuintal
AGRI-0172	Wukirsari	PAD-046	Cangcangan	Cabai Besar/TW/Teropong	Hortikultura	2024	0.8555	0.9745	9	6	1	42.0300	kuintal
AGRI-0173	Argomulyo	PAD-011	Jaranan	Bawang Merah	Hortikultura	2024	0.0163	0.0213	2	1	1	1.1500	kuintal
AGRI-0174	Glagaharjo	PAD-055	Banjarsari	Bawang Merah	Hortikultura	2024	0.0039	0.0045	3	3	1	0.3200	kuintal
AGRI-0175	Wukirsari	PAD-037	Kregan	Cabai Besar/TW/Teropong	Hortikultura	2024	0.4002	0.5266	6	3	1	28.8400	kuintal
AGRI-0176	Glagaharjo	PAD-048	Kalitengah Kidul	Bawang Merah	Hortikultura	2024	0.0062	0.0076	2	1	1	0.3600	kuintal
AGRI-0177	Wukirsari	PAD-029	Sempon	Bawang Merah	Hortikultura	2024	0.0144	0.0179	2	2	1	1.2100	kuintal
AGRI-0178	Wukirsari	PAD-024	Glagahwero	Bawang Merah	Hortikultura	2024	0.0041	0.0055	2	1	1	0.3800	kuintal
AGRI-0179	Argomulyo	PAD-012	Karanglo	Kunyit	Tanaman Obat	2023	0.0740	0.0982	2	1	1	0.3893	kuintal
AGRI-0180	Glagaharjo	PAD-050	Singlar	Kencur	Tanaman Obat	2023	0.0914	0.1012	2	2	1	0.4896	kuintal
AGRI-0181	Wukirsari	PAD-023	Karangpakis	Cabai Rawit	Hortikultura	2024	2.7718	3.6025	27	22	3	287.5200	kuintal
AGRI-0182	Argomulyo	PAD-009	Brongkol	Jahe	Tanaman Obat	2023	0.1007	0.1189	2	1	1	0.7760	kuintal
AGRI-0183	Wukirsari	PAD-032	Sembungan	Cabai Besar/TW/Teropong	Hortikultura	2024	0.6080	0.7045	8	5	1	66.7300	kuintal
AGRI-0184	Wukirsari	PAD-026	Sruni	Bawang Merah	Hortikultura	2024	0.0059	0.0065	3	1	1	0.4800	kuintal
AGRI-0185	Wukirsari	PAD-035	Selorejo	Cabai Keriting	Hortikultura	2024	0.4583	0.5734	6	5	1	35.3500	kuintal
AGRI-0186	Kepuharjo	PAD-064	Manggong	Jahe	Tanaman Obat	2023	0.2645	0.3522	3	2	1	3.0904	kuintal
AGRI-0187	Umbulharjo	PAD-068	Gambretan	Kunyit	Tanaman Obat	2023	0.1410	0.1762	2	1	1	0.5127	kuintal
AGRI-0188	Wukirsari	PAD-036	Plupuh	Cabai Keriting	Hortikultura	2024	0.4920	0.5382	3	2	1	37.5900	kuintal
AGRI-0189	Umbulharjo	PAD-073	Pentingsari	Cabai Besar/TW/Teropong	Hortikultura	2024	0.6537	0.7071	9	6	1	55.0200	kuintal
AGRI-0190	Wukirsari	PAD-042	Ngepringan	Cabai Rawit	Hortikultura	2024	0.4301	0.5404	2	1	1	37.5200	kuintal
AGRI-0191	Wukirsari	PAD-037	Kregan	Bawang Merah	Hortikultura	2024	0.0108	0.0129	2	1	1	0.9200	kuintal
AGRI-0192	Umbulharjo	PAD-067	Gondang	Kencur	Tanaman Obat	2023	0.0936	0.1145	2	2	1	0.5124	kuintal
AGRI-0193	Umbulharjo	PAD-069	Balong	Cabai Rawit	Hortikultura	2024	0.0865	0.1139	2	2	1	11.2000	kuintal
AGRI-0194	Umbulharjo	PAD-066	Pangukrejo	Jahe	Tanaman Obat	2023	0.2705	0.3270	2	1	1	2.8170	kuintal
AGRI-0195	Wukirsari	PAD-023	Karangpakis	Cabai Besar/TW/Teropong	Hortikultura	2024	1.6842	2.2274	19	15	2	112.4400	kuintal
AGRI-0196	Wukirsari	PAD-034	Bedoyo	Cabai Keriting	Hortikultura	2024	0.5974	0.7045	6	4	1	50.3000	kuintal
AGRI-0197	Kepuharjo	PAD-064	Manggong	Cabai Keriting	Hortikultura	2024	0.8939	1.1041	10	7	1	76.0300	kuintal
AGRI-0198	Wukirsari	PAD-036	Plupuh	Kencur	Tanaman Obat	2023	0.0457	0.0507	2	1	1	0.2796	kuintal
AGRI-0199	Argomulyo	PAD-017	Banaran	Cabai Rawit	Hortikultura	2024	0.7346	0.9126	7	4	1	71.5500	kuintal
AGRI-0200	Umbulharjo	PAD-073	Pentingsari	Cabai Rawit	Hortikultura	2024	0.5608	0.6163	8	5	1	40.3200	kuintal
AGRI-0201	Glagaharjo	PAD-055	Banjarsari	Jahe	Tanaman Obat	2023	0.1772	0.2123	2	2	1	1.6080	kuintal
AGRI-0202	Argomulyo	PAD-016	Gadingan	Bawang Merah	Hortikultura	2024	0.0051	0.0068	2	2	1	0.4500	kuintal
AGRI-0203	Umbulharjo	PAD-070	Plosorejo	Bawang Merah	Hortikultura	2024	0.0157	0.0176	2	1	1	1.3000	kuintal
AGRI-0204	Glagaharjo	PAD-050	Singlar	Jahe	Tanaman Obat	2023	0.2409	0.2876	2	1	1	2.2955	kuintal
AGRI-0205	Wukirsari	PAD-037	Kregan	Kencur	Tanaman Obat	2023	0.0326	0.0376	2	2	1	0.2052	kuintal
AGRI-0206	Glagaharjo	PAD-049	Srunen	Kencur	Tanaman Obat	2023	0.0680	0.0804	2	2	1	0.4835	kuintal
AGRI-0207	Umbulharjo	PAD-068	Gambretan	Jahe	Tanaman Obat	2023	0.5752	0.7738	6	4	1	8.4086	kuintal
AGRI-0208	Wukirsari	PAD-023	Karangpakis	Cabai Keriting	Hortikultura	2024	0.3398	0.3979	6	4	1	29.2700	kuintal
AGRI-0209	Argomulyo	PAD-015	Bakalan	Jahe	Tanaman Obat	2023	0.1816	0.2083	2	1	1	2.8648	kuintal
AGRI-0210	Wukirsari	PAD-046	Cangcangan	Kencur	Tanaman Obat	2023	0.0328	0.0361	4	3	1	0.2090	kuintal
AGRI-0211	Wukirsari	PAD-040	Duwet	Bawang Merah	Hortikultura	2024	0.0045	0.0051	2	2	1	0.3100	kuintal
AGRI-0212	Kepuharjo	PAD-062	Pagerjurang	Cabai Besar/TW/Teropong	Hortikultura	2024	0.2281	0.2726	2	2	1	16.1100	kuintal
AGRI-0213	Argomulyo	PAD-018	Kauman	Cabai Rawit	Hortikultura	2024	0.3293	0.3854	2	2	1	29.5600	kuintal
AGRI-0214	Wukirsari	PAD-035	Selorejo	Jahe	Tanaman Obat	2023	0.1828	0.2066	8	4	1	3.1522	kuintal
AGRI-0215	Wukirsari	PAD-024	Glagahwero	Jahe	Tanaman Obat	2023	0.0992	0.1192	2	1	1	1.2345	kuintal
AGRI-0216	Argomulyo	PAD-022	Mudal	Kunyit	Tanaman Obat	2023	0.1113	0.1323	2	1	1	0.4962	kuintal
AGRI-0217	Wukirsari	PAD-046	Cangcangan	Cabai Rawit	Hortikultura	2024	0.5671	0.6631	7	3	1	49.2000	kuintal
AGRI-0218	Wukirsari	PAD-033	Tanjung	Kencur	Tanaman Obat	2023	0.0845	0.1136	2	1	1	0.4552	kuintal
AGRI-0219	Argomulyo	PAD-006	Kebur Lor	Jahe	Tanaman Obat	2023	0.5040	0.5505	7	3	1	5.1562	kuintal
AGRI-0220	Wukirsari	PAD-033	Tanjung	Bawang Merah	Hortikultura	2024	0.0061	0.0072	2	1	1	0.4200	kuintal
AGRI-0221	Glagaharjo	PAD-052	Glagah Malang	Kunyit	Tanaman Obat	2023	0.0873	0.0961	2	1	1	0.4654	kuintal
AGRI-0222	Kepuharjo	PAD-062	Pagerjurang	Kencur	Tanaman Obat	2023	0.0881	0.1020	2	1	1	0.4557	kuintal
AGRI-0223	Wukirsari	PAD-045	Surodadi	Jahe	Tanaman Obat	2023	0.0982	0.1122	2	1	1	0.9087	kuintal
AGRI-0224	Glagaharjo	PAD-047	Kalitengah Lor	Kunyit	Tanaman Obat	2023	0.1115	0.1479	4	3	1	0.6381	kuintal
AGRI-0225	Wukirsari	PAD-042	Ngepringan	Kencur	Tanaman Obat	2023	0.0659	0.0755	2	1	1	0.2818	kuintal
AGRI-0226	Wukirsari	PAD-046	Cangcangan	Kunyit	Tanaman Obat	2023	0.0373	0.0459	2	1	1	0.2629	kuintal
AGRI-0227	Argomulyo	PAD-012	Karanglo	Kencur	Tanaman Obat	2023	0.0457	0.0602	2	1	1	0.2408	kuintal
AGRI-0228	Argomulyo	PAD-016	Gadingan	Cabai Rawit	Hortikultura	2024	0.8393	0.9081	9	4	1	63.8300	kuintal
AGRI-0229	Wukirsari	PAD-030	Ngemplak	Jahe	Tanaman Obat	2023	0.5921	0.7408	5	2	1	7.2218	kuintal
AGRI-0230	Wukirsari	PAD-028	Rejosari	Kunyit	Tanaman Obat	2023	0.1725	0.2243	5	4	1	0.9603	kuintal
AGRI-0231	Argomulyo	PAD-005	Teplok	Bawang Merah	Hortikultura	2024	0.0080	0.0087	3	2	1	0.7600	kuintal
AGRI-0232	Argomulyo	PAD-013	Jetis	Jahe	Tanaman Obat	2023	0.0601	0.0654	2	1	1	0.7017	kuintal
AGRI-0233	Argomulyo	PAD-008	Sewon	Jahe	Tanaman Obat	2023	0.1570	0.1979	3	2	1	1.5288	kuintal
AGRI-0234	Kepuharjo	PAD-061	Batur	Jahe	Tanaman Obat	2023	0.4414	0.5042	3	2	1	7.5552	kuintal
AGRI-0235	Wukirsari	PAD-043	Gondang	Cabai Besar/TW/Teropong	Hortikultura	2024	1.1287	1.3842	13	7	1	107.3900	kuintal
AGRI-0236	Wukirsari	PAD-035	Selorejo	Cabai Rawit	Hortikultura	2024	0.5347	0.6700	10	9	1	52.2700	kuintal
AGRI-0237	Kepuharjo	PAD-059	Petung	Cabai Keriting	Hortikultura	2024	0.3511	0.4209	3	3	1	28.6800	kuintal
AGRI-0238	Glagaharjo	PAD-053	Jetis Sumur	Cabai Rawit	Hortikultura	2024	0.1080	0.1209	2	1	1	8.2900	kuintal
AGRI-0239	Wukirsari	PAD-043	Gondang	Kencur	Tanaman Obat	2023	0.0235	0.0312	2	1	1	0.0936	kuintal
AGRI-0240	Glagaharjo	PAD-052	Glagah Malang	Cabai Besar/TW/Teropong	Hortikultura	2024	2.0648	2.5755	22	18	2	175.2900	kuintal
AGRI-0241	Wukirsari	PAD-028	Rejosari	Cabai Rawit	Hortikultura	2024	0.5181	0.6128	2	1	1	44.5700	kuintal
AGRI-0242	Argomulyo	PAD-005	Teplok	Cabai Rawit	Hortikultura	2024	1.2390	1.4084	12	6	2	126.7800	kuintal
AGRI-0243	Argomulyo	PAD-020	Dliring	Jahe	Tanaman Obat	2023	0.1405	0.1883	2	2	1	1.8961	kuintal
AGRI-0244	Umbulharjo	PAD-068	Gambretan	Cabai Keriting	Hortikultura	2024	0.7195	0.9178	9	8	1	84.0800	kuintal
AGRI-0245	Kepuharjo	PAD-059	Petung	Bawang Merah	Hortikultura	2024	0.0175	0.0190	2	1	1	1.1100	kuintal
AGRI-0246	Umbulharjo	PAD-072	Plosokerep	Bawang Merah	Hortikultura	2024	0.0224	0.0276	2	2	1	1.8900	kuintal
AGRI-0247	Wukirsari	PAD-036	Plupuh	Bawang Merah	Hortikultura	2024	0.0097	0.0130	2	2	1	0.8500	kuintal
AGRI-0248	Argomulyo	PAD-008	Sewon	Cabai Rawit	Hortikultura	2024	1.4992	1.9071	15	11	2	180.0200	kuintal
AGRI-0249	Argomulyo	PAD-014	Suruh	Kencur	Tanaman Obat	2023	0.0516	0.0589	2	1	1	0.2020	kuintal
AGRI-0250	Wukirsari	PAD-039	Cakran	Kunyit	Tanaman Obat	2023	0.0749	0.0951	2	2	1	0.4179	kuintal
AGRI-0251	Argomulyo	PAD-019	Jiwan	Cabai Keriting	Hortikultura	2024	1.5424	2.0733	14	7	2	114.1300	kuintal
AGRI-0252	Wukirsari	PAD-043	Gondang	Bawang Merah	Hortikultura	2024	0.0099	0.0132	2	1	1	1.1300	kuintal
AGRI-0253	Wukirsari	PAD-036	Plupuh	Kunyit	Tanaman Obat	2023	0.0571	0.0674	3	2	1	0.3315	kuintal
AGRI-0254	Argomulyo	PAD-004	Kliwang	Cabai Keriting	Hortikultura	2024	1.6957	2.0661	13	8	1	189.7400	kuintal
AGRI-0255	Argomulyo	PAD-007	Kebur Kidul	Kencur	Tanaman Obat	2023	0.0264	0.0289	2	1	1	0.1275	kuintal
AGRI-0256	Glagaharjo	PAD-050	Singlar	Cabai Besar/TW/Teropong	Hortikultura	2024	0.4130	0.4667	6	3	1	48.5000	kuintal
AGRI-0257	Wukirsari	PAD-039	Cakran	Cabai Rawit	Hortikultura	2024	0.7918	0.9059	9	6	1	53.8100	kuintal
AGRI-0258	Glagaharjo	PAD-051	Gading	Cabai Rawit	Hortikultura	2024	0.6478	0.7538	8	4	1	45.0100	kuintal
AGRI-0259	Glagaharjo	PAD-053	Jetis Sumur	Cabai Keriting	Hortikultura	2024	0.7211	0.8076	9	7	1	87.5900	kuintal
AGRI-0260	Umbulharjo	PAD-068	Gambretan	Cabai Rawit	Hortikultura	2024	0.3941	0.4554	5	3	1	33.2000	kuintal
AGRI-0261	Argomulyo	PAD-003	Panggung	Cabai Keriting	Hortikultura	2024	0.4587	0.5320	6	5	1	37.1700	kuintal
AGRI-0262	Kepuharjo	PAD-058	Jambu	Cabai Besar/TW/Teropong	Hortikultura	2024	0.7111	0.8538	7	5	1	65.3500	kuintal
AGRI-0263	Glagaharjo	PAD-054	Ngancar	Cabai Besar/TW/Teropong	Hortikultura	2024	0.8741	1.1310	11	7	1	74.1600	kuintal
AGRI-0264	Argomulyo	PAD-001	Randusari	Kunyit	Tanaman Obat	2023	0.1697	0.2090	2	1	1	1.1603	kuintal
AGRI-0265	Umbulharjo	PAD-071	Karanggeneng	Kunyit	Tanaman Obat	2023	0.0968	0.1218	2	1	1	0.4210	kuintal
AGRI-0266	Argomulyo	PAD-008	Sewon	Kencur	Tanaman Obat	2023	0.0703	0.0814	2	2	1	0.4084	kuintal
AGRI-0267	Umbulharjo	PAD-067	Gondang	Cabai Rawit	Hortikultura	2024	0.4849	0.6073	5	4	1	34.9000	kuintal
AGRI-0268	Glagaharjo	PAD-048	Kalitengah Kidul	Kencur	Tanaman Obat	2023	0.0942	0.1127	2	1	1	0.4942	kuintal
AGRI-0269	Kepuharjo	PAD-061	Batur	Cabai Keriting	Hortikultura	2024	1.1164	1.2950	14	12	2	99.4500	kuintal
AGRI-0270	Argomulyo	PAD-017	Banaran	Kencur	Tanaman Obat	2023	0.0236	0.0304	2	1	1	0.1020	kuintal
AGRI-0271	Argomulyo	PAD-014	Suruh	Cabai Keriting	Hortikultura	2024	0.6401	0.7439	7	5	1	60.3600	kuintal
AGRI-0272	Umbulharjo	PAD-068	Gambretan	Cabai Besar/TW/Teropong	Hortikultura	2024	0.7886	0.9441	8	6	1	56.1800	kuintal
AGRI-0273	Kepuharjo	PAD-057	Kaliadem	Kencur	Tanaman Obat	2023	0.0667	0.0881	2	1	1	0.3101	kuintal
AGRI-0274	Glagaharjo	PAD-056	Besalen	Jahe	Tanaman Obat	2023	0.0571	0.0719	2	2	1	0.4566	kuintal
AGRI-0275	Umbulharjo	PAD-073	Pentingsari	Kunyit	Tanaman Obat	2023	0.0875	0.1066	2	1	1	0.4247	kuintal
AGRI-0276	Argomulyo	PAD-022	Mudal	Cabai Rawit	Hortikultura	2024	0.3596	0.4415	2	1	1	29.4400	kuintal
AGRI-0277	Argomulyo	PAD-020	Dliring	Kunyit	Tanaman Obat	2023	0.1622	0.2086	6	3	1	0.8539	kuintal
AGRI-0278	Glagaharjo	PAD-056	Besalen	Cabai Keriting	Hortikultura	2024	2.7477	3.1931	27	13	3	243.9400	kuintal
AGRI-0279	Argomulyo	PAD-006	Kebur Lor	Cabai Keriting	Hortikultura	2024	1.1881	1.4731	12	10	1	149.0500	kuintal
AGRI-0280	Argomulyo	PAD-010	Cangkringan	Bawang Merah	Hortikultura	2024	0.0056	0.0062	2	2	1	0.4200	kuintal
AGRI-0281	Wukirsari	PAD-029	Sempon	Jahe	Tanaman Obat	2023	0.1592	0.1806	4	2	1	2.3061	kuintal
AGRI-0282	Kepuharjo	PAD-061	Batur	Kencur	Tanaman Obat	2023	0.0243	0.0281	2	1	1	0.1309	kuintal
AGRI-0283	Argomulyo	PAD-002	Kuwang	Cabai Keriting	Hortikultura	2024	0.2915	0.3344	2	1	1	34.2500	kuintal
AGRI-0284	Umbulharjo	PAD-072	Plosokerep	Kunyit	Tanaman Obat	2023	0.1048	0.1256	2	2	1	0.6250	kuintal
AGRI-0285	Wukirsari	PAD-033	Tanjung	Cabai Besar/TW/Teropong	Hortikultura	2024	0.1432	0.1694	2	2	1	9.4100	kuintal
AGRI-0286	Argomulyo	PAD-002	Kuwang	Cabai Besar/TW/Teropong	Hortikultura	2024	1.4864	1.7434	14	8	1	117.9300	kuintal
AGRI-0287	Wukirsari	PAD-034	Bedoyo	Jahe	Tanaman Obat	2023	1.8275	2.4086	18	15	2	14.1115	kuintal
AGRI-0288	Argomulyo	PAD-001	Randusari	Jahe	Tanaman Obat	2023	0.2419	0.3134	2	1	1	3.1687	kuintal
AGRI-0289	Argomulyo	PAD-015	Bakalan	Cabai Keriting	Hortikultura	2024	1.5384	1.7284	15	12	1	125.6900	kuintal
AGRI-0290	Argomulyo	PAD-003	Panggung	Cabai Rawit	Hortikultura	2024	0.8004	0.8945	10	6	1	87.0000	kuintal
AGRI-0291	Kepuharjo	PAD-062	Pagerjurang	Kunyit	Tanaman Obat	2023	0.4238	0.5619	6	4	1	1.6638	kuintal
AGRI-0292	Kepuharjo	PAD-060	Kopeng	Cabai Rawit	Hortikultura	2024	0.4960	0.5389	8	5	1	43.0800	kuintal
AGRI-0293	Argomulyo	PAD-022	Mudal	Cabai Besar/TW/Teropong	Hortikultura	2024	1.1263	1.2362	11	9	1	108.2300	kuintal
AGRI-0294	Glagaharjo	PAD-052	Glagah Malang	Cabai Rawit	Hortikultura	2024	0.6369	0.7328	7	5	1	55.3500	kuintal
AGRI-0295	Wukirsari	PAD-042	Ngepringan	Cabai Keriting	Hortikultura	2024	1.3696	1.5755	13	8	1	126.9800	kuintal
AGRI-0296	Argomulyo	PAD-017	Banaran	Kunyit	Tanaman Obat	2023	0.0718	0.0887	3	2	1	0.2262	kuintal
AGRI-0297	Wukirsari	PAD-030	Ngemplak	Kencur	Tanaman Obat	2023	0.0243	0.0317	3	2	1	0.1138	kuintal
AGRI-0298	Argomulyo	PAD-020	Dliring	Cabai Besar/TW/Teropong	Hortikultura	2024	0.3003	0.3486	3	2	1	22.8500	kuintal
AGRI-0299	Wukirsari	PAD-043	Gondang	Cabai Rawit	Hortikultura	2024	0.9614	1.2690	6	3	1	77.7900	kuintal
AGRI-0300	Argomulyo	PAD-002	Kuwang	Kencur	Tanaman Obat	2023	0.0190	0.0214	2	1	1	0.0962	kuintal
AGRI-0301	Kepuharjo	PAD-058	Jambu	Jahe	Tanaman Obat	2023	0.2565	0.3136	2	1	1	3.1402	kuintal
AGRI-0302	Argomulyo	PAD-009	Brongkol	Bawang Merah	Hortikultura	2024	0.0044	0.0059	2	1	1	0.4100	kuintal
AGRI-0303	Wukirsari	PAD-040	Duwet	Kencur	Tanaman Obat	2023	0.0393	0.0481	5	3	1	0.1645	kuintal
AGRI-0304	Argomulyo	PAD-013	Jetis	Cabai Besar/TW/Teropong	Hortikultura	2024	0.5615	0.6192	4	2	1	39.8000	kuintal
AGRI-0305	Wukirsari	PAD-041	Gungan	Cabai Keriting	Hortikultura	2024	0.5200	0.5880	9	6	1	37.9300	kuintal
AGRI-0306	Argomulyo	PAD-004	Kliwang	Bawang Merah	Hortikultura	2024	0.0163	0.0199	2	2	1	1.5100	kuintal
AGRI-0307	Argomulyo	PAD-021	Gayam	Kencur	Tanaman Obat	2023	0.1470	0.1775	2	1	1	0.8027	kuintal
AGRI-0308	Argomulyo	PAD-003	Panggung	Cabai Besar/TW/Teropong	Hortikultura	2024	0.5633	0.6216	4	3	1	39.1000	kuintal
AGRI-0309	Glagaharjo	PAD-050	Singlar	Bawang Merah	Hortikultura	2024	0.0255	0.0335	2	1	1	1.8100	kuintal
AGRI-0310	Glagaharjo	PAD-051	Gading	Cabai Keriting	Hortikultura	2024	0.4901	0.6084	7	4	1	32.6500	kuintal
AGRI-0311	Wukirsari	PAD-037	Kregan	Kunyit	Tanaman Obat	2023	0.0373	0.0423	2	1	1	0.2276	kuintal
AGRI-0312	Wukirsari	PAD-035	Selorejo	Bawang Merah	Hortikultura	2024	0.0076	0.0086	2	1	1	0.6000	kuintal
AGRI-0313	Argomulyo	PAD-018	Kauman	Bawang Merah	Hortikultura	2024	0.0038	0.0047	2	1	1	0.3100	kuintal
AGRI-0314	Wukirsari	PAD-025	Pusmalang	Cabai Keriting	Hortikultura	2024	1.0203	1.2050	12	10	1	84.5000	kuintal
AGRI-0315	Wukirsari	PAD-032	Sembungan	Cabai Keriting	Hortikultura	2024	0.7964	1.0138	10	7	1	78.1100	kuintal
AGRI-0316	Wukirsari	PAD-029	Sempon	Kunyit	Tanaman Obat	2023	0.1794	0.2174	4	2	1	1.3650	kuintal
AGRI-0317	Wukirsari	PAD-034	Bedoyo	Kencur	Tanaman Obat	2023	0.0804	0.0873	2	1	1	0.4768	kuintal
AGRI-0318	Argomulyo	PAD-016	Gadingan	Kunyit	Tanaman Obat	2023	0.1137	0.1235	2	2	1	0.5045	kuintal
AGRI-0319	Argomulyo	PAD-011	Jaranan	Kencur	Tanaman Obat	2023	0.0196	0.0241	3	2	1	0.1021	kuintal
AGRI-0320	Wukirsari	PAD-029	Sempon	Kencur	Tanaman Obat	2023	0.1641	0.1847	2	1	1	0.9291	kuintal
AGRI-0321	Wukirsari	PAD-030	Ngemplak	Cabai Besar/TW/Teropong	Hortikultura	2024	0.3316	0.3933	4	2	1	24.8800	kuintal
AGRI-0322	Wukirsari	PAD-036	Plupuh	Jahe	Tanaman Obat	2023	0.8468	1.1112	9	4	1	10.2839	kuintal
AGRI-0323	Glagaharjo	PAD-048	Kalitengah Kidul	Jahe	Tanaman Obat	2023	0.0982	0.1199	2	1	1	1.1961	kuintal
AGRI-0324	Argomulyo	PAD-011	Jaranan	Kunyit	Tanaman Obat	2023	0.1990	0.2615	2	1	1	0.7840	kuintal
AGRI-0325	Argomulyo	PAD-014	Suruh	Cabai Rawit	Hortikultura	2024	1.2724	1.4190	10	5	1	81.7500	kuintal
AGRI-0326	Wukirsari	PAD-040	Duwet	Cabai Keriting	Hortikultura	2024	0.7174	0.8876	10	6	1	75.2200	kuintal
AGRI-0327	Wukirsari	PAD-025	Pusmalang	Bawang Merah	Hortikultura	2024	0.0110	0.0129	2	1	1	1.2900	kuintal
AGRI-0328	Wukirsari	PAD-031	Kiyaran	Cabai Keriting	Hortikultura	2024	0.7155	0.8111	4	2	1	78.9000	kuintal
AGRI-0329	Argomulyo	PAD-011	Jaranan	Cabai Keriting	Hortikultura	2024	0.9787	1.0999	11	10	1	77.1400	kuintal
AGRI-0330	Kepuharjo	PAD-063	Kepuh	Kunyit	Tanaman Obat	2023	0.1138	0.1273	3	2	1	0.4925	kuintal
AGRI-0331	Argomulyo	PAD-001	Randusari	Cabai Keriting	Hortikultura	2024	0.2759	0.3529	8	5	1	29.2800	kuintal
AGRI-0332	Argomulyo	PAD-001	Randusari	Cabai Rawit	Hortikultura	2024	0.3532	0.4348	2	1	1	38.2400	kuintal
AGRI-0333	Wukirsari	PAD-040	Duwet	Cabai Rawit	Hortikultura	2024	1.6315	1.7851	18	15	2	149.9200	kuintal
AGRI-0334	Glagaharjo	PAD-047	Kalitengah Lor	Cabai Besar/TW/Teropong	Hortikultura	2024	0.7999	0.9536	7	6	1	91.3100	kuintal
AGRI-0335	Glagaharjo	PAD-049	Srunen	Kunyit	Tanaman Obat	2023	0.0876	0.1136	2	1	1	0.4401	kuintal
AGRI-0336	Argomulyo	PAD-021	Gayam	Cabai Rawit	Hortikultura	2024	0.5544	0.6169	9	7	1	58.3700	kuintal
AGRI-0337	Argomulyo	PAD-006	Kebur Lor	Cabai Rawit	Hortikultura	2024	0.2989	0.3597	5	3	1	20.3800	kuintal
AGRI-0338	Wukirsari	PAD-041	Gungan	Kencur	Tanaman Obat	2023	0.0672	0.0736	2	1	1	0.3957	kuintal
AGRI-0339	Wukirsari	PAD-030	Ngemplak	Bawang Merah	Hortikultura	2024	0.0060	0.0069	2	1	1	0.5300	kuintal
AGRI-0340	Kepuharjo	PAD-061	Batur	Bawang Merah	Hortikultura	2024	0.0073	0.0091	2	1	1	0.5900	kuintal
AGRI-0341	Umbulharjo	PAD-071	Karanggeneng	Cabai Rawit	Hortikultura	2024	0.5275	0.7008	4	2	1	38.7900	kuintal
AGRI-0342	Wukirsari	PAD-028	Rejosari	Kencur	Tanaman Obat	2023	0.0604	0.0804	2	1	1	0.3612	kuintal
AGRI-0343	Argomulyo	PAD-018	Kauman	Cabai Besar/TW/Teropong	Hortikultura	2024	0.4969	0.6527	4	3	1	36.0200	kuintal
AGRI-0344	Argomulyo	PAD-013	Jetis	Kunyit	Tanaman Obat	2023	0.0513	0.0577	2	1	1	0.3916	kuintal
AGRI-0345	Wukirsari	PAD-024	Glagahwero	Kunyit	Tanaman Obat	2023	0.1153	0.1398	2	1	1	0.6258	kuintal
AGRI-0346	Wukirsari	PAD-033	Tanjung	Kunyit	Tanaman Obat	2023	0.0343	0.0462	2	1	1	0.2263	kuintal
AGRI-0347	Umbulharjo	PAD-073	Pentingsari	Kencur	Tanaman Obat	2023	0.0900	0.1020	2	1	1	0.3425	kuintal
AGRI-0348	Wukirsari	PAD-041	Gungan	Cabai Rawit	Hortikultura	2024	4.3219	5.6816	40	18	3	288.9100	kuintal
AGRI-0349	Umbulharjo	PAD-071	Karanggeneng	Kencur	Tanaman Obat	2023	0.0431	0.0511	2	1	1	0.2545	kuintal
AGRI-0350	Glagaharjo	PAD-054	Ngancar	Jahe	Tanaman Obat	2023	0.1436	0.1656	2	1	1	1.3307	kuintal
AGRI-0351	Glagaharjo	PAD-053	Jetis Sumur	Jahe	Tanaman Obat	2023	0.1802	0.2207	2	2	1	1.5655	kuintal
AGRI-0352	Argomulyo	PAD-013	Jetis	Bawang Merah	Hortikultura	2024	0.0140	0.0160	2	2	1	1.5300	kuintal
AGRI-0353	Glagaharjo	PAD-056	Besalen	Kunyit	Tanaman Obat	2023	0.1531	0.1952	2	1	1	0.7526	kuintal
AGRI-0354	Glagaharjo	PAD-049	Srunen	Cabai Keriting	Hortikultura	2024	0.4253	0.5388	2	2	1	43.7500	kuintal
AGRI-0355	Wukirsari	PAD-036	Plupuh	Cabai Rawit	Hortikultura	2024	0.8888	0.9770	4	2	1	57.2500	kuintal
AGRI-0356	Wukirsari	PAD-037	Kregan	Jahe	Tanaman Obat	2023	0.4552	0.6072	4	2	1	4.1554	kuintal
AGRI-0357	Wukirsari	PAD-046	Cangcangan	Jahe	Tanaman Obat	2023	0.3396	0.4135	6	5	1	3.6874	kuintal
AGRI-0358	Wukirsari	PAD-045	Surodadi	Cabai Besar/TW/Teropong	Hortikultura	2024	1.0508	1.3556	9	7	1	87.4200	kuintal
AGRI-0359	Wukirsari	PAD-026	Sruni	Kunyit	Tanaman Obat	2023	0.2169	0.2613	5	3	1	0.9900	kuintal
AGRI-0360	Argomulyo	PAD-003	Panggung	Bawang Merah	Hortikultura	2024	0.0060	0.0071	2	2	1	0.5400	kuintal
AGRI-0361	Kepuharjo	PAD-059	Petung	Cabai Besar/TW/Teropong	Hortikultura	2024	0.9815	1.2216	12	8	1	85.1500	kuintal
AGRI-0362	Glagaharjo	PAD-047	Kalitengah Lor	Kencur	Tanaman Obat	2023	0.0913	0.1047	2	2	1	0.4257	kuintal
AGRI-0363	Wukirsari	PAD-031	Kiyaran	Cabai Besar/TW/Teropong	Hortikultura	2024	1.5912	2.0055	16	13	2	101.3400	kuintal
AGRI-0364	Glagaharjo	PAD-047	Kalitengah Lor	Cabai Rawit	Hortikultura	2024	0.3599	0.3997	2	1	1	30.6600	kuintal
AGRI-0365	Argomulyo	PAD-007	Kebur Kidul	Bawang Merah	Hortikultura	2024	0.0018	0.0022	2	2	1	0.1500	kuintal
AGRI-0366	Argomulyo	PAD-010	Cangkringan	Cabai Rawit	Hortikultura	2024	1.3184	1.7788	14	8	2	101.0000	kuintal
AGRI-0367	Kepuharjo	PAD-059	Petung	Jahe	Tanaman Obat	2023	0.1507	0.1958	2	1	1	1.1763	kuintal
AGRI-0368	Kepuharjo	PAD-061	Batur	Cabai Besar/TW/Teropong	Hortikultura	2024	0.9227	1.0670	8	7	1	74.4900	kuintal
AGRI-0369	Argomulyo	PAD-019	Jiwan	Cabai Besar/TW/Teropong	Hortikultura	2024	0.8935	0.9879	8	4	1	68.5900	kuintal
AGRI-0370	Glagaharjo	PAD-055	Banjarsari	Cabai Rawit	Hortikultura	2024	0.8886	1.1357	9	8	1	54.1800	kuintal
AGRI-0371	Umbulharjo	PAD-069	Balong	Kencur	Tanaman Obat	2023	0.0579	0.0700	2	2	1	0.2657	kuintal
AGRI-0372	Kepuharjo	PAD-057	Kaliadem	Bawang Merah	Hortikultura	2024	0.0037	0.0050	2	1	1	0.2200	kuintal
AGRI-0373	Kepuharjo	PAD-063	Kepuh	Cabai Besar/TW/Teropong	Hortikultura	2024	0.7647	0.9928	6	4	1	64.5300	kuintal
AGRI-0374	Umbulharjo	PAD-072	Plosokerep	Cabai Keriting	Hortikultura	2024	1.7239	2.1930	16	13	2	126.6100	kuintal
AGRI-0375	Kepuharjo	PAD-058	Jambu	Cabai Rawit	Hortikultura	2024	0.3204	0.3594	3	2	1	30.3500	kuintal
AGRI-0376	Argomulyo	PAD-009	Brongkol	Cabai Keriting	Hortikultura	2024	0.3402	0.3966	2	1	1	27.9500	kuintal
AGRI-0377	Kepuharjo	PAD-057	Kaliadem	Jahe	Tanaman Obat	2023	0.1254	0.1443	2	1	1	1.4272	kuintal
AGRI-0378	Umbulharjo	PAD-066	Pangukrejo	Cabai Keriting	Hortikultura	2024	2.6104	2.9391	29	19	2	346.1900	kuintal
AGRI-0379	Argomulyo	PAD-004	Kliwang	Kencur	Tanaman Obat	2023	0.0715	0.0807	2	1	1	0.2901	kuintal
AGRI-0380	Argomulyo	PAD-008	Sewon	Bawang Merah	Hortikultura	2024	0.0115	0.0150	2	1	1	0.8000	kuintal
AGRI-0381	Kepuharjo	PAD-058	Jambu	Cabai Keriting	Hortikultura	2024	2.0807	2.7383	19	16	2	184.1800	kuintal
AGRI-0382	Wukirsari	PAD-044	Bulaksalak	Cabai Rawit	Hortikultura	2024	0.5839	0.7162	7	5	1	31.6400	kuintal
AGRI-0383	Wukirsari	PAD-034	Bedoyo	Kunyit	Tanaman Obat	2023	0.0487	0.0615	2	1	1	0.2860	kuintal
AGRI-0384	Argomulyo	PAD-012	Karanglo	Cabai Besar/TW/Teropong	Hortikultura	2024	0.3724	0.4470	4	2	1	34.6000	kuintal
AGRI-0385	Umbulharjo	PAD-067	Gondang	Cabai Besar/TW/Teropong	Hortikultura	2024	0.3310	0.3579	2	1	1	15.6700	kuintal
AGRI-0386	Wukirsari	PAD-033	Tanjung	Jahe	Tanaman Obat	2023	0.2524	0.2785	2	1	1	2.9850	kuintal
AGRI-0387	Argomulyo	PAD-014	Suruh	Bawang Merah	Hortikultura	2024	0.0163	0.0213	2	2	1	1.4600	kuintal
AGRI-0388	Argomulyo	PAD-005	Teplok	Kunyit	Tanaman Obat	2023	0.0806	0.0943	2	2	1	0.7079	kuintal
AGRI-0389	Argomulyo	PAD-013	Jetis	Cabai Rawit	Hortikultura	2024	0.3114	0.4002	4	2	1	25.1100	kuintal
AGRI-0390	Wukirsari	PAD-028	Rejosari	Cabai Besar/TW/Teropong	Hortikultura	2024	0.2662	0.2996	2	2	1	15.7800	kuintal
AGRI-0391	Wukirsari	PAD-031	Kiyaran	Kunyit	Tanaman Obat	2023	0.1135	0.1249	2	2	1	0.4386	kuintal
AGRI-0392	Glagaharjo	PAD-054	Ngancar	Cabai Rawit	Hortikultura	2024	0.2591	0.3051	4	3	1	26.3900	kuintal
AGRI-0393	Wukirsari	PAD-026	Sruni	Cabai Keriting	Hortikultura	2024	1.3931	1.6172	14	8	2	111.3700	kuintal
AGRI-0394	Wukirsari	PAD-024	Glagahwero	Cabai Rawit	Hortikultura	2024	1.7593	2.1611	16	12	2	180.0700	kuintal
AGRI-0395	Argomulyo	PAD-010	Cangkringan	Cabai Keriting	Hortikultura	2024	0.5351	0.6578	2	1	1	59.8800	kuintal
AGRI-0396	Wukirsari	PAD-032	Sembungan	Jahe	Tanaman Obat	2023	0.1917	0.2147	2	1	1	1.8426	kuintal
AGRI-0397	Kepuharjo	PAD-059	Petung	Cabai Rawit	Hortikultura	2024	0.5148	0.6156	5	3	1	41.1300	kuintal
AGRI-0398	Kepuharjo	PAD-064	Manggong	Cabai Rawit	Hortikultura	2024	0.3855	0.4188	2	1	1	30.6200	kuintal
AGRI-0399	Kepuharjo	PAD-060	Kopeng	Cabai Besar/TW/Teropong	Hortikultura	2024	2.3616	3.1386	21	17	2	174.9800	kuintal
AGRI-0400	Umbulharjo	PAD-065	Pelemsari	Cabai Keriting	Hortikultura	2024	2.0238	2.2940	18	14	2	167.8000	kuintal
AGRI-0401	Wukirsari	PAD-025	Pusmalang	Kunyit	Tanaman Obat	2023	0.0828	0.0987	2	1	1	0.4228	kuintal
AGRI-0402	Wukirsari	PAD-025	Pusmalang	Jahe	Tanaman Obat	2023	0.1290	0.1407	2	2	1	1.7741	kuintal
AGRI-0403	Argomulyo	PAD-019	Jiwan	Kunyit	Tanaman Obat	2023	0.1083	0.1430	2	2	1	0.4867	kuintal
AGRI-0404	Argomulyo	PAD-010	Cangkringan	Kencur	Tanaman Obat	2023	0.0705	0.0794	2	1	1	0.4004	kuintal
AGRI-0405	Glagaharjo	PAD-051	Gading	Cabai Besar/TW/Teropong	Hortikultura	2024	0.7078	0.8207	6	5	1	61.2900	kuintal
AGRI-0406	Wukirsari	PAD-045	Surodadi	Kencur	Tanaman Obat	2023	0.0580	0.0682	3	3	1	0.5027	kuintal
AGRI-0407	Umbulharjo	PAD-071	Karanggeneng	Bawang Merah	Hortikultura	2024	0.0041	0.0049	2	2	1	0.3400	kuintal
AGRI-0408	Argomulyo	PAD-005	Teplok	Kencur	Tanaman Obat	2023	0.0728	0.0819	3	3	1	0.2942	kuintal
AGRI-0409	Wukirsari	PAD-034	Bedoyo	Cabai Rawit	Hortikultura	2024	0.9712	1.1022	13	8	2	106.1500	kuintal
AGRI-0410	Umbulharjo	PAD-069	Balong	Jahe	Tanaman Obat	2023	0.4136	0.4495	4	3	1	3.4637	kuintal
AGRI-0411	Argomulyo	PAD-004	Kliwang	Jahe	Tanaman Obat	2023	0.2096	0.2397	4	3	1	1.9760	kuintal
AGRI-0412	Glagaharjo	PAD-051	Gading	Jahe	Tanaman Obat	2023	0.4364	0.5529	2	1	1	4.5852	kuintal
AGRI-0413	Kepuharjo	PAD-063	Kepuh	Jahe	Tanaman Obat	2023	0.1382	0.1706	5	4	1	1.8672	kuintal
AGRI-0414	Umbulharjo	PAD-066	Pangukrejo	Kencur	Tanaman Obat	2023	0.0247	0.0271	2	1	1	0.1285	kuintal
AGRI-0415	Kepuharjo	PAD-058	Jambu	Kunyit	Tanaman Obat	2023	0.0981	0.1143	3	2	1	0.4472	kuintal
AGRI-0416	Argomulyo	PAD-012	Karanglo	Bawang Merah	Hortikultura	2024	0.0071	0.0079	2	1	1	0.5000	kuintal
AGRI-0417	Glagaharjo	PAD-051	Gading	Kunyit	Tanaman Obat	2023	0.1191	0.1382	2	1	1	0.5506	kuintal
AGRI-0418	Wukirsari	PAD-024	Glagahwero	Cabai Keriting	Hortikultura	2024	2.1683	2.5653	18	11	2	161.8700	kuintal
AGRI-0419	Glagaharjo	PAD-047	Kalitengah Lor	Bawang Merah	Hortikultura	2024	0.0074	0.0088	2	1	1	0.6300	kuintal
AGRI-0420	Wukirsari	PAD-039	Cakran	Jahe	Tanaman Obat	2023	0.1633	0.1812	4	4	1	2.0315	kuintal
AGRI-0421	Umbulharjo	PAD-066	Pangukrejo	Cabai Besar/TW/Teropong	Hortikultura	2024	0.5628	0.6253	6	3	1	34.7500	kuintal
AGRI-0422	Wukirsari	PAD-035	Selorejo	Cabai Besar/TW/Teropong	Hortikultura	2024	1.2799	1.6783	7	4	1	82.1500	kuintal
AGRI-0423	Glagaharjo	PAD-047	Kalitengah Lor	Jahe	Tanaman Obat	2023	0.1712	0.2252	2	2	1	1.7868	kuintal
AGRI-0424	Glagaharjo	PAD-053	Jetis Sumur	Cabai Besar/TW/Teropong	Hortikultura	2024	0.6243	0.6833	7	4	1	44.3300	kuintal
AGRI-0425	Argomulyo	PAD-009	Brongkol	Cabai Rawit	Hortikultura	2024	0.4103	0.4852	2	1	1	36.5500	kuintal
AGRI-0426	Kepuharjo	PAD-061	Batur	Cabai Rawit	Hortikultura	2024	0.8898	1.0542	8	7	1	102.5100	kuintal
AGRI-0427	Argomulyo	PAD-018	Kauman	Cabai Keriting	Hortikultura	2024	1.5160	1.8044	16	8	1	129.9300	kuintal
AGRI-0428	Umbulharjo	PAD-071	Karanggeneng	Jahe	Tanaman Obat	2023	0.1134	0.1327	2	1	1	1.2704	kuintal
AGRI-0429	Umbulharjo	PAD-069	Balong	Kunyit	Tanaman Obat	2023	0.2105	0.2688	3	3	1	1.0109	kuintal
AGRI-0430	Wukirsari	PAD-027	Sintokan	Cabai Besar/TW/Teropong	Hortikultura	2024	0.6719	0.7948	8	5	1	55.4900	kuintal
AGRI-0431	Argomulyo	PAD-011	Jaranan	Jahe	Tanaman Obat	2023	0.4049	0.4499	2	1	1	3.7853	kuintal
AGRI-0432	Wukirsari	PAD-038	Salam Krajan	Kunyit	Tanaman Obat	2023	0.0875	0.0974	2	2	1	0.6814	kuintal
AGRI-0433	Umbulharjo	PAD-070	Plosorejo	Kencur	Tanaman Obat	2023	0.0743	0.0891	3	2	1	0.2632	kuintal
AGRI-0434	Argomulyo	PAD-016	Gadingan	Cabai Besar/TW/Teropong	Hortikultura	2024	1.3245	1.6937	10	6	1	101.3000	kuintal
AGRI-0435	Kepuharjo	PAD-062	Pagerjurang	Bawang Merah	Hortikultura	2024	0.0101	0.0116	2	1	1	0.8100	kuintal
AGRI-0436	Wukirsari	PAD-043	Gondang	Cabai Keriting	Hortikultura	2024	1.0659	1.1987	11	6	1	112.2200	kuintal
AGRI-0437	Wukirsari	PAD-044	Bulaksalak	Kencur	Tanaman Obat	2023	0.0567	0.0658	2	2	1	0.2833	kuintal
AGRI-0438	Wukirsari	PAD-044	Bulaksalak	Bawang Merah	Hortikultura	2024	0.0017	0.0020	2	1	1	0.1100	kuintal
AGRI-0439	Argomulyo	PAD-016	Gadingan	Kencur	Tanaman Obat	2023	0.0306	0.0350	2	1	1	0.1176	kuintal
AGRI-0440	Argomulyo	PAD-020	Dliring	Bawang Merah	Hortikultura	2024	0.0026	0.0031	2	1	1	0.1900	kuintal
AGRI-0441	Wukirsari	PAD-035	Selorejo	Kencur	Tanaman Obat	2023	0.0681	0.0798	2	2	1	0.3875	kuintal
AGRI-0442	Glagaharjo	PAD-051	Gading	Kencur	Tanaman Obat	2023	0.0457	0.0544	2	1	1	0.2253	kuintal
AGRI-0443	Wukirsari	PAD-026	Sruni	Kencur	Tanaman Obat	2023	0.0244	0.0327	3	3	1	0.0958	kuintal
AGRI-0444	Argomulyo	PAD-007	Kebur Kidul	Cabai Keriting	Hortikultura	2024	1.1246	1.4440	13	10	2	84.2100	kuintal
AGRI-0445	Argomulyo	PAD-020	Dliring	Kencur	Tanaman Obat	2023	0.0474	0.0545	3	2	1	0.2937	kuintal
AGRI-0446	Wukirsari	PAD-024	Glagahwero	Kencur	Tanaman Obat	2023	0.1470	0.1705	3	2	1	0.7394	kuintal
AGRI-0447	Wukirsari	PAD-042	Ngepringan	Kunyit	Tanaman Obat	2023	0.1585	0.2003	2	1	1	0.9340	kuintal
AGRI-0448	Wukirsari	PAD-040	Duwet	Cabai Besar/TW/Teropong	Hortikultura	2024	1.8316	2.0789	16	9	2	137.0000	kuintal
AGRI-0449	Glagaharjo	PAD-052	Glagah Malang	Kencur	Tanaman Obat	2023	0.1141	0.1539	3	2	1	0.3941	kuintal
AGRI-0450	Wukirsari	PAD-028	Rejosari	Cabai Keriting	Hortikultura	2024	1.5559	1.7707	19	13	2	166.5900	kuintal
AGRI-0451	Wukirsari	PAD-031	Kiyaran	Kencur	Tanaman Obat	2023	0.1582	0.1807	4	3	1	0.8543	kuintal
AGRI-0452	Wukirsari	PAD-039	Cakran	Kencur	Tanaman Obat	2023	0.0286	0.0354	2	1	1	0.1638	kuintal
AGRI-0453	Argomulyo	PAD-021	Gayam	Kunyit	Tanaman Obat	2023	0.1809	0.2274	2	2	1	0.9619	kuintal
AGRI-0454	Argomulyo	PAD-003	Panggung	Kencur	Tanaman Obat	2023	0.0545	0.0626	2	1	1	0.2687	kuintal
AGRI-0455	Glagaharjo	PAD-049	Srunen	Cabai Besar/TW/Teropong	Hortikultura	2024	0.3920	0.5032	5	3	1	36.9300	kuintal
AGRI-0456	Umbulharjo	PAD-066	Pangukrejo	Bawang Merah	Hortikultura	2024	0.0233	0.0296	2	1	1	2.2300	kuintal
AGRI-0457	Argomulyo	PAD-022	Mudal	Jahe	Tanaman Obat	2023	0.2865	0.3221	2	2	1	2.3069	kuintal
AGRI-0458	Wukirsari	PAD-026	Sruni	Cabai Besar/TW/Teropong	Hortikultura	2024	0.7175	0.9231	10	5	1	79.4500	kuintal
AGRI-0459	Argomulyo	PAD-004	Kliwang	Kunyit	Tanaman Obat	2023	0.2314	0.3054	2	1	1	0.9695	kuintal
AGRI-0460	Argomulyo	PAD-021	Gayam	Cabai Besar/TW/Teropong	Hortikultura	2024	1.3030	1.4090	10	7	1	77.3300	kuintal
AGRI-0461	Wukirsari	PAD-023	Karangpakis	Bawang Merah	Hortikultura	2024	0.0094	0.0126	2	1	1	0.5900	kuintal
AGRI-0462	Argomulyo	PAD-014	Suruh	Cabai Besar/TW/Teropong	Hortikultura	2024	0.9577	1.1208	10	5	1	66.6600	kuintal
AGRI-0463	Umbulharjo	PAD-069	Balong	Cabai Keriting	Hortikultura	2024	0.3400	0.4286	5	3	1	30.6900	kuintal
AGRI-0464	Kepuharjo	PAD-057	Kaliadem	Cabai Besar/TW/Teropong	Hortikultura	2024	0.3877	0.4871	5	4	1	22.7800	kuintal
AGRI-0465	Wukirsari	PAD-034	Bedoyo	Cabai Besar/TW/Teropong	Hortikultura	2024	1.6894	1.8565	19	9	2	220.9400	kuintal
AGRI-0466	Kepuharjo	PAD-062	Pagerjurang	Cabai Keriting	Hortikultura	2024	0.2653	0.3505	2	1	1	26.3900	kuintal
AGRI-0467	Umbulharjo	PAD-065	Pelemsari	Bawang Merah	Hortikultura	2024	0.0087	0.0116	2	2	1	0.6800	kuintal
AGRI-0468	Kepuharjo	PAD-059	Petung	Kunyit	Tanaman Obat	2023	0.1096	0.1231	2	2	1	0.7776	kuintal
AGRI-0469	Kepuharjo	PAD-061	Batur	Kunyit	Tanaman Obat	2023	0.0333	0.0412	2	1	1	0.1729	kuintal
AGRI-0470	Argomulyo	PAD-012	Karanglo	Jahe	Tanaman Obat	2023	0.3274	0.3964	3	2	1	4.0266	kuintal
AGRI-0471	Umbulharjo	PAD-067	Gondang	Bawang Merah	Hortikultura	2024	0.0102	0.0122	2	2	1	0.8400	kuintal
AGRI-0472	Argomulyo	PAD-022	Mudal	Kencur	Tanaman Obat	2023	0.0529	0.0616	2	2	1	0.3567	kuintal
AGRI-0473	Argomulyo	PAD-013	Jetis	Cabai Keriting	Hortikultura	2024	0.4211	0.5197	3	2	1	39.9900	kuintal
AGRI-0474	Argomulyo	PAD-022	Mudal	Bawang Merah	Hortikultura	2024	0.0119	0.0156	2	1	1	0.7200	kuintal
AGRI-0475	Argomulyo	PAD-013	Jetis	Kencur	Tanaman Obat	2023	0.0475	0.0596	2	1	1	0.1943	kuintal
AGRI-0476	Wukirsari	PAD-038	Salam Krajan	Cabai Besar/TW/Teropong	Hortikultura	2024	0.4679	0.6047	4	3	1	44.4300	kuintal
AGRI-0477	Kepuharjo	PAD-060	Kopeng	Kencur	Tanaman Obat	2023	0.0634	0.0774	2	2	1	0.3452	kuintal
AGRI-0478	Argomulyo	PAD-015	Bakalan	Bawang Merah	Hortikultura	2024	0.0097	0.0105	2	1	1	0.9700	kuintal
AGRI-0479	Argomulyo	PAD-017	Banaran	Cabai Keriting	Hortikultura	2024	0.8480	1.0525	11	10	1	104.1000	kuintal
AGRI-0480	Kepuharjo	PAD-060	Kopeng	Cabai Keriting	Hortikultura	2024	1.0452	1.1710	8	5	1	95.2200	kuintal
AGRI-0481	Glagaharjo	PAD-051	Gading	Bawang Merah	Hortikultura	2024	0.0072	0.0085	2	2	1	0.6900	kuintal
AGRI-0482	Wukirsari	PAD-038	Salam Krajan	Bawang Merah	Hortikultura	2024	0.0071	0.0089	2	1	1	0.4400	kuintal
AGRI-0483	Argomulyo	PAD-007	Kebur Kidul	Kunyit	Tanaman Obat	2023	0.0672	0.0870	3	3	1	0.2229	kuintal
AGRI-0484	Argomulyo	PAD-002	Kuwang	Jahe	Tanaman Obat	2023	0.0669	0.0748	2	2	1	0.7235	kuintal
AGRI-0485	Wukirsari	PAD-029	Sempon	Cabai Rawit	Hortikultura	2024	0.9035	1.1035	9	7	1	81.9300	kuintal
AGRI-0486	Glagaharjo	PAD-050	Singlar	Cabai Keriting	Hortikultura	2024	0.6373	0.7419	7	5	1	69.4300	kuintal
AGRI-0487	Glagaharjo	PAD-055	Banjarsari	Cabai Besar/TW/Teropong	Hortikultura	2024	0.3032	0.3900	2	1	1	28.3800	kuintal
AGRI-0488	Umbulharjo	PAD-069	Balong	Bawang Merah	Hortikultura	2024	0.0097	0.0119	3	3	1	0.8100	kuintal
AGRI-0489	Argomulyo	PAD-007	Kebur Kidul	Cabai Besar/TW/Teropong	Hortikultura	2024	0.9154	0.9923	8	4	1	75.5400	kuintal
AGRI-0490	Argomulyo	PAD-019	Jiwan	Kencur	Tanaman Obat	2023	0.0294	0.0358	2	1	1	0.1637	kuintal
AGRI-0491	Argomulyo	PAD-015	Bakalan	Cabai Besar/TW/Teropong	Hortikultura	2024	0.3282	0.4188	4	3	1	22.6300	kuintal
AGRI-0492	Wukirsari	PAD-031	Kiyaran	Bawang Merah	Hortikultura	2024	0.0247	0.0331	2	2	1	2.0200	kuintal
AGRI-0493	Wukirsari	PAD-027	Sintokan	Cabai Keriting	Hortikultura	2024	0.1168	0.1495	2	2	1	15.5000	kuintal
AGRI-0494	Umbulharjo	PAD-067	Gondang	Kunyit	Tanaman Obat	2023	0.0794	0.1027	4	3	1	0.4145	kuintal
AGRI-0495	Umbulharjo	PAD-069	Balong	Cabai Besar/TW/Teropong	Hortikultura	2024	0.3259	0.4233	5	3	1	25.1500	kuintal
AGRI-0496	Wukirsari	PAD-041	Gungan	Bawang Merah	Hortikultura	2024	0.0125	0.0158	2	2	1	0.9000	kuintal
AGRI-0497	Wukirsari	PAD-039	Cakran	Cabai Besar/TW/Teropong	Hortikultura	2024	1.7070	1.8748	15	11	2	147.2400	kuintal
AGRI-0498	Glagaharjo	PAD-053	Jetis Sumur	Kunyit	Tanaman Obat	2023	0.0303	0.0349	2	1	1	0.2070	kuintal
AGRI-0499	Argomulyo	PAD-001	Randusari	Kencur	Tanaman Obat	2023	0.0872	0.0993	2	1	1	0.4239	kuintal
AGRI-0500	Wukirsari	PAD-030	Ngemplak	Kunyit	Tanaman Obat	2023	0.0388	0.0444	2	2	1	0.1771	kuintal
AGRI-0501	Wukirsari	PAD-041	Gungan	Kunyit	Tanaman Obat	2023	0.0337	0.0454	2	1	1	0.1553	kuintal
AGRI-0502	Argomulyo	PAD-014	Suruh	Jahe	Tanaman Obat	2023	0.1524	0.1888	3	2	1	1.8631	kuintal
AGRI-0503	Glagaharjo	PAD-053	Jetis Sumur	Bawang Merah	Hortikultura	2024	0.0048	0.0054	2	2	1	0.4100	kuintal
AGRI-0504	Argomulyo	PAD-006	Kebur Lor	Kunyit	Tanaman Obat	2023	0.0882	0.1086	5	4	1	0.4361	kuintal
AGRI-0505	Argomulyo	PAD-009	Brongkol	Kunyit	Tanaman Obat	2023	0.0914	0.1164	2	1	1	0.4024	kuintal
AGRI-0506	Argomulyo	PAD-012	Karanglo	Cabai Keriting	Hortikultura	2024	1.1912	1.3891	14	9	2	97.9500	kuintal
AGRI-0507	Wukirsari	PAD-031	Kiyaran	Cabai Rawit	Hortikultura	2024	2.1360	2.5832	19	14	2	146.7100	kuintal
AGRI-0508	Glagaharjo	PAD-054	Ngancar	Cabai Keriting	Hortikultura	2024	1.9433	2.4903	18	13	2	141.0600	kuintal
AGRI-0509	Glagaharjo	PAD-048	Kalitengah Kidul	Kunyit	Tanaman Obat	2023	0.1558	0.1815	4	3	1	0.6898	kuintal
AGRI-0510	Argomulyo	PAD-022	Mudal	Cabai Keriting	Hortikultura	2024	0.3725	0.4385	2	1	1	33.1700	kuintal
AGRI-0511	Argomulyo	PAD-021	Gayam	Bawang Merah	Hortikultura	2024	0.0206	0.0273	2	2	1	1.8800	kuintal
\.


--
-- Data for Name: data_pertanian_real; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.data_pertanian_real (agri_id, wilayah, komoditas, luas_panen_ha, luas_lahan_ha, jumlah_utp, produksi, satuan_produksi, tahun_produksi, tahun_utp, sumber_produksi, sumber_utp, status_data, catatan) FROM stdin;
AGR-001	Kecamatan Cangkringan	Bawang Merah	0.7000	\N	15	58.0000	kuintal	2024	2023	BPS Cangkringan Dalam Angka 2025	ST2023	REAL	\N
AGR-002	Kecamatan Cangkringan	Cabai Keriting	73.0000	\N	156	6643.0000	kuintal	2024	2023	BPS Cangkringan Dalam Angka 2025	ST2023	REAL	\N
AGR-003	Kecamatan Cangkringan	Cabai Rawit	\N	\N	1096	\N	kuintal	2024	2023	BPS Cangkringan Dalam Angka 2025	ST2023	REAL	Produksi 2024 tidak dilaporkan
AGR-004	Kecamatan Cangkringan	Cabai Besar/TW/Teropong	55.0000	\N	4	4409.0000	kuintal	2024	2023	BPS Cangkringan Dalam Angka 2025	ST2023	REAL	\N
AGR-005	Kecamatan Cangkringan	Kentang	\N	\N	\N	\N	kuintal	2024	\N	BPS Cangkringan Dalam Angka 2025	\N	REAL	Data tidak dilaporkan
AGR-006	Kecamatan Cangkringan	Kubis	\N	\N	\N	\N	kuintal	2024	\N	BPS Cangkringan Dalam Angka 2025	\N	REAL	Data tidak dilaporkan
AGR-007	Kecamatan Cangkringan	Tomat	\N	\N	\N	\N	kuintal	2024	\N	BPS Cangkringan Dalam Angka 2025	\N	REAL	Data tidak dilaporkan
AGR-008	Kecamatan Cangkringan	Bawang Putih	\N	\N	\N	\N	kuintal	2024	\N	BPS Cangkringan Dalam Angka 2025	ST2023	REAL	UTP 2023 tidak tercatat
AGR-009	Kecamatan Cangkringan	Kacang Panjang	\N	\N	\N	\N	kuintal	2024	\N	BPS Cangkringan Dalam Angka 2025	\N	REAL	Data tidak dilaporkan
AGR-010	Kecamatan Cangkringan	Melon	\N	\N	\N	\N	kuintal	2024	\N	BPS Cangkringan Dalam Angka 2025	\N	REAL	Data tidak dilaporkan
AGR-011	Kecamatan Cangkringan	Jahe	\N	\N	\N	19896.0000	kg	2023	\N	BPS Cangkringan Dalam Angka 2024	\N	REAL	Produksi merupakan total Jahe
AGR-012	Kecamatan Cangkringan	Lengkuas	\N	\N	\N	\N	kg	2023	\N	BPS Cangkringan Dalam Angka 2024	\N	REAL	Data tidak dilaporkan
AGR-013	Kecamatan Cangkringan	Kencur	\N	\N	\N	2497.0000	kg	2023	\N	BPS Cangkringan Dalam Angka 2024	\N	REAL	\N
AGR-014	Kecamatan Cangkringan	Kunyit	\N	\N	1	4429.0000	kg	2023	2023	BPS Cangkringan Dalam Angka 2024	ST2023	REAL	\N
\.


--
-- Data for Name: kalurahan; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.kalurahan (kalurahan_id, kalurahan, luas_kalurahan_ha, jumlah_padukuhan, jumlah_rw, jumlah_rt, batas_utara, batas_selatan, batas_barat, batas_timur, jarak_kecamatan_km, jarak_kabupaten_km, jarak_provinsi_km, jarak_nasional_km, latitude, longitude) FROM stdin;
KAL-001	Argomulyo	847.0000	22	44	91	Glagaharjo, Wukirsari	Sindumartani, Bimomartani, Kec. Ngemplak	Wukirsari	Kepurun, Kec. Manisrenggo, Kab. Klaten	0.10	20.00	27.00	530.00	-7.6683300	110.4602800
KAL-002	Wukirsari	1456.0000	24	50	103	Umbulharjo, Kepuharjo	Umbulmartani, Widodomartani, Kec. Ngemplak	Pakembinangun, Kec. Pakem	Argomulyo, Glagaharjo	\N	17.00	25.00	528.00	-7.6579160	110.4438360
KAL-003	Glagaharjo	795.0000	10	20	41	Kec. Selo, Kab. Boyolali	Argomulyo	Wukirsari, Kepuharjo	Panggang, Bawukan, Balerante, Kec. Kemalang, Kab. Klaten	3.00	23.00	30.00	533.00	-7.6482628	110.4684501
KAL-004	Kepuharjo	875.0000	8	16	33	Kec. Selo, Kab. Boyolali	Wukirsari	Umbulharjo	Glagaharjo	7.00	28.00	32.00	535.00	-7.6251681	110.4523856
KAL-005	Umbulharjo	826.0000	9	20	40	Kec. Selo, Kab. Boyolali	Wukirsari	Hargobinangun, Kec. Pakem	Kepuharjo	8.00	21.00	29.00	530.00	-7.6258270	110.4333990
\.


--
-- Data for Name: ketersediaan_bahan; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ketersediaan_bahan (ketersediaan_id, bahan_id, padukuhan_id, periode, jumlah_ketersediaan, satuan, kontinuitas, jarak_ke_produksi_km, kemudahan_pengumpulan, status_pemanfaatan, frekuensi, musim, jumlah_sumber, status_data) FROM stdin;
KB-001	BAH-004	PAD-006	2025-01-01	150.00	kg	Kontinu	3.35	Sedang	Belum dimanfaatkan	Harian	Sepanjang tahun	1	Sintetis
KB-002	BAH-011	PAD-017	2025-02-01	287.00	kg	Tidak kontinu	2.70	Mudah	Sebagian dimanfaatkan	Mingguan	Musim panen	4	Sintetis
KB-003	BAH-001	PAD-028	2025-03-01	424.00	kg	Musiman	1.55	Sulit	Sudah dimanfaatkan	Bulanan	Musim tertentu	7	Sintetis
KB-004	BAH-008	PAD-039	2025-04-01	561.00	kg	Cukup kontinu	0.64	Sedang	Dimanfaatkan sebagai pupuk	Musiman	Sepanjang tahun	10	Sintetis
KB-005	BAH-015	PAD-050	2025-05-01	698.00	kg	Kontinu	3.76	Mudah	Belum dimanfaatkan	Harian	Musim panen	3	Sintetis
KB-006	BAH-005	PAD-061	2025-06-01	835.00	kg	Tidak kontinu	2.94	Sulit	Sebagian dimanfaatkan	Mingguan	Musim tertentu	6	Sintetis
KB-007	BAH-012	PAD-072	2025-07-01	972.00	kg	Musiman	1.83	Sedang	Sudah dimanfaatkan	Bulanan	Sepanjang tahun	9	Sintetis
KB-008	BAH-002	PAD-010	2025-08-01	1109.00	kg	Cukup kontinu	3.90	Mudah	Dimanfaatkan sebagai pupuk	Musiman	Musim panen	2	Sintetis
KB-009	BAH-009	PAD-021	2025-09-01	1246.00	kg	Kontinu	2.36	Sulit	Belum dimanfaatkan	Harian	Musim tertentu	5	Sintetis
KB-010	BAH-016	PAD-032	2025-10-01	1383.00	kg	Tidak kontinu	2.27	Sedang	Sebagian dimanfaatkan	Mingguan	Sepanjang tahun	8	Sintetis
KB-011	BAH-006	PAD-043	2025-11-01	169.00	kg	Musiman	1.14	Mudah	Sudah dimanfaatkan	Bulanan	Musim panen	1	Sintetis
KB-012	BAH-013	PAD-054	2025-12-01	306.00	kg	Cukup kontinu	1.62	Sulit	Dimanfaatkan sebagai pupuk	Musiman	Musim tertentu	4	Sintetis
KB-013	BAH-003	PAD-065	2025-01-01	443.00	kg	Kontinu	6.87	Sedang	Belum dimanfaatkan	Harian	Sepanjang tahun	7	Sintetis
KB-014	BAH-010	PAD-003	2025-02-01	580.00	kg	Tidak kontinu	2.33	Mudah	Sebagian dimanfaatkan	Mingguan	Musim panen	10	Sintetis
KB-015	BAH-017	PAD-014	2025-03-01	717.00	kg	Musiman	2.24	Sulit	Sudah dimanfaatkan	Bulanan	Musim tertentu	3	Sintetis
KB-016	BAH-007	PAD-025	2025-04-01	854.00	kg	Cukup kontinu	3.28	Sedang	Dimanfaatkan sebagai pupuk	Musiman	Sepanjang tahun	6	Sintetis
KB-017	BAH-014	PAD-036	2025-05-01	991.00	kg	Kontinu	1.09	Mudah	Belum dimanfaatkan	Harian	Musim panen	9	Sintetis
KB-018	BAH-004	PAD-047	2025-06-01	1128.00	kg	Tidak kontinu	6.76	Sulit	Sebagian dimanfaatkan	Mingguan	Musim tertentu	2	Sintetis
KB-019	BAH-011	PAD-058	2025-07-01	1265.00	kg	Musiman	3.46	Sedang	Sudah dimanfaatkan	Bulanan	Sepanjang tahun	5	Sintetis
KB-020	BAH-001	PAD-069	2025-08-01	1402.00	kg	Cukup kontinu	3.46	Mudah	Dimanfaatkan sebagai pupuk	Musiman	Musim panen	8	Sintetis
KB-021	BAH-008	PAD-007	2025-09-01	188.00	kg	Kontinu	3.55	Sulit	Belum dimanfaatkan	Harian	Musim tertentu	1	Sintetis
KB-022	BAH-015	PAD-018	2025-10-01	325.00	kg	Tidak kontinu	3.17	Sedang	Sebagian dimanfaatkan	Mingguan	Sepanjang tahun	4	Sintetis
KB-023	BAH-005	PAD-029	2025-11-01	462.00	kg	Musiman	1.66	Mudah	Sudah dimanfaatkan	Bulanan	Musim panen	7	Sintetis
KB-024	BAH-012	PAD-040	2025-12-01	599.00	kg	Cukup kontinu	0.48	Sulit	Dimanfaatkan sebagai pupuk	Musiman	Musim tertentu	10	Sintetis
KB-025	BAH-002	PAD-051	2025-01-01	736.00	kg	Kontinu	3.42	Sedang	Belum dimanfaatkan	Harian	Sepanjang tahun	3	Sintetis
KB-026	BAH-009	PAD-062	2025-02-01	873.00	kg	Tidak kontinu	1.93	Mudah	Sebagian dimanfaatkan	Mingguan	Musim panen	6	Sintetis
KB-027	BAH-016	PAD-073	2025-03-01	1010.00	kg	Musiman	3.78	Sulit	Sudah dimanfaatkan	Bulanan	Musim tertentu	9	Sintetis
KB-028	BAH-006	PAD-011	2025-04-01	1147.00	kg	Cukup kontinu	3.28	Sedang	Dimanfaatkan sebagai pupuk	Musiman	Sepanjang tahun	2	Sintetis
KB-029	BAH-013	PAD-022	2025-05-01	1284.00	kg	Kontinu	2.06	Mudah	Belum dimanfaatkan	Harian	Musim panen	5	Sintetis
KB-030	BAH-003	PAD-033	2025-06-01	1421.00	kg	Tidak kontinu	2.10	Sulit	Sebagian dimanfaatkan	Mingguan	Musim tertentu	8	Sintetis
KB-031	BAH-010	PAD-044	2025-07-01	207.00	kg	Musiman	0.72	Sedang	Sudah dimanfaatkan	Bulanan	Sepanjang tahun	1	Sintetis
KB-032	BAH-017	PAD-055	2025-08-01	344.00	kg	Cukup kontinu	1.78	Mudah	Dimanfaatkan sebagai pupuk	Musiman	Musim panen	4	Sintetis
KB-033	BAH-007	PAD-066	2025-09-01	481.00	kg	Kontinu	8.10	Sulit	Belum dimanfaatkan	Harian	Musim tertentu	7	Sintetis
KB-034	BAH-014	PAD-004	2025-10-01	618.00	kg	Tidak kontinu	2.67	Sedang	Sebagian dimanfaatkan	Mingguan	Sepanjang tahun	10	Sintetis
KB-035	BAH-004	PAD-015	2025-11-01	755.00	kg	Musiman	1.51	Mudah	Sudah dimanfaatkan	Bulanan	Musim panen	3	Sintetis
KB-036	BAH-011	PAD-026	2025-12-01	892.00	kg	Cukup kontinu	2.60	Sulit	Dimanfaatkan sebagai pupuk	Musiman	Musim tertentu	6	Sintetis
KB-037	BAH-001	PAD-037	2025-01-01	1029.00	kg	Kontinu	0.72	Sedang	Belum dimanfaatkan	Harian	Sepanjang tahun	9	Sintetis
KB-038	BAH-008	PAD-048	2025-02-01	1166.00	kg	Tidak kontinu	6.02	Mudah	Sebagian dimanfaatkan	Mingguan	Musim panen	2	Sintetis
KB-039	BAH-015	PAD-059	2025-03-01	1303.00	kg	Musiman	4.89	Sulit	Sudah dimanfaatkan	Bulanan	Musim tertentu	5	Sintetis
KB-040	BAH-005	PAD-070	2025-04-01	1440.00	kg	Cukup kontinu	3.02	Sedang	Dimanfaatkan sebagai pupuk	Musiman	Sepanjang tahun	8	Sintetis
KB-041	BAH-012	PAD-008	2025-05-01	226.00	kg	Kontinu	4.54	Mudah	Belum dimanfaatkan	Harian	Musim panen	1	Sintetis
KB-042	BAH-002	PAD-019	2025-06-01	363.00	kg	Tidak kontinu	2.73	Sulit	Sebagian dimanfaatkan	Mingguan	Musim tertentu	4	Sintetis
KB-043	BAH-009	PAD-030	2025-07-01	500.00	kg	Musiman	1.36	Sedang	Sudah dimanfaatkan	Bulanan	Sepanjang tahun	7	Sintetis
KB-044	BAH-016	PAD-041	2025-08-01	637.00	kg	Cukup kontinu	0.49	Mudah	Dimanfaatkan sebagai pupuk	Musiman	Musim panen	10	Sintetis
KB-045	BAH-006	PAD-052	2025-09-01	774.00	kg	Kontinu	0.63	Sulit	Belum dimanfaatkan	Harian	Musim tertentu	3	Sintetis
KB-046	BAH-013	PAD-063	2025-10-01	911.00	kg	Tidak kontinu	2.57	Sedang	Sebagian dimanfaatkan	Mingguan	Sepanjang tahun	6	Sintetis
KB-047	BAH-003	PAD-001	2025-11-01	1048.00	kg	Musiman	3.82	Mudah	Sudah dimanfaatkan	Bulanan	Musim panen	9	Sintetis
KB-048	BAH-010	PAD-012	2025-12-01	1185.00	kg	Cukup kontinu	2.93	Sulit	Dimanfaatkan sebagai pupuk	Musiman	Musim tertentu	2	Sintetis
KB-049	BAH-017	PAD-023	2025-01-01	1322.00	kg	Kontinu	3.25	Sedang	Belum dimanfaatkan	Harian	Sepanjang tahun	5	Sintetis
KB-050	BAH-007	PAD-034	2025-02-01	1459.00	kg	Tidak kontinu	2.18	Mudah	Sebagian dimanfaatkan	Mingguan	Musim panen	8	Sintetis
KB-051	BAH-014	PAD-045	2025-03-01	245.00	kg	Musiman	1.63	Sulit	Sudah dimanfaatkan	Bulanan	Musim tertentu	1	Sintetis
KB-052	BAH-004	PAD-056	2025-04-01	382.00	kg	Cukup kontinu	1.55	Sedang	Dimanfaatkan sebagai pupuk	Musiman	Sepanjang tahun	4	Sintetis
KB-053	BAH-011	PAD-067	2025-05-01	519.00	kg	Kontinu	2.76	Mudah	Belum dimanfaatkan	Harian	Musim panen	7	Sintetis
KB-054	BAH-001	PAD-005	2025-06-01	656.00	kg	Tidak kontinu	2.65	Sulit	Sebagian dimanfaatkan	Mingguan	Musim tertentu	10	Sintetis
KB-055	BAH-008	PAD-016	2025-07-01	793.00	kg	Musiman	1.69	Sedang	Sudah dimanfaatkan	Bulanan	Sepanjang tahun	3	Sintetis
KB-056	BAH-015	PAD-027	2025-08-01	930.00	kg	Cukup kontinu	2.57	Mudah	Dimanfaatkan sebagai pupuk	Musiman	Musim panen	6	Sintetis
KB-057	BAH-005	PAD-038	2025-09-01	1067.00	kg	Kontinu	0.68	Sulit	Belum dimanfaatkan	Harian	Musim tertentu	9	Sintetis
KB-058	BAH-012	PAD-049	2025-10-01	1204.00	kg	Tidak kontinu	6.00	Sedang	Sebagian dimanfaatkan	Mingguan	Sepanjang tahun	2	Sintetis
KB-059	BAH-002	PAD-060	2025-11-01	1341.00	kg	Musiman	3.83	Mudah	Sudah dimanfaatkan	Bulanan	Musim panen	5	Sintetis
KB-060	BAH-009	PAD-071	2025-12-01	1478.00	kg	Cukup kontinu	2.81	Sulit	Dimanfaatkan sebagai pupuk	Musiman	Musim tertentu	8	Sintetis
KB-061	BAH-016	PAD-009	2025-01-01	264.00	kg	Kontinu	3.91	Sedang	Belum dimanfaatkan	Harian	Sepanjang tahun	1	Sintetis
KB-062	BAH-006	PAD-020	2025-02-01	401.00	kg	Tidak kontinu	2.88	Mudah	Sebagian dimanfaatkan	Mingguan	Musim panen	4	Sintetis
KB-063	BAH-013	PAD-031	2025-03-01	538.00	kg	Musiman	1.98	Sulit	Sudah dimanfaatkan	Bulanan	Musim tertentu	7	Sintetis
KB-064	BAH-003	PAD-042	2025-04-01	675.00	kg	Cukup kontinu	0.98	Sedang	Dimanfaatkan sebagai pupuk	Musiman	Sepanjang tahun	10	Sintetis
KB-065	BAH-010	PAD-053	2025-05-01	812.00	kg	Kontinu	2.64	Mudah	Belum dimanfaatkan	Harian	Musim panen	3	Sintetis
KB-066	BAH-017	PAD-064	2025-06-01	949.00	kg	Tidak kontinu	2.14	Sulit	Sebagian dimanfaatkan	Mingguan	Musim tertentu	6	Sintetis
KB-067	BAH-007	PAD-002	2025-07-01	1086.00	kg	Musiman	1.53	Sedang	Sudah dimanfaatkan	Bulanan	Sepanjang tahun	9	Sintetis
KB-068	BAH-014	PAD-013	2025-08-01	1223.00	kg	Cukup kontinu	2.66	Mudah	Dimanfaatkan sebagai pupuk	Musiman	Musim panen	2	Sintetis
KB-069	BAH-004	PAD-024	2025-09-01	1360.00	kg	Kontinu	3.06	Sulit	Belum dimanfaatkan	Harian	Musim tertentu	5	Sintetis
KB-070	BAH-011	PAD-035	2025-10-01	1497.00	kg	Tidak kontinu	2.11	Sedang	Sebagian dimanfaatkan	Mingguan	Sepanjang tahun	8	Sintetis
KB-071	BAH-001	PAD-046	2025-11-01	283.00	kg	Musiman	2.42	Mudah	Sudah dimanfaatkan	Bulanan	Musim panen	1	Sintetis
KB-072	BAH-008	PAD-057	2025-12-01	420.00	kg	Cukup kontinu	2.03	Sulit	Dimanfaatkan sebagai pupuk	Musiman	Musim tertentu	4	Sintetis
KB-073	BAH-015	PAD-068	2025-01-01	557.00	kg	Kontinu	3.17	Sedang	Belum dimanfaatkan	Harian	Sepanjang tahun	7	Sintetis
KB-074	BAH-005	PAD-006	2025-02-01	694.00	kg	Tidak kontinu	3.35	Mudah	Sebagian dimanfaatkan	Mingguan	Musim panen	10	Sintetis
KB-075	BAH-012	PAD-017	2025-03-01	831.00	kg	Musiman	2.70	Sulit	Sudah dimanfaatkan	Bulanan	Musim tertentu	3	Sintetis
KB-076	BAH-002	PAD-028	2025-04-01	968.00	kg	Cukup kontinu	1.55	Sedang	Dimanfaatkan sebagai pupuk	Musiman	Sepanjang tahun	6	Sintetis
KB-077	BAH-009	PAD-039	2025-05-01	1105.00	kg	Kontinu	0.64	Mudah	Belum dimanfaatkan	Harian	Musim panen	9	Sintetis
KB-078	BAH-016	PAD-050	2025-06-01	1242.00	kg	Tidak kontinu	3.76	Sulit	Sebagian dimanfaatkan	Mingguan	Musim tertentu	2	Sintetis
KB-079	BAH-006	PAD-061	2025-07-01	1379.00	kg	Musiman	2.94	Sedang	Sudah dimanfaatkan	Bulanan	Sepanjang tahun	5	Sintetis
KB-080	BAH-013	PAD-072	2025-08-01	165.00	kg	Cukup kontinu	1.83	Mudah	Dimanfaatkan sebagai pupuk	Musiman	Musim panen	8	Sintetis
KB-081	BAH-003	PAD-010	2025-09-01	302.00	kg	Kontinu	3.90	Sulit	Belum dimanfaatkan	Harian	Musim tertentu	1	Sintetis
KB-082	BAH-010	PAD-021	2025-10-01	439.00	kg	Tidak kontinu	2.36	Sedang	Sebagian dimanfaatkan	Mingguan	Sepanjang tahun	4	Sintetis
KB-083	BAH-017	PAD-032	2025-11-01	576.00	kg	Musiman	2.27	Mudah	Sudah dimanfaatkan	Bulanan	Musim panen	7	Sintetis
KB-084	BAH-007	PAD-043	2025-12-01	713.00	kg	Cukup kontinu	1.14	Sulit	Dimanfaatkan sebagai pupuk	Musiman	Musim tertentu	10	Sintetis
KB-085	BAH-014	PAD-054	2025-01-01	850.00	kg	Kontinu	1.62	Sedang	Belum dimanfaatkan	Harian	Sepanjang tahun	3	Sintetis
KB-086	BAH-004	PAD-065	2025-02-01	987.00	kg	Tidak kontinu	6.87	Mudah	Sebagian dimanfaatkan	Mingguan	Musim panen	6	Sintetis
KB-087	BAH-011	PAD-003	2025-03-01	1124.00	kg	Musiman	2.33	Sulit	Sudah dimanfaatkan	Bulanan	Musim tertentu	9	Sintetis
KB-088	BAH-001	PAD-014	2025-04-01	1261.00	kg	Cukup kontinu	2.24	Sedang	Dimanfaatkan sebagai pupuk	Musiman	Sepanjang tahun	2	Sintetis
\.


--
-- Data for Name: padukuhan; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.padukuhan (padukuhan_id, kalurahan_id, kalurahan, padukuhan, jumlah_rt, jumlah_rw, latitude, longitude) FROM stdin;
PAD-001	KAL-001	Argomulyo	Randusari	5	2	-7.6799630	110.4491060
PAD-002	KAL-001	Argomulyo	Kuwang	5	2	-7.6593000	110.4563000
PAD-003	KAL-001	Argomulyo	Panggung	4	2	-7.6666700	110.4555600
PAD-004	KAL-001	Argomulyo	Kliwang	4	2	-7.6697220	110.4561110
PAD-005	KAL-001	Argomulyo	Teplok	4	2	-7.6696660	110.4542510
PAD-006	KAL-001	Argomulyo	Kebur Lor	4	2	-7.6758330	110.4561110
PAD-007	KAL-001	Argomulyo	Kebur Kidul	4	2	-7.6775000	110.4575000
PAD-008	KAL-001	Argomulyo	Sewon	4	2	-7.6850000	110.4647220
PAD-009	KAL-001	Argomulyo	Brongkol	4	2	-7.6784000	110.4665000
PAD-010	KAL-001	Argomulyo	Cangkringan	4	2	-7.6800000	110.4611000
PAD-011	KAL-001	Argomulyo	Jaranan	4	2	-7.6730600	110.4647200
PAD-012	KAL-001	Argomulyo	Karanglo	4	2	-7.6702780	110.4630560
PAD-013	KAL-001	Argomulyo	Jetis	4	2	-7.6677000	110.4629000
PAD-014	KAL-001	Argomulyo	Suruh	5	2	-7.6647800	110.4600100
PAD-015	KAL-001	Argomulyo	Bakalan	4	2	-7.6562400	110.4620000
PAD-016	KAL-001	Argomulyo	Gadingan	4	2	-7.6554700	110.4650300
PAD-017	KAL-001	Argomulyo	Banaran	4	2	-7.6661000	110.4666000
PAD-018	KAL-001	Argomulyo	Kauman	4	2	-7.6669440	110.4725000
PAD-019	KAL-001	Argomulyo	Jiwan	4	2	-7.6638000	110.4700000
PAD-020	KAL-001	Argomulyo	Dliring	4	2	-7.6642000	110.4715000
PAD-021	KAL-001	Argomulyo	Gayam	4	2	-7.6596000	110.4694000
PAD-022	KAL-001	Argomulyo	Mudal	5	2	-7.6530600	110.4702800
PAD-023	KAL-002	Wukirsari	Karangpakis	4	1	-7.6677800	110.4336100
PAD-024	KAL-002	Wukirsari	Glagahwero	4	2	-7.6680600	110.4366700
PAD-025	KAL-002	Wukirsari	Pusmalang	6	2	-7.6725000	110.4402800
PAD-026	KAL-002	Wukirsari	Sruni	6	3	-7.6666700	110.4422200
PAD-027	KAL-002	Wukirsari	Sintokan	4	2	-7.6650000	110.4400000
PAD-028	KAL-002	Wukirsari	Rejosari	4	2	-7.6577800	110.4458300
PAD-029	KAL-002	Wukirsari	Sempon	4	2	-7.6597200	110.4475000
PAD-030	KAL-002	Wukirsari	Ngemplak	4	2	-7.6577800	110.4502800
PAD-031	KAL-002	Wukirsari	Kiyaran	6	3	-7.6583300	110.4402800
PAD-032	KAL-002	Wukirsari	Sembungan	4	2	-7.6586100	110.4369400
PAD-033	KAL-002	Wukirsari	Tanjung	4	2	-7.6525000	110.4352800
PAD-034	KAL-002	Wukirsari	Bedoyo	4	2	-7.6458300	110.4333300
PAD-035	KAL-002	Wukirsari	Selorejo	4	2	-7.6537900	110.4357200
PAD-036	KAL-002	Wukirsari	Plupuh	4	2	-7.6486100	110.4436100
PAD-037	KAL-002	Wukirsari	Kregan	4	2	-7.6416700	110.4480600
PAD-038	KAL-002	Wukirsari	Salam Krajan	4	2	-7.6519400	110.4538900
PAD-039	KAL-002	Wukirsari	Cakran	4	2	-7.6508300	110.4561100
PAD-040	KAL-002	Wukirsari	Duwet	4	2	-7.6483300	110.4566700
PAD-041	KAL-002	Wukirsari	Gungan	4	2	-7.6441700	110.4572200
PAD-042	KAL-002	Wukirsari	Ngepringan	4	2	-7.6450000	110.4619400
PAD-043	KAL-002	Wukirsari	Gondang	3	1	-7.6472200	110.4633300
PAD-044	KAL-002	Wukirsari	Bulaksalak	4	2	-7.6491700	110.4475000
PAD-045	KAL-002	Wukirsari	Surodadi	4	2	-7.6605600	110.4527800
PAD-046	KAL-002	Wukirsari	Cangcangan	4	2	-7.6375000	110.4327800
PAD-047	KAL-003	Glagaharjo	Kalitengah Lor	4	2	-7.5851700	110.4566700
PAD-048	KAL-003	Glagaharjo	Kalitengah Kidul	4	2	-7.5919400	110.4577800
PAD-049	KAL-003	Glagaharjo	Srunen	4	2	-7.5919560	110.4552560
PAD-050	KAL-003	Glagaharjo	Singlar	4	2	-7.6128541	110.4604695
PAD-051	KAL-003	Glagaharjo	Gading	4	2	-7.6172000	110.4644000
PAD-052	KAL-003	Glagaharjo	Glagah Malang	4	2	-7.6491000	110.4578000
PAD-053	KAL-003	Glagaharjo	Jetis Sumur	4	2	-7.6267000	110.4672000
PAD-054	KAL-003	Glagaharjo	Ngancar	5	2	-7.6397220	110.4663890
PAD-055	KAL-003	Glagaharjo	Banjarsari	4	2	-7.6461000	110.4692000
PAD-056	KAL-003	Glagaharjo	Besalen	4	2	-7.6502780	110.4663890
PAD-057	KAL-004	Kepuharjo	Kaliadem	4	2	-7.6288000	110.4466100
PAD-058	KAL-004	Kepuharjo	Jambu	4	2	-7.6148000	110.4552000
PAD-059	KAL-004	Kepuharjo	Petung	4	2	-7.6022000	110.4479000
PAD-060	KAL-004	Kepuharjo	Kopeng	5	2	-7.6113890	110.4536110
PAD-061	KAL-004	Kepuharjo	Batur	4	2	-7.6195020	110.4547410
PAD-062	KAL-004	Kepuharjo	Pagerjurang	4	2	-7.6294440	110.4475000
PAD-063	KAL-004	Kepuharjo	Kepuh	4	2	-7.6227780	110.4530560
PAD-064	KAL-004	Kepuharjo	Manggong	4	2	-7.6274900	110.4474400
PAD-065	KAL-005	Umbulharjo	Pelemsari	4	2	-7.5850000	110.4422220
PAD-066	KAL-005	Umbulharjo	Pangukrejo	6	3	-7.5734000	110.4461000
PAD-067	KAL-005	Umbulharjo	Gondang	4	2	-7.6230710	110.4432440
PAD-068	KAL-005	Umbulharjo	Gambretan	6	3	-7.6255000	110.4330000
PAD-069	KAL-005	Umbulharjo	Balong	4	2	-7.6217000	110.4333000
PAD-070	KAL-005	Umbulharjo	Plosorejo	4	2	-7.6250000	110.4356000
PAD-071	KAL-005	Umbulharjo	Karanggeneng	4	2	-7.6302800	110.4330600
PAD-072	KAL-005	Umbulharjo	Plosokerep	4	2	-7.6316670	110.4447220
PAD-073	KAL-005	Umbulharjo	Pentingsari	4	2	-7.6250000	110.4260000
\.


--
-- Data for Name: penjualan; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.penjualan (penjualan_id, produk_id, bulan, produk, jumlah_terjual, harga_satuan, total_penjualan, satuan, kanal, status_data) FROM stdin;
SALE-0001	PRD-001	2020-01-01	Probiotik GB Proquatic	10.00	45000.00	450000.00	Liter	Shopee	Sintetis
SALE-0002	PRD-001	2020-02-01	Probiotik GB Proquatic	13.00	45000.00	585000.00	Liter	Shopee	Sintetis
SALE-0003	PRD-001	2020-03-01	Probiotik GB Proquatic	14.00	45000.00	630000.00	Liter	Shopee	Sintetis
SALE-0004	PRD-001	2020-04-01	Probiotik GB Proquatic	13.00	45000.00	585000.00	Liter	Shopee	Sintetis
SALE-0005	PRD-001	2020-05-01	Probiotik GB Proquatic	15.00	45000.00	675000.00	Liter	Shopee	Sintetis
SALE-0006	PRD-001	2020-06-01	Probiotik GB Proquatic	13.00	45000.00	585000.00	Liter	Shopee	Sintetis
SALE-0007	PRD-001	2020-07-01	Probiotik GB Proquatic	14.00	45000.00	630000.00	Liter	Shopee	Sintetis
SALE-0008	PRD-001	2020-08-01	Probiotik GB Proquatic	20.00	45000.00	900000.00	Liter	Shopee	Sintetis
SALE-0009	PRD-001	2020-09-01	Probiotik GB Proquatic	13.00	45000.00	585000.00	Liter	Shopee	Sintetis
SALE-0010	PRD-001	2020-10-01	Probiotik GB Proquatic	25.00	45000.00	1125000.00	Liter	Shopee	Sintetis
SALE-0011	PRD-001	2020-11-01	Probiotik GB Proquatic	27.00	45000.00	1215000.00	Liter	Shopee	Sintetis
SALE-0012	PRD-001	2020-12-01	Probiotik GB Proquatic	14.00	45000.00	630000.00	Liter	Shopee	Sintetis
SALE-0013	PRD-002	2020-01-01	Probiotik GB Propunic	3.00	45500.00	136500.00	Liter	Shopee	Sintetis
SALE-0014	PRD-002	2020-02-01	Probiotik GB Propunic	2.00	45500.00	91000.00	Liter	Shopee	Sintetis
SALE-0015	PRD-002	2020-03-01	Probiotik GB Propunic	3.00	45500.00	136500.00	Liter	Shopee	Sintetis
SALE-0016	PRD-002	2020-04-01	Probiotik GB Propunic	3.00	45500.00	136500.00	Liter	Shopee	Sintetis
SALE-0017	PRD-002	2020-05-01	Probiotik GB Propunic	5.00	45500.00	227500.00	Liter	Shopee	Sintetis
SALE-0018	PRD-002	2020-06-01	Probiotik GB Propunic	2.00	45500.00	91000.00	Liter	Shopee	Sintetis
SALE-0019	PRD-002	2020-07-01	Probiotik GB Propunic	3.00	45500.00	136500.00	Liter	Shopee	Sintetis
SALE-0020	PRD-002	2020-08-01	Probiotik GB Propunic	2.00	45500.00	91000.00	Liter	Shopee	Sintetis
SALE-0021	PRD-002	2020-09-01	Probiotik GB Propunic	3.00	45500.00	136500.00	Liter	Shopee	Sintetis
SALE-0022	PRD-002	2020-10-01	Probiotik GB Propunic	5.00	45500.00	227500.00	Liter	Shopee	Sintetis
SALE-0023	PRD-002	2020-11-01	Probiotik GB Propunic	3.00	45500.00	136500.00	Liter	Shopee	Sintetis
SALE-0024	PRD-002	2020-12-01	Probiotik GB Propunic	3.00	45500.00	136500.00	Liter	Shopee	Sintetis
SALE-0025	PRD-003	2020-01-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	7.00	45000.00	315000.00	Liter	Shopee	Sintetis
SALE-0026	PRD-003	2020-02-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	6.00	45000.00	270000.00	Liter	Shopee	Sintetis
SALE-0027	PRD-003	2020-03-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	7.00	45000.00	315000.00	Liter	Shopee	Sintetis
SALE-0028	PRD-003	2020-04-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	10.00	45000.00	450000.00	Liter	Shopee	Sintetis
SALE-0029	PRD-003	2020-05-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	7.00	45000.00	315000.00	Liter	Shopee	Sintetis
SALE-0030	PRD-003	2020-06-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	6.00	45000.00	270000.00	Liter	Shopee	Sintetis
SALE-0031	PRD-003	2020-07-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	7.00	45000.00	315000.00	Liter	Shopee	Sintetis
SALE-0032	PRD-003	2020-08-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	6.00	45000.00	270000.00	Liter	Shopee	Sintetis
SALE-0033	PRD-003	2020-09-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	7.00	45000.00	315000.00	Liter	Shopee	Sintetis
SALE-0034	PRD-003	2020-10-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	7.00	45000.00	315000.00	Liter	Shopee	Sintetis
SALE-0035	PRD-003	2020-11-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	7.00	45000.00	315000.00	Liter	Shopee	Sintetis
SALE-0036	PRD-003	2020-12-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	10.00	45000.00	450000.00	Liter	Shopee	Sintetis
SALE-0037	PRD-004	2020-01-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	1.00	36000.00	36000.00	Zak	Shopee	Sintetis
SALE-0038	PRD-004	2020-02-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0039	PRD-004	2020-03-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	1.00	36000.00	36000.00	Zak	Shopee	Sintetis
SALE-0040	PRD-004	2020-04-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0041	PRD-004	2020-05-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	1.00	36000.00	36000.00	Zak	Shopee	Sintetis
SALE-0042	PRD-004	2020-06-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0043	PRD-004	2020-07-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	1.00	36000.00	36000.00	Zak	Shopee	Sintetis
SALE-0044	PRD-004	2020-08-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0045	PRD-004	2020-09-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	1.00	36000.00	36000.00	Zak	Shopee	Sintetis
SALE-0046	PRD-004	2020-10-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	1.00	36000.00	36000.00	Zak	Shopee	Sintetis
SALE-0047	PRD-004	2020-11-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	1.00	36000.00	36000.00	Zak	Shopee	Sintetis
SALE-0048	PRD-004	2020-12-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	1.00	36000.00	36000.00	Zak	Shopee	Sintetis
SALE-0049	PRD-005	2020-01-01	Tricogem Fungisida Organik	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0050	PRD-005	2020-02-01	Tricogem Fungisida Organik	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0051	PRD-005	2020-03-01	Tricogem Fungisida Organik	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0052	PRD-005	2020-04-01	Tricogem Fungisida Organik	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0053	PRD-005	2020-05-01	Tricogem Fungisida Organik	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0054	PRD-005	2020-06-01	Tricogem Fungisida Organik	2.00	30000.00	60000.00	Gram	Shopee	Sintetis
SALE-0055	PRD-005	2020-07-01	Tricogem Fungisida Organik	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0056	PRD-005	2020-08-01	Tricogem Fungisida Organik	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0057	PRD-005	2020-09-01	Tricogem Fungisida Organik	2.00	30000.00	60000.00	Gram	Shopee	Sintetis
SALE-0058	PRD-005	2020-10-01	Tricogem Fungisida Organik	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0059	PRD-005	2020-11-01	Tricogem Fungisida Organik	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0060	PRD-005	2020-12-01	Tricogem Fungisida Organik	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0061	PRD-006	2020-01-01	Pendawa Subur Pertumbuhan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0062	PRD-006	2020-02-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0063	PRD-006	2020-03-01	Pendawa Subur Pertumbuhan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0064	PRD-006	2020-04-01	Pendawa Subur Pertumbuhan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0065	PRD-006	2020-05-01	Pendawa Subur Pertumbuhan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0066	PRD-006	2020-06-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0067	PRD-006	2020-07-01	Pendawa Subur Pertumbuhan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0068	PRD-006	2020-08-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0069	PRD-006	2020-09-01	Pendawa Subur Pertumbuhan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0070	PRD-006	2020-10-01	Pendawa Subur Pertumbuhan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0071	PRD-006	2020-11-01	Pendawa Subur Pertumbuhan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0072	PRD-006	2020-12-01	Pendawa Subur Pertumbuhan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0073	PRD-007	2020-01-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0074	PRD-007	2020-02-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0075	PRD-007	2020-03-01	Beva Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0076	PRD-007	2020-04-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0077	PRD-007	2020-05-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0078	PRD-007	2020-06-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0079	PRD-007	2020-07-01	Beva Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0080	PRD-007	2020-08-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0081	PRD-007	2020-09-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0082	PRD-007	2020-10-01	Beva Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0083	PRD-007	2020-11-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0084	PRD-007	2020-12-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0085	PRD-008	2020-01-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0086	PRD-008	2020-02-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0087	PRD-008	2020-03-01	Metha Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0088	PRD-008	2020-04-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0089	PRD-008	2020-05-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0090	PRD-008	2020-06-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0091	PRD-008	2020-07-01	Metha Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0092	PRD-008	2020-08-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0093	PRD-008	2020-09-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0094	PRD-008	2020-10-01	Metha Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0095	PRD-008	2020-11-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0096	PRD-008	2020-12-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0097	PRD-009	2020-01-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0098	PRD-009	2020-02-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0099	PRD-009	2020-03-01	Pestisida Organik Pendawa Ampuh	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0100	PRD-009	2020-04-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0101	PRD-009	2020-05-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0102	PRD-009	2020-06-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0103	PRD-009	2020-07-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0104	PRD-009	2020-08-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0105	PRD-009	2020-09-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0106	PRD-009	2020-10-01	Pestisida Organik Pendawa Ampuh	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0107	PRD-009	2020-11-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0108	PRD-009	2020-12-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0109	PRD-010	2020-01-01	Pendawa Subur Pembungaan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0110	PRD-010	2020-02-01	Pendawa Subur Pembungaan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0111	PRD-010	2020-03-01	Pendawa Subur Pembungaan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0112	PRD-010	2020-04-01	Pendawa Subur Pembungaan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0113	PRD-010	2020-05-01	Pendawa Subur Pembungaan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0114	PRD-010	2020-06-01	Pendawa Subur Pembungaan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0115	PRD-010	2020-07-01	Pendawa Subur Pembungaan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0116	PRD-010	2020-08-01	Pendawa Subur Pembungaan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0117	PRD-010	2020-09-01	Pendawa Subur Pembungaan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0118	PRD-010	2020-10-01	Pendawa Subur Pembungaan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0119	PRD-010	2020-11-01	Pendawa Subur Pembungaan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0120	PRD-010	2020-12-01	Pendawa Subur Pembungaan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0121	PRD-011	2020-01-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0122	PRD-011	2020-02-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0123	PRD-011	2020-03-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0124	PRD-011	2020-04-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0125	PRD-011	2020-05-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0126	PRD-011	2020-06-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0127	PRD-011	2020-07-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0128	PRD-011	2020-08-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0129	PRD-011	2020-09-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0130	PRD-011	2020-10-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0131	PRD-011	2020-11-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0132	PRD-011	2020-12-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0133	PRD-001	2021-01-01	Probiotik GB Proquatic	16.00	45000.00	720000.00	Liter	Shopee	Sintetis
SALE-0134	PRD-001	2021-02-01	Probiotik GB Proquatic	9.00	45000.00	405000.00	Liter	Shopee	Sintetis
SALE-0135	PRD-001	2021-03-01	Probiotik GB Proquatic	17.00	45000.00	765000.00	Liter	Shopee	Sintetis
SALE-0136	PRD-001	2021-04-01	Probiotik GB Proquatic	16.00	45000.00	720000.00	Liter	Shopee	Sintetis
SALE-0137	PRD-001	2021-05-01	Probiotik GB Proquatic	9.00	45000.00	405000.00	Liter	Shopee	Sintetis
SALE-0138	PRD-001	2021-06-01	Probiotik GB Proquatic	23.00	45000.00	1035000.00	Liter	Shopee	Sintetis
SALE-0139	PRD-001	2021-07-01	Probiotik GB Proquatic	35.00	45000.00	1575000.00	Liter	Shopee	Sintetis
SALE-0140	PRD-001	2021-08-01	Probiotik GB Proquatic	7.00	45000.00	315000.00	Liter	Shopee	Sintetis
SALE-0141	PRD-001	2021-09-01	Probiotik GB Proquatic	15.00	45000.00	675000.00	Liter	Shopee	Sintetis
SALE-0142	PRD-001	2021-10-01	Probiotik GB Proquatic	20.00	45000.00	900000.00	Liter	Shopee	Sintetis
SALE-0143	PRD-001	2021-11-01	Probiotik GB Proquatic	27.00	45000.00	1215000.00	Liter	Shopee	Sintetis
SALE-0144	PRD-001	2021-12-01	Probiotik GB Proquatic	17.00	45000.00	765000.00	Liter	Shopee	Sintetis
SALE-0145	PRD-002	2021-01-01	Probiotik GB Propunic	1.00	45500.00	45500.00	Liter	Shopee	Sintetis
SALE-0146	PRD-002	2021-02-01	Probiotik GB Propunic	2.00	45500.00	91000.00	Liter	Shopee	Sintetis
SALE-0147	PRD-002	2021-03-01	Probiotik GB Propunic	6.00	45500.00	273000.00	Liter	Shopee	Sintetis
SALE-0148	PRD-002	2021-04-01	Probiotik GB Propunic	4.00	45500.00	182000.00	Liter	Shopee	Sintetis
SALE-0149	PRD-002	2021-05-01	Probiotik GB Propunic	1.00	45500.00	45500.00	Liter	Shopee	Sintetis
SALE-0150	PRD-002	2021-06-01	Probiotik GB Propunic	1.00	45500.00	45500.00	Liter	Shopee	Sintetis
SALE-0151	PRD-002	2021-07-01	Probiotik GB Propunic	1.00	45500.00	45500.00	Liter	Shopee	Sintetis
SALE-0152	PRD-002	2021-08-01	Probiotik GB Propunic	4.00	45500.00	182000.00	Liter	Shopee	Sintetis
SALE-0153	PRD-002	2021-09-01	Probiotik GB Propunic	3.00	45500.00	136500.00	Liter	Shopee	Sintetis
SALE-0154	PRD-002	2021-10-01	Probiotik GB Propunic	6.00	45500.00	273000.00	Liter	Shopee	Sintetis
SALE-0155	PRD-002	2021-11-01	Probiotik GB Propunic	4.00	45500.00	182000.00	Liter	Shopee	Sintetis
SALE-0156	PRD-002	2021-12-01	Probiotik GB Propunic	9.00	45500.00	409500.00	Liter	Shopee	Sintetis
SALE-0157	PRD-003	2021-01-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	12.00	45000.00	540000.00	Liter	Shopee	Sintetis
SALE-0158	PRD-003	2021-02-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	6.00	45000.00	270000.00	Liter	Shopee	Sintetis
SALE-0159	PRD-003	2021-03-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	7.00	45000.00	315000.00	Liter	Shopee	Sintetis
SALE-0160	PRD-003	2021-04-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	6.00	45000.00	270000.00	Liter	Shopee	Sintetis
SALE-0161	PRD-003	2021-05-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	14.00	45000.00	630000.00	Liter	Shopee	Sintetis
SALE-0162	PRD-003	2021-06-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	16.00	45000.00	720000.00	Liter	Shopee	Sintetis
SALE-0163	PRD-003	2021-07-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	8.00	45000.00	360000.00	Liter	Shopee	Sintetis
SALE-0164	PRD-003	2021-08-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	10.00	45000.00	450000.00	Liter	Shopee	Sintetis
SALE-0165	PRD-003	2021-09-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	10.00	45000.00	450000.00	Liter	Shopee	Sintetis
SALE-0166	PRD-003	2021-10-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	3.00	45000.00	135000.00	Liter	Shopee	Sintetis
SALE-0167	PRD-003	2021-11-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	3.00	45000.00	135000.00	Liter	Shopee	Sintetis
SALE-0168	PRD-003	2021-12-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	5.00	45000.00	225000.00	Liter	Shopee	Sintetis
SALE-0169	PRD-004	2021-01-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	2.00	36000.00	72000.00	Zak	Shopee	Sintetis
SALE-0170	PRD-004	2021-02-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	2.00	36000.00	72000.00	Zak	Shopee	Sintetis
SALE-0171	PRD-004	2021-03-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0172	PRD-004	2021-04-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0173	PRD-004	2021-05-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0174	PRD-004	2021-06-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	2.00	36000.00	72000.00	Zak	Shopee	Sintetis
SALE-0175	PRD-004	2021-07-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0176	PRD-004	2021-08-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	1.00	36000.00	36000.00	Zak	Shopee	Sintetis
SALE-0177	PRD-004	2021-09-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	2.00	36000.00	72000.00	Zak	Shopee	Sintetis
SALE-0178	PRD-004	2021-10-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0179	PRD-004	2021-11-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0180	PRD-004	2021-12-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	1.00	36000.00	36000.00	Zak	Shopee	Sintetis
SALE-0181	PRD-005	2021-01-01	Tricogem Fungisida Organik	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0182	PRD-005	2021-02-01	Tricogem Fungisida Organik	2.00	30000.00	60000.00	Gram	Shopee	Sintetis
SALE-0183	PRD-005	2021-03-01	Tricogem Fungisida Organik	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0184	PRD-005	2021-04-01	Tricogem Fungisida Organik	2.00	30000.00	60000.00	Gram	Shopee	Sintetis
SALE-0185	PRD-005	2021-05-01	Tricogem Fungisida Organik	2.00	30000.00	60000.00	Gram	Shopee	Sintetis
SALE-0186	PRD-005	2021-06-01	Tricogem Fungisida Organik	2.00	30000.00	60000.00	Gram	Shopee	Sintetis
SALE-0187	PRD-005	2021-07-01	Tricogem Fungisida Organik	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0188	PRD-005	2021-08-01	Tricogem Fungisida Organik	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0189	PRD-005	2021-09-01	Tricogem Fungisida Organik	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0190	PRD-005	2021-10-01	Tricogem Fungisida Organik	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0191	PRD-005	2021-11-01	Tricogem Fungisida Organik	3.00	30000.00	90000.00	Gram	Shopee	Sintetis
SALE-0192	PRD-005	2021-12-01	Tricogem Fungisida Organik	4.00	30000.00	120000.00	Gram	Shopee	Sintetis
SALE-0193	PRD-006	2021-01-01	Pendawa Subur Pertumbuhan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0194	PRD-006	2021-02-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0195	PRD-006	2021-03-01	Pendawa Subur Pertumbuhan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0196	PRD-006	2021-04-01	Pendawa Subur Pertumbuhan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0197	PRD-006	2021-05-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0198	PRD-006	2021-06-01	Pendawa Subur Pertumbuhan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0199	PRD-006	2021-07-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0200	PRD-006	2021-08-01	Pendawa Subur Pertumbuhan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0201	PRD-006	2021-09-01	Pendawa Subur Pertumbuhan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0202	PRD-006	2021-10-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0203	PRD-006	2021-11-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0204	PRD-006	2021-12-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0205	PRD-007	2021-01-01	Beva Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0206	PRD-007	2021-02-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0207	PRD-007	2021-03-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0208	PRD-007	2021-04-01	Beva Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0209	PRD-007	2021-05-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0210	PRD-007	2021-06-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0211	PRD-007	2021-07-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0212	PRD-007	2021-08-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0213	PRD-007	2021-09-01	Beva Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0214	PRD-007	2021-10-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0215	PRD-007	2021-11-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0216	PRD-007	2021-12-01	Beva Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0217	PRD-008	2021-01-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0218	PRD-008	2021-02-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0219	PRD-008	2021-03-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0220	PRD-008	2021-04-01	Metha Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0221	PRD-008	2021-05-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0222	PRD-008	2021-06-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0223	PRD-008	2021-07-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0224	PRD-008	2021-08-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0225	PRD-008	2021-09-01	Metha Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0226	PRD-008	2021-10-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0227	PRD-008	2021-11-01	Metha Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0228	PRD-008	2021-12-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0229	PRD-009	2021-01-01	Pestisida Organik Pendawa Ampuh	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0230	PRD-009	2021-02-01	Pestisida Organik Pendawa Ampuh	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0231	PRD-009	2021-03-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0232	PRD-009	2021-04-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0233	PRD-009	2021-05-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0234	PRD-009	2021-06-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0235	PRD-009	2021-07-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0236	PRD-009	2021-08-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0237	PRD-009	2021-09-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0238	PRD-009	2021-10-01	Pestisida Organik Pendawa Ampuh	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0239	PRD-009	2021-11-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0240	PRD-009	2021-12-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0241	PRD-010	2021-01-01	Pendawa Subur Pembungaan	3.00	49500.00	148500.00	Liter	Shopee	Sintetis
SALE-0242	PRD-010	2021-02-01	Pendawa Subur Pembungaan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0243	PRD-010	2021-03-01	Pendawa Subur Pembungaan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0244	PRD-010	2021-04-01	Pendawa Subur Pembungaan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0245	PRD-010	2021-05-01	Pendawa Subur Pembungaan	3.00	49500.00	148500.00	Liter	Shopee	Sintetis
SALE-0246	PRD-010	2021-06-01	Pendawa Subur Pembungaan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0247	PRD-010	2021-07-01	Pendawa Subur Pembungaan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0248	PRD-010	2021-08-01	Pendawa Subur Pembungaan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0249	PRD-010	2021-09-01	Pendawa Subur Pembungaan	4.00	49500.00	198000.00	Liter	Shopee	Sintetis
SALE-0250	PRD-010	2021-10-01	Pendawa Subur Pembungaan	3.00	49500.00	148500.00	Liter	Shopee	Sintetis
SALE-0251	PRD-010	2021-11-01	Pendawa Subur Pembungaan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0252	PRD-010	2021-12-01	Pendawa Subur Pembungaan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0253	PRD-011	2021-01-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0254	PRD-011	2021-02-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0255	PRD-011	2021-03-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0256	PRD-011	2021-04-01	Pendawa Subur Tunas (ZpT) Organik	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0257	PRD-011	2021-05-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0258	PRD-011	2021-06-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0259	PRD-011	2021-07-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0260	PRD-011	2021-08-01	Pendawa Subur Tunas (ZpT) Organik	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0261	PRD-011	2021-09-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0262	PRD-011	2021-10-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0263	PRD-011	2021-11-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0264	PRD-011	2021-12-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0265	PRD-001	2022-01-01	Probiotik GB Proquatic	60.00	45000.00	2700000.00	Liter	Shopee	Sintetis
SALE-0266	PRD-001	2022-02-01	Probiotik GB Proquatic	40.00	45000.00	1800000.00	Liter	Shopee	Sintetis
SALE-0267	PRD-001	2022-03-01	Probiotik GB Proquatic	19.00	45000.00	855000.00	Liter	Shopee	Sintetis
SALE-0268	PRD-001	2022-04-01	Probiotik GB Proquatic	10.00	45000.00	450000.00	Liter	Shopee	Sintetis
SALE-0601	PRD-007	2024-01-01	Beva Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0269	PRD-001	2022-05-01	Probiotik GB Proquatic	38.00	45000.00	1710000.00	Liter	Shopee	Sintetis
SALE-0270	PRD-001	2022-06-01	Probiotik GB Proquatic	10.00	45000.00	450000.00	Liter	Shopee	Sintetis
SALE-0271	PRD-001	2022-07-01	Probiotik GB Proquatic	33.00	45000.00	1485000.00	Liter	Shopee	Sintetis
SALE-0272	PRD-001	2022-08-01	Probiotik GB Proquatic	6.00	45000.00	270000.00	Liter	Shopee	Sintetis
SALE-0273	PRD-001	2022-09-01	Probiotik GB Proquatic	45.00	45000.00	2025000.00	Liter	Shopee	Sintetis
SALE-0274	PRD-001	2022-10-01	Probiotik GB Proquatic	20.00	45000.00	900000.00	Liter	Shopee	Sintetis
SALE-0275	PRD-001	2022-11-01	Probiotik GB Proquatic	50.00	45000.00	2250000.00	Liter	Shopee	Sintetis
SALE-0276	PRD-001	2022-12-01	Probiotik GB Proquatic	17.00	45000.00	765000.00	Liter	Shopee	Sintetis
SALE-0277	PRD-002	2022-01-01	Probiotik GB Propunic	2.00	45500.00	91000.00	Liter	Shopee	Sintetis
SALE-0278	PRD-002	2022-02-01	Probiotik GB Propunic	1.00	45500.00	45500.00	Liter	Shopee	Sintetis
SALE-0279	PRD-002	2022-03-01	Probiotik GB Propunic	2.00	45500.00	91000.00	Liter	Shopee	Sintetis
SALE-0280	PRD-002	2022-04-01	Probiotik GB Propunic	1.00	45500.00	45500.00	Liter	Shopee	Sintetis
SALE-0281	PRD-002	2022-05-01	Probiotik GB Propunic	5.00	45500.00	227500.00	Liter	Shopee	Sintetis
SALE-0282	PRD-002	2022-06-01	Probiotik GB Propunic	4.00	45500.00	182000.00	Liter	Shopee	Sintetis
SALE-0283	PRD-002	2022-07-01	Probiotik GB Propunic	1.00	45500.00	45500.00	Liter	Shopee	Sintetis
SALE-0284	PRD-002	2022-08-01	Probiotik GB Propunic	15.00	45500.00	682500.00	Liter	Shopee	Sintetis
SALE-0285	PRD-002	2022-09-01	Probiotik GB Propunic	7.00	45500.00	318500.00	Liter	Shopee	Sintetis
SALE-0286	PRD-002	2022-10-01	Probiotik GB Propunic	1.00	45500.00	45500.00	Liter	Shopee	Sintetis
SALE-0287	PRD-002	2022-11-01	Probiotik GB Propunic	17.00	45500.00	773500.00	Liter	Shopee	Sintetis
SALE-0288	PRD-002	2022-12-01	Probiotik GB Propunic	3.00	45500.00	136500.00	Liter	Shopee	Sintetis
SALE-0289	PRD-003	2022-01-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	21.00	45000.00	945000.00	Liter	Shopee	Sintetis
SALE-0290	PRD-003	2022-02-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	3.00	45000.00	135000.00	Liter	Shopee	Sintetis
SALE-0291	PRD-003	2022-03-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	30.00	45000.00	1350000.00	Liter	Shopee	Sintetis
SALE-0292	PRD-003	2022-04-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	2.00	45000.00	90000.00	Liter	Shopee	Sintetis
SALE-0293	PRD-003	2022-05-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	25.00	45000.00	1125000.00	Liter	Shopee	Sintetis
SALE-0294	PRD-003	2022-06-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	12.00	45000.00	540000.00	Liter	Shopee	Sintetis
SALE-0295	PRD-003	2022-07-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	14.00	45000.00	630000.00	Liter	Shopee	Sintetis
SALE-0296	PRD-003	2022-08-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	10.00	45000.00	450000.00	Liter	Shopee	Sintetis
SALE-0297	PRD-003	2022-09-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	9.00	45000.00	405000.00	Liter	Shopee	Sintetis
SALE-0298	PRD-003	2022-10-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	7.00	45000.00	315000.00	Liter	Shopee	Sintetis
SALE-0299	PRD-003	2022-11-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	13.00	45000.00	585000.00	Liter	Shopee	Sintetis
SALE-0300	PRD-003	2022-12-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	7.00	45000.00	315000.00	Liter	Shopee	Sintetis
SALE-0301	PRD-004	2022-01-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	1.00	36000.00	36000.00	Zak	Shopee	Sintetis
SALE-0302	PRD-004	2022-02-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0303	PRD-004	2022-03-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	1.00	36000.00	36000.00	Zak	Shopee	Sintetis
SALE-0304	PRD-004	2022-04-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	1.00	36000.00	36000.00	Zak	Shopee	Sintetis
SALE-0305	PRD-004	2022-05-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0306	PRD-004	2022-06-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0307	PRD-004	2022-07-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	1.00	36000.00	36000.00	Zak	Shopee	Sintetis
SALE-0308	PRD-004	2022-08-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	1.00	36000.00	36000.00	Zak	Shopee	Sintetis
SALE-0309	PRD-004	2022-09-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	2.00	36000.00	72000.00	Zak	Shopee	Sintetis
SALE-0310	PRD-004	2022-10-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	3.00	36000.00	108000.00	Zak	Shopee	Sintetis
SALE-0311	PRD-004	2022-11-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0312	PRD-004	2022-12-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	2.00	36000.00	72000.00	Zak	Shopee	Sintetis
SALE-0313	PRD-005	2022-01-01	Tricogem Fungisida Organik	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0314	PRD-005	2022-02-01	Tricogem Fungisida Organik	2.00	30000.00	60000.00	Gram	Shopee	Sintetis
SALE-0315	PRD-005	2022-03-01	Tricogem Fungisida Organik	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0316	PRD-005	2022-04-01	Tricogem Fungisida Organik	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0317	PRD-005	2022-05-01	Tricogem Fungisida Organik	2.00	30000.00	60000.00	Gram	Shopee	Sintetis
SALE-0318	PRD-005	2022-06-01	Tricogem Fungisida Organik	4.00	30000.00	120000.00	Gram	Shopee	Sintetis
SALE-0319	PRD-005	2022-07-01	Tricogem Fungisida Organik	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0320	PRD-005	2022-08-01	Tricogem Fungisida Organik	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0321	PRD-005	2022-09-01	Tricogem Fungisida Organik	4.00	30000.00	120000.00	Gram	Shopee	Sintetis
SALE-0322	PRD-005	2022-10-01	Tricogem Fungisida Organik	2.00	30000.00	60000.00	Gram	Shopee	Sintetis
SALE-0323	PRD-005	2022-11-01	Tricogem Fungisida Organik	2.00	30000.00	60000.00	Gram	Shopee	Sintetis
SALE-0324	PRD-005	2022-12-01	Tricogem Fungisida Organik	2.00	30000.00	60000.00	Gram	Shopee	Sintetis
SALE-0325	PRD-006	2022-01-01	Pendawa Subur Pertumbuhan	3.00	49500.00	148500.00	Liter	Shopee	Sintetis
SALE-0326	PRD-006	2022-02-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0327	PRD-006	2022-03-01	Pendawa Subur Pertumbuhan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0328	PRD-006	2022-04-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0329	PRD-006	2022-05-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0330	PRD-006	2022-06-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0331	PRD-006	2022-07-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0332	PRD-006	2022-08-01	Pendawa Subur Pertumbuhan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0333	PRD-006	2022-09-01	Pendawa Subur Pertumbuhan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0334	PRD-006	2022-10-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0335	PRD-006	2022-11-01	Pendawa Subur Pertumbuhan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0336	PRD-006	2022-12-01	Pendawa Subur Pertumbuhan	3.00	49500.00	148500.00	Liter	Shopee	Sintetis
SALE-0337	PRD-007	2022-01-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0338	PRD-007	2022-02-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0339	PRD-007	2022-03-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0340	PRD-007	2022-04-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0341	PRD-007	2022-05-01	Beva Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0342	PRD-007	2022-06-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0343	PRD-007	2022-07-01	Beva Gem	2.00	30000.00	60000.00	Gram	Shopee	Sintetis
SALE-0344	PRD-007	2022-08-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0345	PRD-007	2022-09-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0346	PRD-007	2022-10-01	Beva Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0347	PRD-007	2022-11-01	Beva Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0348	PRD-007	2022-12-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0349	PRD-008	2022-01-01	Metha Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0350	PRD-008	2022-02-01	Metha Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0351	PRD-008	2022-03-01	Metha Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0352	PRD-008	2022-04-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0353	PRD-008	2022-05-01	Metha Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0354	PRD-008	2022-06-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0355	PRD-008	2022-07-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0356	PRD-008	2022-08-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0357	PRD-008	2022-09-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0358	PRD-008	2022-10-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0359	PRD-008	2022-11-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0360	PRD-008	2022-12-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0361	PRD-009	2022-01-01	Pestisida Organik Pendawa Ampuh	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0362	PRD-009	2022-02-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0363	PRD-009	2022-03-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0364	PRD-009	2022-04-01	Pestisida Organik Pendawa Ampuh	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0365	PRD-009	2022-05-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0366	PRD-009	2022-06-01	Pestisida Organik Pendawa Ampuh	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0367	PRD-009	2022-07-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0368	PRD-009	2022-08-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0369	PRD-009	2022-09-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0370	PRD-009	2022-10-01	Pestisida Organik Pendawa Ampuh	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0371	PRD-009	2022-11-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0372	PRD-009	2022-12-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0373	PRD-010	2022-01-01	Pendawa Subur Pembungaan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0374	PRD-010	2022-02-01	Pendawa Subur Pembungaan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0375	PRD-010	2022-03-01	Pendawa Subur Pembungaan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0376	PRD-010	2022-04-01	Pendawa Subur Pembungaan	3.00	49500.00	148500.00	Liter	Shopee	Sintetis
SALE-0377	PRD-010	2022-05-01	Pendawa Subur Pembungaan	3.00	49500.00	148500.00	Liter	Shopee	Sintetis
SALE-0378	PRD-010	2022-06-01	Pendawa Subur Pembungaan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0379	PRD-010	2022-07-01	Pendawa Subur Pembungaan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0380	PRD-010	2022-08-01	Pendawa Subur Pembungaan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0381	PRD-010	2022-09-01	Pendawa Subur Pembungaan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0382	PRD-010	2022-10-01	Pendawa Subur Pembungaan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0383	PRD-010	2022-11-01	Pendawa Subur Pembungaan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0384	PRD-010	2022-12-01	Pendawa Subur Pembungaan	3.00	49500.00	148500.00	Liter	Shopee	Sintetis
SALE-0385	PRD-011	2022-01-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0386	PRD-011	2022-02-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0387	PRD-011	2022-03-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0388	PRD-011	2022-04-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0389	PRD-011	2022-05-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0390	PRD-011	2022-06-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0391	PRD-011	2022-07-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0392	PRD-011	2022-08-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0393	PRD-011	2022-09-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0394	PRD-011	2022-10-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0395	PRD-011	2022-11-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0396	PRD-011	2022-12-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0397	PRD-001	2023-01-01	Probiotik GB Proquatic	40.00	45000.00	1800000.00	Liter	Shopee	Sintetis
SALE-0398	PRD-001	2023-02-01	Probiotik GB Proquatic	10.00	45000.00	450000.00	Liter	Shopee	Sintetis
SALE-0399	PRD-001	2023-03-01	Probiotik GB Proquatic	30.00	45000.00	1350000.00	Liter	Shopee	Sintetis
SALE-0400	PRD-001	2023-04-01	Probiotik GB Proquatic	25.00	45000.00	1125000.00	Liter	Shopee	Sintetis
SALE-0401	PRD-001	2023-05-01	Probiotik GB Proquatic	19.00	45000.00	855000.00	Liter	Shopee	Sintetis
SALE-0402	PRD-001	2023-06-01	Probiotik GB Proquatic	40.00	45000.00	1800000.00	Liter	Shopee	Sintetis
SALE-0403	PRD-001	2023-07-01	Probiotik GB Proquatic	50.00	45000.00	2250000.00	Liter	Shopee	Sintetis
SALE-0404	PRD-001	2023-08-01	Probiotik GB Proquatic	35.00	45000.00	1575000.00	Liter	Shopee	Sintetis
SALE-0405	PRD-001	2023-09-01	Probiotik GB Proquatic	16.00	45000.00	720000.00	Liter	Shopee	Sintetis
SALE-0406	PRD-001	2023-10-01	Probiotik GB Proquatic	37.00	45000.00	1665000.00	Liter	Shopee	Sintetis
SALE-0407	PRD-001	2023-11-01	Probiotik GB Proquatic	27.00	45000.00	1215000.00	Liter	Shopee	Sintetis
SALE-0408	PRD-001	2023-12-01	Probiotik GB Proquatic	16.00	45000.00	720000.00	Liter	Shopee	Sintetis
SALE-0409	PRD-002	2023-01-01	Probiotik GB Propunic	1.00	45500.00	45500.00	Liter	Shopee	Sintetis
SALE-0410	PRD-002	2023-02-01	Probiotik GB Propunic	3.00	45500.00	136500.00	Liter	Shopee	Sintetis
SALE-0411	PRD-002	2023-03-01	Probiotik GB Propunic	6.00	45500.00	273000.00	Liter	Shopee	Sintetis
SALE-0412	PRD-002	2023-04-01	Probiotik GB Propunic	25.00	45500.00	1137500.00	Liter	Shopee	Sintetis
SALE-0413	PRD-002	2023-05-01	Probiotik GB Propunic	6.00	45500.00	273000.00	Liter	Shopee	Sintetis
SALE-0414	PRD-002	2023-06-01	Probiotik GB Propunic	2.00	45500.00	91000.00	Liter	Shopee	Sintetis
SALE-0415	PRD-002	2023-07-01	Probiotik GB Propunic	0.00	45500.00	0.00	Liter	Shopee	Sintetis
SALE-0416	PRD-002	2023-08-01	Probiotik GB Propunic	4.00	45500.00	182000.00	Liter	Shopee	Sintetis
SALE-0417	PRD-002	2023-09-01	Probiotik GB Propunic	11.00	45500.00	500500.00	Liter	Shopee	Sintetis
SALE-0418	PRD-002	2023-10-01	Probiotik GB Propunic	20.00	45500.00	910000.00	Liter	Shopee	Sintetis
SALE-0419	PRD-002	2023-11-01	Probiotik GB Propunic	10.00	45500.00	455000.00	Liter	Shopee	Sintetis
SALE-0420	PRD-002	2023-12-01	Probiotik GB Propunic	0.00	45500.00	0.00	Liter	Shopee	Sintetis
SALE-0421	PRD-003	2023-01-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	20.00	45000.00	900000.00	Liter	Shopee	Sintetis
SALE-0422	PRD-003	2023-02-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	12.00	45000.00	540000.00	Liter	Shopee	Sintetis
SALE-0423	PRD-003	2023-03-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	18.00	45000.00	810000.00	Liter	Shopee	Sintetis
SALE-0424	PRD-003	2023-04-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	1.00	45000.00	45000.00	Liter	Shopee	Sintetis
SALE-0425	PRD-003	2023-05-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	13.00	45000.00	585000.00	Liter	Shopee	Sintetis
SALE-0426	PRD-003	2023-06-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	9.00	45000.00	405000.00	Liter	Shopee	Sintetis
SALE-0427	PRD-003	2023-07-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	11.00	45000.00	495000.00	Liter	Shopee	Sintetis
SALE-0428	PRD-003	2023-08-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	18.00	45000.00	810000.00	Liter	Shopee	Sintetis
SALE-0429	PRD-003	2023-09-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	7.00	45000.00	315000.00	Liter	Shopee	Sintetis
SALE-0430	PRD-003	2023-10-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	4.00	45000.00	180000.00	Liter	Shopee	Sintetis
SALE-0431	PRD-003	2023-11-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	19.00	45000.00	855000.00	Liter	Shopee	Sintetis
SALE-0432	PRD-003	2023-12-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	8.00	45000.00	360000.00	Liter	Shopee	Sintetis
SALE-0433	PRD-004	2023-01-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0434	PRD-004	2023-02-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0435	PRD-004	2023-03-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	3.00	36000.00	108000.00	Zak	Shopee	Sintetis
SALE-0436	PRD-004	2023-04-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0437	PRD-004	2023-05-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	2.00	36000.00	72000.00	Zak	Shopee	Sintetis
SALE-0438	PRD-004	2023-06-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0439	PRD-004	2023-07-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	1.00	36000.00	36000.00	Zak	Shopee	Sintetis
SALE-0440	PRD-004	2023-08-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	3.00	36000.00	108000.00	Zak	Shopee	Sintetis
SALE-0441	PRD-004	2023-09-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0442	PRD-004	2023-10-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	1.00	36000.00	36000.00	Zak	Shopee	Sintetis
SALE-0443	PRD-004	2023-11-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	3.00	36000.00	108000.00	Zak	Shopee	Sintetis
SALE-0444	PRD-004	2023-12-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	1.00	36000.00	36000.00	Zak	Shopee	Sintetis
SALE-0445	PRD-005	2023-01-01	Tricogem Fungisida Organik	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0446	PRD-005	2023-02-01	Tricogem Fungisida Organik	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0447	PRD-005	2023-03-01	Tricogem Fungisida Organik	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0448	PRD-005	2023-04-01	Tricogem Fungisida Organik	3.00	30000.00	90000.00	Gram	Shopee	Sintetis
SALE-0449	PRD-005	2023-05-01	Tricogem Fungisida Organik	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0450	PRD-005	2023-06-01	Tricogem Fungisida Organik	4.00	30000.00	120000.00	Gram	Shopee	Sintetis
SALE-0451	PRD-005	2023-07-01	Tricogem Fungisida Organik	4.00	30000.00	120000.00	Gram	Shopee	Sintetis
SALE-0452	PRD-005	2023-08-01	Tricogem Fungisida Organik	3.00	30000.00	90000.00	Gram	Shopee	Sintetis
SALE-0453	PRD-005	2023-09-01	Tricogem Fungisida Organik	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0454	PRD-005	2023-10-01	Tricogem Fungisida Organik	3.00	30000.00	90000.00	Gram	Shopee	Sintetis
SALE-0455	PRD-005	2023-11-01	Tricogem Fungisida Organik	2.00	30000.00	60000.00	Gram	Shopee	Sintetis
SALE-0456	PRD-005	2023-12-01	Tricogem Fungisida Organik	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0457	PRD-006	2023-01-01	Pendawa Subur Pertumbuhan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0458	PRD-006	2023-02-01	Pendawa Subur Pertumbuhan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0459	PRD-006	2023-03-01	Pendawa Subur Pertumbuhan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0460	PRD-006	2023-04-01	Pendawa Subur Pertumbuhan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0461	PRD-006	2023-05-01	Pendawa Subur Pertumbuhan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0462	PRD-006	2023-06-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0463	PRD-006	2023-07-01	Pendawa Subur Pertumbuhan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0464	PRD-006	2023-08-01	Pendawa Subur Pertumbuhan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0465	PRD-006	2023-09-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0466	PRD-006	2023-10-01	Pendawa Subur Pertumbuhan	5.00	49500.00	247500.00	Liter	Shopee	Sintetis
SALE-0467	PRD-006	2023-11-01	Pendawa Subur Pertumbuhan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0468	PRD-006	2023-12-01	Pendawa Subur Pertumbuhan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0469	PRD-007	2023-01-01	Beva Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0470	PRD-007	2023-02-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0471	PRD-007	2023-03-01	Beva Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0472	PRD-007	2023-04-01	Beva Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0473	PRD-007	2023-05-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0474	PRD-007	2023-06-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0475	PRD-007	2023-07-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0476	PRD-007	2023-08-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0477	PRD-007	2023-09-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0478	PRD-007	2023-10-01	Beva Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0479	PRD-007	2023-11-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0480	PRD-007	2023-12-01	Beva Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0481	PRD-008	2023-01-01	Metha Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0482	PRD-008	2023-02-01	Metha Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0483	PRD-008	2023-03-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0484	PRD-008	2023-04-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0485	PRD-008	2023-05-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0486	PRD-008	2023-06-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0487	PRD-008	2023-07-01	Metha Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0488	PRD-008	2023-08-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0489	PRD-008	2023-09-01	Metha Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0490	PRD-008	2023-10-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0491	PRD-008	2023-11-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0492	PRD-008	2023-12-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0493	PRD-009	2023-01-01	Pestisida Organik Pendawa Ampuh	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0494	PRD-009	2023-02-01	Pestisida Organik Pendawa Ampuh	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0495	PRD-009	2023-03-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0496	PRD-009	2023-04-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0497	PRD-009	2023-05-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0498	PRD-009	2023-06-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0499	PRD-009	2023-07-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0500	PRD-009	2023-08-01	Pestisida Organik Pendawa Ampuh	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0501	PRD-009	2023-09-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0502	PRD-009	2023-10-01	Pestisida Organik Pendawa Ampuh	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0503	PRD-009	2023-11-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0504	PRD-009	2023-12-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0505	PRD-010	2023-01-01	Pendawa Subur Pembungaan	8.00	49500.00	396000.00	Liter	Shopee	Sintetis
SALE-0506	PRD-010	2023-02-01	Pendawa Subur Pembungaan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0507	PRD-010	2023-03-01	Pendawa Subur Pembungaan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0508	PRD-010	2023-04-01	Pendawa Subur Pembungaan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0509	PRD-010	2023-05-01	Pendawa Subur Pembungaan	5.00	49500.00	247500.00	Liter	Shopee	Sintetis
SALE-0510	PRD-010	2023-06-01	Pendawa Subur Pembungaan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0511	PRD-010	2023-07-01	Pendawa Subur Pembungaan	4.00	49500.00	198000.00	Liter	Shopee	Sintetis
SALE-0512	PRD-010	2023-08-01	Pendawa Subur Pembungaan	4.00	49500.00	198000.00	Liter	Shopee	Sintetis
SALE-0513	PRD-010	2023-09-01	Pendawa Subur Pembungaan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0514	PRD-010	2023-10-01	Pendawa Subur Pembungaan	5.00	49500.00	247500.00	Liter	Shopee	Sintetis
SALE-0515	PRD-010	2023-11-01	Pendawa Subur Pembungaan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0516	PRD-010	2023-12-01	Pendawa Subur Pembungaan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0517	PRD-011	2023-01-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0518	PRD-011	2023-02-01	Pendawa Subur Tunas (ZpT) Organik	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0519	PRD-011	2023-03-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0520	PRD-011	2023-04-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0521	PRD-011	2023-05-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0522	PRD-011	2023-06-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0523	PRD-011	2023-07-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0524	PRD-011	2023-08-01	Pendawa Subur Tunas (ZpT) Organik	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0525	PRD-011	2023-09-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0526	PRD-011	2023-10-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0527	PRD-011	2023-11-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0528	PRD-011	2023-12-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0529	PRD-001	2024-01-01	Probiotik GB Proquatic	40.00	45000.00	1800000.00	Liter	Shopee	Sintetis
SALE-0530	PRD-001	2024-02-01	Probiotik GB Proquatic	43.00	45000.00	1935000.00	Liter	Shopee	Sintetis
SALE-0531	PRD-001	2024-03-01	Probiotik GB Proquatic	22.00	45000.00	990000.00	Liter	Shopee	Sintetis
SALE-0532	PRD-001	2024-04-01	Probiotik GB Proquatic	37.00	45000.00	1665000.00	Liter	Shopee	Sintetis
SALE-0533	PRD-001	2024-05-01	Probiotik GB Proquatic	70.00	45000.00	3150000.00	Liter	Shopee	Sintetis
SALE-0534	PRD-001	2024-06-01	Probiotik GB Proquatic	54.00	45000.00	2430000.00	Liter	Shopee	Sintetis
SALE-0535	PRD-001	2024-07-01	Probiotik GB Proquatic	35.00	45000.00	1575000.00	Liter	Shopee	Sintetis
SALE-0536	PRD-001	2024-08-01	Probiotik GB Proquatic	23.00	45000.00	1035000.00	Liter	Shopee	Sintetis
SALE-0537	PRD-001	2024-09-01	Probiotik GB Proquatic	8.00	45000.00	360000.00	Liter	Shopee	Sintetis
SALE-0538	PRD-001	2024-10-01	Probiotik GB Proquatic	25.00	45000.00	1125000.00	Liter	Shopee	Sintetis
SALE-0539	PRD-001	2024-11-01	Probiotik GB Proquatic	38.00	45000.00	1710000.00	Liter	Shopee	Sintetis
SALE-0540	PRD-001	2024-12-01	Probiotik GB Proquatic	15.00	45000.00	675000.00	Liter	Shopee	Sintetis
SALE-0541	PRD-002	2024-01-01	Probiotik GB Propunic	4.00	45500.00	182000.00	Liter	Shopee	Sintetis
SALE-0542	PRD-002	2024-02-01	Probiotik GB Propunic	4.00	45500.00	182000.00	Liter	Shopee	Sintetis
SALE-0543	PRD-002	2024-03-01	Probiotik GB Propunic	3.00	45500.00	136500.00	Liter	Shopee	Sintetis
SALE-0544	PRD-002	2024-04-01	Probiotik GB Propunic	5.00	45500.00	227500.00	Liter	Shopee	Sintetis
SALE-0545	PRD-002	2024-05-01	Probiotik GB Propunic	5.00	45500.00	227500.00	Liter	Shopee	Sintetis
SALE-0546	PRD-002	2024-06-01	Probiotik GB Propunic	8.00	45500.00	364000.00	Liter	Shopee	Sintetis
SALE-0547	PRD-002	2024-07-01	Probiotik GB Propunic	4.00	45500.00	182000.00	Liter	Shopee	Sintetis
SALE-0548	PRD-002	2024-08-01	Probiotik GB Propunic	10.00	45500.00	455000.00	Liter	Shopee	Sintetis
SALE-0549	PRD-002	2024-09-01	Probiotik GB Propunic	14.00	45500.00	637000.00	Liter	Shopee	Sintetis
SALE-0550	PRD-002	2024-10-01	Probiotik GB Propunic	6.00	45500.00	273000.00	Liter	Shopee	Sintetis
SALE-0551	PRD-002	2024-11-01	Probiotik GB Propunic	1.00	45500.00	45500.00	Liter	Shopee	Sintetis
SALE-0552	PRD-002	2024-12-01	Probiotik GB Propunic	7.00	45500.00	318500.00	Liter	Shopee	Sintetis
SALE-0553	PRD-003	2024-01-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	31.00	45000.00	1395000.00	Liter	Shopee	Sintetis
SALE-0554	PRD-003	2024-02-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	5.00	45000.00	225000.00	Liter	Shopee	Sintetis
SALE-0555	PRD-003	2024-03-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	20.00	45000.00	900000.00	Liter	Shopee	Sintetis
SALE-0556	PRD-003	2024-04-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	12.00	45000.00	540000.00	Liter	Shopee	Sintetis
SALE-0557	PRD-003	2024-05-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	50.00	45000.00	2250000.00	Liter	Shopee	Sintetis
SALE-0558	PRD-003	2024-06-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	26.00	45000.00	1170000.00	Liter	Shopee	Sintetis
SALE-0559	PRD-003	2024-07-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	17.00	45000.00	765000.00	Liter	Shopee	Sintetis
SALE-0560	PRD-003	2024-08-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	8.00	45000.00	360000.00	Liter	Shopee	Sintetis
SALE-0561	PRD-003	2024-09-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	10.00	45000.00	450000.00	Liter	Shopee	Sintetis
SALE-0562	PRD-003	2024-10-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	9.00	45000.00	405000.00	Liter	Shopee	Sintetis
SALE-0563	PRD-003	2024-11-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	6.00	45000.00	270000.00	Liter	Shopee	Sintetis
SALE-0564	PRD-003	2024-12-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	46.00	45000.00	2070000.00	Liter	Shopee	Sintetis
SALE-0565	PRD-004	2024-01-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0566	PRD-004	2024-02-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	3.00	36000.00	108000.00	Zak	Shopee	Sintetis
SALE-0567	PRD-004	2024-03-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	2.00	36000.00	72000.00	Zak	Shopee	Sintetis
SALE-0568	PRD-004	2024-04-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	15.00	36000.00	540000.00	Zak	Shopee	Sintetis
SALE-0569	PRD-004	2024-05-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0570	PRD-004	2024-06-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	10.00	36000.00	360000.00	Zak	Shopee	Sintetis
SALE-0571	PRD-004	2024-07-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	2.00	36000.00	72000.00	Zak	Shopee	Sintetis
SALE-0572	PRD-004	2024-08-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	2.00	36000.00	72000.00	Zak	Shopee	Sintetis
SALE-0573	PRD-004	2024-09-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0574	PRD-004	2024-10-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	2.00	36000.00	72000.00	Zak	Shopee	Sintetis
SALE-0575	PRD-004	2024-11-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	2.00	36000.00	72000.00	Zak	Shopee	Sintetis
SALE-0576	PRD-004	2024-12-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	1.00	36000.00	36000.00	Zak	Shopee	Sintetis
SALE-0577	PRD-005	2024-01-01	Tricogem Fungisida Organik	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0578	PRD-005	2024-02-01	Tricogem Fungisida Organik	8.00	30000.00	240000.00	Gram	Shopee	Sintetis
SALE-0579	PRD-005	2024-03-01	Tricogem Fungisida Organik	3.00	30000.00	90000.00	Gram	Shopee	Sintetis
SALE-0580	PRD-005	2024-04-01	Tricogem Fungisida Organik	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0581	PRD-005	2024-05-01	Tricogem Fungisida Organik	5.00	30000.00	150000.00	Gram	Shopee	Sintetis
SALE-0582	PRD-005	2024-06-01	Tricogem Fungisida Organik	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0583	PRD-005	2024-07-01	Tricogem Fungisida Organik	3.00	30000.00	90000.00	Gram	Shopee	Sintetis
SALE-0584	PRD-005	2024-08-01	Tricogem Fungisida Organik	2.00	30000.00	60000.00	Gram	Shopee	Sintetis
SALE-0585	PRD-005	2024-09-01	Tricogem Fungisida Organik	3.00	30000.00	90000.00	Gram	Shopee	Sintetis
SALE-0586	PRD-005	2024-10-01	Tricogem Fungisida Organik	5.00	30000.00	150000.00	Gram	Shopee	Sintetis
SALE-0587	PRD-005	2024-11-01	Tricogem Fungisida Organik	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0588	PRD-005	2024-12-01	Tricogem Fungisida Organik	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0589	PRD-006	2024-01-01	Pendawa Subur Pertumbuhan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0590	PRD-006	2024-02-01	Pendawa Subur Pertumbuhan	5.00	49500.00	247500.00	Liter	Shopee	Sintetis
SALE-0591	PRD-006	2024-03-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0592	PRD-006	2024-04-01	Pendawa Subur Pertumbuhan	5.00	49500.00	247500.00	Liter	Shopee	Sintetis
SALE-0593	PRD-006	2024-05-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0594	PRD-006	2024-06-01	Pendawa Subur Pertumbuhan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0595	PRD-006	2024-07-01	Pendawa Subur Pertumbuhan	3.00	49500.00	148500.00	Liter	Shopee	Sintetis
SALE-0596	PRD-006	2024-08-01	Pendawa Subur Pertumbuhan	5.00	49500.00	247500.00	Liter	Shopee	Sintetis
SALE-0597	PRD-006	2024-09-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0598	PRD-006	2024-10-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0599	PRD-006	2024-11-01	Pendawa Subur Pertumbuhan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0600	PRD-006	2024-12-01	Pendawa Subur Pertumbuhan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0602	PRD-007	2024-02-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0603	PRD-007	2024-03-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0604	PRD-007	2024-04-01	Beva Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0605	PRD-007	2024-05-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0606	PRD-007	2024-06-01	Beva Gem	3.00	30000.00	90000.00	Gram	Shopee	Sintetis
SALE-0607	PRD-007	2024-07-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0608	PRD-007	2024-08-01	Beva Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0609	PRD-007	2024-09-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0610	PRD-007	2024-10-01	Beva Gem	2.00	30000.00	60000.00	Gram	Shopee	Sintetis
SALE-0611	PRD-007	2024-11-01	Beva Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0612	PRD-007	2024-12-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0613	PRD-008	2024-01-01	Metha Gem	2.00	30000.00	60000.00	Gram	Shopee	Sintetis
SALE-0614	PRD-008	2024-02-01	Metha Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0615	PRD-008	2024-03-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0616	PRD-008	2024-04-01	Metha Gem	2.00	30000.00	60000.00	Gram	Shopee	Sintetis
SALE-0617	PRD-008	2024-05-01	Metha Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0618	PRD-008	2024-06-01	Metha Gem	2.00	30000.00	60000.00	Gram	Shopee	Sintetis
SALE-0619	PRD-008	2024-07-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0620	PRD-008	2024-08-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0621	PRD-008	2024-09-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0622	PRD-008	2024-10-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0623	PRD-008	2024-11-01	Metha Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0624	PRD-008	2024-12-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0625	PRD-009	2024-01-01	Pestisida Organik Pendawa Ampuh	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0626	PRD-009	2024-02-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0627	PRD-009	2024-03-01	Pestisida Organik Pendawa Ampuh	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0628	PRD-009	2024-04-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0629	PRD-009	2024-05-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0630	PRD-009	2024-06-01	Pestisida Organik Pendawa Ampuh	3.00	49500.00	148500.00	Liter	Shopee	Sintetis
SALE-0631	PRD-009	2024-07-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0632	PRD-009	2024-08-01	Pestisida Organik Pendawa Ampuh	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0633	PRD-009	2024-09-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0634	PRD-009	2024-10-01	Pestisida Organik Pendawa Ampuh	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0635	PRD-009	2024-11-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0636	PRD-009	2024-12-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0637	PRD-010	2024-01-01	Pendawa Subur Pembungaan	4.00	49500.00	198000.00	Liter	Shopee	Sintetis
SALE-0638	PRD-010	2024-02-01	Pendawa Subur Pembungaan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0639	PRD-010	2024-03-01	Pendawa Subur Pembungaan	4.00	49500.00	198000.00	Liter	Shopee	Sintetis
SALE-0640	PRD-010	2024-04-01	Pendawa Subur Pembungaan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0641	PRD-010	2024-05-01	Pendawa Subur Pembungaan	5.00	49500.00	247500.00	Liter	Shopee	Sintetis
SALE-0642	PRD-010	2024-06-01	Pendawa Subur Pembungaan	5.00	49500.00	247500.00	Liter	Shopee	Sintetis
SALE-0643	PRD-010	2024-07-01	Pendawa Subur Pembungaan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0644	PRD-010	2024-08-01	Pendawa Subur Pembungaan	3.00	49500.00	148500.00	Liter	Shopee	Sintetis
SALE-0645	PRD-010	2024-09-01	Pendawa Subur Pembungaan	5.00	49500.00	247500.00	Liter	Shopee	Sintetis
SALE-0646	PRD-010	2024-10-01	Pendawa Subur Pembungaan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0647	PRD-010	2024-11-01	Pendawa Subur Pembungaan	3.00	49500.00	148500.00	Liter	Shopee	Sintetis
SALE-0648	PRD-010	2024-12-01	Pendawa Subur Pembungaan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0649	PRD-011	2024-01-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0650	PRD-011	2024-02-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0651	PRD-011	2024-03-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0652	PRD-011	2024-04-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0653	PRD-011	2024-05-01	Pendawa Subur Tunas (ZpT) Organik	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0654	PRD-011	2024-06-01	Pendawa Subur Tunas (ZpT) Organik	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0655	PRD-011	2024-07-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0656	PRD-011	2024-08-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0657	PRD-011	2024-09-01	Pendawa Subur Tunas (ZpT) Organik	3.00	49500.00	148500.00	Liter	Shopee	Sintetis
SALE-0658	PRD-011	2024-10-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0659	PRD-011	2024-11-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0660	PRD-011	2024-12-01	Pendawa Subur Tunas (ZpT) Organik	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0661	PRD-001	2025-01-01	Probiotik GB Proquatic	11.00	45000.00	495000.00	Liter	Shopee	Sintetis
SALE-0662	PRD-001	2025-02-01	Probiotik GB Proquatic	70.00	45000.00	3150000.00	Liter	Shopee	Sintetis
SALE-0663	PRD-001	2025-03-01	Probiotik GB Proquatic	24.00	45000.00	1080000.00	Liter	Shopee	Sintetis
SALE-0664	PRD-001	2025-04-01	Probiotik GB Proquatic	30.00	45000.00	1350000.00	Liter	Shopee	Sintetis
SALE-0665	PRD-001	2025-05-01	Probiotik GB Proquatic	55.00	45000.00	2475000.00	Liter	Shopee	Sintetis
SALE-0666	PRD-001	2025-06-01	Probiotik GB Proquatic	45.00	45000.00	2025000.00	Liter	Shopee	Sintetis
SALE-0667	PRD-001	2025-07-01	Probiotik GB Proquatic	100.00	45000.00	4500000.00	Liter	Shopee	Sintetis
SALE-0668	PRD-001	2025-08-01	Probiotik GB Proquatic	15.00	45000.00	675000.00	Liter	Shopee	Sintetis
SALE-0669	PRD-001	2025-09-01	Probiotik GB Proquatic	29.00	45000.00	1305000.00	Liter	Shopee	Sintetis
SALE-0670	PRD-001	2025-10-01	Probiotik GB Proquatic	50.00	45000.00	2250000.00	Liter	Shopee	Sintetis
SALE-0671	PRD-001	2025-11-01	Probiotik GB Proquatic	50.00	45000.00	2250000.00	Liter	Shopee	Sintetis
SALE-0672	PRD-001	2025-12-01	Probiotik GB Proquatic	54.00	45000.00	2430000.00	Liter	Shopee	Sintetis
SALE-0673	PRD-002	2025-01-01	Probiotik GB Propunic	2.00	45500.00	91000.00	Liter	Shopee	Sintetis
SALE-0674	PRD-002	2025-02-01	Probiotik GB Propunic	17.00	45500.00	773500.00	Liter	Shopee	Sintetis
SALE-0675	PRD-002	2025-03-01	Probiotik GB Propunic	7.00	45500.00	318500.00	Liter	Shopee	Sintetis
SALE-0676	PRD-002	2025-04-01	Probiotik GB Propunic	10.00	45500.00	455000.00	Liter	Shopee	Sintetis
SALE-0677	PRD-002	2025-05-01	Probiotik GB Propunic	5.00	45500.00	227500.00	Liter	Shopee	Sintetis
SALE-0678	PRD-002	2025-06-01	Probiotik GB Propunic	11.00	45500.00	500500.00	Liter	Shopee	Sintetis
SALE-0679	PRD-002	2025-07-01	Probiotik GB Propunic	4.00	45500.00	182000.00	Liter	Shopee	Sintetis
SALE-0680	PRD-002	2025-08-01	Probiotik GB Propunic	10.00	45500.00	455000.00	Liter	Shopee	Sintetis
SALE-0681	PRD-002	2025-09-01	Probiotik GB Propunic	7.00	45500.00	318500.00	Liter	Shopee	Sintetis
SALE-0682	PRD-002	2025-10-01	Probiotik GB Propunic	13.00	45500.00	591500.00	Liter	Shopee	Sintetis
SALE-0683	PRD-002	2025-11-01	Probiotik GB Propunic	4.00	45500.00	182000.00	Liter	Shopee	Sintetis
SALE-0684	PRD-002	2025-12-01	Probiotik GB Propunic	30.00	45500.00	1365000.00	Liter	Shopee	Sintetis
SALE-0685	PRD-003	2025-01-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	4.00	45000.00	180000.00	Liter	Shopee	Sintetis
SALE-0686	PRD-003	2025-02-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	39.00	45000.00	1755000.00	Liter	Shopee	Sintetis
SALE-0687	PRD-003	2025-03-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	7.00	45000.00	315000.00	Liter	Shopee	Sintetis
SALE-0688	PRD-003	2025-04-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	70.00	45000.00	3150000.00	Liter	Shopee	Sintetis
SALE-0689	PRD-003	2025-05-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	48.00	45000.00	2160000.00	Liter	Shopee	Sintetis
SALE-0690	PRD-003	2025-06-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	22.00	45000.00	990000.00	Liter	Shopee	Sintetis
SALE-0691	PRD-003	2025-07-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	11.00	45000.00	495000.00	Liter	Shopee	Sintetis
SALE-0692	PRD-003	2025-08-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	24.00	45000.00	1080000.00	Liter	Shopee	Sintetis
SALE-0693	PRD-003	2025-09-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	21.00	45000.00	945000.00	Liter	Shopee	Sintetis
SALE-0694	PRD-003	2025-10-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	45.00	45000.00	2025000.00	Liter	Shopee	Sintetis
SALE-0695	PRD-003	2025-11-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	18.00	45000.00	810000.00	Liter	Shopee	Sintetis
SALE-0696	PRD-003	2025-12-01	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	21.00	45000.00	945000.00	Liter	Shopee	Sintetis
SALE-0697	PRD-004	2025-01-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	3.00	36000.00	108000.00	Zak	Shopee	Sintetis
SALE-0698	PRD-004	2025-02-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	2.00	36000.00	72000.00	Zak	Shopee	Sintetis
SALE-0699	PRD-004	2025-03-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	2.00	36000.00	72000.00	Zak	Shopee	Sintetis
SALE-0700	PRD-004	2025-04-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0701	PRD-004	2025-05-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	1.00	36000.00	36000.00	Zak	Shopee	Sintetis
SALE-0702	PRD-004	2025-06-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	2.00	36000.00	72000.00	Zak	Shopee	Sintetis
SALE-0703	PRD-004	2025-07-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	1.00	36000.00	36000.00	Zak	Shopee	Sintetis
SALE-0704	PRD-004	2025-08-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	0.00	36000.00	0.00	Zak	Shopee	Sintetis
SALE-0705	PRD-004	2025-09-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	2.00	36000.00	72000.00	Zak	Shopee	Sintetis
SALE-0706	PRD-004	2025-10-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	2.00	36000.00	72000.00	Zak	Shopee	Sintetis
SALE-0707	PRD-004	2025-11-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	2.00	36000.00	72000.00	Zak	Shopee	Sintetis
SALE-0708	PRD-004	2025-12-01	Compossap Pupuk Organik Padat dari Kotoran Ternak	1.00	36000.00	36000.00	Zak	Shopee	Sintetis
SALE-0709	PRD-005	2025-01-01	Tricogem Fungisida Organik	5.00	30000.00	150000.00	Gram	Shopee	Sintetis
SALE-0710	PRD-005	2025-02-01	Tricogem Fungisida Organik	17.00	30000.00	510000.00	Gram	Shopee	Sintetis
SALE-0711	PRD-005	2025-03-01	Tricogem Fungisida Organik	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0712	PRD-005	2025-04-01	Tricogem Fungisida Organik	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0713	PRD-005	2025-05-01	Tricogem Fungisida Organik	4.00	30000.00	120000.00	Gram	Shopee	Sintetis
SALE-0714	PRD-005	2025-06-01	Tricogem Fungisida Organik	3.00	30000.00	90000.00	Gram	Shopee	Sintetis
SALE-0715	PRD-005	2025-07-01	Tricogem Fungisida Organik	6.00	30000.00	180000.00	Gram	Shopee	Sintetis
SALE-0716	PRD-005	2025-08-01	Tricogem Fungisida Organik	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0717	PRD-005	2025-09-01	Tricogem Fungisida Organik	8.00	30000.00	240000.00	Gram	Shopee	Sintetis
SALE-0718	PRD-005	2025-10-01	Tricogem Fungisida Organik	3.00	30000.00	90000.00	Gram	Shopee	Sintetis
SALE-0719	PRD-005	2025-11-01	Tricogem Fungisida Organik	2.00	30000.00	60000.00	Gram	Shopee	Sintetis
SALE-0720	PRD-005	2025-12-01	Tricogem Fungisida Organik	5.00	30000.00	150000.00	Gram	Shopee	Sintetis
SALE-0721	PRD-006	2025-01-01	Pendawa Subur Pertumbuhan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0722	PRD-006	2025-02-01	Pendawa Subur Pertumbuhan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0723	PRD-006	2025-03-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0724	PRD-006	2025-04-01	Pendawa Subur Pertumbuhan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0725	PRD-006	2025-05-01	Pendawa Subur Pertumbuhan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0726	PRD-006	2025-06-01	Pendawa Subur Pertumbuhan	5.00	49500.00	247500.00	Liter	Shopee	Sintetis
SALE-0727	PRD-006	2025-07-01	Pendawa Subur Pertumbuhan	8.00	49500.00	396000.00	Liter	Shopee	Sintetis
SALE-0728	PRD-006	2025-08-01	Pendawa Subur Pertumbuhan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0729	PRD-006	2025-09-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0730	PRD-006	2025-10-01	Pendawa Subur Pertumbuhan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0731	PRD-006	2025-11-01	Pendawa Subur Pertumbuhan	10.00	49500.00	495000.00	Liter	Shopee	Sintetis
SALE-0732	PRD-006	2025-12-01	Pendawa Subur Pertumbuhan	3.00	49500.00	148500.00	Liter	Shopee	Sintetis
SALE-0733	PRD-007	2025-01-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0734	PRD-007	2025-02-01	Beva Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0735	PRD-007	2025-03-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0736	PRD-007	2025-04-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0737	PRD-007	2025-05-01	Beva Gem	2.00	30000.00	60000.00	Gram	Shopee	Sintetis
SALE-0738	PRD-007	2025-06-01	Beva Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0739	PRD-007	2025-07-01	Beva Gem	5.00	30000.00	150000.00	Gram	Shopee	Sintetis
SALE-0740	PRD-007	2025-08-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0741	PRD-007	2025-09-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0742	PRD-007	2025-10-01	Beva Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0743	PRD-007	2025-11-01	Beva Gem	3.00	30000.00	90000.00	Gram	Shopee	Sintetis
SALE-0744	PRD-007	2025-12-01	Beva Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0745	PRD-008	2025-01-01	Metha Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0746	PRD-008	2025-02-01	Metha Gem	2.00	30000.00	60000.00	Gram	Shopee	Sintetis
SALE-0747	PRD-008	2025-03-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0748	PRD-008	2025-04-01	Metha Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0749	PRD-008	2025-05-01	Metha Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0750	PRD-008	2025-06-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0751	PRD-008	2025-07-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0752	PRD-008	2025-08-01	Metha Gem	2.00	30000.00	60000.00	Gram	Shopee	Sintetis
SALE-0753	PRD-008	2025-09-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0754	PRD-008	2025-10-01	Metha Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0755	PRD-008	2025-11-01	Metha Gem	1.00	30000.00	30000.00	Gram	Shopee	Sintetis
SALE-0756	PRD-008	2025-12-01	Metha Gem	0.00	30000.00	0.00	Gram	Shopee	Sintetis
SALE-0757	PRD-009	2025-01-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0758	PRD-009	2025-02-01	Pestisida Organik Pendawa Ampuh	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0759	PRD-009	2025-03-01	Pestisida Organik Pendawa Ampuh	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0760	PRD-009	2025-04-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0761	PRD-009	2025-05-01	Pestisida Organik Pendawa Ampuh	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0762	PRD-009	2025-06-01	Pestisida Organik Pendawa Ampuh	3.00	49500.00	148500.00	Liter	Shopee	Sintetis
SALE-0763	PRD-009	2025-07-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0764	PRD-009	2025-08-01	Pestisida Organik Pendawa Ampuh	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0765	PRD-009	2025-09-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0766	PRD-009	2025-10-01	Pestisida Organik Pendawa Ampuh	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0767	PRD-009	2025-11-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0768	PRD-009	2025-12-01	Pestisida Organik Pendawa Ampuh	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0769	PRD-010	2025-01-01	Pendawa Subur Pembungaan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0770	PRD-010	2025-02-01	Pendawa Subur Pembungaan	4.00	49500.00	198000.00	Liter	Shopee	Sintetis
SALE-0771	PRD-010	2025-03-01	Pendawa Subur Pembungaan	8.00	49500.00	396000.00	Liter	Shopee	Sintetis
SALE-0772	PRD-010	2025-04-01	Pendawa Subur Pembungaan	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0773	PRD-010	2025-05-01	Pendawa Subur Pembungaan	5.00	49500.00	247500.00	Liter	Shopee	Sintetis
SALE-0774	PRD-010	2025-06-01	Pendawa Subur Pembungaan	10.00	49500.00	495000.00	Liter	Shopee	Sintetis
SALE-0775	PRD-010	2025-07-01	Pendawa Subur Pembungaan	3.00	49500.00	148500.00	Liter	Shopee	Sintetis
SALE-0776	PRD-010	2025-08-01	Pendawa Subur Pembungaan	10.00	49500.00	495000.00	Liter	Shopee	Sintetis
SALE-0777	PRD-010	2025-09-01	Pendawa Subur Pembungaan	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0778	PRD-010	2025-10-01	Pendawa Subur Pembungaan	4.00	49500.00	198000.00	Liter	Shopee	Sintetis
SALE-0779	PRD-010	2025-11-01	Pendawa Subur Pembungaan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0780	PRD-010	2025-12-01	Pendawa Subur Pembungaan	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0781	PRD-011	2025-01-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0782	PRD-011	2025-02-01	Pendawa Subur Tunas (ZpT) Organik	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0783	PRD-011	2025-03-01	Pendawa Subur Tunas (ZpT) Organik	3.00	49500.00	148500.00	Liter	Shopee	Sintetis
SALE-0784	PRD-011	2025-04-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0785	PRD-011	2025-05-01	Pendawa Subur Tunas (ZpT) Organik	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0786	PRD-011	2025-06-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0787	PRD-011	2025-07-01	Pendawa Subur Tunas (ZpT) Organik	3.00	49500.00	148500.00	Liter	Shopee	Sintetis
SALE-0788	PRD-011	2025-08-01	Pendawa Subur Tunas (ZpT) Organik	5.00	49500.00	247500.00	Liter	Shopee	Sintetis
SALE-0789	PRD-011	2025-09-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
SALE-0790	PRD-011	2025-10-01	Pendawa Subur Tunas (ZpT) Organik	1.00	49500.00	49500.00	Liter	Shopee	Sintetis
SALE-0791	PRD-011	2025-11-01	Pendawa Subur Tunas (ZpT) Organik	2.00	49500.00	99000.00	Liter	Shopee	Sintetis
SALE-0792	PRD-011	2025-12-01	Pendawa Subur Tunas (ZpT) Organik	0.00	49500.00	0.00	Liter	Shopee	Sintetis
\.


--
-- Data for Name: produk; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.produk (produk_id, nama_produk, jenis_produk, deskripsi, manfaat, harga, ukuran_kemasan, produsen, lokasi_produsen, kontak, stok_ketersediaan, foto_produk) FROM stdin;
PRD-001	Probiotik GB Proquatic	Probiotik perikanan	Produk bioteknologi berbasis probiotik yang digunakan pada budidaya ikan dan udang untuk membantu menciptakan kondisi perairan yang stabil melalui aktivitas mikroorganisme pengurai dan mikroorganisme yang bersahabat dengan kehidupan.	Membantu menguraikan limbah organik, sisa pakan, kotoran ikan atau udang, mengurangi bau amonia dan skatol, mengurangi lendir dasar tambak/kolam, menekan mikroorganisme patogen, serta membantu meningkatkan kualitas dan produksi ikan dan udang.	45000.00	1 L	CV. Pendawa Kencana Multi Farm	Yogyakarta	085.643.596.401 (Agus)	Tersedia	Foto Produk 1
PRD-002	Probiotik GB Propunic	Probiotik Organik dan Sanitasi	Produk probiotik yang digunakan sebagai bakteri dekomposisi untuk membantu menguraikan bahan organik, limbah, dan kotoran ternak serta mendukung proses pembuatan pupuk organik.	Membantu mempercepat penguraian bahan organik, mengurangi bau pada kandang dan kotoran ternak, menjadi aktivator pembuatan pupuk organik, membantu mengatasi limbah rumah tangga dan septic tank, serta membantu perawatan saluran dan pengelolaan limbah.	45500.00	1 L	CV. Pendawa Kencana Multi Farm	Yogyakarta	085.643.596.401 (Agus)	Tersedia	Foto Produk 2
PRD-003	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	Probiotik Ternak	Produk bioteknologi yang mengandung koloni mikroorganisme berupa bakteri, fungi, dan aktinomiset beserta enzim yang digunakan sebagai campuran pakan ternak. Mikroorganisme tersebut bekerja secara enzimatis untuk membantu memecah protein, karbohidrat, dan lemak sehingga nutrien pakan dapat dimanfaatkan dengan lebih optimal.	Membantu meningkatkan pemanfaatan dan penyerapan nutrisi pakan, meningkatkan kecernaan pakan, mendukung produksi ternak, serta menghasilkan kotoran yang lebih kering dan mengurangi bau. Dokumen mitra menyebut tingkat kecernaan pakan mencapai 20% berdasarkan hasil laboratorium dan pengalaman lapangan.	45000.00	1 L	CV. Pendawa Kencana Multi Farm	Yogyakarta	085.643.596.401 (Agus)	Tersedia	Foto Produk 11
PRD-004	Compossap Pupuk Organik Padat dari Kotoran Ternak	Pupuk organik padat	Pupuk organik yang dihasilkan melalui pengolahan limbah organik pertanian dan peternakan menjadi pupuk organik yang berkualitas dan berdaya guna.	Merangsang pertumbuhan tanaman, menyegarkan dan memperbaiki kondisi tanah, memperbaiki porositas, agregat dan permeabilitas tanah, meningkatkan kemampuan tanah mengikat air, menyediakan unsur hara makro dan mikro, serta meningkatkan produktivitas lahan.	36000.00	20 kg	CV. Pendawa Kencana Multi Farm	Yogyakarta	085.643.596.401 (Agus)	Tersedia	Foto Produk 3
PRD-005	Tricogem Fungisida Organik	Fungisida organik / agen hayati	Agen hayati berbasis Trichoderma yang dikembangkan sebagai fungisida organik untuk membantu pengendalian hama dan penyakit tanaman.	Membantu mengendalikan penyakit tanaman yang disebabkan oleh fungi serta mendukung pengendalian organisme pengganggu tanaman secara hayati.	30000.00	100 g	CV. Pendawa Kencana Multi Farm	Yogyakarta	085.643.596.401 (Agus)	Tersedia	Foto Produk 4
PRD-006	Pendawa Subur Pertumbuhan	Pupuk organik cair	Pupuk cair organik yang dibuat dari bahan berkualitas melalui proses dekomposisi oleh bakteri pengurai dan digunakan sebagai perangsang pertumbuhan alami tanaman.	Membantu merangsang pertumbuhan tanaman serta menyediakan unsur hara yang mendukung pertumbuhan tanaman. Produk juga mengandung klorofil yang mendukung penggunaannya sebagai perangsang pertumbuhan.	49500.00	1 L	CV. Pendawa Kencana Multi Farm	Yogyakarta	085.643.596.401 (Agus)	Tersedia	Foto Produk 5
PRD-007	Beva Gem	Pestisida organik / agen hayati	Agen hayati berbasis Beauveria bassiana yang digunakan sebagai pestisida organik untuk membantu pengendalian organisme pengganggu tanaman.	Membantu mengendalikan hama tanaman melalui pemanfaatan agen hayati dan mendukung pengendalian hama secara lebih selektif.	30000.00	100 g	CV. Pendawa Kencana Multi Farm	Yogyakarta	085.643.596.401 (Agus)	Tersedia	Foto Produk 6
PRD-008	Metha Gem	Insektisida organik / agen hayati	Agen hayati berbasis Metharizium yang digunakan sebagai insektisida organik untuk membantu pengendalian hama tanaman.	Membantu mengendalikan hama tanaman melalui pemanfaatan agen hayati.	30000.00	100 g	CV. Pendawa Kencana Multi Farm	Yogyakarta	085.643.596.401 (Agus)	Tersedia	Foto Produk 7
PRD-009	Pestisida Organik Pendawa Ampuh	Pestisida Organik	Pestisida organik yang mengandung berbagai jenis tanaman, seperti daun mimba, tembakau, dan tanaman alami lainnya, yang digunakan untuk membantu mencegah dan mengendalikan hama serta penyakit tanaman.	Membantu memberantas hama dan penyakit tanaman, mudah digunakan, aman terhadap lingkungan, serta dapat dikombinasikan dengan metode pengendalian lainnya.	49500.00	1 L	CV. Pendawa Kencana Multi Farm	Yogyakarta	085.643.596.401 (Agus)	Tersedia	Foto Produk 8
PRD-010	Pendawa Subur Pembungaan	Pupuk organik cair	Pupuk cair organik yang dibuat dari bahan berkualitas melalui proses dekomposisi oleh bakteri pengurai dan digunakan sebagai perangsang alami untuk pembungaan dan pembuahan tanaman.	Membantu merangsang pembungaan dan pembuahan tanaman serta mendukung kebutuhan unsur hara tanaman.	49500.00	1 L	CV. Pendawa Kencana Multi Farm	Yogyakarta	085.643.596.401 (Agus)	Tersedia	Foto Produk 9
PRD-011	Pendawa Subur Tunas (ZpT) Organik	Pupuk organik cair	Pupuk organik cair untuk benih dan kecambah yang digunakan untuk mendukung tahap awal pertumbuhan tanaman.	Mendukung perkecambahan benih dan pertumbuhan awal tanaman.	49500.00	1 L	CV. Pendawa Kencana Multi Farm	Yogyakarta	085.643.596.401 (Agus)	Tersedia	Foto Produk 10
\.


--
-- Data for Name: produk_katalog_audit; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.produk_katalog_audit (produk_id, nama_produk, jenis_produk, deskripsi, manfaat, harga, ukuran_kemasan, produsen, lokasi_produsen, kontak, stok_ketersediaan, foto_produk) FROM stdin;
PRD-001	Probiotik GB Proquatic	Probiotik perikanan	Produk bioteknologi berbasis probiotik yang digunakan pada budidaya ikan dan udang untuk membantu menciptakan kondisi perairan yang stabil melalui aktivitas mikroorganisme pengurai dan mikroorganisme yang bersahabat dengan kehidupan.	Membantu menguraikan limbah organik, sisa pakan, kotoran ikan atau udang, mengurangi bau amonia dan skatol, mengurangi lendir dasar tambak/kolam, menekan mikroorganisme patogen, serta membantu meningkatkan kualitas dan produksi ikan dan udang.	45000.00	1 L	CV. Pendawa Kencana Multi Farm	Yogyakarta	085.643.596.401 (Agus)	Tersedia	Foto Produk 1
PRD-002	Probiotik GB Propunic	Probiotik Organik dan Sanitasi	Produk probiotik yang digunakan sebagai bakteri dekomposisi untuk membantu menguraikan bahan organik, limbah, dan kotoran ternak serta mendukung proses pembuatan pupuk organik.	Membantu mempercepat penguraian bahan organik, mengurangi bau pada kandang dan kotoran ternak, menjadi aktivator pembuatan pupuk organik, membantu mengatasi limbah rumah tangga dan septic tank, serta membantu perawatan saluran dan pengelolaan limbah.	45500.00	1 L	CV. Pendawa Kencana Multi Farm	Yogyakarta	085.643.596.401 (Agus)	Tersedia	Foto Produk 2
PRD-003	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	Probiotik Ternak	Produk bioteknologi yang mengandung koloni mikroorganisme berupa bakteri, fungi, dan aktinomiset beserta enzim yang digunakan sebagai campuran pakan ternak. Mikroorganisme tersebut bekerja secara enzimatis untuk membantu memecah protein, karbohidrat, dan lemak sehingga nutrien pakan dapat dimanfaatkan dengan lebih optimal.	Membantu meningkatkan pemanfaatan dan penyerapan nutrisi pakan, meningkatkan kecernaan pakan, mendukung produksi ternak, serta menghasilkan kotoran yang lebih kering dan mengurangi bau. Dokumen mitra menyebut tingkat kecernaan pakan mencapai 20% berdasarkan hasil laboratorium dan pengalaman lapangan.	45000.00	1 L	CV. Pendawa Kencana Multi Farm	Yogyakarta	085.643.596.401 (Agus)	Tersedia	Foto Produk 11
PRD-004	Compossap Pupuk Organik Padat dari Kotoran Ternak	Pupuk organik padat	Pupuk organik yang dihasilkan melalui pengolahan limbah organik pertanian dan peternakan menjadi pupuk organik yang berkualitas dan berdaya guna.	Merangsang pertumbuhan tanaman, menyegarkan dan memperbaiki kondisi tanah, memperbaiki porositas, agregat dan permeabilitas tanah, meningkatkan kemampuan tanah mengikat air, menyediakan unsur hara makro dan mikro, serta meningkatkan produktivitas lahan.	36000.00	20 kg	CV. Pendawa Kencana Multi Farm	Yogyakarta	085.643.596.401 (Agus)	Tersedia	Foto Produk 3
PRD-005	Tricogem Fungisida Organik	Fungisida organik / agen hayati	Agen hayati berbasis Trichoderma yang dikembangkan sebagai fungisida organik untuk membantu pengendalian hama dan penyakit tanaman.	Membantu mengendalikan penyakit tanaman yang disebabkan oleh fungi serta mendukung pengendalian organisme pengganggu tanaman secara hayati.	30000.00	100 g	CV. Pendawa Kencana Multi Farm	Yogyakarta	085.643.596.401 (Agus)	Tersedia	Foto Produk 4
PRD-006	Pendawa Subur Pertumbuhan	Pupuk organik cair	Pupuk cair organik yang dibuat dari bahan berkualitas melalui proses dekomposisi oleh bakteri pengurai dan digunakan sebagai perangsang pertumbuhan alami tanaman.	Membantu merangsang pertumbuhan tanaman serta menyediakan unsur hara yang mendukung pertumbuhan tanaman. Produk juga mengandung klorofil yang mendukung penggunaannya sebagai perangsang pertumbuhan.	49500.00	1 L	CV. Pendawa Kencana Multi Farm	Yogyakarta	085.643.596.401 (Agus)	Tersedia	Foto Produk 5
PRD-007	Beva Gem	Pestisida organik / agen hayati	Agen hayati berbasis Beauveria bassiana yang digunakan sebagai pestisida organik untuk membantu pengendalian organisme pengganggu tanaman.	Membantu mengendalikan hama tanaman melalui pemanfaatan agen hayati dan mendukung pengendalian hama secara lebih selektif.	30000.00	100 g	CV. Pendawa Kencana Multi Farm	Yogyakarta	085.643.596.401 (Agus)	Tersedia	Foto Produk 6
PRD-008	Metha Gem	Insektisida organik / agen hayati	Agen hayati berbasis Metharizium yang digunakan sebagai insektisida organik untuk membantu pengendalian hama tanaman.	Membantu mengendalikan hama tanaman melalui pemanfaatan agen hayati.	30000.00	100 g	CV. Pendawa Kencana Multi Farm	Yogyakarta	085.643.596.401 (Agus)	Tersedia	Foto Produk 7
PRD-009	Pestisida Organik Pendawa Ampuh	Pestisida Organik	Pestisida organik yang mengandung berbagai jenis tanaman, seperti daun mimba, tembakau, dan tanaman alami lainnya, yang digunakan untuk membantu mencegah dan mengendalikan hama serta penyakit tanaman.	Membantu memberantas hama dan penyakit tanaman, mudah digunakan, aman terhadap lingkungan, serta dapat dikombinasikan dengan metode pengendalian lainnya.	49500.00	1 L	CV. Pendawa Kencana Multi Farm	Yogyakarta	085.643.596.401 (Agus)	Tersedia	Foto Produk 8
PRD-010	Pendawa Subur Pembungaan	Pupuk organik cair	Pupuk cair organik yang dibuat dari bahan berkualitas melalui proses dekomposisi oleh bakteri pengurai dan digunakan sebagai perangsang alami untuk pembungaan dan pembuahan tanaman.	Membantu merangsang pembungaan dan pembuahan tanaman serta mendukung kebutuhan unsur hara tanaman.	49500.00	1 L	CV. Pendawa Kencana Multi Farm	Yogyakarta	085.643.596.401 (Agus)	Tersedia	Foto Produk 9
PRD-011	Pendawa Subur Tunas (ZpT) Organik	Pupuk organik cair	Pupuk organik cair untuk benih dan kecambah yang digunakan untuk mendukung tahap awal pertumbuhan tanaman.	Mendukung perkecambahan benih dan pertumbuhan awal tanaman.	49500.00	1 L	CV. Pendawa Kencana Multi Farm	Yogyakarta	085.643.596.401 (Agus)	Tersedia	Foto Produk 10
\.


--
-- Data for Name: produksi; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.produksi (produksi_id, produk_id, nama_produk, jenis_produk, jumlah_produksi_varian, jumlah_produksi_total, satuan, kapasitas_produk, bahan_baku_aktif, bahan_baku, jumlah_bahan_baku, periode_produksi, status_data, satuan_bahan_baku, satuan_stok, stok) FROM stdin;
PRD001	PRD-002	Probiotik GB Propunic	Probiotik Organik dan Sanitasi	5129.00	5129.00	L	6411.00	Lactobacillus, Saccharomyces, Bacillus	Molase, dedak halus, substrat cair fermentasi, mineral pendukung	4103.000	2020	Sintestis	kg	L	513.000
PRD002	PRD-002	Probiotik GB Propunic	Probiotik Organik dan Sanitasi	5558.00	5558.00	L	6948.00	Lactobacillus, Saccharomyces, Bacillus	Molase, dedak halus, substrat cair fermentasi, mineral pendukung	4446.000	2021	Sintestis	kg	L	556.000
PRD003	PRD-002	Probiotik GB Propunic	Probiotik Organik dan Sanitasi	6454.00	6454.00	L	8068.00	Lactobacillus, Saccharomyces, Bacillus	Molase, dedak halus, substrat cair fermentasi, mineral pendukung	5163.000	2022	Sintestis	kg	L	645.000
PRD004	PRD-002	Probiotik GB Propunic	Probiotik Organik dan Sanitasi	7006.00	7006.00	L	8758.00	Lactobacillus, Saccharomyces, Bacillus	Molase, dedak halus, substrat cair fermentasi, mineral pendukung	5605.000	2023	Sintestis	kg	L	701.000
PRD005	PRD-002	Probiotik GB Propunic	Probiotik Organik dan Sanitasi	7859.00	7859.00	L	9824.00	Lactobacillus, Saccharomyces, Bacillus	Molase, dedak halus, substrat cair fermentasi, mineral pendukung	6287.000	2024	Sintestis	kg	L	786.000
PRD006	PRD-002	Probiotik GB Propunic	Probiotik Organik dan Sanitasi	10200.00	10200.00	L	12750.00	Lactobacillus, Saccharomyces, Bacillus	Molase, dedak halus, substrat cair fermentasi, mineral pendukung	8160.000	2025	Sintestis	kg	L	1020.000
PRD007	PRD-003	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	Probiotik Ternak	3000.00	3000.00	L	3750.00	Lactobacillus, Saccharomyces, Bacillus	Molase, dedak halus, substrat cair fermentasi, mineral pendukung	1800.000	2020	Sintestis	kg	L	300.000
PRD008	PRD-003	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	Probiotik Ternak	3560.00	3560.00	L	4450.00	Lactobacillus, Saccharomyces, Bacillus	Molase, dedak halus, substrat cair fermentasi, mineral pendukung	2136.000	2021	Sintestis	kg	L	356.000
PRD009	PRD-003	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	Probiotik Ternak	5200.00	5200.00	L	6500.00	Lactobacillus, Saccharomyces, Bacillus	Molase, dedak halus, substrat cair fermentasi, mineral pendukung	3120.000	2022	Sintestis	kg	L	520.000
PRD010	PRD-003	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	Probiotik Ternak	6210.00	6210.00	L	7763.00	Lactobacillus, Saccharomyces, Bacillus	Molase, dedak halus, substrat cair fermentasi, mineral pendukung	3726.000	2023	Sintestis	kg	L	621.000
PRD011	PRD-003	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	Probiotik Ternak	6100.00	6100.00	L	7625.00	Lactobacillus, Saccharomyces, Bacillus	Molase, dedak halus, substrat cair fermentasi, mineral pendukung	3660.000	2024	Sintestis	kg	L	610.000
PRD012	PRD-003	Probiotik GB Profeed Untuk Ternak Sehat Gemuk	Probiotik Ternak	9210.00	9210.00	L	11513.00	Lactobacillus, Saccharomyces, Bacillus	Molase, dedak halus, substrat cair fermentasi, mineral pendukung	5526.000	2025	Sintestis	kg	L	921.000
PRD013	PRD-001	Probiotik GB Proquatic	Probiotik perikanan	2450.00	2450.00	L	3175.00	Bacillus subtilis, Nitrosomonas, Nitrobacter	Molase, unsur hara mikro, substrat cair hayati	1270.000	2020	Sintestis	kg	L	254.000
PRD014	PRD-001	Probiotik GB Proquatic	Probiotik perikanan	3400.00	3400.00	L	4250.00	Bacillus subtilis, Nitrosomonas, Nitrobacter	Molase, unsur hara mikro, substrat cair hayati	1700.000	2021	Sintestis	kg	L	340.000
PRD015	PRD-001	Probiotik GB Proquatic	Probiotik perikanan	3300.00	3300.00	L	4125.00	Bacillus subtilis, Nitrosomonas, Nitrobacter	Molase, unsur hara mikro, substrat cair hayati	1650.000	2022	Sintestis	kg	L	330.000
PRD016	PRD-001	Probiotik GB Proquatic	Probiotik perikanan	3000.00	3000.00	L	3750.00	Bacillus subtilis, Nitrosomonas, Nitrobacter	Molase, unsur hara mikro, substrat cair hayati	1500.000	2023	Sintestis	kg	L	300.000
PRD017	PRD-001	Probiotik GB Proquatic	Probiotik perikanan	5200.00	5200.00	L	6500.00	Bacillus subtilis, Nitrosomonas, Nitrobacter	Molase, unsur hara mikro, substrat cair hayati	2600.000	2024	Sintestis	kg	L	520.000
PRD018	PRD-001	Probiotik GB Proquatic	Probiotik perikanan	6000.00	6000.00	L	7500.00	Bacillus subtilis, Nitrosomonas, Nitrobacter	Molase, unsur hara mikro, substrat cair hayati	3000.000	2025	Sintestis	kg	L	600.000
PRD019	PRD-010	Pendawa Subur Pembungaan	Pupuk organik cair	1106.00	2765.00	L	1383.00	Ekstrak organik tinggi Kalium dan Fosfat, mikroba pelarut fosfat	Abu sabut kelapa, batuan fosfat organik, ekstrak buah, molase	1327.000	2020	Sintestis	kg	L	111.000
PRD020	PRD-006	Pendawa Subur Pertumbuhan	Pupuk organik cair	968.00	2765.00	L	1210.00	Nutrisi organik kaya nitrogen, starter mikroba	Urin kelinci, ekstrak bahan organik kaya nitrogen, molase	1162.000	2020	Sintestis	kg	L	97.000
PRD021	PRD-011	Pendawa Subur Tunas (ZpT) Organik	Pupuk organik cair	691.00	2765.00	L	864.00	Sitokinin, Auksin, asam humat	Ekstrak tanaman, rumput laut, bahan organik sumber asam humat	829.000	2020	Sintestis	kg	L	69.000
PRD022	PRD-010	Pendawa Subur Pembungaan	Pupuk organik cair	1218.00	3044.00	L	1523.00	Ekstrak organik tinggi Kalium dan Fosfat, mikroba pelarut fosfat	Abu sabut kelapa, batuan fosfat organik, ekstrak buah, molase	1462.000	2021	Sintestis	kg	L	122.000
PRD023	PRD-006	Pendawa Subur Pertumbuhan	Pupuk organik cair	1065.00	3044.00	L	1331.00	Nutrisi organik kaya nitrogen, starter mikroba	Urin kelinci, ekstrak bahan organik kaya nitrogen, molase	1278.000	2021	Sintestis	kg	L	107.000
PRD024	PRD-011	Pendawa Subur Tunas (ZpT) Organik	Pupuk organik cair	761.00	3044.00	L	951.00	Sitokinin, Auksin, asam humat	Ekstrak tanaman, rumput laut, bahan organik sumber asam humat	913.000	2021	Sintestis	kg	L	76.000
PRD025	PRD-010	Pendawa Subur Pembungaan	Pupuk organik cair	1281.00	3202.00	L	1601.00	Ekstrak organik tinggi Kalium dan Fosfat, mikroba pelarut fosfat	Abu sabut kelapa, batuan fosfat organik, ekstrak buah, molase	1537.000	2022	Sintestis	kg	L	128.000
PRD026	PRD-006	Pendawa Subur Pertumbuhan	Pupuk organik cair	1121.00	3202.00	L	1410.00	Nutrisi organik kaya nitrogen, starter mikroba	Urin kelinci, ekstrak bahan organik kaya nitrogen, molase	1345.000	2022	Sintestis	kg	L	112.000
PRD027	PRD-011	Pendawa Subur Tunas (ZpT) Organik	Pupuk organik cair	800.00	3202.00	L	1000.00	Sitokinin, Auksin, asam humat	Ekstrak tanaman, rumput laut, bahan organik sumber asam humat	960.000	2022	Sintestis	kg	L	80.000
PRD028	PRD-010	Pendawa Subur Pembungaan	Pupuk organik cair	1545.00	3862.00	L	1931.00	Ekstrak organik tinggi Kalium dan Fosfat, mikroba pelarut fosfat	Abu sabut kelapa, batuan fosfat organik, ekstrak buah, molase	1854.000	2023	Sintestis	kg	L	155.000
PRD029	PRD-006	Pendawa Subur Pertumbuhan	Pupuk organik cair	1352.00	3862.00	L	1690.00	Nutrisi organik kaya nitrogen, starter mikroba	Urin kelinci, ekstrak bahan organik kaya nitrogen, molase	1622.000	2023	Sintestis	kg	L	135.000
PRD030	PRD-011	Pendawa Subur Tunas (ZpT) Organik	Pupuk organik cair	965.00	3862.00	L	1206.00	Sitokinin, Auksin, asam humat	Ekstrak tanaman, rumput laut, bahan organik sumber asam humat	1158.000	2023	Sintestis	kg	L	97.000
PRD031	PRD-010	Pendawa Subur Pembungaan	Pupuk organik cair	1871.00	4678.00	L	2339.00	Ekstrak organik tinggi Kalium dan Fosfat, mikroba pelarut fosfat	Abu sabut kelapa, batuan fosfat organik, ekstrak buah, molase	2245.000	2024	Sintestis	kg	L	187.000
PRD032	PRD-006	Pendawa Subur Pertumbuhan	Pupuk organik cair	1637.00	4678.00	L	2046.00	Nutrisi organik kaya nitrogen, starter mikroba	Urin kelinci, ekstrak bahan organik kaya nitrogen, molase	1964.000	2024	Sintestis	kg	L	164.000
PRD033	PRD-011	Pendawa Subur Tunas (ZpT) Organik	Pupuk organik cair	1170.00	4678.00	L	1463.00	Sitokinin, Auksin, asam humat	Ekstrak tanaman, rumput laut, bahan organik sumber asam humat	1404.000	2024	Sintestis	kg	L	117.000
PRD034	PRD-010	Pendawa Subur Pembungaan	Pupuk organik cair	2234.00	5584.00	L	2793.00	Ekstrak organik tinggi Kalium dan Fosfat, mikroba pelarut fosfat	Abu sabut kelapa, batuan fosfat organik, ekstrak buah, molase	2681.000	2025	Sintestis	kg	L	223.000
PRD035	PRD-006	Pendawa Subur Pertumbuhan	Pupuk organik cair	1954.00	5584.00	L	2443.00	Nutrisi organik kaya nitrogen, starter mikroba	Urin kelinci, ekstrak bahan organik kaya nitrogen, molase	2345.000	2025	Sintestis	kg	L	195.000
PRD036	PRD-011	Pendawa Subur Tunas (ZpT) Organik	Pupuk organik cair	1396.00	5584.00	L	1745.00	Sitokinin, Auksin, asam humat	Ekstrak tanaman, rumput laut, bahan organik sumber asam humat	1675.000	2025	Sintestis	kg	L	140.000
PRD037	PRD-005	Tricogem Fungisida Organik	Fungisida organik / agen hayati	248.00	620.00	Kg	310.00	Trichoderma harzianum	Beras, jagung halus, carrier cair	273.000	2020	Sintestis	kg	kg	25.000
PRD038	PRD-008	Metha Gem	Insektisida organik / agen hayati	186.00	620.00	Kg	233.00	Metarhizium anisopliae	Substrat nutrisi biakan	205.000	2020	Sintestis	kg	kg	19.000
PRD039	PRD-007	Beva Gem	Pestisida organik / agen hayati	186.00	620.00	Kg	233.00	Beauveria bassiana	Media nutrisi perbanyakan jamur	205.000	2020	Sintestis	kg	kg	19.000
PRD040	PRD-005	Tricogem Fungisida Organik	Fungisida organik / agen hayati	293.00	732.00	Kg	366.00	Trichoderma harzianum	Beras, jagung halus, carrier cair	322.000	2021	Sintestis	kg	kg	29.000
PRD041	PRD-008	Metha Gem	Insektisida organik / agen hayati	220.00	732.00	Kg	275.00	Metarhizium anisopliae	Substrat nutrisi biakan	242.000	2021	Sintestis	kg	kg	22.000
PRD042	PRD-007	Beva Gem	Pestisida organik / agen hayati	219.00	732.00	Kg	274.00	Beauveria bassiana	Media nutrisi perbanyakan jamur	241.000	2021	Sintestis	kg	kg	22.000
PRD043	PRD-005	Tricogem Fungisida Organik	Fungisida organik / agen hayati	302.00	755.00	Kg	378.00	Trichoderma harzianum	Beras, jagung halus, carrier cair	332.000	2022	Sintestis	kg	kg	30.000
PRD044	PRD-008	Metha Gem	Insektisida organik / agen hayati	227.00	755.00	Kg	284.00	Metarhizium anisopliae	Substrat nutrisi biakan	250.000	2022	Sintestis	kg	kg	23.000
PRD045	PRD-007	Beva Gem	Pestisida organik / agen hayati	226.00	755.00	Kg	283.00	Beauveria bassiana	Media nutrisi perbanyakan jamur	249.000	2022	Sintestis	kg	kg	23.000
PRD046	PRD-005	Tricogem Fungisida Organik	Fungisida organik / agen hayati	376.00	940.00	Kg	470.00	Trichoderma harzianum	Beras, jagung halus, carrier cair	414.000	2023	Sintestis	kg	kg	38.000
PRD047	PRD-008	Metha Gem	Insektisida organik / agen hayati	282.00	940.00	Kg	353.00	Metarhizium anisopliae	Substrat nutrisi biakan	310.000	2023	Sintestis	kg	kg	28.000
PRD048	PRD-007	Beva Gem	Pestisida organik / agen hayati	282.00	940.00	Kg	353.00	Beauveria bassiana	Media nutrisi perbanyakan jamur	310.000	2023	Sintestis	kg	kg	28.000
PRD049	PRD-005	Tricogem Fungisida Organik	Fungisida organik / agen hayati	510.00	1275.00	Kg	638.00	Trichoderma harzianum	Beras, jagung halus, carrier cair	561.000	2024	Sintestis	kg	kg	51.000
PRD050	PRD-008	Metha Gem	Insektisida organik / agen hayati	383.00	1275.00	Kg	479.00	Metarhizium anisopliae	Substrat nutrisi biakan	421.000	2024	Sintestis	kg	kg	38.000
PRD051	PRD-007	Beva Gem	Pestisida organik / agen hayati	382.00	1275.00	Kg	478.00	Beauveria bassiana	Media nutrisi perbanyakan jamur	420.000	2024	Sintestis	kg	kg	38.000
PRD052	PRD-005	Tricogem Fungisida Organik	Fungisida organik / agen hayati	568.00	1420.00	Kg	710.00	Trichoderma harzianum	Beras, jagung halus, carrier cair	625.000	2025	Sintestis	kg	kg	57.000
PRD053	PRD-008	Metha Gem	Insektisida organik / agen hayati	426.00	1420.00	Kg	533.00	Metarhizium anisopliae	Substrat nutrisi biakan	469.000	2025	Sintestis	kg	kg	43.000
PRD054	PRD-007	Beva Gem	Pestisida organik / agen hayati	426.00	1420.00	Kg	533.00	Beauveria bassiana	Media nutrisi perbanyakan jamur	469.000	2025	Sintestis	kg	kg	43.000
PRD055	PRD-004	Compossap Pupuk Organik Padat dari Kotoran Ternak	Pupuk organik padat	1305.00	1305.00	Zak	1631.00	Trichoderma, Aspergillus, bakteri selulolitik	Molase, media pembawa organik	32625.000	2020	Sintestis	kg	zak	131.000
PRD056	PRD-004	Compossap Pupuk Organik Padat dari Kotoran Ternak	Pupuk organik padat	1383.00	1383.00	Zak	1729.00	Trichoderma, Aspergillus, bakteri selulolitik	Molase, media pembawa organik	34575.000	2021	Sintestis	kg	zak	138.000
PRD057	PRD-004	Compossap Pupuk Organik Padat dari Kotoran Ternak	Pupuk organik padat	1590.00	1590.00	Zak	1988.00	Trichoderma, Aspergillus, bakteri selulolitik	Molase, media pembawa organik	39750.000	2022	Sintestis	kg	zak	159.000
PRD058	PRD-004	Compossap Pupuk Organik Padat dari Kotoran Ternak	Pupuk organik padat	1377.00	1377.00	Zak	1721.00	Trichoderma, Aspergillus, bakteri selulolitik	Molase, media pembawa organik	34425.000	2023	Sintestis	kg	zak	138.000
PRD059	PRD-004	Compossap Pupuk Organik Padat dari Kotoran Ternak	Pupuk organik padat	1420.00	1420.00	Zak	1755.00	Trichoderma, Aspergillus, bakteri selulolitik	Molase, media pembawa organik	35500.000	2024	Sintestis	kg	zak	142.000
PRD060	PRD-004	Compossap Pupuk Organik Padat dari Kotoran Ternak	Pupuk organik padat	3200.00	3200.00	Zak	4000.00	Trichoderma, Aspergillus, bakteri selulolitik	Molase, media pembawa organik	80000.000	2025	Sintestis	kg	zak	320.000
PRD061	PRD-009	Pestisida Organik Pendawa Ampuh	Pestisida Organik	600.00	600.00	L	750.00	Daun mimba (imba), tembakau, dan tanaman alami lain sebagai bahan penolak hama	Daun mimba, bahan nabati lokal, ekstrak tanaman pengendali hama	180.000	2020	Sintestis	kg	L	60.000
PRD062	PRD-009	Pestisida Organik Pendawa Ampuh	Pestisida Organik	650.00	650.00	L	813.00	Daun mimba (imba), tembakau, dan tanaman alami lain sebagai bahan penolak hama	Daun mimba, bahan nabati lokal, ekstrak tanaman pengendali hama	195.000	2021	Sintestis	kg	L	65.000
PRD063	PRD-009	Pestisida Organik Pendawa Ampuh	Pestisida Organik	700.00	700.00	L	875.00	Daun mimba (imba), tembakau, dan tanaman alami lain sebagai bahan penolak hama	Daun mimba, bahan nabati lokal, ekstrak tanaman pengendali hama	210.000	2022	Sintestis	kg	L	70.000
PRD064	PRD-009	Pestisida Organik Pendawa Ampuh	Pestisida Organik	800.00	800.00	L	1000.00	Daun mimba (imba), tembakau, dan tanaman alami lain sebagai bahan penolak hama	Daun mimba, bahan nabati lokal, ekstrak tanaman pengendali hama	240.000	2023	Sintestis	kg	L	80.000
PRD065	PRD-009	Pestisida Organik Pendawa Ampuh	Pestisida Organik	900.00	900.00	L	1125.00	Daun mimba (imba), tembakau, dan tanaman alami lain sebagai bahan penolak hama	Daun mimba, bahan nabati lokal, ekstrak tanaman pengendali hama	270.000	2024	Sintestis	kg	L	90.000
PRD066	PRD-009	Pestisida Organik Pendawa Ampuh	Pestisida Organik	1000.00	1000.00	L	1250.00	Daun mimba (imba), tembakau, dan tanaman alami lain sebagai bahan penolak hama	Daun mimba, bahan nabati lokal, ekstrak tanaman pengendali hama	300.000	2025	Sintestis	kg	L	100.000
\.


--
-- Data for Name: staging_import_run; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.staging_import_run (run_id, started_at, finished_at, source_sha256, mode, status, report) FROM stdin;
006f4f6e016f4bcbb51dad85fe68a59c	2026-10-24 00:24:35.975381+07	2026-10-24 00:24:39.796581+07	0f352dec5dc71410294196678590f9702a20732210aa89f09309473b33cfcc13	apply	applied	{"pii": {"note": "Nilai kontak tidak ditulis ke laporan/log; kolom tetap dimuat ke tabel produk.", "redacted_in_reports": ["kontak"]}, "mode": "apply", "run_id": "006f4f6e016f4bcbb51dad85fe68a59c", "schema": {"columns": {"produk": {"extra_columns": [], "missing_columns": []}, "produksi": {"extra_columns": [], "missing_columns": []}, "kalurahan": {"extra_columns": [], "missing_columns": []}, "padukuhan": {"extra_columns": [], "missing_columns": []}, "penjualan": {"extra_columns": [], "missing_columns": []}, "bahan_organik": {"extra_columns": [], "missing_columns": []}, "data_pertanian": {"extra_columns": [], "missing_columns": []}, "ketersediaan_bahan": {"extra_columns": [], "missing_columns": []}, "data_pertanian_real": {"extra_columns": [], "missing_columns": []}, "produk_katalog_audit": {"extra_columns": [], "missing_columns": []}}, "missing_tables": [], "existing_tables": ["bahan_organik", "data_pertanian", "data_pertanian_real", "kalurahan", "ketersediaan_bahan", "padukuhan", "penjualan", "produk", "produk_katalog_audit", "produksi", "staging_import_run"]}, "source": {"path": "C:\\\\Users\\\\Arif Raharjo\\\\Documents\\\\project-ebil\\\\Data Projek Vinix (1).xlsx", "sha256": "0f352dec5dc71410294196678590f9702a20732210aa89f09309473b33cfcc13", "sheet_count": 13, "etl_sheet_count": 9, "row_column_note": "Baris/kolom adalah extent pandas tanpa header; baris berformat kosong tidak dihitung.", "archive_sheet_count": 4}, "status": "applied", "tables": {"produk": {"columns": ["produk_id", "nama_produk", "jenis_produk", "deskripsi", "manfaat", "harga", "ukuran_kemasan", "produsen", "lokasi_produsen", "kontak", "stok_ketersediaan", "foto_produk"], "valid_rows": 11, "natural_key": null, "primary_key": "produk_id", "source_rows": 11, "source_sheet": "Data_Produk_Katalog", "rejected_rows": 0, "primary_key_unique": true, "rejected_excel_rows": [], "collapsed_duplicates": 0, "natural_key_duplicates": 0, "primary_key_duplicates": 0}, "produksi": {"columns": ["produksi_id", "produk_id", "nama_produk", "jenis_produk", "jumlah_produksi_varian", "jumlah_produksi_total", "satuan", "kapasitas_produk", "bahan_baku_aktif", "bahan_baku", "jumlah_bahan_baku", "periode_produksi", "status_data", "satuan_bahan_baku", "satuan_stok", "stok"], "valid_rows": 66, "natural_key": ["produk_id", "periode_produksi"], "primary_key": "produksi_id", "source_rows": 66, "source_sheet": "Data_produksi_pupuk", "rejected_rows": 0, "primary_key_unique": true, "rejected_excel_rows": [], "collapsed_duplicates": 0, "natural_key_duplicates": 0, "primary_key_duplicates": 0}, "kalurahan": {"columns": ["kalurahan_id", "kalurahan", "luas_kalurahan_ha", "jumlah_padukuhan", "jumlah_rw", "jumlah_rt", "batas_utara", "batas_selatan", "batas_barat", "batas_timur", "jarak_kecamatan_km", "jarak_kabupaten_km", "jarak_provinsi_km", "jarak_nasional_km", "latitude", "longitude"], "valid_rows": 5, "natural_key": null, "primary_key": "kalurahan_id", "source_rows": 5, "source_sheet": "Data Wilayah_Kalurahan", "rejected_rows": 0, "primary_key_unique": true, "rejected_excel_rows": [], "collapsed_duplicates": 0, "natural_key_duplicates": 0, "primary_key_duplicates": 0}, "padukuhan": {"columns": ["padukuhan_id", "kalurahan_id", "kalurahan", "padukuhan", "jumlah_rt", "jumlah_rw", "latitude", "longitude"], "valid_rows": 73, "natural_key": ["kalurahan_id", "padukuhan"], "primary_key": "padukuhan_id", "source_rows": 73, "source_sheet": "Data_Wilayah_Padukuhan", "rejected_rows": 0, "primary_key_unique": true, "rejected_excel_rows": [], "collapsed_duplicates": 0, "natural_key_duplicates": 0, "primary_key_duplicates": 0}, "penjualan": {"columns": ["penjualan_id", "produk_id", "bulan", "produk", "jumlah_terjual", "harga_satuan", "total_penjualan", "satuan", "kanal", "status_data"], "valid_rows": 792, "natural_key": ["produk_id", "bulan"], "primary_key": "penjualan_id", "source_rows": 792, "source_sheet": "Data_Penjualan", "rejected_rows": 0, "primary_key_unique": true, "rejected_excel_rows": [], "collapsed_duplicates": 0, "natural_key_duplicates": 0, "primary_key_duplicates": 0}, "bahan_organik": {"columns": ["bahan_id", "jenis_bahan_organik", "kategori_bahan"], "valid_rows": 17, "natural_key": null, "primary_key": "bahan_id", "source_rows": 88, "source_sheet": "Data_Bahan_Organik", "rejected_rows": 0, "primary_key_unique": true, "rejected_excel_rows": [], "collapsed_duplicates": 71, "natural_key_duplicates": 0, "primary_key_duplicates": 0}, "data_pertanian": {"columns": ["agri_id", "kalurahan", "padukuhan_id", "padukuhan", "komoditas", "kelompok_komoditas", "tahun", "luas_panen_ha", "luas_lahan_ha", "jumlah_petani", "jumlah_utp", "jumlah_kelompok_tani", "produksi", "satuan_produksi_q"], "valid_rows": 511, "natural_key": ["padukuhan_id", "komoditas", "tahun"], "primary_key": "agri_id", "source_rows": 511, "source_sheet": "Data_Pertanian", "rejected_rows": 0, "primary_key_unique": true, "rejected_excel_rows": [], "collapsed_duplicates": 0, "natural_key_duplicates": 0, "primary_key_duplicates": 0}, "ketersediaan_bahan": {"columns": ["ketersediaan_id", "bahan_id", "padukuhan_id", "periode", "jumlah_ketersediaan", "satuan", "kontinuitas", "jarak_ke_produksi_km", "kemudahan_pengumpulan", "status_pemanfaatan", "frekuensi", "musim", "jumlah_sumber", "status_data"], "valid_rows": 88, "natural_key": ["bahan_id", "padukuhan_id", "periode"], "primary_key": "ketersediaan_id", "source_rows": 88, "source_sheet": "Data_Bahan_Organik", "rejected_rows": 0, "primary_key_unique": true, "rejected_excel_rows": [], "collapsed_duplicates": 0, "natural_key_duplicates": 0, "primary_key_duplicates": 0}, "data_pertanian_real": {"columns": ["agri_id", "wilayah", "komoditas", "luas_panen_ha", "luas_lahan_ha", "jumlah_utp", "produksi", "satuan_produksi", "tahun_produksi", "tahun_utp", "sumber_produksi", "sumber_utp", "status_data", "catatan"], "valid_rows": 14, "natural_key": ["wilayah", "komoditas", "tahun_produksi"], "primary_key": "agri_id", "source_rows": 14, "source_sheet": "Data Pertanian_real", "rejected_rows": 0, "primary_key_unique": true, "rejected_excel_rows": [], "collapsed_duplicates": 0, "natural_key_duplicates": 0, "primary_key_duplicates": 0}, "produk_katalog_audit": {"columns": ["produk_id", "nama_produk", "jenis_produk", "deskripsi", "manfaat", "harga", "ukuran_kemasan", "produsen", "lokasi_produsen", "kontak", "stok_ketersediaan", "foto_produk"], "valid_rows": 11, "natural_key": null, "primary_key": "produk_id", "source_rows": 11, "source_sheet": "Produk_Katalog", "rejected_rows": 0, "primary_key_unique": true, "rejected_excel_rows": [], "collapsed_duplicates": 0, "natural_key_duplicates": 0, "primary_key_duplicates": 0}}, "target": {"host": "localhost", "port": 5432, "user": "postgres", "driver": "postgresql+psycopg2", "database": "vinix7"}, "mapping": {"Data_Penjualan": "penjualan", "Data_Pertanian": "data_pertanian", "Produk_Katalog": "produk_katalog_audit", "Data_Bahan_Organik": "bahan_organik + ketersediaan_bahan", "Data Pertanian_real": "data_pertanian_real", "Data_Produk_Katalog": "produk", "Data_produksi_pupuk": "produksi", "Data Wilayah_Kalurahan": "kalurahan", "Data_Wilayah_Padukuhan": "padukuhan"}, "catalogs": {"identical": true, "main_rows": 11, "audit_rows": 11, "stored_separately": true}, "warnings": [{"code": "kalurahan_distance_datetime_null", "count": 1, "message": "jarak_kecamatan_km berupa tanggal pada satu kalurahan; disimpan NULL.", "examples": [{"excel_row": 3, "kalurahan_id": "KAL-002"}]}, {"code": "organic_distance_unverified", "count": 88, "message": "Semua jarak_ke_produksi_km disimpan NULL karena sumber belum terverifikasi.", "examples": [], "numeric_values": 8, "datetime_values": 80}, {"code": "production_status_typo", "count": 66, "message": "Nilai status_data 'Sintestis' dipertahankan apa adanya.", "examples": []}, {"code": "production_total_is_repeated_group_total", "count": 36, "message": "Jumlah_produksi_total adalah total kelompok berulang; jangan dijumlahkan.", "examples": [], "sum_total": 200392.0, "sum_varian": 142638.0}, {"code": "sales_zero_quantity_kept", "count": 253, "message": "Baris penjualan dengan jumlah 0 dipertahankan.", "examples": []}, {"code": "real_agriculture_missing_luas_lahan_ha", "count": 14, "message": "Data real pertanian memiliki nilai kosong pada luas_lahan_ha.", "examples": []}, {"code": "real_agriculture_missing_jumlah_utp", "count": 9, "message": "Data real pertanian memiliki nilai kosong pada jumlah_utp.", "examples": []}, {"code": "real_agriculture_missing_produksi", "count": 8, "message": "Data real pertanian memiliki nilai kosong pada produksi.", "examples": []}], "started_at": "2026-10-23T17:24:35.975381+00:00", "finished_at": "2026-10-23T17:24:39.796581+00:00", "sheet_audit": [{"role": "etl_source", "rows": 66, "sheet": "Data_produksi_pupuk", "columns": 14, "column_info": [{"name": "produksi_id", "non_null": 66, "pandas_dtype": "object", "unique_non_null": 66}, {"name": "produk_id", "non_null": 66, "pandas_dtype": "object", "unique_non_null": 11}, {"name": "Nama_Produk", "non_null": 66, "pandas_dtype": "object", "unique_non_null": 11}, {"name": "Jenis_Produk", "non_null": 66, "pandas_dtype": "object", "unique_non_null": 9}, {"name": "Jumlah_produksi_varian", "non_null": 66, "pandas_dtype": "int64", "unique_non_null": 60}, {"name": "Jumlah_produksi_total", "non_null": 66, "pandas_dtype": "int64", "unique_non_null": 39}, {"name": "Satuan", "non_null": 66, "pandas_dtype": "object", "unique_non_null": 3}, {"name": "Kapasitas-produk", "non_null": 66, "pandas_dtype": "int64", "unique_non_null": 60}, {"name": "Bahan_baku_aktif", "non_null": 66, "pandas_dtype": "object", "unique_non_null": 10}, {"name": "Bahan_baku", "non_null": 66, "pandas_dtype": "object", "unique_non_null": 10}, {"name": "jumlah_bahan_baku", "non_null": 66, "pandas_dtype": "object", "unique_non_null": 63}, {"name": "Periode_produksi", "non_null": 66, "pandas_dtype": "int64", "unique_non_null": 6}, {"name": "Stok", "non_null": 66, "pandas_dtype": "object", "unique_non_null": 54}, {"name": "status_data", "non_null": 66, "pandas_dtype": "object", "unique_non_null": 1}]}, {"role": "etl_source", "rows": 88, "sheet": "Data_Bahan_Organik", "columns": 16, "column_info": [{"name": "bahan_id", "non_null": 88, "pandas_dtype": "object", "unique_non_null": 17}, {"name": "jenis_bahan_organik", "non_null": 88, "pandas_dtype": "object", "unique_non_null": 17}, {"name": "kategori_bahan", "non_null": 88, "pandas_dtype": "object", "unique_non_null": 10}, {"name": "ketersediaan_id", "non_null": 88, "pandas_dtype": "object", "unique_non_null": 88}, {"name": "padukuhan_id", "non_null": 88, "pandas_dtype": "object", "unique_non_null": 73}, {"name": "periode", "non_null": 88, "pandas_dtype": "datetime64[ns]", "unique_non_null": 12}, {"name": "jumlah_ketersediaan", "non_null": 88, "pandas_dtype": "int64", "unique_non_null": 88}, {"name": "satuan", "non_null": 88, "pandas_dtype": "object", "unique_non_null": 1}, {"name": "kontinuitas", "non_null": 88, "pandas_dtype": "object", "unique_non_null": 4}, {"name": "jarak_ke_produksi_km", "non_null": 88, "pandas_dtype": "object", "unique_non_null": 23}, {"name": "kemudahan_pengumpulan", "non_null": 88, "pandas_dtype": "object", "unique_non_null": 3}, {"name": "status_pemanfaatan", "non_null": 88, "pandas_dtype": "object", "unique_non_null": 4}, {"name": "frekuensi", "non_null": 88, "pandas_dtype": "object", "unique_non_null": 4}, {"name": "musim", "non_null": 88, "pandas_dtype": "object", "unique_non_null": 3}, {"name": "jumlah_sumber", "non_null": 88, "pandas_dtype": "int64", "unique_non_null": 10}, {"name": "status_data", "non_null": 88, "pandas_dtype": "object", "unique_non_null": 1}]}, {"role": "etl_source", "rows": 11, "sheet": "Produk_Katalog", "columns": 12, "column_info": [{"name": "produk_id", "non_null": 11, "pandas_dtype": "object", "unique_non_null": 11}, {"name": "Nama_Produk", "non_null": 11, "pandas_dtype": "object", "unique_non_null": 11}, {"name": "Jenis_Produk", "non_null": 11, "pandas_dtype": "object", "unique_non_null": 9}, {"name": "Deskripsi", "non_null": 11, "pandas_dtype": "object", "unique_non_null": 11}, {"name": "Manfaat", "non_null": 11, "pandas_dtype": "object", "unique_non_null": 11}, {"name": "Harga", "non_null": 11, "pandas_dtype": "int64", "unique_non_null": 5}, {"name": "Ukuran_Kemasan", "non_null": 11, "pandas_dtype": "object", "unique_non_null": 3}, {"name": "Produsen", "non_null": 11, "pandas_dtype": "object", "unique_non_null": 1}, {"name": "Lokasi_Produsen", "non_null": 11, "pandas_dtype": "object", "unique_non_null": 1}, {"name": "Kontak", "non_null": 11, "pandas_dtype": "object", "unique_non_null": 1}, {"name": "Stok_Ketersediaan", "non_null": 11, "pandas_dtype": "object", "unique_non_null": 1}, {"name": "Foto Produk", "non_null": 11, "pandas_dtype": "object", "unique_non_null": 11}]}, {"role": "etl_source", "rows": 11, "sheet": "Data_Produk_Katalog", "columns": 12, "column_info": [{"name": "produk_id", "non_null": 11, "pandas_dtype": "object", "unique_non_null": 11}, {"name": "Nama_Produk", "non_null": 11, "pandas_dtype": "object", "unique_non_null": 11}, {"name": "Jenis_Produk", "non_null": 11, "pandas_dtype": "object", "unique_non_null": 9}, {"name": "Deskripsi", "non_null": 11, "pandas_dtype": "object", "unique_non_null": 11}, {"name": "Manfaat", "non_null": 11, "pandas_dtype": "object", "unique_non_null": 11}, {"name": "Harga", "non_null": 11, "pandas_dtype": "int64", "unique_non_null": 5}, {"name": "Ukuran_Kemasan", "non_null": 11, "pandas_dtype": "object", "unique_non_null": 3}, {"name": "Produsen", "non_null": 11, "pandas_dtype": "object", "unique_non_null": 1}, {"name": "Lokasi_Produsen", "non_null": 11, "pandas_dtype": "object", "unique_non_null": 1}, {"name": "Kontak", "non_null": 11, "pandas_dtype": "object", "unique_non_null": 1}, {"name": "Stok_Ketersediaan", "non_null": 11, "pandas_dtype": "object", "unique_non_null": 1}, {"name": "Foto Produk", "non_null": 11, "pandas_dtype": "object", "unique_non_null": 11}]}, {"role": "etl_source", "rows": 792, "sheet": "Data_Penjualan", "columns": 10, "column_info": [{"name": "Penjualan_id", "non_null": 792, "pandas_dtype": "object", "unique_non_null": 792}, {"name": "Produk_id", "non_null": 792, "pandas_dtype": "object", "unique_non_null": 11}, {"name": "Bulan", "non_null": 792, "pandas_dtype": "datetime64[ns]", "unique_non_null": 72}, {"name": "Produk", "non_null": 792, "pandas_dtype": "object", "unique_non_null": 11}, {"name": "Jumlah_Terjual", "non_null": 792, "pandas_dtype": "int64", "unique_non_null": 47}, {"name": "Harga_Satuan", "non_null": 792, "pandas_dtype": "int64", "unique_non_null": 5}, {"name": "Total_Penjualan", "non_null": 792, "pandas_dtype": "int64", "unique_non_null": 80}, {"name": "Satuan", "non_null": 792, "pandas_dtype": "object", "unique_non_null": 3}, {"name": "Kanal", "non_null": 792, "pandas_dtype": "object", "unique_non_null": 1}, {"name": "Status_Data", "non_null": 792, "pandas_dtype": "object", "unique_non_null": 1}]}, {"role": "etl_source", "rows": 5, "sheet": "Data Wilayah_Kalurahan", "columns": 16, "column_info": [{"name": "kalurahan_id", "non_null": 5, "pandas_dtype": "object", "unique_non_null": 5}, {"name": "kalurahan", "non_null": 5, "pandas_dtype": "object", "unique_non_null": 5}, {"name": "luas_kalurahan_ha", "non_null": 5, "pandas_dtype": "int64", "unique_non_null": 5}, {"name": "jumlah_padukuhan", "non_null": 5, "pandas_dtype": "int64", "unique_non_null": 5}, {"name": "jumlah_rw", "non_null": 5, "pandas_dtype": "int64", "unique_non_null": 4}, {"name": "jumlah_rt", "non_null": 5, "pandas_dtype": "int64", "unique_non_null": 5}, {"name": "batas_utara", "non_null": 5, "pandas_dtype": "object", "unique_non_null": 3}, {"name": "batas_selatan", "non_null": 5, "pandas_dtype": "object", "unique_non_null": 4}, {"name": "batas_barat", "non_null": 5, "pandas_dtype": "object", "unique_non_null": 5}, {"name": "batas_timur", "non_null": 5, "pandas_dtype": "object", "unique_non_null": 5}, {"name": "jarak_kecamatan_km", "non_null": 5, "pandas_dtype": "object", "unique_non_null": 5}, {"name": "jarak_kabupaten_km", "non_null": 5, "pandas_dtype": "int64", "unique_non_null": 5}, {"name": "jarak_provinsi_km", "non_null": 5, "pandas_dtype": "int64", "unique_non_null": 5}, {"name": "jarak_nasional_km", "non_null": 5, "pandas_dtype": "int64", "unique_non_null": 4}, {"name": "latitude", "non_null": 5, "pandas_dtype": "float64", "unique_non_null": 5}, {"name": "longitude", "non_null": 5, "pandas_dtype": "float64", "unique_non_null": 5}]}, {"role": "etl_source", "rows": 73, "sheet": "Data_Wilayah_Padukuhan", "columns": 8, "column_info": [{"name": "padukuhan_id", "non_null": 73, "pandas_dtype": "object", "unique_non_null": 73}, {"name": "kalurahan_id", "non_null": 73, "pandas_dtype": "object", "unique_non_null": 5}, {"name": "kalurahan", "non_null": 73, "pandas_dtype": "object", "unique_non_null": 5}, {"name": "padukuhan", "non_null": 73, "pandas_dtype": "object", "unique_non_null": 72}, {"name": "jumlah_rt", "non_null": 73, "pandas_dtype": "int64", "unique_non_null": 4}, {"name": "jumlah_rw", "non_null": 73, "pandas_dtype": "int64", "unique_non_null": 3}, {"name": "latitude", "non_null": 73, "pandas_dtype": "float64", "unique_non_null": 70}, {"name": "longitude", "non_null": 73, "pandas_dtype": "float64", "unique_non_null": 67}]}, {"role": "etl_source", "rows": 511, "sheet": "Data_Pertanian", "columns": 14, "column_info": [{"name": "agri_id", "non_null": 511, "pandas_dtype": "object", "unique_non_null": 511}, {"name": "kalurahan", "non_null": 511, "pandas_dtype": "object", "unique_non_null": 5}, {"name": "padukuhan_id", "non_null": 511, "pandas_dtype": "object", "unique_non_null": 73}, {"name": "padukuhan", "non_null": 511, "pandas_dtype": "object", "unique_non_null": 72}, {"name": "komoditas", "non_null": 511, "pandas_dtype": "object", "unique_non_null": 7}, {"name": "kelompok_komoditas", "non_null": 511, "pandas_dtype": "object", "unique_non_null": 2}, {"name": "tahun", "non_null": 511, "pandas_dtype": "int64", "unique_non_null": 2}, {"name": "luas_panen_ha", "non_null": 511, "pandas_dtype": "float64", "unique_non_null": 480}, {"name": "luas_lahan_ha", "non_null": 511, "pandas_dtype": "float64", "unique_non_null": 490}, {"name": "jumlah_petani", "non_null": 511, "pandas_dtype": "int64", "unique_non_null": 26}, {"name": "jumlah_utp", "non_null": 511, "pandas_dtype": "int64", "unique_non_null": 22}, {"name": "jumlah_kelompok_tani", "non_null": 511, "pandas_dtype": "int64", "unique_non_null": 3}, {"name": "produksi", "non_null": 511, "pandas_dtype": "float64", "unique_non_null": 492}, {"name": "satuan_produksi_q", "non_null": 511, "pandas_dtype": "object", "unique_non_null": 1}]}, {"role": "archive_only", "rows": 792, "sheet": "Copy of Data_Penjualan", "columns": 19, "column_info": [{"name": "Penjualan_id", "non_null": 792, "pandas_dtype": "object", "unique_non_null": 792}, {"name": "Produk_id", "non_null": 792, "pandas_dtype": "object", "unique_non_null": 11}, {"name": "Bulan", "non_null": 792, "pandas_dtype": "datetime64[ns]", "unique_non_null": 72}, {"name": "Produk", "non_null": 792, "pandas_dtype": "object", "unique_non_null": 11}, {"name": "Jumlah_Terjual", "non_null": 792, "pandas_dtype": "int64", "unique_non_null": 47}, {"name": "Harga_Satuan", "non_null": 792, "pandas_dtype": "int64", "unique_non_null": 5}, {"name": "Total_Penjualan", "non_null": 792, "pandas_dtype": "int64", "unique_non_null": 80}, {"name": "Satuan", "non_null": 792, "pandas_dtype": "object", "unique_non_null": 3}, {"name": "Kanal", "non_null": 792, "pandas_dtype": "object", "unique_non_null": 1}, {"name": "Status_Data", "non_null": 792, "pandas_dtype": "object", "unique_non_null": 1}, {"name": "Unnamed: 10", "non_null": 0, "pandas_dtype": "float64", "unique_non_null": 0}, {"name": "Unnamed: 11", "non_null": 13, "pandas_dtype": "object", "unique_non_null": 13}, {"name": "2020", "non_null": 12, "pandas_dtype": "float64", "unique_non_null": 11}, {"name": "2021", "non_null": 12, "pandas_dtype": "float64", "unique_non_null": 10}, {"name": "2022", "non_null": 12, "pandas_dtype": "float64", "unique_non_null": 9}, {"name": "2023", "non_null": 12, "pandas_dtype": "float64", "unique_non_null": 11}, {"name": "2024", "non_null": 12, "pandas_dtype": "float64", "unique_non_null": 10}, {"name": "2025", "non_null": 12, "pandas_dtype": "float64", "unique_non_null": 10}, {"name": "TOTAL", "non_null": 11, "pandas_dtype": "float64", "unique_non_null": 11}]}, {"role": "archive_only", "rows": 522, "sheet": "Copy of Data Pertanian_Dummy", "columns": 17, "column_info": [{"name": "agri_id", "non_null": 519, "pandas_dtype": "object", "unique_non_null": 519}, {"name": "kalurahan", "non_null": 511, "pandas_dtype": "object", "unique_non_null": 5}, {"name": "padukuhan_id", "non_null": 511, "pandas_dtype": "object", "unique_non_null": 73}, {"name": "padukuhan", "non_null": 511, "pandas_dtype": "object", "unique_non_null": 72}, {"name": "komoditas", "non_null": 511, "pandas_dtype": "object", "unique_non_null": 7}, {"name": "kelompok_komoditas", "non_null": 511, "pandas_dtype": "object", "unique_non_null": 2}, {"name": "tahun", "non_null": 511, "pandas_dtype": "float64", "unique_non_null": 2}, {"name": "luas_panen_ha", "non_null": 511, "pandas_dtype": "float64", "unique_non_null": 480}, {"name": "luas_lahan_ha", "non_null": 511, "pandas_dtype": "float64", "unique_non_null": 490}, {"name": "jumlah_petani", "non_null": 511, "pandas_dtype": "float64", "unique_non_null": 27}, {"name": "jumlah_utp", "non_null": 511, "pandas_dtype": "float64", "unique_non_null": 22}, {"name": "jumlah_kelompok_tani", "non_null": 511, "pandas_dtype": "float64", "unique_non_null": 3}, {"name": "produksi", "non_null": 510, "pandas_dtype": "float64", "unique_non_null": 492}, {"name": "satuan_produksi_q", "non_null": 511, "pandas_dtype": "object", "unique_non_null": 1}, {"name": "sumber", "non_null": 511, "pandas_dtype": "object", "unique_non_null": 1}, {"name": "status_data", "non_null": 511, "pandas_dtype": "object", "unique_non_null": 1}, {"name": "catatan", "non_null": 511, "pandas_dtype": "object", "unique_non_null": 1}]}, {"role": "etl_source", "rows": 14, "sheet": "Data Pertanian_real", "columns": 14, "column_info": [{"name": "agri_id", "non_null": 14, "pandas_dtype": "object", "unique_non_null": 14}, {"name": "wilayah", "non_null": 14, "pandas_dtype": "object", "unique_non_null": 1}, {"name": "komoditas", "non_null": 14, "pandas_dtype": "object", "unique_non_null": 14}, {"name": "luas_panen_ha", "non_null": 3, "pandas_dtype": "float64", "unique_non_null": 3}, {"name": "luas_lahan_ha", "non_null": 0, "pandas_dtype": "float64", "unique_non_null": 0}, {"name": "jumlah_utp", "non_null": 5, "pandas_dtype": "float64", "unique_non_null": 5}, {"name": "produksi", "non_null": 6, "pandas_dtype": "float64", "unique_non_null": 6}, {"name": "satuan_produksi", "non_null": 14, "pandas_dtype": "object", "unique_non_null": 2}, {"name": "tahun_produksi", "non_null": 14, "pandas_dtype": "int64", "unique_non_null": 2}, {"name": "tahun_utp", "non_null": 5, "pandas_dtype": "float64", "unique_non_null": 1}, {"name": "sumber_produksi", "non_null": 14, "pandas_dtype": "object", "unique_non_null": 2}, {"name": "sumber_utp", "non_null": 6, "pandas_dtype": "object", "unique_non_null": 1}, {"name": "status_data", "non_null": 14, "pandas_dtype": "object", "unique_non_null": 1}, {"name": "catatan", "non_null": 9, "pandas_dtype": "object", "unique_non_null": 4}]}, {"role": "archive_only", "rows": 13, "sheet": "Copy of Data Wilayah_Kalurahan", "columns": 18, "column_info": [{"name": "kalurahan_id", "non_null": 8, "pandas_dtype": "object", "unique_non_null": 8}, {"name": "kalurahan", "non_null": 5, "pandas_dtype": "object", "unique_non_null": 5}, {"name": "luas_kalurahan_ha", "non_null": 5, "pandas_dtype": "float64", "unique_non_null": 5}, {"name": "jumlah_padukuhan", "non_null": 5, "pandas_dtype": "float64", "unique_non_null": 5}, {"name": "jumlah_rw", "non_null": 5, "pandas_dtype": "float64", "unique_non_null": 4}, {"name": "jumlah_rt", "non_null": 5, "pandas_dtype": "float64", "unique_non_null": 5}, {"name": "batas_utara", "non_null": 5, "pandas_dtype": "object", "unique_non_null": 3}, {"name": "batas_selatan", "non_null": 5, "pandas_dtype": "object", "unique_non_null": 4}, {"name": "batas_barat", "non_null": 5, "pandas_dtype": "object", "unique_non_null": 5}, {"name": "batas_timur", "non_null": 5, "pandas_dtype": "object", "unique_non_null": 5}, {"name": "jarak_kecamatan_km", "non_null": 5, "pandas_dtype": "object", "unique_non_null": 5}, {"name": "jarak_kabupaten_km", "non_null": 5, "pandas_dtype": "float64", "unique_non_null": 5}, {"name": "jarak_provinsi_km", "non_null": 5, "pandas_dtype": "float64", "unique_non_null": 5}, {"name": "jarak_nasional_km", "non_null": 5, "pandas_dtype": "float64", "unique_non_null": 4}, {"name": "latitude", "non_null": 5, "pandas_dtype": "float64", "unique_non_null": 5}, {"name": "longitude", "non_null": 5, "pandas_dtype": "float64", "unique_non_null": 5}, {"name": "sumber_data", "non_null": 5, "pandas_dtype": "object", "unique_non_null": 5}, {"name": "keterangan", "non_null": 1, "pandas_dtype": "object", "unique_non_null": 1}]}, {"role": "archive_only", "rows": 87, "sheet": "Copy of Data Wilayah_Padukuhan", "columns": 19, "column_info": [{"name": "padukuhan_id", "non_null": 82, "pandas_dtype": "object", "unique_non_null": 82}, {"name": "kalurahan_id", "non_null": 73, "pandas_dtype": "object", "unique_non_null": 5}, {"name": "kalurahan", "non_null": 73, "pandas_dtype": "object", "unique_non_null": 5}, {"name": "padukuhan", "non_null": 73, "pandas_dtype": "object", "unique_non_null": 72}, {"name": "jumlah_rt", "non_null": 73, "pandas_dtype": "float64", "unique_non_null": 4}, {"name": "jumlah_rw", "non_null": 73, "pandas_dtype": "float64", "unique_non_null": 3}, {"name": "latitude", "non_null": 73, "pandas_dtype": "float64", "unique_non_null": 70}, {"name": "longitude", "non_null": 73, "pandas_dtype": "float64", "unique_non_null": 67}, {"name": "sumber_data", "non_null": 73, "pandas_dtype": "object", "unique_non_null": 5}, {"name": "sumber_koordinat", "non_null": 73, "pandas_dtype": "object", "unique_non_null": 1}, {"name": "keterangan", "non_null": 0, "pandas_dtype": "float64", "unique_non_null": 0}, {"name": "jarak_kecamatan_km", "non_null": 5, "pandas_dtype": "object", "unique_non_null": 5}, {"name": "jarak_kabupaten_km", "non_null": 5, "pandas_dtype": "float64", "unique_non_null": 5}, {"name": "jarak_provinsi_km", "non_null": 5, "pandas_dtype": "float64", "unique_non_null": 5}, {"name": "jarak_nasional_km", "non_null": 5, "pandas_dtype": "float64", "unique_non_null": 4}, {"name": "latitude.1", "non_null": 0, "pandas_dtype": "float64", "unique_non_null": 0}, {"name": "longitude.1", "non_null": 0, "pandas_dtype": "float64", "unique_non_null": 0}, {"name": "sumber_data.1", "non_null": 5, "pandas_dtype": "object", "unique_non_null": 5}, {"name": "keterangan.1", "non_null": 1, "pandas_dtype": "object", "unique_non_null": 1}]}], "fatal_errors": [], "foreign_keys": [{"child": "padukuhan", "column": "kalurahan_id", "parent": "kalurahan", "orphans": 0, "parent_column": "kalurahan_id"}, {"child": "data_pertanian", "column": "padukuhan_id", "parent": "padukuhan", "orphans": 0, "parent_column": "padukuhan_id"}, {"child": "ketersediaan_bahan", "column": "bahan_id", "parent": "bahan_organik", "orphans": 0, "parent_column": "bahan_id"}, {"child": "ketersediaan_bahan", "column": "padukuhan_id", "parent": "padukuhan", "orphans": 0, "parent_column": "padukuhan_id"}, {"child": "produksi", "column": "produk_id", "parent": "produk", "orphans": 0, "parent_column": "produk_id"}, {"child": "penjualan", "column": "produk_id", "parent": "produk", "orphans": 0, "parent_column": "produk_id"}], "generated_at": "2026-10-23T17:24:35.817680+00:00", "archive_audit": [{"note": "Kolom tambahan setelah 10 kolom sumber adalah blok pivot, bukan data ETL.", "role": "archive_only", "sheet": "Copy of Data_Penjualan", "source_rows": 792, "material_differences": []}, {"note": "Baris setelah 511 data adalah catatan/sumber, bukan data ETL.", "role": "archive_only", "sheet": "Copy of Data Pertanian_Dummy", "source_rows": 522, "material_differences": [{"key": "AGRI-0047", "column": "produksi"}, {"key": "AGRI-0234", "column": "jumlah_petani"}, {"key": "AGRI-0308", "column": "luas_lahan_ha"}]}, {"note": "Baris tambahan adalah catatan; nilai numerik dibandingkan secara numerik.", "role": "archive_only", "sheet": "Copy of Data Wilayah_Kalurahan", "source_rows": 13, "material_differences": []}, {"note": "Baris tambahan adalah catatan; nilai numerik dibandingkan secara numerik.", "role": "archive_only", "sheet": "Copy of Data Wilayah_Padukuhan", "source_rows": 87, "material_differences": []}], "imported_rows": {"produk": 11, "produksi": 66, "kalurahan": 5, "padukuhan": 73, "penjualan": 792, "bahan_organik": 17, "data_pertanian": 511, "ketersediaan_bahan": 88, "data_pertanian_real": 14, "produk_katalog_audit": 11}, "row_estimates": {"core_total": 1563, "grand_total": 1588, "catalog_audit": 11, "real_agriculture": 14}, "synthetic_real": {"real_rows": 14, "id_overlap": [], "synthetic_rows": 511, "separate_tables": true}, "database_writes": true, "production_rule": {"note": "Jumlah_produksi_total adalah total kelompok berulang; jangan dijumlahkan.", "sum_total": 200392.0, "sum_varian": 142638.0, "aggregation_column": "jumlah_produksi_varian", "rows_total_differs": 36}, "organic_distance": {"status": "blocked_pending_verified_source", "stored_null": 88, "source_values": 88, "stored_non_null": 0}, "sales_consistency": {"rows": 792, "max_bulan": "2025-12-01", "min_bulan": "2020-01-01", "formula_mismatches": 0, "zero_quantity_rows": 253}, "database_row_counts": {"produk": 11, "produksi": 66, "kalurahan": 5, "padukuhan": 73, "penjualan": 792, "bahan_organik": 17, "data_pertanian": 511, "ketersediaan_bahan": 88, "data_pertanian_real": 14, "produk_katalog_audit": 11}, "notebook_references": {"note": "hasil_scoring adalah ranking produk berdasarkan prediksi penjualan, bukan ranking bahan organik.", "core_tables": ["kalurahan", "padukuhan", "data_pertanian", "bahan_organik", "ketersediaan_bahan", "produk", "produksi", "penjualan"], "sheets_read": ["Data_produksi_pupuk", "Data_Bahan_Organik", "Data_Produk_Katalog", "Data_Penjualan", "Data Wilayah_Kalurahan", "Data_Wilayah_Padukuhan", "Data_Pertanian"], "result_tables": ["hasil_peringkat_potensi_organik", "perbandingan_ranking_organik", "hasil_scoring", "hasil_prediksi"]}, "mapping_confirmations": [{"item": "Data_Produk_Katalog", "note": "Katalog utama untuk ETL.", "table": "produk", "status": "confirmed"}, {"item": "Produk_Katalog", "note": "Katalog kedua hanya untuk audit; tidak digabung ke produk.", "table": "produk_katalog_audit", "status": "confirmed"}, {"item": "Data_Pertanian", "note": "Data sintetis tingkat padukuhan; tidak dicampur dengan data riil.", "table": "data_pertanian", "status": "confirmed"}, {"item": "Data Pertanian_real", "note": "Data riil tingkat kecamatan; tidak dapat di-join ke padukuhan.", "table": "data_pertanian_real", "status": "confirmed"}, {"item": "Copy of ...", "note": "Semua sheet Copy of hanya diarsipkan dan bukan sumber ETL.", "table": "arsip", "status": "confirmed"}, {"item": "jarak_ke_produksi_km", "note": "Nilai sumber belum terverifikasi; semua nilai disimpan NULL. AHP-SAW belum dapat dijalankan.", "table": "ketersediaan_bahan", "status": "blocked"}, {"item": "status_data 'Sintestis'", "note": "Nilai dipertahankan apa adanya; perlu keputusan normalisasi ke 'Sintetis'.", "table": "produksi", "status": "needs_confirmation"}, {"item": "data_pertanian_real", "note": "Perlu konfirmasi apakah tabel ini ditampilkan di aplikasi atau hanya arsip audit.", "table": "data_pertanian_real", "status": "needs_confirmation"}, {"item": "hasil_scoring", "note": "Ranking produk berdasarkan prediksi penjualan, bukan ranking potensi bahan organik.", "table": "hasil_scoring", "status": "confirmed"}, {"item": "hasil_prediksi", "note": "Prediksi penjualan 2026; bukan ranking bahan organik.", "table": "hasil_prediksi", "status": "confirmed"}], "real_agriculture_missing": {"produksi": 8, "jumlah_utp": 9, "luas_lahan_ha": 14}}
\.


--
-- Name: bahan_organik bahan_organik_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bahan_organik
    ADD CONSTRAINT bahan_organik_pkey PRIMARY KEY (bahan_id);


--
-- Name: data_pertanian data_pertanian_padukuhan_id_komoditas_tahun_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_pertanian
    ADD CONSTRAINT data_pertanian_padukuhan_id_komoditas_tahun_key UNIQUE (padukuhan_id, komoditas, tahun);


--
-- Name: data_pertanian data_pertanian_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_pertanian
    ADD CONSTRAINT data_pertanian_pkey PRIMARY KEY (agri_id);


--
-- Name: data_pertanian_real data_pertanian_real_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_pertanian_real
    ADD CONSTRAINT data_pertanian_real_pkey PRIMARY KEY (agri_id);


--
-- Name: data_pertanian_real data_pertanian_real_wilayah_komoditas_tahun_produksi_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_pertanian_real
    ADD CONSTRAINT data_pertanian_real_wilayah_komoditas_tahun_produksi_key UNIQUE (wilayah, komoditas, tahun_produksi);


--
-- Name: kalurahan kalurahan_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.kalurahan
    ADD CONSTRAINT kalurahan_pkey PRIMARY KEY (kalurahan_id);


--
-- Name: ketersediaan_bahan ketersediaan_bahan_bahan_id_padukuhan_id_periode_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ketersediaan_bahan
    ADD CONSTRAINT ketersediaan_bahan_bahan_id_padukuhan_id_periode_key UNIQUE (bahan_id, padukuhan_id, periode);


--
-- Name: ketersediaan_bahan ketersediaan_bahan_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ketersediaan_bahan
    ADD CONSTRAINT ketersediaan_bahan_pkey PRIMARY KEY (ketersediaan_id);


--
-- Name: padukuhan padukuhan_kalurahan_id_padukuhan_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.padukuhan
    ADD CONSTRAINT padukuhan_kalurahan_id_padukuhan_key UNIQUE (kalurahan_id, padukuhan);


--
-- Name: padukuhan padukuhan_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.padukuhan
    ADD CONSTRAINT padukuhan_pkey PRIMARY KEY (padukuhan_id);


--
-- Name: penjualan penjualan_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.penjualan
    ADD CONSTRAINT penjualan_pkey PRIMARY KEY (penjualan_id);


--
-- Name: penjualan penjualan_produk_id_bulan_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.penjualan
    ADD CONSTRAINT penjualan_produk_id_bulan_key UNIQUE (produk_id, bulan);


--
-- Name: produk_katalog_audit produk_katalog_audit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produk_katalog_audit
    ADD CONSTRAINT produk_katalog_audit_pkey PRIMARY KEY (produk_id);


--
-- Name: produk produk_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produk
    ADD CONSTRAINT produk_pkey PRIMARY KEY (produk_id);


--
-- Name: produksi produksi_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produksi
    ADD CONSTRAINT produksi_pkey PRIMARY KEY (produksi_id);


--
-- Name: produksi produksi_produk_id_periode_produksi_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produksi
    ADD CONSTRAINT produksi_produk_id_periode_produksi_key UNIQUE (produk_id, periode_produksi);


--
-- Name: staging_import_run staging_import_run_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staging_import_run
    ADD CONSTRAINT staging_import_run_pkey PRIMARY KEY (run_id);


--
-- Name: idx_data_pertanian_padukuhan; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_data_pertanian_padukuhan ON public.data_pertanian USING btree (padukuhan_id);


--
-- Name: idx_ketersediaan_bahan_bahan; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ketersediaan_bahan_bahan ON public.ketersediaan_bahan USING btree (bahan_id);


--
-- Name: idx_ketersediaan_bahan_padukuhan; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ketersediaan_bahan_padukuhan ON public.ketersediaan_bahan USING btree (padukuhan_id);


--
-- Name: idx_padukuhan_kalurahan; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_padukuhan_kalurahan ON public.padukuhan USING btree (kalurahan_id);


--
-- Name: idx_penjualan_bulan; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_penjualan_bulan ON public.penjualan USING btree (bulan);


--
-- Name: idx_penjualan_produk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_penjualan_produk ON public.penjualan USING btree (produk_id);


--
-- Name: idx_produksi_produk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_produksi_produk ON public.produksi USING btree (produk_id);


--
-- Name: data_pertanian data_pertanian_padukuhan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_pertanian
    ADD CONSTRAINT data_pertanian_padukuhan_id_fkey FOREIGN KEY (padukuhan_id) REFERENCES public.padukuhan(padukuhan_id);


--
-- Name: ketersediaan_bahan ketersediaan_bahan_bahan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ketersediaan_bahan
    ADD CONSTRAINT ketersediaan_bahan_bahan_id_fkey FOREIGN KEY (bahan_id) REFERENCES public.bahan_organik(bahan_id);


--
-- Name: ketersediaan_bahan ketersediaan_bahan_padukuhan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ketersediaan_bahan
    ADD CONSTRAINT ketersediaan_bahan_padukuhan_id_fkey FOREIGN KEY (padukuhan_id) REFERENCES public.padukuhan(padukuhan_id);


--
-- Name: padukuhan padukuhan_kalurahan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.padukuhan
    ADD CONSTRAINT padukuhan_kalurahan_id_fkey FOREIGN KEY (kalurahan_id) REFERENCES public.kalurahan(kalurahan_id);


--
-- Name: penjualan penjualan_produk_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.penjualan
    ADD CONSTRAINT penjualan_produk_id_fkey FOREIGN KEY (produk_id) REFERENCES public.produk(produk_id);


--
-- Name: produksi produksi_produk_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produksi
    ADD CONSTRAINT produksi_produk_id_fkey FOREIGN KEY (produk_id) REFERENCES public.produk(produk_id);


--
-- PostgreSQL database dump complete
--

\unrestrict vy7ucBbk6ayuiBs3bOOkVhfJKHSQHyGr73zRv8Gc12HgPMZIg0zrvy7mzZh6orw

