import csv
from pathlib import Path

from compute_k3_distances import (
    PRODUCTION_REF_LABEL,
    _fetch_kb_padukuhan_coords,
    compute_distances,
)
from scripts.db_utils import (
    assert_local_vinix7,
    database_url,
    load_environment,
    make_engine,
)

output = Path("k3_simulasi_neon.csv")

load_environment()
url = database_url()
assert_local_vinix7(url)
engine = make_engine(url)

try:
    with engine.connect() as conn:
        rows = _fetch_kb_padukuhan_coords(conn)

    if len(rows) != 88:
        raise RuntimeError(f"Seharusnya 88 baris, ditemukan {len(rows)}.")

    rows = compute_distances(rows)

    if len({r["ketersediaan_id"] for r in rows}) != 88:
        raise RuntimeError("ID ketersediaan tidak unik. Ekspor dibatalkan.")

    with output.open("w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "ketersediaan_id",
                "jarak_ke_produksi_km",
                "metode",
                "status_data",
            ],
        )
        writer.writeheader()
        for r in rows:
            writer.writerow({
                "ketersediaan_id": r["ketersediaan_id"],
                "jarak_ke_produksi_km": round(r["jarak_computed"], 2),
                "metode": PRODUCTION_REF_LABEL,
                "status_data": "SIMULASI",
            })

    print(f"Ekspor selesai: {output.resolve()}")
    print(f"Jumlah baris data: {len(rows)}")
    print("Database hanya dibaca; tidak ada perubahan database.")
finally:
    engine.dispose()

