import csv
from pathlib import Path

csv_path = Path("k3_simulasi_neon.csv")
sql_path = Path("update_neon_k3_simulasi.sql")

with csv_path.open("r", encoding="utf-8-sig", newline="") as f:
    rows = list(csv.DictReader(f))

if len(rows) != 88:
    raise SystemExit(f"Dibatalkan: CSV harus berisi 88 baris, ditemukan {len(rows)}.")

ids = [r["ketersediaan_id"] for r in rows]
if len(set(ids)) != 88:
    raise SystemExit("Dibatalkan: ada ID duplikat.")

values = ",\n".join(
    f"('{r['ketersediaan_id']}', {float(r['jarak_ke_produksi_km']):.2f})"
    for r in rows
)

sql = f"""-- K3 SIMULASI: centroid aritmetik 73 padukuhan sumber bahan organik.
-- Bukan jarak terverifikasi ke fasilitas produksi nyata.
-- Jalankan hanya pada database Neon project VINIX7.

BEGIN;

DO $$
DECLARE
    total_rows integer;
    null_rows integer;
BEGIN
    SELECT COUNT(*),
           COUNT(*) FILTER (WHERE jarak_ke_produksi_km IS NULL)
    INTO total_rows, null_rows
    FROM public.ketersediaan_bahan;

    IF total_rows <> 88 THEN
        RAISE EXCEPTION 'Dibatalkan: total baris %, seharusnya 88', total_rows;
    END IF;

    IF null_rows <> 88 THEN
        RAISE EXCEPTION 'Dibatalkan: K3 NULL sebanyak %, seharusnya 88. Tidak ada perubahan.', null_rows;
    END IF;
END $$;

UPDATE public.ketersediaan_bahan AS kb
SET jarak_ke_produksi_km = v.jarak_km
FROM (
    VALUES
{values}
) AS v(ketersediaan_id, jarak_km)
WHERE kb.ketersediaan_id = v.ketersediaan_id
  AND kb.jarak_ke_produksi_km IS NULL;

DO $$
DECLARE
    filled_rows integer;
    null_rows integer;
BEGIN
    SELECT COUNT(*) FILTER (WHERE jarak_ke_produksi_km IS NOT NULL),
           COUNT(*) FILTER (WHERE jarak_ke_produksi_km IS NULL)
    INTO filled_rows, null_rows
    FROM public.ketersediaan_bahan;

    IF filled_rows <> 88 OR null_rows <> 0 THEN
        RAISE EXCEPTION 'Verifikasi gagal: terisi %, NULL %', filled_rows, null_rows;
    END IF;
END $$;

COMMIT;

-- Label metode simulasi disimpan sebagai komentar metodologis.
-- Nilai numerik K3 berasal dari centroid sintetis, bukan lokasi fasilitas nyata.
"""

sql_path.write_text(sql, encoding="utf-8")
print(f"Berhasil membuat: {sql_path.resolve()}")
print(f"Jumlah nilai yang disiapkan: {len(rows)}")
print("Belum ada perubahan pada database.")
