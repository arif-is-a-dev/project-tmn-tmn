import os
import sys
import json
import uuid
from pathlib import Path
from datetime import datetime, timezone

from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import make_url

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from scripts.vinix_etl import (
    DEFAULT_SOURCE, PRIMARY_KEYS, TABLE_COLUMNS, TABLE_ORDER,
    build_datasets, print_summary,
)
from scripts.db_utils import assert_schema, upsert_frame

CONFIRMATION = "IMPOR VINIX7 KE NEON"

def main():
    url = os.environ.get("VINIX7_NEON_URL", "").strip()
    if not url:
        raise SystemExit("VINIX7_NEON_URL belum diatur di PowerShell.")

    parsed = make_url(url)
    if (
        parsed.get_backend_name() != "postgresql"
        or parsed.database != "neondb"
        or not (parsed.host or "").endswith(".neon.tech")
    ):
        raise SystemExit("DIBATALKAN: target bukan database Neon neondb.")

    result = build_datasets(str(DEFAULT_SOURCE))
    print_summary(result)

    if result.fatal_errors:
        raise SystemExit("DIBATALKAN: ETL memiliki fatal error.")

    engine = create_engine(
        url, pool_pre_ping=True,
        connect_args={"connect_timeout": 15}
    )

    try:
        with engine.connect() as conn:
            db = conn.exec_driver_sql("SELECT current_database()").scalar_one()
            if db != "neondb":
                raise SystemExit("DIBATALKAN: nama database tidak cocok.")

            assert_schema(engine, TABLE_COLUMNS, ["staging_import_run"])

            tables = list(TABLE_ORDER)
            counts = {
                table: conn.execute(
                    text(f'SELECT COUNT(*) FROM "{table}"')
                ).scalar_one()
                for table in tables
            }
            staging_count = conn.execute(
                text("SELECT COUNT(*) FROM staging_import_run")
            ).scalar_one()

        nonempty = {k: v for k, v in counts.items() if v != 0}
        if nonempty or staging_count != 0:
            raise SystemExit(
                f"DIBATALKAN: target tidak kosong: {nonempty}; "
                f"staging_import_run={staging_count}"
            )

        print("\nTarget: Neon / neondb")
        print("Tabel tujuan kosong dan struktur wajib tersedia.")
        print("Total baris sumber:", sum(len(result.datasets[t]) for t in tables))
        answer = input(
            f"Ketik '{CONFIRMATION}' untuk melanjutkan: "
        ).strip()
        if answer != CONFIRMATION:
            raise SystemExit("Dibatalkan. Tidak ada data yang diimpor.")

        run_id = uuid.uuid4().hex
        started = datetime.now(timezone.utc)
        imported = {}

        with engine.begin() as conn:
            for table in TABLE_ORDER:
                imported[table] = upsert_frame(
                    conn, table, result.datasets[table], PRIMARY_KEYS[table]
                )

            finished = datetime.now(timezone.utc)
            report = {
                "run_id": run_id,
                "mode": "apply",
                "target_database": "neondb",
                "source_sha256": result.report["source"]["sha256"],
                "imported_rows": imported,
                "finished_at": finished.isoformat(),
            }

            conn.execute(text("""
                INSERT INTO staging_import_run
                    (run_id, started_at, finished_at, source_sha256,
                     mode, status, report)
                VALUES
                    (:run_id, :started, :finished, :sha, 'apply',
                     'applied', CAST(:report AS JSONB))
            """), {
                "run_id": run_id,
                "started": started,
                "finished": finished,
                "sha": result.report["source"]["sha256"],
                "report": json.dumps(report, ensure_ascii=False, default=str),
            })

        with engine.connect() as conn:
            final_counts = {
                table: conn.execute(
                    text(f'SELECT COUNT(*) FROM "{table}"')
                ).scalar_one()
                for table in TABLE_ORDER
            }

        print("\nIMPOR SELESAI")
        for table, count in final_counts.items():
            print(f"{table:25} {count}")
        print("Total tabel ETL:", sum(final_counts.values()))
        print("Run ID:", run_id)

    finally:
        engine.dispose()

if __name__ == "__main__":
    main()
